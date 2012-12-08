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

#import "TextualApplication.h"

#import <arpa/inet.h>
#import <mach/mach_time.h>

#import <BlowfishEncryption/BlowfishEncryption.h>

#define _timeoutInterval			360
#define _pingInterval				270
#define _retryInterval				240
#define _reconnectInterval			20
#define _isonCheckIntervalL			30
#define _autojoinDelayInterval		2
#define _pongCheckInterval			30

#ifdef TEXTUAL_TRIAL_BINARY
#define _trialPeriodInterval		7200
#endif

static NSDateFormatter *dateTimeFormatter = nil;

@implementation IRCClient

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if ((self = [super init])) {
		self.tryingNickNumber	= -1;
		self.capPaused			=  0;

		self.isAway				= NO;
		self.userhostInNames	= NO;
		self.multiPrefix		= NO;
		self.identifyMsg		= NO;
		self.identifyCTCP		= NO;
		self.hasIRCopAccess		= NO;

		self.channels		= [NSMutableArray new];
		self.highlights		= [NSMutableArray new];
		self.commandQueue	= [NSMutableArray new];
		self.acceptedCaps	= [NSMutableArray new];
		self.pendingCaps	= [NSMutableArray new];

		self.trackedUsers	= [NSMutableDictionary new];

		self.isupport = [IRCISupportInfo new];

		self.reconnectTimer				= [TLOTimer new];
		self.reconnectTimer.delegate	= self;
		self.reconnectTimer.reqeat		= NO;
		self.reconnectTimer.selector	= @selector(onReconnectTimer:);

		self.retryTimer				= [TLOTimer new];
		self.retryTimer.delegate	= self;
		self.retryTimer.reqeat		= NO;
		self.retryTimer.selector	= @selector(onRetryTimer:);

		self.autoJoinTimer				= [TLOTimer new];
		self.autoJoinTimer.delegate		= self;
		self.autoJoinTimer.reqeat		= YES;
		self.autoJoinTimer.selector		= @selector(onAutoJoinTimer:);

		self.commandQueueTimer				= [TLOTimer new];
		self.commandQueueTimer.delegate		= self;
		self.commandQueueTimer.reqeat		= NO;
		self.commandQueueTimer.selector		= @selector(onCommandQueueTimer:);

		self.pongTimer				= [TLOTimer new];
		self.pongTimer.delegate		= self;
		self.pongTimer.reqeat		= YES;
		self.pongTimer.selector		= @selector(onPongTimer:);

		self.isonTimer				= [TLOTimer new];
		self.isonTimer.delegate		= self;
		self.isonTimer.reqeat		= YES;
		self.isonTimer.selector		= @selector(onISONTimer:);

#ifdef TEXTUAL_TRIAL_BINARY
		self.trialPeriodTimer				= [TLOTimer new];
		self.trialPeriodTimer.delegate		= self;
		self.trialPeriodTimer.reqeat		= NO;
		self.trialPeriodTimer.selector		= @selector(onTrialPeriodTimer:);
#endif
	}

	return self;
}

- (void)dealloc
{
	[self.autoJoinTimer		stop];
	[self.commandQueueTimer stop];
	[self.isonTimer			stop];
	[self.pongTimer			stop];
	[self.reconnectTimer	stop];
	[self.retryTimer		stop];

	[self.conn close];

#ifdef TEXTUAL_TRIAL_BINARY
	[self.trialPeriodTimer stop];
#endif

}

- (void)setup:(IRCClientConfig *)seed
{
	self.config = [seed mutableCopy];
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	self.config = nil;
	self.config = [seed mutableCopy];

	NSArray *chans = self.config.channels;

	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannelConfig *i in chans) {
		IRCChannel *c = [self findChannel:i.name];

		if (c) {
			[c updateConfig:i];

			[ary safeAddObject:c];

			[self.channels removeObjectIdenticalTo:c];
		} else {
			c = [self.world createChannel:i client:self reload:NO adjust:NO];

			[ary safeAddObject:c];
		}
	}

	for (IRCChannel *c in self.channels) {
		if (c.isChannel) {
			[self partChannel:c];
		} else {
			[ary safeAddObject:c];
		}
	}

	[self.channels removeAllObjects];
	[self.channels addObjectsFromArray:ary];

	[self.config.channels removeAllObjects];

	[self.world reloadTree];
	[self.world adjustSelection];
}

- (IRCClientConfig *)storedConfig
{
	IRCClientConfig *u = [self.config mutableCopy];

	[u.channels removeAllObjects];

	for (IRCChannel *c in self.channels) {
		if (c.isChannel) {
			[u.channels safeAddObject:[c.config mutableCopy]];
		}
	}

	return u;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [self.config dictionaryValue];

	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannel *c in self.channels) {
		if (c.isChannel) {
			[ary safeAddObject:[c dictionaryValue]];
		}
	}

	dic[@"channelList"] = ary;

	return dic;
}

#pragma mark -
#pragma mark Properties

- (NSString *)name
{
	return self.config.name;
}

- (BOOL)IRCopStatus
{
	return self.hasIRCopAccess;
}

- (BOOL)isNewTalk
{
	return NO;
}

- (BOOL)isReconnecting
{
	return (self.reconnectTimer && self.reconnectTimer.isActive);
}

#pragma mark -
#pragma mark User Tracking

- (void)handleUserTrackingNotification:(IRCAddressBook *)ignoreItem
							  nickname:(NSString *)nick
							  hostmask:(NSString *)host
							  langitem:(NSString *)localKey
{
	if ([ignoreItem notifyJoins] == YES) {
		NSString *text = TXTFLS(localKey, host, ignoreItem.hostmask);

		[self notifyEvent:TXNotificationAddressBookMatchType
				 lineType:TVCLogLineNoticeType
				   target:nil
					 nick:nick
					 text:text];
	}
}

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores
{
	if (self.hasIRCopAccess) return;
	if (self.isLoggedIn == NO) return;

	if (PointerIsEmpty(self.trackedUsers)) {
		self.trackedUsers = [NSMutableDictionary new];
	}

	if (NSObjectIsNotEmpty(self.trackedUsers)) {
		NSMutableDictionary *oldEntries = [NSMutableDictionary dictionary];
		NSMutableDictionary *newEntries = [NSMutableDictionary dictionary];

		for (NSString *lname in self.trackedUsers) {
			oldEntries[lname] = (self.trackedUsers)[lname];
		}

		for (IRCAddressBook *g in ignores) {
			if (g.notifyJoins) {
				NSString *lname = [g trackingNickname];

				if ([lname isNickname]) {
					if ([oldEntries containsKeyIgnoringCase:lname]) {
						newEntries[lname] = oldEntries[lname];
					} else {
						[newEntries setBool:NO forKey:lname];
					}
				}
			}
		}

		self.trackedUsers = newEntries;
	} else {
		for (IRCAddressBook *g in ignores) {
			if (g.notifyJoins) {
				NSString *lname = [g trackingNickname];

				if ([lname isNickname]) {
					[self.trackedUsers setBool:NO forKey:[g trackingNickname]];
				}
			}
		}
	}

	if (NSObjectIsNotEmpty(self.trackedUsers)) {
		[self performSelector:@selector(startISONTimer)];
	} else {
		[self performSelector:@selector(stopISONTimer)];
	}
}

- (void)startISONTimer
{
	if (self.isonTimer.isActive) return;

	[self.isonTimer start:_isonCheckIntervalL];
}

- (void)stopISONTimer
{
	[self.isonTimer stop];

	[self.trackedUsers removeAllObjects];
}

- (void)onISONTimer:(id)sender
{
	if (self.isLoggedIn) {
		if (NSObjectIsEmpty(self.trackedUsers) || self.hasIRCopAccess) {
			return [self stopISONTimer];
		}

		NSMutableString *userstr = [NSMutableString string];

		for (NSString *name in self.trackedUsers) {
			[userstr appendFormat:@" %@", name];
		}

		[self send:IRCPrivateCommandIndex("ison"), userstr, nil];
	}
}

#pragma mark -
#pragma mark Utilities

- (void)autoConnect:(NSInteger)delay
{
	_connectDelay = delay;

	[self connect];
}

- (void)terminate
{
	[self quit];
	[self closeDialogs];

	for (IRCChannel *c in self.channels) {
		[c terminate];

		[c.log terminate];
	}

	[self disconnect];
}

- (void)closeDialogs
{
	[self.channelListDialog close];
}

- (void)preferencesChanged
{
	self.log.maxLines = [TPCPreferences maxLogLines];

	for (IRCChannel *c in self.channels) {
		[c preferencesChanged];
	}
}

- (void)reloadTree
{
	[self.world reloadTree];
}

- (IRCAddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches
{
	host = [host lowercaseString];

	for (IRCAddressBook *g in self.config.ignores) {
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

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(TVCLogLineType)type
{
	if ([TPCPreferences removeAllFormatting]) {
		raw = [raw stripEffects];
	}

	NSString *rulekey = [TVCLogLine lineTypeString:type];

	NSDictionary *rules = self.world.bundlesWithOutputRules;

	if (NSObjectIsNotEmpty(rules)) {
		NSDictionary *ruleData = [rules dictionaryForKey:rulekey];

		if (NSObjectIsNotEmpty(ruleData)) {
			for (NSString *ruleRegex in ruleData) {
				if ([TLORegularExpression string:raw isMatchedByRegex:ruleRegex]) {
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
	if (PointerIsEmpty(self.chanBanListSheet)) {
		IRCClient *u = [self.world selectedClient];
		IRCChannel *c = [self.world selectedChannel];

		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;

		self.chanBanListSheet = [TDChanBanSheet new];
		self.chanBanListSheet.delegate = self;
		self.chanBanListSheet.window = self.world.window;
	} else {
		[self.chanBanListSheet ok:nil];

		self.chanBanListSheet = nil;

		[self createChanBanListDialog];

		return;
	}

	[self.chanBanListSheet show];
}

- (void)chanBanDialogOnUpdate:(TDChanBanSheet *)sender
{
    [sender.list removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), [self.world.selectedChannel name], @"+b", nil];
}

- (void)chanBanDialogWillClose:(TDChanBanSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [self.world selectedChannel].name, mode]];
        }
    }

	self.chanBanListSheet = nil;
}

#pragma mark -
#pragma mark Channel Invite Exception List Dialog

- (void)createChanInviteExceptionListDialog
{
	if (self.inviteExceptionSheet) {
		[self.inviteExceptionSheet ok:nil];

		self.inviteExceptionSheet = nil;

		[self createChanInviteExceptionListDialog];
	} else {
		IRCClient *u = [self.world selectedClient];
		IRCChannel *c = [self.world selectedChannel];

		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;

		self.inviteExceptionSheet = [TDChanInviteExceptionSheet new];
		self.inviteExceptionSheet.delegate = self;
		self.inviteExceptionSheet.window = self.world.window;
		[self.inviteExceptionSheet show];
	}
}

- (void)chanInviteExceptionDialogOnUpdate:(TDChanInviteExceptionSheet *)sender
{
    [sender.list removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), [self.world.selectedChannel name], @"+I", nil];
}

- (void)chanInviteExceptionDialogWillClose:(TDChanInviteExceptionSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [self.world selectedChannel].name, mode]];
        }
    }

	self.inviteExceptionSheet = nil;
}

#pragma mark -
#pragma mark Chan Ban Exception List Dialog

- (void)createChanBanExceptionListDialog
{
	if (PointerIsEmpty(self.banExceptionSheet)) {
		IRCClient *u = [self.world selectedClient];
		IRCChannel *c = [self.world selectedChannel];

		if (PointerIsEmpty(u) || PointerIsEmpty(c)) return;

		self.banExceptionSheet = [TDChanBanExceptionSheet new];
		self.banExceptionSheet.delegate = self;
		self.banExceptionSheet.window = self.world.window;
	} else {
		[self.banExceptionSheet ok:nil];

		self.banExceptionSheet = nil;

		[self createChanBanExceptionListDialog];

		return;
	}

	[self.banExceptionSheet show];
}

- (void)chanBanExceptionDialogOnUpdate:(TDChanBanExceptionSheet *)sender
{
    [sender.list removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), [self.world.selectedChannel name], @"+e", nil];
}

- (void)chanBanExceptionDialogWillClose:(TDChanBanExceptionSheet *)sender
{
    if (NSObjectIsNotEmpty(sender.modes)) {
        for (NSString *mode in sender.modes) {
            [self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [self.world selectedChannel].name, mode]];
        }
    }

	self.banExceptionSheet = nil;
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (void)createChannelListDialog
{
	if (PointerIsEmpty(self.channelListDialog)) {
		self.channelListDialog = [TDCListDialog new];
		self.channelListDialog.delegate = self;
		[self.channelListDialog start];
	} else {
		[self.channelListDialog show];
	}
}

- (void)listDialogOnUpdate:(TDCListDialog *)sender
{
    [sender.list removeAllObjects];

	[self sendLine:IRCPrivateCommandIndex("list")];
}

- (void)listDialogOnJoin:(TDCListDialog *)sender channel:(NSString *)channel
{
	[self joinUnlistedChannel:channel];
}

- (void)listDialogWillClose:(TDCListDialog *)sender
{
	self.channelListDialog = nil;
}

#pragma mark -
#pragma mark Timers

- (void)startPongTimer
{
	if (self.pongTimer.isActive) return;

	[self.pongTimer start:_pongCheckInterval];
}

- (void)stopPongTimer
{
	if (self.pongTimer.isActive) {
		[self.pongTimer stop];
	}
}

- (void)onPongTimer:(id)sender
{
	if (self.isConnected == NO) {
		return [self stopPongTimer];
	}

	NSInteger timeSpent = [NSDate secondsSinceUnixTimestamp:self.lastMessageReceived];
	NSInteger minsSpent = (timeSpent / 60);

	if (timeSpent >= _timeoutInterval) {
		[self printDebugInformation:TXTFLS(@"IRCDisconnectedByTimeout", minsSpent) channel:nil];

		[self disconnect];
	} else if (timeSpent >= _pingInterval) {
		[self send:IRCPrivateCommandIndex("ping"), self.config.server, nil];
	}
}

- (void)startReconnectTimer
{
	if (self.config.autoReconnect) {
		if (self.reconnectTimer.isActive) return;

		[self.reconnectTimer start:_reconnectInterval];
	}
}

- (void)stopReconnectTimer
{
	[self.reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
	[self connect:IRCNormalReconnectionMode];
}

- (void)startRetryTimer
{
	if (self.retryTimer.isActive) return;

	[self.retryTimer start:_retryInterval];
}

- (void)stopRetryTimer
{
	[self.retryTimer stop];
}

- (void)onRetryTimer:(id)sender
{
	[self disconnect];
	[self connect:IRCConnectionRetryMode];
}

- (void)startAutoJoinTimer
{
	[self.autoJoinTimer stop];
	[self.autoJoinTimer start:_autojoinDelayInterval];
}

- (void)stopAutoJoinTimer
{
	[self.autoJoinTimer stop];
}

- (void)onAutoJoinTimer:(id)sender
{
	if ([TPCPreferences autojoinWaitForNickServ] == NO || NSObjectIsEmpty(self.config.nickPassword)) {
		[self performAutoJoin];

		self.autojoinInitialized = YES;
	} else {
		if (self.serverHasNickServ) {
			if (self.autojoinInitialized) {
				[self performAutoJoin];

				self.autojoinInitialized = YES;
			}
		} else {
			[self performAutoJoin];

			self.autojoinInitialized = YES;
		}
	}

	[self.autoJoinTimer stop];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:IRCConnectNormalMode];
}

