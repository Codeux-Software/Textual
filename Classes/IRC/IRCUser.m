// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define COLOR_NUMBER_MAX	30

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
@synthesize nick;
@synthesize lastFadedWeights;
@synthesize supportInfo;

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
	[nick drain];
	[address drain];
	[username drain];
	
	[super dealloc];
}

- (NSString *)banMask
{
	if (NSObjectIsEmpty(address)) {
		return [NSString stringWithFormat:@"%@!*@*", nick];
	} else {
		NSString *ident = ((username) ?: @"*");
		
		switch ([Preferences banFormat]) {
			case HMBAN_FORMAT_WHNIN:  return [NSString stringWithFormat:@"*!*@%@", address];	
			case HMBAN_FORMAT_WHAINN: return [NSString stringWithFormat:@"*!%@@%@", ident, address];
			case HMBAN_FORMAT_WHANNI: return [NSString stringWithFormat:@"%@!*%@", nick, address];
			case HMBAN_FORMAT_EXACT:  return [NSString stringWithFormat:@"%@!%@@%@", nick, ident, address];
		}
	}
	
	return nil;
}

- (char)mark
{
	if (q) return [supportInfo.userModeQPrefix safeCharacterAtIndex:0];
	if (a) return [supportInfo.userModeAPrefix safeCharacterAtIndex:0];
	if (o) return [supportInfo.userModeOPrefix safeCharacterAtIndex:0];
	if (h) return [supportInfo.userModeHPrefix safeCharacterAtIndex:0];
	if (v) return [supportInfo.userModeVPrefix safeCharacterAtIndex:0];
	
	return ' ';
}

- (BOOL)isOp
{
	return (o || a || q);
}

- (BOOL)isHalfOp 
{
	return (h || [self isOp]);
}

- (NSInteger)colorNumber
{
	if (colorNumber < 0) {
		colorNumber = (CFHash([nick lowercaseString]) % COLOR_NUMBER_MAX);
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

- (CGFloat)totalWeight
{
	[self decayConversation];
	
	return (incomingWeight + outgoingWeight);
}

- (void)outgoingConversation
{
	CGFloat change = ((outgoingWeight == 0) ? 20 : 5);
	
	outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = ((incomingWeight == 0) ? 100 : 20);
	
	incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = ((outgoingWeight == 0) ? 4 : 1);
	
	outgoingWeight += change;
}

- (void)decayConversation
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	CGFloat minutes = ((now - lastFadedWeights) / 60);
	
	if (minutes > 1) {
		lastFadedWeights = now;
		
		if (incomingWeight > 0) {
			incomingWeight /= pow(2, minutes);
		}
		
		if (outgoingWeight > 0) {
			outgoingWeight /= pow(2, minutes);
		}
	}
}

- (BOOL)isEqual:(id)other
{
	if ([other isKindOfClass:[IRCUser class]] == NO) return NO;
	
	return ([nick caseInsensitiveCompare:[(id)other nick]] == NSOrderedSame);
}

- (NSComparisonResult)compare:(IRCUser *)other
{
	if (NSDissimilarObjects(q, other.q)) {
		return ((q) ? NSOrderedAscending : NSOrderedDescending);
	} else if (q) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(a, other.a)) {
		return ((a) ? NSOrderedAscending : NSOrderedDescending);
	} else if (a) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(o, other.o)) {
		return ((o) ? NSOrderedAscending : NSOrderedDescending);
	} else if (o) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(h, other.h)) {
		return ((h) ? NSOrderedAscending : NSOrderedDescending);
	} else if (h) {
		return [nick caseInsensitiveCompare:other.nick];
	} else if (NSDissimilarObjects(v, other.v)) {
		return ((v) ? NSOrderedAscending : NSOrderedDescending);
	} else {
		return [nick caseInsensitiveCompare:other.nick];
	}
}

- (NSComparisonResult)compareUsingWeights:(IRCUser *)other
{
	CGFloat mine   = self.totalWeight;
	CGFloat others = other.totalWeight;

	if (mine > others) return NSOrderedAscending;
	if (mine < others) return NSOrderedDescending;
	
	return [[nick lowercaseString] compare:[other.nick lowercaseString]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, nick];
}

@end