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

@property (strong) IRCWorld *world;
@property (strong) IRCConnection *conn;
@property (strong) IRCClientConfig *config;
@property (strong) IRCISupportInfo *isupport;
@property (strong) IRCChannel *whoisChannel;
@property (strong) IRCChannel *lastSelectedChannel;
@property (strong) NSMutableArray *channels;
@property (strong) NSMutableArray *highlights;
@property (strong) NSMutableArray *commandQueue;
@property (strong) NSMutableDictionary *trackedUsers;
@property (strong) NSMutableArray *pendingCaps;
@property (strong) NSMutableArray *acceptedCaps;
@property (assign) CFAbsoluteTime lastLagCheck;
@property (assign, setter=autoConnect:, getter=connectDelay) NSInteger connectDelay;
@property (assign) NSInteger tryingNickNumber;
@property (assign) BOOL isAway;
@property (assign) BOOL inWhoInfoRun;
@property (assign) BOOL inWhoWasRun;
@property (assign) BOOL userhostInNames;
@property (assign) BOOL multiPrefix;
@property (assign) BOOL identifyMsg;
@property (assign) BOOL identifyCTCP;
@property (assign) BOOL inFirstISONRun;
@property (assign) BOOL hasIRCopAccess;
@property (assign) BOOL reconnectEnabled;
@property (assign) BOOL rawModeEnabled;
@property (assign) BOOL retryEnabled;
@property (assign) BOOL isConnecting;
@property (assign) BOOL isConnected;
@property (assign) BOOL isLoggedIn;
@property (assign) BOOL isQuitting;
@property (assign) BOOL inSASLRequest;
@property (assign) BOOL serverHasNickServ;
@property (assign) BOOL autojoinInitialized;
@property (assign) BOOL sendLagcheckToChannel;
@property (assign) BOOL isIdentifiedWithSASL;
@property (strong) FileLogger *logFile;
@property (assign) NSStringEncoding encoding;
@property (strong) NSString *logDate;
@property (strong) NSString *inputNick;
@property (strong) NSString *sentNick;
@property (strong) NSString *myNick;
@property (strong) NSString *myHost;
@property (strong) NSString *serverHostname;
@property (strong) Timer *isonTimer;
@property (strong) Timer *pongTimer;
@property (strong) Timer *retryTimer;
@property (strong) Timer *autoJoinTimer;
@property (strong) Timer *reconnectTimer;
@property (strong) Timer *commandQueueTimer;
@property (assign) NSInteger lastMessageReceived;
@property (assign) ConnectMode connectType;
@property (assign) DisconnectType disconnectType;
@property (strong) ListDialog *channelListDialog;
@property (strong) ChanBanSheet *chanBanListSheet;
@property (strong) ChanBanExceptionSheet *banExceptionSheet;
@property (strong) ChanInviteExceptionSheet *inviteExceptionSheet;

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