- (void)connect:(IRCConnectMode)mode
{
	[self stopReconnectTimer];

	self.connectType    = mode;
	self.disconnectType = IRCDisconnectNormalMode;

	if (self.isConnected) {
		[self.conn close];
	}

	self.isConnecting     = YES;
	self.reconnectEnabled = YES;

	NSString *host = self.config.host;

	switch (mode) {
		case IRCConnectNormalMode:
			[self printSystemBoth:nil text:TXTFLS(@"IRCIsConnecting", host, self.config.port)];
			break;
		case IRCNormalReconnectionMode:
		case IRCBadSSLCertificateReconnectMode:
			[self printSystemBoth:nil text:TXTLS(@"IRCIsReconnecting")];
			[self printSystemBoth:nil text:TXTFLS(@"IRCIsConnecting", host, self.config.port)];
			break;
		case IRCConnectionRetryMode:
			[self printSystemBoth:nil text:TXTLS(@"IRCIsRetryingConnection")];
			[self printSystemBoth:nil text:TXTFLS(@"IRCIsConnecting", host, self.config.port)];
			break;
		default: break;
	}

    if (PointerIsEmpty(self.conn)) {
        self.conn = [IRCConnection new];
		self.conn.delegate = self;
	}

	self.conn.host		= host;
	self.conn.port		= self.config.port;
	self.conn.useSSL	= self.config.useSSL;

	switch (self.config.proxyType) {
		case TXConnectionSystemSocksProxyType:
			self.conn.useSystemSocks = YES;
		case TXConnectionSocks4ProxyType:
		case TXConnectionSocks5ProxyType:
			self.conn.useSocks			= YES;
			self.conn.socksVersion		= self.config.proxyType;
			self.conn.proxyHost			= self.config.proxyHost;
			self.conn.proxyPort			= self.config.proxyPort;
			self.conn.proxyUser			= self.config.proxyUser;
			self.conn.proxyPassword		= self.config.proxyPassword;
			break;
		default: break;
	}

	[self.conn open];

	[self reloadTree];
}

- (void)disconnect
{
	if (self.conn) {
		[self.conn close];
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
	if (self.isLoggedIn == NO) {
		[self disconnect];

		return;
	}

	[self stopPongTimer];

	self.isQuitting			= YES;
	self.reconnectEnabled	= NO;

	[self.conn clearSendQueue];

	if (NSObjectIsEmpty(comment)) {
		comment = self.config.leavingComment;
	}

	[self send:IRCPrivateCommandIndex("quit"), comment, nil];

	[self performSelector:@selector(disconnect) withObject:nil afterDelay:2.0];
}

- (void)cancelReconnect
{
	[self stopReconnectTimer];
}

- (void)changeNick:(NSString *)newNick
{
	if (self.isConnected == NO) return;

	self.sentNick = newNick;

	[self send:IRCPrivateCommandIndex("nick"), newNick, nil];
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
	if (self.isLoggedIn == NO) return;

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
	[self send:IRCPrivateCommandIndex("join"), channel, password, nil];
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
	if (self.isLoggedIn == NO) return;

	if (channel.isActive == NO) return;
	if (channel.isChannel == NO) return;

	channel.status = IRCChannelParted;

	if (NSObjectIsEmpty(comment)) {
		comment = self.config.leavingComment;
	}

	[self send:IRCPrivateCommandIndex("part"), channel.name, comment, nil];
}

- (void)sendWhois:(NSString *)nick
{
	if (self.isLoggedIn == NO) return;

	[self send:IRCPrivateCommandIndex("whois"), nick, nick, nil];
}

- (void)kick:(IRCChannel *)channel target:(NSString *)nick
{
	[self send:IRCPrivateCommandIndex("kick"), channel.name, nick, [TPCPreferences defaultKickMessage], nil];
}

- (void)quickJoin:(NSArray *)chans
{
	NSMutableString *target = [NSMutableString string];
	NSMutableString *pass   = [NSMutableString string];

	for (IRCChannel *c in chans) {
		NSMutableString *prevTarget = [target mutableCopy];
		NSMutableString *prevPass   = [pass mutableCopy];

        c.status = IRCChannelJoining;

		if (NSObjectIsNotEmpty(target)) {
			[target appendString:@","];
		}

		[target appendString:c.name];

		if (NSObjectIsNotEmpty(c.password)) {
			if (NSObjectIsNotEmpty(pass)) {
				[pass appendString:@","];
			}

			[pass appendString:c.password];
		}

		NSData *targetData = [self convertToCommonEncoding:target];
		NSData *passData   = [self convertToCommonEncoding:pass];

		if ((targetData.length + passData.length) > TXMaximumIRCBodyLength) {
			if (NSObjectIsEmpty(prevTarget)) {
				if (NSObjectIsEmpty(prevPass)) {
					[self send:IRCPrivateCommandIndex("join"), prevTarget, nil];
				} else {
					[self send:IRCPrivateCommandIndex("join"), prevTarget, prevPass, nil];
				}

				[target setString:c.name];
				[pass	setString:c.password];
			} else {
				if (NSObjectIsEmpty(c.password)) {
					[self joinChannel:c];
				} else {
					[self joinChannel:c password:c.password];
				}

				[target setString:NSStringEmptyPlaceholder];
				[pass	setString:NSStringEmptyPlaceholder];
			}
		}
	}

	if (NSObjectIsNotEmpty(target)) {
		if (NSObjectIsEmpty(pass)) {
			[self send:IRCPrivateCommandIndex("join"), target, nil];
		} else {
			[self send:IRCPrivateCommandIndex("join"), target, pass, nil];
		}
	}
}

- (void)updateAutoJoinStatus
{
	self.autojoinInitialized = NO;
}

- (void)performAutoJoin
{
	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannel *c in self.channels) {
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

		if (ary.count >= [TPCPreferences autojoinMaxChannelJoins]) {
			[self quickJoin:ary];

			[ary removeAllObjects];

			pass = YES;
		}
	}

	if (NSObjectIsNotEmpty(ary)) {
		[self quickJoin:ary];
	}

    [self.world reloadTree];
}

#pragma mark -
#pragma mark Trial Period Timer

#ifdef TEXTUAL_TRIAL_BINARY

- (void)startTrialPeriodTimer
{
	if (self.trialPeriodTimer.isActive) return;

	[self.trialPeriodTimer start:_trialPeriodInterval];
}

- (void)stopTrialPeriodTimer
{
	[self.trialPeriodTimer stop];
}

