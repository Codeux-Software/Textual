/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2020 Codeux Software, LLC & respective contributors.
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

#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TDCAlert.h"
#import "TLOLocalization.h"
#import "TVCMainWindow.h"
#import "TVCMainWindowTitlebarAccessoryViewPrivate.h"
#import "TVCLogRenderer.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesLocal.h"
#import "IRCClientPrivate.h"
#import "IRCChannelPrivate.h"
#import "IRCWorld.h"
#import "TLOEncryptionManagerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@interface TLOEncryptionManager () <OTRKitDelegate, OTRKitFingerprintManagerDialogDelegate>
@property (nonatomic, strong, nullable) OTRKitFingerprintManagerDialog *fingerprintManagerDialog;
@end

@interface TLOEncryptionManagerEncodingDecodingObject : NSObject
// Properties that should be manipulated to provide context information
@property (nonatomic, copy, nullable) TLOEncryptionManagerEncodingDecodingCallbackBlock encodingCallback;
@property (nonatomic, copy, nullable) TLOEncryptionManagerInjectCallbackBlock injectionCallback;
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
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[self setupEncryptionManager];
}

- (nullable NSString *)pathToStoreEncryptionSecrets
{
	NSString *sourcePath = [TPCPathInfo groupContainerApplicationSupport];

	if (sourcePath == nil) {
		return nil;
	}

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Encryption Components/"];

	[TPCPathInfo _createDirectoryAtPath:basePath];

	return basePath;
}

- (void)setupEncryptionManager
{
	OTRKit *otrKit = [OTRKit sharedInstance];

	otrKit.accountNameSeparator = @"@";

	otrKit.delegate = (id)self;

	[otrKit setupWithDataPath:[self pathToStoreEncryptionSecrets]];

	[self prepareEncryptionComponentPath:otrKit.fingerprintsPath];
	[self prepareEncryptionComponentPath:otrKit.instanceTagsPath];
	[self prepareEncryptionComponentPath:otrKit.privateKeyPath];

	NSURL *componentPathURL = [NSURL fileURLWithPath:otrKit.dataPath isDirectory:YES];

	NSError *attributesChangeError = nil;

	if ([componentPathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&attributesChangeError] == NO) {
		LogToConsoleError("Failed to hide the folder at the path '%@': %@",
			  componentPathURL, attributesChangeError.localizedDescription);
	}

	[otrKit setMaximumProtocolSize:[self otrKitProtocolMaximumMessageSize]
					   forProtocol:[self otrKitProtocol]];

	[self updatePolicy];
}

- (void)prepareEncryptionComponentPath:(NSString *)path
{
	NSParameterAssert(path != nil);

	/* Create the path if it does not already exist. */
	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		NSError *writeError = nil;

		if ([@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&writeError] == NO) {
			LogToConsoleError("Failed to create base file for encryption component at path: %@",
				  writeError.localizedDescription);
		}
	}

	/* Files are stored in a location that is accessible to Time Machine
	 which means we must mark the files to not be backed up. */
	NSURL *pathURL = [NSURL fileURLWithPath:path isDirectory:NO];

	NSError *attributesChangeError = nil;

	if ([pathURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&attributesChangeError] == NO) {
		LogToConsoleError("Failed to exclude the files at the path '%@' from backup: %@",
			  pathURL, attributesChangeError.localizedDescription);
	}
}

- (void)prepareForApplicationTermination
{
	LogToConsoleTerminationProgress("Preparing encryption manager.");
}

#pragma mark -
#pragma mark Fingerprint Manager

- (void)presentListOfFingerprints
{
	if (self.fingerprintManagerDialog == nil) {
		OTRKitFingerprintManagerDialog *dialog = [OTRKitFingerprintManagerDialog new];

		dialog.delegate = (id)self;

		self.fingerprintManagerDialog = dialog;
	}

	[self.fingerprintManagerDialog open:mainWindow()];
}

#pragma mark -
#pragma mark Account Name Information

