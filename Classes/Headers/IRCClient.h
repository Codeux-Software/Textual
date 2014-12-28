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

#import "IRCTreeItem.h" // superclass

#import "TVCLogLine.h"			// typedef enum
#import "TLOGrowlController.h"	// typedef enum

typedef enum IRCClientConnectMode : NSInteger {
	IRCClientConnectNormalMode,
	IRCClientConnectRetryMode,
	IRCClientConnectReconnectMode,
	IRCClientConnectBadSSLCertificateMode,
} IRCClientConnectMode;

typedef enum IRCClientDisconnectMode : NSInteger {
	IRCClientDisconnectNormalMode,
	IRCClientDisconnectTrialPeriodMode,
	IRCClientDisconnectComputerSleepMode,
	IRCClientDisconnectBadSSLCertificateMode,
	IRCClientDisconnectReachabilityChangeMode,
	IRCClientDisconnectServerRedirectMode,
} IRCClientDisconnectMode;

typedef enum IRCClientIdentificationWithSASLMechanism : NSInteger {
	IRCClientIdentificationWithSASLNoMechanism,
	IRCClientIdentificationWithSASLPlainTextMechanism,
	IRCClientIdentificationWithSASLExternalMechanism,
} IRCClientIdentificationWithSASLMechanism;

/* Always check for ClientIRCv3SupportedCapacityServerTime if the server-time
 capacity is being checked. ClientIRCv3SupportedCapacityZNCServerTime and
 ClientIRCv3SupportedCapacityZNCServerTimeISO are used internally for 
 capacity negotation but once accepted, the default server-time flag 
 is set for the maintained capacity. */

/* ClientIRCv3SupportedCapacitySASL… is set once negotation begins. It is 
 reset if negotation fails. Use ClientIRCv3SupportedCapacityIsIdentifiedWithSASL
 to find actual status of identification. */
typedef enum ClientIRCv3SupportedCapacities : NSInteger {
	ClientIRCv3SupportedCapacityAwayNotify				= 1 << 0, // YES if away-notify CAP supported.
	ClientIRCv3SupportedCapacityIdentifyCTCP			= 1 << 1, // YES if identify-ctcp CAP supported.
	ClientIRCv3SupportedCapacityIdentifyMsg				= 1 << 2, // YES if identify-msg CAP supported.
	ClientIRCv3SupportedCapacityMultiPreifx				= 1 << 3, // YES if multi-prefix CAP supported.
	ClientIRCv3SupportedCapacityServerTime				= 1 << 4, // YES if server-time CAP supported.
	ClientIRCv3SupportedCapacityUserhostInNames			= 1 << 5, // YES if userhost-in-names CAP supported.
	ClientIRCv3SupportedCapacityWatchCommand			= 1 << 6, // YES if the WATCH command is supported.
	ClientIRCv3SupportedCapacityZNCPlaybackModule		= 1 << 7, // YES if the ZNC vendor specific CAP supported.
	ClientIRCv3SupportedCapacityZNCServerTime			= 1 << 8, // YES if the ZNC vendor specific CAP supported.
	ClientIRCv3SupportedCapacityZNCServerTimeISO		= 1 << 9, // YES if the ZNC vendor specific CAP supported.
	ClientIRCv3SupportedCapacitySASLGeneric				= 1 << 10, // YES if any type of SASL is in use.
	ClientIRCv3SupportedCapacitySASLPlainText			= 1 << 11, // YES if SASL plain text CAP is supported.
	ClientIRCv3SupportedCapacitySASLExternal			= 1 << 12, // YES if SASL external CAP is supported.
	ClientIRCv3SupportedCapacityIsInSASLNegotiation		= 1 << 13, // YES if in SASL CAP authentication request, else NO.
	ClientIRCv3SupportedCapacityIsIdentifiedWithSASL	= 1 << 14, // YES if SASL authentication was successful, else NO.
} ClientIRCv3SupportedCapacities;

typedef void (^IRCClientPrintToWebViewCallbackBlock)(BOOL isHighlight);

#define IRCClientConfigurationWasUpdatedNotification	@"IRCClientConfigurationWasUpdatedNotification"

#import "IRCConnection.h" // @protocol

