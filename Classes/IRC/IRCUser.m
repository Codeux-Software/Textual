/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

#define _colorNumberMax				 30

@implementation IRCUser

- (id)init
{
	if ((self = [super init])) {
		self.colorNumber = -1;
		self.lastWeightFade = CFAbsoluteTimeGetCurrent();
	}
	
	return self;
}

- (NSString *)hostmask
{
	NSObjectIsEmptyAssertReturn(self.username, nil);
	NSObjectIsEmptyAssertReturn(self.address, nil);
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	
	return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
}

- (NSString *)banMask
{
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	
	if (NSObjectIsEmpty(self.username) || NSObjectIsEmpty(self.address)) {
		return [NSString stringWithFormat:@"%@!*@*", self.nickname];
	} else {
		switch ([TPCPreferences banFormat]) {
			case TXHostmaskBanWHNINFormat: {
				return [NSString stringWithFormat:@"*!*@%@", self.address];
			} case TXHostmaskBanWHAINNFormat: {
				return [NSString stringWithFormat:@"*!%@@%@", self.username, self.address];
			} case TXHostmaskBanWHANNIFormat: {
				return [NSString stringWithFormat:@"%@!*%@", self.nickname, self.address];
			} case TXHostmaskBanExactFormat: {
				return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
			}
		}
	}
	
	return nil;
}

- (NSString *)mark
{
	if (self.q) {
		return [self.supportInfo userModePrefixSymbol:@"q"];
	} else if (self.a) {
		return [self.supportInfo userModePrefixSymbol:@"a"];
	} else if (self.o) {
		return [self.supportInfo userModePrefixSymbol:@"o"];
	} else if (self.h) {
		return [self.supportInfo userModePrefixSymbol:@"h"];
	} else if (self.v) {
		return [self.supportInfo userModePrefixSymbol:@"v"];
	} else if (self.isCop) {
		return [self.supportInfo userModePrefixSymbol:@"y"]; // InspIRCd-2.0
	}
	
	return nil;
}

- (BOOL)isOp
{
	return (self.o || self.a || self.q);
}

- (BOOL)isHalfOp 
{
	return (self.h || self.o || self.a || self.q);
}

- (NSInteger)colorNumber
{
	if (_colorNumber < 0) {
		NSString *hashName = self.nickname.lowercaseString;

		if ([RZUserDefaults() boolForKey:@"UUIDBasedNicknameColorHashing"]) {
			hashName = [NSString stringWithUUID];
		}
		
		self.colorNumber = (hashName.hash % _colorNumberMax);
	}
	
	return _colorNumber;
}

- (BOOL)isEqual:(id)other
{
	NSAssertReturnR([other isKindOfClass:[IRCUser class]], NO);
	
	return [self.nickname isEqualIgnoringCase:[other nickname]];
}

- (NSUInteger)hash
{
	return self.nickname.lowercaseString.hash;
}

- (CGFloat)totalWeight
{
	[self decayConversation];

	return (self.incomingWeight + self.outgoingWeight);
}

- (void)outgoingConversation
{
	CGFloat change = ((self.outgoingWeight == 0) ? 20 : 5);

	_outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = ((self.incomingWeight == 0) ? 100 : 20);

	_incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = ((self.incomingWeight == 0) ? 4 : 1);

	_incomingWeight += change;
}

- (void)decayConversation
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

	CGFloat minutes = ((now - self.lastWeightFade) / 60);

	if (minutes > 1) {
		self.lastWeightFade = now;

		if (self.incomingWeight > 0) {
			_incomingWeight /= pow(2, minutes);
		}

		if (self.outgoingWeight > 0) {
			_outgoingWeight /= pow(2, minutes);
		}
	}
}

- (NSComparisonResult)compareUsingWeights:(IRCUser *)other
{
	CGFloat local = self.totalWeight;
	CGFloat remte = other.totalWeight;

	if (local > remte) {
		return NSOrderedAscending;
	}
	
	if (local < remte) {
		return NSOrderedDescending;
	}

	return [self compare:other];
}

- (NSComparisonResult)compare:(IRCUser *)other
{
	/* If the user specifically requests that the IRCops get placed higher but
	 the server doesn't support the y prefix, place them at the top, but sort
	 them by their ranks within the channel instead of just alphabetically.

	 Otherwise we sort by their channel rank since the y prefix will naturally
	 float to the top. 
	 
	 Example on a server without the y prefix:
	 
	 q and IRCop is the topmost
	 a and IRCop next
	 ...
	 no rank and IRCop next
	 q and NOT IRCop next
	 a and NOT IRCop next
	 and so on
	 */

	BOOL favorIRCop = [TPCPreferences memberListSortFavorsServerStaff];

	NSComparisonResult rank = NSInvertedComparisonResult([@(self.channelRank) compare:@(other.channelRank)]);

	if (favorIRCop && self.isCop && BOOLReverseValue(other.isCop)) {
		return NSOrderedAscending;
	} else if (favorIRCop && BOOLReverseValue(self.isCop) && other.isCop) {
		return NSOrderedDescending;
	} else if (rank == NSOrderedSame) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else {
		return rank;
	}
}

- (NSInteger)channelRank
{
	if (self.isCop && [self.supportInfo modeIsSupportedUserPrefix:@"y"]) {
		return 6;
	} else if (self.q) {
		return 5;
	} else if (self.a) {
		return 4;
	} else if (self.o) {
		return 3;
	} else if (self.h) {
		return 2;
	} else if (self.v) {
		return 1;
	} else {
		return 0;
	}
}

+ (NSComparator)nicknameLengthComparator
{
	return [^(id obj1, id obj2){
		IRCUser *s1 = obj1;
		IRCUser *s2 = obj2;

		return (s1.nickname.length <= s2.nickname.length);
	} copy];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCUser %@%@>", self.mark, self.nickname];
}

@end