- (NSString *)accountNameForUser:(NSString *)nickname onClient:(IRCClient *)client
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(client != nil);

	return [NSString stringWithFormat:@"%@%@%@", nickname, [OTRKit sharedInstance].accountNameSeparator, client.uniqueIdentifier];
}

- (nullable NSString *)nicknameFromAccountName:(NSString *)accountName
{
	NSParameterAssert(accountName != nil);

	NSString *nickname = [[OTRKit sharedInstance] leftPortionOfAccountName:accountName];

	return nickname;
}

- (nullable IRCClient *)connectionFromAccountName:(NSString *)accountName
{
	NSParameterAssert(accountName != nil);

	NSString *clientIdentifier = [[OTRKit sharedInstance] rightPortionOfAccountName:accountName];

	return [worldController() findClientWithId:clientIdentifier];
}

#pragma mark -
#pragma mark Starting Encryption & Stopping Encryption

- (void)beginConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	[self refreshConversationWith:messageTo from:messageFrom presentMessage:TXTLS(@"OffTheRecord[aii-2q]")];
}

- (void)endConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		[[OTRKit sharedInstance] disableEncryptionWithUsername:messageTo
												   accountName:messageFrom
													  protocol:[self otrKitProtocol]];
	} else {
		[self presentErrorMessage:TXTLS(@"OffTheRecord[g9p-8r]") withAccountName:messageTo];
	}
}

- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom
{
	[self refreshConversationWith:messageTo from:messageFrom presentMessage:TXTLS(@"OffTheRecord[f59-3b]")];
}

- (void)refreshConversationWith:(NSString *)messageTo from:(NSString *)messageFrom presentMessage:(NSString *)message
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);
	NSParameterAssert(message != nil);

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
												   protocol:[self otrKitProtocol]
											 asynchronously:YES];
}

#pragma mark -
#pragma mark Socialist Millionaire

- (void)authenticateUser:(NSString *)messageTo from:(NSString *)messageFrom
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		[OTRKitAuthenticationDialog requestAuthenticationForUsername:messageTo
														 accountName:messageFrom
															protocol:[self otrKitProtocol]];
	} else {
		[self presentErrorMessage:TXTLS(@"OffTheRecord[jrv-gq]") withAccountName:messageTo];
	}
}

#pragma mark -
#pragma mark Encryption & Decryption

- (void)decryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo decodingCallback:(nullable TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);
	NSParameterAssert(messageBody != nil);

	TLOEncryptionManagerEncodingDecodingObject *messageObject = [TLOEncryptionManagerEncodingDecodingObject new];

	messageObject.messageTo = messageTo;
	messageObject.messageFrom = messageFrom;

	messageObject.messageBody = messageBody;

	messageObject.encodingCallback = decodingCallback;

	/* Messages are decoded synchronously because many things incoming
	 from IRC are never passed through OTRKit. To keep the incoming
	 queue synchronous, we keep it synchronous here. */
	[[OTRKit sharedInstance] decodeMessage:messageBody
								  username:messageFrom
							   accountName:messageTo
								  protocol:[self otrKitProtocol]
							asynchronously:NO
									   tag:messageObject];
}

- (void)encryptMessage:(NSString *)messageBody from:(NSString *)messageFrom to:(NSString *)messageTo encodingCallback:(nullable TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(nullable TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);
	NSParameterAssert(messageBody != nil);

	TLOEncryptionManagerEncodingDecodingObject *messageObject = [TLOEncryptionManagerEncodingDecodingObject new];

	messageObject.messageTo = messageTo;
	messageObject.messageFrom = messageFrom;

	messageObject.messageBody = messageBody;

	messageObject.encodingCallback = encodingCallback;

	messageObject.injectionCallback = injectionCallback;

	[[OTRKit sharedInstance] encodeMessage:messageBody
									  tlvs:nil
								  username:messageTo
							   accountName:messageFrom
								  protocol:[self otrKitProtocol]
							asynchronously:NO
									   tag:messageObject];
}

#pragma mark -
#pragma mark Helper Methods

