/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSStringHelper.h"
#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TDCAlert.h"
#import "TPCApplicationInfo.h"
#import "TLOLanguagePreferences.h"
#import "TLOLicenseManagerDownloaderPrivate.h"

NS_ASSUME_NONNULL_BEGIN

/* URLs for performing certain actions with license keys. */
NSString * const TLOLicenseManagerDownloaderLicenseAPIActivationURL						= @"https://textual-license-key-backend.codeux.com/activateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL				= @"https://textual-license-key-backend.codeux.com/sendLostLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIMigrateAppStoreURL				= @"https://textual-license-key-backend.codeux.com/convertReceiptToLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPILicenseUpgradeEligibilityURL		= @"https://textual-license-key-backend.codeux.com/upgradeEligibility.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIReceiptUpgradeEligibilityURL		= @"https://textual-license-key-backend.codeux.com/upgradeEligibilityForReceipt.cs";

/* The license API throttles requests to prevent abuse. The following HTTP status 
 code will inform Textual if it the license API has been overwhelmed. */
NSUInteger const TLOLicenseManagerDownloaderRequestHTTPStatusSuccess = 200; // OK
NSUInteger const TLOLicenseManagerDownloaderRequestHTTPStatusTryAgainLater = 503; // Service Unavailable

/* The following constants note status codes that may be returned part of the 
 contents of a license API response body. This is not a complete list. */
NSUInteger const TLOLicenseManagerDownloaderRequestStatusCodeSuccess = 0;
NSUInteger const TLOLicenseManagerDownloaderRequestStatusCodeGenericError = 2000000;
NSUInteger const TLOLicenseManagerDownloaderRequestStatusCodeTryAgainLater = 2000001;

/* Private header */
@interface TLOLicenseManagerDownloaderConnection : NSObject <NSURLConnectionDelegate>
@property (nonatomic, weak) TLOLicenseManagerDownloader *delegate; // To be set by caller
@property (nonatomic, assign) TLOLicenseManagerDownloaderRequestType requestType; // To be set by caller
@property (nonatomic, copy) NSDictionary<NSString *, id> *requestContextInfo; // Information set by caller such as license key or e-mail address
@property (nonatomic, strong) NSURLConnection *requestConnection; // Will be set by the object, readonly
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse; // Will be set by the object, readonly
@property (nonatomic, strong) NSMutableData *requestResponseData; // Will be set by the object, readonly

- (BOOL)setupConnectionRequest;

- (void)cancelRequest;
@end

@interface TLOLicenseManagerDownloader ()
@property (nonatomic, strong, nullable) TLOLicenseManagerDownloaderConnection *activeConnection;

- (void)processResponseForRequestType:(TLOLicenseManagerDownloaderRequestType)requestType
					   httpStatusCode:(NSUInteger)requestHttpStatusCode
							 contents:(nullable NSData *)requestContents;
@end

#define _connectionTimeoutInterval			30.0

@implementation TLOLicenseManagerDownloader

#pragma mark -
#pragma mark Public Interface

- (void)activateLicense:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	NSDictionary *contextInfo = @{@"licenseKey" : licenseKey};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestActivationType
								context:contextInfo];
}

- (void)deactivateLicense
{
	BOOL operationResult = self.actionBlock(TLOLicenseManagerDownloaderRequestStatusCodeSuccess, nil);

	if (self.completionBlock) {
		self.completionBlock(operationResult, TLOLicenseManagerDownloaderRequestStatusCodeSuccess, nil);
	}
}

- (void)checkUpgradeEligibilityOfLicense:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	NSDictionary *contextInfo = @{@"licenseKey" : licenseKey};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestLicenseUpgradeEligibilityType
								context:contextInfo];
}

- (void)checkUpgradeEligibilityOfReceipt:(NSString *)receiptData
{
	NSParameterAssert(receiptData != nil);

	NSString *macAddress = [XRSystemInformation formattedEthernetMacAddress];

	NSParameterAssert(macAddress != nil);

	NSDictionary *contextInfo = @{
		@"receiptData" : receiptData,
		@"licenseOwnerMacAddress" : macAddress
	};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestReceiptUpgradeEligibilityType
								context:contextInfo];
}

- (void)requestLostLicenseKeyForContactAddress:(NSString *)contactAddress
{
	NSParameterAssert(contactAddress != nil);

	NSDictionary *contextInfo = @{@"licenseOwnerContactAddress" : contactAddress};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestSendLostLicenseType
								context:contextInfo];
}

