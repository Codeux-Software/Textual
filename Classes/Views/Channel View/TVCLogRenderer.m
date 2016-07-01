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

NS_ASSUME_NONNULL_BEGIN

typedef uint32_t attr_t;

@interface TVCLogRenderer ()
{
	void *_effectAttributes;
}

@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) id finalResult;
@property (nonatomic, assign) NSUInteger rendererIsRenderingLinkIndex;
@property (nonatomic, copy) NSDictionary<NSString *, id> *rendererAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *outputDictionary;
@property (nonatomic, weak) TVCLogController *viewController;
@property (nonatomic, assign) TVCLogLineType lineType;
@property (nonatomic, assign) TVCLogLineMemberType memberType;
@end

NSString * const TVCLogRendererConfigurationRenderLinksAttribute = @"TVCLogRendererConfigurationRenderLinksAttribute";
NSString * const TVCLogRendererConfigurationLineTypeAttribute = @"TVCLogRendererConfigurationLineTypeAttribute";
NSString * const TVCLogRendererConfigurationMemberTypeAttribute = @"TVCLogRendererConfigurationMemberTypeAttribute";
NSString * const TVCLogRendererConfigurationHighlightKeywordsAttribute = @"TVCLogRendererConfigurationHighlightKeywordsAttribute";
NSString * const TVCLogRendererConfigurationExcludedKeywordsAttribute = @"TVCLogRendererConfigurationExcludedKeywordsAttribute";

NSString * const TVCLogRendererConfigurationAttributedStringPreferredFontAttribute = @"TVCLogRendererConfigurationAttributedStringPreferredFontAttribute";
NSString * const TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute = @"TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute";

NSString * const TVCLogRendererResultsListOfLinksInBodyAttribute = @"TVCLogRendererResultsListOfLinksInBodyAttribute";
NSString * const TVCLogRendererResultsListOfLinksMappedInBodyAttribute = @"TVCLogRendererResultsListOfLinksMappedInBodyAttribute";
NSString * const TVCLogRendererResultsKeywordMatchFoundAttribute = @"TVCLogRendererResultsKeywordMatchFoundAttribute";
NSString * const TVCLogRendererResultsListOfUsersFoundAttribute = @"TVCLogRendererResultsListOfUsersFoundAttribute";
NSString * const TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute = @"TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute";

#pragma mark -

#define _rendererURLAttribute					(1 << 10)
#define _rendererChannelNameAttribute			(1 << 11)
#define _rendererBoldFormatAttribute			(1 << 12)
#define _rendererUnderlineFormatAttribute		(1 << 13)
#define _rendererItalicFormatAttribute			(1 << 14)
#define _rendererForegroundColorAttribute		(1 << 15)
#define _rendererBackgroundColorAttribute		(1 << 16)
#define _rendererConversationTrackerAttribute	(1 << 17)
#define _rendererKeywordHighlightAttribute		(1 << 18)
#define _rendererStrikethroughFormatAttribute	(1 << 19)

#define _foregroundColorMask	(0x0F)
#define _backgroundColorMask	(0xF0)

#define _effectMask				(												\
									_rendererBoldFormatAttribute |				\
									_rendererUnderlineFormatAttribute |			\
									_rendererItalicFormatAttribute |			\
									_rendererStrikethroughFormatAttribute |		\
									_rendererForegroundColorAttribute |			\
									_rendererBackgroundColorAttribute			\
								)

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

static void setFlag(attr_t *attrBuf, attr_t flag, NSUInteger start, NSUInteger length)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + length);
	
	while (target < end) {
		*target |= flag;
		
		++target;
	}
}

static BOOL isClear(attr_t *attrBuf, attr_t flag, NSUInteger start, NSUInteger length)
{
	attr_t *target = (attrBuf + start);
	attr_t *end = (target + length);
	
	while (target < end) {
		if (*target & flag) {
			return NO;
		}
		
		++target;
	}
	
	return YES;
}

static NSUInteger getNextAttributeRange(attr_t *attrBuf, NSUInteger start, NSUInteger length)
{
	attr_t target = attrBuf[start];
	
	for (NSUInteger i = start; i < length; i++) {
		attr_t t = attrBuf[i];
		
		if (t != target) {
			return (i - start);
		}
	}
	
	return (length - start);
}

#pragma mark -

@implementation TVCLogRenderer

- (instancetype)init
{
	if ((self = [super init])) {
		self->_outputDictionary = [NSMutableDictionary dictionary];

		self->_rendererIsRenderingLinkIndex = NSNotFound;
	}

	return self;
}

