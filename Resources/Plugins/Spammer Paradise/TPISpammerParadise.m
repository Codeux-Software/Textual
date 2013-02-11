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

#import "TPISpammerParadise.h"

@interface TPISpammerParadise ()
@property (nonatomic, strong) NSMutableArray *clonedUsers;
@end

#define _ActionMessagePrefix		[NSString stringWithFormat:@"%CACTION ", 0x01]
#define _ActionMessageSuffix		[NSString stringWithFormat:@"%C", 0x01]

#define _ClonedUserRegistrationKey		@"clone: client = %@; channel = %@; user = %@;"

@implementation TPISpammerParadise

#pragma mark -
#pragma mark User Input

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	if (PointerIsEmpty(self.clonedUsers)) {
		self.clonedUsers = [NSMutableArray array];
	}
	
	IRCChannel *channel = client.world.selectedChannel;

	if (channel.isChannel) {
		NSInteger spacePos = [messageString stringPosition:NSStringWhitespacePlaceholder];

		if (spacePos >= 2) {
			messageString = [messageString safeSubstringToIndex:spacePos];
		}
		
		if ([commandString isEqualToString:@"CLONE"]) {
			[self addCloneOn:client in:channel nickname:messageString];
		} else if ([commandString isEqualToString:@"UNCLONE"]) {
			[self removeCloneOn:client in:channel nickname:messageString];
		} else if ([commandString isEqualToString:@"CLONED"]) {
			[self listAllClones:client];
		} else if ([commandString isEqualToString:@"HSPAM"] && channel.isTalk == NO) {
			[self highlightEveryoneIn:channel on:client];
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"clone", @"unclone", @"cloned", @"hspam"];
}

#pragma mark -
#pragma mark Server Input

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict
{
	if (NSObjectIsEmpty(self.clonedUsers)) {
		return;
	}

	// ---- //

	NSArray *params = messageDict[@"messageParamaters"];

	NSString *nickname = senderDict[@"senderNickname"];
	NSString *message = messageDict[@"messageSequence"];

	// ---- //

	BOOL isAction = NO;

	if ([message hasPrefix:_ActionMessagePrefix] &&
		[message hasSuffix:_ActionMessageSuffix]) {
		
		isAction = YES;
		
		message = [message safeSubstringFromIndex:[_ActionMessagePrefix length]];
		message = [message safeSubstringToIndex:(message.length - 1)];
	}

	// ---- //

	IRCChannel *channel = [client findChannel:params[0]];

	if (channel) {
		IRCUser *member = [channel findMember:nickname options:NSCaseInsensitiveSearch];

		// ---- //
		
		if (PointerIsNotEmpty(member)) {
			NSString *searchKey = [NSString stringWithFormat:_ClonedUserRegistrationKey,
								   client.config.guid, channel.name, member.nick.lowercaseString];

			// ---- //
			
			if ([self.clonedUsers containsObject:searchKey]) {
				NSString *command = IRCPrivateCommandIndex("privmsg");

				if (isAction) {
					command = IRCPrivateCommandIndex("action");
				}

				[client sendText:[NSAttributedString emptyStringWithBase:message] command:command channel:channel];
			}
		}
	}
}

- (NSArray *)pluginSupportsServerInputCommands
{
	return @[@"privmsg"];
}

#pragma mark -
#pragma mark Mass Highlight

- (void)highlightEveryoneIn:(IRCChannel *)channel on:(IRCClient *)client
{
	if (NSObjectIsEmpty(channel.members)) {
		return [client printDebugInformation:TPIFLS(@"SpammerParadiseMassHighlightEmptyChannelMessage", channel.name) channel:channel];
	}

	// ---- //
	
	NSString *userList = NSStringEmptyPlaceholder;

	for (IRCUser *user in channel.members) {
		userList = [userList stringByAppendingFormat:@"%@ ", user.nick];
	}

	[client sendText:[NSAttributedString emptyStringWithBase:userList]
			 command:IRCPrivateCommandIndex("privmsg")
			 channel:channel];
}

#pragma mark -
#pragma mark Handle Clones

- (void)addCloneOn:(IRCClient *)client in:(IRCChannel *)channel nickname:(NSString *)nickname
{
	NSString *cloneResult;

	if (NSObjectIsEmpty(nickname)) {
		cloneResult = TPILS(@"SpammerParadiseInvalidInputErrorMessage");
	} else {
		IRCUser *member = [channel findMember:nickname options:NSCaseInsensitiveSearch];

		if (PointerIsEmpty(member)) {
			cloneResult = TPIFLS(@"SpammerParadiseCloningUserDoesNotExistMessage", nickname, channel.name);
		} else {
			if ([member.nick isEqualNoCase:client.myNick]) {
				cloneResult = TPILS(@"SpammerParadiseCloningUserCannotCloneSelfMessage");
			} else {
				NSString *searchKey = [NSString stringWithFormat:_ClonedUserRegistrationKey,
									   client.config.guid, channel.name, member.nick.lowercaseString];

				// ---- //

				if ([self.clonedUsers containsObject:searchKey]) {
					cloneResult = TPIFLS(@"SpammerParadiseCloningUserIsAlreadyClonedMessage", member.nick, channel.name);
				} else {
					[self.clonedUsers addObject:searchKey];

					cloneResult = TPIFLS(@"SpammerParadiseCloningUserIsNowBeingClonedMessage", member.nick, channel.name);
				}
			}
		}
	}

	[client printDebugInformation:cloneResult channel:channel];
}

- (void)removeCloneOn:(IRCClient *)client in:(IRCChannel *)channel nickname:(NSString *)nickname
{
	NSString *cloneResult;

	if (NSObjectIsEmpty(nickname)) {
		cloneResult = TPILS(@"SpammerParadiseInvalidInputErrorMessage");
	} else {
		if ([nickname isEqualToString:@"-a"]) {
			cloneResult = TPILS(@"SpammerParadiseCloningUnclonedAllUsersMessage");

			[self.clonedUsers removeAllObjects];
		} else {
			IRCUser *member = [channel findMember:nickname options:NSCaseInsensitiveSearch];

			if (PointerIsEmpty(member)) {
				cloneResult = TPIFLS(@"SpammerParadiseCloningUserDoesNotExistMessage", nickname, channel.name);
			} else {
				NSString *searchKey = [NSString stringWithFormat:_ClonedUserRegistrationKey,
									   client.config.guid, channel.name, member.nick.lowercaseString];

				// ---- //
				
				if ([self.clonedUsers containsObject:searchKey]) {
					cloneResult = TPIFLS(@"SpammerParadiseCloningUnclonedSingleUserMessage", member.nick, channel.name);

					[self.clonedUsers removeObject:searchKey];
				} else {
					cloneResult = TPIFLS(@"SpammerParadiseCloningUserIsNotClonedMessage", member.nick, channel.name);
				}
			}
		}
	}

	[client printDebugInformation:cloneResult channel:channel];
}

- (void)listAllClones:(IRCClient *)client
{
	if (NSObjectIsEmpty(self.clonedUsers)) {
		[client printDebugInformation:TPILS(@"SpammerParadiseCloningNoUsersBeingClonedMessage")];
	} else {
		for (NSString *key in self.clonedUsers) {
			[client printDebugInformation:key];
		}
	}
}

@end
