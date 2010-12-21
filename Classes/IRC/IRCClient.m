// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCClient.h"

#include <arpa/inet.h>

#define PONG_INTERVAL			150
#define MAX_BODY_LEN			480
#define RECONNECT_INTERVAL		20
#define RETRY_INTERVAL			240
#define ISON_CHECK_INTERVAL		30
#define TRIAL_PERIOD_INTERVAL	1800

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

- (void)startISONTimer;
- (void)stopISONTimer;
- (void)onISONTimer:(id)sender;

- (void)addCommandToCommandQueue:(TimerCommand *)m;
- (void)clearCommandQueue;

- (void)processBundlesUserMessage:(NSArray *)info;

- (void)handleUserTrackingNotification:(AddressBook *)ignoreItem 
							  hostmask:(NSString *)host
							  nickname:(NSString *)nick
							  langitem:(NSString *)localKey;

- (void)startReconnectTimer;

- (void)requestIPAddressFromInternet;
- (void)setDCCIPAddress:(NSString *)host;

@end

@implementation IRCClient

@synthesize world;
@synthesize config;
@synthesize channels;
@synthesize isupport;
@synthesize isConnecting;
@synthesize isConnected;
@synthesize isLoggedIn;
@synthesize myNick;
@synthesize myAddress;
@synthesize lastSelectedChannel;
@synthesize conn;
@synthesize reconnectEnabled;
@synthesize retryEnabled;
@synthesize rawModeEnabled;
@synthesize isQuitting;
@synthesize encoding;
@synthesize inputNick;
@synthesize sentNick;
@synthesize tryingNickNumber;
@synthesize serverHostname;
@synthesize inList;
@synthesize identifyMsg;
@synthesize identifyCTCP;
@synthesize pongTimer;
@synthesize reconnectTimer;
@synthesize retryTimer;
@synthesize autoJoinTimer;
@synthesize commandQueueTimer;
@synthesize commandQueue;
@synthesize channelListDialog;
@synthesize logFile;
@synthesize logDate;
@synthesize isAway;
@synthesize isonTimer;
@synthesize whoisChannel;
@synthesize chanBanListSheet;
@synthesize banExceptionSheet;
@synthesize inChanBanList;
@synthesize trackedUsers;
@synthesize inFirstISONRun;
@synthesize hasIRCopAccess;
@synthesize inWhoWasRequest;
@synthesize disconnectType;
@synthesize connectType;

