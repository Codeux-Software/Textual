/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

typedef uint32_t attr_t;

@interface TVCLogRenderer ()
{
	void *_effectAttributes;
}

@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) id finalResult;
@property (nonatomic, uweak) TVCLogController *controller;
@property (nonatomic, strong) NSMutableDictionary *outputDictionary;
@property (nonatomic, copy) NSDictionary *rendererAttributes;
@property (nonatomic, assign) BOOL cancelRender;
@property (nonatomic, assign) NSInteger rendererIsRenderingLinkIndex;
@end

NSString * const TVCLogRendererConfigurationShouldRenderLinksAttribute			= @"TVCLogRendererConfigurationShouldRenderLinksAttribute";
NSString * const TVCLogRendererConfigurationLineTypeAttribute					= @"TVCLogRendererConfigurationLineTypeAttribute";
NSString * const TVCLogRendererConfigurationMemberTypeAttribute					= @"TVCLogRendererConfigurationMemberTypeAttribute";
NSString * const TVCLogRendererConfigurationHighlightKeywordsAttribute			= @"TVCLogRendererConfigurationHighlightKeywordsAttribute";
NSString * const TVCLogRendererConfigurationExcludedKeywordsAttribute			= @"TVCLogRendererConfigurationExcludedKeywordsAttribute";

NSString * const TVCLogRendererConfigurationAttributedStringPreferredFontAttribute			= @"TVCLogRendererConfigurationAttributedStringPreferredFontAttribute";
NSString * const TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute		= @"TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute";

NSString * const TVCLogRendererResultsRangesOfAllLinksInBodyAttribute			= @"TVCLogRendererResultsRangesOfAllLinksInBodyAttribute";
NSString * const TVCLogRendererResultsUniqueListOfAllLinksInBodyAttribute		= @"TVCLogRendererResultsUniqueListOfAllLinksInBodyAttribute";
NSString * const TVCLogRendererResultsKeywordMatchFoundAttribute				= @"TVCLogRendererResultsKeywordMatchFoundAttribute";
NSString * const TVCLogRendererResultsListOfUsersFoundAttribute					= @"TVCLogRendererResultsListOfUsersFoundAttribute";
NSString * const TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute		= @"TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute";

#pragma mark -

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

#define TXDirtyCGFloatMatch(s, r)			[NSNumber compareCGFloat:s toFloat:r]

#pragma mark -

/*
static void resetRange(attr_t *attrBuf, NSInteger start, NSInteger len)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + len);

	while (target < end) {
		*target = 0;

		++target;
	}
}
*/

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

#pragma mark -

@implementation TVCLogRenderer

- (instancetype)init
{
	if ((self = [super init])) {
		_rendererIsRenderingLinkIndex = NSNotFound;
	}

	return self;
}

/* Given body, strip effects, place them in a attr_t, and return the 
 body without the effects that were defined in the attr_t */
