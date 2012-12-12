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

#import "TPIAnnoyChannel.h"

/* A lot of admins will hate me for writing this extension. 
 I say… BRING IT ON! 
 
 It is 10:49 A.M., I am bored, been up since 6:00, home alone,
 waiting for loved one to return… so I wrote this. Hate me. */

@interface TPIAnnoyChannel ()
@property (nonatomic, strong) NSMutableArray *clonedUsers;
@end

@implementation TPIAnnoyChannel

#pragma mark -
#pragma mark User Input

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	if (PointerIsEmpty(self.clonedUsers)) {
		self.clonedUsers = [NSMutableArray array];
	}

	// ---- //
	
	IRCChannel *channel = client.world.selectedChannel;

	if (channel.isChannel == NO) {
		return;
	}

	// ---- //
	
	NSString *jerk = messageString;

	/* Get everything up to first space… */
	NSInteger spacePos = [messageString stringPosition:NSStringWhitespacePlaceholder];

	if (spacePos >= 2) {
		jerk = [jerk safeSubstringToIndex:spacePos];
	}
	
	/* Let the fun begin… */
	if ([commandString isEqualToString:@"CLONE"]) {
		[self addCloneOn:client in:channel nickname:jerk];
	} else if ([commandString isEqualToString:@"UNCLONE"]) {
		[self removeCloneOn:client in:channel nickname:jerk];
	} else if ([commandString isEqualToString:@"CLONED"]) {
		[self listAllClones:client];
	} else if ([commandString isEqualToString:@"HSPAM"] && channel.isTalk == NO) {
		[self highlightEveryoneIn:channel on:client];
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

	NSString *chaname = params[0];
	NSString *person = senderDict[@"senderNickname"];
	NSString *message = messageDict[@"messageSequence"];

	// ---- //

	BOOL isAction = NO;

	if ([message hasPrefix:@"ACTION "] && [message hasSuffix:@""]) {
		isAction = YES;
		
		message = [message safeSubstringAfterIndex:7];
		message = [message safeSubstringToIndex:(message.length - 1)];
	}

	// ---- //

	IRCChannel *channel = [client findChannel:chaname];

	if (channel) {
		IRCUser *member = [channel findMember:person options:NSCaseInsensitiveSearch];

		// ---- //
		
		if (PointerIsNotEmpty(member)) {
			NSString *searchKey = [NSString stringWithFormat:@"clone: client = %@; channel = %@; user = %@;",
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

/* This right here is what will piss people off… */
- (void)highlightEveryoneIn:(IRCChannel *)channel on:(IRCClient *)client
{
	if (NSObjectIsEmpty(channel.members)) {
		return [client printDebugInformation:TXTFLS(@"AnnoyChannelMassHighlightEmptyChannelMessage", channel.name) channel:channel];
	}
	
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

- (void)addCloneOn:(IRCClient *)client in:(IRCChannel *)channel nickname:(NSString *)person
{
	NSString *cloneResult;

	if (NSObjectIsEmpty(person)) {
		cloneResult = TXTLS(@"AnnoyChannelInvalidInputErrorMessage");
	} else {
		IRCUser *member = [channel findMember:person options:NSCaseInsensitiveSearch];

		if (PointerIsEmpty(member)) {
			cloneResult = TXTFLS(@"AnnoyChannelCloningUserDoesNotExistMessage", person, channel.name);
		} else {
			NSString *searchKey = [NSString stringWithFormat:@"clone: client = %@; channel = %@; user = %@;",
								   client.config.guid, channel.name, member.nick.lowercaseString];

			if ([self.clonedUsers containsObject:searchKey]) {
				cloneResult = TXTFLS(@"AnnoyChannelCloningUserAlreadyClonedMessage", member.nick, channel.name);
			} else {
				[self.clonedUsers addObject:searchKey];

				cloneResult = TXTFLS(@"AnnoyChannelCloningUserNowBeingClonedMessage", member.nick, channel.name);
			}
		}
	}

	[client printDebugInformation:cloneResult channel:channel];
}

- (void)removeCloneOn:(IRCClient *)client in:(IRCChannel *)channel nickname:(NSString *)person
{
	NSString *cloneResult;

	if (NSObjectIsEmpty(person)) {
		cloneResult = TXTLS(@"AnnoyChannelInvalidInputErrorMessage");
	} else {
		if ([person isEqualToString:@"-a"]) {
			cloneResult = TXTLS(@"AnnoyChannelCloningUnclonedAllUsersMessage");

			[self.clonedUsers removeAllObjects];
		} else {
			IRCUser *member = [channel findMember:person options:NSCaseInsensitiveSearch];

			if (PointerIsEmpty(member)) {
				cloneResult = TXTFLS(@"AnnoyChannelCloningUserDoesNotExistMessage", person, channel.name);
			} else {
				NSString *searchKey = [NSString stringWithFormat:@"clone: client = %@; channel = %@; user = %@;",
									   client.config.guid, channel.name, member.nick.lowercaseString];

				if ([self.clonedUsers containsObject:searchKey]) {
					cloneResult = TXTFLS(@"AnnoyChannelCloningUnclonedOneUserMessage", member.nick, channel.name);

					[self.clonedUsers removeObject:searchKey];
				} else {
					cloneResult = TXTFLS(@"AnnoyChannelCloningUserIsNotClonedMessage", member.nick, channel.name);
				}
			}
		}
	}

	[client printDebugInformation:cloneResult channel:channel];
}

- (void)listAllClones:(IRCClient *)client
{
	if (NSObjectIsEmpty(self.clonedUsers)) {
		[client printDebugInformation:TXTLS(@"AnnoyChannelCloningNoUsersBeingClonedMessage")];
	} else {
		for (NSString *key in self.clonedUsers) {
			[client printDebugInformation:key];
		}
	}
}

@end