- (OTRKitMessageState)messageStateFor:(NSString *)messageTo from:(NSString *)messageFrom
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	OTRKitMessageState currentState =
		[[OTRKit sharedInstance] messageStateForUsername:messageTo
											 accountName:messageFrom
												protocol:[self otrKitProtocol]];

	return currentState;
}

- (BOOL)safeToTransferFile:(NSString *)filename to:(NSString *)messageTo from:(NSString *)messageFrom isIncomingFileTransfer:(BOOL)isIncomingFileTransfer
{
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		if (isIncomingFileTransfer) {
			BOOL continueop = [TDCAlert modalAlertWithMessage:TXTLS(@"OffTheRecord[nuo-8s]")
														title:TXTLS(@"OffTheRecord[mnw-qt]", filename)
												defaultButton:TXTLS(@"Prompts[qso-2g]")
											  alternateButton:TXTLS(@"OffTheRecord[ng0-5q]")];

			return (continueop == NO);
		}
		else
		{
			NSString *nickname = [self nicknameFromAccountName:messageTo];

			BOOL continueop = [TDCAlert modalAlertWithMessage:TXTLS(@"OffTheRecord[7he-76]")
														title:TXTLS(@"OffTheRecord[gcg-tv]", filename, nickname)
												defaultButton:TXTLS(@"Prompts[qso-2g]")
											  alternateButton:TXTLS(@"OffTheRecord[0v0-ix]")];

			return (continueop == NO);
		}
	}

	return YES;
}

- (void)updateLockIconButton:(TVCMainWindowTitlebarAccessoryViewLockButton *)button withStateOf:(NSString *)messageTo from:(NSString *)messageFrom
{
	NSParameterAssert(button != nil);
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	OTRKitMessageState currentState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																		   accountName:messageFrom
																			  protocol:[self otrKitProtocol]];

	if (currentState == OTRKitMessageStateEncrypted) {
		BOOL hasVerifiedKey = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:messageTo
																				  accountName:messageFrom
																					 protocol:[self otrKitProtocol]];

		if (hasVerifiedKey) {
			button.title = TXTLS(@"OffTheRecord[l9n-p9]");

			[button setIconAsLocked];
		} else {
			button.title = TXTLS(@"OffTheRecord[w34-mg]");

			/* Even though we are encrypted, our icon is still set to unlocked because
			 the identity of messageTo still has not been authenticated. */
			[button setIconAsUnlocked];
		}
	} else {
		button.title = TXTLS(@"OffTheRecord[anu-ky]");

		[button setIconAsUnlocked];
	}
}

- (void)performBlock:(void (^)(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel))block inRelationToAccountName:(NSString *)accountName
{
	[self performBlock:block inRelationToAccountName:accountName createWindowIfMissing:NO];
}

- (void)performBlock:(void (^)(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel))block inRelationToAccountName:(NSString *)accountName createWindowIfMissing:(BOOL)createWindowIfMissing
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		IRCClient *client = [self connectionFromAccountName:accountName];

		if (client == nil) {
			return;
		}

		NSString *nickname = [self nicknameFromAccountName:accountName];

		IRCChannel *channel = nil;

		if (createWindowIfMissing) {
			channel = [client findChannelOrCreate:nickname isPrivateMessage:YES];
		} else {
			channel = [client findChannel:nickname];
		}

		block(nickname, client, channel);
	});
}