@interface IRCClient : IRCTreeItem <IRCConnectionDelegate, TDChanBanExceptionSheetDelegate, TDChanBanSheetDelegate, TDChanInviteExceptionSheetDelegate, TDCListDialogDelegate>
@property (nonatomic, copy) IRCClientConfig *config;
@property (nonatomic, strong) IRCISupportInfo *supportInfo;
@property (nonatomic, assign) IRCClientConnectMode connectType;
@property (nonatomic, assign) IRCClientDisconnectMode disconnectType;
@property (nonatomic, copy) TXEmtpyBlockDataType disconnectCallback; // Changing this may break some things
@property (nonatomic, assign) NSInteger connectDelay;
@property (nonatomic, assign) BOOL inUserInvokedJoinRequest;
@property (nonatomic, assign) BOOL inUserInvokedIsonRequest;
@property (nonatomic, assign) BOOL inUserInvokedNamesRequest;
@property (nonatomic, assign) BOOL inUserInvokedWhoRequest;
@property (nonatomic, assign) BOOL inUserInvokedWhowasRequest;
@property (nonatomic, assign) BOOL inUserInvokedWatchRequest;
@property (nonatomic, assign) BOOL inUserInvokedModeRequest;
@property (nonatomic, assign) BOOL autojoinInProgress;			// YES if autojoin is running, else NO.
@property (nonatomic, assign) BOOL hasIRCopAccess;				// YES if local user is IRCOp, else NO.
@property (nonatomic, assign) BOOL isAutojoined;				// YES if autojoin has been completed, else NO.
@property (nonatomic, assign) BOOL isAway;						// YES if Textual has knowledge of local user being away, else NO.
@property (nonatomic, assign) BOOL isConnected;					// YES if socket is connected, else NO.
@property (nonatomic, assign) BOOL isConnecting;				// YES if socket is connecting, else, NO. Set to NO on raw numeric 001.
@property (nonatomic, assign) BOOL isIdentifiedWithNickServ;	// YES if NickServ identification was successful, else NO.
@property (nonatomic, assign) BOOL isLoggedIn;					// YES if connected to server, else NO. Set to YES on raw numeric 001.
@property (nonatomic, assign) BOOL isQuitting;					// YES if connection to IRC server is being quit, else NO.
@property (nonatomic, assign) BOOL isWaitingForNickServ;		// YES if NickServ identification is pending, else NO.
@property (nonatomic, assign) BOOL isZNCBouncerConnection;		// YES if Textual detected that this connection is ZNC based.
@property (nonatomic, assign) BOOL rawModeEnabled;				// YES if sent & received data should be logged to console, else NO.
@property (nonatomic, assign) BOOL reconnectEnabled;			// YES if reconnection is allowed, else NO.
@property (nonatomic, assign) BOOL serverHasNickServ;			// YES if NickServ service was found on server, else NO.
@property (nonatomic, assign) ClientIRCv3SupportedCapacities capacities;
@property (nonatomic, nweak) NSArray *channelList; // channelList is actually a proxy setter/getter for internal storage.
@property (nonatomic, copy) NSArray *cachedHighlights;
@property (nonatomic, strong) IRCChannel *lastSelectedChannel; // If this is the selected client, then the value of this property is the current selection. If the current client is not selected, then this value is either its previous selection or nil.
@property (nonatomic, copy) NSString *preAwayNickname; // Nickname before away was set.
@property (nonatomic, assign) NSTimeInterval lastMessageReceived;			// The time at which the last of any incoming data was received.
@property (nonatomic, assign) NSTimeInterval lastMessageServerTime;			// The time of the last message received that contained a server-time CAP.
@property (nonatomic, copy) NSString *serverRedirectAddressTemporaryStore; // Temporary store for RPL_BOUNCE (010) redirects.
@property (nonatomic, assign) NSInteger serverRedirectPortTemporaryStore; // Temporary store for RPL_BOUNCE (010) redirects.

// seed can be either an NSDictionary representation of an IRCClientConfig instance or an IRCClientConfig instance itself.
// Supplying an empty NSDictionary will result in the client using default values.
- (void)setup:(id)seed;

- (void)updateConfig:(IRCClientConfig *)seed;
- (void)updateConfig:(IRCClientConfig *)seed withSelectionUpdate:(BOOL)reloadSelection;

- (void)updateConfigFromTheCloud:(IRCClientConfig *)seed;

// Use -copyOfStoredConfig to return the configuration that DOES NOT contain any private messages.
// It is also a COPY, not the one used internally, which means it can be passed around and modified without
// fear that it will have any negative effects on the IRC client itself.
// Accessing -config property directly will return the current configuration used internally by the client.
// This configuration will include any associated private messages.
@property (readonly, copy) IRCClientConfig *copyOfStoredConfig;

// -dictionaryValue may return a value that contains private messages. This depends on whether
// end user has configured Textual to remember the state of queries between saves.
- (NSMutableDictionary *)dictionaryValue; // Values to be used for saving to NSUserDefaults and no other purposes.
- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary;

