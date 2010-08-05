// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "IRCClient.h"

@interface PluginProtocol : NSObject

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString*)messageString
				  command:(NSString*)commandString;

- (void)messageReceivedByServer:(IRCClient*)client 
						 sender:(NSDictionary*)senderDict 
						message:(NSDictionary*)messageDict;

- (NSArray*)pluginSupportsUserInputCommands;
- (NSArray*)pluginSupportsServerInputCommands;

@end