- (void)buildEffectsDictionary
{
	NSString *body = self->_body;

	NSUInteger bodyLength = body.length;

	NSUInteger currentPosition = 0;

	attr_t effectsBuffer[bodyLength];

	attr_t currentEffect = 0;

	memset(effectsBuffer, 0, (bodyLength * sizeof(attr_t)));

	UniChar charactersOut[bodyLength];
	UniChar charactersIn[bodyLength];

	[body getCharacters:charactersIn range:body.range];

	for (NSUInteger i = 0; i < bodyLength; i++) {
		UniChar character = charactersIn[i];

		if (character < 0x20) {
			switch (character) {
				case IRCTextFormatterBoldEffectCharacter:
				{
					if (currentEffect & _rendererBoldFormatAttribute) {
						currentEffect &= ~_rendererBoldFormatAttribute;
					} else {
						currentEffect |= _rendererBoldFormatAttribute;
					}

					continue;
				}
				case IRCTextFormatterColorEffectCharacter:
				{
					NSUInteger foregoundColor = NSNotFound;
					NSUInteger backgroundColor = NSNotFound;

					i += [body colorCodesStartingAt:i foregroundColor:&foregoundColor backgroundColor:&backgroundColor];

					currentEffect &= ~(_rendererForegroundColorAttribute | _rendererBackgroundColorAttribute | 0xFF);

					if (foregoundColor != NSNotFound) {
						foregoundColor %= 16;

						currentEffect |= _rendererForegroundColorAttribute;
						currentEffect |= (foregoundColor & _foregroundColorMask);
					} else {
						currentEffect &= ~(_rendererForegroundColorAttribute | _foregroundColorMask);
					}

					if (backgroundColor != NSNotFound) {
						backgroundColor %= 16;

						currentEffect |= _rendererBackgroundColorAttribute;
						currentEffect |= ((backgroundColor << 4) & _backgroundColorMask);
					} else {
						currentEffect &= ~(_rendererBackgroundColorAttribute | _backgroundColorMask);
					}

					continue;
				}
				case IRCTextFormatterTerminatingCharacter:
				{
					currentEffect = 0;

					continue;
				}
				case IRCTextFormatterItalicEffectCharacter:
				case IRCTextFormatterItalicEffectCharacterOld:
				{
					if (currentEffect & _rendererItalicFormatAttribute) {
						currentEffect &= ~_rendererItalicFormatAttribute;
					} else {
						currentEffect |= _rendererItalicFormatAttribute;
					}

					continue;
				}
				case IRCTextFormatterStrikethroughEffectCharacter:
				{
					if (currentEffect & _rendererStrikethroughFormatAttribute) {
						currentEffect &= ~_rendererStrikethroughFormatAttribute;
					} else {
						currentEffect |= _rendererStrikethroughFormatAttribute;
					}

					continue;
				}
				case IRCTextFormatterUnderlineEffectCharacter:
				{
					if (currentEffect & _rendererUnderlineFormatAttribute) {
						currentEffect &= ~_rendererUnderlineFormatAttribute;
					} else {
						currentEffect |= _rendererUnderlineFormatAttribute;
					}

					continue;
				}
			}
		}

		effectsBuffer[currentPosition] = currentEffect;

		charactersOut[currentPosition++] = character;
	}

	NSUInteger effectsBufferSize = sizeof(effectsBuffer);

	self->_effectAttributes = malloc(effectsBufferSize);

	memcpy(self->_effectAttributes, effectsBuffer, effectsBufferSize);

	NSString *stringWithoutEffects = [NSString stringWithCharacters:charactersOut length:currentPosition];

	self->_outputDictionary[TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute] = stringWithoutEffects;

	self->_body = stringWithoutEffects;
}

- (BOOL)isRenderingPRIVMSG
{
	return (self->_lineType == TVCLogLinePrivateMessageType || self->_lineType == TVCLogLineActionType);
}

- (BOOL)isRenderingPRIVMSG_or_NOTICE
{
	return (self->_lineType == TVCLogLinePrivateMessageType || self->_lineType == TVCLogLineActionType || self->_lineType == TVCLogLineNoticeType);
}

- (BOOL)scanForKeywords
{
	return ([self isRenderingPRIVMSG] && self->_memberType == TVCLogLineMemberNormalType);
}

