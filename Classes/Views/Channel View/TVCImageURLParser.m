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
	/* List based off https://en.wikipedia.org/wiki/Internet_media_type#Type_image */

	return @[@"image/gif", @"image/jpeg", @"image/png", @"image/svg+xml", @"image/tiff", @"image/x-ms-bmp"];
}

/* Takes URL, places it on a pasteboard, and hands off to a WebView instance.
 Doing so is a dead simple hack to convert IDN domains to ASCII. */
+ (NSURL *)URLFromWebViewPasteboard:(NSString *)baseURL
{
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithUniqueName];
	
	[pasteboard setStringContent:baseURL];

	NSURL *u = [WebView URLFromPasteboard:pasteboard];

	/* For some users, u returns nil for valid URLs. There is no
	 explanation for this so for now we fallback to classic NSURL
	 if it does do this to hack around a fix. */
	if (u == nil) {
		u = [NSURL URLWithString:baseURL];
	}

	return u;
}

+ (NSString *)imageURLFromBase:(NSString *)url
{
	/* Convert URL. */
	NSURL *u = [TVCImageURLParser URLFromWebViewPasteboard:url];

	NSString *scheme = [u scheme];
	
	NSString *host = [[u host] lowercaseString];

	NSString *path = [[u path] encodeURIFragment];
	NSString *query = [[u query] encodeURIFragment];

	NSString *lowercasePath = [path lowercaseString];
    
    if (query) {
        path = [[path stringByAppendingString:@"?"] stringByAppendingString:query];
    }

	if ([scheme isEqualToString:@"file"]) {
		// If the file is a local file (file:// scheme), then let us ignore it.
		// Only the local user can see their own files.

		return nil;
	}

	NSString *plguinResult = [sharedPluginManager() processInlineMediaContentURL:[u absoluteString]];

	if (plguinResult) {
		return plguinResult;
	}

	BOOL hadExtension = NO;

	if ([lowercasePath hasSuffix:@".jpg"]	||
		[lowercasePath hasSuffix:@".jpeg"]	||
		[lowercasePath hasSuffix:@".png"]	||
		[lowercasePath hasSuffix:@".gif"]	||
		[lowercasePath hasSuffix:@".tif"]	||
		[lowercasePath hasSuffix:@".tiff"]	||
		[lowercasePath hasSuffix:@".bmp"])
	{
		hadExtension = YES;

        if ([host hasSuffix:@"wikipedia.org"]) {
            return nil;
        } else if ([url hasPrefix:@"http://fukung.net/v/"]) {
			return [url stringByReplacingOccurrencesOfString:@"http://fukung.net/v/" withString:@"http://media.fukung.net/images/"];
        } else if ([host hasSuffix:@"dropbox.com"]) {
			// Continue to processing…
		} else {
			return [u absoluteString];
		}
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
	} else if ([host hasPrefix:@"docs.google.com"]) {
		if ([path hasPrefix:@"/file/d/"]) {
			NSArray *parts = [path componentsSeparatedByString:@"/"];

			NSAssertReturnR(([parts count] == 4 || [parts count] == 5), nil);

			NSString *photoID;

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
	} else if ([host hasSuffix:@"tweetphoto.com"]) {
		NSObjectIsEmptyAssertReturn(path, nil);

		return [NSString stringWithFormat:@"http://TweetPhotoAPI.com/api/TPAPI.svc/imagefromurl?size=medium&url=%@", [url encodeURIComponent]];
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
	/* } else if ([host hasSuffix:@"imgur.com"]) {
		if ([path hasPrefix:@"/gallery/"]) {
			NSString *s = [path substringFromIndex:9];

			if ([s isAlphabeticNumericOnly]) {
				return [NSString stringWithFormat:@"http://i.imgur.com/%@.png", s];
			}
		} */
	} else if ([host hasSuffix:@"ubuntuone.com"]) {
		if ([path hasPrefix:@"/"]) {
			NSString *s = [path substringFromIndex:1];

			if ([s isAlphabeticNumericOnly] && [s length] == 22) {
				return url;
			}
		}
	} else if ([host hasSuffix:@"d.pr"]) {
		if ([path hasPrefix:@"/i/"]) {
			NSString *s = [path substringFromIndex:3];

			if ([s isAlphabeticNumericOnly]) {
				return [NSString stringWithFormat:@"http://d.pr/i/%@.png", s];
			}
		}
	} else if ([host hasSuffix:@"mediacru.sh"]) {
		if ([path hasPrefix:@"/"] && [path length] == 13) {
			NSString *s = [path substringFromIndex:1];

			if ([s onlyContainsCharacters:TXWesternAlphabetIncludingUnderscoreDashCharacterSet]) {
				/* This site does both http and https. */

				return [NSString stringWithFormat:@"https://cdn.mediacru.sh/%@.jpg", s];
			}
		}
	} else if ([host hasSuffix:@"youtube.com"] || [host isEqualToString:@"youtu.be"]) {
		NSString *vid = nil;

		if ([host isEqualToString:@"youtu.be"]) {
			NSString *path = [u path];
			
			NSObjectIsEmptyAssertReturn(path, nil);
			
			vid = [path substringFromIndex:1];
		} else {
			NSString *query = [u query];

			if ([query length] > 0) {
				NSArray *queries = [query componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];

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
				/* This behavior is was found by accident but is quite interesting. YouTube
				 links limit the video ID to a maximum length of eleven. If it exceeds that,
				 it only takes the first eleven characters. So a video link like:
				 
				 http://www.youtube.com/watch?v=qMkYlIA7mgw7435345354354343
				 
				 will actually be seen as:
				 
				 http://www.youtube.com/watch?v=qMkYlIA7mgw
				 
				 This is all fine and cool, but their image server does not do the same.
				 Therefore, this is a fix in Textual to catch the length and resize so that
				 we provide valid images for the weird links. */

				vid = [vid substringToIndex:11];
			}

			return [NSString stringWithFormat:@"http://i.ytimg.com/vi/%@/mqdefault.jpg", vid];
		}
	} else if ([host hasSuffix:@"nicovideo.jp"] || [host isEqualToString:@"nico.ms"]) {
		NSString *vid = nil;

		if ([host isEqualToString:@"nico.ms"]) {
			NSString *path = [u path];
			
			NSObjectIsEmptyAssertReturn(path, nil);
			
			path = [path substringFromIndex:1];

			if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
				vid = path;
			}
		} else {
			NSString *path = [u path];
			
			if ([path hasPrefix:@"/watch/"]) {
				path = [path substringFromIndex:7];

				if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
					vid = path;
				}
			}
		}

		if (vid && [vid length] > 2) {
			long long vidNum = [[vid substringFromIndex:2] longLongValue];

			return [NSString stringWithFormat:@"http://tn-skr%qi.smilevideo.jp/smile?i=%qi", ((vidNum % 4) + 1), vidNum];
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
