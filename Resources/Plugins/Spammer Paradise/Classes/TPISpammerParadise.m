/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2013 - 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TPISpammerParadise.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TPISpammerParadise

#pragma mark -
#pragma mark User Input

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	IRCChannel *channel = mainWindow().selectedChannel;

	if (channel.isChannel == NO) {
		return;
	}

	messageString = messageString.trim;

	if ([commandString isEqualToString:@"CLONES"]) {
		[self findAllClonesInChannel:channel onClient:client];
	} else if ([commandString isEqualToString:@"NAMEL"]) {
		[self buildListOfUsersInChannel:channel onClient:client parameters:messageString];
	} else if ([commandString isEqualToString:@"FINDUSER"]) {
		[self findAllUsersMatchingString:messageString inChannel:channel onClient:client];
	}
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"clones", @"namel", @"finduser"];
}

- (void)buildListOfUsersInChannel:(IRCChannel *)channel onClient:(IRCClient *)client parameters:(NSString *)parameters
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(client != nil);
	NSParameterAssert(parameters != nil);

	NSArray *memberList = channel.memberList;

	if (memberList.count == 0) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]", channel.name) inChannel:channel];

		return;
	}

	/* Process parameters */
	BOOL displayRank = NO;
	BOOL sortByRank = NO;

	if ([parameters hasPrefix:@"-"]) {
		NSString *flagsString = [parameters substringFromIndex:1];

		NSArray *flags = flagsString.characterStringBuffer;

		displayRank = [flags containsObject:@"d"];
		sortByRank = [flags containsObject:@"r"];
	}

	/* -memberList returns a list sorted by rank by default.
	 If we are not sorting by rank, then we have to first get
	 the member list then sort it another way. */
	if (sortByRank == NO) {
		/* Sort user objects alphabetically by comparing nicknames */

		memberList =
		[memberList sortedArrayUsingComparator:^NSComparisonResult(IRCChannelUser *member1, IRCChannelUser *member2) {
			NSString *nickname1 = member1.user.nickname;
			NSString *nickname2 = member2.user.nickname;

			return [nickname1 caseInsensitiveCompare:nickname2];
		}];
	}

	/* Join user objects into string */
	NSMutableString *resultString = [NSMutableString string];

	for (IRCChannelUser *member in memberList) {
		if (displayRank) {
			[resultString appendString:member.mark];
		}

		[resultString appendString:member.user.nickname];

		[resultString appendString:@" "];
	}

	[client printDebugInformation:[resultString copy] inChannel:channel];
}

- (void)findAllUsersMatchingString:(NSString *)matchString inChannel:(IRCChannel *)channel onClient:(IRCClient *)client
{
	NSParameterAssert(matchString != nil);
	NSParameterAssert(channel != nil);
	NSParameterAssert(client != nil);

	BOOL hasSearchCondition = NSObjectIsNotEmpty(matchString);

	NSArray *memberList = channel.memberList;

	if (memberList.count == 0) {
		if (hasSearchCondition) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", channel.name, matchString) inChannel:channel];
		} else {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", channel.name) inChannel:channel];
		}

		return;
	}

	NSMutableArray<IRCChannelUser *> *membersMatched = [NSMutableArray array];

	for (IRCChannelUser *member in memberList) {
		NSString *hostmask = member.user.hostmask;

		if (hostmask == nil) {
			continue;
		}

		if (hasSearchCondition) {
			if ([hostmask containsIgnoringCase:matchString] == NO) {
				continue;
			}
		}

		[membersMatched addObject:member];
	}

	if (membersMatched.count <= 0) {
		if (hasSearchCondition) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", channel.name, matchString) inChannel:channel];
		} else {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", channel.name) inChannel:channel];
		}

		return;
	}

	if (hasSearchCondition) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1005]", membersMatched.count, channel.name, matchString) inChannel:channel];
	} else {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]", membersMatched.count, channel.name) inChannel:channel];
	}

	[membersMatched sortUsingComparator:^NSComparisonResult(IRCChannelUser *member1, IRCChannelUser *member2) {
		NSString *nickname1 = member1.user.nickname;
		NSString *nickname2 = member2.user.nickname;

		return [nickname1 caseInsensitiveCompare:nickname2];
	}];

	for (IRCChannelUser *member in membersMatched) {
		NSString *resultString = [NSString stringWithFormat:@"%@ -> %@", member.user.nickname, member.user.hostmask];

		[client printDebugInformation:resultString inChannel:channel];
	}
}

- (void)findAllClonesInChannel:(IRCChannel *)channel onClient:(IRCClient *)client
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(client != nil);

	NSMutableDictionary<NSString *, NSArray *> *members = [NSMutableDictionary dictionary];

	/* Populate our list by matching an array of users to that of the address. */
	for (IRCChannelUser *member in channel.memberList) {
		NSString *address = member.user.address;

		if (address == nil) {
			continue;
		}

		NSString *nickname = member.user.nickname;

		NSArray *clones = members[address];

		if (clones) {
			clones = [clones arrayByAddingObject:nickname];

			members[address] = clones;
		} else {
			members[address] = @[nickname];
		}
	}

	/* Filter the new list by removing users with less than two matches. */
	NSArray *memberHosts = members.allKeys;

	for (NSString *memberHost in memberHosts) {
		NSArray *clones = [members arrayForKey:memberHost];

		if (clones.count < 2) {
			[members removeObjectForKey:memberHost];
		}
	}

	/* No cloes found */
	if (members.count == 0) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]") inChannel:channel];

		return;
	}

	/* Build result string */
	[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1002]", members.count, channel.name) inChannel:channel];

	for (NSString *memberHost in members) {
		NSArray *clones = [members arrayForKey:memberHost];

		NSString *clonesString = [clones componentsJoinedByString:@", "];

		NSString *resultString = [NSString stringWithFormat:@"*!*@%@ -> %@", memberHost, clonesString];

		[client printDebugInformation:resultString inChannel:channel];
	}
}

@end

NS_ASSUME_NONNULL_END
