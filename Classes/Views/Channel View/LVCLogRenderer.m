// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

#define _rendererURLAttribute					(1 << 31)
#define _rendererAddressAttribute				(1 << 30) // deprecated
#define _rendererChannelNameAttribute			(1 << 29)
#define _rendererBoldFormatAttribute			(1 << 28)
#define _rendererUnderlineFormatAttribute		(1 << 27)
#define _rendererItalicFormatAttribute			(1 << 26)
#define _rendererTextColorAttribute				(1 << 25)
#define _rendererBackgroundColorAttribute		(1 << 24)
#define _rendererConversationTrackerAttribute	(1 << 23)
#define _rendererKeywordHighlightAttribute		(1 << 22)

#define _backgroundColorMask	(0xF0)
#define _textColorMask			(0x0F)
#define _effectMask				(_rendererBoldFormatAttribute | _rendererUnderlineFormatAttribute | _rendererItalicFormatAttribute | _rendererTextColorAttribute | _rendererBackgroundColorAttribute)

NSComparisonResult nicknameLengthSort(IRCUser *s1, IRCUser *s2, void *context);

typedef uint32_t attr_t;

static void setFlag(attr_t *attrBuf, attr_t flag, NSInteger start, NSInteger len)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + len);
	
	while (target < end) {
		*target |= flag;
		++target;
	}
}

static BOOL isClear(attr_t *attrBuf, attr_t flag, NSInteger start, NSInteger len)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + len);
	
	while (target < end) {
		if (*target & flag) return NO;
		
		++target;
	}
	
	return YES;
}

static NSInteger getNextAttributeRange(attr_t *attrBuf, NSInteger start, NSInteger len)
{
	attr_t target = attrBuf[start];
	
	for (NSInteger i = start; i < len; ++i) {
		attr_t t = attrBuf[i];
		
		if (NSDissimilarObjects(t, target)) {
			return (i - start);
		}
	}
	
	return (len - start);
}

NSComparisonResult nicknameLengthSort(IRCUser *s1, IRCUser *s2, void *context) 
{
	return (s1.nick.length <= s2.nick.length);
}

NSString *logEscape(NSString *s)
{
	return [s.gtm_stringByEscapingForHTML stringByReplacingOccurrencesOfString:@"  " withString:@" &nbsp;"];
}

NSString *logEscapeWithNil(NSString *s)
{
    NSString *escaped = logEscape(s);
    
    if (NSObjectIsEmpty(escaped)) {
        return NSStringEmptyPlaceholder;
    }
    
    return escaped;
}

NSInteger mapColorValue(NSColor *color)
{
	NSArray *possibleColors = [NSColor possibleFormatterColors];
	
	if ([color numberOfComponents] == 4) {
		CGFloat _redc   = [color redComponent];
		CGFloat _bluec  = [color blueComponent];
		CGFloat _greenc = [color greenComponent];
		CGFloat _alphac = [color alphaComponent];
		
		for (NSInteger i = 0; i <= 15; i++) {
			NSArray *allColors = possibleColors[i];
			
			for (NSColor *mapped in allColors) {
				if ([mapped numberOfComponents] == 4) {
					CGFloat redc   = [mapped redComponent];
					CGFloat bluec  = [mapped blueComponent];
					CGFloat greenc = [mapped greenComponent];
					CGFloat alphac = [mapped alphaComponent];
					
					if (TXDirtyCGFloatsMatch(_redc, redc)     && TXDirtyCGFloatsMatch(_bluec, bluec) &&
						TXDirtyCGFloatsMatch(_greenc, greenc) && TXDirtyCGFloatsMatch(_alphac, alphac)) {
						
						return i;
					}
				} else {
					if ([color isEqual:mapped]) {
						return i;
					}
				}
			}
		}
	} else {
		for (NSInteger i = 0; i <= 15; i++) {
			NSColor *mapped = mapColorCode(i);
			
			if ([color isEqual:mapped]) {
				return i;
			}
		}
	}
	
	return -1;
}

