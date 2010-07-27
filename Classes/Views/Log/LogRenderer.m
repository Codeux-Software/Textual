// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "LogRenderer.h"
#import "NSStringHelper.h"
#import "GTMNSString+HTML.h"
#import "UnicodeHelper.h"
#import "Preferences.h"

#define URL_ATTR				(1 << 31)
#define ADDRESS_ATTR			(1 << 30)
#define CHANNEL_NAME_ATTR		(1 << 29)
#define KEYWORD_ATTR			(1 << 28)
#define BOLD_ATTR				(1 << 27)
#define UNDERLINE_ATTR			(1 << 26)
#define ITALIC_ATTR				(1 << 25)
#define TEXT_COLOR_ATTR			(1 << 24)
#define BACKGROUND_COLOR_ATTR	(1 << 23)
#define BACKGROUND_COLOR_MASK	(0xF0)
#define TEXT_COLOR_MASK			(0x0F)

#define EFFECT_MASK				(BOLD_ATTR | UNDERLINE_ATTR | ITALIC_ATTR | TEXT_COLOR_ATTR | BACKGROUND_COLOR_ATTR)

typedef uint32_t attr_t;
static void setFlag(attr_t* attrBuf, attr_t flag, NSInteger start, NSInteger len)
{
	attr_t* target = attrBuf + start;
	attr_t* end = target + len;
	
	while (target < end) {
		*target |= flag;
		++target;
	}
}

static BOOL isClear(attr_t* attrBuf, attr_t flag, NSInteger start, NSInteger len)
{
	attr_t* target = attrBuf + start;
	attr_t* end = target + len;
	
	while (target < end) {
		if (*target & flag) return NO;
		++target;
	}
	
	return YES;
}

static NSInteger getNextAttributeRange(attr_t* attrBuf, NSInteger start, NSInteger len)
{
	attr_t target = attrBuf[start];
	
	for (NSInteger i=start; i<len; ++i) {
		attr_t t = attrBuf[i];
		if (t != target) {
			return i - start;
		}
	}
	
	return len - start;
}

NSString* logEscape(NSString* s)
{
	s = [s gtm_stringByEscapingForHTML];
	return [s stringByReplacingOccurrencesOfString:@"  " withString:@" &nbsp;"];
}

static NSString* renderRange(NSString* body, attr_t attr, NSInteger start, NSInteger len)
{
	NSString* content = [body substringWithRange:NSMakeRange(start, len)];
	
	if (attr & URL_ATTR) {
		NSString* link = content;
		NSString* metacontent = nil;
		
		NSString *choppedString = [link fastChopEndWithChars:[Preferences bannedURLRegexChars]];
		
		NSInteger origLenth = [link length];
		NSInteger choppedLenth = [choppedString length];
		
		if (choppedLenth < origLenth) {
			metacontent = [link safeSubstringFromIndex:choppedLenth];
			
			link = [link safeSubstringToIndex:choppedLenth];
			content = [content safeSubstringToIndex:choppedLenth];
		}
		
		if (![link contains:@"://"]) {
			link = [NSString stringWithFormat:@"http://%@", link];
		}
		
		content = logEscape(content);		
		if (metacontent == nil) {
			return [NSString stringWithFormat:@"<a href=\"%@\" class=\"url\" oncontextmenu=\"on_url()\">%@</a>", link, content];
		} else {
			return [NSString stringWithFormat:@"<a href=\"%@\" class=\"url\" oncontextmenu=\"on_url()\">%@</a>%@", link, content, metacontent];
		}
	} else if (attr & KEYWORD_ATTR) {
		content = logEscape(content);
		if (attr & ADDRESS_ATTR) {
			return [NSString stringWithFormat:@"<span class=\"highlight\"><span class=\"address\" oncontextmenu=\"on_addr()\">%@</span></span>", content];
		} else if (attr & CHANNEL_NAME_ATTR) {
			return [NSString stringWithFormat:@"<span class=\"highlight\"><span class=\"channel\" oncontextmenu=\"on_chname()\">%@</span></span>", content];
		} else {
			return [NSString stringWithFormat:@"<span class=\"highlight\">%@</span>", content];
		}
	} else if (attr & ADDRESS_ATTR) {
		content = logEscape(content);
		return [NSString stringWithFormat:@"<span class=\"address\" oncontextmenu=\"on_addr()\">%@</span>", content];
	} else if (attr & CHANNEL_NAME_ATTR) {
		content = logEscape(content);
		return [NSString stringWithFormat:@"<span class=\"channel\" oncontextmenu=\"on_chname()\">%@</span>", content];
	} else if (attr & EFFECT_MASK) {
		content = logEscape(content);
		NSMutableString* s = [NSMutableString stringWithString:@"<span class=\"effect\" style=\""];
		if (attr & BOLD_ATTR) [s appendString:@"font-weight:bold;"];
		if (attr & UNDERLINE_ATTR) [s appendString:@"text-decoration:underline;"];
		if (attr & ITALIC_ATTR) [s appendString:@"font-style:italic;"];
		[s appendString:@"\""];
		if (attr & TEXT_COLOR_ATTR) [s appendFormat:@" color-number=\"%d\"", (attr & TEXT_COLOR_MASK)];
		if (attr & BACKGROUND_COLOR_ATTR) [s appendFormat:@" bgcolor-number=\"%d\"", (attr & BACKGROUND_COLOR_MASK) >> 4];
		[s appendFormat:@">%@</span>", content];
		return s;
	} else {
		return logEscape(content);
	}
}

