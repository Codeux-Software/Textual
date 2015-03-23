/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "TextualApplication.h"

/* TLOEncryptionManager class is a beast that should be avoided by
 plugins. Please use higher up APIs in IRCClient and elsewhere for 
 sending encrypted messages to one or more users. */

#define sharedEncryptionManager()			[TXSharedApplication sharedEncryptionManager]

#define TLOEncryptionManagerMenuItemTagStartPrivateConversation			9930 // "Start Private Conversation"
#define TLOEncryptionManagerMenuItemTagRefreshPrivateConversation		9931 // "Refresh Private Conversation"
#define TLOEncryptionManagerMenuItemTagEndPrivateConversation			9932 // "End Private Conversation"
#define TLOEncryptionManagerMenuItemTagAuthenticateChatPartner			9933 // "Authenticate Chat Partner"
#define TLOEncryptionManagerMenuItemTagViewListOfFingerprints			9934 // "View List of Fingerprints"

typedef void (^TLOEncryptionManagerInjectCallbackBlock)(NSString *encodedString);
typedef void (^TLOEncryptionManagerEncodingDecodingCallbackBlock)(NSString *originalString, BOOL wasEncrypted);

@interface TLOEncryptionManager : NSObject <OTRKitDelegate, OTRKitFingerprintManagerDialogDelegate>
/* Returns unique "account name" used for messageFrom and messageTo parameters. */
- (NSString *)accountNameWithUser:(NSString *)nickname onClient:(IRCClient *)client;

/* Converts the "account name" into its individual components. */
- (NSString *)nicknameFromAccountName:(NSString *)accountName;
- (IRCClient *)connectionFromAccountName:(NSString *)accountName;

/* Begin and end an encrypted conversation with a user. */
- (void)beginConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;
- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;
- (void)endConversationWith:(NSString *)messageTo from:(NSString *)messageFrom;

/* Socialist Millionaire Problem <http://en.wikipedia.org/wiki/Socialist_millionaire> */
- (void)authenticateUser:(NSString *)messageTo from:(NSString *)messageFrom;

/* Open dialog containing list of fingerprints. */
- (void)presentListOfFingerprints;

/* State information */
- (void)prepareForApplicationTermination;

- (void)updateLockIconButton:(id)button withStateOf:(NSString *)messageTo from:(NSString *)messageFrom;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem withStateOf:(NSString *)messageTo from:(NSString *)messageFrom;

/* Define configuration options */
- (void)setEncryptionPolicy:(OTRKitPolicy)policy;

/* Encryption/Decryption */
- (void)encryptMessage:(NSString *)messageBody
				  from:(NSString *)messageFrom
					to:(NSString *)messageTo
	  encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback
	 injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback;

- (void)decryptMessage:(NSString *)messageBody
				  from:(NSString *)messageFrom
					to:(NSString *)messageTo
	  decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback;
@end

/* The “weak ciphers” addition exists for backwards compatibility. */
/* It existence does not weaken Textual’s Off-the-Record implementation. */
/* It exists for Textual's "FiSH" plugin to hook into the encryption
 manager to accept encryption responsibilities when the user has a need
 to use those tools because of applications that do not support OTR. */
/* The weak cipher manager must be set before TLOEncryptionManager has
 been constructed so that TLOEncryptionManager knows not to hook into
 any features of Off-the-Record. Trying to set the weak cipher manager
 after the class is constructed with throw an exception. */
/* When set, all calls to -encryptMessage: and -decryptMessage: are
 proxied through to the “weak cipher manager” */

@interface TLOEncryptionManager (TLOEncryptionManagerWeakCiphers)
- (BOOL)usesWeakCiphers;

+ (void)setWeakCipherManager:(id)weakCipherManager;
@end
