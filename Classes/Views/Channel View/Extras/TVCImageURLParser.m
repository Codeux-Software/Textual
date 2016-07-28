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

@implementation TVCImageURLParser

+ (NSArray<NSString *> *)validImageContentTypes
{
	static NSArray<NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		cachedValue =
		@[@"image/gif",
		  @"image/jpeg",
		  @"image/png",
		  @"image/svg+xml",
		  @"image/tiff",
		  @"image/x-ms-bmp"];
	});

	return cachedValue;
}

+ (nullable NSString *)imageURLFromBase:(NSString *)url
{
	NSParameterAssert(url != nil);

	NSURL *urlUrl = url.URLUsingWebKitPasteboard;

	if (urlUrl == nil) {
		return nil;
	}

	NSString *pluginResult = [THOPluginDispatcher processInlineMediaContentURL:urlUrl.absoluteString];

	if (pluginResult) {
		return pluginResult;
	}

	NSString *urlScheme = urlUrl.scheme;

	if ([urlScheme isEqualToString:@"http"] == NO &&
		[urlScheme isEqualToString:@"https"] == NO)
	{
		return nil;
	}
	
	NSString *urlHost = urlUrl.host.lowercaseString;
	NSString *urlPath = urlUrl.path.percentEncodedURLPath;
	NSString *urlQuery = urlUrl.query.percentEncodedURLQuery;

	BOOL hasFileExtension = NO;

	if ([urlPath hasSuffixIgnoringCase:@".jpg"] || [urlQuery hasSuffixIgnoringCase:@".jpg"] ||
		[urlPath hasSuffixIgnoringCase:@".jpeg"] || [urlQuery hasSuffixIgnoringCase:@".jpeg"] ||
		[urlPath hasSuffixIgnoringCase:@".png"] || [urlQuery hasSuffixIgnoringCase:@".png"] ||
		[urlPath hasSuffixIgnoringCase:@".gif"] || [urlQuery hasSuffixIgnoringCase:@".gif"] ||
		[urlPath hasSuffixIgnoringCase:@".tif"] || [urlQuery hasSuffixIgnoringCase:@".tif"] ||
		[urlPath hasSuffixIgnoringCase:@".tiff"] || [urlQuery hasSuffixIgnoringCase:@".tiff"] ||
		[urlPath hasSuffixIgnoringCase:@".svg"] || [urlQuery hasSuffixIgnoringCase:@".svg"] ||
		[urlPath hasSuffixIgnoringCase:@".bmp"] || [urlQuery hasSuffixIgnoringCase:@".bmp"])
	{
		hasFileExtension = YES;

        if ([urlHost hasSuffix:@"wikipedia.org"]) {
            return nil;
        } else if ([url hasPrefix:@"http://fukung.net/v/"]) {
			return [url stringByReplacingOccurrencesOfString:@"http://fukung.net/v/" withString:@"http://media.fukung.net/images/"];
        } else if ([urlHost hasSuffix:@"dropbox.com"]) {
			// Continue to processing...
		} else {
			return urlUrl.absoluteString;
		}
	}

	NSString *urlPathCombined = urlPath;

	if (urlQuery) {
		urlPathCombined = [urlPathCombined stringByAppendingFormat:@"?%@", urlQuery];
	}

	if ([urlHost hasSuffix:@"dropbox.com"])
	{
		if ([urlPathCombined hasPrefix:@"/s/"] && hasFileExtension) {
			return [@"https://dl.dropboxusercontent.com" stringByAppendingString:urlPathCombined];
		}
	}
	else if ([urlHost hasSuffix:@"instacod.es"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);
		
		NSString *s = [urlPath substringFromIndex:1];

		if (s.numericOnly) {
			return [@"http://instacod.es/file/" stringByAppendingString:s];
		}
	}
	else if ([urlHost isEqualToString:@"pbs.twimg.com"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		urlPath = [urlPath
			stringByReplacingOccurrencesOfString:@"\\:(large|medium|orig|small|thumb)$"
									  withString:NSStringEmptyPlaceholder
										 options:NSRegularExpressionSearch
										   range:urlPath.range];

		return [NSString stringWithFormat:@"https://pbs.twimg.com/%@:orig", urlPath];
	}
	else if ([urlHost isEqualToString:@"docs.google.com"])
	{
		if ([urlPath hasPrefix:@"/file/d/"] == NO) {
			return nil;
		}

		NSString *photoId = nil;

		NSArray *components = [urlPath componentsSeparatedByString:@"/"];

		if (components.count == 5) {
			if ([components[4] isEqualToString:@"edit"]) { // Add a little validation
				photoId = components[3];
			}
		} else if (components.count == 4) {
			photoId = components[3];
		} else {
			return nil;
		}

		if (photoId) {
			return [@"https://docs.google.com/uc?id=" stringByAppendingString:photoId];
		}
	}
	else if ([urlHost hasSuffix:@"twitpic.com"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);
		
		NSString *s = [urlPath substringFromIndex:1];

		if ([s hasSuffix:@"/full"]) {
			s = [s substringToIndex:(s.length - 5)];
		}

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://twitpic.com/show/large/%@", s];
		}
	}
	else if ([urlHost hasSuffix:@"cl.ly"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		NSString *s = [urlPath substringFromIndex:1];
        
        NSArray *components = [s componentsSeparatedByString:@"/"];

		if (components.count != 2) {
			return nil;
		}

		NSString *p1 = components[0];
		NSString *p2 = components[1];

        if ([p1 isEqualIgnoringCase:@"image"]) {
            return [NSString stringWithFormat:@"http://cl.ly/%@/content", p2];
        }
	}
	else if ([urlHost hasSuffix:@"instagram.com"] ||
			 [urlHost hasSuffix:@"instagr.am"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		if ([urlPath hasPrefix:@"/p/"] == NO) {
			return nil;
		}

		NSString *s = [urlPath substringFromIndex:3];

		if ([s onlyContainsCharacters:CS_AtoZUnderscoreDashCharacters]) {
			return [NSString stringWithFormat:@"https://www.instagram.com/p/%@/media/?size=l", s];
		}
	}

#warning TODO: Remove 'img.ly' entry; service will no longer exist after July 31, 2015
	else if ([urlHost isEqualToString:@"img.ly"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		NSString *s = [urlPath substringFromIndex:1];

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://img.ly/show/large/%@", s];
		}
	}
	else if ([urlHost hasSuffix:@"leetfil.es"] ||
			 [urlHost hasSuffix:@"lfil.es"] ||
			 [urlHost hasSuffix:@"i.leetfil.es"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		if ([urlHost hasSuffix:@"i.leetfil.es"]) {
			NSString *s = [urlPath substringFromIndex:1];

			if (s.alphabeticNumericOnly) {
				return [NSString stringWithFormat:@"https://i.leetfil.es/%@", s];
			}
		} else if ([urlHost hasSuffix:@"lfil.es"]) {
			if ([urlPath hasPrefix:@"/i/"]) {
				NSString *s = [urlPath substringFromIndex:3];

				if (s.alphabeticNumericOnly) {
					return [NSString stringWithFormat:@"https://i.leetfil.es/%@", s];
				}
			} else if ([urlPath hasPrefix:@"/v/"]) {
				NSString *v = [urlPath substringFromIndex:3];

				if (v.alphabeticNumericOnly) {
					return [NSString stringWithFormat:@"https://v.leetfil.es/%@_thumb", v];
				}
			}
		} else {
			if ([urlPath hasPrefix:@"/image/"]) {
				NSString *s = [urlPath substringFromIndex:7];

				if (s.alphabeticNumericOnly) {
					return [NSString stringWithFormat:@"https://i.leetfil.es/%@", s];
				}
			} else if ([urlPath hasPrefix:@"/video/"]) {
				NSString *v = [urlPath substringFromIndex:7];

				if (v.alphabeticNumericOnly) {
					return [NSString stringWithFormat:@"https://v.leetfil.es/%@_thumb", v];
				}
			}
		}
	}
	else if ([urlHost hasSuffix:@"movapic.com"])
	{
		if ([urlPath hasPrefix:@"/pic/"] == NO) {
			return nil;
		}

		NSString *s = [urlPath substringFromIndex:5];

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://image.movapic.com/pic/m_%@.jpeg", s];
		}
	}
	else if ([urlHost hasSuffix:@"f.hatena.ne.jp"])
	{
		NSArray *components = [urlPath componentsSeparatedByString:@"/"];

		if (components.count < 3) {
			return nil;
		}

		NSString *userId = components[1];
		NSString *photoId = components[2];

		if (userId.length == 0 || photoId.length < 8) {
			return nil;
		}

		if (photoId.numericOnly == NO) {
			return nil;
		}

		NSString *userIdHead = [userId substringToIndex:1];
		NSString *photoIdHead = [photoId substringToIndex:8];

		return [NSString stringWithFormat:@"http://img.f.hatena.ne.jp/images/fotolife/%@/%@/%@/%@.jpg", userIdHead, userId, photoIdHead, photoId];
	}
	else if ([urlHost isEqualToString:@"puu.sh"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil);

		NSString *s = [urlPath substringFromIndex:1];

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://puu.sh/%@.jpg", s];
		}
	}
	else if ([urlHost hasSuffix:@"d.pr"])
	{
		if ([urlPath hasPrefix:@"/i/"] == NO) {
			return nil;
		}

		NSString *s = [urlPath substringFromIndex:3];

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://d.pr/i/%@.png", s];
		}
	}
	else if ([urlHost hasSuffix:@"youtube.com"] ||
			 [urlHost isEqualToString:@"youtu.be"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil)

		NSString *videoId = nil;

		if ([urlHost isEqualToString:@"youtu.be"]) {
			videoId = [urlPath substringFromIndex:1];
		} else {
			NSDictionary *queryItems = urlQuery.URLQueryItems;

			videoId = queryItems[@"v"];
		}

		if (videoId.length < 11) {
			return nil;
		}

		if (videoId.length > 11) {
			videoId = [videoId substringToIndex:11];
		}

		return [NSString stringWithFormat:@"http://i.ytimg.com/vi/%@/mqdefault.jpg", videoId];
	}
	else if ([urlHost hasSuffix:@"nicovideo.jp"] ||
			 [urlHost isEqualToString:@"nico.ms"])
	{
		NSObjectIsEmptyAssertReturn(urlPath, nil)

		NSString *videoId = nil;

		NSString *s = nil;

		if ([urlHost isEqualToString:@"nico.ms"]) {
			s = [urlPath substringFromIndex:1];
		} else if ([urlPath hasPrefix:@"/watch/"]) {
			s = [urlPath substringFromIndex:7];
		}

		if ([s hasPrefix:@"sm"] || [s hasPrefix:@"nm"]) {
			videoId = s;
		}

		if (videoId.length < 3) {
			return nil;
		}

		long long videoNumber = [videoId substringFromIndex:2].longLongValue;

		return [NSString stringWithFormat:@"http://tn-skr%lli.smilevideo.jp/smile?i=%lli", ((videoNumber % 4) + 1), videoNumber];
	}
	else if ([urlPath hasPrefix:@"/image/"])
	{
		/* Try our best to regonize cl.ly custom domains. */
		NSString *s = [urlPath substringFromIndex:7];

		if (s.length != 12) {
			return nil;
		}

		if (s.alphabeticNumericOnly) {
			return [NSString stringWithFormat:@"http://cl.ly/%@/content", s];
		}
	}

	return nil;
}

@end

NS_ASSUME_NONNULL_END