- (void)onTrialPeriodTimer:(id)sender
{
	if (self.isLoggedIn) {
		self.disconnectType = IRCTrialPeriodDisconnectMode;

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
					NSString *newstr = [CSFWBlowfish encodeData:*message
															key:chan.config.encryptionKey
													   encoding:self.config.encoding];

					if ([newstr length] < 5) {
						[self printDebugInformation:TXTLS(@"BlowfishEncryptionFailed") channel:chan];

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
					NSString *newstr = [CSFWBlowfish decodeData:*message
															key:chan.config.encryptionKey
													   encoding:self.config.encoding];

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

-(void)executeTextualCmdScript:(NSDictionary *)details
{
	if ([details containsKey:@"path"] == NO) {
		return;
	}

    NSString *scriptPath = [details valueForKey:@"path"];

#ifdef TXUserScriptsFolderAvailable
	BOOL MLNonsandboxedScript = NO;

	NSString *userScriptsPath = [TPCPreferences systemUnsupervisedScriptFolderPath];

	if (NSObjectIsNotEmpty(userScriptsPath)) {
		if ([scriptPath contains:userScriptsPath]) {
			MLNonsandboxedScript = YES;
		}
	}
#endif

    if ([scriptPath hasSuffix:@".scpt"]) {
		/* /////////////////////////////////////////////////////// */
		/* Event Descriptor */
		/* /////////////////////////////////////////////////////// */

		NSAppleEventDescriptor *firstParameter	= [NSAppleEventDescriptor descriptorWithString:details[@"input"]];
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

		[event setParamDescriptor:handler		forKeyword:keyASSubroutineName];
		[event setParamDescriptor:parameters	forKeyword:keyDirectObject];

		/* /////////////////////////////////////////////////////// */
		/* Execute Event — Mountain Lion, Non-sandboxed Script */
		/* /////////////////////////////////////////////////////// */

#ifdef TXUserScriptsFolderAvailable
		if (MLNonsandboxedScript) {
			if ([TPCPreferences featureAvailableToOSXMountainLion]) {
				NSError *aserror = [NSError new];

				NSUserAppleScriptTask *applescript = [[NSUserAppleScriptTask alloc] initWithURL:[NSURL fileURLWithPath:scriptPath] error:&aserror];
				
				if (PointerIsEmpty(applescript)) {
					LogToConsole(TXTLS(@"ScriptExecutionFailure"), [aserror localizedDescription]);
				} else {
					[applescript executeWithAppleEvent:event
									 completionHandler:^(NSAppleEventDescriptor *result, NSError *error) {

										 if (PointerIsEmpty(result)) {
											 LogToConsole(TXTLS(@"ScriptExecutionFailure"), [error localizedDescription]);
										 } else {
											 NSString *finalResult = [result stringValue].trim;

											 if (NSObjectIsNotEmpty(finalResult)) {
												 [self.world.iomt inputText:finalResult command:IRCPrivateCommandIndex("privmsg")];
											 }
										 }
									 }];
				}

			}

			return;
		}
#endif

		/* /////////////////////////////////////////////////////// */
		/* Execute Event — All Other */
		/* /////////////////////////////////////////////////////// */

		NSDictionary *errors = @{};

		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errors];

        if (appleScript) {
            NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];

            if (errors && PointerIsEmpty(result)) {
                LogToConsole(TXTLS(@"ScriptExecutionFailure"), errors);
            } else {
                NSString *finalResult = [result stringValue].trim;

                if (NSObjectIsNotEmpty(finalResult)) {
                    [self.world.iomt inputText:finalResult command:IRCPrivateCommandIndex("privmsg")];
                }
            }
        } else {
            LogToConsole(TXTLS(@"ScriptExecutionFailure"), errors);
        }

    } else {
		/* /////////////////////////////////////////////////////// */
		/* Execute Shell Script */
		/* /////////////////////////////////////////////////////// */

        NSMutableArray *args  = [NSMutableArray array];

        NSString *input = [details valueForKey:@"input"];

        for (NSString *i in [input componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
            [args addObject:i];
        }

        NSTask *scriptTask = [NSTask new];
        NSPipe *outputPipe = [NSPipe pipe];

        if ([_NSFileManager() isExecutableFileAtPath:scriptPath] == NO) {
            NSArray *chmodArguments = @[@"+x", scriptPath];

			NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];

            [chmod waitUntilExit];
        }

        [scriptTask setStandardOutput:outputPipe];
        [scriptTask setLaunchPath:scriptPath];
        [scriptTask setArguments:args];

        NSFileHandle *filehandle = [outputPipe fileHandleForReading];

        [scriptTask launch];
        [scriptTask waitUntilExit];

        NSData *outputData = [filehandle readDataToEndOfFile];

		NSString *outputString  = [NSString stringWithData:outputData encoding:NSUTF8StringEncoding];

        if (NSObjectIsNotEmpty(outputString)) {
            [self.world.iomt inputText:outputString command:IRCPrivateCommandIndex("privmsg")];
        }

    }
}

- (void)processBundlesUserMessage:(NSArray *)info
{
	NSString *command = NSStringEmptyPlaceholder;
	NSString *message = [info safeObjectAtIndex:0];

	if ([info count] == 2) {
		command = [info safeObjectAtIndex:1];
		command = [command uppercaseString];
	}

	[NSBundle sendUserInputDataToBundles:self.world message:message command:command client:self];
}

- (void)processBundlesServerMessage:(IRCMessage *)msg
{
	[NSBundle sendServerInputDataToBundles:self.world client:self message:msg];
}

#pragma mark -
#pragma mark Sending Text

- (BOOL)inputText:(id)str command:(NSString *)command
{
	if (self.isConnected == NO) {
		if (NSObjectIsEmpty(str)) {
			return NO;
		}
	}

	id sel = self.world.selected;

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

	[self sendText:new command:IRCPrivateCommandIndex("privmsg") channel:[self.world selectedChannelOn:self]];
}

- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel
{
	if (NSObjectIsEmpty(str)) {
        return;
    }

	TVCLogLineType type;

	if ([command isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([command isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	} else {
		type = TVCLogLinePrivateMessageType;
	}

	if ([self.world.bundlesForUserInput containsKey:command]) {
		[self.invokeInBackgroundThread processBundlesUserMessage:@[str.string, (id)nil]];
	}

	NSArray *lines = [str performSelector:@selector(splitIntoLines)];

	for (NSAttributedString *line in lines) {
		if (NSObjectIsEmpty(line)) {
            continue;
        }

        NSMutableAttributedString *str = [line mutableCopy];

		while (NSObjectIsNotEmpty(str)) {
            NSString *newstr = [str attributedStringToASCIIFormatting:&str
															 lineType:type
															  channel:channel.name
															 hostmask:self.myHost];

			[self printBoth:channel type:type nick:self.myNick text:newstr];

			if ([self encryptOutgoingMessage:&newstr channel:channel] == NO) {
				continue;
			}

			NSString *cmd = command;

			if (type == TVCLogLineActionType) {
				cmd = IRCPrivateCommandIndex("privmsg");

				newstr = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), newstr, 0x01];
			} else if (type == TVCLogLinePrivateMessageType) {
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

	[self send:IRCPrivateCommandIndex("privmsg"), target, trail, nil];
}

- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSString *trail;

	if (NSObjectIsNotEmpty(text)) {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, command, text, 0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@%c", 0x01, command, 0x01];
	}

	[self send:IRCPrivateCommandIndex("notice"), target, trail, nil];
}

- (void)sendCTCPPing:(NSString *)target
{
	[self sendCTCPQuery:target command:IRCPrivateCommandIndex("ctcp_ping") text:[NSString stringWithFormat:@"%qu", mach_absolute_time()]];
}

- (BOOL)sendCommand:(id)str
{
	return [self sendCommand:str completeTarget:YES target:nil];
}

- (BOOL)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName
{
    NSMutableAttributedString *s = [NSMutableAttributedString alloc];

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

	IRCClient  *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];

	IRCChannel *selChannel = nil;

	if ([cmd isEqualToString:IRCPublicCommandIndex("mode")] && ([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
		// Do not complete for /mode #chname ...
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

	switch ([TPCPreferences indexOfIRCommand:cmd publicSearch:YES]) {
		case 5004: // Command: AWAY
		{
            NSString *msg = s.string;

			if (NSObjectIsEmpty(s) && cutColon == NO) {
                if (self.isAway == NO) {
                    msg = TXTLS(@"IRCAwayCommandDefaultReason");
                }
			}

			if ([TPCPreferences awayAllConnections]) {
				for (IRCClient *u in [self.world clients]) {
					if (u.isConnected == NO) continue;

					[u.client send:cmd, msg, nil];
				}
			} else {
				if (self.isConnected == NO) return NO;

				[self send:cmd, msg, nil];
			}

			return YES;
			break;
		}
		case 5030: // Command: INVITE
		{
			/* invite nick[ nick[ ...]] [channel] */

			if (NSObjectIsEmpty(s)) {
				return NO;
			}

            NSMutableArray *nicks = [NSMutableArray arrayWithArray:[s.mutableString componentsSeparatedByString:NSStringWhitespacePlaceholder]];

			if ([nicks count] && [nicks.lastObject isChannelName]) {
				targetChannelName = [nicks lastObject];

				[nicks removeLastObject];
			} else if (c) {
				targetChannelName = c.name;
			} else {
				return NO;
			}

			for (NSString *nick in nicks) {
				[self send:cmd, nick, targetChannelName, nil];
			}

			return YES;
			break;
		}
		case 5031: // Command: J
		case 5032:  // Command: JOIN
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

			[self send:IRCPrivateCommandIndex("join"), targetChannelName, s.string, nil];

			return YES;
			break;
		}
		case 5033: // Command: KICK
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
					reason = [TPCPreferences defaultKickMessage];
				}

				[self send:cmd, targetChannelName, peer, reason, nil];
			}

			return YES;
			break;
		}
		case 5035: // Command: KILL
		{
			NSString *peer = s.getToken.string;

			if (peer) {
				NSString *reason = [s.string trim];

				if (NSObjectIsEmpty(reason)) {
					reason = [TPCPreferences IRCopDefaultKillMessage];
				}

				[self send:IRCPrivateCommandIndex("kill"), peer, reason, nil];
			}

			return YES;
			break;
		}
		case 5037: // Command: LIST
		{
			if (PointerIsEmpty(self.channelListDialog)) {
				[self createChannelListDialog];
			}

			[self send:IRCPrivateCommandIndex("list"), s.string, nil];

			return YES;
			break;
		}
		case 5048: // Command: NICK
		{
			NSString *newnick = s.getToken.string;

			if ([TPCPreferences nickAllConnections]) {
				for (IRCClient *u in [self.world clients]) {
					if ([u isConnected] == NO) continue;

					[u.client changeNick:newnick];
				}
			} else {
				if (self.isConnected == NO) return NO;

				[self changeNick:newnick];
			}

			return YES;
			break;
		}
		case 5050: // Command: NOTICE
		case 5051: // Command: OMSG
		case 5052: // Command: ONOTICE
		case 5041: // Command: ME
		case 5043: // Command: MSG
		case 5064: // Command: SME
		case 5065: // Command: SMSG
		{
			BOOL opMsg      = NO;
			BOOL secretMsg  = NO;

			if ([cmd isEqualToString:IRCPublicCommandIndex("msg")]) {
				cmd = IRCPrivateCommandIndex("privmsg");
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("omsg")]) {
				opMsg = YES;

				cmd = IRCPrivateCommandIndex("privmsg");
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("onotice")]) {
				opMsg = YES;

				cmd = IRCPrivateCommandIndex("notice");
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("sme")]) {
				secretMsg = YES;

				cmd = IRCPublicCommandIndex("me");
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("smsg")]) {
				secretMsg = YES;

				cmd = IRCPrivateCommandIndex("privmsg");
			}

			if ([cmd isEqualToString:IRCPrivateCommandIndex("privmsg")] ||
				[cmd isEqualToString:IRCPrivateCommandIndex("notice")] ||
				[cmd isEqualToString:IRCPrivateCommandIndex("action")]) {

				if (opMsg) {
					if (selChannel && selChannel.isChannel && [s.string isChannelName] == NO) {
						targetChannelName = selChannel.name;
					} else {
						targetChannelName = s.getToken.string;
					}
				} else {
					targetChannelName = s.getToken.string;
				}
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("me")]) {
				cmd = IRCPrivateCommandIndex("action");

				if (selChannel) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = s.getToken.string;
				}
			}

			if ([cmd isEqualToString:IRCPrivateCommandIndex("privmsg")] ||
				[cmd isEqualToString:IRCPrivateCommandIndex("notice")]) {

				if ([s.string hasPrefix:@"\x01"]) {
					cmd = (([cmd isEqualToString:IRCPrivateCommandIndex("privmsg")]) ?
						   IRCPrivateCommandIndex("ctcp") :
						   IRCPrivateCommandIndex("ctcp_ctcpreply"));

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

			if ([cmd isEqualToString:IRCPrivateCommandIndex("ctcp")]) {
                NSMutableAttributedString *t = s.mutableCopy;

                NSString *subCommand = [t.getToken.string uppercaseString];

				if ([subCommand isEqualToString:IRCPrivateCommandIndex("action")]) {
					cmd = IRCPrivateCommandIndex("action");

					s = t;

					targetChannelName = s.getToken.string;
				} else {
					NSString *subCommand = [s.getToken.string uppercaseString];

					if (NSObjectIsNotEmpty(subCommand)) {
						targetChannelName = s.getToken.string;

						if ([subCommand isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
							[self sendCTCPPing:targetChannelName];
						} else {
							[self sendCTCPQuery:targetChannelName command:subCommand text:s.string];
						}
					}

					return YES;
				}
			}

			if ([cmd isEqualToString:IRCPrivateCommandIndex("ctcp_ctcpreply")]) {
				targetChannelName = s.getToken.string;

				NSString *subCommand = s.getToken.string;

				[self sendCTCPReply:targetChannelName command:subCommand text:s.string];

				return YES;
			}

			if ([cmd isEqualToString:IRCPrivateCommandIndex("privmsg")] ||
				[cmd isEqualToString:IRCPrivateCommandIndex("notice")] ||
				[cmd isEqualToString:IRCPrivateCommandIndex("action")]) {

				if (NSObjectIsEmpty(s))                 return NO;
				if (NSObjectIsEmpty(targetChannelName)) return NO;

				TVCLogLineType type;

				if ([cmd isEqualToString:IRCPrivateCommandIndex("notice")]) {
					type = TVCLogLineNoticeType;
				} else if ([cmd isEqualToString:IRCPrivateCommandIndex("action")]) {
					type = TVCLogLineActionType;
				} else {
					type = TVCLogLinePrivateMessageType;
				}

				while (NSObjectIsNotEmpty(s)) {
					NSArray *targets = [targetChannelName componentsSeparatedByString:@","];

                    NSString *t = [s attributedStringToASCIIFormatting:&s
															  lineType:type
															   channel:targetChannelName
															  hostmask:self.myHost];

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

						if (PointerIsEmpty(c) && secretMsg == NO && [chname isChannelName] == NO) {
							if (type == TVCLogLineNoticeType) {
								c = (id)self;
							} else {
								c = [self.world createTalk:chname client:self];
							}
						}

						if (c) {
							[self printBoth:c type:type nick:self.myNick text:t];

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

						if ([localCmd isEqualToString:IRCPrivateCommandIndex("action")]) {
							localCmd = IRCPrivateCommandIndex("privmsg");

							t = [NSString stringWithFormat:@"\x01%@ %@\x01", IRCPrivateCommandIndex("action"), t];
						}

						[self send:localCmd, chname, t, nil];

                        if (c && [TPCPreferences giveFocusOnMessage]) {
                            [self.world select:c];
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
				[self.world destroyChannel:selChannel];

				return YES;
			} else {
				targetChannelName = s.getToken.string;
			}

			if (targetChannelName) {
				NSString *reason = [s.string trim];

				if (NSObjectIsEmpty(s) && cutColon == NO) {
					reason = [self.config leavingComment];
				}

				[self partUnlistedChannel:targetChannelName withComment:reason];
			}

			return YES;
			break;
		}
		case 5057: // Command: QUIT
		{
			[self quit:s.string.trim];

			return YES;
			break;
		}
		case 5070: // Command: TOPIC
		case 5067: // Command: T
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
					[self send:IRCPrivateCommandIndex("topic"), targetChannelName, topic, nil];
				}
			}

			return YES;
			break;
		}
		case 5079: // Command: WHO
		{
			self.inWhoInfoRun = YES;

			[self send:IRCPrivateCommandIndex("who"), s.string, nil];

			return YES;
			break;
		}
		case 5080: // Command: WHOIS
		{
			NSString *peer = s.string;

			if (NSObjectIsEmpty(peer)) {
				IRCChannel *c = self.world.selectedChannel;

				if (c.isTalk) {
					peer = c.name;
				} else {
					return NO;
				}
			}

			if ([s.string contains:NSStringWhitespacePlaceholder]) {
				[self sendLine:[NSString stringWithFormat:@"%@ %@", IRCPrivateCommandIndex("whois"), peer]];
			} else {
				[self send:IRCPrivateCommandIndex("whois"), peer, peer, nil];
			}

			return YES;
			break;
		}
		case 5014: // Command: CTCP
		{
			targetChannelName = s.getToken.string;

			if (NSObjectIsNotEmpty(targetChannelName)) {
				NSString *subCommand = [s.getToken.string uppercaseString];

				if ([subCommand isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
					[self sendCTCPPing:targetChannelName];
				} else {
					[self sendCTCPQuery:targetChannelName command:subCommand text:s.string];
				}
			}

			return YES;
			break;
		}
		case 5015: // Command: CTCPREPLY
		{
			targetChannelName = s.getToken.string;

			NSString *subCommand = s.getToken.string;

			[self sendCTCPReply:targetChannelName command:subCommand text:s.string];

			return YES;
			break;
		}
		case 5005: // Command: BAN
		case 5072: // Command: UNBAN
		{
			if (c) {
				NSString *peer = s.getToken.string;

				if (peer) {
					IRCUser *user = [c findMember:peer];

					NSString *host = ((user) ? [user banMask] : peer);

					if ([cmd isEqualToString:IRCPublicCommandIndex("ban")]) {
						[self sendCommand:[NSString stringWithFormat:@"%@ +b %@", IRCPublicCommandIndex("mode"), host] completeTarget:YES target:c.name];
					} else {
						[self sendCommand:[NSString stringWithFormat:@"%@ -b %@", IRCPublicCommandIndex("mode"), host] completeTarget:YES target:c.name];
					}
				}
			}

			return YES;
			break;
		}
		case 5042: // Command: MODE
		case 5019: // Command: DEHALFOP
		case 5020: // Command: DEOP
		case 5021: // Command: DEVOICE
		case 5026: // Command: HALFOP
		case 5053: // Command: OP
		case 5076: // Command: VOICE
		case 5071: // Command: UMODE
		case 5040: // Command: M
		{
			if ([cmd isEqualToString:IRCPublicCommandIndex("m")]) {
				cmd = IRCPrivateCommandIndex("mode");
			}

			if ([cmd isEqualToString:IRCPublicCommandIndex("mode")]) {
				if (selChannel && selChannel.isChannel && [s.string isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else if (([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
					targetChannelName = s.getToken.string;
				}
			} else if ([cmd isEqualToString:IRCPublicCommandIndex("umode")]) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:NSStringWhitespacePlaceholder]	atIndex:0];
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:self.myNick]						atIndex:0];
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

					[ms appendString:NSStringWhitespacePlaceholder];
					[ms appendString:s.string];

                    [s setAttributedString:[NSAttributedString emptyStringWithBase:ms]];
				}
			}

			NSMutableString *line = [NSMutableString string];

			[line appendString:IRCPrivateCommandIndex("mode")];

			if (NSObjectIsNotEmpty(targetChannelName)) {
				[line appendString:NSStringWhitespacePlaceholder];
				[line appendString:targetChannelName];
			}

			if (NSObjectIsNotEmpty(s)) {
				[line appendString:NSStringWhitespacePlaceholder];
				[line appendString:s.string];
			}

			[self sendLine:line];

			return YES;
			break;
		}
		case 5010: // Command: CLEAR
		{
			if (c) {
				[self.world clearContentsOfChannel:c inClient:self];

				[c setDockUnreadCount:0];
				[c setTreeUnreadCount:0];
				[c setKeywordCount:0];
			} else if (u) {
				[self.world clearContentsOfClient:self];

				[u setDockUnreadCount:0];
				[u setTreeUnreadCount:0];
				[u setKeywordCount:0];
			}

			[self.world updateIcon];
			[self.world reloadTree];

			return YES;
			break;
		}
		case 5012: // Command: CLOSE
		case 5061: // Command: REMOVE
		{
			NSString *nick = s.getToken.string;

			if (NSObjectIsNotEmpty(nick)) {
				c = [self findChannel:nick];
			}

			if (c) {
				[self.world destroyChannel:c];
			}

			return YES;
			break;
		}
		case 5060: // Command: REJOIN
		case 5016: // Command: CYCLE
		case 5027: // Command: HOP
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
		case 5029: // Command: IGNORE
		case 5073: // Command: UNIGNORE
		{
			if (NSObjectIsEmpty(s)) {
				[self.world.menuController showServerPropertyDialog:self ignore:@"--"];
			} else {
				NSString *n = s.getToken.string;

				IRCUser  *u = [c findMember:n];

				if (PointerIsEmpty(u)) {
					[self.world.menuController showServerPropertyDialog:self ignore:n];

					return YES;
				}

				NSString *hostmask = [u banMask];

				IRCAddressBook *g = [IRCAddressBook new];

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

				if ([cmd isEqualToString:IRCPublicCommandIndex("ignore")]) {
					BOOL found = NO;

					for (IRCAddressBook *e in self.config.ignores) {
						if ([g.hostmask isEqualToString:e.hostmask]) {
							found = YES;

							break;
						}
					}

					if (found == NO) {
						[self.config.ignores safeAddObject:g];

						[self.world save];
					}
				} else {
					NSMutableArray *ignores = self.config.ignores;

					for (NSInteger i = (ignores.count - 1); i >= 0; --i) {
						IRCAddressBook *e = [ignores safeObjectAtIndex:i];

						if ([g.hostmask isEqualToString:e.hostmask]) {
							[ignores safeRemoveObjectAtIndex:i];

							[self.world save];

							break;
						}
					}
				}
			}

			return YES;
			break;
		}
		case 5059: // Command: RAW
		case 5058: // Command: QUOTE
		{
			[self sendLine:s.string];

			return YES;
			break;
		}
		case 5056: // Command: QUERY
		{
			NSString *nick = s.getToken.string;

			if (NSObjectIsEmpty(nick)) {
				if (c && c.isTalk) {
					[self.world destroyChannel:c];
				}
			} else {
				IRCChannel *c = [self findChannelOrCreate:nick useTalk:YES];

				[self.world select:c];
			}

			return YES;
			break;
		}
		case 5069: // Command: TIMER
		{
			NSInteger interval = [s.getToken.string integerValue];

			if (interval > 0) {
				TLOTimerCommand *cmd = [TLOTimerCommand new];

				if ([s.string hasPrefix:@"/"]) {
                    [s deleteCharactersInRange:NSMakeRange(0, 1)];
				}

				cmd.input = s.string;
				cmd.cid   = ((c) ? c.uid : -1);
				cmd.time  = (CFAbsoluteTimeGetCurrent() + interval);

				[self addCommandToCommandQueue:cmd];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"IRCTimerCommandRequiresInteger")];
			}

			return YES;
			break;
		}
		case 5078: // Command: WEIGHTS
		{
			if (c) {
				NSInteger tc = 0;

				for (IRCUser *m in c.members) {
					if (m.totalWeight > 0) {
						NSString *text = TXTFLS(@"IRCWeightsCommandResultRow", m.nick, m.incomingWeight, m.outgoingWeight, m.totalWeight);

						tc++;

						[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text];
					}
				}

				if (tc == 0) {
					[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"IRCWeightsCommandNoResults")];
				}
			}

			return YES;
			break;
		}
		case 5022: // Command: ECHO
		case 5018: // Command: DEBUG
		{
			if ([s.string isEqualNoCase:@"raw on"]) {
				self.rawModeEnabled = YES;

				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"IRCRawModeIsEnabled")];
			} else if ([s.string isEqualNoCase:@"raw off"]) {
				self.rawModeEnabled = NO;

				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"IRCRawModeIsDisabled")];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:s.string];
			}

			return YES;
			break;
		}
		case 5011: // Command: CLEARALL
		{
			[self.world.messageOperationQueue setSuspended:YES];

			if ([TPCPreferences clearAllOnlyOnActiveServer]) {
				[self.world clearContentsOfClient:self];

				for (IRCChannel *c in self.channels) {
					[self.world clearContentsOfChannel:c inClient:self];

					[c setDockUnreadCount:0];
					[c setTreeUnreadCount:0];
					[c setKeywordCount:0];
				}

				[self.world updateIcon];
				[self.world reloadTree];
				[self.world markAllAsRead:self];
			} else {
				[self.world destroyAllEvidence];
			}

			[self.world.messageOperationQueue setSuspended:NO];

			return YES;
			break;
		}
		case 5003: // Command: AMSG
		{
            [s insertAttributedString:[NSAttributedString emptyStringWithBase:@"MSG "] atIndex:0];

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *u in [self.world clients]) {
					if ([u isConnected] == NO) continue;

					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;

						[u.client sendCommand:s completeTarget:YES target:c.name];
					}
				}
			} else {
				if (self.isConnected == NO) return NO;

				for (IRCChannel *c in self.channels) {
					c.isUnread = YES;

					[self sendCommand:s completeTarget:YES target:c.name];
				}
			}

			[self reloadTree];

			return YES;
			break;
		}
		case 5002: // Command: AME
		{
            [s insertAttributedString:[NSAttributedString emptyStringWithBase:@"ME "] atIndex:0];

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *u in [self.world clients]) {
					if ([u isConnected] == NO) continue;

					for (IRCChannel *c in [u channels]) {
						c.isUnread = YES;

						[u.client sendCommand:s completeTarget:YES target:c.name];
					}
				}
			} else {
				if (self.isConnected == NO) return NO;

				for (IRCChannel *c in self.channels) {
					c.isUnread = YES;

                    [u.client sendCommand:s completeTarget:YES target:c.name];
				}
			}

			[self reloadTree];

			return YES;
			break;
		}
		case 5083: // Command: KB
		case 5034: // Command: KICKBAN
		{
			if (c) {
				NSString *peer = s.getToken.string;

				if (peer) {
					NSString *reason = [s.string trim];

					IRCUser *user = [c findMember:peer];

					NSString *host = ((user) ? [user banMask] : peer);

					if (NSObjectIsEmpty(reason)) {
						reason = [TPCPreferences defaultKickMessage];
					}

					[self send:IRCPrivateCommandIndex("mode"), c.name, @"+b", host, nil];
					[self send:IRCPrivateCommandIndex("kick"), c.name, user.nick, reason, nil];
				}
			}

			return YES;
			break;
		}
		case 5028: // Command: ICBADGE
		{
			if ([s.string contains:NSStringWhitespacePlaceholder] == NO) return NO;

			NSArray *data = [s.string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			[TVCDockIcon drawWithHilightCount:[data integerAtIndex:0]
								 messageCount:[data integerAtIndex:1]];

			return YES;
			break;
		}
		case 5062: // Command: SERVER
		{
			if (NSObjectIsNotEmpty(s)) {
				[self.world createConnection:s.string chan:nil];
			}

			return YES;
			break;
		}
		case 5013: // Command: CONN
		{
			if (NSObjectIsNotEmpty(s)) {
				[self.config setHost:s.getToken.string];
			}

			if (self.isConnected) [self quit];

			[self performSelector:@selector(connect) withObject:nil afterDelay:2.0];

			return YES;
			break;
		}
		case 5046: // Command: MYVERSION
		{
			NSString *ref  = [TPCPreferences gitBuildReference];
			NSString *name = [TPCPreferences applicationName];
			NSString *vers = [TPCPreferences textualInfoPlist][@"CFBundleVersion"];

			NSString *text = [NSString stringWithFormat:TXTLS(@"IRCCTCPVersionInfo"), name, vers,
							  ((NSObjectIsEmpty(ref)) ? TXTLS(@"Unknown") : ref),
							  [TPCPreferences textualInfoPlist][@"TXBundleBuildCodeName"]];

			if (c.isChannel == NO && c.isTalk == NO) {
				[self printDebugInformationToConsole:text];
			} else {
				text = TXTFLS(@"IRCCTCPVersionTitle", text);

				[self sendPrivmsgToSelectedChannel:text];
			}

			return YES;
			break;
		}
		case 5044: // Command: MUTE
		{
			if (self.world.soundMuted) {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"SoundIsAlreadyMuted")];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"SoundIsNowMuted")];

				[self.world setSoundMuted:YES];
			}

			return YES;
			break;
		}
		case 5075: // Command: UNMUTE
		{
			if (self.world.soundMuted) {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"SoundIsNoLongerMuted")];

				[self.world setSoundMuted:NO];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"SoundIsNotMuted")];
			}

			return YES;
			break;
		}
		case 5074: // Command: UNLOAD_PLUGINS
		{
			[NSBundle.invokeInBackgroundThread deallocBundlesFromMemory:self.world];

			return YES;
			break;
		}
		case 5038: // Command: LOAD_PLUGINS
		{
			[NSBundle.invokeInBackgroundThread loadBundlesIntoMemory:self.world];

			return YES;
			break;
		}
		case 5084: // Command: LAGCHECK
		case 5045: // Command: MYLAG
		{
			self.lastLagCheck = CFAbsoluteTimeGetCurrent();

			if ([cmd isEqualNoCase:IRCPublicCommandIndex("mylag")]) {
				self.sendLagcheckToChannel = YES;
			}

			[self sendCTCPQuery:self.myNick command:IRCPrivateCommandIndex("ctcp_lagcheck") text:[NSString stringWithDouble:self.lastLagCheck]];

			[self printDebugInformation:TXTLS(@"LagCheckRequestSentMessage")];

			return YES;
			break;
		}
		case 5082: // Command: ZLINE
		case 5023: // Command: GLINE
		case 5025: // Command: GZLINE
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
						reason = [TPCPreferences IRCopDefaultGlineMessage];

						if ([reason contains:NSStringWhitespacePlaceholder]) {
							NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

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
		case 5063:  // Command: SHUN
		case 5068: // Command: TEMPSHUN
		{
			NSString *peer = s.getToken.string;

			if ([peer hasPrefix:@"-"]) {
				[self send:cmd, peer, s.string, nil];
			} else {
				if (peer) {
					if ([cmd isEqualToString:IRCPublicCommandIndex("tempshun")]) {
						NSString *reason = s.getToken.string.trim;

						if (NSObjectIsEmpty(reason)) {
							reason = [TPCPreferences IRCopDefaultShunMessage];

							if ([reason contains:NSStringWhitespacePlaceholder]) {
								NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

								reason = [reason safeSubstringAfterIndex:spacePos];
							}
						}

						[self send:cmd, peer, reason, nil];
					} else {
						NSString *time   = s.getToken.string;
						NSString *reason = s.string.trim;

						if (NSObjectIsEmpty(reason)) {
							reason = [TPCPreferences IRCopDefaultShunMessage];

							if ([reason contains:NSStringWhitespacePlaceholder]) {
								NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

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
		case 5006: // Command: CAP
		case 5007: // Command: CAPS
		{
			if (NSObjectIsNotEmpty(self.acceptedCaps)) {
				NSString *caps = [self.acceptedCaps componentsJoinedByString:@", "];

				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTFLS(@"IRCCapCurrentlyEnbaled", caps)];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:TXTLS(@"IRCCapCurrentlyEnabledNone")];
			}

			return YES;
			break;
		}
		case 5008: // Command: CCBADGE
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

				[self.world reloadTree];
			}

			return YES;
			break;
		}
		case 5049: // Command: NNCOLORESET
		{
			if (PointerIsNotEmpty(c) && c.isChannel) {
				for (IRCUser *u in c.members) {
					u.colorNumber = -1;
				}
			}

			return YES;
			break;
		}
		case 5066: // Command: SSLCONTEXT
		{
			[self.conn.conn openSSLCertificateTrustDialog];

			return YES;
			break;
		}
		default:
		{
            NSString *command = [cmd lowercaseString];

            NSArray *extensions = @[@".scpt", @".py", @".pyc", @".rb", @".pl", @".sh", @".bash", NSStringEmptyPlaceholder];

#ifdef TXUserScriptsFolderAvailable
			NSArray *scriptPaths = @[
			NSStringNilValueSubstitute([TPCPreferences systemUnsupervisedScriptFolderPath]),
			NSStringNilValueSubstitute([TPCPreferences bundledScriptFolderPath]),
			NSStringNilValueSubstitute([TPCPreferences customScriptFolderPath])
			];
#else
			NSArray *scriptPaths = @[
			NSStringNilValueSubstitute([TPCPreferences whereScriptsPath]),
			NSStringNilValueSubstitute([TPCPreferences whereScriptsLocalPath])
			];
#endif

            NSString *scriptPath = [NSString string];

            BOOL scriptFound = NO;

			for (NSString *path in scriptPaths) {
				if (NSObjectIsEmpty(path)) {
					continue;
				}

				if (scriptFound == YES) {
					break;
				}

				for (NSString *i in extensions) {
					NSString *filename = [NSString stringWithFormat:@"%@%@", command, i];

					scriptPath  = [path stringByAppendingPathComponent:filename];
					scriptFound = [_NSFileManager() fileExistsAtPath:scriptPath];

					if (scriptFound == YES) {
						break;
					}
				}
            }

			BOOL pluginFound = BOOLValueFromObject([self.world.bundlesForUserInput objectForKey:cmd]);

			if (pluginFound && scriptFound) {
				LogToConsole(TXTLS(@"PluginCommandClashErrorMessage") ,cmd);
			} else {
				if (pluginFound) {
					[self.invokeInBackgroundThread processBundlesUserMessage:
					 @[[NSString stringWithString:s.string], cmd]];

					return YES;
				} else {
					if (scriptFound) {
                        NSDictionary *inputInfo = @{
						@"channel": NSStringNilValueSubstitute(c.name),
						@"path": scriptPath,
						@"input": s.string,
						@"completeTarget": @(completeTarget),
						@"target": NSStringNilValueSubstitute(targetChannelName)
						};

                        [self.invokeInBackgroundThread executeTextualCmdScript:inputInfo];

                        return YES;
					}
				}
			}

			if (cutColon) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:@":"] atIndex:0];
			}

			if ([s length]) {
                [s insertAttributedString:[NSAttributedString emptyStringWithBase:NSStringWhitespacePlaceholder] atIndex:0];
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
	[self.conn sendLine:str];

	if (self.rawModeEnabled) {
		LogToConsole(@"<< %@", str);
	}

	self.world.messagesSent++;
	self.world.bandwidthOut += [str length];
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

		[s appendString:NSStringWhitespacePlaceholder];

		if (i == (count - 1) && (NSObjectIsEmpty(e) || [e hasPrefix:@":"] ||
								 [e contains:NSStringWhitespacePlaceholder])) {

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
	for (IRCChannel *c in self.channels) {
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
			return [self.world createTalk:name client:self];
		} else {
			IRCChannelConfig *seed = [IRCChannelConfig new];

			seed.name = name;

			return [self.world createChannel:seed client:self reload:YES adjust:YES];
		}
	}

	return c;
}

- (NSInteger)indexOfTalkChannel
{
	NSInteger i = 0;

	for (IRCChannel *e in self.channels) {
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

	while (self.commandQueue.count) {
		TLOTimerCommand *m = [self.commandQueue safeObjectAtIndex:0];

		if (m.time <= now) {
			NSString *target = nil;

			IRCChannel *c = [self.world findChannelByClientId:self.uid channelId:m.cid];

			if (c) {
				target = c.name;
			}

			[self sendCommand:m.input completeTarget:YES target:target];

			[self.commandQueue safeRemoveObjectAtIndex:0];
		} else {
			break;
		}
	}

	if (self.commandQueue.count) {
		TLOTimerCommand *m = [self.commandQueue safeObjectAtIndex:0];

		CFAbsoluteTime delta = (m.time - CFAbsoluteTimeGetCurrent());

		[self.commandQueueTimer start:delta];
	} else {
		[self.commandQueueTimer stop];
	}
}

- (void)addCommandToCommandQueue:(TLOTimerCommand *)m
{
	BOOL added = NO;

	NSInteger i = 0;

	for (TLOTimerCommand *c in self.commandQueue) {
		if (m.time < c.time) {
			added = YES;

			[self.commandQueue safeInsertObject:m atIndex:i];

			break;
		}

		++i;
	}

	if (added == NO) {
		[self.commandQueue safeAddObject:m];
	}

	if (i == 0) {
		[self processCommandsInCommandQueue];
	}
}

- (void)clearCommandQueue
{
	[self.commandQueueTimer stop];
	[self.commandQueue removeAllObjects];
}

- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark Window Title

- (void)updateClientTitle
{
	[self.world updateClientTitle:self];
}

- (void)updateChannelTitle:(IRCChannel *)c
{
	[self.world updateChannelTitle:c];
}

#pragma mark -
#pragma mark Growl

- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([self.myNick isEqual:nick]) {
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

			if (type == TXNotificationHighlightType) {
				if (channel.config.ignoreHighlights) {
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

	[TLOSoundPlayer play:[TPCPreferences soundForEvent:type] isMuted:self.world.soundMuted];

	if ([TPCPreferences growlEnabledForEvent:type] == NO) return YES;
	if ([TPCPreferences stopGrowlOnActive] && [self.world.window isOnCurrentWorkspace]) return YES;
	if ([TPCPreferences disableWhileAwayForEvent:type] == YES && self.isAway == YES) return YES;

	NSDictionary *info = nil;

	NSString *title = chname;
	NSString *desc;

	if (ltype == TVCLogLineActionType || ltype == TVCLogLineActionNoHighlightType) {
		desc = [NSString stringWithFormat:TXNotificationDialogActionNicknameFormat, nick, text];
	} else {
		desc = [NSString stringWithFormat:TXNotificationDialogStandardNicknameFormat, nick, text];
	}

	if (channel) {
		info = @{@"client": @(self.uid), @"channel": @(channel.uid)};
	} else {
		info = @{@"client": @(self.uid)};
	}

	[self.world notifyOnGrowl:type title:title desc:desc userInfo:info];

	return YES;
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype
{
	return [self notifyEvent:type lineType:ltype target:nil nick:NSStringEmptyPlaceholder text:NSStringEmptyPlaceholder];
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(id)target nick:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}

	[TLOSoundPlayer play:[TPCPreferences soundForEvent:type] isMuted:self.world.soundMuted];

	if ([TPCPreferences growlEnabledForEvent:type] == NO) return YES;
	if ([TPCPreferences stopGrowlOnActive] && [self.world.window isOnCurrentWorkspace]) return YES;
	if ([TPCPreferences disableWhileAwayForEvent:type] == YES && self.isAway == YES) return YES;

	IRCChannel *channel = nil;

	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel *)target;

			if (channel.config.growl == NO) {
				return YES;
			}
		}
	}

	NSString *title = NSStringEmptyPlaceholder;
	NSString *desc  = NSStringEmptyPlaceholder;

	switch (type) {
		case TXNotificationConnectType:				title = self.name; break;
		case TXNotificationDisconnectType:			title = self.name; break;
		case TXNotificationAddressBookMatchType:	desc = text; break;
		case TXNotificationKickType:
		{
			title = channel.name;

			desc = TXTFLS(@"NotificationKickedMessageDescription", nick, text);

			break;
		}
		case TXNotificationInviteType:
		{
			title = self.name;

			desc = TXTFLS(@"NotificationInvitedMessageDescriptioni", nick, text);

			break;
		}
		default: return YES;
	}

	NSDictionary *info = nil;

	if (channel) {
		info = @{@"client": @(self.uid), @"channel": @(channel.uid)};
	} else {
		info = @{@"client": @(self.uid)};
	}

	[self.world notifyOnGrowl:type title:title desc:desc userInfo:info];

	return YES;
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(id)t
{
	BOOL isActiveWindow = [self.world.window isOnCurrentWorkspace];

	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([t isChannel] == YES || [t isTalk] == YES) {
			if (NSDissimilarObjects(self.world.selected, t) || isActiveWindow == NO) {
				[t setKeywordCount:([t keywordCount] + 1)];

				[self.world updateIcon];
			}
		}
	}

	if ([t isUnread] || (isActiveWindow && self.world.selected == t)) {
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
	BOOL isActiveWindow = [self.world.window isOnCurrentWorkspace];

	if ([t isUnread] || (isActiveWindow && self.world.selected == t)) {
		return;
	}

	[t setIsNewTalk:YES];

	[self reloadTree];

	if (isActiveWindow == NO) {
		[NSApp requestUserAttention:NSInformationalRequest];
	}

	[self.world updateIcon];
}

- (void)setUnreadState:(id)t
{
	BOOL isActiveWindow = [self.world.window isOnCurrentWorkspace];

	if ([t isKindOfClass:[IRCChannel class]]) {
		if ([TPCPreferences countPublicMessagesInIconBadge] == NO) {
			if ([t isTalk] == YES && [t isClient] == NO) {
				if (NSDissimilarObjects(self.world.selected, t) || isActiveWindow == NO) {
					[t setDockUnreadCount:([t dockUnreadCount] + 1)];

					[self.world updateIcon];
				}
			}
		} else {
			if (NSDissimilarObjects(self.world.selected, t) || isActiveWindow == NO) {
				[t setDockUnreadCount:([t dockUnreadCount] + 1)];

				[self.world updateIcon];
			}
		}
	}

    if (isActiveWindow == NO || (NSDissimilarObjects(self.world.selected, t) && isActiveWindow)) {
		[t setTreeUnreadCount:([t treeUnreadCount] + 1)];
	}

	if (isActiveWindow && self.world.selected == t) {
		return;
	} else {
		[t setIsUnread:YES];

		[self reloadTree];
	}
}

#pragma mark -
#pragma mark Print

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type text:(NSString *)text
{
	return [self printBoth:chan type:type nick:nil text:text];
}

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	return [self printBoth:chan type:type nick:nil text:text receivedAt:receivedAt];
}

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text
{
	return [self printBoth:chan type:type nick:nick text:text receivedAt:[NSDate date]];
}

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	return [self printChannel:chan type:type nick:nick text:text receivedAt:receivedAt];
}

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel
{
	NSString *format	= [TPCPreferences themeNicknameFormat];
	NSString *aformat	= self.world.viewTheme.other.nicknameFormat;

	if (NSObjectIsNotEmpty(aformat)) {
		format = aformat;
	}

	if (NSObjectIsEmpty(format)) {
		format = TXLogLineUndefinedNicknameFormat;
	}

    if ([format contains:@"%n"]) {
        format = [format stringByReplacingOccurrencesOfString:@"%n" withString:nick];
    }

	if ([format contains:@"%@"]) {
		if (channel && channel.isClient == NO && channel.isChannel) {
			IRCUser *m = [channel findMember:nick];

			if (m) {
				NSString *mark = [NSString stringWithChar:m.mark];

				if ([mark isEqualToString:NSStringWhitespacePlaceholder] || NSObjectIsEmpty(mark)) {
					format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSStringEmptyPlaceholder];
				} else {
					format = [format stringByReplacingOccurrencesOfString:@"%@" withString:mark];
				}
			} else {
				format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSStringEmptyPlaceholder];
			}
		} else {
			format = [format stringByReplacingOccurrencesOfString:@"%@" withString:NSStringEmptyPlaceholder];
		}
	}

	return format;
}

