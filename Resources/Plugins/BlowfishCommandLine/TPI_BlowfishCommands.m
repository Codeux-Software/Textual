// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_BlowfishCommands.h"

#define TXExchangeRequestPrefix			@"DH1080_INIT "
#define TXExchangeResponsePrefix		@"DH1080_FINISH "

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
		
		if ([messageString contains:NSStringWhitespacePlaceholder]) {
			messageString = [messageString substringToIndex:[messageString stringPosition:NSStringWhitespacePlaceholder]];
		}
		
		if ([commandString isEqualToString:@"SETKEY"]) {
			if (NSObjectIsEmpty(messageString)) {
				c.config.encryptionKey = nil;
				
				[[client iomt] printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
			} else {
				if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
					if ([c.config.encryptionKey isEqualToString:messageString] == NO) {
						[[client iomt] printDebugInformation:TXTLS(@"BlowfishEncryptionKeyChanged") channel:c];
					}
				} else {
					if (c.isTalk) {
						[[client iomt] printDebugInformation:TXTLS(@"BlowfishEncryptionStartedInQuery") channel:c];
					} else {
						[[client iomt] printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
					}
				}
				
				c.config.encryptionKey = messageString;
			}
		} else if ([commandString isEqualToString:@"DELKEY"]) {
			c.config.encryptionKey = nil;
			
			[[client iomt] printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
		} else if ([commandString isEqualToString:@"KEY"]) {
			if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
				[[client iomt] printDebugInformation:TXTFLS(@"BlowfishCurrentEncryptionKey", c.config.encryptionKey) channel:c];
			} else {	
				[[client iomt] printDebugInformation:TXTLS(@"BlowfishNoEncryptionKeySet") channel:c];
			}
		} else if ([commandString isEqualToString:@"KEYX"]) {
			[[client iomt] printDebugInformation:TXTLS(@"BlowfishKeyExchangeFeatureNotReadyYet") channel:c];
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
	
	NSArray *privmsgRule_1 = [NSArray arrayWithObjects:[@"^" stringByAppendingString:TXExchangeRequestPrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), nil];
	
	NSArray *privmsgRule_2 = [NSArray arrayWithObjects:[@"^" stringByAppendingString:TXExchangeResponsePrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), nil];
	
	[rules setObject:[NSArray arrayWithObjects:privmsgRule_1, privmsgRule_2, nil] forKey:IRCCommandFromLineType(TVCLogLineNoticeType)];
	
	return rules;
}

@end