- (void)stripDangerousUnicodeCharactersFromBody
{
	if ([TPCPreferences automaticallyFilterUnicodeTextSpam] == NO) {
		return;
	}

	if (self->_lineType != TVCLogLineActionType			&&
		self->_lineType != TVCLogLineCTCPType			&&
		self->_lineType != TVCLogLineCTCPQueryType		&&
		self->_lineType != TVCLogLineCTCPReplyType		&&
		self->_lineType != TVCLogLineDCCFileTransferType	&&
		self->_lineType != TVCLogLineNoticeType			&&
		self->_lineType != TVCLogLinePrivateMessageType	&&
		self->_lineType != TVCLogLineTopicType)
	{
		return;
	}

	self->_body =
	[XRRegularExpression string:self->_body
				replacedByRegex:@"\\p{InCombining_Diacritical_Marks}"
					 withString:CS_UnicodeReplacementCharacter];
}

- (void)buildListOfLinksInBody
{
	BOOL renderLinks = [self->_rendererAttributes boolForKey:TVCLogRendererConfigurationRenderLinksAttribute];

	if (renderLinks == NO) {
		return;
	}

	NSMutableDictionary<NSString *, NSString *> *linksMapped = [NSMutableDictionary dictionary];

	NSArray *links = [TLOLinkParser locatedLinksForString:self->_body];

	for (AHHyperlinkScannerResult *link in links) {
		NSRange linkRange = link.range;

		NSString *linkString = link.stringValue;

		setFlag(self->_effectAttributes, _rendererURLAttribute, linkRange.location, linkRange.length);

		if (linksMapped[linkString] == nil) {
			linksMapped[linkString] = link.uniqueIdentifier;
		}
	}

	self->_outputDictionary[TVCLogRendererResultsListOfLinksInBodyAttribute] = links;
	self->_outputDictionary[TVCLogRendererResultsListOfLinksMappedInBodyAttribute] = [linksMapped copy];
}

- (void)matchKeywords
{
	if ([self scanForKeywords] == NO) {
		return;
	}

	id excludedKeywords = [self->_rendererAttributes arrayForKey:TVCLogRendererConfigurationExcludedKeywordsAttribute];
	id highlightKeywords = [self->_rendererAttributes arrayForKey:TVCLogRendererConfigurationHighlightKeywordsAttribute];

	IRCClient *client = self->_viewController.associatedClient;
	IRCChannel *channel = self->_viewController.associatedChannel;

	NSArray *clientHighlightList = client.config.highlightList;

	if (clientHighlightList.count > 0) {
		if (excludedKeywords == nil) {
			excludedKeywords = [NSMutableArray array];
		} else {
			excludedKeywords = [excludedKeywords mutableCopy];
		}

		if (highlightKeywords == nil) {
			highlightKeywords = [NSMutableArray array];
		} else {
			highlightKeywords = [highlightKeywords mutableCopy];
		}
	}

	for (IRCHighlightMatchCondition *e in clientHighlightList) {
		NSString *matchChannelId = e.matchChannelId;

		if (matchChannelId.length > 0) {
			NSString *channelId = channel.uniqueIdentifier;

			if ([matchChannelId isEqualToString:channelId] == NO) {
				continue;
			}
		}

		if (e.matchIsExcluded) {
			[excludedKeywords addObjectWithoutDuplication:e.matchKeyword];
		} else {
			[highlightKeywords addObjectWithoutDuplication:e.matchKeyword];
		}
	}

	if ([highlightKeywords count] == 0) {
		self->_outputDictionary[TVCLogRendererResultsKeywordMatchFoundAttribute] = @(NO);

		return;
	}

	NSMutableArray<NSValue *> *excludeRanges = [NSMutableArray array];

	for (NSString *excludeKeyword in excludedKeywords) {
		[self->_body enumerateMatchesOfString:excludeKeyword withBlock:^(NSRange range, BOOL *stop) {
			[excludeRanges addObject:[NSValue valueWithRange:range]];
		} options:NSCaseInsensitiveSearch];
	}

	BOOL foundKeyword = NO;

	switch ([TPCPreferences highlightMatchingMethod]) {
		case TXNicknameHighlightExactMatchType:
		case TXNicknameHighlightPartialMatchType:
		{
			foundKeyword = [self matchKeywordsUsingNormalMatching:highlightKeywords excludedRanges:excludeRanges];

			break;
		}
		case TXNicknameHighlightRegularExpressionMatchType:
		{
			foundKeyword = [self matchKeywordsUsingRegularExpression:highlightKeywords excludedRanges:excludeRanges];

			break;
		}
	}

	self->_outputDictionary[TVCLogRendererResultsKeywordMatchFoundAttribute] = @(foundKeyword);
}

