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

NS_ASSUME_NONNULL_BEGIN

#define _imageLoaderMaxCacheSize			10

#define _imageLoaderRequestTimeout			30

#define _imageMaximumWidth					7200

@interface TVCImageURLoader ()
@property (nonatomic, copy) NSString *requestImageUniqeId;
@property (nonatomic, copy) NSString *requestImageURL;
@property (nonatomic, copy) NSString *requestImageURLCacheToken;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@property (nonatomic, strong) NSMutableData *requestResponseData;
@property (nonatomic, assign) BOOL checkDimensionsOfImage;
@end

static NSCache *_internalCache = nil;

@implementation TVCImageURLoader

#pragma mark -
#pragma mark Public API

+ (void)load
{
	if (_internalCache == nil) {
		_internalCache = [NSCache new];
		_internalCache.countLimit = _imageLoaderMaxCacheSize;
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

	self.requestImageUniqeId = nil;

	self.requestConnection = nil;
	self.requestResponse = nil;
	self.requestResponseData = nil;
}

- (void)dealloc
{
	self.delegate = nil;
}

- (void)assesURL:(NSString *)baseURL withId:(NSString *)uniqueId
{
	NSParameterAssert(baseURL != nil);
	NSParameterAssert(uniqueId != nil);

	NSString *baseURLCacheToken = baseURL.md5;

	id cachedValue = [_internalCache objectForKey:baseURLCacheToken];

	if (cachedValue) {
		[self informDelegateWhetherImageIsSafe:[cachedValue boolValue] withUniqueId:uniqueId];

		return;
	}

	/* Reset the connection if needed. */
	[self cleanupConnectionRequest];

	self.requestImageURL = baseURL;
	self.requestImageURLCacheToken = baseURLCacheToken;

	self.requestImageUniqeId = uniqueId;

	/* Create the request */
	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseURL]
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_imageLoaderRequestTimeout];

	[baseRequest setValue:TVCLogViewCommonUserAgentString forHTTPHeaderField:@"User-Agent"];

	/* GET is used instead of HEAD because some services block the use of HEAD. */
	baseRequest.HTTPMethod = @"GET";

	/* This is stored in a local variable so that a user changing something during a 
	 load in progess, it does not message up any of the already existing requests. */
	self.checkDimensionsOfImage = ([TPCPreferences inlineImagesMaxHeight] > 0);

	if (self.checkDimensionsOfImage) {
		self.requestResponseData = [NSMutableData data];
	}

	/* Send the actual request off */
	 self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self startImmediately:NO];

	[self.requestConnection start];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)informDelegateWhetherImageIsSafe:(BOOL)isSafeToLoadImage withUniqueId:(NSString *)uniqueId
{
	NSParameterAssert(uniqueId != nil);

	if (isSafeToLoadImage)
	{
		if ([self.delegate respondsToSelector:@selector(isSafeToPresentImageWithId:)]) {
			[self.delegate isSafeToPresentImageWithId:uniqueId];
		}
	}
	else
	{
		if ([self.delegate respondsToSelector:@selector(isNotSafeToPresentImageWithId:)]) {
			[self.delegate isNotSafeToPresentImageWithId:uniqueId];
		}
	}
}

- (BOOL)headersAreValid
{
	/* Fix for very unfortunate logic oversight. Loading an image that ends up redirecting
	 to a data image will result in self.requestResponse existing as an of NSURLResponse
	 which does not have a header field resulting in crashes. Thanks to Prince32780 */
	if ([self.requestResponse isKindOfClass:[NSHTTPURLResponse class]] == NO) {
		return NO;
	}

	/* Get data from headers */
	NSDictionary *headerFields = self.requestResponse.allHeaderFields;

	TXUnsignedLongLong contentLength = [headerFields longLongForKey:@"Content-Length"];

	if (contentLength > [TPCPreferences inlineImagesMaxFilesize]) {
		return NO;
	}

	NSString *contentType = [headerFields stringForKey:@"Content-Type"];

	NSArray *validContentTypes = [TVCImageURLParser validImageContentTypes];

	if ([validContentTypes containsObject:contentType] == NO) {
		return NO;
	}

	return YES;
}

- (BOOL)imageIsValid
{
	if (self.requestResponseData == nil) {
		return NO;
	}

	CGImageSourceRef image = CGImageSourceCreateWithData((__bridge CFDataRef)self.requestResponseData, NULL);

	if (image == NULL) {
		return NO;
	}

	CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(image, 0, NULL);

	if (imageProperties == NULL) {
		CFRelease(image);

		return NO;
	}

	NSNumber *imageWidth = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
	NSNumber *imageHeight = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);

	CFRelease(image);
	CFRelease(imageProperties);

	if (imageWidth.integerValue > _imageMaximumWidth) {
		return NO;
	} else if (imageHeight.integerValue > [TPCPreferences inlineImagesMaxHeight]) {
		return NO;
	}

	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL isSafeToLoadImage = (self.requestResponse.statusCode == 200);

	if (self.checkDimensionsOfImage) {
		isSafeToLoadImage = (isSafeToLoadImage && [self imageIsValid]);
	}

	[_internalCache setObject:@(isSafeToLoadImage) forKey:self.requestImageURLCacheToken];

	[self informDelegateWhetherImageIsSafe:isSafeToLoadImage withUniqueId:self.requestImageUniqeId];

	[self cleanupConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cleanupConnectionRequest];

	LogToConsole(@"Failed to complete connection request with error: %@",
			error.localizedDescription)
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self.checkDimensionsOfImage == NO) {
		return;
	}

	[self.requestResponseData appendData:data];

	/* If the Content-Length header was not available, then we
	 still go ahead and check the downloaded data length here. */
	if (self.requestResponseData.length > [TPCPreferences inlineImagesMaxFilesize]) {
		LogToConsole(@"Inline image exceeds maximum file length")
		
		[self cleanupConnectionRequest];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response;

	if ([self headersAreValid] == NO) {
		[self cleanupConnectionRequest];

		return;
	}

	if (self.checkDimensionsOfImage == NO) {
		/* If we do not care about the height, then we are going
		 to fake a successful download at this point so that we
		 can post the image without waiting for the entire thing
		 to download and waste bandwidth. */

		[self connectionDidFinishLoading:nil];
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache */
}

@end

NS_ASSUME_NONNULL_END
