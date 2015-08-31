/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TLOLicenseManager.h"
#import "TLOLicenseManagerDownloader.h"

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1

/* URLs for performing certain actions with license keys. */
NSString * const TLOLicenseManagerDownloaderLicenseAPIActivationURL						= @"https://www.codeux.com/textual/private/fastspring/textual5-license-API/activateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL				= @"https://www.codeux.com/textual/private/fastspring/textual5-license-API/sendLostLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIMigrateAppStoreURL				= @"https://www.codeux.com/textual/private/fastspring/textual5-license-API/convertReceiptToLicense.cs";

/* The license API throttles requests to prevent abuse. The following HTTP status 
 code will inform Textual if it the license API has been overwhelmed. */
NSInteger const TLOLicenseManagerDownloaderRequestHTTPStatusSuccess = 200; // OK
NSInteger const TLOLicenseManagerDownloaderRequestHTTPStatusTryAgainLater = 503; // Service Unavailable

/* The following constants note status codes that may be returned part of the 
 contents of a license API response body. This is not a complete list. */
NSInteger const TLOLicenseManagerDownloaderRequestStatusCodeSuccess = 0;

NSInteger const TLOLicenseManagerDownloaderRequestStatusCodeGenericError = 1000000;
NSInteger const TLOLicenseManagerDownloaderRequestStatusCodeTryAgainLater = 1000001;

/* Private header */
@interface TLOLicenseManagerDownloaderConnection : NSObject <NSURLConnectionDelegate>
@property (nonatomic, strong) TLOLicenseManagerDownloader *delegate; // To be set by caller
@property (nonatomic, assign) TLOLicenseManagerDownloaderRequestType requestType; // To be set by caller
@property (nonatomic, copy) NSDictionary *requestContextInfo; // Information set by caller such as license key or e-mail address
@property (nonatomic, strong) NSMutableData *responseData; // Will be set by the object, readonly
@property (nonatomic, strong) NSURLConnection *requestConnection; // Will be set by the object, readonly
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse; // Will be set by the object, readonly

- (BOOL)setupConnectionRequest;
@end

@interface TLOLicenseManagerDownloader ()
@property (nonatomic, strong) TLOLicenseManagerDownloaderConnection *activeConnection;

- (void)processResponseForRequestType:(TLOLicenseManagerDownloaderRequestType)requestType httpStatusCode:(NSInteger)requestHttpStatusCode contents:(NSData *)requestContents;
@end

static BOOL TLOLicenseManagerDownloaderConnectionSelected = NO;

#define _connectionTimeoutInterval			30.0

@implementation TLOLicenseManagerDownloader

#pragma mark -
#pragma mark Public Interface

- (void)activateLicense:(NSString *)licenseKey
{
	if (NSObjectIsEmpty(licenseKey)) {
		return; // Cancel operation...
	}

	NSDictionary *contextInfo = @{@"licenseKey" : licenseKey};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestActivationType context:contextInfo];
}

- (void)deactivateLicense
{
	BOOL operationResult = TLOLicenseManagerDeleteUserLicenseFile();

	if (self.completionBlock) {
		self.completionBlock(operationResult);
	}
}

- (void)requestLostLicenseKeyForContactAddress:(NSString *)contactAddress
{
	if (NSObjectIsEmpty(contactAddress)) {
		return; // Cancel operation...
	}

	NSDictionary *contextInfo = @{@"licenseOwnerContactAddress" : contactAddress};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestSendLostLicenseType context:contextInfo];
}

- (void)migrateMacAppStorePurcahse:(NSString *)receiptData licenseOwnerName:(NSString *)licenseOwnerName licenseOwnerContactAddress:(NSString *)licenseOwnerContactAddress
{
	NSString *macAddress = [XRSystemInformation formattedEthernetMacAddress];

	if (NSObjectIsEmpty(receiptData) ||
		NSObjectIsEmpty(licenseOwnerName) ||
		NSObjectIsEmpty(licenseOwnerContactAddress) ||
		NSObjectIsEmpty(macAddress))
	{
		return; // Cancel operation...
	}

	NSDictionary *contextInfo = @{
		@"receiptData" : receiptData,
		@"licenseOwnerMacAddress" : macAddress,
		@"licenseOwnerName"	: licenseOwnerName,
		@"licenseOwnerContactAddress" : licenseOwnerContactAddress
	};

	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestMigrateAppStoreType context:contextInfo];
}

