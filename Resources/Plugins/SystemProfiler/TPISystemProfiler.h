@interface TPISystemProfiler : NSObject

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString*)messageString
				  command:(NSString*)commandString;

- (NSArray*)pluginSupportsUserInputCommands;

@end