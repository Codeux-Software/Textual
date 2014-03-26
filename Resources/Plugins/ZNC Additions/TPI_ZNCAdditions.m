/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#import "TPI_ZNCAdditions.h"

@implementation TPI_ZNCAdditions

#pragma mark -
#pragma mark Plugin API

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict
{
	if ([client isZNCBouncerConnection]) {
		NSString *sender = [senderDict objectForKey:@"senderNickname"];
		NSString *message = [messageDict objectForKey:@"messageSequence"];

		if ([sender isEqualToString:@"*status"] && [message hasPrefix:@"Disconnected from IRC"]) {
			/* We listen for ZNC disconnects so that we can terminate channels when we
			 disconnect from the server ZNC was connected to. ZNC does not localize 
			 itself so detecting these disconnects is not very hard… */

			/* handleIRCSideDisconnect: calls -deactivate on IRCChannel. That call in 
			 IRCChannel posts a script event to the active style. Therefore, we have to
			 invoke the calls on the main thread because WebKit is not thread safe. */
			[[self iomt] handleIRCSideDisconnect:client];
		}
	}
}

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	BOOL isDetach = [commandString isEqualIgnoringCase:@"DETACH"];
	BOOL isAttach = [commandString isEqualIgnoringCase:@"ATTACH"];
	
	if (isAttach || isDetach) {
		if ([client isZNCBouncerConnection] == NO) {
			[client printDebugInformation:TPILS(@"BasicLanguage[1000]")];

			return;
		}

		messageString = [messageString trim];
		
		IRCChannel *matchedChannel;
		
		if ([messageString isChannelName:client]) {
			matchedChannel = [client findChannel:messageString];
		} else {
			matchedChannel = [[self worldController] selectedChannel];
		}
		
		if (matchedChannel) {
			[[matchedChannel config] setAutoJoin:isAttach];
			
			if (isDetach) {
				[client sendLine:[NSString stringWithFormat:@"%@ %@", commandString, [matchedChannel name]]];
			
				[client printDebugInformation:TPIFLS(@"BasicLanguage[1001]", [matchedChannel name]) channel:matchedChannel];
			} else {
				[client joinUnlistedChannel:[matchedChannel name]];
			}
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"detach", @"attach"];
}

- (NSArray *)pluginSupportsServerInputCommands
{
	return @[@"privmsg"];
}

- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	NSAssertReturnR([client isZNCBouncerConnection], input);

	/* Who is sending this message? */
	if (NSObjectsAreEqual([[input sender] nickname], @"*buffextras") == NO) {
		return input;
	}

	/* What type of message is this person sending? */
	if (NSObjectsAreEqual([input command], IRCPrivateCommandIndex("privmsg")) == NO) {
		return input;
	}

	/* Begin processing input… */
	NSAssertReturnR(([[input params] count] == 2), input);

	NSMutableString *s = [[input params][1] mutableCopy];

	/* Define user information. */
	NSString *hostmask = [s getToken];

	NSString *nicknameInt = nil;
	NSString *usernameInt = nil;
	NSString *addressInt = nil;

	[[input sender] setHostmask:hostmask];

	if ([hostmask hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt]) {
		[[input sender] setNickname:nicknameInt];
		[[input sender] setUsername:usernameInt];
		[[input sender] setAddress:addressInt];

		if (NSObjectsAreEqual([[input sender] nickname], [client localNickname])) {
			return input; // Do not post these events for self.
		}
	} else {
		[[input sender] setNickname:hostmask];
		[[input sender] setIsServer:NO];
	}

	[input setIsPrintOnlyMessage:YES];

	/* Start actual work. */
	if ([s hasPrefix:@"is now known as "]) {
		/* Begin nickname change. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"is now known as " length])];

		NSString *newNickname = [s getToken];

		NSObjectIsEmptyAssertReturn(newNickname, input);

		[input setCommand:IRCPrivateCommandIndex("nick")];

		[[input params] removeObjectAtIndex:1];
		[[input params] addObject:newNickname];
		/* End nickname change. */
	}
	else if ([s isEqualToString:@"joined"])
	{
		/* Begin channel join. */
		[input setCommand:IRCPrivateCommandIndex("join")];

		[[input params] removeObjectAtIndex:1];
		/* End channel join. */
	}
	else if ([s hasPrefix:@"set mode: "])
	{
		/* Begin mode processing. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"set mode: " length])];

		[input setCommand:IRCPrivateCommandIndex("mode")];

		NSString *modesSet = [s getToken];

		NSObjectIsEmptyAssertReturn(modesSet, input);

		[[input params] removeObjectAtIndex:1];

		[[input params] safeAddObject:modesSet];
		[[input params] safeAddObject:s];
		/* End mode processing. */
	}
	else if ([s hasPrefix:@"quit with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin quit message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"quit with message: [" length])];
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];

		[input setCommand:IRCPrivateCommandIndex("quit")];

		[[input params] removeObjectAtIndex:1];
		[[input params] safeAddObject:s];
		/* End quit message. */
	}
	else if ([s hasPrefix:@"parted with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin part message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"parted with message: [" length])];
		[s deleteCharactersInRange:NSMakeRange((s.length - 1), 1)];

		[input setCommand:IRCPrivateCommandIndex("part")];

		[[input params] removeObjectAtIndex:1];
		[[input params] safeAddObject:s];
		/* End part message. */
	}
	else if ([s hasPrefix:@"kicked "] && [s hasSuffix:@"]"])
	{
		/* Begin kick message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"kicked " length])];
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];

		NSString *whoKicked = [s getToken];

		if (NSObjectIsEmpty(whoKicked) || [s hasPrefix:@"Reason: ["] == NO) {
			return input;
		}

		[s deleteCharactersInRange:NSMakeRange(0, [@"Reason: [" length])];

		[input setCommand:IRCPrivateCommandIndex("kick")];

		[[input params] removeObjectAtIndex:1];

		[[input params] safeAddObject:whoKicked];
		[[input params] safeAddObject:s];
		/* End kick message. */
	}
	else if ([s hasPrefix:@"changed the topic to: "])
	{
		/* Begin topic change. */
		/* We get the latest topic on join so we tell Textual to ignore this line. */

		return nil;
		/* End topic change. */
	}

	return input;
}

#pragma mark -
#pragma mark Private API

- (void)handleIRCSideDisconnect:(IRCClient *)client
{
	for (IRCChannel *c in [client channels]) {
		NSAssertReturnLoopContinue( [c isActive]);
        NSAssertReturnLoopContinue([[c name] hasPrefix:@"~#"] == NO);
		
        [c deactivate];
	}

	[[self worldController] reloadTreeGroup:client];
}

@end
