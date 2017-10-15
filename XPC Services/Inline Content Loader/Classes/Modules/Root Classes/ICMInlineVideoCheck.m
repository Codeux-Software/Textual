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

/* A lot of services block HEAD requests.
 Because of this, we perform GET, then break the connection once
 the headers are received. That's why images and video checks use
 NSURLConnection requests with a delegate. */

#import "ICMInlineVideoCheck.h"

NS_ASSUME_NONNULL_BEGIN

#define _videoLoaderMaxCacheSize			10
#define _videoLoaderRequestTimeout			30

@interface ICMInlineVideoCheckRequest : NSObject
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@end

@interface ICMInlineVideoCheckState : NSObject
@property (nonatomic, copy) ICMInlineVideoCheckCompletionBlock completionBlock;
@property (nonatomic, copy) NSString *cacheToken;
@property (nonatomic, copy, nullable) NSString *videoType; // set by connection response
@end

@interface ICMInlineVideoCheck ()
@property (nonatomic, strong) ICMInlineVideoCheckRequest *request;
@property (nonatomic, strong) ICMInlineVideoCheckState *state;
@property (readonly) BOOL headersAreValid;
@end

static NSCache<NSString *, NSDictionary<NSString *, id> *> *_internalCache = nil;

@implementation ICMInlineVideoCheck

#pragma mark -
#pragma mark State

+ (void)load
{
	if (_internalCache == nil) {
		_internalCache = [NSCache new];
		_internalCache.countLimit = _videoLoaderMaxCacheSize;
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

- (void)checkAddress:(NSString *)address completionBlock:(ICMInlineVideoCheckCompletionBlock)completionBlock
{
	NSParameterAssert(address != nil);
	NSParameterAssert(completionBlock != nil);

	/* Does this URL already have a cached response? */
	NSString *cacheToken = address.md5;

	NSDictionary<NSString *, id> *cachedResponse = [_internalCache objectForKey:cacheToken];

	if (cachedResponse) {
		BOOL safeToLoad = [cachedResponse boolForKey:@"safeToLoad"];

		NSString *videoOfType = [cachedResponse stringForKey:@"videoOfType"];

		completionBlock(safeToLoad, videoOfType);

		return;
	}

	/* Bind state */
	self.request = [ICMInlineVideoCheckRequest new];
	self.state = [ICMInlineVideoCheckState new];

	self.state.cacheToken = cacheToken;

	self.state.completionBlock = completionBlock;

	/* Create the request */
	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:address]
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_videoLoaderRequestTimeout];

	/* GET is used instead of HEAD because some services block the use of HEAD. */
	baseRequest.HTTPMethod = @"GET";

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

- (void)informDelegateWhetherVideoOfType:(nullable NSString *)videoOfType safeToLoad:(BOOL)safeToLoad
{
	NSMutableDictionary *cachedValue = [NSMutableDictionary dictionaryWithCapacity:2];
	[cachedValue setBool:safeToLoad forKey:@"safeToLoad"];
	[cachedValue maybeSetObject:videoOfType forKey:@"videoOfType"];
	[_internalCache setObject:[cachedValue copy] forKey:self.state.cacheToken];

	self.state.completionBlock(safeToLoad, videoOfType);
}

- (BOOL)headersAreValid
{
	/* Check type of response received */
	NSHTTPURLResponse *requestResponse = self.request.response;

	if ([requestResponse isKindOfClass:[NSHTTPURLResponse class]] == NO) {
		return NO;
	}

	/* Get data from headers */
	NSDictionary *headerFields = requestResponse.allHeaderFields;

	NSString *contentType = [headerFields stringForKey:@"Content-Type"];

	NSArray *validContentTypes = [ICMInlineVideo validVideoContentTypes];

	if ([validContentTypes containsObject:contentType] == NO) {
		return NO;
	}

	self.state.videoType = contentType;

	return YES;
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL safeToLoad = (self.request.response.statusCode == 200);

	NSString *videoOfType = self.state.videoType;

	[self informDelegateWhetherVideoOfType:videoOfType safeToLoad:safeToLoad];

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
	;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.request.response = (id)response;

	if (self.headersAreValid == NO) {
		[self cleanupConnectionRequest];

		return;
	}

	/* Ffake a successful download at this point so that we
	 can post the video without waiting for the entire thing
	 to download and waste bandwidth. */
	[self connectionDidFinishLoading:nil];
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache */
}

@end

#pragma mark -

@implementation ICMInlineVideoCheckRequest
@end

@implementation ICMInlineVideoCheckState
@end

NS_ASSUME_NONNULL_END
