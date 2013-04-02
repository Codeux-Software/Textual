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

#import "TPIBragSpam.h"

@implementation TPIBragSpam

- (void)appendPluralOrSingular:(NSMutableString **)resultString valueToken:(NSString *)valueToken value:(NSInteger)valueActual
{
	if (NSDissimilarObjects(valueActual, 1)) {
		valueToken = [valueToken stringByAppendingString:@"[PLURAL]"];
	}

	[*resultString appendString:TPIFLS(valueToken, valueActual)];
}

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	if ([commandString isEqualToString:@"BRAG"]) {
		NSAssertReturn(client.worldController.selectedChannel.isChannel);
		
		NSInteger operCount      = 0;
		NSInteger chanOpCount    = 0;
		NSInteger chanHopCount   = 0;
		NSInteger chanVopCount   = 0;
		NSInteger channelCount   = 0;
		NSInteger networkCount   = 0;
		NSInteger powerOverCount = 0;
		
		for (IRCClient *c in client.worldController.clients) {
			if (c.isConnected == NO) {
				continue;
			}
			
			networkCount++;
			
			if (c.hasIRCopAccess == YES) {
				operCount++;
			}
			
			NSMutableArray *trackedUsers = [NSMutableArray new];
			
			for (IRCChannel *ch in c.channels) {
				if ([ch isActive] == NO || [ch isChannel] == NO) {
					continue;
				}

				channelCount += 1;
				
				IRCUser *myself = [ch findMember:c.localNickname];
				
				if (myself.q || myself.a || myself.o) {
					chanOpCount++;
				} else if (myself.h) {
					chanHopCount++;
				} else if (myself.v) {
					chanVopCount++;
				}
				
				for (IRCUser *m in ch.memberList) {
					if ([m isEqual:myself]) {
						continue;
					}
				
					BOOL addUser = NO;

					if (client.hasIRCopAccess && m.isCop == NO) {
						addUser = YES;
					} else if (myself.q && m.q == NO) {
						addUser = YES;
					} else if (myself.a && m.q == NO && m.a == NO) {
						addUser = YES;
					} else if (myself.o && m.q == NO && m.a == NO && m.o == NO) {
						addUser = YES;
					} else if (myself.h && m.q == NO && m.a == NO && m.o == NO && m.h == NO) {
						addUser = YES;	
					}
					
					if (addUser == YES) {
						if ([trackedUsers containsObject:m.nickname] == NO) {
							powerOverCount++;
							
							[trackedUsers addObject:m.nickname];
						}
					}
				}
			}
			
		}

		NSMutableString *resultString = [NSMutableString string];

		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultChannel" value:channelCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultNetwork" value:networkCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultIRCopStatus" value:operCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultOpMode" value:chanOpCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultHalfopMode" value:chanHopCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultVoiceMode" value:chanVopCount];
		[self appendPluralOrSingular:&resultString valueToken:@"BragspamPluginNormalResultUserPower" value:powerOverCount];

		[client sendPrivmsgToSelectedChannel:resultString];
	}
}

- (NSArray*)pluginSupportsUserInputCommands
{
	return @[@"brag"];
}	

@end
