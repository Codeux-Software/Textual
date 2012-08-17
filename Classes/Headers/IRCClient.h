/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

typedef enum IRCConnectMode : NSInteger {
	IRCConnectNormalMode,
	IRCConnectionRetryMode,
	IRCNormalReconnectionMode,
	IRCBadSSLCertificateReconnectMode,
} IRCConnectMode;

typedef enum IRCDisconnectType : NSInteger {
	IRCDisconnectNormalMode,

#ifdef TEXTUAL_TRIAL_BINARY
	IRCTrialPeriodDisconnectMode,
#endif

	IRCBadSSLCertificateDisconnectMode,
    IRCSleepModeDisconnectMode,
} IRCDisconnectType;

@interface IRCClient : IRCTreeItem
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, strong) IRCConnection *conn;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, strong) IRCISupportInfo *isupport;
@property (nonatomic, strong) IRCChannel *whoisChannel;
@property (nonatomic, strong) IRCChannel *lastSelectedChannel;
@property (nonatomic, assign) IRCConnectMode connectType;
@property (nonatomic, assign) IRCDisconnectType disconnectType;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableArray *highlights;
@property (nonatomic, strong) NSMutableArray *pendingCaps;
@property (nonatomic, strong) NSMutableArray *acceptedCaps;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, assign) CFAbsoluteTime lastLagCheck;
@property (nonatomic, assign, setter=autoConnect:) NSInteger connectDelay;
@property (nonatomic, assign) NSInteger tryingNickNumber;		// Used for nick collision connections.
@property (nonatomic, assign) NSUInteger capPaused;				// Used as a BOOL, but can also represent an integer in special cases.
@property (nonatomic, assign) BOOL isAway;					// YES if Textuak has knowledge of local user being away, else NO.
@property (nonatomic, assign) BOOL inWhoInfoRun;			// YES if user invoked /WHO and should output results, else NO.
@property (nonatomic, assign) BOOL inWhoWasRun;				// YES if WHOIS information should be treated as WHOWAS.
@property (nonatomic, assign) BOOL userhostInNames;			// YES if userhost-in-names CAP supported.
@property (nonatomic, assign) BOOL multiPrefix;				// YES if multi-prefix CAP supported.
@property (nonatomic, assign) BOOL identifyMsg;				// YES if identify-msg CAP supported.
@property (nonatomic, assign) BOOL identifyCTCP;			// YES if identify-ctcp CAP supported.
@property (nonatomic, assign) BOOL inFirstISONRun;			// YES if first time running ISON command for user trackig, else NO.
@property (nonatomic, assign) BOOL hasIRCopAccess;			// YES if local user is IRCOp, else NO.
@property (nonatomic, assign) BOOL reconnectEnabled;		// YES if reconnection is allowed, else NO.
@property (nonatomic, assign) BOOL rawModeEnabled;			// YES if sent & received data should be logged to console, else NO.
@property (nonatomic, assign) BOOL isConnecting;			// YES if socket is connecting, else, NO. Set to NO on raw numeric 001.
@property (nonatomic, assign) BOOL isConnected;				// YES if socket is connected, else NO.
@property (nonatomic, assign) BOOL isLoggedIn;				// YES if connected to server, else NO. Set to YES on raw numeric 001.
@property (nonatomic, assign) BOOL isQuitting;				// YES if connection to IRC server is being quit, else NO.
@property (nonatomic, assign) BOOL inSASLRequest;			// YES if in SASL CAP authentication request, else NO.
@property (nonatomic, assign) BOOL serverHasNickServ;		// YES if NickServ service was found on server, else NO.
@property (nonatomic, assign) BOOL autojoinInitialized;		// YES if autojoin in process of running, else NO.
@property (nonatomic, assign) BOOL sendLagcheckToChannel;	// YES if CTCP LAGCHECK reply should be posted to active channel, else NO.
@property (nonatomic, assign) BOOL isIdentifiedWithSASL;	// YES if SASL authentication was successful, else NO.
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, strong) NSString *sentNick;			// Nickname used for nick collision connections. Is equal to myNick if there is no collision.
@property (nonatomic, strong) NSString *myNick;				// Cached value of local user nickname.
@property (nonatomic, strong) NSString *myHost;				// Host of local user cached during JOIN.
@property (nonatomic, strong) TLOTimer *isonTimer;			// Timer responsible for sending ISON commands for user tracking.
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *autoJoinTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;		// "/timer" command queue.

