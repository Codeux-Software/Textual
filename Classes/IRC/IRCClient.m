// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <arpa/inet.h>
#import <mach/mach_time.h>

#define TIMEOUT_INTERVAL			360
#define PING_INTERVAL				270
#define RETRY_INTERVAL				240
#define RECONNECT_INTERVAL			20
#define ISON_CHECK_INTERVAL			30
#define TRIAL_PERIOD_INTERVAL		7200
#define AUTOJOIN_DELAY_INTERVAL		2
#define PONG_CHECK_INTERVAL			30

static NSDateFormatter *dateTimeFormatter = nil;

@interface IRCClient (Private)
- (void)setKeywordState:(id)target;
- (void)setNewTalkState:(id)target;
- (void)setUnreadState:(id)target;

- (void)receivePrivmsgAndNotice:(IRCMessage *)message;
- (void)receiveJoin:(IRCMessage *)message;
- (void)receivePart:(IRCMessage *)message;
- (void)receiveKick:(IRCMessage *)message;
- (void)receiveQuit:(IRCMessage *)message;
- (void)receiveKill:(IRCMessage *)message;
- (void)receiveNick:(IRCMessage *)message;
- (void)receiveMode:(IRCMessage *)message;
- (void)receiveTopic:(IRCMessage *)message;
- (void)receiveInvite:(IRCMessage *)message;
- (void)receiveError:(IRCMessage *)message;
- (void)receivePing:(IRCMessage *)message;
- (void)receiveNumericReply:(IRCMessage *)message;

- (void)receiveInit:(IRCMessage *)message;
- (void)receiveText:(IRCMessage *)m command:(NSString *)cmd text:(NSString *)text identified:(BOOL)identified;
- (void)receiveCTCPQuery:(IRCMessage *)message text:(NSString *)text;
- (void)receiveCTCPReply:(IRCMessage *)message text:(NSString *)text;
- (void)receiveErrorNumericReply:(IRCMessage *)message;
- (void)receiveNickCollisionError:(IRCMessage *)message;

- (void)tryAnotherNick;
- (void)changeStateOff;
- (void)performAutoJoin;

- (void)addCommandToCommandQueue:(TimerCommand *)m;
- (void)clearCommandQueue;

- (void)handleUserTrackingNotification:(AddressBook *)ignoreItem 
							  nickname:(NSString *)nick
							  hostmask:(NSString *)host
							  langitem:(NSString *)localKey;

@end

@implementation IRCClient

@synthesize autoJoinTimer;
@synthesize autojoinInitialized;
@synthesize banExceptionSheet;
@synthesize chanBanListSheet;
@synthesize channelListDialog;
@synthesize channels;
@synthesize commandQueue;
@synthesize commandQueueTimer;
@synthesize config;
@synthesize conn;
@synthesize connectType;
@synthesize disconnectType;
@synthesize encoding;
@synthesize hasIRCopAccess;
@synthesize highlights;
@synthesize pendingCaps;
@synthesize acceptedCaps;
@synthesize userhostInNames;
@synthesize multiPrefix;
@synthesize identifyCTCP;
@synthesize identifyMsg;
@synthesize inWhoInfoRun;
@synthesize inWhoWasRun;
@synthesize inFirstISONRun;
@synthesize inputNick;
@synthesize inviteExceptionSheet;
@synthesize isAway;
@synthesize isConnected;
@synthesize isConnecting;
@synthesize isLoggedIn;
@synthesize isQuitting;
@synthesize isonTimer;
@synthesize isupport;
@synthesize lastLagCheck;
@synthesize lastSelectedChannel;
@synthesize logDate;
@synthesize logFile;
@synthesize myHost;
@synthesize myNick;
@synthesize pongTimer;
@synthesize rawModeEnabled;
@synthesize reconnectEnabled;
@synthesize reconnectTimer;
@synthesize retryEnabled;
@synthesize retryTimer;
@synthesize sentNick;
@synthesize sendLagcheckToChannel;
@synthesize isIdentifiedWithSASL;
@synthesize serverHasNickServ;
@synthesize serverHostname;
@synthesize trackedUsers;
@synthesize tryingNickNumber;
@synthesize whoisChannel;
@synthesize inSASLRequest;
@synthesize lastMessageReceived;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		tryingNickNumber = -1;
		
		capPaused = 0;
		userhostInNames = NO;
		multiPrefix = NO;
		identifyMsg = NO;
		identifyCTCP = NO;
		
		channels     = [NSMutableArray new];
		highlights   = [NSMutableArray new];
		commandQueue = [NSMutableArray new];
		acceptedCaps = [NSMutableArray new];
		pendingCaps	 = [NSMutableArray new];
		
		trackedUsers = [NSMutableDictionary new];
		
		isupport = [IRCISupportInfo new];
		
		isAway		   = NO;
		hasIRCopAccess = NO;
		
		reconnectTimer			= [Timer new];
		reconnectTimer.delegate = self;
		reconnectTimer.reqeat	= NO;
		reconnectTimer.selector = @selector(onReconnectTimer:);
		
		retryTimer			= [Timer new];
		retryTimer.delegate = self;
		retryTimer.reqeat	= NO;
		retryTimer.selector = @selector(onRetryTimer:);
		
		autoJoinTimer			= [Timer new];
		autoJoinTimer.delegate	= self;
		autoJoinTimer.reqeat	= YES;
		autoJoinTimer.selector	= @selector(onAutoJoinTimer:);
		
		commandQueueTimer			= [Timer new];
		commandQueueTimer.delegate	= self;
		commandQueueTimer.reqeat	= NO;
		commandQueueTimer.selector	= @selector(onCommandQueueTimer:);
		
		pongTimer			= [Timer new];
		pongTimer.delegate	= self;
		pongTimer.reqeat	= YES;
		pongTimer.selector	= @selector(onPongTimer:);
		
		isonTimer			= [Timer new];
		isonTimer.delegate	= self;
		isonTimer.reqeat	= YES;
		isonTimer.selector	= @selector(onISONTimer:);
		
#ifdef IS_TRIAL_BINARY
		trialPeriodTimer			= [Timer new];
		trialPeriodTimer.delegate	= self;
		trialPeriodTimer.reqeat		= NO;
		trialPeriodTimer.selector	= @selector(onTrialPeriodTimer:);	
#endif
	}
	
	return self;
}

- (void)dealloc
{
	[autoJoinTimer stop];
	[commandQueueTimer stop];
	[conn close];
	[isonTimer stop];
	[pongTimer stop];
	[reconnectTimer stop];
	[retryTimer stop];
	
#ifdef IS_TRIAL_BINARY
	[trialPeriodTimer stop];
#endif
	
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCClientConfig *)seed
{
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	config = nil;
	
	config = [seed mutableCopy];
	
	NSArray *chans = config.channels;
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCChannelConfig *i in chans) {
		IRCChannel *c = [self findChannel:i.name];
		
		if (c) {
			[c updateConfig:i];
			
			[ary safeAddObject:c];
			
			[channels removeObjectIdenticalTo:c];
		} else {
			c = [world createChannel:i client:self reload:NO adjust:NO];
			
			[ary safeAddObject:c];
		}
	}
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[self partChannel:c];
		} else {
			[ary safeAddObject:c];
		}
	}
	
	[channels removeAllObjects];
	[channels addObjectsFromArray:ary];
	
	[config.channels removeAllObjects];
	
	[world reloadTree];
	[world adjustSelection];
}

- (IRCClientConfig *)storedConfig
{
	IRCClientConfig *u = [config mutableCopy];
	
	[u.channels removeAllObjects];
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[u.channels safeAddObject:[c.config mutableCopy]];
		}
	}
	
	return u;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [config dictionaryValue];
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[ary safeAddObject:[c dictionaryValue]];
		}
	}
	
	[dic setObject:ary forKey:@"channels"];
	
	return dic;
}

#pragma mark -
#pragma mark Properties

- (NSString *)name
{
	return config.name;
}

- (BOOL)IRCopStatus
{
	return hasIRCopAccess;
}

- (BOOL)isNewTalk
{
	return NO;
}

- (BOOL)isReconnecting
{
	return (reconnectTimer && reconnectTimer.isActive);
}

#pragma mark -
#pragma mark User Tracking

- (void)handleUserTrackingNotification:(AddressBook *)ignoreItem 
							  nickname:(NSString *)nick
							  hostmask:(NSString *)host
							  langitem:(NSString *)localKey
{
	if ([ignoreItem notifyJoins] == YES) {
		NSString *text = TXTFLS(localKey, host, ignoreItem.hostmask);
		
		[self notifyEvent:NOTIFICATION_ADDRESS_BOOK_MATCH lineType:LINE_TYPE_NOTICE target:nil nick:nick text:text];
	}
}

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores
{
	if (hasIRCopAccess) return;
	if (isLoggedIn == NO) return;
	
	if (PointerIsEmpty(trackedUsers)) {
		trackedUsers = [NSMutableDictionary new];
	}
	
	if (NSObjectIsNotEmpty(trackedUsers)) {
		NSMutableDictionary *oldEntries = [NSMutableDictionary dictionary];
		NSMutableDictionary *newEntries = [NSMutableDictionary dictionary];
		
		for (NSString *lname in trackedUsers) {
			[oldEntries setObject:[trackedUsers objectForKey:lname] forKey:lname];
		}
		
		for (AddressBook *g in ignores) {
			if (g.notifyJoins) {
				NSString *lname = [g trackingNickname];
				
				if ([lname isNickname]) {
					if ([oldEntries containsKeyIgnoringCase:lname]) {
						[newEntries setObject:[oldEntries objectForKey:lname] forKey:lname];
					} else {
						[newEntries setBool:NO forKey:lname];
					}
				}
			}
		}
		
		trackedUsers = newEntries;
	} else {
		for (AddressBook *g in ignores) {
			if (g.notifyJoins) {
				NSString *lname = [g trackingNickname];
				
				if ([lname isNickname]) {
					[trackedUsers setBool:NO forKey:[g trackingNickname]];
				}
			}
		}
	}
	
	if (NSObjectIsNotEmpty(trackedUsers)) {
		[self performSelector:@selector(startISONTimer)];
	} else {
		[self performSelector:@selector(stopISONTimer)];
	}
}

#pragma mark -
#pragma mark Utilities

- (NSInteger)connectDelay
{
	return connectDelay;
}

- (void)autoConnect:(NSInteger)delay
{
	connectDelay = delay;
	
	[self connect];
}

- (void)terminate
{
	[self quit];
	[self closeDialogs];
	
	for (IRCChannel *c in channels) {
		[c terminate];
	}
	
	[self disconnect];
}

- (void)closeDialogs
{
	[channelListDialog close];
}

- (void)preferencesChanged
{
	log.maxLines = [Preferences maxLogLines];
	
	for (IRCChannel *c in channels) {
		[c preferencesChanged];
	}
}

- (void)reloadTree
{
	[world reloadTree];
}

- (AddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches
{
	host = [host lowercaseString];
	
	for (AddressBook *g in config.ignores) {
		if ([g checkIgnore:host]) {
			NSDictionary *ignoreDict = [g dictionaryValue];
			
			NSInteger totalMatches = 0;
			
			for (NSString *matchkey in matches) {
				if ([ignoreDict boolForKey:matchkey] == YES) {
					totalMatches++;
				}
			}
			
			if (totalMatches > 0) {
				return g;
			}
		}
	}
	
	return nil;
}


- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(LogLineType)type
{
	if ([Preferences removeAllFormatting]) {
		raw = [raw stripEffects];
	}
	
	NSString	 *rulekey = [LogLine lineTypeString:type];
	NSDictionary *rules   = world.bundlesWithOutputRules;
	
	if (NSObjectIsNotEmpty(rules)) {
		NSDictionary *ruleData = [rules dictionaryForKey:rulekey];
		
		if (NSObjectIsNotEmpty(ruleData)) {
			for (NSString *ruleRegex in ruleData) {
				if ([TXRegularExpression string:raw isMatchedByRegex:ruleRegex]) {
					NSArray *regexData = [ruleData arrayForKey:ruleRegex];
					
					BOOL console = [regexData boolAtIndex:0];
					BOOL channel = [regexData boolAtIndex:1];
					BOOL queries = [regexData boolAtIndex:2];
					
					if ([chan isKindOfClass:[IRCChannel class]]) {
						if ((chan.isTalk && queries) || (chan.isChannel && channel) || (chan.isClient && console)) {
							return YES;
						}
					} else {
						if (console) {
							return YES;
						}
					}
				}
			}
		}
	}
	
	return NO;
}

#pragma mark -
#pragma mark Channel Ban List Dialog

- (void)createChanBanListDialog
{
	if (PointerIsEmpty(chanBanListSheet)) {
		IRCClient *u = [world selectedClient];
		IRCChannel *c = [world selectedChannel];
		
		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;
		
		chanBanListSheet = [ChanBanSheet new];
		chanBanListSheet.delegate = self;
		chanBanListSheet.window = world.window;
	} else {
		[chanBanListSheet ok:nil];
		
		chanBanListSheet = nil;
		
		[self createChanBanListDialog];
		
		return;
	}
	
	[chanBanListSheet show];
}

- (void)chanBanDialogOnUpdate:(ChanBanSheet *)sender
{
    [sender.list removeAllObjects];
    
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+b", nil];
}

- (void)chanBanDialogWillClose:(ChanBanSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [world selectedChannel].name, mode]];
        }
    }
	
	chanBanListSheet = nil;
}

#pragma mark -
#pragma mark Channel Invite Exception List Dialog

- (void)createChanInviteExceptionListDialog
{
	if (inviteExceptionSheet) {
		[inviteExceptionSheet ok:nil];
		
		inviteExceptionSheet = nil;
		
		[self createChanInviteExceptionListDialog];
	} else {
		IRCClient *u = [world selectedClient];
		IRCChannel *c = [world selectedChannel];
		
		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;
		
		inviteExceptionSheet = [ChanInviteExceptionSheet new];
		inviteExceptionSheet.delegate = self;
		inviteExceptionSheet.window = world.window;
		[inviteExceptionSheet show];
	}
}

- (void)chanInviteExceptionDialogOnUpdate:(ChanInviteExceptionSheet *)sender
{
    [sender.list removeAllObjects];
    
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+I", nil];
}

- (void)chanInviteExceptionDialogWillClose:(ChanInviteExceptionSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [world selectedChannel].name, mode]];
        }
    }
	
	inviteExceptionSheet = nil;
}

#pragma mark -
#pragma mark Chan Ban Exception List Dialog

- (void)createChanBanExceptionListDialog
{
	if (PointerIsEmpty(banExceptionSheet)) {
		IRCClient *u = [world selectedClient];
		IRCChannel *c = [world selectedChannel];
		
		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;
		
		banExceptionSheet = [ChanBanExceptionSheet new];
		banExceptionSheet.delegate = self;
		banExceptionSheet.window = world.window;
	} else {
		[banExceptionSheet ok:nil];
		
		banExceptionSheet = nil;
		
		[self createChanBanExceptionListDialog];
		
		return;
	}
	
	[banExceptionSheet show];
}

- (void)chanBanExceptionDialogOnUpdate:(ChanBanExceptionSheet *)sender
{
    [sender.list removeAllObjects];
    
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+e", nil];
}

- (void)chanBanExceptionDialogWillClose:(ChanBanExceptionSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [world selectedChannel].name, mode]];
        }
    }
	
	banExceptionSheet = nil;
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (void)createChannelListDialog
{
	if (PointerIsEmpty(channelListDialog)) {
		channelListDialog = [ListDialog new];
		channelListDialog.delegate = self;
		[channelListDialog start];
	} else {
		[channelListDialog show];
	}
}

- (void)listDialogOnUpdate:(ListDialog *)sender
{
    [sender.list removeAllObjects];
    
	[self sendLine:IRCCI_LIST];
}

- (void)listDialogOnJoin:(ListDialog *)sender channel:(NSString *)channel
{
	[self joinUnlistedChannel:channel];
}

- (void)listDialogWillClose:(ListDialog *)sender
{
	channelListDialog = nil;
}

#pragma mark -
#pragma mark Timers

- (void)startISONTimer
{
	if (isonTimer.isActive) return;
	
	[isonTimer start:ISON_CHECK_INTERVAL];
}

- (void)stopISONTimer
{
	[isonTimer stop];
    
	[trackedUsers removeAllObjects];
}

- (void)onISONTimer:(id)sender
{
	if (isLoggedIn) {
		if (hasIRCopAccess)					return [self stopISONTimer];
		if (NSObjectIsEmpty(trackedUsers))	return [self stopISONTimer];
		
		NSMutableString *userstr = [NSMutableString string];
		
		for (NSString *name in trackedUsers) {
			[userstr appendFormat:@" %@", name];
		}
		
		[self send:IRCCI_ISON, userstr, nil];
	}
}

- (void)startPongTimer
{
	if (pongTimer.isActive) return;
	
	[pongTimer start:PONG_CHECK_INTERVAL];
}

- (void)stopPongTimer
{
	if (pongTimer.isActive) {
		[pongTimer stop];
	}
}

- (void)onPongTimer:(id)sender
{
	if (isConnected == NO) {
		[self stopPongTimer];
		
		return;
	}
	
	NSInteger timeSpent = [NSDate secondsSinceUnixTimestamp:lastMessageReceived];
	NSInteger minsSpent = (timeSpent / 60);
	
	if (timeSpent >= TIMEOUT_INTERVAL) {
		[self printDebugInformation:TXTFLS(@"IRC_DISCONNECTED_FROM_TIMEOUT", minsSpent) channel:nil];
		
		[self disconnect];
	} else if (timeSpent >= PING_INTERVAL) {
		[self send:IRCCI_PING, serverHostname, nil];
	}
}

- (void)startReconnectTimer
{
	if (config.autoReconnect) {
		if (reconnectTimer.isActive) return;
		
		[reconnectTimer start:RECONNECT_INTERVAL];
	}
}