- (nullable NSString *)localizedStringForEvent:(OTRKitMessageEvent)event
{
	NSString *localeKey = nil;

#define _dv(event, localInt)		case (event): { localeKey = (localInt); break; }

	switch (event) {
		_dv(OTRKitMessageEventEncryptionRequired,				@"jww-e0")
		_dv(OTRKitMessageEventEncryptionError,					@"jvt-fi")
		_dv(OTRKitMessageEventConnectionEnded,					@"c5o-2l")
		_dv(OTRKitMessageEventSetupError,						@"uhy-85")
		_dv(OTRKitMessageEventMessageReflected,					@"bl0-5i")
		_dv(OTRKitMessageEventMessageResent,					@"c49-q0")
		_dv(OTRKitMessageEventReceivedMessageNotInPrivate,		@"6v9-w3")
		_dv(OTRKitMessageEventReceivedMessageUnreadable,		@"9if-xp")
		_dv(OTRKitMessageEventReceivedMessageMalformed,			@"auo-n0")
		_dv(OTRKitMessageEventLogHeartbeatReceived,				@"nl1-nf")
		_dv(OTRKitMessageEventLogHeartbeatSent,					@"iwt-9f")
		_dv(OTRKitMessageEventReceivedMessageGeneralError,		@"2zx-p6")
		_dv(OTRKitMessageEventReceivedMessageUnencrypted,		@"1lf-f0")
		_dv(OTRKitMessageEventReceivedMessageUnrecognized,		@"4by-8j")
		_dv(OTRKitMessageEventReceivedMessageForOtherInstance,	@"c7t-vi")

		default:
		{
			break;
		}
	}

#undef _dv

	if (localeKey) {
		localeKey = [NSString stringWithFormat:@"OffTheRecord[%@]", localeKey];

		return TXTLS(localeKey);
	}

	return nil;
}

- (BOOL)eventIsErroneous:(OTRKitMessageEvent)event
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
	[self printMessage:message inChannel:channel onClient:client escapeMessage:YES];
}

- (void)printMessage:(NSString *)message inChannel:(IRCChannel *)channel onClient:(IRCClient *)client escapeMessage:(BOOL)escapeMessage
{
	NSParameterAssert(message != nil);
	NSParameterAssert(channel != nil);
	NSParameterAssert(client != nil);

	[client print:message
			   by:nil
		inChannel:channel
		   asType:TVCLogLineTypeOffTheRecordEncryptionStatus
		  command:TVCLogLineDefaultCommandValue
	escapeMessage:escapeMessage];
}

- (void)presentMessage:(NSString *)message withAccountName:(NSString *)accountName
{
	[self presentMessage:message withAccountName:accountName escapeMessage:YES];
}

- (void)presentMessage:(NSString *)message withAccountName:(NSString *)accountName escapeMessage:(BOOL)escapeMessage
{
	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		if (channel == nil) {
			return;
		}

		[self printMessage:message inChannel:channel onClient:client escapeMessage:escapeMessage];
	} inRelationToAccountName:accountName
		createWindowIfMissing:YES];
}

- (void)presentErrorMessage:(NSString *)errorMessage withAccountName:(NSString *)accountName
{
	[self presentErrorMessage:errorMessage withAccountName:accountName escapeMessage:YES];
}

- (void)presentErrorMessage:(NSString *)errorMessage withAccountName:(NSString *)accountName escapeMessage:(BOOL)escapeMessage
{
	[self presentMessage:errorMessage withAccountName:accountName escapeMessage:escapeMessage];
}

- (void)authenticationStatusChangedForAccountName:(NSString *)accountName isVerified:(BOOL)isVerified
{
	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		if (channel == nil) {
			return;
		}

		if (isVerified) {
			[self printMessage:TXTLS(@"OffTheRecord[rj0-ys]", nickname) inChannel:channel onClient:client];
		} else {
			[self printMessage:TXTLS(@"OffTheRecord[ufr-mh]", nickname) inChannel:channel onClient:client];
		}

		[channel noteEncryptionStateDidChange];
	} inRelationToAccountName:accountName];
}

#pragma mark -
#pragma mark Off-the-Record Kit Delegate