- (void)prepareForApplicationTermination;
- (void)prepareForPermanentDestruction; // Call -quit before invoking this or you know, use IRCWorld

- (void)preferencesChanged;

- (void)closeDialogs;

- (void)willDestroyChannel:(IRCChannel *)channel; // Callback for IRCWorld

@property (readonly, copy) NSString *uniqueIdentifier;

@property (readonly, copy) NSString *networkName; // Only returns the actual network name or nil.
@property (readonly, copy) NSString *altNetworkName; // Will return the configured name if the actual name is not available.
@property (readonly, copy) NSString *networkAddress;

@property (readonly, copy) NSString *localNickname;
@property (readonly, copy) NSString *localHostmask;

- (void)enableCapacity:(ClientIRCv3SupportedCapacities)capacity;
- (void)disableCapacity:(ClientIRCv3SupportedCapacities)capacity;

- (BOOL)isCapacityEnabled:(ClientIRCv3SupportedCapacities)capacity;

@property (readonly, copy) NSString *enabledCapacitiesStringValue;

@property (readonly) NSInteger channelCount;

- (void)addChannel:(IRCChannel *)channel;
- (void)addChannel:(IRCChannel *)channel atPosition:(NSInteger)pos;
- (void)removeChannel:(IRCChannel *)channel;

- (NSInteger)indexOfChannel:(IRCChannel *)channel;

- (void)updateStoredChannelList;

- (void)selectFirstChannelInChannelList;

- (void)addHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine;

@property (readonly) NSTimeInterval lastMessageServerTimeWithCachedValue;

- (BOOL)nicknameIsPrivateZNCUser:(NSString *)nickname;
- (NSString *)nicknameWithZNCUserPrefix:(NSString *)nickname;

- (void)reachabilityChanged:(BOOL)reachable;

- (void)autoConnect:(NSInteger)delay afterWakeUp:(BOOL)afterWakeUp;

@property (getter=isReconnecting, readonly) BOOL reconnecting;

- (void)postEventToViewController:(NSString *)eventToken;
- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel;

- (NSString *)encryptOutgoingMessage:(NSString *)message channel:(IRCChannel *)channel performedEncryption:(BOOL *)performedEncryption;
- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)channel;