- (id)init
{
	if ((self = [super init])) {
		tryingNickNumber = -1;
		channels = [NSMutableArray new];
		isupport = [IRCISupportInfo new];
		
		isAway = NO;
		hasIRCopAccess = NO;
		
		reconnectTimer = [Timer new];
		reconnectTimer.delegate = self;
		reconnectTimer.reqeat = NO;
		reconnectTimer.selector = @selector(onReconnectTimer:);
		
		retryTimer = [Timer new];
		retryTimer.delegate = self;
		retryTimer.reqeat = NO;
		retryTimer.selector = @selector(onRetryTimer:);
		
		autoJoinTimer = [Timer new];
		autoJoinTimer.delegate = self;
		autoJoinTimer.reqeat = NO;
		autoJoinTimer.selector = @selector(onAutoJoinTimer:);
		
		commandQueueTimer = [Timer new];
		commandQueueTimer.delegate = self;
		commandQueueTimer.reqeat = NO;
		commandQueueTimer.selector = @selector(onCommandQueueTimer:);
		
		pongTimer = [Timer new];
		pongTimer.delegate = self;
		pongTimer.reqeat = YES;
		pongTimer.selector = @selector(onPongTimer:);
		
		isonTimer = [Timer new];
		isonTimer.delegate = self;
		isonTimer.reqeat = YES;
		isonTimer.selector = @selector(onISONTimer:);
		
#ifdef IS_TRIAL_BINARY
		trialPeriodTimer = [Timer new];
		trialPeriodTimer.delegate = self;
		trialPeriodTimer.reqeat = NO;
		trialPeriodTimer.selector = @selector(onTrialPeriodTimer:);	
#endif
		
		trackedUsers = [NSMutableDictionary new];
		commandQueue = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[config release];
	[channels release];
	[isupport release];
	[conn close];
	[conn autorelease];
	
	[inputNick release];
	[sentNick release];
	[myNick release];
	
	[serverHostname release];
	[trackedUsers release];
	
	[myAddress release];
	
	[pongTimer stop];
	[pongTimer release];
	[reconnectTimer stop];
	[reconnectTimer release];
	[retryTimer stop];
	[retryTimer release];
	[autoJoinTimer stop];
	[autoJoinTimer release];
	[isonTimer stop];
	[isonTimer release];
	[commandQueueTimer stop];
	[commandQueueTimer release];
	[commandQueue release];
	
#ifdef IS_TRIAL_BINARY
	[trialPeriodTimer stop];
	[trialPeriodTimer release];
#endif
	
	[lastSelectedChannel release];
	[channelListDialog release];
	[chanBanListSheet release];
	
	[logFile release];
	[logDate release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCClientConfig *)seed
{
	[config autorelease];
	config = [seed mutableCopy];
	
	addressDetectionMethod = [Preferences dccAddressDetectionMethod];
	
	if (addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
		[self setDCCIPAddress:[Preferences dccMyaddress]];
	}
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	[config release];
	config = nil;
	config = [seed mutableCopy];
	
	NSArray *chans = config.channels;
	
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCChannelConfig *i in chans) {
		IRCChannel *c = [self findChannel:i.name];
		
		if (c) {
			[c updateConfig:i];
			[ary addObject:c];
			[channels removeObjectIdenticalTo:c];
		} else {
			c = [world createChannel:i client:self reload:NO adjust:NO];
			[ary addObject:c];
		}
	}
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[self partChannel:c];
		} else {
			[ary addObject:c];
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
	IRCClientConfig *u = [[config mutableCopy] autorelease];
	[u.channels removeAllObjects];
	
	for (IRCChannel *c in channels) {
		if (c.isChannel) {
			[u.channels addObject:[[c.config mutableCopy] autorelease]];
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
			[ary addObject:[c dictionaryValue]];
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
	return reconnectTimer && reconnectTimer.isActive;
}

#pragma mark -
#pragma mark User Tracking

- (void)handleUserTrackingNotification:(AddressBook *)ignoreItem 
							  hostmask:(NSString *)host
							  nickname:(NSString *)nick
							  langitem:(NSString *)localKey
{
	BOOL sendEvent = ([ignoreItem notifyJoins] == YES || [ignoreItem notifyWhoisJoins] == YES);
	
	if (sendEvent) {
		IRCChannel *nsc = [self findChannelOrCreate:TXTLS(@"IRCOP_SERVICES_NOTIFICATION_WINDOW_TITLE") useTalk:YES];
		NSString *text = [NSString stringWithFormat:TXTLS(localKey), host, ignoreItem.hostmask];
		
		if ([ignoreItem notifyJoins] == YES) {
			nsc.isUnread = YES;
			
			[self printBoth:nsc type:LINE_TYPE_NOTICE text:text];
		}
		
		if ([ignoreItem notifyWhoisJoins] == YES) {
			nsc.isUnread = YES;
			whoisChannel = nsc;
			
			[self sendWhois:nick];
		}
		
		[self notifyEvent:GROWL_ADDRESS_BOOK_MATCH target:nsc nick:nick text:text];
	}	
}

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores
{
	if (!isLoggedIn) return;
	if (hasIRCopAccess) return;
	if (!trackedUsers) trackedUsers = [NSMutableDictionary new];
	
	if ([trackedUsers count] > 0) {
		NSMutableDictionary *oldEntries = [NSMutableDictionary dictionary];
		NSMutableDictionary *newEntries = [NSMutableDictionary dictionary];
		
		for (NSString *name in trackedUsers) {
			[oldEntries setObject:name forKey:[name lowercaseString]];
		}
		
		for (AddressBook *g in ignores) {
			if (g.notifyJoins || g.notifyWhoisJoins) {
				NSString *name = [g trackingNickname];
				NSString *lcname = [name lowercaseString];
				
				if ([oldEntries objectForKey:lcname]) {
					[newEntries setObject:[trackedUsers objectForKey:name] forKey:name];
				} else {
					[newEntries setObject:@"0" forKey:name];
				}
			}
		}
		
		[trackedUsers release];
		trackedUsers = [newEntries retain];
	} else {
		for (AddressBook *g in ignores) {
			if (g.notifyJoins || g.notifyWhoisJoins) {
				[trackedUsers setObject:@"0" forKey:[g trackingNickname]];
			}
		}
	}
	
	if (isonTimer.isActive) [self stopISONTimer];
	if (isonTimer.isActive == NO && [trackedUsers count] > 0) [self startISONTimer];
}

#pragma mark -
#pragma mark Utilities

- (void)setDCCIPAddress:(NSString *)host
{
	if ([host isIPAddress]) {	
		if (myAddress != host) {
			[myAddress release];
			myAddress = [host retain];
		}
	}
}

- (NSInteger)connectDelay
{
	return connectDelay;
}

- (void)autoConnect:(NSInteger)delay
{
	connectDelay = delay;
	[self connect];
}

- (void)onTimer
{
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
	[channelListDialog release];
}

- (void)preferencesChanged
{
	log.maxLines = [Preferences maxLogLines];
	
	if (addressDetectionMethod != [Preferences dccAddressDetectionMethod]) {
		addressDetectionMethod = [Preferences dccAddressDetectionMethod];
		
		[myAddress release];
		myAddress = nil;
		
		if (addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
			[self setDCCIPAddress:[Preferences dccMyaddress]];
		} else {
			[self requestIPAddressFromInternet];
		}
	}
	
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
				if ([[ignoreDict objectForKey:matchkey] boolValue] == YES) {
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

- (AddressBook *)checkIgnore:(NSString *)hostmask 
					  uname:(NSString *)username 
					   name:(NSString *)nickname
			   matchAgainst:(NSArray *)matches
{
	if ([nickname contains:@"."]) return nil;
	
	NSString *real_host = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];
	
	return [self checkIgnoreAgainstHostmask:real_host withMatches:matches];
}

#pragma mark -
#pragma mark ChanBanDialog

- (void)createChanBanListDialog
{
	if (!chanBanListSheet) {
		IRCClient *u = world.selectedClient;
		IRCChannel *c = world.selectedChannel;
		if (!u || !c) return;
		
		chanBanListSheet = [ChanBanSheet new];
		chanBanListSheet.delegate = self;
		chanBanListSheet.window = world.window;
	} else {
		[chanBanListSheet ok:nil];
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
	if ([sender.modeString length] > 1) {
		[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [[world selectedChannel] name], sender.modeString]];
	}
	
	inChanBanList = NO;
	chanBanListSheet = nil;
}

- (void)createChanBanExceptionListDialog
{
	if (!banExceptionSheet) {
		IRCClient *u = world.selectedClient;
		IRCChannel *c = world.selectedChannel;
		if (!u || !c) return;
		
		banExceptionSheet = [ChanBanExceptionSheet new];
		banExceptionSheet.delegate = self;
		banExceptionSheet.window = world.window;
	} else {
		[banExceptionSheet ok:nil];
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
	if ([sender.modeString length] > 1) {
		[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, [[world selectedChannel] name], sender.modeString]];
	}
	
	inChanBanList = NO;
	banExceptionSheet = nil;
}

#pragma mark -
#pragma mark ListDialog

- (void)createChannelListDialog
{
	if (!channelListDialog) {
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
	[self send:IRCCI_JOIN, channel, nil];
}

- (void)listDialogWillClose:(ListDialog *)sender
{
	[channelListDialog autorelease];
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
		if ([trackedUsers count] < 1) return [self stopISONTimer];
		
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
		if (serverHostname.length) {
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
	[autoJoinTimer start:[Preferences connectAutoJoinDelay]];
}

- (void)stopAutoJoinTimer
{
	[autoJoinTimer stop];
}

- (void)onAutoJoinTimer:(id)sender
{
	[self performAutoJoin];
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
	
	connectType = mode;
	disconnectType = DISCONNECT_NORMAL;
	
	if (conn) {
		[conn close];
		[conn autorelease];
		conn = nil;
	}
	
	isConnecting = YES;
	reconnectEnabled = YES;
	retryEnabled = YES;
	
	NSString *host = config.host;
	
	switch (mode) {
		case CONNECT_NORMAL:
			[self printSystemBoth:nil text:[NSString stringWithFormat:TXTLS(@"IRC_IS_CONNECTING"), host, config.port]];
			break;
		case CONNECT_RECONNECT:
			[self printSystemBoth:nil text:TXTLS(@"IRC_IS_RECONNECTING")];
			[self printSystemBoth:nil text:[NSString stringWithFormat:TXTLS(@"IRC_IS_CONNECTING"), host, config.port]];
			break;
		case CONNECT_RETRY:
			[self printSystemBoth:nil text:TXTLS(@"IRC_IS_RETRYING_CONNECTION")];
			[self printSystemBoth:nil text:[NSString stringWithFormat:TXTLS(@"IRC_IS_CONNECTING"), host, config.port]];
			break;
		default:
			break;
	}
	
	conn = [IRCConnection new];
	conn.delegate = self;
	conn.host = host;
	conn.port = config.port;
	conn.useSSL = config.useSSL;
	conn.encoding = config.encoding;
	
	switch (config.proxyType) {
		case PROXY_SOCKS_SYSTEM:
			conn.useSystemSocks = YES;
		case PROXY_SOCKS4:
		case PROXY_SOCKS5:
			conn.useSocks = YES;
			conn.socksVersion = config.proxyType;
			conn.proxyHost = config.proxyHost;
			conn.proxyPort = config.proxyPort;
			conn.proxyUser = config.proxyUser;
			conn.proxyPassword = config.proxyPassword;
			break;
		default:
			break;
	}
	
	[conn open];
}

- (void)disconnect
{
	if (conn) {
		[conn close];
		[conn autorelease];
		conn = nil;
	}
	
	[self stopPongTimer];
	[self changeStateOff];
}

- (void)disconnectWithTimer
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread sleepForTimeInterval:1.5];
	[[self invokeOnMainThread] disconnect];
	
	[pool release];
}

- (void)quit
{
	[self quit:nil];
}

- (void)quit:(NSString *)comment
{
	if (!isLoggedIn) {
		[self disconnect];
		return;
	}
	
	[self stopPongTimer];
	
	isQuitting = YES;
	reconnectEnabled = NO;
	[conn clearSendQueue];
	[self send:IRCCI_QUIT, comment ?: config.leavingComment, nil];
	[[self invokeInBackgroundThread] disconnectWithTimer];
}

- (void)cancelReconnect
{
	[self stopReconnectTimer];
}

- (void)changeNick:(NSString *)newNick
{
	if (!isConnected) return;
	
	[inputNick autorelease];
	[sentNick autorelease];
	inputNick = [newNick retain];
	sentNick = [newNick retain];
	
	[self send:IRCCI_NICK, newNick, nil];
}

- (void)joinChannel:(IRCChannel *)channel
{
	if (!isLoggedIn) return;
	if (channel.isActive) return;
	
	NSString *password = channel.config.password;
	if (!password.length) password = nil;
	
	[self send:IRCCI_JOIN, channel.name, password, nil];
}

- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password
{
	if (!isLoggedIn) return;
	
	if (!password.length) password = channel.config.password;
	if (!password.length) password = nil;
	
	[self send:IRCCI_JOIN, channel.name, password, nil];
}

- (void)partChannel:(IRCChannel *)channel
{
	if (!isLoggedIn) return;
	if (!channel.isActive) return;
	
	NSString *comment = config.leavingComment;
	if (!comment.length) comment = nil;
	
	[self send:IRCCI_PART, channel.name, comment, nil];
}

- (void)sendWhois:(NSString *)nick
{
	if (!isLoggedIn) return;
	
	[self send:IRCCI_WHOIS, nick, nick, nil];
}

- (void)changeOp:(IRCChannel *)channel users:(NSArray *)inputUsers mode:(char)mode value:(BOOL)value
{
	if (!isLoggedIn || !channel || !channel.isActive || !channel.isChannel || !channel.isOp) return;
	
	NSMutableArray *users = [NSMutableArray array];
	
	for (IRCUser *user in inputUsers) {
		IRCUser *m = [channel findMember:user.nick];
		if (m) {
			if (value != [m hasMode:mode]) {
				[users addObject:m];
			}
		}
	}
	
	NSInteger max = isupport.modesCount;
	while (users.count) {
		NSArray *ary = [users subarrayWithRange:NSMakeRange(0, MIN(max, users.count))];
		
		NSMutableString *s = [NSMutableString string];
		[s appendFormat:@"%@ %@ %c", IRCCI_MODE, channel.name, value ? '+' : '-'];
		
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
	NSMutableString *pass = [NSMutableString string];
	
	for (IRCChannel *c in chans) {
		NSMutableString *prevTarget = [[target mutableCopy] autorelease];
		NSMutableString *prevPass = [[pass mutableCopy] autorelease];
		
		if (!target.isEmpty) [target appendString:@","];
		[target appendString:c.name];
		if (!c.password.isEmpty) {
			if (!pass.isEmpty) [pass appendString:@","];
			[pass appendString:c.password];
		}
		
		NSData *targetData = [target dataUsingEncoding:conn.encoding];
		NSData *passData = [pass dataUsingEncoding:conn.encoding];
		
		if (targetData.length + passData.length > MAX_BODY_LEN) {
			if (!prevTarget.isEmpty) {
				if (prevPass.isEmpty) {
					[self send:IRCCI_JOIN, prevTarget, nil];
				} else {
					[self send:IRCCI_JOIN, prevTarget, prevPass, nil];
				}
				[target setString:c.name];
				[pass setString:c.password];
			} else {
				if (c.password.isEmpty) {
					[self send:IRCCI_JOIN, c.name, nil];
				} else {
					[self send:IRCCI_JOIN, c.name, c.password, nil];
				}
				[target setString:@""];
				[pass setString:@""];
			}
		}
	}
	
	if (!target.isEmpty) {
		if (pass.isEmpty) {
			[self send:IRCCI_JOIN, target, nil];
		} else {
			[self send:IRCCI_JOIN, target, pass, nil];
		}
	}
}

- (void)performAutoJoin
{
	[self stopAutoJoinTimer];
	
	NSMutableArray *ary = [NSMutableArray array];
	for (IRCChannel *c in channels) {
		if (c.isChannel && c.config.autoJoin) {
			[ary addObject:c];
		}
	}
	
	[self joinChannels:ary];
}

- (void)joinChannels:(NSArray *)chans
{
	NSMutableArray *ary = [NSMutableArray array];
	BOOL pass = YES;
	
	for (IRCChannel *c in chans) {
		BOOL hasPass = !c.password.isEmpty;
		
		if (pass) {
			pass = hasPass;
			[ary addObject:c];
		} else {
			if (hasPass) {
				[self quickJoin:ary];
				[ary removeAllObjects];
				pass = hasPass;
			}
			[ary addObject:c];
		}
		
		if (ary.count >= [Preferences autojoinMaxChannelJoins]) {
			[self quickJoin:ary];
			[ary removeAllObjects];
			pass = YES;
		}
	}
	
	if (ary.count > 0) {
		[self quickJoin:ary];
	}
}

#pragma mark -
#pragma mark Trial Period Handlers

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
#pragma mark Sending Text

- (BOOL)inputText:(NSString *)str command:(NSString *)command
{
	if (!isConnected) {
		if ([str length] < 1) {
			return NO;
		}
	}
	
	id sel = world.selected;
	if (!sel) return NO;
	
	NSArray *lines = [str splitIntoLines];
	for (NSString *s in lines) {
		if (s.length == 0) continue;
		
		if ([sel isClient]) {
			// server
			if ([s hasPrefix:@"/"]) {
				s = [s safeSubstringFromIndex:1];
			}
			[self sendCommand:s];
		} else {
			// channel
			IRCChannel *channel = (IRCChannel *)sel;
			
			if ([s hasPrefix:@"/"] && ![s hasPrefix:@"//"]) {
				// command
				s = [s safeSubstringFromIndex:1];
				[self sendCommand:s];
			} else {
				// text
				if ([s hasPrefix:@"/"]) {
					s = [s safeSubstringFromIndex:1];
				}
				[self sendText:s command:command channel:channel];
			}
		}
	}
	
	return YES;
}

- (NSString *)truncateText:(NSMutableString *)str command:(NSString *)command channelName:(NSString *)chname
{
	NSInteger max = IRC_BODY_LEN;
	
	if (chname) {
		max -= [conn convertToCommonEncoding:chname].length;
	}
	
	if (myNick.length) {
		max -= myNick.length;
	} else {
		max -= isupport.nickLen;
	}
	
	max -= config.username.length;
	
	if ([command isEqualToString:IRCCI_NOTICE]) {
		max -= 18;
	} else if ([command isEqualToString:IRCCI_ACTION]) {
		max -= 28;
	} else {
		max -= 19;
	}
	
	if (max <= 0) {
		return nil;
	}
	
	NSString *s = str;
	if (s.length > max) {
		s = [s safeSubstringToIndex:max];
	} else {
		s = [[s copy] autorelease];
	}
	
	while (1) {
		NSInteger len = [conn convertToCommonEncoding:s].length;
		NSInteger delta = len - max;
		if (delta <= 0) break;
		
		if (delta < 5) {
			s = [s safeSubstringToIndex:s.length - 1];
		} else {
			s = [s safeSubstringToIndex:s.length - (delta / 3)];
		}
	}
	
	[str deleteCharactersInRange:NSMakeRange(0, s.length)];
	return s;
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	[self sendText:message command:IRCCI_PRIVMSG channel:[[self world] selectedChannelOn:self]];
}

- (void)sendText:(NSString *)str command:(NSString *)command channel:(IRCChannel *)channel
{
	if (!str.length) return;
	
	LogLineType type;
	
	if ([command isEqualToString:IRCCI_NOTICE]) {
		type = LINE_TYPE_NOTICE;
	} else if ([command isEqualToString:IRCCI_ACTION]) {
		type = LINE_TYPE_ACTION;
	} else {
		type = LINE_TYPE_PRIVMSG;
	}
	
	if ([[world bundlesForUserInput] objectForKey:command]) {
		[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:str, nil, nil]];
	}
	
	NSArray *lines = [str splitIntoLines];
	for (NSString *line in lines) {
		if (!line.length) continue;
		
		NSMutableString *s = [[line mutableCopy] autorelease];
		
		while (s.length > 0) {
			NSString *t = [self truncateText:s command:command channelName:channel.name];
			if (!t.length) break;
			
			[self printBoth:channel type:type nick:myNick text:t identified:YES];
			
			NSString *cmd = command;
			if (type == LINE_TYPE_ACTION) {
				cmd = IRCCI_PRIVMSG;
				t = [NSString stringWithFormat:@"%c%@ %@%c", (UniChar)0x01, IRCCI_ACTION, t, (UniChar)0x01];
			} else if (type == LINE_TYPE_PRIVMSG) {
				[channel detectOutgoingConversation:t];
			}
			[self send:cmd, channel.name, t, nil];
		}
	}
}

- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSString *trail;
	if (text.length) {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", (UniChar)0x01, command, text, (UniChar)0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@%c", (UniChar)0x01, command, (UniChar)0x01];
	}
	[self send:IRCCI_PRIVMSG, target, trail, nil];
}

- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSString *trail;
	if (text.length) {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", (UniChar)0x01, command, text, (UniChar)0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@%c", (UniChar)0x01, command, (UniChar)0x01];
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

- (void)executeTextualCmdScript:(NSMutableDictionary *)details 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	
	if ([details objectForKey:@"path"] == nil) {
		return;
	}
	
	NSDictionary *errors = [NSDictionary dictionary];
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:
								  [NSURL fileURLWithPath:[details objectForKey:@"path"]] error:&errors];
	
	if (appleScript) {
		NSAppleEventDescriptor *firstParameter = [NSAppleEventDescriptor descriptorWithString:[details objectForKey:@"input"]];
		
		NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
		[parameters insertDescriptor:firstParameter atIndex:1];
		
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
																						bytes:&psn
																					   length:sizeof(ProcessSerialNumber)];
		
		NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:[@"textualcmd" lowercaseString]];
		
		NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																				 eventID:kASSubroutineEvent
																		targetDescriptor:target
																				returnID:kAutoGenerateReturnID
																		   transactionID:kAnyTransactionID];
		
		[event setParamDescriptor:handler forKeyword:keyASSubroutineName];
		[event setParamDescriptor:parameters forKeyword:keyDirectObject];
		
		NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];
		
		if (errors && !result) {
			NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);
		} else {	
			NSString *finalResult = [result stringValue];
			finalResult = [finalResult stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			if ([finalResult length] >= 1) {
				[[world invokeOnMainThread] inputText:finalResult command:IRCCI_PRIVMSG];
			}
		}
	} else {
		NSLog(TXTLS(@"IRC_SCRIPT_EXECUTION_FAILURE"), errors);	
	}
	
	[appleScript release];
	[pool drain];
}

