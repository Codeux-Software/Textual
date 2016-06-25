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

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@interface TLOEncryptionManager ()
@property (nonatomic, strong) OTRKitFingerprintManagerDialog *fingerprintManagerDialog;
@end

@interface TLOEncryptionManagerEncodingDecodingObject : NSObject
// Properties that should be manipulated to provide context information
@property (nonatomic, copy) TLOEncryptionManagerEncodingDecodingCallbackBlock encodingCallback;
@property (nonatomic, copy) TLOEncryptionManagerInjectCallbackBlock injectionCallback;
@property (nonatomic, copy) NSString *messageFrom;
@property (nonatomic, copy) NSString *messageTo;
@property (nonatomic, copy) NSString *messageBody; // unencrypted value
@end

@implementation TLOEncryptionManager

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		[self setupEncryptionManager];

		return self;
	}

	return nil;
}

- (NSString *)pathToStoreEncryptionSecrets
{
	NSString *cachesFolder = [TPCPathInfo applicationSupportFolderPathInGroupContainer];

	if (cachesFolder == nil) {
		return nil;
	}

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Encryption Components/"];

	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	return dest;
}

- (void)setupEncryptionManager
{
	OTRKit *otrKit = [OTRKit sharedInstance];

	[otrKit setDelegate:self];

	[otrKit setAccountNameSeparator:@"@"];

	[otrKit setupWithDataPath:[self pathToStoreEncryptionSecrets]];

	[self prepareEncryptionComponentPath:[otrKit privateKeyPath]];
	[self prepareEncryptionComponentPath:[otrKit fingerprintsPath]];
	[self prepareEncryptionComponentPath:[otrKit instanceTagsPath]];

	NSURL *componentPathURL = [NSURL fileURLWithPath:[self pathToStoreEncryptionSecrets] isDirectory:YES];

	NSError *attributesChangeError = nil;

	if ([componentPathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&attributesChangeError] == NO) {
		LogToConsoleError("Failed to hide the folder at the path '%{public}@': %{public}@", componentPathURL, [attributesChangeError localizedDescription])
	}

	[otrKit setMaximumProtocolSize:[self otrKitProtocolMaximumMessageSize]
					   forProtocol:[self otrKitProtocol]];

	[self updatePolicy];
}

- (void)prepareEncryptionComponentPath:(NSString *)path
{
	/* Create the path if it does not already exist. */
	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		NSError *writeError = nil;

		if ([NSStringEmptyPlaceholder writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&writeError] == NO) {
			LogToConsoleError("Failed to create base file for encryption component at path: %@", [writeError localizedDescription])
		}
	}

	/* Files are stored in a location that is accessible to Time Machine
	 which means we must mark the files to not be backed up. */
	NSURL *pathURL = [NSURL fileURLWithPath:path isDirectory:NO];

	NSError *attributesChangeError = nil;

	if ([pathURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&attributesChangeError] == NO) {
		LogToConsoleError("Failed to exclude the files at the path '%{public}@' from backup: %{public}@", pathURL, [attributesChangeError localizedDescription])
	}
}

- (void)prepareForApplicationTermination
{
	;
}

#pragma mark -
#pragma mark Fingerprint Manager

- (void)presentListOfFingerprints
{
	if ([self fingerprintManagerDialog] == nil) {
		OTRKitFingerprintManagerDialog *dialog = [OTRKitFingerprintManagerDialog new];

		[dialog setDelegate:self];

		[self setFingerprintManagerDialog:dialog];
	}

	[[self fingerprintManagerDialog] open:mainWindow()];
}

#pragma mark -
#pragma mark Account Name Information

- (NSString *)accountNameWithUser:(NSString *)nickname onClient:(IRCClient *)client
{
	PointerIsEmptyAssertReturn(nickname, nil)
	PointerIsEmptyAssertReturn(client, nil)

	return [NSString stringWithFormat:@"%@%@%@", nickname, [[OTRKit sharedInstance] accountNameSeparator], [client uniqueIdentifier]];
}

