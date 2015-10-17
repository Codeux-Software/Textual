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

#import "IRCUserPrivate.h"

#define _colorNumberMax				 30

#define _presentAwayMessageFor301Threshold			300.0f

@interface IRCUser ()
@property (nonatomic, weak) IRCISupportInfo *supportInfo;
@property (nonatomic, assign) CFAbsoluteTime presentAwayMessageFor301LastEvent;
@end

@implementation IRCUser

- (instancetype)init
{
	if ((self = [super init])) {
		self.lastWeightFade = CFAbsoluteTimeGetCurrent();
	}
	
	return self;
}

- (instancetype)initWithUser:(IRCUser *)otherUser
{
	if ((self = [super init])) {
		[self migrate:otherUser];
	}
	
	return self;
}

+ (id)newUserOnClient:(IRCClient *)client withNickname:(NSString *)nickname
{
	IRCUser *newUser = [IRCUser new];

	[newUser setSupportInfo:[client supportInfo]];

	[newUser setNickname:nickname];
	
	return newUser;
}

- (void)setIsAway:(BOOL)isAway
{
	if (NSDissimilarObjects(isAway, _isAway)) {
		_isAway = isAway;

		if (_isAway == NO) {
			if (self.presentAwayMessageFor301LastEvent > 0.0) {
				self.presentAwayMessageFor301LastEvent = 0.0f;
			}
		}
	}
}

- (BOOL)presentAwayMessageFor301
{
	if (self.isAway == NO) {
		return NO;
	}

	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

	if ((self.presentAwayMessageFor301LastEvent + _presentAwayMessageFor301LastEvent) < now) {
		 self.presentAwayMessageFor301LastEvent = now;

		return YES;
	} else {
		return NO;
	}
}

- (NSString *)hostmask
{
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	NSObjectIsEmptyAssertReturn(self.username, nil);
	NSObjectIsEmptyAssertReturn(self.address, nil);
	
	return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
}

- (NSString *)banMask
{
	if (NSObjectIsEmpty(self.nickname)) {
		return nil;
	}

	if (NSObjectIsEmpty(self.username) || NSObjectIsEmpty(self.address)) {
		return [NSString stringWithFormat:@"%@!*@*", self.nickname];
	}

	switch ([TPCPreferences banFormat]) {
		case TXHostmaskBanWHNINFormat: {	return [NSString stringWithFormat:@"*!*@%@", self.address];										}
		case TXHostmaskBanWHAINNFormat: {	return [NSString stringWithFormat:@"*!%@@%@", self.username, self.address];						}
		case TXHostmaskBanWHANNIFormat: {	return [NSString stringWithFormat:@"%@!*%@", self.nickname, self.address];						}
		case TXHostmaskBanExactFormat: {	return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];		}
	}
	
	return nil;
}

- (BOOL)userModesContainsMode:(NSString *)mode
{
	NSParameterAssert(([mode length] == 1));

	if (NSObjectIsEmpty(self.modes)) {
		return NO;
	} else {
		return [self.modes contains:mode];
	}
}

- (NSString *)highestRankedUserMode
{
	if (NSObjectIsEmpty(self.modes)) {
		return nil;
	} else {
		return [self.modes stringCharacterAtIndex:0];
	}
}

- (NSString *)mark
{
	NSString *highestRank = [self highestRankedUserMode];

	if (highestRank) {
		return [self.supportInfo userModePrefixSymbolWithMode:highestRank];
	} else {
		return nil;
	}
}

- (NSInteger)channelRank
{
	NSString *highestRank = [self highestRankedUserMode];

	if (highestRank) {
		return [self.supportInfo rankForUserPrefixWithMode:highestRank];
	} else {
		return 0; // Furthest that can be gone down.
	}
}

- (BOOL)isOp
{
	if (NSObjectIsEmpty(self.modes)) {
		return NO;
	} else {
		return [self.modes containsCharacters:@"qOao"];
	}
}

- (BOOL)isHalfOp 
{
	if (NSObjectIsEmpty(self.modes)) {
		return NO;
	} else {
		return [self.modes containsCharacters:@"qOaoh"];
	}
}

- (BOOL)q
{
	return (([self ranks] & IRCUserChannelOwnerRank) == IRCUserChannelOwnerRank);
}

- (BOOL)a
{
	return (([self ranks] & IRCUserSuperOperatorRank) == IRCUserSuperOperatorRank);
}

- (BOOL)o
{
	return (([self ranks] & IRCUserNormalOperatorRank) == IRCUserNormalOperatorRank);
}

- (BOOL)h
{
	return (([self ranks] & IRCUserHalfOperatorRank) == IRCUserHalfOperatorRank);
}

- (BOOL)v
{
	return (([self ranks] & IRCUserVoicedRank) == IRCUserVoicedRank);
}

- (IRCUserRank)rank
{
	NSString *highestMark = [self highestRankedUserMode];

	return [self rankWithMark:highestMark];
}

