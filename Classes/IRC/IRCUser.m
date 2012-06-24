// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

#define _colorNumberMax		30

@interface IRCUser (Private)
- (void)decayConversation;
@end

@implementation IRCUser


- (id)init
{
	if ((self = [super init])) {
		self.colorNumber = -1;
		
		self.lastFadedWeights = CFAbsoluteTimeGetCurrent();
	}
	
	return self;
}

- (NSString *)banMask
{
	if (NSObjectIsEmpty(self.address)) {
		return [NSString stringWithFormat:@"%@!*@*", self.nick];
	} else {
		NSString *ident = ((self.username) ?: @"*");
		
		switch ([TPCPreferences banFormat]) {
			case TXHostmaskBanWHNINFormat:  return [NSString stringWithFormat:@"*!*@%@", self.address];	 break;
			case TXHostmaskBanWHAINNFormat: return [NSString stringWithFormat:@"*!%@@%@", ident, self.address]; break;
			case TXHostmaskBanWHANNIFormat: return [NSString stringWithFormat:@"%@!*%@", self.nick, self.address]; break;
			case TXHostmaskBanExactFormat:  return [NSString stringWithFormat:@"%@!%@@%@", self.nick, ident, self.address]; break;
		}
	}
	
	return nil;
}

- (char)mark
{
	if (self.q) return [self.supportInfo.userModeQPrefix safeCharacterAtIndex:0]; 
	if (self.a) return [self.supportInfo.userModeAPrefix safeCharacterAtIndex:0]; 
	if (self.o) return [self.supportInfo.userModeOPrefix safeCharacterAtIndex:0]; 
	if (self.h) return [self.supportInfo.userModeHPrefix safeCharacterAtIndex:0]; 
	if (self.v) return [self.supportInfo.userModeVPrefix safeCharacterAtIndex:0];
	
	return ' ';
}

- (BOOL)isOp
{
	return (self.o || self.a || self.q);
}

- (BOOL)isHalfOp 
{
	return (self.h || [self isOp]);
}

- (NSInteger)colorNumber
{
	if (_colorNumber < 0) {
		if ([_NSUserDefaults() boolForKey:@"UUIDBasedNicknameColorHashing"]) {
			self.colorNumber = (CFHash((__bridge CFTypeRef)([NSString stringWithUUID])) % _colorNumberMax);
		} else {
			self.colorNumber = (CFHash((__bridge CFTypeRef)([self.nick lowercaseString])) % _colorNumberMax);
		}
	}
	
	return _colorNumber;
}

- (BOOL)hasMode:(char)mode
{
	switch (mode) {
		case 'q': return self.q; break;
		case 'a': return self.a; break;
		case 'o': return self.o; break;
		case 'h': return self.h; break;
		case 'v': return self.v; break;
	}
	
	return NO;
}

- (CGFloat)totalWeight
{
	[self decayConversation];
	
	return (self.incomingWeight + self.outgoingWeight);
}

- (void)outgoingConversation
{
	CGFloat change = ((self.outgoingWeight == 0) ? 20 : 5);
	
	self.outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = ((self.incomingWeight == 0) ? 100 : 20);
	
	self.incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = ((self.outgoingWeight == 0) ? 4 : 1);
	
	self.outgoingWeight += change;
}

- (void)decayConversation
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	CGFloat minutes = ((now - self.lastFadedWeights) / 60);
	
	if (minutes > 1) {
		self.lastFadedWeights = now;
		
		if (self.incomingWeight > 0) {
			self.incomingWeight /= pow(2, minutes);
		}
		
		if (self.outgoingWeight > 0) {
			self.outgoingWeight /= pow(2, minutes);
		}
	}
}

- (BOOL)isEqual:(id)other
{
	if ([other isKindOfClass:[IRCUser class]] == NO) return NO;
	
	return ([self.nick caseInsensitiveCompare:[(id)other nick]] == NSOrderedSame);
}

- (NSComparisonResult)compare:(IRCUser *)other
{
	if (NSDissimilarObjects(self.q, other.q)) {
		return ((self.q) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.q) {
		return [self.nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(self.a, other.a)) {
		return ((self.a) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.a) {
		return [self.nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(self.o, other.o)) {
		return ((self.o) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.o) {
		return [self.nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(self.h, other.h)) {
		return ((self.h) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.h) {
		return [self.nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(self.v, other.v)) {
		return ((self.v) ? NSOrderedAscending : NSOrderedDescending);
	} else {
		return [self.nick caseInsensitiveCompare:other.nick];
	}
}

- (NSComparisonResult)compareUsingWeights:(IRCUser *)other
{
	CGFloat mine   = self.totalWeight;
	CGFloat others = other.totalWeight;
	
	if (mine > others) return NSOrderedAscending;
	if (mine < others) return NSOrderedDescending;
	
	return [self.nick.lowercaseString compare:other.nick.lowercaseString];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, self.nick];
}

@end