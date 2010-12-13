// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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