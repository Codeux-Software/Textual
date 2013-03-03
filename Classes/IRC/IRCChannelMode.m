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

@interface IRCChannelMode ()
@property (nonatomic, strong) NSMutableDictionary *allModes;
@end

@implementation IRCChannelMode

- (id)init
{
	if ((self = [super init])) {
		self.allModes = [NSMutableDictionary dictionary];
	}

	return self;
}

- (id)initWithChannelMode:(IRCChannelMode *)other
{
	if ((self = [super init])) {
		self.isupport = other.isupport;
		self.allModes = other.allModes;

		return self;
	}

	return nil;
}

- (void)clear
{
	[self.allModes removeAllObjects];
}

- (NSDictionary *)modeInformation
{
	return self.allModes;
}

- (NSArray *)badModes
{
	return @[@"q", @"a", @"o", @"h", @"v", @"b", @"e", @"I"];
}

- (NSArray *)update:(NSString *)str
{
	NSArray *ary = [self.isupport parseMode:str];

	for (IRCModeInfo *h in ary) {
		if ([self.badModes containsObject:h.modeToken]) {
			continue;
		}
		
		[self.allModes safeSetObject:h forKey:h.modeToken];
	}

	return ary;
}

- (NSString *)getChangeCommand:(IRCChannelMode *)mode
{
	NSMutableString *frstr = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];
	NSMutableString *track = [NSMutableString string];

	NSArray *modes = mode.modeInformation.sortedDictionaryKeys;

	/* Build the removals first. */
	for (NSString *mkey in modes) {
		IRCModeInfo *h = [mode.allModes objectForKey:mkey];

		if (h.modeIsSet) {
			if (NSObjectIsNotEmpty(h.modeParamater)) {
				[trail appendFormat:@" %@", h.modeParamater];
			}

			[track appendString:h.modeToken];

			if ([h.modeToken isEqualToString:@"k"]) {
				h.modeParamater = NSStringEmptyPlaceholder;
			} else {
				if ([h.modeToken isEqualToString:@"l"]) {
					h.modeParamater = 0;
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
		IRCModeInfo *h = [mode.allModes objectForKey:mkey];

		if (h.modeIsSet == NO) {
			if (NSObjectIsNotEmpty(h.modeParamater)) {
				[trail appendFormat:@" %@", h.modeParamater];
			}

			[track appendString:h.modeToken];
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
	return [self.allModes containsKey:mode];
}

- (IRCModeInfo *)modeInfoFor:(NSString *)mode
{
	if ([self modeIsDefined:mode] == NO) {
		IRCModeInfo *m = [self.isupport createMode:mode];

		[self.allModes safeSetObject:m forKey:mode];
	}

	return [self.allModes objectForKey:mode];
}

- (NSString *)format:(BOOL)maskK
{
	NSMutableString *frstr = [NSMutableString string];
	NSMutableString *trail = [NSMutableString string];

	[frstr appendString:@"+"];

	NSArray *modes = self.allModes.sortedDictionaryKeys;

	for (NSString *mkey in modes) {
		IRCModeInfo *h = [self.allModes objectForKey:mkey];

		if (h.modeIsSet) {
			if (h.modeParamater && maskK == NO) {
				if ([h.modeToken isEqualToString:@"k"]) {
					[trail appendFormat:@" ******"];
				} else {
					[trail appendFormat:@" %@", h.modeParamater];
				}
			}

			[frstr appendFormat:@"%@", h.modeToken];
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

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelMode allocWithZone:zone] initWithChannelMode:self];
}

@end
