/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

#import "ICMInlineImageCheck.h"

NS_ASSUME_NONNULL_BEGIN

#define _imageLoaderMaxCacheSize			10
#define _imageLoaderRequestTimeout			30

#define _imageMaximumWidth					7200

@interface ICMInlineImageCheckRequest : NSObject
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong, nullable) NSMutableData *responseData;
@end

@interface ICMInlineImageCheckState : NSObject
@property (nonatomic, copy) ICMInlineImageCheckCompletionBlock completionBlock;
@property (nonatomic, copy) NSString *cacheToken;
@property (nonatomic, assign) BOOL checkDimensions;
@property (nonatomic, assign) NSUInteger maximumHeight;
@property (nonatomic, assign) TXUnsignedLongLong maximumFilesize;
@property (nonatomic, copy, nullable) NSString *imageType; // set by connection response
@end

@interface ICMInlineImageCheck ()
@property (nonatomic, strong) ICMInlineImageCheckRequest *request;
@property (nonatomic, strong) ICMInlineImageCheckState *state;
@end

static NSCache<NSString *, NSDictionary<NSString *, id> *> *_internalCache = nil;

@implementation ICMInlineImageCheck

#pragma mark -
#pragma mark State

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
	NSURLConnection *connection = self.request.connection;

	if (connection) {
		[connection cancel];
	}

	self.request = nil;
	self.state = nil;
}

#pragma mark -
#pragma mark Public API

- (void)checkAddress:(NSString *)address completionBlock:(ICMInlineImageCheckCompletionBlock)completionBlock
{
	NSParameterAssert(address != nil);
	NSParameterAssert(completionBlock != nil);

	/* Does this URL already have a cached response? */
	NSString *cacheToken = address.md5;

	NSDictionary<NSString *, id> *cachedResponse = [_internalCache objectForKey:cacheToken];

	if (cachedResponse) {
		BOOL safeToLoad = [cachedResponse boolForKey:@"safeToLoad"];

		NSString *imageOfType = [cachedResponse stringForKey:@"imageOfType"];

		completionBlock(safeToLoad, imageOfType);

		return;
	}

	/* Bind state */
	self.request = [ICMInlineImageCheckRequest new];
	self.state = [ICMInlineImageCheckState new];

	self.state.cacheToken = cacheToken;

	self.state.completionBlock = completionBlock;

	/* Create the request */
	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:address]
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_imageLoaderRequestTimeout];

	/* GET is used instead of HEAD because some services block the use of HEAD. */
	baseRequest.HTTPMethod = @"GET";

	/* This is stored in a local variable so that a user changing something during a
	 load in progess, it does not mess up any of the already existing requests. */
	self.state.maximumHeight = [TPCPreferences inlineMediaMaxHeight];
	self.state.maximumFilesize = [TPCPreferences inlineImagesMaxFilesize];

	BOOL checkDimensions = (self.state.maximumHeight > 0);

	self.state.checkDimensions = checkDimensions;

	if (checkDimensions) {
		self.request.responseData = [NSMutableData data];
	}

	/* Send the request */
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self startImmediately:NO];

	self.request.connection = connection;

	/* It is import to set the delegate queue because this may be
	 started on a temporary thread spawned by an incoming XPC message. */
	[connection setDelegateQueue:[NSOperationQueue mainQueue]];

	[connection start];
}

#pragma mark -
#pragma mark Utilities

- (void)informDelegateWhetherImageOfType:(nullable NSString *)imageOfType safeToLoad:(BOOL)safeToLoad
{
	NSMutableDictionary *cachedValue = [NSMutableDictionary dictionaryWithCapacity:2];
	[cachedValue setBool:safeToLoad forKey:@"safeToLoad"];
	[cachedValue maybeSetObject:imageOfType forKey:@"imageOfType"];
	[_internalCache setObject:[cachedValue copy] forKey:self.state.cacheToken];

	self.state.completionBlock(safeToLoad, imageOfType);
}

- (BOOL)headersAreValid
{
	/* Fix for very unfortunate logic oversight. Loading an image that ends up redirecting
	 to a data image will result in self.requestResponse existing as an of NSURLResponse
	 which does not have a header field resulting in crashes. Thanks to Prince32780 */
	NSHTTPURLResponse *requestResponse = self.request.response;

	if ([requestResponse isKindOfClass:[NSHTTPURLResponse class]] == NO) {
		return NO;
	}

	/* Get data from headers */
	NSDictionary *headerFields = requestResponse.allHeaderFields;

	TXUnsignedLongLong contentLength = [headerFields longLongForKey:@"Content-Length"];

	if (contentLength > self.state.maximumFilesize) {
		return NO;
	}

	NSString *contentType = [headerFields stringForKey:@"Content-Type"];

	NSArray *validContentTypes = [ICMInlineImage validImageContentTypes];

	if ([validContentTypes containsObject:contentType] == NO) {
		return NO;
	}

	self.state.imageType = contentType;

	return YES;
}

- (BOOL)imageIsValid
{
	NSMutableData *responseData = self.request.responseData;

	if (responseData == nil) {
		return NO;
	}

	CGImageSourceRef image = CGImageSourceCreateWithData((__bridge CFDataRef)responseData, NULL);

	if (image == NULL) {
		LogToConsoleDebug("Image is not valid because CGImageSourceCreateWithData() returned NULL");

		return NO;
	}

	CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(image, 0, NULL);

	if (imageProperties == NULL) {
		LogToConsoleDebug("Image is not valid because CGImageSourceCopyPropertiesAtIndex() returned NULL");

		CFRelease(image);

		return NO;
	}

	NSNumber *imageWidth = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
	NSNumber *imageHeight = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);

	CFRelease(image);
	CFRelease(imageProperties);

	if (imageWidth.integerValue > _imageMaximumWidth) {
		LogToConsoleDebug("Image is not valid because its width exceeds the maximum");

		return NO;
	} else if (imageHeight.integerValue > self.state.maximumHeight) {
		LogToConsoleDebug("Image is not valid because its height exceeds the maximum");

		return NO;
	}

	return YES;
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL safeToLoad = (self.request.response.statusCode == 200);

	if (self.state.checkDimensions) {
		safeToLoad = (safeToLoad && [self imageIsValid]);
	}

	NSString *imageType = self.state.imageType;

	[self informDelegateWhetherImageOfType:imageType safeToLoad:safeToLoad];

	[self cleanupConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cleanupConnectionRequest];

	LogToConsoleError("Failed to complete connection request with error: %@",
		error.localizedDescription);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSMutableData *responseData = self.request.responseData;

	if (responseData == nil) {
		return;
	}

	[responseData appendData:data];

	/* If the Content-Length header was not available, then we
	 still go ahead and check the downloaded data length here. */
	if (responseData.length > self.state.maximumFilesize) {
		LogToConsoleInfo("Image is not valid because its size exceeds the maximum");

		[self cleanupConnectionRequest];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.request.response = (id)response;

	if ([self headersAreValid] == NO) {
		[self cleanupConnectionRequest];

		return;
	}

	if (self.state.checkDimensions == NO) {
		/* If we do not care about the height, then we are going
		 to fake a successful download at this point so that we
		 can post the image without waiting for the entire thing
		 to download and waste bandwidth. */

		[self connectionDidFinishLoading:nil];
	}
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache */
}

@end

#pragma mark -

@implementation ICMInlineImageCheckRequest
@end

@implementation ICMInlineImageCheckState
@end

NS_ASSUME_NONNULL_END