- (void)processBundlesUserMessage:(NSArray *)info
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	
	NSString *command = @"";
	NSString *message = [info safeObjectAtIndex:0];
	
	if ([info count] == 2) {
		command = [[info safeObjectAtIndex:1] uppercaseString];
	}
	
	[NSBundle sendUserInputDataToBundles:world message:message command:command client:self];
	
	[pool drain];
}

- (void)processBundlesServerMessage:(IRCMessage *)msg
{
	[NSBundle sendServerInputDataToBundles:world client:self message:msg];
}

- (BOOL)sendCommand:(NSString *)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName
{
	NSMutableString *s = [[str mutableCopy] autorelease];
	
	NSString *cmd = [[s getToken] uppercaseString];
	
	if (!cmd.length) return NO;
	if (!str.length) return NO;
	
	IRCClient *u = world.selectedClient;
	IRCChannel *c = world.selectedChannel;
	
	IRCChannel *selChannel = nil;
	if ([cmd isEqualToString:IRCCI_MODE] && !([s hasPrefix:@"+"] || [s hasPrefix:@"-"])) {
		// do not complete for /mode #chname ...
	} else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	BOOL cutColon = NO;
	if ([s hasPrefix:@"/"]) {
		cutColon = YES;
		[s deleteCharactersInRange:NSMakeRange(0, 1)];
	}
	
	switch ([Preferences commandUIndex:cmd]) {
		case 3: // Command: AWAY
			if (!s.length && !cutColon) {
				s = ((isAway == NO) ? (NSMutableString *)TXTLS(@"IRC_AWAY_COMMAND_DEFAULT_REASON") : nil);
			}
			
			if ([Preferences awayAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if (![u isConnected]) continue;
					
					[[u client] send:cmd, s, nil];
				}
			} else {
				if (![self isConnected]) return NO;
				
				[self send:cmd, s, nil];
			}
			
			return YES;
			break;
		case 5: // Command: INVITE
			targetChannelName = [s getToken];
			
			if (!s.length && !cutColon) {
				s = nil;
			}
			
			[self send:cmd, targetChannelName, s, nil];
			return YES;
			break;
		case 51: // Command: J
		case 7: // Command: JOIN
		{
			if (selChannel && selChannel.isChannel && !s.length) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
				if (![targetChannelName isChannelName]) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}
			
			if (!s.length && !cutColon) {
				s = nil;
			}
			
			[self send:IRCCI_JOIN, targetChannelName, s, nil];
			
			return YES;
			break;
		}
		case 8: // Command: KICK
			if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
			}
			
			NSString *peer = [s getToken];
			
			if (peer) {
				NSString *reason = [s trim];
				
				if ([reason length] < 1) {
					reason = [Preferences defaultKickMessage];
				}
				
				[self send:cmd, targetChannelName, peer, reason, nil];
			}
			return YES;
			break;
		case 9: // Command: KILL
		{
			NSString *peer = [s getToken];
			
			if (peer) {
				NSString *reason = [s trim];
				
				if ([reason length] < 1) {
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
					if (![u isConnected]) continue;
					
					[[u client] changeNick:newnick];
				}
			} else {
				if (![self isConnected]) return NO;
				
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
		case 53: // Command: M
		case 54: // Command: ME
		case 55: // Command: MSG
		{
			cmd = (([cmd isEqualToString:IRCCI_MSG]) ? IRCCI_PRIVMSG : cmd);
			BOOL opMsg = NO;
			
			if ([cmd isEqualToString:IRCCI_OMSG]) {
				opMsg = YES;
				cmd = IRCCI_MSG;
			} else if ([cmd isEqualToString:IRCCI_ONOTICE]) {
				opMsg = YES;
				cmd = IRCCI_NOTICE;
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || [cmd isEqualToString:IRCCI_NOTICE] || [cmd isEqualToString:IRCCI_ACTION]) {
				if (opMsg) {
					if (selChannel && selChannel.isChannel && ![s isChannelName]) {
						targetChannelName = selChannel.name;
					} else {
						targetChannelName = [s getToken];
					}
				} else {
					targetChannelName = [s getToken];
				}
			} else if ([cmd isEqualToString:IRCCI_ME] || [cmd isEqualToString:IRCCI_M]) {
				cmd = IRCCI_ACTION;
				if (selChannel) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = [s getToken];
				}
			}
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || [cmd isEqualToString:IRCCI_NOTICE]) {
				if ([s hasPrefix:@"\x01"]) {
					cmd = [cmd isEqualToString:IRCCI_PRIVMSG] ? IRCCI_CTCP : IRCCI_CTCPREPLY;
					[s deleteCharactersInRange:NSMakeRange(0, 1)];
					NSRange r = [s rangeOfString:@"\x01"];
					if (r.location != NSNotFound) {
						NSInteger len = s.length - r.location;
						if (len > 0) {
							[s deleteCharactersInRange:NSMakeRange(r.location, len)];
						}
					}
				}
			}
			
			if ([cmd isEqualToString:IRCCI_CTCP]) {
				NSMutableString *t = [[s mutableCopy] autorelease];
				NSString *subCommand = [[t getToken] uppercaseString];
				if ([subCommand isEqualToString:IRCCI_ACTION]) {
					cmd = IRCCI_ACTION;
					s = t;
					targetChannelName = [s getToken];
				} else {
					NSString *subCommand = [[s getToken] uppercaseString];
					if (subCommand.length) {
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
			
			if ([cmd isEqualToString:IRCCI_PRIVMSG] || [cmd isEqualToString:IRCCI_NOTICE] || [cmd isEqualToString:IRCCI_ACTION]) {
				if (!targetChannelName) return NO;
				if (!s.length) return NO;
				
				LogLineType type;
				if ([cmd isEqualToString:IRCCI_NOTICE]) {
					type = LINE_TYPE_NOTICE;
				} else if ([cmd isEqualToString:IRCCI_ACTION]) {
					type = LINE_TYPE_ACTION;
				} else {
					type = LINE_TYPE_PRIVMSG;
				}
				
				while (s.length) {
					NSString *t = [self truncateText:s command:cmd channelName:targetChannelName];
					if (!t.length) break;
					
					NSMutableArray *targetsResult = [NSMutableArray array];
					NSArray *targets = [targetChannelName componentsSeparatedByString:@","];
					for (NSString *chname in targets) {
						if (!chname.length) continue;
						
						BOOL opPrefix = NO;
						if ([chname hasPrefix:@"@"]) {
							opPrefix = YES;
							chname = [chname safeSubstringFromIndex:1];
						}
						
						NSString *lowerChname = [chname lowercaseString];
						IRCChannel *c = [self findChannel:chname];
						
						if (!c
							&& ![chname isChannelName]
							&& ![lowerChname isEqualToString:@"nickserv"]
							&& ![lowerChname isEqualToString:@"chanserv"]) {
							c = [world createTalk:chname client:self];
						}
						
						[self printBoth:(c ?: (id)chname) type:type nick:myNick text:t identified:YES];
						
						if ([chname isChannelName]) {
							if (opMsg || opPrefix) {
								chname = [@"@" stringByAppendingString:chname];
							}
						}
						
						[targetsResult addObject:chname];
					}
					
					NSString *localCmd = cmd;
					if ([localCmd isEqualToString:IRCCI_ACTION]) {
						localCmd = IRCCI_PRIVMSG;
						t = [NSString stringWithFormat:@"\x01%@ %@\x01", IRCCI_ACTION, t];
					}
					
					[self send:localCmd, [targetsResult componentsJoinedByString:@","], t, nil];
				}
			} 
			
			return YES;
			break;
		}
		case 15: // Command: PART
		case 52: // Command: LEAVE
			if (selChannel && selChannel.isChannel && ![s isChannelName]) {
				targetChannelName = selChannel.name;
			} else if (selChannel && selChannel.isTalk && ![s isChannelName]) {
				[world destroyChannel:selChannel];
				return YES;
			} else {
				targetChannelName = [s getToken];
			}
			
			if (targetChannelName) {
				NSString *reason = [s trim];
				
				if (!s.length && !cutColon) {
					reason = [config leavingComment];
				}
				
				[self send:IRCCI_PART, targetChannelName, reason, nil];
			}
			return YES;
			break;
		case 20: // Command: QUIT
		{
			NSString *reason = [s trim];
			
			if ([s length] < 1) {
				reason = config.leavingComment;
			}
			
			[self quit:reason];
			return YES;
			break;
		}
		case 21: // Command: TOPIC
		case 61: // Command: T
			if (selChannel && selChannel.isChannel && ![s isChannelName]) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = [s getToken];
			}
			
			if (targetChannelName) {
				if (!s.length && !cutColon) {
					s = nil;
				}
				
				[self send:IRCCI_TOPIC, targetChannelName, s, nil];
			}
			return YES;
			break;
		case 24: // Command: WHOIS
			if ([s contains:@" "]) {
				[self sendLine:[NSString stringWithFormat:@"%@ %@", IRCCI_WHOIS, s]];
			} else {
				[self send:IRCCI_WHOIS, s, s, nil];
			}
			
			return YES;
			break;
		case 32: // Command: CTCP
		{ 
			NSString *subCommand = [[s getToken] uppercaseString];
			
			if (subCommand.length) {
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
			targetChannelName = [s getToken];
			NSString *subCommand = [s getToken];
			[self sendCTCPReply:targetChannelName command:subCommand text:s];
			return YES;
			break;
		case 41: // Command: BAN
		case 64: // Command: UNBAN
			if (c) {
				NSString *host = nil;
				NSString *peer = [s getToken];
				
				if (peer) {
					IRCUser *user = [c findMember:peer];
					
					if (user) {
						host = [user banMask];
					} else {
						host = peer;
					}
					
					if ([cmd isEqualToString:IRCCI_BAN]) {
						[self sendCommand:[NSString stringWithFormat:@"MODE +b %@", host] completeTarget:YES target:c.name];
					} else {
						[self sendCommand:[NSString stringWithFormat:@"MODE -b %@", host] completeTarget:YES target:c.name];
					}
				}
			}
			return YES;
			break;
		case 11: // Command: MODE
		case 45: // Command: DEHALFOP
		case 46: // Command: DEOP
		case 47: // Command: DEVOICE
		case 48: // Command: HALFOP
		case 56: // Command: OP
		case 63: // Command: VOICE
		case 66: // Command: UMODE
			if ([cmd isEqualToString:IRCCI_MODE]) {
				if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
					targetChannelName = selChannel.name;
				} else if (!([s hasPrefix:@"+"] || [s hasPrefix:@"-"])) {
					targetChannelName = [s getToken];
				}
			} else if ([cmd isEqualToString:IRCCI_UMODE]) {
				[s insertString:@" " atIndex:0];
				[s insertString:myNick atIndex:0];
			} else {
				if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
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
				if (!params.count) {
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
			
			if (targetChannelName.length) {
				[line appendString:@" "];
				[line appendString:targetChannelName];
			}
			
			if (s.length) {
				[line appendString:@" "];
				[line appendString:s];
			}
			
			[self sendLine:line];
			return YES;
			break;
		case 42: // Command: CLEAR
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
		case 43: // Command: CLOSE
		case 77: // Command: REMOVE
		{
			NSString *nick = [s getToken];
			
			if (nick.length) {
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
			if (c) {
				NSString *pass = nil;
				if ([c.mode modeIsDefined:@"k"]) pass = [c.mode modeInfoFor:@"k"].param;
				if (!pass.length) pass = nil;
				[self partChannel:c];
				[self joinChannel:c password:pass];
			}
			return YES;
			break;
		case 50: // Command: IGNORE
		case 65: // Command: UNIGNORE
			if (!s.length) {
				[world.menuController showServerPropertyDialog:self ignore:YES];
				return YES;
			} else {
				AddressBook *g = [[AddressBook new] autorelease];
				
				NSString *hostmask = [s getToken];
				
				if (![hostmask contains:@"!"] || ![hostmask contains:@"@"]) {
					IRCChannel *c = world.selectedChannel;
					
					if (c) {
						IRCUser *u = [c findMember:hostmask];
						
						if (u) {
							hostmask = [u banMask];
						} else {
							hostmask = [NSString stringWithFormat:@"%@*!*@*", hostmask];
						}
					} else {
						hostmask = [NSString stringWithFormat:@"%@*!*@*", hostmask];
					}
				}
				
				g.hostmask = hostmask;
				g.ignorePublicMsg = YES;
				g.ignorePrivateMsg = YES;
				g.ignoreHighlights = YES;
				g.ignorePMHighlights = YES;
				g.ignoreNotices = YES;
				g.ignoreCTCP = YES;
				g.ignoreDCC = YES;
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
					
					if (!found) {
						[config.ignores addObject:g];
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
		case 57: // Command: RAW
		case 60: // Command: QUOTE
			[self sendLine:s];
			return YES;
			break;
		case 59: // Command: QUERY
		{
			NSString *nick = [s getToken];
			
			if (!nick.length) {
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
				TimerCommand *cmd = [[TimerCommand new] autorelease];
				
				if ([s hasPrefix:@"/"]) {
					[s deleteCharactersInRange:NSMakeRange(0, 1)];
				}
				
				cmd.input = s;
				cmd.time = CFAbsoluteTimeGetCurrent() + interval;
				cmd.cid = c ? c.uid : -1;
				
				[self addCommandToCommandQueue:cmd];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_ERROR_REPLY text:TXTLS(@"IRC_TIMER_REQUIRES_REALINT")];
			}
			
			return YES;
			break;
		}
		case 68: // Command: WEIGHTS
			if (c) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:@"WEIGHTS: "];
				
				for (IRCUser *m in c.members) {
					if (m.totalWeight > 0) {
						NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_WEIGHTS_COMMAND_RESULT"), m.nick, m.incomingWeight, m.outgoingWeight, m.totalWeight];
						[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
					}
				}
			}
			
			return YES;
			break;
		case 69: // Command: ECHO
		case 70: // Command: DEBUG
			if ([s isEqualToString:@"raw on"]) {
				rawModeEnabled = YES;
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_ENABLED")];
			} else if ([s isEqualToString:@"raw off"]) {
				rawModeEnabled = NO;	
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"IRC_RAW_MODE_IS_DISABLED")];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:s];
			}
			
			return YES;
			break;
		case 71: // Command: CLEARALL
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
		case 72: // Command: AMSG
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if (![u isConnected]) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
						[[u client] sendCommand:[NSString stringWithFormat:@"MSG %@ %@", c.name, s] completeTarget:YES target:c.name];
					}
				}
			} else {
				if (![self isConnected]) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
					[self sendCommand:[NSString stringWithFormat:@"MSG %@ %@", c.name, s] completeTarget:YES target:c.name];
				}
			}
			
			[self reloadTree];
			return YES;
			break;
		case 73: // Command: AME
			if ([Preferences amsgAllConnections]) {
				for (IRCClient *u in [world clients]) {
					if (![u isConnected]) continue;
					
					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;
						[[u client] sendCommand:[NSString stringWithFormat:@"ME %@", s] completeTarget:YES target:c.name];
					}
				}
			} else {
				if (![self isConnected]) return NO;
				
				for (IRCChannel *c in channels) {
					c.isUnread = YES;
					[self sendCommand:[NSString stringWithFormat:@"ME %@", s] completeTarget:YES target:c.name];
				}
			}
			
			[self reloadTree];
			return YES;
			break;
		case 78: // Command: KB
		case 79: // Command: KICKBAN 
			if (c) {
				NSString *host = nil;
				NSString *peer = [s getToken];
				
				if (peer) {
					NSString *reason = [s trim];
					
					IRCUser *user = [c findMember:peer];
					
					if (user) {
						host = [user banMask];
					} else {
						host = peer;
					}
					
					if ([reason length] < 1) {
						reason = [Preferences defaultKickMessage];
					}
					
					[self send:IRCCI_MODE, c.name, @"+b", host, nil];
					[self send:IRCCI_KICK, c.name, user.nick, reason, nil];
				}
			}
			
			return YES;
			break;
		case 81: // Command: ICBADGE
			if (![s contains:@" "]) return NO;
			
			NSArray *data = [s componentsSeparatedByString:@" "];
			
			[DockIcon drawWithHilightCount:[[data safeObjectAtIndex:0] integerValue] messageCount:[[data safeObjectAtIndex:1] integerValue]];
			
			return YES;
			break;
		case 82: // Command: SERVER
			if ([s length] >= 1) {
				[world createConnection:s chan:nil];
			}
			
			return YES;
			break;
		case 83: // Command: CONN
			if ([s length] >= 1) {
				[config setHost:s];
			}
			
			if (isConnected) [self quit];
			[self connect];
			
			return YES;
			break;
		case 84: // Command: MYVERSION
		{
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CTCP_VERSION_INFO"), 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"], 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"], 
							  [[Preferences textualInfoPlist] objectForKey:@"Build Number"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductName"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductVersion"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductBuildVersion"],
							  [Preferences systemProcessor]];
			
			[self sendPrivmsgToSelectedChannel:text];
			
			return YES;
			break;
		}
		case 90: // Command: RESETFILES
			[[ViewTheme invokeInBackgroundThread] createUserDirectory:YES];
			
			[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOURCE_RESOURCES_FILES_RESET")];
			
			return YES;
			break;
		case 74: // Command: MUTE
			if (world.soundMuted) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_ALREADY_MUTED")];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_HAS_BEEN_MUTED")];
				
				[world setSoundMuted:YES];
			}
			return YES;
			break;
		case 75: // Command: UNMUTE
			if (world.soundMuted) {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_NO_LONGER_MUTED")];
				
				[world setSoundMuted:NO];
			} else {
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:TXTLS(@"SOUND_IS_NOT_MUTED")];
			}
			return YES;
			break;
		case 76: // Command: UNLOAD_PLUGINS
			[[NSBundle invokeInBackgroundThread] deallocAllAvailableBundlesFromMemory:world];
			return YES;
			break;
		case 91: // Command: LOAD_PLUGINS
			[[NSBundle invokeInBackgroundThread] loadAllAvailableBundlesIntoMemory:world];
			return YES;
			break;
		default:
		{
			if ([[world bundlesForUserInput] objectForKey:cmd]) {
				[[self invokeInBackgroundThread] processBundlesUserMessage:[NSArray arrayWithObjects:[NSString stringWithString:s], cmd, nil]];
			} else {
				NSString *scriptPath = [[Preferences whereScriptsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.scpt", [cmd lowercaseString]]];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
					NSDictionary *inputInfo = [NSDictionary dictionaryWithObjectsAndKeys:c.name, @"channel", scriptPath, @"path", s, @"input", 
											   [NSNumber numberWithBool:completeTarget], @"completeTarget", targetChannelName, @"target", nil];
					[NSThread detachNewThreadSelector:@selector(executeTextualCmdScript:) toTarget:self withObject:[[inputInfo mutableCopy] autorelease]];
				} else {
					if (cutColon) {
						[s insertString:@":" atIndex:0];
					}
					
					[s insertString:@" " atIndex:0];
					[s insertString:cmd atIndex:0];
					
					[self sendLine:s];
				}
			}
			
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
		[ary addObject:obj];
	}
	va_end(args);
	
	NSMutableString *s = [NSMutableString stringWithString:str];
	
	NSInteger count = ary.count;
	for (NSInteger i = 0; i < count; i++) {
		NSString *e = [ary safeObjectAtIndex:i];
		
		[s appendString:@" "];
		
		if (i == count-1 && (e.length == 0 || [e hasPrefix:@":"] || [e contains:@" "])) {
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
	
	if (c == nil) {
		return [self findChannelOrCreate:name useTalk:NO];
	} else {
		return c;
	}
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name useTalk:(BOOL)doTalk
{
	if (doTalk) {
		return [world createTalk:name client:self];
	} else {
		IRCChannelConfig *seed = [[IRCChannelConfig new] autorelease];
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
		CFAbsoluteTime delta = m.time - CFAbsoluteTimeGetCurrent();
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
			[commandQueue insertObject:m atIndex:i];
			break;
		}
		++i;
	}
	
	if (!added) {
		[commandQueue addObject:m];
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

- (void)notifyText:(GrowlNotificationType)type target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if (![Preferences growlEnabledForEvent:type]) return;
	if ([Preferences disableWhileAwayForEvent:type] == YES && isAway == YES) return;
	
	IRCChannel *channel = nil;
	NSString *chname = nil;
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel *)target;
			chname = channel.name;
			if (!channel.config.growl) {
				return;
			}
		} else {
			chname = (NSString *)target;
		}
	}
	if (!chname) {
		chname = self.name;
	}
	
	NSString *title = chname;
	NSString *desc = [NSString stringWithFormat:@"<%@> %@", nick, text];
	NSString *context;
	if (channel) {
		context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
	} else {
		context = [NSString stringWithDouble:uid];
	}
	
	[world notifyOnGrowl:type title:title desc:desc context:context];
	[SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
}

- (void)notifyEvent:(GrowlNotificationType)type
{
	[self notifyEvent:type target:nil nick:@"" text:@""];
}

- (void)notifyEvent:(GrowlNotificationType)type target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if (![Preferences growlEnabledForEvent:type]) return;
	if ([Preferences disableWhileAwayForEvent:type] == YES && isAway == YES) return;
	
	IRCChannel *channel = nil;
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel *)target;
			if (!channel.config.growl) {
				return;
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
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_KICKED_DESC"), nick, text];
			break;
		case GROWL_INVITED:
			title = self.name;
			desc = [NSString stringWithFormat:TXTLS(@"GROWL_MSG_INVITED_DESC"), nick, text];
			break;
		case GROWL_ADDRESS_BOOK_MATCH:
			desc = text;
			break;
		default:
			return;
	}
	
	NSString *context;
	if (channel) {
		context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
	} else {
		context = [NSString stringWithDouble:uid];
	}
	
	[world notifyOnGrowl:type title:title desc:desc context:context];
	[SoundPlayer play:[Preferences soundForEvent:type] isMuted:world.soundMuted];
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(id)t
{
	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([t isChannel] == YES || [t isTalk] == YES) {
			if (world.selected != t || ![[NSApp mainWindow] isOnCurrentWorkspace]) {
				[t setKeywordCount:([t keywordCount] + 1)];
				[world updateIcon];
			}
		}
	}
	
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isKeyword]) return;
	[t setIsKeyword:YES];
	[self reloadTree];
	if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
}

