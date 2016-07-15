/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "IRCClientConfig.h"
#import "IRCCommandIndex.h"
#import "IRCConnection.h"
#import "IRCTreeItem.h"

#import "TLOEncryptionManager.h"

#import "TVCLogController.h"
#import "TVCLogLine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IRCClientConnectMode) {
	IRCClientConnectNormalMode = 0,
	IRCClientConnectRetryMode,
	IRCClientConnectReconnectMode,
};

typedef NS_ENUM(NSUInteger, IRCClientDisconnectMode) {
	IRCClientDisconnectNormalMode = 0,
	IRCClientDisconnectComputerSleepMode,
	IRCClientDisconnectBadCertificateMode,
	IRCClientDisconnectReachabilityChangeMode,
	IRCClientDisconnectServerRedirectMode,
};

typedef NS_OPTIONS(NSUInteger, ClientIRCv3SupportedCapacities) {
	ClientIRCv3SupportedCapacityAwayNotify				= 1 << 0, // YES if away-notify CAP supported
	ClientIRCv3SupportedCapacityIdentifyCTCP			= 1 << 1, // YES if identify-ctcp CAP supported
	ClientIRCv3SupportedCapacityIdentifyMsg				= 1 << 2, // YES if identify-msg CAP supported
	ClientIRCv3SupportedCapacityMultiPreifx				= 1 << 3, // YES if multi-prefix CAP supported
	ClientIRCv3SupportedCapacityServerTime				= 1 << 4, // YES if server-time CAP supported
	ClientIRCv3SupportedCapacityUserhostInNames			= 1 << 5, // YES if userhost-in-names CAP supported
	ClientIRCv3SupportedCapacityWatchCommand			= 1 << 6, // YES if the WATCH command is supported
	ClientIRCv3SupportedCapacityIsInSASLNegotiation		= 1 << 7, // YES if in SASL CAP authentication request
	ClientIRCv3SupportedCapacityIsIdentifiedWithSASL	= 1 << 8, // YES if SASL authentication was successful
	ClientIRCv3SupportedCapacityZNCSelfMessage			= 1 << 14, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapacityZNCPlaybackModule		= 1 << 15, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapacityBatch					= 1 << 16, // YES if batch CAP supported
	ClientIRCv3SupportedCapacityZNCCertInfoModule		= 1 << 17, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapacityEchoMessageModule		= 1 << 18 // YES if echo-message CAP supported
};

TEXTUAL_EXTERN NSString * const IRCClientConfigurationWasUpdatedNotification;

TEXTUAL_EXTERN NSString * const IRCClientChannelListWasModifiedNotification;

@interface IRCClient : IRCTreeItem <IRCConnectionDelegate>
@property (readonly, copy) IRCClientConfig *config;
@property (readonly) IRCISupportInfo *supportInfo;
@property (readonly) IRCClientConnectMode connectType;
@property (readonly) IRCClientDisconnectMode disconnectType;
@property (readonly) BOOL isAutojoined;					// YES if autojoin has completed
@property (readonly) BOOL isAutojoining;				// YES if autojoin is in progress
@property (readonly) BOOL isConnecting;					// YES if socket is connecting. Set to NO on raw numeric 001.
@property (readonly) BOOL isConnected;					// YES if socket is connected
@property (readonly) BOOL isConnectedToZNC;				// YES if Textual detected that this connection is ZNC
@property (readonly) BOOL isLoggedIn;					// YES if logged into server. Set to YES on raw numeric 001.
@property (readonly) BOOL isQuitting;					// YES if socket is disconnecting
@property (readonly) BOOL isReconnecting;				// YES if reconnect is pending
@property (readonly) BOOL isSecured;					// YES if socket is connected using SSL/TLS
@property (readonly) BOOL userIsAway;					// YES if local uesr is away
@property (readonly) BOOL userIsIRCop;					// YES if local user is IRCop
@property (readonly) BOOL userIsIdentifiedWithNickServ; // YES if NickServ identification was successful
@property (readonly) BOOL isWaitingForNickServ;			// YES if NickServ identification is pending
@property (readonly) BOOL serverHasNickServ;			// YES if NickServ service was found on server
@property (readonly) BOOL inUserInvokedJoinRequest;
@property (readonly) BOOL inUserInvokedIsonRequest;
@property (readonly) BOOL inUserInvokedNamesRequest;
@property (readonly) BOOL inUserInvokedWhoRequest;
@property (readonly) BOOL inUserInvokedWhowasRequest;
@property (readonly) BOOL inUserInvokedWatchRequest;
@property (readonly) BOOL inUserInvokedModeRequest;
@property (readonly) NSTimeInterval lastMessageReceived;			// The time at which the last of any incoming data was received
@property (readonly) NSTimeInterval lastMessageServerTime;			// The time of the last message received that contained a server-time CAP
@property (readonly) NSUInteger channelCount;
@property (readonly, weak, nullable) IRCChannel *lastSelectedChannel; // If this is the selected client, then the value of this property is the current selection. If the current client is not selected, then this value is either its previous selection or nil.
@property (readonly, copy) NSArray<IRCChannel *> *channelList;
@property (readonly, copy) NSArray<IRCHighlightLogEntry *> *cachedHighlights;
@property (readonly, copy, nullable) NSString *userHostmask; // The hostmask of the local user
@property (readonly, copy) NSString *userNickname; // The nickname of the local user
@property (readonly, copy) NSString *serverAddress; // The address of the server connected to or nil
@property (readonly, copy, nullable) NSString *networkName; // The name of the network connected to or nil
@property (readonly, copy) NSString *networkNameAlt; // The name of the network connected to or the configured Connection Name
@property (readonly, copy, nullable) NSString *preAwayUserNickname; // Nickname before away was set or nil
@property (readonly, copy, nullable) NSData *zncBouncerCertificateChainData;

