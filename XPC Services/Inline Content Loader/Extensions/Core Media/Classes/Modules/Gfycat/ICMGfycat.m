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

#import "ICLHelpers.h"
#import "ICMGfycat.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICMGfycat

- (void)_performActionForVideo:(NSString *)videoIdentifier atSpeed:(double)playbackSpeed reversed:(BOOL)playbackReversed
{
	NSParameterAssert(videoIdentifier != nil);

	NSString *addressToRequest = [@"https://gfycat.com/cajax/get/" stringByAppendingString:videoIdentifier];

	[ICLHelpers requestJSONObject:@"mp4Url"
						   ofType:[NSString class]
					  inHierarchy:@[@"gfyItem"]
					  fromAddress:addressToRequest
				  completionBlock:^(id object)
	 {
		 if (object == nil) {
			 [self notifyUnsafeToLoadVideo];

			 return;
		 }

		 NSString *address = object;

		 if (playbackReversed) {
			 address = [address stringByReplacingOccurrencesOfString:@".mp4" withString:@"-reverse.mp4"];
		 }

		 self.videoPlaybackSpeed = playbackSpeed;

		 [self performActionForAddress:address];
	 }];
}

#pragma mark -
#pragma mark Action Block

+ (nullable ICLInlineContentModuleActionBlock)actionBlockForURL:(NSURL *)url
{
	NSParameterAssert(url != nil);

	double playbackSpeed = 1.0;

	BOOL playbackReversed = NO;

	NSString *videoIdentifier = [self _videoIdentifierForURL:url atSpeed:&playbackSpeed reversed:&playbackReversed];

	if (videoIdentifier == nil) {
		return nil;
	}

	return [^(ICLInlineContentModule *module) {
		__weak ICMGfycat *moduleTyped = (id)module;

		[moduleTyped _performActionForVideo:videoIdentifier atSpeed:playbackSpeed reversed:playbackReversed];
	} copy];
}

+ (nullable NSString *)_videoIdentifierForURL:(NSURL *)url atSpeed:(double *)playbackSpeedIn reversed:(BOOL *)playbackReversedIn
{
	NSString *urlPath = url.path.percentEncodedURLPath;

	if ([urlPath hasPrefix:@"/gifs/detail/"]) {
		urlPath = [urlPath substringFromIndex:13];
	}

	NSString *videoIdentifier = [urlPath trimCharacters:@"/"];

	if (videoIdentifier.isAlphabeticNumericOnly == NO) {
		return nil;
	}

	NSString *urlQuery = url.query.percentEncodedURLQuery;

	NSDictionary *queryItems = urlQuery.URLQueryItems;

	NSString *playbackDirection = queryItems[@"direction"];

	if ([playbackDirection isEqualToString:@"reverse"]) {
		*playbackReversedIn = YES;
	}

	NSString *playbackSpeed = queryItems[@"speed"];

	if (playbackSpeed.isAnyPositiveNumber) {
		*playbackSpeedIn = playbackSpeed.doubleValue;
	}

	return videoIdentifier;
}

+ (nullable NSArray<NSString *> *)domains
{
	static NSArray<NSString *> *domains = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		domains =
		@[
		  @"gfycat.com",
		  @"www.gfycat.com"
		];
	});

	return domains;
}

+ (BOOL)contentIsFile
{
	return YES;
}

#pragma mark -
#pragma mark Utilities

- (void)finalizePreflight
{
	self.payload.classAttribute = @"inlineGfycat";
}

@end

NS_ASSUME_NONNULL_END