- (void)setupNewActionWithRequestType:(TLOLicenseManagerDownloaderRequestType)requestType context:(NSDictionary *)requestContext
{
	if (TLOLicenseManagerDownloaderConnectionSelected == NO) {
		TLOLicenseManagerDownloaderConnectionSelected = YES;

		TLOLicenseManagerDownloaderConnection *connectionObject = [TLOLicenseManagerDownloaderConnection new];

		[connectionObject setRequestContextInfo:requestContext];

		[connectionObject setRequestType:requestType];

		[connectionObject setDelegate:self];

		[self setActiveConnection:connectionObject];

		(void)[connectionObject setupConnectionRequest];
	}
}

- (void)processResponseForRequestType:(TLOLicenseManagerDownloaderRequestType)requestType httpStatusCode:(NSInteger)requestHttpStatusCode contents:(NSData *)requestContents
{
	/* The license API returns content as property lists, including errors. This method
	 will try to convert the returned contents into an NSDictionary (assuming its a valid
	 property list). If that fails, then the method shows generic failure reason and
	 logs to the console that the contents could not parsed. */

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self setActiveConnection:nil];
	});

	TLOLicenseManagerDownloaderConnectionSelected = NO;

#define _performCompletionBlockAndReturn(operationResult)				if (self.completionBlock) {								\
																			self.completionBlock((operationResult));			\
																		}														\
																																\
																		return;

	/* Attempt to convert contents into a property list dictionary */
	id propertyList = nil;

	if (NSDissimilarObjects(requestContents, nil)) {
		NSError *readError = nil;

		propertyList = [NSPropertyListSerialization propertyListWithData:requestContents
																 options:NSPropertyListImmutable
																  format:NULL
																   error:&readError];

		if (propertyList == nil || [propertyList isKindOfClass:[NSDictionary class]] == NO) {
			if (readError) {
				LogToConsole(@"Failed to convert contents of request into dictionary. Error: %@", [readError localizedDescription]);
			}
		}
	}

	/* Process resulting property list (if it was successful) */
	if (propertyList) {
		id statusCode = propertyList[@"Status Code"];

		id statusContext = propertyList[@"Status Context"];

		if (statusCode == nil || [statusCode isKindOfClass:[NSNumber class]] == NO) {
			LogToConsole(@"'Status Code' is nil or not of kind 'NSNumber'");

			goto present_fatal_error;
		}

		NSInteger statusCodeInt = [statusCode integerValue];

		if (requestHttpStatusCode == TLOLicenseManagerDownloaderRequestHTTPStatusSuccess && statusCodeInt == TLOLicenseManagerDownloaderRequestStatusCodeSuccess)
		{
			/* Process successful results */
			if (requestType == TLOLicenseManagerDownloaderRequestActivationType)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSData class]] == NO) {
					LogToConsole(@"'Status Context' is nil or not of kind 'NSData'");

					goto present_fatal_error;
				}

				if (TLOLicenseManagerUserLicenseWriteFileContents(statusContext) == NO) {
					LogToConsole(@"Failed to write user license file contents");

					goto present_fatal_error;
				}

				if (self.isSilentOnSuccess == NO) {
					(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1006][2]")
															 title:TXTLS(@"TLOLicenseManager[1006][1]")
													 defaultButton:TXTLS(@"BasicLanguage[1011]")
												   alternateButton:nil
													suppressionKey:nil
												   suppressionText:nil];
				}

				_performCompletionBlockAndReturn(YES)
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType)
			{
				if (self.isSilentOnSuccess == NO) {
					if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
						LogToConsole(@"'Status Context' is nil or not of kind 'NSDictionary'");

						goto present_fatal_error;
					}

					NSString *licenseOwnerContactAddress = statusContext[@"licenseOwnerContactAddress"];

					if (NSObjectIsEmpty(licenseOwnerContactAddress)) {
						LogToConsole(@"'licenseOwnerContactAddress' is nil or of zero length");

						goto present_fatal_error;
					}

					(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1005][2]", licenseOwnerContactAddress)
															 title:TXTLS(@"TLOLicenseManager[1005][1]", licenseOwnerContactAddress)
													 defaultButton:TXTLS(@"BasicLanguage[1011]")
												   alternateButton:nil
													suppressionKey:nil
												   suppressionText:nil];
				}
				
				_performCompletionBlockAndReturn(YES)
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType)
			{
				if (self.isSilentOnSuccess == NO) {
					if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
						LogToConsole(@"'Status Context' is nil or not of kind 'NSDictionary'");

						goto present_fatal_error;
					}

					NSString *licenseOwnerContactAddress = statusContext[@"licenseOwnerContactAddress"];

					if (NSObjectIsEmpty(licenseOwnerContactAddress)) {
						LogToConsole(@"'licenseOwnerContactAddress' is nil or of zero length");

						goto present_fatal_error;
					}

					(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1010][2]", licenseOwnerContactAddress)
															 title:TXTLS(@"TLOLicenseManager[1010][1]", licenseOwnerContactAddress)
													 defaultButton:TXTLS(@"BasicLanguage[1011]")
												   alternateButton:nil
													suppressionKey:nil
												   suppressionText:nil];
				}

				_performCompletionBlockAndReturn(YES)
			}
		}
		else // TLOLicenseManagerDownloaderRequestStatusCodeSuccess
		{
			/* Errors related to license activation. */
			if (statusCodeInt == 6500000)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1004][2]")
														 title:TXTLS(@"TLOLicenseManager[1004][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}
			else if (statusCodeInt == 6500001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseKey = statusContext[@"licenseKey"];

				if (NSObjectIsEmpty(licenseKey)) {
					LogToConsole(@"'licenseKey' is nil or of zero length");

					goto present_fatal_error;
				}

				BOOL userResponse = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1002][2]")
																	   title:TXTLS(@"TLOLicenseManager[1002][1]", licenseKey)
															   defaultButton:TXTLS(@"BasicLanguage[1011]")
															 alternateButton:TXTLS(@"TLOLicenseManager[1002][3]")
															  suppressionKey:nil
															 suppressionText:nil];

				if (userResponse == NO) { // NO = alternate button
					[self contactSupport];
				}

				_performCompletionBlockAndReturn(NO)
			}
			else if (statusCodeInt == 6500002)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseKey = statusContext[@"licenseKey"];

				if (NSObjectIsEmpty(licenseKey)) {
					LogToConsole(@"'licenseKey' is nil or of zero length");

					goto present_fatal_error;
				}

				NSInteger licenseKeyActivationLimit = [statusContext integerForKey:@"licenseKeyActivationLimit"];

				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1014][2]", licenseKeyActivationLimit)
														 title:TXTLS(@"TLOLicenseManager[1014][1]", licenseKey)
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}

			/* Errors related to lost license recovery. */
			else if (statusCodeInt == 6400000)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1003][2]")
														 title:TXTLS(@"TLOLicenseManager[1003][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}
			else if (statusCodeInt == 6400001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *originalInput = statusContext[@"originalInput"];

				if (NSObjectIsEmpty(originalInput)) {
					LogToConsole(@"'originalInput' is nil or of zero length");

					goto present_fatal_error;
				}

				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1013][2]", originalInput)
														 title:TXTLS(@"TLOLicenseManager[1013][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}

			/* Error messages related to Mac App Store migration. */
			else if (statusCodeInt == 6600002)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1012][2]")
														 title:TXTLS(@"TLOLicenseManager[1012][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}
			else if (statusCodeInt == 6600003)
			{
				/* We do not present a custom dialog for this error, but we still log
				 the contents of the context to the console to help diagnose issues. */
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *errorMessage = statusContext[@"Error Message"];

				if (NSObjectIsEmpty(errorMessage)) {
					LogToConsole(@"'errorMessage' is nil or of zero length");

					goto present_fatal_error;
				}

				LogToConsole(@"Receipt validation failed:\n%@", errorMessage);
			}
			else if (statusCodeInt == 6600004)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1011][2]")
														 title:TXTLS(@"TLOLicenseManager[1011][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn(NO)
			}
		}
	}

