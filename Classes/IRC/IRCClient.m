/* ********************************************************************* 
	   _____		_			   _	___ ____   ____
	  |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
	   | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
	   | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
	   |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

/* This source file contains work that originated from the Chat Core 
 framework of the Colloquy project. The source in question is in relation
 to the handling of SASL authentication requests. The license of the 
 Chat Core project is as follows: 
 
 This document can be found mirrored at the author's website:
 <http://colloquy.info/project/browser/trunk/Resources/BSD%20License.txt>
 
 No actual copyright is presented in the license file or the actual 
 source file in which this work was obtained so the work is assumed to
 be Copyright © 2000 - 2012 the Colloquy IRC Client
 
 ------- License -------
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote
 products derived from this software without specific prior written
 permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "TextualApplication.h"

#define _isonCheckInterval			30
#define _pingInterval				270
#define _pongCheckInterval			30
#define _reconnectInterval			20
#define _retryInterval				240
#define _timeoutInterval			360
#define _trialPeriodInterval		7200

@interface IRCClient ()
/* These are all considered private. */

@property (nonatomic, strong) IRCConnection *socket;
@property (nonatomic, assign) BOOL inFirstISONRun;
@property (nonatomic, assign) BOOL sendLagcheckReplyToChannel;
@property (nonatomic, assign) BOOL timeoutWarningShownToUser;
@property (nonatomic, assign) NSInteger tryingNickNumber;
@property (nonatomic, assign) NSInteger connectionReconnectCount;
@property (nonatomic, assign) NSUInteger CAPpausedStatus;
@property (nonatomic, assign) NSTimeInterval lastLagCheck;
@property (nonatomic, strong) NSString *myHost;
@property (nonatomic, strong) NSString *myNick;
@property (nonatomic, strong) NSString *sentNick;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *trialPeriodTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, strong) Reachability *hostReachability;
@end

@implementation IRCClient

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if ((self = [super init]))
	{
		self.isupport = [IRCISupportInfo new];

		self.channels			= [NSMutableArray new];
		self.highlights			= [NSMutableArray new];
		self.commandQueue		= [NSMutableArray new];
		self.CAPacceptedCaps	= [NSMutableArray new];
		self.CAPpendingCaps		= [NSMutableArray new];

		self.trackedUsers = [NSMutableDictionary new];

		self.reconnectTimer				= [TLOTimer new];
		self.reconnectTimer.delegate	= self;
		self.reconnectTimer.reqeatTimer = NO;
		self.reconnectTimer.selector	= @selector(onReconnectTimer:);

		self.retryTimer				= [TLOTimer new];
		self.retryTimer.delegate	= self;
		self.retryTimer.reqeatTimer	= NO;
		self.retryTimer.selector	= @selector(onRetryTimer:);

		self.commandQueueTimer				= [TLOTimer new];
		self.commandQueueTimer.delegate		= self;
		self.commandQueueTimer.reqeatTimer	= NO;
		self.commandQueueTimer.selector		= @selector(onCommandQueueTimer:);

		self.pongTimer				= [TLOTimer new];
		self.pongTimer.delegate		= self;
		self.pongTimer.reqeatTimer	= YES;
		self.pongTimer.selector		= @selector(onPongTimer:);

		self.isonTimer				= [TLOTimer new];
		self.isonTimer.delegate		= self;
		self.isonTimer.reqeatTimer	= YES;
		self.isonTimer.selector		= @selector(onISONTimer:);

#ifdef TEXTUAL_TRIAL_BINARY
		self.trialPeriodTimer				= [TLOTimer new];
		self.trialPeriodTimer.delegate		= self;
		self.trialPeriodTimer.reqeatTimer	= NO;
		self.trialPeriodTimer.selector		= @selector(onTrialPeriodTimer:);
#endif
	}
	
	return self;
}

- (void)dealloc
{
	[self.isonTimer	stop];
	[self.pongTimer	stop];
	[self.retryTimer stop];
	[self.reconnectTimer stop];
	[self.commandQueueTimer stop];

	[self.socket close];

	[self destroyReachability];

#ifdef TEXTUAL_TRIAL_BINARY
	[self.trialPeriodTimer stop];
#endif
}

- (void)setup:(id)seed
{
	if (PointerIsNotEmpty(self.config)) {
		return;
	}
	
	if ([seed isKindOfClass:[NSDictionary class]]) {
		NSObjectIsEmptyAssert(seed);
		
		self.config = [[IRCClientConfig alloc] initWithDictionary:seed];
	} else if ([seed isKindOfClass:[IRCClientConfig class]]) {
		self.config = [seed mutableCopy];
	} else {
		return;
	}

	[self setupReachability];

	[self resetAllPropertyValues];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCClient [%@]: %@>", [self altNetworkName], [self networkAddress]];
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	[self updateConfig:seed fromTheCloud:NO withSelectionUpdate:YES];
}

- (void)updateConfig:(IRCClientConfig *)seed fromTheCloud:(BOOL)isCloudUpdate withSelectionUpdate:(BOOL)reloadSelection
{
	PointerIsEmptyAssert(seed);
	
	/* Ignore if we have equality. */
	if ([self.config isEqualToClientConfiguration:seed]) {
		return;
	}
	
	BOOL ignoreListChanged = (NSObjectsAreEqual(self.config.ignoreList, seed.ignoreList) == NO);
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* It is important to know this value changed before seed update. */
	BOOL syncToCloudChanged = NSDissimilarObjects(self.config.excludedFromCloudSyncing, seed.excludedFromCloudSyncing);
	
	/* Temporary store. */
	NSData *identitySSLCertificateInformation;
	
	if (isCloudUpdate) {
		/* The identity certificate cannot be stored in the cloud since it requires to
		 a reference to a local resource. Therefore, when updating from the cloud, we
		 take the value stored locally, cache it into a local variable, allow the new
		 seed to be applied, then apply that value back to the seed. This allows the 
		 user to define certificates on each machine. */
		
		if (self.config.identitySSLCertificate) {
			identitySSLCertificateInformation = self.config.identitySSLCertificate;
		}
	}
#endif
	
	/* Write all channel keychains before copying over new configuration. */
	for (IRCChannelConfig *i in [seed channelList]) {
		[i writeKeychainItemsToDisk];
	}
	
	/* Populate new seed. */
	self.config = nil;
	self.config = [seed mutableCopy];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (isCloudUpdate) {
		/* Update new, local seed with cache SSL certificate. */
		
		if (identitySSLCertificateInformation) {
			[self.config setIdentitySSLCertificate:identitySSLCertificateInformation];
			
			identitySSLCertificateInformation = nil;
		}
	}
	
	/* Maybe remove this client from deleted list (maybe). */
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if (syncToCloudChanged) {
			if (self.config.excludedFromCloudSyncing == NO) {
				[self.worldController removeClientFromListOfDeletedClients:self.config.itemUUID];
			}
		}
	}
#endif
	
	/* Begin normal operations. */
	NSArray *chans = [self.config channelList];

	NSMutableArray *ory = [self.channels mutableCopy];

	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannelConfig *i in chans) {
		IRCChannel *cinl = [self findChannel:i.channelName inList:ory];

		if (cinl) {
			[cinl updateConfig:i];

			[ary safeAddObject:cinl];

			[ory removeObjectIdenticalTo:cinl];
		} else {
			IRCChannel *cina = [self findChannel:i.channelName inList:ary];

			if (cina) {
				/* Channels are removed from self.channels here which means that
				 another pass of findChannel: will not find duplicates. So, instead,
				 we scan the new array. */

				continue; // Do not allow duplicates.
			} else {
				cinl = [self.worldController createChannel:i client:self reload:NO adjust:NO];

				[ary safeAddObject:cinl];
			}
		}
	}

	for (IRCChannel *c in ory) {
		if (c.isChannel) {
			[self partChannel:c];
		} else {
			[ary safeAddObject:c];
		}
	}

	[self.channels removeAllObjects];
	[self.channels addObjectsFromArray:ary];

	[self.config.channelList removeAllObjects];

	/* reloadItem will drop the views and reload them. We need to remember
	 the selection because of this. */
	if (reloadSelection) {
		id selectedItem = [self.worldController selectedItem];
		
		[self.worldController setTemporarilyDisablePreviousSelectionUpdates:YES];
	
		[self.masterController.serverList reloadItem:self reloadChildren:YES];

		[self.worldController select:selectedItem];
		[self.worldController adjustSelection];
		
		[self.worldController setTemporarilyDisablePreviousSelectionUpdates:NO];
	}
		
	[self.config writeKeychainItemsToDisk];
	
	[self setupReachability];
	
	if (ignoreListChanged) {
		[self updateIgnoreConfiguration:YES];
	}
}

- (IRCClientConfig *)storedConfig
{
	IRCClientConfig *u = self.config;

	[u.channelList removeAllObjects];

	for (IRCChannel *c in self.channels) {
		if (c.isChannel) {
			[u.channelList safeAddObject:[c.config mutableCopy]];
		}
	}

	return u;
}

- (void)updateIgnoreConfiguration:(BOOL)reloadUserStatus
{
	if (self == [self.worldController selectedClient]) {
		IRCChannel *selectedChannel = [self.worldController selectedChannel];
		
		if ([selectedChannel isChannel]) {
			[selectedChannel updateTableViewByRemovingIgnoredUsers];
		}
	}
	
	if (reloadUserStatus) {
		[self populateISONTrackedUsersList:self.config.ignoreList];
	}
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self dictionaryValue:NO];
}

- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary
{
	NSMutableDictionary *dic = [self.config dictionaryValue:isCloudDictionary];

	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannel *c in self.channels) {
		if (c.isChannel || [TPCPreferences rememberServerListQueryStates]) {
			[ary addObject:[c dictionaryValue]];
		}
	}

	dic[@"channelList"] = ary;
	
	return dic;
}

- (void)prepareForApplicationTermination
{
	[self quit];
	
	[self closeDialogs];
	[self closeLogFile];

	for (IRCChannel *c in self.channels) {
		[c prepareForApplicationTermination];
	}

	[self.viewController prepareForApplicationTermination];
}

- (void)prepareForPermanentDestruction
{
	[self quit];
	
	[self closeDialogs];
	[self closeLogFile];
	
	for (IRCChannel *c in self.channels) {
		[c prepareForPermanentDestruction];
	}
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)closeDialogs
{
    TXMenuController *menuController = [self menuController];

    [menuController popWindowViewIfExists:[self listDialogWindowKey]];
    [menuController popWindowSheetIfExists];
}

- (void)preferencesChanged
{
	[self reopenLogFileIfNeeded];

	[self.viewController preferencesChanged];

	for (IRCChannel *c in self.channels) {
		[c preferencesChanged];

        if (self.CAPawayNotify == NO) {
            if ([c numberOfMembers] > [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
                for (IRCUser *u in [c unsortedMemberList]) {
                    u.isAway = NO;
                }
            }
        }
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)uniqueIdentifier
{
	return [self.config itemUUID];
}

- (NSString *)name
{
	return self.config.clientName;
}

- (NSString *)networkName
{
	return self.isupport.networkName;
}

- (NSString *)altNetworkName
{
	NSObjectIsEmptyAssertReturn(self.isupport.networkName, self.config.clientName);

	return self.isupport.networkName;
}

- (NSString *)networkAddress
{
	return self.isupport.networkAddress;
}

- (NSString *)localNickname
{
	NSObjectIsEmptyAssertReturn(self.myNick, self.config.nickname);

	return self.myNick;
}

- (NSString *)localHostmask
{
	return self.myHost;
}

- (TDCFileTransferDialog *)fileTransferController
{
	return self.menuController.fileTransferController;
}

- (BOOL)isReconnecting
{
	return (self.reconnectTimer && self.reconnectTimer.timerIsActive);
}

- (NSMutableDictionary *)auxiliaryConfiguration
{
	return [self.config auxiliaryConfiguration];
}

#pragma mark -
#pragma mark Reachability

- (void)setupReachability
{
	[self destroyReachability];

	 self.hostReachability = [Reachability reachabilityWithHostname:self.config.serverAddress];
	[self.hostReachability setReachableOnWWAN:NO];

	__unsafe_unretained typeof(self) weakSelf = self;

	[self.hostReachability setReachableBlock:^(Reachability *reachability) {
		if (weakSelf) {
			[weakSelf reachabilityChanged:YES];
		}
	}];

	[self.hostReachability setUnreachableBlock:^(Reachability *reachability) {
		if (weakSelf) {
			[weakSelf reachabilityChanged:NO];
		}
	}];

	[self.hostReachability startNotifier];
}

- (void)destroyReachability
{
	PointerIsNotEmptyAssert(self.hostReachability);

	[self.hostReachability setReachableBlock:nil];
	[self.hostReachability setUnreachableBlock:nil];

	[self.hostReachability stopNotifier];
	 self.hostReachability = nil;
}

- (void)reachabilityChanged:(BOOL)reachable
{
	if (self.rawModeEnabled) {
		LogToConsole(@"%@ %@ %@", self.config.serverAddress,
								self.hostReachability.currentReachabilityString,
								self.hostReachability.currentReachabilityFlags);
	} else {
		DebugLogToConsole(@"%@ %@ %@", self.config.serverAddress,
						  self.hostReachability.currentReachabilityString,
						  self.hostReachability.currentReachabilityFlags);
	}

	if (self.isLoggedIn) {
		if (reachable == NO) {
			if (self.config.performDisconnectOnReachabilityChange) {
				self.disconnectType = IRCDisconnectReachabilityChangeMode;
				self.reconnectEnabled = YES;
				
				[self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
			}
		}
	}
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
	return [self.config.clientName uppercaseString];
}

#pragma mark -
#pragma mark Encoding

- (NSArray *)encodingDictionary
{
    return @[@(self.config.primaryEncoding), @(self.config.fallbackEncoding)];
}

- (NSArray *)fallbackEncodingDictionary
{
    return [NSString supportedStringEncodings:YES];
}

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	NSArray *encodings = [self encodingDictionary];

	for (id base in encodings) {
		NSData *s = [data dataUsingEncoding:[base integerValue] allowLossyConversion:YES];

		NSObjectIsEmptyAssertLoopContinue(s);

		return s;
	}

    encodings = [self fallbackEncodingDictionary];

	for (id base in encodings) {
		NSData *s = [data dataUsingEncoding:[base integerValue] allowLossyConversion:YES];

		NSObjectIsEmptyAssertLoopContinue(s);

		return s;
	}

	DebugLogToConsole(@"NSData encode failure. (%@)", data);

	return nil;
}

- (NSString *)convertFromCommonEncoding:(NSData *)data
{
	NSArray *encodings = [self encodingDictionary];

	for (id base in encodings) {
		NSString *s = [NSString stringWithBytes:[data bytes] length:[data length] encoding:[base integerValue]];

		NSObjectIsEmptyAssertLoopContinue(s);

		return s;
	}

    encodings = [self fallbackEncodingDictionary];

	for (id base in encodings) {
		NSString *s = [NSString stringWithBytes:[data bytes] length:[data length] encoding:[base integerValue]];

		NSObjectIsEmptyAssertLoopContinue(s);

		return s;
	}

	DebugLogToConsole(@"NSData decode failure. (%@)", data);

	return nil;
}

#pragma mark -
#pragma mark Ignore Matching

- (IRCAddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches
{
	NSObjectIsEmptyAssertReturn(host, nil);
	NSObjectIsEmptyAssertReturn(matches, nil);
	
	NSString *hostmask = [host lowercaseString];

	for (IRCAddressBook *g in self.config.ignoreList) {
		if ([g checkIgnore:hostmask]) {
			NSDictionary *ignoreDict = [g dictionaryValue];

			for (NSString *matchkey in matches) {
				if ([ignoreDict boolForKey:matchkey] == YES) {
					return g;
				}
			}
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Output Rules

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(TVCLogLineType)type
{
	NSObjectIsEmptyAssertReturn(raw, NO);
	
	if ([TPCPreferences removeAllFormatting]) {
		raw = [raw stripIRCEffects];
	}

	NSArray *rules = [THOPluginManagerSharedInstance() outputRulesForCommand:IRCCommandFromLineType(type)];

	for (NSArray *ruleData in rules) {
		NSString *ruleRegex = ruleData[0];

		if ([TLORegularExpression string:raw isMatchedByRegex:ruleRegex]) {
			BOOL console = [ruleData boolAtIndex:0];
			BOOL channel = [ruleData boolAtIndex:1];
			BOOL queries = [ruleData boolAtIndex:2];

			if ([chan isKindOfClass:[IRCChannel class]]) {
				if ((chan.isClient && console) ||
					(chan.isChannel && channel) ||
					(chan.isPrivateMessage && queries)) {

					return YES;
				}
			} else {
				return console;
			}
		}
	}

	return NO;
}

#pragma mark -
#pragma mark Encryption and Decryption Handling

- (BOOL)isSupportedMessageEncryptionFormat:(NSString *)message channel:(IRCChannel *)channel
{
	NSObjectIsEmptyAssertReturn(message, NO);
	
	if (channel && (channel.isChannel || channel.isPrivateMessage)) {
		return channel.config.encryptionKeyIsSet;
	}
	
	return NO;
}

- (BOOL)isMessageEncrypted:(NSString *)message channel:(IRCChannel *)channel
{
	if ([self isSupportedMessageEncryptionFormat:message channel:channel]) {
		return ([message hasPrefix:@"+OK "] || [message hasPrefix:@"mcps"]);
	}

	return NO;
}

- (BOOL)encryptOutgoingMessage:(NSString **)message channel:(IRCChannel *)channel
{
	if ([self isSupportedMessageEncryptionFormat:(*message) channel:channel]) {
		NSString *newstr = [CSFWBlowfish encodeData:(*message) key:channel.config.encryptionKey encoding:self.config.primaryEncoding];

		if (newstr.length < 5) {
			[self printDebugInformation:TXTLS(@"BlowfishEncryptionFailed") channel:channel];

			return NO;
		} else {
			(*message) = newstr;
		}
	}

	return YES;
}

- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)channel
{
	if ([self isSupportedMessageEncryptionFormat:(*message) channel:channel]) {
		NSString *newstr = [CSFWBlowfish decodeData:(*message) key:channel.config.encryptionKey encoding:self.config.primaryEncoding];

		if (NSObjectIsNotEmpty(newstr)) {
			(*message)= newstr;
		}
	}
}

#pragma mark -
#pragma mark Growl

/* Spoken events are only called from within the following calls so we are going to 
 shove the key value matching in here to make it all in one place for management. */

- (NSString *)localizedSpokenMessageForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationChannelMessageType:		{ return TXTLS(@"NotificationChannelMessageSpokenMessage");			}
		case TXNotificationChannelNoticeType:		{ return TXTLS(@"NotificationChannelNoticeSpokenMessage");			}
		case TXNotificationConnectType:				{ return TXTLS(@"NotificationConnectedSpokenMessage");				}
		case TXNotificationDisconnectType:			{ return TXTLS(@"NotificationDisconnectSpokenMessage");				}
		case TXNotificationInviteType:				{ return TXTLS(@"NotificationInvitedSpokenMessage");				}
		case TXNotificationKickType:				{ return TXTLS(@"NotificationKickedSpokenMessage");					}
		case TXNotificationNewPrivateMessageType:	{ return TXTLS(@"NotificationNewPrivateMessageSpokenMessage");		}
		case TXNotificationPrivateMessageType:		{ return TXTLS(@"NotificationPrivateMessageSpokenMessage");			}
		case TXNotificationPrivateNoticeType:		{ return TXTLS(@"NotificationPrivateNoticeSpokenMessage");			}
		case TXNotificationHighlightType:			{ return TXTLS(@"NotificationHighlightSpokenMessage");				}
			
		case TXNotificationFileTransferSendSuccessfulType:			{ return TXTLS(@"NotificationFileTransferSendSuccessfulSpokenMessage");			}
		case TXNotificationFileTransferReceiveSuccessfulType:		{ return TXTLS(@"NotificationFileTransferReceiveSuccessfulSpokenMessage");		}
		case TXNotificationFileTransferSendFailedType:				{ return TXTLS(@"NotificationFileTransferSendFailedSpokenMessage");				}
		case TXNotificationFileTransferReceiveFailedType:			{ return TXTLS(@"NotificationFileTransferReceiveFailedSpokenMessage");			}
		case TXNotificationFileTransferReceiveRequestedType:		{ return TXTLS(@"NotificationFileTransferReceiveRequestedSpokenMessage");		}
	
		default: { return nil; }
	}

	return nil;
}

- (void)speakEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text
{
	text = text.trim; // Do not leave spaces in text to be spoken.

	NSString *formattedMessage;
	
	switch (type) {
		case TXNotificationHighlightType:
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		{
			NSObjectIsEmptyAssertLoopBreak(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];
			
			formattedMessage = TXTFLS(nformatString, target.name.channelNameToken, nick, text);

			break;
		}
		case TXNotificationNewPrivateMessageType:
		case TXNotificationPrivateMessageType:
		case TXNotificationPrivateNoticeType:
		{
			NSObjectIsEmptyAssertLoopBreak(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTFLS(nformatString, nick, text);
			
			break;
		}
		case TXNotificationKickType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTFLS(nformatString, target.name.channelNameToken, nick);

			break;
		}
		case TXNotificationInviteType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTFLS(nformatString, text.channelNameToken, nick);

			break;
		}
		case TXNotificationConnectType:
		case TXNotificationDisconnectType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTFLS(nformatString, self.altNetworkName);
			
			break;
		}
		case TXNotificationAddressBookMatchType:
		{
			formattedMessage = text;

			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		case TXNotificationFileTransferReceiveSuccessfulType:
		case TXNotificationFileTransferSendFailedType:
		case TXNotificationFileTransferReceiveFailedType:
		case TXNotificationFileTransferReceiveRequestedType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];
			
			formattedMessage = TXTFLS(nformatString, nick);
		}
	}

	NSObjectIsEmptyAssert(formattedMessage);

	[self.masterController.speechSynthesizer speak:formattedMessage];
}

- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}

	PointerIsEmptyAssertReturn(target, NO);

	NSObjectIsEmptyAssertReturn(text, NO);
	NSObjectIsEmptyAssertReturn(nick, NO);

	if ([self.localNickname isEqualIgnoringCase:nick]) {
		return NO;
	}

	NSString *channelName = target.name;

	if (type == TXNotificationHighlightType) {
		if (target.config.ignoreHighlights) {
			return YES;
		}
	} else if (target.config.pushNotifications == NO) {
		return YES;
	}
    
    if ([TPCPreferences bounceDockIconForEvent:type]) {
        [NSApp requestUserAttention:NSInformationalRequest];
    }

	if (self.worldController.areNotificationsDisabled) {
		return YES;
	}
    
	if (self.worldController.isSoundMuted == NO) {
		[TLOSoundPlayer play:[TPCPreferences soundForEvent:type]];

		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}

	if ([TPCPreferences growlEnabledForEvent:type] == NO) {
		return YES;
	}

	if ([TPCPreferences postNotificationsWhileInFocus] == NO && self.masterController.mainWindowIsActive) {
		if (NSDissimilarObjects(type, TXNotificationAddressBookMatchType)) {
			return YES;
		}
	}

	if ([TPCPreferences disabledWhileAwayForEvent:type] && self.isAway) {
		return YES;
	}
	
	NSString *title = channelName;
	NSString *desc;

	if (ltype == TVCLogLineActionType || ltype == TVCLogLineActionNoHighlightType) {
		desc = [NSString stringWithFormat:TXNotificationDialogActionNicknameFormat, nick, text];
	} else {
		nick = [self formatNick:nick channel:target];

		desc = [NSString stringWithFormat:TXNotificationDialogStandardNicknameFormat, nick, text];
	}

	[self.masterController.growlController notify:type title:title description:desc userInfo:@{@"client" : self.treeUUID, @"channel" : target.treeUUID}];

	return YES;
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype
{
	return [self notifyEvent:type lineType:ltype target:nil nick:NSStringEmptyPlaceholder text:NSStringEmptyPlaceholder];
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}
	
	//NSObjectIsEmptyAssertReturn(text, NO);
	//NSObjectIsEmptyAssertReturn(nick, NO);
    
    if ([TPCPreferences bounceDockIconForEvent:type]) {
        [NSApp requestUserAttention:NSInformationalRequest];
    }

	if (self.worldController.areNotificationsDisabled) {
		return YES;
	}

	if (self.worldController.isSoundMuted == NO) {
		[TLOSoundPlayer play:[TPCPreferences soundForEvent:type]];
		
		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}

	if ([TPCPreferences growlEnabledForEvent:type] == NO) {
		return YES;
	}

	if ([TPCPreferences postNotificationsWhileInFocus] == NO && self.masterController.mainWindowIsActive) {
		if (NSDissimilarObjects(type, TXNotificationAddressBookMatchType)) {
			return YES;
		}
	}

	if ([TPCPreferences disabledWhileAwayForEvent:type] && self.isAway == YES) {
		return YES;
	}

	if (target) {
		if (target.config.pushNotifications == NO) {
			return YES;
		}
	}

	NSString *title = NSStringEmptyPlaceholder;
	NSString *desc = NSStringEmptyPlaceholder;
	
	NSDictionary *info = nil;
	
	if (target) {
		info = @{@"client": self.treeUUID, @"channel": target.treeUUID};
	} else {
		info = @{@"client": self.treeUUID};
	}

	switch (type) {
		case TXNotificationFileTransferSendSuccessfulType:
		case TXNotificationFileTransferReceiveSuccessfulType:
		case TXNotificationFileTransferSendFailedType:
		case TXNotificationFileTransferReceiveFailedType:
		case TXNotificationFileTransferReceiveRequestedType:
		{
			title = nick;
			desc = text;
			
			info = @{@"isFileTransferNotification" : @(YES)};
			
			break;
		}
		case TXNotificationConnectType:
		{
			title = [self altNetworkName];

			break;
		}
		case TXNotificationDisconnectType:
		{
			title = [self altNetworkName];

			break;
		}
		case TXNotificationAddressBookMatchType:
		{
			desc = text;

			break;
		}
		case TXNotificationKickType:
		{
			PointerIsEmptyAssertReturn(target, YES);
			
			title = target.name;
			
			desc = TXTFLS(@"NotificationKickedMessageDescription", nick, text);

			break;
		}
		case TXNotificationInviteType:
		{
			title = [self altNetworkName];
			
			desc = TXTFLS(@"NotificationInvitedMessageDescription", nick, text);

			break;
		}
		default: { return YES; }
	}

	[self.masterController.growlController notify:type title:title description:desc userInfo:info];
	
	return YES;
}