- (BOOL)matchKeywordsUsingNormalMatching:(NSArray<NSString *> *)keywords excludedRanges:(NSArray<NSValue *> *)excludedRanges
{
	NSParameterAssert(keywords != nil);
	NSParameterAssert(excludedRanges != nil);

	NSString *body = self->_body;

	__block BOOL foundKeyword = NO;

	for (NSString *keyword in keywords) {
		[body enumerateMatchesOfString:keyword withBlock:^(NSRange range, BOOL *stop) {
			for (NSValue *excludedRange in excludedRanges) {
				if (NSIntersectionRange(range, excludedRange.rangeValue).length > 0) {
					return;
				}
			}

			if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightExactMatchType) {
				if ([self sectionOfBodyIsSurroundedByNonAlphabeticals:range] == NO) {
					return;
				}
			}

			if (isClear(_effectAttributes, _rendererURLAttribute, range.location, range.length)) {
				setFlag(_effectAttributes, _rendererKeywordHighlightAttribute, range.location, range.length);

				foundKeyword = YES;

				*stop = YES;
			}
		} options:NSCaseInsensitiveSearch];

		if (foundKeyword) {
			break;
		}
	}

	return foundKeyword;
}

- (BOOL)matchKeywordsUsingRegularExpression:(NSArray<NSString *> *)keywords excludedRanges:(NSArray<NSValue *> *)excludedRanges
{
	NSParameterAssert(keywords != nil);
	NSParameterAssert(excludedRanges != nil);

	NSString *body = self->_body;

	BOOL foundKeyword = NO;

	for (NSString *keyword in keywords) {
		NSRange matchRange = [XRRegularExpression string:body rangeOfRegex:keyword withoutCase:YES];

		if (matchRange.location == NSNotFound) {
			continue;
		}

		BOOL enabled = YES;

		for (NSValue *excludedRange in excludedRanges) {
			if (NSIntersectionRange(matchRange, excludedRange.rangeValue).length > 0) {
				enabled = NO;

				break;
			}
		}

		if (enabled == NO) {
			continue;
		}

		if (isClear(_effectAttributes, _rendererURLAttribute, matchRange.location, matchRange.length)) {
			setFlag(_effectAttributes, _rendererKeywordHighlightAttribute, matchRange.location, matchRange.length);

			foundKeyword = YES;

			break;
		}
	}

	return foundKeyword;
}

- (void)findAllChannelNames
{
	if ([self isRenderingPRIVMSG_or_NOTICE] == NO) {
		return;
	}

	NSString *body = self->_body;

	[body enumerateMatchesOfString:@"#([a-zA-Z0-9\\#\\-]+)" withBlock:^(NSRange range, BOOL *stop) {
		if ([self sectionOfBodyIsSurroundedByNonAlphabeticals:range] == NO) {
			return;
		}

		if (isClear(self->_effectAttributes, _rendererURLAttribute, range.location, range.length)) {
			setFlag(self->_effectAttributes, _rendererChannelNameAttribute, range.location, range.length);
		}
	} options:(NSCaseInsensitiveSearch | NSRegularExpressionSearch)];
}

- (BOOL)sectionOfBodyIsSurroundedByNonAlphabeticals:(NSRange)range
{
	NSString *body = self->_body;

	NSUInteger bodyLength = body.length;

	UniChar aa = [body characterAtIndex:range.location];

	if (CS_StringIsBase10Numeric(aa) || [THOUnicodeHelper isAlphabeticalCodePoint:aa]) {
		NSInteger leftLocation = (range.location - 1);

		if (leftLocation >= 0 && leftLocation < bodyLength) {
			UniChar bb = [body characterAtIndex:leftLocation];

			if (CS_StringIsBase10Numeric(bb) || [THOUnicodeHelper isAlphabeticalCodePoint:bb]) {
				return NO;
			}
		}
	}

	UniChar cc = [body characterAtIndex:(NSMaxRange(range) - 1)];

	if (CS_StringIsBase10Numeric(cc) || [THOUnicodeHelper isAlphabeticalCodePoint:cc]) {
		NSInteger rightLocation = NSMaxRange(range);

		if (rightLocation < bodyLength) {
			UniChar dd = [body characterAtIndex:rightLocation];

			if (CS_StringIsBase10Numeric(dd) || [THOUnicodeHelper isAlphabeticalCodePoint:dd]) {
				return NO;
			}
		}
	}

	return YES;
}

