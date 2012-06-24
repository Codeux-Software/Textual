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
				
				[client printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
			} else {
				if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
					if ([c.config.encryptionKey isEqualToString:messageString] == NO) {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionKeyChanged") channel:c];
					}
				} else {
					if (c.isTalk) {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionStartedInQuery") channel:c];
					} else {
						[client printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
					}
				}
				
				c.config.encryptionKey = messageString;
			}
		} else if ([commandString isEqualToString:@"DELKEY"]) {
			c.config.encryptionKey = nil;
			
			[client printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
		} else if ([commandString isEqualToString:@"KEY"]) {
			if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
				[client printDebugInformation:TXTFLS(@"BlowfishCurrentEncryptionKey", c.config.encryptionKey) channel:c];
			} else {	
				[client printDebugInformation:TXTLS(@"BlowfishNoEncryptionKeySet") channel:c];
			}
		} else if ([commandString isEqualToString:@"KEYX"]) {
			[client printDebugInformation:TXTLS(@"BlowfishKeyExchangeFeatureNotReadyYet") channel:c];
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"setkey", @"delkey", @"key", @"keyx"];
}

- (NSDictionary *)pluginOutputDisplayRules
{
	/* This is an undocumented plugin call to suppress certain messages. */
	
	NSMutableDictionary *rules = [NSMutableDictionary dictionary];
	
	NSArray *privmsgRule_1 = @[[@"^" stringByAppendingString:TXExchangeRequestPrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];
	
	NSArray *privmsgRule_2 = @[[@"^" stringByAppendingString:TXExchangeResponsePrefix], 
							  NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];
	
	rules[IRCCommandFromLineType(TVCLogLineNoticeType)] = @[privmsgRule_1, privmsgRule_2];
	
	return rules;
}

@end