- (void)updatePolicy
{
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		[OTRKit sharedInstance].otrPolicy = OTRKitPolicyNever;

		return;
	}

	if ([TPCPreferences textEncryptionIsRequired]) {
		[OTRKit sharedInstance].otrPolicy = OTRKitPolicyAlways;
	} else if ([TPCPreferences textEncryptionIsOpportunistic]) {
		[OTRKit sharedInstance].otrPolicy = OTRKitPolicyOpportunistic;
	} else {
		[OTRKit sharedInstance].otrPolicy = OTRKitPolicyManual;
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

- (NSString *)maybeInsertProperNegotiationMessage:(NSString *)message
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

	NSUInteger numberOfMatches = [boundryRegex numberOfMatchesInString:message options:0 range:message.range];

	if (numberOfMatches == 1) {
		NSArray *messageComponents = [message componentsSeparatedByString:@"\n"];

		return [NSString stringWithFormat:@"%@ %@", messageComponents[0], TXTLS(@"OffTheRecord[8hr-8l]")];
	}

	return message;
}

- (void)otrKit:(OTRKit *)otrKit injectMessage:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(nullable id)tag
{
	message = [self maybeInsertProperNegotiationMessage:message];

	if (tag && [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]]) {
		TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

		if (messageObject.injectionCallback) {
			messageObject.injectionCallback(message);

			return; // Do not continue after callback block...
		}
	}

	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		[client send:@"PRIVMSG", nickname, message, nil];
	} inRelationToAccountName:username];
}

- (void)otrKit:(OTRKit *)otrKit encodedMessage:(nullable NSString *)encodedMessage wasEncrypted:(BOOL)wasEncrypted username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(nullable id)tag error:(nullable NSError *)error
{
	if (tag == nil || [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]] == NO) {
		return;
	}

	TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

	if (messageObject.encodingCallback) {
		messageObject.encodingCallback(messageObject.messageBody, wasEncrypted);
	}
}

- (void)otrKit:(OTRKit *)otrKit decodedMessage:(nullable NSString *)decodedMessage wasEncrypted:(BOOL)wasEncrypted tlvs:(NSArray<OTRTLV *> *)tlvs username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(nullable id)tag
{
	if (decodedMessage == nil) {
		return;
	}

	if (tag == nil || [tag isKindOfClass:[TLOEncryptionManagerEncodingDecodingObject class]] == NO) {
		return;
	}

	TLOEncryptionManagerEncodingDecodingObject *messageObject = tag;

	if (messageObject.encodingCallback) {
		messageObject.encodingCallback(decodedMessage, wasEncrypted);
	}
}

- (void)otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	/* We do not force create window if it does not exist when updating encryption
	 status because status changes are only important if one is open. When a new
	 window is created, it will populate the latest state regardless of delegate. */
	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		if (channel == nil) {
			return;
		}

		[channel noteEncryptionStateDidChange];
	} inRelationToAccountName:username];

	if (messageState ==  OTRKitMessageStateEncrypted) {
		BOOL isVerified = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:username
																			  accountName:accountName
																				 protocol:[self otrKitProtocol]];

		if (isVerified) {
			[self presentMessage:TXTLS(@"OffTheRecord[r3w-fj]") withAccountName:username];
		} else {
			[self presentMessage:TXTLS(@"OffTheRecord[l49-9y]") withAccountName:username escapeMessage:NO];
		}
	} else if (messageState == OTRKitMessageStateFinished ||
			   messageState == OTRKitMessageStatePlaintext)
	{
		[self presentMessage:TXTLS(@"OffTheRecord[m1z-eb]") withAccountName:username];

		/* When policy is changed to never, all open conversations are
		 closed. Because user probably wont intend to use authenication
		 dialogs without encryption enabled, then let's cancel any that
		 are open for this condition. */
		if ([TPCPreferences textEncryptionIsEnabled] == NO) {
			[OTRKitAuthenticationDialog cancelRequestForUsername:username
													 accountName:accountName
														protocol:protocol];
		}
	}
}

- (BOOL)otrKit:(OTRKit *)otrKit isUsernameLoggedIn:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	__block BOOL userIsActive = NO;

	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		if (channel == nil) {
			return;
		}

		userIsActive = channel.isActive;
	} inRelationToAccountName:username];

	return userIsActive;
}

