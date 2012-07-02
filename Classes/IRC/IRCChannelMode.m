// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

/* Sloppy mode parser. */

@implementation IRCChannelMode

- (id)init
{
	if ((self = [super init])) {
		self.allModes		= [NSMutableArray new];
		self.modeIndexes	= [NSMutableDictionary new];
	}
	
	return self;
}

- (id)initWithChannelMode:(IRCChannelMode *)other
{
	self.isupport		= other.isupport;
	self.allModes		= other.allModes;
	self.modeIndexes	= other.modeIndexes;
	
	return self;
}

- (void)clear
{
	[self.allModes		removeAllObjects];
	[self.modeIndexes	removeAllObjects];
}

- (NSArray *)badModes 
{
	return @[@"q", @"a", @"o", @"h", @"v", @"b", @"e", @"I"];
}

- (NSArray *)update:(NSString *)str
{
	NSArray *ary = [self.isupport parseMode:str];
	
	for (IRCModeInfo *h in ary) {
		if (h.op) continue;
		
		NSString *modec = [NSString stringWithChar:h.mode];
		
		if ([[self badModes] containsObject:modec]) continue;
		
		if ([self.modeIndexes containsKey:modec]) {
			NSInteger moindex = [self.modeIndexes integerForKey:modec];
			
			[self.allModes safeRemoveObjectAtIndex:moindex];
			[self.allModes safeInsertObject:h atIndex:moindex];
		} else {
			[self.allModes safeAddObject:h];
			
			[self.modeIndexes setInteger:[self.allModes indexOfObject:h] forKey:modec];
		}
	}
	
	return ary;
}

- (NSString *)getChangeCommand:(IRCChannelMode *)mode
{
	NSMutableString *str   = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	
	for (IRCModeInfo *h in mode.allModes) {
		if (h.plus == YES) {
			if (h.param) {
				[trail appendFormat:@" %@", h.param];
			}
			
			[str appendFormat:@"+%c", h.mode];
		} else {
			if (h.param) {
				[trail appendFormat:@" %@", h.param];
			}
			
			[str appendFormat:@"-%c", h.mode];
			
			if (h.mode == 'k') {
				h.param = NSStringEmptyPlaceholder;
			} else {
				if (h.mode == 'l') {
					h.param = 0;
				}
			}
		}
	}
	
	return [[str stringByAppendingString:trail] trim];
}

- (BOOL)modeIsDefined:(NSString *)mode
{
	return [self.modeIndexes containsKey:mode];
}

- (IRCModeInfo *)modeInfoFor:(NSString *)mode
{
	BOOL objk = [self modeIsDefined:mode];
	
	if (objk == NO) {
		IRCModeInfo *m = [self.isupport createMode:mode];
		
		[self.allModes safeAddObject:m];
		
		[self.modeIndexes setInteger:[self.allModes indexOfObject:m] forKey:mode];
	}
	
	return [self.allModes safeObjectAtIndex:[self.modeIndexes integerForKey:mode]];
}

- (NSString *)format:(BOOL)maskK
{
	NSMutableString *str   = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	
	[str appendString:@"+"];
	
	for (IRCModeInfo *h in self.allModes) {
		if (maskK == YES) {
			if (h.mode == 'k') continue;
		}
		
		if (h.plus) {
			if (h.param) {
				[trail appendFormat:@" %@", h.param];
			}
			
			[str appendFormat:@"%c", h.mode];
		}
	}
	
	return [[str stringByAppendingString:trail] trim];
}

- (NSString *)string
{
	return [self format:NO];
}

- (NSString *)titleString
{
	return [self format:YES];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelMode allocWithZone:zone] initWithChannelMode:self];
}

@end