@implementation LogRenderer

+ (void)setUp
{
}

+ (NSString*)renderBody:(NSString*)body 
		    nolinks:(BOOL)showLinks 
		   keywords:(NSArray*)keywords 
	     excludeWords:(NSArray*)excludeWords 
	   exactWordMatch:(BOOL)exactWordMatch 
		highlighted:(BOOL*)highlighted 
		  URLRanges:(NSArray**)urlRanges;
{
	NSInteger len = body.length;
	attr_t attrBuf[len];
	memset(attrBuf, 0, len * sizeof(attr_t));
	
	NSInteger start;
	
	UniChar source[len];
	CFStringGetCharacters((CFStringRef)body, CFRangeMake(0, len), source);
	
	attr_t currentAttr = 0;
	UniChar dest[len];
	NSInteger n = 0;
	
	for (NSInteger i=0; i<len; i++) {
		UniChar c = source[i];
		if (c < 0x20) {
			switch (c) {
				case 0x02:
					if (currentAttr & BOLD_ATTR) {
						currentAttr &= ~BOLD_ATTR;
					}
					else {
						currentAttr |= BOLD_ATTR;
					}
					continue;
				case 0x03:
				{
					NSInteger textColor = -1;
					NSInteger backgroundColor = -1;
					
					if (i+1 < len) {
						c = source[i+1];
						if (IsNumeric(c)) {
							++i;
							textColor = c - '0';
							if (i+1 < len) {
								c = source[i+1];
								if (IsNumeric(c)) {
									++i;
									textColor = textColor * 10 + c - '0';
								}
								if (i+1 < len) {
									c = source[i+1];
									if (c == ',') {
										++i;
										
										if (i+1 < len) {
											c = source[i+1];
											if (IsNumeric(c)) {
												++i;
												backgroundColor = c - '0';
												if (i+1 < len) {
													c = source[i+1];
													if (IsNumeric(c)) {
														++i;
														backgroundColor = backgroundColor * 10 + c - '0';
													}
												}
											}
										}
									}
								}
							}
						}
						
						currentAttr &= ~(TEXT_COLOR_ATTR | BACKGROUND_COLOR_ATTR | 0xFF);

						if (backgroundColor >= 0) {
							backgroundColor %= 16;
							currentAttr |= BACKGROUND_COLOR_ATTR;
							currentAttr |= (backgroundColor << 4) & BACKGROUND_COLOR_MASK;
						} else {
							currentAttr &= ~(BACKGROUND_COLOR_ATTR | BACKGROUND_COLOR_MASK);
						}
						
						if (textColor >= 0) {
							textColor %= 16;
							currentAttr |= TEXT_COLOR_ATTR;
							currentAttr |= textColor & TEXT_COLOR_MASK;
						} else {
							currentAttr &= ~(TEXT_COLOR_ATTR | TEXT_COLOR_MASK);
						}
					}
					continue;
				}
				case 0x0F:
					currentAttr = 0;
					continue;
				case 0x16:
					if (currentAttr & ITALIC_ATTR) {
						currentAttr &= ~ITALIC_ATTR;
					}
					else {
						currentAttr |= ITALIC_ATTR;
					}
					continue;
				case 0x1F:
					if (currentAttr & UNDERLINE_ATTR) {
						currentAttr &= ~UNDERLINE_ATTR;
					}
					else {
						currentAttr |= UNDERLINE_ATTR;
					}
					continue;
			}
		}
		
		attrBuf[n] = currentAttr;
		dest[n++] = c;
	}
	
	body = [[[NSString alloc] initWithCharacters:dest length:n] autorelease];
	len = n;
	
	NSMutableArray* urlAry = [NSMutableArray array];
	start = 0;
	
	if (!showLinks) {
		while (start < len) {
			NSRange r = [body rangeOfUrlStart:start];
			if (r.location == NSNotFound) {
				break;
			}
			
			if (r.length == 1000) {
				start = r.location + 1;
			} else {			
				setFlag(attrBuf, URL_ATTR, r.location, r.length);
				[urlAry addObject:[NSValue valueWithRange:r]];
				start = NSMaxRange(r) + 1;
			}
		}
	}
	
	if (urlAry.count) {
		*urlRanges = urlAry;
	}
	
	BOOL foundKeyword = NO;
	NSMutableArray* excludeRanges = [NSMutableArray array];
	if (!exactWordMatch) {
		for (NSString* excludeWord in excludeWords) {
			start = 0;
			while (start < len) {
				NSRange r = [body rangeOfString:excludeWord options:NSCaseInsensitiveSearch range:NSMakeRange(start, len - start)];
				if (r.location == NSNotFound) {
					break;
				}
				[excludeRanges addObject:[NSValue valueWithRange:r]];
				start = NSMaxRange(r) + 1;
			}
		}
	}
	
	for (NSString* keyword in keywords) {
		start = 0;
		while (start < len) {
			NSRange r = [body rangeOfString:keyword options:NSCaseInsensitiveSearch range:NSMakeRange(start, len - start)];
			if (r.location == NSNotFound) {
				break;
			}
			
			BOOL enabled = YES;
			for (NSValue* e in excludeRanges) {
				if (NSIntersectionRange(r, [e rangeValue]).length > 0) {
					enabled = NO;
					break;
				}
			}
			
			if (exactWordMatch) {
				if (enabled) {
					UniChar c = [body characterAtIndex:r.location];
					if ([UnicodeHelper isAlphabeticalCodePoint:c]) {
						NSInteger prev = r.location - 1;
						if (0 <= prev && prev < len) {
							UniChar c = [body characterAtIndex:prev];
							if ([UnicodeHelper isAlphabeticalCodePoint:c]) {
								enabled = NO;
							}
						}
					}
				}
				
				if (enabled) {
					UniChar c = [body characterAtIndex:NSMaxRange(r)-1];
					if ([UnicodeHelper isAlphabeticalCodePoint:c]) {
						NSInteger next = NSMaxRange(r);
						if (next < len) {
							UniChar c = [body characterAtIndex:next];
							if ([UnicodeHelper isAlphabeticalCodePoint:c]) {
								enabled = NO;
							}
						}
					}
				}
			}
			
			if (enabled) {
				if (isClear(attrBuf, URL_ATTR, r.location, r.length)) {
					foundKeyword = YES;
					setFlag(attrBuf, KEYWORD_ATTR, 0, len);
					break;
				}
			}
			
			start = NSMaxRange(r) + 1;
		}
		
		if (foundKeyword) break;
	}
	
	start = 0;
	while (start < len) {
		NSRange r = [body rangeOfAddressStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		if (isClear(attrBuf, URL_ATTR, r.location, r.length)) {
			setFlag(attrBuf, ADDRESS_ATTR, r.location, r.length);
		}
		
		start = NSMaxRange(r) + 1;
	}
	
	start = 0;
	while (start < len) {
		NSRange r = [body rangeOfChannelNameStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		if (isClear(attrBuf, URL_ATTR, r.location, r.length)) {
			setFlag(attrBuf, CHANNEL_NAME_ATTR, r.location, r.length);
		}
		
		start = NSMaxRange(r) + 1;
	}
	
	NSMutableString* result = [NSMutableString string];
	
	start = 0;
	while (start < len) {
		NSInteger n = getNextAttributeRange(attrBuf, start, len);
		if (n <= 0) break;
		
		attr_t t = attrBuf[start];
		NSString* s = renderRange(body, t, start, n);
		[result appendString:s];
		
		start += n;
	}
	
	*highlighted = foundKeyword;
	return result;
}

@end