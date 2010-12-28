// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
	isupport = [other.isupport retain];
	modeIndexes = other.modeIndexes;
	allModes = other.allModes;
	
	return self;
}

- (void)dealloc
{
	[isupport release];
	[allModes release];
	[modeIndexes release];
	
	[super dealloc];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelMode allocWithZone:zone] initWithChannelMode:self];
}

- (void)clear
{
	[allModes removeAllObjects];
	[modeIndexes removeAllObjects];
}

- (NSArray *)update:(NSString *)str
{
	NSArray *ary = [isupport parseMode:str];
	NSArray *badObjects = [NSArray arrayWithObjects:@"q", @"a", @"o", @"h", @"v", @"b", @"e", nil];
	
	for (IRCModeInfo *h in ary) {
		if (h.op) continue;
		    
		NSString *modec = [NSString stringWithChar:h.mode];
		
		if ([badObjects containsObject:modec]) continue;
		
		NSString *objk = [modeIndexes objectForKey:modec];
		if (objk) {
			NSInteger moindex = [objk integerValue];
			[allModes safeRemoveObjectAtIndex:moindex];
			[allModes insertObject:h atIndex:moindex];
		} else {
			[allModes addObject:h];
			
			NSInteger i = [allModes indexOfObject:h];
			[modeIndexes setObject:[NSNumber numberWithInteger:i] forKey:modec];
		}
	}
	
	return ary;
}

- (NSString *)getChangeCommand:(IRCChannelMode *)mode
{
	NSMutableString *str = [NSMutableString string];
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
				h.param = @"";
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
	NSString *objk = [modeIndexes objectForKey:mode];
	
	return BOOLReverseValue((objk == nil));
}

- (IRCModeInfo *)modeInfoFor:(NSString *)mode
{
	BOOL objk = [self modeIsDefined:mode];
	
	if (objk == NO) {
		IRCModeInfo *m = [isupport createMode:mode];
		[allModes addObject:m];
		NSInteger i = [allModes indexOfObject:m];
		[modeIndexes setObject:[NSNumber numberWithInteger:i] forKey:mode];
	}
	
	return [allModes safeObjectAtIndex:[[modeIndexes objectForKey:mode] integerValue]];
}

- (NSString *)format:(BOOL)maskK
{
	NSMutableString *str = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	
	[str appendString:@"+"];
	
	for (IRCModeInfo *h in allModes) {
		if (maskK == YES) {
			if ((const char)h.mode == 'k') continue;
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

@end