- (void)connect;
- (void)connect:(IRCClientConnectMode)connectMode;
- (void)connect:(IRCClientConnectMode)connectMode preferIPv4:(BOOL)preferIPv4;

- (void)quit;
- (void)quitWithComment:(NSString *)comment;

- (void)cancelReconnect;

@property (readonly) ClientIRCv3SupportedCapacities capacities;
@property (readonly, copy) NSString *enabledCapacitiesStringValue;

- (BOOL)isCapacitySupported:(NSString *)capacityString;

- (BOOL)isCapacityEnabled:(ClientIRCv3SupportedCapacities)capacity;

- (void)joinChannel:(IRCChannel *)channel;
- (void)joinChannel:(IRCChannel *)channel password:(nullable NSString *)password;
- (void)joinUnlistedChannel:(NSString *)channel;
- (void)joinUnlistedChannel:(NSString *)channel password:(nullable NSString *)password;
- (void)forceJoinChannel:(NSString *)channel password:(nullable NSString *)password;

- (void)partChannel:(IRCChannel *)channel;
- (void)partChannel:(IRCChannel *)channel withComment:(nullable NSString *)comment;
- (void)partUnlistedChannel:(NSString *)channel;
- (void)partUnlistedChannel:(NSString *)channel withComment:(nullable NSString *)comment;

- (void)changeNickname:(NSString *)newNickname;

- (void)kick:(NSString *)nickname inChannel:(IRCChannel *)channel;

- (void)sendCTCPQuery:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text;
- (void)sendCTCPReply:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text;
- (void)sendCTCPPing:(NSString *)nickname;

- (void)sendWhois:(NSString *)nickname;

- (void)sendWhoToChannel:(IRCChannel *)channel;
- (void)sendWhoToChannelNamed:(NSString *)channel;

- (void)toggleAwayStatus:(BOOL)setAway;
- (void)toggleAwayStatus:(BOOL)setAway withComment:(nullable NSString *)comment;

- (void)requestModesForChannel:(IRCChannel *)channel;
- (void)requestModesForChannelNamed:(NSString *)channel;

- (void)sendModes:(nullable NSString *)modeSymbols withParamaters:(nullable NSArray<NSString *> *)paramaters inChannel:(IRCChannel *)channel;
- (void)sendModes:(nullable NSString *)modeSymbols withParamatersString:(nullable NSString *)paramatersString inChannel:(IRCChannel *)channel;

- (void)sendModes:(nullable NSString *)modeSymbols withParamaters:(nullable NSArray<NSString *> *)paramaters inChannelNamed:(NSString *)channel;
- (void)sendModes:(nullable NSString *)modeSymbols withParamatersString:(nullable NSString *)paramatersString inChannelNamed:(NSString *)channel;

- (void)sendPing:(NSString *)tokenString;
- (void)sendPong:(NSString *)tokenString;

- (void)sendInviteTo:(NSString *)nickname toJoinChannel:(IRCChannel *)channel;
- (void)sendInviteTo:(NSString *)nickname toJoinChannelNamed:(NSString *)channel;

- (void)requestTopicForChannel:(IRCChannel *)channel;
- (void)requestTopicForChannelNamed:(NSString *)channel;

- (void)sendTopicTo:(nullable NSString *)topic inChannel:(IRCChannel *)channel;
- (void)sendTopicTo:(nullable NSString *)topic inChannelNamed:(NSString *)channel;

- (void)sendCapacity:(NSString *)subcommand data:(nullable NSString *)data;

- (void)sendIsonForNicknames:(NSArray<NSString *> *)nicknames;
- (void)sendIsonForNicknamesString:(NSString *)nicknames;

- (void)modifyWatchListBy:(BOOL)adding nicknames:(NSArray<NSString *> *)nicknames;