- (BOOL)printChannel:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text
{
	return [self printChannel:chan type:type nick:nil text:text receivedAt:[NSDate date]];
}

- (BOOL)printChannel:(id)chan type:(TVCLogLineType)type text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	return [self printChannel:chan type:type nick:nil text:text receivedAt:receivedAt];
}

- (BOOL)printAndLog:(TVCLogLine *)line withHTML:(BOOL)rawHTML
{
	BOOL result = [self.log print:line withHTML:rawHTML];

	if (self.isConnected == NO) {
		return NO;
	}

	if ([TPCPreferences logTranscript] && rawHTML == NO) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];
			self.logFile.client = self;
			self.logFile.writePlainText = YES;
			self.logFile.flatFileStructure = NO;
		}

		NSString *logstr = [self.log renderedBodyForTranscriptLog:line];

		if (NSObjectIsNotEmpty(logstr)) {
			[self.logFile writePlainTextLine:logstr];
		}
	}

	return result;
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	return [self printRawHTMLToCurrentChannel:text withTimestamp:YES receivedAt:receivedAt];
}

- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	return [self printRawHTMLToCurrentChannel:text withTimestamp:NO receivedAt:receivedAt];
}

- (BOOL)printRawHTMLToCurrentChannel:(NSString *)text withTimestamp:(BOOL)showTime receivedAt:(NSDate *)receivedAt
{
	TVCLogLine *c = [TVCLogLine new];

	IRCChannel *channel = [self.world selectedChannelOn:self];

	c.body       = text;
	c.lineType   = TVCLogLineDebugType;
	c.memberType = TVCLogMemberNormalType;

	if (showTime) {
		c.receivedAt = receivedAt;
	}

	if (channel) {
		return [channel print:c withHTML:YES];
	} else {
		return [self.log print:c withHTML:YES];
	}
}