- (void)setNewTalkState:(id)t
{
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isNewTalk]) return;
	[t setIsNewTalk:YES];
	[self reloadTree];
	if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
	[world updateIcon];
}

- (void)setUnreadState:(id)t
{
	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([Preferences countPublicMessagesInIconBadge] == NO) {
			if ([t isTalk] == YES && [t isClient] == NO) {
				if (world.selected != t || ![[NSApp mainWindow] isOnCurrentWorkspace]) {
					[t setUnreadCount:([t unreadCount] + 1)];
					[world updateIcon];
				}
			}
		} else {
			if (world.selected != t || ![[NSApp mainWindow] isOnCurrentWorkspace]) {
				[t setUnreadCount:([t unreadCount] + 1)];
				[world updateIcon];
			}	
		}
	}
	
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isUnread]) return;
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
	NSString *format = nil;
	
	if (world.viewTheme.other.nicknameFormat) {
		format = world.viewTheme.other.nicknameFormat;
	} else {
		if ([Preferences themeOverrideNickFormat]) {
			format = [Preferences themeNickFormat];
		}
	}
	
	if ([format length] < 1) {
		format = @"<%@%n>";
	}
	
	NSString *s = format;
	
	if ([s contains:@"%@"]) {
		if (channel && !channel.isClient && channel.isChannel) {
			IRCUser *m = [channel findMember:nick];
			
			if (m) {
				NSString *mark = [NSString stringWithChar:m.mark];
				
				if ([mark isEqualToString:@" "] || [mark length] < 1) {
					s = [s stringByReplacingOccurrencesOfString:@"%@" withString:@""];
				} else {
					s = [s stringByReplacingOccurrencesOfString:@"%@" withString:mark];
				}
			} else {
				s = [s stringByReplacingOccurrencesOfString:@"%@" withString:@""];	
			}
		} else {
			s = [s stringByReplacingOccurrencesOfString:@"%@" withString:@""];	
		}
	}
	
	while (1) {
		NSRange r = [s rangeOfRegex:@"%(-?\\d+)?n"];
		if (r.location == NSNotFound) break;
		
		NSRange numRange = r;
		
		if (numRange.location != NSNotFound && numRange.length > 0) {
			NSString *numStr = [s substringWithRange:numRange];
			NSInteger n = [numStr integerValue];
			NSString *formattedNick = nick;
			
			if (n >= 0) {
				NSInteger pad = n - nick.length;
				if (pad > 0) {
					NSMutableString *ms = [NSMutableString stringWithString:nick];
					
					for (NSInteger i = 0; i < pad; ++i) {
						[ms appendString:@" "];
					}
					
					formattedNick = ms;
				}
			} else {
				NSInteger pad = -n - nick.length;
				
				if (pad > 0) {
					NSMutableString *ms = [NSMutableString string];
					
					for (NSInteger i = 0; i < pad; ++i) {
						[ms appendString:@" "];
					}
					
					[ms appendString:nick];
					formattedNick = ms;
				}
			}
			
			s = [s stringByReplacingCharactersInRange:r withString:formattedNick];
		} else {
			s = [s stringByReplacingCharactersInRange:r withString:nick];
		}
	}
	
	return s;
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type text:(NSString *)text
{
	return [self printChannel:chan type:type nick:nil text:text identified:NO];
}

