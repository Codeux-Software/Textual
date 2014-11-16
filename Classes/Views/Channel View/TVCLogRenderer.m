/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

typedef uint32_t attr_t;

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

static void resetRange(attr_t *attrBuf, NSInteger start, NSInteger len)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + len);

	while (target < end) {
		*target = 0;

		++target;
	}
}

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
		if (*target & flag) {
			return NO;
		}
		
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

@implementation TVCLogRenderer

// ====================================================== //
// Begin renderer.										  //
// ====================================================== //

+ (id)renderAttributedRange:(NSMutableAttributedString *)body attributes:(attr_t)attrArray start:(NSUInteger)rangeStart length:(NSUInteger)rangeLength baseFont:(NSFont *)defaultFont
{
	NSRange r = NSMakeRange(rangeStart, rangeLength);

	if (attrArray & _effectMask)
	{
		NSFont *boldItalic = defaultFont;

		if (attrArray & _rendererBoldFormatAttribute) {
			boldItalic = [RZFontManager() convertFont:boldItalic toHaveTrait:NSBoldFontMask];
		}

		if (attrArray & _rendererItalicFormatAttribute) {
			boldItalic = [RZFontManager() convertFont:boldItalic toHaveTrait:NSItalicFontMask];

            if ([boldItalic fontTraitSet:NSItalicFontMask] == NO) {
                boldItalic = [boldItalic convertToItalics];
            }
        }

		if (boldItalic) {
			[body addAttribute:NSFontAttributeName value:boldItalic range:r];
		}

		if (attrArray & _rendererUnderlineFormatAttribute) {
			[body addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:r];
		}

		if (attrArray & _rendererTextColorAttribute) {
			NSInteger colorCode = (attrArray & _textColorMask);

			[body addAttribute:NSForegroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:r];
		}

		if (attrArray & _rendererBackgroundColorAttribute) {
			NSInteger colorCode = ((attrArray & _backgroundColorMask) >> 4);

			[body addAttribute:NSBackgroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:r];
		}
	}

	return body;
}

