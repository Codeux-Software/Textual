/* *********************************************************************
 *
 *         Copyright (c) 2015 - 2018 Codeux Software, LLC
 *     Please see ACKNOWLEDGEMENT for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of "Codeux Software, LLC", nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TPIBlowfishEncryption.h"

#import "TextualApplicationPrivate.h"

#define TXExchangeRequestPrefix				@"DH1080_INIT "
#define TXExchangeResponsePrefix			@"DH1080_FINISH "

#define TXExchangeReuqestTimeoutDelay		10

@interface TPIBlowfishEncryption ()
@property (nonatomic, strong) IBOutlet NSView *preferencePaneView;

/* 
	  key format:	STRING("<channel UUID> –> <remote nickname>")
	value format:	 ARRAY("<pointer to EKBlowfishEncryptionKeyExchange>", "<pointer to IRCChannel>")
 
	-keyExchangeDictionaryKey: can be used to generate key.
*/
@property (nonatomic, strong) NSMutableDictionary *keyExchangeRequests;

- (IBAction)preferencesChanged:(id)sender;
@end

@implementation TPIBlowfishEncryption

#pragma mark -
#pragma mark Plugin Structure

+ (BOOL)isPluginEnabled
{
	static BOOL _servicesEnabledChecked = NO;
	static BOOL _servicesEnabled = NO;

	if (_servicesEnabledChecked == NO) {
		_servicesEnabledChecked = YES;

		_servicesEnabled = [RZUserDefaults() boolForKey:@"Blowfish Encryption Extension -> Enable Service"];
	}

	return _servicesEnabled;
}

- (BOOL)isPluginEnabled
{
	return [TPIBlowfishEncryption isPluginEnabled];
}

- (void)pluginLoadedIntoMemory
{
	[self performBlockOnMainThread:^{
		[TPIBundleFromClass() loadNibNamed:@"TPIBlowfishEncryption" owner:self topLevelObjects:nil];
	}];

	if ([self isPluginEnabled]) {
		self.keyExchangeRequests = [NSMutableDictionary dictionary];
	}
}

