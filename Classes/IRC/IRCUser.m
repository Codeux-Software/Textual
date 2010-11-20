// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCUser.h"
#import "NSStringHelper.h"

#define COLOR_NUMBER_MAX	16

@interface IRCUser (Private)
- (void)decayConversation;
@end

@implementation IRCUser

@synthesize username;
@synthesize address;
@synthesize q;
@synthesize a;
@synthesize o;
@synthesize h;
@synthesize v;
@synthesize isMyself;
@synthesize incomingWeight;
@synthesize outgoingWeight;

- (id)init
{
	if ((self = [super init])) {
		colorNumber = -1;
		lastFadedWeights = CFAbsoluteTimeGetCurrent();
	}
	return self;
}

- (void)dealloc
{
	[nick release];
	[username release];
	[address release];
	[super dealloc];
}

- (NSString*)nick
{
	return nick;
}

- (void)setNick:(NSString *)value
{
	if (nick != value) {
		[nick release];
		nick = [value retain];
	}
}

- (NSString *)banMask
{
	if ([address length] < 1) {
		return [NSString stringWithFormat:@"%@!*@*", nick];
	} else {
		if ([username length] < 1) {
			return [NSString stringWithFormat:@"*!*@%@", address];	
		} else {
			return [NSString stringWithFormat:@"*!%@@%@", username, address];
		}
	}
}

- (char)mark
{
	if (q) return '~';
	if (a) return '&';
	if (o) return '@';
	if (h) return '%';
	if (v) return '+';
	return ' ';
}

- (BOOL)isOp
{
	return o || a || q;
}

- (BOOL)isHalfOp 
{
	return h;
}

- (NSInteger)colorNumber
{
	if (colorNumber < 0) {
		colorNumber = CFHash([nick lowercaseString]) % COLOR_NUMBER_MAX;
	}
	return colorNumber;
}

- (BOOL)hasMode:(char)mode
{
	switch (mode) {
		case 'q': return q;
		case 'a': return a;
		case 'o': return o;
		case 'h': return h;
		case 'v': return v;
	}
	return NO;
}

- (CGFloat)weight
{
	[self decayConversation];
	return incomingWeight + outgoingWeight;
}

- (void)outgoingConversation
{
	CGFloat change = (outgoingWeight == 0) ? 20 : 5;
	outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = (incomingWeight == 0) ? 100 : 20;
	incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = (outgoingWeight == 0) ? 4 : 1;
	outgoingWeight += change;
}

- (void)decayConversation
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	CGFloat minutes = (now - lastFadedWeights) / 60;
	
	if (minutes > 1) {
		lastFadedWeights = now;
		if (incomingWeight > 0) {
			incomingWeight /= (pow(2, minutes));
		}
		if (outgoingWeight > 0) {
			outgoingWeight /= (pow(2, minutes));
		}
	}
}

- (BOOL)isEqual:(id)other
{
	if (![other isKindOfClass:[IRCUser class]]) return NO;
	IRCUser* u = other;
	return [nick caseInsensitiveCompare:u.nick] == NSOrderedSame;
}

- (NSComparisonResult)compare:(IRCUser*)other
{
	if (q != other.q) {
		return q ? NSOrderedAscending : NSOrderedDescending;
	} else if (q) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (a != other.a) {
		return a ? NSOrderedAscending : NSOrderedDescending;
	} else if (a) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (o != other.o) {
		return o ? NSOrderedAscending : NSOrderedDescending;
	} else if (o) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (h != other.h) {
		return h ? NSOrderedAscending : NSOrderedDescending;
	} else if (h) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (v != other.v) {
		return v ? NSOrderedAscending : NSOrderedDescending;
	} else {
		return [nick caseInsensitiveCompare:other.nick];
	}
}

- (NSComparisonResult)compareUsingWeights:(IRCUser*)other
{
	CGFloat mine = self.weight;
	CGFloat others = other.weight;

	if (mine > others) return NSOrderedAscending;
	if (mine < others) return NSOrderedDescending;
	return [[nick lowercaseString] compare:[other.nick lowercaseString]];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, nick];
}

@synthesize lastFadedWeights;
@end