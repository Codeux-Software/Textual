// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ImageURLParser

+ (NSString *)imageURLForURL:(NSString *)url
{
	NSString *lowerUrl = [url lowercaseString];
    
	NSURL *u = [NSURL URLWithString:[url encodeURIFragment]];
	
	NSString *host = [u.host lowercaseString];
	NSString *path = u.path;
	
	if ([lowerUrl hasSuffix:@".jpg"]
		|| [lowerUrl hasSuffix:@".jpeg"] || [lowerUrl hasSuffix:@".png"]
		|| [lowerUrl hasSuffix:@".gif"]  || [lowerUrl hasSuffix:@".tif"]
		|| [lowerUrl hasSuffix:@".tiff"] || [lowerUrl hasSuffix:@".bmp"]) {
		
        if ([host hasSuffix:@"wikipedia.org"]) {
            return nil;
        } else if ([url hasPrefix:@"http://fukung.net/v/"]) {
            url = [url stringByReplacingOccurrencesOfString:@"http://fukung.net/v/" withString:@"http://media.fukung.net/images/"];
        }
        
		return url;
	}
	
    if ([host hasSuffix:@"twitpic.com"]) {
		if (NSObjectIsNotEmpty(path)) {
			NSString *s = [path safeSubstringFromIndex:1];
			
			if ([s hasSuffix:@"/full"]) {
				s = [s safeSubstringToIndex:(s.length - 5)];
			}
			
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://twitpic.com/show/large/%@", s];
			}
		}
	} else if ([host hasSuffix:@"cl.ly"]) {
		if (NSObjectIsNotEmpty(path)) {
			NSString *s = [path safeSubstringFromIndex:1];
			
			if ([s contains:@"/"]) {
				s = [s safeSubstringToIndex:[s stringPosition:@"/"]];
			}
			
			if ([s length] == 20) {
				return [NSString stringWithFormat:@"http://cl.ly/%@/content", s];
			}
		}
	} else if ([host hasSuffix:@"tweetphoto.com"]) {
		if (NSObjectIsNotEmpty(path)) {
			return [NSString stringWithFormat:@"http://TweetPhotoAPI.com/api/TPAPI.svc/imagefromurl?size=medium&url=%@", [url encodeURIComponent]];
		}
	} else if ([host hasSuffix:@"yfrog.com"]) {
		if (NSObjectIsNotEmpty(path)) {
			return [NSString stringWithFormat:@"%@:iphone", url];
		}
	} else if ([host hasSuffix:@"twitgoo.com"]) {
		if (NSObjectIsNotEmpty(path)) {
			NSString *s = [path safeSubstringFromIndex:1];
			
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://twitgoo.com/show/Img/%@", s];
			}
		}
	} else if ([host isEqualToString:@"img.ly"]) {
		if (NSObjectIsNotEmpty(path)) {
			NSString *s = [path safeSubstringFromIndex:1];
			
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://img.ly/show/large/%@", s];
			}
		}
	} else if ([host hasSuffix:@"movapic.com"]) {
		if ([path hasPrefix:@"/pic/"]) {
			NSString *s = [path safeSubstringFromIndex:5];
			
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://image.movapic.com/pic/m_%@.jpeg", s];
			}
		}
	} else if ([host hasSuffix:@"f.hatena.ne.jp"]) {
		NSArray *ary = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		
		if (ary.count >= 3) {
			NSString *userId = [ary safeObjectAtIndex:1];
			NSString *photoId = [ary safeObjectAtIndex:2];
			
			if (userId.length && photoId.length > 8 && [photoId isNumericOnly]) {
				NSString *userIdHead  = [userId safeSubstringToIndex:1];
				NSString *photoIdHead = [photoId safeSubstringToIndex:8];
				
				return [NSString stringWithFormat:@"http://img.f.hatena.ne.jp/images/fotolife/%@/%@/%@/%@.jpg", userIdHead, userId, photoIdHead, photoId];
			}
		}
	} else if ([host hasSuffix:@"youtube.com"] || [host isEqualToString:@"youtu.be"]) {
		NSString *vid = nil;
		
		if ([host isEqualToString:@"youtu.be"]) {
			NSString *path = u.path;
			
			if (NSObjectIsNotEmpty(path)) {
				vid = [path safeSubstringFromIndex:1];
			}
		} else {
			NSString *query = u.query;
			
			if (query.length) {
				NSArray *queries = [query componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
				
				if (NSObjectIsNotEmpty(queries)) {
					NSCharacterSet *equal = [NSCharacterSet characterSetWithCharactersInString:@"="];
					
					for (NSString *e in queries) {
						NSArray *ary = [e componentsSeparatedByCharactersInSet:equal];
						
						if (ary.count >= 2) {
							NSString *key = [ary safeObjectAtIndex:0];
							NSString *value = [ary safeObjectAtIndex:1];
							
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
			return [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/default.jpg", vid];
		}
	} else if ([host hasSuffix:@"nicovideo.jp"] || [host isEqualToString:@"nico.ms"]) {
		NSString *vid = nil;
		
		if ([host isEqualToString:@"nico.ms"]) {
			NSString *path = u.path;
			
			if (NSObjectIsNotEmpty(path)) {
				path = [path safeSubstringFromIndex:1];
				
				if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
					vid = path;
				}
			}
		} else {
			NSString *path = u.path;
			
			if ([path hasPrefix:@"/watch/"]) {
				path = [path safeSubstringFromIndex:7];
				
				if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
					vid = path;
				}
			}
		}
		
		if (vid && vid.length > 2) {
			long long vidNum = [[vid safeSubstringFromIndex:2] longLongValue];
			
			return [NSString stringWithFormat:@"http://tn-skr%qi.smilevideo.jp/smile?i=%qi", (vidNum%4 + 1), vidNum];
		}
	} else {
		if (NSObjectIsNotEmpty(path)) {
			NSString *s = [path safeSubstringFromIndex:1];
			
			if ([s contains:@"/"]) {
				s = [s safeSubstringToIndex:[s stringPosition:@"/"]];
			}
			
            /* Attempt to match cl.ly custom domains. */
			if ([s length] == 20) {
                if ([TXRegularExpression string:s isMatchedByRegex:@"([a-zA-Z0-9]{20})"]) {
                    return [NSString stringWithFormat:@"http://%@/%@/content", host, s];
                }
			}
		}
    }
	
	return nil;
}

@end