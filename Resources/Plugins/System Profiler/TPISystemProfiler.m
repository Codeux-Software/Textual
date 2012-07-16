/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#import "TPISystemProfiler.h"
#import "TPI_SP_SysInfo.h"

@interface TPISystemProfiler ()
@property (nonatomic, strong) IBOutlet NSView *preferencePaneView;
@end

@implementation TPISystemProfiler

#pragma mark -
#pragma mark Memory Allocation & Deallocation

/* Allocation & Deallocation */
- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
	[NSBundle loadNibNamed:@"TPISystemProfiler" owner:self];
	
	NSDictionary *settingDefaults = @{
	@"System Profiler Extension -> Feature Enabled -> CPU Model" : @YES,
	@"System Profiler Extension -> Feature Enabled -> Memory Information" : @YES,
	@"System Profiler Extension -> Feature Enabled -> System Uptime" : @YES,
	@"System Profiler Extension -> Feature Enabled -> Disk Information" : @YES,
	@"System Profiler Extension -> Feature Enabled -> GPU Model" : @YES,
	@"System Profiler Extension -> Feature Enabled -> Screen Resolution" : @YES,
	@"System Profiler Extension -> Feature Enabled -> Load Average" : @YES,
	@"System Profiler Extension -> Feature Enabled -> OS Version" : @YES
	};

	[_NSUserDefaults() registerDefaults:settingDefaults];
}

#pragma mark -
#pragma mark Preference Pane

/* Preference Pane */
- (NSView *)preferencesView
{
	return self.preferencePaneView;
}

- (NSString *)preferencesMenuItemName
{
	return TXTLS(@"SystemInformationPreferencePaneMenuItemTitle");
}

#pragma mark -
#pragma mark User Input

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"sysinfo", @"memory", @"uptime", @"netstats", 
	@"msgcount", @"diskspace", @"theme", @"screens",
	@"runcount", @"loadavg", @"sysmem"];
}

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
#ifndef DEBUG
	if ([client isConnected]) {
#endif
		
		NSString *channelName = client.world.selectedChannel.name;
		
		if ([channelName length] >= 1) {
			if ([commandString isEqualToString:@"SYSINFO"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo compiledOutput]];
			} else if ([commandString isEqualToString:@"MEMORY"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationMemoryUsage]];
			} else if ([commandString isEqualToString:@"UPTIME"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationAndSystemUptime]];
			} else if ([commandString isEqualToString:@"NETSTATS"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo networkStats]];
			} else if ([commandString isEqualToString:@"MSGCOUNT"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo bandwidthStatsFrom:client.world]];
			} else if ([commandString isEqualToString:@"DISKSPACE"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo allVolumesAndSizes]];
			} else if ([commandString isEqualToString:@"THEME"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo logThemeInformationFrom:client.world]];
			} else if ([commandString isEqualToString:@"SCREENS"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo activeScreenResolutions]];
			} else if ([commandString isEqualToString:@"RUNCOUNT"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationRunCount]];
			} else if ([commandString isEqualToString:@"LOADAVG"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo systemLoadAverage]];
			} else if ([commandString isEqualToString:@"SYSMEM"]) {
				[client sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo systemMemoryUsage]];
			}
		}
		
#ifndef DEBUG
	}
#endif
}

@end