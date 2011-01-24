// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSBundle (NSBundleHelper)

+ (void)reloadBundles:(IRCWorld *)world;
+ (void)loadBundlesIntoMemory:(IRCWorld *)world;
+ (void)deallocBundlesFromMemory:(IRCWorld *)world;

+ (void)sendUserInputDataToBundles:(IRCWorld *)world
						   message:(NSString *)message
						   command:(NSString *)command
							client:(IRCClient *)client;

+ (void)sendServerInputDataToBundles:(IRCWorld *)world
							  client:(IRCClient *)client
							 message:(IRCMessage *)msg;

@end