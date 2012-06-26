// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
	if ([client isConnected]) {
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
	}
}

@end