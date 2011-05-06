// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_BlowfishCommands.h"

#define exchangeRequestPrefix	@"DH1080_INIT "
#define exchangeResponsePrefix	@"DH1080_FINISH "

#define exchangeTimeoutTimerInterval	10

@interface TPI_BlowfishCommands (Private)
- (void)processMessageOnMainThread:(IRCClient *)client 
							sender:(NSDictionary *)senderDict 
						   message:(NSDictionary *)messageDict;

- (BOOL)activeRequestExistsFor:(NSString *)nick onClient:(IRCClient *)u;
- (void)handleKeyExchangeTimeout:(NSTimer *)timer;

- (void)addKeyExchangeRequestForClient:(IRCClient *)u nickname:(NSString *)nick exchangeServer:(CFDH1080 *)server;
- (void)removeKeyExchangeRequestForClient:(IRCClient *)u nickname:(NSString *)nick;
@end

@implementation TPI_BlowfishCommands

@synthesize inTimerLoop;
@synthesize keyExchangeData;

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
			if (c.isTalk == NO) {
				[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_QUERY_ONLY") channel:c];
			} else {
				NSString *chname = [c name];
				
				if ([self activeRequestExistsFor:chname onClient:client]) {
					[[client iomt] printDebugInformation:TXTFLS(@"BLOWFISH_KEY_EXCHANGE_ALREADY_EXISTS", chname) channel:c];
				} else {
					CFDH1080 *exchangeServer = [CFDH1080 new];
					
					if (exchangeServer) {
						NSString *publicKey = [exchangeServer generatePublicKey];
						
						if (NSObjectIsEmpty(publicKey)) {
							[[client iomt] printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_UNKNOWN_ERROR") channel:c];
						} else {
							[[client iomt] printDebugInformation:TXTFLS(@"BLOWFISH_KEY_EXCHANGE_REQUEST_SENT", chname) channel:c];
							[[client iomt] sendText:[exchangeRequestPrefix stringByAppendingString:publicKey] command:IRCCI_NOTICE channel:c];
							
							[self addKeyExchangeRequestForClient:client nickname:chname exchangeServer:exchangeServer];
						}
					}
				}
			}
		}
	}
}

- (void)messageReceivedByServer:(IRCClient *)client 
						 sender:(NSDictionary *)senderDict 
						message:(NSDictionary *)messageDict
{
	[[self iomt] processMessageOnMainThread:client sender:senderDict message:messageDict];
} 

- (NSArray *)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"setkey", @"delkey", @"key", @"keyx", nil];
}