- (IRCUserRank)ranks
{
	IRCUserRank ranks = 0;

	if (NSObjectIsEmpty(self.modes) == NO) {
		for (NSInteger i = 0; i < [self.modes length]; i++) {
			NSString *cc = [self.modes stringCharacterAtIndex:i];

			IRCUserRank rank = [self rankWithMark:cc];

			if (NSDissimilarObjects(rank, IRCUserNoRank)) {
				ranks |= rank;
			}
		}
	}

	if (ranks == 0) {
		ranks |= IRCUserNoRank;
	}

	return ranks;
}

- (IRCUserRank)rankWithMark:(NSString *)mark
{
	if (mark == nil) {
		return IRCUserNoRank; // Furthest that can be gone down.
	}

#define _mm(mode)			NSObjectsAreEqual(mark, (mode))

	// +Y/+y is used by InspIRCd-2.0 to represent an IRCop
	// +O is used by binircd-1.0.0 for channel owner
	if (_mm(@"y") || _mm(@"Y")) {
		return IRCUserIRCopByModeRank;
	} else if (_mm(@"q") || _mm(@"O")) {
		return IRCUserChannelOwnerRank;
	} else if (_mm(@"a")) {
		return IRCUserSuperOperatorRank;
	} else if (_mm(@"o")) {
		return IRCUserNormalOperatorRank;
	} else if (_mm(@"h")) {
		return IRCUserHalfOperatorRank;
	} else if (_mm(@"v")) {
		return IRCUserVoicedRank;
	} else {
		return IRCUserNoRank;
	}

#undef _mm
}

- (BOOL)isEqual:(id)other
{
	if ([other isKindOfClass:[IRCUser class]] == NO) {
		return NO;
	} else {
		return NSObjectsAreEqual([self lowercaseNickname], [other lowercaseNickname]);
	}
}

- (NSUInteger)hash
{
	return [self.lowercaseNickname hash];
}

- (NSString *)lowercaseNickname
{
	return [self.nickname lowercaseString];
}

- (CGFloat)totalWeight
{
	[self decayConversation];

	return (self.incomingWeight + self.outgoingWeight);
}

- (void)outgoingConversation
{
	CGFloat change = ((lrint(self.outgoingWeight) == 0) ? 20 : 5);

	self.outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = ((lrint(self.incomingWeight) == 0) ? 100 : 20);

	self.incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = ((lrint(self.incomingWeight) == 0) ? 4 : 1);

	self.incomingWeight += change;
}

- (void)decayConversation
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

	CGFloat minutes = ((now - self.lastWeightFade) / 60);

	if (minutes > 1) {
		self.lastWeightFade = now;

		if (self.incomingWeight > 0) {
			self.incomingWeight /= pow(2, minutes);
		}

		if (self.outgoingWeight > 0) {
			self.outgoingWeight /= pow(2, minutes);
		}
	}
}

- (NSComparisonResult)compareUsingWeights:(IRCUser *)other
{
	CGFloat local = self.totalWeight;

	CGFloat remote = [other totalWeight];

	if (local > remote) {
		return NSOrderedAscending;
	}
	
	if (local < remote) {
		return NSOrderedDescending;
	}

	return [self compare:other];
}

- (NSComparisonResult)compare:(IRCUser *)other
{
	if ([other isKindOfClass:[IRCUser class]] == NO) {
		return NSOrderedSame;
	} else {
		NSNumber *localRank = [NSNumber numberWithInteger:[self channelRank]];

		NSNumber *remoteRank = [NSNumber numberWithInteger:[other channelRank]];

		NSComparisonResult normalRank = [localRank compare:remoteRank];

		NSComparisonResult invertedRank = NSInvertedComparisonResult(normalRank);

		BOOL favorIRCop = [TPCPreferences memberListSortFavorsServerStaff];

		if (favorIRCop && [self isCop] && [other isCop] == NO) {
			return NSOrderedAscending;
		} else if (favorIRCop && [self isCop] == NO && [other isCop]) {
			return NSOrderedDescending;
		} else if (invertedRank == NSOrderedSame) {
			return [[self nickname] caseInsensitiveCompare:[other nickname]];
		} else {
			return invertedRank;
		}
	}
}

+ (NSComparator)nicknameLengthComparator
{
	return [^(IRCUser *obj1, IRCUser *obj2){
		return ([[obj1 nickname] length] <=
				[[obj2 nickname] length]);
	} copy];
}

- (void)migrate:(IRCUser *)from
{
	self.supportInfo = [from supportInfo];
	
	self.nickname = [from nickname];
	self.username = [from username];
	self.address = [from address];

	self.realname = [from realname];

	self.modes = [from modes];

	self.isCop = [from isCop];
	self.isAway = [from isAway];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCUser %@%@>", self.mark, self.nickname];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[IRCUser allocWithZone:zone] initWithUser:self];
}

@end

#pragma mark -
#pragma mark Nickname Color Style Generator 

@implementation IRCUserNicknameColorStyleGenerator