- (void)stopReconnectTimer
{
	[reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
	[self connect:CONNECT_RECONNECT];
}

- (void)startRetryTimer
{
	if (retryTimer.isActive) return;
	
	[retryTimer start:RETRY_INTERVAL];
}

- (void)stopRetryTimer
{
	[retryTimer stop];
}

- (void)onRetryTimer:(id)sender
{
	[self disconnect];
	[self connect:CONNECT_RETRY];
}

- (void)startAutoJoinTimer
{
	[autoJoinTimer stop];
	[autoJoinTimer start:AUTOJOIN_DELAY_INTERVAL];
}

- (void)stopAutoJoinTimer
{
	[autoJoinTimer stop];
}

- (void)onAutoJoinTimer:(id)sender
{
	if ([Preferences autojoinWaitForNickServ] == NO || NSObjectIsEmpty(config.nickPassword)) {
		[self performAutoJoin];
		
		autojoinInitialized = YES;
	} else {
		if (serverHasNickServ) {
			if (autojoinInitialized) {
				[self performAutoJoin];
				
				autojoinInitialized = YES;
			}
		} else {
			[self performAutoJoin];
			
			autojoinInitialized = YES;
		}
	}
	
	[autoJoinTimer stop];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:CONNECT_NORMAL];
}

- (void)connect:(ConnectMode)mode
{
	[self stopReconnectTimer];
	
	connectType    = mode;
	disconnectType = DISCONNECT_NORMAL;
	
	if (isConnected) {
		[conn close];
	}
	
	retryEnabled     = YES;
	isConnecting     = YES;
	reconnectEnabled = YES;
	
	NSString *host = config.host;
	
	switch (mode) {
		case CONNECT_NORMAL:
			[self printSystemBoth:nil text:TXTFLS(@"IRC_IS_CONNECTING", host, config.port)];
			break;
		case CONNECT_RECONNECT:
			[self printSystemBoth:nil text:TXTLS(@"IRC_IS_RECONNECTING")];
			[self printSystemBoth:nil text:TXTFLS(@"IRC_IS_CONNECTING", host, config.port)];
			break;
		case CONNECT_RETRY:
			[self printSystemBoth:nil text:TXTLS(@"IRC_IS_RETRYING_CONNECTION")];
			[self printSystemBoth:nil text:TXTFLS(@"IRC_IS_CONNECTING", host, config.port)];
			break;
		default: break;
	}
	
    if (PointerIsEmpty(conn)) {
        conn = [IRCConnection new];
        conn.delegate = self;
	}
    
	conn.host	  = host;
	conn.port	  = config.port;
	conn.useSSL   = config.useSSL;
	conn.encoding = config.encoding;
	
	switch (config.proxyType) {
		case PROXY_SOCKS_SYSTEM:
			conn.useSystemSocks = YES;
		case PROXY_SOCKS4:
		case PROXY_SOCKS5:
			conn.useSocks      = YES;
			conn.socksVersion  = config.proxyType;
			conn.proxyHost     = config.proxyHost;
			conn.proxyPort	   = config.proxyPort;
			conn.proxyUser	   = config.proxyUser;
			conn.proxyPassword = config.proxyPassword;
			break;
		default: break;
	}
	
	[conn open];
	
	[self reloadTree];
}

- (void)disconnect
{
	if (conn) {
		[conn close];
	}
	
	[self stopPongTimer];
	[self changeStateOff];
}

- (void)quit
{
	[self quit:nil];
}

- (void)quit:(NSString *)comment
{
	if (isLoggedIn == NO) {
		[self disconnect];
        
		return;
	}
	
	[self stopPongTimer];
	
	isQuitting = YES;
	reconnectEnabled = NO;
	
	[conn clearSendQueue];
	
	[self send:IRCCI_QUIT, ((comment) ?: config.leavingComment), nil];
	
	[self performSelector:@selector(disconnect) withObject:nil afterDelay:2.0];
}

- (void)cancelReconnect
{
	[self stopReconnectTimer];
}

- (void)changeNick:(NSString *)newNick
{
	if (isConnected == NO) return;

	inputNick = newNick;
	sentNick = newNick;
	
	[self send:IRCCI_NICK, newNick, nil];
}

- (void)_joinKickedChannel:(IRCChannel *)channel
{
	if (PointerIsNotEmpty(channel)) {
		if (channel.status == IRCChannelTerminated) {
			return;
		}
		
		[self joinChannel:channel];
	}
}

- (void)joinChannel:(IRCChannel *)channel
{
	return [self joinChannel:channel password:nil];
}

- (void)joinUnlistedChannel:(NSString *)channel
{
	[self joinUnlistedChannel:channel password:nil];
}

- (void)partUnlistedChannel:(NSString *)channel
{
	[self partUnlistedChannel:channel withComment:nil];
}

- (void)partChannel:(IRCChannel *)channel 
{
	[self partChannel:channel withComment:nil];
}

- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password
{
	if (isLoggedIn == NO) return;
	if (channel.isActive) return;
	if (channel.isChannel == NO) return;
	
	channel.status = IRCChannelJoining;
	
	if (NSObjectIsEmpty(password)) password = channel.config.password;
	if (NSObjectIsEmpty(password)) password = nil;
	
	[self forceJoinChannel:channel.name password:password];
}

- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password
{
	if ([channel isChannelName]) {
		IRCChannel *chan = [self findChannel:channel];
		
		if (chan) {
			return [self joinChannel:chan password:password];
		}
		
		[self forceJoinChannel:channel password:password];
	} else {
        if ([channel isEqualToString:@"0"]) {
            [self forceJoinChannel:channel password:password];
        }
    }
}

- (void)forceJoinChannel:(NSString *)channel password:(NSString *)password
{
	[self send:IRCCI_JOIN, channel, password, nil];
}

- (void)partUnlistedChannel:(NSString *)channel withComment:(NSString *)comment
{
	if ([channel isChannelName]) {
		IRCChannel *chan = [self findChannel:channel];
		
		if (chan) {
			chan.status = IRCChannelParted;
			
			return [self partChannel:chan withComment:comment];
		}
	}
}

- (void)partChannel:(IRCChannel *)channel withComment:(NSString *)comment
{
	if (isLoggedIn == NO) return;
	if (channel.isActive == NO) return;
	if (channel.isChannel == NO) return;
	
	channel.status = IRCChannelParted;
	
	if (NSObjectIsEmpty(comment)) {
		comment = config.leavingComment;
	}
	
	[self send:IRCCI_PART, channel.name, comment, nil];
}

- (void)sendWhois:(NSString *)nick
{
	if (isLoggedIn == NO) return;
	
	[self send:IRCCI_WHOIS, nick, nick, nil];
}

- (void)changeOp:(IRCChannel *)channel users:(NSArray *)inputUsers mode:(char)mode value:(BOOL)value
{
	if (isLoggedIn == NO || PointerIsEmpty(channel) || channel.isActive == NO || 
		channel.isChannel == NO || channel.isOp == NO) return;
	
	NSMutableArray *users = [NSMutableArray array];
	
	for (IRCUser *user in inputUsers) {
		IRCUser *m = [channel findMember:user.nick];
		
		if (m) {
			if (NSDissimilarObjects(value, [m hasMode:mode])) {
				[users safeAddObject:m];
			}
		}
	}
	
	NSInteger max = isupport.modesCount;
	
	while (users.count) {
		NSArray *ary = [users subarrayWithRange:NSMakeRange(0, MIN(max, users.count))];
		
		NSMutableString *s = [NSMutableString string];
		
		[s appendFormat:@"%@ %@ %c", IRCCI_MODE, channel.name, ((value) ? '+' : '-')];
		
		for (NSInteger i = (ary.count - 1); i >= 0; --i) {
			[s appendFormat:@"%c", mode];
		}
		
		for (IRCUser *m in ary) {
			[s appendString:NSWhitespaceCharacter];
			[s appendString:m.nick];
		}
		
		[self sendLine:s];
		
		[users removeObjectsInRange:NSMakeRange(0, ary.count)];
	}
}

- (void)kick:(IRCChannel *)channel target:(NSString *)nick
{
	[self send:IRCCI_KICK, channel.name, nick, [Preferences defaultKickMessage], nil];
}

- (void)quickJoin:(NSArray *)chans
{
	NSMutableString *target = [NSMutableString string];
	NSMutableString *pass   = [NSMutableString string];
	
	for (IRCChannel *c in chans) {
		NSMutableString *prevTarget = [target mutableCopy];
		NSMutableString *prevPass   = [pass mutableCopy];
        
        c.status = IRCChannelJoining;
		
		if (NSObjectIsNotEmpty(target)) [target appendString:@","];
		
		[target appendString:c.name];
		
		if (NSObjectIsNotEmpty(c.password)) {
			if (NSObjectIsNotEmpty(pass)) [pass appendString:@","];
			
			[pass appendString:c.password];
		}
		
		NSStringEncoding enc = conn.encoding;
		
		if (enc == 0x0000) enc = NSUTF8StringEncoding;
		
		NSData *targetData = [target dataUsingEncoding:enc];
		NSData *passData   = [pass dataUsingEncoding:enc];
		
		if ((targetData.length + passData.length) > MAXIMUM_IRC_BODY_LEN) {
			if (NSObjectIsEmpty(prevTarget)) {
				if (NSObjectIsEmpty(prevPass)) {
					[self send:IRCCI_JOIN, prevTarget, nil];
				} else {
					[self send:IRCCI_JOIN, prevTarget, prevPass, nil];
				}
				
				[target setString:c.name];
				[pass setString:c.password];
			} else {
				if (NSObjectIsEmpty(c.password)) {
					[self joinChannel:c];
				} else {
					[self joinChannel:c password:c.password];
				}
				
				[target setString:NSNullObject];
				[pass setString:NSNullObject];
			}
		}
	}
	
	if (NSObjectIsNotEmpty(target)) {
		if (NSObjectIsEmpty(pass)) {
			[self send:IRCCI_JOIN, target, nil];
		} else {
			[self send:IRCCI_JOIN, target, pass, nil];
		}
	}
}

- (void)updateAutoJoinStatus
{
	autojoinInitialized = NO;
}

- (void)performAutoJoin
{
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCChannel *c in channels) {
		if (c.isChannel && c.config.autoJoin) {
			if (c.isActive == NO) {
				[ary safeAddObject:c];
			}
		}
	}
	
	[self joinChannels:ary];
	
	[self performSelector:@selector(updateAutoJoinStatus) withObject:nil afterDelay:5.0];
}

- (void)joinChannels:(NSArray *)chans
{
	NSMutableArray *ary = [NSMutableArray array];
	
	BOOL pass = YES;
	
	for (IRCChannel *c in chans) {
		BOOL hasPass = NSObjectIsNotEmpty(c.password);
		
		if (pass) {
			pass = hasPass;
			
			[ary safeAddObject:c];
		} else {
			if (hasPass) {
				[self quickJoin:ary];
				
				[ary removeAllObjects];
				
				pass = hasPass;
			}
			
			[ary safeAddObject:c];
		}
		
		if (ary.count >= [Preferences autojoinMaxChannelJoins]) {
			[self quickJoin:ary];
			
			[ary removeAllObjects];
			
			pass = YES;
		}
	}
	
	if (NSObjectIsNotEmpty(ary)) {
		[self quickJoin:ary];
	}
    
    [world reloadTree];
}

#pragma mark -
#pragma mark Trial Period Timer

#ifdef IS_TRIAL_BINARY

- (void)startTrialPeriodTimer
{
	if (trialPeriodTimer.isActive) return;
	
	[trialPeriodTimer start:TRIAL_PERIOD_INTERVAL];
}

- (void)stopTrialPeriodTimer
{
	[trialPeriodTimer stop];
}

- (void)onTrialPeriodTimer:(id)sender
{
	if (isLoggedIn) {
		disconnectType = DISCONNECT_TRIAL_PERIOD;
		
		[self quit];
	}
}

#endif

#pragma mark -
#pragma mark Encryption and Decryption Handling

- (BOOL)encryptOutgoingMessage:(NSString **)message channel:(IRCChannel *)chan
{
	if ([chan isKindOfClass:[IRCChannel class]]) {
		if (PointerIsEmpty(chan) == NO && *message) {
			if ([chan isChannel] || [chan isTalk]) {
				if (NSObjectIsNotEmpty(chan.config.encryptionKey)) {
					NSString *newstr = [CSFWBlowfish encodeData:*message key:chan.config.encryptionKey encoding:config.encoding];
					
					if ([newstr length] < 5) {
						[self printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPT_FAILED") channel:chan];
						
						return NO;
					} else {
						*message = newstr;
					}
				}
			}
		}
	}
	
	return YES;
}

- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)chan
{
	if ([chan isKindOfClass:[IRCChannel class]]) {
		if (PointerIsEmpty(chan) == NO && *message) {
			if ([chan isChannel] || [chan isTalk]) {
				if (NSObjectIsNotEmpty(chan.config.encryptionKey)) {
					NSString *newstr = [CSFWBlowfish decodeData:*message key:chan.config.encryptionKey encoding:config.encoding];
					
					if (NSObjectIsNotEmpty(newstr)) {
						*message = newstr;
					}
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Plugins and Scripts

- (void)executeTextualCmdScript:(NSDictionary *)details 
{
	if ([details containsKey:@"path"] == NO) {
		return;
	}
    
    NSString *scriptPath = [details valueForKey:@"path"];
	
#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
	BOOL MLNonsandboxedScript = NO;
	
	if ([scriptPath contains:[Preferences whereScriptsUnsupervisedPath]]) {
		MLNonsandboxedScript = YES;
	}
#endif
    
    if ([scriptPath hasSuffix:@".scpt"]) {
		/* Event Descriptor */
		
		NSAppleEventDescriptor *firstParameter	= [NSAppleEventDescriptor descriptorWithString:[details objectForKey:@"input"]];
		NSAppleEventDescriptor *parameters		= [NSAppleEventDescriptor listDescriptor];
		
		[parameters insertDescriptor:firstParameter atIndex:1];
		
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		
		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
																						bytes:&psn
																					   length:sizeof(ProcessSerialNumber)];
		
		NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:@"textualcmd"];
		NSAppleEventDescriptor *event	= [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																				 eventID:kASSubroutineEvent
																		targetDescriptor:target
																				returnID:kAutoGenerateReturnID
																		   transactionID:kAnyTransactionID];
		
		[event setParamDescriptor:handler forKeyword:keyASSubroutineName];
		[event setParamDescriptor:parameters forKeyword:keyDirectObject];
		
		/* Execute Event — Mountain Lion, Non-sandboxed Script */
		
#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
		if (MLNonsandboxedScript) {
			if ([Preferences featureAvailableToOSXMountainLion]) {
				NSError *aserror = [NSError new];
				
				NSUserAppleScriptTask *applescript = [[NSUserAppleScriptTask alloc] initWithURL:[NSURL fileURLWithPath:scriptPath] error:&aserror];
				
				if (PointerIsEmpty(applescript)) {
					NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), [aserror localizedDescription]);
				} else {
					[applescript executeWithAppleEvent:event
									 completionHandler:^(NSAppleEventDescriptor *result, NSError *error){
										 
										 if (PointerIsEmpty(result)) {
											 NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), [error localizedDescription]);
										 } else {	
											 NSString *finalResult = [result stringValue].trim;
											 
											 if (NSObjectIsNotEmpty(finalResult)) {
												 [world.iomt inputText:finalResult command:IRCCI_PRIVMSG];
											 }
										 }
									 }];
				}
				
			}
			
			return;
		}
#endif
		
		/* Execute Event — All Other */
		
		NSDictionary *errors = [NSDictionary dictionary];
		
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errors];
        
        if (appleScript) {
            NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];
            
            if (errors && PointerIsEmpty(result)) {
                NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);
            } else {	
                NSString *finalResult = [result stringValue].trim;
                
                if (NSObjectIsNotEmpty(finalResult)) {
                    [world.iomt inputText:finalResult command:IRCCI_PRIVMSG];
                }
            }
        } else {
            NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);	
        }
        
    } else {
        NSMutableArray *args  = [NSMutableArray array];
		
        NSString *input = [details valueForKey:@"input"];
        
        for (NSString *i in [input componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
            [args addObject:i];
        }
        
        NSTask *scriptTask = [NSTask new];
        NSPipe *outputPipe = [NSPipe pipe];
        
        if ([_NSFileManager() isExecutableFileAtPath:scriptPath] == NO) {
            NSArray *chmodArguments = [NSArray arrayWithObjects:@"+x", scriptPath, nil];
            
			NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];
            
            [chmod waitUntilExit];
        }
        
        [scriptTask setStandardOutput:outputPipe];
        [scriptTask setLaunchPath:scriptPath];
        [scriptTask setArguments:args];
        
        NSFileHandle *filehandle = [outputPipe fileHandleForReading];
        
        [scriptTask launch];
        [scriptTask waitUntilExit];
        
        NSData *outputData    = [filehandle readDataToEndOfFile];
		
		NSString *outputString  = [NSString stringWithData:outputData encoding:NSUTF8StringEncoding];
        
        if (NSObjectIsNotEmpty(outputString)) {
            [world.iomt inputText:outputString command:IRCCI_PRIVMSG];
        }
        
    }
}

- (void)processBundlesUserMessage:(NSArray *)info
{
	NSString *command = NSNullObject;
	NSString *message = [info safeObjectAtIndex:0];
	
	if ([info count] == 2) {
		command = [[info safeObjectAtIndex:1] uppercaseString];
	}
	
	[NSBundle sendUserInputDataToBundles:world message:message command:command client:self];
}

- (void)processBundlesServerMessage:(IRCMessage *)msg
{
	[NSBundle sendServerInputDataToBundles:world client:self message:msg];
}

#pragma mark -
#pragma mark Sending Text

- (BOOL)inputText:(id)str command:(NSString *)command
{
	if (isConnected == NO) {
		if (NSObjectIsEmpty(str)) {
			return NO;
		}
	}
	
	id sel = world.selected;
	
	if (PointerIsEmpty(sel)) {
        return NO;
    }
	
    if ([str isKindOfClass:[NSString class]]) {
        str = [NSAttributedString emptyStringWithBase:str];
    }
    
    NSArray *lines = [str performSelector:@selector(splitIntoLines)];
	
	for (__strong NSAttributedString *s in lines) {
		if (NSObjectIsEmpty(s)) {
            continue;
        }
        
        NSRange chopRange = NSMakeRange(1, (s.string.length - 1));
		
		if ([sel isClient]) {
			if ([s.string hasPrefix:@"/"]) {
                s = [s attributedSubstringFromRange:chopRange];
			}
			
			[self sendCommand:s];
		} else {
			IRCChannel *channel = (IRCChannel *)sel;
			
			if ([s.string hasPrefix:@"/"] && [s.string hasPrefix:@"//"] == NO) {
                s = [s attributedSubstringFromRange:chopRange];
				
				[self sendCommand:s];
			} else {
				if ([s.string hasPrefix:@"/"]) {
                    s = [s attributedSubstringFromRange:chopRange];
				}
				
				[self sendText:s command:command channel:channel];
			}
		}
	}
	
	return YES;
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
    NSAttributedString *new = [NSAttributedString emptyStringWithBase:message];
    
	[self sendText:new command:IRCCI_PRIVMSG channel:[world selectedChannelOn:self]];
}

- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel
{
	if (NSObjectIsEmpty(str)) {
        return;
    }
	
	LogLineType type;
	
	if ([command isEqualToString:IRCCI_NOTICE]) {
		type = LINE_TYPE_NOTICE;
	} else if ([command isEqualToString:IRCCI_ACTION]) {
		type = LINE_TYPE_ACTION;
	} else {
		type = LINE_TYPE_PRIVMSG;
	}
	
	if ([[world bundlesForUserInput] containsKey:command]) {
		[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:str.string, nil, nil]];
	}
	
	NSArray *lines = [str performSelector:@selector(splitIntoLines)];
	
	for (NSAttributedString *line in lines) {
		if (NSObjectIsEmpty(line)) {
            continue;
        }
		
        NSMutableAttributedString *str = [line mutableCopy];
		
		while (NSObjectIsNotEmpty(str)) {
            NSString *newstr = [str attributedStringToASCIIFormatting:&str lineType:type channel:channel.name hostmask:myHost];
			
			[self printBoth:channel type:type nick:myNick text:newstr identified:YES];
			
			if ([self encryptOutgoingMessage:&newstr channel:channel] == NO) {
				continue;
			}
			
			NSString *cmd = command;
			
			if (type == LINE_TYPE_ACTION) {
				cmd = IRCCI_PRIVMSG;
                
				newstr = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCCI_ACTION, newstr, 0x01];
			} else if (type == LINE_TYPE_PRIVMSG) {
				[channel detectOutgoingConversation:newstr];
			}
			
			[self send:cmd, channel.name, newstr, nil];
		}
		
	}
}

- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	if (NSObjectIsEmpty(command)) {
		return;
	}
	
	NSString *trail;
	
	if (NSObjectIsNotEmpty(text)) {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, command, text, 0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@%c", 0x01, command, 0x01];
	}
	
	[self send:IRCCI_PRIVMSG, target, trail, nil];
}

- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSString *trail;
	
	if (NSObjectIsNotEmpty(text)) {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, command, text, 0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@%c", 0x01, command, 0x01];
	}
	
	[self send:IRCCI_NOTICE, target, trail, nil];
}

- (void)sendCTCPPing:(NSString *)target
{
	[self sendCTCPQuery:target command:IRCCI_PING text:[NSString stringWithFormat:@"%qu", mach_absolute_time()]];
}

- (BOOL)sendCommand:(id)str
{
	return [self sendCommand:str completeTarget:YES target:nil];
}