- (void)buildEffectsDictionary
{
	NSInteger length = [_body length];

	NSInteger n	= 0;

	attr_t attrBuf[length];
	attr_t currentAttr = 0;

	memset(attrBuf, 0, (length * sizeof(attr_t)));

	UniChar dest[length];
	UniChar source[length];

	CFStringGetCharacters((__bridge CFStringRef)_body, CFRangeMake(0, length), source);

	for (NSInteger i = 0; i < length; i++) {
		UniChar c = source[i];

		if (c < 0x20) {
			switch (c) {
				case IRCTextFormatterBoldEffectCharacter:
				{
					if (currentAttr & _rendererBoldFormatAttribute) {
						currentAttr &= ~_rendererBoldFormatAttribute;
					} else {
						currentAttr |= _rendererBoldFormatAttribute;
					}

					continue;
				}
				case IRCTextFormatterColorEffectCharacter:
				{
					NSInteger foregoundColor  = -1;
					NSInteger backgroundColor = -1;

					if ((i + 1) < length) {
						c = source[(i + 1)];

						if (CSCEF_StringIsBase10Numeric(c)) {
							++i;

							foregoundColor = (c - '0');

							if ((i + 1) < length) {
								c = source[(i + 1)];

								if (CSCEF_StringIsBase10Numeric(c)) {
									++i;

									foregoundColor = (foregoundColor * 10 + c - '0');
								}

								if ((i + 1) < length) {
									c = source[(i + 1)];
								}
							}
						}

						/* It's possible for an IRC client to send formatting with only a comma
						 and the background color digit. Therefore, this logic is independent
						 of the logic shown above for the foreground color. */
						if (c == ',') {
							++i;

							if ((i + 1) < length) {
								c = source[(i + 1)];

								if (CSCEF_StringIsBase10Numeric(c)) {
									++i;

									backgroundColor = (c - '0');

									if ((i + 1) < length) {
										c = source[(i + 1)];

										if (CSCEF_StringIsBase10Numeric(c)) {
											++i;

											backgroundColor = (backgroundColor * 10 + c - '0');
										}
									}
								} else {
									i--;
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
				case IRCTextFormatterTerminatingCharacter:
				{
					currentAttr = 0;

					continue;
				}
				case IRCTextFormatterItalicEffectCharacter:
				case 0x16: // Old character used for italic text
				{
					if (currentAttr & _rendererItalicFormatAttribute) {
						currentAttr &= ~_rendererItalicFormatAttribute;
					} else {
						currentAttr |= _rendererItalicFormatAttribute;
					}

					continue;
				}
				case IRCTextFormatterUnderlineEffectCharacter:
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

	NSString *stringBody = [NSString stringWithCharacters:dest length:n];

	_body = [stringBody copy];

	_outputDictionary[TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute] = stringBody;

	NSInteger bufferSize = sizeof(attrBuf);

	_effectAttributes = malloc(bufferSize);

	memcpy(_effectAttributes, attrBuf, bufferSize);
}

- (BOOL)isRenderingPRIVMSG
{
	TVCLogLineType lineType = [_rendererAttributes integerForKey:TVCLogRendererConfigurationLineTypeAttribute];

	return (lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLineActionType);
}

- (BOOL)isRenderingPRIVMSG_or_NOTICE
{
	TVCLogLineType lineType = [_rendererAttributes integerForKey:TVCLogRendererConfigurationLineTypeAttribute];

	return (lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLineActionType || lineType == TVCLogLineNoticeType);
}

- (BOOL)scanForKeywords
{
	TVCLogLineMemberType memberType = [_rendererAttributes integerForKey:TVCLogRendererConfigurationMemberTypeAttribute];

	return ([self isRenderingPRIVMSG] || memberType == TVCLogLineMemberNormalType);
}

- (void)stripDangerousUnicodeCharactersFromBody
{
	if ([TPCPreferences automaticallyFilterUnicodeTextSpam]) {
		TVCLogLineType lineType = [_rendererAttributes integerForKey:TVCLogRendererConfigurationLineTypeAttribute];

		if (lineType == TVCLogLineActionType			||
			lineType == TVCLogLineCTCPType				||
			lineType == TVCLogLineDCCFileTransferType	||
			lineType == TVCLogLineNoticeType			||
			lineType == TVCLogLinePrivateMessageType	||
			lineType == TVCLogLineTopicType)
		{
			NSString * const replacementCharacter = [NSString stringWithFormat:@"%C", 0xfffd];

			NSString *fixedString = [XRRegularExpression string:_body replacedByRegex:@"\\p{InCombining_Diacritical_Marks}" withString:replacementCharacter];

			_body = [fixedString copy];
		}
	}
}

- (void)buildListOfLinksInBody
{
	BOOL renderLinks = [_rendererAttributes boolForKey:TVCLogRendererConfigurationShouldRenderLinksAttribute];

	if (renderLinks) {
		NSMutableDictionary *urlAry = [NSMutableDictionary dictionary];

		NSArray *urlAryRanges = [TLOLinkParser locatedLinksForString:_body];

		for (NSArray *rn in urlAryRanges) {
			NSRange r = NSRangeFromString(rn[0]);

			if (r.length > 0) {
				/* Strip existing effects and apply section as URL. */
				// resetRange(_effectAttributes, r.location, r.length);

				setFlag(_effectAttributes, _rendererURLAttribute, r.location, r.length);

				/* Build unique list of URLs by using them as keys. */
				NSString *matchedURL = rn[1];

				NSString *hashedValue = [matchedURL md5];

				if (urlAry[hashedValue] == nil) {
					urlAry[hashedValue] = matchedURL;
				}
			}
		}

		_outputDictionary[TVCLogRendererResultsRangesOfAllLinksInBodyAttribute] = urlAryRanges;
		_outputDictionary[TVCLogRendererResultsUniqueListOfAllLinksInBodyAttribute] = urlAry;
	}
}

- (void)matchKeywords
{
	if ([self scanForKeywords]) {
		id highlightWords = [_rendererAttributes arrayForKey:TVCLogRendererConfigurationHighlightKeywordsAttribute];
		id excludedWords = [_rendererAttributes arrayForKey:TVCLogRendererConfigurationExcludedKeywordsAttribute];

		PointerIsEmptyAssert(_controller);

		IRCClient *client = [_controller associatedClient];
		IRCChannel *channel = [_controller associatedChannel];

		NSArray *clientHighlightList = [[client config] highlightList];

		if ([clientHighlightList count] > 0) {
			highlightWords = [highlightWords mutableCopy];

			excludedWords = [excludedWords mutableCopy];
		}

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
					[excludedWords addObjectWithoutDuplication:[e matchKeyword]];
				} else {
					[highlightWords addObjectWithoutDuplication:[e matchKeyword]];
				}
			}
		}

		BOOL foundKeyword = NO;

		NSMutableArray *excludeRanges = [NSMutableArray array];

		/* Exclude word matching. */
		NSInteger start = 0;
		NSInteger length = [_body length];

		for (NSString *excludeWord in excludedWords) {
			while (start < length) {
				NSRange r = [_body rangeOfString:excludeWord
										options:NSCaseInsensitiveSearch
										  range:NSMakeRange(start, (length - start))];

				if (r.location == NSNotFound) {
					break;
				}

				[excludeRanges addObject:[NSValue valueWithRange:r]];

				start = (NSMaxRange(r) + 1);
			}

			start = 0;
		}

		switch ([TPCPreferences highlightMatchingMethod]) {
			case TXNicknameHighlightExactMatchType:
			case TXNicknameHighlightPartialMatchType:
			{
				[self matchKeywordsUsingNormalMatching:highlightWords excludedRanges:excludeRanges foundKeyword:&foundKeyword];

				break;
			}
			case TXNicknameHighlightRegularExpressionMatchType:
			{
				[self matchKeywordsUsingRegularExpression:highlightWords excludedRanges:excludeRanges foundKeyword:&foundKeyword];

				break;
			}
		}

		[_outputDictionary setBool:foundKeyword forKey:TVCLogRendererResultsKeywordMatchFoundAttribute];
	}
}

- (void)matchKeywordsUsingNormalMatching:(NSArray *)keywrods excludedRanges:(NSArray *)excludedRanges foundKeyword:(BOOL *)foundKeyword
{
	/* Normal keyword matching. Partial and absolute. */
	for (__strong NSString *keyword in keywrods) {
		NSInteger start = 0;
		NSInteger length = [_body length];

		while (start < length) {
			NSRange r = [_body rangeOfString:keyword
									 options:NSCaseInsensitiveSearch
									   range:NSMakeRange(start, (length - start))];

			if (r.location == NSNotFound) {
				break;
			}

			BOOL enabled = YES;

			for (NSValue *e in excludedRanges) {
				if (NSIntersectionRange(r, e.rangeValue).length > 0) {
					enabled = NO;

					break;
				}
			}

			if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightExactMatchType) {
				enabled = [self sectionOfBodyIsSurroundedByNonAlphabeticals:r];
			}

			if (enabled) {
				if (isClear(_effectAttributes, _rendererURLAttribute, r.location, r.length)) {
					setFlag(_effectAttributes, _rendererKeywordHighlightAttribute, r.location, r.length);

					if ( foundKeyword) {
						*foundKeyword = YES;
					}

					break;
				}
			}

			start = (NSMaxRange(r) + 1);
		}

		/* We break after finding a keyword because as long as there is one
		 amongst many, that is all the end user really cares about. */
		if (foundKeyword) {
			if (*foundKeyword) {
				break;
			}
		}
	}
}

- (void)matchKeywordsUsingRegularExpression:(NSArray *)keywords excludedRanges:(NSArray *)excludedRanges foundKeyword:(BOOL *)foundKeyword
{
	/* Regular expression keyword matching. */
	for (NSString *keyword in keywords) {
		NSRange matchRange = [XRRegularExpression string:_body rangeOfRegex:keyword withoutCase:YES];

		if (matchRange.location == NSNotFound) {
			continue;
		} else {
			BOOL enabled = YES;

			for (NSValue *e in excludedRanges) {
				/* Did the regular expression find a match inside an excluded range? */
				if (NSIntersectionRange(matchRange, e.rangeValue).length > 0) {
					enabled = NO;

					break;
				}
			}

			/* Found a match. */
			if (enabled) {
				if (isClear(_effectAttributes, _rendererURLAttribute, matchRange.location, matchRange.length)) {
					setFlag(_effectAttributes, _rendererKeywordHighlightAttribute, matchRange.location, matchRange.length);

					if ( foundKeyword) {
						*foundKeyword = YES;
					}

					break; // break from first for loop ending search
				}
			}
		}
	}
}

- (void)findAllChannelNames
{
	if ([self isRenderingPRIVMSG_or_NOTICE]) {
		NSInteger start = 0;
		NSInteger length = [_body length];

		while (start < length) {
			NSRange r = [_body rangeOfNextSegmentMatchingRegularExpression:@"#([a-zA-Z0-9\\#\\-]+)" startingAt:start];

			if (r.location == NSNotFound) {
				break;
			}

			NSInteger prev = (r.location - 1);

			if (0 <= prev && prev < length) {
				UniChar c = [_body characterAtIndex:prev];

				if (CSCEF_StringIsWordLetter(c)) {
					break;
				}
			}

			NSInteger next = NSMaxRange(r);

			if (next < length) {
				UniChar c = [_body characterAtIndex:next];

				if (CSCEF_StringIsWordLetter(c)) {
					break;
				}
			}

			if (isClear(_effectAttributes, _rendererURLAttribute, r.location, r.length)) {
				setFlag(_effectAttributes, _rendererChannelNameAttribute, r.location, r.length);
			}

			start = (NSMaxRange(r) + 1);
		}
	}
}

- (BOOL)sectionOfBodyIsSurroundedByNonAlphabeticals:(NSRange)r
{
	BOOL cleanMatch = YES;

	NSInteger length = [_body length];

	UniChar c = [_body characterAtIndex:r.location];

	if ([THOUnicodeHelper isAlphabeticalCodePoint:c] || CSCEF_StringIsBase10Numeric(c)) {
		NSInteger prev = (r.location - 1);

		if (0 <= prev && prev < length) {
			UniChar cc = [_body characterAtIndex:prev];

			if ([THOUnicodeHelper isAlphabeticalCodePoint:cc] || CSCEF_StringIsBase10Numeric(cc)) {
				cleanMatch = NO;
			}
		}
	}

	if (cleanMatch) {
		UniChar cc = [_body characterAtIndex:(NSMaxRange(r) - 1)];

		if ([THOUnicodeHelper isAlphabeticalCodePoint:cc] || CSCEF_StringIsBase10Numeric(cc)) {
			NSInteger next = NSMaxRange(r);

			if (next < length) {
				UniChar ccc = [_body characterAtIndex:next];

				if ([THOUnicodeHelper isAlphabeticalCodePoint:ccc] || CSCEF_StringIsBase10Numeric(ccc)) {
					cleanMatch = NO;
				}
			}
		}
	}

	return cleanMatch;
}

- (void)scanBodyForChannelUsers
{
	if ([self isRenderingPRIVMSG]) {
		PointerIsEmptyAssert(_controller);

		IRCClient *client = [_controller associatedClient];
		IRCChannel *channel = [_controller associatedChannel];

		NSInteger totalNicknameLength = 0;
		NSInteger totalNicknameCount = 0;

		NSMutableSet *mentionedUsers = [NSMutableSet set];

		NSArray *sortedMembers = [channel memberListSortedByNicknameLength];

		NSInteger start = 0;
		NSInteger length = [_body length];

		for (IRCUser *user in sortedMembers) {
			while (start < length) {
				NSRange r = [_body rangeOfString:[user nickname]
										 options:NSCaseInsensitiveSearch
										   range:NSMakeRange(start, (length - start))];

				if (r.location == NSNotFound) {
					break;
				}

				BOOL cleanMatch = [self sectionOfBodyIsSurroundedByNonAlphabeticals:r];

				if (cleanMatch) {
					if (isClear(_effectAttributes, _rendererURLAttribute, r.location, r.length) &&
						isClear(_effectAttributes, _rendererKeywordHighlightAttribute, r.location, r.length))
					{
						/* Check if the nickname conversation tracking found is matched to an ignore
						 that is set to hide them. */
						IRCAddressBookEntry *ignoreCheck = [client checkIgnoreAgainstHostmask:[user hostmask] withMatches:@[@"hideMessagesContainingMatch"]];

						if (ignoreCheck && [ignoreCheck ignoreMessagesContainingMatchh]) {
							_cancelRender = YES;

							return; // Break from this method.
						}

						/* Continue normally. */
						setFlag(_effectAttributes, _rendererConversationTrackerAttribute, r.location, r.length);

						totalNicknameCount += 1;
						totalNicknameLength += [[user nickname] length];

						[mentionedUsers addObject:user];
					}
				}

				start = (NSMaxRange(r) + 1);
			}

			start = 0;
		}

		if ([mentionedUsers count] > 0) {
			/* Calculate how much of the body length is actually nicknames.
			 This is used when trying to stop highlight spam messages.
			 By design, Textual counts anything above 75% spam. It
			 also only begins counting after a certain number of
			 users are present in the message. */
			if ([TPCPreferences automaticallyDetectHighlightSpam]) {
				CGFloat nhsp = (((CGFloat)totalNicknameLength / (CGFloat)length) * 100.00f);

				if (nhsp > 75.0f && totalNicknameCount > 10) {
					[_outputDictionary setBool:NO forKey:TVCLogRendererResultsKeywordMatchFoundAttribute];
				}
			}

			/* Return list of mentioned users. This list is used to update weights. */
			_outputDictionary[TVCLogRendererResultsListOfUsersFoundAttribute] = [mentionedUsers allObjects];
		} else {
			_outputDictionary[TVCLogRendererResultsListOfUsersFoundAttribute] = [NSSet set];
		}
	} else {
		_outputDictionary[TVCLogRendererResultsListOfUsersFoundAttribute] = [NSSet set];
	}
}

- (id)renderAttributedRange:(NSMutableAttributedString *)body attributes:(attr_t)attrArray start:(NSUInteger)rangeStart length:(NSUInteger)rangeLength
{
	NSRange r = NSMakeRange(rangeStart, rangeLength);

	NSFont *defaultFont = _rendererAttributes[TVCLogRendererConfigurationAttributedStringPreferredFontAttribute];

	if (defaultFont == nil) {
		NSAssert(NO, @"FATAL ERROR: TVCLogRenderer cannot be supplied with a nil 'TVCLogRendererAttributedStringPreferredFontAttribute' attribute when rendering an attributed string");
	}

	NSColor *defaultColor = _rendererAttributes[TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute];

	if (attrArray & _effectMask) {
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
		} else {
			if (defaultColor) {
				[body addAttribute:NSForegroundColorAttributeName value:defaultColor range:r];
			}
		}

		if (attrArray & _rendererBackgroundColorAttribute) {
			NSInteger colorCode = ((attrArray & _backgroundColorMask) >> 4);

			[body addAttribute:NSBackgroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:r];
		}
	} else {
		[body addAttribute:NSFontAttributeName value:defaultFont range:r];

		if (defaultColor) {
			[body addAttribute:NSForegroundColorAttributeName value:defaultColor range:r];
		}
	}

	return body;
}

- (id)renderRange:(NSString *)body attributes:(attr_t)attrArray start:(NSUInteger)rangeStart length:(NSUInteger)rangeLength
{
	NSString *unescapedContent = [body substringWithRange:NSMakeRange(rangeStart, rangeLength)];

	NSString *escapedContent = [TVCLogRenderer escapeString:unescapedContent];

	NSString *messageFragment = nil;

	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];

	if (attrArray & _rendererURLAttribute)
	{
		templateTokens[@"anchorTitle"] = escapedContent;

		/* Go over all ranges and associated URLs instead of asking 
		 parser for same URL again and doing double the work. */
		for (NSArray *rn in _outputDictionary[TVCLogRendererResultsRangesOfAllLinksInBodyAttribute]) {
			NSRange r = NSRangeFromString(rn[0]);

			if (r.location == _rendererIsRenderingLinkIndex) {
				templateTokens[@"anchorLocation"] = rn[1];
			}
		}

		/* Find unique ID (if any?). */
		if (     _controller) {
			if ([_controller inlineImagesEnabledForView]) {
				NSDictionary *urlMatches = [_outputDictionary dictionaryForKey:TVCLogRendererResultsUniqueListOfAllLinksInBodyAttribute];

				NSString *hashedValue = [templateTokens[@"anchorLocation"] md5];

				if ([urlMatches containsKey:hashedValue]) {
					templateTokens[@"anchorInlineImageAvailable"] = @(YES);
					templateTokens[@"anchorInlineImageUniqueID"] = hashedValue;
				}
			}
		}

		/* Render template. */
		messageFragment = [TVCLogRenderer renderTemplate:@"renderedStandardAnchorLinkResource" attributes:templateTokens];
	}
	else if (attrArray & _rendererChannelNameAttribute)
	{
		templateTokens[@"channelName"] = escapedContent;

		messageFragment = [TVCLogRenderer renderTemplate:@"renderedChannelNameLinkResource" attributes:templateTokens];
	}
	else if (attrArray & _rendererConversationTrackerAttribute)
	{
		templateTokens[@"messageFragment"] = escapedContent;

		if ([TPCPreferences disableNicknameColorHashing] == YES) {
			templateTokens[@"inlineNicknameMatchFound"] = @(NO);
		} else {
			if (_controller) {
				IRCClient *u = [_controller associatedClient];
				IRCChannel *c = [_controller associatedChannel];

				IRCUser *user = [c findMember:escapedContent];

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
							if ([modeSymbol isEqualToString:@"+"] || [modeSymbol isEqualToString:@"-"]) {
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
	}

	if (messageFragment == nil) {
		messageFragment = escapedContent;
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

			/* If a background color is set, but a foreground one is not, we supply a value
			 of -1 for the foreground color to trigger the template to add appropriate 
			 HTML for defining color elements. */
			if ((attrArray & _rendererTextColorAttribute) == NO) {
				templateTokens[@"fragmentTextColorIsSet"] = @(YES);
				templateTokens[@"fragmentTextColor"] = @(-1);
			}
		}

		/* Escape spaces that are prefix and suffix characters. */
		if ([messageFragment hasPrefix:NSStringWhitespacePlaceholder]) {
			 messageFragment = [messageFragment stringByReplacingCharactersInRange:NSMakeRange(0, 1)
																	   withString:@"&nbsp;"];
		}

		if ([messageFragment hasSuffix:NSStringWhitespacePlaceholder]) {
			 messageFragment = [messageFragment stringByReplacingCharactersInRange:NSMakeRange(([escapedContent length] - 1), 1)
																	 withString:@"&nbsp;"];
		}
	}

	// --- //

	templateTokens[@"messageFragment"] = messageFragment;

	return [TVCLogRenderer renderTemplate:@"formattedMessageFragment" attributes:templateTokens];
}

- (void)renderFinalResultsForPlainTextBody
{
	NSMutableString *result = [NSMutableString string];

	NSInteger start = 0;
	NSInteger length = [_body length];

	while (start < length) {
		NSInteger n = getNextAttributeRange(_effectAttributes, start, length);

		NSAssertReturnLoopBreak(n > 0);

		attr_t t = ((attr_t *)_effectAttributes)[start];

		BOOL attributesIncludeURL = ((t & _rendererURLAttribute) == _rendererURLAttribute);

		if (_rendererIsRenderingLinkIndex == NSNotFound) {
			if (attributesIncludeURL) {
				_rendererIsRenderingLinkIndex = start;
			}
		} else {
			if (attributesIncludeURL == NO) {
				_rendererIsRenderingLinkIndex = NSNotFound;
			}
		}

		id renderedSegment = [self renderRange:_body attributes:t start:start length:n];

		if (renderedSegment) {
			[result appendString:renderedSegment];
		}

		start += n;
	}

	_finalResult = [result copy];
}

- (void)renderFinalResultsForAttributedBody
{
	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:_body attributes:nil];

	NSInteger start = 0;
	NSInteger length = [_body length];

	while (start < length) {
		NSInteger n = getNextAttributeRange(_effectAttributes, start, length);

		NSAssertReturnLoopBreak(n > 0);

		attr_t t = ((attr_t *)_effectAttributes)[start];

		result = [self renderAttributedRange:result attributes:t start:start length:n];

		start += n;
	}

	_finalResult = [result copy];
}

- (void)cleanUpResources
{
	if (_effectAttributes) {
		free(_effectAttributes);
	}
}

+ (NSString *)renderBody:(NSString *)body forController:(TVCLogController *)controller withAttributes:(NSDictionary *)inputDictionary resultInfo:(NSDictionary *__autoreleasing *)outputDictionary
{
	if (body == nil) {
		NSAssert(NO, @"'body' cannot be nil");
	}

	if ([body length] <= 0) {
		return NSStringEmptyPlaceholder;
	}

	if (controller == nil) {
		NSAssert(NO, @"nil 'controller'");
	}

	TVCLogRenderer *renderer = [TVCLogRenderer new];

	[renderer setController:controller];

	NSMutableDictionary *resultInfo = [NSMutableDictionary dictionary];

	[renderer setOutputDictionary:resultInfo];

	if (inputDictionary == nil) {
		LogToConsole(@"WARNING: TVCLogRenderer is not designed to be supplied a nil inputDictionary. Please supply an inputDictionary value.");
		LogToConsoleCurrentStackTrace

		[renderer setRendererAttributes:@{}];
	} else {
		[renderer setRendererAttributes:inputDictionary];
	}

	body = [sharedPluginManager() postWillRenderMessageEvent:body
										   forViewController:controller
													lineType:[inputDictionary integerForKey:TVCLogRendererConfigurationLineTypeAttribute]
												  memberType:[inputDictionary integerForKey:TVCLogRendererConfigurationMemberTypeAttribute]];

	[renderer setBody:body];

	[renderer buildEffectsDictionary];
	[renderer stripDangerousUnicodeCharactersFromBody];
	[renderer buildListOfLinksInBody];
	[renderer matchKeywords];
	[renderer findAllChannelNames];
	[renderer scanBodyForChannelUsers];

	if ( outputDictionary) {
		*outputDictionary = [[renderer outputDictionary] copy];
	}

	if ([renderer cancelRender]) {
		return nil;
	} else {
		[renderer renderFinalResultsForPlainTextBody];
	}

	[renderer cleanUpResources];

	return [renderer finalResult];
}

+ (NSAttributedString *)renderBodyIntoAttributedString:(NSString *)body withAttributes:(NSDictionary *)attributes
{
	if (body == nil) {
		NSAssert(NO, @"'body' cannot be nil");
	}

	if ([body length] <= 0) {
		return [[NSAttributedString alloc] initWithString:NSStringEmptyPlaceholder attributes:nil];
	}

	TVCLogRenderer *renderer = [TVCLogRenderer new];

	NSMutableDictionary *resultInfo = [NSMutableDictionary dictionary];

	if (attributes == nil) {
		NSAssert(NO, @"FATAL ERROR: TVCLogRenderer cannot be supplied with a nil 'attributes' parameter when rendering an attributed string");
	} else {
		[renderer setRendererAttributes:attributes];
	}

	[renderer setOutputDictionary:resultInfo];

	[renderer setBody:body];

	[renderer buildEffectsDictionary];
	[renderer stripDangerousUnicodeCharactersFromBody];

	if ([renderer cancelRender]) {
		return nil;
	} else {
		[renderer renderFinalResultsForAttributedBody];
	}

	[renderer cleanUpResources];

	return [renderer finalResult];
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