- (BOOL)printAndLog:(LogLine *)line withHTML:(BOOL)rawHTML
{
	BOOL result = [log print:line withHTML:rawHTML];
	
	if (!self.isConnected) return NO;
	
	if ([Preferences logTranscript]) {
		if (!logFile) {
			logFile = [FileLogger new];
			logFile.client = self;
		}
		
		NSString *comp = [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil]];
		if (logDate) {
			if (![logDate isEqualToString:comp]) {
				[logDate release];
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
	IRCChannel *channel = [world selectedChannelOn:self];
	LogLineType memberType = MEMBER_TYPE_NORMAL;
	LogLineType type = LINE_TYPE_REPLY;
	
	LogLine *c = [[LogLine new] autorelease];
	
	if (showTime) {
		NSString *time = TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
		
		if (time.length) {
			time = [time stringByAppendingString:@" "];
		}
		
		c.time = time;
	}
	
	c.body = text;
	c.lineType = type;
	c.memberType = memberType;
	
	if (channel) {
		return [channel print:c withHTML:YES];
	} else {
		if ([Preferences logTranscript]) {
			return [self printAndLog:c withHTML:YES];
		} else {
			return [log print:c withHTML:YES];
		}
	}
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
	NSString *time = TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], world.viewTheme.other.timestampFormat);
	IRCChannel *channel = nil;
	NSString *place = nil;
	NSString *nickStr = nil;
	LogLineType memberType = MEMBER_TYPE_NORMAL;
	NSInteger colorNumber = 0;
	NSArray *keywords = nil;
	NSArray *excludeWords = nil;
	
	LogLine *c = [[LogLine new] autorelease];
	
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
				keywords = [Preferences keywords];
				excludeWords = [Preferences excludeWords];
				
				if ([Preferences keywordCurrentNick]) {
					NSMutableArray *ary = [[keywords mutableCopy] autorelease];
					[ary insertObject:myNick atIndex:0];
					keywords = ary;
				}
			}
		}
	}
	
	if (type == LINE_TYPE_ACTION_NH) {
		type = LINE_TYPE_ACTION;
	} else if (type == LINE_TYPE_PRIVMSG_NH) {
		type = LINE_TYPE_PRIVMSG;
	}
	
	if (time.length) {
		time = [time stringByAppendingString:@" "];
	}
	
	if (nick.length > 0) {
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
	c.nick = nickStr;
	c.body = text;
	c.lineType = type;
	c.memberType = memberType;
	c.nickInfo = nick;
	c.clickInfo = nil;
	c.identified = identified;
	c.nickColorNumber = colorNumber;
	c.keywords = keywords;
	c.excludeWords = excludeWords;
	
	if (channel) {
		if ([Preferences autoAddScrollbackMark]) {
			if (channel != world.selectedChannel || ![[NSApp mainWindow] isOnCurrentWorkspace]) {
				if (!channel.isUnread) {
					if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION || type == LINE_TYPE_NOTICE) {
						[channel.log unmark];
						[channel.log mark];
					}
				}
			}
		}
		
		return [channel print:c];
	} else {
		if (type == LINE_TYPE_PART) {
			return NO;
		} else {
			if ([Preferences logTranscript]) {
				return [self printAndLog:c withHTML:NO];
			} else {
				return [log print:c];
			}
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
	NSString *text = [m sequence:1];
	[self printBoth:nil type:LINE_TYPE_REPLY text:text];
}

- (void)printUnknownReply:(IRCMessage *)m
{
	[self printBoth:nil type:LINE_TYPE_REPLY text:[m sequence:1]];
}

- (void)printErrorReply:(IRCMessage *)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel
{
	NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_HAD_RAW_ERROR"), m.numericReply, [m sequence]];
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
		NSInteger n = [text findString:@"\x01"];
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
	NSString *anick = m.sender.nick;
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
	
	AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
											uname:m.sender.user 
											 name:m.sender.nick
									 matchAgainst:[NSArray arrayWithObjects:@"ignoreHighlights", 
												   @"ignorePMHighlights",
												   @"ignoreNotices", 
												   @"ignorePublicMsg", 
												   @"ignorePrivateMsg", nil]];
	
	if (target.isChannelName) {
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
		BOOL keyword = [self printBoth:(c ?: (id)target) type:type nick:anick text:text identified:identified];
		
		if (type == LINE_TYPE_NOTICE) {
			[self notifyText:GROWL_CHANNEL_NOTICE target:(c ?: (id)target) nick:anick text:text];
		} else {
			id t = c ?: (id)self;
			[self setUnreadState:t];
			if (keyword) [self setKeywordState:t];
			
			GrowlNotificationType kind = keyword ? GROWL_HIGHLIGHT : GROWL_CHANNEL_MSG;
			[self notifyText:kind target:(c ?: (id)target) nick:anick text:text];
			
			if (c) {
				IRCUser *sender = [c findMember:anick];
				if (sender) {
					static NSCharacterSet *underlineSet = nil;
					if (!underlineSet) {
						underlineSet = [[NSCharacterSet characterSetWithCharactersInString:@"_"] retain];
					}
					NSString *trimmedMyNick = [myNick stringByTrimmingCharactersInSet:underlineSet];
					if ([text rangeOfString:trimmedMyNick options:NSCaseInsensitiveSearch].location != NSNotFound) {
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
		
		if (!anick.length) {
			[self printBoth:nil type:type text:text];
		} else if ([anick contains:@"."]) {
			if (type == LINE_TYPE_NOTICE) {
				if (hasIRCopAccess) {
					if ([text hasPrefix:@"*** Notice -- Client connecting"] || 
						[text hasPrefix:@"*** Notice -- Client exiting"] || 
						[text hasPrefix:@"*** You are connected to"] || 
						[text hasPrefix:@"Forbidding Q-lined nick"] || 
						[text hasPrefix:@"Exiting ssl client"]) {
						[self printBoth:nil type:type text:text];	
						
						BOOL processData = NO;
						
						NSString *host;
						NSString *snick;
						
						NSInteger match_math = 0;
						
						if ([text hasPrefix:@"*** Notice -- Client connecting at"]) {
							processData = YES;
						} else if ([text hasPrefix:@"*** Notice -- Client connecting on port"]) {
							processData = YES;
							
							match_math = 1;
						}
						
						if (processData) {	
							NSArray *chunks = [text componentsSeparatedByString:@" "];
							
							host = [chunks safeObjectAtIndex:(8 + match_math)];
							snick = [chunks safeObjectAtIndex:(7 + match_math)];
							
							host = [host safeSubstringFromIndex:1];
							host = [host safeSubstringToIndex:([host length] - 1)];
							host = [NSString stringWithFormat:@"%@!%@", snick, host];
							
							ignoreChecks = [self checkIgnoreAgainstHostmask:host
																withMatches:[NSArray arrayWithObjects:@"notifyWhoisJoins", @"notifyJoins", nil]];
							
							[self handleUserTrackingNotification:ignoreChecks hostmask:host nickname:snick langitem:@"USER_TRACKING_HOSTMASK_CONNECTED"];
						}
					} else {
						if ([Preferences handleServerNotices]) {
							if ([Preferences handleIRCopAlerts] && [text contains:[Preferences IRCopAlertMatch]]) {
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
			BOOL newTalk = NO;
			if (!c && type != LINE_TYPE_NOTICE) {
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
						if (config.nickPassword.length) {
							[self send:IRCCI_PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
						}
					}
				}
				
				[self notifyText:GROWL_TALK_NOTICE target:(c ?: (id)target) nick:anick text:text];
			} else {
				if ([ignoreChecks ignorePrivateMsg] == YES) {
					return;
				}
				
				BOOL keyword = [self printBoth:c type:type nick:anick text:text identified:identified];
				
				id t = c ?: (id)self;
				[self setUnreadState:t];
				if (keyword) [self setKeywordState:t];
				if (newTalk) [self setNewTalkState:t];
				
				GrowlNotificationType kind = keyword ? GROWL_HIGHLIGHT : newTalk ? GROWL_NEW_TALK : GROWL_TALK_MSG;
				[self notifyText:kind target:(c ?: (id)target) nick:anick text:text];
				
				NSString *hostTopic = [NSString stringWithFormat:@"%@!%@@%@", m.sender.nick, m.sender.user, m.sender.address];
				
				if ([hostTopic isEqualNoCase:c.topic] == NO) {
					[c setTopic:hostTopic];
					[c.log setTopic:hostTopic];
				}
			}
		}
	} else {
		if (!anick.length || [anick contains:@"."]) {
			[self printBoth:nil type:type text:text];
		} else {
			if ([ignoreChecks ignorePublicMsg] == YES) {
				return;
			}
			
			[self printBoth:nil type:type nick:anick text:text identified:identified];
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;
	NSMutableString *s = [[text mutableCopy] autorelease];
	NSString *command = [[s getToken] uppercaseString];
	
	AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
											uname:m.sender.user 
											 name:m.sender.nick
									 matchAgainst:[NSArray arrayWithObjects:@"ignoreCTCP", nil]];
	
	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}
	
	if ([command isEqualToString:IRCCI_DCC]) {
		return;
	} else {
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_RECIEVED_CTCP_REQUEST"), command, nick];
		[self printBoth:nil type:LINE_TYPE_CTCP text:text];
		
		if ([command isEqualToString:IRCCI_PING]) {
			[self sendCTCPReply:nick command:command text:s];
		} else if ([command isEqualToString:IRCCI_TIME]) {
			NSString *text = [[NSDate date] description];
			[self sendCTCPReply:nick command:command text:text];
		} else if ([command isEqualToString:IRCCI_VERSION]) {
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CTCP_VERSION_INFO"), 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"], 
							  [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"], 
							  [[Preferences textualInfoPlist] objectForKey:@"Build Number"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductName"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductVersion"], 
							  [[Preferences systemInfoPlist] objectForKey:@"ProductBuildVersion"],
							  [Preferences systemProcessor]];
			
			[self sendCTCPReply:nick command:command text:text];
		} else if ([command isEqualToString:IRCCI_USERINFO]) {
			[self sendCTCPReply:nick command:command text:config.userInfo ?: @""];
		} else if ([command isEqualToString:IRCCI_CLIENTINFO]) {
			[self sendCTCPReply:nick command:command text:TXTLS(@"DCC VERSION CLIENTINFO USERINFO PING TIME")];
		}
	}
}

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;
	NSMutableString *s = [[text mutableCopy] autorelease];
	NSString *command = [[s getToken] uppercaseString];
	
	AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
											uname:m.sender.user 
											 name:m.sender.nick
									 matchAgainst:[NSArray arrayWithObjects:@"ignoreCTCP", nil]];
	
	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}
	
	IRCChannel *c = nil;
	
	if ([Preferences locationToSendNotices] == NOTICES_SENDTO_CURCHAN) {
		c = [world selectedChannelOn:self];
	}
	
	if ([command isEqualToString:IRCCI_PING]) {
		double time = [s doubleValue];
		double delta = CFAbsoluteTimeGetCurrent() - time;
		
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_RECIEVED_CTCP_PING_REPLY"), nick, command, delta];
		[self printBoth:c type:LINE_TYPE_CTCP text:text];
	} else {
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_RECIEVED_CTCP_REPLY"), nick, command, s];
		[self printBoth:c type:LINE_TYPE_CTCP text:text];
	}
}


- (void)requestUserHosts:(IRCChannel *)c 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([c.name isChannelName]) {
		[c setIsModeInit:YES];
		
		[self send:IRCCI_MODE, c.name, nil];
		[self send:IRCCI_WHO, c.name, nil, nil];
	}
	
	[pool drain];
}

- (void)_requestIPAddressFromInternet
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURLRequest *chRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://myip.dnsomatic.com/"] 
											   cachePolicy:NSURLRequestReloadIgnoringCacheData 
										   timeoutInterval:10];
	
	NSData *response = [NSURLConnection sendSynchronousRequest:chRequest returningResponse:nil error:NULL]; 
	
	if (response) {
		NSString *address = [[NSString alloc] initWithData:response encoding:NSASCIIStringEncoding];
		[address autorelease];
		[self setDCCIPAddress:[address trim]];
	}
	
	[pool release];
}

- (void)requestIPAddressFromInternet
{
	[[self invokeInBackgroundThread] _requestIPAddressFromInternet];
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	
	BOOL myself = [nick isEqualNoCase:myNick];
	
	BOOL njoin = NO;
	if ([chname hasSuffix:@"\x07o"]) {
		njoin = YES;
		chname = [chname safeSubstringToIndex:chname.length - 2];
	}
	
	IRCChannel *c = [self findChannelOrCreate:chname];
	
	if (myself) {
		[c activate];
		[self reloadTree];
		
		if (!myAddress) {
			[self requestIPAddressFromInternet];
		}
	}
	
	if (c && ![c findMember:nick]) {
		IRCUser *u = [[IRCUser new] autorelease];
		u.nick = nick;
		u.username = m.sender.user;
		u.address = m.sender.address;
		u.o = njoin;
		[c addMember:u];
		[self updateChannelTitle:c];
	}
	
	if ([Preferences showJoinLeave]) {
		AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
												uname:m.sender.user 
												 name:m.sender.nick
										 matchAgainst:[NSArray arrayWithObjects:@"ignoreJPQE", @"notifyWhoisJoins", @"notifyJoins", nil]];
		
		if ([ignoreChecks ignoreJPQE] == YES && !myself) {
			return;
		}
		
		if (hasIRCopAccess == NO) {
			if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
				NSString *tracker = [ignoreChecks trackingNickname];
				NSInteger ison = [[trackedUsers objectForKey:tracker] integerValue];
				
				if (!ison) {					
					NSString *host = [NSString stringWithFormat:@"%@!%@@%@", m.sender.nick, m.sender.user, m.sender.address];
					[self handleUserTrackingNotification:ignoreChecks hostmask:host nickname:m.sender.nick langitem:@"USER_TRACKING_HOSTMASK_NOW_AVAILABLE"];
					[trackedUsers setObject:@"1" forKey:tracker];
				}
			}
		}
		
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_JOINED_CHANNEL"), nick, m.sender.user, m.sender.address];
		[self printBoth:(c ?: (id)chname) type:LINE_TYPE_JOIN text:text];
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
		[self updateChannelTitle:c];
	}
	
	if ([Preferences showJoinLeave]) {
		AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
												uname:m.sender.user 
												 name:m.sender.nick
										 matchAgainst:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
		
		if ([ignoreChecks ignoreJPQE] == YES) {
			return;
		}
		
		NSString *message = [NSString stringWithFormat:TXTLS(@"IRC_USER_PARTED_CHANNEL"), nick, m.sender.user, m.sender.address];
		
		if ([comment length] > 0) {
			message = [message stringByAppendingFormat:@" (%@)", comment];
		}
		
		[self printBoth:(c ?: (id)chname) type:LINE_TYPE_PART text:message];
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
		BOOL myself = [target isEqualNoCase:myNick];
		
		if (myself) {
			[c deactivate];
			[self reloadTree];
			[self notifyEvent:GROWL_KICKED target:c nick:nick text:comment];
		}
		
		[c removeMember:target];
		[self updateChannelTitle:c];
		
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_KICKED_FROM_CHANNEL"), nick, target, comment];
		[self printBoth:(c ?: (id)chname) type:LINE_TYPE_KICK text:text];
		
		if (myself) {
			if ([Preferences rejoinOnKick]) {
				NSString *pass = nil;
				
				if ([c.mode modeIsDefined:@"k"]) pass = [c.mode modeInfoFor:@"k"].param;
				if (!pass.length) pass = nil;
				
				[self joinChannel:c password:pass];
			}
		}
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *comment = [[m paramAt:0] trim];
	
	AddressBook *ignoreChecks = [self checkIgnore:m.sender.address 
											uname:m.sender.user 
											 name:m.sender.nick
									 matchAgainst:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
	
	if ([ignoreChecks ignoreJPQE] == YES) {
		return;
	}
	
	if (hasIRCopAccess == NO) {
		if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
			NSString *tracker = [ignoreChecks trackingNickname];
			NSInteger ison = [[trackedUsers objectForKey:tracker] integerValue];
			
			if (ison) {					
				[trackedUsers setObject:@"0" forKey:tracker];
				NSString *host = [NSString stringWithFormat:@"%@!%@@%@", m.sender.nick, m.sender.user, m.sender.address];
				[self handleUserTrackingNotification:ignoreChecks hostmask:host nickname:m.sender.nick langitem:@"USER_TRACKING_HOSTMASK_NO_LONGER_AVAILABLE"];
			}
		}
	}
	
	NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_DISCONNECTED"), nick, m.sender.user, m.sender.address];
	
	if ([comment length] > 0) {
		text = [text stringByAppendingFormat:@" (%@)", comment];
	}
	
	for (IRCChannel *c in channels) {
		if ([c findMember:nick]) {
			if ([Preferences showJoinLeave]) {
				[self printChannel:c type:LINE_TYPE_QUIT text:text];
			}
			
			[c removeMember:nick];
			[self updateChannelTitle:c];
		}
	}
}