- (void)pluginWillBeUnloadedFromMemory
{
	if ([self isPluginEnabled]) {
		self.keyExchangeRequests = nil;

		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizedString(@"BasicLanguage[1028]");
}

- (NSView *)pluginPreferencesPaneView
{
	return self.preferencePaneView;
}

- (void)preferencesChanged:(id)sender
{
	[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
									  body:TPILocalizedString(@"BasicLanguage[1027][2]")
									 title:TPILocalizedString(@"BasicLanguage[1027][1]")
							 defaultButton:TPILocalizedString(@"BasicLanguage[1027][3]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client
{
	if ([self isPluginEnabled] == NO) {
		return; // Cancel operation...
	}

	[self performBlockOnMainThread:^{
		NSString *person = [inputObject senderNickname];

		NSString *message = [inputObject messageSequence];

		if ([message hasPrefix:@"+"]) {
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
		if ([self isPluginEnabled] == NO) {
			(void)[TLOPopupPrompts dialogWindowWithMessage:TPILocalizedString(@"BasicLanguage[1030][2]", [commandString lowercaseString])
													 title:TPILocalizedString(@"BasicLanguage[1030][1]")
											 defaultButton:TPILocalizedString(@"BasicLanguage[1030][3]")
										   alternateButton:nil
											suppressionKey:nil
										   suppressionText:nil];

			return; // Cancel operation...
		}

		IRCChannel *c = [mainWindow() selectedChannelOn:client];
		
		if ([c isChannel] || [c isPrivateMessage]) {
			NSString *_messageString = [messageString trimAndGetFirstToken];

			NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:c];
			
			if ([commandString isEqualToString:@"SETKEY"]) {
				if (NSObjectIsEmpty(_messageString)) {
					[TPIBlowfishEncryption setEncryptionKey:nil forChannel:c];
					
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1026]") inChannel:c];
				} else {
					if (NSObjectIsNotEmpty(encryptionKey)) {
						if ([encryptionKey isEqualToString:_messageString] == NO) {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1024]") inChannel:c];
						}
					} else {
						if ([c isPrivateMessage]) {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1002]") inChannel:c];
						} else {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1025]") inChannel:c];
						}
					}

					if ([_messageString length] > 56) {
						 _messageString = [_messageString substringToIndex:56];

						[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1032]") inChannel:c];
					}

					[TPIBlowfishEncryption setEncryptionKey:_messageString forChannel:c];
				}
			} else if ([commandString isEqualToString:@"DELKEY"]) {
				[TPIBlowfishEncryption setEncryptionKey:nil forChannel:c];
				
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1026]") inChannel:c];
			} else if ([commandString isEqualToString:@"KEY"]) {
				if (NSObjectIsNotEmpty(encryptionKey)) {
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]", encryptionKey) inChannel:c];
				} else {	
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]") inChannel:c];
				}
			} else if ([commandString isEqualToString:@"SETKEYMODE"]) {
				if ([_messageString isEqualIgnoringCase:@"CBC"]) {
					[TPIBlowfishEncryption setEncryptionModeOfOperation:EKBlowfishEncryptionCBCModeOfOperation forChannel:c];
					
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1020]") inChannel:c];
				} else {
					[TPIBlowfishEncryption setEncryptionModeOfOperation:EKBlowfishEncryptionECBModeOfOperation forChannel:c];
					
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1021]") inChannel:c];
				}
			} else if ([commandString isEqualToString:@"KEYX"]) {
				if ([c isPrivateMessage] == NO) {
					[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1008]") inChannel:c];
				} else {
					if ([self keyExchangeRequestExists:c]) {
						[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1009]", [c name]) inChannel:c];
					} else if (NSObjectIsNotEmpty(encryptionKey)) {
						[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1016]", [c name]) inChannel:c];
					} else {
						EKBlowfishEncryptionKeyExchange *keyRequest = [EKBlowfishEncryptionKeyExchange new];

						NSString *publicKey = [keyRequest generatePublicKey];

						if (NSObjectIsEmpty(publicKey)) {
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]") inChannel:c];
						} else {
							NSString *requestKey = [self keyExchangeDictionaryKey:c];
							
							NSString *requestMsg = nil;
							
							if ([_messageString isEqualIgnoringCase:@"nocbc"]) {
								requestMsg = [NSString stringWithFormat:@"%@%@", TXExchangeRequestPrefix, publicKey];
							} else {
								requestMsg = [NSString stringWithFormat:@"%@%@ CBC", TXExchangeRequestPrefix, publicKey];
							}

							[[self keyExchangeRequests] setObject:@[keyRequest, c] forKey:requestKey];

							[client send:@"NOTICE", [c name], requestMsg, nil];

							[self keyExchangeSetupTimeoutTimer:requestKey];
							
							[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1011]", [c name]) inChannel:c];
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

- (NSArray *)pluginOutputSuppressionRules
{
    /* Rule 1 */
    THOPluginOutputSuppressionRule *noticeRule1 = [THOPluginOutputSuppressionRule new];
    
    [noticeRule1 setRestrictConsole:YES];
    [noticeRule1 setRestrictChannel:YES];
    [noticeRule1 setRestrictPrivateMessage:YES];

    [noticeRule1 setMatch:[@"^" stringByAppendingString:TXExchangeRequestPrefix]];
    
    /* Rule 2 */
    THOPluginOutputSuppressionRule *noticeRule2 = [THOPluginOutputSuppressionRule new];
    
    [noticeRule2 setRestrictConsole:YES];
    [noticeRule2 setRestrictChannel:YES];
    [noticeRule2 setRestrictPrivateMessage:YES];
    
    [noticeRule2 setMatch:[@"^" stringByAppendingString:TXExchangeResponsePrefix]];
    
    
    return @[noticeRule1, noticeRule2];
}

#pragma mark -
#pragma mark Options

+ (void)setEncryptionKey:(NSString *)encryptionKey forChannel:(IRCChannel *)channel
{
	if (channel) {
		NSString *serviceName = [NSString stringWithFormat:@"textual.cblowfish.%@", [channel uniqueIdentifier]];

		if (encryptionKey == nil) {
			[XRKeychain deleteKeychainItem:@"Textual (Blowfish Encryption)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:serviceName];

			[[channel viewController] setEncrypted:NO];
		} else {
			[XRKeychain modifyOrAddKeychainItem:@"Textual (Blowfish Encryption)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:encryptionKey
									serviceName:serviceName];

			[[channel viewController] setEncrypted:YES];
		}
	}
}

+ (NSString *)encryptionKeyForChannel:(IRCChannel *)channel
{
	if (channel) {
		NSString *serviceName = [NSString stringWithFormat:@"textual.cblowfish.%@", [channel uniqueIdentifier]];

		return [XRKeychain getPasswordFromKeychainItem:@"Textual (Blowfish Encryption)"
										  withItemKind:@"application password"
										   forUsername:nil
										   serviceName:serviceName];
	} else {
		return nil;
	}
}

+ (void)setEncryptionModeOfOperation:(EKBlowfishEncryptionModeOfOperation)modeOfOperation forChannel:(IRCChannel *)channel
{
	if (channel) {
		NSString *defaultsKey = [NSString stringWithFormat:@"Private Extension Store -> Blowfish Encryption Extension -> Encryption Mode of Operation -> %@", [channel uniqueIdentifier]];

		if (modeOfOperation == EKBlowfishEncryptionDefaultModeOfOperation) {
			[RZUserDefaults() removeObjectForKey:defaultsKey];
		} else {
			[RZUserDefaults() setInteger:modeOfOperation forKey:defaultsKey];
		}
	}
}

+ (EKBlowfishEncryptionModeOfOperation)encryptionModeOfOperationForChannel:(IRCChannel *)channel
{
	if (channel) {
		NSString *defaultsKey = [NSString stringWithFormat:@"Private Extension Store -> Blowfish Encryption Extension -> Encryption Mode of Operation -> %@", [channel uniqueIdentifier]];

		id defaultsValue = [RZUserDefaults() objectForKey:defaultsKey];

		if (defaultsValue) {
			return (EKBlowfishEncryptionModeOfOperation)[defaultsValue integerValue];
		} else {
			return EKBlowfishEncryptionDefaultModeOfOperation;
		}
	} else {
		return EKBlowfishEncryptionNoneModeOfOperation;
	}
}

#pragma mark -
#pragma mark Key Exchange

- (void)keyExchangeRequestReceived:(NSString *)requestDataRaw on:(IRCClient *)client from:(NSString *)requestSender
{
	IRCChannel *channel = [client findChannelOrCreate:requestSender isPrivateMessage:YES];
	
	NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:channel];
	
    if (NSObjectIsNotEmpty(encryptionKey)) {
        [client printDebugInformation:TPILocalizedString(@"BasicLanguage[1015]", [channel name]) inChannel:channel];

        return;
    }
	
	EKBlowfishEncryptionModeOfOperation mode = EKBlowfishEncryptionDefaultModeOfOperation;

	NSString *requestData = nil;
	
	if ([requestDataRaw length] > [TXExchangeRequestPrefix length]) {
		requestData = [requestDataRaw substringFromIndex:[TXExchangeRequestPrefix length]];
		
		NSArray *parts = [requestData split:NSStringWhitespacePlaceholder];
		
		requestData = parts[0];
		
		if ([parts count] > 1 && [parts[1] isEqualToString:@"CBC"]) {
			mode = EKBlowfishEncryptionCBCModeOfOperation;
		}
	} else {
		requestData =  requestDataRaw;
	}

	//LogToConsoleDebug("Key Exchange Request Received:");
	//LogToConsoleDebug("	Client: %@", client);
	//LogToConsoleDebug("	Channel: %@", channel);
	//LogToConsoleDebug("	Message: %@", requestData);
	
	if ([requestData length] <= 0) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1019]") inChannel:channel];
	} else {
		if ([self keyExchangeRequestExists:channel]) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1010]", [channel name]) inChannel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1009]", [channel name]) inChannel:channel];
		} else {
			EKBlowfishEncryptionKeyExchange *keyRequest = [EKBlowfishEncryptionKeyExchange new];

			/* Process secret from the Receiver. */
			NSString *theSecret = [keyRequest secretKeyFromPublicKey:requestData];

			if (NSObjectIsEmpty(theSecret)) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]") inChannel:channel];

				return;
			}

			/* Generate our own public key. If everything has gone correctly up to here,
			 then when the user that sent the request computes our public key, we both
			 should have the same secret. */
			NSString *publicKey = [keyRequest generatePublicKey];

			if (NSObjectIsEmpty(publicKey)) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]") inChannel:channel];

				return;
			}

			//LogToConsoleDebug("	Shared Secret: %@", theSecret);

			[TPIBlowfishEncryption setEncryptionKey:theSecret forChannel:channel];
			[TPIBlowfishEncryption setEncryptionModeOfOperation:mode forChannel:channel];

			/* Finish up. */
			NSString *requestMsg = [TXExchangeResponsePrefix stringByAppendingString:publicKey];
			
			if (mode == EKBlowfishEncryptionCBCModeOfOperation) {
				requestMsg = [requestMsg stringByAppendingString:@" CBC"];
			}

			[client send:@"NOTICE", [channel name], requestMsg, nil];

			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1010]", [channel name]) inChannel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1013]", [channel name]) inChannel:channel];
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1005]", [channel name]) inChannel:channel];
			
			if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1017]") inChannel:channel];
			} else {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1018]") inChannel:channel];
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", [channel name]) inChannel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", [channel name]) inChannel:channel];
		}
	}
}