NSColor *mapColorCode(NSInteger colorChar) 
{
	/* See NSColorHelper.m under Helpers */
	
	switch (colorChar) {
		case 0:  return [NSColor formatterWhiteColor];
		case 1:  return [NSColor formatterBlackColor];
		case 2:  return [NSColor formatterNavyBlueColor]; 
		case 3:  return [NSColor formatterDarkGreenColor];
		case 4:  return [NSColor formatterRedColor];
		case 5:  return [NSColor formatterBrownColor];
		case 6:  return [NSColor formatterPurpleColor];
		case 7:  return [NSColor formatterOrangeColor];
		case 8:  return [NSColor formatterYellowColor];
		case 9:  return [NSColor formatterLimeGreenColor];
		case 10: return [NSColor formatterTealColor];
		case 11: return [NSColor formatterAquaCyanColor];
		case 12: return [NSColor formatterLightBlueColor];
		case 13: return [NSColor formatterFuchsiaPinkColor];
		case 14: return [NSColor formatterNormalGrayColor];
		case 15: return [NSColor formatterLightGrayColor];
	}
	
	return nil;
}

static NSMutableAttributedString *renderAttributedRange(NSMutableAttributedString *body, attr_t attr, NSInteger start, NSInteger len, NSFont *font)
{
	NSRange r = NSMakeRange(start, len);
	
	if (attr & _effectMask) {
		NSFont *boldItalic = font;
		
		if (attr & _rendererBoldFormatAttribute) {
			boldItalic = [_NSFontManager() convertFont:boldItalic toHaveTrait:NSBoldFontMask];
		}
		
		if (attr & _rendererItalicFormatAttribute) {
			boldItalic = [_NSFontManager() convertFont:boldItalic toHaveTrait:NSItalicFontMask];
            
            if ([boldItalic fontTraitSet:NSItalicFontMask] == NO) {
                boldItalic = [boldItalic convertToItalics];
            }
        }
		
		if (boldItalic) {
			[body addAttribute:NSFontAttributeName value:boldItalic range:r];
		}
		
		if (attr & _rendererUnderlineFormatAttribute) {
			[body addAttribute:NSUnderlineStyleAttributeName value:@(NSSingleUnderlineStyle) range:r];
		}
		
		if (attr & _rendererTextColorAttribute) {
			NSInteger colorCode = (attr & _textColorMask);
			
			[body addAttribute:NSForegroundColorAttributeName value:mapColorCode(colorCode) range:r];
		}
		
		if (attr & _rendererBackgroundColorAttribute) {
			NSInteger colorCode = ((attr & _backgroundColorMask) >> 4);
			
			[body addAttribute:NSBackgroundColorAttributeName value:mapColorCode(colorCode) range:r];
		}
	}
	
	return body;
}

static NSString *renderRange(NSString *body, attr_t attr, NSInteger start, NSInteger len, TVCLogController *log)
{
	NSString *content = [body safeSubstringWithRange:NSMakeRange(start, len)];
	
	if (attr & _rendererURLAttribute) {
		NSString *link = content;
		
		if ([link contains:@"://"] == NO) {
			link = [NSString stringWithFormat:@"http://%@", link];
		}	
		
		return [NSString stringWithFormat:@"<a href=\"%@\" class=\"url\" oncontextmenu=\"Textual.on_url()\">%@</a>", link, logEscape(content)];
	} else if (attr & _rendererChannelNameAttribute) {
		return [NSString stringWithFormat:@"<span class=\"channel\" ondblclick=\"Textual.on_dblclick_chname()\" oncontextmenu=\"Textual.on_chname()\">%@</span>", logEscape(content)];
	} else {
		BOOL matchedUser = NO;
		
		content = logEscape(content);
		
		NSMutableString *s = [NSMutableString string];
		
		if (attr & _rendererConversationTrackerAttribute) {
            IRCClient   *client = log.client;
			IRCUser     *user   = [log.channel findMember:content options:NSCaseInsensitiveSearch];
			
			if (PointerIsEmpty(user) == NO) {
                if ([user.nick isEqualNoCase:client.myNick] == NO) {
                    matchedUser = YES;
					
                    [s appendFormat:@"<span class=\"inline_nickname\" ondblclick=\"Textual.on_dblclick_ct_nick()\" oncontextmenu=\"Textual.on_ct_nick()\" colornumber=\"%d\">", [user colorNumber]];
                } 
            }
		}
		
		if (attr & _effectMask) {
			[s appendString:@"<span class=\"effect\" style=\""];
			
			if (attr & _rendererBoldFormatAttribute)	   [s appendString:@"font-weight:bold;"];
			if (attr & _rendererItalicFormatAttribute)    [s appendString:@"font-style:italic;"];
			if (attr & _rendererUnderlineFormatAttribute) [s appendString:@"text-decoration:underline;"];
			
			[s appendString:@"\""];
			
			if (attr & _rendererTextColorAttribute)		  [s appendFormat:@" color-number=\"%d\"", (attr & _textColorMask)];
			if (attr & _rendererBackgroundColorAttribute) [s appendFormat:@" bgcolor-number=\"%d\"", (attr & _backgroundColorMask) >> 4];
			
			[s appendFormat:@">%@</span>", content];
		} else {
			if (matchedUser == NO) {
				return content;
			} else {
				[s appendString:content];
			}
		}
		
		if (matchedUser) {
			[s appendString:@"</span>"];
		}
		
		return s;
	}
}