- (void)receiveKill:(IRCMessage *)m
{
	NSString *target = [m paramAt:0];
	
	for (IRCChannel *c in channels) {
		if ([c findMember:target]) {
			[c removeMember:target];
			[self updateChannelTitle:c];
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	BOOL myself = NO;
	
	AddressBook *ignoreChecks;
	
	NSString *nick = m.sender.nick;
	NSString *toNick = [m paramAt:0];
	
	if ([nick isEqualNoCase:myNick]) {
		[myNick release];
		myNick = [toNick retain];
		
		myself = YES;
	} else {
		ignoreChecks = [self checkIgnore:m.sender.address 
								   uname:m.sender.user 
									name:m.sender.nick
							matchAgainst:[NSArray arrayWithObjects:@"ignoreJPQE", nil]];
		
		if (hasIRCopAccess == NO) {
			if ([ignoreChecks notifyJoins] == YES || [ignoreChecks notifyWhoisJoins] == YES) {
				NSString *tracker = [ignoreChecks trackingNickname];
				NSInteger ison = [[trackedUsers objectForKey:tracker] integerValue];
				NSString *host = [NSString stringWithFormat:@"%@!%@@%@", m.sender.nick, m.sender.user, m.sender.address];
				
				if (ison) {					
					[self handleUserTrackingNotification:ignoreChecks hostmask:host nickname:m.sender.nick langitem:@"USER_TRACKING_HOSTMASK_NO_LONGER_AVAILABLE"];
					[trackedUsers setObject:@"0" forKey:tracker];
				} else {				
					[self handleUserTrackingNotification:ignoreChecks hostmask:host nickname:m.sender.nick langitem:@"USER_TRACKING_HOSTMASK_NOW_AVAILABLE"];
					[trackedUsers setObject:@"1" forKey:tracker];
				}
			}
		}
	}
	
	for (IRCChannel *c in channels) {
		if ([c findMember:nick]) { 
			if ((myself == NO && [ignoreChecks ignoreJPQE] == NO) || myself == YES) {
				NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_CHANGED_NICKNAME"), nick, toNick];
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
		[self updateChannelTitle:c];
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
			
			[self updateChannelTitle:c];
		}
		
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_MDOE_SET"), nick, modeStr];
		[self printBoth:(c ?: (id)target) type:LINE_TYPE_MODE text:text];
	} else {
		NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_MDOE_SET"), nick, modeStr];
		[self printBoth:nil type:LINE_TYPE_MODE text:text];
		[self updateClientTitle];
	}
}

- (void)receiveTopic:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *topic = [m paramAt:1];
	
	IRCChannel *c = [self findChannel:chname];
	if (c) {
		c.topic = topic;
		[self updateChannelTitle:c];
		[c.log setTopic:topic];
	}
	
	NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_TOPIC_CHANGED"), nick, topic];
	[self printBoth:(c ?: (id)chname) type:LINE_TYPE_TOPIC text:text];
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:1];
	
	NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_INVITED_YOU_TO"), nick, m.sender.user, m.sender.address, chname];
	[self printBoth:self type:LINE_TYPE_INVITE text:text];
	
	[self notifyEvent:GROWL_INVITED target:nil nick:nick text:chname];
	
	if ([Preferences autoJoinOnInvite]) {
		[self send:IRCCI_JOIN, chname, nil, nil];
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
	
	isAway = NO;
	isConnecting = NO;
	isLoggedIn = YES;
	conn.loggedIn = YES;
	tryingNickNumber = -1;
	hasIRCopAccess = NO;
	
	inList = NO;
	
	[serverHostname release];
	serverHostname = [m.sender.raw retain];
	[myNick release];
	myNick = [[m paramAt:0] retain];
	
	[self notifyEvent:GROWL_LOGIN];
	
	if (config.nickPassword.length) {
		[self send:IRCCI_PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
	}
	
	[self startAutoJoinTimer];
	
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
			m = [[IRCUser new] autorelease];
			m.nick = myNick;
			[c addMember:m];
			
			m = [[IRCUser new] autorelease];
			m.nick = c.name;
			[c addMember:m];
		}
	}
	
#ifdef IS_TRIAL_BINARY
	[self startTrialPeriodTimer];
#endif
	
	[self updateClientTitle];
	[self reloadTree];
	
	inFirstISONRun = YES;
	[self populateISONTrackedUsersList:config.ignores];
}

- (void)receiveNumericReply:(IRCMessage *)m
{
	NSInteger n = m.numericReply; 
	if (400 <= n && n < 600 && n != 403 && n != 422) {
		[self receiveErrorNumericReply:m];
		return;
	}
	
	switch (n) {
		case 1:
		{
			NSString *matche = [[m sequence:1] stringByMatching:@"Welcome to the (.*) (.*)" capture:1];
			
			if (matche) {
				[config setNetwork:matche];
				[world updateTitle];
			}
			
			[self receiveInit:m];
			[self printReply:m];
			break;
		}
		case 2 ... 4:
		case 10:
		case 20:
		case 42:
		case 250 ... 255:
		case 265 ... 266:
			[self printReply:m];
			break;
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
		case 5:	// RPL_ISUPPORT
			[isupport update:[m sequence:1]];
			break;
		case 221:	// RPL_UMODEIS
		{
			NSString *modeStr = [m paramAt:1];
			
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([modeStr isEqualToString:@"+"]) return;
			
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_YOU_HAVE_UMODES"), modeStr];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 290:	// RPL_CAPAB on freenode
		{
			NSString *kind = [m paramAt:1];
			kind = [kind lowercaseString];
			
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
			
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_IS_AWAY"), nick, comment];
			
			if (c) {
				[self printBoth:(id)nick type:LINE_TYPE_REPLY text:text];
			}
			
			if (whoisChannel && ![whoisChannel isEqualTo:c]) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
			} else {		
				if (![sc isEqualTo:c]) {
					[self printBoth:sc type:LINE_TYPE_REPLY text:text];
				}
			}
			
			break;
		}
		case 305: 
			isAway = NO;
			[self printUnknownReply:m];
			break;
		case 306: 
			isAway = YES;
			[self printUnknownReply:m];
			break;
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
			
			if (inWhoWasRequest) {
				text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOWAS_HOSTMASK"), nick, username, address, realname];
			} else {
				text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOIS_HOSTMASK"), nick, username, address, realname];
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
				text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOWAS_CONNECTED_FROM"), nick, server, [dateTimeFormatter stringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]]];
			} else {
				text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOIS_CONNECTED_FROM"), nick, server, serverInfo];
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
			NSString *idleStr = [m paramAt:2];
			NSString *signOnStr = [m paramAt:3];
			
			NSString *idleTime = TXReadableTime((NSTimeInterval)([[NSDate date] timeIntervalSince1970] - [idleStr doubleValue]), YES);
			NSString *dateFromString = [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[signOnStr doubleValue]]];
			
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOIS_UPTIME"), nick, dateFromString, idleTime];
			
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
			NSString *trail = [m paramAt:2];
			
			trail = [trail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_WHOIS_CHANNELS"), nick, trail];
			
			if (whoisChannel) {
				[self printBoth:whoisChannel type:LINE_TYPE_REPLY text:text];
			} else {		
				[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
			}
			break;
		}
		case 318:	// RPL_ENDOFWHOIS
			whoisChannel = nil;
			break;
		case 324:	// RPL_CHANNELMODEIS
		{
			NSString *chname = [m paramAt:1];
			NSString *modeStr = [m sequence:2];
			
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([modeStr isEqualToString:@"+"]) return;
			
			IRCChannel *c = [self findChannel:chname];
			if (c.isModeInit == NO || [[c.mode allModes] count] < 1) {
				if (c && c.isActive) {
					[c.mode clear];
					[c.mode update:modeStr];
					
					c.isModeInit = YES;
					[self updateChannelTitle:c];
				}
				
				NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_MODES"), modeStr];
				[self printBoth:(c ?: (id)chname) type:LINE_TYPE_MODE text:text];
			}
			break;
		}
		case 332:	// RPL_TOPIC
		{
			NSString *chname = [m paramAt:1];
			NSString *topic = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:chname];
			if (c && c.isActive) {
				c.topic = topic;
				[self updateChannelTitle:c];
				[c.log setTopic:topic];
			}
			
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_TOPIC"), topic];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_TOPIC text:text];
			break;
		}
		case 333:	
		{
			NSString *chname = [m paramAt:1];
			NSString *setter = [m paramAt:2];
			NSString *timeStr = [m paramAt:3];
			long long timeNum = [timeStr longLongValue];
			
			static NSCharacterSet *set = nil;
			if (!set) {
				set = [[NSCharacterSet characterSetWithCharactersInString:@"!@"] retain];
			}
			NSRange r = [setter rangeOfCharacterFromSet:set];
			if (r.location != NSNotFound) {
				setter = [setter safeSubstringToIndex:r.location];
			}
			
			IRCChannel *c = [self findChannel:chname];
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_TOPIC_AUTHOR"), setter, [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_TOPIC text:text];
			break;
		}
		case 341:	// RPL_INVITING
		{
			NSString *nick = [m paramAt:1];
			NSString *chname = [m paramAt:2];
			
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_USER_INVITED_OTHER_USER"), nick, chname];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 303:
		{
			if (hasIRCopAccess) {
				[self printUnknownReply:m];
			} else {
				NSString *allusers = [[m sequence] trim];
				
				NSMutableArray *users = [NSMutableArray array];
				NSArray *chunks = [allusers componentsSeparatedByString:@" "];
				
				for (NSString *name in chunks) {
					[users addObject:[name lowercaseString]];
				}
				
				NSDictionary *tracked = [trackedUsers copy];
				
				for (NSString *name in tracked) {
					NSString *langkey = nil;
					NSString *lcname = [name lowercaseString];
					NSInteger ison = [[trackedUsers objectForKey:name] integerValue];
					
					if (ison) {
						if (![users containsObject:lcname]) {
							if (inFirstISONRun == NO) {
								langkey = @"USER_TRACKING_NICKNAME_NO_LONGER_AVAILABLE";
							}
							
							[trackedUsers setObject:@"0" forKey:name];
						}
					} else {
						if ([users containsObject:lcname]) {
							langkey = ((inFirstISONRun) ? @"USER_TRACKING_NICKNAME_AVAILABLE" : @"USER_TRACKING_NICKNAME_NOW_AVAILABLE");
							[trackedUsers setObject:@"1" forKey:name];
						}
					}
					
					if (langkey) {
						for (AddressBook *g in config.ignores) {
							NSString *trname = [[g trackingNickname] lowercaseString];
							
							if ([trname isEqualToString:lcname]) {
								[self handleUserTrackingNotification:g hostmask:name nickname:name langitem:langkey];
							}
						}
					}
				}
				[tracked release];
				
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
			if (c && c.isModeInit) {
				[c setIsModeInit:NO];
			} else {
				[self printUnknownReply:m];
			}
			
			break;
		}
		case 352:	// RPL_WHOENTRY
		{
			NSString *chname = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:chname];
			if (c && c.isModeInit) {
				NSString *nick = [m paramAt:5];
				NSString *hostmask = [m paramAt:3];
				NSString *username = [m paramAt:2];
				
				IRCUser *u = [c findMember:nick];
				
				if (u) {
					if ([u.address length] < 1) {
						[u setAddress:hostmask];
						[u setUsername:username];
					}
				} else {
					IRCUser *u = [[IRCUser new] autorelease];
					u.nick = nick;
					u.username = username;
					u.address = hostmask;
					[c addMember:u];
				}
			} else {
				[self printUnknownReply:m];
			}
			break;
		}
		case 353:	// RPL_NAMREPLY
		{
			NSString *chname = [m paramAt:2];
			NSString *trail = [m paramAt:3];
			
			IRCChannel *c = [self findChannel:chname];
			if (c && c.isActive && !c.isNamesInit) {
				NSArray *ary = [trail componentsSeparatedByString:@" "];
				for (NSString *nick in ary) {
					nick = [nick trim];
					
					if (!nick.length) continue;
					
					NSString *u = [nick substringWithRange:NSMakeRange(0, 1)];
					NSString *op = @" ";
					if ([u isEqualTo:@"@"] || [u isEqualTo:@"~"] || 
						[u isEqualTo:@"&"] || [u isEqualTo:@"%"] || 
						[u isEqualTo:@"+"] || [u isEqualTo:@"!"]) {
						op = (([u isEqualToString:@"!"]) ? @"&" : u);
						nick = [nick safeSubstringFromIndex:1];
					}
					
					IRCUser *m = [[IRCUser new] autorelease];
					m.nick = nick;
					m.q = ([op isEqualTo:@"~"]);
					m.a = ([op isEqualTo:@"&"]);
					m.o = ([op isEqualTo:@"@"] || m.q);
					m.h = ([op isEqualTo:@"%"]);
					m.v = ([op isEqualTo:@"+"]);
					m.isMyself = [nick isEqualNoCase:myNick];
					[c addMember:m reload:NO];
					if ([myNick isEqualNoCase:nick]) {
						c.isOp = (m.q || m.a | m.o);
					}
				}
				[c reloadMemberList];
				[self updateChannelTitle:c];
			} else {
				[self printBoth:c ?: (id)chname type:LINE_TYPE_REPLY text:[NSString stringWithFormat:@"Names: %@", trail]];
			}
			break;
		}
		case 366:	// RPL_ENDOFNAMES
		{
			NSString *chname = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:chname];
			if (c && c.isActive && !c.isNamesInit) {
				c.isNamesInit = YES;
				
				if ([c numberOfMembers] <= 1 && c.isOp) {
					NSString *m = c.config.mode;
					if (m.length) {
						NSString *line = [NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, chname, m];
						[self sendLine:line];
					}
					c.isModeInit = YES;
				}
				
				if ([c numberOfMembers] <= 1 && [chname isModeChannelName]) {
					NSString *topic = c.storedTopic;
					if (!topic.length) {
						topic = c.config.topic;
					}
					if (topic.length) {
						[self send:IRCCI_TOPIC, chname, topic, nil];
					}
				}
				
				if ([c numberOfMembers] > 1) {
					// @@@add to who queue
				} else {
					c.isWhoInit = YES;
				}
				
				[self updateChannelTitle:c];
				
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
			
			if (!inList) {
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
			inList = NO;
			break;
		case 321:
		case 329:
			// do nothing
			break;
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
			} else {
				[self printUnknownReply:m];
			}
			break;
		}
		case 368:
		case 349:
			inChanBanList = NO;
			break;
		case 348:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];
			long long seton = [[m paramAt:4] longLongValue];
			
			if (inChanBanList && banExceptionSheet) {
				[banExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			} else {
				[self printUnknownReply:m];
			}
			break;
		}
		case 381:
			hasIRCopAccess = YES;
			[self printBoth:nil type:LINE_TYPE_REPLY text:[NSString stringWithFormat:TXTLS(@"IRC_USER_HAS_GOOD_LIFE"), m.sender.nick]];
			break;
		case 328:
		{
			NSString *chname = [m paramAt:1];
			NSString *website = [m paramAt:2];
			
			IRCChannel *c = [self findChannel:chname];
			if (c && website) {
				[self printBoth:c ?: (id)chname type:LINE_TYPE_WEBSITE text:[NSString stringWithFormat:TXTLS(@"IRC_CHANNEL_HAS_WEBSITE"), website]];
			}
			
			break;
		}
		case 369:
			inWhoWasRequest = NO;
			[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:[m sequence]];
			break;
		default:
			if ([world.bundlesForServerInput objectForKey:[NSString stringWithInteger:m.numericReply]]) break;
			
			[self printUnknownReply:m];
			break;
	}
}

- (void)receiveErrorNumericReply:(IRCMessage *)m
{
	NSInteger n = m.numericReply;
	
	switch (n) {
		case 401:	// ERR_NOSUCHNICK
		{
			NSString *nick = [m paramAt:1];
			
			IRCChannel *c = [self findChannel:nick];
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
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_HAD_RAW_ERROR"), m.numericReply, [m sequence:1]];
			[self printBoth:[world selectedChannelOn:self] type:LINE_TYPE_REPLY text:text];
			return;
			break;
		}
		case 404:	// ERR_CANNOTSENDMESSAGE
		{
			NSString *chname = [m paramAt:1];
			NSString *text = [NSString stringWithFormat:TXTLS(@"IRC_HAD_RAW_ERROR"), m.numericReply, [m sequence:2]];
			
			[self printBoth:[self findChannel:chname] type:LINE_TYPE_REPLY text:text];
			
			return;
			break;
		}
	}
	
	[self printErrorReply:m];
}

- (void)receiveNickCollisionError:(IRCMessage *)m
{
	if (config.altNicks.count && !isLoggedIn) {
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
				NSMutableString *s = [[head mutableCopy] autorelease];
				
				for (NSInteger i = (isupport.nickLen - s.length); i > 0; --i) {
					[s appendString:@"_"];
				}
				
				[sentNick release];
				sentNick = [s retain];
				
				break;
			}
		}
		
		if (!found) {
			[sentNick release];
			sentNick = @"0";
		}
	} else {
		[sentNick autorelease];
		sentNick = [[sentNick stringByAppendingString:@"_"] retain];
	}
	
	[self send:IRCCI_NICK, sentNick, nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)changeStateOff
{
	if (!isLoggedIn && !isConnecting) return;
	
	BOOL prevConnected = isConnected;
	
	[conn autorelease];
	conn = nil;
	
	[self clearCommandQueue];
	[self stopRetryTimer];
	[self stopISONTimer];
	
	if (reconnectEnabled) {
		[self startReconnectTimer];
	}
	
	isConnecting = isConnected = isLoggedIn = isQuitting = NO;
	[myNick release];
	myNick = @"";
	[sentNick release];
	sentNick = @"";
	
	tryingNickNumber = -1;
	hasIRCopAccess = NO;
	
	NSString *disconnectTXTLString = nil;
	
	switch (disconnectType) {
		case DISCONNECT_NORMAL:
			disconnectTXTLString = @"IRC_DISCONNECTED_FROM_SERVER";
			break;
		case DISCONNECT_TRIAL_PERIOD:
			disconnectTXTLString = @"TRIAL_BUILD_NETWORK_DISCONNECTED";
			break;
		default:
			break;
	}
	
	if (disconnectTXTLString) {
		for (IRCChannel *c in channels) {
			if (c.isActive) {
				[c deactivate];
				[self printSystem:c text:TXTLS(disconnectTXTLString)];
			}
		}
		
		[self printSystemBoth:nil text:TXTLS(disconnectTXTLString)];
	}
	
#ifdef IS_TRIAL_BINARY
	[self stopTrialPeriodTimer];
#endif
	
	[self updateClientTitle];
	[self reloadTree];
	
	if (prevConnected) {
		if (disconnectType == DISCONNECT_NORMAL ||
			disconnectType == DISCONNECT_TRIAL_PERIOD) {
			
			[self notifyEvent:GROWL_DISCONNECT];
		}
	}
	
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
	
	if (!inputNick.length) {
		[inputNick autorelease];
		inputNick = [config.nick retain];
	}
	
	[sentNick autorelease];
	[myNick autorelease];
	sentNick = [inputNick retain];
	myNick = [inputNick retain];
	
	[isupport reset];
	
	NSInteger modeParam = config.invisibleMode ? 8 : 0;
	
	NSString *user = config.username;
	NSString *realName = config.realName;
	if (!user.length) user = config.nick;
	if (!realName.length) realName = config.nick;
	
	if (config.password.length) [self send:IRCCI_PASS, config.password, nil];
	[self send:IRCCI_NICK, sentNick, nil];
	[self send:IRCCI_USER, user, [NSString stringWithDouble:modeParam], @"*", realName, nil];
	
	[self updateClientTitle];
}

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender
{
	[self changeStateOff];
}