- (NSString *)nicknameFromAccountName:(NSString *)accountName
{
	NSString *nickname = [[OTRKit sharedInstance] leftPortionOfAccountName:accountName];

	return nickname;
}

- (IRCClient *)connectionFromAccountName:(NSString *)accountName
{
	NSString *clientIdentifier = [[OTRKit sharedInstance] rightPortionOfAccountName:accountName];

	return [worldController() findClientWithId:clientIdentifier];
}

#pragma mark -
#pragma mark Starting Encryption & Stopping Encryption

- (void)beginConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	[self refreshConversationWith:messageTo from:messageFrom presentMessage:TXTLS(@"OffTheRecord[1006]")];
}

- (void)endConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		[[OTRKit sharedInstance] disableEncryptionWithUsername:messageTo
												   accountName:messageFrom
													  protocol:[self otrKitProtocol]];
	} else {
		[self presentErrorMessage:TXTLS(@"OffTheRecord[1009]") withAccountName:messageTo];
	}
}

- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	[self refreshConversationWith:messageTo from:messageFrom presentMessage:TXTLS(@"OffTheRecord[1005]")];
}

- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom presentMessage:(NSString *)message
{
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)

	[self presentMessage:message withAccountName:messageTo];

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		[[OTRKit sharedInstance] disableEncryptionWithUsername:messageTo
												   accountName:messageFrom
													  protocol:[self otrKitProtocol]];
	}

	[[OTRKit sharedInstance] initiateEncryptionWithUsername:messageTo
												accountName:messageFrom
												   protocol:[self otrKitProtocol]];
}

#pragma mark -
#pragma mark Socialist Millionaire

- (void)authenticateUser:(NSString *)messageTo from:(NSString *)messageFrom
{
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		[OTRKitAuthenticationDialog requestAuthenticationForUsername:messageTo
														 accountName:messageFrom
															protocol:[self otrKitProtocol]];
	} else {
		[self presentErrorMessage:TXTLS(@"OffTheRecord[1008]") withAccountName:messageTo];
	}
}

#pragma mark -
#pragma mark Encryption & Decryption

- (void)decryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)
	PointerIsEmptyAssert(messageBody)

	TLOEncryptionManagerEncodingDecodingObject *messageObject = [TLOEncryptionManagerEncodingDecodingObject new];

	[messageObject setMessageTo:messageTo];
	[messageObject setMessageFrom:messageFrom];
	[messageObject setMessageBody:messageBody];

	[messageObject setEncodingCallback:decodingCallback];

	[[OTRKit sharedInstance] decodeMessage:messageBody
								  username:messageFrom
							   accountName:messageTo
								  protocol:[self otrKitProtocol]
									   tag:messageObject];
}

- (void)encryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)
	PointerIsEmptyAssert(messageBody)

	/*
	 If we are not performing encryption automatically and we are not in an encrypted
	 conversation, then manually invoke blocks at this point and do not message OTRKit.
	 This exception is made because when OTRL_POLICY_MANUAL is set, OTR discards outgoing
	 messages altogther. 
	 
	 If we allow automatic OTR, then we hae to check whether the OTR request was rejected.
	 If it was, then we manually send the message because OTR will refuse to once it has
	 been rejected. 
	 */
	BOOL isManualPolicy = ([[OTRKit sharedInstance] otrPolicy] == OTRKitPolicyManual ||
						   [[OTRKit sharedInstance] otrPolicy] == OTRKitPolicyNever);

	BOOL isRejectedOffer = ([[OTRKit sharedInstance] offerStateForUsername:messageTo
															   accountName:messageFrom
																  protocol:[self otrKitProtocol]] == OTRKitOfferStateRejected &&

							[[OTRKit sharedInstance] otrPolicy] == OTRKitPolicyOpportunistic);

	if (isRejectedOffer || isManualPolicy)
	{
		OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																			   accountName:messageFrom
																				  protocol:[self otrKitProtocol]];

		if (currentState == OTRKitMessageStatePlaintext) {
			if (encodingCallback) {
				encodingCallback(messageBody, NO);
			}

			if (injectionCallback) {
				injectionCallback(messageBody);
			}

			return; // Cancel operation...
		}
	}

	/* Pass message off to OTRKit */
	TLOEncryptionManagerEncodingDecodingObject *messageObject = [TLOEncryptionManagerEncodingDecodingObject new];

	[messageObject setMessageTo:messageTo];
	[messageObject setMessageFrom:messageFrom];
	[messageObject setMessageBody:messageBody];

	[messageObject setEncodingCallback:encodingCallback];
	[messageObject setInjectionCallback:injectionCallback];

	[[OTRKit sharedInstance] encodeMessage:messageBody
									  tlvs:nil
								  username:messageTo
							   accountName:messageFrom
								  protocol:[self otrKitProtocol]
									   tag:messageObject];
}

