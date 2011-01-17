// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_BlowfishCommands.h"

@implementation TPI_BlowfishCommands

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	IRCChannel *c = [[client world] selectedChannelOn:client];
	
	if (c.isChannel || c.isTalk) {
		messageString = [messageString trim];
		
		if ([messageString contains:@" "]) {
			messageString = [messageString substringToIndex:[messageString stringPosition:@" "]];
		}
		
		if ([commandString isEqualToString:@"SETKEY"]) {
			if ([messageString length] < 1) {
				c.config.encryptionKey = nil;
				
				[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED")];
			} else {
				if ([c.config.encryptionKey length] > 0) {
					if ([c.config.encryptionKey isEqualToString:messageString] == NO) {
						[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_KEY_CHANGED")];
					}
				} else {
					if (c.isTalk) {
						[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED_QUERY")];
					} else {
						[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED")];
					}
				}
				
				c.config.encryptionKey = messageString;
			}
		} else if ([commandString isEqualToString:@"DELKEY"]) {
			c.config.encryptionKey = nil;
			[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED")];
		} else if ([commandString isEqualToString:@"KEY"]) {
			if ([c.config.encryptionKey length] > 1) {
				[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:[NSString stringWithFormat:TXTLS(@"BLOWFISH_ENCRYPTION_KEY"), c.config.encryptionKey]];
			} else {	
				[[client invokeOnMainThread] printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_NO_KEY")];
			}
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"setkey", @"delkey", @"key", nil];
}

@end