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

- (void)didReceiveServerInputOnClient:(IRCClient *)client
					senderInformation:(NSDictionary *)senderDict
				   messageInformation:(NSDictionary *)messageDict
{
	if ([client isZNCBouncerConnection]) {
		NSString *sender = senderDict[@"senderNickname"];
		NSString *message = messageDict[@"messageSequence"];

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

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	BOOL isDetach = [commandString isEqualIgnoringCase:@"DETACH"];
	BOOL isAttach = [commandString isEqualIgnoringCase:@"ATTACH"];
	
	if (isAttach || isDetach) {
		if ([client isZNCBouncerConnection] == NO) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]")];

			return;
		}

		messageString = [messageString trim];
		
		IRCChannel *matchedChannel;
		
		if ([messageString isChannelName:client]) {
			matchedChannel = [client findChannel:messageString];
		} else {
			matchedChannel = [mainWindow() selectedChannel];
		}
		
		if (matchedChannel) {
			[[matchedChannel config] setAutoJoin:isAttach];
			
			if (isDetach) {
				[client sendLine:[NSString stringWithFormat:@"%@ %@", commandString, [matchedChannel name]]];
			
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]", [matchedChannel name]) channel:matchedChannel];
			} else {
				[client joinUnlistedChannel:[matchedChannel name]];
			}
		}
	}
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"detach", @"attach"];
}

- (NSArray *)subscribedServerInputCommands
{
	return @[@"privmsg"];
}

- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	/* Only do work if client is even detected as ZNC. */
	if ([client isZNCBouncerConnection] == NO) {
		return input;
	}

	/* Who is sending this message? */
	IRCPrefix *senderInfo = [input sender];
	
	if (NSObjectsAreEqual([senderInfo nickname], @"*buffextras") == NO) {
		return input;
	}

	/* What type of message is this person sending? */
	if (NSObjectsAreEqual([input command], IRCPrivateCommandIndex("privmsg")) == NO) {
		return input;
	}

	/* Check our count. */
	if (([input paramsCount] == 2) == NO) {
		return input;
	}

	/* Begin processing data. */
	NSMutableArray *mutparams = [[input params] mutableCopy];
	
	NSMutableString *s = [mutparams[1] mutableCopy];

	/* Define user information. */
	NSString *hostmask = [s getToken];

	if ([hostmask length] <= 0) {
		return input;
	}
	
	NSString *nicknameInt = nil;
	NSString *usernameInt = nil;
	NSString *addressInt = nil;
	
	[senderInfo setHostmask:hostmask];
	
	[senderInfo setIsServer:NO];

	if ([hostmask hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt]) {
		[senderInfo setNickname:nicknameInt];
		[senderInfo setUsername:usernameInt];
		[senderInfo setAddress:addressInt];

		if (NSObjectsAreEqual([senderInfo nickname], [client localNickname])) {
			return input; // Do not post these events for self.
		}
	} else {
		[senderInfo setNickname:hostmask];
		
		[senderInfo setIsServer:YES];
	}

	/* Let Textual know to treat this message as a special event. */
	[input setIsPrintOnlyMessage:YES];

	/* Start actual work. */
	if ([s hasPrefix:@"is now known as "]) {
		/* Begin nickname change. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"is now known as " length])];

		NSString *newNickname = [s getToken];

		NSObjectIsEmptyAssertReturn(newNickname, input);

		[input setCommand:IRCPrivateCommandIndex("nick")];

		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:newNickname];
		/* End nickname change. */
	}
	else if ([s isEqualToString:@"joined"])
	{
		/* Begin channel join. */
		[input setCommand:IRCPrivateCommandIndex("join")];

		[mutparams removeObjectAtIndex:1];
		/* End channel join. */
	}
	else if ([s hasPrefix:@"set mode: "])
	{
		/* Begin mode processing. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"set mode: " length])];

		[input setCommand:IRCPrivateCommandIndex("mode")];

		NSString *modesSet = [s getToken];

		NSObjectIsEmptyAssertReturn(modesSet, input);

		[mutparams removeObjectAtIndex:1];

		[mutparams addObject:modesSet];
		[mutparams addObject:s];
		/* End mode processing. */
	}
	else if ([s hasPrefix:@"quit with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin quit message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"quit with message: [" length])];	// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];					// Remove trailing character.

		[input setCommand:IRCPrivateCommandIndex("quit")];

		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:s];
		/* End quit message. */
	}
	else if ([s hasPrefix:@"parted with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin part message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"parted with message: [" length])];		// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];						// Remove trailing character.

		[input setCommand:IRCPrivateCommandIndex("part")];

		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:s];
		/* End part message. */
	}
	else if ([s hasPrefix:@"kicked "] && [s hasSuffix:@"]"])
	{
		/* Begin kick message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"kicked " length])];	// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];		// Remove trailing character.

		NSString *whoKicked = [s getToken];

		if (NSObjectIsEmpty(whoKicked) || [s hasPrefix:@"Reason: ["] == NO) {
			return input;
		}

		[s deleteCharactersInRange:NSMakeRange(0, [@"Reason: [" length])];

		[input setCommand:IRCPrivateCommandIndex("kick")];

		[mutparams removeObjectAtIndex:1];

		[mutparams addObject:whoKicked];
		[mutparams addObject:s];
		/* End kick message. */
	}
	else if ([s hasPrefix:@"changed the topic to: "])
	{
		/* Begin topic change. */
		/* We get the latest topic on join so we tell Textual to ignore this line. */

		return nil;
		/* End topic change. */
	}
	
	[input setParams:mutparams];

	return input;
}

#pragma mark -
#pragma mark Private API

- (void)handleIRCSideDisconnect:(IRCClient *)client
{
	for (IRCChannel *c in [client channelList]) {
		NSAssertReturnLoopContinue( [c isActive]);
        NSAssertReturnLoopContinue([[c name] hasPrefix:@"~#"] == NO);
		
        [c deactivate];
	}

	[mainWindow() reloadTreeGroup:client];
}

@end