#pragma mark -
#pragma mark Helper Methods

- (OTRKitMessageState)messageStateFor:(NSString *)messageTo from:(NSString *)messageFrom
{
	PointerIsEmptyAssertReturn(messageTo, OTRKitMessageStatePlaintext);
	PointerIsEmptyAssertReturn(messageFrom, OTRKitMessageStatePlaintext);

	OTRKitMessageState currentState =
		[[OTRKit sharedInstance] messageStateForUsername:messageTo
											 accountName:messageFrom
												protocol:[self otrKitProtocol]];

	return currentState;
}

- (BOOL)safeToTransferFile:(NSString *)filename to:(NSString *)messageTo from:(NSString *)messageFrom isIncomingFileTransfer:(BOOL)isIncomingFileTransfer
{
	PointerIsEmptyAssertReturn(messageTo, NO)
	PointerIsEmptyAssertReturn(messageFrom, NO)

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		if (isIncomingFileTransfer) {
			BOOL continueop = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1132][2]")
																 title:TXTLS(@"Prompts[1132][1]", filename)
														 defaultButton:TXTLS(@"Prompts[0004]")
													   alternateButton:TXTLS(@"Prompts[1132][3]")];

			return (continueop == NO);
		} else {
			NSString *nickname = [self nicknameFromAccountName:messageTo];

			BOOL continueop = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1133][2]")
																 title:TXTLS(@"Prompts[1133][1]", filename, nickname)
														 defaultButton:TXTLS(@"Prompts[0004]")
													   alternateButton:TXTLS(@"Prompts[1133][3]")];

			return (continueop == NO);
		}
	}

	return YES;
}

- (void)updateLockIconButton:(id)button withStateOf:(NSString *)messageTo from:(NSString *)messageFrom
{
	PointerIsEmptyAssert(button)
	PointerIsEmptyAssert(messageTo)
	PointerIsEmptyAssert(messageFrom)

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		BOOL hasVerifiedKey = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:messageTo
																				  accountName:messageFrom
																					 protocol:[self otrKitProtocol]];

		if (hasVerifiedKey) {
			[button setTitle:TXTLS(@"OffTheRecord[1011][3]")];

			[button setIconAsLocked];
		} else {
			[button setTitle:TXTLS(@"OffTheRecord[1011][2]")];

			/* Even though we are encrypted, our icon is still set to unlocked because
			 the identity of messageTo still has not been authenticated. */
			[button setIconAsUnlocked];
		}
	} else {
		[button setTitle:TXTLS(@"OffTheRecord[1011][1]")];

		[button setIconAsUnlocked];
	}
}

- (void)performBlockInRelationToAccountName:(NSString *)accountName block:(void (^)(NSString *nickname, IRCClient *client, IRCChannel *channel))block
{
	[self performBlockOnMainThread:^{
		NSString *nickname = [self nicknameFromAccountName:accountName];

		IRCClient *client = [self connectionFromAccountName:accountName];

		if (client == nil) {
			LogToConsoleError("-connectionFromAccountName: returned a nil value, failing")
		} else {
			IRCChannel *channel = [client findChannelOrCreate:nickname isPrivateMessage:YES];

			block(nickname, client, channel);
		}
	}];
}