#pragma mark -
#pragma mark ZNC Bouncer Accessories

- (BOOL)isSafeToPostNotificationForMessage:(IRCMessage *)m inChannel:(IRCChannel *)channel
{
	PointerIsEmptyAssertReturn(m, NO);
	PointerIsEmptyAssertReturn(channel, NO);

	NSAssertReturnR(self.isZNCBouncerConnection, YES); // Post if we aren't ZNC connection.
	NSAssertReturnR(self.config.zncIgnorePlaybackNotifications, YES); // Post if user doesn't give a shit.

	return ([self messageIsPartOfZNCPlaybackBuffer:m inChannel:channel] == NO); // Do playback check…
}

- (BOOL)messageIsPartOfZNCPlaybackBuffer:(IRCMessage *)m inChannel:(IRCChannel *)channel
{
	PointerIsEmptyAssertReturn(m, NO);
	PointerIsEmptyAssertReturn(channel, NO);

	NSAssertReturnR(self.CAPServerTime, NO);
	NSAssertReturnR(self.isZNCBouncerConnection, NO);

	/* When Textual is using the server-time CAP with ZNC it does not tell us when
	 the playback buffer begins and when it ends. Therefore, we must make a best 
	 guess. We do this by checking if the message being parsed has a @time= attached
	 to it from server-time and also if it was sent during join.
	 
	 This is all best guess… */
	return m.isHistoric;
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(IRCChannel *)t
{
	BOOL isActiveWindow = self.masterController.mainWindowIsActive;

	if (NSDissimilarObjects(self.worldController.selectedItem, t) || isActiveWindow == NO) {
		t.nicknameHighlightCount += 1;

        [self.worldController updateIcon];
        [self.worldController reloadTreeItem:t];
	}

	if (t.isUnread || (isActiveWindow && self.worldController.selectedItem == t)) {
		return;
	}
}

- (void)setUnreadState:(IRCChannel *)t
{
	[self setUnreadState:t isHighlight:NO];
}

- (void)setUnreadState:(IRCChannel *)t isHighlight:(BOOL)isHighlight
{
	BOOL isActiveWindow = self.masterController.mainWindowIsActive;

	if (t.isPrivateMessage || ([TPCPreferences displayPublicMessageCountOnDockBadge] && t.isChannel)) {
		if (NSDissimilarObjects(self.worldController.selectedItem, t) || isActiveWindow == NO) {
			t.dockUnreadCount += 1;
            
            [self.worldController updateIcon];
		}
	}

	if (isActiveWindow == NO || (NSDissimilarObjects(self.worldController.selectedItem, t) && isActiveWindow)) {
		t.treeUnreadCount += 1;

		if (t.config.showTreeBadgeCount || (t.config.showTreeBadgeCount == NO && isHighlight)) {
			[self.worldController reloadTreeItem:t];
		}
	}
}

#pragma mark -
#pragma mark Find Channel

- (IRCChannel *)findChannel:(NSString *)name inList:(NSArray *)channelList
{
	for (IRCChannel *c in channelList) {
		if ([c.name isEqualIgnoringCase:name]) {
			return c;
		}
	}

	return nil;
}

- (IRCChannel *)findChannel:(NSString *)name
{
	return [self findChannel:name inList:self.channels];
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name
{
	return [self findChannelOrCreate:name isPrivateMessage:NO];
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name isPrivateMessage:(BOOL)isPM
{
	IRCChannel *c = [self findChannel:name];

	if (PointerIsEmpty(c)) {
		if (isPM) {
			return [self.worldController createPrivateMessage:name client:self];
		} else {
			IRCChannelConfig *seed = [IRCChannelConfig new];

			seed.channelName = name;

			return [self.worldController createChannel:seed client:self reload:YES adjust:YES];
		}
	}

	return c;
}

- (NSInteger)indexOfFirstPrivateMessage
{
	NSInteger i = 0;

	for (IRCChannel *e in self.channels) {
		if (e.isPrivateMessage) {
			return i;
		}
		
		i += 1;
	}
	
	return -1;
}

#pragma mark -
#pragma mark Send Raw Data

- (void)sendLine:(NSString *)str
{
	if (self.isConnected == NO) {
		return [self printDebugInformationToConsole:TXTLS(@"ServerNotConnectedLineSendError")];
	}

	[self.socket sendLine:str];

	self.worldController.messagesSent++;
	self.worldController.bandwidthOut += str.length;
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

	NSString *s = [IRCSendingMessage stringWithCommand:str arguments:ary];

	NSObjectIsEmptyAssert(s);

	[self sendLine:s];
}

#pragma mark -
#pragma mark Sending Text

- (void)inputText:(id)str command:(NSString *)command
{
	id sel = self.worldController.selectedItem;

	NSObjectIsEmptyAssert(str);
	NSObjectIsEmptyAssert(command);
	
	PointerIsEmptyAssert(sel);

	if ([str isKindOfClass:[NSString class]]) {
		str = [NSAttributedString emptyStringWithBase:str];
	}

	NSArray *lines = [str performSelector:@selector(splitIntoLines)];

	for (__strong NSAttributedString *s in lines) {
		NSRange chopRange = NSMakeRange(1, (s.length - 1));

		if ([sel isClient]) {
			if ([s.string hasPrefix:@"/"]) {
				if (s.length > 1) {
					s = [s attributedSubstringFromRange:chopRange];
					
					[self sendCommand:s];
				}
			} else {
				[self sendCommand:s];
			}
		} else {
			IRCChannel *channel = (IRCChannel *)sel;

			if ([s.string hasPrefix:@"/"] && [s.string hasPrefix:@"//"] == NO && s.length > 1) {
				s = [s attributedSubstringFromRange:chopRange];

				[self sendCommand:s];
			} else {
				if ([s.string hasPrefix:@"/"] && s.length > 1) {
					s = [s attributedSubstringFromRange:chopRange];
				}

				[self sendText:s command:command channel:channel];
			}
		}
	}
}

- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel
{
    [self sendText:str command:command channel:channel withEncryption:YES];
}

- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel withEncryption:(BOOL)encryptChat
{
	NSObjectIsEmptyAssert(str);
	NSObjectIsEmptyAssert(command);
	
	PointerIsEmptyAssert(channel);

	TVCLogLineType type;

	if ([command isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([command isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	} else {
		type = TVCLogLinePrivateMessageType;
	}
	
	NSString *commandActual = IRCPrivateCommandIndex("privmsg");

	if (type == TVCLogLineNoticeType) {
		commandActual = IRCPrivateCommandIndex("notice");
	}

	NSArray *lines = [str performSelector:@selector(splitIntoLines)];

	for (NSAttributedString *line in lines) {
		NSMutableAttributedString *strc = [line mutableCopy];

		while (strc.length >= 1)
		{
			NSString *newstr = [strc attributedStringToASCIIFormatting:&strc
															  lineType:type
															   channel:channel.name
															  hostmask:self.myHost];

            BOOL encrypted = (encryptChat && [self isSupportedMessageEncryptionFormat:newstr channel:channel]);

            [self print:channel
				   type:type
				   nick:self.localNickname
				   text:newstr
			  encrypted:encrypted
			 receivedAt:[NSDate date]
				command:commandActual];

            if (encrypted) {
                NSAssertReturnLoopContinue([self encryptOutgoingMessage:&newstr channel:channel]);
            }
            
			if (type == TVCLogLineActionType) {
				command = IRCPrivateCommandIndex("privmsg");

				newstr = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), newstr, 0x01];
			}

			[self send:command, channel.name, newstr, nil];
		}
	}
	
	[self processBundlesUserMessage:str.string command:NSStringEmptyPlaceholder];
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	[self sendText:[NSAttributedString emptyStringWithBase:message]
		   command:IRCPrivateCommandIndex("privmsg")
		   channel:[self.worldController selectedChannelOn:self]];
}

- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSObjectIsEmptyAssert(target);
	NSObjectIsEmptyAssert(command);

	NSString *trail;

	if (NSObjectIsEmpty(text)) {
		trail = [NSString stringWithFormat:@"%c%@%c", 0x01, command, 0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, command, text, 0x01];
	}

	[self send:IRCPrivateCommandIndex("privmsg"), target, trail, nil];
}

- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSObjectIsEmptyAssert(target);
	NSObjectIsEmptyAssert(command);
	
	NSString *trail;

	if (NSObjectIsEmpty(text)) {
		trail = [NSString stringWithFormat:@"%c%@%c", 0x01, command, 0x01];
	} else {
		trail = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, command, text, 0x01];
	}

	[self send:IRCPrivateCommandIndex("notice"), target, trail, nil];
}

- (void)sendCTCPPing:(NSString *)target
{
	[self sendCTCPQuery:target
				command:IRCPrivateCommandIndex("ctcp_ping")
				   text:[NSString stringWithFormat:@"%f", [NSDate epochTime]]];
}

#pragma mark -
#pragma mark Send Command

- (void)sendCommand:(id)str
{
	[self sendCommand:str completeTarget:YES target:nil];
}

- (void)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName
{
	NSObjectIsEmptyAssert(str);
	
	NSMutableAttributedString *s = [NSMutableAttributedString alloc];

	if ([str isKindOfClass:[NSString class]]) {
		s = [s initWithString:str];
	} else {
		if ([str isKindOfClass:[NSAttributedString class]]) {
			s = [s initWithAttributedString:str];
		}
	}

	NSString *rawcaseCommand = s.getToken.string;
	
	NSString *uppercaseCommand = [rawcaseCommand uppercaseString];
	NSString *lowercaseCommand = [rawcaseCommand lowercaseString];
	
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	IRCChannel *selChannel = nil;

	if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("mode")] && ([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
		// Do not complete for /mode #chname ...
	} else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	NSString *uncutInput = s.string;

	switch ([TPCPreferences indexOfIRCommand:uppercaseCommand publicSearch:YES]) {
		case 5004: // Command: AWAY
		{
			if (NSObjectIsEmpty(uncutInput)) {
                uncutInput = TXTLS(@"IRCAwayCommandDefaultReason");
			}
            
            if (self.isAway) {
                uncutInput = nil;
            }

            if ([TPCPreferences awayAllConnections]) {
                for (IRCClient *client in self.worldController.clients) {
                    [client toggleAwayStatus:NSObjectIsNotEmpty(uncutInput) withReason:uncutInput];
                }
            } else {
                [self toggleAwayStatus:NSObjectIsNotEmpty(uncutInput) withReason:uncutInput];
            }

			break;
		}
		case 5030: // Command: INVITE
		{
			NSObjectIsEmptyAssert(uncutInput);

			NSMutableArray *nicks = [NSMutableArray arrayWithArray:[uncutInput componentsSeparatedByString:NSStringWhitespacePlaceholder]];

			if (NSObjectIsNotEmpty(nicks) && [nicks.lastObject isChannelName:self]) {
				targetChannelName = [nicks lastObject];

				[nicks removeLastObject];
			} else if (selChannel && selChannel.isChannel) {
				targetChannelName = selChannel.name;
			} else {
				return;
			}

			for (NSString *nick in nicks) {
				if ([nick isNickname:self] && [nick isChannelName:self] == NO) {
					[self send:uppercaseCommand, nick, targetChannelName, nil];
				}
			}
			
			break;
		}
		case 5031: // Command: J
		case 5032:  // Command: JOIN
		{
			if (selChannel && selChannel.isChannel && NSObjectIsEmpty(uncutInput)) {
				targetChannelName = selChannel.name;
			} else {
				NSObjectIsEmptyAssert(uncutInput);

				targetChannelName = s.getToken.string;

				if ([targetChannelName isChannelName:self] == NO && [targetChannelName isEqualToString:@"0"] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}

			self.inUserInvokedJoinRequest = YES;

			[self send:IRCPrivateCommandIndex("join"), targetChannelName, s.string, nil];

			break;
		}
		case 5033: // Command: KICK
		{
			NSObjectIsEmptyAssert(uncutInput);
				
			if (selChannel && selChannel.isChannel && [uncutInput isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *nickname = s.getToken.string;
			NSString *reason = s.string.trim;

			NSObjectIsEmptyAssert(nickname);

			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences defaultKickMessage];
			}

			[self send:uppercaseCommand, targetChannelName, nickname, reason, nil];

			break;
		}
		case 5035: // Command: KILL
		{
			NSObjectIsEmptyAssert(uncutInput);

			NSString *nickname = s.getToken.string;
			NSString *reason = s.string.trim;

			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences IRCopDefaultKillMessage];
			}

			[self send:IRCPrivateCommandIndex("kill"), nickname, reason, nil];

			break;
		}
		case 5037: // Command: LIST
		{
			if (PointerIsEmpty([self listDialog])) {
				[self createChannelListDialog];
			}

			[self send:IRCPrivateCommandIndex("list"), s.string, nil];

			break;
		}
		case 5048: // Command: NICK
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSString *newnick = s.getToken.string;
			
			if ([TPCPreferences nickAllConnections]) {
				for (IRCClient *client in self.worldController.clients) {
					[client changeNick:newnick];
				}
			} else {
				[self changeNick:newnick];
			}

			break;
		}
		case 5050: // Command: NOTICE
		case 5051: // Command: OMSG
		case 5052: // Command: ONOTICE
		case 5041: // Command: ME
		case 5043: // Command: MSG
		case 5064: // Command: SME
		case 5065: // Command: SMSG
		case 5088: // Command: UMSG
		case 5089: // Command: UME
		case 5090: // Command: UNOTICE
		{
			BOOL opMsg = NO;
			BOOL secretMsg = NO;
            BOOL doNotEncrypt = NO;

			TVCLogLineType type = TVCLogLinePrivateMessageType;

			/* Command Type. */
			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("msg")]) {
				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("smsg")]) {
				secretMsg = YES;

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("omsg")]) {
				opMsg = YES;

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("umsg")]) {
				doNotEncrypt = YES;

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("notice")]) {
				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("onotice")]) {
				opMsg = YES;

				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("unotice")]) {
				doNotEncrypt = YES;

				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("me")]) {
				type = TVCLogLineActionType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("sme")]) {
				secretMsg = YES;

				type = TVCLogLineActionType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("ume")]) {
				doNotEncrypt = YES;

				type = TVCLogLineActionType;
			}
            
			/* Actual command being sent. */
			if (type == TVCLogLineNoticeType) {
				uppercaseCommand = IRCPrivateCommandIndex("notice");
			} else {
				uppercaseCommand = IRCPrivateCommandIndex("privmsg");
			}

			//rawcaseCommand = uppercaseCommand; // Analyze: Never read.
			//lowercaseCommand = uppercaseCommand.lowercaseString; // Analyze: Never read.

			/* Destination. */
			if (selChannel && type == TVCLogLineActionType && secretMsg == NO) {
				targetChannelName = selChannel.name;
			} else if (selChannel && selChannel.isChannel && opMsg && [s.string isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			if (type == TVCLogLineActionType) {
				if (NSObjectIsEmpty(s)) {
					/* If the input is empty, then set one space character as our input
					 when using the /me command so that the use of /me without any input
					 still sends an action. */

					s = [[NSAttributedString emptyStringWithBase:NSStringWhitespacePlaceholder] mutableCopy];
				}
			} else {
				NSObjectIsEmptyAssert(s);
			}
			
			NSObjectIsEmptyAssert(targetChannelName);
			
			NSArray *targets = [targetChannelName componentsSeparatedByString:@","];

			while (s.length >= 1)
			{
				NSString *t = [s attributedStringToASCIIFormatting:&s lineType:type channel:targetChannelName hostmask:self.myHost];

				for (__strong NSString *channelName in targets) {
					BOOL opPrefix = NO;

					if ([channelName hasPrefix:@"@"]) {
						opPrefix = YES;

						channelName = [channelName safeSubstringFromIndex:1];
					}

					IRCChannel *channel = [self findChannel:channelName];

					if (PointerIsEmpty(channel) && secretMsg == NO) {
						if ([channelName isChannelName:self] == NO) {
							channel = [self.worldController createPrivateMessage:channelName client:self];
						}
					}

					if (channel) {
                        BOOL encrypted = (doNotEncrypt == NO && [self isSupportedMessageEncryptionFormat:t channel:channel]);

                        [self print:channel
							   type:type
							   nick:self.localNickname
							   text:t
						  encrypted:encrypted
						 receivedAt:[NSDate date]
							command:uppercaseCommand];

                        if (encrypted) {
                            NSAssertReturnLoopContinue([self encryptOutgoingMessage:&t channel:channel]);
                        }
                    }

					if ([channelName isChannelName:self]) {
						if (opMsg || opPrefix) {
							channelName = [@"@" stringByAppendingString:channelName];
						}
					}

					if (type == TVCLogLineActionType) {
						t = [NSString stringWithFormat:@"%C%@ %@%C", 0x01, IRCPrivateCommandIndex("action"), t, 0x01];
					}

					[self send:uppercaseCommand, channelName, t, nil];

					/* Focus message destination? */
					if (channel && secretMsg == NO && [TPCPreferences giveFocusOnMessageCommand]) {
						[self.worldController select:channel];
					}
				}
			}

			break;
		}
		case 5054: // Command: PART
		case 5036: // Command: LEAVE
		{
			if (selChannel && selChannel.isChannel && [uncutInput isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else if (selChannel && selChannel.isPrivateMessage && [uncutInput isChannelName:self] == NO) {
				[self.worldController destroyChannel:selChannel];

				return;
			} else {
				NSObjectIsEmptyAssert(uncutInput);
				
				targetChannelName = s.getToken.string;
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *reason = s.string.trim;

			if (NSObjectIsEmpty(reason)) {
				reason = self.config.normalLeavingComment;
			}

			[self send:IRCPrivateCommandIndex("part"), targetChannelName, reason, nil];

			break;
		}
		case 5057: // Command: QUIT
		{
			[self quit:uncutInput];

			break;
		}
		case 5070: // Command: TOPIC
		case 5067: // Command: T
		{
			if (selChannel && selChannel.isChannel && [uncutInput isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *topic = [s attributedStringToASCIIFormatting];

			if (NSObjectIsEmpty(topic)) {
				[self send:IRCPrivateCommandIndex("topic"), targetChannelName, nil];
			} else {
				IRCChannel *channel = [self findChannel:targetChannelName];

				if ([self encryptOutgoingMessage:&topic channel:channel] == YES) {
					[self send:IRCPrivateCommandIndex("topic"), targetChannelName, topic, nil];
				}
			}

			break;
		}
		case 5079: // Command: WHO
		{
			NSObjectIsEmptyAssert(uncutInput);

			self.inUserInvokedWhoRequest = YES;

			[self send:IRCPrivateCommandIndex("who"), uncutInput, nil];

			break;
		}
		case 5097: // Command: WATCH
		{
			self.inUserInvokedWatchRequest = YES;

			[self send:IRCPrivateCommandIndex("watch"), nil];

			break;
		}
		case 5094: // Command: NAMES
		{
			NSObjectIsEmptyAssert(uncutInput);

			self.inUserInvokedNamesRequest = YES;

			[self send:IRCPrivateCommandIndex("names"), uncutInput, nil];

			break;
		}
		case 5080: // Command: WHOIS
		{
			NSString *nickname1 = s.getToken.string;
			NSString *nickname2 = s.getToken.string;

			if (NSObjectIsEmpty(nickname1)) {
				if (selChannel.isPrivateMessage) {
					nickname1 = selChannel.name;
				} else {
					return;
				}
			}

			if (NSObjectIsEmpty(nickname2)) {
				[self send:IRCPrivateCommandIndex("whois"), nickname1, nickname1, nil];
			} else {
				[self send:IRCPrivateCommandIndex("whois"), nickname1, nickname2, nil];
			}

			break;
		}
		case 5014: // Command: CTCP
		{
			if (selChannel && selChannel.isPrivateMessage) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSString *subCommand = s.getToken.string.uppercaseString;

			NSObjectIsEmptyAssert(subCommand);
			NSObjectIsEmptyAssert(targetChannelName);

			if ([subCommand isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
				[self sendCTCPPing:targetChannelName];
			} else {
				[self sendCTCPQuery:targetChannelName command:subCommand text:s.string];
			}

			break;
		}
		case 5015: // Command: CTCPREPLY
		{
			if (selChannel && selChannel.isPrivateMessage) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSString *subCommand = s.getToken.string.uppercaseString;

			NSObjectIsEmptyAssert(subCommand);
			NSObjectIsEmptyAssert(targetChannelName);

			[self sendCTCPReply:targetChannelName command:subCommand text:s.string];
			
			break;
		}
		case 5005: // Command: BAN
		case 5072: // Command: UNBAN
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			if (selChannel && selChannel.isChannel && [uncutInput isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *banmask = s.getToken.string;
			
			NSObjectIsEmptyAssert(banmask);

			IRCChannel *channel = [self findChannel:targetChannelName];

			if (channel) {
				IRCUser *user = [channel memberWithNickname:banmask];

				if (user) {
					banmask = [user banMask];
				}
			}

			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("ban")]) {
				[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"+b", banmask, nil];
			} else {
				[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"-b", banmask, nil];
			}

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
			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("m")]) {
				uppercaseCommand = IRCPublicCommandIndex("mode");
				lowercaseCommand = uppercaseCommand.lowercaseString;
				//rawcaseCommand = uppercaseCommand; // Analyze: Never read.
			}

			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("halfop")] ||
				[uppercaseCommand isEqualToString:IRCPublicCommandIndex("dehalfop")])
			{
				/* Do not try mode changes when they are not supported. */

				BOOL modeHSupported = [self.isupport modeIsSupportedUserPrefix:@"h"];

				if (modeHSupported == NO) {
					[self printDebugInformation:TXTLS(@"HalfopCommandNotSupportedOnServer")];

					return;
				}
			}

			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("mode")]) {
				if (selChannel && selChannel.isChannel && [s.string isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else if (([s.string hasPrefix:@"+"] || [s.string hasPrefix:@"-"]) == NO) {
					targetChannelName = s.getToken.string;
				}

				self.inUserInvokedModeRequest = YES;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("umode")]) {
				[s insertAttributedString:[NSAttributedString emptyStringWithBase:NSStringWhitespacePlaceholder]	atIndex:0];
				[s insertAttributedString:[NSAttributedString emptyStringWithBase:self.localNickname]				atIndex:0];
			} else {
				if (selChannel && selChannel.isChannel && [s.string isModeChannelName] == NO) {
					targetChannelName = selChannel.name;
				} else {
					targetChannelName = s.getToken.string;
				}

				NSString *sign;

				if ([uppercaseCommand hasPrefix:@"DE"] || [uppercaseCommand hasPrefix:@"UN"]) {
					sign = @"-";

					uppercaseCommand = [uppercaseCommand safeSubstringFromIndex:2];
					lowercaseCommand = uppercaseCommand.lowercaseString;
					//rawcaseCommand = uppercaseCommand; // Analyze: Never read.
				} else {
					sign = @"+";
				}

				NSArray *params = [s.string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

				NSObjectIsEmptyAssert(params);
				
				NSMutableString *ms = [NSMutableString stringWithString:sign];

				NSString *modeCharStr = [lowercaseCommand safeSubstringToIndex:1];

				for (NSInteger i = (params.count - 1); i >= 0; --i) {
					[ms appendString:modeCharStr];
				}

				[ms appendString:NSStringWhitespacePlaceholder];
				[ms appendString:s.string];

				[s setAttributedString:[NSAttributedString emptyStringWithBase:ms]];
			}

			NSMutableString *line = [NSMutableString string];
			
			[line appendString:IRCPrivateCommandIndex("mode")];

			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("umode")] == NO) {
				NSObjectIsEmptyAssert(targetChannelName);
				
				[line appendString:NSStringWhitespacePlaceholder];
				[line appendString:targetChannelName];
			}

			if (NSObjectIsNotEmpty(s)) {
				[line appendString:NSStringWhitespacePlaceholder];
				[line appendString:s.string];
			}

			[self sendLine:line];

			break;
		}
		case 5010: // Command: CLEAR
		{
			if (selChannel) {
				[self.worldController clearContentsOfChannel:selChannel inClient:self];
			} else if (u) {
				[self.worldController clearContentsOfClient:u];
			}

			break;
		}
		case 5012: // Command: CLOSE
		case 5061: // Command: REMOVE
		{
			if (selChannel && NSObjectIsEmpty(uncutInput)) {
				[self.worldController destroyChannel:selChannel];
			} else {
				NSString *channel = s.getToken.string;
				
				IRCChannel *oc = [self findChannel:channel];

				if (oc) {
					[self.worldController destroyChannel:oc];
				}
			}

			break;
		}
		case 5060: // Command: REJOIN
		case 5016: // Command: CYCLE
		case 5027: // Command: HOP
		{
			if (selChannel && selChannel.isChannel) {
				NSString *password = nil;

				if ([c.modeInfo modeIsDefined:@"k"]) {
					password = [c.modeInfo modeInfoFor:@"k"].modeParamater;
				}

				[self partChannel:c];
				[self forceJoinChannel:c.name password:password];
			}

			break;
		}
		case 5029: // Command: IGNORE
		case 5073: // Command: UNIGNORE
		{
			BOOL isIgnoreCommand = [uppercaseCommand isEqualToString:IRCPublicCommandIndex("ignore")];
				
			if (NSObjectIsEmpty(uncutInput) || PointerIsEmpty(selChannel)) {
				if (isIgnoreCommand) {
                    [self.masterController.menuController showServerPropertyDialog:self withDefaultView:@"addressBook" andContext:@"--"];
				} else {
                    [self.masterController.menuController showServerPropertyDialog:self withDefaultView:@"addressBook" andContext:@"-"];
				}
			} else {
				NSString *nickname = s.getToken.string;
				
				IRCUser *user = [selChannel memberWithNickname:nickname];

				if (PointerIsEmpty(user)) {
					if (isIgnoreCommand) {
                        [self.masterController.menuController showServerPropertyDialog:self withDefaultView:@"addressBook" andContext:nickname];
					} else {
                        [self.masterController.menuController showServerPropertyDialog:self withDefaultView:@"addressBook" andContext:@"-"];
					}

					return;
				}

				IRCAddressBook *g = [IRCAddressBook new];

				g.hostmask = [user banMask];

				g.ignoreCTCP = YES;
				g.ignoreJPQE = YES;
				g.ignoreNotices	= YES;
				g.ignorePublicMessages = YES;
				g.ignorePrivateMessages = YES;
				g.ignorePublicHighlights = YES;
				g.ignorePrivateHighlights = YES;
				g.ignoreFileTransferRequests = YES;

				g.hideMessagesContainingMatch = NO;
				g.hideInMemberList = YES;

				g.notifyJoins = NO;

				if (isIgnoreCommand) {
					BOOL found = NO;

					for (IRCAddressBook *e in self.config.ignoreList) {
						if ([g.hostmask isEqualToString:e.hostmask]) {
							found = YES;

							break;
						}
					}

					if (found == NO) {
						[self.config.ignoreList safeAddObject:g];
						
						[self updateIgnoreConfiguration:NO];
					}
				} else {
					for (IRCAddressBook *e in self.config.ignoreList) {
						if ([g.hostmask isEqualToString:e.hostmask]) {
							[self.config.ignoreList removeObject:e];

							[self updateIgnoreConfiguration:NO];

							break;
						}
					}
				}
			}

			break;
		}
		case 5059: // Command: RAW
		case 5058: // Command: QUOTE
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			[self sendLine:uncutInput];

			break;
		}
		case 5095: // Command: AQUOTE
		case 5096: // Command: ARAW
		{
			NSObjectIsEmptyAssert(uncutInput);

			for (IRCClient *client in self.worldController.clients) {
				[client sendLine:uncutInput];
			}

			break;
		}
		case 5056: // Command: QUERY
		{
			NSString *nickname = s.getToken.string;

			if (NSObjectIsEmpty(nickname)) {
				if (selChannel && selChannel.isPrivateMessage) {
					[self.worldController destroyChannel:selChannel];
				}
			} else {
				if ([nickname isChannelName:self] == NO && [nickname isNickname:self]) {
					IRCChannel *channel = [self findChannelOrCreate:nickname isPrivateMessage:YES];

					[self.worldController select:channel];
				}
			}

			break;
		}
		case 5069: // Command: TIMER
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSInteger interval = [s.getToken.string integerValue];

			NSObjectIsEmptyAssert(s);

			if (interval > 0) {
				TLOTimerCommand *cmd = [TLOTimerCommand new];

				if ([s.string hasPrefix:@"/"]) {
					[s deleteCharactersInRange:NSMakeRange(0, 1)];
				}

				if (selChannel) {
					cmd.channelID = selChannel.treeUUID;
				} else {
					cmd.channelID = nil;
				}
				
				cmd.rawInput = s.string;
				cmd.timerInterval = ([NSDate epochTime] + interval);

				[self addCommandToCommandQueue:cmd];
			} else {
				[self printDebugInformation:TXTLS(@"IRCTimerCommandRequiresInteger")];
			}

			break;
		}
		case 5022: // Command: ECHO
		case 5018: // Command: DEBUG
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			if ([uncutInput isEqualIgnoringCase:@"raw on"]) {
				self.rawModeEnabled = YES;

				[self printDebugInformation:TXTLS(@"IRCRawModeIsEnabled")];

				LogToConsole(@"%@", TXTLS(@"IRCRawModeIsEnabledSessionStart"));
			} else if ([uncutInput isEqualIgnoringCase:@"raw off"]) {
				self.rawModeEnabled = NO;

				[self printDebugInformation:TXTLS(@"IRCRawModeIsDisabled")];

				LogToConsole(@"%@", TXTLS(@"IRCRawModeIsDisabledSessionStart"));
			} else if ([uncutInput isEqualIgnoringCase:@"devmode on"]) {
				[RZUserDefaults() setBool:YES forKey:TXDeveloperEnvironmentToken];
			} else if ([uncutInput isEqualIgnoringCase:@"devmode off"]) {
				[RZUserDefaults() setBool:NO forKey:TXDeveloperEnvironmentToken];
			} else {
				[self printDebugInformation:uncutInput];
			}

			break;
		}
		case 5011: // Command: CLEARALL
		{
			if ([TPCPreferences clearAllOnlyOnActiveServer]) {
				[self.worldController clearContentsOfClient:self];

				for (IRCChannel *channel in self.channels) {
					[self.worldController clearContentsOfChannel:channel inClient:self];
				}

				[self.worldController markAllAsRead:self];
			} else {
				[self.worldController destroyAllEvidence];
			}

			break;
		}
		case 5003: // Command: AMSG
		{
			NSObjectIsEmptyAssert(uncutInput);

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *client in self.worldController.clients) {
                    if(client.isConnected) {
                        for (IRCChannel *channel in client.channels) {
                            if(channel.isActive) {
                                [client setUnreadState:channel];
                                [client sendText:s command:IRCPrivateCommandIndex("privmsg") channel:channel];
                            }
                        }
                    }
				}
			} else {
				for (IRCChannel *channel in self.channels) {
					[self setUnreadState:channel];
					[self sendText:s command:IRCPrivateCommandIndex("privmsg") channel:channel];
				}
			}

			break;
		}
		case 5002: // Command: AME
		{
			NSObjectIsEmptyAssert(uncutInput);

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *client in self.worldController.clients) {
                    if(client.isConnected) {
                        for (IRCChannel *channel in client.channels) {
                            if(channel.isActive) {
                                [client setUnreadState:channel];
                                [client sendText:s command:IRCPrivateCommandIndex("action") channel:channel];
                            }
                        }
                    }
				}
			} else {
				for (IRCChannel *channel in self.channels) {
					[self setUnreadState:channel];
					[self sendText:s command:IRCPrivateCommandIndex("action") channel:channel];
				}
			}

			break;
		}
		case 5083: // Command: KB
		case 5034: // Command: KICKBAN
		{
			NSObjectIsEmptyAssert(uncutInput);

			if (selChannel && selChannel.isChannel && [uncutInput isChannelName:self] == NO) {
				targetChannelName = selChannel.name;
			} else {
				targetChannelName = s.getToken.string;
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *nickname = s.getToken.string;
			NSString *banmask = nickname;

			NSObjectIsEmptyAssert(banmask);

			IRCChannel *channel = [self findChannel:targetChannelName];

			if (channel) {
				IRCUser *user = [channel memberWithNickname:banmask];

				if (user) {
					nickname = user.nickname;
					banmask = user.banMask;
				}
			}
			
			NSString *reason = s.string.trim;
			
			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences defaultKickMessage];
			}

			[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"+b", banmask, nil];
			[self send:IRCPrivateCommandIndex("kick"), targetChannelName, nickname, reason, nil];

			break;
		}
		case 5028: // Command: ICBADGE
		{
			NSAssertReturn([uncutInput contains:NSStringWhitespacePlaceholder]);
			
			NSArray *data = [s.string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			[TVCDockIcon drawWithHilightCount:[data integerAtIndex:0]
								 messageCount:[data integerAtIndex:1]];

			break;
		}
		case 5062: // Command: SERVER
		{
			NSObjectIsEmptyAssert(uncutInput);

			[IRCExtras createConnectionAndJoinChannel:uncutInput channel:nil autoConnect:YES];

			break;
		}
		case 5013: // Command: CONN
		{
			if (self.isConnected) {
				[self quit];
			}

			if (self.isQuitting) {
				if (NSObjectIsNotEmpty(uncutInput)) {
					/* We have to chase -disconnect from destroying this… */

					[self performSelector:@selector(setServerRedirectAddressTemporaryStore:) withObject:s.getToken.string afterDelay:2.0];
				}

				[self performSelector:@selector(connect) withObject:nil afterDelay:2.0];
			} else {
				if (NSObjectIsNotEmpty(uncutInput)) {
					self.serverRedirectAddressTemporaryStore = s.getToken.string;
				}
				
				[self connect];
			}

			break;
		}
		case 5046: // Command: MYVERSION
		{
			NSString *gref = [TPCPreferences gitBuildReference];
			NSString *name = [TPCPreferences applicationName];
			NSString *vers = [TPCPreferences textualInfoPlist][@"CFBundleVersion"];
			NSString *code = [TPCPreferences textualInfoPlist][@"TXBundleBuildCodeName"];
			NSString *ccnt = [TPCPreferences gitCommitCount];

			if (NSObjectIsEmpty(gref)) {
				gref = TXTLS(@"Unknown");
			}

			NSString *text;
			
			if ([uncutInput isEqualIgnoringCase:@"-d"]) {
				text = [NSString stringWithFormat:TXTLS(@"IRCCTCPVersionInfoDetailed_2"), name, vers, gref, code];
			} else {
				text = [NSString stringWithFormat:TXTLS(@"IRCCTCPVersionInfoDetailed_1"), name, vers, ccnt];
			}

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:text];
			} else {
				text = TXTFLS(@"IRCCTCPVersionTitle", text);

				[self sendPrivmsgToSelectedChannel:text];
			}

			break;
		}
		case 5044: // Command: MUTE
		{
			if (self.worldController.isSoundMuted) {
				[self printDebugInformation:TXTLS(@"SoundIsAlreadyMuted")];
			} else {
				[self printDebugInformation:TXTLS(@"SoundIsNowMuted")];

				[self.masterController.menuController toggleMuteOnNotificationSoundsShortcut:NSOffState];
			}

			break;
		}
		case 5075: // Command: UNMUTE
		{
			if (self.worldController.isSoundMuted) {
				[self printDebugInformation:TXTLS(@"SoundIsNoLongerMuted")];

				[self.masterController.menuController toggleMuteOnNotificationSoundsShortcut:NSOnState];
			} else {
				[self printDebugInformation:TXTLS(@"SoundIsNotMuted")];
			}

			break;
		}
		case 5093: // Command: TAGE
		{
			/* Textual Age — Developr mode only. */

			NSTimeInterval timeDiff = [NSDate secondsSinceUnixTimestamp:TXBirthdayReferenceDate];

			NSString *message = TXTFLS(@"TimeIntervalSinceFirstCommit", TXReadableTime(timeDiff));

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:message];
			} else {
				[self sendPrivmsgToSelectedChannel:message];
			}
			
			break;
		}
		case 5091: // Command: LOADED_PLUGINS
		{
			NSArray *loadedBundles = [THOPluginManagerSharedInstance() allLoadedExtensions];
			NSArray *loadedScripts = [THOPluginManagerSharedInstance() supportedAppleScriptCommands];

			NSString *bundleResult = [loadedBundles componentsJoinedByString:@", "];
			NSString *scriptResult = [loadedScripts componentsJoinedByString:@", "];

			if (NSObjectIsEmpty(bundleResult)) {
				bundleResult = TXTLS(@"LoadedPlguinsCommandNothingLoaded");
			}

			if (NSObjectIsEmpty(scriptResult)) {
				scriptResult = TXTLS(@"LoadedPlguinsCommandNothingLoaded");
			}

			[self printDebugInformation:TXTFLS(@"LoadedPlguinsCommandLoadedBundles", bundleResult)];
			[self printDebugInformation:TXTFLS(@"LoadedPlguinsCommandLoadedScripts", scriptResult)];

			break;
		}
		case 5084: // Command: LAGCHECK
		case 5045: // Command: MYLAG
		{
			self.lastLagCheck = [NSDate epochTime];

			if ([uppercaseCommand isEqualIgnoringCase:IRCPublicCommandIndex("mylag")]) {
				self.sendLagcheckReplyToChannel = YES;
			}

			[self sendCTCPQuery:self.localNickname command:IRCPrivateCommandIndex("ctcp_lagcheck") text:[NSString stringWithDouble:self.lastLagCheck]];

			[self printDebugInformation:TXTLS(@"LagCheckRequestSentMessage")];

			break;
		}
		case 5082: // Command: ZLINE
		case 5023: // Command: GLINE
		case 5025: // Command: GZLINE
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSString *nickname = s.getToken.string;

			if ([nickname hasPrefix:@"-"]) {
				[self send:uppercaseCommand, nickname, s.string, nil];
			} else {
				NSString *gltime = s.getToken.string;
				NSString *reason = s.string.trim;

				if (NSObjectIsEmpty(reason)) {
					reason = [TPCPreferences IRCopDefaultGlineMessage];

					/* Remove the time from our default reason. */
					if ([reason contains:NSStringWhitespacePlaceholder]) {
						NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

						if (NSObjectIsEmpty(gltime)) {
							gltime = [reason safeSubstringToIndex:spacePos];
						}

						reason = [reason substringAfterIndex:spacePos];
					}
				}

				[self send:uppercaseCommand, nickname, gltime, reason, nil];
			}

			break;
		}
		case 5063:  // Command: SHUN
		case 5068: // Command: TEMPSHUN
		{
			NSObjectIsEmptyAssert(uncutInput);

			NSString *nickname = s.getToken.string;

			if ([nickname hasPrefix:@"-"]) {
				[self send:uppercaseCommand, nickname, s.string, nil];
			} else {
				if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("tempshun")]) {
					NSString *reason = s.getToken.string;

					if (NSObjectIsEmpty(reason)) {
						reason = [TPCPreferences IRCopDefaultShunMessage];

						/* Remove the time from our default reason. */
						if ([reason contains:NSStringWhitespacePlaceholder]) {
							NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

							reason = [reason substringAfterIndex:spacePos];
						}
					}

					[self send:uppercaseCommand, nickname, reason, nil];
				} else {
					NSString *shtime = s.getToken.string;
					NSString *reason = s.string.trim;

					if (NSObjectIsEmpty(reason)) {
						reason = [TPCPreferences IRCopDefaultShunMessage];

						/* Remove the time from our default reason. */
						if ([reason contains:NSStringWhitespacePlaceholder]) {
							NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

							if (NSObjectIsEmpty(shtime)) {
								shtime = [reason safeSubstringToIndex:spacePos];
							}

							reason = [reason substringAfterIndex:spacePos];
						}
					}

					[self send:uppercaseCommand, nickname, shtime, reason, nil];
				}
			}

			break;
		}
		case 5006: // Command: CAP
		case 5007: // Command: CAPS
		{
			if (NSObjectIsNotEmpty(self.CAPacceptedCaps)) {
				NSString *caps = [self.CAPacceptedCaps componentsJoinedByString:@", "];

				[self printDebugInformation:TXTFLS(@"IRCCapCurrentlyEnbaled", caps)];
			} else {
				[self printDebugInformation:TXTLS(@"IRCCapCurrentlyEnabledNone")];
			}

			break;
		}
		case 5008: // Command: CCBADGE
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSString *channel = s.getToken.string;
			NSString *bacount = s.getToken.string;

			NSObjectIsEmptyAssert(bacount);

			NSString *ishl = s.getToken.string;

			IRCChannel *oc = [self findChannel:channel];

			PointerIsEmptyAssert(oc);
			
			[oc setTreeUnreadCount:bacount.integerValue];

			if ([ishl isEqualToString:@"-h"]) {
				[oc setNicknameHighlightCount:1];
			}
			
			[self.worldController reloadTreeItem:oc];

			break;
		}
		case 5049: // Command: NNCOLORESET
		{
			if (selChannel && selChannel.isChannel) {
				for (IRCUser *user in [selChannel unsortedMemberList]) {
					user.colorNumber = -1;
				}
			}

			break;
		}
		case 5066: // Command: SSLCONTEXT
		{
			if (self.socket.connectionUsesSSL && self.socket.isConnected) {
				[self.socket openSSLCertificateTrustDialog];
			}
			
			break;
		}
		case 5087: // Command: FAKERAWDATA
		{
			[self ircConnectionDidReceive:s.string];

			break;
		}
		case 5098: // Command: GETSCRIPTS
		{
			NSString *installer = [RZMainBundle() pathForResource:@"Textual IRC Client Extras" ofType:@"pkg" inDirectory:@"Script Installers"];
			
			[RZWorkspace() openFile:installer withApplication:@"Installer"];

			break;
		}
		case 5099: // Command: GOTO
		{
			NSObjectIsEmptyAssertLoopBreak(uncutInput);
			
			NSMutableArray *results = [NSMutableArray array];
			
			for (IRCClient *client in [self.worldController clients]) {
				for (IRCChannel *channel in [client channels]) {
					NSString *name = [channel.name channelNameTokenByTrimmingAllPrefixes:self];
					
					NSInteger score = [uncutInput compareWithWord:name matchGain:10 missingCost:1];
					
					[results addObject:@{@"score" : @(score), @"item" : channel}];
				}
			}
			
			NSObjectIsEmptyAssertLoopBreak(results);

			[results sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
				return [obj1[@"score"] compare:obj2[@"score"]];
			}];
			
			NSDictionary *topResult = (id)results[0];
			
			[self.worldController select:topResult[@"item"]];
			
			break;
		}
		case 5092: // Command: DEFAULTS
		{
			/* Check base string. */
			if (NSObjectIsEmpty(uncutInput)) {
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];

				return;
			}

			/* Begin processing input. */
			NSString *section1 = [s.getToken string];
			NSString *section2 = [s.getTokenIncludingQuotes string];
			NSString *section3 = [s.getTokenIncludingQuotes string];

			NSArray *providedKeys = @[@"Send Authentication Requests to UserServ"];

			if (NSObjectsAreEqual(section1, @"help"))
			{
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_01")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_02")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_03")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_04")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_05")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_06")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_07")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_08")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_09")];
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandHelpInformation_10")];
			}
			else if (NSObjectsAreEqual(section1, @"features"))
			{
				[TLOpenLink openWithString:@"http://www.codeux.com/textual/wiki/Command-Reference.wiki?command=defaults"];
			}
			else if (NSObjectsAreEqual(section1, @"enable"))
			{
				if (NSObjectIsEmpty(section2)) {
					[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];
				} else {
					if ([providedKeys containsObject:section2] == NO) {
						[self printDebugInformation:TXTFLS(@"ClientAuxiliaryConfigurationCommandFeatureCannotEnable", section2)];
					} else {
						[[self auxiliaryConfiguration] setBool:YES forKey:section2];

						[self printDebugInformation:TXTFLS(@"ClientAuxiliaryConfigurationCommandFeatureEnabled", section2)];
					}
				}
			}
			else if (NSObjectsAreEqual(section1, @"disable"))
			{
				if (NSObjectIsEmpty(section2)) {
					[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];
				} else {
					if ([providedKeys containsObject:section2] == NO) {
						[self printDebugInformation:TXTFLS(@"ClientAuxiliaryConfigurationCommandFeatureCannotDisable", section2)];
					} else {
						[[self auxiliaryConfiguration] setBool:NO forKey:section2];

						[self printDebugInformation:TXTFLS(@"ClientAuxiliaryConfigurationCommandFeatureDisabled", section2)];
					}
				}
			}
			else if (NSObjectsAreEqual(section1, @"write"))
			{
				if (NSObjectIsEmpty(section2)) {
					[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];
				} else {
					[[self auxiliaryConfiguration] setObject:section3 forKey:section2];
				}
			}
			else if (NSObjectsAreEqual(section1, @"read"))
			{
				id settingValue;

				if (NSObjectIsEmpty(section2)) {
					settingValue =  [self auxiliaryConfiguration];
				} else {
					settingValue = [[self auxiliaryConfiguration] objectForKey:section2];
				}

				NSString *message = [NSString stringWithFormat:@"%@", settingValue];

				NSArray *messages = [message split:NSStringNewlinePlaceholder];

				for (NSString *value in messages) {
					[self printDebugInformation:[NSString stringWithFormat:@"%@ => %@", section2, value]];
				}
			}
			else if (NSObjectsAreEqual(section1, @"delete"))
			{
				if (NSObjectIsEmpty(section2)) {
					[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];
				} else {
					[[self auxiliaryConfiguration] removeObjectForKey:section2];
				}
			}
			else
			{
				[self printDebugInformation:TXTLS(@"ClientAuxiliaryConfigurationCommandInvalidSyntaxError")];
			}

			break;
		}
		default:
		{
			/* Scan scripts first. */
			NSDictionary *scriptPaths = [THOPluginManagerSharedInstance() supportedAppleScriptCommands:YES];

			NSString *scriptPath;

			for (NSString *scriptCommand in scriptPaths) {
				if ([scriptCommand isEqualToString:lowercaseCommand]) {
					scriptPath = [scriptPaths objectForKey:lowercaseCommand];
				}
			}

			BOOL scriptFound = NSObjectIsNotEmpty(scriptPath);

			/* Scan plugins second. */
			BOOL pluginFound = [[THOPluginManagerSharedInstance() supportedUserInputCommands] containsObject:lowercaseCommand];

			/* Perform script or plugin. */
			if (pluginFound && scriptFound) {
				LogToConsole(TXTLS(@"PluginCommandClashErrorMessage"), uppercaseCommand);
			} else {
				if (pluginFound) {
					[self processBundlesUserMessage:uncutInput command:lowercaseCommand];
					
					return;
				} else {
					if (scriptFound) {
						NSDictionary *inputInfo = @{
							@"path"				: scriptPath,
							@"input"			: uncutInput,
							@"completeTarget"	: @(completeTarget),
							@"channel"			: NSStringNilValueSubstitute(selChannel.name),
							@"target"			: NSStringNilValueSubstitute(targetChannelName)
						};
						
						[self executeTextualCmdScript:inputInfo];
						
						return;
					}
				}
			}

			/* Panic. Send to server. */
			uncutInput = [NSString stringWithFormat:@"%@ %@", uppercaseCommand, uncutInput];
			
			[self sendLine:uncutInput];
			
			break;
		}
	}
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logTranscript]) {
		PointerIsEmptyAssert(self.logFile);

		[self.logFile reopenIfNeeded];
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	PointerIsEmptyAssert(self.logFile);

	[self.logFile close];
}