- (void)ircConnectionDidError:(NSString *)error
{
	if (disconnectType == DISCONNECT_BAD_SSL_CERT) {
		[self connect:CONNECT_BADSSL_CRT_RECONNECT];
	} else {
		[self printError:error];
	}
}

- (void)ircConnectionDidReceive:(NSData *)data
{
	NSStringEncoding enc = encoding;
	if (encoding == NSUTF8StringEncoding && config.fallbackEncoding != NSUTF8StringEncoding && ![data isValidUTF8]) {
		enc = config.fallbackEncoding;
	}
	
	if (encoding == NSISO2022JPStringEncoding) {
		data = [data convertKanaFromNativeToISO2022];
	}
	
	NSString *s = [[[NSString alloc] initWithData:data encoding:enc] autorelease];
	if (!s) {
		s = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
		if (!s) return;
	}
	
	world.messagesReceived++;
	world.bandwidthIn += [s length];
	
	if (rawModeEnabled) {
		NSLog(@" >> %@", s);
	}
	
	if ([Preferences removeAllFormatting]) {
		NSMutableString *t = [[s mutableCopy] autorelease];
		s = [t stripEffects];
	}
	
	IRCMessage *m = [[[IRCMessage alloc] initWithLine:s] autorelease];
	NSString *cmd = m.command;
	
	if (m.numericReply != 1 && [config.server length] < 1) {
		if ([m.sender.nick contains:@"."]) {
			[config setServer:m.sender.nick];
			[world updateTitle];
		}
	}
	
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
				[world updateTitle];
				break;
			case 8: // Command: KICK
				[self receiveKick:m];
				[world updateTitle];
				break;
			case 9: // Command: KILL
				[self receiveKill:m];
				[world updateTitle];
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
				[world updateTitle];
				break;
			case 17: // Command: PING
				[self receivePing:m];
				break;
			case 20: // Command: QUIT
				[self receiveQuit:m];
				[world updateTitle];
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
				[m.params insertObject:m.sender.nick atIndex:0];
				
				NSString *text = [m.params safeObjectAtIndex:1];
				
				[m.params safeRemoveObjectAtIndex:1];
				[m.params insertObject:[NSString stringWithFormat:@"[%@]: %@", m.command, text] atIndex:1];
				
				m.command = IRCCI_NOTICE;
				
				[self receivePrivmsgAndNotice:m];
				break;
		}
	}
	
	if ([[world bundlesForServerInput] objectForKey:cmd]) {
		[[self invokeInBackgroundThread] processBundlesServerMessage:m];
	}
}

- (void)ircConnectionWillSend:(NSString *)line
{
}

#pragma mark -
#pragma mark Init

+ (void)load
{
	if (self != [IRCClient class]) return;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	dateTimeFormatter = [NSDateFormatter new];
	[dateTimeFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateTimeFormatter setTimeStyle:NSDateFormatterLongStyle];
	
	[pool drain];
}

@end