- (void)keyExchangeResponseReceived:(NSString *)responseDataRaw on:(IRCClient *)client from:(NSString *)responseKey
{
	NSArray *exchangeData = [self keyExchangeInformation:responseKey];

	if (exchangeData) {
		NSString *responseData = nil;
		
		EKBlowfishEncryptionModeOfOperation mode = EKBlowfishEncryptionDefaultModeOfOperation;

		if ([responseDataRaw length] > [TXExchangeResponsePrefix length]) {
			responseData = [responseDataRaw substringFromIndex:[TXExchangeResponsePrefix length]];
			
			NSArray *parts = [responseData split:NSStringWhitespacePlaceholder];
			
			responseData = parts[0];
			
			if ([parts count] > 1 && [parts[1] isEqualToString:@"CBC"]) {
				mode = EKBlowfishEncryptionCBCModeOfOperation;
			}
		} else {
			responseData =  responseDataRaw;
		}
		
		//LogToConsoleDebug("Key Exchange Response Received:");
		//LogToConsoleDebug("	Response Key: %@", responseKey);
		//LogToConsoleDebug("	Response Info: %@", exchangeData);
		//LogToConsoleDebug("	Message: %@", responseData);

		EKBlowfishEncryptionKeyExchange *request = exchangeData[0];
		
		IRCChannel *channel = exchangeData[1];
		
		if ([responseData length] <= 0) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1019]") inChannel:channel];
		} else {
			NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:channel];
			
			if (NSObjectIsNotEmpty(encryptionKey)) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1015]", [channel name]) inChannel:channel];
				
				return;
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1014]", [channel name]) inChannel:channel];
			
			/* Compute the public key received against our own. Our original public key
			 was sent to the user which has responded by computing their own against
			 that. Now we compute the key received to obtain the shared secret. What?… */
			NSString *theSecret = [request secretKeyFromPublicKey:responseData];
			
			if (NSObjectIsEmpty(theSecret)) {
				return [client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]") inChannel:channel];
			}
			
			//LogToConsoleDebug("	Shared Secret: %@", theSecret);

			[TPIBlowfishEncryption setEncryptionKey:theSecret forChannel:channel];
			[TPIBlowfishEncryption setEncryptionModeOfOperation:mode forChannel:channel];
			
			/* Finish up. */
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1005]", [channel name]) inChannel:channel];
			
			if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1017]") inChannel:channel];
			} else {
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1018]") inChannel:channel];
			}
			
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1006]", [channel name]) inChannel:channel];
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1007]", [channel name]) inChannel:channel];
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
		
		[[channel associatedClient] printDebugInformation:TPILocalizedString(@"BasicLanguage[1012]", [channel name]) inChannel:channel];

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

		if ([requestData count] == 2												&& // Array count is equal to 2.
			PointerIsNotEmpty( request )											&& // Pointer are not empty.
			PointerIsNotEmpty( channel )											&& // Pointer are not empty.
			PointerIsNotEmpty([channel associatedClient])							&& // Pointer are not empty.
			[request isKindOfClass:[EKBlowfishEncryptionKeyExchange class]]			&& // Type of class is correct.
			[channel isKindOfClass:[IRCChannel class]]) {							   // Type of class is correct.

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