- (BOOL)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName
{
    NSMutableAttributedString *s;
    
    s = [NSMutableAttributedString alloc];
    
    if ([str isKindOfClass:[NSString class]]) {
        s = [s initWithString:str];
    } else {
        if ([str isKindOfClass:[NSAttributedString class]]) {
            s = [s initWithAttributedString:str];
        }
    }

	NSString *cmd = [s.getToken.string uppercaseString];
	
	if (NSObjectIsEmpty(cmd)) return NO;
	if (NSObjectIsEmpty(str)) return NO;
	
	IRCClient  *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	IRCChannel *selChannel = nil;
	
	if ([cmd isEqualToString:IRCCI_MODE] && ([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
		// do not complete for /mode #chname ...
	} else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	BOOL cutColon = NO;
	
	if ([s.string hasPrefix:@"/"]) {
		cutColon = YES;
		
        [s deleteCharactersInRange:NSMakeRange(0, 1)];
	}
	
	switch ([Preferences commandUIndex:cmd]) {
		case 3: // Command: AWAY
		{
            NSString *msg = s.string;
            
			if (NSObjectIsEmpty(s) && cutColon == NO) {
                if (isAway == NO) {
                    msg = TXTLS(@"IRC_AWAY_COMMAND_DEFAULT_REASON");
                }
			}
			
			if ([Preferences awayAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if (u.isConnected == NO) continue;
					
					[u.client send:cmd, msg, nil];
				}
			} else {
				if (isConnected == NO) return NO;
				
				[self send:cmd, msg, nil];
			}
			
			return YES;
			break;
		}
		case 5: // Command: INVITE
		{
			/* invite nick[ nick[ ...]] [channel] */
			
			if (NSObjectIsEmpty(s)) {
				return NO;
			}
			
            NSMutableArray *nicks = [NSMutableArray arrayWithArray:
									 [[s mutableString] componentsSeparatedByString: @" "]];
			
			if ([nicks count] && [[nicks lastObject] isChannelName]) {
				targetChannelName = [nicks lastObject];
				[nicks removeLastObject];
			} else if (c) {
				/* They didn't supply a channel, use the selected channel */
				targetChannelName = c.name;
			} else {
				/* We're not in a channel and they didn't supply a channel */
				return NO;
			}
			
			for (NSString *nick in nicks) {
				[self send:cmd, nick, targetChannelName, nil];
			}
			
			return YES;
			break;
		}
		case 51: // Command: J
		case 7: // Command: JOIN
		{
			if (selChannel && selChannel.isChannel && NSObjectIsEmpty(s)) {
				targetChannelName = selChannel.name;
			} else {
                if (NSObjectIsEmpty(s)) {
                    return NO;
                }
                
				targetChannelName = s.getToken.string;
				
				if ([targetChannelName isChannelName] == NO && [targetChannelName isEqualToString:@"0"] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}
			
			[self send:IRCCI_JOIN, targetChannelName, s.string, nil];
			
			return YES;
			break;
		}
		case 8: // Command: KICK
		{
			if (selChannel && selChannel.isChannel) {
				targetChannelName = selChannel.name;
			} else {
                if (NSObjectIsEmpty(s)) {
                    return NO;
                }
                
				targetChannelName = s.getToken.string;
			}
			
			NSString *peer = s.getToken.string;
			
			if (peer) {
				NSString *reason = [s.string trim];
				
				if (NSObjectIsEmpty(reason)) {
					reason = [Preferences defaultKickMessage];
				}
				
				[self send:cmd, targetChannelName, peer, reason, nil];
			}
			
			return YES;
			break;
		}
		case 9: // Command: KILL
		{
			NSString *peer = s.getToken.string;
			
			if (peer) {
				NSString *reason = [s.string trim];
				
				if (NSObjectIsEmpty(reason)) {
					reason = [Preferences IRCopDefaultKillMessage];
				}
				
				[self send:IRCCI_KILL, peer, reason, nil];
			}
			
			return YES;
			break;
		}
		case 10: // Command: LIST
		{
			if (PointerIsEmpty(channelListDialog)) {
				[self createChannelListDialog];
			}
			
			[self send:IRCCI_LIST, s.string, nil];
			
			return YES;
			break;
		}
		case 13: // Command: NICK
		{
			NSString *newnick = s.getToken.string;
			
			if ([Preferences nickAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					[u.client changeNick:newnick];
				}
			} else {
				if (isConnected == NO) return NO;
				
				[self changeNick:newnick];
			}
			
			return YES;
			break;
		}
		case 14: // Command: NOTICE
		case 19: // Command: PRIVMSG
		case 27: // Command: ACTION
		case 38: // Command: OMSG
		case 39: // Command: ONOTICE
		case 54: // Command: ME
		case 55: // Command: MSG
		case 92: // Command: SME
		case 93: // Command: SMSG
		{
			BOOL opMsg      = NO;
			BOOL secretMsg  = NO;
			
			if ([cmd isEqualToString:IRCCI_MSG]) {
				cmd = IRCCI_PRIVMSG;
			} else if ([cmd isEqualToString:IRCCI_OMSG]) {
				opMsg = YES;
                
				cmd = IRCCI_PRIVMSG;
			} else if ([cmd isEqualToString:IRCCI_ONOTICE]) {
				opMsg = YES;
                
				cmd = IRCCI_NOTICE;
			} else if ([cmd isEqualToString:IRCCI_SME]) {
				secretMsg = YES;
                
				cmd = IRCCI_ME;
			} else if ([cmd isEqualToString:IRCCI_SMSG]) {
				secretMsg = YES;
                
				cmd = IRCCI_PRIVMSG;
			} 
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || 
				[cmd isEqualToString:IRCCI_NOTICE] || 
				[cmd isEqualToString:IRCCI_ACTION]) {
				
				if (opMsg) {
					if (selChannel && selChannel.isChannel && [s.string isChannelName] == NO) {
						targetChannelName = selChannel.name;
					} else {
						targetChannelName = s.getToken.string;
					}
				} else {
					targetChannelName = s.getToken.string;
				}
			} else if ([cmd isEqualToString:IRCCI_ME]) {
				cmd = IRCCI_ACTION;
				
				if (selChannel) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = s.getToken.string;
				}
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || [cmd isEqualToString:IRCCI_NOTICE]) {
				if ([s.string hasPrefix:@"\x01"]) {
					cmd = (([cmd isEqualToString:IRCCI_PRIVMSG]) ? IRCCI_CTCP : IRCCI_CTCPREPLY);
					
                    [s deleteCharactersInRange:NSMakeRange(0, 1)];
					
					NSRange r = [s.string rangeOfString:@"\x01"];
					
					if (NSDissimilarObjects(r.location, NSNotFound)) {
						NSInteger len = (s.length - r.location);
						
						if (len > 0) {
                            [s deleteCharactersInRange:NSMakeRange(r.location, len)];
						}
					}
				}
			}
			
			if ([cmd isEqualToString:IRCCI_CTCP]) {
                NSMutableAttributedString *t = s.mutableCopy;
				
                NSString *subCommand = [t.getToken.string uppercaseString];
				
				if ([subCommand isEqualToString:IRCCI_ACTION]) {
					cmd = IRCCI_ACTION;
                    
					s = t;
                    
					targetChannelName = s.getToken.string;
				} else {
					NSString *subCommand = [s.getToken.string uppercaseString];
					
					if (NSObjectIsNotEmpty(subCommand)) {
						targetChannelName = s.getToken.string;
						
						if ([subCommand isEqualToString:IRCCI_PING]) {
							[self sendCTCPPing:targetChannelName];
						} else {
							[self sendCTCPQuery:targetChannelName command:subCommand text:s.string];
						}
					}
					
					return YES;
				}
			}
			
			if ([cmd isEqualToString:IRCCI_CTCPREPLY]) {
				targetChannelName = s.getToken.string;
				
				NSString *subCommand = s.getToken.string;
				
				[self sendCTCPReply:targetChannelName command:subCommand text:s.string];
				
				return YES;
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || 
				[cmd isEqualToString:IRCCI_NOTICE] || 
				[cmd isEqualToString:IRCCI_ACTION]) {
				
				if (NSObjectIsEmpty(s))                 return NO;
				if (NSObjectIsEmpty(targetChannelName)) return NO;
				
				LogLineType type;
				
				if ([cmd isEqualToString:IRCCI_NOTICE]) {
					type = LINE_TYPE_NOTICE;
				} else if ([cmd isEqualToString:IRCCI_ACTION]) {
					type = LINE_TYPE_ACTION;
				} else {
					type = LINE_TYPE_PRIVMSG;
				}
                
				while (NSObjectIsNotEmpty(s)) {
					NSArray *targets = [targetChannelName componentsSeparatedByString:@","];
                    
                    NSString *t = [s attributedStringToASCIIFormatting:&s lineType:type channel:targetChannelName hostmask:myHost];
					
					for (__strong NSString *chname in targets) {
						if (NSObjectIsEmpty(chname)) {
                            continue;
                        }
						
						BOOL opPrefix = NO;
						
						if ([chname hasPrefix:@"@"]) {
							opPrefix = YES;
                            
							chname = [chname safeSubstringFromIndex:1];
						}
						
						IRCChannel *c = [self findChannel:chname];
						
						if (PointerIsEmpty(c) && [chname isChannelName] == NO &&
							secretMsg == NO) {
							if (type == LINE_TYPE_NOTICE) {
								c = (id)self;
							} else {
								c = [world createTalk:chname client:self];
							}
						}
						
						if (c) {
							[self printBoth:c type:type nick:myNick text:t identified:YES];
							
							if ([self encryptOutgoingMessage:&t channel:c] == NO) {
								continue;
							}
						}
						
						if ([chname isChannelName]) {
							if (opMsg || opPrefix) {
								chname = [@"@" stringByAppendingString:chname];
							}
						}
						
						NSString *localCmd = cmd;
						
						if ([localCmd isEqualToString:IRCCI_ACTION]) {
							localCmd = IRCCI_PRIVMSG;
							
							t = [NSString stringWithFormat:@"\x01%@ %@\x01", IRCCI_ACTION, t];
						}
						
						[self send:localCmd, chname, t, nil];
						
                        if (c && [Preferences giveFocusOnMessage]) {
                            [world select:c];
                        }
					}
				}
			} 
			
			return YES;
			break;
		}
		case 15: // Command: PART
		case 52: // Command: LEAVE
		{
			if (selChannel && selChannel.isChannel && [s.string isChannelName] == NO) {
				targetChannelName = selChannel.name;
			} else if (selChannel && selChannel.isTalk && [s.string isChannelName] == NO) {
				[world destroyChannel:selChannel];
				
				return YES;
			} else {
				targetChannelName = s.getToken.string;
			}
			
			if (targetChannelName) {
				NSString *reason = [s.string trim];
				
				if (NSObjectIsEmpty(s) && cutColon == NO) {
					reason = [config leavingComment];
				}
				
				[self partUnlistedChannel:targetChannelName withComment:reason];
			}
			
			return YES;
			break;
		}
		case 20: // Command: QUIT
		{
			[self quit:s.string.trim];
			
			return YES;
			break;
		}
		case 21: // Command: TOPIC
		case 61: // Command: T
		{
			if (selChannel && selChannel.isChannel && [s.string isChannelName] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}
			
			if (targetChannelName) {
				NSString *topic = [s attributedStringToASCIIFormatting];
                
				if (NSObjectIsEmpty(topic)) {
					topic = nil;
				}
				
				IRCChannel *c = [self findChannel:targetChannelName];
				
				if ([self encryptOutgoingMessage:&topic channel:c] == YES) {
					[self send:IRCCI_TOPIC, targetChannelName, topic, nil];
				}
			}
			
			return YES;
			break;
		}
		case 23: // Command: WHO
		{
			inWhoInfoRun = YES;
			
			[self send:IRCCI_WHO, s.string, nil];
			
			return YES;
			break;
		}
		case 24: // Command: WHOIS
		{
			NSString *peer = s.string;
			
			if (NSObjectIsEmpty(peer)) {
				IRCChannel *c = world.selectedChannel;
				
				if (c.isTalk) {
					peer = c.name;
				} else {
					return NO;
				}
			}
			
			if ([s.string contains:NSWhitespaceCharacter]) {
				[self sendLine:[NSString stringWithFormat:@"%@ %@", IRCCI_WHOIS, peer]];
			} else {
				[self send:IRCCI_WHOIS, peer, peer, nil];
			}
			
			return YES;
			break;
		}
		case 32: // Command: CTCP
		{ 
			targetChannelName = s.getToken.string;
			
			if (NSObjectIsNotEmpty(targetChannelName)) {
				NSString *subCommand = [s.getToken.string uppercaseString];
				
				if ([subCommand isEqualToString:IRCCI_PING]) {
					[self sendCTCPPing:targetChannelName];
				} else {
					[self sendCTCPQuery:targetChannelName command:subCommand text:s.string];
				}
			}
			
			return YES;
			break;
		}
		case 33: // Command: CTCPREPLY
		{
			targetChannelName = s.getToken.string;
			
			NSString *subCommand = s.getToken.string;
			
			[self sendCTCPReply:targetChannelName command:subCommand text:s.string];
			
			return YES;
			break;
		}
		case 41: // Command: BAN
		case 64: // Command: UNBAN
		{
			if (c) {
				NSString *peer = s.getToken.string;
				
				if (peer) {
					IRCUser *user = [c findMember:peer];
                    
					NSString *host = ((user) ? [user banMask] : peer);
					
					if ([cmd isEqualToString:IRCCI_BAN]) {
						[self sendCommand:[NSString stringWithFormat:@"MODE +b %@", host] completeTarget:YES target:c.name];
					} else {
						[self sendCommand:[NSString stringWithFormat:@"MODE -b %@", host] completeTarget:YES target:c.name];
					}
				}
			}
			
			return YES;
			break;
		}
		case 11: // Command: MODE
		case 45: // Command: DEHALFOP
		case 46: // Command: DEOP
		case 47: // Command: DEVOICE
		case 48: // Command: HALFOP
		case 56: // Command: OP
		case 63: // Command: VOICE
		case 66: // Command: UMODE
		case 53: // Command: M
		{
			if ([cmd isEqualToString:IRCCI_M]) {
				cmd = IRCCI_MODE;
			}
			
			if ([cmd isEqualToString:IRCCI_MODE]) {
				if (selChannel && selChannel.isChannel && [s.string isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else if (([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
					targetChannelName = s.getToken.string;
				}
			} else if ([cmd isEqualToString:IRCCI_UMODE]) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:NSWhitespaceCharacter] atIndex:0];
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:myNick]                atIndex:0];
			} else {
				if (selChannel && selChannel.isChannel && [s.string isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = s.getToken.string;
				}
				
				NSString *sign;
				
				if ([cmd hasPrefix:@"DE"] || [cmd hasPrefix:@"UN"]) {
					sign = @"-";
                    
					cmd = [cmd safeSubstringFromIndex:2];
				} else {
					sign = @"+";
				}
				
				NSArray *params = [s.string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				
				if (NSObjectIsEmpty(params)) {
					return YES;
				} else {
					NSMutableString *ms = [NSMutableString stringWithString:sign];
                    
					NSString *modeCharStr;
					
                    modeCharStr = [cmd safeSubstringToIndex:1];
                    modeCharStr = [modeCharStr lowercaseString];
                    
					for (NSInteger i = (params.count - 1); i >= 0; --i) {
						[ms appendString:modeCharStr];
					}
					
					[ms appendString:NSWhitespaceCharacter];
					[ms appendString:s.string];
					
                    [s setAttributedString:[NSAttributedString emptyStringWithBase:ms]];
				}
			}
			
			NSMutableString *line = [NSMutableString string];
			
			[line appendString:IRCCI_MODE];
			
			if (NSObjectIsNotEmpty(targetChannelName)) {
				[line appendString:NSWhitespaceCharacter];
				[line appendString:targetChannelName];
			}
			
			if (NSObjectIsNotEmpty(s)) {
				[line appendString:NSWhitespaceCharacter];
				[line appendString:s.string];
			}
			
			[self sendLine:line];
			
			return YES;
			break;
		}
		case 42: // Command: CLEAR
		{
			if (c) {
				[world clearContentsOfChannel:c inClient:self];
				
				[c setDockUnreadCount:0];
				[c setTreeUnreadCount:0];
				[c setKeywordCount:0];
			} else if (u) {
				[world clearContentsOfClient:self];
				
				[u setDockUnreadCount:0];
				[u setTreeUnreadCount:0];
				[u setKeywordCount:0];
			}
			
			[world updateIcon];
			[world reloadTree];
			
			return YES;
			break;
		}
		case 43: // Command: CLOSE
		case 77: // Command: REMOVE
		{
			NSString *nick = s.getToken.string;
			
			if (NSObjectIsNotEmpty(nick)) {
				c = [self findChannel:nick];
			}
			
			if (c) {
				[world destroyChannel:c];
			}
			
			return YES;
			break;
		}
		case 44: // Command: REJOIN
		case 49: // Command: CYCLE
		case 58: // Command: HOP
		{
			if (c) {
				NSString *pass = nil;
				
				if ([c.mode modeIsDefined:@"k"]) {
					pass = [c.mode modeInfoFor:@"k"].param;
				}
				
				[self partChannel:c];
				[self forceJoinChannel:c.name password:pass];
			}
			
			return YES;
			break;
		}
		case 50: // Command: IGNORE
		case 65: // Command: UNIGNORE
		{
			if (NSObjectIsEmpty(s)) {
				[world.menuController showServerPropertyDialog:self ignore:@"--"];
			} else {
				NSString *n = s.getToken.string;
                
				IRCUser  *u = [c findMember:n];
				
				if (PointerIsEmpty(u)) {
					[world.menuController showServerPropertyDialog:self ignore:n];
					
					return YES;
				}
				
				NSString *hostmask = [u banMask];
				
				AddressBook *g = [[AddressBook alloc] init];
				
				g.hostmask = hostmask;
                
				g.ignorePublicMsg       = YES;
				g.ignorePrivateMsg      = YES;
				g.ignoreHighlights      = YES;
				g.ignorePMHighlights    = YES;
				g.ignoreNotices         = YES;
				g.ignoreCTCP            = YES;
				g.ignoreJPQE            = YES;
				g.notifyJoins           = NO;
				
				[g processHostMaskRegex];
				
				if ([cmd isEqualToString:IRCCI_IGNORE]) {
					BOOL found = NO;
					
					for (AddressBook *e in config.ignores) {
						if ([g.hostmask isEqualToString:e.hostmask]) {
							found = YES;
                            
							break;
						}
					}
					
					if (found == NO) {
						[config.ignores safeAddObject:g];
                        
						[world save];
					}
				} else {
					NSMutableArray *ignores = config.ignores;
					
					for (NSInteger i = (ignores.count - 1); i >= 0; --i) {
						AddressBook *e = [ignores safeObjectAtIndex:i];
						
						if ([g.hostmask isEqualToString:e.hostmask]) {
							[ignores safeRemoveObjectAtIndex:i];
							
							[world save];
							
							break;
						}
					}
				}
			}
			
			return YES;
			break;
		}
		case 57: // Command: RAW
		case 60: // Command: QUOTE
		{
			[self sendLine:s.string];
			
			return YES;
			break;
		}
		case 59: // Command: QUERY
		{
			NSString *nick = s.getToken.string;
			
			if (NSObjectIsEmpty(nick)) {
				if (c && c.isTalk) {
					[world destroyChannel:c];
				}
			} else {
				IRCChannel *c = [self findChannelOrCreate:nick useTalk:YES];
				
				[world select:c];
			}
			
			return YES;
			break;
		}
		case 62: // Command: TIMER
		{	
			NSInteger interval = [s.getToken.string integerValue];
			
			if (interval > 0) {
				TimerCommand *cmd = [[TimerCommand alloc] init];
				
				if ([s.string hasPrefix:@"/"]) {
                    [s deleteCharactersInRange:NSMakeRange(0, 1)];
				}
				
				cmd.input = s.string;
				cmd.time  = (CFAbsoluteTimeGetCurrent() + interval);
				cmd.cid   = ((c) ? c.uid : -1);
				
				[self addCommandToCommandQueue:cmd];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_ERROR_REPLY text:TXTLS(@"IRC_TIMER_REQUIRES_REALINT")];
			}
			
			return YES;
			break;
		}
		case 68: // Command: WEIGHTS
		{
			if (c) {
				NSInteger tc = 0;
				
				for (IRCUser *m in c.members) {
					if (m.totalWeight > 0) {
						NSString *text = TXTFLS(@"IRC_WEIGHTS_COMMAND_RESULT", m.nick, m.incomingWeight, m.outgoingWeight, m.totalWeight);
						
						tc++;
						
						[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
					}
				}
				
				if (tc == 0) {
					[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_WEIGHTS_COMMAND_NO_RESULT")];
				}
			}
			
			return YES;
			break;
		}
		case 69: // Command: ECHO
		case 70: // Command: DEBUG
		{
			if ([s.string isEqualNoCase:@"raw on"]) {
				rawModeEnabled = YES;
				
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_ENABLED")];
			} else if ([s.string isEqualNoCase:@"raw off"]) {
				rawModeEnabled = NO;	
				
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_DISABLED")];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:s.string];
			}
			
			return YES;
			break;
		}
		case 71: // Command: CLEARALL
		{
			if ([Preferences clearAllOnlyOnActiveServer]) {
				[world clearContentsOfClient:self];
				
				for (IRCChannel *c in channels) {
					[world clearContentsOfChannel:c inClient:self];
					
					[c setDockUnreadCount:0];
					[c setTreeUnreadCount:0];
					[c setKeywordCount:0];
				}
			} else {
				for (IRCClient *u in [world clients]) {
					[world clearContentsOfClient:u];
					
					for (IRCChannel *c in [u channels]) {
						[world clearContentsOfChannel:c inClient:u];
						
						[c setDockUnreadCount:0];
						[c setTreeUnreadCount:0];
						[c setKeywordCount:0];
					}
				}
			}
			
			[world updateIcon];
			[world reloadTree];
			[world markAllAsRead];
			
			return YES;
			break;
		}
		case 72: // Command: AMSG
		{
            [s insertAttributedString:[NSAttributedString emptyStringWithBase:@"MSG "] atIndex:0];
            
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
                        
						[u.client sendCommand:s completeTarget:YES target:c.name];
					}
				}
			} else {
				if (isConnected == NO) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
                    
					[self sendCommand:s completeTarget:YES target:c.name];
				}
			}
			
			[self reloadTree];
			
			return YES;
			break;
		}
		case 73: // Command: AME
		{
            [s insertAttributedString:[NSAttributedString emptyStringWithBase:@"ME "] atIndex:0];
            
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
						
						[u.client sendCommand:s completeTarget:YES target:c.name];
					}
				}
			} else {
				if (isConnected == NO) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
					
                    [u.client sendCommand:s completeTarget:YES target:c.name];
				}
			}
			
			[self reloadTree];
			
			return YES;
			break;
		}
		case 78: // Command: KB
		case 79: // Command: KICKBAN 
		{
			if (c) {
				NSString *peer = s.getToken.string;
				
				if (peer) {
					NSString *reason = [s.string trim];
					
					IRCUser *user = [c findMember:peer];
                    
					NSString *host = ((user) ? [user banMask] : peer);
					
					if (NSObjectIsEmpty(reason)) {
						reason = [Preferences defaultKickMessage];
					}
					
					[self send:IRCCI_MODE, c.name, @"+b", host, nil];
					[self send:IRCCI_KICK, c.name, user.nick, reason, nil];
				}
			}
			
			return YES;
			break;
		}
		case 81: // Command: ICBADGE
		{
			if ([s.string contains:NSWhitespaceCharacter] == NO) return NO;
			
			NSArray *data = [s.string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			[DockIcon drawWithHilightCount:[data integerAtIndex:0] 
							  messageCount:[data integerAtIndex:1]];
			
			return YES;
			break;
		}
		case 82: // Command: SERVER
		{
			if (NSObjectIsNotEmpty(s)) {
				[world createConnection:s.string chan:nil];
			}
			
			return YES;
			break;
		}
		case 83: // Command: CONN
		{
			if (NSObjectIsNotEmpty(s)) {
				[config setHost:s.getToken.string];
			}
			
			if (isConnected) [self quit];
			
			[self performSelector:@selector(connect) withObject:nil afterDelay:2.0];
			
			return YES;
			break;
		}
		case 84: // Command: MYVERSION
		{
			NSString *ref  = [Preferences gitBuildReference];
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CTCP_VERSION_INFO"), 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"], 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"], 
							  ((NSObjectIsEmpty(ref)) ? @"Unknown" : ref)];
			
			if (c.isChannel == NO && c.isTalk == NO) {
				[self printDebugInformationToConsole:text];
			} else {
				text = TXTFLS(@"IRC_CTCP_VERSION_TITLE", text);
				
				[self sendPrivmsgToSelectedChannel:text];
			}
			
			return YES;
			break;
		}
		case 74: // Command: MUTE
		{
			if (world.soundMuted) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_ALREADY_MUTED")];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_HAS_BEEN_MUTED")];
				
				[world setSoundMuted:YES];
			}
			
			return YES;
			break;
		}
		case 75: // Command: UNMUTE
		{
			if (world.soundMuted) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_NO_LONGER_MUTED")];
				
				[world setSoundMuted:NO];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_NOT_MUTED")];
			}
			
			return YES;
			break;
		}
		case 76: // Command: UNLOAD_PLUGINS
		{
			[[NSBundle invokeInBackgroundThread] deallocBundlesFromMemory:world];
			
			return YES;
			break;
		}
		case 91: // Command: LOAD_PLUGINS
		{
			[[NSBundle invokeInBackgroundThread] loadBundlesIntoMemory:world];
			
			return YES;
			break;
		}
		case 94: // Command: LAGCHECK
		case 95: // Command: MYLAG
		{
			lastLagCheck = CFAbsoluteTimeGetCurrent();
			
			if ([cmd isEqualNoCase:IRCCI_MYLAG]) {
				sendLagcheckToChannel = YES;
			}
			
			[self sendCTCPQuery:myNick command:IRCCI_LAGCHECK text:[NSString stringWithDouble:lastLagCheck]];
			[self printDebugInformation:TXTLS(@"LAG_CHECK_REQUEST_SENT_MESSAGE")];
			
			return YES;
			break;
		}
		case 96: // Command: ZLINE
		case 97: // Command: GLINE
		case 98: // Command: GZLINE
		{
			NSString *peer = s.getToken.string;
			
			if ([peer hasPrefix:@"-"]) {
				[self send:cmd, peer, s.string, nil];
			} else {
				NSString *time   = s.getToken.string;
				NSString *reason = s.string;
				
				if (peer) {
					reason = [reason trim];
					
					if (NSObjectIsEmpty(reason)) {
						reason = [Preferences IRCopDefaultGlineMessage];
						
						if ([reason contains:NSWhitespaceCharacter]) {
							NSInteger spacePos = [reason stringPosition:NSWhitespaceCharacter];
							
							if (NSObjectIsEmpty(time)) {
								time = [reason safeSubstringToIndex:spacePos];
							}
							
							reason = [reason safeSubstringAfterIndex:spacePos];
						}
					}
					
					[self send:cmd, peer, time, reason, nil];
				}
			}
			
			return YES;
			break;
		}
		case 99:  // Command: SHUN
		case 100: // Command: TEMPSHUN
		{
			NSString *peer = s.getToken.string;
			
			if ([peer hasPrefix:@"-"]) {
				[self send:cmd, peer, s.string, nil];
			} else {
				if (peer) {
					if ([cmd isEqualToString:IRCCI_TEMPSHUN]) {
						NSString *reason = s.getToken.string;
						
						reason = [reason trim];
						
						if (NSObjectIsEmpty(reason)) {
							reason = [Preferences IRCopDefaultShunMessage];
							
							if ([reason contains:NSWhitespaceCharacter]) {
								NSInteger spacePos = [reason stringPosition:NSWhitespaceCharacter];
								
								reason = [reason safeSubstringAfterIndex:spacePos];
							}
						}
						
						[self send:cmd, peer, reason, nil];
					} else {
						NSString *time   = s.getToken.string;
						NSString *reason = s.string;
						
						reason = [reason trim];
						
						if (NSObjectIsEmpty(reason)) {
							reason = [Preferences IRCopDefaultShunMessage];
							
							if ([reason contains:NSWhitespaceCharacter]) {
								NSInteger spacePos = [reason stringPosition:NSWhitespaceCharacter];
								
								if (NSObjectIsEmpty(time)) {
									time = [reason safeSubstringToIndex:spacePos];
								}
								
								reason = [reason safeSubstringAfterIndex:spacePos];
							}
						}
						
						[self send:cmd, peer, time, reason, nil];
					}
				}
			}
			
			return YES;
			break;
		}
		case 102: // Command: CAP
		case 103: // Command: CAPS
		{
			if ([acceptedCaps count]) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_CAP_CURRENTLY_ENABLED", [acceptedCaps componentsJoinedByString:@", "])];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_CAP_CURRENTLY_ENABLED_NONE")];
			}
			
			return YES;
			break;
		}
		case 104: // Command: CCBADGE
		{
			NSString *chan = s.getToken.string;
			
			if (NSObjectIsEmpty(chan)) {
				return NO;
			}
			
			NSInteger count = [s.getToken.string integerValue];
			
			IRCChannel *c = [self findChannel:chan];
			
			if (PointerIsNotEmpty(c)) {
				[c setTreeUnreadCount:count];
				
				NSString *hlt = s.getToken.string;
				
				if (NSObjectIsNotEmpty(hlt)) {
					if ([hlt isEqualToString:@"-h"]) {
						[c setIsKeyword:YES];
						[c setKeywordCount:1];
					}
				}
				
				[world reloadTree];
			}
			
			return YES;
			break;
		}
		default:
		{	
            NSArray *extensions = [NSArray arrayWithObjects:@".scpt", @".py", @".pyc", @".rb", @".pl", @".sh", @".bash", @"", nil];
            
            NSString *scriptPath = [NSString string];
            NSString *command = [cmd lowercaseString];
            
            BOOL scriptFound;
			
			NSArray *scriptPaths = [NSArray arrayWithObjects:
									
#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
									[Preferences whereScriptsUnsupervisedPath],
#endif
									
									[Preferences whereScriptsLocalPath],
									[Preferences whereScriptsPath], nil];
			
			
            
			for (NSString *path in scriptPaths) {
				if (scriptFound == YES) {
					break;
				}
				
				for (NSString *i in extensions) {
					NSString *filename = [NSString stringWithFormat:@"%@%@", command, i];
					
					scriptPath = [path stringByAppendingPathComponent:filename];
					scriptFound = [_NSFileManager() fileExistsAtPath:scriptPath];
					
					if (scriptFound == YES) {
						break;
					}
				}
            }
			
			BOOL pluginFound = BOOLValueFromObject([world.bundlesForUserInput objectForKey:cmd]);
			
			if (pluginFound && scriptFound) {
				NSLog(TXTLS(@"PLUGIN_COMMAND_CLASH_ERROR_MESSAGE") ,cmd);
			} else {
				if (pluginFound) {
					[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:[NSString stringWithString:s.string], cmd, nil]];
					
					return YES;
				} else {
					if (scriptFound) {
                        NSDictionary *inputInfo = [NSDictionary dictionaryWithObjectsAndKeys:c.name, @"channel", scriptPath, @"path", s.string, @"input", 
                                                   NSNumberWithBOOL(completeTarget), @"completeTarget", targetChannelName, @"target", nil];
                        
                        [[self invokeInBackgroundThread] executeTextualCmdScript:inputInfo];
                        
                        return YES;
					}
				}
			}
			
			if (cutColon) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:@":"] atIndex:0];
			}
			
			if ([s length]) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:NSWhitespaceCharacter] atIndex:0];
			}
			
            [s insertAttributedString:[NSAttributedString emptyStringWithBase:cmd] atIndex:0];
			
			[self sendLine:s.string];
			
			return YES;
			break;
		}
	}
	
	return NO;
}

- (void)sendLine:(NSString *)str
{
	[conn sendLine:str];
	
	if (rawModeEnabled) {
		NSLog(@" << %@", str);
	}
	
	world.messagesSent++;
	world.bandwidthOut += [str length];
}

- (void)send:(NSString *)str, ...
{
	NSMutableArray *ary = [NSMutableArray array];
	
	id obj;
	va_list args;
	va_start(args, str);
	
	while ((obj = va_arg(args, id))) {
		[ary safeAddObject:obj];
	}
	
	va_end(args);
	
	NSMutableString *s = [NSMutableString stringWithString:str];
	
	NSInteger count = ary.count;
	
	for (NSInteger i = 0; i < count; i++) {
		NSString *e = [ary safeObjectAtIndex:i];
		
		[s appendString:NSWhitespaceCharacter];
		
		if (i == (count - 1) && (NSObjectIsEmpty(e) || [e hasPrefix:@":"] || [e contains:NSWhitespaceCharacter])) {
			[s appendString:@":"];
		}
		
		[s appendString:e];
	}
	
	[self sendLine:s];
}

#pragma mark -
#pragma mark Find Channel

