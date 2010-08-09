// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "IRCClient.h"

@interface NSBundle (NSBundleHelper)

+ (void)reloadAllAvailableBundles:(IRCWorld*)world;
+ (void)loadAllAvailableBundlesIntoMemory:(IRCWorld*)world;
+ (void)deallocAllAvailableBundlesFromMemory:(IRCWorld*)world;

+ (void)sendUserInputDataToBundles:(IRCWorld*)world
						   message:(NSString*)message
						   command:(NSString*)command
							client:(IRCClient*)client;

+ (void)sendServerInputDataToBundles:(IRCWorld*)world
							  client:(IRCClient*)client
							 message:(IRCMessage*)msg;

@end