- (void)writeToLogFile:(TVCLogLine *)line
{
	if ([TPCPreferences logTranscript]) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];
			self.logFile.client = self;
		}

		[self.logFile writeLine:line];
	}
}

- (void)logFileRecordSessionChanges:(BOOL)newSession /* @private */
{
	NSString *langkey = @"LogFileBeginOfSessionHeader";

	if (newSession == NO) {
		langkey = @"LogFileEndOfSessionHeader";
	}

	TVCLogLine *top = [TVCLogLine newManagedObjectWithoutContextAssociation];
	TVCLogLine *mid = [TVCLogLine newManagedObjectWithoutContextAssociation];
	TVCLogLine *end = [TVCLogLine newManagedObjectWithoutContextAssociation];

	[mid setMessageBody:TXTLS(langkey)];
	[top setMessageBody:NSStringWhitespacePlaceholder];
	[end setMessageBody:NSStringWhitespacePlaceholder];

	[self writeToLogFile:top];
	[self writeToLogFile:mid];
	[self writeToLogFile:end];

	for (IRCChannel *channel in self.channels) {
		[channel writeToLogFile:top];
		[channel writeToLogFile:mid];
		[channel writeToLogFile:end];
	}

	top = nil;
	mid = nil;
	end = nil;
}

- (void)logFileWriteSessionBegin
{
	[self logFileRecordSessionChanges:YES];
}

- (void)logFileWriteSessionEnd
{
	[self logFileRecordSessionChanges:NO];
}

#pragma mark -
#pragma mark Print

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel
{
	return [self formatNick:nick channel:channel formatOverride:nil];
}

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel formatOverride:(NSString *)forcedFormat
{
	/* Validate input. */
	NSObjectIsEmptyAssertReturn(nick, nil);

	PointerIsEmptyAssertReturn(channel, nil);

	/* Define default formats. */
	NSString *nmformat = [TPCPreferences themeNicknameFormat];

	NSString *override = self.themeController.customSettings.nicknameFormat;

	/* Use theme based format? */
	if (NSObjectIsNotEmpty(override)) {
		nmformat = override;
	}

	/* Use default format? */
	if (NSObjectIsEmpty(nmformat)) {
		nmformat = TXLogLineUndefinedNicknameFormat;
	}

	/* Use a forced format? */
	if (NSObjectIsNotEmpty(forcedFormat)) {
		nmformat = forcedFormat;
	}

	/* Find mark character. */
	NSString *mark = NSStringEmptyPlaceholder;

	if (channel && channel.isChannel) {
		IRCUser *m = [channel memberWithNickname:nick];

		if (m && NSObjectIsNotEmpty(m.mark)) {
			mark = m.mark;
		}
	}

	/* Begin parsing format string. */
	NSString *formatMarker = @"%";
	NSString *chunk = nil;

	NSScanner *scanner = [NSScanner scannerWithString:nmformat];

	[scanner setCharactersToBeSkipped:nil];

	NSMutableString *buffer = [NSMutableString new];

	/* Loop for actual scanner. */
	while ([scanner isAtEnd] == NO) {
		/* Read any static characters into buffer. */
		if ([scanner scanUpToString:formatMarker intoString:&chunk] == YES) {
			[buffer appendString:chunk];
		}

		/* Eat the format marker. */
		if ([scanner scanString:formatMarker intoString:nil] == NO) {
			break;
		}

		/* Read width specifier (may be empty). */
		NSInteger width = 0;

		[scanner scanInteger:&width];

		/* Read the output type marker. */
		NSString *oValue = nil;

		if ([scanner scanString:@"@" intoString:nil] == YES) {
			oValue = mark; // User mode mark.
		} else if ([scanner scanString:@"n" intoString:nil] == YES) {
			oValue = nick; // Actual nickname.
		} else if ([scanner scanString:formatMarker intoString:nil] == YES) {
			oValue = formatMarker; // Format marker.
		}

		if (PointerIsNotEmpty(oValue)) {
			/* Check math and perform final append. */
			if (width < 0 && ABS(width) > oValue.length) {
				[buffer appendString:[@"" stringByPaddingToLength:(ABS(width) - oValue.length) withString:@" " startingAtIndex:0]];
			}

			[buffer appendString:oValue];

			if (width > 0 && width > oValue.length) {
				[buffer appendString:[@"" stringByPaddingToLength:(width - oValue.length) withString:@" " startingAtIndex:0]];
			}
		}
	}

	return [NSString stringWithString:buffer];
}

