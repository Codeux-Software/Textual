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

@interface IRCChannelMode ()
@property (nonatomic, strong) NSMutableDictionary *allModes;
@end

@implementation IRCChannelMode

- (instancetype)init
{
	if ((self = [super init])) {
		self.allModes = [NSMutableDictionary dictionary];
	}

	return self;
}

- (void)clear
{
	@synchronized(self.allModes) {
		[self.allModes removeAllObjects];
	}
}

- (NSDictionary *)modeInformation
{
	@synchronized(self.allModes) {
		return [NSDictionary dictionaryWithDictionary:self.allModes];
	}
}

- (NSArray *)badModes
{
	return @[@"b", @"e", @"I"];
}

- (NSArray *)update:(NSString *)str
{
	NSArray *ary = [self.supportInfo parseMode:str];

	@synchronized(self.allModes) {
		for (IRCModeInfo *h in ary) {
			/* Get basic info. */
			NSString *modeSymbol = [h modeToken];

			/* Do not allow a predefined list of modes. */
			if ([[self badModes] containsObject:modeSymbol]) {
				continue;
			}
			
			/* Do not allow user symbols. */
			if ([[self supportInfo] modeIsSupportedUserPrefix:modeSymbol]) {
				continue;
			}
			
			/* Populate new info. */
			self.allModes[modeSymbol] = h;
		}
	}

	return ary;
}

- (NSString *)getChangeCommand:(IRCChannelMode *)mode
{
	NSMutableString *frstr = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	NSMutableString *track = [NSMutableString string];

	NSDictionary *modeInfo = [mode modeInformation];
	
	NSArray *modes = [modeInfo sortedDictionaryKeys];

	/* Build the removals first. */
	for (NSString *mkey in modes) {
		IRCModeInfo *h = modeInfo[mkey];
		
		NSString *symbol = [h modeToken];
		NSString *param = [h modeParamater];

		if ([h modeIsSet]) {
			if ([param length] > 0) {
				[trail appendFormat:@" %@", param];
			}

			[track appendString:symbol];

			if ([symbol isEqualToString:@"k"]) {
				[h setModeParamater:NSStringEmptyPlaceholder];
			} else {
				if ([symbol isEqualToString:@"l"]) {
					[h setModeParamater:@"0"];
				}
			}
		}
	}

	if (track) {
		[frstr appendString:@"+"];
		[frstr appendString:track];

		[track setString:NSStringEmptyPlaceholder];
	}

	/* Build the additions next. */
	for (NSString *mkey in modes) {
		IRCModeInfo *h = modeInfo[mkey];
		
		NSString *symbol = [h modeToken];
		NSString *param = [h modeParamater];

		if ([h modeIsSet] == NO) {
			if ([param length] > 0) {
				[trail appendFormat:@" %@", param];
			}

			[track appendString:symbol];
		}
	}
	
	if (track) {
		[frstr appendString:@"-"];
		[frstr appendString:track];
	}

	return [frstr stringByAppendingString:trail];
}

- (BOOL)modeIsDefined:(NSString *)mode
{
	@synchronized(self.allModes) {
		return [self.allModes containsKey:mode];
	}
}

- (IRCModeInfo *)modeInfoFor:(NSString *)mode
{
	NSObjectIsEmptyAssertReturn(mode, nil);
	
	if ([self modeIsDefined:mode] == NO) {
		IRCModeInfo *m = [self.supportInfo createMode:mode];
		
		@synchronized(self.allModes) {
			self.allModes[mode] = m;
		}
	}
	
	@synchronized(self.allModes) {
		return self.allModes[mode];
	}
}

- (NSString *)format:(BOOL)maskK
{
	NSMutableString *frstr = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];

	[frstr appendString:@"+"];

	NSDictionary *modeInfo = [self modeInformation];
	
	NSArray *modes = [modeInfo sortedDictionaryKeys];

	for (NSString *mkey in modes) {
		IRCModeInfo *h = modeInfo[mkey];
		
		NSString *symbol = [h modeToken];
		NSString *param = [h modeParamater];

		if ([h modeIsSet]) {
			if ([param length] > 0) {
				if ([symbol isEqualToString:@"k"] && maskK) {
					[trail appendFormat:@" ******"];
				} else {
					[trail appendFormat:@" %@", param];
				}
			}

			[frstr appendFormat:@"%@", symbol];
		}
	}

	return [frstr stringByAppendingString:trail];
}

- (NSString *)string
{
	return [self format:NO];
}

- (NSString *)titleString
{
	return [self format:YES];
}

- (id)copyWithZone:(NSZone *)zone
{
	IRCChannelMode *newInstance = [[IRCChannelMode allocWithZone:zone] init];

	[newInstance setSupportInfo:self.supportInfo];

	@synchronized(self.allModes) {
		[[newInstance allModes] addEntriesFromDictionary:self.allModes];
	}
	
	return newInstance;
}

@end