- (NSString *)localizedStringForEvent:(OTRKitMessageEvent)event
{
	NSString *localeKey = nil;

#define _dv(event, localInt)		case (event): { localeKey = (localInt); break; }

	switch (event) {
		_dv(OTRKitMessageEventEncryptionRequired,				@"01")
		_dv(OTRKitMessageEventEncryptionError,					@"02")
		_dv(OTRKitMessageEventConnectionEnded,					@"03")
		_dv(OTRKitMessageEventSetupError,						@"04")
		_dv(OTRKitMessageEventMessageReflected,					@"05")
		_dv(OTRKitMessageEventMessageResent,					@"06")
		_dv(OTRKitMessageEventReceivedMessageNotInPrivate,		@"07")
		_dv(OTRKitMessageEventReceivedMessageUnreadable,		@"08")
		_dv(OTRKitMessageEventReceivedMessageMalformed,			@"09")
		_dv(OTRKitMessageEventLogHeartbeatReceived,				@"10")
		_dv(OTRKitMessageEventLogHeartbeatSent,					@"11")
		_dv(OTRKitMessageEventReceivedMessageGeneralError,		@"12")
		_dv(OTRKitMessageEventReceivedMessageUnencrypted,		@"13")
		_dv(OTRKitMessageEventReceivedMessageUnrecognized,		@"14")
		_dv(OTRKitMessageEventReceivedMessageForOtherInstance,	@"15")

		default:
		{
			break;
		}
	}

#undef _dv

	if (localeKey) {
		localeKey = [NSString stringWithFormat:@"OffTheRecord[1007][%@]", localeKey];
	}

	if (localeKey) {
		return TXTLS(localeKey);
	} else {
		return nil;
	}
}

- (BOOL)eventIsErrornous:(OTRKitMessageEvent)event
{
	switch (event) {
		case OTRKitMessageEventEncryptionError:
		case OTRKitMessageEventReceivedMessageGeneralError:
		case OTRKitMessageEventReceivedMessageMalformed:
		case OTRKitMessageEventReceivedMessageNotInPrivate:
		case OTRKitMessageEventReceivedMessageUnreadable:
		case OTRKitMessageEventReceivedMessageUnrecognized:
		case OTRKitMessageEventEncryptionRequired:
		{
			return YES;
		}
		default:
		{
			return NO;
		}
	}
}

- (void)printMessage:(NSString *)message inChannel:(IRCChannel *)channel onClient:(IRCClient *)client
{
	[client print:channel
			 type:TVCLogLineOffTheRecordEncryptionStatusType
		 nickname:nil
	  messageBody:message
		  command:TVCLogLineDefaultCommandValue];
}

- (void)presentMessage:(NSString *)message withAccountName:(NSString *)accountName
{
	[self performBlockInRelationToAccountName:accountName block:^(NSString *nickname, IRCClient *client, IRCChannel *channel) {
		[self printMessage:message inChannel:channel onClient:client];
	}];
}

- (void)presentErrorMessage:(NSString *)errorMessage withAccountName:(NSString *)accountName
{
	[self presentMessage:errorMessage withAccountName:accountName];
}

- (void)authenticationStatusChangedForAccountName:(NSString *)accountName isVerified:(BOOL)isVerified
{
	[self performBlockInRelationToAccountName:accountName block:^(NSString *nickname, IRCClient *client, IRCChannel *channel) {
		if (isVerified) {
			[self printMessage:TXTLS(@"OffTheRecord[1002]", nickname) inChannel:channel onClient:client];
		} else {
			[self printMessage:TXTLS(@"OffTheRecord[1003]", nickname) inChannel:channel onClient:client];
		}

		[channel noteEncryptionStateDidChange];
	}];
}