- (void)scanBodyForChannelMembers
{
	if ([self isRenderingPRIVMSG] == NO) {
		return;
	}

	NSString *body = self->_body;

	NSUInteger bodyLength = body.length;

	if (bodyLength == 0) {
		self->_outputDictionary[TVCLogRendererResultsListOfUsersFoundAttribute] = [NSSet set];

		return;
	}

	IRCChannel *channel = self->_viewController.associatedChannel;

	NSArray<IRCUser *> *users = channel.memberListSortedByNicknameLength;

	__block NSUInteger totalNicknameCount = 0;
	__block NSUInteger totalNicknameLength = 0;

	NSMutableSet<IRCUser *> *userSet = [NSMutableSet set];

	for (IRCUser *user in users) {
		[body enumerateMatchesOfString:user.nickname withBlock:^(NSRange range, BOOL *stop) {
			if ([self sectionOfBodyIsSurroundedByNonAlphabeticals:range] == NO) {
				return;
			}

			if (isClear(self->_effectAttributes, _rendererURLAttribute, range.location, range.length)) {
				setFlag(self->_effectAttributes, _rendererConversationTrackerAttribute, range.location, range.length);

				if ([userSet containsObject:user] == NO) {
					[userSet addObject:user];
				}

				if (isClear(_effectAttributes, _rendererKeywordHighlightAttribute, range.location, range.length)) {
					totalNicknameCount += 1;
					totalNicknameLength += range.length;
				}
			}
		} options:NSCaseInsensitiveSearch];
	}

	/* Calculate how much of the message is just nicknames.
	 This is used when trying to stop highlight spam.
	 Textual counts anything above 75% spam. */
	if ([TPCPreferences automaticallyDetectHighlightSpam]) {
		NSUInteger nicknamePercent = ((totalNicknameLength / bodyLength) * 100);

		if (nicknamePercent > 75 && totalNicknameCount > 10) {
			self->_outputDictionary[TVCLogRendererResultsKeywordMatchFoundAttribute] = @(NO);
		}
	}

	self->_outputDictionary[TVCLogRendererResultsListOfUsersFoundAttribute] = [userSet copy];
}

#pragma mark -

- (void)applyAttributes:(attr_t)attributes toAttributedString:(NSMutableAttributedString *)string startingAt:(NSUInteger)rangeStart length:(NSUInteger)rangeLength
{
	NSParameterAssert(string != nil);

	NSRange fragmentRange = NSMakeRange(rangeStart, rangeLength);

	NSFont *defaultFont = self->_rendererAttributes[TVCLogRendererConfigurationAttributedStringPreferredFontAttribute];

	NSColor *defaultFontColor = self->_rendererAttributes[TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute];

	if (attributes & _effectMask) {
		NSFont *boldItalicFont = defaultFont;

		if (attributes & _rendererBoldFormatAttribute) {
			boldItalicFont = [RZFontManager() convertFont:boldItalicFont toHaveTrait:NSBoldFontMask];

			[string addAttribute:IRCTextFormatterBoldAttributeName value:@(YES) range:fragmentRange];
		}

		if (attributes & _rendererItalicFormatAttribute) {
			boldItalicFont = [RZFontManager() convertFont:boldItalicFont toHaveTrait:NSItalicFontMask];

            if ([boldItalicFont fontTraitSet:NSItalicFontMask] == NO) {
                boldItalicFont = boldItalicFont.convertToItalics;
			}
			
			[string addAttribute:IRCTextFormatterItalicAttributeName value:@(YES) range:fragmentRange];
        }

		if (boldItalicFont) {
			[string addAttribute:NSFontAttributeName value:boldItalicFont range:fragmentRange];
		}

		if (attributes & _rendererStrikethroughFormatAttribute) {
			[string addAttribute:IRCTextFormatterStrikethroughAttributeName value:@(YES) range:fragmentRange];

			[string addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:fragmentRange];
		}

		if (attributes & _rendererUnderlineFormatAttribute) {
			[string addAttribute:IRCTextFormatterUnderlineAttributeName value:@(YES) range:fragmentRange];

			[string addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:fragmentRange];
		}

		if (attributes & _rendererForegroundColorAttribute) {
			NSUInteger colorCode = (attributes & _foregroundColorMask);

			[string addAttribute:IRCTextFormatterForegroundColorAttributeName value:@(colorCode) range:fragmentRange];

			[string addAttribute:NSForegroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:fragmentRange];
		} else {
			if (defaultFontColor) {
				[string addAttribute:NSForegroundColorAttributeName value:defaultFontColor range:fragmentRange];
			}
		}

		if (attributes & _rendererBackgroundColorAttribute) {
			NSUInteger colorCode = ((attributes & _backgroundColorMask) >> 4);

			[string addAttribute:IRCTextFormatterBackgroundColorAttributeName value:@(colorCode) range:fragmentRange];

			[string addAttribute:NSBackgroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:fragmentRange];
		}
	}
	else
	{
		[string addAttribute:NSFontAttributeName value:defaultFont range:fragmentRange];

		if (defaultFontColor) {
			[string addAttribute:NSForegroundColorAttributeName value:defaultFontColor range:fragmentRange];
		}
	}
}

