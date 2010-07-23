#import <Cocoa/Cocoa.h>
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "IRCClient.h"

@interface NSBundle (NSBundleHelper)

+ (void)loadAllAvailableBundlesIntoMemory:(IRCWorld*)world;

+ (void)sendUserInputDataToBundles:(IRCWorld*)world
				   message:(NSString*)message
				   command:(NSString*)command
				    client:(IRCClient*)client;

+ (void)sendServerInputDataToBundles:(IRCWorld*)world
					client:(IRCClient*)client
				     message:(IRCMessage*)msg;

@end