- (NSArray *)pluginSupportsServerInputCommands
{
	return [NSArray arrayWithObjects:@"notice", nil];
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

#pragma mark -
#pragma mark Key Exchange Handling

- (void)processMessageOnMainThread:(IRCClient *)client 
							sender:(NSDictionary *)senderDict 
						   message:(NSDictionary *)messageDict
{
	NSString *clikey   = client.config.guid;
	NSString *nickname = [senderDict objectForKey:@"senderNickname"];
	NSString *message  = [messageDict objectForKey:@"messageSequence"];   
	
	if ([message length] >= 191 || [message length] <= 195) {
		if ([message hasPrefix:exchangeRequestPrefix]) {
			IRCChannel *channel   = [client findChannelOrCreate:nickname useTalk:YES];
			NSString   *publicKey = [message safeSubstringFromIndex:[exchangeRequestPrefix length]];
			
			if (channel.isTalk == NO) {
				return NSLog(@"Unable to output text due to rule match by Blowfish Encryption extension.");
			}
			
			CFDH1080 *exchangeServer = [CFDH1080 new];
			
			if (exchangeServer) {
				[client printDebugInformation:TXTFLS(@"BLOWFISH_KEY_EXCHANGE_RESPONSE_PENDING", nickname) channel:channel];
				
				NSString *localPublicKey = [exchangeServer generatePublicKey];
				
				if (NSObjectIsEmpty(localPublicKey)) {
					[client printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_UNKNOWN_ERROR") channel:channel];
				} else {
					NSString *secretKey = [exchangeServer secretKeyFromPublicKey:publicKey];
					
					if (NSObjectIsEmpty(secretKey)) {
						[client printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_UNKNOWN_ERROR") channel:channel];
					} else {
						[client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED_QUERY") channel:channel];
						[client sendText:[exchangeResponsePrefix stringByAppendingString:localPublicKey] command:IRCCI_NOTICE channel:channel];
						
						[channel.config setEncryptionKey:secretKey];
					}
				}
			}
		} else {
			if ([message hasPrefix:exchangeResponsePrefix]) {
				NSString     *publicKey  = [message safeSubstringFromIndex:[exchangeResponsePrefix length]];
				IRCChannel   *channel    = [client findChannelOrCreate:nickname useTalk:YES];
				NSDictionary *nicknames  = [keyExchangeData dictionaryForKey:clikey];
				
				if (channel.isTalk == NO) {
					return NSLog(@"Unable to output text due to rule match by Blowfish Encryption extension.");
				}
				
				if ([nicknames containsKeyIgnoringCase:nickname]) {
					NSString     *dkey = [nicknames keyIgnoringCase:nickname];
					NSDictionary *data = [nicknames dictionaryForKey:dkey];
					
					CFDH1080 *server = [data pointerForKey:@"server"];
					
					if (PointerIsEmpty(server)) {
						[client printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_UNKNOWN_ERROR") channel:channel];
					} else {
						NSString *secretKey = [server secretKeyFromPublicKey:publicKey];
						
						if (NSObjectIsEmpty(secretKey)) {
							[client printDebugInformation:TXTLS(@"BLOWFISH_KEY_EXCHANGE_UNKNOWN_ERROR") channel:channel];
						} else {
							[client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED_QUERY") channel:channel];
							
							[channel.config setEncryptionKey:secretKey];
							
							[self removeKeyExchangeRequestForClient:client nickname:nickname];
						}
					}
				}
			}
		}
	}
}

- (void)addKeyExchangeRequestForClient:(IRCClient *)u nickname:(NSString *)nick exchangeServer:(CFDH1080 *)server;
{
	if (PointerIsEmpty(u) || PointerIsEmpty(server) || NSObjectIsEmpty(nick)) {
		return;
	}
	
	NSString *ckey = u.config.guid;
	
	if (NSObjectIsEmpty(keyExchangeData)) {
		keyExchangeData = [NSMutableDictionary dictionary];
		
		[keyExchangeData retain];
	}
	
	if ([keyExchangeData containsKey:ckey] == NO) {
		[keyExchangeData setObject:[NSMutableDictionary newad] forKey:ckey];
	}
	
	NSMutableDictionary *data     = [NSMutableDictionary dictionary];
	
	[data setPointer:u							forKey:@"client"];
	[data setPointer:server						forKey:@"server"];
	[data setInteger:CFAbsoluteTimeGetCurrent() forKey:@"time"];
	
	[[keyExchangeData objectForKey:ckey] setObject:data forKey:nick];		
	
	/* Since this is runnning in the background there is no need for a timer.
	 Just hold thread for the seconds needed to determine a request timed out. */
	
	[NSThread sleepForTimeInterval:exchangeTimeoutTimerInterval];
	
	if ([self activeRequestExistsFor:nick onClient:u]) {
		[self removeKeyExchangeRequestForClient:u nickname:nick];
		
		IRCChannel *c = [u findChannelOrCreate:nick useTalk:YES];
		
		[[u iomt] printDebugInformation:TXTFLS(@"BLOWFISH_KEY_EXCHANGE_TIMED_OUT", nick) channel:c];
	}
}

- (BOOL)activeRequestExistsFor:(NSString *)nick onClient:(IRCClient *)u
{
	if (PointerIsEmpty(u) || NSObjectIsEmpty(nick)) {
		return NO;
	}
	
	NSString *ckey = u.config.guid;
	
	if (NSObjectIsNotEmpty(keyExchangeData)) {
		if ([keyExchangeData containsKey:ckey]) {
			NSDictionary *nicknames = [keyExchangeData dictionaryForKey:ckey];
			
			if ([nicknames containsKeyIgnoringCase:nick]) {
				NSString     *dkey = [nicknames keyIgnoringCase:nick];
				NSDictionary *data = [nicknames dictionaryForKey:dkey];
				
				NSInteger time1 = [data integerForKey:@"time"];
				NSInteger time2 = CFAbsoluteTimeGetCurrent();
				
				if ((time2 - time1) <= exchangeTimeoutTimerInterval) {
					return YES;
				}
			}
		}
	}
	
	return NO;
}

- (void)removeKeyExchangeRequestForClient:(IRCClient *)u nickname:(NSString *)nick
{
	if (PointerIsEmpty(u) || NSObjectIsEmpty(nick)) {
		return;
	}
	
	NSString *ckey = u.config.guid;
	
	if ([self activeRequestExistsFor:nick onClient:u]) {
		NSDictionary *nicknames = [keyExchangeData dictionaryForKey:ckey];
		
		if ([nicknames count] == 1) {
			[keyExchangeData removeObjectForKey:ckey];
		} else {
			[[keyExchangeData objectForKey:ckey] removeObjectForKey:[nicknames keyIgnoringCase:nick]];
		}
	}
}

- (void)dealloc
{
	[keyExchangeData drain];
	
	[super dealloc];
}

@end