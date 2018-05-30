/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2017, 2018 Codeux Software, LLC & respective contributors.
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

#import "ICMVimeo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICMVimeo

- (void)_performActionForVideo:(NSString *)videoIdentifier
{
	NSParameterAssert(videoIdentifier != nil);

	ICLPayloadMutable *payload = self.payload;

	NSDictionary *templateAttributes =
	@{
	  @"uniqueIdentifier" : payload.uniqueIdentifier,
	  @"videoIdentifier" : videoIdentifier
	};

	NSError *templateRenderError = nil;

	NSString *html = [self.template renderObject:templateAttributes error:&templateRenderError];

	payload.html = html;

	[self finalizeWithError:templateRenderError];
}

#pragma mark -
#pragma mark Action Block

+ (nullable ICLInlineContentModuleActionBlock)actionBlockForURL:(NSURL *)url
{
	NSParameterAssert(url != nil);

	NSString *videoIdentifier = [self _videoIdentifierForURL:url];

	if (videoIdentifier == nil) {
		return nil;
	}

	return [^(ICLInlineContentModule *module) {
		__weak ICMVimeo *moduleTyped = (id)module;

		[moduleTyped _performActionForVideo:videoIdentifier];
	} copy];
}

+ (nullable NSString *)_videoIdentifierForURL:(NSURL *)url
{
	NSString *urlPath = url.path.percentEncodedURLPath;

	if (urlPath.length <= 1) {
		return nil;
	}

	NSString *videoIdentifier = [urlPath trimCharacters:@"/"];

	if (videoIdentifier.isNumericOnly == NO) {
		return nil;
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
		  @"vimeo.com",
		  @"www.vimeo.com"
		];
	});

	return domains;
}

#pragma mark -
#pragma mark Utilities

- (nullable NSURL *)templateURL
{
	return [NSBundleForClass() URLForResource:@"ICMVimeo" withExtension:@"mustache"];
}

@end

NS_ASSUME_NONNULL_END
