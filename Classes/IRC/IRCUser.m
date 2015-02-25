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

#define _colorNumberMax				 30

@interface IRCUser ()
@property (nonatomic, nweak) IRCClient *associatedClient;
@end

@implementation IRCUser

- (instancetype)init
{
	if ((self = [super init])) {
		self.colorNumber = -1;
		
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

	[newUser setAssociatedClient:client];

	[newUser setNickname:nickname];
	
	return newUser;
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
			}
			case TXHostmaskBanWHAINNFormat: {
				return [NSString stringWithFormat:@"*!%@@%@", self.username, self.address];
			}
			case TXHostmaskBanWHANNIFormat: {
				return [NSString stringWithFormat:@"%@!*%@", self.nickname, self.address];
			}
			case TXHostmaskBanExactFormat: {
				return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
			}
		}
	}
	
	return nil;
}

- (NSString *)mark
{
	IRCISupportInfo *supportInfo = self.associatedClient.supportInfo;
	
	if (self.q) {
		if (self.binircd_O) {
			return [supportInfo userModePrefixSymbol:@"O"]; // binircd-1.0.0
		} else {
			return [supportInfo userModePrefixSymbol:@"q"];
		}
	} else if (self.a) {
		return [supportInfo userModePrefixSymbol:@"a"];
	} else if (self.o) {
		return [supportInfo userModePrefixSymbol:@"o"];
	} else if (self.h) {
		return [supportInfo userModePrefixSymbol:@"h"];
	} else if (self.v) {
		return [supportInfo userModePrefixSymbol:@"v"];
	} else if (self.isCop) {
		if (self.InspIRCd_y_lower) {
			return [supportInfo userModePrefixSymbol:@"y"]; // InspIRCd-2.0
		} else if (self.InspIRCd_y_upper) {
			return [supportInfo userModePrefixSymbol:@"Y"]; // InspIRCd-2.0
		}
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

- (IRCUserRank)currentRank
{
	if (self.isCop) {
		return IRCUserIRCopRank;
	} else if (self.q) {
		return IRCUserChannelOwnerRank;
	} else if (self.a) {
		return IRCUserSuperOperatorRank;
	} else if (self.o) {
		return IRCUserNormalOperatorRank;
	} else if (self.h) {
		return IRCUserHalfOperatorRank;
	} else if (self.v) {
		return IRCUserVoicedRank;
	} else {
		return IRCUserNoRank;
	}
}

- (NSInteger)colorNumber
{
	if (_colorNumber < 0) {
		NSString *name = [self lowercaseNickname];
		
		NSInteger nameLength = [name length];
		
		NSUInteger hashedValue = 0;
		
		for (NSInteger i = 0; i < nameLength; i++) {
			UniChar c = [name characterAtIndex:i];
			
			hashedValue = ((hashedValue << 6) + hashedValue + c);
		}
		
		_colorNumber = (hashedValue % _colorNumberMax);
	}
	
	return _colorNumber;
}

- (BOOL)isEqual:(id)other
{
	NSObjectIsKindOfClassAssertReturn(other, IRCUser, NO);
	
	return [self.nickname isEqualIgnoringCase:[other nickname]];
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
	
	NSComparisonResult normalRank = [@([self channelRank]) compare:@([other channelRank])];
	
	NSComparisonResult invertedRank = NSInvertedComparisonResult(normalRank);
	
	BOOL favorIRCop = [TPCPreferences memberListSortFavorsServerStaff];
	
	if (favorIRCop && self.isCop && [other isCop] == NO) {
		return NSOrderedAscending;
	} else if (favorIRCop && self.isCop == NO && [other isCop]) {
		return NSOrderedDescending;
	} else if (invertedRank == NSOrderedSame) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else {
		return invertedRank;
	}
}

- (NSInteger)channelRank
{
	if (self.isCop && (self.InspIRCd_y_upper || self.InspIRCd_y_lower)) {
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
	return [^(IRCUser *obj1, IRCUser *obj2){
		return ([[obj1 nickname] length] <=
				[[obj2 nickname] length]);
	} copy];
}

- (void)migrate:(IRCUser *)from
{
	/* Lazy-man copy. */
	self.associatedClient = [from associatedClient];
	
	self.nickname = [from nickname];
	self.username = [from username];
	self.address = [from address];

	self.realname = [from realname];

	self.colorNumber = [from colorNumber];

	self.q = [from q];
	self.a = [from a];
	self.o = [from o];
	self.h = [from h];
	self.v = [from v];

	self.isCop = [from isCop];
	self.isAway = [from isAway];

	self.InspIRCd_y_upper = [from InspIRCd_y_upper];
	self.InspIRCd_y_lower = [from InspIRCd_y_lower];

	self.binircd_O = [from binircd_O];
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
