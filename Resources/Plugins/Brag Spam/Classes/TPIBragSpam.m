/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

- (void)appendPluralOrSingular:(NSString **)resultString valueToken:(NSInteger)valueToken value:(NSInteger)valueActual
{
	NSString *valueKey = nil;

	if (NSDissimilarObjects(valueActual, 1)) {
		valueKey = [NSString stringWithFormat:@"BasicLanguage[%ld][1]", valueToken];
	} else {
		valueKey = [NSString stringWithFormat:@"BasicLanguage[%ld][0]", valueToken];
	}

	*resultString = [*resultString stringByAppendingString:TPILocalizedString(valueKey, valueActual)];
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
TEXTUAL_IGNORE_DEPRECATION_BEGIN

	if ([commandString isEqualToString:@"BRAG"]) {
		IRCChannel *selectedChannel = [mainWindow() selectedChannel];

		NSAssertReturn([selectedChannel isChannel]);
		
		NSInteger operCount      = 0;
		NSInteger chanOpCount    = 0;
		NSInteger chanHopCount   = 0;
		NSInteger chanVopCount   = 0;
		NSInteger channelCount   = 0;
		NSInteger networkCount   = 0;
		NSInteger powerOverCount = 0;
		
		for (IRCClient *c in [worldController() clientList]) {
			if ([c isConnected] == NO) {
				continue;
			}
			
			networkCount++;
			
			if ([c hasIRCopAccess] == YES) {
				operCount++;
			}
			
			NSMutableArray *trackedUsers = [NSMutableArray new];
			
			for (IRCChannel *ch in [c channelList]) {
				if ([ch isActive] == NO || [ch isChannel] == NO) {
					continue;
				}

				channelCount += 1;
				
				IRCUser *myself = [ch findMember:[c localNickname]];
				
				if ([c hasIRCopAccess] == NO) {
					if ([myself isCop]) {
						[c setHasIRCopAccess:YES];
						
						operCount++;
					}
				}
				
				if ([myself q] || [myself a] || [myself o]) {
					chanOpCount++;
				} else if ([myself h]) {
					chanHopCount++;
				} else if ([myself v]) {
					chanVopCount++;
				}
				
				for (IRCUser *m in [ch memberList]) {
					if ([m isEqual:myself]) {
						continue;
					}
				
					BOOL addUser = NO;

					if ([c hasIRCopAccess] && [m isCop] == NO) {
						addUser = YES;
					} else if ([myself q] && [m q] == NO) {
						addUser = YES;
					} else if ([myself a] && [m q] == NO && [m a] == NO) {
						addUser = YES;
					} else if ([myself o] && [m q] == NO && [m a] == NO && [m o] == NO) {
						addUser = YES;
					} else if ([myself h] && [m q] == NO && [m a] == NO && [m o] == NO && [m h] == NO) {
						addUser = YES;	
					}
					
					if (addUser == YES) {
						if ([trackedUsers containsObject:[m nickname]] == NO) {
							powerOverCount++;
							
							[trackedUsers addObject:[m nickname]];
						}
					}
				}
			}
			
		}

		NSString *resultString = NSStringEmptyPlaceholder;

		[self appendPluralOrSingular:&resultString valueToken:1000 value:channelCount];
		[self appendPluralOrSingular:&resultString valueToken:1001 value:networkCount];

		if (powerOverCount == 0) {
			resultString = [resultString stringByAppendingString:TPILocalizedString(@"BasicLanguage[1007]")];
		} else {
			[self appendPluralOrSingular:&resultString valueToken:1002 value:operCount];
			[self appendPluralOrSingular:&resultString valueToken:1003 value:chanOpCount];
			[self appendPluralOrSingular:&resultString valueToken:1004 value:chanHopCount];
			[self appendPluralOrSingular:&resultString valueToken:1005 value:chanVopCount];
			[self appendPluralOrSingular:&resultString valueToken:1006 value:powerOverCount];
		}

		[client sendText:[NSAttributedString emptyStringWithBase:resultString]
				 command:IRCPrivateCommandIndex("privmsg")
				 channel:selectedChannel];
	}

TEXTUAL_IGNORE_DEPRECATION_END
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"brag"];
}	

@end