- (void)printAndLog:(TVCLogLine *)line completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	[self.viewController print:line completionBlock:completionBlock];
	
	[self writeToLogFile:line];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text command:(NSString *)command
{
	[self print:chan type:type nick:nick text:text encrypted:NO receivedAt:[NSDate date] command:command message:nil completionBlock:NULL];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	[self print:chan type:type nick:nick text:text encrypted:NO receivedAt:receivedAt command:command message:nil completionBlock:NULL];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	[self print:chan type:type nick:nick text:text encrypted:isEncrypted receivedAt:receivedAt command:command message:nil completionBlock:NULL];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command message:(IRCMessage *)rawMessage
{
	[self print:chan type:type nick:nick text:text encrypted:isEncrypted receivedAt:receivedAt command:command message:rawMessage completionBlock:NULL];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command message:(IRCMessage *)rawMessage completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	NSObjectIsEmptyAssert(text);
	NSObjectIsEmptyAssert(command);
	
	if ([self outputRuleMatchedInMessage:text inChannel:chan withLineType:type] == YES) {
		return;
	}

	IRCChannel *channel = nil;

	TVCLogLineMemberType memberType = TVCLogLineMemberNormalType;

	NSInteger colorNumber = 0;

	NSArray *matchKeywords = nil;
	NSArray *excludeKeywords = nil;

	if (nick && [nick isEqualToString:self.localNickname]) {
		memberType = TVCLogLineMemberLocalUserType;
	}

	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = chan;
	} else {
		/* We only want chan to be an IRCChannel for an actual
		 channel or nil for the console. Anything else should be
		 ignored and stopped from printing. */

		NSObjectIsNotEmptyAssert(chan);
	}

	if ((type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType) && memberType == TVCLogLineMemberNormalType) {
		if (channel && [channel.config ignoreHighlights] == NO) {
			matchKeywords = [TPCPreferences highlightMatchKeywords];
			excludeKeywords = [TPCPreferences highlightExcludeKeywords];

			if (([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) == NO) {
				if ([TPCPreferences highlightCurrentNickname]) {
					matchKeywords = [matchKeywords arrayByAddingObject:[self localNickname]];
				}
			}
		}
	}

	if (type == TVCLogLineActionNoHighlightType) {
		type = TVCLogLineActionType;
	} else if (type == TVCLogLinePrivateMessageNoHighlightType) {
		type = TVCLogLinePrivateMessageType;
	}

	if (self.isLoggedIn == NO && NSObjectIsEmpty(nick)) {
		if (type == TVCLogLinePrivateMessageType ||
			type == TVCLogLineActionType ||
			type == TVCLogLineNoticeType)
		{
			nick = [self.config nickname];

			memberType = TVCLogLineMemberLocalUserType;
		}
	}

	if (nick && channel && (type == TVCLogLinePrivateMessageType ||
							type == TVCLogLineActionType))
	{
		IRCUser *user = [channel memberWithNickname:nick];

		if (user) {
			colorNumber = user.colorNumber;
		}
	} else {
		colorNumber = -1;
	}

	/* Create new log entry. */
	TVCLogLine *c = [TVCLogLine newManagedObjectForClient:self channel:channel];

	/* Data types. */
	c.lineType				= type;
	c.memberType			= memberType;

	/* Encrypted message? */
	c.isEncrypted           = isEncrypted;

	/* Highlight words. */
	c.excludeKeywords		= excludeKeywords;
	c.highlightKeywords		= matchKeywords;

	/* Message body. */
	c.messageBody			= text;

	/* Sender. */
	c.nickname				= nick;
	c.nicknameColorNumber	= @(colorNumber);

	/* Send date. */
	c.receivedAt			= receivedAt;

	/* Actual command. */
	c.rawCommand			= [command lowercaseString];

	if (channel) {
		if ([TPCPreferences autoAddScrollbackMark]) {
			if (NSDissimilarObjects(channel, self.worldController.selectedChannel) || self.masterController.mainWindowIsActive == NO) {
				if (channel.isUnread == NO) {
					if (type == TVCLogLinePrivateMessageType ||
						type == TVCLogLineActionType ||
						type == TVCLogLineNoticeType)
					{
						[channel.viewController mark];
					}
				}
			}
		}

		[channel print:c completionBlock:completionBlock];
	} else {
		[self printAndLog:c completionBlock:completionBlock];
	}
}

- (void)printReply:(IRCMessage *)m
{
	[self print:nil type:TVCLogLineDebugType nick:nil text:[m sequence:1] encrypted:NO receivedAt:m.receivedAt command:m.command message:nil completionBlock:NULL];
}

- (void)printUnknownReply:(IRCMessage *)m
{
	[self print:nil type:TVCLogLineDebugType nick:nil text:[m sequence:1] encrypted:NO receivedAt:m.receivedAt command:m.command message:nil completionBlock:NULL];
}

- (void)printDebugInformation:(NSString *)m
{
	[self print:[self.worldController selectedChannelOn:self] type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:TXLogLineDefaultRawCommandValue message:nil completionBlock:NULL];
}

- (void)printDebugInformation:(NSString *)m forCommand:(NSString *)command
{
	[self print:[self.worldController selectedChannelOn:self] type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:command message:nil completionBlock:NULL];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[self print:nil type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:TXLogLineDefaultRawCommandValue message:nil completionBlock:NULL];
}

- (void)printDebugInformationToConsole:(NSString *)m forCommand:(NSString *)command
{
	[self print:nil type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:command message:nil completionBlock:NULL];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel
{
	[self print:channel type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:TXLogLineDefaultRawCommandValue message:nil completionBlock:NULL];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel command:(NSString *)command
{
	[self print:channel type:TVCLogLineDebugType nick:nil text:m encrypted:NO receivedAt:[NSDate date] command:command message:nil completionBlock:NULL];
}

- (void)printErrorReply:(IRCMessage *)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel
{
	NSString *text = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence]);

	[self print:channel type:TVCLogLineDebugType nick:nil text:text encrypted:NO receivedAt:m.receivedAt command:m.command message:nil completionBlock:NULL];
}

- (void)printError:(NSString *)error forCommand:(NSString *)command
{
	[self print:nil type:TVCLogLineDebugType nick:nil text:error encrypted:NO receivedAt:[NSDate date] command:command message:nil completionBlock:NULL];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)resetAllPropertyValues
{
	self.tryingNickNumber = -1;

	self.CAPawayNotify = NO;
	self.CAPidentifyCTCP = NO;
	self.CAPidentifyMsg = NO;
	self.CAPinSASLRequest = NO;
	self.CAPisIdentifiedWithSASL = NO;
	self.CAPmultiPrefix = NO;
	self.CAPWatchCommand = NO;
	self.CAPpausedStatus = 0;
	self.CAPuserhostInNames = NO;
	self.CAPServerTime = NO;
	
	self.autojoinInProgress = NO;
	self.hasIRCopAccess = NO;
	self.inFirstISONRun = NO;
	self.inUserInvokedNamesRequest = NO;
	self.inUserInvokedWatchRequest = NO;
	self.inUserInvokedWhoRequest = NO;
	self.inUserInvokedWhowasRequest = NO;
	self.inUserInvokedModeRequest = NO;
	self.inUserInvokedJoinRequest = NO;
	self.inUserInvokedWatchRequest = NO;
	self.isZNCBouncerConnection = NO;
	self.isAutojoined = NO;
	self.isAway = NO;
	self.isConnected = NO;
	self.isConnecting = NO;
	self.isIdentifiedWithNickServ = NO;
	self.isLoggedIn = NO;
	self.isQuitting = NO;
	self.isWaitingForNickServ = NO;
	self.reconnectEnabled = NO;
	self.sendLagcheckReplyToChannel = NO;
	self.serverHasNickServ = NO;
	self.timeoutWarningShownToUser = NO;

	self.myHost = nil;
	self.myNick = self.config.nickname;
	self.sentNick = self.config.nickname;

	self.serverRedirectAddressTemporaryStore = nil;
	self.serverRedirectPortTemporaryStore = 0;

	self.lastLagCheck = 0;
	self.lastMessageReceived = 0;

	[self.CAPacceptedCaps removeAllObjects];
	[self.CAPpendingCaps removeAllObjects];
	[self.commandQueue removeAllObjects];
}

- (void)changeStateOff
{
	if (self.isLoggedIn == NO && self.isConnecting == NO) {
		return;
	}
	
	self.socket = nil;

	[self stopPongTimer];
	[self stopRetryTimer];
	[self stopISONTimer];

#ifdef TEXTUAL_TRIAL_BINARY
	[self stopTrialPeriodTimer];
#endif

	if (self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	[self.isupport reset];

	NSString *dcntmsg = nil;

	switch (self.disconnectType) {
		case IRCDisconnectNormalMode:				{ dcntmsg = @"IRCDisconnectedFromServer"; break; }
		case IRCDisconnectComputerSleepMode:		{ dcntmsg = @"IRCDisconnectedBySleepMode"; break; }
		case IRCDisconnectTrialPeriodMode:			{ dcntmsg = @"IRCDisconnectedByTrialPeriodTimer"; break; }
		case IRCDisconnectBadSSLCertificateMode:	{ dcntmsg = @"IRCDisconnectedByBadSSLCertificate"; break; }
		case IRCDisconnectServerRedirectMode:		{ dcntmsg = @"IRCDisconnectedByServerRedirect"; break; }
		case IRCDisconnectReachabilityChangeMode:	{ dcntmsg = @"IRCDisconnectedByReachabilityChange"; break; }
		default: break;
	}

	if (dcntmsg) {
		for (IRCChannel *c in self.channels) {
			if (c.isActive) {
				[c deactivate];

				[self printDebugInformation:TXTLS(dcntmsg) channel:c];
			}
		}

        [self.viewController mark];
        
		[self printDebugInformationToConsole:TXTLS(dcntmsg)];

		if (self.isConnected) {
			[self notifyEvent:TXNotificationDisconnectType lineType:TVCLogLineDebugType];
		}
	}

	[self logFileWriteSessionEnd];
	[self resetAllPropertyValues];

	[self.worldController reloadTreeGroup:self];
}

- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	[self startRetryTimer];

	[self printDebugInformationToConsole:TXTLS(@"IRCConnectedToServer")];

	self.isLoggedIn	= NO;
	self.isConnected = YES;
	self.reconnectEnabled = YES;

	self.sentNick = self.config.nickname;
	self.myNick = self.config.nickname;

	[self.isupport reset];

	NSString *userName = self.config.username;
	NSString *realName = self.config.realname;
	NSString *modeParam = @"0";

	if (self.config.invisibleMode) {
		modeParam = @"8";
	}

	if (NSObjectIsEmpty(userName)) {
		userName = self.config.nickname;
	}

	if (NSObjectIsEmpty(realName)) {
		realName = self.config.nickname;
	}

	[self send:IRCPrivateCommandIndex("cap"), @"LS", nil];

	if (self.config.serverPasswordIsSet) {
		[self send:IRCPrivateCommandIndex("pass"), self.config.serverPassword, nil];
	}

	[self send:IRCPrivateCommandIndex("nick"), self.sentNick, nil];
	[self send:IRCPrivateCommandIndex("user"), userName, modeParam, @"*", realName, nil];

	[self.worldController reloadTreeGroup:self];
}

#pragma mark -

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender withError:(NSError *)distcError;
{
	[self disconnect];
	
	if (self.disconnectType == IRCDisconnectBadSSLCertificateMode) {
		[self cancelReconnect];
		
		if (distcError) {
			SecTrustRef trustRef = (__bridge SecTrustRef)([distcError.userInfo objectForKey:@"peerCertificateTrustRef"]);

			if (trustRef) {
				SFCertificateTrustPanel *panel = [SFCertificateTrustPanel sharedCertificateTrustPanel];
				
				[panel setAlternateButtonTitle:TXTLS(@"CancelButton")];
				[panel setInformativeText:TXTLS(@"SocketBadSSLCertificateErrorMessage")];
				
				NSInteger returnCode = [panel runModalForTrust:trustRef message:TXTLS(@"SocketBadSSLCertificateErrorTitle")];
				
				if (returnCode == NSAlertDefaultReturn) {
					[self connect:IRCConnectBadSSLCertificateMode];
				}
			}
		}
	}
}

#pragma mark -

- (void)ircConnectionDidError:(NSString *)error
{
	[self printError:error forCommand:TXLogLineDefaultRawCommandValue];
}

- (void)ircConnectionDidReceive:(NSString *)data
{
	NSString *s = data;

	self.lastMessageReceived = [NSDate epochTime];

	NSObjectIsEmptyAssert(s);

	self.worldController.messagesReceived++;
	self.worldController.bandwidthIn += s.length;

	[self logToConsoleIncomingTraffic:s];

	/* We are terminating and thusly do not give a shit about the data
	 and our view is probably gone by now anyways */
	if (self.masterController.terminating) {
		return;
	}

	if ([TPCPreferences removeAllFormatting]) {
		s = [s stripIRCEffects];
	}

	IRCMessage *m = [IRCMessage new];

	[m parseLine:s forClient:self];

    /* Intercept input. */
    m = [THOPluginManagerSharedInstance() processInterceptedServerInput:m for:self];

    PointerIsEmptyAssert(m);

	if (m.numericReply > 0) {
		[self receiveNumericReply:m];
	} else {
		NSInteger switchNumeric = [TPCPreferences indexOfIRCommand:m.command publicSearch:NO];

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
			{
				[m.params safeInsertObject:self.localNickname atIndex:0];

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
				if (self.isZNCBouncerConnection == NO) {
					/* ZNC sends CAPs using its own server hostmask so we will use that to detect 
					 if the connection is ZNC based. */

					if ([@"irc.znc.in" isEqualToString:m.sender.nickname] && m.sender.isServer) {
						self.isZNCBouncerConnection = YES;

						DebugLogToConsole(@"ZNC based connection detected…");
					}
				}
				
				[self receiveCapacityOrAuthenticationRequest:m];
				
				break;
			}
            case 1050: // Command: AWAY (away-notify CAP)
            {
                [self receiveAwayNotifyCapacity:m];
            }
		}
	}

	[self processBundlesServerMessage:m];
}

- (void)ircConnectionWillSend:(NSString *)line
{
	[self logToConsoleOutgoingTraffic:line];
}

- (void)logToConsoleOutgoingTraffic:(NSString *)line
{
	if (self.rawModeEnabled) {
		LogToConsole(@"OUTGOING [\"%@\"]: << %@", self.altNetworkName, line);
	}
}

- (void)logToConsoleIncomingTraffic:(NSString *)line
{
	if (self.rawModeEnabled) {
		LogToConsole(@"INCOMING [\"%@\"]: >> %@", self.altNetworkName, line);
	}
}

#pragma mark -
#pragma mark NickServ Information

- (NSArray *)nickServSupportedNeedIdentificationTokens
{
    return @[
        @"nickname is owned",
        @"nickname is registered",
        @"owned by someone else",
        @"nick belongs to another user",
        @"if you do not change your nickname",
        @"authentication required",
        @"authenticate yourself",
        @"identify yourself",
		@"type /msg NickServ IDENTIFY password"
    ];
}

- (NSArray *)nickServSupportedSuccessfulIdentificationTokens
{
    return @[
            @"now recognized",
			@"automatically identified",
            @"already identified",
            @"successfully identified",
            @"you are already logged in",
            @"you are now identified",
            @"password accepted"
        ];
}

#pragma mark -
#pragma mark Protocol Handlers

- (void)receivePrivmsgAndNotice:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 2);
	
	NSString *text = [m paramAt:1];

	if (self.CAPidentifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		text = [text safeSubstringFromIndex:1];
	} else if (self.CAPidentifyMsg && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
		text = [text safeSubstringFromIndex:1];
	}

	if ([text hasPrefix:@"\x01"]) {
		text = [text safeSubstringFromIndex:1];

		NSInteger n = [text stringPosition:@"\x01"];

		if (n >= 0) {
			text = [text safeSubstringToIndex:n];
		}

		if ([m.command isEqualToString:IRCPrivateCommandIndex("privmsg")]) {
			if ([text.uppercaseString hasPrefix:@"ACTION "]) {
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

- (void)receiveText:(IRCMessage *)m command:(NSString *)command text:(NSString *)text
{
	NSAssertReturn(m.params.count >= 1);

	NSObjectIsEmptyAssert(command);

	if ([command isEqualToString:IRCPrivateCommandIndex("action")] == NO) {
		/* Allow in actions without a body. */
		
		NSObjectIsEmptyAssert(text);
	} else {
		if (NSObjectIsEmpty(text)) {
			/* Use a single space if an action is empty. */

			text = NSStringWhitespacePlaceholder;
		}
	}
	
	NSString *sender = m.sender.nickname;
	NSString *target = [m paramAt:0];
	
	BOOL isEncrypted = NO;

	/* Message type. */
	TVCLogLineType type = TVCLogLinePrivateMessageType;

	if ([command isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([command isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	}

	/* Operator message? */
	if ([target hasPrefix:@"@"]) {
		target = [target safeSubstringFromIndex:1];
	}

	/* Ignore dictionary. */
	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
														withMatches:@[	@"ignoreHighlights",
																		@"ignorePMHighlights",
																		@"ignoreNotices",
																		@"ignorePublicMsg",
																		@"ignorePrivateMsg"	]];


	/* Ignore highlights? */
	if ([ignoreChecks ignorePublicHighlights] == YES) {
		if (type == TVCLogLineActionType) {
			type = TVCLogLineActionNoHighlightType;
		} else if (type == TVCLogLinePrivateMessageType) {
			type = TVCLogLinePrivateMessageNoHighlightType;
		}
	}

	/* Is the target a channel? */
	if ([target isChannelName:self]) {
		/* Ignore message? */
		if ([ignoreChecks ignoreNotices] && type == TVCLogLineNoticeType) {
			return;
		} else if ([ignoreChecks ignorePublicMessages]) {
			return;
		}

		/* Does the target exist? */
		IRCChannel *c = [self findChannel:target];

		PointerIsEmptyAssert(c);

		/* Is it encrypted? If so, decrypt. */
		isEncrypted = [self isMessageEncrypted:text channel:c];

		if (isEncrypted) {
			[self decryptIncomingMessage:&text channel:c];
		}

		if (type == TVCLogLineNoticeType) {
			/* Post notice and inform Growl. */

			[self print:c
				   type:type
				   nick:sender
				   text:text
			  encrypted:isEncrypted
			 receivedAt:m.receivedAt
				command:m.command
				message:m];

			if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
				[self notifyText:TXNotificationChannelNoticeType lineType:type target:c nick:sender text:text];
			}
		} else {
			/* Post regular message and inform Growl. */
			
			[self print:c
				   type:type
				   nick:sender
				   text:text
			  encrypted:isEncrypted
			 receivedAt:m.receivedAt
				command:m.command
				message:m
		completionBlock:^(BOOL highlight)
			 {
				 if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
					 BOOL postevent = NO;

					 if (highlight) {
						 postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nick:sender text:text];

						 if (postevent) {
							 [self setKeywordState:c];
						 }
					 } else {
						 postevent = [self notifyText:TXNotificationChannelMessageType lineType:type target:c nick:sender text:text];
					 }

					 /* Mark channel as unread. */
					 if (postevent) {
						 [self setUnreadState:c isHighlight:highlight];
					 }
				 } else {
					 if (highlight) {
						 [self setKeywordState:c];
					 }
					 
					 [self setUnreadState:c isHighlight:highlight];
				 }
			}];

			/* Weights. */
			IRCUser *owner = [c memberWithNickname:sender];

			PointerIsEmptyAssert(owner);

			NSString *trimmedMyNick = [self.localNickname trimCharacters:@"_"]; // Remove any underscores from around nickname. (Guest___ becomes Guest)

			/* If we are mentioned in this piece of text, then update our weight for the user. */
			if ([text stringPositionIgnoringCase:trimmedMyNick] >= 0) {
				[owner outgoingConversation];
			} else {
				[owner conversation];
			}
		}
	}
	else // The target is not a channel.
	{
		/* Is the sender a server? */
		if ([sender isNickname:self] == NO) {
			if ([text hasPrefix:@"*** Your codepage is '"] && [text hasSuffix:@"'"]) {
				self.isupport.networkUsesCodepageModule = YES;
			}
			
			[self print:nil type:type nick:nil text:text receivedAt:m.receivedAt command:m.command];
		} else {
			/* Ignore message? */
			if ([ignoreChecks ignoreNotices] && type == TVCLogLineNoticeType) {
				return;
			} else if ([ignoreChecks ignorePrivateMessages]) {
				return;
			}

			/* Does the query for the sender already exist?… */
			IRCChannel *c = [self findChannel:sender];

			BOOL newPrivateMessage = NO;

			if (PointerIsEmpty(c) && NSDissimilarObjects(type, TVCLogLineNoticeType)) {
				c = [self.worldController createPrivateMessage:sender client:self];

				newPrivateMessage = YES;
			}

			/* Is the message encrypted? If so, decrypt. */
			isEncrypted = [self isMessageEncrypted:text channel:c];

			if (isEncrypted) {
				[self decryptIncomingMessage:&text channel:c];
			}

			if (type == TVCLogLineNoticeType) {
				/* Where do we send a notice if it is not from a server? */
				if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
					c = [self.worldController selectedChannelOn:self];
				}

				if ([sender isEqualIgnoringCase:@"ChanServ"]) {
					/* Forward entry messages to the channel they are associated with. */
					/* Format we are going for: -ChanServ- [#channelname] blah blah… */
					NSInteger spacePos = [text stringPosition:NSStringWhitespacePlaceholder];

					if ([text hasPrefix:@"["] && spacePos > 3) {
						NSString *textHead = [text safeSubstringToIndex:spacePos];

						if ([textHead hasSuffix:@"]"]) {
							textHead = [textHead safeSubstringToIndex:(textHead.length - 1)]; // Remove the ]
							textHead = [textHead safeSubstringFromIndex:1]; // Remove the [

							if ([textHead isChannelName:self]) {
								IRCChannel *thisChannel = [self findChannel:textHead];

								if (thisChannel) {
									text = [text safeSubstringFromIndex:(textHead.length + 2)]; // Remove the [#channelname] from the text.'

									c = thisChannel;
								}
							}
						}
					}
				} else if ([sender isEqualIgnoringCase:@"NickServ"]) {
					self.serverHasNickServ = YES;
					
                    BOOL continueNickServScan = YES;
					
					NSString *cleanedText = text;
					
					if ([TPCPreferences removeAllFormatting] == NO) {
						cleanedText = [cleanedText stripIRCEffects];
					}
					
					if (self.isWaitingForNickServ == NO) {
						/* Scan for messages telling us that we need to identify. */
						for (NSString *token in [self nickServSupportedNeedIdentificationTokens]) {
							if ([cleanedText containsIgnoringCase:token]) {
								continueNickServScan = NO;
								
								NSAssertReturnLoopContinue(self.config.nicknamePasswordIsSet);
								
								NSString *IDMessage = [NSString stringWithFormat:@"IDENTIFY %@", self.config.nicknamePassword];
								
								if ([[self networkAddress] hasSuffix:@"dal.net"]) {
									self.isWaitingForNickServ = YES;
									
									[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ@services.dal.net", IDMessage, nil];
								} else {
									if (self.CAPisIdentifiedWithSASL == NO) {
										self.isWaitingForNickServ = YES;

										/* Check auxiliary configuration. */
										BOOL sendToUserServ = [self.auxiliaryConfiguration boolForKey:@"Send Authentication Requests to UserServ"];

										if (sendToUserServ) {
											IDMessage = [NSString stringWithFormat:@"login %@ %@", self.config.nickname, self.config.nicknamePassword];

											[self send:IRCPrivateCommandIndex("privmsg"), @"userserv", IDMessage, nil];
										} else {
											[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ", IDMessage, nil];
										}
									}
								}
								
								break;
							}
						}
					}
					
                    /* Scan for messages telling us that we are now identified. */
                    if (continueNickServScan) {
                        for (NSString *token in [self nickServSupportedSuccessfulIdentificationTokens]) {
                            if ([cleanedText containsIgnoringCase:token]) {
                                self.isIdentifiedWithNickServ = YES;
								self.isWaitingForNickServ = NO;
                                
                                if ([TPCPreferences autojoinWaitsForNickServ]) {
                                    if (self.isAutojoined == NO) {
                                        [self performAutoJoin];
                                    }
                                }
                            }
                        }
                    }
				}
				
				/* Post the notice. */
				[self print:c
					   type:type
					   nick:sender
					   text:text
				  encrypted:isEncrypted
				 receivedAt:m.receivedAt
					command:m.command
					message:m];

				/* Set the query as unread and inform Growl. */
				[self setUnreadState:c];

				if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
					[self notifyText:TXNotificationPrivateNoticeType lineType:type target:c nick:sender text:text];
				}
			} else {
				/* Post regular message and inform Growl. */
				[self print:c
					   type:type
					   nick:sender
					   text:text
				  encrypted:isEncrypted
				 receivedAt:m.receivedAt
					command:m.command
					message:m
			completionBlock:^(BOOL highlight)
				 {
					 if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
						 BOOL postevent = NO;

						 if (highlight) {
							 postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nick:sender text:text];

							 if (postevent) {
								 [self setKeywordState:c];
							 }
						 } else {
							 if (newPrivateMessage) {
								 postevent = [self notifyText:TXNotificationNewPrivateMessageType lineType:type target:c nick:sender text:text];
							 } else {
								 postevent = [self notifyText:TXNotificationPrivateMessageType lineType:type target:c nick:sender text:text];
							 }
						 }

						 /* Mark query as unread. */
						 if (postevent) {
							 [self setUnreadState:c isHighlight:highlight];
						 }
					 } else {
						 if (highlight) {
							 [self setKeywordState:c];
						 }

						 [self setUnreadState:c isHighlight:highlight];
					 }
				 }];

				/* Set the query topic to the host of the sender. */
				NSString *hostTopic = m.sender.hostmask;

				if ([hostTopic isEqualIgnoringCase:c.topic] == NO) {
					[c setTopic:hostTopic];

                    [self.worldController updateTitleFor:c];
				}

				/* Update query status. */
				if (c.isActive == NO) {
					[c activate];

					[self.worldController reloadTreeItem:c];
				}
			}
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSObjectIsEmptyAssert(text);

	NSMutableString *s = text.mutableCopy;

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
														withMatches:@[@"ignoreCTCP",
																	  @"ignoreFileTransferRequests"]];

	NSAssertReturn([ignoreChecks ignoreCTCP] == NO);

	NSString *sendern = m.sender.nickname;
	NSString *command = s.getToken.uppercaseString;
	
	NSObjectIsEmptyAssert(command);

	if ([TPCPreferences replyToCTCPRequests] == NO) {
		return [self printDebugInformationToConsole:TXTFLS(@"IRCCTCPRequestIgnored", command, sendern)];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("dcc")]) {
		[self receivedDCCQuery:m message:s ignoreInfo:ignoreChecks];
		
		return; // Above method does all the work.
	} else {
		IRCChannel *target = nil;

		if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
			target = [self.worldController selectedChannelOn:self];
		}

		NSString *textm = TXTFLS(@"IRCRecievedCTCPRequest", command, sendern);

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")] == NO) {
			[self print:target
				   type:TVCLogLineCTCPType
				   nick:nil
				   text:textm
			 receivedAt:m.receivedAt
				command:m.command];
		}

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
			NSAssertReturn(s.length < 50);

			[self sendCTCPReply:sendern command:command text:s];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_time")]) {
			[self sendCTCPReply:sendern command:command text:[[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_cap")]) {
			if ([s isEqualIgnoringCase:@"LS"]) {
				[self sendCTCPReply:sendern command:command text:TXTFLS(@"IRCClientSupportedCapacities")];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")] ||
				   [command isEqualToString:IRCPrivateCommandIndex("ctcp_version")])
		{
			NSString *fakever = [TPCPreferences masqueradeCTCPVersion];

			if (NSObjectIsNotEmpty(fakever)) {
				[self sendCTCPReply:sendern command:command text:fakever];
			} else {
				NSString *name = [TPCPreferences applicationName];
				NSString *vers = [TPCPreferences textualInfoPlist][@"CFBundleVersion"];
				NSString *code = [TPCPreferences textualInfoPlist][@"TXBundleBuildCodeName"];

				NSString *textoc = [NSString stringWithFormat:TXTLS(@"IRCCTCPVersionInfoBasic"), name, vers, code];

				[self sendCTCPReply:sendern command:command text:textoc];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_finger")]) {
			[self sendCTCPReply:sendern command:command text:TXTFLS(@"IRCCTCPFingerCommandReply")];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_clientinfo")]) {
			[self sendCTCPReply:sendern command:command text:TXTLS(@"IRCCTCPSupportedReplies")];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")]) {
			double time = [NSDate epochTime];

			if (time >= self.lastLagCheck && self.lastLagCheck > 0 && [sendern isEqualIgnoringCase:self.localNickname]) {
				double delta = (time - self.lastLagCheck);

				NSString *rating;

					   if (delta < 0.01) {						rating = TXTLS(@"LagCheckRequestReplyRating_00");
				} else if (delta >= 0.01 && delta < 0.1) {		rating = TXTLS(@"LagCheckRequestReplyRating_01");
				} else if (delta >= 0.1 && delta < 0.2) {		rating = TXTLS(@"LagCheckRequestReplyRating_02");
				} else if (delta >= 0.2 && delta < 0.5) {		rating = TXTLS(@"LagCheckRequestReplyRating_03");
				} else if (delta >= 0.5 && delta < 1.0) {		rating = TXTLS(@"LagCheckRequestReplyRating_04");
				} else if (delta >= 1.0 && delta < 2.0) {		rating = TXTLS(@"LagCheckRequestReplyRating_05");
				} else if (delta >= 2.0 && delta < 5.0) {		rating = TXTLS(@"LagCheckRequestReplyRating_06");
				} else if (delta >= 5.0 && delta < 10.0) {		rating = TXTLS(@"LagCheckRequestReplyRating_07");
				} else if (delta >= 10.0 && delta < 30.0) {		rating = TXTLS(@"LagCheckRequestReplyRating_08");
				} else if (delta >= 30.0) {						rating = TXTLS(@"LagCheckRequestReplyRating_09"); }

				textm = TXTFLS(@"LagCheckRequestReplyMessage", [self networkAddress], delta, rating);
			} else {
				textm = TXTLS(@"LagCheckRequestUnknownReply");
			}

			if (self.sendLagcheckReplyToChannel) {
				[self sendPrivmsgToSelectedChannel:textm];

				self.sendLagcheckReplyToChannel = NO;
			} else {
				[self printDebugInformation:textm];
			}

			self.lastLagCheck = 0;
		}
	}
}

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text
{
	NSObjectIsEmptyAssert(text);

	NSMutableString *s = text.mutableCopy;

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.address
														withMatches:@[@"ignoreCTCP"]];

	NSAssertReturn([ignoreChecks ignoreCTCP] == NO);

	NSString *sendern = m.sender.nickname;
	NSString *command = s.getToken.uppercaseString;

	IRCChannel *c = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
		c = [self.worldController selectedChannelOn:self];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
		double delta = ([NSDate epochTime] - [s doubleValue]);
		
		text = TXTFLS(@"IRCRecievedCTCPPingReply", sendern, command, delta);
	} else {
		text = TXTFLS(@"IRCRecievedCTCPReply", sendern, command, s);
	}

	[self print:c
		   type:TVCLogLineCTCPType
		   nick:nil
		   text:text
	 receivedAt:m.receivedAt
		command:m.command];
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 1);
	
	NSString *sendern = m.sender.nickname;
	NSString *channel = [m paramAt:0];

	BOOL myself = [sendern isEqualIgnoringCase:self.localNickname];

	if (self.autojoinInProgress == NO && myself) {
		[self.worldController expandClient:self];
	}

	IRCChannel *c = [self findChannelOrCreate:channel];

	PointerIsEmptyAssert(c);

	if (myself) {
		if (c.status == IRCChannelJoined) {
			return;
		}

		[c activate];

		[self.worldController reloadTreeItem:c];
		
		self.myHost = m.sender.hostmask;

		if (self.autojoinInProgress == NO) {
			if (self.inUserInvokedJoinRequest) {
				[self.worldController expandClient:c.client];
				[self.worldController select:c];
			}

			if (self.inUserInvokedJoinRequest) {
				/* Null out BOOL after first join so a switch does not occur after
				 every single join if the user did a target with more than one channel. */

				self.inUserInvokedJoinRequest = NO;
			}
		}

		if (c.config.encryptionKeyIsSet) {
			[c.client printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
		}
	}

	if (m.isPrintOnlyMessage == NO) {
		if (PointerIsEmpty([c memberWithNickname:sendern])) {
			IRCUser *u = [IRCUser new];
			
			u.nickname = sendern;
			u.username = m.sender.username;
			u.address = m.sender.address;
			
			u.supportInfo = self.isupport;
			
			[c addMember:u];
			
			/* Add to existing query? */
			IRCChannel *query = [self findChannel:sendern];
			
			if (query && query.isActive == NO) {
				[query activate];
				
				[self print:query
					   type:TVCLogLineJoinType
					   nick:nil
					   text:TXTFLS(@"IRCUserReconnectedToPrivateMessage", sendern)
				 receivedAt:m.receivedAt
					command:m.command];
				
				[self.worldController reloadTreeItem:query];
			}
		}
	}

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
														withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

	if (m.isPrintOnlyMessage == NO) {
		[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
	}

	if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
		return;
	}

	if ([TPCPreferences showJoinLeave] || myself) {
		NSString *text = TXTFLS(@"IRCUserJoinedChannel", sendern, m.sender.username, m.sender.address);

		[self print:c
			   type:TVCLogLineJoinType
			   nick:nil
			   text:text
		 receivedAt:m.receivedAt
			command:m.command];
	}

	if (m.isPrintOnlyMessage == NO) {
		[self.worldController updateTitleFor:c];

		if (myself) {
			c.inUserInvokedModeRequest = YES;

			[self send:IRCPrivateCommandIndex("mode"), c.name, nil];
		}
	}
}

