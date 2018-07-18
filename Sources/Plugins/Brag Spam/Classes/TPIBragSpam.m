/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TPIBragSpam.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TPIBragSpam

- (void)appendPluralOrSingular:(NSMutableString *)resultString valueToken:(NSString *)valueToken value:(NSInteger)value
{
	NSString *valueKey = nil;

	if (value == 1) {
		valueKey = [NSString stringWithFormat:@"BasicLanguage[%@-1]", valueToken];
	} else {
		valueKey = [NSString stringWithFormat:@"BasicLanguage[%@-2]", valueToken];
	}

	[resultString appendString:TPILocalizedString(valueKey, value)];
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	if ([commandString isEqualToString:@"BRAG"]) {
		IRCChannel *selectedChannel = mainWindow().selectedChannel;

		if (selectedChannel == nil) {
			return;
		}

		NSUInteger operCount = 0;
		NSUInteger channelOpCount = 0;
		NSUInteger channelHalfopCount = 0;
		NSUInteger channelVoiceCount = 0;
		NSUInteger channelCount = 0;
		NSUInteger networkCount = 0;
		NSUInteger powerOverCount = 0;

		for (IRCClient *client in worldController().clientList) {
			if (client.isConnected == NO) {
				continue;
			}

			networkCount++;

			IRCUser *localUser = client.myself;

			if (client.userIsIRCop || localUser.isIRCop) {
				operCount++;
			}

			NSMutableArray<NSString *> *trackedUsers = [NSMutableArray new];

			for (IRCChannel *channel in client.channelList) {
				if (channel.isActive == NO || channel.isChannel == NO) {
					continue;
				}

				channelCount += 1;

				IRCChannelUser *myself = [channel findMember:client.userNickname];

				IRCUserRank myRanks = myself.ranks;

				BOOL IHaveModeQ = ((myRanks & IRCUserRankChannelOwner) == IRCUserRankChannelOwner);
				BOOL IHaveModeA = ((myRanks & IRCUserRankSuperOperator) == IRCUserRankSuperOperator);
				BOOL IHaveModeO = ((myRanks & IRCUserRankNonermalOperator) == IRCUserRankNonermalOperator);
				BOOL IHaveModeH = ((myRanks & IRCUserRankHalfOperator) == IRCUserRankHalfOperator);
				BOOL IHaveModeV = ((myRanks & IRCUserRankVoiced) == IRCUserRankVoiced);

				if (IHaveModeQ || IHaveModeA || IHaveModeO) {
					channelOpCount++;
				} else if (IHaveModeH) {
					channelHalfopCount++;
				} else if (IHaveModeV) {
					channelVoiceCount++;
				}

				for (IRCChannelUser *member in channel.memberList) {
					if ([member isEqual:myself]) {
						continue;
					}

					BOOL addUser = NO;

					IRCUserRank userRanks = member.ranks;

					BOOL UserHasModeQ = ((userRanks & IRCUserRankChannelOwner) == IRCUserRankChannelOwner);
					BOOL UserHasModeA = ((userRanks & IRCUserRankSuperOperator) == IRCUserRankSuperOperator);
					BOOL UserHasModeO = ((userRanks & IRCUserRankNonermalOperator) == IRCUserRankNonermalOperator);
					BOOL UserHasModeH = ((userRanks & IRCUserRankHalfOperator) == IRCUserRankHalfOperator);

					if (client.userIsIRCop && member.user.isIRCop == NO) {
						addUser = YES;
					} else if (IHaveModeQ && UserHasModeQ == NO) {
						addUser = YES;
					} else if (IHaveModeA && UserHasModeQ == NO && UserHasModeA == NO) {
						addUser = YES;
					} else if (IHaveModeO && UserHasModeQ == NO && UserHasModeA == NO && UserHasModeO == NO) {
						addUser = YES;
					} else if (IHaveModeH && UserHasModeQ == NO && UserHasModeA == NO && UserHasModeO == NO && UserHasModeH == NO) {
						addUser = YES;
					}

					if (addUser) {
						if ([trackedUsers containsObject:member.user.nickname] == NO) {
							[trackedUsers addObject:member.user.nickname];

							powerOverCount++;
						}
					}
				}
			}
		}

		NSMutableString *resultString = [NSMutableString string];

		[self appendPluralOrSingular:resultString valueToken:@"30l-sx" value:channelCount];
		[self appendPluralOrSingular:resultString valueToken:@"rks-0t" value:networkCount];

		if (powerOverCount == 0) {
			[resultString appendString:TPILocalizedString(@"BasicLanguage[jpi-po]")];
		} else {
			[self appendPluralOrSingular:resultString valueToken:@"614-ac" value:operCount];
			[self appendPluralOrSingular:resultString valueToken:@"qne-b5" value:channelOpCount];
			[self appendPluralOrSingular:resultString valueToken:@"431-yv" value:channelHalfopCount];
			[self appendPluralOrSingular:resultString valueToken:@"x1m-jp" value:channelVoiceCount];
			[self appendPluralOrSingular:resultString valueToken:@"ny4-wd" value:powerOverCount];
		}

		[client sendPrivmsg:[resultString copy] toChannel:selectedChannel];
	}
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"brag"];
}

@end

NS_ASSUME_NONNULL_END
