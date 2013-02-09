/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TPI_BlowfishCommands.h"

#define TXExchangeRequestPrefix				@"DH1080_INIT "
#define TXExchangeResponsePrefix			@"DH1080_FINISH "

#define TXExchangeReuqestTimeoutDelay		10

@interface TPI_BlowfishCommands ()
/* 
	  key format:	STRING("<client UUID> —> <remote nickname>")
	value format:	 ARRAY("<pointer to CFDH1080>", "<pointer to IRCChannel>")
 
	-keyExchangeDictionaryKey: can be used to generate key.
*/

@property (nonatomic, strong) NSMutableDictionary *keyExchangeRequests;
@end

@implementation TPI_BlowfishCommands

#pragma mark -
#pragma mark Plugin Structure.

- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
	self.keyExchangeRequests = [NSMutableDictionary dictionary];
}

- (void)pluginUnloadedFromMemory
{
	self.keyExchangeRequests = nil;
}

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict
{
	NSString *person  = senderDict[@"senderNickname"];
	NSString *message = messageDict[@"messageSequence"];

	BOOL isRequest = [message hasPrefix:TXExchangeRequestPrefix];
	BOOL isResponse = [message hasPrefix:TXExchangeResponsePrefix];

	if (isRequest || isResponse) {
		if (isRequest) {
			/* A request may create a query so it must be invoked on
			 the main thread. Creating a channel requires access to
			 WebKit and WebKit will throw an exception because they
			 hate running on anything else. */

			[self.iomt keyExchangeRequestReceived:message on:client from:person];
		} else {
			/* We do not want to create the channel if it is a response.
			 If the user closed the query, then allow old request to expire.
			 This is done so that the IRCChannel pointer part of our request
			 dictionary will remain same instead of creating a new one and
			 the old pointing to nothing. */
			
			IRCChannel *channel = [client findChannel:person];

			if (channel) {
				NSString *requestKey = [self keyExchangeDictionaryKey:channel];

				if (NSObjectIsNotEmpty(requestKey)) {
					[self keyExchangeResponseReceived:message on:client from:requestKey];
				}
			}
		}
	}
}

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString
{
	IRCChannel *c = [client.world selectedChannelOn:client];
	
	if (c.isChannel || c.isTalk) {
		messageString = messageString.trim;
		
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
			if (c.isTalk == NO) {
				[client printDebugInformation:TXTLS(@"BlowfishKeyExchangeForQueriesOnly") channel:c];
			} else {
				if ([self keyExchangeRequestExists:c]) {
					[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeRequestAlreadyExists", c.name) channel:c];
				} else {
					CFDH1080 *keyRequest = [CFDH1080 new];

					NSString *publicKey = [keyRequest generatePublicKey];

					if (NSObjectIsEmpty(publicKey)) {
						[client printDebugInformation:TXTLS(@"BlowfishKeyExchangeUnknownErrorOccurred") channel:c];
					} else {
						NSString *requestKey = [self keyExchangeDictionaryKey:c];
						NSString *requestMsg = [TXExchangeRequestPrefix stringByAppendingString:publicKey];

						[self.keyExchangeRequests setObject:@[keyRequest, c] forKey:requestKey];

						[client sendText:[NSAttributedString emptyStringWithBase:requestMsg]
								 command:IRCPrivateCommandIndex("notice")
								 channel:c];

						[self performSelectorOnMainThread:@selector(keyExchangeSetupTimeoutTimer:) withObject:requestKey waitUntilDone:NO];
						
						[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeRequestSent", c.name) channel:c];
					}
				}
			}
		}
	}
}

- (NSArray *)pluginSupportsUserInputCommands
{
	return @[@"setkey", @"delkey", @"key", @"keyx"];
}

- (NSArray *)pluginSupportsServerInputCommands
{
	return @[@"notice"];
}

- (NSDictionary *)pluginOutputDisplayRules
{
	NSString *ruleKey = IRCCommandFromLineType(TVCLogLineNoticeType);

	NSArray *rule_1 = @[[@"^" stringByAppendingString:TXExchangeRequestPrefix],
	NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];

	NSArray *rule_2 = @[[@"^" stringByAppendingString:TXExchangeResponsePrefix],
	NSNumberWithBOOL(YES), NSNumberWithBOOL(YES), NSNumberWithBOOL(YES)];

	return @{ruleKey : @[rule_1, rule_2]};
}

#pragma mark -
#pragma mark Key Exchange.

- (void)keyExchangeRequestReceived:(NSString *)requestData on:(IRCClient *)client from:(NSString *)requestSender
{
	IRCChannel *channel = [client findChannelOrCreate:requestSender useTalk:YES];

	requestData = [requestData safeSubstringFromIndex:[TXExchangeRequestPrefix length]];

	//DebugLogToConsole(@"Key Exchange Request Received:");
	//DebugLogToConsole(@"	Client: %@", client);
	//DebugLogToConsole(@"	Channel: %@", channel);
	//DebugLogToConsole(@"	Message: %@", requestData);
	
	[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeRequestReceived", channel.name) channel:channel];

	if ([self keyExchangeRequestExists:channel]) {
		[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeRequestAlreadyExists", channel.name) channel:channel];
	} else {
		CFDH1080 *keyRequest = [CFDH1080 new];

		/* Process secret from the Receiver. */
		NSString *theSecret = [keyRequest secretKeyFromPublicKey:requestData];

		if (NSObjectIsEmpty(theSecret)) {
			return [client printDebugInformation:TXTLS(@"BlowfishKeyExchangeUnknownErrorOccurred") channel:channel];
		}

		//DebugLogToConsole(@"	Shared Secret: %@", theSecret);

		channel.config.encryptionKey = theSecret;

		/* Generate our own public key. If everything has gone correctly up to here,
		 then when the user that sent the request computes our public key, we both
		 should have the same secret. */
		NSString *publicKey = [keyRequest generatePublicKey];

		if (NSObjectIsEmpty(publicKey)) {
			return [client printDebugInformation:TXTLS(@"BlowfishKeyExchangeUnknownErrorOccurred") channel:channel];
		}

		/* Finish up. */
		NSString *requestMsg = [TXExchangeResponsePrefix stringByAppendingString:publicKey];

		[client sendText:[NSAttributedString emptyStringWithBase:requestMsg]
				 command:IRCPrivateCommandIndex("notice")
				 channel:channel];

		[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeResponseSent", channel.name) channel:channel];
		[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeSuccessful", channel.name) channel:channel];
	}
}

- (void)keyExchangeResponseReceived:(NSString *)responseData on:(IRCClient *)client from:(NSString *)responseKey
{
	NSArray *exchangeData = [self keyExchangeInformation:responseKey];

	if (NSObjectIsNotEmpty(exchangeData)) {
		responseData = [responseData safeSubstringFromIndex:[TXExchangeResponsePrefix length]];
		
		//DebugLogToConsole(@"Key Exchange Response Received:");
		//DebugLogToConsole(@"	Response Key: %@", responseKey);
		//DebugLogToConsole(@"	Response Info: %@", exchangeData);
		//DebugLogToConsole(@"	Message: %@", responseData);

		CFDH1080 *request = exchangeData[0];
		IRCChannel *channel = exchangeData[1];
		
		[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeResponseReceived", channel.name) channel:channel];
		
		/* Compute the public key received against our own. Our original public key
		 was sent to the user which has responded by computing their own against 
		 that. Now we compute the key received to obtain the shared secret. What?… */
		NSString *theSecret = [request secretKeyFromPublicKey:responseData];

		if (NSObjectIsEmpty(theSecret)) {
			return [client printDebugInformation:TXTLS(@"BlowfishKeyExchangeUnknownErrorOccurred") channel:channel];
		}
		
		//DebugLogToConsole(@"	Shared Secret: %@", theSecret);

		channel.config.encryptionKey = theSecret;

		/* Finish up. */
		[client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeSuccessful", channel.name) channel:channel];
		
		[self.keyExchangeRequests removeObjectForKey:responseKey];
	}
}

#pragma mark -
#pragma mark Key Exchange Timer.

- (void)keyExchangeSetupTimeoutTimer:(NSString *)requestKey
{
	[self performSelector:@selector(keyExchangeTimedOut:) withObject:requestKey afterDelay:TXExchangeReuqestTimeoutDelay];
}

- (void)keyExchangeTimedOut:(NSString *)requestKey
{
	NSArray *requestData = [self keyExchangeInformation:requestKey];

	if (NSObjectIsNotEmpty(requestKey)) {
		IRCChannel *channel = requestData[1];
		
		[channel.client printDebugInformation:TXTFLS(@"BlowfishKeyExchangeRequestTimedOut", channel.name) channel:channel];

		[self.keyExchangeRequests removeObjectForKey:requestKey];
	}
}

#pragma mark -
#pragma mark Key Exchange Information.

- (BOOL)keyExchangeRequestExists:(IRCChannel *)channel
{
	NSString *requestKey = [self keyExchangeDictionaryKey:channel];

	return NSObjectIsNotEmpty([self keyExchangeInformation:requestKey]);
}

- (NSArray *)keyExchangeInformation:(NSString *)requestKey
{
	NSArray *requestData = [self.keyExchangeRequests arrayForKey:requestKey];

	if (NSObjectIsNotEmpty(requestData)) {
		id request = requestData[0];
		id channel = requestData[1];

		if (requestData.count == 2								&& // Array count is equal to 2.
			PointerIsNotEmpty( request )						&& // Pointer are not empty.
			PointerIsNotEmpty( channel )						&& // Pointer are not empty.
			PointerIsNotEmpty([channel client])					&& // Pointer are not empty.
			[request isKindOfClass:[CFDH1080 class]]			&& // Type of class is correct.
			[channel isKindOfClass:[IRCChannel class]]) {		   // Type of class is correct.

			return requestData;
		}
	}

	return nil;
}

- (NSString *)keyExchangeDictionaryKey:(IRCChannel *)channel
{
	if (PointerIsEmpty(channel) || channel.isTalk == NO) {
		return nil;
	}
	
	return [NSString stringWithFormat:@"%@ –> %@", channel.client.config.guid, channel.name];
}

@end