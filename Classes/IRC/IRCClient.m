// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#include <arpa/inet.h>

#define PONG_INTERVAL				150
#define RETRY_INTERVAL				240
#define RECONNECT_INTERVAL			20
#define ISON_CHECK_INTERVAL			30
#define TRIAL_PERIOD_INTERVAL		1800
#define AUTOJOIN_DELAY_INTERVAL		2

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
@synthesize identifyCTCP;
@synthesize identifyMsg;
@synthesize inChanBanList;
@synthesize inFirstISONRun;
@synthesize inList;
@synthesize inWhoWasRequest;
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
@synthesize sendLagcheckToChannel;
@synthesize sentNick;
@synthesize serverHasNickServ;
@synthesize serverHostname;
@synthesize trackedUsers;
@synthesize tryingNickNumber;
@synthesize whoisChannel;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		tryingNickNumber = -1;
		
		channels     = [NSMutableArray new];
		commandQueue = [NSMutableArray new];
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
	[autoJoinTimer drain];
	[chanBanListSheet drain];
	[channelListDialog drain];
	[channels drain];
	[commandQueueTimer stop];
	[commandQueueTimer drain];
	[commandQueue drain];
	[config drain];
	[conn autodrain];
	[conn close];
	[inputNick drain];
	[inviteExceptionSheet drain];
	[isonTimer stop];
	[isonTimer drain];
	[isupport drain];
	[lastSelectedChannel drain];
	[logDate drain];
	[logFile drain];
	[myHost drain];
	[myNick drain];
	[pongTimer stop];
	[pongTimer drain];
	[reconnectTimer stop];
	[reconnectTimer drain];
	[retryTimer stop];
	[retryTimer drain];
	[sentNick drain];
	[serverHostname drain];
	[trackedUsers drain];
	
#ifdef IS_TRIAL_BINARY
	[trialPeriodTimer stop];
	[trialPeriodTimer drain];
#endif
	
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCClientConfig *)seed
{
	[config autodrain];
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	[config drain];
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
	IRCClientConfig *u = [[config mutableCopy] autodrain];
	
	[u.channels removeAllObjects];
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[u.channels safeAddObject:[[c.config mutableCopy] autodrain]];
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
	BOOL sendEvent = ([ignoreItem notifyJoins] == YES || [ignoreItem notifyWhoisJoins] == YES);
	BOOL sendWhois = BOOLReverseValue(localKey == @"USER_TRACKING_NICKNAME_NO_LONGER_AVAILABLE");
	
	if (sendEvent) {
		NSString *text = TXTFLS(localKey, host, ignoreItem.hostmask);
        
		IRCChannel *nsc = [self findChannelOrCreate:TXTLS(@"NOTIFICATION_WINDOW_TITLE") useTalk:YES];
		
        nsc.isUnread = YES;
        
		if ([ignoreItem notifyJoins] == YES) {
			[self printBoth:nsc type:LINE_TYPE_NOTICE text:text];
		}
		
		if ([ignoreItem notifyWhoisJoins] == YES && sendWhois == YES) {
			whoisChannel = nsc;
			
			[self sendWhois:nick];
		}
		
		[self notifyEvent:GROWL_ADDRESS_BOOK_MATCH lineType:LINE_TYPE_NOTICE target:nsc nick:nick text:text];
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
			if (g.notifyJoins || g.notifyWhoisJoins) {
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
		
		[trackedUsers drain];
		trackedUsers = [newEntries retain];
	} else {
		for (AddressBook *g in ignores) {
			if (g.notifyJoins || g.notifyWhoisJoins) {
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
	[channelListDialog drain];
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

- (NSString *)truncateTextForIRC:(NSMutableString **)string lineType:(LogLineType)type channel:(NSString *)chan 
{
	NSMutableString *base = *string;
	
	NSString *new  = [base copy];
	
	NSInteger stringl  = new.length;
	NSInteger baseMath = (chan.length + myHost.length + 14); 
	
	[new autodrain];
	
	if ((stringl + baseMath) > IRC_BODY_LEN) {
		stringl = (IRC_BODY_LEN - baseMath);
		
		new = [new safeSubstringToIndex:stringl];
		
		NSRange currentRange  = NSMakeRange(0, stringl);
		NSRange maxSpaceRange = NSMakeRange((stringl - 40), 40); 
		NSRange spaceRange    = [new rangeOfString:@" " options:NSBackwardsSearch range:maxSpaceRange]; 
		
		if (spaceRange.location != NSNotFound) {
			currentRange.length = (stringl - (stringl - spaceRange.location));
		}
		
		[base safeDeleteCharactersInRange:currentRange];
		
		return [new safeSubstringWithRange:currentRange];
	} else {
		[base safeDeleteCharactersInRange:NSMakeRange(0, new.length)];
	}
	
	*string = base;
	
	return new;
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
		
		[chanBanListSheet drain];
		chanBanListSheet = nil;
		
		[self createChanBanListDialog];
		
		return;
	}
	
	inChanBanList = YES;
	
	[chanBanListSheet show];
}

- (void)chanBanDialogOnUpdate:(ChanBanSheet *)sender
{
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+b", nil];
}

- (void)chanBanDialogWillClose:(ChanBanSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.modeString)) {
		[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [[world selectedChannel] name], sender.modeString]];
	}
	
	inChanBanList = NO;
	
	[chanBanListSheet drain];
	chanBanListSheet = nil;
}

#pragma mark -
#pragma mark Channel Invite Exception List Dialog

- (void)createChanInviteExceptionListDialog
{
	if (PointerIsEmpty(inviteExceptionSheet)) {
		IRCClient *u = [world selectedClient];
		IRCChannel *c = [world selectedChannel];
		
		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;
		
		inviteExceptionSheet = [ChanInviteExceptionSheet new];
		inviteExceptionSheet.delegate = self;
		inviteExceptionSheet.window = world.window;
	} else {
		[inviteExceptionSheet ok:nil];
		
		[inviteExceptionSheet drain];
		inviteExceptionSheet = nil;
		
		[self createChanBanExceptionListDialog];
		
		return;
	}
	
	inChanBanList = YES;
	
	[inviteExceptionSheet show];
}

- (void)chanInviteExceptionDialogOnUpdate:(ChanInviteExceptionSheet *)sender
{
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+I", nil];
}

- (void)chanInviteExceptionDialogWillClose:(ChanInviteExceptionSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.modeString)) {
		[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [[world selectedChannel] name], sender.modeString]];
	}
	
	inChanBanList = NO;
	
	[inviteExceptionSheet drain];
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
		
		[banExceptionSheet drain];
		banExceptionSheet = nil;
		
		[self createChanBanExceptionListDialog];
		
		return;
	}
	
	inChanBanList = YES;
	
	[banExceptionSheet show];
}

- (void)chanBanExceptionDialogOnUpdate:(ChanBanExceptionSheet *)sender
{
	[self send:IRCCI_MODE, [[world selectedChannel] name], @"+e", nil];
}

- (void)chanBanExceptionDialogWillClose:(ChanBanExceptionSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.modeString)) {
		[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [[world selectedChannel] name], sender.modeString]];
	}
	
	inChanBanList = NO;
	
	[banExceptionSheet drain];
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
	[self sendLine:IRCCI_LIST];
}

- (void)listDialogOnJoin:(ListDialog *)sender channel:(NSString *)channel
{
	[self joinUnlistedChannel:channel];
}

- (void)listDialogWillClose:(ListDialog *)sender
{
	[channelListDialog drain];
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
		if (hasIRCopAccess) return [self stopISONTimer];
		if (NSObjectIsEmpty(trackedUsers)) return [self stopISONTimer];
		
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
	
	[pongTimer start:PONG_INTERVAL];
}

- (void)stopPongTimer
{
	[pongTimer stop];
}

- (void)onPongTimer:(id)sender
{
	if (isLoggedIn) {
		if (NSObjectIsNotEmpty(serverHostname)) {
			[self send:IRCCI_PONG, serverHostname, nil];
		}
	} else {
		[self stopPongTimer];
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
	
	if (conn) {
		[conn close];
		[conn autodrain];
		conn = nil;
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
	
	conn		  = [IRCConnection new];
	conn.delegate = self;
    
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
}

- (void)disconnect
{
	if (conn) {
		[conn close];
		[conn autodrain];
		conn = nil;
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
	
	[inputNick autodrain];
	[sentNick autodrain];
	
	inputNick = [newNick retain];
	sentNick = [newNick retain];
	
	[self send:IRCCI_NICK, newNick, nil];
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
			
			return [self partChannel:chan];
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
			if (value != [m hasMode:mode]) {
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
			[s appendString:@" "];
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
		NSMutableString *prevTarget = [[target mutableCopy] autodrain];
		NSMutableString *prevPass   = [[pass mutableCopy] autodrain];
		
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
		
		if ((targetData.length + passData.length) > MAX_BODY_LEN) {
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
				
				[target setString:@""];
				[pass setString:@""];
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
					NSString *newstr = [CSFWBlowfish encodeData:*message key:chan.config.encryptionKey];
					
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
					NSString *newstr = [CSFWBlowfish decodeData:*message key:chan.config.encryptionKey];
					
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
	
	NSDictionary *errors = [NSDictionary dictionary];
	
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[details objectForKey:@"path"]] error:&errors];
	
	if (appleScript) {
		NSAppleEventDescriptor *firstParameter = [NSAppleEventDescriptor descriptorWithString:[details objectForKey:@"input"]];
		NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
		
        [parameters insertDescriptor:firstParameter atIndex:1];
		
		ProcessSerialNumber psn = { 0, kCurrentProcess };
        
		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
																						bytes:&psn
																					   length:sizeof(ProcessSerialNumber)];
		NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:@"textualcmd"];
		NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																				 eventID:kASSubroutineEvent
																		targetDescriptor:target
																				returnID:kAutoGenerateReturnID
																		   transactionID:kAnyTransactionID];
		
		[event setParamDescriptor:handler forKeyword:keyASSubroutineName];
		[event setParamDescriptor:parameters forKeyword:keyDirectObject];
		
		NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];
		
		if (errors && PointerIsEmpty(result)) {
			NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);
		} else {	
			NSString *finalResult = [[result stringValue] trim];
			
			if (NSObjectIsNotEmpty(finalResult)) {
				[[world iomt] inputText:finalResult command:IRCCI_PRIVMSG];
			}
		}
	} else {
		NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);	
	}
	
	[appleScript drain];
}