- (BOOL)printChannel:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	if ([self outputRuleMatchedInMessage:text inChannel:chan withLineType:type] == YES) {
		return NO;
	}

	IRCChannel *channel = nil;

	TVCLogMemberType memberType = TVCLogMemberNormalType;

	NSInteger colorNumber = 0;

	NSArray *keywords     = nil;
	NSArray *excludeWords = nil;

	TVCLogLine *c = [TVCLogLine new];

	if (nick && [nick isEqualToString:self.myNick]) {
		memberType = TVCLogMemberLocalUserType;
	}

	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = chan;
	} else if ([chan isKindOfClass:[NSString class]]) {
        if (NSObjectIsNotEmpty(chan)) {
            return NO;
        }
	}

	if (type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType) {
		if (NSDissimilarObjects(memberType, TVCLogMemberLocalUserType)) {
			if (channel && channel.config.ignoreHighlights == NO) {
				keywords     = [TPCPreferences keywords];
				excludeWords = [TPCPreferences excludeWords];

				if (NSDissimilarObjects([TPCPreferences keywordMatchingMethod],
										TXNicknameHighlightRegularExpressionMatchType)) {

                    if ([TPCPreferences keywordCurrentNick]) {
                        NSMutableArray *ary = [keywords mutableCopy];

                        [ary safeInsertObject:self.myNick atIndex:0];

                        keywords = ary;
                    }
                }
			}
		}
	}

	if (type == TVCLogLineActionNoHighlightType) {
		type = TVCLogLineActionType;
	} else if (type == TVCLogLinePrivateMessageNoHighlightType) {
		type = TVCLogLinePrivateMessageType;
	}

	if (nick && channel && (type == TVCLogLinePrivateMessageType
							|| type == TVCLogLineActionType)) {
		
		IRCUser *user = [channel findMember:nick];

		if (user) {
			colorNumber = user.colorNumber;
		}
	}

	c.body			= text;
	c.nick			= nick;
	c.receivedAt	= receivedAt;

	c.lineType			= type;
	c.memberType		= memberType;
	c.nickColorNumber	= colorNumber;

	c.keywords		= keywords;
	c.excludeWords	= excludeWords;

	if (channel) {
		if ([TPCPreferences autoAddScrollbackMark]) {
			if (NSDissimilarObjects(channel, self.world.selectedChannel) ||
				[self.world.window isOnCurrentWorkspace] == NO) {

				if (channel.isUnread == NO) {
					if (type == TVCLogLinePrivateMessageType ||
						type == TVCLogLineActionType ||
						type == TVCLogLineNoticeType) {
						
						[channel.log unmark];
						[channel.log mark];
					}
				}
			}
		}

		return [channel print:c];
	} else {
		if ([TPCPreferences logTranscript]) {
			return [self printAndLog:c withHTML:NO];
		} else {
			return [self.log print:c];
		}
	}
}

- (void)printSystem:(id)channel text:(NSString *)text
{
	[self printChannel:channel type:TVCLogLineDebugType text:text receivedAt:[NSDate date]];
}

- (void)printSystem:(id)channel text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	[self printChannel:channel type:TVCLogLineDebugType text:text receivedAt:receivedAt];
}

- (void)printSystemBoth:(id)channel text:(NSString *)text
{
	[self printSystemBoth:channel text:text receivedAt:[NSDate date]];
}

- (void)printSystemBoth:(id)channel text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	[self printBoth:channel type:TVCLogLineDebugType text:text receivedAt:receivedAt];
}

- (void)printReply:(IRCMessage *)m
{
	[self printBoth:nil type:TVCLogLineDebugType text:[m sequence:1] receivedAt:m.receivedAt];
}

- (void)printUnknownReply:(IRCMessage *)m
{
	[self printBoth:nil type:TVCLogLineDebugType text:[m sequence:1] receivedAt:m.receivedAt];
}

- (void)printDebugInformation:(NSString *)m
{
	[self printDebugInformation:m channel:[self.world selectedChannelOn:self]];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[self printDebugInformation:m channel:nil];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel
{
	[self printBoth:channel type:TVCLogLineDebugType text:m];
}

- (void)printErrorReply:(IRCMessage *)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel
{
	NSString *text = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence]);

	[self printBoth:channel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
}

