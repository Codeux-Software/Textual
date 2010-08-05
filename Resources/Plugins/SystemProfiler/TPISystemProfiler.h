#import <Cocoa/Cocoa.h>

#include "IRCClient.h"
#include "IRCWorld.h"
#include "NSObject+DDExtensions.h"

@interface TPISystemProfiler : NSObject

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString*)messageString
				  command:(NSString*)commandString;

- (NSArray*)pluginSupportsUserInputCommands;

@end