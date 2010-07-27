// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface PluginProtocol : NSObject

- (void)messageSentByUser:(NSObject*)client
			message:(NSString*)messageString
			command:(NSString*)commandString;

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)messageDict;

- (NSArray*)pluginSupportsUserInputCommands;
- (NSArray*)pluginSupportsServerInputCommands;

@end