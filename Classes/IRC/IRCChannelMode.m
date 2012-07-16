/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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