- (void)otrKit:(OTRKit *)otrKit showFingerprintConfirmationForTheirHash:(NSString *)theirHash ourHash:(NSString *)ourHash username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		/* We print this message unescaped to include an anchor in the HTML
		 that the user can click to authenticate the user.
		 We are passing outside input to it, which we do escape. */
		[self printMessage:TXTLS(@"OffTheRecord[67n-6j]",
								 [TVCLogRenderer escapeHTML:nickname],
								 [TVCLogRenderer escapeHTML:theirHash])
				 inChannel:channel
				  onClient:client
			 escapeMessage:NO];
	}  inRelationToAccountName:username
		 createWindowIfMissing:YES];
}

- (void)otrKit:(OTRKit *)otrKit handleSMPEvent:(OTRKitSMPEvent)event progress:(double)progress question:(nullable NSString *)question username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol error:(nullable NSError *)error
{
	[OTRKitAuthenticationDialog handleAuthenticationRequest:event progress:progress question:question username:username accountName:accountName protocol:protocol];
}

- (void)otrKit:(OTRKit *)otrKit handleMessageEvent:(OTRKitMessageEvent)event message:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(nullable id)tag error:(nullable NSError *)error
{
	if (event == OTRKitMessageEventReceivedMessageUnencrypted) {
		[self otrKit:otrKit decodedMessage:message wasEncrypted:NO tlvs:nil username:username accountName:accountName protocol:protocol tag:tag];

		return;
	}

	if ([self eventIsErroneous:event]) {
		NSString *errorMessage = [self localizedStringForEvent:event];

		[self presentErrorMessage:errorMessage withAccountName:username];
	}
}

- (void)otrKit:(OTRKit *)otrKit receivedSymmetricKey:(NSData *)symmetricKey forUse:(NSUInteger)use useData:(NSData *)useData username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{

}

- (void)otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol
{

}

- (void)otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(nullable NSError *)error
{

}

- (void)otrKit:(OTRKit *)otrKit fingerprintIsVerifiedStateChangedForUsername:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol verified:(BOOL)verified
{
	[self authenticationStatusChangedForAccountName:username isVerified:verified];
}

- (void)otrKitFingerprintManagerDialogDidClose:(OTRKitFingerprintManagerDialog *)otrkitFingerprintManager
{
	self.fingerprintManagerDialog = nil;
}

- (BOOL)otrKit:(OTRKit *)otrKit ignoreMessage:(NSString *)message messageType:(OTRKitMessageType)messageType username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
	__block BOOL ignoreMessage = NO;

	[self performBlock:^(NSString *nickname, IRCClient *client, IRCChannel * _Nullable channel) {
		if (messageType == OTRKitMessageTypeNotOTR) {
			return;
		}

		if ([client isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage]) {
			ignoreMessage = [client nicknameIsMyself:nickname];
		}
	} inRelationToAccountName:username];

	return ignoreMessage;
}

#pragma mark -
#pragma mark Menu Item Actions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem withStateOf:(NSString *)messageTo from:(NSString *)messageFrom
{
	NSParameterAssert(menuItem != nil);
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(messageFrom != nil);

	NSUInteger menuItemTag = menuItem.tag;

	if (menuItemTag == MTOTRStatusButtonViewListOfFingerprints) {
		return YES;
	}

	OTRKitMessageState currentMessageState = [[OTRKit sharedInstance] messageStateForUsername:messageTo
																				  accountName:messageFrom
																					 protocol:[self otrKitProtocol]];

	BOOL messageStateEncrypted = (currentMessageState == OTRKitMessageStateEncrypted);

	switch (menuItemTag) {
		case MTOTRStatusButtonStartPrivateConversation:
		{
			menuItem.hidden = messageStateEncrypted;

			return YES;
		}
		case MTOTRStatusButtonRefreshPrivateConversation:
		{
			menuItem.hidden = (messageStateEncrypted == NO);

			return YES;
		}
		case MTOTRStatusButtonEndPrivateConversation:
		{
			return messageStateEncrypted;
		}
		case MTOTRStatusButtonAuthenticateChatPartner:
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

NS_ASSUME_NONNULL_END
