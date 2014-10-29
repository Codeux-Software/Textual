/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

- (void)pluginLoadedIntoMemory
{
	self.keyExchangeRequests = [NSMutableDictionary dictionary];
}

- (void)pluginWillBeUnloadedFromMemory
{
	self.keyExchangeRequests = nil;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didReceiveServerInputOnClient:(IRCClient *)client
					senderInformation:(NSDictionary *)senderDict
				   messageInformation:(NSDictionary *)messageDict
{
	[self performBlockOnMainThread:^{
		NSString *person  = senderDict[@"senderNickname"];
		NSString *message = messageDict[@"messageSequence"];

		if ([message hasPrefix:@"+"]) {
			/* For some reason, NOTICE has a + prefix for key exchange on
			 freenode. This fixex that. */
			
			message = [message substringFromIndex:1];
		}

		BOOL isRequest = [message hasPrefix:TXExchangeRequestPrefix];
		BOOL isResponse = [message hasPrefix:TXExchangeResponsePrefix];

		if (isRequest || isResponse) {
			if (isRequest) {
				/* A request may create a query so it must be invoked on
				 the main thread. Creating a channel requires access to
				 WebKit and WebKit will throw an exception because they
				 hate running on anything else. */

				[self keyExchangeRequestReceived:message on:client from:person];
			} else {
				/* We do not want to create the channel if it is a response.
				 If the user closed the query, then allow old request to expire.
				 This is done so that the IRCChannel pointer part of our request
				 dictionary will remain same instead of creating a new one and
				 the old pointing to nothing. */
				
				IRCChannel *channel = [client findChannel:person];

				if (channel) {
					NSString *requestKey = [self keyExchangeDictionaryKey:channel];

					if (requestKey) {
						[self keyExchangeResponseReceived:message on:client from:requestKey];
					}
				}
			}
		}
	}];
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	[self performBlockOnMainThread:^{
		IRCChannel *c = [mainWindow() selectedChannelOn:client];
		
		if ([c isChannel] || [c isPrivateMessage]) {
			NSString *_messageString = [messageString trimAndGetFirstToken];

			NSString *encryptionKey = [c encryptionKey];
			
			if ([commandString isEqualToString:@"SETKEY"]) {
				if (NSObjectIsEmpty(_messageString)) {
					[c setEncryptionKey:NSStringEmptyPlaceholder];
					
					[client printDebugInformation:BLS(1004) channel:c];
				} else {
					if (encryptionKey) {
						if ([encryptionKey isEqualToString:_messageString] == NO) {
							[client printDebugInformation:BLS(1002) channel:c];
						}
					} else {
						if ([c isPrivateMessage]) {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1002]") channel:c];
						} else {
							[client printDebugInformation:BLS(1003) channel:c];
						}
					}
					
					[c setEncryptionKey:_messageString];
				}
			} else if ([commandString isEqualToString:@"DELKEY"]) {
				[c setEncryptionKey:NSStringEmptyPlaceholder];
				
				[client printDebugInformation:BLS(1004) channel:c];
			} else if ([commandString isEqualToString:@"KEY"]) {
				if (encryptionKey) {
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]", encryptionKey) channel:c];
				} else {	
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]") channel:c];
				}
			} else if ([commandString isEqualToString:@"SETKEYMODE"]) {
				if ([_messageString isEqualIgnoringCase:@"CBC"]) {
					[c setEncryptionAlgorithm:CSFWBlowfishEncryptionCBCAlgorithm];
					
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1020]") channel:c];
				} else {
					[c setEncryptionAlgorithm:CSFWBlowfishEncryptionECBAlgorithm];
					
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1021]") channel:c];
				}
			} else if ([commandString isEqualToString:@"KEYX"]) {
				if ([c isPrivateMessage] == NO) {
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1008]") channel:c];
				} else {
					if ([self keyExchangeRequestExists:c]) {
						[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1009]", [c name]) channel:c];
					} else if (encryptionKey) {
						[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1016]", [c name]) channel:c];
					} else {
						CFDH1080 *keyRequest = [CFDH1080 new];

						NSString *publicKey = [keyRequest generatePublicKey];

						if (NSObjectIsEmpty(publicKey)) {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]") channel:c];
						} else {
							NSString *requestKey = [self keyExchangeDictionaryKey:c];
							
							NSString *requestMsg = nil;
							
							if ([_messageString isEqualIgnoringCase:@"nocbc"]) {
								requestMsg = [NSString stringWithFormat:@"%@%@", TXExchangeRequestPrefix, publicKey];
							} else {
								requestMsg = [NSString stringWithFormat:@"%@%@ CBC", TXExchangeRequestPrefix, publicKey];
							}

							[[self keyExchangeRequests] setObject:@[keyRequest, c] forKey:requestKey];

							[client sendText:[NSAttributedString emptyStringWithBase:requestMsg]
									 command:IRCPrivateCommandIndex("notice")
									 channel:c];

							[self keyExchangeSetupTimeoutTimer:requestKey];
							
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1011]", [c name]) channel:c];
						}
					}
				}
			}
			
			encryptionKey = nil;
		}
	}];
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"setkey", @"delkey", @"key", @"keyx", @"setkeymode"];
}

