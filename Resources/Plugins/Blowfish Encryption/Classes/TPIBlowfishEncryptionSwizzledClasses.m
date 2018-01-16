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
	XRExchangeInstanceMethod(@"IRCClient", @"encryptionAllowedForTarget:", @"__tpi_encryptionAllowedForTarget:");
	XRExchangeInstanceMethod(@"IRCClient", @"decryptMessage:from:target:decodingCallback:", @"__tpi_decryptMessage:from:target:decodingCallback:");
	XRExchangeInstanceMethod(@"IRCClient", @"encryptMessage:directedAt:encodingCallback:injectionCallback:", @"__tpi_encryptMessage:directedAt:encodingCallback:injectionCallback:");
	XRExchangeInstanceMethod(@"IRCClient", @"lengthOfEncryptedMessageDirectedAt:thatFitsWithinBounds:", @"__tpi_lengthOfEncryptedMessageDirectedAt:thatFitsWithinBounds:");
}

- (BOOL)__tpi_encryptionAllowedForTarget:(NSString *)target
{
	if ([TPIBlowfishEncryption isPluginEnabled] == NO) {
		return [self __tpi_encryptionAllowedForTarget:target];
	}

	return NO;
}

- (NSInteger)__tpi_lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSInteger)maximumLength
{
	if ([TPIBlowfishEncryption isPluginEnabled] == NO) {
		return [self __tpi_lengthOfEncryptedMessageDirectedAt:messageTo thatFitsWithinBounds:maximumLength];
	}

	IRCChannel *targetChannel = [self findChannel:messageTo];

	if (targetChannel == nil) {
		return 0;
	}

	NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

	if (encryptionKey == nil) {
		return 0;
	}

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

- (void)__tpi_encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
#define _callback(_encodedString_, _wasEncrypted_) 	\
	if (encodingCallback) { 	\
		encodingCallback(messageBody, _wasEncrypted_); 	\
	} 	\
	if (injectionCallback) { 	\
		injectionCallback(_encodedString_); 	\
	} 	\

	if ([TPIBlowfishEncryption isPluginEnabled] == NO) {
		[self __tpi_encryptMessage:messageBody directedAt:messageTo encodingCallback:encodingCallback injectionCallback:injectionCallback];

		return;
	}

	IRCChannel *targetChannel = [self findChannel:messageTo];

	if (targetChannel == nil) {
		_callback(messageBody, NO);

		return;
	}

	NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

	if (encryptionKey == nil) {
		_callback(messageBody, NO);

		return;
	}

	EKBlowfishEncryptionModeOfOperation decodeMode = [TPIBlowfishEncryption encryptionModeOfOperationForChannel:targetChannel];

	NSString *encodedString = [EKBlowfishEncryption encodeData:messageBody key:encryptionKey mode:decodeMode encoding:NSUTF8StringEncoding];

	if ([encodedString length] < 5) {
		[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1023]") inChannel:targetChannel];

		return;
	}

	_callback(encodedString, YES);

#undef _callback
}

- (void)__tpi_decryptMessage:(NSString *)messageBody from:(NSString *)messageFrom target:(NSString *)target decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
#define _callback(_decodedString_, _wasEncrypted_) 	\
	if (decodingCallback) { 	\
		decodingCallback(_decodedString_, _wasEncrypted_); 	\
	}

	if ([TPIBlowfishEncryption isPluginEnabled] == NO) {
		[self __tpi_decryptMessage:messageBody from:messageFrom target:target decodingCallback:decodingCallback];

		return;
	}

	if ([messageBody hasPrefix:@"+OK "] == NO &&
		[messageBody hasPrefix:@"mcps"] == NO)
	{
		_callback(messageBody, NO);

		return;
	}

	IRCChannel *targetChannel = nil;

	if ([self stringIsChannelName:target]) {
		targetChannel = [self findChannel:target];
	} else {
		targetChannel = [self findChannel:messageFrom];
	}

	if (targetChannel == nil) {
		_callback(messageBody, NO);

		return;
	}

	NSString *encryptionKey = [TPIBlowfishEncryption encryptionKeyForChannel:targetChannel];

	if (encryptionKey == nil) {
		_callback(messageBody, NO);

		return;
	}

	NSInteger lostBytes = 0;

	EKBlowfishEncryptionModeOfOperation decodeMode = [TPIBlowfishEncryption encryptionModeOfOperationForChannel:targetChannel];

	NSString *decodedString = [EKBlowfishEncryption decodeData:messageBody key:encryptionKey mode:decodeMode encoding:NSUTF8StringEncoding lostBytes:&lostBytes];

	if (decodedString == nil) {
		[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1022]") inChannel:targetChannel];

		return;
	}

	if (lostBytes > 0) {
		[self printDebugInformation:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1031]", lostBytes) inChannel:targetChannel];

		/* Do not return for this. This is not a fatal error. */
	}

	_callback(decodedString, YES);

#undef _callback
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
	if ([TPIBlowfishEncryption isPluginEnabled] == NO) {
		return;
	}

	if ([self isPrivateMessage] == NO) {
		return;
	}

	[TPIBlowfishEncryption setEncryptionKey:nil forChannel:self];

	[TPIBlowfishEncryption setEncryptionModeOfOperation:EKBlowfishEncryptionDefaultModeOfOperation forChannel:self];
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

+ (void)load
{
	XRExchangeInstanceMethod(@"TPCPreferencesUserDefaults", @"objectForKey:", @"__tpi_objectForKey:");
	XRExchangeInstanceMethod(@"TPCPreferencesUserDefaults", @"setObject:forKey:", @"__tpi_setObject:forKey:");
}

- (void)__tpi_setObject:(id)value forKey:(NSString *)defaultName
{
	if ([TPIBlowfishEncryption isPluginEnabled]) {
		if ([defaultName hasPrefix:@"Off-the-Record Messaging -> "]) {
			static dispatch_once_t onceToken;

			dispatch_once(&onceToken, ^{
				[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
												  body:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][2]")
												 title:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][1]")
										 defaultButton:TXLocalizedStringAlternative([NSBundle bundleForClass:[TPIBlowfishEncryption class]], @"BasicLanguage[1029][3]")
									   alternateButton:nil
										   otherButton:nil];
			});

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