present_fatal_error:
	[self presentTryAgainLaterErrorDialog];

	_performCompletionBlockAndReturn(NO)

#undef _performCompletionBlockAndReturn
}

- (void)presentTryAgainLaterErrorDialog
{
	BOOL userResponse = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1001][2]")
														   title:TXTLS(@"TLOLicenseManager[1001][1]")
												   defaultButton:TXTLS(@"BasicLanguage[1011]")
												 alternateButton:TXTLS(@"TLOLicenseManager[1001][3]")
												  suppressionKey:nil
												 suppressionText:nil];

	if (userResponse == NO) { // NO = alternate button
		[self contactSupport];
	}
}

- (void)contactSupport
{
	[TLOpenLink openWithString:@"mailto:support@codeux.com"];
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
	}

	if (requestURLString) {
		return [NSURL URLWithString:requestURLString];
	} else {
		return nil;
	}
}

- (NSString *)encodedRequestContextValue:(NSString *)contextKey
{
	return [self.requestContextInfo[contextKey] encodeURIComponent];
}

- (BOOL)populateRequestPostData:(NSMutableURLRequest *)connectionRequest
{
	/* Post paramater(s) defined by this method are subjec to change at
	 any time because obviously, the license API is not public interface */

	/* Perform basic validation on our host object. */
	if (connectionRequest == nil) {
		return NO; // Cancel operation...
	}

	/* Post data is sent as form values with key/value pairs. */
	NSString *currentUserLanguage = [[NSLocale currentLocale] localeIdentifier];

	NSString *requestBodyString = nil;

	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType) {
		NSString *encodedContextInfo = [self encodedRequestContextValue:@"licenseKey"];

		requestBodyString = [NSString stringWithFormat:@"licenseKey=%@&lang=%@", encodedContextInfo, currentUserLanguage];
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType) {
		NSString *encodedContextInfo = [self encodedRequestContextValue:@"licenseOwnerContactAddress"];

		requestBodyString = [NSString stringWithFormat:@"licenseOwnerContactAddress=%@&lang=%@", encodedContextInfo, currentUserLanguage];
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestMigrateAppStoreType) {
		NSString *receiptData = [self encodedRequestContextValue:@"receiptData"];

		NSString *licenseOwnerName = [self encodedRequestContextValue:@"licenseOwnerName"];

		NSString *licenseOwnerContactAddress = [self encodedRequestContextValue:@"licenseOwnerContactAddress"];

		NSString *licenseOwnerMacAddress = [self encodedRequestContextValue:@"licenseOwnerMacAddress"];

		requestBodyString = [NSString stringWithFormat:@"receiptData=%@&licenseOwnerMacAddress=%@&licenseOwnerContactAddress=%@&licenseOwnerName=%@&lang=%@",
							 receiptData, licenseOwnerMacAddress, licenseOwnerContactAddress, licenseOwnerName, currentUserLanguage];
	}

	if (requestBodyString) {
		NSData *requestBodyData = [requestBodyString dataUsingEncoding:NSASCIIStringEncoding];

		[connectionRequest setHTTPMethod:@"POST"];

		[connectionRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

		[connectionRequest setHTTPBody:requestBodyData];

		return YES;
	} else {
		return NO;
	}
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

	self.responseData = nil;
}

- (BOOL)setupConnectionRequest
{
	/* Destroy any cached data that may be defined. */
	[self destroyConnectionRequest];

	/* Setup request including HTTP POST data. Return NO on failure. */
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

	/* Create the connection and start it. */
	self.responseData = [NSMutableData data];

	 self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];

	[self.requestConnection start];

	/* Return a successful result */
	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSInteger requestStatusCode = [self.requestResponse statusCode];

	NSData *requestContentsCopy = [self.responseData copy];

	[self destroyConnectionRequest];

	if ( self.delegate) {
		[self.delegate processResponseForRequestType:self.requestType httpStatusCode:requestStatusCode contents:requestContentsCopy];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self destroyConnectionRequest]; // Destroy the existing request.

	LogToConsole(@"Failed to complete connection request with error: %@", [error localizedDescription]);

	if ( self.delegate) {
		[self.delegate processResponseForRequestType:self.requestType httpStatusCode:TLOLicenseManagerDownloaderRequestHTTPStatusTryAgainLater contents:nil];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end

#endif