+ (id)renderRange:(NSString *)body attributes:(attr_t)attrArray start:(NSUInteger)rangeStart length:(NSUInteger)rangeLength for:(TVCLogController *)logController context:(NSDictionary *)resultContext
{
	NSString *contentne = [body substringWithRange:NSMakeRange(rangeStart, rangeLength)];

	NSString *contentes = [TVCLogRenderer escapeString:contentne];

	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];

	if (attrArray & _rendererURLAttribute)
	{
		templateTokens[@"anchorTitle"]		=  contentes;
	   //templateTokens[@"anchorLocation"]	= [contentne stringWithValidURIScheme];

		/* Go over all ranges and associated URLs instead of asking 
		 parser for same URL again and doing double the work. */
		for (NSArray *rn in resultContext[@"allHyperlinksInBody"]) {
			NSRange r = NSRangeFromString(rn[0]);

			if (r.location == rangeStart) {
				templateTokens[@"anchorLocation"] = rn[1];
			}
		}

		/* Find unique ID (if any?). */
		if (resultContext && [logController inlineImagesEnabledForView]) {
			NSDictionary *urlMatches = [resultContext dictionaryForKey:@"InlineImageURLMatches"];

			NSString *keyValue = urlMatches[templateTokens[@"anchorLocation"]];

			if (keyValue) {
				templateTokens[@"anchorInlineImageAvailable"] = @(YES);
				templateTokens[@"anchorInlineImageUniqueID"] = keyValue;
			}
		}

		/* Render template. */
		return [TVCLogRenderer renderTemplate:@"renderedStandardAnchorLinkResource" attributes:templateTokens];
	}
	else if (attrArray & _rendererChannelNameAttribute)
	{
		templateTokens[@"channelName"] = contentes;

		return [TVCLogRenderer renderTemplate:@"renderedChannelNameLinkResource" attributes:templateTokens];
	}
	else
	{
		if (attrArray & _rendererConversationTrackerAttribute) {
			templateTokens[@"messageFragment"] = contentes;

			if ([TPCPreferences disableNicknameColorHashing] == YES) {
				templateTokens[@"inlineNicknameMatchFound"] = @(NO);
			} else {
				IRCClient *u = [logController associatedClient];
				IRCChannel *c = [logController associatedChannel];
				
				IRCUser *user = [c findMember:contentes];

				if (user) {
					if (NSObjectsAreEqual([user nickname], [u localNickname]) == NO)
					{
						NSString *modeSymbol = NSStringEmptyPlaceholder;
						
						if ([TPCPreferences conversationTrackingIncludesUserModeSymbol]) {
							NSString *usermark = [user mark];
							
							if (rangeStart > 0) {
								if (usermark) {
									NSString *prevchar = [body stringCharacterAtIndex:(rangeStart - 1)];

									if ([prevchar isEqualToString:usermark] == NO) {
										modeSymbol = usermark;
									}
								}
							} else {
								if (usermark) {
									modeSymbol = usermark;
								}
							}
						}
						
						/* If nickname length = 1 and mode char is +, then we ignore it
						 becasue someone with nick "m" becoming "+m" might be confused
						 for a mode symbol. Same could apply to - too, but I do not know
						 of any network that uses that for status symbol. */
						if ([[user nickname] length] == 1) {
							if ([modeSymbol isEqualToString:@"+"]) {
								modeSymbol = NSStringEmptyPlaceholder;
							}
						}
						
						templateTokens[@"inlineNicknameMatchFound"] = @(YES);
						templateTokens[@"inlineNicknameColorNumber"] = @([user colorNumber]);
						templateTokens[@"inlineNicknameUserModeSymbol"] = modeSymbol;
					}
				}
			}
		}

		// --- //

		if (attrArray & _effectMask) {
			templateTokens[@"fragmentContainsFormattingSymbols"] = @(YES);

			if (attrArray & _rendererBoldFormatAttribute) {
				templateTokens[@"fragmentIsBold"] = @(YES);
			}

			if (attrArray & _rendererItalicFormatAttribute) {
				templateTokens[@"fragmentIsItalicized"] = @(YES);
			}

			if (attrArray & _rendererUnderlineFormatAttribute) {
				templateTokens[@"fragmentIsUnderlined"] = @(YES);
			}

			if (attrArray & _rendererTextColorAttribute) {
				NSInteger colorCode = (attrArray & _textColorMask);

				/* We have to tell the template that the color is actually set
				 because if it only checked the value of "fragmentTextColor" in
				 an if statement the color white (code 0) would not show because
				 zero would show as a null value to the if statement. */
				
				templateTokens[@"fragmentTextColorIsSet"] = @(YES);
				templateTokens[@"fragmentTextColor"] = @(colorCode);
			}

			if (attrArray & _rendererBackgroundColorAttribute) {
				NSInteger colorCode = ((attrArray & _backgroundColorMask) >> 4);

				templateTokens[@"fragmentBackgroundColorIsSet"] = @(YES);
				templateTokens[@"fragmentBackgroundColor"] = @(colorCode);
			}

			/* Escape spaces that are prefix and suffix characters. */
			if ([contentes hasPrefix:NSStringWhitespacePlaceholder]) {
				contentes = [contentes stringByReplacingCharactersInRange:NSMakeRange(0, 1)
															   withString:@"&nbsp;"];
			}

			if ([contentes hasSuffix:NSStringWhitespacePlaceholder]) {
				contentes = [contentes stringByReplacingCharactersInRange:NSMakeRange(([contentes length] - 1), 1)
															   withString:@"&nbsp;"];
			}
		}

		/* Define content. */
		templateTokens[@"messageFragment"] = contentes;

		// --- //

		return [TVCLogRenderer renderTemplate:@"formattedMessageFragment" attributes:templateTokens];
	}
}

