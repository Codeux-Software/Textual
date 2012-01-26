// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_BlowfishCommands.h"

#define exchangeRequestPrefix	@"DH1080_INIT "
#define exchangeResponsePrefix	@"DH1080_FINISH "

@implementation TPI_BlowfishCommands

#pragma mark -
#pragma mark Plugin Structure

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	IRCChannel *c = [client.world selectedChannelOn:client];
	
	if (c.isChannel || c.isTalk) {
		messageString = [messageString trim];
		
		if ([messageString contains:NSWhitespaceCharacter]) {
			messageString = [messageString substringToIndex:[messageString stringPosition:NSWhitespaceCharacter]];
		}
		
		if ([commandString isEqualToString:@"SETKEY"]) {
			if (NSObjectIsEmpty(messageString)) {
				c.config.encryptionKey = nil;
				
				[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED") channel:c];
			} else {
				if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
					if ([c.config.encryptionKey isEqualToString:messageString] == NO) {
						[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_KEY_CHANGED") channel:c];
					}
				} else {
					if (c.isTalk) {
						[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED_QUERY") channel:c];
					} else {
						[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED") channel:c];
					}
				}
				
				c.config.encryptionKey = messageString;
			}
		} else if ([commandString isEqualToString:@"DELKEY"]) {
			c.config.encryptionKey = nil;
			
			[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED") channel:c];
		} else if ([commandString isEqualToString:@"KEY"]) {
			if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
				[[client iomt] printDebugInformation:TXTFLS(@"BLOWFISH_ENCRYPTION_KEY", c.config.encryptionKey) channel:c];
			} else {	
				[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_NO_KEY") channel:c];
			}
		} else if ([commandString isEqualToString:@"KEYX"]) {
			[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_NOT_READY_YET") channel:c];
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"setkey", @"delkey", @"key", @"keyx", nil];
}

- (NSDictionary *)pluginOutputDisplayRules
{
	/* This is an undocumented plugin call to suppress certain messages. */
	
	NSMutableDictionary *rules = [NSMutableDictionary dictionary];
	
	NSArray *privmsgRule_1 = [NSArray arrayWithObjects:[@"^" stringByAppendingString:exchangeRequestPrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), nil];
	
	NSArray *privmsgRule_2 = [NSArray arrayWithObjects:[@"^" stringByAppendingString:exchangeResponsePrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), nil];
	
	[rules setObject:[NSArray arrayWithObjects:privmsgRule_1, privmsgRule_2, nil] forKey:IRCCommandFromLineType(LINE_TYPE_NOTICE)];
	
	return rules;
}

@end