+ (NSString *)nicknameColorStyleForString:(NSString *)inputString
{
	NSObjectIsEmptyAssertReturn(inputString, nil);

	TPCThemeSettingsNicknameColorStyle colorStyle = [themeSettings() nicknameColorStyle];

	NSInteger stringHash =
	[IRCUserNicknameColorStyleGenerator hashForString:inputString colorStyle:colorStyle];

	return [IRCUserNicknameColorStyleGenerator nicknameColorStyleForHash:stringHash colorStyle:colorStyle];
}

+ (NSString *)nicknameColorStyleForHash:(NSInteger)stringHash colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	if (colorStyle == TPCThemeSettingsNicknameColorLegacyStyle)
	{
		return [NSString stringWithInteger:(stringHash % _colorNumberMax)];
	}
	else if (colorStyle == TPCThemeSettingsNicknameColorHashHueDarkStyle ||
			 colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle)
	{
		/* Define base pair */
		BOOL onLightBackground = (colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle);

		NSInteger stringHashAbsolute = ABS(stringHash);

		/* Hug */
		NSInteger h = (stringHashAbsolute % 360);

		/* Saturation */
		NSInteger s;

		if (onLightBackground) {
			s = (60 + stringHashAbsolute % 25);
		} else {
			s = (20 + stringHashAbsolute % 70);
		}

		/* Lightness */
		NSInteger l;

		if (onLightBackground) {
			if (s >= 60 && s < 66) {
				l = (45 + stringHashAbsolute % 10);
			} else if (s >= 66 && s < 72) {
				l = (40 + stringHashAbsolute % 10);
			} else if (s >= 72 && s < 78) {
				l = (35 + stringHashAbsolute % 10);
			} else if (s >= 78 && s <= 85) {
				l = (30 + stringHashAbsolute % 10);
			}
		} else {
			l = (50 + stringHashAbsolute % 20);
		}

		/* Hard code the lightness when dealing with some blues and purple. */
		if (h >= 215 && h <= 280 && l < 70) {
			if (onLightBackground) {
				l = (55 + stringHashAbsolute % 10);
			} else {
				l = (65 + stringHashAbsolute % 20);
			}
		}

		return [NSString stringWithFormat:@"hsl(%ld,%ld%%,%ld%%)", h, s, l];
	} else {
		return nil;
		
	}
}

+ (NSString *)preprocessString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	if (colorStyle == TPCThemeSettingsNicknameColorHashHueDarkStyle ||
		colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle)
	{
		static NSCharacterSet *nonAlphaCharacters = nil;

		if (nonAlphaCharacters == nil) {
			nonAlphaCharacters = [NSCharacterSet characterSetWithCharactersInString:@"^[]-_{}\\"];
		}

		NSString *unshuffledString = [inputString lowercaseString];

		NSInteger unshuffledStringLength = [unshuffledString length];

		if (unshuffledStringLength <= 3) {
			return unshuffledString;
		}

		NSInteger stringMiddlePoint = (NSInteger)(ceil(unshuffledStringLength / 2));

		UniChar stringFirstCharacter = [unshuffledString characterAtIndex:0];
		UniChar stringMiddleCharacter = [unshuffledString characterAtIndex:stringMiddlePoint];
		UniChar stringLastCharacter = [unshuffledString characterAtIndex:(unshuffledStringLength - 1)];

		NSInteger shuffleStartingPoint = 0;

		if ((unshuffledStringLength % 2) == 0) {
			shuffleStartingPoint = (ABS(stringFirstCharacter + stringMiddleCharacter + stringLastCharacter * 743930) % unshuffledStringLength);
		} else if ((unshuffledStringLength % 5) == 0) {
			shuffleStartingPoint = (ABS(stringFirstCharacter + stringMiddleCharacter + stringLastCharacter * 1263) % unshuffledStringLength);
		} else {
			shuffleStartingPoint = (ABS(stringFirstCharacter + stringMiddleCharacter + stringLastCharacter) % unshuffledStringLength);
		}

		NSMutableString *shuffledString = [NSMutableString stringWithCapacity:unshuffledStringLength];

		for (NSInteger i = shuffleStartingPoint; i >= 0; i--) {
			UniChar c = [unshuffledString characterAtIndex:i];

			if ([nonAlphaCharacters characterIsMember:c] == NO) {
				[shuffledString appendString:[NSString stringWithUniChar:c]];
			}
		}

		for (NSInteger i = (shuffleStartingPoint + 1); i < unshuffledStringLength; i++) {
			UniChar c = [unshuffledString characterAtIndex:i];

			if ([nonAlphaCharacters characterIsMember:c] == NO) {
				[shuffledString appendString:[NSString stringWithUniChar:c]];
			}
		}

		return shuffledString;
	} else {
		return [inputString lowercaseString];
	}
}

+ (NSInteger)hashForString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	NSString *stringToHash =
	[IRCUserNicknameColorStyleGenerator preprocessString:inputString colorStyle:colorStyle];

	NSInteger stringToHashLength = [stringToHash length];

	NSUInteger hashedValue = 0;

	for (NSInteger i = 0; i < stringToHashLength; i++) {
		UniChar c = [inputString characterAtIndex:i];

		hashedValue = ((hashedValue << 6) + hashedValue + c);
	}

	return hashedValue;
}

@end