- (void)requestChannelList;

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet paramaterString:(NSString *)paramaterString;
- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet paramaterString:(NSString *)paramaterString characterSet:(NSCharacterSet *)characterList;

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet modeParamaters:(NSArray<NSString *> *)modeParamaters;

- (void)createChannelListDialog;
- (void)createChannelInviteExceptionListSheet;
- (void)createChannelBanExceptionListSheet;
- (void)createChannelBanListSheet;

- (void)presentCertificateTrustInformation;

- (void)closeDialogs;

#pragma mark -

- (nullable IRCChannel *)findChannel:(NSString *)withName;
- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName;
- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName isPrivateMessage:(BOOL)isPrivateMessage;

- (nullable NSData *)convertToCommonEncoding:(NSString *)string;
- (nullable NSString *)convertFromCommonEncoding:(NSData *)data;

- (NSString *)formatNickname:(NSString *)nickname inChannel:(nullable IRCChannel *)channel;
- (NSString *)formatNickname:(NSString *)nickname inChannel:(nullable IRCChannel *)channel withFormat:(nullable NSString *)format;

- (BOOL)nicknameIsZNCUser:(NSString *)nickname;
- (nullable NSString *)nicknameAsZNCUser:(NSString *)nickname; // Returns nil if not connected to ZNC

- (BOOL)nicknameIsMyself:(NSString *)nickname;

- (BOOL)stringIsNickname:(NSString *)string;
- (BOOL)stringIsChannelName:(NSString *)string;

- (nullable IRCAddressBookEntry *)checkIgnoreAgainstHostmask:(NSString *)hostmask withMatches:(NSArray<NSString *> *)matches;

- (BOOL)outputRuleMatchedInMessage:(NSString *)message inChannel:(nullable IRCChannel *)channel;

#pragma mark -

- (void)setUnreadStateForChannel:(IRCChannel *)channel;
- (void)setUnreadStateForChannel:(IRCChannel *)channel isHighlight:(BOOL)isHighlight;

- (void)setHighlightStateForChannel:(IRCChannel *)channel;

#pragma mark -

- (void)sendCommand:(id)string;
- (void)sendCommand:(id)string completeTarget:(BOOL)completeTarget target:(nullable NSString *)targetChannelName;

- (void)sendCommand:(NSString *)command toZNCModuleNamed:(NSString *)module;

- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel;
- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel withEncryption:(BOOL)encryptText;

- (void)sendLine:(NSString *)string;
- (void)send:(NSString *)string, ...;

- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel; // Invoke -sendText: with proper values
- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel;
- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel;

/* When using -sendPrivmsgToSelectedChannel:, if the actual selected channel in the main
 window is not owned by this client, then the message will be sent to the server console. */
/* The method obviously does not work as expected so it has been marked as deprecated.
 However, it will remain functional for plugin authors who wish to use it. */
- (void)sendPrivmsgToSelectedChannel:(NSString *)message TEXTUAL_DEPRECATED("Use sendPrivmsg:toChannel: instead");

#pragma mark -

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (NSUInteger)lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSUInteger)maximumLength;

- (BOOL)encryptionAllowedForNickname:(NSString *)nickname;

- (void)encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback;
- (void)decryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback;

@property (nonatomic, readonly, copy) NSString * _Nonnull encryptionAccountNameForLocalUser;
- (NSString *)encryptionAccountNameForUser:(NSString *)nickname;
#endif

#pragma mark -

// nil channel prints the message to the server console
// referenceMessage.command is used if command == nil
// referenceMessage and command cannot be nil together (this throws exceptions)
- (void)		print:(NSString *)messageBody
				   by:(nullable NSString *)nickname
		    inChannel:(nullable IRCChannel *)channel
			   asType:(TVCLogLineType)lineType
			  command:(nullable NSString *)command
		   receivedAt:(NSDate *)receivedAt
		  isEncrypted:(BOOL)isEncrypted
	 referenceMessage:(nullable IRCMessage *)referenceMessage
	  completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock;

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command;
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt;
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted;
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted referenceMessage:(nullable IRCMessage *)referenceMessage;

- (void)printDebugInformationToConsole:(NSString *)message;
- (void)printDebugInformationToConsole:(NSString *)message asCommand:(NSString *)command;

- (void)printDebugInformation:(NSString *)message;
- (void)printDebugInformation:(NSString *)message asCommand:(NSString *)command;

- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel;
- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel asCommand:(NSString *)command;

#pragma mark -

- (void)clearCachedHighlights;

/* -config may not always reflect the current state of the client.
 * This is because its too costly to mutate it for stuff that changes
 * many times a second. The client instead saves a copy of its
 * configuration periodically. This method will force it to perform
 * a save if you need to rely on most recent version. */
- (void)updateStoredConfiguration;
@end

NS_ASSUME_NONNULL_END
