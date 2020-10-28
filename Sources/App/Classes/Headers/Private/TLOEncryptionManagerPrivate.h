/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
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
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
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

#import <EncryptionKit/EncryptionKit.h>

#import "TLOEncryptionManager.h"

NS_ASSUME_NONNULL_BEGIN

@class IRCClient, TVCMainWindowTitlebarAccessoryViewLockButton;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
#define sharedEncryptionManager()			[TXSharedApplication sharedEncryptionManager]
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@interface TLOEncryptionManager : NSObject
/* Returns unique "account name" used for messageFrom and messageTo parameters */
- (NSString *)accountNameForUser:(NSString *)nickname onClient:(IRCClient *)client;

/* Converts the "account name" into its individual components */
- (nullable NSString *)nicknameFromAccountName:(NSString *)accountName;
- (nullable IRCClient *)connectionFromAccountName:(NSString *)accountName;

/* Begin and end an encrypted conversation with a user */
- (void)beginConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;
- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;
- (void)endConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;

/* Socialist Millionaire Problem <http://en.wikipedia.org/wiki/Socialist_millionaire> */
- (void)authenticateUser:(NSString *)messageTo from:(NSString *)messageFrom;

/* Open dialog containing list of fingerprints */
- (void)presentListOfFingerprints;

/* State information */
- (OTRKitMessageState)messageStateFor:(NSString *)messageTo from:(NSString *)messageFrom;

- (void)updateLockIconButton:(TVCMainWindowTitlebarAccessoryViewLockButton *)button withStateOf:(NSString *)messageTo from:(NSString *)messageFrom;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem withStateOf:(NSString *)messageTo from:(NSString *)messageFrom;

- (BOOL)safeToTransferFile:(NSString *)filename to:(NSString *)messageTo from:(NSString *)messageFrom isIncomingFileTransfer:(BOOL)isIncomingFileTransfer;

/* Define configuration options */
- (void)updatePolicy;

/* Encryption/Decryption */
- (void)encryptMessage:(NSString *)messageBody
				  from:(NSString *)messageFrom
					to:(NSString *)messageTo
	  encodingCallback:(nullable TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback
	 injectionCallback:(nullable TLOEncryptionManagerInjectCallbackBlock)injectionCallback;

- (void)decryptMessage:(NSString *)messageBody
				  from:(NSString *)messageFrom
					to:(NSString *)messageTo
	  decodingCallback:(nullable TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback;
@end
#endif

NS_ASSUME_NONNULL_END