- (void)migrateMacAppStorePurchase:(NSString *)receiptData licenseOwnerName:(NSString *)licenseOwnerName licenseOwnerContactAddress:(NSString *)licenseOwnerContactAddress
{
	NSParameterAssert(receiptData != nil);
	NSParameterAssert(licenseOwnerName != nil);
	NSParameterAssert(licenseOwnerContactAddress != nil);

	NSString *macAddress = [XRSystemInformation formattedEthernetMacAddress];

	NSParameterAssert(macAddress != nil);

	NSDictionary *contextInfo = @{
		@"receiptData" : receiptData,
		@"licenseOwnerName"	: licenseOwnerName,
		@"licenseOwnerContactAddress" : licenseOwnerContactAddress,
		@"licenseOwnerMacAddress" : macAddress
	};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestMigrateAppStoreType
								context:contextInfo];
}

- (void)setupNewActionWithRequestType:(TLOLicenseManagerDownloaderRequestType)requestType context:(NSDictionary<NSString *, id> *)requestContext
{
	NSParameterAssert(requestContext != nil);

	if (self.activeConnection != nil) {
		[self.activeConnection cancelRequest];
	}

	TLOLicenseManagerDownloaderConnection *connectionObject = [TLOLicenseManagerDownloaderConnection new];

	connectionObject.delegate = self;

	connectionObject.requestContextInfo = requestContext;

	connectionObject.requestType = requestType;

	self.activeConnection = connectionObject;

	(void)[connectionObject setupConnectionRequest];
}

- (void)cancelRequest
{
	if (self.activeConnection == nil) {
		return;
	}

	[self.activeConnection cancelRequest];

	self.activeConnection = nil;

	self.actionBlock = nil;
	self.errorBlock = nil;
	self.completionBlock = nil;
}

- (void)processResponseForRequestType:(TLOLicenseManagerDownloaderRequestType)requestType httpStatusCode:(NSUInteger)requestHttpStatusCode contents:(nullable NSData *)requestContents
{
	/* The license API returns content as property lists, including errors. This method
	 will try to convert the returned contents into an NSDictionary (assuming its a valid
	 property list). If that fails, then the method shows generic failure reason and
	 logs to the console that the contents could not parsed. */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		self.activeConnection = nil;
	});

