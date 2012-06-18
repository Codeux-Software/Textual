// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPISystemProfiler.h"
#import "TPI_SP_SysInfo.h"

@implementation TPISystemProfiler

- (NSArray *)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"sysinfo", @"memory", @"uptime", @"netstats", 
			@"msgcount", @"diskspace", @"theme", @"screens", @"runcount", @"loadavg",
			@"sysmem", nil];
}

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	if ([client isConnected]) {
		NSString *channelName = client.world.selectedChannel.name;
		
		if ([channelName length] >= 1) {
			if ([commandString isEqualToString:@"SYSINFO"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo compiledOutput]];
			} else if ([commandString isEqualToString:@"MEMORY"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationMemoryUsage]];
				
				if ([_NSUserDefaults() boolForKey:@"HideMemoryCommandExtraInfo"] == NO) {
					[client.iomt printDebugInformation:TXTLS(@"SystemInformationApplicationMemoryUseInfoLink")];
				}
			} else if ([commandString isEqualToString:@"UPTIME"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationAndSystemUptime]];
			} else if ([commandString isEqualToString:@"NETSTATS"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo networkStats]];
			} else if ([commandString isEqualToString:@"MSGCOUNT"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo bandwidthStatsFrom:client.world]];
			} else if ([commandString isEqualToString:@"DISKSPACE"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo allVolumesAndSizes]];
			} else if ([commandString isEqualToString:@"THEME"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo logThemeInformationFrom:client.world]];
			} else if ([commandString isEqualToString:@"SCREENS"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo activeScreenResolutions]];
			} else if ([commandString isEqualToString:@"RUNCOUNT"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationRunCount]];
			} else if ([commandString isEqualToString:@"LOADAVG"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo systemLoadAverage]];
			} else if ([commandString isEqualToString:@"SYSMEM"]) {
				[client.iomt sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo systemMemoryUsage]];
			}
		}
	}
}

@end