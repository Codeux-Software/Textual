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

#import "ICMTwitchLive.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ICMTwitchLiveContentType)
{
	ICMTwitchLiveUnknownType = 0,
	ICMTwitchLiveChannelType,
	ICMTwitchLiveVideoType
};

@implementation ICMTwitchLive

- (void)_performActionForContent:(NSString *)contentIdentifier type:(ICMTwitchLiveContentType)contentType
{
	NSParameterAssert(contentIdentifier != nil);
	NSParameterAssert(contentType != ICMTwitchLiveUnknownType);

	NSString *contentArgument = nil;

	if (contentType == ICMTwitchLiveChannelType) {
		contentArgument = @"channel";
	} else if (contentType == ICMTwitchLiveVideoType) {
		contentArgument = @"video";
	}

	ICLPayloadMutable *payload = self.payload;

	NSDictionary *templateAttributes =
	@{
	  @"uniqueIdentifier" : payload.uniqueIdentifier,
	  @"contentIdentifier" : contentIdentifier,
	  @"contentArgument" : contentArgument
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

	ICMTwitchLiveContentType contentType = ICMTwitchLiveUnknownType;

	NSString *contentIdentifier = [self _contentIdentifierForURL:url type:&contentType];

	if (contentIdentifier == nil) {
		return nil;
	}

	return [^(ICLInlineContentModule *module) {
		__weak ICMTwitchLive *moduleTyped = (id)module;

		[moduleTyped _performActionForContent:contentIdentifier type:contentType];
	} copy];
}

+ (nullable NSString *)_contentIdentifierForURL:(NSURL *)url type:(ICMTwitchLiveContentType *)contentTypeIn
{
	NSString *urlPath = url.path.percentEncodedURLPath;

	if (urlPath.length <= 1) {
		return nil;
	}

	urlPath = [urlPath substringFromIndex:1]; // "/"

	/* These exceptions cover all domains */
	if ([urlPath isEqualToString:@"directory"] ||
		[urlPath hasPrefix:@"directory/"] ||
		[urlPath isEqualToString:@"store"] ||
		[urlPath hasPrefix:@"store/"])
	{
		return nil;
	}

	/* Match videos */
	if ([urlPath hasPrefix:@"videos/"]) {
		urlPath = [urlPath substringFromIndex:7];

		NSString *contentIdentifier = [urlPath trimCharacters:@"/"];

		if (contentIdentifier.isNumericOnly == NO) {
			return nil;
		}

		*contentTypeIn = ICMTwitchLiveVideoType;

		return contentIdentifier;
	}

	/* Consider any other match a channel */
	{
		NSString *contentIdentifier = [urlPath trimCharacters:@"/"];

		if (contentIdentifier.length < 4 ||
			contentIdentifier.length > 25)
		{
			return nil;
		}

		if ([contentIdentifier onlyContainsCharactersFromCharacterSet:[NSCharacterSet Ato9Underscore]] == NO) {
			return nil;
		}

		*contentTypeIn = ICMTwitchLiveChannelType;

		return contentIdentifier;
	}
}

+ (nullable NSArray<NSString *> *)domains
{
	static NSArray<NSString *> *domains = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		domains =
		@[
		  @"twitch.tv",
		  @"www.twitch.tv",
		  @"go.twitch.tv"
		];
	});

	return domains;
}

#pragma mark -
#pragma mark Utilities

- (nullable NSURL *)templateURL
{
	return [NSBundleForClass() URLForResource:@"ICMTwitchLive" withExtension:@"mustache"];
}

@end

NS_ASSUME_NONNULL_END