#pragma mark -
#pragma mark Off-the-Record Kit Delegate

- (void)updatePolicy
{
	if ([TPCPreferences textEncryptionIsRequired]) {
		[[OTRKit sharedInstance] setOtrPolicy:OTRKitPolicyAlways];
	} else {
		if ([TPCPreferences textEncryptionIsOpportunistic]) {
			[[OTRKit sharedInstance] setOtrPolicy:OTRKitPolicyOpportunistic];
		} else {
			[[OTRKit sharedInstance] setOtrPolicy:OTRKitPolicyManual];
		}
	}
}

- (NSString *)otrKitProtocol
{
	return @"prpl-irc";
}

- (int)otrKitProtocolMaximumMessageSize
{
	return 400; // Chosen by fair dice roll.
}

- (NSString *)maybeInsertProperNegotationMessge:(NSString *)message
{
	static NSRegularExpression *boundryRegex = nil;

	if (boundryRegex == nil) {
		NSString *boundryMatch = [NSString stringWithFormat:
			@"\\?OTRv?([0-9]+)\\?\n<b>(.*)</b> has requested an "
			@"<a href=\"https://otr.cypherpunks.ca/\">Off-the-Record "
			@"private conversation</a>.  However, you do not have a plugin "
			@"to support that.\nSee <a href=\"https://otr.cypherpunks.ca/\">"
			@"https://otr.cypherpunks.ca/</a> for more information."];

		boundryRegex = [NSRegularExpression regularExpressionWithPattern:boundryMatch options:0 error:NULL];
	}

	NSUInteger numMatches = [boundryRegex numberOfMatchesInString:message options:0 range:[message range]];

	if (numMatches == 1) {
		NSArray *messageComponents = [message componentsSeparatedByString:NSStringNewlinePlaceholder];

		return [NSString stringWithFormat:@"%@ %@", messageComponents[0], TXTLS(@"OffTheRecord[1010]")];
	} else {
		return message;
	}
}

- (void)otrKit:(OTRKit *)otrKit injectMessage:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
	message = [self maybeInsertProperNegotationMessge:message];

	if (tag && [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]]) {
		TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

		if ([messageObject injectionCallback]) {
			[messageObject injectionCallback](message);

			return; // Do not continue after callback block...
		}
	}

	[self performBlockInRelationToAccountName:username block:^(NSString *nickname, IRCClient *client, IRCChannel *channel) {
		[client send:IRCPrivateCommandIndex("privmsg"), [channel name], message, nil];
	}];
}

- (void)otrKit:(OTRKit *)otrKit encodedMessage:(NSString *)encodedMessage wasEncrypted:(BOOL)wasEncrypted username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error
{
	if (tag && [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]]) {
		TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

		if ([tag encodingCallback]) {
			[tag encodingCallback]([messageObject messageBody], wasEncrypted);
		}
	}
}

- (void)otrKit:(OTRKit *)otrKit decodedMessage:(NSString *)decodedMessage wasEncrypted:(BOOL)wasEncrypted tlvs:(NSArray *)tlvs username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
	if (tag && [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]]) {
		TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

		if ([messageObject encodingCallback]) {
			[messageObject encodingCallback](decodedMessage, wasEncrypted);
		}
	}
}

- (void)otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	[self performBlockInRelationToAccountName:username block:^(NSString *nickname, IRCClient *client, IRCChannel *channel) {
		[channel noteEncryptionStateDidChange];
	}];

	if (messageState ==  OTRKitMessageStateEncrypted) {
		BOOL isVerified = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:username
																			  accountName:accountName
																				 protocol:[self otrKitProtocol]];

		if (isVerified) {
			[self presentMessage:TXTLS(@"OffTheRecord[1001][02]") withAccountName:username];
		} else {
			[self presentMessage:TXTLS(@"OffTheRecord[1001][01]") withAccountName:username];
		}
	} else if (messageState == OTRKitMessageStateFinished ||
			   messageState == OTRKitMessageStatePlaintext)
	{
		[self presentMessage:TXTLS(@"OffTheRecord[1004]") withAccountName:username];
	}
}

