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

@implementation TVCImageURLParser

+ (NSArray *)validImageContentTypes
{
	return @[@"image/gif", @"image/jpeg", @"image/png", @"image/svg+xml", @"image/tiff", @"image/x-ms-bmp"];
}

+ (NSString *)imageURLFromBase:(NSString *)url
{
	/* Convert URL. */
	NSURL *u = [url URLUsingWebKitPasteboard];

	NSString *pluginResult = [THOPluginDispatcher processInlineMediaContentURL:[u absoluteString]];

	if (pluginResult) {
		return pluginResult;
	}

	NSString *scheme = [u scheme];

	if ([scheme isEqualToString:@"file"]) {
		// If the file is a local file (file:// scheme), then let us ignore it.
		// Only the local user can see their own files.

		return nil;
	}
	
	NSString *host = [[u host] lowercaseString];

	NSString *path = [[u path] percentEncodedURLPath];

	NSString *query = [[u query] percentEncodedURLQuery];

	BOOL hadExtension = NO;

	if ([path hasSuffixIgnoringCase:@".jpg"]	|| [query hasSuffixIgnoringCase:@".jpg"]	||
		[path hasSuffixIgnoringCase:@".jpeg"]	|| [query hasSuffixIgnoringCase:@".jpeg"]	||
		[path hasSuffixIgnoringCase:@".png"]	|| [query hasSuffixIgnoringCase:@".png"]	||
		[path hasSuffixIgnoringCase:@".gif"]	|| [query hasSuffixIgnoringCase:@".gif"]	||
		[path hasSuffixIgnoringCase:@".tif"]	|| [query hasSuffixIgnoringCase:@".tif"]	||
		[path hasSuffixIgnoringCase:@".tiff"]	|| [query hasSuffixIgnoringCase:@".tiff"]	||
		[path hasSuffixIgnoringCase:@".svg"]	|| [query hasSuffixIgnoringCase:@".svg"]	||
		[path hasSuffixIgnoringCase:@".bmp"]	|| [query hasSuffixIgnoringCase:@".bmp"])
	{
		hadExtension = YES;

        if ([host hasSuffix:@"wikipedia.org"]) {
            return nil;
        } else if ([url hasPrefix:@"http://fukung.net/v/"]) {
			return [url stringByReplacingOccurrencesOfString:@"http://fukung.net/v/" withString:@"http://media.fukung.net/images/"];
        } else if ([host hasSuffix:@"dropbox.com"]) {
			// Continue to processing...
		} else {
			return [u absoluteString];
		}
	}

	if (query) {
		path = [[path stringByAppendingString:@"?"] stringByAppendingString:query];
	}

	if ([host hasSuffix:@"dropbox.com"]) {
		if ([path hasPrefix:@"/s/"] && hadExtension) {
			return [@"https://dl.dropboxusercontent.com" stringByAppendingString:path];
		}
	} else if ([host hasSuffix:@"instacod.es"]) {
		NSObjectIsEmptyAssertReturn(path, nil);
		
		NSString *s = [path substringFromIndex:1];

		if ([s isNumericOnly]) {
			return [@"http://instacod.es/file/" stringByAppendingString:s];
		}
	} else if ([host isEqualToString:@"pbs.twimg.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		path = [path stringByReplacingOccurrencesOfString:@"\\:(large|medium|orig|small|thumb)$"
											   withString:NSStringEmptyPlaceholder
												  options:NSRegularExpressionSearch
													range:[path range]];

		return [NSString stringWithFormat:@"https://pbs.twimg.com/%@:orig", path];
	} else if ([host isEqualToString:@"docs.google.com"]) {
		if ([path hasPrefix:@"/file/d/"]) {
			NSArray *parts = [path componentsSeparatedByString:@"/"];

			NSAssertReturnR(([parts count] == 4 || [parts count] == 5), nil);

			NSString *photoID = nil;

			if ([parts count] == 5) {
				if ([parts[4] isEqualToString:@"edit"]) { // Add a little validation.
					photoID = parts[3];
				}
			} else {
				photoID = parts[3];
			}

			if (photoID) {
				return [@"https://docs.google.com/uc?id=" stringByAppendingString:photoID];
			}
		}
	} else if ([host hasSuffix:@"twitpic.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);
		
		NSString *s = [path substringFromIndex:1];

		if ([s length] > 5) {
			if ([s hasSuffix:@"/full"]) {
				s = [s substringToIndex:([s length] - 5)];
			}
		}

		if ([s isAlphabeticNumericOnly]) {
			return [NSString stringWithFormat:@"http://twitpic.com/show/large/%@", s];
		}
	} else if ([host hasSuffix:@"cl.ly"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		NSString *p = [path substringFromIndex:1];
        
        NSArray *components = [p componentsSeparatedByString:@"/"];

		NSAssertReturnR(([components count] == 2), nil);

		NSString *p1 = components[0];
		NSString *p2 = components[1];

        if ([p1 isEqualIgnoringCase:@"image"]) {
            return [NSString stringWithFormat:@"http://cl.ly/%@/content", p2];
        }
	} else if ([host hasSuffix:@"instagram.com"] ||
			   [host hasSuffix:@"instagr.am"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		if ([path hasPrefix:@"/p/"]) {
			path = [path substringFromIndex:3];

			if ([path onlyContainsCharacters:CS_LatinAlphabetIncludingUnderscoreDashCharacterSet]) {
				return [NSString stringWithFormat:@"https://www.instagram.com/p/%@/media/?size=l", path];
			}
		}
	} else if ([host hasSuffix:@"tweetphoto.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		return [NSString stringWithFormat:@"http://TweetPhotoAPI.com/api/TPAPI.svc/imagefromurl?size=medium&url=%@", [url percentEncodedString]];
	} else if ([host hasSuffix:@"yfrog.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		return [NSString stringWithFormat:@"%@:iphone", url];
	} else if ([host hasSuffix:@"twitgoo.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		NSString *s = [path substringFromIndex:1];

		if ([s isAlphabeticNumericOnly]) {
			return [NSString stringWithFormat:@"http://twitgoo.com/show/Img/%@", s];
		}
	} else if ([host isEqualToString:@"img.ly"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		NSString *s = [path substringFromIndex:1];

		if ([s isAlphabeticNumericOnly]) {
			return [NSString stringWithFormat:@"http://img.ly/show/large/%@", s];
		}
	} else if ([host hasSuffix:@"leetfil.es"] || [host hasSuffix:@"i.leetfil.es"]) {
        	if ([host hasSuffix:@"i.leetfil.es"]) {
			NSString *i = [path substringFromIndex:1];

            		if ([i isAlphabeticNumericOnly]) {
                		return [NSString stringWithFormat:@"https://i.leetfil.es/%@", i];
            		}
        	} else {
            		if ([path hasPrefix:@"/image/"]) {
        			NSString *s = [path substringFromIndex:7];
                
        			if ([s isAlphabeticNumericOnly]) {
					return [NSString stringWithFormat:@"https://i.leetfil.es/%@", s];
				}
			} else if ([path hasPrefix:@"/video/"]) {
                		NSString *v = [path substringFromIndex:7];
                
                		if ([v isAlphabeticNumericOnly]) {
                    			return [NSString stringWithFormat:@"https://v.leetfil.es/%@_thumb", v];
                		}
            		}
        	}
	} else if ([host hasSuffix:@"movapic.com"]) {
		if ([path hasPrefix:@"/pic/"]) {
			NSString *s = [path substringFromIndex:5];

			if ([s isAlphabeticNumericOnly]) {
				return [NSString stringWithFormat:@"http://image.movapic.com/pic/m_%@.jpeg", s];
			}
		}
	} else if ([host hasSuffix:@"f.hatena.ne.jp"]) {
		NSArray *ary = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

		if ([ary count] >= 3) {
			NSString *userId = ary[1];
			NSString *photoId = ary[2];

			if ([userId length] > 0 && [photoId length] > 8 && [photoId isNumericOnly]) {
				NSString *userIdHead  = [userId substringToIndex:1];
				NSString *photoIdHead = [photoId substringToIndex:8];

				return [NSString stringWithFormat:@"http://img.f.hatena.ne.jp/images/fotolife/%@/%@/%@/%@.jpg", userIdHead, userId, photoIdHead, photoId];
			}
		}
	} else if ([host isEqualToString:@"puu.sh"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		NSString *s = [path substringFromIndex:1];

		if ([s isAlphabeticNumericOnly]) {
			return [NSString stringWithFormat:@"http://puu.sh/%@.jpg", s];
		}
	} else if ([host hasSuffix:@"d.pr"]) {
		if ([path hasPrefix:@"/i/"]) {
			NSString *s = [path substringFromIndex:3];

			if ([s isAlphabeticNumericOnly]) {
				return [NSString stringWithFormat:@"http://d.pr/i/%@.png", s];
			}
		}
	} else if ([host hasSuffix:@"youtube.com"] || [host isEqualToString:@"youtu.be"]) {
		NSString *vid = nil;

		if ([host isEqualToString:@"youtu.be"]) {
			NSString *dpath = [u path];
			
			NSObjectIsEmptyAssertReturn(dpath, nil);
			
			vid = [dpath substringFromIndex:1];
		} else {
			NSString *dquery = [u query];

			if ([dquery length] > 0) {
				NSArray *queries = [dquery componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];

				if ([queries count] > 0) {
					NSCharacterSet *equal = [NSCharacterSet characterSetWithCharactersInString:@"="];

					for (NSString *e in queries) {
						NSArray *ary = [e componentsSeparatedByCharactersInSet:equal];

						if ([ary count] >= 2) {
							NSString *key = ary[0];
							NSString *value = ary[1];

							if ([key isEqualToString:@"v"]) {
								vid = value;

								break;
							}
						}
					}
				}
			}
		}

		if (vid) {
			if ([vid length] > 11) {
				vid = [vid substringToIndex:11];
			}

			return [NSString stringWithFormat:@"http://i.ytimg.com/vi/%@/mqdefault.jpg", vid];
		}
	} else if ([host hasSuffix:@"nicovideo.jp"] || [host isEqualToString:@"nico.ms"]) {
		NSString *vid = nil;

		if ([host isEqualToString:@"nico.ms"]) {
			NSString *dpath = [u path];
			
			NSObjectIsEmptyAssertReturn(dpath, nil);
			
			dpath = [dpath substringFromIndex:1];

			if ([dpath hasPrefix:@"sm"] || [dpath hasPrefix:@"nm"]) {
				vid = dpath;
			}
		} else {
			NSString *dpath = [u path];
			
			if ([dpath hasPrefix:@"/watch/"]) {
				dpath = [dpath substringFromIndex:7];

				if ([dpath hasPrefix:@"sm"] || [dpath hasPrefix:@"nm"]) {
					vid = dpath;
				}
			}
		}

		if (vid && [vid length] > 2) {
			long long vidNum = [[vid substringFromIndex:2] longLongValue];

			return [NSString stringWithFormat:@"http://tn-skr%lli.smilevideo.jp/smile?i=%lli", ((vidNum % 4) + 1), vidNum];
		}
	} else if ([path hasPrefix:@"/image/"]) {
		/* Try our best to regonize cl.ly custom domains. */
		NSString *s = [path substringFromIndex:7];

		if ([s isAlphabeticNumericOnly] && [s length] == 12) {
			return [NSString stringWithFormat:@"http://cl.ly%@/content", path];
		}
	}

	return nil;
}

@end