- (IRCChannel *)findChannel:(NSString *)name
{
	for (IRCChannel *c in channels) {
		if ([c.name isEqualNoCase:name]) {
			return c;
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name
{
	IRCChannel *c = [self findChannel:name];
	
	if (PointerIsEmpty(c)) {
		return [self findChannelOrCreate:name useTalk:NO];
	}
	
	return c;
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name useTalk:(BOOL)doTalk
{
	IRCChannel *c = [self findChannel:name];
	
	if (PointerIsEmpty(c)) {
		if (doTalk) {
			return [world createTalk:name client:self];
		} else {
			IRCChannelConfig *seed = [[IRCChannelConfig alloc] init];
			
			seed.name = name;
			
			return [world createChannel:seed client:self reload:YES adjust:YES];
		}
	}
	
	return c;
}

- (NSInteger)indexOfTalkChannel
{
	NSInteger i = 0;
	
	for (IRCChannel *e in channels) {
		if (e.isTalk) return i;
		
		++i;
	}
	
	return -1;
}

#pragma mark -
#pragma mark Command Queue

- (void)processCommandsInCommandQueue
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	while (commandQueue.count) {
		TimerCommand *m = [commandQueue safeObjectAtIndex:0];
		
		if (m.time <= now) {
			NSString *target = nil;
			
			IRCChannel *c = [world findChannelByClientId:uid channelId:m.cid];
			
			if (c) {
				target = c.name;
			}
			
			[self sendCommand:m.input completeTarget:YES target:target];
			
			[commandQueue safeRemoveObjectAtIndex:0];
		} else {
			break;
		}
	}
	
	if (commandQueue.count) {
		TimerCommand *m = [commandQueue safeObjectAtIndex:0];
		
		CFAbsoluteTime delta = (m.time - CFAbsoluteTimeGetCurrent());
		
		[commandQueueTimer start:delta];
	} else {
		[commandQueueTimer stop];
	}
}

- (void)addCommandToCommandQueue:(TimerCommand *)m
{
	BOOL added = NO;
	
	NSInteger i = 0;
	
	for (TimerCommand *c in commandQueue) {
		if (m.time < c.time) {
			added = YES;
			
			[commandQueue safeInsertObject:m atIndex:i];
			
			break;
		}
		
		++i;
	}
	
	if (added == NO) {
		[commandQueue safeAddObject:m];
	}
	
	if (i == 0) {
		[self processCommandsInCommandQueue];
	}
}

- (void)clearCommandQueue
{
	[commandQueueTimer stop];
	[commandQueue removeAllObjects];
}

- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark Window Title

- (void)updateClientTitle
{
	[world updateClientTitle:self];
}

- (void)updateChannelTitle:(IRCChannel *)c
{
	[world updateChannelTitle:c];
}

#pragma mark -
#pragma mark Growl

- (BOOL)notifyText:(NotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([myNick isEqual:nick]) {
		return NO;
	}
	
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}
	
	IRCChannel *channel = nil;
	
	NSString *chname = nil;
	
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel *)target;
			chname = channel.name;
			
			if (type == NOTIFICATION_HIGHLIGHT) {
				if (channel.config.ihighlights) {
					return YES;
				}
			} else if (channel.config.growl == NO) {
				return YES;
			}
		} else {
			chname = (NSString *)target;
		}
	}
	
	if (NSObjectIsEmpty(chname)) {
		chname = self.name;
	}
    
	[SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
	
	if ([Preferences growlEnabledForEvent:type] == NO) return YES;
	if ([Preferences stopGrowlOnActive] && [world.window isOnCurrentWorkspace]) return YES;
	if ([Preferences disableWhileAwayForEvent:type] == YES && isAway == YES) return YES;
	
	NSDictionary *info = nil;
	
	NSString *title = chname;
	NSString *desc;
	
	if (ltype == LINE_TYPE_ACTION || ltype == LINE_TYPE_ACTION_NH) {
		desc = [NSString stringWithFormat:@"• %@: %@", nick, text];
	} else {
		desc = [NSString stringWithFormat:@"<%@> %@", nick, text];
	}
	
	if (channel) {
		info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:uid], @"client", [NSNumber numberWithInteger:channel.uid], @"channel", nil];
	} else {
		info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:uid], @"client", nil];
	}
	
	[world notifyOnGrowl:type title:title desc:desc userInfo:info];
	
	return YES;
}

- (BOOL)notifyEvent:(NotificationType)type lineType:(LogLineType)ltype
{
	return [self notifyEvent:type lineType:ltype target:nil nick:NSNullObject text:NSNullObject];
}

- (BOOL)notifyEvent:(NotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}
	
	[SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
	
	if ([Preferences growlEnabledForEvent:type] == NO) return YES;
	if ([Preferences stopGrowlOnActive] && [world.window isOnCurrentWorkspace]) return YES;
	if ([Preferences disableWhileAwayForEvent:type] == YES && isAway == YES) return YES;
	
	IRCChannel *channel = nil;
	
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel *)target;
			
			if (channel.config.growl == NO) {
				return YES;
			}
		}
	}
	
	NSString *title = NSNullObject;
	NSString *desc  = NSNullObject;
	
	switch (type) {
		case NOTIFICATION_LOGIN:
		{
			title = self.name;
			break;
		}
		case NOTIFICATION_DISCONNECT:
		{
			title = self.name;
			break;
		}
		case NOTIFICATION_KICKED:
		{
			title = channel.name;
			desc = TXTFLS(@"NOTIFICATION_MSG_KICKED_DESC", nick, text);
			break;
		}
		case NOTIFICATION_INVITED:
		{
			title = self.name;
			desc = TXTFLS(@"NOTIFICATION_MSG_INVITED_DESC", nick, text);
			break;
		}
		case NOTIFICATION_ADDRESS_BOOK_MATCH: 
		{
			desc = text;
			break;
		}
		default: return YES;
	}
	
	NSDictionary *info = nil;
	
	if (channel) {
		info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:uid], @"client", [NSNumber numberWithInteger:channel.uid], @"channel", nil];
	} else {
		info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:uid], @"client", nil];
	}
	
	[world notifyOnGrowl:type title:title desc:desc userInfo:info];
	
	return YES;
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(id)t
{
	BOOL isActiveWindow = [world.window isOnCurrentWorkspace];
	
	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([t isChannel] == YES || [t isTalk] == YES) {
			if (NSDissimilarObjects(world.selected, t) || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
				[t setKeywordCount:([t keywordCount] + 1)];
				
				[world updateIcon];
			}
		}
	}
	
	if ([t isUnread] || (isActiveWindow && world.selected == t)) {
		return;
	}
	
	[t setIsKeyword:YES];
	
	[self reloadTree];
	
	if (isActiveWindow == NO) {
		[NSApp requestUserAttention:NSInformationalRequest];
	}
}

- (void)setNewTalkState:(id)t
{
	BOOL isActiveWindow = [world.window isOnCurrentWorkspace];
	
	if ([t isUnread] || (isActiveWindow && world.selected == t)) {
		return;
	}
	
	[t setIsNewTalk:YES];
	
	[self reloadTree];
	
	if (isActiveWindow == NO) {
		[NSApp requestUserAttention:NSInformationalRequest];
	}
	
	[world updateIcon];
}

- (void)setUnreadState:(id)t
{
	BOOL isActiveWindow = [world.window isOnCurrentWorkspace];
	
	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([Preferences countPublicMessagesInIconBadge] == NO) {
			if ([t isTalk] == YES && [t isClient] == NO) {
				if (NSDissimilarObjects(world.selected, t) || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
					[t setDockUnreadCount:([t dockUnreadCount] + 1)];
					
					[world updateIcon];
				}
			}
		} else {
			if (NSDissimilarObjects(world.selected, t) || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
				[t setDockUnreadCount:([t dockUnreadCount] + 1)];
				
				[world updateIcon];
			}	
		}
	}
	
    if (isActiveWindow == NO || (NSDissimilarObjects(world.selected, t) && isActiveWindow)) {
		[t setTreeUnreadCount:([t treeUnreadCount] + 1)];
	}
	
	if (isActiveWindow && world.selected == t) {
		return;
	} else {
		[t setIsUnread:YES];
		
		[self reloadTree];
	}
}

#pragma mark -
#pragma mark Print

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text
{
	return [self printBoth:chan type:type nick:nil text:text identified:NO];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	return [self printBoth:chan type:type nick:nil text:text identified:NO receivedAt:receivedAt];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
	return [self printBoth:chan type:type nick:nick text:text identified:identified receivedAt:[NSDate date]];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate*)receivedAt
{
	return [self printChannel:chan type:type nick:nick text:text identified:identified receivedAt:receivedAt];
}

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel
{
	NSString *format = ((world.viewTheme.other.nicknameFormat) ? world.viewTheme.other.nicknameFormat : [Preferences themeNickFormat]);
	
	if (NSObjectIsEmpty(format)) {
		format = @"<%@%n>";
	}
    
    if ([format contains:@"%n"]) {
        format = [format stringByReplacingOccurrencesOfString:@"%n" withString:nick];
    }
	
	if ([format contains:@"%@"]) {
		if (channel && channel.isClient == NO && channel.isChannel) {
			IRCUser *m = [channel findMember:nick];
			
			if (m) {
				NSString *mark = [NSString stringWithChar:m.mark];
				
				if ([mark isEqualToString:NSWhitespaceCharacter] || NSObjectIsEmpty(mark)) {
					format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSNullObject];
				} else {
					format = [format stringByReplacingOccurrencesOfString:@"%@" withString:mark];
				}
			} else {
				format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSNullObject];	
			}
		} else {
			format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSNullObject];	
		}
	}
	
	return format;
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
	return [self printChannel:chan type:type nick:nil text:text identified:identified receivedAt:[NSDate date]];
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type text:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	return [self printChannel:chan type:type nick:nil text:text identified:NO receivedAt:receivedAt];
}

- (BOOL)printAndLog:(LogLine *)line withHTML:(BOOL)rawHTML
{
	BOOL result = [log print:line withHTML:rawHTML];
	
	if (isConnected == NO) return NO;
	
	if ([Preferences logTranscript]) {
		if (PointerIsEmpty(logFile)) {
			logFile = [FileLogger new];
			logFile.client = self;
		}
		
		NSString *comp = [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil]];
		
		if (logDate) {
			if ([logDate isEqualToString:comp] == NO) {
				
				logDate = comp;
				[logFile reopenIfNeeded];
			}
		} else {
			logDate = comp;
		}
		
		NSString *nickStr = NSNullObject;
		
		if (line.nick) {
			nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
		}
		
		NSString *s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
		
		[logFile writeLine:s];
	}
	
	return result;
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	return [self printRawHTMLToCurrentChannel:text withTimestamp:YES receivedAt:receivedAt];
}

- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	return [self printRawHTMLToCurrentChannel:text withTimestamp:NO receivedAt:receivedAt];
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime receivedAt:(NSDate*)receivedAt
{
	LogLine *c = [[LogLine alloc] init];
	
	IRCChannel *channel = [world selectedChannelOn:self];
	
	c.body       = text;
	c.lineType   = LINE_TYPE_REPLY;
	c.memberType = MEMBER_TYPE_NORMAL;
	
	if (showTime) {
		NSString *time = TXFormattedTimestampWithOverride(receivedAt, [Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
		
		if (NSObjectIsNotEmpty(time)) {
			time = [time stringByAppendingString:NSWhitespaceCharacter];
		}
		
		c.time = time;
	}
	
	if (channel) {
		return [channel print:c withHTML:YES];
	} else {
		return [log print:c withHTML:YES];
	}
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate*)receivedAt
{
	if ([self outputRuleMatchedInMessage:text inChannel:chan withLineType:type] == YES) {
		return NO;
	}
	
	NSString *time    = TXFormattedTimestampWithOverride(receivedAt, [Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
	NSString *nickStr = nil;
	
	IRCChannel *channel = nil;
    
	LogMemberType memberType = MEMBER_TYPE_NORMAL;
	
	NSInteger colorNumber = 0;
	
	NSArray *keywords     = nil;
	NSArray *excludeWords = nil;
    
	LogLine *c = [[LogLine alloc] init];
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = MEMBER_TYPE_MYSELF;
	}
	
	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = chan;
	} else if ([chan isKindOfClass:[NSString class]]) {
        if (NSObjectIsNotEmpty(chan)) {
            return NO;
        }
	}
	
	if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) {
		if (NSDissimilarObjects(memberType, MEMBER_TYPE_MYSELF)) {
			if (channel && [[channel config] ihighlights] == NO) {
				keywords     = [Preferences keywords];
				excludeWords = [Preferences excludeWords];
				
                if ([Preferences keywordMatchingMethod] != KEYWORD_MATCH_REGEX) {
                    if ([Preferences keywordCurrentNick]) {
                        NSMutableArray *ary = [keywords mutableCopy];
                        
                        [ary safeInsertObject:myNick atIndex:0];
                        
                        keywords = ary;
                    }
                }
			}
		}
	}
	
	if (type == LINE_TYPE_ACTION_NH) {
		type = LINE_TYPE_ACTION;
	} else if (type == LINE_TYPE_PRIVMSG_NH) {
		type = LINE_TYPE_PRIVMSG;
	}
	
	if (NSObjectIsNotEmpty(time)) {
		time = [time stringByAppendingString:NSWhitespaceCharacter];
	}
	
	if (NSObjectIsNotEmpty(nick)) {
		if (type == LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ ", nick];
		} else if (type == LINE_TYPE_NOTICE) {
			nickStr = [NSString stringWithFormat:@"-%@-", nick];
		} else {
			nickStr = [self formatNick:nick channel:channel];
		}
	}
	
	if (nick && channel && (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION)) {
		IRCUser *user = [channel findMember:nick];
		
		if (user) {
			colorNumber = user.colorNumber;
		}
	}
	
	c.time = time;
	c.nick = nickStr;
	c.body = text;
	
	c.lineType			= type;
	c.memberType		= memberType;
	c.nickInfo			= nick;
	c.identified		= identified;
	c.nickColorNumber	= colorNumber;
	
	c.keywords		= keywords;
	c.excludeWords	= excludeWords;
	
	if (channel) {
		if ([Preferences autoAddScrollbackMark]) {
			if (NSDissimilarObjects(channel, [world selectedChannel]) || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
				if (channel.isUnread == NO) {
					if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION || type == LINE_TYPE_NOTICE) {
						[channel.log unmark];
						[channel.log mark];
					}
				}
			}
		}
		
		return [channel print:c];
	} else {
		if ([Preferences logTranscript]) {
			return [self printAndLog:c withHTML:NO];
		} else {
			return [log print:c];
		}
	}
}

- (void)printSystem:(id)channel text:(NSString *)text
{
	[self printChannel:channel type:LINE_TYPE_SYSTEM text:text receivedAt:[NSDate date]];
}

- (void)printSystem:(id)channel text:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	[self printChannel:channel type:LINE_TYPE_SYSTEM text:text receivedAt:receivedAt];
}

- (void)printSystemBoth:(id)channel text:(NSString *)text 
{
	[self printSystemBoth:channel text:text receivedAt:[NSDate date]];
}

- (void)printSystemBoth:(id)channel text:(NSString *)text receivedAt:(NSDate*)receivedAt
{
	[self printBoth:channel type:LINE_TYPE_SYSTEM text:text receivedAt:receivedAt];
}

- (void)printReply:(IRCMessage *)m
{
	[self printBoth:nil type:LINE_TYPE_REPLY text:[m sequence:1] receivedAt:m.receivedAt];
}

- (void)printUnknownReply:(IRCMessage *)m
{
	[self printBoth:nil type:LINE_TYPE_REPLY text:[m sequence:1] receivedAt:m.receivedAt];
}

