// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Sloppy mode parser. */

@implementation IRCChannelMode

@synthesize isupport;
@synthesize allModes;
@synthesize modeIndexes;

- (id)init
{
	if ((self = [super init])) {
		allModes = [NSMutableArray new];
		modeIndexes = [NSMutableDictionary new];
	}

	return self;
}

- (id)initWithChannelMode:(IRCChannelMode *)other
{
	isupport = other.isupport;
	allModes = other.allModes;
	modeIndexes = other.modeIndexes;
	
	return self;
}

- (void)dealloc
{
	[allModes drain];
	[modeIndexes drain];
	
	[super dealloc];
}

- (void)clear
{
	[allModes removeAllObjects];
	[modeIndexes removeAllObjects];
}

- (NSArray *)badModes 
{
	return [NSArray arrayWithObjects:@"q", @"a", @"o", @"h", @"v", @"b", @"e", @"I", nil];
}

- (NSArray *)update:(NSString *)str
{
	NSArray *ary = [isupport parseMode:str];
	
	for (IRCModeInfo *h in ary) {
		if (h.op) continue;
		    
		NSString *modec = [NSString stringWithChar:h.mode];
		
		if ([[self badModes] containsObject:modec]) continue;
		
		if ([modeIndexes containsKey:modec]) {
			NSInteger moindex = [modeIndexes integerForKey:modec];
			
			[allModes safeRemoveObjectAtIndex:moindex];
			[allModes safeInsertObject:h atIndex:moindex];
		} else {
			[allModes safeAddObject:h];
			
			[modeIndexes setInteger:[allModes indexOfObject:h] forKey:modec];
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
				h.param = NSNullObject;
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
	return [modeIndexes containsKey:mode];
}

- (IRCModeInfo *)modeInfoFor:(NSString *)mode
{
	BOOL objk = [self modeIsDefined:mode];
	
	if (objk == NO) {
		IRCModeInfo *m = [isupport createMode:mode];
		
		[allModes safeAddObject:m];
		[modeIndexes setInteger:[allModes indexOfObject:m] forKey:mode];
	}
	
	return [allModes safeObjectAtIndex:[modeIndexes integerForKey:mode]];
}

- (NSString *)format:(BOOL)maskK
{
	NSMutableString *str   = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	
	[str appendString:@"+"];
	
	for (IRCModeInfo *h in allModes) {
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