- (void)receivePart:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 1);

	NSString *sendern = m.sender.nickname;
	NSString *channel = [m paramAt:0];
	NSString *comment = [m paramAt:1];

	IRCChannel *c = [self findChannel:channel];
	
	PointerIsEmptyAssert(c);

	if (m.isPrintOnlyMessage == NO) {
		if ([sendern isEqualIgnoringCase:self.localNickname]) {
			[c deactivate];

			[self.worldController reloadTreeItem:c];
		}

		[c removeMember:sendern];
	}
	
	BOOL myself = [sendern isEqualIgnoringCase:self.localNickname];

	if ([TPCPreferences showJoinLeave] || myself) {
		IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
															withMatches:@[@"ignoreJPQE"]];

		if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
			return;
		}

		NSString *message = TXTFLS(@"IRCUserPartedChannel", sendern, m.sender.username, m.sender.address);

		if (NSObjectIsNotEmpty(comment)) {
			message = [message stringByAppendingFormat:@" (%@)", comment];
		}

		[self print:c
			   type:TVCLogLinePartType
			   nick:nil
			   text:message
		 receivedAt:m.receivedAt
			command:m.command];
	}

	if (m.isPrintOnlyMessage == NO) {
		[self.worldController updateTitleFor:c];
	}
}

- (void)receiveKick:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 2);
	
	NSString *sendern = m.sender.nickname;
	NSString *channel = [m paramAt:0];
	NSString *targetu = [m paramAt:1];
	NSString *comment = [m paramAt:2];

	IRCChannel *c = [self findChannel:channel];
	
	PointerIsEmptyAssert(c);

	if (m.isPrintOnlyMessage == NO) {
		if ([targetu isEqualIgnoringCase:self.localNickname]) {
			[c deactivate];

			[self.worldController reloadTreeItem:c];

			[self notifyEvent:TXNotificationKickType lineType:TVCLogLineKickType target:c nick:sendern text:comment];

			if ([TPCPreferences rejoinOnKick] && c.errorOnLastJoinAttempt == NO) {
				[self printDebugInformation:TXTLS(@"IRCChannelPreparingRejoinAttempt") channel:c];

				[self performSelector:@selector(joinKickedChannel:) withObject:c afterDelay:3.0];
			}
		}
		
		[c removeMember:targetu];
	}

	BOOL myself = [sendern isEqualIgnoringCase:self.localNickname];

	if ([TPCPreferences showJoinLeave] || myself) {
		IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
															withMatches:@[@"ignoreJPQE"]];

		if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
			return;
		}

		NSString *message = TXTFLS(@"IRCUserKickedFromChannel", sendern, targetu, comment);

		[self print:c
			   type:TVCLogLineKickType
			   nick:nil
			   text:message
		 receivedAt:m.receivedAt
			command:m.command];
	}

	if (m.isPrintOnlyMessage == NO) {
		[self.worldController updateTitleFor:c];
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSString *sendern = m.sender.nickname;
	NSString *comment = [m paramAt:0];
	NSString *target = nil;

	BOOL myself = [sendern isEqualIgnoringCase:self.localNickname];

	IRCAddressBook *ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
														withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

	/* When m.isPrintOnlyMessage is set for quit messages the order in which
	 the paramas is handled is a little different. Index 0 is the target channel
	 for the print and index 1 is the quit message. In a normal quit message, 
	 where m.isPrintOnlyMessage == NO, then 0 is quit message and 1 is nothing. */
	if (m.isPrintOnlyMessage) {
		NSAssert((m.params.count == 2), @"Bad m.isPrintOnlyMessage conditions.");

		comment = [m paramAt:1];
		target = [m paramAt:0];
	}

	/* Continue. */
	NSString *text = TXTFLS(@"IRCUserDisconnected", sendern, m.sender.username, m.sender.address);

	if (NSObjectIsNotEmpty(comment)) {
		NSString *nsrgx = @"^((([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)) (([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)))$";
		
		if ([TLORegularExpression string:comment isMatchedByRegex:nsrgx]) {
			comment = TXTFLS(@"IRCServerHadNetsplitQuitMessage", comment);
		}

		text = [text stringByAppendingFormat:@" (%@)", comment];
	}

	/* Is this a targetted print message? */
	if (m.isPrintOnlyMessage) {
		IRCChannel *c = [self findChannel:target];

		if (c) {
			if ([TPCPreferences showJoinLeave] && [ignoreChecks ignoreJPQE] == NO && c.config.ignoreJPQActivity == NO) {
				[self print:c
					   type:TVCLogLineQuitType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
			}
		}

		/* Once a targetted print occurs, we can stop here. Nothing else
		 ini this method should be used when it is a print only job. */
		return;
	}

	/* Continue with normal operations. */
	for (IRCChannel *c in self.channels) {
		if ([c memberWithNickname:sendern]) {
			if (([TPCPreferences showJoinLeave] && [ignoreChecks ignoreJPQE] == NO && c.config.ignoreJPQActivity == NO) || myself || c.isPrivateMessage) {
				if (c.isPrivateMessage) {
					text = TXTFLS(@"IRCUserDisconnectedFromPrivateMessage", sendern);
				}

				[self print:c
					   type:TVCLogLineQuitType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
			}

			if (m.isPrintOnlyMessage == NO) {
				[c removeMember:sendern];

				if (myself || c.isPrivateMessage) {
					[c deactivate];

					if (myself == NO) {
						[self.worldController reloadTreeItem:c];
					}
				}
			}
		}
	}

	[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];

	if (myself) {
		[self.worldController reloadTreeGroup:self];
	}

	[self.worldController updateTitle];
}

- (void)receiveKill:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 1);

	NSString *target = [m paramAt:0];

	for (IRCChannel *c in self.channels) {
		if ([c memberWithNickname:target]) {
			[c removeMember:target];
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	IRCAddressBook *ignoreChecks;

	NSString *oldNick = m.sender.nickname;
	NSString *newNick;
	NSString *target;

	/* Check input conditions. */
	if (m.isPrintOnlyMessage == NO) {
		NSAssert((m.params.count == 1), @"Bad receiveNick: conditions.");

        newNick = [m paramAt:0];
	} else {
		NSAssert((m.params.count == 2), @"Bad m.isPrintOnlyMessage conditions.");

		target = [m paramAt:0];
        newNick = [m paramAt:1];
	}

	/* Are they exactly the same? */
	if ([oldNick isEqualToString:newNick]) {
		return;
	}

	/* Prepare ignore checks. */
	BOOL myself = [oldNick isEqualIgnoringCase:self.localNickname];

	if (myself) {
		if (m.isPrintOnlyMessage == NO) {
			self.myNick = newNick;
			self.sentNick = newNick;
		}
	} else {
		if (m.isPrintOnlyMessage == NO) {
			/* Check new nickname in address book user check. */
			ignoreChecks = [self checkIgnoreAgainstHostmask:[newNick stringByAppendingString:@"!-@-"]
												withMatches:@[@"notifyJoins"]];

			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}

		/* Check old nickname in address book user check. */
		ignoreChecks = [self checkIgnoreAgainstHostmask:m.sender.hostmask
											withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

		if (m.isPrintOnlyMessage == NO) {
			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}
	}

	/* Is this a targetted print message? */
	if (m.isPrintOnlyMessage) {
		IRCChannel *c = [self findChannel:target];

		if (c) {
			if ((myself == NO && [ignoreChecks ignoreJPQE] == NO && [TPCPreferences showJoinLeave] && c.config.ignoreJPQActivity == NO) || myself == YES) {
				NSString *text = TXTFLS(@"IRCUserChangedNickname", oldNick, newNick);

				[self print:c
					   type:TVCLogLineNickType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
			}
		}

		/* Once a targetted print occurs, we can stop here. Nothing else
		 ini this method should be used when it is a print only job. */
		return;
	}

	/* Continue with normal operations. */
	for (IRCChannel *c in self.channels) {
		if ([c memberWithNickname:oldNick]) {
            
			if ((myself == NO && [ignoreChecks ignoreJPQE] == NO && [TPCPreferences showJoinLeave] && c.config.ignoreJPQActivity == NO) || myself == YES) {
				NSString *text = TXTFLS(@"IRCUserChangedNickname", oldNick, newNick);

				[self print:c
					   type:TVCLogLineNickType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
			}

			[c renameMember:oldNick to:newNick];
		}
	}

	IRCChannel *c = [self findChannel:oldNick];
	IRCChannel *t = [self findChannel:newNick];

	PointerIsEmptyAssert(c);

	if (t && [c.name isEqualIgnoringCase:t.name] == NO) {
		[self.worldController destroyChannel:t];
	}

	c.name = newNick;

	[self.worldController reloadTreeItem:c];
	
	if (myself) {
		[self.worldController updateTitleFor:c];
	}
	
	[self.fileTransferController nicknameChanged:oldNick toNickname:newNick client:self];
}

- (void)receiveMode:(IRCMessage *)m
{
	NSAssertReturn(m.params.count >= 2);

	NSString *sendern = m.sender.nickname;
	NSString *targetc = [m paramAt:0];
	NSString *modestr = [m sequence:1];

	if ([targetc isChannelName:self]) {
		IRCChannel *c = [self findChannel:targetc];

		PointerIsEmptyAssert(c);
		
		if (m.isPrintOnlyMessage == NO) {
			NSArray *info = [c.modeInfo update:modestr];

			BOOL performWho = NO;

			for (IRCModeInfo *h in info) {
				[c changeMember:h.modeParamater mode:h.modeToken value:h.modeIsSet];

				if (h.modeIsSet == NO && self.CAPmultiPrefix == NO) {
					performWho = YES;
				}
			}

			if (performWho) {
				[self send:IRCPrivateCommandIndex("who"), c.name, nil, nil];
			}
		}

		if ([TPCPreferences showJoinLeave] && c.config.ignoreJPQActivity == NO) {
			[self print:c
				   type:TVCLogLineModeType
				   nick:nil
				   text:TXTFLS(@"IRCModeSet", sendern, modestr)
			 receivedAt:m.receivedAt
				command:m.command];
		}

		if (m.isPrintOnlyMessage == NO) {
			[self.worldController updateTitleFor:c];
		}
	} else {
		[self print:nil
			   type:TVCLogLineModeType
			   nick:nil
			   text:TXTFLS(@"IRCModeSet", sendern, modestr)
		 receivedAt:m.receivedAt
			command:m.command];
	}
}

- (void)receiveTopic:(IRCMessage *)m
{
	NSAssertReturn(m.params.count == 2);

	NSString *sendern = m.sender.nickname;
	NSString *channel = [m paramAt:0];
	NSString *topicav = [m paramAt:1];

	IRCChannel *c = [self findChannel:channel];

	BOOL isEncrypted = [self isMessageEncrypted:topicav channel:c];

	if (isEncrypted) {
		[self decryptIncomingMessage:&topicav channel:c];
	}
	
	if (m.isPrintOnlyMessage == NO) {
		[c setTopic:topicav];
	}

	[self print:c
		   type:TVCLogLineTopicType
		   nick:nil
		   text:TXTFLS(@"IRCChannelTopicChanged", sendern, topicav)
	  encrypted:isEncrypted
	 receivedAt:m.receivedAt
		command:m.command];
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSAssertReturn(m.params.count == 2);

	NSString *sendern = m.sender.nickname;
	NSString *channel = [m paramAt:1];
	
	NSString *text = TXTFLS(@"IRCUserInvitedYouToJoinChannel", sendern, m.sender.username, m.sender.address, channel);
	
	[self print:[self.worldController selectedChannelOn:self]
		   type:TVCLogLineInviteType
		   nick:nil
		   text:text
	 receivedAt:m.receivedAt
		command:m.command];
	
	[self notifyEvent:TXNotificationInviteType lineType:TVCLogLineInviteType target:nil nick:sendern text:channel];
	
	if ([TPCPreferences autoJoinOnInvite]) {
		[self joinUnlistedChannel:channel];
	}
}

- (void)receiveErrorExcessFloodWarningPopupCallback:(TLOPopupPromptReturnType)returnType withOriginalAlert:(NSAlert *)originalAlert
{
    if (returnType == TLOPopupPromptReturnPrimaryType) {
        [self startReconnectTimer];
    } else if (returnType == TLOPopupPromptReturnSecondaryType) {
        [self cancelReconnect];
    } else {
        /* Our menuController already has built in methods for handling the opening
         of our server properties so we are going to call that instead of creating a 
         new instance of TDCServerSheet here ourselves. */

        [self.masterController.menuController showServerPropertyDialog:self withDefaultView:@"floodControl" andContext:nil];
    }
}

- (void)receiveError:(IRCMessage *)m
{
    NSString *message = m.sequence;

    /* This match is pretty general, but it works in most situations. */
    if (([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Excess Flood)"]) ||
		([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Max SendQ exceeded)"]))
	{
        [self.worldController select:self]; // Bring server to attention before popping view.

        /* Cancel any active reconnect before asking if the user wants to do it. */
        /* We cancel after 1.0 second to allow this popup prompt to be called and then 
         for Textual to process the actual drop in socket. receiveError: is called before
         our reconnect begins so we have to race it. */
        [self performSelector:@selector(cancelReconnect) withObject:nil afterDelay:1.0];

        /* Prompt user about disconnect. */
        TLOPopupPrompts *prompt = [TLOPopupPrompts new];

        [prompt sheetWindowWithQuestion:self.masterController.mainWindow
                                 target:self
                                 action:@selector(receiveErrorExcessFloodWarningPopupCallback:withOriginalAlert:)
                                   body:TXTLS(@"ExcessFloodIRCDisconnectAlertMessage")
                                  title:TXTLS(@"ExcessFloodIRCDisconnectAlertTitle")
                          defaultButton:TXTLS(@"YesButton")
                        alternateButton:TXTLS(@"NoButton")
                            otherButton:TXTLS(@"ExcessFloodIRCDisconnectAlertOpenFloodControlButton")
                         suppressionKey:nil
                        suppressionText:nil];
    } else {
        [self printError:m.sequence forCommand:m.command];
    }
}

#pragma mark -
#pragma mark Server CAP

- (void)sendNextCap
{
	if (self.CAPpausedStatus == NO) {
		if (NSObjectIsNotEmpty(self.CAPpendingCaps)) {
			NSString *cap = [self.CAPpendingCaps lastObject];

			[self send:IRCPrivateCommandIndex("cap"), @"REQ", cap, nil];

			[self.CAPpendingCaps removeLastObject];
		} else {
			[self send:IRCPrivateCommandIndex("cap"), @"END", nil];
		}
	}
}

- (void)pauseCap
{
	self.CAPpausedStatus++;
}

- (void)resumeCap
{
	self.CAPpausedStatus--;

	[self sendNextCap];
}

- (BOOL)isCapAvailable:(NSString *)cap
{
	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org

	return ([cap isEqualIgnoringCase:@"identify-msg"]			||
			[cap isEqualIgnoringCase:@"identify-ctcp"]          ||
            [cap isEqualIgnoringCase:@"away-notify"]            ||
			[cap isEqualIgnoringCase:@"multi-prefix"]			||
			[cap isEqualIgnoringCase:@"userhost-in-names"]      ||
			[cap isEqualIgnoringCase:@"server-time"]			||
			[cap isEqualIgnoringCase:@"znc.in/server-time"]     ||
            [cap isEqualIgnoringCase:@"znc.in/server-time-iso"] ||
		   ([cap isEqualIgnoringCase:@"sasl"] && self.config.nicknamePasswordIsSet));
}

- (void)cap:(NSString *)cap result:(BOOL)supported
{
	if (supported) {
		if ([cap isEqualIgnoringCase:@"sasl"]) {
			self.CAPinSASLRequest = YES;

			[self pauseCap];
			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"PLAIN", nil];
		} else if ([cap isEqualIgnoringCase:@"userhost-in-names"]) {
			self.CAPuserhostInNames = YES;
		} else if ([cap isEqualIgnoringCase:@"multi-prefix"]) {
			self.CAPmultiPrefix = YES;
		} else if ([cap isEqualIgnoringCase:@"identify-msg"]) {
			self.CAPidentifyMsg = YES;
		} else if ([cap isEqualIgnoringCase:@"identify-ctcp"]) {
			self.CAPidentifyCTCP = YES;
		} else if ([cap isEqualIgnoringCase:@"away-notify"]) {
            self.CAPawayNotify = YES;
        } else if ([cap isEqualIgnoringCase:@"server-time"] ||
				   [cap isEqualIgnoringCase:@"znc.in/server-time"] ||
				   [cap isEqualIgnoringCase:@"znc.in/server-time-iso"])
		{
			self.CAPServerTime = YES;
		}
	}
}

- (void)receiveCapacityOrAuthenticationRequest:(IRCMessage *)m
{
	/* Implementation based off Colloquy's own. */

	NSAssertReturn(m.params.count >= 1);

	NSString *command = [m command];
	NSString *starprt = [m paramAt:0];
	NSString *baseprt = [m paramAt:1];
	NSString *actions = [m sequence:2];

	if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap")]) {
		if ([baseprt isEqualIgnoringCase:@"LS"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				if ([self isCapAvailable:cap]) {
                    NSObjectIsEmptyAssertLoopContinue(cap);

					[self.CAPpendingCaps addObject:cap];
				}
			}
		} else if ([baseprt isEqualIgnoringCase:@"ACK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
                NSObjectIsEmptyAssertLoopContinue(cap);
                
				[self.CAPacceptedCaps addObject:cap];

				[self cap:cap result:YES];
			}
		} else if ([baseprt isEqualIgnoringCase:@"NAK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self cap:cap result:NO];
			}
		}

		[self sendNextCap];
	} else {
		if ([starprt isEqualToString:@"+"]) {
			NSString *authStringD = [NSString stringWithFormat:@"%@%C%@%C%@",   self.config.nickname, 0x00,
                                                                                self.config.nickname, 0x00,
                                                                                self.config.nicknamePassword];
            
			NSString *authStringE = [authStringD base64EncodingWithLineLength:400];

			NSArray *authStrings = [authStringE componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

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
	NSAssertReturn(m.params.count >= 1);

	[self send:IRCPrivateCommandIndex("pong"), [m sequence:0], nil];
}

- (void)receiveAwayNotifyCapacity:(IRCMessage *)m
{
    NSAssertReturn(self.CAPawayNotify);

    /* What are we changing to? */
    BOOL isAway = NSObjectIsNotEmpty([m sequence]);

    /* Find all users matching user info. */
    NSString *nickname = m.sender.nickname;

    for (IRCChannel *channel in self.channels) {
        IRCUser *user = [channel memberWithNickname:nickname];

        PointerIsEmptyAssertLoopContinue(user);

        user.isAway = isAway;

		[channel updateMemberOnTableView:user]; // Redraw the user in the user list.
    }
}

- (void)receiveInit:(IRCMessage *)m
{
	/* Manage timers. */
#ifdef TEXTUAL_TRIAL_BINARY
	[self startTrialPeriodTimer];
#endif
	
	[self startPongTimer];
	[self stopRetryTimer];

	/* Manage local variables. */
	self.isupport.networkAddress = m.sender.hostmask;

	self.isLoggedIn = YES;
	self.isConnected = YES;
	self.inFirstISONRun = YES;
  
	[self postEventToViewController:@"serverConnected"];

	self.connectionReconnectCount = 0;
	
	self.serverRedirectAddressTemporaryStore = nil;
	self.serverRedirectPortTemporaryStore = 0;

	self.myNick	= [m paramAt:0];
	self.sentNick = self.myNick;

	/* Notify Growl. */
	[self notifyEvent:TXNotificationConnectType lineType:TVCLogLineDebugType];

	/* Perform login commands. */
	for (__strong NSString *s in self.config.loginCommands) {
		if ([s hasPrefix:@"/"]) {
			s = [s safeSubstringFromIndex:1];
		}

		[self sendCommand:s completeTarget:NO target:nil];
	}

	/* Activate existing queries. */
	for (IRCChannel *c in self.channels) {
		if (c.isPrivateMessage) {
			[c activate];
		}
	}

	[self.worldController reloadTreeGroup:self];
    [self.worldController updateTitle];

	[self.masterController updateSegmentedController];

	/* Everything else. */
	if ([TPCPreferences autojoinWaitsForNickServ] == NO || self.CAPisIdentifiedWithSASL) {
		[self performAutoJoin];
	} else {
        /* If we wait for NickServ we set a timer of 3.0 seconds before performing auto join.
         When this timer is executed, if we do not have any knowledge of NickServ existing
         on the current server, then we perform the autojoin. This is primarly a fix for the
         ZNC SASL module which will complete identification before connecting and once connected
         Textual will have no knowledge of whether the local user is identified or not. 
         
         NickServ will send a notice asking for identification as soon as connection occurs so
         this is the best patch. At least for right now. */

        [self performSelector:@selector(performAutoJoin) withObject:nil afterDelay:3.0];
    }

	/* We need time for the server to send its configuration. */
	[self performSelector:@selector(populateISONTrackedUsersList:) withObject:self.config.ignoreList afterDelay:3.0];
}

- (void)receiveNumericReply:(IRCMessage *)m
{
	NSInteger n = m.numericReply;

	if (400 <= n && n < 600 && (n == 403) == NO && (n == 422) == NO) {
		return [self receiveErrorNumericReply:m];
	}

	switch (n) {
		case 1: // RPL_WELCOME
		{
			[self receiveInit:m];
			[self printReply:m];

			break;
		}
		case 2: // RPL_YOURHOST
		case 3: // RPL_CREATED
		case 4: // RPL_MYINFO
		{
			[self printReply:m];

			break;
		}
		case 5: // RPL_ISUPPORT
		{
            [self.isupport update:[m sequence:1] client:self];
            
            if (self.rawModeEnabled || [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken]) {
                NSArray *configRep = [self.isupport buildConfigurationRepresentation];

                /* Just updated our configuration so pull last object from our rep to get last insert. */
                [self printDebugInformationToConsole:[configRep lastObject] forCommand:m.command];
            }

			[self.worldController reloadTreeGroup:self];

			break;
		}
		case 10: // RPL_REDIR
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);

			NSString *address = [m paramAt:1];
			NSString *portraw = [m paramAt:2];

			self.disconnectType = IRCDisconnectServerRedirectMode;

			[self disconnect]; // No worry about gracefully disconnecting by using quit: since it is just a redirect.

			/* -disconnect would destroy this so we set them after… */
			self.serverRedirectAddressTemporaryStore = address;
			self.serverRedirectPortTemporaryStore = [portraw integerValue];

			[self connect];

			break;
		}
		case 20: // RPL_(?????) — Legacy code. What goes here?
		case 42: // RPL_(?????) — Legacy code. What goes here?
		case 250 ... 255: // RPL_STATSCONN, RPL_LUSERCLIENT, RPL_LUSERHOP, RPL_LUSERUNKNOWN, RPL_LUSERCHANNELS, RPL_LUSERME
		{
			[self printReply:m];

			break;
		}
		case 265 ... 266: // RPL_LOCALUSERS, RPL_GLOBALUSERS
        {
            NSString *message = [m sequence];

            if (m.params.count == 4) {
                /* Removes user count from in front of messages on IRCds that send them.
                 Example: ">> :irc.example.com 265 Guest 2 3 :Current local users 2, max 3" */
                
                message = [m sequence:3];
            }

            [self print:nil
				   type:TVCLogLineDebugType
				   nick:nil
				   text:message
			  encrypted:NO
			 receivedAt:m.receivedAt
				command:m.command];

			break;
        }
		case 372: // RPL_MOTD
		case 375: // RPL_MOTDSTART
		case 376: // RPL_ENDOFMOTD
		case 422: // ERR_NOMOTD
		{
			NSAssertReturnLoopBreak([TPCPreferences displayServerMOTD]);

			if (n == 422) {
				[self printErrorReply:m];
			} else {
				[self printReply:m];
			}
			
			break;
		}
		case 221: // RPL_UMODES
		{
			NSAssertReturnLoopBreak(m.params.count >= 2);
			
			NSString *modestr = [m paramAt:1];

			if ([modestr isEqualToString:@"+"]) {
				break;
			}
			
			[self print:nil
				   type:TVCLogLineDebugType
				   nick:nil
				   text:TXTFLS(@"IRCUserHasModes", self.localNickname, modestr)
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 290: // RPL_CAPAB (freenode)
		{
			NSAssertReturnLoopBreak(m.params.count >= 2);

			NSString *kind = [m paramAt:1];

			if ([kind isEqualIgnoringCase:@"identify-msg"]) {
				self.CAPidentifyMsg = YES;
			} else if ([kind isEqualIgnoringCase:@"identify-ctcp"]) {
				self.CAPidentifyCTCP = YES;
			}

			[self printReply:m];

			break;
		}
		case 301: // RPL_AWAY
		{
			NSAssertReturnLoopBreak(m.params.count >= 2);

			NSString *awaynick = [m paramAt:1];
			NSString *comment = [m paramAt:2];

			IRCChannel *ac = [self findChannel:awaynick];
			IRCChannel *sc = [self.worldController selectedChannelOn:self];

			NSString *text = TXTFLS(@"IRCUserIsAway", awaynick, comment);

            if (ac) {
                [self print:ac
					   type:TVCLogLineDebugType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
            } else {
                [self print:sc
					   type:TVCLogLineDebugType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
            }

			break;
		}
		case 305: // RPL_UNAWAY
		case 306: // RPL_NOWAWAY
		{
			self.isAway = (m.numericReply == 306);

			[self printUnknownReply:m];
            
            /* Update our own status. This has to only be done with away-notify CAP enabled.
             Old, WHO based information requests will still show our own status. */

            NSAssertReturnLoopBreak(self.CAPawayNotify);

            for (IRCChannel *channel in self.channels) {
                IRCUser *myself = [channel memberWithNickname:self.localNickname];
                
                PointerIsEmptyAssertLoopContinue(myself); // This *should* never be empty.
                
                myself.isAway = self.isAway;

				[channel updateMemberOnTableView:myself]; // Redraw the user in the user list.
            }

			break;
		}
		case 307: // RPL_WHOISREGNICK
		case 310: // RPL_WHOISHELPOP
		case 313: // RPL_WHOISOPERATOR
		case 335: // RPL_WHOISBOT
		case 378: // RPL_WHOISHOST
		case 379: // RPL_WHOISMODES
		case 671: // RPL_WHOISSECURE
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);

			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];

            [self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 338: // RPL_WHOISACTUALLY (ircu, Bahamut)
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];

            [self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 311: // RPL_WHOISUSER
		case 314: // RPL_WHOWASUSER
		{
			NSAssertReturnLoopBreak(m.params.count >= 6);

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *hostmask = [m paramAt:3];
			NSString *realname = [m paramAt:5];

			NSString *text = nil;

			self.inUserInvokedWhowasRequest = (n == 314);

			if ([realname hasPrefix:@":"]) {
				realname = [realname safeSubstringFromIndex:1];
			}

			if (self.inUserInvokedWhowasRequest) {
				text = TXTFLS(@"IRCUserWhowasHostmask", nickname, username, hostmask, realname);
			} else {
				/* Update local cache of our hostmask. */
				if ([self.myNick isEqualIgnoringCase:nickname]) {
					NSString *completehost = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];

					self.myHost = completehost;
				}

				/* Continue normal WHOIS event. */
				text = TXTFLS(@"IRCUserWhoisHostmask", nickname, username, hostmask, realname);
			}

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 312: // RPL_WHOISSERVER
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *nickname = [m paramAt:1];
			NSString *serverHost = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];

			NSString *text = nil;

			if (self.inUserInvokedWhowasRequest) {
				NSString *timeInfo = [NSDateFormatter localizedStringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]
																	dateStyle:NSDateFormatterLongStyle
																	timeStyle:NSDateFormatterLongStyle];
				
				text = TXTFLS(@"IRCUserWhowasConnectedFrom", nickname, serverHost, timeInfo);
			} else {
				text = TXTFLS(@"IRCUserWhoisConnectedFrom", nickname, serverHost, serverInfo);
			}

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 317: // RPL_WHOISIDLE
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *nickname = [m paramAt:1];
			NSString *idleTime = [m paramAt:2];
			NSString *connTime = [m paramAt:3];

			idleTime = TXReadableTime(idleTime.doubleValue);
			
			connTime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:connTime.doubleValue]
													  dateStyle:NSDateFormatterLongStyle
													  timeStyle:NSDateFormatterLongStyle];

			NSString *text = TXTFLS(@"IRCUserWhoisUptime", nickname, connTime, idleTime);

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 319: // RPL_WHOISCHANNELS
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);

			NSString *nickname = [m paramAt:1];
			NSString *channels = [m paramAt:2];

			NSString *text = TXTFLS(@"IRCUserWhoisChannels", nickname, channels);

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 324: // RPL_CHANNELMODES
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);

			NSString *channel = [m paramAt:1];
			NSString *modestr = [m sequence:2];

			if ([modestr isEqualToString:@"+"]) {
				break;
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if (c.isActive) {
				[c.modeInfo clear];
				[c.modeInfo update:modestr];
			}

			if (self.inUserInvokedModeRequest || c.inUserInvokedModeRequest) {
				NSString *fmodestr = [c.modeInfo format:NO];

				[self print:c
					   type:TVCLogLineModeType
					   nick:nil
					   text:TXTFLS(@"IRCChannelHasModes", fmodestr)
				 receivedAt:m.receivedAt
					command:m.command];

				if (c.inUserInvokedModeRequest) {
					c.inUserInvokedModeRequest = NO;
				} else {
					self.inUserInvokedModeRequest = NO;
				}
			}
			
			break;
		}
		case 332: // RPL_TOPIC
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);

			NSString *channel = [m paramAt:1];
			NSString *topicva = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			BOOL isEncrypted = [self isMessageEncrypted:topicva channel:c];

			if (isEncrypted) {
				[self decryptIncomingMessage:&topicva channel:c];
			}

			if (c.isActive) {
				[c setTopic:topicva];

				[self print:c
					   type:TVCLogLineTopicType
					   nick:nil
					   text:TXTFLS(@"IRCChannelHasTopic", topicva)
				  encrypted:isEncrypted
				 receivedAt:m.receivedAt
					command:m.command];
			}

			break;
		}
		case 333: // RPL_TOPICWHOTIME
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *channel = [m paramAt:1];
			NSString *topicow = [m paramAt:2];
			NSString *settime = [m paramAt:3];

			topicow = [topicow nicknameFromHostmask];

			settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:settime.doubleValue]
													 dateStyle:NSDateFormatterLongStyle
													 timeStyle:NSDateFormatterLongStyle];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if (c.isActive) {
				NSString *text = [NSString stringWithFormat:TXTLS(@"IRCChannelHasTopicAuthor"), topicow, settime];

				[self print:c
					   type:TVCLogLineTopicType
					   nick:nil
					   text:text
				 receivedAt:m.receivedAt
					command:m.command];
			}
			
			break;
		}
		case 341: // RPL_INVITING
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);
			
			NSString *nickname = [m paramAt:1];
			NSString *channel = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if (c.isActive) {
				[self print:c
					   type:TVCLogLineDebugType
					   nick:nil
					   text:TXTFLS(@"IRCUserInvitedToJoinChannel", nickname, channel)
				 receivedAt:m.receivedAt
					command:m.command];
			}
			
			break;
		}
		case 303: // RPL_ISON
		{
			/* Cut the users up. */
			NSArray *users = [m.sequence split:NSStringWhitespacePlaceholder];

			/* Start going over the list of tracked nicknames. */
			NSDictionary *trackedUsers = [self.trackedUsers copy];

			for (NSString *name in trackedUsers) {
				NSString *langkey = nil;

				/* Was the user on during the last check? */
				BOOL ison = [self.trackedUsers boolForKey:name];

				if (ison) {
					/* If the user was on before, but is not in the list of ISON 
					 users in this reply, then they are considered gone. Log that. */
					if ([users containsObjectIgnoringCase:name] == NO) {
						if (self.inFirstISONRun == NO) {
							langkey = @"UserTrackingNicknameNoLongerAvailable";
						}

						[self.trackedUsers setBool:NO forKey:name];
					}
				} else {
					/* If they were not on but now are, then log that too. */
					if ([users containsObjectIgnoringCase:name]) {
						if (self.inFirstISONRun) {
							langkey = @"UserTrackingNicknameIsAvailable";
						} else {
							langkey = @"UserTrackingNicknameNowAvailable";
						}
						
						[self.trackedUsers setBool:YES forKey:name];
					}
				}

				/* If we have a langkey, then there was something logged. We will now
				 find the actual tracking rule that matches the name and post that to the
				 end user to see the user status. */
				NSObjectIsEmptyAssertLoopContinue(langkey);
				
				for (IRCAddressBook *g in self.config.ignoreList) {
					NSString *trname = [g trackingNickname];

					if ([trname isEqualIgnoringCase:name]) {
						[self handleUserTrackingNotification:g nickname:name langitem:langkey];
					}
				}
			}

			if (self.inFirstISONRun) { // Reset internal var.
				self.inFirstISONRun = NO;
			}

			/* Update private messages. */
			for (IRCChannel *channel in self.channels) {
				NSAssertReturnLoopContinue(channel.isPrivateMessage);

				/* Does the private message contain users? */
				if (channel.isActive) {
					/* If the user is no longer on, deactivate the private message. */

					if ([users containsObjectIgnoringCase:channel.name] == NO) {
						[channel deactivate];

						[self.worldController reloadTreeItem:channel];
					}
				} else {
					/* Activate the private message if the user is back on. */
					if ([users containsObjectIgnoringCase:channel.name]) {
						[channel activate];

						[self.worldController reloadTreeItem:channel];
					}
				}
			}

			break;
		}
		case 315: // RPL_ENDOFWHO
		{
			NSString *channel = [m paramAt:1];

			IRCChannel *c = [self findChannel:channel];
			
			if (self.inUserInvokedWhoRequest) {
				[self printUnknownReply:m];

				self.inUserInvokedWhoRequest = NO;
			}

            [self.worldController updateTitleFor:c];

			break;
		}
		case 352: // RPL_WHOREPLY
		{
			NSAssertReturnLoopBreak(m.params.count >= 7);

			NSString *channel = [m paramAt:1];

			if (self.inUserInvokedWhoRequest) {
				[self printUnknownReply:m];
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);
			
			NSString *nickname = [m paramAt:5];
			NSString *hostmask = [m paramAt:3];
			NSString *username = [m paramAt:2];
			NSString *flfields = [m paramAt:6];

            BOOL isIRCop = NO;
            BOOL isAway = NO;

			// Field Syntax: <H|G>[*][@|+]
			// Strip G or H (away status).
            if ([flfields hasPrefix:@"G"] && self.inUserInvokedWhoRequest == NO) {
				if ([TPCPreferences trackUserAwayStatusMaximumChannelSize] > 0 || self.CAPawayNotify) {
					isAway = YES;
				}
			}

			flfields = [flfields substringFromIndex:1];

			if ([flfields contains:@"*"]) {
				flfields = [flfields substringFromIndex:1];

                isIRCop = YES;
			}

			BOOL checkForDiff = YES;

			IRCUser *ou = [c memberWithNickname:nickname];
			IRCUser *nu;

			if (PointerIsEmpty(ou)) {
				nu = [IRCUser new];
				nu.nickname = nickname;

				checkForDiff = NO;
			}

			if (checkForDiff) {
				nu = [ou copy];
			}

			if (NSObjectIsEmpty(nu.address)) {
				nu.address = hostmask;
				nu.username = username;
			}
            
            nu.isCop = isIRCop;
            nu.isAway = isAway;

			nu.supportInfo = self.isupport;

			NSInteger i;

			for (i = 0; i < flfields.length; i++) {
				NSString *prefix = [flfields safeSubstringWithRange:NSMakeRange(i, 1)];

				if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"q"]]) {
					nu.q = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"O"]]) { // binircd-1.0.0
					nu.q = YES;
					nu.binircd_O = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"a"]]) {
					nu.a = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"o"]]) {
					nu.o = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"h"]]) {
					nu.h = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"v"]]) {
					nu.v = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"y"]]) { // InspIRCd-2.0
					nu.isCop = YES;
					nu.InspIRCd_y_lower = YES;
				} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"Y"]]) { // InspIRCd-2.0
					nu.isCop = YES;
					nu.InspIRCd_y_upper = YES;
				} else {
					break;
				}
			}

			/* Update local cache of our hostmask. */
			if ([self.myNick isEqualIgnoringCase:nickname]) {
				NSString *completehost = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];

				self.myHost = completehost;
			}

			/* Continue normal WHO reply tracking. */
			if (checkForDiff) {
				BOOL requiresRedraw = [c memberRequiresRedraw:ou comparedTo:nu];

				[ou migrate:nu];

				if (requiresRedraw) {
					[c removeMember:[nu nickname]];

					[c addMember:ou];
				}
			} else {
				[c addMember:nu]; // User was never on channel. Add them…
			}

			break;
		}
		case 353: // RPL_NAMEREPLY
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *channel = [m paramAt:2];
			NSString *nameblob = [m paramAt:3];
			
			if (self.inUserInvokedNamesRequest) {
				[self printUnknownReply:m];
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			NSArray *items = [nameblob componentsSeparatedByString:NSStringWhitespacePlaceholder];

			for (__strong NSString *nickname in items) {
                NSObjectIsEmptyAssertLoopContinue(nickname);
                
				IRCUser *member = [IRCUser new];

				NSInteger i;

				for (i = 0; i < nickname.length; i++) {
					NSString *prefix = [nickname safeSubstringWithRange:NSMakeRange(i, 1)];

					if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"q"]]) {
						member.q = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"O"]]) { // binircd-1.0.0
						member.q = YES;
						member.binircd_O = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"a"]]) {
						member.a = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"o"]]) {
						member.o = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"h"]]) {
						member.h = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"v"]]) {
						member.v = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"y"]]) { // InspIRCd-2.0
						member.isCop = YES;
						member.InspIRCd_y_lower = YES;
					} else if ([prefix isEqualTo:[self.isupport userModePrefixSymbol:@"Y"]]) { // InspIRCd-2.0
						member.isCop = YES;
						member.InspIRCd_y_upper = YES;
					} else {
						break;
					}
				}

				nickname = [nickname substringFromIndex:i];

				member.supportInfo = self.isupport;

                member.nickname = [nickname nicknameFromHostmask];
                member.username = [nickname usernameFromHostmask];
                member.address = [nickname addressFromHostmask];

				if ([c memberWithNickname:member.nickname]) {
					[c removeMember:member.nickname];
				}
				
				[c addMember:member];
			}

			break;
		}
		case 366: // RPL_ENDOFNAMES
		{
			NSAssertReturnLoopBreak(m.params.count >= 2);
			
			NSString *channel = [m paramAt:1];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);
		
			if (c.numberOfMembers <= 1) {
				NSString *mode = c.config.defaultModes;

				if (NSObjectIsNotEmpty(m)) {
					[self send:IRCPrivateCommandIndex("mode"), c.name, mode, nil];
				}
			}

			if (c.numberOfMembers <= 1 && [channel isModeChannelName]) {
				NSString *topic = c.config.defaultTopic;

				if (NSObjectIsNotEmpty(topic)) {
					if ([self encryptOutgoingMessage:&topic channel:c] == YES) {
						[self send:IRCPrivateCommandIndex("topic"), c.name, topic, nil];
					}
				}
			}

			[self send:IRCPrivateCommandIndex("who"), c.name, nil, nil];

			if (self.inUserInvokedNamesRequest) {
				self.inUserInvokedNamesRequest = NO;
			}
            
            [self.worldController updateTitleFor:c];

			break;
		}
		case 320: // RPL_WHOISSPECIAL
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);
			
			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m sequence:2]];

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 321: // RPL_LISTSTART
		{
            TDCListDialog *channelListDialog = [self listDialog];

			if (channelListDialog) {
				[channelListDialog clear];
			}

			break;
		}
		case 322: // RPL_LIST
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);
			
			NSString *channel = [m paramAt:1];
			NSString *uscount = [m paramAt:2];
			NSString *topicva = [m sequence:3];

            TDCListDialog *channelListDialog = [self listDialog];

			if (channelListDialog) {
				[channelListDialog addChannel:channel count:uscount.integerValue topic:topicva];
			}

			break;
		}
		case 323: // RPL_LISTEND
		case 329: // RPL_CREATIONTIME
		case 368: // RPL_ENDOFBANLIST
		case 347: // RPL_ENDOFINVITELIST
		case 349: // RPL_ENDOFEXCEPTLIST
		case 318: // RPL_ENDOFWHOIS
		{
			break; // Ignored numerics.
		}
		case 330: // RPL_WHOISACCOUNT (ircu)
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 367: // RPL_BANLIST
		{
			NSAssertReturnLoopBreak(m.params.count >= 5);

			NSString *hostmask = [m paramAt:2];
			NSString *banowner = [m paramAt:3];
			NSString *settime = [m paramAt:4];

			settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:settime.doubleValue]
													 dateStyle:NSDateFormatterLongStyle
													 timeStyle:NSDateFormatterLongStyle];

            TXMenuController *menuController = self.masterController.menuController;

            TDChanBanSheet *chanBanListSheet = [menuController windowFromWindowList:@"TDChanBanSheet"];

            if (chanBanListSheet) {
				[chanBanListSheet addBan:hostmask tset:settime	setby:banowner];
			}

			break;
		}
		case 346: // RPL_INVITELIST
		{
			NSAssertReturnLoopBreak(m.params.count >= 5);

			NSString *hostmask = [m paramAt:2];
			NSString *banowner = [m paramAt:3];
			NSString *settime = [m paramAt:4];

			settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:settime.doubleValue]
													 dateStyle:NSDateFormatterLongStyle
													 timeStyle:NSDateFormatterLongStyle];

            TXMenuController *menuController = self.masterController.menuController;

            TDChanInviteExceptionSheet *inviteExceptionSheet = [menuController windowFromWindowList:@"TDChanInviteExceptionSheet"];

			if (inviteExceptionSheet) {
				[inviteExceptionSheet addException:hostmask tset:settime setby:banowner];
			}

			break;
		}
		case 348: // RPL_EXCEPTLIST
		{
			NSAssertReturnLoopBreak(m.params.count >= 5);

			NSString *hostmask = [m paramAt:2];
			NSString *banowner = [m paramAt:3];
			NSString *settime = [m paramAt:4];

			settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:settime.doubleValue]
													 dateStyle:NSDateFormatterLongStyle
													 timeStyle:NSDateFormatterLongStyle];

            TXMenuController *menuController = self.masterController.menuController;

            TDChanBanExceptionSheet *banExceptionSheet = [menuController windowFromWindowList:@"TDChanBanExceptionSheet"];

			if (banExceptionSheet) {
				[banExceptionSheet addException:hostmask tset:settime setby:banowner];
			}

			break;
		}
		case 381: // RPL_YOUREOPER
		{
			if (self.hasIRCopAccess == NO) {
				/* If we are already an IRCOp, then we do not need to see this line again.
				 We will assume that if we are seeing it again, then it is the result of a
				 user opening two connections to a single bouncer session. */

				[self print:nil
					   type:TVCLogLineDebugType
					   nick:nil
					   text:TXTFLS(@"IRCUserIsNowIRCOperator", m.sender.nickname)
				 receivedAt:m.receivedAt
					command:m.command];

				self.hasIRCopAccess = YES;
			}

			break;
		}
		case 328: // RPL_CHANNEL_URL
		{
			NSAssertReturnLoopBreak(m.params.count >= 3);
			
			NSString *channel = [m paramAt:1];
			NSString *website = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			if (c && website) {
				[self print:c
					   type:TVCLogLineWebsiteType
					   nick:nil
					   text:TXTFLS(@"IRCChannelHasWebsite", website)
				 receivedAt:m.receivedAt
					command:m.command];
			}

			break;
		}
		case 369: // RPL_ENDOFWHOWAS
		{
			self.inUserInvokedWhowasRequest = NO;

			[self print:[self.worldController selectedChannelOn:self]
				   type:TVCLogLineDebugType
				   nick:nil
				   text:[m sequence]
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 602: // RPL_WATCHOFF
		case 606: // RPL_WATCHLIST
		case 607: // RPL_ENDOFWATCHLIST
		case 608: // RPL_CLEARWATCH
		{
			if (self.inUserInvokedWatchRequest) {
				[self printUnknownReply:m];
			}

			if (n == 608 || n == 607) {
				self.inUserInvokedWatchRequest = NO;
			}

			break;
		}
		case 600: // RPL_LOGON
		case 601: // RPL_LOGOFF
		case 604: // RPL_NOWON
		case 605: // RPL_NOWOFF
		{
			NSAssertReturnLoopBreak(m.params.count >= 5);

			if (self.inUserInvokedWatchRequest) {
				[self printUnknownReply:m];

				return;
			}

			NSString *sendern = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];

			NSString *hostmaskwon = nil; // Hostmask without nickname
			NSString *hostmaskwnn = nil; // Hostmask with nickname

			IRCAddressBook *ignoreChecks = nil;

			if (NSDissimilarObjects(n, 605)) {
				/* 605 does not have the host, but the rest do. */
				
				hostmaskwon = [NSString stringWithFormat:@"%@@%@", username, address];
				hostmaskwnn = [NSString stringWithFormat:@"%@!%@", sendern, hostmaskwon];

				ignoreChecks = [self checkIgnoreAgainstHostmask:hostmaskwnn withMatches:@[@"notifyJoins"]];
			} else {
				ignoreChecks = [self checkIgnoreAgainstHostmask:[sendern stringByAppendingString:@"!-@-"]
													withMatches:@[@"notifyJoins"]];
			}

			/* We only continue if there is an actual address book match for the nickname. */
			PointerIsEmptyAssertLoopBreak(ignoreChecks);

			if (n == 600)
			{ // logged online
				[self handleUserTrackingNotification:ignoreChecks
											nickname:sendern
											langitem:@"UserTrackingNicknameNowAvailable"];
			}
			else if (n == 601)
			{ // logged offline
				[self handleUserTrackingNotification:ignoreChecks
											nickname:sendern
											langitem:@"UserTrackingNicknameNoLongerAvailable"];
			}
			else if (n == 604)
			{ // is online
				[self.trackedUsers setBool:YES forKey:sendern];
			}
			else if (n == 605)
			{ // is offline
				[self.trackedUsers setBool:NO forKey:sendern];
			}

			break;
		}
		case 716: // RPL_TARGUMODEG
		{
			// Ignore, 717 will take care of notification.
			
			break;
		}
		case 717: // RPL_TARGNOTIFY
		{
			NSAssertReturnLoopBreak(m.params.count == 3);

			NSString *sendern = [m paramAt:1];
			
			[self printDebugInformation:TXTFLS(@"IRCUserNotifiedOfBlockedMessageForUmodeG", sendern)];
			
			break;
		}
		case 718:
		{
			NSAssertReturnLoopBreak(m.params.count == 4);
			
			NSString *sendern = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
				IRCChannel *c = [self.worldController selectedChannelOn:self];

				[self printDebugInformation:TXTFLS(@"IRCUserPrivateMessageBlockedByUmodeG", sendern, hostmask) channel:c];
			} else {
				[self printDebugInformation:TXTFLS(@"IRCUserPrivateMessageBlockedByUmodeG", sendern, hostmask)];
			}

			break;
		}
		case 900: // RPL_LOGGEDIN
		{
			NSAssertReturnLoopBreak(m.params.count >= 4);

			self.CAPisIdentifiedWithSASL = YES;

			[self print:self
				   type:TVCLogLineDebugType
				   nick:nil
				   text:[m sequence:3]
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 903: // RPL_SASLSUCCESS
		case 904: // ERR_SASLFAIL
		case 905: // ERR_SASLTOOLONG
		case 906: // ERR_SASLABORTED
		case 907: // ERR_SASLALREADY
		{
			if (n == 903) { // success
				[self print:self
					   type:TVCLogLineNoticeType
					   nick:nil
					   text:[m sequence:1]
				 receivedAt:m.receivedAt
					command:m.command];
			} else {
				[self printReply:m];
			}

			if (self.CAPinSASLRequest) {
				self.CAPinSASLRequest = NO;

				[self resumeCap];
			}

			break;
		}
		default:
		{
			NSString *numericString = [NSString stringWithInteger:n];

			if ([[THOPluginManagerSharedInstance() supportedServerInputCommands] containsObject:numericString]) {
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
		case 401: // ERR_NOSUCHNICK
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];

			if (c && c.isActive) {
				[self printErrorReply:m channel:c];
			} else {
				[self printErrorReply:m];
			}

			break;
		}
		case 402: // ERR_NOSUCHSERVER
		{
			NSString *text = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence:1]);

			[self print:nil
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 433: // ERR_NICKNAMEINUSE
		case 437: // ERR_NICKCHANGETOOFAST
		{
			if (self.isLoggedIn) {
				break;
			}
			
			[self receiveNickCollisionError:m];

			break;
		}
		case 404: // ERR_CANNOTSENDTOCHAN
		{
			NSString *text = TXTFLS(@"IRCHadRawError", m.numericReply, [m sequence:2]);

			IRCChannel *c = [self findChannel:[m paramAt:1]];
			
			[self print:c
				   type:TVCLogLineDebugType
				   nick:nil
				   text:text
			 receivedAt:m.receivedAt
				command:m.command];

			break;
		}
		case 403: // ERR_NOSUCHCHANNEL
		case 405: // ERR_TOOMANYCHANNELS
		case 471: // ERR_CHANNELISFULL
		case 473: // ERR_INVITEONLYCHAN
		case 474: // ERR_BANNEDFROMCHAN
		case 475: // ERR_BADCHANNEL
		case 476: // ERR_BADCHANMASK
		case 477: // ERR_NEEDREGGEDNICK
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];

			if (c) {
				c.errorOnLastJoinAttempt = YES;
			}
			
			[self printErrorReply:m];

			break;
		}
		default:
		{
			[self printErrorReply:m];

			break;
		}
	}
}