- (nullable id)renderString:(NSString *)string attributes:(attr_t)attributes startingAt:(NSUInteger)rangeStart length:(NSUInteger)rangeLength
{
	NSParameterAssert(string != nil);

	NSString *html = nil;

	NSString *fragment = [string substringWithRange:NSMakeRange(rangeStart, rangeLength)];

	NSString *fragmentEscaped = [TVCLogRenderer escapeString:fragment];

	NSMutableDictionary<NSString *, id> *templateTokens = [NSMutableDictionary dictionary];

	if (attributes & _rendererURLAttribute)
	{
		NSString *anchorLocation = nil;

		NSArray *links = self->_outputDictionary[TVCLogRendererResultsListOfLinksInBodyAttribute];

		for (AHHyperlinkScannerResult *link in links) {
			if (link.range.location == self->_rendererIsRenderingLinkIndex) {
				anchorLocation = link.stringValue;
			}
		}

		if (self->_viewController.inlineMediaEnabledForView) {
			NSDictionary *linksMapped = self->_outputDictionary[TVCLogRendererResultsListOfLinksMappedInBodyAttribute];

			NSString *uniqueIdentifier = linksMapped[anchorLocation];

			if (uniqueIdentifier) {
				templateTokens[@"anchorInlineImageAvailable"] = @(YES);
				templateTokens[@"anchorInlineImageUniqueID"] = uniqueIdentifier;
			}
		}

		templateTokens[@"anchorLocation"] = anchorLocation;

		templateTokens[@"anchorTitle"] = fragmentEscaped;

		html = [TVCLogRenderer renderTemplate:@"renderedStandardAnchorLinkResource" attributes:templateTokens];
	}
	else if (attributes & _rendererChannelNameAttribute)
	{
		templateTokens[@"channelName"] = fragmentEscaped;

		html = [TVCLogRenderer renderTemplate:@"renderedChannelNameLinkResource" attributes:templateTokens];
	}
	else if (attributes & _rendererConversationTrackerAttribute)
	{
		templateTokens[@"messageFragment"] = fragmentEscaped;

		if ([TPCPreferences disableNicknameColorHashing] == YES) {
			templateTokens[@"inlineNicknameMatchFound"] = @(NO);
		} else {
			IRCChannel *channel = self->_viewController.associatedChannel;

			IRCUser *user = [channel findMember:fragmentEscaped];

			if (user.nickname.length > 1) {
				NSString *modeSymbol = NSStringEmptyPlaceholder;

				if ([TPCPreferences conversationTrackingIncludesUserModeSymbol]) {
					NSString *modeSymbolTemp = user.mark;

					if (rangeStart > 0) {
						NSString *leftCharacter = [string stringCharacterAtIndex:(rangeStart - 1)];

						if ([leftCharacter isEqualToString:modeSymbolTemp] == NO) {
							modeSymbol = modeSymbolTemp;
						}
					} else {
						modeSymbol = modeSymbolTemp;
					}
				}

				NSString *nicknameColorStyle = [IRCUserNicknameColorStyleGenerator nicknameColorStyleForString:user.nickname];

				templateTokens[@"inlineNicknameMatchFound"] = @(YES);

				templateTokens[@"inlineNicknameColorNumber"] = nicknameColorStyle;
				templateTokens[@"inlineNicknameColorStyle"] = nicknameColorStyle;

				templateTokens[@"nicknameColorHashingIsStyleBased"] = @(themeSettings().nicknameColorStyle != TPCThemeSettingsNicknameColorLegacyStyle);

				templateTokens[@"inlineNicknameUserModeSymbol"] = modeSymbol;
			}
		}
	}

	if (html == nil) {
		html = fragmentEscaped;
	}

	// --- //

	if (attributes & _effectMask) {
		templateTokens[@"fragmentContainsFormattingSymbols"] = @(YES);

		if (attributes & _rendererBoldFormatAttribute) {
			templateTokens[@"fragmentIsBold"] = @(YES);
		}

		if (attributes & _rendererItalicFormatAttribute) {
			templateTokens[@"fragmentIsItalicized"] = @(YES);
		}

		if (attributes & _rendererStrikethroughFormatAttribute) {
			templateTokens[@"fragmentIsStruckthrough"] = @(YES);
		}

		if (attributes & _rendererUnderlineFormatAttribute) {
			templateTokens[@"fragmentIsUnderlined"] = @(YES);
		}

		if (attributes & _rendererForegroundColorAttribute) {
			NSInteger colorCode = (attributes & _foregroundColorMask);

			/* We have to tell the template that the color is actually set
			 because if it only checked the value of "fragmentTextColor" in
			 an if statement the color white (code 0) would not show because
			 zero would show as a null value to the if statement. */
			
			templateTokens[@"fragmentTextColorIsSet"] = @(YES);
			templateTokens[@"fragmentTextColor"] = @(colorCode);
		}

		if (attributes & _rendererBackgroundColorAttribute) {
			NSInteger colorCode = ((attributes & _backgroundColorMask) >> 4);

			templateTokens[@"fragmentBackgroundColorIsSet"] = @(YES);
			templateTokens[@"fragmentBackgroundColor"] = @(colorCode);

			/* If a background color is set, but a foreground color is not
			 we supply a value of -1 for the foreground color so that the
			 templates at least render the condtional HTML */
			if ((attributes & _rendererForegroundColorAttribute) == 0) {
				templateTokens[@"fragmentTextColorIsSet"] = @(YES);
				templateTokens[@"fragmentTextColor"] = @(-1);
			}
		}
	}

	/* Escape spaces that are prefix and suffix characters */
	if ([html hasPrefix:NSStringWhitespacePlaceholder]) {
		html = [html stringByReplacingCharactersInRange:NSMakeRange(0, 1)
											 withString:@"&nbsp;"];
	}

	if ([html hasSuffix:NSStringWhitespacePlaceholder]) {
		html = [html stringByReplacingCharactersInRange:NSMakeRange((html.length - 1), 1)
											 withString:@"&nbsp;"];
	}

	// --- //

	templateTokens[@"messageFragment"] = html;

	return [TVCLogRenderer renderTemplate:@"formattedMessageFragment" attributes:templateTokens];
}

