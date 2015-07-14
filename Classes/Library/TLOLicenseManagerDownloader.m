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

#import "TLOLicenseManagerDownloader.h"

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1

/* URLs for performing certain actions with license keys. */
NSString * const TLOLicenseManagerDownloaderLicenseAPIActivationURL						= @"https://www.codeux.com/textual/private/fastspring/license-api/activateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL				= @"https://www.codeux.com/textual/private/fastspring/license-api/sendLostLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIConvertMASReceiptURL				= @"https://www.codeux.com/textual/private/fastspring/license-api/convertReceiptToLicense.cs";

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
@property (nonatomic, copy) NSString *requestContextInfo; // Information set by caller such as license key or e-mail address
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
	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestActivationType context:licenseKey];
}

- (void)deactivateLicense
{

}

- (void)requestLostLicenseKeyForContactAddress:(NSString *)contactAddress
{
	[self setupNewActionWithRequestType:TLOLicenseManagerDownloaderRequestSendLostLicenseType context:contactAddress];
}

- (void)convertMacAppStorePurcahse
{

}

- (void)setupNewActionWithRequestType:(TLOLicenseManagerDownloaderRequestType)requestType context:(NSString *)requestContext
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

#define _performCompletionBlockAndReturn()					if (self.completionBlock) {				\
																self.completionBlock();				\
															}										\
																									\
															return;

	/* Attempt to convert contents into a property list dictionary */
	NSError *readError = nil;

	id propertyList = [NSPropertyListSerialization propertyListWithData:requestContents
																options:NSPropertyListImmutable
																 format:NULL
																  error:&readError];

	if (propertyList == nil || [propertyList isKindOfClass:[NSDictionary class]] == NO) {
		if (readError) {
			LogToConsole(@"Failed to convert contents of request into dictionary. Error: %@", [readError localizedDescription]);
		}
	}

	/* Process resulting property list (if it was successful) */
	if (propertyList) {
		id statusCode = [propertyList objectForKey:@"Status Code"];

		id statusContext = [propertyList objectForKey:@"Status Context"];

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

				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1006][2]")
														 title:TXTLS(@"TLOLicenseManager[1006][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn()
			}
			else if (requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' is nil or not of kind 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseOwnerContactAddress = [statusContext objectForKey:@"licenseOwnerContactAddress"];

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
				
				_performCompletionBlockAndReturn()
			}
		}
		else // TLOLicenseManagerDownloaderRequestStatusCodeSuccess
		{
			/* Handle failrue status codes */
			if (statusCodeInt == 6500000)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1004][2]")
														 title:TXTLS(@"TLOLicenseManager[1004][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn()
			}
			else if (statusCodeInt == 6500001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *licenseKey = [statusContext objectForKey:@"licenseKey"];

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

				_performCompletionBlockAndReturn()
			}
			else if (statusCodeInt == 6400000)
			{
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1003][2]")
														 title:TXTLS(@"TLOLicenseManager[1003][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn()
			}
			else if (statusCodeInt == 6400001)
			{
				if (statusContext == nil || [statusContext isKindOfClass:[NSDictionary class]] == NO) {
					LogToConsole(@"'Status Context' kind is not of 'NSDictionary'");

					goto present_fatal_error;
				}

				NSString *originalInput = [statusContext objectForKey:@"originalInput"];

				if (NSObjectIsEmpty(originalInput)) {
					LogToConsole(@"'originalInput' is nil or of zero length");

					goto present_fatal_error;
				}

				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1007][2]", originalInput)
														 title:TXTLS(@"TLOLicenseManager[1007][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1011]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				_performCompletionBlockAndReturn()
			}
		}
	}

present_fatal_error:
	[self presentTryAgainLaterErrorDialog];

	_performCompletionBlockAndReturn()
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
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestConvertMASReceiptType) {
		requestURLString = TLOLicenseManagerDownloaderLicenseAPIConvertMASReceiptURL;
	}

	if (requestURLString) {
		return [NSURL URLWithString:requestURLString];
	} else {
		return nil;
	}
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
	NSString *encodedContextInfo = [self.requestContextInfo encodeURIComponent];

	NSString *currentUserLanguage = [[NSLocale currentLocale] localeIdentifier];

	NSString *requestBodyString = nil;

	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType) {
		requestBodyString = [NSString stringWithFormat:@"l=%@&lang=%@", encodedContextInfo, currentUserLanguage];
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType) {
		requestBodyString = [NSString stringWithFormat:@"lo=%@&lang=%@", encodedContextInfo, currentUserLanguage];
	} else if (self.requestType == TLOLicenseManagerDownloaderRequestConvertMASReceiptType) {
		;
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
	/* Validate object configuration */
	if (NSObjectIsEmpty(self.requestContextInfo)) {
		return NO; // Cancel operation...
	}

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