@implementation LVCLogRenderer

+ (NSString *)renderBody:(NSString *)body 
			  controller:(TVCLogController *)log
			  renderType:(TVCLogRendererType)drawingType
			  properties:(NSDictionary *)inputDictionary
			  resultInfo:(NSDictionary **)outputDictionary
{
	NSMutableDictionary *resultInfo = [NSMutableDictionary dictionary];
	
	BOOL renderLinks	   = [inputDictionary boolForKey:@"renderLinks"];
	BOOL exactWordMatching = ([TPCPreferences keywordMatchingMethod] == TXNicknameHighlightExactMatchType);
    BOOL regexWordMatching = ([TPCPreferences keywordMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType);
	
	NSArray *keywords	  = [inputDictionary arrayForKey:@"keywords"];
	NSArray *excludeWords = [inputDictionary arrayForKey:@"excludeWords"];
    
    NSFont *attributedStringFont = inputDictionary[@"attributedStringFont"];
	
	NSInteger len	= [body length];
	NSInteger start = 0;
	NSInteger n		= 0;
	
	attr_t attrBuf[len];
	attr_t currentAttr = 0;
	
	memset(attrBuf, 0, (len * sizeof(attr_t)));
	
	UniChar dest[len];
	UniChar source[len];
	
	CFStringGetCharacters((__bridge CFStringRef)body, CFRangeMake(0, len), source);
	
	for (NSInteger i = 0; i < len; i++) {
		UniChar c = source[i];
		
		if (c < 0x20) {
			switch (c) {
				case 0x02:
				{
					if (currentAttr & _rendererBoldFormatAttribute) {
						currentAttr &= ~_rendererBoldFormatAttribute;
					} else {
						currentAttr |= _rendererBoldFormatAttribute;
					}
					
					continue;
				}
				case 0x03:
				{
					NSInteger textColor       = -1;
					NSInteger backgroundColor = -1;
					
					if ((i + 1) < len) {
						c = source[i+1];
						
						if (TXIsNumeric(c)) {
							++i;
							
							textColor = (c - '0');
							
							if ((i + 1) < len) {
								c = source[i+1];
								
								if (TXIsIRCColor(c, textColor)) {
									++i;
									
									textColor = (textColor * 10 + c - '0');
								}
								
								if ((i + 1) < len) {
									c = source[i+1];
									
									if (c == ',') {
										++i;
										
										if ((i + 1) < len) {
											c = source[i+1];
											
											if (TXIsNumeric(c)) {
												++i;
												
												backgroundColor = (c - '0');
												
												if ((i + 1) < len) {
													c = source[i+1];
													
													if (TXIsIRCColor(c, backgroundColor)) {
														++i;
														
														backgroundColor = (backgroundColor * 10 + c - '0');
													}
												}
											} else {
												i--;
											}
										}
									}
								}
							}
						}
						
						currentAttr &= ~(_rendererTextColorAttribute | _rendererBackgroundColorAttribute | 0xFF);
						
						if (backgroundColor >= 0) {
							backgroundColor %= 16;
							
							currentAttr |= _rendererBackgroundColorAttribute;
							currentAttr |= (backgroundColor << 4) & _backgroundColorMask;
						} else {
							currentAttr &= ~(_rendererBackgroundColorAttribute | _backgroundColorMask);
						}
						
						if (textColor >= 0) {
							textColor %= 16;
							
							currentAttr |= _rendererTextColorAttribute;
							currentAttr |= textColor & _textColorMask;
						} else {
							currentAttr &= ~(_rendererTextColorAttribute | _textColorMask);
						}
					}
					continue;
				}
				case 0x0F:
				{
					currentAttr = 0;
					continue;
				}
				case 0x16:
				{
					if (currentAttr & _rendererItalicFormatAttribute) {
						currentAttr &= ~_rendererItalicFormatAttribute;
					} else {
						currentAttr |= _rendererItalicFormatAttribute;
					}
					
					continue;
				}
				case 0x1F:
				{
					if (currentAttr & _rendererUnderlineFormatAttribute) {
						currentAttr &= ~_rendererUnderlineFormatAttribute;
					} else {
						currentAttr |= _rendererUnderlineFormatAttribute;
					}
					
					continue;
				}
			}
		}
		
		attrBuf[n] = currentAttr;
		dest[n++] = c;
	}
	
	len = n;
	body = [NSString stringWithCharacters:dest length:n];
	
	if (drawingType == TVCLogRendererHTMLType) {
		/* Links */
		
		if (renderLinks) {
			NSMutableArray *urlAry = [NSMutableArray array];
			
			NSArray *urlAryRanges = [TLOLinkParser locatedLinksForString:body];
			
			if (NSObjectIsNotEmpty(urlAryRanges)) {
				for (NSString *rn in urlAryRanges) {
					NSRange r = NSRangeFromString(rn);
					
					if (r.length >= 1) {
						setFlag(attrBuf, _rendererURLAttribute, r.location, r.length);
						
						[urlAry safeAddObject:[NSValue valueWithRange:r]];
					}
				}
			}
			
			resultInfo[@"URLRanges"] = urlAry;
		}
		
		/* Word Matching — Highlights */
		
		BOOL foundKeyword = NO;
		
		NSMutableArray *excludeRanges = [NSMutableArray array];
		
		if (exactWordMatching == NO) {
			for (NSString *excludeWord in excludeWords) {
				start = 0;
				
				while (start < len) {
					NSRange r = [body rangeOfString:excludeWord 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(start, (len - start))];
					
					if (r.location == NSNotFound) {
						break;
					}
					
					[excludeRanges safeAddObject:[NSValue valueWithRange:r]];
					
					start = (NSMaxRange(r) + 1);
				}
			}
		}
		
        if (regexWordMatching) {
            for (NSString *keyword in keywords) {
                NSRange matchRange = [TLORegularExpression string:body rangeOfRegex:keyword withoutCase:YES];
                
                if (matchRange.location == NSNotFound) {
                    continue;
                } else {
                    BOOL enabled = YES;
                    
                    for (NSValue *e in excludeRanges) {
                        if (NSIntersectionRange(matchRange, [e rangeValue]).length > 0) {
                            enabled = NO;
                            
                            break;
                        }
                    }
                    
                    if (enabled) {
                        setFlag(attrBuf, _rendererKeywordHighlightAttribute, matchRange.location, matchRange.length);
                        
                        foundKeyword = YES;
                        
                        break;
                    }
                }
            }
        } else {
			NSString *curchan; 
			
			if (log) {
				curchan = log.channel.name;
			}
			
            for (__strong NSString *keyword in keywords) {
				BOOL continueSearch = YES;
				
				if ([keyword contains:@";"] && ([keyword contains:@"-"] || [keyword contains:@"+"])) {
					NSRange atsrange = [keyword rangeOfString:@";" options:NSBackwardsSearch];
					
					NSString *excludeList = [keyword safeSubstringAfterIndex:atsrange.location];
					
					keyword = [keyword safeSubstringToIndex:atsrange.location];
					
					NSArray *excldlist = [excludeList split:NSStringWhitespacePlaceholder];
					
					for (NSString *exchan in excldlist) {
						if ([exchan hasPrefix:@"-"] == NO && [exchan hasPrefix:@"+"] == NO) {
							continue;
						}
						
						NSString *nchan = [exchan safeSubstringFromIndex:1];
						
						if ([nchan isEqualToString:@"all"]) {
							continueSearch = NO;
						}
						
						if ([exchan hasPrefix:@"+"]) {
							if ([nchan isEqualNoCase:curchan]) {
								continueSearch = YES;
							}
						} else {
							if ([exchan hasPrefix:@"-"]) {
								if ([nchan isEqualNoCase:curchan]) {
									continueSearch = NO;
								}
							}
						}
					}
				}
				
				if (continueSearch) {
					start = 0;
					
					while (start < len) {
						NSRange r = [body rangeOfString:keyword 
												options:NSCaseInsensitiveSearch 
												  range:NSMakeRange(start, (len - start))];
						
						if (r.location == NSNotFound) {
							break;
						}
						
						BOOL enabled = YES;
						
						for (NSValue *e in excludeRanges) {
							if (NSIntersectionRange(r, [e rangeValue]).length > 0) {
								enabled = NO;
								
								break;
							}
						}
						
						if (exactWordMatching) {
							if (enabled) {
								UniChar c = [body characterAtIndex:r.location];
								
								if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
									NSInteger prev = (r.location - 1);
									
									if (0 <= prev && prev < len) {
										UniChar c = [body characterAtIndex:prev];
										
										if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
											enabled = NO;
										}
									}
								}
							}
							
							if (enabled) {
								UniChar c = [body characterAtIndex:(NSMaxRange(r) - 1)];
								
								if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
									NSInteger next = NSMaxRange(r);
									
									if (next < len) {
										UniChar c = [body characterAtIndex:next];
										
										if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
											enabled = NO;
										}
									}
								}
							}
						}
						
						if (enabled) {
							if (isClear(attrBuf, _rendererURLAttribute, r.location, r.length)) {
								setFlag(attrBuf, _rendererKeywordHighlightAttribute, r.location, r.length);
								
								foundKeyword = YES;
								
								break;
							}
						}
						
						start = (NSMaxRange(r) + 1);
					}
					
					if (foundKeyword) break;
				}
            }
        }
        
		[resultInfo setBool:foundKeyword forKey:@"wordMatchFound"];
		
		/* Channel Name Detection */
		
		start = 0;
		
		while (start < len) {
			NSRange r = [body rangeOfChannelNameStart:start];
			
			if (r.location == NSNotFound) {
				break;
			}
			
			if (isClear(attrBuf, _rendererURLAttribute, r.location, r.length)) {
				setFlag(attrBuf, _rendererChannelNameAttribute, r.location, r.length);
			}
			
			start = (NSMaxRange(r) + 1);
		}
		
		/* Conversation Tracking */
		
		if ([TPCPreferences trackConversations]) {
			if (log) {
				IRCChannel *log_channel = log.channel;
				
				if (log_channel) {
					NSArray *channel_members = [[NSArray arrayWithArray:log_channel.members] sortedArrayUsingFunction:nicknameLengthSort context:nil];
					
					if (channel_members) {
						for (IRCUser *user in channel_members) {
							start = 0;
							
							while (start < len) {
								NSRange r = [body rangeOfString:user.nick 
														options:NSCaseInsensitiveSearch 
														  range:NSMakeRange(start, (len - start))];
								
								if (r.location == NSNotFound) {
									break;
								}
								
								BOOL cleanMatch = YES;
								
								UniChar c = [body characterAtIndex:r.location];
								
								if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
									NSInteger prev = (r.location - 1);
									
									if (0 <= prev && prev < len) {
										UniChar c = [body characterAtIndex:prev];
										
										if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
											cleanMatch = NO;
										}
									}
								}
								
								if (cleanMatch) {
									UniChar c = [body characterAtIndex:(NSMaxRange(r) - 1)];
									
									if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
										NSInteger next = NSMaxRange(r);
										
										if (next < len) {
											UniChar c = [body characterAtIndex:next];
											
											if ([THOUnicodeHelper isAlphabeticalCodePoint:c]) {
												cleanMatch = NO;
											}
										}
									}
								}
								
								if (cleanMatch) {
									if (isClear(attrBuf, _rendererURLAttribute, r.location, r.length) &&
										isClear(attrBuf, _rendererKeywordHighlightAttribute, r.location, r.length)) {
										
										setFlag(attrBuf, _rendererConversationTrackerAttribute, r.location, r.length);
									}
								}
								
								start = (NSMaxRange(r) + 1);
							}
						}
					}
				}
			}
		}
		
		if (PointerIsEmpty(outputDictionary) == NO) {
			*outputDictionary = resultInfo;
		}
	}
	
	/* Draw Actual Result */
	
	id result = nil;
	
	if (drawingType == TVCLogRendererAttributedStringType) {
		result = [[NSMutableAttributedString alloc] initWithString:body];
	} else {
		result = [NSMutableString string];
	}
	
	start = 0;
	
	while (start < len) {
		NSInteger n = getNextAttributeRange(attrBuf, start, len);
		
		if (n <= 0) break;
		
		attr_t t = attrBuf[start];
		
		if (drawingType == TVCLogRendererAttributedStringType) {
			result = renderAttributedRange(result, t, start, n, attributedStringFont);	
		} else {
			[result appendString:renderRange(body, t, start, n, log)];
		}
		
		start += n;
	}
	
	return result;
}

@end