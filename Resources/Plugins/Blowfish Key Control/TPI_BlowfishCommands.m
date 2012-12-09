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

#import "TPI_BlowfishCommands.h"

/* It may seem confusing why these commands are an extension when
 the actual encryption support is built into Textual. Well, it is
 an extension just because the actual commands are considered 
 not that important to be in the actual core when an everyday
 user would use the actual user interface to set a key. These
 are considered more an addon for "pro" users. */

#define TXExchangeRequestPrefix			@"DH1080_INIT "
#define TXExchangeResponsePrefix		@"DH1080_FINISH "

@implementation TPI_BlowfishCommands

#pragma mark -
#pragma mark Plugin Structure

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	IRCChannel *c = [client.world selectedChannelOn:client];
	
	if (c.isChannel || c.isTalk) {
		messageString = [messageString trim];
		
		if ([messageString contains:NSStringWhitespacePlaceholder]) {
			messageString = [messageString substringToIndex:[messageString stringPosition:NSStringWhitespacePlaceholder]];
		}
		
		if ([commandString isEqualToString:@"SETKEY"]) {
			if (NSObjectIsEmpty(messageString)) {
				c.config.encryptionKey = nil;
				
				[client printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
			} else {
				if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
					if ([c.config.encryptionKey isEqualToString:messageString] == NO) {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionKeyChanged") channel:c];
					}
				} else {
					if (c.isTalk) {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionStartedInQuery") channel:c];
					} else {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
					}
				}
				
				c.config.encryptionKey = messageString;
			}
		} else if ([commandString isEqualToString:@"DELKEY"]) {
			c.config.encryptionKey = nil;
			
			[client printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
		} else if ([commandString isEqualToString:@"KEY"]) {
			if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
				[client printDebugInformation:TXTFLS(@"BlowfishCurrentEncryptionKey", c.config.encryptionKey) channel:c];
			} else {	
				[client printDebugInformation:TXTLS(@"BlowfishNoEncryptionKeySet") channel:c];
			}
		} else if ([commandString isEqualToString:@"KEYX"]) {
			[client printDebugInformation:TXTLS(@"BlowfishKeyExchangeFeatureNotReadyYet") channel:c];
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"setkey", @"delkey", @"key", @"keyx"];
}

- (NSDictionary *)pluginOutputDisplayRules
{
	/* This is an undocumented plugin call to suppress certain messages. */
	/* These rules hide encryption request and replies in private messages. 
	 Now Textual just needs to add actual support for them… */
	
	NSMutableDictionary *rules = [NSMutableDictionary dictionary];
	
	NSArray *privmsgRule_1 = @[[@"^" stringByAppendingString:TXExchangeRequestPrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];
	
	NSArray *privmsgRule_2 = @[[@"^" stringByAppendingString:TXExchangeResponsePrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];
	
	rules[IRCCommandFromLineType(TVCLogLineNoticeType)] = @[privmsgRule_1, privmsgRule_2];
	
	return rules;
}

@end