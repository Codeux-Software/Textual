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

@implementation IRCMessage

- (id)init
{
	if ((self = [super init])) {
		[self parseLine:NSStringEmptyPlaceholder];
	}
	
	return self;
}

- (id)initWithLine:(NSString *)line
{
	if ((self = [super init])) {
		[self parseLine:line];
	}
	
	return self;
}

- (void)parseLine:(NSString *)line
{
	self.command = NSStringEmptyPlaceholder;
	
	self.sender = [IRCPrefix new];
	self.params = [NSMutableArray new];
	
	NSMutableString *s = [line mutableCopy];

	// ---- //
	
	NSMutableDictionary *extensions = [NSMutableDictionary dictionary];
	
	if ([s hasPrefix:@"@"]) {
		NSString *t = [s.getToken substringFromIndex:1]; //Get token and remove @.
		
		NSArray *values = [t componentsSeparatedByString:@","];

		for (NSString *comp in values) {
			NSArray *info = [comp componentsSeparatedByString:@"="];
			
			if (NSDissimilarObjects(info.count, 2)) {
				continue;
			}
			
			[extensions setObject:[info objectAtIndex:1]
						   forKey:[info objectAtIndex:0]];
		}
	}

	// ---- //
	
	NSString *serverTime = NSDictionaryObjectKeyValueCompare(extensions, @"t", [extensions objectForKey:@"time"]);

	if (NSObjectIsNotEmpty(serverTime)) {
		NSDateFormatter *dateFormatter = [NSDateFormatter new];
		
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateFormat:@"yyy-MM-dd'T'HH:mm:ss.SSS'Z'"]; //2011-10-19T16:40:51.620Z
		
		NSDate *date = [dateFormatter dateFromString:serverTime];
		
		if (PointerIsEmpty(date)) {
			date = [NSDate dateWithTimeIntervalSince1970:[serverTime doubleValue]];
		}
		
		if (PointerIsEmpty(date)) {
			date = [NSDate date];
		}
		
		self.receivedAt = date;
	} else {
		self.receivedAt = [NSDate date];
	}

	// ---- //
	
	if ([s hasPrefix:@":"]) {
		NSString *t;
		
		t = [s getToken];
		t = [t safeSubstringFromIndex:1];
		
		self.sender.raw = t;
		
		NSInteger i = [t findCharacter:'!'];
		
		if (i < 0) {
			self.sender.nick = t;
			self.sender.isServer = YES;
		} else {
			self.sender.nick = [t safeSubstringToIndex:i];
			
			t = [t safeSubstringAfterIndex:i];
			i = [t findCharacter:'@'];
			
			if (i >= 0) {
				self.sender.user = [t safeSubstringToIndex:i];
				self.sender.address = [t safeSubstringAfterIndex:i];
			}
		}
	}
	
	self.command = [s.getToken uppercaseString];
	
	self.numericReply = [self.command integerValue];
	
	while (NSObjectIsNotEmpty(s)) {
		if ([s hasPrefix:@":"]) {
			[self.params safeAddObject:[s safeSubstringFromIndex:1]];
			
			break;
		} else {
			[self.params safeAddObject:[s getToken]];
		}
	}
	
}

- (NSString *)paramAt:(NSInteger)index
{
	if (index < self.params.count) {
		return [self.params safeObjectAtIndex:index];
	} else {
		return NSStringEmptyPlaceholder;
	}
}

- (NSString *)sequence
{
	if ([self.params count] < 2) {
		return [self sequence:0];
	} else {
		return [self sequence:1];
	}
}

- (NSString *)sequence:(NSInteger)index
{
	NSMutableString *s = [NSMutableString string];
	
	for (NSInteger i = index; i < self.params.count; i++) {
		NSString *e = [self.params safeObjectAtIndex:i];
		
		if (NSDissimilarObjects(i, index)) {
			[s appendString:NSStringWhitespacePlaceholder];
		}
		
		[s appendString:e];
	}
	
	return s;
}

- (NSString *)description
{
	NSMutableString *ms = [NSMutableString string];
	
	[ms appendString:@"<IRCMessage "];
	[ms appendString:self.command];
	
	for (NSString *s in self.params) {
		[ms appendString:NSStringWhitespacePlaceholder];
		[ms appendString:s];
	}
	
	[ms appendString:@">"];
	
	return ms;
}

@end