- (void)printError:(NSString *)error
{
	[self printBoth:nil type:TVCLogLineDebugType text:error];
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (BOOL)isActive
{
	return self.isLoggedIn;
}

- (IRCClient *)client
{
	return self;
}

- (NSInteger)numberOfChildren
{
	return self.channels.count;
}

- (id)childAtIndex:(NSInteger)index
{
	return [self.channels safeObjectAtIndex:index];
}

- (NSString *)label
{
	return [self.config.name uppercaseString];
}

#pragma mark -
#pragma mark Protocol Handlers

- (void)receivePrivmsgAndNotice:(IRCMessage *)m
{
	NSString *text = [m paramAt:1];

	if (self.identifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		text = [text safeSubstringFromIndex:1];
	} else if (self.identifyMsg && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
		text = [text safeSubstringFromIndex:1];
	}

	if ([text hasPrefix:@"\x01"]) {
		text = [text safeSubstringFromIndex:1];

		NSInteger n = [text stringPosition:@"\x01"];

		if (n >= 0) {
			text = [text safeSubstringToIndex:n];
		}

		if ([m.command isEqualToString:IRCPrivateCommandIndex("privmsg")]) {
			if ([[text uppercaseString] hasPrefix:@"ACTION "]) {
				text = [text safeSubstringFromIndex:7];

				[self receiveText:m command:IRCPrivateCommandIndex("action") text:text];
			} else {
				[self receiveCTCPQuery:m text:text];
			}
		} else {
			[self receiveCTCPReply:m text:text];
		}
	} else {
		[self receiveText:m command:m.command text:text];
	}
}

- (void)receiveText:(IRCMessage *)m command:(NSString *)cmd text:(NSString *)text
{
	NSString *anick  = m.sender.nick;
	NSString *target = [m paramAt:0];

	TVCLogLineType type = TVCLogLinePrivateMessageType;

	if ([cmd isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([cmd isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	}

	if ([target hasPrefix:@"@"]) {
		target = [target safeSubstringFromIndex:1];
	}

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
														withMatches:@[@"ignoreHighlights",
									@"ignorePMHighlights",
									@"ignoreNotices",
									@"ignorePublicMsg",
									@"ignorePrivateMsg"]];


	if ([target isChannelName]) {
		if ([ignoreChecks ignoreHighlights] == YES) {
			if (type == TVCLogLineActionType) {
				type = TVCLogLineActionNoHighlightType;
			} else if (type == TVCLogLinePrivateMessageType) {
				type = TVCLogLinePrivateMessageNoHighlightType;
			}
		}

		if (type == TVCLogLineNoticeType) {
			if ([ignoreChecks ignoreNotices] == YES) {
				return;
			}
		} else {
			if ([ignoreChecks ignorePublicMsg] == YES) {
				return;
			}
		}

		IRCChannel *c = [self findChannel:target];

		if (PointerIsEmpty(c)) {
			return;
		}

		[self decryptIncomingMessage:&text channel:c];

		if (type == TVCLogLineNoticeType) {
			[self printBoth:c type:type nick:anick text:text receivedAt:m.receivedAt];

			[self notifyText:TXNotificationChannelNoticeType lineType:type target:c nick:anick text:text];
		} else {
			BOOL highlight = [self printBoth:c type:type nick:anick text:text receivedAt:m.receivedAt];
			BOOL postevent = NO;

			if (highlight) {
				postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nick:anick text:text];

				if (postevent) {
					[self setKeywordState:c];
				}
			} else {
				postevent = [self notifyText:TXNotificationChannelMessageType lineType:type target:c nick:anick text:text];
			}

			if (postevent && (highlight || c.config.growl)) {
				[self setUnreadState:c];
			}

			if (c) {
				IRCUser *sender = [c findMember:anick];

				if (sender) {
					NSString *trimmedMyNick = [self.myNick stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]];

					if ([text stringPositionIgnoringCase:trimmedMyNick] >= 0) {
						[sender outgoingConversation];
					} else {
						[sender conversation];
					}
				}
			}
		}
	} else {
		BOOL targetOurself = [target isEqualNoCase:self.myNick];

		if ([ignoreChecks ignorePMHighlights] == YES) {
			if (type == TVCLogLineActionType) {
				type = TVCLogLineActionNoHighlightType;
			} else if (type == TVCLogLinePrivateMessageType) {
				type = TVCLogLinePrivateMessageNoHighlightType;
			}
		}

		if (targetOurself && [ignoreChecks ignorePrivateMsg]) {
			return;
		}

		if (NSObjectIsEmpty(anick)) {
			[self printBoth:nil type:type text:text receivedAt:m.receivedAt];
		} else if ([anick isNickname] == NO) {
			if (type == TVCLogLineNoticeType) {
				if (self.hasIRCopAccess) {
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
							host = [host safeSubstringToIndex:(host.length - 1)];

							ignoreChecks = [self checkIgnoreAgainstHostmask:[snick stringByAppendingFormat:@"!%@", host]
																withMatches:@[@"notifyJoins"]];

							[self handleUserTrackingNotification:ignoreChecks
														nickname:snick
														hostmask:host
														langitem:@"UserTrackingHostmaskConnected"];
						}
					} else {
						if ([TPCPreferences handleServerNotices]) {
							if ([TPCPreferences handleIRCopAlerts] && [text containsIgnoringCase:[TPCPreferences IRCopAlertMatch]]) {
								IRCChannel *c = [self.world selectedChannelOn:self];

								[self setUnreadState:c];

								[self printBoth:c type:TVCLogLineNoticeType text:text receivedAt:m.receivedAt];
							} else {
								IRCChannel *c = [self findChannelOrCreate:TXTLS(@"ServerNoticeTreeItemTitle") useTalk:YES];

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

			if (PointerIsEmpty(c) && NSDissimilarObjects(type, TVCLogLineNoticeType)) {
				if (targetOurself) {
					c = [self.world createTalk:anick client:self];
				} else {
					c = [self.world createTalk:target client:self];
				}

				newTalk = YES;
			}

			if (type == TVCLogLineNoticeType) {
				if ([ignoreChecks ignoreNotices] == YES) {
					return;
				}

				if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
					c = [self.world selectedChannelOn:self];
				}

				[self printBoth:c type:type nick:anick text:text receivedAt:m.receivedAt];

				if ([anick isEqualNoCase:@"NickServ"]) {
					if ([text hasPrefix:@"This nickname is registered"] ||
						[text hasPrefix:@"This nickname is owned by someone else"] ||
						[text hasPrefix:@"This nick is owned by someone else"])
					{
						if (NSObjectIsNotEmpty(self.config.nickPassword)) {
							if ([self.config.server hasSuffix:@"dal.net"]) {
								self.serverHasNickServ = YES;

								[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ@services.dal.net",
									[NSString stringWithFormat:@"IDENTIFY %@", self.config.nickPassword], nil];
							} else if (self.isIdentifiedWithSASL == NO) {
								self.serverHasNickServ = YES;
								
								[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ",
									[NSString stringWithFormat:@"IDENTIFY %@", self.config.nickPassword], nil];
							}
						}
					} else {
						if ([TPCPreferences autojoinWaitForNickServ]) {
							if ([text hasPrefix:@"You are now identified"] ||
								[text hasPrefix:@"You are already identified"] ||
								[text hasSuffix:@"you are now recognized."] ||
								[text hasPrefix:@"Password accepted"]) {

								if (self.autojoinInitialized == NO && self.serverHasNickServ) {
									self.autojoinInitialized = YES;

									[self performAutoJoin];
								}
							}
						} else {
							self.autojoinInitialized = YES;
						}
					}
				}

				if (targetOurself) {
					[self setUnreadState:c];

					[self notifyText:TXNotificationQueryNoticeType lineType:type target:c nick:anick text:text];
				}
			} else {
				BOOL highlight = [self printBoth:c type:type nick:anick text:text receivedAt:m.receivedAt];
				BOOL postevent = NO;

				if (highlight) {
					postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nick:anick text:text];

					if (postevent) {
						[self setKeywordState:c];
					}
				} else if (targetOurself) {
					if (newTalk) {
						postevent = [self notifyText:TXNotificationNewQueryType lineType:type target:c nick:anick text:text];

						if (postevent) {
							[self setNewTalkState:c];
						}
					} else {
						postevent = [self notifyText:TXNotificationQueryMessageType lineType:type target:c nick:anick text:text];
					}
				}

				if (postevent) {
					[self setUnreadState:c];
				}

				NSString *hostTopic = m.sender.raw;

				if ([hostTopic isEqualNoCase:c.topic] == NO) {
					[c		setTopic:hostTopic];
					[c.log	setTopic:hostTopic];
				}
			}
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;

	NSMutableString *s = text.mutableCopy;

	NSString *command = s.getToken.uppercaseString;

	if ([TPCPreferences replyToCTCPRequests] == NO) {
		[self printDebugInformationToConsole:TXTFLS(@"IRCCTCPRequestIgnored", command, nick)];

		return;
	}

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
														withMatches:@[@"ignoreCTCP"]];

	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("dcc")]) {
		[self printDebugInformationToConsole:TXTLS(@"DCCRequestErrorMessage")];
	} else {
		IRCChannel *target = nil;

		if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
			target = [self.world selectedChannelOn:self];
		}

		NSString *text = TXTFLS(@"IRCRecievedCTCPRequest", command, nick);

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")] == NO) {
			[self printBoth:target type:TVCLogLineCTCPType text:text receivedAt:m.receivedAt];
		}

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
			[self sendCTCPReply:nick command:command text:s];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_time")]) {
			[self sendCTCPReply:nick command:command text:[[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_version")]) {
			NSString *fakever = [TPCPreferences masqueradeCTCPVersion];

			if (NSObjectIsNotEmpty(fakever)) {
				[self sendCTCPReply:nick command:command text:fakever];
			} else {
				NSString *ref  = [TPCPreferences gitBuildReference];
				NSString *name = [TPCPreferences applicationName];
				NSString *vers = [TPCPreferences textualInfoPlist][@"CFBundleVersion"];

				NSString *text = [NSString stringWithFormat:TXTLS(@"IRCCTCPVersionInfo"), name, vers,
								  ((NSObjectIsEmpty(ref)) ? TXTLS(@"Unknown") : ref),
								  [TPCPreferences textualInfoPlist][@"TXBundleBuildCodeName"]];

				[self sendCTCPReply:nick command:command text:text];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")]) {
			[self sendCTCPReply:nick command:command text:NSStringEmptyPlaceholder];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_clientinfo")]) {
			[self sendCTCPReply:nick command:command text:TXTLS(@"IRCCTCPSupportedReplies")];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")]) {
			TXNSDouble time = CFAbsoluteTimeGetCurrent();

			if (time >= self.lastLagCheck || self.lastLagCheck == 0 || [nick isEqualNoCase:self.myNick]) {
				TXNSDouble delta = (time - self.lastLagCheck);

				NSString *rating;

				if (delta <= 0.09) {						rating = TXTLS(@"LagCheckRequestReplyRating_01");
				} else if (delta >= 0.1 && delta < 0.2) {	rating = TXTLS(@"LagCheckRequestReplyRating_02");
				} else if (delta >= 0.2 && delta < 0.5) {	rating = TXTLS(@"LagCheckRequestReplyRating_03");
				} else if (delta >= 0.5 && delta < 1.0) {	rating = TXTLS(@"LagCheckRequestReplyRating_04");
				} else if (delta >= 1.0 && delta < 2.0) {	rating = TXTLS(@"LagCheckRequestReplyRating_05");
				} else if (delta >= 2.0 && delta < 5.0) {	rating = TXTLS(@"LagCheckRequestReplyRating_06");
				} else if (delta >= 5.0 && delta < 10.0) {	rating = TXTLS(@"LagCheckRequestReplyRating_07");
				} else if (delta >= 10.0 && delta < 30.0) {	rating = TXTLS(@"LagCheckRequestReplyRating_08");
				} else if (delta >= 30.0) {					rating = TXTLS(@"LagCheckRequestReplyRating_09"); }

				text = TXTFLS(@"LagCheckRequestReplyMessage", self.config.server, delta, rating);
			} else {
				text = TXTLS(@"LagCheckRequestUnknownReply");
			}

			if (self.sendLagcheckToChannel) {
				[self sendPrivmsgToSelectedChannel:text];

				self.sendLagcheckToChannel = NO;
			} else {
				[self printDebugInformation:text];
			}

			self.lastLagCheck = 0;
		}
	}
}

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text
{
	NSString *nick = m.sender.nick;

	NSMutableString *s = text.mutableCopy;

	NSString *command = s.getToken.uppercaseString;

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
														withMatches:@[@"ignoreCTCP"]];

	if ([ignoreChecks ignoreCTCP] == YES) {
		return;
	}

	IRCChannel *c = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
		c = [self.world selectedChannelOn:self];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
		uint64_t delta = (mach_absolute_time() - [s longLongValue]);

		mach_timebase_info_data_t info;
		mach_timebase_info(&info);

		TXNSDouble nano = (1e-9 * ((TXNSDouble)info.numer / (TXNSDouble)info.denom));
		TXNSDouble seconds = ((TXNSDouble)delta * nano);

		text = TXTFLS(@"IRCRecievedCTCPPingReply", nick, command, seconds);
	} else {
		text = TXTFLS(@"IRCRecievedCTCPReply", nick, command, s);
	}

	[self printBoth:c type:TVCLogLineCTCPType text:text receivedAt:m.receivedAt];
}

- (void)requestUserHosts:(IRCChannel *)c
{
	if ([c.name isChannelName]) {
		[c setIsModeInit:YES];

		[self send:IRCPrivateCommandIndex("mode"), c.name, nil];

		if (self.userhostInNames == NO) {
			// We can skip requesting WHO, we already have this information.

			[self send:IRCPrivateCommandIndex("who"), c.name, nil, nil];
		}
	}
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSString *nick   = m.sender.nick;
	NSString *chname = [m paramAt:0];

	BOOL njoin  = NO;
	BOOL myself = [nick isEqualNoCase:self.myNick];

	if ([chname hasSuffix:@"\x07o"]) {
		njoin  = YES;

		chname = [chname safeSubstringToIndex:(chname.length - 2)];
	}

	IRCChannel *c = [self findChannelOrCreate:chname];

	if (myself) {
		[c activate];

		[self reloadTree];

		self.myHost = m.sender.raw;

		if (self.autojoinInitialized == NO && [self.autoJoinTimer isActive] == NO) {
			[self.world select:c];
            [self.world.serverList expandItem:c];
		}

		if (NSObjectIsNotEmpty(c.config.encryptionKey)) {
			[c.client printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
		}
	}

	if (PointerIsEmpty([c findMember:nick])) {
		IRCUser *u = [IRCUser new];

		u.o           = njoin;
		u.nick        = nick;
		u.username    = m.sender.user;
		u.address	  = m.sender.address;
		u.supportInfo = self.isupport;

		[c addMember:u];
	}

    IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
														withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

    if ([ignoreChecks ignoreJPQE] == YES && myself == NO) {
        return;
    }

    if (self.hasIRCopAccess == NO) {
        if ([ignoreChecks notifyJoins] == YES) {
            NSString *tracker = [ignoreChecks trackingNickname];

            BOOL ison = [self.trackedUsers boolForKey:tracker];

            if (ison == NO) {
                [self handleUserTrackingNotification:ignoreChecks
                                            nickname:m.sender.nick
                                            hostmask:[m.sender.raw hostmaskFromRawString]
                                            langitem:@"UserTrackingHostmaskNowAvailable"];

                [self.trackedUsers setBool:YES forKey:tracker];
            }
        }
    }

	if ([TPCPreferences showJoinLeave]) {
        if (c.config.ignoreJPQActivity) {
            return;
        }

		NSString *text = TXTFLS(@"IRCUserJoinedChannel", nick, m.sender.user, m.sender.address);

		[self printBoth:c type:TVCLogLineJoinType text:text receivedAt:m.receivedAt];
	}
}

- (void)receivePart:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *comment = [m paramAt:1].trim;

	IRCChannel *c = [self findChannel:chname];

	if (c) {
		if ([nick isEqualNoCase:self.myNick]) {
			[c deactivate];

			[self reloadTree];
		}

		[c removeMember:nick];

		if ([TPCPreferences showJoinLeave]) {
            if (c.config.ignoreJPQActivity) {
                return;
            }

			IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
																withMatches:@[@"ignoreJPQE"]];

			if ([ignoreChecks ignoreJPQE] == YES) {
				return;
			}

			NSString *message = TXTFLS(@"IRCUserPartedChannel", nick, m.sender.user, m.sender.address);

			if (NSObjectIsNotEmpty(comment)) {
				message = [message stringByAppendingFormat:@" (%@)", comment];
			}

			[self printBoth:c type:TVCLogLinePartType text:message receivedAt:m.receivedAt];
		}
	}
}

- (void)receiveKick:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:0];
	NSString *target = [m paramAt:1];
	NSString *comment = [m paramAt:2].trim;

	IRCChannel *c = [self findChannel:chname];

	if (c) {
		[c removeMember:target];

		if ([TPCPreferences showJoinLeave]) {
            if (c.config.ignoreJPQActivity) {
                return;
            }

			IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
																withMatches:@[@"ignoreJPQE"]];

			if ([ignoreChecks ignoreJPQE] == YES) {
				return;
			}

			NSString *message = TXTFLS(@"IRCUserKickedFromChannel", nick, target, comment);

			[self printBoth:c type:TVCLogLineKickType text:message receivedAt:m.receivedAt];
		}

		if ([target isEqualNoCase:self.myNick]) {
			[c deactivate];

			[self reloadTree];

			[self notifyEvent:TXNotificationKickType lineType:TVCLogLineKickType target:c nick:nick text:comment];

			if ([TPCPreferences rejoinOnKick] && c.errLastJoin == NO) {
				[self printDebugInformation:TXTLS(@"IRCChannelPreparingRejoinAttempt") channel:c];

				[self performSelector:@selector(_joinKickedChannel:) withObject:c afterDelay:3.0];
			}
		}
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSString *nick    = m.sender.nick;
	NSString *comment = [m paramAt:0].trim;

	BOOL myself = [nick isEqualNoCase:self.myNick];

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
														withMatches:@[@"ignoreJPQE"]];

	NSString *text = TXTFLS(@"IRCUserDisconnected", nick, m.sender.user, m.sender.address);

	if (NSObjectIsNotEmpty(comment)) {
		if ([TLORegularExpression string:comment
						isMatchedByRegex:@"^((([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)) (([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)))$"]) {

			comment = TXTFLS(@"IRCServerHadNetsplitQuitMessage", comment);
		}

		text = [text stringByAppendingFormat:@" (%@)", comment];
	}

	for (IRCChannel *c in self.channels) {
		if ([c findMember:nick]) {
			if ([TPCPreferences showJoinLeave] && c.config.ignoreJPQActivity == NO && [ignoreChecks ignoreJPQE] == NO) {
				[self printChannel:c type:TVCLogLineQuitType text:text receivedAt:m.receivedAt];
			}

			[c removeMember:nick];

			if (myself) {
				[c deactivate];
			}
		}
	}

	if (myself == NO) {
		if ([nick isEqualNoCase:self.config.nick]) {
			[self changeNick:self.config.nick];
		}
	}

	[self.world reloadTree];

	if (self.hasIRCopAccess == NO) {
		if ([ignoreChecks notifyJoins] == YES) {
			NSString *tracker = [ignoreChecks trackingNickname];

			BOOL ison = [self.trackedUsers boolForKey:tracker];

			if (ison) {
				[self.trackedUsers setBool:NO forKey:tracker];

				[self handleUserTrackingNotification:ignoreChecks
											nickname:m.sender.nick
											hostmask:[m.sender.raw hostmaskFromRawString]
											langitem:@"UserTrackingHostmaskNoLongerAvailable"];
			}
		}
	}
}

