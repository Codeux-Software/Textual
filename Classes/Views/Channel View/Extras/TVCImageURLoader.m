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

#import "TextualApplication.h"

#define _imageLoaderMaxCacheSize			10

#define _imageLoaderMaxRequestTime			30

#define _imageMaximumImageWidth				7200

@interface TVCImageURLoader ()
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, copy) NSString *requestImageUniqeID;
@property (nonatomic, copy) NSString *requestImageURL;
@property (nonatomic, copy) NSString *requestImageURLCacheToken;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@property (nonatomic, assign) BOOL isInRequestWithCheckForMaximumHeight;
@end

static NSCache *_internalCache = nil;

@implementation TVCImageURLoader

#pragma mark -
#pragma mark Public API

+ (void)load
{
	if (_internalCache == nil) {
		_internalCache = [NSCache new];

		[_internalCache setCountLimit:_imageLoaderMaxCacheSize];
	}
}

+ (void)invalidateInternalCache
{
	[_internalCache removeAllObjects];
}

- (void)cleanupConnectionRequest
{
	if ( self.requestConnection) {
		[self.requestConnection cancel];
	}

	self.requestImageURL = nil;
	self.requestImageURLCacheToken = nil;

	self.requestImageUniqeID = nil;
	self.requestConnection = nil;
	self.requestResponse = nil;

	self.responseData = nil;
}

- (void)dealloc
{
	self.delegate = nil;
}

- (void)assesURL:(NSString *)baseURL withID:(NSString *)uniqueID
{
	NSObjectIsEmptyAssert(baseURL);
	NSObjectIsEmptyAssert(uniqueID);

	/* Determine whether this URL has already been cached. If so, inform
	 the callback of the cached value for the URL. */
	NSString *baseURLCacheToken = [baseURL md5];

	id cachedValue = [_internalCache objectForKey:baseURLCacheToken];

	if (cachedValue) {
		[self informDelegateWhetherImageIsSafe:[cachedValue boolValue] withUniqueID:uniqueID];

		return;
	}

	/* Reset the connection if needed. */
	[self cleanupConnectionRequest];

	self.requestImageURL = baseURL;
	self.requestImageURLCacheToken = baseURLCacheToken;

	self.requestImageUniqeID = uniqueID;

	/* Create the request. */
	/* We use a mutable request because we are going to set the HTTP method. */
	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseURL]
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_imageLoaderMaxRequestTime];

	[baseRequest setValue:TVCLogViewCommonUserAgentString forHTTPHeaderField:@"User-Agent"];

	/* This is stored in a local variable so that a user changing something during a load in
	 progess, it does not fuck up any of the already existing requests. */
		self.isInRequestWithCheckForMaximumHeight = ([TPCPreferences inlineImagesMaxHeight] > 0);

	if (self.isInRequestWithCheckForMaximumHeight) {
		self.responseData = [NSMutableData data];
	}

	[baseRequest setHTTPMethod:@"GET"];

	/* Send the actual request off. */
	 self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self startImmediately:NO];

	[self.requestConnection start];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)informDelegateWhetherImageIsSafe:(BOOL)isSafeToLoadImage withUniqueID:(NSString *)uniqueID
{
	if (isSafeToLoadImage) {
		if ([self.delegate respondsToSelector:@selector(isSafeToPresentImageWithID:)]) {
			[self.delegate isSafeToPresentImageWithID:uniqueID];
		}
	} else {
		if ([self.delegate respondsToSelector:@selector(isNotSafeToPresentImageWithID:)]) {
			[self.delegate isNotSafeToPresentImageWithID:uniqueID];
		}
	}
}

- (BOOL)continueWithImageProcessing
{
	/* Get data from headers. */
	NSDictionary *headers = [self.requestResponse allHeaderFields];

	TXUnsignedLongLong sizeInBytes = [headers longLongForKey:@"Content-Length"];

	NSString *imageContentType = [headers stringForKey:@"Content-Type"];

	/* Check size. */
	if (sizeInBytes > [TPCPreferences inlineImagesMaxFilesize]) {
		return NO;
	}

	/* Check type. */
	NSArray *validContentTypes = [TVCImageURLParser validImageContentTypes];

	if ([validContentTypes containsObject:imageContentType] == NO) {
		return NO;
	}

	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL isSafeToLoadImage = NO;

	BOOL isValidResponse = ([self.requestResponse statusCode] == 200);

    if (isValidResponse) {
		if (self.isInRequestWithCheckForMaximumHeight) {
			if (self.responseData == nil) {
				goto destroy_connection;
			}
			
			CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.responseData, NULL);
			
			if (PointerIsEmpty(imageSource)) {
				goto destroy_connection;
			}
			
			CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
		
			if (PointerIsEmpty(properties)) {
				CFRelease(imageSource);

				goto destroy_connection;
			}

			NSNumber *width = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
			NSNumber *height = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);

			CFRelease(imageSource);
			CFRelease(properties);

			if ([height integerValue] <= [TPCPreferences inlineImagesMaxHeight] && [width integerValue] <= _imageMaximumImageWidth) {
				isSafeToLoadImage = YES;
			}
		} else {
			isSafeToLoadImage = YES;
		}
	}

destroy_connection:
	[_internalCache setObject:@(isSafeToLoadImage) forKey:self.requestImageURLCacheToken];

	[self informDelegateWhetherImageIsSafe:isSafeToLoadImage withUniqueID:self.requestImageUniqeID];

	[self cleanupConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cleanupConnectionRequest];

	LogToConsole(@"Failed to complete connection request with error: %@", [error localizedDescription]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self.isInRequestWithCheckForMaximumHeight) {
		[self.responseData appendData:data];

		/* If the Content-Length header was not available, then we
		 still go ahead and check the downloaded data length here. */
		if ([self.responseData length] > [TPCPreferences inlineImagesMaxFilesize]) {
			LogToConsole(@"Inline image exceeds maximum file length.");
			
			[self cleanupConnectionRequest];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response;

	if ([self continueWithImageProcessing] == NO) {
		[self cleanupConnectionRequest];
	} else {
		if (self.isInRequestWithCheckForMaximumHeight == NO) {
			/* If we do not care about the height, then we are going
			 to fake a successful download at this point so that we
			 can post the image without waiting for the entire thing
			 to download and waste bandwidth. */

			[self connectionDidFinishLoading:nil];
		}
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache. */
}

@end
