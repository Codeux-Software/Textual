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

#import "TPISystemProfiler.h"
#import "TPI_SP_SysInfo.h"

@interface TPISystemProfiler ()
@property (nonatomic, strong) NSView *preferencePaneView;
@end

@implementation TPISystemProfiler

#pragma mark -
#pragma mark Memory Allocation & Deallocation

/* Allocation & Deallocation */
- (void)pluginLoadedIntoMemory
{
	NSDictionary *defaults = @{
	   @"System Profiler Extension -> Feature Disabled -> GPU Model" : @(YES),
	   @"System Profiler Extension -> Feature Disabled -> Disk Information" : @(YES),
	   @"System Profiler Extension -> Feature Disabled -> Screen Resolution" : @(YES)
	};
	
	[RZUserDefaults() registerDefaults:defaults];
	
	[TPIBundleFromClass() loadCustomNibNamed:@"TPISystemProfiler" owner:self topLevelObjects:nil];
}

#pragma mark -
#pragma mark Preference Pane

/* Preference Pane */
- (NSView *)pluginPreferencesPaneView
{
	return self.preferencePaneView;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizedString(@"BasicLanguage[1000]");
}

#pragma mark -
#pragma mark User Input

- (NSArray *)subscribedUserInputCommands
{
	return @[@"sysinfo", @"memory", @"uptime", @"netstats", 
	@"msgcount", @"diskspace", @"style", @"screens",
	@"runcount", @"loadavg", @"sysmem", @"sfont"];
}

- (void)sendMessage:(NSString *)message onClient:(IRCClient *)client toChannel:(IRCChannel *)channel
{
	[client sendText:[NSAttributedString emptyStringWithBase:message]
			 command:IRCPrivateCommandIndex("privmsg")
			 channel:channel];
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	IRCChannel *channel = [worldController() selectedChannel];
	
	if (channel) {
		if ([commandString isEqualToString:@"SYSINFO"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"MEMORY"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationMemoryUsage] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"UPTIME"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationAndSystemUptime] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"NETSTATS"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemNetworkInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"MSGCOUNT"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationBandwidthStatistics] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"DISKSPACE"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemDiskspaceInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"STYLE"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationActiveStyle] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"SCREENS"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemDisplayInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"RUNCOUNT"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationRuntimeStatistics] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"LOADAVG"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemCPULoadInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"SYSMEM"]) {
			[self sendMessage:[TPI_SP_CompiledOutput systemMemoryInformation] onClient:client toChannel:channel];
		} else if ([commandString isEqualToString:@"SFONT"]) {
			[self sendMessage:[TPI_SP_CompiledOutput applicationConfiguredFontInformation] onClient:client toChannel:channel];
		}
	}
}

@end
