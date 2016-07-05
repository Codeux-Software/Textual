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

#import <CommonCrypto/CommonDigest.h>

#define _colorNumberMax				 30

#define _presentAwayMessageFor301Threshold			300.0

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
				self.presentAwayMessageFor301LastEvent = 0.0;
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

	if ((self.presentAwayMessageFor301LastEvent + _presentAwayMessageFor301Threshold) < now) {
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
		return [self.supportInfo userPrefixForModeSymbol:highestRank];
	} else {
		return NSStringEmptyPlaceholder;
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

#define _overridesDefaultsKey		@"Nickname Color Style Overrides"

+ (NSString *)nicknameColorStyleForString:(NSString *)inputString
{
	return [IRCUserNicknameColorStyleGenerator nicknameColorStyleForString:inputString isOverride:NULL];
}

+ (NSString *)nicknameColorStyleForString:(NSString *)inputString isOverride:(BOOL *)isOverride
{
	NSObjectIsEmptyAssertReturn(inputString, nil);

	NSString *unshuffledString = [inputString lowercaseString];

	NSColor *styleOverride =
	[IRCUserNicknameColorStyleGenerator nicknameColorStyleOverrideForKey:unshuffledString];

	if (styleOverride) {
		if ( isOverride) {
			*isOverride = YES;
		}

		return [NSString stringWithFormat:@"#%@", [styleOverride hexadecimalValue]];
	} else {
		if ( isOverride) {
			*isOverride = NO;
		}
	}

	TPCThemeSettingsNicknameColorStyle colorStyle = [themeSettings() nicknameColorStyle];

	NSNumber *stringHash =
	[IRCUserNicknameColorStyleGenerator hashForString:unshuffledString colorStyle:colorStyle];

	return [IRCUserNicknameColorStyleGenerator nicknameColorStyleForHash:stringHash colorStyle:colorStyle];
}

+ (NSString *)nicknameColorStyleForHash:(NSNumber *)stringHash colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	if (colorStyle == TPCThemeSettingsNicknameColorLegacyStyle)
	{
		NSInteger stringHash64 = [stringHash integerValue];

		return [NSString stringWithInteger:(stringHash64 % _colorNumberMax)];
	}
	else if (colorStyle == TPCThemeSettingsNicknameColorHashHueDarkStyle ||
			 colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle)
	{
		/* Define base pair */
		BOOL onLightBackground = (colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle);

		unsigned int stringHash32 = [stringHash intValue];

		int shash = (stringHash32 >> 1);
		int lhash = (stringHash32 >> 2);

		int h = (stringHash32 % 360);

		int s;
		int l;

		if (onLightBackground)
		{
			s = (shash % 50 + 35);   // 35 - 85
			l = (lhash % 38 + 20);   // 20 - 58

			// Lower lightness for Yello, Green, Cyan
			if (h > 45 && h <= 195) {
				l = (lhash % 21 + 20);   // 20 - 41

				if (l > 31) {
					s = (shash % 40 + 55);   // 55 - 95
				} else {
					s = (shash % 35 + 65);   // 65 - 95
				}
			}

			// Give the reds a bit more saturation
			if (h <= 25 || h >= 335) {
				s = (shash % 33 + 45); // 45 - 78
			}
		}
		else
		{
			s = (shash % 50 + 45);   // 50 - 95
			l = (lhash % 36 + 45);   // 45 - 81

			// give the pinks a wee bit more lightness
			if (h >= 280 && h < 335) {
				l = (lhash % 36 + 50); // 50 - 86
			}

			// Give the blues a smaller (but lighter) range
			if (h >= 210 && h < 240) {
				l = (lhash % 30 + 60); // 60 - 90
			}

			// Tone down very specific range of blue/purple
			if (h >= 240 && h < 280) {
				s = (shash % 55 + 40); // 40 - 95
				l = (lhash % 20 + 65); // 65 - 85
			}

			// Give the reds a bit less saturation
			if (h <= 25 || h >= 335) {
				s = (shash % 33 + 45); // 45 - 78
			}

			// Give the yellows and greens a bit less saturation as well
			if (h >= 50 && h <= 150) {
				s = (shash % 50 + 40); // 40 - 90
			}
		}

		return [NSString stringWithFormat:@"hsl(%i,%i%%,%i%%)", h, s, l];
	} else {
		return nil;
	}
}

