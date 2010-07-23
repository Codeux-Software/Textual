#import <Cocoa/Cocoa.h>

@interface TPISystemProfiler : NSObject

- (void)messageSentByUser:(NSObject*)client
			message:(NSString*)messageString
			command:(NSString*)commandString;

- (NSArray*)pluginSupportsUserInputCommands;

@end