#pragma mark -

- (void)renderFinalResultsForPlainTextBody
{
	NSMutableString *result = [NSMutableString string];

	NSString *body = self->_body;

	NSUInteger bodyLength = body.length;

	NSUInteger currentPosition = 0;

	while (currentPosition < bodyLength) {
		NSUInteger fragmentLength = getNextAttributeRange(self->_effectAttributes, currentPosition, bodyLength);

		if (fragmentLength == 0) {
			break;
		}

		attr_t attributes = ((attr_t *)self->_effectAttributes)[currentPosition];

		BOOL attributesIncludeURL = ((attributes & _rendererURLAttribute) == _rendererURLAttribute);

		if (attributesIncludeURL) {
			if (self->_rendererIsRenderingLinkIndex == NSNotFound) {
				self->_rendererIsRenderingLinkIndex = currentPosition;
			}
		} else {
			self->_rendererIsRenderingLinkIndex = NSNotFound;
		}

		NSString *messageFragment = [self renderString:body attributes:attributes startingAt:currentPosition length:fragmentLength];

		if (messageFragment) {
			[result appendString:messageFragment];
		}

		currentPosition += fragmentLength;
	}

	self.finalResult = result;
}

- (void)renderFinalResultsForAttributedBody
{
	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:self->_body attributes:nil];

	NSUInteger resultLength = result.length;

	NSUInteger currentPosition = 0;

	while (currentPosition < resultLength) {
		NSUInteger fragmentLength = getNextAttributeRange(self->_effectAttributes, currentPosition, resultLength);

		if (fragmentLength == 0) {
			break;
		}

		attr_t attributes = ((attr_t *)self->_effectAttributes)[currentPosition];

		[self applyAttributes:attributes toAttributedString:result startingAt:currentPosition length:fragmentLength];

		currentPosition += fragmentLength;
	}

	self.finalResult = result;
}

- (void)cleanUpResources
{
	free(_effectAttributes);
}

#pragma mark -

+ (NSString *)renderBody:(NSString *)body forViewController:(TVCLogController *)viewController withAttributes:(NSDictionary<NSString *, id> *)inputDictionary resultInfo:(NSDictionary<NSString *, id> * _Nullable * _Nullable)outputDictionary
{
	NSParameterAssert(body != nil);
	NSParameterAssert(viewController != nil);
	NSParameterAssert(inputDictionary != nil);

	if (body.length == 0) {
		return NSStringEmptyPlaceholder;
	}

	TVCLogLineType lineType = [inputDictionary unsignedIntegerForKey:TVCLogRendererConfigurationLineTypeAttribute];

	TVCLogLineMemberType memberType = [inputDictionary unsignedIntegerForKey:TVCLogRendererConfigurationMemberTypeAttribute];

	TVCLogRenderer *renderer = [TVCLogRenderer new];

	renderer.body =
	[THOPluginDispatcher willRenderMessage:body
						 forViewController:viewController
								  lineType:lineType
								memberType:memberType];

	renderer.lineType = lineType;

	renderer.memberType = memberType;

	renderer.rendererAttributes = inputDictionary;

	renderer.viewController = viewController;

	[renderer buildEffectsDictionary];

	[renderer stripDangerousUnicodeCharactersFromBody];

	[renderer buildListOfLinksInBody];

	[renderer matchKeywords];

	[renderer findAllChannelNames];

	[renderer scanBodyForChannelMembers];

	if ( outputDictionary) {
		*outputDictionary = [renderer.outputDictionary copy];
	}

	[renderer renderFinalResultsForPlainTextBody];

	[renderer cleanUpResources];

	return renderer.finalResult;
}

