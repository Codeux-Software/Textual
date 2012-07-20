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

@implementation IRCSendingMessage

- (id)initWithCommand:(NSString *)aCommand
{
	if ((self = [super init])) {
		self.completeColon = YES;
		
		self.params = [NSMutableArray new];
		
		self.command = [aCommand uppercaseString];
	}
	
	return self;
}

- (void)addParameter:(NSString *)parameter
{
	[self.params safeAddObject:parameter];
}

- (NSString *)string
{
	if (NSObjectIsEmpty(self.string)) {
		BOOL forceCompleteColon = NO;
		if ([self.command isEqualToString:IRCPrivateCommandIndex("privmsg")] ||
			[self.command isEqualToString:IRCPrivateCommandIndex("notice")]) {
			
			forceCompleteColon = YES;
		} else if (   [self.command isEqualToString:IRCPrivateCommandIndex("nick")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("mode")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("join")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("names")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("who")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("list")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("invite")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("whois")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("whowas")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("ison")]
				   || [self.command isEqualToString:IRCPrivateCommandIndex("user")]) {
			
			self.completeColon = NO;
		}
		
		NSMutableString *d = [NSMutableString new];
		
		[d appendString:self.command];
		
		NSInteger count = [self.params count];
		
		if (NSObjectIsNotEmpty(self.params)) {
			for (NSInteger i = 0; i < (count - 1); ++i) {
				NSString *s = [self.params safeObjectAtIndex:i];
				
				[d appendString:NSStringWhitespacePlaceholder];
				[d appendString:s];
			}
			
			[d appendString:NSStringWhitespacePlaceholder];
			
			NSString *s = [self.params safeObjectAtIndex:(count - 1)];
			
			BOOL firstColonOrSpace = NO;
			
			if (NSObjectIsNotEmpty(s)) {
				UniChar c = [s characterAtIndex:0];
				
				firstColonOrSpace = (c == ' ' || c == ':');
			}
			
			if (forceCompleteColon || (self.completeColon && (NSObjectIsEmpty(s) || firstColonOrSpace))) {
				[d appendString:@":"];
			}
			
			[d appendString:s];
		}
		
		[d appendString:@"\r\n"];
		
		_string = d;
	}
	
	return self.string;
}

@end