- (void)receiveKill:(IRCMessage *)m
{
	NSString *target = [m paramAt:0];

	for (IRCChannel *c in self.channels) {
		if ([c findMember:target]) {
			[c removeMember:target];
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	IRCAddressBook *ignoreChecks;

	NSString *nick   = m.sender.nick;
	NSString *toNick = [m paramAt:0];

    if ([nick isEqualToString:toNick]) {
        return;
    }

	BOOL myself = [nick isEqualNoCase:self.myNick];

	if (myself) {
		self.myNick = toNick;
	} else {
		ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.raw
											withMatches:@[@"ignoreJPQE"]];

		if (self.hasIRCopAccess == NO) {
			if ([ignoreChecks notifyJoins] == YES) {
				NSString *tracker = [ignoreChecks trackingNickname];

				BOOL ison = [self.trackedUsers boolForKey:tracker];

				if (ison) {
					[self handleUserTrackingNotification:ignoreChecks
												nickname:m.sender.nick
												hostmask:[m.sender.raw hostmaskFromRawString]
												langitem:@"UserTrackingHostmaskNoLongerAvailable"];
				} else {
					[self handleUserTrackingNotification:ignoreChecks
												nickname:m.sender.nick
												hostmask:[m.sender.raw hostmaskFromRawString]
												langitem:@"UserTrackingHostmaskNowAvailable"];
				}

				[self.trackedUsers setBool:BOOLReverseValue(ison) forKey:tracker];
			}
		}
	}

	for (IRCChannel *c in self.channels) {
		if ([c findMember:nick]) {
			if ((myself == NO && [ignoreChecks ignoreJPQE] == NO) || myself == YES) {
				NSString *text = TXTFLS(@"IRCUserChangedNickname", nick, toNick);

				[self printChannel:c type:TVCLogLineNickType text:text receivedAt:m.receivedAt];
			}

			[c renameMember:nick to:toNick];
		}
	}

	IRCChannel *c = [self findChannel:nick];

	if (c) {
		IRCChannel *t = [self findChannel:toNick];

		if (t) {
			[self.world destroyChannel:t];
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

				if (h.plus == NO && self.multiPrefix == NO) {
					performWho = YES;
				}
			}

			if (performWho) {
				[self send:IRCPrivateCommandIndex("who"), c.name, nil, nil];
			}

			[self printBoth:c type:TVCLogLineModeType text:TXTFLS(@"IRCModeSet", nick, modeStr) receivedAt:m.receivedAt];
		}
	} else {
		[self printBoth:nil type:TVCLogLineModeType text:TXTFLS(@"IRCModeSet", nick, modeStr) receivedAt:m.receivedAt];
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
		[c		setTopic:topic];
		[c.log	setTopic:topic];

		[self printBoth:c type:TVCLogLineTopicType text:TXTFLS(@"IRCChannelTopicChanged", nick, topic) receivedAt:m.receivedAt];
	}
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSString *nick = m.sender.nick;
	NSString *chname = [m paramAt:1];

	NSString *text = TXTFLS(@"IRCUserInvitedYouToJoinChannel", nick, m.sender.user, m.sender.address, chname);

	[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineInviteType text:text receivedAt:m.receivedAt];

	[self notifyEvent:TXNotificationInviteType lineType:TVCLogLineInviteType target:nil nick:nick text:chname];

	if ([TPCPreferences autoJoinOnInvite]) {
		[self joinUnlistedChannel:chname];
	}
}

- (void)receiveError:(IRCMessage *)m
{
	[self printError:m.sequence];
}

#pragma mark -
#pragma mark Server CAP

- (void)sendNextCap
{
	if (self.capPaused == NO) {
		if (self.pendingCaps && [self.pendingCaps count]) {
			NSString *cap = [self.pendingCaps lastObject];

			[self send:IRCPrivateCommandIndex("cap"), @"REQ", cap, nil];

			[self.pendingCaps removeLastObject];
		} else {
			[self send:IRCPrivateCommandIndex("cap"), @"END", nil];
		}
	}
}

- (void)pauseCap
{
	self.capPaused++;
}

- (void)resumeCap
{
	self.capPaused--;

	[self sendNextCap];
}

- (BOOL)isCapAvailable:(NSString *)cap
{
	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org
	
	return ([cap isEqualNoCase:@"identify-msg"] ||
			[cap isEqualNoCase:@"identify-ctcp"] ||
			[cap isEqualNoCase:@"multi-prefix"] ||
			[cap isEqualNoCase:@"userhost-in-names"] ||
			[cap isEqualNoCase:@"server-time"] ||
			[cap isEqualNoCase:@"znc.in/server-time"] ||
			([cap isEqualNoCase:@"sasl"] && NSObjectIsNotEmpty(self.config.nickPassword)));
}