- (IRCAddressBookEntry *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches;

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(TVCLogLineType)type;

- (void)sendFile:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken;

- (void)connect;
- (void)connect:(IRCClientConnectMode)mode;
- (void)connect:(IRCClientConnectMode)mode preferringIPv6:(BOOL)preferIPv6;

- (void)disconnect;
- (void)quit;
- (void)quit:(NSString *)comment;
- (void)cancelReconnect;

- (void)sendNextCap;
- (void)pauseCap;
- (void)resumeCap;
- (BOOL)isCapAvailable:(NSString *)cap;
- (void)cap:(NSString *)cap result:(BOOL)supported;

- (void)joinChannel:(IRCChannel *)channel;
- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password;
- (void)joinUnlistedChannel:(NSString *)channel;
- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password;
- (void)forceJoinChannel:(NSString *)channel password:(NSString *)password;
- (void)partChannel:(IRCChannel *)channel;
- (void)partChannel:(IRCChannel *)channel withComment:(NSString *)comment;
- (void)partUnlistedChannel:(NSString *)channel;
- (void)partUnlistedChannel:(NSString *)channel withComment:(NSString *)comment;

- (void)sendWhois:(NSString *)nick;
- (void)changeNickname:(NSString *)newNick;
- (void)kick:(IRCChannel *)channel target:(NSString *)nick;
- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPPing:(NSString *)target;

- (void)toggleAwayStatus:(BOOL)setAway;
- (void)toggleAwayStatus:(BOOL)setAway withReason:(NSString *)reason;

- (void)createChannelListDialog;
- (void)createChanBanListDialog;
- (void)createChanBanExceptionListDialog;
- (void)createChanInviteExceptionListDialog;

// Creating a channel will require Textual to create a new WebView
// Invoking this method on anything other than the main thread will
// crash Textual because WebView requires all operations to occur on
// the main thread. If you already are certain that the channel will
// already exist, then call from whatever thread you want.
- (IRCChannel *)findChannel:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name isPrivateMessage:(BOOL)isPM;

- (NSData *)convertToCommonEncoding:(NSString *)data;
- (NSString *)convertFromCommonEncoding:(NSData *)data;

// Defaults to TVCLogLineUndefinedNicknameFormat
- (NSString *)formatNickname:(NSString *)nick channel:(IRCChannel *)channel;
- (NSString *)formatNickname:(NSString *)nick channel:(IRCChannel *)channel formatOverride:(NSString *)forcedFormat;

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype;
- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text;
- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text userInfo:(NSDictionary *)userInfo;

- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text;

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize requestIdentifier:(NSString *)identifier;

- (void)populateISONTrackedUsersList:(NSArray *)ignores;

#pragma mark -

/* WARNING:
 
	WebKit which Textual uses for rendering messages will crash if it is not
	interacted with on the main thread. Therefore, always make sure you send
	messages on the main thread. Otherwise, happy crashing. :)
 */

- (void)sendCommand:(id)str;
- (void)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName;
- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel;
- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel withEncryption:(BOOL)encryptChat;
- (void)inputText:(id)str command:(NSString *)command; // This is call invoked by the input text field. There is no reason to call directly.

- (void)sendLine:(NSString *)str;
- (void)send:(NSString *)str, ...;

/* When using -sendPrivmsgToSelectedChannel:, if the actual selected channel in the main
 window is not owned by this client, then the message will be sent to the server console. */
/* The method obviously does not work as expected so it has been marked as deprecated.
 However, it will remain functional for plugin authors who wish to use it. */
- (void)sendPrivmsgToSelectedChannel:(NSString *)message TEXTUAL_DEPRECATED("Use sendPrivmsg:toChannel: instead");

- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel;
- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel;
- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel;

#pragma mark -

/* ------ */
/* Printing to the WebView for each channel/server in Textual is actually very complicated and
 over the years there have been a lot of design changes. The current design works like the 
 following:
 
 1. print… method is called with all associated information. 
 2. Once called, the code behind it parses the input and places all relevant information inside
 a copy of TVCLogLine which is then passed around. 
 3. Once the instance of TVCLogLine is created, it is handed down to the associated TVCLogController
 for either the server console or the actual channel view. TVCLogController will then attach the 
 copy of TVCLogLine to a background concurrent operation queue. Each server is assigned its very 
 own concurrent queue. On the queue, each print operation occurs. This is done to allow all work 
 to be processed in the background without locking up the main thread. It is also designed so 
 incoming spam on one server does not interfere with the operations of another server. Each 
 printing operation is handled on a first come, first served basis. 
 4. When an individual print operation is fired, the renderring of each message to HTML occurs. 
 This is the heaviest part of the printing operation as it requires extensive text based analysis
 of the actual incoming message. Once completed, the actual HTML is handed off back to the main
 thread where WebKit handles all the drawing operations. At that point it is out of the hands of
 Textual and will be displayed to the user as soon as WebKit renders it. */
/* All print calls point to this single one: */
- (void)printToWebView:(id)channel													// An IRCChannel or nil for the console.
				  type:(TVCLogLineType)type											// The time the message was received at for the timestamp.
			   command:(NSString *)command											// The line type. See TVCLogLine.h
			  nickname:(NSString *)nickname											// The nickname associated with the print.
		   messageBody:(NSString *)messageBody										// The actual text being printed.
		   isEncrypted:(BOOL)isEncrypted											// Is the text encrypted? This flag DOES NOT encrypt it. It informs the WebView if it was in fact encrypted so it can be treated with more privacy.
			receivedAt:(NSDate *)receivedAt											// Can be the actual command (PRIVMSG, NOTICE, etc.) or a raw numeric (001, 002, etc.) — … TVCLogLineDefaultRawCommandValue = internal debug command.
	  referenceMessage:(IRCMessage *)referenceMessage								// Actual IRCMessage to associate with the print job.
	   completionBlock:(IRCClientPrintToWebViewCallbackBlock)completionBlock;		// A block to call when the actual print occurs.
/* ------ */

- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody command:(NSString *)command;
- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody receivedAt:(NSDate *)receivedAt command:(NSString *)command;
- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody isEncrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command;
- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody isEncrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command referenceMessage:(IRCMessage *)referenceMessage;

- (void)printReply:(IRCMessage *)m;
- (void)printUnknownReply:(IRCMessage *)m;

- (void)printDebugInformation:(NSString *)m;
- (void)printDebugInformation:(NSString *)m forCommand:(NSString *)command;

- (void)printDebugInformationToConsole:(NSString *)m;
- (void)printDebugInformationToConsole:(NSString *)m forCommand:(NSString *)command;

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel;
- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel command:(NSString *)command;

- (void)printError:(NSString *)error forCommand:(NSString *)command;

- (void)printErrorReply:(IRCMessage *)m;
- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel;
@end