#define _performCompletionBlockAndReturn(operationResult) \
	if (self.completionBlock) { 	\
		self.completionBlock((operationResult), (statusCode), (statusContext)); 	\
	} 	\
		\
	return;

	/* Define defaults */
	id propertyList = nil;

	NSUInteger statusCode = 0;

	id statusContext = nil;

	if (requestHttpStatusCode == TLOLicenseManagerDownloaderRequestHTTPStatusTryAgainLater) {
		statusCode = TLOLicenseManagerDownloaderRequestStatusCodeTryAgainLater;

		goto present_fatal_error;
	} else {
		statusCode = TLOLicenseManagerDownloaderRequestStatusCodeGenericError;
	}

	/* Attempt to convert contents into a property list dictionary */
	if (requestContents) {
		NSError *propertyListReadError = nil;

		propertyList = [NSPropertyListSerialization propertyListWithData:requestContents
																 options:NSPropertyListImmutable
																  format:NULL
																   error:&propertyListReadError];

		if (propertyList == nil || [propertyList isKindOfClass:[NSDictionary class]] == NO) {
			if (propertyListReadError) {
				LogToConsoleError("Failed to convert contents of request into dictionary. Error: %{public}@",
					  propertyListReadError.localizedDescription);
			}
		}
	}

	if (propertyList) {
		id l_statusCode = propertyList[@"Status Code"];

		if (l_statusCode == nil || [l_statusCode isKindOfClass:[NSNumber class]] == NO) {
			LogToConsoleError("'Status Code' is nil or not of kind 'NSNumber'");

			goto present_fatal_error;
		}

		statusCode = [l_statusCode unsignedIntegerValue];

		statusContext = propertyList[@"Status Context"];

		if (requestHttpStatusCode == TLOLicenseManagerDownloaderRequestHTTPStatusSuccess)
		{
			/* Process successful results */
			if (requestType == TLOLicenseManagerDownloaderRequestActivationType && statusCode == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSData class]] == NO) {
					LogToConsoleError("'Status Context' is nil or not of kind 'NSData'");

					goto present_fatal_error;
				}

				if (self.actionBlock != nil && self.actionBlock(statusCode, statusContext) == NO) {
					LogToConsoleError("Failed to write user license file contents");

					goto present_fatal_error;
				}

				if (self.isSilentOnSuccess == NO) {
					(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[k39-7l]")
													title:TXTLS(@"TLOLicenseManager[jbs-64]")
											defaultButton:TXTLS(@"Prompts[c7s-dq]")
										  alternateButton:nil];
				}
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType && statusCode == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' is nil or not of kind 'NSDictionary'");

					goto present_fatal_error;
				}

				if (self.actionBlock != nil && self.actionBlock(statusCode, statusContext) == NO) {
					LogToConsoleError("Action blocked returned error");

					goto present_fatal_error;
				}

				NSString *licenseOwnerContactAddress = statusContext[@"licenseOwnerContactAddress"];

				if (licenseOwnerContactAddress.length == 0) {
					LogToConsoleError("'licenseOwnerContactAddress' is nil or of zero length");

					goto present_fatal_error;
				}

				if (self.isSilentOnSuccess == NO) {
					(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[fxj-s6]", licenseOwnerContactAddress)
													title:TXTLS(@"TLOLicenseManager[m4q-ul]", licenseOwnerContactAddress)
											defaultButton:TXTLS(@"Prompts[c7s-dq]")
										  alternateButton:nil];
				}
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' is nil or not of kind 'NSDictionary'");

					goto present_fatal_error;
				}

				if (self.actionBlock != nil && self.actionBlock(statusCode, statusContext) == NO) {
					LogToConsoleError("Action blocked returned error");

					goto present_fatal_error;
				}

				NSString *licenseOwnerContactAddress = statusContext[@"licenseOwnerContactAddress"];

				if (licenseOwnerContactAddress.length == 0) {
					LogToConsoleError("'licenseOwnerContactAddress' is nil or of zero length");

					goto present_fatal_error;
				}

				if (self.isSilentOnSuccess == NO) {
					(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[yxk-ej]", licenseOwnerContactAddress)
													title:TXTLS(@"TLOLicenseManager[vxq-oa]", licenseOwnerContactAddress)
											defaultButton:TXTLS(@"Prompts[c7s-dq]")
										  alternateButton:nil];
				}
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestLicenseUpgradeEligibilityType && statusCode == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' is nil or not of kind 'NSDictionary'");

					goto present_fatal_error;
				}

				if (self.actionBlock != nil) {
					(void)self.actionBlock(statusCode, statusContext);
				}
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestReceiptUpgradeEligibilityType && statusCode == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' is nil or not of kind 'NSDictionary'");

					goto present_fatal_error;
				}

				if (self.actionBlock != nil) {
					(void)self.actionBlock(statusCode, statusContext);
				}
			}

			_performCompletionBlockAndReturn(YES)
		}
		else // TLOLicenseManagerDownloaderRequestStatusCodeSuccess
		{
			if (self.errorBlock != nil && self.errorBlock(statusCode, statusContext)) {
				goto perform_return;
			}

			if (self.isSilentOnFailure) {
				goto perform_return;
			}

			/* Errors related to license activation. */
			if (requestType == TLOLicenseManagerDownloaderRequestActivationType && statusCode == 6500000)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[wc7-mn]")
												title:TXTLS(@"TLOLicenseManager[fg6-gf]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestActivationType && statusCode == 6500001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseKey = statusContext[@"licenseKey"];

				if (licenseKey.length == 0) {
					LogToConsoleError("'licenseKey' is nil or of zero length");

					goto present_fatal_error;
				}

				BOOL userResponse = [TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[w1n-n0]")
															  title:TXTLS(@"TLOLicenseManager[u8h-qv]", licenseKey.prettyLicenseKey)
													  defaultButton:TXTLS(@"Prompts[c7s-dq]")
													alternateButton:TXTLS(@"TLOLicenseManager[vgp-j6]")];

				if (userResponse == NO) { // NO = alternate button
					[self contactSupport];
				}
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestActivationType && statusCode == 6500002)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseKey = statusContext[@"licenseKey"];

				if (licenseKey.length == 0) {
					LogToConsoleError("'licenseKey' is nil or of zero length");

					goto present_fatal_error;
				}

				NSInteger licenseKeyActivationLimit = [statusContext integerForKey:@"licenseKeyActivationLimit"];

				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[6aa-ow]", licenseKeyActivationLimit)
												title:TXTLS(@"TLOLicenseManager[o66-ox]", licenseKey.prettyLicenseKey)
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}

			/* Errors related to lost license recovery. */
			else if (requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType && statusCode == 6400000)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[dio-y9]")
												title:TXTLS(@"TLOLicenseManager[ocm-03]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType && statusCode == 6400001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *originalInput = statusContext[@"originalInput"];

				if (originalInput.length == 0) {
					LogToConsoleError("'originalInput' is nil or of zero length");

					goto present_fatal_error;
				}

				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[6zh-jr]", originalInput)
												title:TXTLS(@"TLOLicenseManager[r87-jw]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}

			/* Error messages related to Mac App Store migration. */
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == 6600002)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[bu4-zk]")
												title:TXTLS(@"TLOLicenseManager[ztd-5y]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == 6600003)
			{
				/* We do not present a custom dialog for this error, but we still log
				 the contents of the context to the console to help diagnose issues. */
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsoleError("'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *errorMessage = statusContext[@"Error Message"];

				if (errorMessage.length == 0) {
					LogToConsoleError("'errorMessage' is nil or of zero length");

					goto present_fatal_error;
				}

				LogToConsoleError("Receipt validation failed:\n%{public}@", errorMessage);

				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[ujo-cd]", errorMessage)
												title:TXTLS(@"TLOLicenseManager[p9s-ak]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == 6600004)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[36y-49]")
												title:TXTLS(@"TLOLicenseManager[enb-hw]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == 6600006)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[do9-8x]")
												title:TXTLS(@"TLOLicenseManager[f49-rk]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType && statusCode == 6600007)
			{
				(void)[TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[4n2-ps]")
												title:TXTLS(@"TLOLicenseManager[t28-j9]")
										defaultButton:TXTLS(@"Prompts[c7s-dq]")
									  alternateButton:nil];
			}

			_performCompletionBlockAndReturn(NO)
		}
	}

present_fatal_error:
	if ((self.errorBlock == nil ||
		 self.errorBlock(statusCode, statusContext) == NO) &&
		self.isSilentOnFailure == NO)
	{
		[self presentTryAgainLaterErrorDialog];
	}

perform_return:
	_performCompletionBlockAndReturn(NO)

#undef _performCompletionBlockAndReturn
}

- (void)presentTryAgainLaterErrorDialog
{
	BOOL userResponse = [TDCAlert modalAlertWithMessage:TXTLS(@"TLOLicenseManager[1cv-0v]")
												  title:TXTLS(@"TLOLicenseManager[nhh-ts]")
										  defaultButton:TXTLS(@"Prompts[c7s-dq]")
										alternateButton:TXTLS(@"TLOLicenseManager[bqw-cv]")];

	if (userResponse == NO) { // NO = alternate button
		[self contactSupport];
	}
}

- (void)contactSupport
{
	[menuController() contactSupport:nil];
}

@end

#pragma mark -
#pragma mark Connection Assistant

@implementation TLOLicenseManagerDownloaderConnection

- (NSURL *)requestURL
{
	NSString *requestURLString = nil;

	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPIActivationURL;
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL;
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPIMigrateAppStoreURL;
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestLicenseUpgradeEligibilityType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPILicenseUpgradeEligibilityURL;
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestReceiptUpgradeEligibilityType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPIReceiptUpgradeEligibilityURL;
	}

	return [NSURL URLWithString:requestURLString];
}

- (NSString *)encodedRequestContextValue:(NSString *)contextKey
{
	NSParameterAssert(contextKey != nil);

	NSString *contextValue = self.requestContextInfo[contextKey];

	return contextValue.percentEncodedString;
}

- (BOOL)populateRequestPostData:(NSMutableURLRequest *)connectionRequest
{
	NSParameterAssert(connectionRequest != nil);

	/* Post parameter(s) defined by this method are subjec to change at
	 any time because obviously, the license API is not public interface */

	/* Post data is sent as form values with key/value pairs. */
	NSString *currentUserLanguage = [NSLocale currentLocale].localeIdentifier;

	NSString *applicationVersion = [TPCApplicationInfo applicationVersion].percentEncodedString;

	NSString *requestBodyString = nil;

	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType)
	{
		NSString *encodedContextInfo = [self encodedRequestContextValue:@"licenseKey"];

		requestBodyString = [NSString stringWithFormat:@"licenseKey=%@&lang=%@&version=%@",
				 encodedContextInfo, currentUserLanguage, applicationVersion];
	}
	else if (self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType)
	{
		NSString *encodedContextInfo = [self encodedRequestContextValue:@"licenseOwnerContactAddress"];

		requestBodyString = [NSString stringWithFormat:@"licenseOwnerContactAddress=%@&lang=%@&version=%@",
				 encodedContextInfo, currentUserLanguage, applicationVersion];
	}
	else if (self.requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType)
	{
		NSString *receiptData = [self encodedRequestContextValue:@"receiptData"];
		NSString *licenseOwnerName = [self encodedRequestContextValue:@"licenseOwnerName"];
		NSString *licenseOwnerContactAddress = [self encodedRequestContextValue:@"licenseOwnerContactAddress"];
		NSString *licenseOwnerMacAddress = [self encodedRequestContextValue:@"licenseOwnerMacAddress"];

		requestBodyString =
		[NSString stringWithFormat:@"receiptData=%@&licenseOwnerMacAddress=%@&licenseOwnerContactAddress=%@&licenseOwnerName=%@&lang=%@&version=%@",
				receiptData, licenseOwnerMacAddress, licenseOwnerContactAddress, licenseOwnerName, currentUserLanguage, applicationVersion];
	}
	else if (self.requestType == TLOLicenseManagerDownloaderRequestLicenseUpgradeEligibilityType)
	{
		NSString *encodedContextInfo = [self encodedRequestContextValue:@"licenseKey"];

		requestBodyString = [NSString stringWithFormat:@"licenseKey=%@&lang=%@&outputFormat=plist&version=%@",
				 encodedContextInfo, currentUserLanguage, applicationVersion];
	}
	else if (self.requestType == TLOLicenseManagerDownloaderRequestReceiptUpgradeEligibilityType)
	{
		NSString *receiptData = [self encodedRequestContextValue:@"receiptData"];
		NSString *licenseOwnerMacAddress = [self encodedRequestContextValue:@"licenseOwnerMacAddress"];

		requestBodyString = [NSString stringWithFormat:@"receiptData=%@&licenseOwnerMacAddress=%@&lang=%@&outputFormat=plist&version=%@",
				 receiptData, licenseOwnerMacAddress, currentUserLanguage, applicationVersion];
	}

	if (requestBodyString == nil) {
		return NO;
	}

	NSData *requestBodyData = [requestBodyString dataUsingEncoding:NSASCIIStringEncoding];

	connectionRequest.HTTPMethod = @"POST";

	[connectionRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

	connectionRequest.HTTPBody = requestBodyData;

	return YES;
}

- (void)dealloc
{
	self.delegate = nil;
}

- (void)destroyConnectionRequest
{
	if ( self.requestConnection) {
		[self.requestConnection cancel];
	}

	self.requestConnection = nil;
	self.requestResponse = nil;
	self.requestResponseData = nil;
}

- (void)cancelRequest
{
	[self destroyConnectionRequest];
}

- (BOOL)setupConnectionRequest
{
	/* Destroy any cached data that may be defined */
	[self destroyConnectionRequest];

	/* Setup request including HTTP POST data. Return NO on failure */
	NSURL *requestURL = [self requestURL];

	if (requestURL == nil) {
		return NO;
	}

	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:requestURL
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_connectionTimeoutInterval];

	if ([self populateRequestPostData:baseRequest] == NO) {
		return NO;
	}

	/* Create the connection and start it */
	self.requestResponseData = [NSMutableData data];

	self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self startImmediately:NO];

	[self.requestConnection start];

	/* Return a successful result */
	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSUInteger requestStatusCode = self.requestResponse.statusCode;

	NSData *requestContentsCopy = [self.requestResponseData copy];

	[self destroyConnectionRequest];

	if ( self.delegate) {
		[self.delegate processResponseForRequestType:self.requestType
									  httpStatusCode:requestStatusCode
											contents:requestContentsCopy];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self destroyConnectionRequest]; // Destroy the existing request

	LogToConsoleError("Failed to complete connection request with error: %{public}@", error.localizedDescription);

	if ( self.delegate) {
		[self.delegate processResponseForRequestType:self.requestType
									  httpStatusCode:TLOLicenseManagerDownloaderRequestHTTPStatusTryAgainLater
											contents:nil];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.requestResponseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response;
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end

NS_ASSUME_NONNULL_END