- (NSArray *)subscribedServerInputCommands
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

- (void)keyExchangeRequestReceived:(NSString *)requestDataRaw on:(IRCClient *)client from:(NSString *)requestSender
{
	IRCChannel *channel = [client findChannelOrCreate:requestSender isPrivateMessage:YES];
	
	NSString *encryptionKey = [channel encryptionKey];
	
    if (encryptionKey) {
        [client printDebugInformation:TPILocalizedString(@"BasicLanguage[1015]", [channel name]) channel:channel];

        return;
    }
	
	CSFWBlowfishEncryptionAlgorithm algorithm = CSFWBlowfishEncryptionDefaultAlgorithm;

	NSString *requestData = nil;
	
	if ([requestDataRaw length] > [TXExchangeRequestPrefix length]) {
		requestData = [requestDataRaw substringFromIndex:[TXExchangeRequestPrefix length]];
		
		NSArray *parts = [requestData split:NSStringWhitespacePlaceholder];
		
		requestData = parts[0];
		
		if ([parts count] > 1 && [parts[1] isEqualToString:@"CBC"]) {
			algorithm = CSFWBlowfishEncryptionCBCAlgorithm;
		}
	} else {
		requestData =  requestDataRaw;
	}

	//DebugLogToConsole(@"Key Exchange Request Received:");
	//DebugLogToConsole(@"	Client: %@", client);
	//DebugLogToConsole(@"	Channel: %@", channel);
	//DebugLogToConsole(@"	Message: %@", requestData);
	
	if ([requestData length] <= 0) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1019]") channel:channel];
	} else {
		if ([self keyExchangeRequestExists:channel]) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1010]", [channel name]) channel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1009]", [channel name]) channel:channel];
		} else {
			CFDH1080 *keyRequest = [CFDH1080 new];

			/* Process secret from the Receiver. */
			NSString *theSecret = [keyRequest secretKeyFromPublicKey:requestData];

			if (NSObjectIsEmpty(theSecret)) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]") channel:channel];

				return;
			}

			/* Generate our own public key. If everything has gone correctly up to here,
			 then when the user that sent the request computes our public key, we both
			 should have the same secret. */
			NSString *publicKey = [keyRequest generatePublicKey];

			if (NSObjectIsEmpty(publicKey)) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]") channel:channel];

				return;
			}

			//DebugLogToConsole(@"	Shared Secret: %@", theSecret);
			
			[channel setEncryptionKey:theSecret];
			
			[channel setEncryptionAlgorithm:algorithm];

			/* Finish up. */
			NSString *requestMsg = [TXExchangeResponsePrefix stringByAppendingString:publicKey];
			
			if (algorithm == CSFWBlowfishEncryptionCBCAlgorithm) {
				requestMsg = [requestMsg stringByAppendingString:@" CBC"];
			}

			[client sendText:[NSAttributedString emptyStringWithBase:requestMsg]
					 command:IRCPrivateCommandIndex("notice")
					 channel:channel
			  withEncryption:NO];

			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1010]", [channel name]) channel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1013]", [channel name]) channel:channel];
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1005]", [channel name]) channel:channel];
			
			if (algorithm == CSFWBlowfishEncryptionDefaultAlgorithm || algorithm == CSFWBlowfishEncryptionECBAlgorithm) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1017]") channel:channel];
			} else {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1018]") channel:channel];
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", [channel name]) channel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", [channel name]) channel:channel];
		}
	}
}