- (void)receiveNickCollisionError:(IRCMessage *)m
{
	NSArray *altNicks = self.config.alternateNicknames;
	
	if (NSObjectIsNotEmpty(altNicks) && self.isLoggedIn == NO) {
		self.tryingNickNumber += 1;

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
	if (self.sentNick.length >= self.isupport.nicknameLength) {
		NSString *nick = [self.sentNick safeSubstringToIndex:self.isupport.nicknameLength];

		BOOL found = NO;

		for (NSInteger i = (nick.length - 1); i >= 0; --i) {
			UniChar c = [nick characterAtIndex:i];
			
			if (NSDissimilarObjects(c, '_')) {
				found = YES;
				
				NSString *head = [nick safeSubstringToIndex:i];
				
				NSMutableString *s = [head mutableCopy];
				
				for (NSInteger ii = (self.isupport.nicknameLength - s.length); ii > 0; --ii) {
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
#pragma mark Autojoin

- (void)updateAutoJoinStatus
{
	self.autojoinInProgress = NO;
	self.isAutojoined = YES;
}

- (void)performAutoJoin
{
	if ([self.channels count] < 1 || (self.isZNCBouncerConnection && self.config.zncIgnoreConfiguredAutojoin)) {
		/* What are we joining? */
		self.isAutojoined = YES;

		return;
	}

	if ([TPCPreferences autojoinWaitsForNickServ]) {
        if (self.serverHasNickServ && self.isIdentifiedWithNickServ == NO) {
            return;
        }
    }
    
	self.autojoinInProgress = YES;

	NSMutableArray *ary = [NSMutableArray array];

	for (IRCChannel *c in self.channels) {
		if (c.isChannel && c.config.autoJoin) {
			if (c.isActive == NO) {
				[ary safeAddObject:c];
			}
		}
	}

	[self quickJoin:ary];

	[self performSelector:@selector(updateAutoJoinStatus) withObject:nil afterDelay:15.0];
}

#pragma mark -
#pragma mark Post Events

- (void)postEventToViewController:(NSString *)eventToken
{
    [self.viewController executeScriptCommand:@"handleEvent" withArguments:@[eventToken] onQueue:NO];

    for (IRCChannel *channel in self.channels) {
        [self postEventToViewController:eventToken forChannel:channel];
    }
}

- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel
{
	[channel.viewController executeScriptCommand:@"handleEvent" withArguments:@[eventToken] onQueue:NO];
}

#pragma mark -
#pragma mark Timers

- (void)startPongTimer
{
	if (self.pongTimer.timerIsActive) {
		return;
	}

	[self.pongTimer start:_pongCheckInterval];
}

- (void)stopPongTimer
{
	if (self.pongTimer.timerIsActive) {
		[self.pongTimer stop];
	}
}

- (void)onPongTimer:(id)sender
{
	if (self.isLoggedIn == NO) {
		return [self stopPongTimer];
	}

	/* Instead of stopping and starting the timer every time this changes, it
	 it is easier to check if we should do it every timer iteration.
	 The ability to disable this is important on PSYBNC connectiongs because
	 PSYBNC doesn't respond to PING commands. There are other irc daemons that
	 don't reply to PING either and they should all be shot. */
	if (self.config.performPongTimer == NO) {
		return;
	}

	NSInteger timeSpent = [NSDate secondsSinceUnixTimestamp:self.lastMessageReceived];

	if (timeSpent >= _timeoutInterval) {

		if (self.config.performDisconnectOnPongTimer) {
			[self printDebugInformation:TXTFLS(@"IRCDisconnectedByTimeout", (timeSpent / 60)) channel:nil];

			[self disconnect];
		} else {
			if (self.timeoutWarningShownToUser == NO) {
				[self printDebugInformation:TXTFLS(@"IRCMightDisconnectWithTimeout", (timeSpent / 60)) channel:nil];

				self.timeoutWarningShownToUser = YES;
			}
		}
	} else if (timeSpent >= _pingInterval) {
		[self send:IRCPrivateCommandIndex("ping"), [self networkAddress], nil];
	}
}

- (void)startReconnectTimer
{
	if (self.config.autoReconnect) {
		if (self.reconnectTimer.timerIsActive) {
			return;
		}

		[self.reconnectTimer start:_reconnectInterval];
	}
}

- (void)stopReconnectTimer
{
	[self.reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
	[self connect:IRCConnectReconnectMode];
}

- (void)startRetryTimer
{
	if (self.retryTimer.timerIsActive) {
		return;
	}

	[self.retryTimer start:_retryInterval];
}

- (void)stopRetryTimer
{
	[self.retryTimer stop];
}

- (void)onRetryTimer:(id)sender
{
	[self disconnect];
	
	[self connect:IRCConnectRetryMode];
}

#pragma mark -
#pragma mark Trial Period Timer

#ifdef TEXTUAL_TRIAL_BINARY

- (void)startTrialPeriodTimer
{
	if (self.trialPeriodTimer.timerIsActive) {
		return;
	}
	
	[self.trialPeriodTimer start:_trialPeriodInterval];
}

- (void)stopTrialPeriodTimer
{
	[self.trialPeriodTimer stop];
}

- (void)onTrialPeriodTimer:(id)sender
{
	if (self.isLoggedIn) {
		self.disconnectType = IRCDisconnectTrialPeriodMode;

		[self quit];
	}
}

#endif

#pragma mark -
#pragma mark Plugins and Scripts

- (void)outputTextualCmdScriptError:(NSString *)scriptPath
							  input:(NSString *)scriptInput
							context:(NSDictionary *)userInfo
							  error:(NSError *)originalError
{
	BOOL devmode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

	NSString *script = [scriptPath lastPathComponent];

	id errord;
	id errorb;

	if (NSObjectIsEmpty(userInfo) && PointerIsNotEmpty(originalError)) {
		errord = [originalError localizedDescription];
		errorb = [originalError localizedDescription];
	} else {
		errord = userInfo[NSAppleScriptErrorBriefMessage];
		errorb = userInfo[NSLocalizedFailureReasonErrorKey];

		if (NSObjectIsEmpty(errord) && NSObjectIsNotEmpty(errorb)) {
			errord = errorb;
		}

		if (NSObjectIsEmpty(errorb) && NSObjectIsNotEmpty(errord)) {
			errorb = errord;
		}
	}

	if (NSObjectIsEmpty(scriptInput)) {
		scriptInput = @"(null)";
	}

	if (devmode) {
		[self printDebugInformation:TXTFLS(@"ScriptExecutionFailureDetailed", script, scriptInput, errord)];
	}

	LogToConsole(TXTLS(@"ScriptExecutionFailureBasic"), errorb);
}

- (void)postTextualCmdScriptResult:(NSString *)resultString to:(NSString *)destination
{
	resultString = [resultString trim];
	
	NSObjectIsEmptyAssert(resultString);

	/* If our resultString does not begin with a / (meaning a command), then we will tell Textual it is a
	 MSG command so that it posts as a normal message and goes to the correct destination. Each result 
	 line is thrown through inputText:command: to have Textual treat it like any other user input. */

	/* -splitIntoLines is only available to NSAttributedString and I was too lazy to add it to NSString
	 so fuck it… just convert our input over. */
	NSAttributedString *resultBase = [NSAttributedString emptyStringWithBase:resultString];

	NSArray *lines = [resultBase splitIntoLines];

	dispatch_sync(dispatch_get_main_queue(), ^{
		for (NSAttributedString *s in lines) {
			if ([s.string hasPrefix:@"/"]) {
				/* We do not have to worry about whether this is an actual command or an escaped one
				 by using double slashes (//) at this point because inputText:command: will do all that
				 hard work for us. We only care if it starts with a slash. */

				[self inputText:s command:IRCPrivateCommandIndex("privmsg")];
			} else {
				/* If there is no destination, then we are fucked. */

				if (NSObjectIsEmpty(destination)) {
					/* Do not send a normal message to the console. What? */
				} else {
					NSString *msgcmd = [NSString stringWithFormat:@"/msg %@ %@", destination, s.string];

					[self inputText:msgcmd command:IRCPrivateCommandIndex("privmsg")];
				}
			}
		}
	});
}

- (void)executeTextualCmdScript:(NSDictionary *)details
{
	dispatch_async([THOPluginManagerSharedInstance() dispatchQueue], ^{
		[self internalExecuteTextualCmdScript:details];
	});
}

- (void)internalExecuteTextualCmdScript:(NSDictionary *)details
{
	/* Gather information about the script to be executed. */
	NSAssertReturn([details containsKey:@"path"]);

	NSString *scriptInput = details[@"input"];
	NSString *scriptPath  = details[@"path"];

	NSString *destinationChannel = details[@"channel"];

	BOOL MLNonsandboxedScript = NO;

	/* MLNonsandboxedScript tells this call that the script can
	 be ran outside of the Mac OS sandbox attached to Textual. */
	NSString *userScriptsPath = [TPCPreferences systemUnsupervisedScriptFolderPath];

	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		if ([scriptPath hasPrefix:userScriptsPath]) {
			MLNonsandboxedScript = YES;
		}
	}

	/* Is it AppleScript? */
	if ([scriptPath hasSuffix:TPCResourceManagerScriptDocumentTypeExtension]) {
		/* /////////////////////////////////////////////////////// */
		/* Event Descriptor */
		/* /////////////////////////////////////////////////////// */

		NSAppleEventDescriptor *firstParameter	= [NSAppleEventDescriptor descriptorWithString:scriptInput];
		NSAppleEventDescriptor *secondParameter = [NSAppleEventDescriptor descriptorWithString:destinationChannel];
		
		NSAppleEventDescriptor *parameters		= [NSAppleEventDescriptor listDescriptor];

		[parameters insertDescriptor:firstParameter atIndex:1];
		[parameters insertDescriptor:secondParameter atIndex:2];

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

		if (MLNonsandboxedScript) {
			NSError *aserror = nil;

			NSUserAppleScriptTask *applescript = [[NSUserAppleScriptTask alloc] initWithURL:[NSURL fileURLWithPath:scriptPath] error:&aserror];

			if (PointerIsEmpty(applescript) || aserror) {
				[self outputTextualCmdScriptError:scriptPath input:scriptInput context:[aserror userInfo] error:aserror];
			} else {
				[applescript executeWithAppleEvent:event
								 completionHandler:^(NSAppleEventDescriptor *result, NSError *error)
				{
					 if (PointerIsEmpty(result)) {
						 [self outputTextualCmdScriptError:scriptPath input:scriptInput context:[error userInfo] error:error];
					 } else {
						 [self postTextualCmdScriptResult:result.stringValue to:destinationChannel];
					 }
				}];
			}

			return;
		}

		/* /////////////////////////////////////////////////////// */
		/* Execute Event — All Other */
		/* /////////////////////////////////////////////////////// */

		NSDictionary *errors = @{};

		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errors];

		if (appleScript) {
			NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];

			if (errors && PointerIsEmpty(result)) {
				[self outputTextualCmdScriptError:scriptPath input:scriptInput context:errors error:nil];
			} else {
				[self postTextualCmdScriptResult:result.stringValue to:destinationChannel];
			}
		} else {
			[self outputTextualCmdScriptError:scriptPath input:scriptInput context:errors error:nil];
		}
	} else {
		/* /////////////////////////////////////////////////////// */
		/* Execute Shell Script */
		/* /////////////////////////////////////////////////////// */

		if (MLNonsandboxedScript == NO) {
			// We only accept executables if they are on
			// Mountain Lion and within the unsupervised
			// scripts folder.

			return;
		}

		NSArray *arguments1 = [scriptInput split:NSStringWhitespacePlaceholder];
		NSArray *arguments2 = [NSArray arrayWithObject:NSStringNilValueSubstitute(destinationChannel)];

		NSArray *arguments = [arguments2 arrayByAddingObjectsFromArray:arguments1];
		
		NSURL *userScriptURL = [NSURL fileURLWithPath:scriptPath];

		NSError *aserror = nil;
		
		NSUserUnixTask *unixTask = [[NSUserUnixTask alloc] initWithURL:userScriptURL error:&aserror];

		if (PointerIsEmpty(unixTask) || aserror) {
			[self outputTextualCmdScriptError:scriptPath input:scriptInput context:nil error:aserror];

			return;
		}

		NSPipe *standardOutputPipe = [NSPipe pipe];
		
		NSFileHandle *writingPipe = [standardOutputPipe fileHandleForWriting];
		NSFileHandle *readingPipe = [standardOutputPipe fileHandleForReading];
		
		[unixTask setStandardOutput:writingPipe];

		[unixTask executeWithArguments:arguments completionHandler:^(NSError *err) {
			if (err) {
				[self outputTextualCmdScriptError:scriptPath input:scriptInput context:nil error:err];
			} else {
				NSData *outputData = [readingPipe readDataToEndOfFile];

				NSString *outputString = [NSString stringWithData:outputData encoding:NSUTF8StringEncoding];

				[self postTextualCmdScriptResult:outputString to:destinationChannel];
			}
		}];
	}
}

- (void)processBundlesUserMessage:(NSString *)message command:(NSString *)command
{
	[THOPluginManagerSharedInstance() sendUserInputDataToBundles:self message:message command:command];
}

- (void)processBundlesServerMessage:(IRCMessage *)message
{
	[THOPluginManagerSharedInstance() sendServerInputDataToBundles:self message:message];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:IRCConnectNormalMode];
}

- (void)connect:(IRCConnectMode)mode
{
	if (self.isQuitting) {
		return;
	}

    [self postEventToViewController:@"serverConnecting"];
	
	[self stopReconnectTimer];

	self.connectType = mode;
	self.disconnectType = IRCDisconnectNormalMode;

	if (self.isConnected) {
		[self.socket close];
	}

	self.isConnecting = YES;
	self.reconnectEnabled = YES;

	NSString *host = self.config.serverAddress;

	NSInteger port = self.config.serverPort;

	/* Do we have a temporary redirect? */
	if (NSObjectIsNotEmpty(self.serverRedirectAddressTemporaryStore)) {
		host = self.serverRedirectAddressTemporaryStore;
	}

	if (self.serverRedirectPortTemporaryStore > 0) {
		port = self.serverRedirectPortTemporaryStore;
	}

	/* Continue connection… */
	[self logFileWriteSessionBegin];

	if (mode == IRCConnectReconnectMode) {
		self.connectionReconnectCount += 1;

		NSString *reconnectCount = TXFormattedNumber(self.connectionReconnectCount);
		
		[self printDebugInformationToConsole:TXTFLS(@"IRCIsReconnectingWithAttemptCount", reconnectCount)];
	} else if (mode == IRCConnectBadSSLCertificateMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRCIsReconnecting")];
	} else if (mode == IRCConnectRetryMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRCIsRetryingConnection")];
	}

	if (PointerIsEmpty(self.socket)) {
		self.socket = [IRCConnection new];
		self.socket.client = self;
	}

	self.socket.serverAddress = host;
	self.socket.serverPort = port;

	self.socket.connectionPrefersIPv6 = self.config.connectionPrefersIPv6;
	self.socket.connectionUsesSSL = self.config.connectionUsesSSL;

	if (self.config.proxyType == TXConnectionSystemSocksProxyType) {
		self.socket.connectionUsesSystemSocks = YES;

		[self printDebugInformationToConsole:TXTFLS(@"IRCIsConnectingWithSystemProxy", host, port)];
	} else if (self.config.proxyType == TXConnectionSocks4ProxyType ||
			   self.config.proxyType == TXConnectionSocks5ProxyType)
	{
		self.socket.connectionUsesNormalSocks = YES;
		
		self.socket.proxyPort = self.config.proxyPort;
		self.socket.proxyAddress = self.config.proxyAddress;
		self.socket.proxyPassword = self.config.proxyPassword;
		self.socket.proxyUsername = self.config.proxyUsername;
		self.socket.proxySocksVersion = self.config.proxyType;

		[self printDebugInformationToConsole:TXTFLS(@"IRCIsConnectingWithNormalProxy", host, port, self.config.proxyAddress, self.config.proxyPort)];
	} else {
		[self printDebugInformationToConsole:TXTFLS(@"IRCIsConnecting", host, port)];
	}

	self.socket.connectionUsesFloodControl = self.config.outgoingFloodControl;

	self.socket.floodControlDelayInterval = self.config.floodControlDelayTimerInterval;
	self.socket.floodControlMaximumMessageCount = self.config.floodControlMaximumMessages;

	[self.socket open];

	[self.worldController reloadTreeGroup:self];
}

- (void)autoConnect:(NSInteger)delay afterWakeUp:(BOOL)afterWakeUp
{
	self.connectDelay = delay;

	if (afterWakeUp) {
		[self autoConnectAfterWakeUp];
	} else {
		[self performSelector:@selector(connect) withObject:nil afterDelay:self.connectDelay];
	}
}

- (void)autoConnectAfterWakeUp
{
	if (self.isLoggedIn) {
		return;
	}
	
	if ([self.hostReachability isReachableViaWiFi]) {
		[self connect];
	} else {
		[self printDebugInformationToConsole:TXTFLS(@"AutoConnectAfterWakeUpHostNotReachable", self.config.serverAddress, @(self.connectDelay))];

		[self performSelector:@selector(autoConnectAfterWakeUp) withObject:nil afterDelay:self.connectDelay];
	}
}

- (void)disconnect
{
	/* This does nothing if there was no previous call to performSelector:withObject:afterDelay:
		but is super important to call if there was. */
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];

	if (self.socket) {
		[self.socket close];
	}

	[self changeStateOff];

	if (self.masterController.terminating) {
		self.masterController.terminatingClientCount -= 1;
	} else {
		[self postEventToViewController:@"serverDisconnected"];
	}
}

- (void)quit
{
	[self quit:nil];
}

- (void)quit:(NSString *)comment
{
    if (self.isQuitting) {
        return;
    }
    
	if (self.isLoggedIn == NO) {
		[self disconnect];

		return;
	}

    [self postEventToViewController:@"serverDisconnecting"];

	self.isQuitting	= YES;
	self.reconnectEnabled = NO;

	[self.socket clearSendQueue];

	if (NSObjectIsEmpty(comment)) {
		comment = self.config.normalLeavingComment;
	}

	[self send:IRCPrivateCommandIndex("quit"), comment, nil];

	[self performSelector:@selector(disconnect) withObject:nil afterDelay:2.0];
}

- (void)cancelReconnect
{
	self.reconnectEnabled = NO;
	self.connectionReconnectCount = 0;

	[self stopReconnectTimer];
}

- (void)changeNick:(NSString *)newNick
{
	if (self.isConnected == NO) {
		return;
	}

	self.sentNick = newNick;

	[self send:IRCPrivateCommandIndex("nick"), newNick, nil];
}

- (void)joinChannel:(IRCChannel *)channel
{
	return [self joinChannel:channel password:nil];
}

- (void)joinUnlistedChannel:(NSString *)channel
{
	[self joinUnlistedChannel:channel password:nil];
}

- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password
{
	PointerIsEmptyAssert(channel);
	
	NSAssertReturn(self.isLoggedIn);
	
	NSAssertReturn(channel.isChannel);
	NSAssertReturn(channel.isActive == NO);

	channel.status = IRCChannelJoining;

	if (NSObjectIsEmpty(password)) {
		if (channel.config.secretKey) {
			password = channel.secretKey;
		} else {
			password = nil;
		}
	}
	
	[self forceJoinChannel:channel.name password:password];
}

- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password
{
	NSObjectIsEmptyAssert(channel);
	
	if ([channel isChannelName:self]) {
		IRCChannel *chan = [self findChannel:channel];

		if (chan) {
			[self joinChannel:chan password:password];
		} else {
			[self forceJoinChannel:channel password:password];
		}
	} else {
		if ([channel isEqualToString:@"0"]) {
			[self forceJoinChannel:channel password:password];
		}
	}
}

- (void)forceJoinChannel:(NSString *)channel password:(NSString *)password
{
	NSObjectIsEmptyAssert(channel);
	
	[self send:IRCPrivateCommandIndex("join"), channel, password, nil];
}

- (void)joinKickedChannel:(IRCChannel *)channel
{
	PointerIsEmptyAssert(channel);

	NSAssertReturn(channel.status == IRCChannelParted);

	[self joinChannel:channel];
}

- (void)partUnlistedChannel:(NSString *)channel
{
	[self partUnlistedChannel:channel withComment:nil];
}

- (void)partChannel:(IRCChannel *)channel
{
	[self partChannel:channel withComment:nil];
}

- (void)partUnlistedChannel:(NSString *)channel withComment:(NSString *)comment
{
	NSObjectIsEmptyAssert(channel);
	
	if ([channel isChannelName:self]) {
		IRCChannel *chan = [self findChannel:channel];

		if (chan) {
			[self partChannel:chan withComment:comment];
		}
	}
}

- (void)partChannel:(IRCChannel *)channel withComment:(NSString *)comment
{
	PointerIsEmptyAssert(channel);

	NSAssertReturn(self.isLoggedIn);

	NSAssertReturn(channel.isChannel);
	NSAssertReturn(channel.isActive);

	channel.status = IRCChannelParted;

	if (NSObjectIsEmpty(comment)) {
		comment = self.config.normalLeavingComment;
	}

	[self send:IRCPrivateCommandIndex("part"), channel.name, comment, nil];
}

- (void)sendWhois:(NSString *)nick
{
	NSAssertReturn(self.isLoggedIn);

	[self send:IRCPrivateCommandIndex("whois"), nick, nick, nil];
}

- (void)kick:(IRCChannel *)channel target:(NSString *)nick
{
	NSAssertReturn(self.isLoggedIn);

	[self send:IRCPrivateCommandIndex("kick"), channel.name, nick, [TPCPreferences defaultKickMessage], nil];
}

- (void)quickJoin:(NSArray *)chans withKeys:(BOOL)passKeys
{
	NSMutableString *channelList = [NSMutableString string];
	NSMutableString *passwordList = [NSMutableString string];

	NSInteger channelCount = 0;

	for (IRCChannel *c in chans) {
		NSMutableString *previousChannelList = [channelList mutableCopy];
		NSMutableString *previousPasswordList = [passwordList mutableCopy];

		c.status = IRCChannelJoining;

		if (c.config.secretKeyIsSet) {
			if (passKeys == NO) {
				continue;
			}
			
			if (NSObjectIsNotEmpty(passwordList)) {
				[passwordList appendString:@","];
			}

			[passwordList appendString:c.secretKey];
		} else {
			if (passKeys) {
				continue;
			}
		}

		if (NSObjectIsNotEmpty(channelList)) {
			[channelList appendString:@","];
		}

		[channelList appendString:c.name];

		if (channelCount > [TPCPreferences autojoinMaxChannelJoins]) {
			if (NSObjectIsEmpty(previousPasswordList)) {
				[self send:IRCPrivateCommandIndex("join"), previousChannelList, nil];
			} else {
				[self send:IRCPrivateCommandIndex("join"), previousChannelList, previousPasswordList, nil];
			}

			[channelList setString:c.name];

			if (c.config.secretKeyIsSet) {
				[passwordList setString:c.secretKey];
			}

			channelCount = 1; // To match setString: statements up above.
		} else {
			channelCount += 1;
		}
	}

	if (NSObjectIsNotEmpty(channelList)) {
		if (NSObjectIsEmpty(passwordList)) {
			[self send:IRCPrivateCommandIndex("join"), channelList, nil];
		} else {
			[self send:IRCPrivateCommandIndex("join"), channelList, passwordList, nil];
		}
	}
}

- (void)quickJoin:(NSArray *)chans
{
	[self quickJoin:chans withKeys:NO];
	[self quickJoin:chans withKeys:YES];
}

- (void)toggleAwayStatus:(BOOL)setAway
{
    [self toggleAwayStatus:setAway withReason:TXTLS(@"IRCAwayCommandDefaultReason")];
}

- (void)toggleAwayStatus:(BOOL)setAway withReason:(NSString *)reason
{
	NSAssertReturn(self.isLoggedIn);

    /* Our internal self.isAway status will be updated by the numeric replies 
     for these. */

	if (setAway && NSObjectIsNotEmpty(reason)) {
		[self send:IRCPrivateCommandIndex("away"), reason, nil];
	} else {
		[self send:IRCPrivateCommandIndex("away"), nil];
	}

	NSString *newNick = nil;
	
	if (setAway) {
		self.preAwayNickname = [self localNickname];

		newNick = self.config.awayNickname;
	} else {
		newNick = self.preAwayNickname;
	}

	if (NSObjectIsNotEmpty(newNick)) {
		[self changeNick:newNick];
	}
}


#pragma mark -
#pragma mark File Transfers

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXFSLongInt)totalFilesize
{
	NSString *description = nil;
	
	switch (type) {
		case TXNotificationFileTransferSendSuccessfulType:
		{
			description = TXTFLS(@"NotificationFileTransferSendSuccessfulDescription", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			description = TXTFLS(@"NotificationFileTransferReceiveSuccessfulDescription", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			description = TXTFLS(@"NotificationFileTransferSendFailedDescription", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			description = TXTFLS(@"NotificationFileTransferReceiveFailedDescription", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			description = TXTFLS(@"NotificationFileTransferReceiveRequestedDescription", filename, totalFilesize);
			
			break;
		}
		default: { break; }
	}
	
	[self notifyEvent:type lineType:0 target:nil nick:nickname text:description];
}

- (void)receivedDCCQuery:(IRCMessage *)m message:(NSMutableString *)rawMessage ignoreInfo:(IRCAddressBook *)ignoreChecks
{
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		/* Gather inital information. */
		NSString *nickname = [m.sender nickname];
		
		/* Only target ourself. */
		if (NSObjectsAreEqual([m paramAt:0], [self localNickname]) == NO) {
			return;
		}
		
		/* Gather basic information. */
		NSString *subcommand = [[rawMessage getToken] uppercaseString];
		
		/* For now, we recognize ACCEPT and RESUME, but we do not act on it. Just adding
		 code for future expansion in another update. Basically, I had time to write the
		 basic handler so I will thank myself in time when it comes to write the rest. */
		BOOL isSendRequest = ([subcommand isEqualToString:@"SEND"]);
	//	BOOL isResumeRequest = ([subcommand isEqualToString:@"RESUME"]);
	//	BOOL isAcceptRequest = ([subcommand isEqualToString:@"ACCEPT"]);
		
		// Process file transfer requests.
		if (isSendRequest /* || isResumeRequest || isAcceptRequest */) {
			/* Check ignore status. */
			if ([ignoreChecks ignoreFileTransferRequests] == YES) {
				return;
			}
			
			/* Gather information about the actual transfer. */
			NSString *section1 = [rawMessage getTokenIncludingQuotes];
			NSString *section2 = [rawMessage getToken];
			NSString *section3 = [rawMessage getToken];
			NSString *section4 = [rawMessage getToken];
			NSString *section5 = [rawMessage getToken];

			/* Trim whitespaces if someone tries to send blank spaces 
			 in a quoted string for filename. */
			section1 = [section1 trim];
			
			/* Remove T from in front of token if it is there. */
			if (isSendRequest) {
				if ([section5 hasPrefix:@"T"]) {
					section5 = [section5 substringFromIndex:1];
				}
			} /* else if (isAcceptRequest || isResumeRequest) {
			   if ([section4 hasPrefix:@"T"]) {
					section4 = [section4 substringFromIndex:1];
			   }
			} */
			
			/* Valid values? */
			NSObjectIsEmptyAssert(section1);
			NSObjectIsEmptyAssert(section2);
		  //NSObjectIsEmptyAssert(section3);
			NSObjectIsEmptyAssert(section4);

			/* Start data association. */
			NSString *hostAddress;
			NSString *hostPort;
			NSString *filename;
			NSString *filesize;
			NSString *transferToken;
			
			/* Match data variables. */
			if (isSendRequest)
			{
				/* Get normal information. */
				filename = [section1 safeFilename];
				filesize =  section4;
				
				hostPort = section3;
				
				transferToken = section5;
				
				/* Translate host address. */
				if ([section2 isNumericOnly]) {
					long long a = [section2 longLongValue];
					
					NSInteger w = (a & 0xff); a >>= 8;
					NSInteger x = (a & 0xff); a >>= 8;
					NSInteger y = (a & 0xff); a >>= 8;
					NSInteger z = (a & 0xff);
					
					hostAddress = [NSString stringWithFormat:@"%d.%d.%d.%d", z, y, x, w];
				} else {
					hostAddress = section2;
				}
			}
			/* else if (isResumeRequest || isAcceptRequest)
			 {
				 filename = section1;
				 filesize = section3;
				 
				 hostPort = section2;
				 
				 transferToken = section4;
				 
				 hostAddress = nil; // ACCEPT and RESUME do not carry the host address.
			 } */
			
			/* Process invidiual commands. */
			if (isSendRequest) {
				/* DCC SEND <filename> <peer-ip> <port> <filesize> [token] */

				/* Important check. */
				NSAssertReturn([filesize longLongValue] > 0);

				/* Add the actual file. */
				if (transferToken && [transferToken length] > 0) {
					/* Validate the transfer token is a number. */
					if ([transferToken isNumericOnly]) {
						/* Is part of reverse DCC request. Let's check if the token
						 already exists somewhere. If it does, we ignore this request. */
						BOOL transferExists = [self.fileTransferController fileTransferExistsWithToken:transferToken];

						/* 0 port indicates a new request in reverse DCC */
						if ([hostPort integerValue] == 0) {
							if (transferExists == NO) {
								[self receivedDCCSend:nickname
											 filename:filename
											  address:hostAddress
												 port:[hostPort integerValue]
											 filesize:[filesize longLongValue]
												token:transferToken];

								return;
							} else {
								LogToConsole(@"Received reverse DCC request with token '%@' but the token already exists.", transferToken);
							}
						} else {
							if (transferExists) {
								TDCFileTransferDialogTransferController *e = [self.fileTransferController fileTransferSenderMatchingToken:transferToken];

								if (e) {
									/* Define transfer information. */
									[e setHostAddress:hostAddress];
									[e setTransferPort:[hostPort integerValue]];

									[e didReceiveSendRequestFromClient];

									return;
								}
							}
						}
					}
				} else {
					/* Treat as normal DCC request. */
					[self receivedDCCSend:nickname
								 filename:filename
								  address:hostAddress
									 port:[hostPort integerValue]
								 filesize:[filesize longLongValue]
									token:nil];

					return;
				}
			}
		}
	}
	
	// Report an error.
	[self print:nil type:TVCLogLineDCCFileTransferType nick:nil text:TXTLS(@"DCCRequestErrorMessage") command:TXLogLineDefaultRawCommandValue];
}


- (void)receivedDCCSend:(NSString *)nickname filename:(NSString *)filename address:(NSString *)address port:(NSInteger)port filesize:(TXFSLongInt)totalFilesize token:(NSString *)transferToken
{
	/* Inform of the DCC and possibly ignore it. */
	NSString *message = TXTFLS(@"DCCFileTransferRequestReceived", nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nick:nil text:message command:TXLogLineDefaultRawCommandValue];
	
	if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyIgnoreAction) {
		return;
	}
	
	/* Post notification. */
	[self notifyFileTransfer:TXNotificationFileTransferReceiveRequestedType nickname:nickname filename:filename filesize:totalFilesize];
	
	/* Add file. */
	[self.fileTransferController addReceiverForClient:self
											 nickname:nickname
											  address:address
												 port:port
											 filename:filename
											 filesize:totalFilesize
												token:transferToken];
}

- (void)sendFile:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXFSLongInt)totalFilesize token:(NSString *)transferToken
{
	/* DCC is mountain lion or later. */
	NSAssertReturn([TPCPreferences featureAvailableToOSXMountainLion]);
	
	/* Build a safe filename. */
	NSString *escapedFileName = [filename stringByReplacingOccurrencesOfString:NSStringWhitespacePlaceholder withString:@"_"];
	
	/* Build the address information. */
	NSString *address = [self DCCTransferAddress];
	
	NSObjectIsEmptyAssert(address);
	
	/* Send file information. */
	NSString *trail;

	if (transferToken && [transferToken length] > 0) {
		trail = [NSString stringWithFormat:@"%@ %@ %i %qi %@", escapedFileName, address, port, totalFilesize, transferToken];
	} else {
		trail = [NSString stringWithFormat:@"%@ %@ %i %qi", escapedFileName, address, port, totalFilesize];
	}
	
	[self sendCTCPQuery:nickname command:@"DCC SEND" text:trail];
	
	NSString *message = TXTFLS(@"DCCFileTransferInitiated", nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nick:nil text:message command:TXLogLineDefaultRawCommandValue];
}

- (NSString *)DCCTransferAddress
{
	NSString *address;
	NSString *baseaddr = [self.fileTransferController cachedIPAddress];
	
	if ([baseaddr isIPv6Address]) {
		address = baseaddr;
	} else {
		NSArray *addrInfo = [baseaddr componentsSeparatedByString:@"."];
		
		NSInteger w = [addrInfo[0] integerValue];
		NSInteger x = [addrInfo[1] integerValue];
		NSInteger y = [addrInfo[2] integerValue];
		NSInteger z = [addrInfo[3] integerValue];
		
		unsigned long long a = 0;
		
		a |= w; a <<= 8;
		a |= x; a <<= 8;
		a |= y; a <<= 8;
		a |= z;
		
		address = [NSString stringWithFormat:@"%qu", a];
	}
	
	return address;
}

#pragma mark -
#pragma mark Command Queue

- (void)processCommandsInCommandQueue
{
	NSTimeInterval now = [NSDate epochTime];

	while (self.commandQueue.count) {
		TLOTimerCommand *m = [self.commandQueue safeObjectAtIndex:0];

		if (m.timerInterval <= now) {
			NSString *target = nil;

			IRCChannel *c = [self.worldController findChannelByClientId:self.treeUUID channelId:m.channelID];

			if (c) {
				target = c.name;
			}

			[self sendCommand:m.rawInput completeTarget:YES target:target];

			[self.commandQueue safeRemoveObjectAtIndex:0];
		} else {
			break;
		}
	}

	if (self.commandQueue.count) {
		TLOTimerCommand *m = [self.commandQueue safeObjectAtIndex:0];

		NSTimeInterval delta = (m.timerInterval - [NSDate epochTime]);

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
		if (m.timerInterval < c.timerInterval) {
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
#pragma mark User Tracking

- (void)handleUserTrackingNotification:(IRCAddressBook *)ignoreItem
							  nickname:(NSString *)nick
							  langitem:(NSString *)localKey
{
	if ([ignoreItem notifyJoins]) {
		NSString *text = TXTFLS(localKey, nick, ignoreItem.hostmask);

		[self notifyEvent:TXNotificationAddressBookMatchType
				 lineType:TVCLogLineNoticeType
				   target:nil
					 nick:nick
					 text:text];
	}
}

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores
{
    NSAssertReturn(self.isLoggedIn);

	if (PointerIsEmpty(self.trackedUsers)) {
		self.trackedUsers = [NSMutableDictionary new];
	}

	/* Create a copy of all old entries. */
	NSDictionary *oldEntries = [self.trackedUsers copy];

	NSMutableDictionary *oldEntriesNicknames = [NSMutableDictionary dictionary];

	for (NSString *lname in oldEntries) {
		oldEntriesNicknames[lname] = (self.trackedUsers)[lname];
	}

	/* Store for the new entries. */
	NSMutableDictionary *newEntries = [NSMutableDictionary dictionary];

	/* Additions & Removels for WATCH command. ISON does not access these. */
	NSMutableArray *watchAdditions = [NSMutableArray array];
	NSMutableArray *watchRemovals = [NSMutableArray array];

	/* First we go through all the new entries fed to this method and add them. */
	for (IRCAddressBook *g in ignores) {
		if (g.notifyJoins) {
			NSString *lname = [g trackingNickname];

			if ([lname isNickname:self]) {
				if ([oldEntriesNicknames containsKeyIgnoringCase:lname]) {
					newEntries[lname] = oldEntriesNicknames[lname];
				} else {
					[newEntries setBool:NO forKey:lname];

					if (self.CAPWatchCommand) {
						/* We only add to the watch list if existing entry is not found. */

						[watchAdditions safeAddObject:lname];
					}
				}
			}
		}
	}

	/* Now that we have an established list of entries that either already
	 existed or are newly added; we now have to go through the old entries
	 and find ones that are not in the new. Those are removals. */
	if (self.CAPWatchCommand) {
		for (NSString *lname in oldEntriesNicknames) {
			if ([newEntries containsKeyIgnoringCase:lname] == NO) {
				[watchRemovals safeAddObject:lname];
			}
		}

		/* Send additions. */
		if (NSObjectIsNotEmpty(watchAdditions)) {
			NSString *addString = [watchAdditions componentsJoinedByString:@" +"];

			[self send:IRCPrivateCommandIndex("watch"), [@"+" stringByAppendingString:addString], nil];
		}

		/* Send removals. */
		if (NSObjectIsNotEmpty(watchRemovals)) {
			NSString *delString = [watchRemovals componentsJoinedByString:@" -"];

			[self send:IRCPrivateCommandIndex("watch"), [@"-" stringByAppendingString:delString], nil];
		}
	}

	/* Finish up. */
	self.trackedUsers = newEntries;

    [self startISONTimer];
}

- (void)startISONTimer
{
	if (self.isonTimer.timerIsActive == NO) {
        [self.isonTimer start:_isonCheckInterval];
    }
}

- (void)stopISONTimer
{
	[self.isonTimer stop];

	[self.trackedUsers removeAllObjects];
}

- (void)onISONTimer:(id)sender
{
    NSAssertReturn(self.isLoggedIn);

    NSMutableString *userstr = [NSMutableString string];

	for (IRCChannel *channel in self.channels) {
		if (self.CAPawayNotify == NO) {
            if (channel.isChannel && channel.isActive && [channel numberOfMembers] <= [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
                [self send:IRCPrivateCommandIndex("who"), channel.name, nil];
            }
        }

		if (channel.isPrivateMessage) {
			[userstr appendFormat:@" %@", channel.name];
		}
    }

	if (self.CAPWatchCommand) {
		for (NSString *name in self.trackedUsers) {
			[userstr appendFormat:@" %@", name]; 
		}
	}

	/* We send a ISON request to track private messages as well as tracked users. */
	NSObjectIsEmptyAssert(userstr);

    [self send:IRCPrivateCommandIndex("ison"), userstr, nil];
}

- (void)checkAddressBookForTrackedUser:(IRCAddressBook *)abEntry inMessage:(IRCMessage *)message
{
    PointerIsEmptyAssert(abEntry);

	NSAssertReturn(self.CAPWatchCommand == NO);
    
    NSString *tracker = [abEntry trackingNickname];

	BOOL ison = [self.trackedUsers boolForKey:tracker];

    /* Notification Type: JOIN Command. */
    if ([message.command isEqualIgnoringCase:@"JOIN"]) {
        if (ison == NO) {
            [self handleUserTrackingNotification:abEntry
                                        nickname:message.sender.nickname
                                        langitem:@"UserTrackingNicknameNowAvailable"];
            
            [self.trackedUsers setBool:YES forKey:tracker];
        }

        return;
    }
    
    /* Notification Type: QUIT Command. */
    if ([message.command isEqualIgnoringCase:@"QUIT"]) {
        if (ison) {
            [self handleUserTrackingNotification:abEntry
                                        nickname:message.sender.nickname
                                        langitem:@"UserTrackingNicknameNoLongerAvailable"];

            [self.trackedUsers setBool:NO forKey:tracker];
        }

        return;
    }
    
    /* Notification Type: NICK Command. */
    if ([message.command isEqualIgnoringCase:@"NICK"]) {
        if (ison) {
            [self handleUserTrackingNotification:abEntry
                                        nickname:message.sender.nickname
                                        langitem:@"UserTrackingNicknameNoLongerAvailable"];
        } else {
            [self handleUserTrackingNotification:abEntry
                                        nickname:message.sender.nickname
                                        langitem:@"UserTrackingNicknameNowAvailable"];
        }

        [self.trackedUsers setBool:BOOLReverseValue(ison) forKey:tracker];
    }
}

#pragma mark -
#pragma mark Channel Ban List Dialog

- (void)createChanBanListDialog
{
    TXMenuController *menuController = self.masterController.menuController;

    [menuController popWindowSheetIfExists];
    
    IRCClient *u = [self.worldController selectedClient];
    IRCChannel *c = [self.worldController selectedChannel];
    
    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanBanSheet *chanBanListSheet = [TDChanBanSheet new];
    
    chanBanListSheet.delegate = self;
    chanBanListSheet.window = self.masterController.mainWindow;

	[chanBanListSheet show];

    [menuController addWindowToWindowList:chanBanListSheet];
}

- (void)chanBanDialogOnUpdate:(TDChanBanSheet *)sender
{
	[sender.banList removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, @"+b", nil];
}

- (void)chanBanDialogWillClose:(TDChanBanSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.changeModeList)) {
		for (NSString *mode in sender.changeModeList) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, mode]];
		}
	}

    [self.masterController.menuController removeWindowFromWindowList:@"TDChanBanSheet"];
}

#pragma mark -
#pragma mark Channel Invite Exception List Dialog

- (void)createChanInviteExceptionListDialog
{
    TXMenuController *menuController = self.masterController.menuController;

    [menuController popWindowSheetIfExists];

    IRCClient *u = [self.worldController selectedClient];
    IRCChannel *c = [self.worldController selectedChannel];

    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanInviteExceptionSheet *inviteExceptionSheet = [TDChanInviteExceptionSheet new];

    inviteExceptionSheet.delegate = self;
    inviteExceptionSheet.window = self.masterController.mainWindow;

    [inviteExceptionSheet show];

    [menuController addWindowToWindowList:inviteExceptionSheet];
}

- (void)chanInviteExceptionDialogOnUpdate:(TDChanInviteExceptionSheet *)sender
{
	[sender.exceptionList removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, @"+I", nil];
}

- (void)chanInviteExceptionDialogWillClose:(TDChanInviteExceptionSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.changeModeList)) {
		for (NSString *mode in sender.changeModeList) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, mode]];
		}
	}

    [self.masterController.menuController removeWindowFromWindowList:@"TDChanInviteExceptionSheet"];
}