- (void)cap:(NSString *)cap result:(BOOL)supported
{
	if (supported) {
		if ([cap isEqualNoCase:@"sasl"]) {
			self.inSASLRequest = YES;

			[self pauseCap];
			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"PLAIN", nil];
		} else if ([cap isEqualNoCase:@"userhost-in-names"]) {
			self.userhostInNames = YES;
		} else if ([cap isEqualNoCase:@"multi-prefix"]) {
			self.multiPrefix = YES;
		} else if ([cap isEqualNoCase:@"identify-msg"]) {
			self.identifyMsg = YES;
		} else if ([cap isEqualNoCase:@"identify-ctcp"]) {
			self.identifyCTCP = YES;
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

    if ([command isEqualNoCase:IRCPrivateCommandIndex("cap")]) {
        if ([base isEqualNoCase:@"LS"]) {
            NSArray *caps = [action componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            for (NSString *cap in caps) {
				if ([self isCapAvailable:cap]) {
					[self.pendingCaps addObject:cap];
				}
            }
        } else if ([base isEqualNoCase:@"ACK"]) {
			NSArray *caps = [action componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            for (NSString *cap in caps) {
				[self.acceptedCaps addObject:cap];

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
            NSData *usernameData = [self.config.nick dataUsingEncoding:self.config.encoding allowLossyConversion:YES];

            NSMutableData *authenticateData = [usernameData mutableCopy];

            [authenticateData appendBytes:"\0" length:1];
            [authenticateData appendData:usernameData];
            [authenticateData appendBytes:"\0" length:1];
            [authenticateData appendData:[self.config.nickPassword dataUsingEncoding:self.config.encoding allowLossyConversion:YES]];

            NSString *authString = [authenticateData base64EncodingWithLineLength:400];

            NSArray *authStrings = [authString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

            for (NSString *string in authStrings) {
                [self send:IRCPrivateCommandIndex("cap_authenticate"), string, nil];
            }

            if (NSObjectIsEmpty(authStrings) || [(NSString *)[authStrings lastObject] length] == 400) {
                [self send:IRCPrivateCommandIndex("cap_authenticate"), @"+", nil];
            }
        }
    }
}

- (void)receivePing:(IRCMessage *)m
{
	[self send:IRCPrivateCommandIndex("pong"), [m sequence:0], nil];
}

- (void)receiveInit:(IRCMessage *)m
{
	[self startPongTimer];
	[self stopRetryTimer];
	[self stopAutoJoinTimer];

	self.sendLagcheckToChannel = self.serverHasNickServ			= NO;
	self.isLoggedIn = self.conn.loggedIn = self.inFirstISONRun	= YES;
	self.isAway = self.isConnecting = self.hasIRCopAccess		= NO;

	self.tryingNickNumber = -1;

	[self.config setServer:m.sender.raw];
	
	self.myNick	= [m paramAt:0];

	[self notifyEvent:TXNotificationConnectType lineType:TVCLogLineDebugType];

	for (__strong NSString *s in self.config.loginCommands) {
		if ([s hasPrefix:@"/"]) {
			s = [s safeSubstringFromIndex:1];
		}

		[self sendCommand:s completeTarget:NO target:nil];
	}

	for (IRCChannel *c in self.channels) {
		if (c.isTalk) {
			[c activate];

			IRCUser *m;

			m = [IRCUser new];
			m.supportInfo = self.isupport;
			m.nick = self.myNick;
			[c addMember:m];

			m = [IRCUser new];
			m.supportInfo = self.isupport;
			m.nick = c.name;
			[c addMember:m];
		}
	}

	[self reloadTree];
	[self populateISONTrackedUsersList:self.config.ignores];

#ifdef TEXTUAL_TRIAL_BINARY
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
		case 2:
		case 3:
		case 4:
		{
			[self printReply:m];

			break;
		}
		case 5:
		{
			[self.isupport update:[m sequence:1] client:self];

			[self.config setNetwork:TXTFLS(@"IRCServerNetworkName", self.isupport.networkName)];

			[self.world updateTitle];

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
			if ([TPCPreferences displayServerMOTD]) {
				[self printReply:m];
			}

			break;
		}
		case 221:
		{
			NSString *modeStr = [m paramAt:1];

			if ([modeStr isEqualToString:@"+"]) return;

			[self printBoth:nil type:TVCLogLineDebugType text:TXTFLS(@"IRCUserHasModes", modeStr) receivedAt:m.receivedAt];

			break;
		}
		case 290:
		{
			NSString *kind = [[m paramAt:1] lowercaseString];

			if ([kind isEqualToString:@"identify-msg"]) {
				self.identifyMsg = YES;
			} else if ([kind isEqualToString:@"identify-ctcp"]) {
				self.identifyCTCP = YES;
			}

			[self printReply:m];

			break;
		}
		case 301:
		{
			NSString *nick = [m paramAt:1];
			NSString *comment = [m paramAt:2];

			IRCChannel *c = [self findChannel:nick];
			IRCChannel *sc = [self.world selectedChannelOn:self];

			NSString *text = TXTFLS(@"IRCUserIsAway", nick, comment);

			if (c) {
				[self printBoth:(id)nick type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			if (self.whoisChannel && [self.whoisChannel isEqualTo:c] == NO) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				if ([sc isEqualTo:c] == NO) {
					[self printBoth:sc type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
				}
			}

			break;
		}
		case 305:
		{
			self.isAway = NO;

			[self printUnknownReply:m];

			break;
		}
		case 306:
		{
			self.isAway = YES;

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

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 338:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
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

			self.inWhoWasRun = (m.numericReply == 314);

			if ([realname hasPrefix:@":"]) {
				realname = [realname safeSubstringFromIndex:1];
			}

			if (self.inWhoWasRun) {
				text = TXTFLS(@"IRCUserWhowasHostmask", nick, username, address, realname);
			} else {
				text = TXTFLS(@"IRCUserWhoisHostmask", nick, username, address, realname);
			}

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 312:
		{
			NSString *nick = [m paramAt:1];
			NSString *server = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];

			NSString *text = nil;

			if (self.inWhoWasRun) {
				text = TXTFLS(@"IRCUserWhowasConnectedFrom", nick, server,
							  [dateTimeFormatter stringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]]);
			} else {
				text = TXTFLS(@"IRCUserWhoisConnectedFrom", nick, server, serverInfo);
			}

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 317:
		{
			NSString *nick = [m paramAt:1];

			NSInteger idleStr = [m paramAt:2].doubleValue;
			NSInteger signOnStr = [m paramAt:3].doubleValue;

			NSString *idleTime = TXReadableTime(idleStr);
			NSString *dateFromString = [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:signOnStr]];

			NSString *text = TXTFLS(@"IRCUserWhoisUptime", nick, dateFromString, idleTime);

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 319:
		{
			NSString *nick = [m paramAt:1];
			NSString *trail = [m paramAt:2].trim;

			NSString *text = TXTFLS(@"IRCUserWhoisChannels", nick, trail);

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 318:
		{
			self.whoisChannel = nil;

			break;
		}
		case 324:
		{
			NSString *chname = [m paramAt:1];
			NSString *modeStr;

			modeStr = [m sequence:2];
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if ([modeStr isEqualToString:@"+"]) return;

			IRCChannel *c = [self findChannel:chname];

			if (c.isModeInit == NO || NSObjectIsEmpty([c.mode allModes])) {
				if (c && c.isActive) {
					[c.mode clear];
					[c.mode update:modeStr];

					c.isModeInit = YES;
				}

				[self printBoth:c type:TVCLogLineModeType text:TXTFLS(@"IRCChannelHasModes", modeStr) receivedAt:m.receivedAt];
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
				[c		setTopic:topic];
				[c.log	setTopic:topic];

				[self printBoth:c type:TVCLogLineTopicType text:TXTFLS(@"IRCChannelHasTopic", topic) receivedAt:m.receivedAt];
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
				NSString *text = [NSString stringWithFormat:TXTLS(@"IRCChannelHasTopicAuthor"), setter,
								  [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];

				[self printBoth:c type:TVCLogLineTopicType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 341:
		{
			NSString *nick = [m paramAt:1];
			NSString *chname = [m paramAt:2];

			IRCChannel *c = [self findChannel:chname];

			[self printBoth:c type:TVCLogLineDebugType text:TXTFLS(@"IRCUserInvitedToJoinChannel", nick, chname) receivedAt:m.receivedAt];

			break;
		}
		case 303:
		{
			if (self.hasIRCopAccess) {
				[self printUnknownReply:m];
			} else {
				NSArray *users = [[m sequence] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

				for (NSString *name in self.trackedUsers) {
					NSString *langkey = nil;

					BOOL ison = [self.trackedUsers boolForKey:name];

					if (ison) {
						if ([users containsObjectIgnoringCase:name] == NO) {
							if (self.inFirstISONRun == NO) {
								langkey = @"UserTrackingNicknameNoLongerAvailable";
							}

							[self.trackedUsers setBool:NO forKey:name];
						}
					} else {
						if ([users containsObjectIgnoringCase:name]) {
							langkey = ((self.inFirstISONRun) ? @"UserTrackingNicknameIsAvailable" : @"UserTrackingNicknameNowAvailable");

							[self.trackedUsers setBool:YES forKey:name];
						}
					}

					if (NSObjectIsNotEmpty(langkey)) {
						for (IRCAddressBook *g in self.config.ignores) {
							NSString *trname = [g trackingNickname];

							if ([trname isEqualNoCase:name]) {
								[self handleUserTrackingNotification:g nickname:name hostmask:name langitem:langkey];
							}
						}
					}
				}

				if (self.inFirstISONRun) {
					self.inFirstISONRun = NO;
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

			if (self.inWhoInfoRun) {
				[self printUnknownReply:m];

				self.inWhoInfoRun = NO;
			}

			break;
		}
		case 352:
		{
			NSString *chname = [m paramAt:1];

			IRCChannel *c = [self findChannel:chname];

			if (c) {
				NSString *nick		= [m paramAt:5];
				NSString *hostmask	= [m paramAt:3];
				NSString *username	= [m paramAt:2];
				NSString *fields    = [m paramAt:6];

				BOOL isIRCOp = NO;

				// fields = G|H *| chanprefixes
				// strip G or H (away status)
				fields = [fields substringFromIndex:1];

				if ([fields hasPrefix:@"*"]) {
					// The nick is an oper
					fields = [fields substringFromIndex:1];

					isIRCOp = YES;
				}

				IRCUser *u = [c findMember:nick];

				if (PointerIsEmpty(u)) {
					IRCUser *u = [IRCUser new];

					u.nick			= nick;
					u.isIRCOp		= isIRCOp;
					u.supportInfo	= self.isupport;
				}

				NSInteger i;

				for (i = 0; i < fields.length; i++) {
					NSString *prefix = [fields safeSubstringWithRange:NSMakeRange(i, 1)];

					if ([prefix isEqualTo:self.isupport.userModeQPrefix]) {
						u.q = YES;
					} else if ([prefix isEqualTo:self.isupport.userModeAPrefix]) {
						u.a = YES;
					} else if ([prefix isEqualTo:self.isupport.userModeOPrefix]) {
						u.o = YES;
					} else if ([prefix isEqualTo:self.isupport.userModeHPrefix]) {
						u.h = YES;
					} else if ([prefix isEqualTo:self.isupport.userModeVPrefix]) {
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

			if (self.inWhoInfoRun) {
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

					IRCUser *m = [IRCUser new];

					NSInteger i;

					for (i = 0; i < nick.length; i++) {
						NSString *prefix = [nick safeSubstringWithRange:NSMakeRange(i, 1)];

						if ([prefix isEqualTo:self.isupport.userModeQPrefix]) {
							m.q = YES;
						} else if ([prefix isEqualTo:self.isupport.userModeAPrefix]) {
							m.a = YES;
						} else if ([prefix isEqualTo:self.isupport.userModeOPrefix]) {
							m.o = YES;
						} else if ([prefix isEqualTo:self.isupport.userModeHPrefix]) {
							m.h = YES;
						} else if ([prefix isEqualTo:self.isupport.userModeVPrefix]) {
							m.v = YES;
						} else {
							break;
						}
					}

					nick = [nick substringFromIndex:i];

					m.nick		= [nick nicknameFromHostmask];
					m.username	= [nick identFromHostmask];
					m.address	= [nick hostFromHostmask];

					m.supportInfo = self.isupport;
					m.isMyself    = [nick isEqualNoCase:self.myNick];

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
						NSString *line = [NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), chname, m];

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
							[self send:IRCPrivateCommandIndex("topic"), chname, topic, nil];
						}
					}
				}

				if ([TPCPreferences processChannelModes]) {
					[self requestUserHosts:c];
				}
			}

			break;
		}
		case 320:
		{
			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m sequence:2]];

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 321:
		{
			if (self.channelListDialog) {
				[self.channelListDialog clear];
			}

			break;
		}
		case 322:
		{
			NSString *chname	= [m paramAt:1];
			NSString *countStr	= [m paramAt:2];
			NSString *topic		= [m sequence:3];

			if (self.channelListDialog) {
				[self.channelListDialog addChannel:chname count:[countStr integerValue] topic:topic];
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

			if (self.whoisChannel) {
				[self printBoth:self.whoisChannel type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			} else {
				[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];
			}

			break;
		}
		case 367:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];

			long long seton = [[m paramAt:4] longLongValue];

			if (self.chanBanListSheet) {
				[self.chanBanListSheet addBan:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}

			break;
		}
		case 346:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];

			long long seton = [[m paramAt:4] longLongValue];

			if (self.inviteExceptionSheet) {
				[self.inviteExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}

			break;
		}
		case 348:
		{
			NSString *mask = [m paramAt:2];
			NSString *owner = [m paramAt:3];

			long long seton = [[m paramAt:4] longLongValue];

			if (self.banExceptionSheet) {
				[self.banExceptionSheet addException:mask tset:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seton]] setby:owner];
			}

			break;
		}
		case 381:
		{
			if (self.hasIRCopAccess == NO) {
                /* If we are already an IRCOp, then we do not need to see this line again.
                 We will assume that if we are seeing it again, then it is the result of a
                 user opening two connections to a single bouncer session. */

                [self printBoth:nil type:TVCLogLineDebugType text:TXTFLS(@"IRCUserIsNowIRCOperator", m.sender.nick) receivedAt:m.receivedAt];

                self.hasIRCopAccess = YES;
            }

			break;
		}
		case 328:
		{
			NSString *chname = [m paramAt:1];
			NSString *website = [m paramAt:2];

			IRCChannel *c = [self findChannel:chname];

			if (c && website) {
				[self printBoth:c type:TVCLogLineWebsiteType text:TXTFLS(@"IRCChannelHasWebsite", website) receivedAt:m.receivedAt];
			}

			break;
		}
		case 369:
		{
			self.inWhoWasRun = NO;

			[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:[m sequence] receivedAt:m.receivedAt];

			break;
		}
        case 900:
        {
            self.isIdentifiedWithSASL = YES;

            [self printBoth:self type:TVCLogLineDebugType text:[m sequence:3] receivedAt:m.receivedAt];

            break;
        }
        case 903:
        case 904:
        case 905:
        case 906:
        case 907:
        {
            if (n == 903) { // success
                [self printBoth:self type:TVCLogLineNoticeType text:[m sequence:1] receivedAt:m.receivedAt];
            } else {
                [self printReply:m];
            }

            if (self.inSASLRequest) {
                self.inSASLRequest = NO;

                [self resumeCap];
            }

            break;
        }
		default:
		{
			if ([self.world.bundlesForServerInput containsKey:[NSString stringWithInteger:m.numericReply]]) {
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
		case 401:
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];

			if (c && c.isActive) {
				[self printErrorReply:m channel:c];

				return;
			} else {
				[self printErrorReply:m];
			}

			return;
			break;
		}
		case 433:
		case 437:
        {
			if (self.isLoggedIn) break;

			[self receiveNickCollisionError:m];

			return;
			break;
        }
		case 402:
		{
			NSString *text = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence:1]);

			[self printBoth:[self.world selectedChannelOn:self] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];

			return;
			break;
		}
		case 404:
		{
			NSString *chname = [m paramAt:1];
			NSString *text	 = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence:2]);

			[self printBoth:[self findChannel:chname] type:TVCLogLineDebugType text:text receivedAt:m.receivedAt];

			return;
			break;
		}
		case 405:
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
	if (self.config.altNicks.count && self.isLoggedIn == NO) {
		++self.tryingNickNumber;

		NSArray *altNicks = self.config.altNicks;

		if (self.tryingNickNumber < altNicks.count) {
			NSString *nick = [altNicks safeObjectAtIndex:self.tryingNickNumber];

			[self send:IRCPrivateCommandIndex("nick"), nick, nil];
		} else {
			[self tryAnotherNick];
		}
	} else {
		[self tryAnotherNick];
	}
}

- (void)tryAnotherNick
{
	if (self.sentNick.length >= self.isupport.nickLen) {
		NSString *nick = [self.sentNick safeSubstringToIndex:self.isupport.nickLen];

		BOOL found = NO;

		for (NSInteger i = (nick.length - 1); i >= 0; --i) {
			UniChar c = [nick characterAtIndex:i];

			if (NSDissimilarObjects(c, '_')) {
				found = YES;

				NSString *head = [nick safeSubstringToIndex:i];

				NSMutableString *s = [head mutableCopy];

				for (NSInteger i = (self.isupport.nickLen - s.length); i > 0; --i) {
					[s appendString:@"_"];
				}

				self.sentNick = s;

				break;
			}
		}

		if (found == NO) {
			self.sentNick = @"0";
		}
	} else {
		self.sentNick = [self.sentNick stringByAppendingString:@"_"];
	}

	[self send:IRCPrivateCommandIndex("nick"), self.sentNick, nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)changeStateOff
{
	if (self.isLoggedIn == NO && self.isConnecting == NO) return;

	BOOL prevConnected = self.isConnected;

	[self.acceptedCaps removeAllObjects];
	self.capPaused = 0;

	self.userhostInNames	= NO;
	self.multiPrefix		= NO;
	self.identifyMsg		= NO;
	self.identifyCTCP		= NO;

	self.conn = nil;

    for (IRCChannel *c in self.channels) {
        c.status = IRCChannelParted;
    }

	[self clearCommandQueue];
	[self stopRetryTimer];
	[self stopISONTimer];

	if (self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	self.sendLagcheckToChannel = self.isIdentifiedWithSASL = NO;
	self.isConnecting = self.isConnected = self.isLoggedIn = self.isQuitting = NO;
	self.hasIRCopAccess = self.serverHasNickServ = self.autojoinInitialized = NO;

	self.myNick   = NSStringEmptyPlaceholder;
	self.sentNick = NSStringEmptyPlaceholder;

	self.tryingNickNumber = -1;

	NSString *disconnectTXTLString = nil;

	switch (self.disconnectType) {
		case IRCDisconnectNormalMode:				disconnectTXTLString = @"IRCDisconnectedFromServer"; break;
        case IRCSleepModeDisconnectMode:			disconnectTXTLString = @"IRCDisconnectedBySleepMode"; break;

#ifdef TEXTUAL_TRIAL_BINARY
		case IRCTrialPeriodDisconnectMode:			disconnectTXTLString = @"IRCDisconnectedByTrialPeriodTimer"; break;
#endif

		case IRCBadSSLCertificateDisconnectMode:	disconnectTXTLString = @"IRCDisconnectedByBadSSLCertificate"; break;
		default: break;
	}

	if (disconnectTXTLString) {
		for (IRCChannel *c in self.channels) {
			if (c.isActive) {
				[c deactivate];

				[self printSystem:c text:TXTLS(disconnectTXTLString)];
			}
		}

		[self printSystemBoth:nil text:TXTLS(disconnectTXTLString)];

		if (prevConnected) {
			[self notifyEvent:TXNotificationDisconnectType lineType:TVCLogLineDebugType];
		}
	}

#ifdef TEXTUAL_TRIAL_BINARY
	[self stopTrialPeriodTimer];
#endif

	[self reloadTree];

	self.isAway = NO;
}

- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	[self startRetryTimer];
	[self printSystemBoth:nil text:TXTLS(@"IRCConnectedToServer")];

	self.isLoggedIn		= NO;
	self.isConnected	= self.reconnectEnabled = YES;

	self.sentNick = self.config.nick;
	self.myNick   = self.config.nick;

	[self.isupport reset];

	NSInteger modeParam = ((self.config.invisibleMode) ? 8 : 0);

	NSString *user		= self.config.username;
	NSString *realName	= self.config.realName;

	if (NSObjectIsEmpty(user)) {
        user = self.config.nick;
    }

	if (NSObjectIsEmpty(realName)) {
        realName = self.config.nick;
    }

    [self send:IRCPrivateCommandIndex("cap"), @"LS", nil];

	if (NSObjectIsNotEmpty(self.config.password)) {
        [self send:IRCPrivateCommandIndex("pass"), self.config.password, nil];
    }

	[self send:IRCPrivateCommandIndex("nick"), self.sentNick, nil];
	[self send:IRCPrivateCommandIndex("user"), user, [NSString stringWithDouble:modeParam], @"*", realName, nil];

	[self.world reloadTree];
}


- (void)ircBadSSLCertificateDisconnectCallback:(TLOPopupPromptReturnType)returnCode
{
	NSString *supKeyFull = [TXPopupPromptSuppressionPrefix stringByAppendingFormat:@"cert_trust_error.%@", self.config.guid];;

	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		[_NSUserDefaults() setBool:YES forKey:supKeyFull];

		self.config.isTrustedConnection = YES;

		[self connect:IRCBadSSLCertificateReconnectMode];
	}
}

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender
{
	if (self.disconnectType == IRCBadSSLCertificateDisconnectMode) {
		NSString *supkeyBack = [NSString stringWithFormat:@"cert_trust_error.%@", self.config.guid];

		if (self.config.isTrustedConnection == NO) {
			TLOPopupPrompts *prompt = [TLOPopupPrompts new];

			[prompt sheetWindowWithQuestion:self.world.window
									 target:self
									 action:@selector(ircBadSSLCertificateDisconnectCallback:)
									   body:TXTLS(@"SocketBadSSLCertificateErrorMessage")
									  title:TXTLS(@"SocketBadSSLCertificateErrorTitle")
							  defaultButton:TXTLS(@"TrustButton")
							alternateButton:TXTLS(@"CancelButton")
								otherButton:nil
							 suppressionKey:supkeyBack
							suppressionText:@"-"];
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
	self.lastMessageReceived = [NSDate epochTime];

	NSString *s = [self convertFromCommonEncoding:data];

	if (NSObjectIsEmpty(s)) {
		return;
	}

	self.world.messagesReceived++;
	self.world.bandwidthIn += [s length];

	if (self.rawModeEnabled) {
		LogToConsole(@">> %@", s);
	}

	if ([TPCPreferences removeAllFormatting]) {
		s = [s stripEffects];
	}

	IRCMessage *m = [[IRCMessage alloc] initWithLine:s];

	NSString *cmd = m.command;

	if (m.numericReply > 0) {
		[self receiveNumericReply:m];
	} else {
		NSInteger switchNumeric = [TPCPreferences indexOfIRCommand:cmd publicSearch:NO];

		switch (switchNumeric) {
			case 1016: // Command: ERROR
            {
				[self receiveError:m];
				break;
            }
			case 1018: // Command: INVITE
            {
				[self receiveInvite:m];
				break;
            }
			case 1020: // Command: JOIN
            {
				[self receiveJoin:m];
				break;
            }
			case 1021: // Command: KICK
            {
				[self receiveKick:m];
				break;
            }
			case 1022: // Command: KILL
            {
				[self receiveKill:m];
				break;
            }
			case 1026: // Command: MODE
            {
				[self receiveMode:m];
				break;
            }
			case 1029: // Command: NICK
            {
				[self receiveNick:m];
				break;
            }
			case 1030: // Command: NOTICE
			case 1035: // Command: PRIVMSG
            {
				[self receivePrivmsgAndNotice:m];
				break;
            }
			case 1031: // Command: PART
            {
				[self receivePart:m];
				break;
            }
            case 1033: // Command: PING
            {
                [self receivePing:m];
                break;
            }
            case 1036: // Command: QUIT
            {
                [self receiveQuit:m];
                break;
            }
            case 1039: // Command: TOPIC
            {
                [self receiveTopic:m];
                break;
            }
            case 1038: // Command: WALLOPS
            case 1006: // Command: CHATOPS
            case 1017: // Command: GLOBOPS
            case 1024: // Command: LOCOPS
            case 1027: // Command: NACHAT
            case 1003: // Command: ADCHAT
            {
                [m.params safeInsertObject:m.sender.nick atIndex:0];

                NSString *text = [m.params safeObjectAtIndex:1];

                [m.params safeRemoveObjectAtIndex:1];
                [m.params safeInsertObject:[NSString stringWithFormat:TXLogLineSpecialNoticeMessageFormat, m.command, text] atIndex:1];

                m.command = IRCPrivateCommandIndex("notice");

                [self receivePrivmsgAndNotice:m];

                break;
            }
            case 1005: // Command: AUTHENTICATE
            case 1004: // Command: CAP
            {
                [self receiveCapacityOrAuthenticationRequest:m];
                break;
            }
        }
    }

    if ([self.world.bundlesForServerInput containsKey:cmd]) {
        [self.invokeInBackgroundThread processBundlesServerMessage:m];
    }

    [self.world updateTitle];
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

#pragma mark -
#pragma mark Encoding

- (NSArray *)encodingDictionary
{
	return @[
		@(self.config.encoding),
		@(self.config.fallbackEncoding),
		@(NSUTF8StringEncoding),
		@(NSASCIIStringEncoding)
	];
}

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	NSArray *encodings = [self encodingDictionary];

	for (id base in encodings) {
		NSData *s = [data dataUsingEncoding:[base integerValue]];

		if (NSObjectIsNotEmpty(s)) {
			return s;
		}
	}

	// ---- //

	LogToConsole(@"NSData encode failure. (%@)", data);

	return nil;
}

- (NSString *)convertFromCommonEncoding:(NSData *)data
{
	NSArray *encodings = [self encodingDictionary];

	for (id base in encodings) {
		NSString *s = [NSString stringWithData:data encoding:[base integerValue]];

		if (NSObjectIsNotEmpty(s)) {
			return s;
		}
	}

	// ---- //

	LogToConsole(@"NSData decode failure. (%@)", data);

	return nil;
}

#pragma mark -
#pragma mark Deprecated

- (void)changeOp:(IRCChannel *)channel users:(NSArray *)inputUsers mode:(char)mode value:(BOOL)value
{
	return;
}

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified
{
	return NO;
}

- (BOOL)printBoth:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt
{
	return NO;
}

- (BOOL)printChannel:(IRCChannel *)channel type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text identified:(BOOL)identified receivedAt:(NSDate *)receivedAt
{
	return NO;
}

@end