#ifdef TEXTUAL_TRIAL_BINARY
@property (nonatomic, strong) TLOTimer *trialPeriodTimer;
#endif

@property (nonatomic, assign) NSInteger lastMessageReceived;
@property (nonatomic, strong) TDCListDialog *channelListDialog;
@property (nonatomic, strong) TDChanBanSheet *chanBanListSheet;
@property (nonatomic, strong) TDChanBanExceptionSheet *banExceptionSheet;
@property (nonatomic, strong) TDChanInviteExceptionSheet *inviteExceptionSheet;

- (void)setup:(IRCClientConfig *)seed;
- (void)updateConfig:(IRCClientConfig *)seed;
- (IRCClientConfig *)storedConfig;
- (NSMutableDictionary *)dictionaryValue;

- (void)autoConnect:(NSInteger)delay;
- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (BOOL)isReconnecting;

- (IRCAddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches;

- (BOOL)encryptOutgoingMessage:(NSString **)message channel:(IRCChannel *)chan;
- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)chan;

- (void)connect;
- (void)connect:(IRCConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString *)comment;
- (void)cancelReconnect;

- (BOOL)IRCopStatus;

- (void)sendNextCap;
- (void)pauseCap;
- (void)resumeCap;
- (BOOL)isCapAvailable:(NSString *)cap;
- (void)cap:(NSString *)cap result:(BOOL)supported;

- (void)joinChannels:(NSArray *)chans;
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
- (void)changeNick:(NSString *)newNick;
- (void)kick:(IRCChannel *)channel target:(NSString *)nick;
- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPPing:(NSString *)target;

- (void)createChannelListDialog;
- (void)createChanBanListDialog;
- (void)createChanBanExceptionListDialog;
- (void)createChanInviteExceptionListDialog;

- (BOOL)sendCommand:(id)str;
- (BOOL)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName;
- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel;
- (BOOL)inputText:(id)str command:(NSString *)command;

- (void)sendLine:(NSString *)str;
- (void)send:(NSString *)str, ...;

- (NSInteger)indexOfTalkChannel;

- (IRCChannel *)findChannel:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name useTalk:(BOOL)doTalk;

- (NSData *)convertToCommonEncoding:(NSString *)data;
- (NSString *)convertFromCommonEncoding:(NSData *)data;

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel;

- (void)sendPrivmsgToSelectedChannel:(NSString *)message;

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime receivedAt:(NSDate *)receivedAt;

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type text:(NSString *)text;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)printChannel:(IRCChannel *)channel type:(TVCLogLineType)type text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)printAndLog:(TVCLogLine *)line withHTML:(BOOL)rawHTML;
- (BOOL)printChannel:(IRCChannel *)channel type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (void)printSystem:(id)channel text:(NSString *)text;
- (void)printSystem:(id)channel text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (void)printSystemBoth:(id)channel text:(NSString *)text;
- (void)printSystemBoth:(id)channel text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (void)printReply:(IRCMessage *)m;
- (void)printUnknownReply:(IRCMessage *)m;
- (void)printDebugInformation:(NSString *)m;
- (void)printDebugInformationToConsole:(NSString *)m;
- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel;
- (void)printErrorReply:(IRCMessage *)m;
- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel;
- (void)printError:(NSString *)error;

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype;
- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;
- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores;

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(TVCLogLineType)type;

- (void)changeOp:(IRCChannel *)channel users:(NSArray *)users mode:(char)mode value:(BOOL)value TEXTUAL_DEPRECATED;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified TEXTUAL_DEPRECATED;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt TEXTUAL_DEPRECATED;
- (BOOL)printChannel:(IRCChannel *)channel type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt TEXTUAL_DEPRECATED;
@end