#pragma mark -
#pragma mark Chan Ban Exception List Dialog

- (void)createChanBanExceptionListDialog
{
    TXMenuController *menuController = self.masterController.menuController;

    [menuController popWindowSheetIfExists];

    IRCClient *u = [self.worldController selectedClient];
    IRCChannel *c = [self.worldController selectedChannel];

    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanBanExceptionSheet *banExceptionSheet = [TDChanBanExceptionSheet new];

    banExceptionSheet.delegate = self;
    banExceptionSheet.window = self.masterController.mainWindow;

	[banExceptionSheet show];

    [menuController addWindowToWindowList:banExceptionSheet];
}

- (void)chanBanExceptionDialogOnUpdate:(TDChanBanExceptionSheet *)sender
{
	[sender.exceptionList removeAllObjects];

	[self send:IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, @"+e", nil];
}

- (void)chanBanExceptionDialogWillClose:(TDChanBanExceptionSheet *)sender
{
	if (NSObjectIsNotEmpty(sender.changeModeList)) {
		for (NSString *mode in sender.changeModeList) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), self.worldController.selectedChannel.name, mode]];
		}
	}

    [self.masterController.menuController removeWindowFromWindowList:@"TDChanBanExceptionSheet"];
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (NSString *)listDialogWindowKey
{
	/* Create a different window so each client can have its own window open. */

	return [NSString stringWithFormat:@"TDCListDialog -> %@", self.config.itemUUID];
}