- (BOOL)otrKit:(OTRKit *)otrKit isUsernameLoggedIn:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	__block BOOL userIsActive = NO;

	[self performBlockInRelationToAccountName:username block:^(NSString *nickname, IRCClient *client, IRCChannel *channel) {
		userIsActive = [channel isActive];
	}];

	return userIsActive;
}

- (void)otrKit:(OTRKit *)otrKit showFingerprintConfirmationForTheirHash:(NSString *)theirHash ourHash:(NSString *)ourHash username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	[OTRKitAuthenticationDialog showFingerprintConfirmation:mainWindow() username:username accountName:accountName protocol:protocol];
}

- (void)otrKit:(OTRKit *)otrKit handleSMPEvent:(OTRKitSMPEvent)event progress:(double)progress question:(NSString *)question username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	[OTRKitAuthenticationDialog handleAuthenticationRequest:event progress:progress question:question username:username accountName:accountName protocol:protocol];
}

- (void)otrKit:(OTRKit *)otrKit handleMessageEvent:(OTRKitMessageEvent)event message:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error
{
	if (event == OTRKitMessageEventReceivedMessageUnencrypted) {
		[self otrKit:otrKit decodedMessage:message wasEncrypted:NO tlvs:nil username:username accountName:accountName protocol:protocol tag:tag];
	} else {
		if ([self eventIsErrornous:event]) {
			[self presentErrorMessage:[self localizedStringForEvent:event] withAccountName:username];
		}
	}
}

- (void)otrKit:(OTRKit *)otrKit receivedSymmetricKey:(NSData *)symmetricKey forUse:(NSUInteger)use useData:(NSData *)useData username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (void)otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol
{
	;
}

- (void)otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(NSError *)error
{
	;
}

- (void)otrKit:(OTRKit *)otrKit fingerprintIsVerifiedStateChangedForUsername:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol verified:(BOOL)verified
{
	[self authenticationStatusChangedForAccountName:username isVerified:verified];
}

- (void)otrKitFingerprintManagerDialogDidClose:(OTRKitFingerprintManagerDialog *)otrkitFingerprintManager
{
	[self setFingerprintManagerDialog:nil];
}

#pragma mark -
#pragma mark Menu Item Actions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem withStateOf:(NSString *)messageTo from:(NSString *)messageFrom
{
	PointerIsEmptyAssertReturn(menuItem, NO)
	PointerIsEmptyAssertReturn(messageTo, NO)
	PointerIsEmptyAssertReturn(messageFrom, NO)

	NSInteger menuItemTag = [menuItem tag];

	if (menuItemTag == TLOEncryptionManagerMenuItemTagViewListOfFingerprints) {
		return YES;
	}

	OTRKitMessageState currentMessageState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																				  accountName:messageFrom
																					 protocol:[self otrKitProtocol]];

	BOOL messageStateEncrypted = (currentMessageState == OTRKitMessageStateEncrypted);

	switch (menuItemTag) {
		case TLOEncryptionManagerMenuItemTagStartPrivateConversation:
		{
			[menuItem setHidden:messageStateEncrypted];

			return YES;
		}
		case TLOEncryptionManagerMenuItemTagRefreshPrivateConversation:
		{
			[menuItem setHidden:(messageStateEncrypted == NO)];

			return YES;
		}
		case TLOEncryptionManagerMenuItemTagEndPrivateConversation:
		{
			return messageStateEncrypted;
		}
		case TLOEncryptionManagerMenuItemTagAuthenticateChatPartner:
		{
			return messageStateEncrypted;
		}
	}

	return NO;
}

@end

#pragma mark -
#pragma mark Dummy Class

@implementation TLOEncryptionManagerEncodingDecodingObject
@end
#endif
