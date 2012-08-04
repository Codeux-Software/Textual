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
	IRCTrialPeriodDisconnectMode,
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
@property (nonatomic, strong) NSMutableArray *highlights;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, strong) NSMutableArray *pendingCaps;
@property (nonatomic, strong) NSMutableArray *acceptedCaps;
@property (nonatomic, assign) CFAbsoluteTime lastLagCheck;
@property (nonatomic, assign, setter=autoConnect:) NSInteger connectDelay;
@property (nonatomic, assign) NSInteger tryingNickNumber;
@property (nonatomic, assign) NSUInteger capPaused;
@property (nonatomic, assign) BOOL isAway;
@property (nonatomic, assign) BOOL inWhoInfoRun;
@property (nonatomic, assign) BOOL inWhoWasRun;
@property (nonatomic, assign) BOOL userhostInNames;
@property (nonatomic, assign) BOOL multiPrefix;
@property (nonatomic, assign) BOOL identifyMsg;
@property (nonatomic, assign) BOOL identifyCTCP;
@property (nonatomic, assign) BOOL inFirstISONRun;
@property (nonatomic, assign) BOOL hasIRCopAccess;
@property (nonatomic, assign) BOOL reconnectEnabled;
@property (nonatomic, assign) BOOL rawModeEnabled;
@property (nonatomic, assign) BOOL retryEnabled;
@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isLoggedIn;
@property (nonatomic, assign) BOOL isQuitting;
@property (nonatomic, assign) BOOL inSASLRequest;
@property (nonatomic, assign) BOOL serverHasNickServ;
@property (nonatomic, assign) BOOL autojoinInitialized;
@property (nonatomic, assign) BOOL sendLagcheckToChannel;
@property (nonatomic, assign) BOOL isIdentifiedWithSASL;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, strong) NSString *inputNick;
@property (nonatomic, strong) NSString *sentNick;
@property (nonatomic, strong) NSString *myNick;
@property (nonatomic, strong) NSString *myHost;
@property (nonatomic, strong) NSString *serverHostname;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *autoJoinTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;

#ifdef IS_TRIAL_BINARY
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
- (void)changeOp:(IRCChannel *)channel users:(NSArray *)users mode:(char)mode value:(BOOL)value;
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

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified TEXTUAL_DEPRECATED;
- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt TEXTUAL_DEPRECATED;
- (BOOL)printChannel:(IRCChannel *)channel type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt TEXTUAL_DEPRECATED;
@end