+ (NSAttributedString *)renderBodyAsAttributedString:(NSString *)body withAttributes:(NSDictionary<NSString *, id> *)inputDictionary;
{
	NSParameterAssert(body != nil);
	NSParameterAssert(inputDictionary != nil);

	if (body.length == 0) {
		return [NSAttributedString attributedString];
	}

	NSFont *defaultFont = inputDictionary[TVCLogRendererConfigurationAttributedStringPreferredFontAttribute];

	NSAssert((defaultFont != nil),
		@"FATAL ERROR: TVCLogRenderer cannot be supplied with a nil 'TVCLogRendererAttributedStringPreferredFontAttribute' attribute when rendering an attributed string");

	TVCLogRenderer *renderer = [TVCLogRenderer new];

	renderer.body = body;

	renderer.lineType = [inputDictionary unsignedIntegerForKey:TVCLogRendererConfigurationLineTypeAttribute];

	renderer.memberType = [inputDictionary unsignedIntegerForKey:TVCLogRendererConfigurationMemberTypeAttribute];

	renderer.rendererAttributes = inputDictionary;

	[renderer buildEffectsDictionary];

	[renderer stripDangerousUnicodeCharactersFromBody];

	[renderer renderFinalResultsForAttributedBody];

	[renderer cleanUpResources];

	return renderer.finalResult;
}

#pragma mark -

+ (nullable NSString *)renderTemplate:(NSString *)templateName
{
	return [TVCLogRenderer renderTemplate:templateName attributes:nil];
}

+ (nullable NSString *)renderTemplate:(NSString *)templateName attributes:(nullable NSDictionary<NSString *, id> *)templateToken
{
	NSParameterAssert(templateName != nil);

	GRMustacheTemplate *template = [themeSettings() templateWithName:templateName];

	if (template == nil) {
		return nil;
	}

	NSString *templateRender = [template renderObject:templateToken error:NULL];

	if (templateRender == nil) {
		return nil;
	}

	return templateRender.removeAllNewlines;
}

+ (NSString *)escapeString:(NSString *)string
{
	NSParameterAssert(string != nil);

	NSString *stringEscaped = string.gtm_stringByEscapingForHTML;

	if (stringEscaped == nil) {
		stringEscaped = NSStringEmptyPlaceholder;
	}

	stringEscaped = [stringEscaped stringByReplacingOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;"];
	stringEscaped = [stringEscaped stringByReplacingOccurrencesOfString:@"  " withString:@"&nbsp;&nbsp;"];

	return stringEscaped;
}

+ (NSColor *)mapColorCode:(NSUInteger)colorCode
{
	NSParameterAssert(colorCode <= 15);

#define _dv(key, value)		case (key): { return (value); }

	switch (colorCode) {
		_dv(0, [NSColor formatterWhiteColor])
		_dv(1, [NSColor formatterBlackColor])
		_dv(2, [NSColor formatterNavyBlueColor])
		_dv(3, [NSColor formatterDarkGreenColor])
		_dv(4, [NSColor formatterRedColor])
		_dv(5, [NSColor formatterBrownColor])
		_dv(6, [NSColor formatterPurpleColor])
		_dv(7, [NSColor formatterOrangeColor])
		_dv(8, [NSColor formatterYellowColor])
		_dv(9, [NSColor formatterLimeGreenColor])
		_dv(10, [NSColor formatterTealColor])
		_dv(11, [NSColor formatterAquaCyanColor])
		_dv(12, [NSColor formatterLightBlueColor])
		_dv(13, [NSColor formatterFuchsiaPinkColor])
		_dv(14, [NSColor formatterNormalGrayColor])
		_dv(15, [NSColor formatterLightGrayColor])
	}

#undef _dv

	return nil;
}

@end

NS_ASSUME_NONNULL_END