+ (NSString *)renderBody:(NSString *)body 
			  controller:(TVCLogController *)log
			  renderType:(TVCLogRendererType)drawingType
			  properties:(NSDictionary *)inputDictionary
			  resultInfo:(NSDictionary **)outputDictionary
{
	NSMutableDictionary *resultInfo = [NSMutableDictionary dictionary];

	/* Input information. */
	BOOL renderLinks = [inputDictionary boolForKey:@"renderLinks"];
	BOOL isNormalMsg = [inputDictionary boolForKey:@"isNormalMessage"];
	BOOL isPlainText = [inputDictionary boolForKey:@"isPlainTextMessage"];

	BOOL exactWordMatching = ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightExactMatchType);
    BOOL regexWordMatching = ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType);

	TVCLogLineType lineType	= [inputDictionary integerForKey:@"lineType"];
	TVCLogLineMemberType memberType	= [inputDictionary integerForKey:@"memberType"];
	
	IRCClient *client = [log associatedClient];
	IRCChannel *channel = [log associatedChannel];
	
	IRCClientConfig *clientConfig = [client config];
	
	id highlightWords = [inputDictionary arrayForKey:@"highlightKeywords"];
	id excludeWords	= [inputDictionary arrayForKey:@"excludeKeywords"];
	
	NSArray *clientHighlightList = nil;

	/* Only bother spending time creating a copy if we actually need them. */
	if (isPlainText) {
		clientHighlightList = [clientConfig highlightList];

		if ([clientHighlightList count] >= 1) {
			highlightWords = [highlightWords mutableCopy];

			excludeWords = [excludeWords mutableCopy];
		}
	}

    NSFont *attributedStringFont = inputDictionary[@"attributedStringFont"];
	
	/* Let plugins have first shot. */
	body = [sharedPluginManager() postWillRenderMessageEvent:body forViewController:log lineType:lineType memberType:memberType];
	
	/* This is the most important part of the entire process of rendering each line.
	 The following code will scan each character of the input body one by one judging
	 each character based on what surrounds it in order to find formatting related to 
	 bold, color, italics, and underline. */
	NSInteger length = [body length];
	NSInteger start  = 0;
	NSInteger n		 = 0;
	
	attr_t attrBuf[length];
	attr_t currentAttr = 0;
	
	memset(attrBuf, 0, (length * sizeof(attr_t)));
	
	UniChar dest[length];
	UniChar source[length];
	
	CFStringGetCharacters((__bridge CFStringRef)body, CFRangeMake(0, length), source);
	
	for (NSInteger i = 0; i < length; i++) {
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
					NSInteger foregoundColor  = -1;
					NSInteger backgroundColor = -1;
					
					if ((i + 1) < length) {
						c = source[(i + 1)];
						
						if (TXStringIsBase10Numeric(c)) {
							++i;
							
							foregoundColor = (c - '0');
							
							if ((i + 1) < length) {
								c = source[(i + 1)];
								
								if (TXStringIsBase10Numeric(c)) {
									++i;
									
									foregoundColor = (foregoundColor * 10 + c - '0');
								}
								
								if ((i + 1) < length) {
									c = source[(i + 1)];
									
									if (c == ',') {
										++i;
										
										if ((i + 1) < length) {
											c = source[(i + 1)];
											
											if (TXStringIsBase10Numeric(c)) {
												++i;
												
												backgroundColor = (c - '0');
												
												if ((i + 1) < length) {
													c = source[(i + 1)];
													
													if (TXStringIsBase10Numeric(c)) {
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
							currentAttr |= ((backgroundColor << 4) & _backgroundColorMask);
						} else {
							currentAttr &= ~(_rendererBackgroundColorAttribute | _backgroundColorMask);
						}
						
						if (foregoundColor >= 0) {
							foregoundColor %= 16;
							
							currentAttr |= _rendererTextColorAttribute;
							currentAttr |= (foregoundColor & _textColorMask);
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
				case 0x1d:
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

	/* Now that we have scanned the input body for all fomatting characters,
	 we will now build upon the string minus those. */
	body = [NSString stringWithCharacters:dest length:n];

	length = [body length];
	
	/* We set this because if a plugin was sent the messageBody value of the line
	 sent to the renderer, then the value may be different than what appears in 
	 here because a plugin can still intercept the renderer value which is set 
	 as /body/. Therefore, we set the renderer value to the output dictionary. */
	resultInfo[@"messageBody"] = body;
	
	/* When rendering a message as HTML output, TVCLogRenderer takes pride 
	 in finding as much information about the message as possible. Information
	 that it looks for includes nicknames from the channel the message is being
	 sent to, any links (with or without a scheme), highlight keywords, and
	 channel names. This information is completely ignored when rendering the
	 body into an attributed string. */

	if (drawingType == TVCLogRendererHTMLType) {
		/* Kill common Zalgo characters. */
		if ([TPCPreferences automaticallyFilterUnicodeTextSpam]) {
			if (lineType == TVCLogLineActionType			||
				lineType == TVCLogLineCTCPType				||
				lineType == TVCLogLineDCCFileTransferType	||
				lineType == TVCLogLineNoticeType			||
				lineType == TVCLogLinePrivateMessageType	||
				lineType == TVCLogLineTopicType)
			{
				NSString *replacementCharacter = [NSString stringWithFormat:@"%C", 0xfffd];
					
				body = [TLORegularExpression string:body replacedByRegex:@"\\p{InCombining_Diacritical_Marks}" withString:replacementCharacter];
			}
		}
			
		/* Scan the body for links. */
		if (renderLinks) {
			NSMutableDictionary *urlAry = [NSMutableDictionary dictionary];

			/* Do scan. */
			NSArray *urlAryRanges = [TLOLinkParser locatedLinksForString:body];

			for (NSArray *rn in urlAryRanges) {
				NSRange r = NSRangeFromString(rn[0]);

				if (r.length >= 1) {
					/* Do not allow IRC formatting in URL. */
					resetRange(attrBuf, r.location, r.length);

					/* Mark range as URL */
					setFlag(attrBuf, _rendererURLAttribute, r.location, r.length);
					
					if (isNormalMsg && [log inlineImagesEnabledForView]) {
						/* Get URL from returned array. */
						NSString *matchedURL = rn[1];

						/* We search for a key matching this string. */
						NSString *keyMatch = urlAry[matchedURL];

						/* Do we have a key already or no? */
						if (keyMatch == nil) {
							/* If we do not already have a key, then we add one. */
							NSString *itemID = [NSString stringWithUUID];

							urlAry[matchedURL] = itemID;
						}
					}
				}
			}

			resultInfo[@"allHyperlinksInBody"] = urlAryRanges;
			resultInfo[@"InlineImageURLMatches"] = urlAry;
		} else {
			resultInfo[@"allHyperlinksInBody"] = @[];
		}

		if (isPlainText) {
			/* Add server/channel specific matches. */
			for (TDCHighlightEntryMatchCondition *e in clientHighlightList) {
				BOOL addKeyword = NO;
				
				NSString *matchChannel = [e matchChannelID];

				if ([matchChannel length] > 0) {
					NSString *channelID = [channel uniqueIdentifier];

					if ([matchChannel isEqualToString:channelID]) {
						addKeyword = YES;
					}
				} else {
					addKeyword = YES;
				}

				if (addKeyword) {
					if ([e matchIsExcluded]) {
						[excludeWords addObjectWithoutDuplication:[e matchKeyword]];
					} else {
						[highlightWords addObjectWithoutDuplication:[e matchKeyword]];
					}
				}
			}
			
			/* Word Matching — Highlights. */
			BOOL foundKeyword = NO;
			
			NSMutableArray *excludeRanges = [NSMutableArray array];

			/* Exclude word matching. */
			for (NSString *excludeWord in excludeWords) {
				start = 0;
				
				while (start < length) {
					NSRange r = [body rangeOfString:excludeWord 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(start, (length - start))];
					
					if (r.location == NSNotFound) {
						break;
					}
					
					[excludeRanges addObject:[NSValue valueWithRange:r]];
					
					start = (NSMaxRange(r) + 1);
				}
			}

			if (regexWordMatching) {
				/* Regular expression keyword matching. */
				for (NSString *keyword in highlightWords) {
					NSRange matchRange = [TLORegularExpression string:body rangeOfRegex:keyword withoutCase:YES];
					
					if (matchRange.location == NSNotFound) {
						continue;
					} else {
						BOOL enabled = YES;
						
						for (NSValue *e in excludeRanges) {
							/* Did the regular expression find a match inside an excluded range? */
							if (NSIntersectionRange(matchRange, e.rangeValue).length > 0) {
								enabled = NO;
								
								break;
							}
						}

						/* Found a match. */
						if (enabled) {
							if (isClear(attrBuf, _rendererURLAttribute, matchRange.location, matchRange.length)) {
								setFlag(attrBuf, _rendererKeywordHighlightAttribute, matchRange.location, matchRange.length);
								
								foundKeyword = YES;
								
								break;
							}
						}
					}
				}
			} else {
				/* Normal keyword matching. Partial and absolute. */
				for (__strong NSString *keyword in highlightWords) {
					start = 0;

					while (start < length) {
						NSRange r = [body rangeOfString:keyword
												options:NSCaseInsensitiveSearch
												  range:NSMakeRange(start, (length - start))];

						if (r.location == NSNotFound) {
							break;
						}

						BOOL enabled = YES;

						for (NSValue *e in excludeRanges) {
							if (NSIntersectionRange(r, e.rangeValue).length > 0) {
								enabled = NO;

								break;
							}
						}

						if (exactWordMatching) {
							if (enabled) {
								UniChar c = [body characterAtIndex:r.location];

								if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
									NSInteger prev = (r.location - 1);

									if (0 <= prev && prev < length) {
										UniChar c = [body characterAtIndex:prev];

										if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
											enabled = NO;
										}
									}
								}
							}

							if (enabled) {
								UniChar c = [body characterAtIndex:(NSMaxRange(r) - 1)];

								if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
									NSInteger next = NSMaxRange(r);

									if (next < length) {
										UniChar c = [body characterAtIndex:next];

										if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
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

					/* We break after finding a keyword because as long as there is one
					 amongst many, that is all the end user really cares about. */
					if (foundKeyword) {
						break;
					}

				}
			}

			[resultInfo setBool:foundKeyword forKey:@"wordMatchFound"];

			/* Channel Name Detection. */
			start = 0;

			while (start < length) {
				NSRange r = [body rangeOfNextSegmentMatchingRegularExpression:@"#([a-zA-Z0-9\\#\\-]+)" startingAt:start];

				if (r.location == NSNotFound) {
					break;
				}
				
				NSInteger prev = (r.location - 1);
				
				if (0 <= prev && prev < length) {
					UniChar c = [body characterAtIndex:prev];
					
					if (TXStringIsWordLetter(c)) {
						break;
					}
				}
				
				NSInteger next = NSMaxRange(r);
				
				if (next < length) {
					UniChar c = [body characterAtIndex:next];
					
					if (TXStringIsWordLetter(c)) {
						break;
					}
				}

				if (isClear(attrBuf, _rendererURLAttribute, r.location, r.length)) {
					setFlag(attrBuf, _rendererChannelNameAttribute, r.location, r.length);
				}

				start = (NSMaxRange(r) + 1);
			}

			/* Conversation Tracking */
			if (isNormalMsg) {
				NSInteger totalNicknameLength = 0;
				NSInteger totalNicknameCount = 0;

				NSMutableSet *mentionedUsers = [NSMutableSet set];

				NSArray *sortedMembers = [channel memberListSortedByNicknameLength];

				for (IRCUser *user in sortedMembers) {
					start = 0;

					PointerIsEmptyAssertLoopContinue(user);

					while (start < length) {
						NSRange r = [body rangeOfString:[user nickname]
												options:NSCaseInsensitiveSearch
												  range:NSMakeRange(start, (length - start))];

						if (r.location == NSNotFound) {
							break;
						}

						BOOL cleanMatch = YES;

						UniChar c = [body characterAtIndex:r.location];

						if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
							NSInteger prev = (r.location - 1);

							if (0 <= prev && prev < length) {
								UniChar c = [body characterAtIndex:prev];

								if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
									cleanMatch = NO;
								}
							}
						}

						if (cleanMatch) {
							UniChar c = [body characterAtIndex:(NSMaxRange(r) - 1)];

							if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
								NSInteger next = NSMaxRange(r);

								if (next < length) {
									UniChar c = [body characterAtIndex:next];

									if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || TXStringIsBase10Numeric(c)) {
										cleanMatch = NO;
									}
								}
							}
						}

						if (cleanMatch) {
							if (isClear(attrBuf, _rendererURLAttribute, r.location, r.length) &&
								isClear(attrBuf, _rendererKeywordHighlightAttribute, r.location, r.length))
							{
								/* Check if the nickname conversation tracking found is matched to an ignore
								 that is set to hide them. */
								IRCAddressBookEntry *ignoreCheck = [client checkIgnoreAgainstHostmask:[user hostmask] withMatches:@[@"hideMessagesContainingMatch"]];

								if (ignoreCheck && [ignoreCheck hideMessagesContainingMatch]) {
									if (outputDictionary) {
										*outputDictionary = @{@"containsIgnoredNickname" : @(YES)};
									}

									return nil;
								}

								/* Continue normally. */
								setFlag(attrBuf, _rendererConversationTrackerAttribute, r.location, r.length);

								totalNicknameCount += 1;
								totalNicknameLength += [[user nickname] length];

								[mentionedUsers addObject:user];
							}
						}

						start = (NSMaxRange(r) + 1);
					}
				}

				if ([mentionedUsers count] > 0) {
					/* Calculate how much of the body length is actually nicknames. 
					 This is used when trying to stop highlight spam messages.
					 By design, Textual counts anything above 75% spam. It
					 also only begins counting after a certain number of 
					 users are present in the message. */
					if ([TPCPreferences automaticallyDetectHighlightSpam]) {
						CGFloat nhsp = (((CGFloat)totalNicknameLength / (CGFloat)body.length) * 100.00f);

						if (nhsp > 75.0f && totalNicknameCount > 10) {
							[resultInfo setBool:NO forKey:@"wordMatchFound"];
						}
					}

					/* Return list of mentioned users. This list is used to update weights. */
					resultInfo[@"mentionedUsers"] = [mentionedUsers allObjects];
				} else {
					resultInfo[@"mentionedUsers"] = [NSSet set];
				}
			} else {
				resultInfo[@"mentionedUsers"] = [NSSet set];
			}
			
			/* End HTML drawing. */
		}
	} // isPlainText

	/* Draw Actual Result */
	id result = nil;
	
	if (drawingType == TVCLogRendererAttributedStringType) {
		result = [NSMutableAttributedString mutableStringWithBase:body attributes:nil];

		[result beginEditing];
	} else {
		result = [NSMutableString string];
	}
	
	start = 0;
	
	while (start < length) {
		NSInteger n = getNextAttributeRange(attrBuf, start, length);

		NSAssertReturnLoopBreak(n > 0);
		
		attr_t t = attrBuf[start];
		
		if (drawingType == TVCLogRendererAttributedStringType) {
			result = [TVCLogRenderer renderAttributedRange:result
												attributes:t
													 start:start
													length:n
												  baseFont:attributedStringFont];
		} else {
			NSString *renderedRange = [TVCLogRenderer renderRange:body
													   attributes:t
															start:start
														   length:n
															  for:log
														  context:resultInfo];

			if ([renderedRange length] > 0) {
				[result appendString:renderedRange];
			}
		}
		
		start += n;
	}

	if (drawingType == TVCLogRendererAttributedStringType) {
		[result endEditing];
	} else {
		/* Prepare output dictionary for HTML render. */
		if (PointerIsEmpty(outputDictionary) == NO) {
			*outputDictionary = resultInfo;
		}
	}
	
	return result;
}

// ====================================================== //
// End renderer.										  //
// ====================================================== //

+ (NSString *)renderTemplate:(NSString *)templateName
{
	return [TVCLogRenderer renderTemplate:templateName attributes:nil];
}

+ (NSString *)renderTemplate:(NSString *)templateName attributes:(NSDictionary *)templateTokens
{
	GRMustacheTemplate *tmpl = [themeSettings() templateWithName:templateName];

	PointerIsEmptyAssertReturn(tmpl, nil);

	NSString *aHtml = [tmpl renderObject:templateTokens error:NULL];

	NSObjectIsEmptyAssertReturn(aHtml, nil);

	return [aHtml removeAllNewlines];
}

+ (NSString *)escapeString:(NSString *)s
{
	s = [s gtm_stringByEscapingForHTML];

	s = [s stringByReplacingOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;"];
	s = [s stringByReplacingOccurrencesOfString:@"  " withString:@"&nbsp;&nbsp;"];

	return s;
}

+ (NSString *)escapeStringWithoutNil:(NSString *)s
{
    NSString *escaped = [TVCLogRenderer escapeString:s];

    if (escaped == nil) {
        return NSStringEmptyPlaceholder;
    }

    return escaped;
}

+ (NSInteger)mapColorValue:(NSColor *)color
{
	NSArray *possibleColors = [NSColor possibleFormatterColors];

	if ([color numberOfComponents] < 4) {
        color = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    }
    
    CGFloat _redc   = [color redComponent];
    CGFloat _bluec  = [color blueComponent];
    CGFloat _greenc = [color greenComponent];
    CGFloat _alphac = [color alphaComponent];

    for (NSInteger i = 0; i <= 15; i++) {
        NSColor *mapped = possibleColors[i];

        if ([mapped numberOfComponents] == 4) {
            CGFloat redc   = [mapped redComponent];
            CGFloat bluec  = [mapped blueComponent];
            CGFloat greenc = [mapped greenComponent];
            CGFloat alphac = [mapped alphaComponent];

            if (TXDirtyCGFloatMatch(_redc, redc)     && TXDirtyCGFloatMatch(_bluec, bluec) &&
                TXDirtyCGFloatMatch(_greenc, greenc) && TXDirtyCGFloatMatch(_alphac, alphac)) {

                return i;
            }
        } else {
            if ([color isEqual:mapped]) {
                return i;
            }
        }
    }

	return -1;
}

+ (NSColor *)mapColorCode:(NSInteger)colorCode
{
	/* See NSColorHelper.m under Helpers */

	switch (colorCode) {
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

@end
