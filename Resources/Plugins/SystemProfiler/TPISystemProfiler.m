// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPISystemProfiler.h"
#import "TPI_SP_SysInfo.h"

@implementation TPISystemProfiler

- (NSArray*)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"sysinfo", @"memory", @"uptime", @"netstats", 
			@"msgcount", @"diskspace", @"theme", @"screens", @"runcount", @"loadavg", @"sysmem", nil];
}

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString*)messageString
				  command:(NSString*)commandString
{
	if ([client isConnected]) {
		NSString *channelName = [[client.world selectedChannel] name];
		
		if ([channelName length] >= 1) {
			if ([commandString isEqualToString:@"SYSINFO"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo compiledOutput]];
			} else if ([commandString isEqualToString:@"MEMORY"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationMemoryUsage]];
				
				if ([_NSUserDefaults() boolForKey:@"HideMemoryCommandExtraInfo"] == NO) {
					[[client iomt] printDebugInformation:@"Information about memory use: http://is.gd/j0a9s"];
				}
			} else if ([commandString isEqualToString:@"UPTIME"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo applicationAndSystemUptime]];
			} else if ([commandString isEqualToString:@"NETSTATS"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getNetworkStats]];
			} else if ([commandString isEqualToString:@"MSGCOUNT"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getBandwidthStats:client.world]];
			} else if ([commandString isEqualToString:@"DISKSPACE"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getAllVolumesAndSizes]];
			} else if ([commandString isEqualToString:@"THEME"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getCurrentThemeInUse:client.world]];
			} else if ([commandString isEqualToString:@"SCREENS"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getAllScreenResolutions]];
			} else if ([commandString isEqualToString:@"RUNCOUNT"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getTextualRunCount]];
			} else if ([commandString isEqualToString:@"LOADAVG"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getSystemLoadAverage]];
			} else if ([commandString isEqualToString:@"SYSMEM"]) {
				[[client iomt] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo getSystemMemoryUsage]];
			}
		}
	}
}

@end