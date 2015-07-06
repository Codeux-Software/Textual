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
NSString * const TLOLicenseManagerDownloaderLicenseAPIDeactivationWithTokenURL			= @"https://www.codeux.com/textual/private/fastspring/license-api/deactivateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIDeactivationWithoutTokenURL		= @"https://www.codeux.com/textual/private/fastspring/license-api/deactivateLicenseRequest.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL				= @"https://www.codeux.com/textual/private/fastspring/license-api/sendLostLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIConvertMASReceiptURL				= @"https://www.codeux.com/textual/private/fastspring/license-api/convertReceiptToLicense.cs";

/* The license API throttles requests to prevent abuse. The following HTTP status code will inform
 Textual if it the license API has been overwhelmed. */
NSInteger const TLOLicenseManagerDownloaderRequestResponseStatusSuccess = 200; // OK
NSInteger const TLOLicenseManagerDownloaderRequestResponseStatusTryAgainLater = 503; // Service Unavailable

/* Private header */
@interface TLOLicenseManagerDownloaderConnection : NSObject <NSURLConnectionDelegate>
@property (nonatomic, assign) TLOLicenseManagerDownloaderRequestType requestType; // To be set by caller
@property (nonatomic, copy) TLOLicenseManagerDownloaderCompletionBlock completionBlock; // To be set by caller
@property (nonatomic, copy) NSString *requestLicenseKey; // To be set by caller
@property (nonatomic, copy) NSString *requestContextInfo; // Additional, optional info such as activation token to be set by caller
@property (nonatomic, strong) NSMutableData *responseData; // Will be set by the object, readonly
@property (nonatomic, strong) NSURLConnection *requestConnection; // Will be set by the object, readonly
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse; // Will be set by the object, readonly

- (BOOL)setupConnectionRequest;
@end

@interface TLOLicenseManagerDownloader ()
@property (nonatomic, strong) TLOLicenseManagerDownloaderConnection *activeConnection;
@end

#define _connectionTimeoutInterval			30.0

@implementation TLOLicenseManagerDownloader

#pragma mark -
#pragma mark Public Interface

- (void)activateLicense:(NSString *)licenseKey
{
	if (PointerIsEmpty(self.activeConnection) == NO) {
		return; // An action is already active...
	}

	/* Setup connection object for activating a license key. */
	TLOLicenseManagerDownloaderConnection *connectionObject = [TLOLicenseManagerDownloaderConnection new];

	[connectionObject setRequestLicenseKey:licenseKey];

	[connectionObject setRequestType:TLOLicenseManagerDownloaderRequestActivationType];

	[connectionObject setCompletionBlock:^(id sender, TLOLicenseManagerDownloaderRequestType requestType, TLOLicenseManagerDownloaderResult requestResult, NSData *requestContents) {
		__weak TLOLicenseManagerDownloader *weakSelf = (id)self;

		if (requestResult == TLOLicenseManagerDownloaderResultSuccessful) {
			(void)TLOLicenseManagerUserLicenseWriteFileContents(requestContents);
		} else if (requestResult == TLOLicenseManagerDownloaderResultGenericError) {
			[weakSelf presentGenericErrorWithContents:requestContents];
		} else if (requestResult == TLOLicenseManagerDownloaderResultNetworkError ||
				   requestResult == TLOLicenseManagerDownloaderResultTryAgainLaterError)
		{
			[weakSelf presentFatalNetworkErrorDialog];
		}

		if ([weakSelf completionBlock]) {
			[weakSelf completionBlock](self, requestType, requestResult, requestContents);
		}

		[weakSelf setActiveConnection:nil];
	}];

	[self setActiveConnection:connectionObject];

	(void)[connectionObject setupConnectionRequest];
}

- (void)deactivateLicense:(NSString *)licenseKey withActivationToken:(NSString *)activationToken
{

}

- (void)deactivateLicenseWithoutActivationToken:(NSString *)licenseKey
{

}

- (void)requestLostLicenseKeyForContactAddress:(NSString *)contactAddress
{

}

- (void)convertMacAppStorePurcahse
{

}

- (void)presentGenericErrorWithContents:(NSData *)requestContents
{
	/* The license API returns content as property lists, including errors. This method
	 will try to convert the returned contents into an NSDictionary (assuming its a valid
	 property list). If that fails, then the method shows generic failure reason and
	 logs to the console that the contents could not parsed. */

	if (NSObjectIsEmpty(requestContents) == NO) {
		NSError *readError = nil;

		id propertyList = [NSPropertyListSerialization propertyListWithData:requestContents
																	options:NSPropertyListImmutable
																	 format:NULL
																	  error:&readError];

		if (propertyList == nil || [propertyList isKindOfClass:[NSDictionary class]] == NO) {
			if (readError) {
				LogToConsole(@"Failed to convert contents of request into dictionary. Error: %@", [readError localizedDescription]);
			}
		} else {
			NSString *errorMessage = [propertyList objectForKey:@"Error Message"];

			if (NSObjectIsEmpty(errorMessage) == NO) {
				(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1276][2]", errorMessage)
														 title:TXTLS(@"BasicLanguage[1276][1]")
												 defaultButton:TXTLS(@"BasicLanguage[1186]")
											   alternateButton:nil
												suppressionKey:nil
											   suppressionText:nil];

				return; // Cancel further action...
			}
		}
	}

	[self presentFatalNetworkErrorDialog];
}