+ (NSString *)preprocessString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	if (colorStyle == TPCThemeSettingsNicknameColorHashHueDarkStyle ||
		colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle)
	{
		return [NSString stringWithFormat:@"a-%@", inputString];
	} else {
		return inputString;
	}
}

+ (NSNumber *)hashForString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	NSString *stringToHash =
	[IRCUserNicknameColorStyleGenerator preprocessString:inputString colorStyle:colorStyle];

	NSInteger stringToHashLength = [stringToHash length];

	if (colorStyle == TPCThemeSettingsNicknameColorHashHueDarkStyle ||
		colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle)
	{
		NSData *stringToHashData = [stringToHash dataUsingEncoding:NSUTF8StringEncoding];

		NSMutableData *hashedData = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];

		CC_MD5([stringToHashData bytes], (CC_LONG)[stringToHashData length], [hashedData mutableBytes]);

		unsigned int hashedValue;
		[hashedData getBytes:&hashedValue length:sizeof(unsigned int)];

		return @(hashedValue);
	}
	else
	{
		NSInteger hashedValue = 0;

		for (NSInteger i = 0; i < stringToHashLength; i++) {
			UniChar c = [stringToHash characterAtIndex:i];

			hashedValue = ((hashedValue << 6) + hashedValue + c);
		}

		return @(hashedValue);
	}
}

/* 
 *   Color override storage talks in NSColor instead of hexadecimal strings for a few reasons:
 *    1. Easier to work with when modifying. No need to perform messy string conversion.
 *    2. Easier to change output format in another update (if that decision is made)
 */
+ (NSColor *)nicknameColorStyleOverrideForKey:(NSString *)styleKey
{
	NSDictionary *colorStyleOverrides = [RZUserDefaults() dictionaryForKey:_overridesDefaultsKey];

	if (colorStyleOverrides) {
		id objectValue = [colorStyleOverrides objectForKey:styleKey];

		if (objectValue == nil || [objectValue isKindOfClass:[NSData class]] == NO) {
			return nil;
		}

		id objectValueObj = [NSUnarchiver unarchiveObjectWithData:objectValue];

		if (objectValueObj == nil || [objectValueObj isKindOfClass:[NSColor class]] == NO) {
			return nil;
		}

		return objectValueObj;
	}

	return nil;
}

+ (void)setNicknameColorStyleOverride:(NSColor *)styleValue forKey:(NSString *)styleKey
{
	NSObjectIsEmptyAssert(styleKey);

	NSDictionary *colorStyleOverrides = [RZUserDefaults() dictionaryForKey:_overridesDefaultsKey];

	if (styleValue == nil) {
		if (colorStyleOverrides == nil) {
			return;
		} else if ([colorStyleOverrides count] == 1) {
			[RZUserDefaults() removeObjectForKey:_overridesDefaultsKey];

			return;
		}
	}

	NSData *styleValueRolled = nil;

	if (styleValue) {
		styleValueRolled = [NSArchiver archivedDataWithRootObject:styleValue];

		if (colorStyleOverrides == nil) {
			colorStyleOverrides = [NSDictionary new];
		}
	}

	NSMutableDictionary *colorStyleOverridesMut = [colorStyleOverrides mutableCopy];

	if (styleValue == nil) {
		[colorStyleOverridesMut removeObjectForKey:styleKey];
	} else {
		[colorStyleOverridesMut setObject:styleValueRolled forKey:styleKey];
	}

	[RZUserDefaults() setObject:[colorStyleOverridesMut copy] forKey:_overridesDefaultsKey];
}

@end
