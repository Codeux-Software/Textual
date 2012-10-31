/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#define _rendererURLAttribute					(1 << 31)
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
#define _effectMask				(												\
									_rendererBoldFormatAttribute |				\
									_rendererUnderlineFormatAttribute |			\
									_rendererItalicFormatAttribute |			\
									_rendererTextColorAttribute |				\
									_rendererBackgroundColorAttribute			\
								)

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

NSString *TXRenderStyleTemplate(NSString *templateName, NSDictionary *templateTokens, TVCLogController *logController)
{
	GRMustacheTemplate *tmpl = [logController.theme.other templateWithName:templateName];

	if (PointerIsNotEmpty(tmpl)) {
		
		NSString *aHtml = [tmpl renderObject:templateTokens error:NULL];

		if (NSObjectIsNotEmpty(aHtml)) {
			return aHtml.removeAllNewlines;
		}
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

	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];

	if (attr & _rendererURLAttribute)
	{
		templateTokens[@"anchorLocation"]	= [content stringWithValidURIScheme];
		templateTokens[@"anchorTitle"]		= logEscape(content);

		return TXRenderStyleTemplate(@"renderedStandardAnchorLinkResource", templateTokens, log);
	}
	else if (attr & _rendererChannelNameAttribute)
	{
		templateTokens[@"channelName"] = logEscape(content);
		
		return TXRenderStyleTemplate(@"renderedChannelNameLinkResource", templateTokens, log);
	}
	else
	{
		content = logEscape(content);

		templateTokens[@"messageFragment"] = content;

		// --- //
		
		if (attr & _rendererConversationTrackerAttribute) {
            IRCClient *client =  log.client;
			IRCUser   *user   = [log.channel findMember:content options:NSCaseInsensitiveSearch];
			
			if (PointerIsEmpty(user) == NO) {
                if ([user.nick isEqualNoCase:client.myNick] == NO) {
					templateTokens[@"inlineNicknameMatchFound"]  = @(YES);
					templateTokens[@"inlineNicknameColorNumber"] = @(user.colorNumber);
                } 
            }
		}
		
		// --- //
		
		if (attr & _effectMask) {
			templateTokens[@"fragmentContainsFormattingSymbols"] = @(YES);
			
			if (attr & _rendererBoldFormatAttribute) {
				templateTokens[@"fragmentIsBold"] = @(YES);
			}
			
			if (attr & _rendererItalicFormatAttribute) {
				templateTokens[@"fragmentIsItalicized"] = @(YES);
			}
			
			if (attr & _rendererUnderlineFormatAttribute) {
				templateTokens[@"fragmentIsUnderlined"] = @(YES);
			}
			
			if (attr & _rendererTextColorAttribute) {
				templateTokens[@"fragmentTextColor"] = @(attr & _textColorMask);
			}
			
			if (attr & _rendererBackgroundColorAttribute) {
				templateTokens[@"fragmentBackgroundColor"] = @((attr & _backgroundColorMask) >> 4);
			}
		}

		// --- //

		return TXRenderStyleTemplate(@"formattedMessageFragment", templateTokens, log);
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
	BOOL isNormalMsg	   = [inputDictionary boolForKey:@"isNormalMessage"];
	
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
			NSString *curchan = nil;
			
			if (log && isNormalMsg) {
				curchan = [log.channel.name lowercaseString];
			}

			// ---- //
			
			NSString *curnick;

			curnick = [inputDictionary objectForKey:@"nick"];
			curnick = [curnick lowercaseString];

			// ---- //
			
            for (__strong NSString *keyword in keywords) {
				BOOL continueSearch = YES;
				
				if ([keyword contains:@";"] &&
					([keyword contains:@"-"] || [keyword contains:@"+"])) {
					
					// ---- //
					
					NSRange range = [keyword rangeOfString:@";" options:NSBackwardsSearch];
					
					NSArray *limitList = [[keyword safeSubstringAfterIndex:range.location] split:NSStringWhitespacePlaceholder];

					// ---- //

					keyword = [keyword safeSubstringToIndex:range.location];
					
					NSMutableArray *includeChannels		= [NSMutableArray array];
					NSMutableArray *excludeChannels		= [NSMutableArray array];
					NSMutableArray *includeNicks		= [NSMutableArray array];
					NSMutableArray *excludeNicks		= [NSMutableArray array];
					
					for (__strong NSString *limit in limitList) {
						BOOL include = [limit hasPrefix:@"+"];
						BOOL exclude = [limit hasPrefix:@"-"];
						
						if (exclude == NO && include == NO) {
							continue;
						}
						
						limit = [limit safeSubstringFromIndex:1].lowercaseString;
						
						if ([limit hasPrefix:@"#"]) {
							if (include) {
								[includeChannels addObject:limit];
							} else {
								[excludeChannels addObject:limit];
							}
						} else {
							if (include) {
								[includeNicks addObject:limit];
							} else {
								[excludeNicks addObject:limit];
							}
						}
					}
					
					if (curchan && [curchan hasPrefix:@"#"]) {
						if (NSObjectIsNotEmpty(includeChannels) &&
							NSObjectIsEmpty(excludeChannels)) {
							
							if ([includeChannels containsObject:curchan] == NO) {
								continueSearch = NO;
							}
						} else {
							if ([includeChannels containsObject:curchan]) {
								continueSearch = YES;
							}
							if ([excludeChannels containsObject:curchan]) {
								continueSearch = NO;
							}
						}
					}
					
					if (continueSearch && curnick) {
						if (NSObjectIsNotEmpty(includeNicks) &&
							NSObjectIsEmpty(excludeNicks)) {
							
							if ([includeNicks containsObject:curnick] == NO) {
								continueSearch = NO;
							}
						} else {
							if ([includeNicks containsObject:curnick]) {
								continueSearch = YES;
							}
							if ([excludeNicks containsObject:curnick]) {
								continueSearch = NO;
							}
						}
					} else if (continueSearch && curnick &&
							NSObjectIsNotEmpty(includeNicks) &&
							   NSObjectIsEmpty(excludeNicks)) {

						continueSearch = NO;
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
			if (log && isNormalMsg) {
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
			NSString *renderedRange = renderRange(body, t, start, n, log);
			
			[result appendString:renderedRange];
		}
		
		start += n;
	}
	
	return result;
}

@end