- (void)processBundlesUserMessage:(NSArray *)info
{
	NSString *command = @"";
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

- (BOOL)inputText:(NSString *)str command:(NSString *)command
{
	if (isConnected == NO) {
		if (NSObjectIsEmpty(str)) {
			return NO;
		}
	}
	
	id sel = world.selected;
	
	if (PointerIsEmpty(sel)) return NO;
	
	NSArray *lines = [str splitIntoLines];
	
	for (NSString *s in lines) {
		if (NSObjectIsEmpty(s)) continue;
		
		if ([sel isClient]) {
			if ([s hasPrefix:@"/"]) {
				s = [s safeSubstringFromIndex:1];
			}
			
			[self sendCommand:s];
		} else {
			IRCChannel *channel = (IRCChannel *)sel;
			
			if ([s hasPrefix:@"/"] && [s hasPrefix:@"//"] == NO) {
				s = [s safeSubstringFromIndex:1];
				
				[self sendCommand:s];
			} else {
				if ([s hasPrefix:@"/"]) {
					s = [s safeSubstringFromIndex:1];
				}
				
				[self sendText:s command:command channel:channel];
			}
		}
	}
	
	return YES;
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	[self sendText:message command:IRCCI_PRIVMSG channel:[world selectedChannelOn:self]];
}

- (void)sendText:(NSString *)str command:(NSString *)command channel:(IRCChannel *)channel
{
	if (NSObjectIsEmpty(str)) return;
	
	LogLineType type;
	
	if ([command isEqualToString:IRCCI_NOTICE]) {
		type = LINE_TYPE_NOTICE;
	} else if ([command isEqualToString:IRCCI_ACTION]) {
		type = LINE_TYPE_ACTION;
	} else {
		type = LINE_TYPE_PRIVMSG;
	}
	
	if ([[world bundlesForUserInput] containsKey:command]) {
		[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:str, nil, nil]];
	}
	
	NSArray *lines = [str splitIntoLines];
	
	for (NSString *line in lines) {
		if (NSObjectIsEmpty(line)) continue;
		
		NSMutableString *str = [line mutableCopy];
		
		while (NSObjectIsNotEmpty(str)) {
			NSString *newstr = [self truncateTextForIRC:&str lineType:type channel:channel.name];
			
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
		
		[str drain];
	}
}

- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text
{
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
	[self sendCTCPQuery:target command:IRCCI_PING text:[NSString stringWithFloat:CFAbsoluteTimeGetCurrent()]];
}

- (BOOL)sendCommand:(NSString *)s
{
	return [self sendCommand:s completeTarget:YES target:nil];
}

- (BOOL)sendCommand:(NSString *)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName
{
	NSMutableString *s = [[str mutableCopy] autodrain];
	
	NSString *cmd = [[s getToken] uppercaseString];
	
	if (NSObjectIsEmpty(cmd)) return NO;
	if (NSObjectIsEmpty(str)) return NO;
	
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	IRCChannel *selChannel = nil;
	
	if ([cmd isEqualToString:IRCCI_MODE] && ([s hasPrefix:@"+"] || [s hasPrefix:@"-"]) == NO) {
		// do not complete for /mode #chname ...
	} else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	BOOL cutColon = NO;
	
	if ([s hasPrefix:@"/"]) {
		cutColon = YES;
		
		[s safeDeleteCharactersInRange:NSMakeRange(0, 1)];
	}
	
	switch ([Preferences commandUIndex:cmd]) {
		case 3: // Command: AWAY
		{
			if (NSObjectIsEmpty(s) && cutColon == NO) {
				s = ((isAway == NO) ? (NSMutableString *)TXTLS(@"IRC_AWAY_COMMAND_DEFAULT_REASON") : nil);
			}
			
			if ([Preferences awayAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if (isConnected == NO) continue;
					
					[[u client] send:cmd, s, nil];
				}
			} else {
				if (isConnected == NO) return NO;
				
				[self send:cmd, s, nil];
			}
			
			return YES;
			break;
		}
		case 5: // Command: INVITE
		{
			targetChannelName = [s getToken];
			
			if (NSObjectIsEmpty(s) && cutColon == NO) {
				s = nil;
			}
			
			[self send:cmd, [targetChannelName trim], [s trim], nil];
			
			return YES;
			break;
		}
		case 51: // Command: J
		case 7: // Command: JOIN
		{
			if (selChannel && selChannel.isChannel && NSObjectIsEmpty(s)) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
				
				if ([targetChannelName isChannelName] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}
			
			if (NSObjectIsEmpty(s) && cutColon == NO) {
				s = nil;
			}
			
			[self send:IRCCI_JOIN, targetChannelName, s, nil];
			
			return YES;
			break;
		}
		case 8: // Command: KICK
		{
			if (selChannel && selChannel.isChannel && [s isModeChannelName] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
			}
			
			NSString *peer = [s getToken];
			
			if (peer) {
				NSString *reason = [s trim];
				
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
			NSString *peer = [s getToken];
			
			if (peer) {
				NSString *reason = [s trim];
				
				if (NSObjectIsEmpty(reason)) {
					reason = [Preferences IRCopDefaultKillMessage];
				}
				
				[self send:IRCCI_KILL, peer, reason, nil];
			}
			
			return YES;
			break;
		}
		case 13: // Command: NICK
		{
			NSString *newnick = [s getToken];
			
			if ([Preferences nickAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					[[u client] changeNick:newnick];
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
			BOOL opMsg = NO;
			BOOL secretMsg = NO;
			
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
					if (selChannel && selChannel.isChannel && [s isChannelName] == NO) {
						targetChannelName = selChannel.name;
					} else {
						targetChannelName = [s getToken];
					}
				} else {
					targetChannelName = [s getToken];
				}
			} else if ([cmd isEqualToString:IRCCI_ME]) {
				cmd = IRCCI_ACTION;
				
				if (selChannel) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = [s getToken];
				}
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || [cmd isEqualToString:IRCCI_NOTICE]) {
				if ([s hasPrefix:@"\x01"]) {
					cmd = (([cmd isEqualToString:IRCCI_PRIVMSG]) ? IRCCI_CTCP : IRCCI_CTCPREPLY);
					
					[s safeDeleteCharactersInRange:NSMakeRange(0, 1)];
					
					NSRange r = [s rangeOfString:@"\x01"];
					
					if (r.location != NSNotFound) {
						NSInteger len = (s.length - r.location);
						
						if (len > 0) {
							[s safeDeleteCharactersInRange:NSMakeRange(r.location, len)];
						}
					}
				}
			}
			
			if ([cmd isEqualToString:IRCCI_CTCP]) {
				NSMutableString *t = [[s mutableCopy] autodrain];
				NSString *subCommand = [[t getToken] uppercaseString];
				
				if ([subCommand isEqualToString:IRCCI_ACTION]) {
					cmd = IRCCI_ACTION;
					s = t;
					targetChannelName = [s getToken];
				} else {
					NSString *subCommand = [[s getToken] uppercaseString];
					
					if (NSObjectIsNotEmpty(subCommand)) {
						targetChannelName = [s getToken];
						
						if ([subCommand isEqualToString:IRCCI_PING]) {
							[self sendCTCPPing:targetChannelName];
						} else {
							[self sendCTCPQuery:targetChannelName command:subCommand text:s];
						}
					}
					
					return YES;
				}
			}
			
			if ([cmd isEqualToString:IRCCI_CTCPREPLY]) {
				targetChannelName = [s getToken];
				
				NSString *subCommand = [s getToken];
				
				[self sendCTCPReply:targetChannelName command:subCommand text:s];
				
				return YES;
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || 
				[cmd isEqualToString:IRCCI_NOTICE] || 
				[cmd isEqualToString:IRCCI_ACTION]) {
				
				if (NSObjectIsEmpty(s)) return NO;
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
					NSString *t = [self truncateTextForIRC:&s lineType:type channel:targetChannelName];
					
					for (NSString *chname in targets) {
						if (NSObjectIsEmpty(chname)) continue;
						
						BOOL opPrefix = NO;
						
						if ([chname hasPrefix:@"@"]) {
							opPrefix = YES;
							chname = [chname safeSubstringFromIndex:1];
						}
						
						NSString *lowerChname = [chname lowercaseString];
						
						IRCChannel *c = [self findChannel:chname];
						
						if (PointerIsEmpty(c)
							&& [chname isChannelName] == NO
							&& [lowerChname isEqualToString:@"nickserv"] == NO
							&& [lowerChname isEqualToString:@"chanserv"] == NO) {
							
							if (secretMsg == NO) {
								if (type == LINE_TYPE_NOTICE) {
									c = (id)self;
								} else {
									c = [world createTalk:chname client:self];
								}
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
					}
				}
			} 
			
			return YES;
			break;
		}
		case 15: // Command: PART
		case 52: // Command: LEAVE
		{
			if (selChannel && selChannel.isChannel && [s isChannelName] == NO) {
				targetChannelName = selChannel.name;
			} else if (selChannel && selChannel.isTalk && [s isChannelName] == NO) {
				[world destroyChannel:selChannel];
				
				return YES;
			} else {
				targetChannelName = [s getToken];
			}
			
			if (targetChannelName) {
				NSString *reason = [s trim];
				
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
			[self quit:[s trim]];
			
			return YES;
			break;
		}
		case 21: // Command: TOPIC
		case 61: // Command: T
		{
			if (selChannel && selChannel.isChannel && [s isChannelName] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
			}
			
			if (targetChannelName) {
				if (NSObjectIsEmpty(s) && cutColon == NO) {
					s = nil;
				}
				
				IRCChannel *c = [self findChannel:targetChannelName];
				
				if ([self encryptOutgoingMessage:&s channel:c] == YES) {
					[self send:IRCCI_TOPIC, targetChannelName, s, nil];
				}
			}
			
			return YES;
			break;
		}
		case 23: // Command: WHO
		{
			NSString *chaname = [s getToken];
			
			if (NSObjectIsEmpty(s)) {
				if ([chaname isChannelName]) {
					IRCChannel *c = [self findChannel:chaname];
					
					if (c) {
						[c setIsWhoInit:YES];
						[c setForceOutput:YES];
					}
				}
				
				[self send:IRCCI_WHO, chaname, nil];
			} else {
				[self send:IRCCI_WHO, chaname, s, nil];
			}
			
			return YES;
			break;
		}
		case 24: // Command: WHOIS
		{
			if ([s contains:@" "]) {
				[self sendLine:[NSString stringWithFormat:@"%@ %@", IRCCI_WHOIS, s]];
			} else {
				[self send:IRCCI_WHOIS, s, s, nil];
			}
			
			return YES;
			break;
		}
		case 32: // Command: CTCP
		{ 
			NSString *subCommand = [[s getToken] uppercaseString];
			
			if (NSObjectIsNotEmpty(subCommand)) {
				targetChannelName = [s getToken];
				
				if ([subCommand isEqualToString:IRCCI_PING]) {
					[self sendCTCPPing:targetChannelName];
				} else {
					[self sendCTCPQuery:targetChannelName command:subCommand text:s];
				}
			}
			
			return YES;
			break;
		}
		case 33: // Command: CTCPREPLY
		{
			targetChannelName = [s getToken];
			
			NSString *subCommand = [s getToken];
			
			[self sendCTCPReply:targetChannelName command:subCommand text:s];
			
			return YES;
			break;
		}
		case 41: // Command: BAN
		case 64: // Command: UNBAN
		{
			if (c) {
				NSString *peer = [s getToken];
				
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
				if (selChannel && selChannel.isChannel && [s isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else if (([s hasPrefix:@"+"] || [s hasPrefix:@"-"]) == NO) {
					targetChannelName = [s getToken];
				}
			} else if ([cmd isEqualToString:IRCCI_UMODE]) {
				[s insertString:@" " atIndex:0];
				[s insertString:myNick atIndex:0];
			} else {
				if (selChannel && selChannel.isChannel && [s isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = [s getToken];
				}
				
				NSString *sign;
				
				if ([cmd hasPrefix:@"DE"] || [cmd hasPrefix:@"UN"]) {
					sign = @"-";
					cmd = [cmd safeSubstringFromIndex:2];
				} else {
					sign = @"+";
				}
				
				NSArray *params = [s componentsSeparatedByString:@" "];
				
				if (NSObjectIsEmpty(params)) {
					return YES;
				} else {
					NSMutableString *ms = [NSMutableString stringWithString:sign];
					NSString *modeCharStr = [[cmd safeSubstringToIndex:1] lowercaseString];
					
					for (NSInteger i = (params.count - 1); i >= 0; --i) {
						[ms appendString:modeCharStr];
					}
					
					[ms appendString:@" "];
					[ms appendString:s];
					
					[s setString:ms];
				}
			}
			
			NSMutableString *line = [NSMutableString string];
			
			[line appendString:IRCCI_MODE];
			
			if (NSObjectIsNotEmpty(targetChannelName)) {
				[line appendString:@" "];
				[line appendString:targetChannelName];
			}
			
			if (NSObjectIsNotEmpty(s)) {
				[line appendString:@" "];
				[line appendString:s];
			}
			
			[self sendLine:line];
			
			return YES;
			break;
		}
		case 42: // Command: CLEAR
		{
			if (c) {
				[world clearContentsOfChannel:c inClient:self];
				
				[c setUnreadCount:0];
				[c setKeywordCount:0];
			} else if (u) {
				[world clearContentsOfClient:self];
				
				[u setUnreadCount:0];
				[u setKeywordCount:0];
			}
			
			[world updateIcon];
			
			return YES;
			break;
		}
		case 43: // Command: CLOSE
		case 77: // Command: REMOVE
		{
			NSString *nick = [s getToken];
			
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
				[world.menuController showServerPropertyDialog:self ignore:@"-"];
			} else {
				NSString *n = [s getToken];
				IRCUser  *u = [c findMember:n];
				
				if (PointerIsEmpty(u)) {
					[world.menuController showServerPropertyDialog:self ignore:n];
					
					return YES;
				}
				
				NSString *hostmask = [u banMask];
				
				AddressBook *g = [AddressBook newad];
				
				g.hostmask = hostmask;
				g.ignorePublicMsg = YES;
				g.ignorePrivateMsg = YES;
				g.ignoreHighlights = YES;
				g.ignorePMHighlights = YES;
				g.ignoreNotices = YES;
				g.ignoreCTCP = YES;
				g.ignoreJPQE = YES;
				g.notifyJoins = NO;
				g.notifyWhoisJoins = NO;
				
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
			[self sendLine:s];
			
			return YES;
			break;
		}
		case 59: // Command: QUERY
		{
			NSString *nick = [s getToken];
			
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
			NSInteger interval = [[s getToken] integerValue];
			
			if (interval > 0) {
				TimerCommand *cmd = [TimerCommand newad];
				
				if ([s hasPrefix:@"/"]) {
					[s safeDeleteCharactersInRange:NSMakeRange(0, 1)];
				}
				
				cmd.input = s;
				cmd.time = (CFAbsoluteTimeGetCurrent() + interval);
				cmd.cid = ((c) ? c.uid : -1);
				
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
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:@"WEIGHTS: "];
				
				for (IRCUser *m in c.members) {
					if (m.totalWeight > 0) {
						NSString *text = TXTFLS(@"IRC_WEIGHTS_COMMAND_RESULT", m.nick, m.incomingWeight, m.outgoingWeight, m.totalWeight);
						
						[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
					}
				}
			}
			
			return YES;
			break;
		}
		case 69: // Command: ECHO
		case 70: // Command: DEBUG
		{
			if ([s isEqualNoCase:@"raw on"]) {
				rawModeEnabled = YES;
				
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_ENABLED")];
			} else if ([s isEqualNoCase:@"raw off"]) {
				rawModeEnabled = NO;	
				
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_DISABLED")];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:s];
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
					
					[c setUnreadCount:0];
					[c setKeywordCount:0];
				}
			} else {
				for (IRCClient *u in [world clients]) {
					[world clearContentsOfClient:u];
					
					for (IRCChannel *c in [u channels]) {
						[world clearContentsOfChannel:c inClient:u];
						
						[c setUnreadCount:0];
						[c setKeywordCount:0];
					}
				}
			}
			
			[world updateIcon];
			[world markAllAsRead];
			
			return YES;
			break;
		}
		case 72: // Command: AMSG
		{
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
						
						[[u client] sendCommand:[NSString stringWithFormat:@"MSG %@ %@", c.name, s] completeTarget:YES target:c.name];
					}
				}
			} else {
				if (isConnected == NO) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
					
					[self sendCommand:[NSString stringWithFormat:@"MSG %@ %@", c.name, s] completeTarget:YES target:c.name];
				}
			}
			
			[self reloadTree];
			
			return YES;
			break;
		}
		case 73: // Command: AME
		{
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if ([u isConnected] == NO) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
						
						[[u client] sendCommand:[NSString stringWithFormat:@"ME %@", s] completeTarget:YES target:c.name];
					}
				}
			} else {
				if (isConnected == NO) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
					
					[self sendCommand:[NSString stringWithFormat:@"ME %@", s] completeTarget:YES target:c.name];
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
				NSString *peer = [s getToken];
				
				if (peer) {
					NSString *reason = [s trim];
					
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
			if ([s contains:@" "] == NO) return NO;
			
			NSArray *data = [s componentsSeparatedByString:@" "];
			
			[DockIcon drawWithHilightCount:[data integerAtIndex:0] 
							  messageCount:[data integerAtIndex:1]];
			
			return YES;
			break;
		}
		case 82: // Command: SERVER
		{
			if (NSObjectIsNotEmpty(s)) {
				[world createConnection:s chan:nil];
			}
			
			return YES;
			break;
		}
		case 83: // Command: CONN
		{
			if (NSObjectIsNotEmpty(s)) {
				[config setHost:s];
			}
			
			if (isConnected) [self quit];
			
			[self connect];
			
			return YES;
			break;
		}
		case 84: // Command: MYVERSION
		{
			NSString *ref = [[Preferences textualInfoPlist] objectForKey:@"Build Reference"];
			
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
		case 90: // Command: RESETFILES
		{
			NSString *path = [Preferences whereApplicationSupportPath];
			
			BOOL doAction = [PopupPrompts dialogWindowWithQuestion:TXTFLS(@"RESOURCES_FILE_RESET_WARNING_MESSAGE", path)
															 title:TXTLS(@"RESOURCES_FILE_RESET_WARNING_TITLE")
													 defaultButton:TXTLS(@"CONTINUE_BUTTON")
												   alternateButton:TXTLS(@"CANCEL_BUTTON")
													suppressionKey:nil suppressionText:nil];
			
			if (doAction) {
				if ([_NSFileManager() removeItemAtPath:path error:NULL] == NO) {
					NSLog(@"Silently ignoring failed resource removal.");
				}
				
				NSString *themeName = [ViewTheme extractThemeName:[Preferences themeName]];
				NSString *themePath = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:themeName];
				
				if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
					[_NSUserDefaults() setObject:DEFAULT_TEXUAL_STYLE forKey:@"Preferences.Theme.log_font_name"];
				}
				
				[PopupPrompts dialogWindowWithQuestion:TXTLS(@"RESOURCES_FILE_RESET_QUITTING_MESSAGE")
												 title:TXTLS(@"RESOURCES_FILE_RESET_QUITTING_TITLE")
										 defaultButton:TXTLS(@"OK_BUTTON") 
									   alternateButton:nil suppressionKey:nil suppressionText:nil];
				
				world.master.terminating = YES; 
				
				[NSApp terminate:nil];
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
			NSString *peer = [s getToken];
			
			if ([peer hasPrefix:@"-"]) {
				[self send:cmd, peer, s, nil];
			} else {
				NSString *time   = [s getToken];
				NSString *reason = s;
				
				if (peer) {
					reason = [reason trim];
					
					if (NSObjectIsEmpty(reason)) {
						reason = [Preferences IRCopDefaultGlineMessage];
						
						if ([reason contains:@" "]) {
							NSInteger spacePos = [reason stringPosition:@" "];
							
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
			NSString *peer   = [s getToken];
			
			if ([peer hasPrefix:@"-"]) {
				[self send:cmd, peer, s, nil];
			} else {
				if (peer) {
					if ([cmd isEqualToString:IRCCI_TEMPSHUN]) {
						NSString *reason = [s getToken];
						
						reason = [reason trim];
						
						if (NSObjectIsEmpty(reason)) {
							reason = [Preferences IRCopDefaultShunMessage];
							
							if ([reason contains:@" "]) {
								NSInteger spacePos = [reason stringPosition:@" "];
								
								reason = [reason safeSubstringAfterIndex:spacePos];
							}
						}
						
						[self send:cmd, peer, reason, nil];
					} else {
						NSString *time   = [s getToken];
						NSString *reason = s;
						
						reason = [reason trim];
						
						if (NSObjectIsEmpty(reason)) {
							reason = [Preferences IRCopDefaultShunMessage];
							
							if ([reason contains:@" "]) {
								NSInteger spacePos = [reason stringPosition:@" "];
								
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
		default:
		{
			NSString *scriptPath  = [[Preferences whereScriptsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.scpt", [cmd lowercaseString]]];
			NSString *localScript = [[Preferences whereScriptsLocalPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.scpt", [cmd lowercaseString]]];
            
			BOOL scriptFound  = [_NSFileManager() fileExistsAtPath:scriptPath];
			BOOL lscriptFound = [_NSFileManager() fileExistsAtPath:localScript];
			BOOL pluginFound  = BOOLValueFromObject([world.bundlesForUserInput objectForKey:cmd]);
			
			if (pluginFound && (scriptFound || lscriptFound)) {
				NSLog(@"Command %@ shared by both a script and plugin. Sending to server because of inability to determine priority.", cmd);
			} else {
				if (pluginFound) {
					[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:[NSString stringWithString:s], cmd, nil]];
					
					return YES;
				} else {
                    if (scriptFound || localScript) {
                        if (scriptFound == NO) {
                            scriptPath = localScript;
                        }
                        
						if ([_NSFileManager() fileExistsAtPath:scriptPath]) {
							NSDictionary *inputInfo = [NSDictionary dictionaryWithObjectsAndKeys:c.name, @"channel", scriptPath, @"path", s, @"input", 
													   NSNumberWithBOOL(completeTarget), @"completeTarget", targetChannelName, @"target", nil];
							
							[[self invokeInBackgroundThread] executeTextualCmdScript:inputInfo];
							
							return YES;
						} 
                    }
                }
            }
            
            if (cutColon) {
                [s insertString:@":" atIndex:0];
            }
            
            if ([s length]) {
                [s insertString:@" " atIndex:0];
            }
            
            [s insertString:cmd atIndex:0];
            
            [self sendLine:s];
            
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
        
        [s appendString:@" "];
        
        if (i == (count - 1) && (NSObjectIsEmpty(e) || [e hasPrefix:@":"] || [e contains:@" "])) {
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
    
    return ((PointerIsEmpty(c)) ? [self findChannelOrCreate:name useTalk:NO] : c);
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name useTalk:(BOOL)doTalk
{
    if (doTalk) {
        return [world createTalk:name client:self];
    } else {
        IRCChannelConfig *seed = [IRCChannelConfig newad];
        
        seed.name = name;
        
        return [world createChannel:seed client:self reload:YES adjust:YES];
    }
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

- (BOOL)notifyText:(GrowlNotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
    if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
        return NO;
    }
    
    [SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
    
    if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return YES;
    if ([Preferences growlEnabledForEvent:type] == NO) return YES;
    if ([Preferences disableWhileAwayForEvent:type] == YES && isAway == YES) return YES;
    
    IRCChannel *channel = nil;
    NSString *chname = nil;
    
    if (target) {
        if ([target isKindOfClass:[IRCChannel class]]) {
            channel = (IRCChannel *)target;
            chname = channel.name;
            
            if (channel.config.growl == NO) {
                return YES;
            }
        } else {
            chname = (NSString *)target;
        }
    }
    
    if (NSObjectIsEmpty(chname)) {
        chname = self.name;
    }
    
    NSString *context = nil;
    NSString *title = chname;
    NSString *desc = [NSString stringWithFormat:@"<%@> %@", nick, text];
    
    if (channel) {
        context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
    } else {
        context = [NSString stringWithDouble:uid];
    }
    
    [world notifyOnGrowl:type title:title desc:desc context:context];
    
    return YES;
}

- (BOOL)notifyEvent:(GrowlNotificationType)type lineType:(LogLineType)ltype
{
    return [self notifyEvent:type lineType:ltype target:nil nick:@"" text:@""];
}

- (BOOL)notifyEvent:(GrowlNotificationType)type lineType:(LogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
    if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
        return NO;
    }
    
    [SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
    
    if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return YES;
    if ([Preferences growlEnabledForEvent:type] == NO) return YES;
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
    
    NSString *title = @"";
    NSString *desc = @"";
    
    switch (type) {
        case GROWL_LOGIN:
            title = self.name;
            break;
        case GROWL_DISCONNECT:
            title = self.name;
            break;
        case GROWL_KICKED:
            title = channel.name;
            desc = TXTFLS(@"GROWL_MSG_KICKED_DESC", nick, text);
            break;
        case GROWL_INVITED:
            title = self.name;
            desc = TXTFLS(@"GROWL_MSG_INVITED_DESC", nick, text);
            break;
        case GROWL_ADDRESS_BOOK_MATCH:
            desc = text;
            break;
        default:
            return YES;
    }
    
    NSString *context = nil;
    
    if (channel) {
        context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
    } else {
        context = [NSString stringWithDouble:uid];
    }
    
    [world notifyOnGrowl:type title:title desc:desc context:context];
    
    return YES;
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(id)t
{
    if ([t isKindOfClass:[IRCChannel class]]) {
        if ([t isChannel] == YES || [t isTalk] == YES) {
            if (world.selected != t || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
                [t setKeywordCount:([t keywordCount] + 1)];
                
                [world updateIcon];
            }
        }
    }
    
    if ([t isKeyword]) return;
    if ([NSApp isActive] && world.selected == t) return;
    
    [t setIsKeyword:YES];
    
    [self reloadTree];
    
    if ([NSApp isActive] == NO) [NSApp requestUserAttention:NSInformationalRequest];
}

- (void)setNewTalkState:(id)t
{
    if ([NSApp isActive] && world.selected == t) return;
    if ([t isNewTalk]) return;
    
    [t setIsNewTalk:YES];
    
    [self reloadTree];
    
    if ([NSApp isActive] == NO) [NSApp requestUserAttention:NSInformationalRequest];
    
    [world updateIcon];
}

- (void)setUnreadState:(id)t
{
    if ([t isKindOfClass:[IRCChannel class]]) {
        if ([Preferences countPublicMessagesInIconBadge] == NO) {
            if ([t isTalk] == YES && [t isClient] == NO) {
                if (world.selected != t || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
                    [t setUnreadCount:([t unreadCount] + 1)];
                    
                    [world updateIcon];
                }
            }
        } else {
            if (world.selected != t || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
                [t setUnreadCount:([t unreadCount] + 1)];
                
                [world updateIcon];
            }	
        }
    }
    
    if ([t isUnread]) return;
    if ([NSApp isActive] && world.selected == t) return;
    
    [t setIsUnread:YES];
    
    [self reloadTree];
}

#pragma mark -
#pragma mark Print

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString *)text
{
    return [self printBoth:chan type:type nick:nil text:text identified:NO];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
    return [self printChannel:chan type:type nick:nick text:text identified:identified];
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
                
                if ([mark isEqualToString:@" "] || NSObjectIsEmpty(mark)) {
                    format = [format stringByReplacingOccurrencesOfString:@"%@" withString:@""];
                } else {
                    format = [format stringByReplacingOccurrencesOfString:@"%@" withString:mark];
                }
            } else {
                format = [format stringByReplacingOccurrencesOfString:@"%@" withString:@""];	
            }
        } else {
            format = [format stringByReplacingOccurrencesOfString:@"%@" withString:@""];	
        }
    }
    
    return format;
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type text:(NSString *)text
{
    return [self printChannel:chan type:type nick:nil text:text identified:NO];
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
                [logDate drain];
                
                logDate = [comp retain];
                [logFile reopenIfNeeded];
            }
        } else {
            logDate = [comp retain];
        }
        
        NSString *nickStr = @"";
        
        if (line.nick) {
            nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
        }
        
        NSString *s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
        
        [logFile writeLine:s];
    }
    
    return result;
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text 
{
    return [self printRawHTMLToCurrentChannel:text withTimestamp:YES];
}

- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text 
{
    return [self printRawHTMLToCurrentChannel:text withTimestamp:NO];
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime
{
    LogLine *c = [LogLine newad];
    
    IRCChannel *channel = [world selectedChannelOn:self];
    
    c.body       = text;
    c.lineType   = LINE_TYPE_REPLY;
    c.memberType = MEMBER_TYPE_NORMAL;
    
    if (showTime) {
        NSString *time = TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
        
        if (NSObjectIsNotEmpty(time)) {
            time = [time stringByAppendingString:@" "];
        }
        
        c.time = time;
    }
    
    if (channel) {
        return [channel print:c withHTML:YES];
    } else {
        return [log print:c withHTML:YES];
    }
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
    if ([self outputRuleMatchedInMessage:text inChannel:chan withLineType:type] == YES) {
        return NO;
    }
    
    LogLine *c = [LogLine newad];
    
    NSString *time = TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
    
    IRCChannel *channel = nil;
    
    NSString *place   = nil;
    NSString *nickStr = nil;
    
    LogMemberType memberType = MEMBER_TYPE_NORMAL;
    
    NSInteger colorNumber = 0;
    
    NSArray *keywords     = nil;
    NSArray *excludeWords = nil;
    
    if (nick && [nick isEqualToString:myNick]) {
        memberType = MEMBER_TYPE_MYSELF;
    }
    
    if ([chan isKindOfClass:[IRCChannel class]]) {
        channel = chan;
    } else if ([chan isKindOfClass:[NSString class]]) {
        place = [NSString stringWithFormat:@"<%@> ", chan];
    }
    
    if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) {
        if (memberType != MEMBER_TYPE_MYSELF) {
            if (channel && [[channel config] ihighlights] == NO) {
                keywords     = [Preferences keywords];
                excludeWords = [Preferences excludeWords];
                
                if ([Preferences keywordMatchingMethod] != KEYWORD_MATCH_REGEX) {
                    if ([Preferences keywordCurrentNick]) {
                        NSMutableArray *ary = [[keywords mutableCopy] autodrain];
                        
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
        time = [time stringByAppendingString:@" "];
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
    
    c.place = place;
    c.nick  = nickStr;
    
    c.body = text;
    
    c.lineType			= type;
    c.memberType		= memberType;
    c.nickInfo			= nick;
    c.clickInfo			= nil;
    c.identified		= identified;
    c.nickColorNumber	= colorNumber;
    
    c.keywords		= keywords;
    c.excludeWords	= excludeWords;
    
    if (channel) {
        if ([Preferences autoAddScrollbackMark]) {
            if (channel != [world selectedChannel] || [[NSApp mainWindow] isOnCurrentWorkspace] == NO) {
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
    [self printChannel:channel type:LINE_TYPE_SYSTEM text:text];
}

- (void)printSystemBoth:(id)channel text:(NSString *)text
{
    [self printBoth:channel type:LINE_TYPE_SYSTEM text:text];
}

- (void)printReply:(IRCMessage *)m
{
    [self printBoth:nil type:LINE_TYPE_REPLY text:[m sequence:1]];
}

- (void)printUnknownReply:(IRCMessage *)m
{
    [self printBoth:nil type:LINE_TYPE_REPLY text:[m sequence:1]];
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
    
    [self printBoth:channel type:LINE_TYPE_ERROR_REPLY text:text];
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
            [self printBoth:c type:type nick:anick text:text identified:identified];
            
            [self notifyText:GROWL_CHANNEL_NOTICE lineType:type target:c nick:anick text:text];
        } else {
            BOOL highlight = [self printBoth:c type:type nick:anick text:text identified:identified];
            BOOL postevent = NO;
            
            if (highlight) {
                postevent = [self notifyText:GROWL_HIGHLIGHT lineType:type target:c nick:anick text:text];
                
                if (postevent) {
                    [self setKeywordState:c];
                }
            } else {
                postevent = [self notifyText:GROWL_CHANNEL_MSG lineType:type target:c nick:anick text:text];
            }
            
            if (postevent) {
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
    } else if ([target isEqualNoCase:myNick]) {
        if ([ignoreChecks ignorePMHighlights] == YES) {
            if (type == LINE_TYPE_ACTION) {
                type = LINE_TYPE_ACTION_NH;
            } else if (type == LINE_TYPE_PRIVMSG) {
                type = LINE_TYPE_PRIVMSG_NH;
            }
        }
        
        if ([ignoreChecks ignorePrivateMsg] == YES) {
            return;
        }
        
        if (NSObjectIsEmpty(anick)) {
            [self printBoth:nil type:type text:text];
        } else if ([anick isNickname] == NO) {
            if (type == LINE_TYPE_NOTICE) {
                if (hasIRCopAccess) {
                    if ([text hasPrefix:@"*** Notice -- Client connecting"] || 
                        [text hasPrefix:@"*** Notice -- Client exiting"] || 
                        [text hasPrefix:@"*** You are connected to"] || 
                        [text hasPrefix:@"Forbidding Q-lined nick"] || 
                        [text hasPrefix:@"Exiting ssl client"]) {
                        
                        [self printBoth:nil type:type text:text];	
                        
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
                            
                            NSArray *chunks = [text componentsSeparatedByString:@" "];
                            
                            host = [chunks safeObjectAtIndex:(8 + match_math)];
                            snick = [chunks safeObjectAtIndex:(7 + match_math)];
                            
                            host = [host safeSubstringFromIndex:1];
                            host = [host safeSubstringToIndex:([host length] - 1)];
                            
                            ignoreChecks = [self checkIgnoreAgainstHostmask:[snick stringByAppendingFormat:@"!%@", host]
                                                                withMatches:[NSArray arrayWithObjects:@"notifyWhoisJoins", @"notifyJoins", nil]];
                            
                            [self handleUserTrackingNotification:ignoreChecks 
                                                        nickname:snick 
                                                        hostmask:host
                                                        langitem:@"USER_TRACKING_HOSTMASK_CONNECTED"];
                        }
                    } else {
                        if ([Preferences handleServerNotices]) {
                            if ([Preferences handleIRCopAlerts] && [text containsIgnoringCase:[Preferences IRCopAlertMatch]]) {
                                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_NOTICE text:text];
                            } else {
                                IRCChannel *c = [self findChannelOrCreate:TXTLS(@"SERVER_NOTICES_WINDOW_TITLE") useTalk:YES];
                                
                                c.isUnread = YES;
                                
                                [self printBoth:c type:type text:text];
                            }
                        } else {
                            [self printBoth:nil type:type text:text];
                        }
                    }
                } else {
                    [self printBoth:nil type:type text:text];
                }
            } else {
                [self printBoth:nil type:type text:text];
            }
        } else {
            IRCChannel *c = [self findChannel:anick];
            
            [self decryptIncomingMessage:&text channel:c];
            
            BOOL newTalk = NO;
            
            if (PointerIsEmpty(c) && type != LINE_TYPE_NOTICE) {
                c = [world createTalk:anick client:self];
                
                newTalk = YES;
            }
            
            if (type == LINE_TYPE_NOTICE) {
                if ([ignoreChecks ignoreNotices] == YES) {
                    return;
                }
                
                if ([Preferences locationToSendNotices] == NOTICES_SENDTO_CURCHAN) {
                    c = [world selectedChannelOn:self];
                }
                
                [self printBoth:c type:type nick:anick text:text identified:identified];
                
                if ([anick isEqualNoCase:@"NickServ"]) {
                    if ([text hasPrefix:@"This nickname is registered"]) {
                        if (NSObjectIsNotEmpty(config.nickPassword)) {
                            serverHasNickServ = YES;
                            
                            [self send:IRCCI_PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
                        }
                    } else {
                        if ([Preferences autojoinWaitForNickServ]) {
                            if ([text hasPrefix:@"You are now identified"] ||
                                [text hasPrefix:@"You are already identified"] ||
                                [text hasSuffix:@"you are now recognized."]) {
                                
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
                
                [self notifyText:GROWL_TALK_NOTICE lineType:type target:c nick:anick text:text];
            } else {
                BOOL highlight = [self printBoth:c type:type nick:anick text:text identified:identified];
                BOOL postevent = NO;
                
                if (highlight) {
                    postevent = [self notifyText:GROWL_HIGHLIGHT lineType:type target:c nick:anick text:text];
                    
                    if (postevent) {
                        [self setKeywordState:c];
                    }
                } else {
                    if (newTalk) {
                        postevent = [self notifyText:GROWL_NEW_TALK lineType:type target:c nick:anick text:text];
                        
                        if (postevent) {
                            [self setNewTalkState:c];
                        }
                    } else {
                        postevent = [self notifyText:GROWL_TALK_MSG lineType:type target:c nick:anick text:text];
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
    } else {
        if (NSObjectIsEmpty(anick) || [anick isNickname] == NO) {
            [self printBoth:nil type:type text:text];
        } else {
            [self printBoth:nil type:type nick:anick text:text identified:identified];
        }
    }
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
    NSString *nick = m.sender.nick;
    
    NSMutableString *s = [[text mutableCopy] autodrain];
    NSString *command = [[s getToken] uppercaseString];
    
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
            [self printBoth:target type:LINE_TYPE_CTCP text:text];
        }
        
        if ([command isEqualToString:IRCCI_PING]) {
            [self sendCTCPReply:nick command:command text:s];
        } else if ([command isEqualToString:IRCCI_TIME]) {
            [self sendCTCPReply:nick command:command text:[[NSDate date] description]];
        } else if ([command isEqualToString:IRCCI_VERSION]) {
            NSString *ref = [[Preferences textualInfoPlist] objectForKey:@"Build Reference"];
            
            NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CTCP_VERSION_INFO"), 
                              [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"], 
                              [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"], 
                              ((NSObjectIsEmpty(ref)) ? @"Unknown" : ref)];
            
            [self sendCTCPReply:nick command:command text:text];
        } else if ([command isEqualToString:IRCCI_USERINFO]) {
            [self sendCTCPReply:nick command:command text:((config.userInfo) ?: @"")];
        } else if ([command isEqualToString:IRCCI_CLIENTINFO]) {
            [self sendCTCPReply:nick command:command text:TXTLS(@"IRC_CTCP_CLIENT_INFO")];
        } else if ([command isEqualToString:IRCCI_LAGCHECK]) {
            double time = CFAbsoluteTimeGetCurrent();
            
            if (time >= lastLagCheck) {
                double delta = (time - lastLagCheck);
                
                text = TXTFLS(@"LAG_CHECK_REQUEST_REPLY_MESSAGE", delta);
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
    
    NSMutableString *s = [[text mutableCopy] autodrain];
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
        double time = [s doubleValue];
        double delta = (CFAbsoluteTimeGetCurrent() - time);
        
        text = TXTFLS(@"IRC_RECIEVED_CTCP_PING_REPLY", nick, command, delta);
    } else {
        text = TXTFLS(@"IRC_RECIEVED_CTCP_REPLY", nick, command, s);
    }
    
    [self printBoth:c type:LINE_TYPE_CTCP text:text];
}

- (void)requestUserHosts:(IRCChannel *)c 
{
    if ([c.name isChannelName]) {
        [c setIsWhoInit:YES];
        [c setIsModeInit:YES];
        
        [self send:IRCCI_MODE, c.name, nil];
        [self send:IRCCI_WHO, c.name, nil, nil];
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
        
        [myHost drain];
        myHost = [m.sender.raw retain];
        
        if (autojoinInitialized == NO && [autoJoinTimer isActive] == NO) {
            [world select:c];
        }
        
        if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
            [c.client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED") channel:c];
        }
    }
    
    if ([c findMember:nick] == NO) {
        IRCUser *u = [IRCUser newad];
        
        u.o           = njoin;
        u.nick        = nick;
        u.username    = m.sender.user;
        u.address	  = m.sender.address;
        u.supportInfo = isupport;
        
        [c addMember:u];
    }
    
    if ([Preferences showJoinLeave]) {
        AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
                                                         withMatches:[NSArray arrayWithObjects:
                                                                      @"ignoreJPQE", 
                                                                      @"notifyWhoisJoins", 
                                                                      @"notifyJoins", nil]];
        
        if ([ignoreChecks ignoreJPQE] == YES && myself == NO) {
            return;
        }
        
        if (hasIRCopAccess == NO) {
            if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
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
        
        NSString *text = TXTFLS(@"IRC_USER_JOINED_CHANNEL", nick, m.sender.user, m.sender.address);
        
        [self printBoth:c type:LINE_TYPE_JOIN text:text];
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
            AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
                                                             withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
            
            if ([ignoreChecks ignoreJPQE] == YES) {
                return;
            }
            
            NSString *message = TXTFLS(@"IRC_USER_PARTED_CHANNEL", nick, m.sender.user, m.sender.address);
            
            if (NSObjectIsNotEmpty(comment)) {
                message = [message stringByAppendingFormat:@" (%@)", comment];
            }
            
            [self printBoth:c type:LINE_TYPE_PART text:message];
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
            AddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
                                                             withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
            
            if ([ignoreChecks ignoreJPQE] == YES) {
                return;
            }
            
            NSString *message = TXTFLS(@"IRC_USER_KICKED_FROM_CHANNEL", nick, target, comment);
            
            [self printBoth:c type:LINE_TYPE_KICK text:message];
        }
        
        if ([target isEqualNoCase:myNick]) {
            [c deactivate];
            
            [self reloadTree];
            [self notifyEvent:GROWL_KICKED lineType:LINE_TYPE_KICK target:c nick:nick text:comment];
            
            if ([Preferences rejoinOnKick] && c.errLastJoin == NO) {
                [self joinChannel:c];
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
    
    if ([ignoreChecks ignoreJPQE] == YES) {
        return;
    }
    
    if (hasIRCopAccess == NO) {
        if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
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
            if ([Preferences showJoinLeave]) {
                [self printChannel:c type:LINE_TYPE_QUIT text:text];
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
    
    BOOL myself = [nick isEqualNoCase:myNick];
    
    if (myself) {
        [myNick drain];
        myNick = [toNick retain];
    } else {
        ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw 
                                            withMatches:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
        
        if (hasIRCopAccess == NO) {
            if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
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
                
                [self printChannel:c type:LINE_TYPE_NICK text:text];
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
            
            for (IRCModeInfo *h in info) {
                [c changeMember:h.param mode:h.mode value:h.plus];
            }
            
            [self printBoth:c type:LINE_TYPE_MODE text:TXTFLS(@"IRC_MDOE_SET", nick, modeStr)];
        }
    } else {
        [self printBoth:nil type:LINE_TYPE_MODE text:TXTFLS(@"IRC_MDOE_SET", nick, modeStr)];
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
        
        [self printBoth:c type:LINE_TYPE_TOPIC text:TXTFLS(@"IRC_CHANNEL_TOPIC_CHANGED", nick, topic)];
    }
}

- (void)receiveInvite:(IRCMessage *)m
{
    NSString *nick = m.sender.nick;
    NSString *chname = [m paramAt:1];
    
    NSString *text = TXTFLS(@"IRC_USER_INVITED_YOU_TO", nick, m.sender.user, m.sender.address, chname);
    
    [self printBoth:self type:LINE_TYPE_INVITE text:text];
    [self notifyEvent:GROWL_INVITED lineType:LINE_TYPE_INVITE target:nil nick:nick text:chname];
    
    if ([Preferences autoJoinOnInvite]) {
        [self joinUnlistedChannel:chname];
    }
}

- (void)receiveError:(IRCMessage *)m
{
    [self printError:m.sequence];
}

- (void)receivePing:(IRCMessage *)m
{
    [self send:IRCCI_PONG, [m sequence:0], nil];
    
    [self stopPongTimer];
    [self startPongTimer];
}

- (void)receiveInit:(IRCMessage *)m
{
    [self startPongTimer];
    [self stopRetryTimer];
    [self stopAutoJoinTimer];
    
    [world expandClient:self];
    
    sendLagcheckToChannel = serverHasNickServ = NO;
    isLoggedIn = conn.loggedIn = inFirstISONRun = YES;
    isAway = isConnecting = hasIRCopAccess = inList = NO;
    
    tryingNickNumber = -1;
    
    [serverHostname drain];
    serverHostname = [m.sender.raw retain];
    
    [myNick drain];
    myNick = [[m paramAt:0] retain];
    
    [self notifyEvent:GROWL_LOGIN lineType:LINE_TYPE_SYSTEM];
    
    for (NSString *s in config.loginCommands) {
        if ([s hasPrefix:@"/"]) {
            s = [s safeSubstringFromIndex:1];
        }
        
        [self sendCommand:s completeTarget:NO target:nil];
    }
    
    for (IRCChannel *c in channels) {
        if (c.isTalk) {
            [c activate];
            
            IRCUser *m;
            
            m = [IRCUser newad];
            m.supportInfo = isupport;
            m.nick = myNick;
            [c addMember:m];
            
            m = [IRCUser newad];
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
    
    if (400 <= n && n < 600 && n != 403 && n != 422) {
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
        case 5:		// RPL_ISUPPORT
        {
            [isupport update:[m sequence:1]];
            
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
        case 221:	// RPL_UMODEIS
        {
            NSString *modeStr = [m paramAt:1];
            
            if ([modeStr isEqualToString:@"+"]) return;
            
            [self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_YOU_HAVE_UMODES", modeStr)];
            
            break;
        }
        case 290:	// RPL_CAPAB on freenode
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
        case 301:	// RPL_AWAY
        {
            NSString *nick = [m paramAt:1];
            NSString *comment = [m paramAt:2];
            
            IRCChannel *c = [self findChannel:nick];
            IRCChannel *sc = [world selectedChannelOn:self];
            
            NSString *text = TXTFLS(@"IRC_USER_IS_AWAY", nick, comment);
            
            if (c) {
                [self printBoth:(id)nick type:LINE_TYPE_REPLY text:text];
            }
            
            if (whoisChannel && [whoisChannel isEqualTo:c] == NO) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                if ([sc isEqualTo:c] == NO) {
                    [self printBoth:sc type:LINE_TYPE_REPLY text:text];
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
        case 307: // RPL_WHOISGENERAL
        case 310: // RPL_WHOISGENERAL
        case 313: // RPL_WHOISGENERAL
        case 335: // RPL_WHOISGENERAL
        case 378: // RPL_WHOISGENERAL
        case 379: // RPL_WHOISGENERAL
        case 671: // RPL_WHOISGENERAL
        {
            NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 338:	// RPL_WHOISCONNECTFROM
        {
            NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 311:	// RPL_WHOISUSER
        case 314:   // RPL_WHOWASUSER
        {
            NSString *nick = [m paramAt:1];
            NSString *username = [m paramAt:2];
            NSString *address = [m paramAt:3];
            NSString *realname = [m paramAt:5];
            
            NSString *text = nil;
            
            inWhoWasRequest = ((m.numericReply == 314) ? YES : NO);
            
            if ([realname hasPrefix:@":"]) {
                realname = [realname safeSubstringFromIndex:1];
            }
            
            if (inWhoWasRequest) {
                text = TXTFLS(@"IRC_USER_WHOWAS_HOSTMASK", nick, username, address, realname);
            } else {
                text = TXTFLS(@"IRC_USER_WHOIS_HOSTMASK", nick, username, address, realname);
            }	
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 312:	// RPL_WHOISSERVER
        {
            NSString *nick = [m paramAt:1];
            NSString *server = [m paramAt:2];
            NSString *serverInfo = [m paramAt:3];
            
            NSString *text = nil;
            
            if (inWhoWasRequest) {
                text = TXTFLS(@"IRC_USER_WHOWAS_CONNECTED_FROM", nick, server, [dateTimeFormatter stringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]]);
            } else {
                text = TXTFLS(@"IRC_USER_WHOIS_CONNECTED_FROM", nick, server, serverInfo);
            }
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 317:	// RPL_WHOISIDLE
        {
            NSString *nick = [m paramAt:1];
            
            NSInteger idleStr = [[m paramAt:2] doubleValue];
            NSInteger signOnStr = [[m paramAt:3] doubleValue];
            
            NSString *idleTime = TXReadableTime(idleStr);
            NSString *dateFromString = [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:signOnStr]];
            
            NSString *text = TXTFLS(@"IRC_USER_WHOIS_UPTIME", nick, dateFromString, idleTime);
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 319:	// RPL_WHOISCHANNELS
        {
            NSString *nick = [m paramAt:1];
            NSString *trail = [[m paramAt:2] trim];
            
            NSString *text = TXTFLS(@"IRC_USER_WHOIS_CHANNELS", nick, trail);
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 318:	// RPL_ENDOFWHOIS
        {
            whoisChannel = nil;
            
            break;
        }
        case 324:	// RPL_CHANNELMODEIS
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
                
                [self printBoth:c type:LINE_TYPE_MODE text:TXTFLS(@"IRC_CHANNEL_HAS_MODES", modeStr)];
            }
            
            break;
        }
        case 332:	// RPL_TOPIC
        {
            NSString *chname = [m paramAt:1];
            NSString *topic = [m paramAt:2];
            
            IRCChannel *c = [self findChannel:chname];
            
            [self decryptIncomingMessage:&topic channel:c];
            
            if (c && c.isActive) {
                [c setTopic:topic];
                [c.log setTopic:topic];
                
                [self printBoth:c type:LINE_TYPE_TOPIC text:TXTFLS(@"IRC_CHANNEL_HAS_TOPIC", topic)];
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
            
            if (r.location != NSNotFound) {
                setter = [setter safeSubstringToIndex:r.location];
            }
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c) {
                NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_TOPIC_AUTHOR"), setter, 
                                  [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
                
                [self printBoth:c type:LINE_TYPE_TOPIC text:text];
            }
            
            break;
        }
        case 341:	// RPL_INVITING
        {
            NSString *nick = [m paramAt:1];
            NSString *chname = [m paramAt:2];
            
            [self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_USER_INVITED_OTHER_USER", nick, chname)];
            
            break;
        }
        case 303:
        {
            if (hasIRCopAccess) {
                [self printUnknownReply:m];
            } else {
                NSArray *users = [[m sequence] componentsSeparatedByString:@" "];
                
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
        case 315:	// RPL_WHOEND
        {
            NSString *chname = [m paramAt:1];
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c && (c.isModeInit || c.isWhoInit)) {
                [c setIsWhoInit:NO];
                [c setIsModeInit:NO];
                
                if (c.forceOutput) {
                    [self printUnknownReply:m];
                    
                    [c setForceOutput:NO];
                }
            } 
            
            break;
        }
        case 352:	// RPL_WHOENTRY
        {
            NSString *chname = [m paramAt:1];
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c) {
                if (c.isWhoInit) {
                    NSString *nick = [m paramAt:5];
                    NSString *hostmask = [m paramAt:3];
                    NSString *username = [m paramAt:2];
                    
                    IRCUser *u = [c findMember:nick];
                    
                    if (u) {
                        if (NSObjectIsEmpty(u.address)) {
                            [u setAddress:hostmask];
                            [u setUsername:username];
                        }
                    } else {
                        IRCUser *u = [IRCUser newad];
                        
                        u.nick = nick;
                        u.username = username;
                        u.address = hostmask;
                        u.supportInfo = isupport;
                        
                        [c addMember:u];
                    }
                    
                    if (c.forceOutput) {
                        [self printUnknownReply:m];	
                    }
                } else {
                    if (c.isActive == NO) {
                        [self printUnknownReply:m];	
                    }
                }
            }
            
            break;
        }
        case 353:	// RPL_NAMREPLY
        {
            NSString *chname = [m paramAt:2];
            NSString *trail  = [m paramAt:3];
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c && c.isNamesInit == NO) {
                NSArray *ary = [trail componentsSeparatedByString:@" "];
                
                for (NSString *nick in ary) {
                    nick = [nick trim];
                    
                    if (NSObjectIsEmpty(nick)) continue;
                    
                    NSString *u  = [nick safeSubstringWithRange:NSMakeRange(0, 1)];
                    NSString *op = @" ";
                    
                    if ([u isEqualTo:isupport.userModeQPrefix] || [u isEqualTo:isupport.userModeHPrefix] || 
                        [u isEqualTo:isupport.userModeAPrefix] || [u isEqualTo:isupport.userModeVPrefix] || 
                        [u isEqualTo:isupport.userModeOPrefix]) {
                        
                        nick = [nick safeSubstringFromIndex:1];
                        op   = u;
                    }
                    
                    IRCUser *m = [IRCUser newad];
                    
                    m.nick        = nick;
                    
                    m.q = ([op isEqualTo:isupport.userModeQPrefix]);
                    m.a = ([op isEqualTo:isupport.userModeAPrefix]);
                    m.o = ([op isEqualTo:isupport.userModeOPrefix] || m.q);
                    m.h = ([op isEqualTo:isupport.userModeHPrefix]);
                    m.v = ([op isEqualTo:isupport.userModeVPrefix]);
                    
                    m.supportInfo = isupport;
                    m.isMyself    = [nick isEqualNoCase:myNick];
                    
                    [c addMember:m reload:NO];
                    
                    if (m.isMyself) {
                        c.isOp     = (m.q || m.a | m.o);
                        c.isHalfOp = (m.h || c.isOp);
                    }
                }
                
                [c reloadMemberList];
            } else {
                [self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_CHANNEL_NAMES_LIST", chname, trail)];
            }
            
            break;
        }
        case 366:	// RPL_ENDOFNAMES
        {
            NSString *chname = [m paramAt:1];
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c && c.isActive && c.isNamesInit == NO) {
                c.isNamesInit = YES;
                
                if ([c numberOfMembers] <= 1 && c.isOp) {
                    NSString *m = c.config.mode;
                    
                    if (NSObjectIsNotEmpty(m)) {
                        NSString *line = [NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, chname, m];
                        
                        [self sendLine:line];
                    }
                    
                    c.isModeInit = YES;
                }
                
                if ([c numberOfMembers] <= 1 && [chname isModeChannelName]) {
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
                
                if ([c numberOfMembers] < 1) {
                    c.isWhoInit = YES;
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
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 322:	// RPL_LIST
        {
            NSString *chname = [m paramAt:1];
            NSString *countStr = [m paramAt:2];
            NSString *topic = [m sequence:3];
            
            if (inList == NO) {
                inList = YES;
                
                if (channelListDialog) {
                    [channelListDialog clear];
                } else {
                    [self createChannelListDialog];
                }
            }
            
            if (channelListDialog) {
                [channelListDialog addChannel:chname count:[countStr integerValue] topic:topic];
            }
            
            break;
        }
        case 323:	// RPL_LISTEND
        {
            inList = NO;
            
            break;
        }
        case 321:
        case 329:
        {
            return;
            break;
        }
        case 330:
        {
            NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
            
            if (whoisChannel) {
                [self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
            } else {		
                [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            }
            
            break;
        }
        case 367:
        {
            NSString *mask = [m paramAt:2];
            NSString *owner = [m paramAt:3];
            
            long long seton = [[m paramAt:4] longLongValue];
            
            if (inChanBanList && chanBanListSheet) {
                [chanBanListSheet addBan:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
            }
            
            break;
        }
        case 368:
        case 347:
        case 349:
        {
            inChanBanList = NO;
            
            break;
        }
        case 346:
        {
            NSString *mask = [m paramAt:2];
            NSString *owner = [m paramAt:3];
            
            long long seton = [[m paramAt:4] longLongValue];
            
            if (inChanBanList && inviteExceptionSheet) {
                [inviteExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
            }
            
            break;
        }
        case 348:
        {
            NSString *mask = [m paramAt:2];
            NSString *owner = [m paramAt:3];
            
            long long seton = [[m paramAt:4] longLongValue];
            
            if (inChanBanList && banExceptionSheet) {
                [banExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
            }
            
            break;
        }
        case 381:
        {
            hasIRCopAccess = YES;
            
            [self printBoth:nil type:LINE_TYPE_REPLY text:TXTFLS(@"IRC_USER_HAS_GOOD_LIFE", m.sender.nick)];
            
            break;
        }
        case 328:
        {
            NSString *chname = [m paramAt:1];
            NSString *website = [m paramAt:2];
            
            IRCChannel *c = [self findChannel:chname];
            
            if (c && website) {
                [self printBoth:c type:LINE_TYPE_WEBSITE text:TXTFLS(@"IRC_CHANNEL_HAS_WEBSITE", website)];
            }
            
            break;
        }
        case 369:
        {
            inWhoWasRequest = NO;
            
            [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:[m sequence]];
            
            break;
        }
        default:
        {
            if ([world.bundlesForServerInput containsKey:[NSString stringWithInteger:m.numericReply]]) break;
            
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
            if (isLoggedIn) break;
            
            [self receiveNickCollisionError:m];
            break;
        case 402:   // ERR_NOSUCHSERVER
        {
            NSString *text = TXTFLS(@"IRC_HAD_RAW_ERROR", m.numericReply, [m sequence:1]);
            
            [self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
            
            return;
            break;
        }
        case 404:	// ERR_CANNOTSENDMESSAGE
        {
            NSString *chname = [m paramAt:1];
            NSString *text = TXTFLS(@"IRC_HAD_RAW_ERROR", m.numericReply, [m sequence:2]);
            
            [self printBoth:[self findChannel:chname] type:LINE_TYPE_REPLY text:text];
            
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
            
            if (c != '_') {
                found = YES;
                
                NSString *head = [nick safeSubstringToIndex:i];
                NSMutableString *s = [[head mutableCopy] autodrain];
                
                for (NSInteger i = (isupport.nickLen - s.length); i > 0; --i) {
                    [s appendString:@"_"];
                }
                
                [sentNick drain];
                sentNick = [s retain];
                
                break;
            }
        }
        
        if (found == NO) {
            [sentNick drain];
            sentNick = @"0";
        }
    } else {
        [sentNick autodrain];
        sentNick = [[sentNick stringByAppendingString:@"_"] retain];
    }
    
    [self send:IRCCI_NICK, sentNick, nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)changeStateOff
{
    if (isLoggedIn == NO && isConnecting == NO) return;
    
    BOOL prevConnected = isConnected;
    
    [conn autodrain];
    conn = nil;
    
    [self clearCommandQueue];
    [self stopRetryTimer];
    [self stopISONTimer];
    
    if (reconnectEnabled) {
        [self startReconnectTimer];
    }
    
    sendLagcheckToChannel = NO;
    isConnecting = isConnected = isLoggedIn = isQuitting = NO;
    hasIRCopAccess = serverHasNickServ = autojoinInitialized = NO;
    
    [myNick drain];
    [sentNick drain];
    myNick = @"";
    sentNick = @"";
    
    tryingNickNumber = -1;
    
    NSString *disconnectTXTLString = nil;
    
    switch (disconnectType) {
        case DISCONNECT_NORMAL:
            disconnectTXTLString = @"IRC_DISCONNECTED_FROM_SERVER";
            break;
        case DISCONNECT_TRIAL_PERIOD:
            disconnectTXTLString = @"TRIAL_BUILD_NETWORK_DISCONNECTED";
            break;
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
            [self notifyEvent:GROWL_DISCONNECT lineType:LINE_TYPE_SYSTEM];
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
    
    if (connectType != CONNECT_BADSSL_CRT_RECONNECT) {
        [self printSystemBoth:nil text:TXTLS(@"IRC_CONNECTED_TO_SERVER")];
    }
    
    isLoggedIn = NO;
    isConnected = reconnectEnabled = YES;
    
    encoding = config.encoding;
    
    if (NSObjectIsEmpty(inputNick)) {
        [inputNick autodrain];
        inputNick = [config.nick retain];
    }
    
    [sentNick autodrain];
    [myNick autodrain];
    
    sentNick = [inputNick retain];
    myNick = [inputNick retain];
    
    [isupport reset];
    
    NSInteger modeParam = ((config.invisibleMode) ? 8 : 0);
    
    NSString *user = config.username;
    NSString *realName = config.realName;
    
    if (NSObjectIsEmpty(user)) user = config.nick;
    if (NSObjectIsEmpty(realName)) realName = config.nick;
    
    if (NSObjectIsNotEmpty(config.password)) [self send:IRCCI_PASS, config.password, nil];
    
    [self send:IRCCI_NICK, sentNick, nil];
    
    if (config.bouncerMode) { // Fuck psybnc — use ZNC
        [self send:IRCCI_USER, user, [NSString stringWithDouble:modeParam], @"*", [@":" stringByAppendingString:realName], nil];
    } else {
        [self send:IRCCI_USER, user, [NSString stringWithDouble:modeParam], @"*", realName, nil];
    }
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
    
    IRCMessage *m = [[[IRCMessage alloc] initWithLine:s] autodrain];
    
    NSString *cmd = m.command;
    
    if (m.numericReply > 0) { 
        [self receiveNumericReply:m];
    } else {
        switch ([Preferences commandUIndex:cmd]) {	
            case 4: // Command: ERROR
                [self receiveError:m];
                break;
            case 5: // Command: INVITE
                [self receiveInvite:m];
                break;
            case 7: // Command: JOIN
                [self receiveJoin:m];
                break;
            case 8: // Command: KICK
                [self receiveKick:m];
                break;
            case 9: // Command: KILL
                [self receiveKill:m];
                break;
            case 11: // Command: MODE
                [self receiveMode:m];
                break;
            case 13: // Command: NICK
                [self receiveNick:m];
                break;
            case 14: // Command: NOTICE
            case 19: // Command: PRIVMSG
                [self receivePrivmsgAndNotice:m];
                break;
            case 15: // Command: PART
                [self receivePart:m];
                break;
            case 17: // Command: PING
                [self receivePing:m];
                break;
            case 20: // Command: QUIT
                [self receiveQuit:m];
                break;
            case 21: // Command: TOPIC
                [self receiveTopic:m];
                break;
            case 80: // Command: WALLOPS
            case 85: // Command: CHATOPS
            case 86: // Command: GLOBOPS
            case 87: // Command: LOCOPS
            case 88: // Command: NACHAT
            case 89: // Command: ADCHAT
                [m.params safeInsertObject:m.sender.nick atIndex:0];
                
                NSString *text = [m.params safeObjectAtIndex:1];
                
                [m.params safeRemoveObjectAtIndex:1];
                [m.params safeInsertObject:[NSString stringWithFormat:@"[%@]: %@", m.command, text] atIndex:1];
                
                m.command = IRCCI_NOTICE;
                
                [self receivePrivmsgAndNotice:m];
                
                break;
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
    if (self != [IRCClient class]) return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    dateTimeFormatter = [NSDateFormatter new];
    [dateTimeFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateTimeFormatter setTimeStyle:NSDateFormatterLongStyle];
    
    [pool drain];
}

@end