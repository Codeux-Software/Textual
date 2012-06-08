// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCWorld;

typedef enum {
	CONNECT_NORMAL,
	CONNECT_RETRY,
	CONNECT_RECONNECT,
	CONNECT_BADSSL_CRT_RECONNECT,
} ConnectMode;

typedef enum {
	DISCONNECT_NORMAL,
	DISCONNECT_TRIAL_PERIOD,
	DISCONNECT_BAD_SSL_CERT,
    DISCONNECT_SLEEP_MODE,
} DisconnectType;

@interface IRCClient : IRCTreeItem
{
	IRCWorld *world;
	IRCConnection *conn;
	IRCClientConfig *config;
	IRCISupportInfo *isupport;
	
	IRCChannel *whoisChannel;
	IRCChannel *lastSelectedChannel;
	
	NSMutableArray *channels;
	NSMutableArray *highlights;
	NSMutableArray *commandQueue;
	
	NSMutableDictionary *trackedUsers;
	
	NSInteger connectDelay;
	NSInteger tryingNickNumber;
	
	NSMutableArray *pendingCaps;
	NSMutableArray *acceptedCaps;
	
	NSUInteger capPaused;

	BOOL isAway;
	BOOL hasIRCopAccess;
	
	BOOL sendLagcheckToChannel;
	
    BOOL isIdentifiedWithSASL;
	BOOL reconnectEnabled;
	BOOL rawModeEnabled;
	BOOL retryEnabled;
	BOOL isConnecting;
	BOOL isConnected;
	BOOL isLoggedIn;
	BOOL isQuitting;
	
	BOOL serverHasNickServ;
	BOOL autojoinInitialized;
	
	BOOL userhostInNames;
	BOOL multiPrefix;
	BOOL identifyMsg;
	BOOL identifyCTCP;
	BOOL inWhoInfoRun;
    BOOL inSASLRequest;
	BOOL inWhoWasRun;
	BOOL inFirstISONRun;
	
	CFAbsoluteTime lastLagCheck;
	
	NSStringEncoding encoding;
	
	NSString *logDate;
	
	NSString *inputNick;
	NSString *sentNick;
	NSString *myNick;
	NSString *myHost;
	
	NSString *serverHostname;
	
	Timer *isonTimer;
	Timer *pongTimer;
	Timer *retryTimer;
	Timer *autoJoinTimer;
	Timer *reconnectTimer;
	Timer *commandQueueTimer;
	
	ConnectMode connectType;
	DisconnectType disconnectType;
	
	ListDialog *channelListDialog;
	ChanBanSheet *chanBanListSheet;
	ChanBanExceptionSheet *banExceptionSheet;
	ChanInviteExceptionSheet *inviteExceptionSheet;
	
	NSInteger lastMessageReceived;
	
	FileLogger *logFile;
	
#ifdef IS_TRIAL_BINARY
	Timer *trialPeriodTimer;
#endif
}

@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, strong) IRCConnection *conn;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, strong) IRCISupportInfo *isupport;
@property (nonatomic, strong) IRCChannel *whoisChannel;
@property (nonatomic, strong) IRCChannel *lastSelectedChannel;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *highlights;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, strong) NSMutableArray *pendingCaps;
@property (nonatomic, strong) NSMutableArray *acceptedCaps;
@property (nonatomic, assign) CFAbsoluteTime lastLagCheck;
@property (nonatomic, assign, setter=autoConnect:, getter=connectDelay) NSInteger connectDelay;
@property (nonatomic, assign) NSInteger tryingNickNumber;
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
@property (nonatomic, strong) FileLogger *logFile;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, strong) NSString *logDate;
@property (nonatomic, strong) NSString *inputNick;
@property (nonatomic, strong) NSString *sentNick;
@property (nonatomic, strong) NSString *myNick;
@property (nonatomic, strong) NSString *myHost;
@property (nonatomic, strong) NSString *serverHostname;
@property (nonatomic, strong) Timer *isonTimer;
@property (nonatomic, strong) Timer *pongTimer;
@property (nonatomic, strong) Timer *retryTimer;
@property (nonatomic, strong) Timer *autoJoinTimer;
@property (nonatomic, strong) Timer *reconnectTimer;
@property (nonatomic, strong) Timer *commandQueueTimer;
@property (nonatomic, assign) NSInteger lastMessageReceived;
@property (nonatomic, assign) ConnectMode connectType;
@property (nonatomic, assign) DisconnectType disconnectType;
@property (nonatomic, strong) ListDialog *channelListDialog;
@property (nonatomic, strong) ChanBanSheet *chanBanListSheet;
@property (nonatomic, strong) ChanBanExceptionSheet *banExceptionSheet;
@property (nonatomic, strong) ChanInviteExceptionSheet *inviteExceptionSheet;

- (void)setup:(IRCClientConfig *)seed;
- (void)updateConfig:(IRCClientConfig *)seed;
- (IRCClientConfig *)storedConfig;
- (NSMutableDictionary *)dictionaryValue;

- (void)autoConnect:(NSInteger)delay;
- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (BOOL)isReconnecting;

- (AddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches;

- (BOOL)encryptOutgoingMessage:(NSString **)message channel:(IRCChannel *)chan;
- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)chan;

- (void)connect;
- (void)connect:(ConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString *)comment;
- (void)cancelReconnect;

- (BOOL)IRCopStatus;

- (void)sendNextCap;
- (void)pauseCap;
- (void)resumeCap;
- (BOOL)isCapAvailable:(NSString*)cap;
- (void)cap:(NSString*)cap result:(BOOL)supported;

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

- (void)sendPrivmsgToSelectedChannel:(NSString *)message;

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime receivedAt:(NSDate*)receivedAt;

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text;
- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate*)receivedAt;
- (BOOL)printChannel:(IRCChannel *)channel type:(LogLineType)type text:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (BOOL)printAndLog:(LogLine *)line withHTML:(BOOL)rawHTML;
- (BOOL)printChannel:(IRCChannel *)channel type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate*)receivedAt;
- (void)printSystem:(id)channel text:(NSString *)text;
- (void)printSystem:(id)channel text:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (void)printSystemBoth:(id)channel text:(NSString *)text;
- (void)printSystemBoth:(id)channel text:(NSString *)text receivedAt:(NSDate*)receivedAt;
- (void)printReply:(IRCMessage *)m;
- (void)printUnknownReply:(IRCMessage *)m;
- (void)printDebugInformation:(NSString *)m;
- (void)printDebugInformationToConsole:(NSString *)m;
- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel;
- (void)printErrorReply:(IRCMessage *)m;
- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel;
- (void)printError:(NSString *)error;

- (BOOL)notifyEvent:(NotificationType)type lineType:(LogLineType)ltype;
- (BOOL)notifyEvent:(NotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;
- (BOOL)notifyText:(NotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores;

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(LogLineType)type;

@end
