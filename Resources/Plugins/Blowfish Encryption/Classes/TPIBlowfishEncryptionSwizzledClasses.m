/* *********************************************************************

        Copyright (c) 2010 - 2015 Codeux Software, LLC
     Please see ACKNOWLEDGEMENT for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of "Codeux Software, LLC", nor the names of its 
   contributors may be used to endorse or promote products derived 
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

#import "TPIBlowfishEncryption.h"
#import "TPIBlowfishEncryptionSwizzledClasses.h"

@implementation IRCClient (IRCClientSwizzled)

+ (void)load
{
	XRExchangeInstanceMethod(@"IRCClient", @"encryptionAllowedForNickname:", @"__tpi_encryptionAllowedForNickname:");
	XRExchangeInstanceMethod(@"IRCClient", @"decryptMessage:referenceMessage:decodingCallback:", @"__tpi_decryptMessage:referenceMessage:decodingCallback:");
	XRExchangeInstanceMethod(@"IRCClient", @"encryptMessage:directedAt:encodingCallback:injectionCallback:", @"__tpi_encryptMessage:directedAt:encodingCallback:injectionCallback:");
	XRExchangeInstanceMethod(@"IRCClient", @"lengthOfEncryptedMessageDirectedAt:thatFitsWithinBounds:", @"__tpi_lengthOfEncryptedMessageDirectedAt:thatFitsWithinBounds:");
}

- (BOOL)__tpi_encryptionAllowedForNickname:(NSString *)nickname
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		return NO;
	} else {
		return [self __tpi_encryptionAllowedForNickname:nickname];
	}
}

- (NSInteger)__tpi_lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSInteger)maximumLength
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		IRCChannel *targetChannel = [self findChannel:messageTo];

		if (targetChannel) {
			NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

			if (encryptionKey) {
				NSInteger lastEstimatedSize = 0;

				for (NSInteger i = maximumLength; i >= 0; i--) {
					NSInteger sizeForLength = [EKBlowfishEncryption estiminatedLengthOfEncodedDataOfLength:i];

					if (sizeForLength < maximumLength) {
						break;
					} else {
						lastEstimatedSize = i;
					}
				}

				return lastEstimatedSize;
			}
		}
	}

	return [self __tpi_lengthOfEncryptedMessageDirectedAt:messageTo thatFitsWithinBounds:maximumLength];
}

- (void)__tpi_encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
	if ([TPIBlowfishEncryption isPluginEnabled])
	{
		IRCChannel *targetChannel = [self findChannel:messageTo];

		if (targetChannel) {
			NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

			if (encryptionKey) {
				EKBlowfishEncryptionModeOfOperation decodeMode = [TPIBlowfishEncryption encryptionModeOfOperationForChannel:targetChannel];

				NSString *newstr = [EKBlowfishEncryption encodeData:messageBody key:encryptionKey mode:decodeMode encoding:NSUTF8StringEncoding];

				if ([newstr length] < 5) {
					[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1023]") inChannel:targetChannel];
				} else {
					if (encodingCallback) {
						encodingCallback(messageBody, YES);
					}

					if (injectionCallback) {
						injectionCallback(newstr);
					}
				}

				return; // Cancel operation...
			}
		}
	}

	[self __tpi_encryptMessage:messageBody directedAt:messageTo encodingCallback:encodingCallback injectionCallback:injectionCallback];
}

- (void)__tpi_decryptMessage:(NSString *)messageBody referenceMessage:(IRCMessage *)referenceMessage decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	if ([TPIBlowfishEncryption isPluginEnabled])
	{
		if ([messageBody hasPrefix:@"+OK "] || [messageBody hasPrefix:@"mcps"]) {
			NSString *target = [referenceMessage paramAt:0];

			NSString *sender = [referenceMessage senderNickname];

			IRCChannel *targetChannel = nil;

			if ([target isChannelNameOn:self]) {
				targetChannel = [self findChannel:target];
			} else {
				targetChannel = [self findChannel:sender];
			}

			if (targetChannel) {
				NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

				if (encryptionKey) {
					NSInteger lostBytes = 0;

					EKBlowfishEncryptionModeOfOperation decodeMode = [TPIBlowfishEncryption encryptionModeOfOperationForChannel:targetChannel];

					NSString *newstr = [EKBlowfishEncryption decodeData:messageBody key:encryptionKey mode:decodeMode encoding:NSUTF8StringEncoding lostBytes:&lostBytes];

					if (newstr == nil) {
						[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1022]") inChannel:targetChannel];
					} else {
						if (lostBytes > 0) {
							[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1031]", lostBytes) inChannel:targetChannel];
						}

						if (NSObjectIsNotEmpty(newstr)) {
							if (decodingCallback) {
								decodingCallback(newstr, YES);
							}
						}
					}

					return; // Cancel operation...
				}
			}
		}
	}

	[self __tpi_decryptMessage:messageBody referenceMessage:referenceMessage decodingCallback:decodingCallback];
}

@end

#pragma mark -

@implementation IRCChannel (IRCChannelSwizzled)

+ (void)load
{
	XRExchangeInstanceMethod(@"IRCChannel", @"prepareForApplicationTermination", @"__tpi_prepareForApplicationTermination");
	XRExchangeInstanceMethod(@"IRCChannel", @"prepareForPermanentDestruction", @"__tpi_prepareForPermanentDestruction");
}

- (void)__tpi_destroyEncryptionKeychain
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		if ([self isPrivateMessage]) {
			[TPIBlowfishEncryption setEncryptionKey:nil forChannel:self];
			[TPIBlowfishEncryption setEncryptionModeOfOperation:EKBlowfishEncryptionDefaultModeOfOperation forChannel:self];
		}
	}
}

- (void)__tpi_prepareForApplicationTermination
{
	[self __tpi_destroyEncryptionKeychain];

	[self __tpi_prepareForApplicationTermination];
}

- (void)__tpi_prepareForPermanentDestruction
{
	[self __tpi_destroyEncryptionKeychain];

	[self __tpi_prepareForPermanentDestruction];
}

@end

#pragma mark -

@implementation TPCPreferencesUserDefaults (TPIBlowfishEncryptionSwizzledPreferences)

static BOOL _offTheRecordWarningSheetDisplayed = NO;

+ (void)load
{
	XRExchangeInstanceMethod(@"TPCPreferencesUserDefaults", @"objectForKey:", @"__tpi_objectForKey:");
	XRExchangeInstanceMethod(@"TPCPreferencesUserDefaults", @"setObject:forKey:", @"__tpi_setObject:forKey:");
}

- (void)__tpi_setObject:(id)value forKey:(NSString *)defaultName
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		if ([defaultName hasPrefix:@"Off-the-Record Messaging -> "]) {
			if (_offTheRecordWarningSheetDisplayed == NO) {
				_offTheRecordWarningSheetDisplayed = YES;

				[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
												  body:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][2]")
												 title:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][1]")
										 defaultButton:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][3]")
									   alternateButton:nil
										   otherButton:nil
									   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
										   _offTheRecordWarningSheetDisplayed = NO;
									   }];
			}

			return; // Cancel operation...
		}
	}

	[self __tpi_setObject:value forKey:defaultName];
}

- (id)__tpi_objectForKey:(NSString *)defaultName
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		if ([defaultName hasPrefix:@"Off-the-Record Messaging -> "]) {
			return @(NO);
		}
	}

	return [self __tpi_objectForKey:defaultName];
}

@end
