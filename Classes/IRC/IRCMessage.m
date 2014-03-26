/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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
		//[self parseLine:NSStringEmptyPlaceholder];
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
	[self parseLine:line forClient:nil];
}

- (void)parseLine:(NSString *)line forClient:(IRCClient *)client
{
	self.command = NSStringEmptyPlaceholder;

	self.isHistoric = NO;

	self.sender = [IRCPrefix new];
	self.params = [NSMutableArray new];
	
	NSMutableString *s = [line mutableCopy];

	// ---- //

    /* Get extensions from in front of input string. See IRCv3.atheme.org for
     more information regarding extensions in the IRC protocol. */

	/* We only bother searching for extensions if we already have a CAP that
	 is in relation to one. */

	if (client && client.CAPServerTime) {
		if ([s hasPrefix:@"@"]) {
			NSString *t = [[s getToken] substringFromIndex:1]; //Get token and remove @.
			
			NSArray *values = [t componentsSeparatedByString:@","];

			for (NSString *comp in values) {
				NSArray *info = [comp componentsSeparatedByString:@"="];

				NSAssertReturnLoopContinue(info.count == 2);

				NSString *extKey = info[0];
				NSString *extVal = info[1];

				/* Process @time= value inline for server-time. */

				BOOL hasTimeExt = [extKey isEqualToString:@"time"];

				NSAssertReturnLoopBreak(hasTimeExt);

				NSDate *date = [[self.worldController isoStandardDateFormatter] dateFromString:extVal];
				
				if (PointerIsEmpty(date)) {
					date = [NSDate dateWithTimeIntervalSince1970:[extVal doubleValue]];
				}

				if (date) {
					self.isHistoric = YES;

					self.receivedAt = date;
				}

				/* End inline procesing of the @time= and @t= extensions. */
			}
		}
	}

	if (PointerIsEmpty(self.receivedAt)) {
		self.receivedAt = [NSDate date];
	}

	// ---- //

    /* Begin the parsing of the actual input string. */
    /* First thing to do is get the sender information from in 
     front of the message. */

	if ([s hasPrefix:@":"]) {
		NSString *t = [[s getToken] substringFromIndex:1];

		NSString *nicknameInt = nil;
		NSString *usernameInt = nil;
		NSString *addressInt = nil;

		self.sender.hostmask = t;
		
		if ([t hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt]) {
			self.sender.nickname = nicknameInt;
            self.sender.username = usernameInt;
            self.sender.address = addressInt;
        } else {
			self.sender.nickname = t;
			self.sender.isServer = YES;
		}
	}

    /* Now that we have the sender information… continue to the
     actual command being used. */
    
	self.command = [[s getToken] uppercaseString];
	
	self.numericReply = [self.command integerValue];

    /* After the sender information and command information is extracted,
     there is not much left to the parse. Just searching for the beginning
     of a message segment or getting the next token. */
    
	while ([s length] > 0) {
		if ([s hasPrefix:@":"]) {
			[self.params addObject:[s substringFromIndex:1]];
			
			break;
		} else {
			[self.params addObject:[s getToken]];
		}
	}
	
}

- (NSString *)paramAt:(NSInteger)index
{
	if (index < [self.params count]) {
		return self.params[index];
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
	
	for (NSInteger i = index; i < [self.params count]; i++) {
		NSString *e = self.params[i];
		
		if (NSDissimilarObjects(i, index)) {
			[s appendString:NSStringWhitespacePlaceholder];
		}
		
		[s appendString:e];
	}
	
	return s;
}

@end