- (void)printDebugInformation:(NSString *)m
{
	[self printDebugInformation:m channel:[world selectedChannelOn:self]];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[self printDebugInformation:m channel:nil];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel
{
	[self printBoth:channel type:LINE_TYPE_DEBUG text:m];
}

- (void)printErrorReply:(IRCMessage *)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel
{
	NSString *text = TXTFLS(@"IRC_HAD_RAW_ERROR", m.numericReply, [m sequence]);
	
	[self printBoth:channel type:LINE_TYPE_ERROR_REPLY text:text receivedAt:m.receivedAt];
}

- (void)printError:(NSString *)error
{
	[self printBoth:nil type:LINE_TYPE_ERROR text:error];
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (BOOL)isActive
{
	return isLoggedIn;
}

- (IRCClient *)client
{
	return self;
}

- (NSInteger)numberOfChildren
{
	return channels.count;
}

- (id)childAtIndex:(NSInteger)index
{
	return [channels safeObjectAtIndex:index];
}

- (NSString *)label
{
	return config.name;
}

#pragma mark -
#pragma mark Protocol Handlers

- (void)receivePrivmsgAndNotice:(IRCMessage *)m
{
	NSString *text = [m paramAt:1];
	
	BOOL identified = NO;
	
	if (identifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		identified = [text hasPrefix:@"+"];
		text = [text safeSubstringFromIndex:1];
	} else if (identifyMsg && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
		identified = [text hasPrefix:@"+"];
		text = [text safeSubstringFromIndex:1];
	}
	
	if ([text hasPrefix:@"\x01"]) {
		text = [text safeSubstringFromIndex:1];
		
		NSInteger n = [text stringPosition:@"\x01"];
		
		if (n >= 0) {
			text = [text safeSubstringToIndex:n];
		}
		
		if ([m.command isEqualToString:IRCCI_PRIVMSG]) {
			if ([[text uppercaseString] hasPrefix:@"ACTION "]) {
				text = [text safeSubstringFromIndex:7];
				
				[self receiveText:m command:IRCCI_ACTION text:text identified:identified];
			} else {
				[self receiveCTCPQuery:m text:text];
			}
		} else {
			[self receiveCTCPReply:m text:text];
		}
	} else {
		[self receiveText:m command:m.command text:text identified:identified];
	}
}

- (void)receiveText:(IRCMessage *)m command:(NSString *)cmd text:(NSString *)text identified:(BOOL)identified
{
	NSString *anick  = m.sender.nick;
	NSString *target = [m paramAt:0];
	
	LogLineType type = LINE_TYPE_PRIVMSG;
	
	if ([cmd isEqualToString:IRCCI_NOTICE]) {
		type = LINE_TYPE_NOTICE;
	} else if ([cmd isEqualToString:IRCCI_ACTION]) {
		type = LINE_TYPE_ACTION;
	}
	
	if ([target hasPrefix:@"@"]) {
		target = [target safeSubstringFromIndex:1];
	}
	
	AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
													 withMatches:[NSArray arrayWithObjects:@"ignoreHighlights", 
																  @"ignorePMHighlights",
																  @"ignoreNotices", 
																  @"ignorePublicMsg", 
																  @"ignorePrivateMsg", nil]];
	
	
	if ([target isChannelName]) {
		if ([ignoreChecks ignoreHighlights] == YES) {
			if (type == LINE_TYPE_ACTION) {
				type = LINE_TYPE_ACTION_NH;
			} else if (type == LINE_TYPE_PRIVMSG) {
				type = LINE_TYPE_PRIVMSG_NH;
			}
		}
		
		if (type == LINE_TYPE_NOTICE) {
			if ([ignoreChecks ignoreNotices] == YES) {
				return;
			}
		} else {
			if ([ignoreChecks ignorePublicMsg] == YES) {
				return;
			}
		}
		
		IRCChannel *c = [self findChannel:target];
		if (PointerIsEmpty(c)) return;
		
		[self decryptIncomingMessage:&text channel:c];
		
		if (type == LINE_TYPE_NOTICE) {     
			[self printBoth:c type:type nick:anick text:text identified:identified receivedAt:m.receivedAt];
			[self notifyText:NOTIFICATION_CHANNEL_NOTICE lineType:type target:c nick:anick text:text];
		} else {
			BOOL highlight = [self printBoth:c type:type nick:anick text:text identified:identified receivedAt:m.receivedAt];
			BOOL postevent = NO;
			
			if (highlight) {
				postevent = [self notifyText:NOTIFICATION_HIGHLIGHT lineType:type target:c nick:anick text:text];
				
				if (postevent) {
					[self setKeywordState:c];
				}
			} else {
				postevent = [self notifyText:NOTIFICATION_CHANNEL_MSG lineType:type target:c nick:anick text:text];
			}
			
			if (postevent && (highlight || c.config.growl)) {
				[self setUnreadState:c];
			}
			
			if (c) {
				IRCUser *sender = [c findMember:anick];
				
				if (sender) {
					NSString *trimmedMyNick = [myNick stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]];
					
					if ([text stringPositionIgnoringCase:trimmedMyNick] >= 0) {
						[sender outgoingConversation];
					} else {
						[sender conversation];
					}
				}
			}
		}
	} else {
		BOOL targetOurself = [target isEqualNoCase:myNick];
		
		if ([ignoreChecks ignorePMHighlights] == YES) {
			if (type == LINE_TYPE_ACTION) {
				type = LINE_TYPE_ACTION_NH;
			} else if (type == LINE_TYPE_PRIVMSG) {
				type = LINE_TYPE_PRIVMSG_NH;
			}
		}
		
		if (targetOurself && [ignoreChecks ignorePrivateMsg]) {
			return;
		}
		
		if (NSObjectIsEmpty(anick)) {
			[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
		} else if ([anick isNickname] == NO) {
			if (type == LINE_TYPE_NOTICE) {
				if (hasIRCopAccess) {
					if ([text hasPrefix:@"*** Notice -- Client connecting"] || 
						[text hasPrefix:@"*** Notice -- Client exiting"] || 
						[text hasPrefix:@"*** You are connected to"] || 
						[text hasPrefix:@"Forbidding Q-lined nick"] || 
						[text hasPrefix:@"Exiting ssl client"]) {
						
						[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
						
						BOOL processData = NO;
						
						NSInteger match_math = 0;
						
						if ([text hasPrefix:@"*** Notice -- Client connecting at"]) {
							processData = YES;
						} else if ([text hasPrefix:@"*** Notice -- Client connecting on port"]) {
							processData = YES;
							
							match_math = 1;
						}
						
						if (processData) {	
							NSString *host = nil;
							NSString *snick = nil;
							
							NSArray *chunks = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
							
							host  = [chunks safeObjectAtIndex:(8 + match_math)];
							snick = [chunks safeObjectAtIndex:(7 + match_math)];
							
							host = [host safeSubstringFromIndex:1];
							host = [host safeSubstringToIndex:([host length] - 1)];
							
							ignoreChecks = [self checkIgnoreAgainstHostmask:[snick stringByAppendingFormat:@"!%@", host]
																withMatches:[NSArray arrayWithObjects:@"notifyJoins", nil]];
							
							[self handleUserTrackingNotification:ignoreChecks 
														nickname:snick 
														hostmask:host
														langitem:@"USER_TRACKING_HOSTMASK_CONNECTED"];
						}
					} else {
						if ([Preferences handleServerNotices]) {
							if ([Preferences handleIRCopAlerts] && [text containsIgnoringCase:[Preferences IRCopAlertMatch]]) {
								IRCChannel *c = [world selectedChannelOn:self];
								
								[self setUnreadState:c];
								[self printBoth:c type:LINE_TYPE_NOTICE text:text receivedAt:m.receivedAt];
							} else {
								IRCChannel *c = [self findChannelOrCreate:TXTLS(@"SERVER_NOTICES_WINDOW_TITLE") useTalk:YES];
								
								c.isUnread = YES;
								
								[self setUnreadState:c];
								[self printBoth:c type:type text:text receivedAt:m.receivedAt];
							}
						} else {
							[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
						}
					}
				} else {
					[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
				}
			} else {
				[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
			}
		} else {
			IRCChannel *c;
			
			if (targetOurself) {
				c = [self findChannel:anick];
			} else {
				c = [self findChannel:target];
			}
			
			[self decryptIncomingMessage:&text channel:c];
			
			BOOL newTalk = NO;
			
			if (PointerIsEmpty(c) && NSDissimilarObjects(type, LINE_TYPE_NOTICE)) {
				if (targetOurself) {
					c = [world createTalk:anick client:self];
				} else {
					c = [world createTalk:target client:self];
				}
				
				newTalk = YES;
			}
			
			if (type == LINE_TYPE_NOTICE) {
				if ([ignoreChecks ignoreNotices] == YES) {
					return;
				}
				
				if ([Preferences locationToSendNotices] == NOTICES_SENDTO_CURCHAN) {
					c = [world selectedChannelOn:self];
				}
				
				[self printBoth:c type:type nick:anick text:text identified:identified receivedAt:m.receivedAt];
				
				if ([anick isEqualNoCase:@"NickServ"]) {
					if ([text hasPrefix:@"This nickname is registered"]) {
						if (NSObjectIsNotEmpty(config.nickPassword) && isIdentifiedWithSASL == NO) {
							serverHasNickServ = YES;
							
							[self send:IRCCI_PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
						}
					} else if ([text hasPrefix:@"This nick is owned by someone else"]) {
						if ([config.server hasSuffix:@"dal.net"]) {
							if (NSObjectIsNotEmpty(config.nickPassword)) {
								serverHasNickServ = YES;
								
								[self send:IRCCI_PRIVMSG, @"NickServ@services.dal.net", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
							}
						}
					} else {
						if ([Preferences autojoinWaitForNickServ]) {
							if ([text hasPrefix:@"You are now identified"] ||
								[text hasPrefix:@"You are already identified"] ||
								[text hasSuffix:@"you are now recognized."] ||
								[text hasPrefix:@"Password accepted for"]) {
								
								if (autojoinInitialized == NO && serverHasNickServ) {
									autojoinInitialized = YES;
									
									[self performAutoJoin];
								}
							}
						} else {
							autojoinInitialized = YES;
						}
					}
				}
				
				if (targetOurself) {
					[self setUnreadState:c];
					[self notifyText:NOTIFICATION_TALK_NOTICE lineType:type target:c nick:anick text:text];
				}
			} else {
				BOOL highlight = [self printBoth:c type:type nick:anick text:text identified:identified receivedAt:m.receivedAt];
				BOOL postevent = NO;
				
				if (highlight) {
					postevent = [self notifyText:NOTIFICATION_HIGHLIGHT lineType:type target:c nick:anick text:text];
					
					if (postevent) {
						[self setKeywordState:c];
					}
				} else if (targetOurself) {
					if (newTalk) {
						postevent = [self notifyText:NOTIFICATION_NEW_TALK lineType:type target:c nick:anick text:text];
						
						if (postevent) {
							[self setNewTalkState:c];
						}
					} else {
						postevent = [self notifyText:NOTIFICATION_TALK_MSG lineType:type target:c nick:anick text:text];
					}
				}
				
				if (postevent) {
					[self setUnreadState:c];
				}
				
				NSString *hostTopic = m.sender.raw;
				
				if ([hostTopic isEqualNoCase:c.topic] == NO) {
					[c setTopic:hostTopic];
					[c.log setTopic:hostTopic];
				}
			}
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;
	
	NSMutableString *s = [text mutableCopy];
	NSString *command = [[s getToken] uppercaseString];
	
	if ([Preferences replyToCTCPRequests] == NO) {
		[self printDebugInformationToConsole:TXTFLS(@"IRC_HAS_IGNORED_CTCP", command, nick)];
		
		return;
	}
	
	AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
													 withMatches:[NSArray arrayWithObjects:@"ignoreCTCP", nil]];
	
	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}
	
	if ([command isEqualToString:IRCCI_DCC]) {
		[self printDebugInformationToConsole:TXTLS(@"DCC_REQUEST_ERROR_MESSAGE")];
	} else {
		IRCChannel *target = nil;
		
		if ([Preferences locationToSendNotices] == NOTICES_SENDTO_CURCHAN) {
			target = [world selectedChannelOn:self];
		}
		
		NSString *text = TXTFLS(@"IRC_RECIEVED_CTCP_REQUEST", command, nick);
		
		if ([command isEqualToString:IRCCI_LAGCHECK] == NO) {
			[self printBoth:target type:LINE_TYPE_CTCP text:text receivedAt:m.receivedAt];
		}
		
		if ([command isEqualToString:IRCCI_PING]) {
			[self sendCTCPReply:nick command:command text:s];
		} else if ([command isEqualToString:IRCCI_TIME]) {
			[self sendCTCPReply:nick command:command text:[[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
		} else if ([command isEqualToString:IRCCI_VERSION]) {
			NSString *ref  = [Preferences gitBuildReference];
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CTCP_VERSION_INFO"), 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"], 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"], 
							  ((NSObjectIsEmpty(ref)) ? @"Unknown" : ref)];
			
			[self sendCTCPReply:nick command:command text:text];
		} else if ([command isEqualToString:IRCCI_USERINFO]) {
			[self sendCTCPReply:nick command:command text:NSNullObject];
		} else if ([command isEqualToString:IRCCI_CLIENTINFO]) {
			[self sendCTCPReply:nick command:command text:TXTLS(@"IRC_CTCP_CLIENT_INFO")];
		} else if ([command isEqualToString:IRCCI_LAGCHECK]) {
			if (lastLagCheck == 0) {
				[self printDebugInformationToConsole:TXTFLS(@"IRC_HAS_IGNORED_CTCP", command, nick)];
			}
			
			NSDoubleN time = CFAbsoluteTimeGetCurrent();
			
			if (time >= lastLagCheck) {
				NSDoubleN delta = (time - lastLagCheck);
				
				text = TXTFLS(@"LAG_CHECK_REQUEST_REPLY_MESSAGE", config.server, delta);
			} else {
				text = TXTLS(@"LAG_CHECK_REQUEST_UNKNOWN_REPLY_MESSAGE");
			}
			
			if (sendLagcheckToChannel) {
				[self sendPrivmsgToSelectedChannel:text];
				
				sendLagcheckToChannel = NO;
			} else {
				[self printDebugInformation:text];
			}
			
			lastLagCheck = 0;
		}
	}
}

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;
	
	NSMutableString *s = [text mutableCopy];
	NSString *command = [[s getToken] uppercaseString];
	
	AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
													 withMatches:[NSArray arrayWithObjects:@"ignoreCTCP", nil]];
	
	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}
	
	IRCChannel *c = nil;
	
	if ([Preferences locationToSendNotices] == NOTICES_SENDTO_CURCHAN) {
		c = [world selectedChannelOn:self];
	}
	
	if ([command isEqualToString:IRCCI_PING]) {
		uint64_t delta = (mach_absolute_time() - [s longLongValue]);
		
		mach_timebase_info_data_t info;
		mach_timebase_info(&info);
		
		NSDoubleN nano = (1e-9 * ((NSDoubleN)info.numer / (NSDoubleN)info.denom));
		NSDoubleN seconds = ((NSDoubleN)delta * nano);
		
		text = TXTFLS(@"IRC_RECIEVED_CTCP_PING_REPLY", nick, command, seconds);
	} else {
		text = TXTFLS(@"IRC_RECIEVED_CTCP_REPLY", nick, command, s);
	}
	
	[self printBoth:c type:LINE_TYPE_CTCP text:text receivedAt:m.receivedAt];
}

- (void)requestUserHosts:(IRCChannel *)c 
{
	if ([c.name isChannelName]) {
		[c setIsModeInit:YES];
		
		[self send:IRCCI_MODE, c.name, nil];
		
		if (userhostInNames == NO) {
			// We can skip requesting WHO, we already have this information
			[self send:IRCCI_WHO, c.name, nil, nil];
		}
	}
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSString *nick   = m.sender.nick;
	NSString *chname = [m paramAt:0];
	
	BOOL njoin  = NO;
	BOOL myself = [nick isEqualNoCase:myNick];
	
	if ([chname hasSuffix:@"\x07o"]) {
		njoin  = YES;
		chname = [chname safeSubstringToIndex:(chname.length - 2)];
	}
	
	IRCChannel *c = [self findChannelOrCreate:chname];
	
	if (myself) {
		[c activate];
		
		[self reloadTree];
		
		myHost = m.sender.raw;
		
		if (autojoinInitialized == NO && [autoJoinTimer isActive] == NO) {
			[world select:c];
            [world.serverList expandItem:c];
		}
		
		if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
			[c.client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED") channel:c];
		}
	}
	
	if (PointerIsEmpty([c findMember:nick])) {
		IRCUser *u = [[IRCUser alloc] init];
		
		u.o           = njoin;
		u.nick        = nick;
		u.username    = m.sender.user;
		u.address	  = m.sender.address;
		u.supportInfo = isupport;
		
		[c addMember:u];
	}
	
    AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
                                                     withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", @"notifyJoins", nil]];
    
    if ([ignoreChecks ignoreJPQE] == YES && myself == NO) {
        return;
    }
    
    if (hasIRCopAccess == NO) {
        if ([ignoreChecks notifyJoins] == YES) {
            NSString *tracker = [ignoreChecks trackingNickname];
            
            BOOL ison = [trackedUsers boolForKey:tracker];
            
            if (ison == NO) {					
                [self handleUserTrackingNotification:ignoreChecks 
                                            nickname:m.sender.nick 
                                            hostmask:[m.sender.raw hostmaskFromRawString] 
                                            langitem:@"USER_TRACKING_HOSTMASK_NOW_AVAILABLE"];
                
                [trackedUsers setBool:YES forKey:tracker];
            }
        }
    }
    
	if ([Preferences showJoinLeave]) {
        if (c.config.iJPQActivity) {
            return;
        }
        
		NSString *text = TXTFLS(@"IRC_USER_JOINED_CHANNEL", nick, m.sender.user, m.sender.address);
		
		[self printBoth:c type:LINE_TYPE_JOIN text:text receivedAt:m.receivedAt];
	}
}

- (void)receivePart:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *comment = [[m paramAt:1] trim];
	
	IRCChannel *c = [self findChannel:chname];
	
	if (c) {
		if ([nick isEqualNoCase:myNick]) {
			[c deactivate];
			
			[self reloadTree];
		}
		
		[c removeMember:nick];
		
		if ([Preferences showJoinLeave]) {
            if (c.config.iJPQActivity) {
                return;
            }
            
			AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
															 withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
			
			if ([ignoreChecks ignoreJPQE] == YES) {
				return;
			}
			
			NSString *message = TXTFLS(@"IRC_USER_PARTED_CHANNEL", nick, m.sender.user, m.sender.address);
			
			if (NSObjectIsNotEmpty(comment)) {
				message = [message stringByAppendingFormat:@" (%@)", comment];
			}
			
			[self printBoth:c type:LINE_TYPE_PART text:message receivedAt:m.receivedAt];
		}
	}
}

- (void)receiveKick:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *target = [m paramAt:1];
	NSString *comment = [[m paramAt:2] trim];
	
	IRCChannel *c = [self findChannel:chname];
	
	if (c) {
		[c removeMember:target];
		
		if ([Preferences showJoinLeave]) {
            if (c.config.iJPQActivity) {
                return;
            }
            
			AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
															 withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
			
			if ([ignoreChecks ignoreJPQE] == YES) {
				return;
			}
			
			NSString *message = TXTFLS(@"IRC_USER_KICKED_FROM_CHANNEL", nick, target, comment);
			
			[self printBoth:c type:LINE_TYPE_KICK text:message receivedAt:m.receivedAt];
		}
		
		if ([target isEqualNoCase:myNick]) {
			[c deactivate];
			
			[self reloadTree];

			[self notifyEvent:NOTIFICATION_KICKED lineType:LINE_TYPE_KICK target:c nick:nick text:comment];
			
			if ([Preferences rejoinOnKick] && c.errLastJoin == NO) {
				[self printDebugInformation:TXTLS(@"IRC_CHANNEL_PREPARING_REJOIN") channel:c];
				
				[self performSelector:@selector(_joinKickedChannel:) withObject:c afterDelay:3.0];
			}
		}
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSString *nick    = m.sender.nick;
	NSString *comment = [[m paramAt:0] trim];
	
	BOOL myself = [nick isEqualNoCase:myNick];
	
	AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
													 withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
	
	NSString *text = TXTFLS(@"IRC_USER_DISCONNECTED", nick, m.sender.user, m.sender.address);
	
	if (NSObjectIsNotEmpty(comment)) {
		if ([TXRegularExpression string:comment 
					   isMatchedByRegex:@"^((([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)) (([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)))$"]) {
			
			comment = TXTFLS(@"IRC_SERVER_HAD_NETSPLIT", comment);
		}
		
		text = [text stringByAppendingFormat:@" (%@)", comment];
	}
	
	for (IRCChannel *c in channels) {
		if ([c findMember:nick]) {
			if ([Preferences showJoinLeave] && c.config.iJPQActivity == NO && [ignoreChecks ignoreJPQE] == NO) {
				[self printChannel:c type:LINE_TYPE_QUIT text:text receivedAt:m.receivedAt];
			}
			
			[c removeMember:nick];
			
			if (myself) {
				[c deactivate];
			}
		}
	}
	
	if (myself == NO) {
		if ([nick isEqualNoCase:config.nick]) {
			[self changeNick:config.nick];
		}
	}
	
	[world reloadTree];
	
	if (hasIRCopAccess == NO) {
		if ([ignoreChecks notifyJoins] == YES) {
			NSString *tracker = [ignoreChecks trackingNickname];
			
			BOOL ison = [trackedUsers boolForKey:tracker];
			
			if (ison) {					
				[trackedUsers setBool:NO forKey:tracker];
				
				[self handleUserTrackingNotification:ignoreChecks 
											nickname:m.sender.nick 
											hostmask:[m.sender.raw hostmaskFromRawString]
											langitem:@"USER_TRACKING_HOSTMASK_NO_LONGER_AVAILABLE"];
			}
		}
	}
}

- (void)receiveKill:(IRCMessage *)m
{
	NSString *target = [m paramAt:0];
	
	for (IRCChannel *c in channels) {
		if ([c findMember:target]) {
			[c removeMember:target];
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	AddressBook *ignoreChecks;
	
	NSString *nick   = m.sender.nick;
	NSString *toNick = [m paramAt:0];
    
    if ([nick isEqualToString:toNick]) {
        return;
    }
	
	BOOL myself = [nick isEqualNoCase:myNick];
	
	if (myself) {
		myNick = toNick;
	} else {
		ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
											withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
		
		if (hasIRCopAccess == NO) {
			if ([ignoreChecks notifyJoins] == YES) {
				NSString *tracker = [ignoreChecks trackingNickname];
				
				BOOL ison = [trackedUsers boolForKey:tracker];
				
				if (ison) {					
					[self handleUserTrackingNotification:ignoreChecks 
												nickname:m.sender.nick 
												hostmask:[m.sender.raw hostmaskFromRawString]
												langitem:@"USER_TRACKING_HOSTMASK_NO_LONGER_AVAILABLE"];
				} else {				
					[self handleUserTrackingNotification:ignoreChecks 
												nickname:m.sender.nick 
												hostmask:[m.sender.raw hostmaskFromRawString]
												langitem:@"USER_TRACKING_HOSTMASK_NOW_AVAILABLE"];
				}
				
				[trackedUsers setBool:BOOLReverseValue(ison) forKey:tracker];
			}
		}
	}
	
	for (IRCChannel *c in channels) {
		if ([c findMember:nick]) { 
			if ((myself == NO && [ignoreChecks ignoreJPQE] == NO) || myself == YES) {
				NSString *text = TXTFLS(@"IRC_USER_CHANGED_NICKNAME", nick, toNick);
				
				[self printChannel:c type:LINE_TYPE_NICK text:text receivedAt:m.receivedAt];
			}
			
			[c renameMember:nick to:toNick];
		}
	}
	
	IRCChannel *c = [self findChannel:nick];
	
	if (c) {
		IRCChannel *t = [self findChannel:toNick];
		
		if (t) {
			[world destroyChannel:t];
		}
		
		c.name = toNick;
		
		[self reloadTree];
	}
}

- (void)receiveMode:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *target = [m paramAt:0];
	NSString *modeStr = [m sequence:1];
	
	if ([target isChannelName]) {
		IRCChannel *c = [self findChannel:target];
		
		if (c) {
			NSArray *info = [c.mode update:modeStr];
			BOOL performWho = NO;
			
			for (IRCModeInfo *h in info) {
				[c changeMember:h.param mode:h.mode value:h.plus];
				
				if (h.plus == NO && multiPrefix == NO) {
					performWho = YES;
				}
			}
			
			if (performWho) {
				[self send:IRCCI_WHO, c.name, nil, nil];
			}
			
			[self printBoth:c type:LINE_TYPE_MODE text:TXTFLS(@"IRC_MDOE_SET", nick, modeStr) receivedAt:m.receivedAt];
		}
	} else {
		[self printBoth:nil type:LINE_TYPE_MODE text:TXTFLS(@"IRC_MDOE_SET", nick, modeStr) receivedAt:m.receivedAt];
	}
}

- (void)receiveTopic:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *topic = [m paramAt:1];
	
	IRCChannel *c = [self findChannel:chname];
	
	[self decryptIncomingMessage:&topic channel:c];
	
	if (c) {
		[c setTopic:topic];
		[c.log setTopic:topic];
		
		[self printBoth:c type:LINE_TYPE_TOPIC text:TXTFLS(@"IRC_CHANNEL_TOPIC_CHANGED", nick, topic) receivedAt:m.receivedAt];
	}
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:1];
	
	NSString *text = TXTFLS(@"IRC_USER_INVITED_YOU_TO", nick, m.sender.user, m.sender.address, chname);
	
	[self printBoth:self type:LINE_TYPE_INVITE text:text receivedAt:m.receivedAt];
	[self notifyEvent:NOTIFICATION_INVITED lineType:LINE_TYPE_INVITE target:nil nick:nick text:chname];
	
	if ([Preferences autoJoinOnInvite]) {
		[self joinUnlistedChannel:chname];
	}
}

- (void)receiveError:(IRCMessage *)m
{
	[self printError:m.sequence];
}

- (void)sendNextCap 
{
	if (capPaused == NO) {
		if (pendingCaps && [pendingCaps count]) {
			NSString *cap = [pendingCaps lastObject];
			
			[self send:IRCCI_CAP, @"REQ", cap, nil];
			
			[pendingCaps removeLastObject];
		} else {
			[self send:IRCCI_CAP, @"END", nil];
		}
	}
}

- (void)pauseCap 
{
	capPaused++;
}

- (void)resumeCap 
{
	capPaused--;
	
	[self sendNextCap];
}

- (BOOL)isCapAvailable:(NSString*)cap 
{
	return ([cap isEqualNoCase:@"identify-msg"] ||
			[cap isEqualNoCase:@"identify-ctcp"] ||
			[cap isEqualNoCase:@"multi-prefix"] ||
			[cap isEqualNoCase:@"userhost-in-names"] ||
			//[cap isEqualNoCase:@"znc.in/server-time"] ||
			([cap isEqualNoCase:@"sasl"] && NSObjectIsNotEmpty(config.nickPassword)));
}

- (void)cap:(NSString*)cap result:(BOOL)supported 
{
	if (supported) {
		if ([cap isEqualNoCase:@"sasl"]) {
			inSASLRequest = YES;
			
			[self pauseCap];
			[self send:IRCCI_AUTHENTICATE, @"PLAIN", nil];
		} else if ([cap isEqualNoCase:@"userhost-in-names"]) {
			userhostInNames = YES;
		} else if ([cap isEqualNoCase:@"multi-prefix"]) {
			multiPrefix = YES;
		} else if ([cap isEqualNoCase:@"identify-msg"]) {
			identifyMsg = YES;
		} else if ([cap isEqualNoCase:@"identify-ctcp"]) {
			identifyCTCP = YES;
		}
	}
}

- (void)receiveCapacityOrAuthenticationRequest:(IRCMessage *)m
{
    /* Implementation based off Colloquy's own. */
    
    NSString *command = [m command];
    NSString *star    = [m paramAt:0];
    NSString *base    = [m paramAt:1];
    NSString *action  = [m sequence:2];
    
    star   = [star trim];
    action = [action trim];
    
    if ([command isEqualNoCase:IRCCI_CAP]) {
        if ([base isEqualNoCase:@"LS"]) {
            NSArray *caps = [action componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
            for (NSString *cap in caps) {
				if ([self isCapAvailable:cap]) {
					[pendingCaps addObject:cap];
				}
            }
        } else if ([base isEqualNoCase:@"ACK"]) {
			NSArray *caps = [action componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
            for (NSString *cap in caps) {
				[acceptedCaps addObject:cap];
				
				[self cap:cap result:YES];
			}
		} else if ([base isEqualNoCase:@"NAK"]) {
			NSArray *caps = [action componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
            for (NSString *cap in caps) {
				[self cap:cap result:NO];
			}
		}
		
		[self sendNextCap];
    } else {
        if ([star isEqualToString:@"+"]) {
            NSData *usernameData = [config.nick dataUsingEncoding:config.encoding allowLossyConversion:YES];
            
            NSMutableData *authenticateData = [usernameData mutableCopy];
			
            [authenticateData appendBytes:"\0" length:1];
            [authenticateData appendData:usernameData];
            [authenticateData appendBytes:"\0" length:1];
            [authenticateData appendData:[config.nickPassword dataUsingEncoding:config.encoding allowLossyConversion:YES]];
            
            NSString *authString = [authenticateData base64EncodingWithLineLength:400];
            NSArray *authStrings = [authString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            for (NSString *string in authStrings) {
                [self send:IRCCI_AUTHENTICATE, string, nil];
            }
            
            if (NSObjectIsEmpty(authStrings) || [(NSString *)[authStrings lastObject] length] == 400) {
                [self send:IRCCI_AUTHENTICATE, @"+", nil];
            }
        }
    }
}

- (void)receivePing:(IRCMessage *)m
{
	[self send:IRCCI_PONG, [m sequence:0], nil];
}

- (void)receiveInit:(IRCMessage *)m
{
	[self startPongTimer];
	[self stopRetryTimer];
	[self stopAutoJoinTimer];
	
	sendLagcheckToChannel = serverHasNickServ = NO;
	isLoggedIn = conn.loggedIn = inFirstISONRun = YES;
	isAway = isConnecting = hasIRCopAccess = NO;
	
	tryingNickNumber = -1;
	
	serverHostname = m.sender.raw;
	
	myNick = [m paramAt:0];
	
	[self notifyEvent:NOTIFICATION_LOGIN lineType:LINE_TYPE_SYSTEM];
	
	for (__strong NSString *s in config.loginCommands) {
		if ([s hasPrefix:@"/"]) {
			s = [s safeSubstringFromIndex:1];
		}
		
		[self sendCommand:s completeTarget:NO target:nil];
	}
	
	for (IRCChannel *c in channels) {
		if (c.isTalk) {
			[c activate];
			
			IRCUser *m;
			
			m = [[IRCUser alloc] init];
			m.supportInfo = isupport;
			m.nick = myNick;
			[c addMember:m];
			
			m = [[IRCUser alloc] init];
			m.supportInfo = isupport;
			m.nick = c.name;
			[c addMember:m];
		}
	}
	
	[self reloadTree];
	[self populateISONTrackedUsersList:config.ignores];
	
#ifdef IS_TRIAL_BINARY
	[self startTrialPeriodTimer];
#endif
	
	[self startAutoJoinTimer];
}

- (void)receiveNumericReply:(IRCMessage *)m
{
	NSInteger n = m.numericReply; 
	
	if (400 <= n && n < 600 && 
		NSDissimilarObjects(n, 403) && 
		NSDissimilarObjects(n, 422)) {
		
		return [self receiveErrorNumericReply:m];
	}
	
	switch (n) {
		case 1: 
		{
			[self receiveInit:m];
			[self printReply:m];
			
			break;
		}
		case 2 ... 4:
		{
			if (NSObjectIsEmpty(config.server)) {
				if ([m.sender.nick isNickname] == NO) {
					[config setServer:m.sender.nick];
				}
			}
			
			[self printReply:m];
			
			break;
		}
		case 5:
		{
			[isupport update:[m sequence:1] client:self];
			
			if (NSObjectIsNotEmpty(isupport.networkName)) {
				[config setNetwork:TXTFLS(@"IRC_HAS_NETWORK_NAME", isupport.networkName)];
				
				[world updateTitle];
			}
			
			break;
		}
		case 10:
		case 20:
		case 42:
		case 250 ... 255:
		case 265 ... 266:
		{
			[self printReply:m];
			
			break;
		}
		case 372:
		case 375:
		case 376:	 
		case 422:	
		{
			if ([Preferences displayServerMOTD]) {
				[self printReply:m];
			}
			
			break;
		}
		case 221:
		{
			NSString *modeStr = [m paramAt:1];
			
			if ([modeStr isEqualToString:@"+"]) return;
			
			[self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_YOU_HAVE_UMODES", modeStr) receivedAt:m.receivedAt];
			
			break;
		}
		case 290:
		{
			NSString *kind = [[m paramAt:1] lowercaseString];
			
			if ([kind isEqualToString:@"identify-msg"]) {
				identifyMsg = YES;
			} else if ([kind isEqualToString:@"identify-ctcp"]) {
				identifyCTCP = YES;
			}
			
			[self printReply:m];
			
			break;
		}
		case 301:
		{
			NSString *nick = [m paramAt:1];
			NSString *comment = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:nick];
			IRCChannel *sc = [world selectedChannelOn:self];
			
			NSString *text = TXTFLS(@"IRC_USER_IS_AWAY", nick, comment);
			
			if (c) {
				[self printBoth:(id)nick type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			if (whoisChannel && [whoisChannel isEqualTo:c] == NO) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				if ([sc isEqualTo:c] == NO) {
					[self printBoth:sc type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
				}
			}
			
			break;
		}
		case 305: 
		{
			isAway = NO;
			
			[self printUnknownReply:m];
			
			break;
		}
		case 306: 
		{
			isAway = YES;
			
			[self printUnknownReply:m];
			
			break;
		}
		case 307:
		case 310:
		case 313:
		case 335:
		case 378:
		case 379:
		case 671:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 338:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 311:
		case 314:
		{
			NSString *nick = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];
			NSString *realname = [m paramAt:5];
			
			NSString *text = nil;
			
			inWhoWasRun = (m.numericReply == 314);
			
			if ([realname hasPrefix:@":"]) {
				realname = [realname safeSubstringFromIndex:1];
			}
			
			if (inWhoWasRun) {
				text = TXTFLS(@"IRC_USER_WHOWAS_HOSTMASK", nick, username, address, realname);
			} else {
				text = TXTFLS(@"IRC_USER_WHOIS_HOSTMASK", nick, username, address, realname);
			}	
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 312:
		{
			NSString *nick = [m paramAt:1];
			NSString *server = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];
			
			NSString *text = nil;
			
			if (inWhoWasRun) {
				text = TXTFLS(@"IRC_USER_WHOWAS_CONNECTED_FROM", nick, server, [dateTimeFormatter stringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]]);
			} else {
				text = TXTFLS(@"IRC_USER_WHOIS_CONNECTED_FROM", nick, server, serverInfo);
			}
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 317:
		{
			NSString *nick = [m paramAt:1];
			
			NSInteger idleStr = [[m paramAt:2] doubleValue];
			NSInteger signOnStr = [[m paramAt:3] doubleValue];
			
			NSString *idleTime = TXReadableTime(idleStr);
			NSString *dateFromString = [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:signOnStr]];
			
			NSString *text = TXTFLS(@"IRC_USER_WHOIS_UPTIME", nick, dateFromString, idleTime);
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 319:
		{
			NSString *nick = [m paramAt:1];
			NSString *trail = [[m paramAt:2] trim];
			
			NSString *text = TXTFLS(@"IRC_USER_WHOIS_CHANNELS", nick, trail);
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 318:
		{
			whoisChannel = nil;
			
			break;
		}
		case 324:
		{
			NSString *chname = [m paramAt:1];
			NSString *modeStr = [m sequence:2];
			
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			if ([modeStr isEqualToString:@"+"]) return;
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c.isModeInit == NO || NSObjectIsEmpty([c.mode allModes])) {
				if (c && c.isActive) {
					[c.mode clear];
					[c.mode update:modeStr];
					
					c.isModeInit = YES;
				}
				
				[self printBoth:c type:LINE_TYPE_MODE text:TXTFLS(@"IRC_CHANNEL_HAS_MODES", modeStr) receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 332:
		{
			NSString *chname = [m paramAt:1];
			NSString *topic = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:chname];
			
			[self decryptIncomingMessage:&topic channel:c];
			
			if (c && c.isActive) {
				[c setTopic:topic];
				[c.log setTopic:topic];
				
				[self printBoth:c type:LINE_TYPE_TOPIC text:TXTFLS(@"IRC_CHANNEL_HAS_TOPIC", topic) receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 333:	
		{
			NSString *chname = [m paramAt:1];
			NSString *setter = [m paramAt:2];
			NSString *timeStr = [m paramAt:3];
			long long timeNum = [timeStr longLongValue];
			
			NSRange r = [setter rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"!@"]];
			
			if (NSDissimilarObjects(r.location, NSNotFound)) {
				setter = [setter safeSubstringToIndex:r.location];
			}
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c) {
				NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_TOPIC_AUTHOR"), setter, 
								  [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
				
				[self printBoth:c type:LINE_TYPE_TOPIC text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 341:
		{
			NSString *nick = [m paramAt:1];
			NSString *chname = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:chname];
			
			[self printBoth:c type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_USER_INVITED_OTHER_USER", nick, chname) receivedAt:m.receivedAt];
			
			break;
		}
		case 303:
		{
			if (hasIRCopAccess) {
				[self printUnknownReply:m];
			} else {
				NSArray *users = [[m sequence] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				
				for (NSString *name in trackedUsers) {
					NSString *langkey = nil;
					
					BOOL ison = [trackedUsers boolForKey:name];
					
					if (ison) {
						if ([users containsObjectIgnoringCase:name] == NO) {
							if (inFirstISONRun == NO) {
								langkey = @"USER_TRACKING_NICKNAME_NO_LONGER_AVAILABLE";
							}
							
							[trackedUsers setBool:NO forKey:name];
						}
					} else {
						if ([users containsObjectIgnoringCase:name]) {
							langkey = ((inFirstISONRun) ? @"USER_TRACKING_NICKNAME_AVAILABLE" : @"USER_TRACKING_NICKNAME_NOW_AVAILABLE");
							
							[trackedUsers setBool:YES forKey:name];
						}
					}
					
					if (NSObjectIsNotEmpty(langkey)) {
						for (AddressBook *g in config.ignores) {
							NSString *trname = [g trackingNickname];
							
							if ([trname isEqualNoCase:name]) {
								[self handleUserTrackingNotification:g nickname:name hostmask:name langitem:langkey];
							}
						}
					}
				}
				
				if (inFirstISONRun) {
					inFirstISONRun = NO;
				}
			}
			
			break;
		}
		case 315:
		{
			NSString *chname = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c && c.isModeInit) {
				[c setIsModeInit:NO];
			} 
			
			if (inWhoInfoRun) {
				[self printUnknownReply:m];
				
				inWhoInfoRun = NO;
			}
			
			break;
		}
		case 352:  // RPL_WHOREPLY
		{
			NSString *chname = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c) {
				NSString *nick		= [m paramAt:5];
				NSString *hostmask	= [m paramAt:3];
				NSString *username	= [m paramAt:2];
				NSString *fields     = [m paramAt:6];
				
				// fields = G|H *| chanprefixes
				// strip G or H (away status)
				fields = [fields substringFromIndex:1];
				
				if ([fields hasPrefix:@"*"]) {
					// The nick is an oper
					fields = [fields substringFromIndex:1];
				}
				
				IRCUser *u = [c findMember:nick];
				
				if (PointerIsEmpty(u)) {
					IRCUser *u = [[IRCUser alloc] init];
					
					u.supportInfo = isupport;
					u.nick = nick;
				}
				
				NSInteger i;
				
				for (i = 0; i < fields.length; i++) {
					NSString *prefix = [fields safeSubstringWithRange:NSMakeRange(i, 1)];
					
					if ([prefix isEqualTo:isupport.userModeQPrefix]) {
						u.q = YES;
					} else if ([prefix isEqualTo:isupport.userModeAPrefix]) {
						u.a = YES;
					} else if ([prefix isEqualTo:isupport.userModeOPrefix]) {
						u.o = YES;
					} else if ([prefix isEqualTo:isupport.userModeHPrefix]) {
						u.h = YES;
					} else if ([prefix isEqualTo:isupport.userModeVPrefix]) {
						u.v = YES;
					} else {
						break;
					}
				}
				
				if (NSObjectIsEmpty(u.address)) {
					[u setAddress:hostmask];
					[u setUsername:username];
				}
				
				[c updateOrAddMember:u];
				[c reloadMemberList];
			} 
			
			if (inWhoInfoRun) {
				[self printUnknownReply:m];	
			}
			
			break;
		}
		case 353:
		{
			NSString *chname = [m paramAt:2];
			NSString *trail  = [m paramAt:3];
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c) {
				NSArray *ary = [trail componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				
				for (__strong NSString *nick in ary) {
					nick = [nick trim];
					
					if (NSObjectIsEmpty(nick)) continue;
					
					IRCUser *m = [[IRCUser alloc] init];
					
					NSInteger i;
					
					for (i = 0; i < nick.length; i++) {
						NSString *prefix = [nick safeSubstringWithRange:NSMakeRange(i, 1)];
						
						if ([prefix isEqualTo:isupport.userModeQPrefix]) {
							m.q = YES;
						} else if ([prefix isEqualTo:isupport.userModeAPrefix]) {
							m.a = YES;
						} else if ([prefix isEqualTo:isupport.userModeOPrefix]) {
							m.o = YES;
						} else if ([prefix isEqualTo:isupport.userModeHPrefix]) {
							m.h = YES;
						} else if ([prefix isEqualTo:isupport.userModeVPrefix]) {
							m.v = YES;
						} else {
							break;
						}
					}
					
					nick = [nick substringFromIndex:i];
					
					m.nick = [nick nicknameFromHostmask];
					m.username = [nick identFromHostmask];
					m.address = [nick hostFromHostmask];
					
					m.supportInfo = isupport;
					m.isMyself    = [nick isEqualNoCase:myNick];
					
					[c addMember:m reload:NO];
					
					if (m.isMyself) {
						c.isOp     = (m.q || m.a | m.o);
						c.isHalfOp = (m.h || c.isOp);
					}
				}
				
				[c reloadMemberList];
			} 
			
			break;
		}
		case 366:
		{
			NSString *chname = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c) {
				if ([c numberOfMembers] <= 1 && c.isOp) {
					NSString *m = c.config.mode;
					
					if (NSObjectIsNotEmpty(m)) {
						NSString *line = [NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, chname, m];
						
						[self sendLine:line];
					}
					
					c.isModeInit = YES;
				}
				
				if ([c numberOfMembers] <= 1 && [chname isModeChannelName] && c.isOp) {
					NSString *topic = c.storedTopic;
					
					if (NSObjectIsEmpty(topic)) {
						topic = c.config.topic;
					}
					
					if (NSObjectIsNotEmpty(topic)) {
						if ([self encryptOutgoingMessage:&topic channel:c] == YES) {
							[self send:IRCCI_TOPIC, chname, topic, nil];
						}
					}
				}
				
				if ([Preferences processChannelModes]) {
					[self requestUserHosts:c];
				}
			}
			
			break;
		}
		case 320:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m sequence:2]];
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 321:
		{
			if (channelListDialog) {
				[channelListDialog clear];
			}
			
			break;
		}
		case 322:
		{
			NSString *chname = [m paramAt:1];
			NSString *countStr = [m paramAt:2];
			NSString *topic = [m sequence:3];
			
			if (channelListDialog) {
				[channelListDialog addChannel:chname count:[countStr integerValue] topic:topic];
			}
			
			break;
		}
		case 323:	
		case 329:
		case 368:
		case 347:
		case 349:
		{
			return;
			break;
		}
		case 330:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 367:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];
			
			long long seton = [[m paramAt:4] longLongValue];
			
			if (chanBanListSheet) {
				[chanBanListSheet addBan:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}
			
			break;
		}
		case 346:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];
			
			long long seton = [[m paramAt:4] longLongValue];
			
			if (inviteExceptionSheet) {
				[inviteExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}
			
			break;
		}
		case 348:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];
			
			long long seton = [[m paramAt:4] longLongValue];
			
			if (banExceptionSheet) {
				[banExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}
			
			break;
		}
		case 381:
		{
			if (hasIRCopAccess == NO) {
                /* If we are already an IRCOp, then we do not need to see this line again. 
                 We will assume that if we are seeing it again, then it is the result of a
                 user opening two connections to a single bouncer session. */
                
                [self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_USER_HAS_GOOD_LIFE", m.sender.nick) receivedAt:m.receivedAt];
                
                hasIRCopAccess = YES;
            }
			
			break;
		}
		case 328:
		{
			NSString *chname = [m paramAt:1];
			NSString *website = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:chname];
			
			if (c && website) {
				[self printBoth:c type:LINE_TYPE_WEBSITE text:TXTFLS(@"IRC_CHANNEL_HAS_WEBSITE", website) receivedAt:m.receivedAt];
			}
			
			break;
		}
		case 369:
		{
			inWhoWasRun = NO;
			
			[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:[m sequence] receivedAt:m.receivedAt];
			
			break;
		}
        case 900:
        {
            isIdentifiedWithSASL = YES;
            
            [self printBoth:self type:LINE_TYPE_REPLY text:[m sequence:3] receivedAt:m.receivedAt];
            
            break;
        }
        case 903:
        case 904:
        case 905:
        case 906:
        case 907:
        {
            if (n == 903) { // success 
                [self printBoth:self type:LINE_TYPE_NOTICE text:[m sequence:1] receivedAt:m.receivedAt];
            } else {
                [self printReply:m];
            }
            
            if (inSASLRequest) {
                inSASLRequest = NO;
                [self resumeCap];
            }
            
            break;
        }
		default:
		{
			if ([world.bundlesForServerInput containsKey:[NSString stringWithInteger:m.numericReply]]) {
				break;
			}
			
			[self printUnknownReply:m];
			
			break;
		}
	}
}

- (void)receiveErrorNumericReply:(IRCMessage *)m
{
	NSInteger n = m.numericReply;
	
	switch (n) {
		case 401:	// ERR_NOSUCHNICK
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];
			
			if (c && c.isActive) {
				[self printErrorReply:m channel:c];
				
				return;
			}
			
			break;
		}
		case 433:	// ERR_NICKNAMEINUSE
		case 437:   // ERR_NICKTEMPUNAVAIL
        {
			if (isLoggedIn) break;
			
			[self receiveNickCollisionError:m];
			break;
        }
		case 402:   // ERR_NOSUCHSERVER
		{
			NSString *text = TXTFLS(@"IRC_HAD_RAW_ERROR", m.numericReply, [m sequence:1]);
			
			[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			
			return;
			break;
		}
		case 404:	// ERR_CANNOTSENDMESSAGE
		{
			NSString *chname = [m paramAt:1];
			NSString *text = TXTFLS(@"IRC_HAD_RAW_ERROR", m.numericReply, [m sequence:2]);
			
			[self printBoth:[self findChannel:chname] type:LINE_TYPE_REPLY text:text receivedAt:m.receivedAt];
			
			return;
			break;
		}
		case 405:	// ERR_GENERICJOINERROR
		case 471:
		case 473:
		case 474:
		case 475:
		case 477:
		case 485:
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];
			
			if (c) {
				c.errLastJoin = YES;
			}
		}
	}
	
	[self printErrorReply:m];
}

- (void)receiveNickCollisionError:(IRCMessage *)m
{
	if (config.altNicks.count && isLoggedIn == NO) {
		++tryingNickNumber;
		
		NSArray *altNicks = config.altNicks;
		
		if (tryingNickNumber < altNicks.count) {
			NSString *nick = [altNicks safeObjectAtIndex:tryingNickNumber];
			
			[self send:IRCCI_NICK, nick, nil];
		} else {
			[self tryAnotherNick];
		}
	} else {
		[self tryAnotherNick];
	}
}

- (void)tryAnotherNick
{
	if (sentNick.length >= isupport.nickLen) {
		NSString *nick = [sentNick safeSubstringToIndex:isupport.nickLen];
		
		BOOL found = NO;
		
		for (NSInteger i = (nick.length - 1); i >= 0; --i) {
			UniChar c = [nick characterAtIndex:i];
			
			if (NSDissimilarObjects(c, '_')) {
				found = YES;
				
				NSString *head = [nick safeSubstringToIndex:i];
				NSMutableString *s = [head mutableCopy];
				
				for (NSInteger i = (isupport.nickLen - s.length); i > 0; --i) {
					[s appendString:@"_"];
				}
				
				sentNick = s;
				
				break;
			}
		}
		
		if (found == NO) {
			sentNick = @"0";
		}
	} else {
		sentNick = [sentNick stringByAppendingString:@"_"];
	}
	
	[self send:IRCCI_NICK, sentNick, nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)changeStateOff
{
	if (isLoggedIn == NO && isConnecting == NO) return;
	
	BOOL prevConnected = isConnected;
	
	[acceptedCaps removeAllObjects];
	capPaused = 0;
	
	userhostInNames = NO;
	multiPrefix = NO;
	identifyMsg = NO;
	identifyCTCP = NO;
	
	conn = nil;
    
    for (IRCChannel *c in channels) {
        c.status = IRCChannelParted;
    }
	
	[self clearCommandQueue];
	[self stopRetryTimer];
	[self stopISONTimer];
	
	if (reconnectEnabled) {
		[self startReconnectTimer];
	}
	
	sendLagcheckToChannel = isIdentifiedWithSASL = NO;
	isConnecting = isConnected = isLoggedIn = isQuitting = NO;
	hasIRCopAccess = serverHasNickServ = autojoinInitialized = NO;
	
	
	myNick = NSNullObject;
	sentNick = NSNullObject;
	
	tryingNickNumber = -1;
	
	NSString *disconnectTXTLString = nil;
	
	switch (disconnectType) {
		case DISCONNECT_NORMAL:       disconnectTXTLString = @"IRC_DISCONNECTED_FROM_SERVER"; break;
        case DISCONNECT_SLEEP_MODE:   disconnectTXTLString = @"IRC_DISCONNECTED_FROM_SLEEP"; break;
		case DISCONNECT_TRIAL_PERIOD: disconnectTXTLString = @"TRIAL_BUILD_NETWORK_DISCONNECTED"; break;
		default: break;
	}
	
	if (disconnectTXTLString) {
		for (IRCChannel *c in channels) {
			if (c.isActive) {
				[c deactivate];
				
				[self printSystem:c text:TXTLS(disconnectTXTLString)];
			}
		}
		
		[self printSystemBoth:nil text:TXTLS(disconnectTXTLString)];
		
		if (prevConnected) {
			[self notifyEvent:NOTIFICATION_DISCONNECT lineType:LINE_TYPE_SYSTEM];
		}
	}
	
#ifdef IS_TRIAL_BINARY
	[self stopTrialPeriodTimer];
#endif
	
	[self reloadTree];
	
	isAway = NO;
}

- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	[self startRetryTimer];
	
	if (NSDissimilarObjects(connectType, CONNECT_BADSSL_CRT_RECONNECT)) {
		[self printSystemBoth:nil text:TXTLS(@"IRC_CONNECTED_TO_SERVER")];
	}
	
	isLoggedIn = NO;
	isConnected = reconnectEnabled = YES;
	
	encoding = config.encoding;
	
	if (NSObjectIsEmpty(inputNick)) {
		inputNick = config.nick;
	}
	
	sentNick = inputNick;
	myNick   = inputNick;
	
	[isupport reset];
	
	NSInteger modeParam = ((config.invisibleMode) ? 8 : 0);
	
	NSString *user = config.username;
	NSString *realName = config.realName;
	
	if (NSObjectIsEmpty(user)) {
        user = config.nick;
    }
    
	if (NSObjectIsEmpty(realName)) {
        realName = config.nick;
    }
    
    [self send:IRCCI_CAP, @"LS", nil];
	
	if (NSObjectIsNotEmpty(config.password)) {
        [self send:IRCCI_PASS, config.password, nil];
    }
	
	[self send:IRCCI_NICK, sentNick, nil];
	
	if (config.bouncerMode) { // Fuck psybnc — use ZNC
		[self send:IRCCI_USER, user, [NSString stringWithDouble:modeParam], @"*", [@":" stringByAppendingString:realName], nil];
	} else {
		[self send:IRCCI_USER, user, [NSString stringWithDouble:modeParam], @"*", realName, nil];
	}
	
	[world reloadTree];
}

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender
{
	if (disconnectType == DISCONNECT_BAD_SSL_CERT) {
		NSString *suppKey = [@"Preferences.prompts.cert_trust_error." stringByAppendingString:config.guid];
		
		if (config.isTrustedConnection == NO) {
			BOOL status = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_MESSAGE") 
														   title:TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_TITLE") 
												   defaultButton:TXTLS(@"TRUST_BUTTON") 
												 alternateButton:TXTLS(@"CANCEL_BUTTON")
													 otherButton:nil
												  suppressionKey:suppKey
												 suppressionText:@"-"];
			
			[_NSUserDefaults() setBool:status forKey:suppKey];
			
			if (status) {
				config.isTrustedConnection = status;
				
				[self connect:CONNECT_BADSSL_CRT_RECONNECT];
				
				return;
			}
		}
	}
	
	[self changeStateOff];
}

- (void)ircConnectionDidError:(NSString *)error
{
	[self printError:error];
}

- (void)ircConnectionDidReceive:(NSData *)data
{
	lastMessageReceived = [NSDate epochTime];
	
	NSString *s = [NSString stringWithData:data encoding:encoding];
	
	if (PointerIsEmpty(s)) {
		s = [NSString stringWithData:data encoding:config.fallbackEncoding];
		
		if (PointerIsEmpty(s)) {
			s = [NSString stringWithData:data encoding:NSUTF8StringEncoding];
			
			if (PointerIsEmpty(s)) {
				NSLog(@"NSData decode failure. (%@)", data);
				
				return;
			}
		}
	}
	
	world.messagesReceived++;
	world.bandwidthIn += [s length];
	
	if (rawModeEnabled) {
		NSLog(@" >> %@", s);
	}
	
	if ([Preferences removeAllFormatting]) {
		s = [s stripEffects];
	}
	
	IRCMessage *m = [[IRCMessage alloc] initWithLine:s];
	
	NSString *cmd = m.command;
	
	if (m.numericReply > 0) { 
		[self receiveNumericReply:m];
	} else {
		switch ([Preferences commandUIndex:cmd]) {	
			case 4: // Command: ERROR
            {
				[self receiveError:m];
				break;
            }
			case 5: // Command: INVITE
            {
				[self receiveInvite:m];
				break;
            }
			case 7: // Command: JOIN
            {
				[self receiveJoin:m];
				break;
            }
			case 8: // Command: KICK
            {
				[self receiveKick:m];
				break;
            }
			case 9: // Command: KILL
            {
				[self receiveKill:m];
				break;
            }
			case 11: // Command: MODE
            {
				[self receiveMode:m];
				break;
            }
			case 13: // Command: NICK
            {
				[self receiveNick:m];
				break;
            }
			case 14: // Command: NOTICE
			case 19: // Command: PRIVMSG
            {
				[self receivePrivmsgAndNotice:m];
				break;
            }
			case 15: // Command: PART
                
            {
				[self receivePart:m];
				break;
            }
            case 17: // Command: PING
            {
                [self receivePing:m];
                break;
            }
            case 20: // Command: QUIT
            {
                [self receiveQuit:m];
                break;
            }
            case 21: // Command: TOPIC
            {
                [self receiveTopic:m];
                break;
            }
            case 80: // Command: WALLOPS
            case 85: // Command: CHATOPS
            case 86: // Command: GLOBOPS
            case 87: // Command: LOCOPS
            case 88: // Command: NACHAT
            case 89: // Command: ADCHAT
            {
                [m.params safeInsertObject:m.sender.nick atIndex:0];
                
                NSString *text = [m.params safeObjectAtIndex:1];
                
                [m.params safeRemoveObjectAtIndex:1];
                [m.params safeInsertObject:[NSString stringWithFormat:@"[%@]: %@", m.command, text] atIndex:1];
                
                m.command = IRCCI_NOTICE;
                
                [self receivePrivmsgAndNotice:m];
                
                break;
            }
            case 101: // Command: AUTHENTICATE
            case 102: // Command: CAP
            {
                [self receiveCapacityOrAuthenticationRequest:m];
                break;
            }
        }
    }
    
    if ([[world bundlesForServerInput] containsKey:cmd]) {
        [[self invokeInBackgroundThread] processBundlesServerMessage:m];
    }
    
    [world updateTitle];
}

- (void)ircConnectionWillSend:(NSString *)line
{
}

#pragma mark -
#pragma mark Init

+ (void)load
{
	if (NSDissimilarObjects(self, [IRCClient class])) return;
	
	@autoreleasepool {
	
		dateTimeFormatter = [NSDateFormatter new];
		[dateTimeFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateTimeFormatter setTimeStyle:NSDateFormatterLongStyle];
	
	}
}

@end
