#import "TPISystemProfiler.h"
#import "TPI_SP_SysInfo.h"

@implementation TPISystemProfiler

- (NSArray*)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"sysinfo", nil];
}

- (void)messageSentByUser:(NSObject*)client
			message:(NSString*)messageString
			command:(NSString*)commandString
{
	if ([client isConnected]) {
		NSString *channelName = [[[client world] selectedChannel] name];
	
		if ([channelName length] >= 1) {
			[[client invokeOnMainThread] sendPrivmsgToSelectedChannel:[TPI_SP_SysInfo compiledOutput]];
		}
	}
}

@end