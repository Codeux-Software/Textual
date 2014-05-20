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

#import "TPISpammerParadise.h"

@implementation TPISpammerParadise

#pragma mark -
#pragma mark User Input

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	IRCChannel *channel = [[self worldController] selectedChannel];

	if ([channel isChannel]) {
		if ([commandString isEqualToString:@"CLONES"]) {
			[self findAllClonesIn:channel on:client];
		} else if ([commandString isEqualToString:@"NAMEL"]) {
			[self buildListOfUsersOn:channel on:client];
		} else if ([commandString isEqualToString:@"FINDUSER"]) {
			[self findAllUsersMatchingHost:[messageString trim] in:channel on:client];
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"clones", @"namel", @"finduser"];
}

- (void)buildListOfUsersOn:(IRCChannel *)channel on:(IRCClient *)client
{
	if ([channel numberOfMembers] <= 0) {
		[client printDebugInformation:TPIFLS(@"BasicLanguage[1000]", [channel name]) channel:channel];

		return; // We cannot do anything with no users now can we?
	}

	/* Build list of users and print it. */
	NSMutableArray *users = [NSMutableArray array];

	for (IRCUser *u in [channel unsortedMemberList]) {
		[users addObject:[u nickname]];
	}

	[users sortUsingSelector:@selector(compare:)];

	NSString *printedList = [users componentsJoinedByString:NSStringWhitespacePlaceholder];

	[client printDebugInformation:printedList channel:channel];
}

- (void)findAllUsersMatchingHost:(NSString *)matchString in:(IRCChannel *)channel on:(IRCClient *)client
{
	/* Validate input. */
	BOOL hasSearchCondition = NSObjectIsNotEmpty(matchString);

	/* Check number of users. */
	if ([channel numberOfMembers] <= 0) {
		if (hasSearchCondition) {
			[client printDebugInformation:TPIFLS(@"BasicLanguage[1007]", [channel name], matchString) channel:channel];
		} else {
			[client printDebugInformation:TPIFLS(@"BasicLanguage[1006]", [channel name]) channel:channel];
		}

		return; // We cannot do anything with no users now can we?
	}

	/* Build list of users. */
	NSMutableArray *userlist = [NSMutableArray array];

	for (IRCUser *user in [channel unsortedMemberList]) {
		NSString *userAddress = [user hostmask];

        NSObjectIsEmptyAssertLoopContinue(userAddress);

		if (hasSearchCondition) {
			if ([userAddress containsIgnoringCase:matchString]) {
				[userlist addObject:user];
			}
		} else {
			[userlist addObject:user];
		}
	}

	/* Do we even have any matches? */
	if ([userlist count] <= 0) {
		if (hasSearchCondition) {
			[client printDebugInformation:TPIFLS(@"BasicLanguage[1007]", [channel name], matchString) channel:channel];
		} else {
			[client printDebugInformation:TPIFLS(@"BasicLanguage[1006]", [channel name]) channel:channel];
		}

		return;
	}

	/* We have results, so let's skim them. */
	if (hasSearchCondition) {
		[client printDebugInformation:TPIFLS(@"BasicLanguage[1005]", [userlist count], [channel name], matchString) channel:channel];
	} else {
		[client printDebugInformation:TPIFLS(@"BasicLanguage[1004]", [userlist count], [channel name]) channel:channel];
	}

	[userlist sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 nickname] compare:[obj2 nickname]];
	}];

	for (IRCUser *user in userlist) {
        NSString *resultString = [NSString stringWithFormat:@"%@ -> %@", [user nickname], [user hostmask]];

        [client printDebugInformation:resultString channel:channel];
	}
}

- (void)findAllClonesIn:(IRCChannel *)channel on:(IRCClient *)client
{
    NSMutableDictionary *allUsers = [NSMutableDictionary dictionary];

    /* Populate our list by matching an array of users to that of the address. */
    for (IRCUser *user in [channel unsortedMemberList]) {
        NSObjectIsEmptyAssertLoopContinue([user address]);

        NSArray *clones = [allUsers arrayForKey:[user address]];

        if (NSObjectIsEmpty(clones)) {
            [allUsers setObject:@[[user nickname]] forKey:[user address]];
        } else {
            clones = [clones arrayByAddingObject:[user nickname]];

            [allUsers setObject:clones forKey:[user address]];
        }
    }

    /* Filter the new list by removing users with less than two matches. */
    NSArray *listKeys = [allUsers allKeys];

    for (NSString *dictKey in listKeys) {
        NSArray *userArray = [allUsers arrayForKey:dictKey];

        if ([userArray count] <= 1) {
            [allUsers removeObjectForKey:dictKey];
        }
    }

    /* Now that we have our list made, sort it & present it. */

    /* No cloes found. */
    if (NSObjectIsEmpty(allUsers)) {
        [client printDebugInformation:TPILS(@"BasicLanguage[1001]") channel:channel];

        return;
    }

    /* Build clone list. */
    [client printDebugInformation:TPIFLS(@"BasicLanguage[1002]", [allUsers count], [channel name]) channel:channel];
    
    for (NSString *dictKey in allUsers) {
        NSArray *userArray = [allUsers arrayForKey:dictKey];

        NSString *resultString = [NSString stringWithFormat:@"*!*@%@ -> %@", dictKey, [userArray componentsJoinedByString:@", "]];

        [client printDebugInformation:resultString channel:channel];
    }
}

@end