- (void)presentFatalNetworkErrorDialog
{
	BOOL userResponse = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1275][2]")
														   title:TXTLS(@"BasicLanguage[1275][1]")
												   defaultButton:TXTLS(@"BasicLanguage[1011]")
												 alternateButton:TXTLS(@"BasicLanguage[1275][3]")
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

	switch (self.requestType) {
		case TLOLicenseManagerDownloaderRequestActivationType:
		{
			requestURLString = TLOLicenseManagerDownloaderLicenseAPIActivationURL;

			break;
		}
		case TLOLicenseManagerDownloaderRequestDeactivationWithTokenType:
		{
			requestURLString = TLOLicenseManagerDownloaderLicenseAPIDeactivationWithTokenURL;

			break;
		}
		case TLOLicenseManagerDownloaderRequestDeactivationWithoutTokenType:
		{
			requestURLString = TLOLicenseManagerDownloaderLicenseAPIDeactivationWithoutTokenURL;

			break;
		}
		case TLOLicenseManagerDownloaderRequestSendLostLicenseType:
		{
			requestURLString = TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL;

			break;
		}
		case TLOLicenseManagerDownloaderRequestConvertMASReceiptType:
		{
			requestURLString = TLOLicenseManagerDownloaderLicenseAPIConvertMASReceiptURL;

			break;
		}
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

	NSString *encodedLicenseKey = nil;

	NSString *encodedContextInfo = nil;

	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType ||
		self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithTokenType ||
		self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithoutTokenType)
	{
		encodedLicenseKey = [self.requestLicenseKey encodeURIComponent];
	}

	if (self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithTokenType ||
 		self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType ||
		self.requestType == TLOLicenseManagerDownloaderRequestConvertMASReceiptType)
	{
		encodedContextInfo = [self.requestContextInfo encodeURIComponent];
	}

	/* Post data is sent as form values with key/value pairs. */

	NSString *currentUserLanguage = [[NSLocale currentLocale] localeIdentifier];

	NSString *requestBodyString = nil;

	switch (self.requestType) {
		case TLOLicenseManagerDownloaderRequestActivationType:
		{
			requestBodyString = [NSString stringWithFormat:@"l=%@&lang=%@", encodedLicenseKey, currentUserLanguage];

			break;
		}
		case TLOLicenseManagerDownloaderRequestDeactivationWithTokenType:
		{
			requestBodyString = [NSString stringWithFormat:@"l=%@&a_t=%@&lang=%@", encodedLicenseKey, encodedContextInfo, currentUserLanguage];

			break;
		}
		case TLOLicenseManagerDownloaderRequestDeactivationWithoutTokenType:
		{
			requestBodyString = [NSString stringWithFormat:@"l=%@&lang=%@", encodedLicenseKey, currentUserLanguage];

			break;
		}
		case TLOLicenseManagerDownloaderRequestSendLostLicenseType:
		{
			requestBodyString = [NSString stringWithFormat:@"lo=%@&lang=%@", encodedContextInfo, currentUserLanguage];

			break;
		}
		case TLOLicenseManagerDownloaderRequestConvertMASReceiptType:
		{
			// Not defined, yet...

			break;
		}
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
	if (self.requestType == TLOLicenseManagerDownloaderRequestActivationType ||
		self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithTokenType ||
		self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithoutTokenType)
	{
		if (NSObjectIsEmpty(self.requestLicenseKey)) {
			return NO; // Cancel operation...
		}
	}

	if (self.requestType == TLOLicenseManagerDownloaderRequestDeactivationWithTokenType ||
		self.requestType == TLOLicenseManagerDownloaderRequestSendLostLicenseType ||
		self.requestType == TLOLicenseManagerDownloaderRequestConvertMASReceiptType)
	{
		if (NSObjectIsEmpty(self.requestContextInfo)) {
			return NO; // Cancel operation...
		}
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
	NSInteger statusCode = [self.requestResponse statusCode];

	NSData *responseDataCopy = [self.responseData copy];

	TLOLicenseManagerDownloaderResult resultType = 0;

	if (statusCode == TLOLicenseManagerDownloaderRequestResponseStatusSuccess) {
		resultType = TLOLicenseManagerDownloaderResultSuccessful;
	} else if (statusCode == TLOLicenseManagerDownloaderRequestResponseStatusTryAgainLater) {
		LogToConsole(@"License API is currently overloaded and cannot accept requests at this time.");

		resultType = TLOLicenseManagerDownloaderResultTryAgainLaterError;
	} else {
		resultType = TLOLicenseManagerDownloaderResultGenericError;
	}

	[self destroyConnectionRequest];

	if (self.completionBlock) {
		self.completionBlock(self, self.requestType, resultType, responseDataCopy);
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self destroyConnectionRequest]; // Destroy the existing request.

	LogToConsole(@"Failed to complete connection request with error: %@", [error localizedDescription]);

	if (self.completionBlock) {
		self.completionBlock(self, self.requestType, TLOLicenseManagerDownloaderResultNetworkError, nil);
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
