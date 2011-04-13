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
	NSMutableArray *commandQueue;
	
	NSMutableDictionary *trackedUsers;
	
	NSInteger connectDelay;
	NSInteger tryingNickNumber;
	
	BOOL isAway;
	BOOL hasIRCopAccess;
	
	BOOL sendLagcheckToChannel;
	
	BOOL reconnectEnabled;
	BOOL rawModeEnabled;
	BOOL retryEnabled;
	BOOL isConnecting;
	BOOL isConnected;
	BOOL isLoggedIn;
	BOOL isQuitting;
	
	BOOL serverHasNickServ;
	BOOL autojoinInitialized;
	
	BOOL inList;
	BOOL identifyMsg;
	BOOL identifyCTCP;
	BOOL inChanBanList;
	BOOL inFirstISONRun;
	BOOL inWhoWasRequest;
	
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
	
	FileLogger *logFile;
	
#ifdef IS_TRIAL_BINARY
	Timer *trialPeriodTimer;
#endif
}

@property (retain) IRCWorld *world;
@property (retain) IRCConnection *conn;
@property (retain) IRCClientConfig *config;
@property (retain) IRCISupportInfo *isupport;
@property (retain) IRCChannel *whoisChannel;
@property (retain) IRCChannel *lastSelectedChannel;
@property (retain) NSMutableArray *channels;
@property (retain) NSMutableArray *commandQueue;
@property (retain) NSMutableDictionary *trackedUsers;
@property (assign) CFAbsoluteTime lastLagCheck;
@property (assign, setter=autoConnect:, getter=connectDelay) NSInteger connectDelay;
@property (assign) NSInteger tryingNickNumber;
@property (assign) BOOL isAway;
@property (assign) BOOL inList;
@property (assign) BOOL identifyMsg;
@property (assign) BOOL identifyCTCP;
@property (assign) BOOL inChanBanList;
@property (assign) BOOL inFirstISONRun;
@property (assign) BOOL inWhoWasRequest;
@property (assign) BOOL hasIRCopAccess;
@property (assign) BOOL reconnectEnabled;
@property (assign) BOOL rawModeEnabled;
@property (assign) BOOL retryEnabled;
@property (assign) BOOL isConnecting;
@property (assign) BOOL isConnected;
@property (assign) BOOL isLoggedIn;
@property (assign) BOOL isQuitting;
@property (assign) BOOL serverHasNickServ;
@property (assign) BOOL autojoinInitialized;
@property (assign) BOOL sendLagcheckToChannel;
@property (retain) FileLogger *logFile;
@property (assign) NSStringEncoding encoding;
@property (retain) NSString *logDate;
@property (retain) NSString *inputNick;
@property (retain) NSString *sentNick;
@property (retain) NSString *myNick;
@property (retain) NSString *myHost;
@property (retain) NSString *serverHostname;
@property (retain) Timer *isonTimer;
@property (retain) Timer *pongTimer;
@property (retain) Timer *retryTimer;
@property (retain) Timer *autoJoinTimer;
@property (retain) Timer *reconnectTimer;
@property (retain) Timer *commandQueueTimer;
@property (assign) ConnectMode connectType;
@property (assign) DisconnectType disconnectType;
@property (retain) ListDialog *channelListDialog;
@property (retain) ChanBanSheet *chanBanListSheet;
@property (retain) ChanBanExceptionSheet *banExceptionSheet;
@property (retain) ChanInviteExceptionSheet *inviteExceptionSheet;

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

- (void)joinChannels:(NSArray *)chans;
- (void)joinChannel:(IRCChannel *)channel;
- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password;
- (void)joinUnlistedChannel:(NSString *)channel;
- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password;
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

- (BOOL)inputText:(NSString *)s command:(NSString *)command;
- (BOOL)sendCommand:(NSString *)s;
- (BOOL)sendCommand:(NSString *)s completeTarget:(BOOL)completeTarget target:(NSString *)target;
- (void)sendText:(NSString *)s command:(NSString *)command channel:(IRCChannel *)channel;

- (void)sendLine:(NSString *)str;
- (void)send:(NSString *)str, ...;

- (NSInteger)indexOfTalkChannel;

- (IRCChannel *)findChannel:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name useTalk:(BOOL)doTalk;

- (void)sendPrivmsgToSelectedChannel:(NSString *)message;

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text;
- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text ;
- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime;

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified;
- (BOOL)printChannel:(IRCChannel *)channel type:(LogLineType)type text:(NSString *)text;
- (BOOL)printAndLog:(LogLine *)line withHTML:(BOOL)rawHTML;
- (BOOL)printChannel:(IRCChannel *)channel type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified;
- (void)printSystem:(id)channel text:(NSString *)text;
- (void)printSystemBoth:(id)channel text:(NSString *)text;
- (void)printReply:(IRCMessage *)m;
- (void)printUnknownReply:(IRCMessage *)m;
- (void)printDebugInformation:(NSString *)m;
- (void)printDebugInformationToConsole:(NSString *)m;
- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel;
- (void)printErrorReply:(IRCMessage *)m;
- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel;
- (void)printError:(NSString *)error;

- (BOOL)notifyEvent:(GrowlNotificationType)type lineType:(LogLineType)ltype;
- (BOOL)notifyEvent:(GrowlNotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;
- (BOOL)notifyText:(GrowlNotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text;

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores;

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(LogLineType)type;

@end