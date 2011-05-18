// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Model for Textual plugins */

@interface PluginProtocol : NSObject

/* Supported Commands */
- (NSArray *)pluginSupportsUserInputCommands;
- (NSArray *)pluginSupportsServerInputCommands;

/* Supported Commands Delegates */
- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString;

- (void)messageReceivedByServer:(IRCClient *)client 
						 sender:(NSDictionary *)senderDict 
						message:(NSDictionary *)messageDict;

/* Output Rules */
- (NSDictionary *)pluginOutputDisplayRules;

/* Allocation & Deallocation */
- (void)pluginLoadedIntoMemory:(IRCWorld *)world;
- (void)pluginUnloadedFromMemory;

/* Preference Pane */
- (NSView *)preferencesView;
- (NSString *)preferencesMenuItemName;

@end