- (void)keyExchangeResponseReceived:(NSString *)responseDataRaw on:(IRCClient *)client from:(NSString *)responseKey
{
	NSArray *exchangeData = [self keyExchangeInformation:responseKey];

	if (exchangeData) {
		NSString *responseData = nil;
		
		CSFWBlowfishEncryptionAlgorithm algorithm = CSFWBlowfishEncryptionDefaultAlgorithm;

		if ([responseDataRaw length] > [TXExchangeResponsePrefix length]) {
			responseData = [responseDataRaw substringFromIndex:[TXExchangeResponsePrefix length]];
			
			NSArray *parts = [responseData split:NSStringWhitespacePlaceholder];
			
			responseData = parts[0];
			
			if ([parts count] > 1 && [parts[1] isEqualToString:@"CBC"]) {
				algorithm = CSFWBlowfishEncryptionCBCAlgorithm;
			}
		} else {
			responseData =  responseDataRaw;
		}
		
		//DebugLogToConsole(@"Key Exchange Response Received:");
		//DebugLogToConsole(@"	Response Key: %@", responseKey);
		//DebugLogToConsole(@"	Response Info: %@", exchangeData);
		//DebugLogToConsole(@"	Message: %@", responseData);

		CFDH1080 *request = exchangeData[0];
		
		IRCChannel *channel = exchangeData[1];
		
		if ([responseData length] <= 0) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1019]") channel:channel];
		} else {
			NSString *encryptionKey = [channel encryptionKey];
			
			if (encryptionKey) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1015]", [channel name]) channel:channel];
				
				return;
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1014]", [channel name]) channel:channel];
			
			/* Compute the public key received against our own. Our original public key
			 was sent to the user which has responded by computing their own against
			 that. Now we compute the key received to obtain the shared secret. What?… */
			NSString *theSecret = [request secretKeyFromPublicKey:responseData];
			
			if (NSObjectIsEmpty(theSecret)) {
				return [client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]") channel:channel];
			}
			
			//DebugLogToConsole(@"	Shared Secret: %@", theSecret);
			
			[channel setEncryptionKey:theSecret];
			
			[channel setEncryptionAlgorithm:algorithm];
			
			/* Finish up. */
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1005]", [channel name]) channel:channel];
			
			if (algorithm == CSFWBlowfishEncryptionDefaultAlgorithm || algorithm == CSFWBlowfishEncryptionECBAlgorithm) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1017]") channel:channel];
			} else {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1018]") channel:channel];
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", [channel name]) channel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", [channel name]) channel:channel];
		}
		
		[[self keyExchangeRequests] removeObjectForKey:responseKey];
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
		
		[[channel associatedClient] printDebugInformation:TPILocalizedString(@"BasicLanguage[1012]", [channel name]) channel:channel];

		[[self keyExchangeRequests] removeObjectForKey:requestKey];
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
	NSArray *requestData = [[self keyExchangeRequests] arrayForKey:requestKey];

	if (NSObjectIsNotEmpty(requestData)) {
		id request = requestData[0];
		id channel = requestData[1];

		if ([requestData count] == 2							&& // Array count is equal to 2.
			PointerIsNotEmpty( request )						&& // Pointer are not empty.
			PointerIsNotEmpty( channel )						&& // Pointer are not empty.
			PointerIsNotEmpty([channel associatedClient])		&& // Pointer are not empty.
			[request isKindOfClass:[CFDH1080 class]]			&& // Type of class is correct.
			[channel isKindOfClass:[IRCChannel class]]) {		   // Type of class is correct.

			return requestData;
		}
	}

	return nil;
}

- (NSString *)keyExchangeDictionaryKey:(IRCChannel *)channel
{
	if (PointerIsEmpty(channel) || [channel isPrivateMessage] == NO) {
		return nil;
	}
	
	return [NSString stringWithFormat:@"%@ –> %@", [channel uniqueIdentifier], [channel name]];
}

@end