- (TDCListDialog *)listDialog
{
    return [self.masterController.menuController windowFromWindowList:self.listDialogWindowKey];
}

- (void)createChannelListDialog
{
    TXMenuController *menuController = self.masterController.menuController;

    NSAssertReturn([menuController popWindowViewIfExists:self.listDialogWindowKey] == NO);
    
    TDCListDialog *channelListDialog = [TDCListDialog new];

    channelListDialog.client = self;
	channelListDialog.delegate = self;
    
    [channelListDialog start];

    [menuController addWindowToWindowList:channelListDialog withKeyValue:self.listDialogWindowKey];
}

- (void)listDialogOnUpdate:(TDCListDialog *)sender
{
	[self sendLine:IRCPrivateCommandIndex("list")];
}

- (void)listDialogOnJoin:(TDCListDialog *)sender channel:(NSString *)channel
{
	self.inUserInvokedJoinRequest = YES;
	
	[self joinUnlistedChannel:channel];
}

- (void)listDialogWillClose:(TDCListDialog *)sender
{
    [self.masterController.menuController removeWindowFromWindowList:self.listDialogWindowKey];
}

#pragma mark -
#pragma mark Deprecated

- (void)printError:(NSString *)error
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt
{
	TEXTUAL_DEPRECATED_ASSERT;
}

@end
