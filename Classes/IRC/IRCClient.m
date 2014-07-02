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
#define _trialPeriodInterval		43200 // 12 HOURS

@interface IRCClient ()
/* These are all considered private. */

@property (nonatomic, strong) IRCConnection *socket;
@property (nonatomic, assign) BOOL isInvokingISONCommandForFirstTime;
@property (nonatomic, assign) BOOL timeoutWarningShownToUser;
@property (nonatomic, assign) NSInteger tryingNicknameNumber;
@property (nonatomic, assign) NSUInteger CAPPausedStatus;
@property (nonatomic, assign) NSTimeInterval lastLagCheck;
@property (nonatomic, strong) NSString *cachedLocalHostmask;
@property (nonatomic, strong) NSString *cachedLocalNickname;
@property (nonatomic, strong) NSString *tryingNicknameSentNickname;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *trialPeriodTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;
@property (nonatomic, assign) ClientIRCv3SupportedCapacities capacitiesPending;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, nweak) IRCChannel *lagCheckDestinationChannel;
@end

@implementation IRCClient

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if ((self = [super init]))
	{
		/* ---- */
		self.supportInfo = [IRCISupportInfo new];
		
		/* ---- */
		self.connectType = IRCClientConnectNormalMode;
		self.disconnectType = IRCClientDisconnectNormalMode;
		
		/* ---- */
		self.inUserInvokedNamesRequest = NO;
		self.inUserInvokedWatchRequest = NO;
		self.inUserInvokedWhoRequest = NO;
		self.inUserInvokedWhowasRequest = NO;
		self.inUserInvokedModeRequest = NO;
		self.inUserInvokedJoinRequest = NO;
		self.inUserInvokedWatchRequest = NO;
		
		/* ---- */
		self.capacitiesPending = 0;
		self.capacities = 0;
		
		/* ---- */
		self.isAutojoined = NO;
		self.isAway = NO;
		self.isConnected = NO;
		self.isConnecting = NO;
		self.isIdentifiedWithNickServ = NO;
		self.isInvokingISONCommandForFirstTime = NO;
		self.isLoggedIn = NO;
		self.isQuitting = NO;
		self.isWaitingForNickServ = NO;
		self.isZNCBouncerConnection = NO;
		
		/* ---- */
		self.autojoinInProgress = NO;
		self.rawModeEnabled = NO;
		self.reconnectEnabled = NO;
		self.serverHasNickServ = NO;
		self.timeoutWarningShownToUser = NO;
		
		/* ---- */
		self.cachedHighlights = @[];
		
		/* ---- */
		self.lastSelectedChannel = nil;
		
		/* ---- */
		self.lastLagCheck = 0;
		
		/* ---- */
		self.cachedLocalHostmask = nil;
		self.cachedLocalNickname = nil;
		
		/* ---- */
		self.tryingNicknameSentNickname = nil;
		self.tryingNicknameNumber = -1;
		
		/* ---- */
		self.channels = [NSMutableArray array];
		self.commandQueue = [NSMutableArray array];
		
		/* ---- */
		self.trackedUsers = [NSMutableDictionary dictionary];
		
		/* ---- */
		self.preAwayNickname = nil;
		
		/* ---- */
		self.lastMessageReceived = 0;
		self.lastMessageServerTime = 0;
		
		/* ---- */
		self.serverRedirectAddressTemporaryStore = nil;
		self.serverRedirectPortTemporaryStore = 0;
		
		/* ---- */
		self.reconnectTimer					= [TLOTimer new];
		self.reconnectTimer.delegate		= self;
		self.reconnectTimer.reqeatTimer		= NO;
		self.reconnectTimer.selector		= @selector(onReconnectTimer:);
		
		/* ---- */
		self.retryTimer						= [TLOTimer new];
		self.retryTimer.delegate			= self;
		self.retryTimer.reqeatTimer			= NO;
		self.retryTimer.selector			= @selector(onRetryTimer:);
		
		/* ---- */
		self.commandQueueTimer				= [TLOTimer new];
		self.commandQueueTimer.delegate		= self;
		self.commandQueueTimer.reqeatTimer	= NO;
		self.commandQueueTimer.selector		= @selector(onCommandQueueTimer:);
		
		/* ---- */
		self.pongTimer						= [TLOTimer new];
		self.pongTimer.delegate				= self;
		self.pongTimer.reqeatTimer			= YES;
		self.pongTimer.selector				= @selector(onPongTimer:);
		
		/* ---- */
		self.isonTimer						= [TLOTimer new];
		self.isonTimer.delegate				= self;
		self.isonTimer.reqeatTimer			= YES;
		self.isonTimer.selector				= @selector(onISONTimer:);
		
		/* ---- */
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
	
#ifdef TEXTUAL_TRIAL_BINARY
	[self.trialPeriodTimer stop];
#endif

	[self.socket close];
}

- (void)setup:(id)seed
{
	if ([seed isKindOfClass:[NSDictionary class]]) {
		self.config = [[IRCClientConfig alloc] initWithDictionary:seed];
	} else if ([seed isKindOfClass:[IRCClientConfig class]]) {
		self.config = seed; // Setter will copy.
	} else {
		NSAssert(NO, @"Bad configuration type.");
	}

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
	/* Ignore if we have equality. */
	NSAssertReturn([seed isEqualToClientConfiguration:_config] == NO);
	
	/* Did the ignore list change at all? */
	BOOL ignoreListIsSame = NSObjectsAreEqual(self.config.ignoreList, seed.ignoreList);
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* It is important to know this value changed before seed update. */
	BOOL syncToCloudIsSame = (self.config.excludedFromCloudSyncing == seed.excludedFromCloudSyncing);
	
	/* Temporary store. */
	/* The identity certificate cannot be stored in the cloud since it requires to
	 a reference to a local resource. Therefore, when updating from the cloud, we
	 take the value stored locally, cache it into a local variable, allow the new
	 seed to be applied, then apply that value back to the seed. This allows the
	 user to define certificates on each machine. */
	NSData *identitySSLCertificateInformation = self.config.identitySSLCertificate;
#endif
	
	/* Write all channel keychains before copying over new configuration. */
	for (IRCChannelConfig *i in [seed channelList]) {
		[i writeKeychainItemsToDisk];
	}
	
	/* Populate new seed. */
	self.config = seed; // Setter handles copy.
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* Update new, local seed with cache SSL certificate. */
	self.config.identitySSLCertificate = identitySSLCertificateInformation;
	
	/* Maybe remove this client from deleted list (maybe). */
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if (syncToCloudIsSame == NO) {
			if (self.config.excludedFromCloudSyncing == NO) {
				[worldController() removeClientFromListOfDeletedClients:[self uniqueIdentifier]];
			}
		}
	}
#endif
	
	/* Begin normal operations. */
	/* List of channels that are in current configuration. */
	NSArray *channelConfigurations = self.config.channelList;
	
	/* List of channels actively particpating with this client. */
	NSMutableArray *originalChannelList;
	
	@synchronized(self.channels) {
		originalChannelList = [NSMutableArray arrayWithObject:self.channels];
	}
	
	/* New list of channels to reflect configuration. */
	NSMutableArray *newChannelList = [NSMutableArray array];

	for (IRCChannelConfig *i in channelConfigurations) {
		/* First we check whether the configured channel 
		 exists in the current context of the client. */
		IRCChannel *cinl = [self findChannel:[i channelName] inList:originalChannelList];

		if (cinl) {
			/* It exists so we update its configuration. */
			[cinl updateConfig:i];

			/* We also are sure to add it to new list of channels. */
			[newChannelList addObject:cinl];

			/* Lastly, we remove the channel from the old list. */
			[originalChannelList removeObjectIdenticalTo:cinl];
		} else {
			/* The channel was not found in the old list so we now check if it
			 exists again in the new array. */
			IRCChannel *cina = [self findChannel:[i channelName] inList:newChannelList];

			if (cina) {
				/* Channels are removed from self.channels here which means that
				 another pass of findChannel: will not find duplicates. So, instead,
				 we scan the new array. */

				continue; // Do not allow duplicates.
			} else {
				cinl = [worldController() createChannel:i client:self reload:NO adjust:NO];

				[newChannelList addObject:cinl];
			}
		}
	}

	/* Any channels left in the old array can be destroyed 
	 or if they are not a channel, then they can be reinserted
	 because we do not care about private messages being updated
	 above so they must be reinserted here. */
	for (IRCChannel *c in originalChannelList) {
		if ([c isChannel]) {
			[self partChannel:c];
		} else {
			[newChannelList addObject:c];
		}
	}

	/* And of course once we are done, we update the actual
	 client side list of channels. */
	@synchronized(self.channels) {
		[self.channels removeAllObjects];
		[self.channels addObjectsFromArray:newChannelList];
	}
	
	/* Reset stored channel list now that we are done. */
	[self updateStoredChannelList];

	/* We also write all passwords to Keychain here. */
	[self.config writeKeychainItemsToDisk];
	
	/* Lastly, if our ignore list changed, we need to inform
	 downstream of that fact. */
	if (ignoreListIsSame == NO) {
		[self populateISONTrackedUsersList:self.config.ignoreList];
	}
	
	/* reloadItem will drop the views and reload them. We need to remember
	 the selection because of this. */
	if (reloadSelection) {
		id selectedItem = [mainWindow() selectedItem];
		
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:YES];
	
		[mainWindowServerList() reloadItem:self reloadChildren:YES];

		[mainWindow() select:selectedItem];
		[mainWindow() adjustSelection];
		
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:NO];
	}
}

- (void)updateStoredChannelList
{
	NSMutableArray *newChannelList = [NSMutableArray array];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c isChannel] || [TPCPreferences rememberServerListQueryStates]) {
				[newChannelList addObject:[c.config copy]];
			}
		}
	}
	
	[self.config setChannelList:newChannelList];
}

- (IRCClientConfig *)copyOfStoredConfig
{
	return [self.config copyWithoutPrivateMessages];
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self.config dictionaryValue:NO];
}

- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary
{
	return [self.config dictionaryValue:isCloudDictionary];
}

- (void)prepareForApplicationTermination
{
	/* Archive server-time timestamp if certain conditions are met. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityServerTime]) {
		if ([TPCPreferences logToDiskIsEnabled]) {
			if (self.lastMessageServerTime > 0) {
				self.config.cachedLastServerTimeCapacityReceivedAtTimestamp = self.lastMessageServerTime;
			}
		}
	}
	
	/* Perform normal operations. */
	[self quit];
	
	[self closeDialogs];
	[self closeLogFile];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c prepareForApplicationTermination];
		}
	}

	[self.viewController prepareForApplicationTermination];
}

- (void)prepareForPermanentDestruction
{
	[self quit];
	
	[self closeDialogs];
	[self closeLogFile];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c prepareForPermanentDestruction];
		}
	}
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)closeDialogs
{
    [menuController() popWindowViewIfExists:[self listDialogWindowKey]];
    [menuController() popWindowSheetIfExists];
}

- (void)preferencesChanged
{
	[self reopenLogFileIfNeeded];

	[self.viewController preferencesChanged];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c preferencesChanged];

			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]) {
				if ([c numberOfMembers] > [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
					for (IRCUser *u in [c sortedByChannelRankMemberList]) {
						u.isAway = NO;
					}
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)uniqueIdentifier
{
	return self.config.itemUUID;
}

- (NSString *)name
{
	return self.config.clientName;
}

- (NSString *)networkName
{
	return self.supportInfo.networkName;
}

- (NSString *)altNetworkName
{
	if (NSObjectIsEmpty(self.supportInfo.networkName)) {
		return self.config.clientName;
	} else {
		return self.supportInfo.networkName;
	}
}

- (NSString *)networkAddress
{
	return self.supportInfo.networkAddress;
}

- (NSString *)localNickname
{
	if (NSObjectIsEmpty(self.cachedLocalNickname)) {
		return self.config.nickname;
	} else {
		return self.cachedLocalNickname;
	}
}

- (NSString *)localHostmask
{
	return self.cachedLocalHostmask;
}

- (TDCFileTransferDialog *)fileTransferController
{
	return [menuController() fileTransferController];
}

- (BOOL)isReconnecting
{
	return self.reconnectTimer.timerIsActive;
}

- (NSTimeInterval)lastMessageServerTimeWithCachedValue
{
	/* If the server time being fetched is currently has no value
	 and logging is enabled, then check whether we stored a timestamp
	 from a previous session of Textual and restore that. */
	static BOOL _checkedForPreviousSessionTime = NO;

	if (_checkedForPreviousSessionTime == NO) {
		if ([TPCPreferences logToDiskIsEnabled]) {
			if (self.lastMessageServerTime == 0) {
				double storedTime = self.config.cachedLastServerTimeCapacityReceivedAtTimestamp;

				if (storedTime) {
					self.lastMessageServerTime = storedTime;
				}
			}

			_checkedForPreviousSessionTime = YES;
		}
	}

	return self.lastMessageServerTime;
}

#pragma mark -
#pragma mark Highlights

- (void)addHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine
{
	PointerIsEmptyAssert(channel);
	PointerIsEmptyAssert(logLine);
	
	if ([TPCPreferences logHighlights]) {
		/* Render message. */
		NSString *messageBody;
		NSString *nicknameBody = [logLine formattedNickname:channel];
		
		if ([logLine lineType] == TVCLogLineActionType) {
			if ([nicknameBody hasSuffix:@":"]) {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogAlternativeActionFormat, [nicknameBody trim], logLine.messageBody];
			} else {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardActionFormat, [nicknameBody trim], logLine.messageBody];
			}
		} else {
			messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardMessageFormat, [nicknameBody trim], logLine.messageBody];
		}
		
		/* Create entry. */
		NSArray *entry = @[channel.name, @([NSDate epochTime]), [messageBody attributedStringWithIRCFormatting:TXPreferredGlobalTableViewFont]];
		
		/* We insert at head so that latest is always on top. */
		NSMutableArray *highlightData = [self.cachedHighlights mutableCopy];
		
		[highlightData insertObject:entry atIndex:0];
		
		self.cachedHighlights = highlightData; // Setter will perform copy.
		
		/* Reload table if the window is open. */
		id highlightSheet = [menuController() windowFromWindowList:@"TDCHighlightListSheet"];
		
		if (highlightSheet) {
			[highlightSheet performSelector:@selector(reloadTable) withObject:nil afterDelay:2.0];
		}
	}
}
#pragma mark -
#pragma mark Reachability

- (BOOL)isHostReachable
{
	return [[TXSharedApplication sharedNetworkReachabilityObject] isReachable];
}

- (void)reachabilityChanged:(BOOL)reachable
{
	if (reachable == NO) {
		if (self.isLoggedIn) {
			if (self.config.performDisconnectOnReachabilityChange) {
				self.disconnectType = IRCClientDisconnectReachabilityChangeMode;
				self.reconnectEnabled = YES;
				
				[self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
			}
		}
	}
}

#pragma mark -
#pragma mark Channel Storage

- (NSInteger)channelCount
{
	__block NSInteger channelCount = 0;
	
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			channelCount = [self.channels count];
		}
	});
	
	return channelCount;
}

- (void)addChannel:(IRCChannel *)channel
{
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels addObjectWithoutDuplication:channel];
			
			[self updateStoredChannelList];
		}
	});
}

- (void)addChannel:(IRCChannel *)channel atPosition:(NSInteger)pos
{
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels insertObject:channel atIndex:pos];
			
			[self updateStoredChannelList];
		}
	});
}

- (void)removeChannel:(IRCChannel *)channel
{
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels removeObjectIdenticalTo:channel];
		}
	});
}

- (NSInteger)indexOfFirstPrivateMessage
{
	__block NSInteger i = 0;
	
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			for (IRCChannel *e in self.channels) {
				if ([e isPrivateMessage]) {
					return;
				}
				
				i += 1;
			}
		}
	});
	
	return -1;
}

- (NSInteger)indexOfChannel:(IRCChannel *)channel
{
	__block NSInteger i = 0;
	
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			i = [self.channels indexOfObject:channel];
		}
	});
	
	return -1;
}

- (void)selectFirstChannelInChannelList
{
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			if ([self.channels count] > 0) {
				[mainWindow() select:self.channels[0]];
			}
		}
	});
}

- (NSArray *)channelList
{
	__block NSArray *channelList = nil;
	
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			channelList = [NSArray arrayWithArray:self.channels];
		}
	});
	
	return channelList;
}

- (void)setChannelList:(NSArray *)channelList
{
	TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels removeAllObjects];
			
			[self.channels addObjectsFromArray:channelList];
			
			[self updateStoredChannelList];
		}
	});
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

- (IRCClient *)associatedClient
{
	return self;
}

- (IRCChannel *)associatedChannel
{
	return nil;
}

- (NSInteger)numberOfChildren
{
	return [self channelCount];
}

- (id)childAtIndex:(NSInteger)index
{
	return self.channels[index];
}

- (NSString *)label
{
	return [self.config.clientName uppercaseString];
}

#pragma mark -
#pragma mark Encoding

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	NSData *s = [data dataUsingEncoding:self.config.primaryEncoding allowLossyConversion:NO];

	if (s == nil) {
		s = [data dataUsingEncoding:self.config.fallbackEncoding allowLossyConversion:NO];

		if (s == nil) {
			s = [data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		}
	}

	if (s == nil) {
		DebugLogToConsole(@"NSData encode failure. (%@)", data);
	}

	return s;
}

- (NSString *)convertFromCommonEncoding:(NSData *)data
{
	NSString *s = [NSString stringWithBytes:[data bytes] length:[data length] encoding:self.config.primaryEncoding];

	if (s == nil) {
		s = [NSString stringWithBytes:[data bytes] length:[data length] encoding:self.config.fallbackEncoding];

		if (s == nil) {
			s = [NSString stringWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
		}
	}

	if (s == nil) {
		DebugLogToConsole(@"NSData decode failure. (%@)", data);
	}

	return s;
}

#pragma mark -
#pragma mark Ignore Matching

- (IRCAddressBookEntry *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches
{
	NSObjectIsEmptyAssertReturn(host, nil);
	NSObjectIsEmptyAssertReturn(matches, nil);
	
	NSString *hostmask = [host lowercaseString];

	for (IRCAddressBookEntry *g in self.config.ignoreList) {
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

	NSArray *rules = [sharedPluginManager() outputRulesForCommand:IRCCommandFromLineType(type)];

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

		if ([newstr length]< 5) {
			[self printDebugInformation:BLS(1001) channel:channel];

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
			(*message) = newstr;
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
		case TXNotificationChannelMessageType:						{ return BLS(1043);		}
		case TXNotificationChannelNoticeType:						{ return BLS(1044);		}
		case TXNotificationConnectType:								{ return BLS(1051);		}
		case TXNotificationDisconnectType:							{ return BLS(1052);		}
		case TXNotificationInviteType:								{ return BLS(1046);		}
		case TXNotificationKickType:								{ return BLS(1047);		}
		case TXNotificationNewPrivateMessageType:					{ return BLS(1048);		}
		case TXNotificationPrivateMessageType:						{ return BLS(1049);		}
		case TXNotificationPrivateNoticeType:						{ return BLS(1050);		}
		case TXNotificationHighlightType:							{ return BLS(1045);		}

		case TXNotificationFileTransferSendSuccessfulType:			{ return BLS(1053);		}
		case TXNotificationFileTransferReceiveSuccessfulType:		{ return BLS(1054);		}
		case TXNotificationFileTransferSendFailedType:				{ return BLS(1055);		}
		case TXNotificationFileTransferReceiveFailedType:			{ return BLS(1056);		}
		case TXNotificationFileTransferReceiveRequestedType:		{ return BLS(1057);		}
	
		default: { return nil; }
	}

	return nil;
}

- (void)speakEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text
{
	text = [text trim]; // Do not leave spaces in text to be spoken.
	text = [text stripIRCEffects]; // Do not leave formatting in text to be spoken.

	NSString *formattedMessage;
	
	switch (type) {
		case TXNotificationHighlightType:
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		{
			NSObjectIsEmptyAssertLoopBreak(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];
			
			formattedMessage = TXTLS(nformatString, [[target name] channelNameToken], nick, text);

			break;
		}
		case TXNotificationNewPrivateMessageType:
		case TXNotificationPrivateMessageType:
		case TXNotificationPrivateNoticeType:
		{
			NSObjectIsEmptyAssertLoopBreak(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, nick, text);
			
			break;
		}
		case TXNotificationKickType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, [[target name] channelNameToken], nick);

			break;
		}
		case TXNotificationInviteType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, [text channelNameToken], nick);

			break;
		}
		case TXNotificationConnectType:
		case TXNotificationDisconnectType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, [self altNetworkName]);
			
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
			
			formattedMessage = TXTLS(nformatString, nick);
		}
	}

	NSObjectIsEmptyAssert(formattedMessage);

	[[TXSharedApplication sharedSpeechSynthesizer] speak:formattedMessage];
}

- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}

	PointerIsEmptyAssertReturn(target, NO);

	NSObjectIsEmptyAssertReturn(text, NO);
	NSObjectIsEmptyAssertReturn(nick, NO);

	if ([nick isEqualIgnoringCase:[self localNickname]]) {
		return NO;
	}

	NSString *channelName = [target name];

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

	if ([sharedGrowlController() areNotificationsDisabled]) {
		return YES;
	}
	
	if ([sharedGrowlController() areNotificationSoundsDisabled]) {
		[TLOSoundPlayer playAlertSound:[TPCPreferences soundForEvent:type]];

		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}

	if ([TPCPreferences growlEnabledForEvent:type] == NO) {
		return YES;
	}

	if ([TPCPreferences postNotificationsWhileInFocus] == NO && [mainWindow() isInactive] == NO) {
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
		nick = [self formatNickname:nick channel:target];

		desc = [NSString stringWithFormat:TXNotificationDialogStandardNicknameFormat, nick, text];
	}

	NSDictionary *userInfo = @{@"client" : self.treeUUID, @"channel" : target.treeUUID};
	
	[sharedGrowlController() notify:type title:title description:desc userInfo:userInfo];

	return YES;
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype
{
	return [self notifyEvent:type lineType:ltype target:nil nickname:NSStringEmptyPlaceholder text:NSStringEmptyPlaceholder];
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}
	
	//NSObjectIsEmptyAssertReturn(text, NO);
	//NSObjectIsEmptyAssertReturn(nick, NO);
    
    if ([TPCPreferences bounceDockIconForEvent:type]) {
        [NSApp requestUserAttention:NSInformationalRequest];
    }
	
	if ([sharedGrowlController() areNotificationsDisabled]) {
		return YES;
	}
	
	if ([sharedGrowlController() areNotificationSoundsDisabled]) {
		[TLOSoundPlayer playAlertSound:[TPCPreferences soundForEvent:type]];
		
		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}

	if ([TPCPreferences growlEnabledForEvent:type] == NO) {
		return YES;
	}

	if ([TPCPreferences postNotificationsWhileInFocus] == NO && [mainWindow() isInactive] == NO) {
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

	NSString *title = nil;
	NSString *desc = nil;
	
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
			
			title = [target name];
			
			desc = BLS(1077, nick, text);

			break;
		}
		case TXNotificationInviteType:
		{
			title = [self altNetworkName];
			
			desc = BLS(1076, nick, text);

			break;
		}
		default: { return YES; }
	}

	[sharedGrowlController() notify:type title:title description:desc userInfo:info];
	
	return YES;
}

#pragma mark -
#pragma mark ZNC Bouncer Accessories

- (BOOL)isSafeToPostNotificationForMessage:(IRCMessage *)m inChannel:(IRCChannel *)channel
{
	// Validate input.
	PointerIsEmptyAssertReturn(m, NO);
	PointerIsEmptyAssertReturn(channel, NO);
	
	// Post if user doesn't give a shit.
	if (self.config.zncIgnorePlaybackNotifications == NO) {
		return YES;
	}

	// Check other conditionals.
	return ([self messageIsPartOfZNCPlaybackBuffer:m inChannel:channel] == NO); // Do playback check…
}

- (BOOL)messageIsPartOfZNCPlaybackBuffer:(IRCMessage *)m inChannel:(IRCChannel *)channel
{
	PointerIsEmptyAssertReturn(m, NO);
	PointerIsEmptyAssertReturn(channel, NO);
	
	if (self.isZNCBouncerConnection == NO) {
		return NO;
	}
	
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityServerTime] == NO) {
		return NO;
	}

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
	BOOL isActiveWindow = [mainWindow() isKeyWindow];

	if (NSDissimilarObjects([mainWindow() selectedItem], t) || isActiveWindow == NO) {
		t.nicknameHighlightCount += 1;

		[TVCDockIcon updateDockIcon];
		
		[mainWindow() reloadTreeItem:t];
	}

	if (t.isUnread || (isActiveWindow && [mainWindow() selectedItem] == t)) {
		return;
	}
}

- (void)setUnreadState:(IRCChannel *)t
{
	[self setUnreadState:t isHighlight:NO];
}

- (void)setUnreadState:(IRCChannel *)t isHighlight:(BOOL)isHighlight
{
	BOOL isActiveWindow = [mainWindow() isKeyWindow];

	if (t.isPrivateMessage || ([TPCPreferences displayPublicMessageCountOnDockBadge] && t.isChannel)) {
		if (NSDissimilarObjects([mainWindow() selectedItem], t) || isActiveWindow == NO) {
			t.dockUnreadCount += 1;
			
			[TVCDockIcon updateDockIcon];
		}
	}

	if (isActiveWindow == NO || (NSDissimilarObjects([mainWindow() selectedItem], t) && isActiveWindow)) {
		t.treeUnreadCount += 1;

		if (t.config.showTreeBadgeCount || (t.config.showTreeBadgeCount == NO && isHighlight)) {
			[mainWindow() reloadTreeItem:t];
		}
	}
}

#pragma mark -
#pragma mark Find Channel

- (IRCChannel *)findChannel:(NSString *)name inList:(NSArray *)channelList
{
	for (IRCChannel *c in channelList) {
		if ([name isEqualIgnoringCase:c.name]) {
			return c;
		}
	}

	return nil;
}

- (IRCChannel *)findChannel:(NSString *)name
{
	@synchronized(self.channels) {
		return [self findChannel:name inList:self.channels];
	}
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name
{
	return [self findChannelOrCreate:name isPrivateMessage:NO];
}

- (IRCChannel *)findChannelOrCreate:(NSString *)name isPrivateMessage:(BOOL)isPM
{
	IRCChannel *c = [self findChannel:name];

	if (c == nil) {
		if (isPM) {
			return [worldController() createPrivateMessage:name client:self];
		} else {
			IRCChannelConfig *seed = [IRCChannelConfig new];

			[seed setChannelName:name];

			return [worldController() createChannel:seed client:self reload:YES adjust:YES];
		}
	}

	return c;
}

#pragma mark -
#pragma mark Send Raw Data

- (void)sendLine:(NSString *)str
{
	if (self.isConnected == NO) {
		return [self printDebugInformationToConsole:BLS(1199)];
	}

	[self.socket sendLine:str];

	worldController().messagesSent += 1;
	worldController().bandwidthOut += [str length];
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

	NSString *s = [IRCSendingMessage stringWithCommand:str arguments:ary];

	NSObjectIsEmptyAssert(s);

	[self sendLine:s];
}

#pragma mark -
#pragma mark Sending Text

- (void)inputText:(id)str command:(NSString *)command
{
	id sel = [mainWindow() selectedItem];
	
	PointerIsEmptyAssert(sel);

	NSObjectIsEmptyAssert(str);
	NSObjectIsEmptyAssert(command);

	if ([str isKindOfClass:[NSString class]]) {
		str = [NSAttributedString emptyStringWithBase:str];
	}

	NSArray *lines = [str performSelector:@selector(splitIntoLines)];

	for (__strong NSAttributedString *s in lines) {
		NSRange chopRange = NSMakeRange(1, ([s length] - 1));

		if ([sel isClient]) {
			if ([[s string] hasPrefix:@"/"]) {
				if ([s length] > 1) {
					s = [s attributedSubstringFromRange:chopRange];
					
					[self sendCommand:s];
				}
			} else {
				[self sendCommand:s];
			}
		} else {
			IRCChannel *channel = (IRCChannel *)sel;

			if ([[s string] hasPrefix:@"/"] && [[s string] hasPrefix:@"//"] == NO && [s length] > 1) {
				s = [s attributedSubstringFromRange:chopRange];

				[self sendCommand:s];
			} else {
				if ([[s string] hasPrefix:@"/"] && [s length] > 1) {
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

		while ([strc length] > 0)
		{
			NSString *newstr = [strc attributedStringToASCIIFormatting:&strc
															  lineType:type
															   channel:[channel name]
															  hostmask:self.cachedLocalHostmask];

            BOOL encrypted = (encryptChat && [self isSupportedMessageEncryptionFormat:newstr channel:channel]);

			[self print:channel
				   type:type
			   nickname:[self localNickname]
			messageBody:newstr
			isEncrypted:encrypted
			 receivedAt:[NSDate date]
				command:commandActual];

            if (encrypted) {
                NSAssertReturnLoopContinue([self encryptOutgoingMessage:&newstr channel:channel]);
            }
            
			if (type == TVCLogLineActionType) {
				command = IRCPrivateCommandIndex("privmsg");

				newstr = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), newstr, 0x01];
			}

			[self send:command, [channel name], newstr, nil];
		}
	}
	
	[self processBundlesUserMessage:[str string] command:NSStringEmptyPlaceholder];
}

- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString emptyStringWithBase:message]
			   command:IRCPrivateCommandIndex("privmsg")
			   channel:channel];
	}];
}

- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString emptyStringWithBase:message]
			   command:IRCPrivateCommandIndex("action")
			   channel:channel];
	}];
}

- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString emptyStringWithBase:message]
			   command:IRCPrivateCommandIndex("notice")
			   channel:channel];
	}];
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString emptyStringWithBase:message]
			   command:IRCPrivateCommandIndex("privmsg")
			   channel:[mainWindow() selectedChannelOn:self]];
	}];
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

	NSString *rawcaseCommand = [s getTokenAsString];
	
	NSString *uppercaseCommand = [rawcaseCommand uppercaseString];
	NSString *lowercaseCommand = [rawcaseCommand lowercaseString];
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	IRCChannel *selChannel = nil;

	if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("mode")] && ([[s string] hasPrefix:@"+"] || [[s string] hasPrefix:@"-"]) == NO) {
		// Do not complete for /mode #chname ...
	} else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	NSString *uncutInput = [s string];

	switch ([IRCCommandIndex indexOfIRCommand:uppercaseCommand publicSearch:YES]) {
		case 5004: // Command: AWAY
		{
			if (NSObjectIsEmpty(uncutInput)) {
                uncutInput = BLS(1115);
			}
            
            if (self.isAway) {
                uncutInput = nil;
            }
			
			BOOL setAway = NSObjectIsNotEmpty(uncutInput);

            if ([TPCPreferences awayAllConnections]) {
                for (IRCClient *client in [worldController() clientList]) {
                    [client toggleAwayStatus:setAway withReason:uncutInput];
                }
            } else {
                [self toggleAwayStatus:setAway withReason:uncutInput];
            }

			break;
		}
		case 5030: // Command: INVITE
		{
			NSObjectIsEmptyAssert(uncutInput);

			NSMutableArray *nicks = [NSMutableArray arrayWithArray:[uncutInput componentsSeparatedByString:NSStringWhitespacePlaceholder]];

			if (NSObjectIsNotEmpty(nicks) && [[nicks lastObject] isChannelName:self]) {
				targetChannelName = [nicks lastObject];

				[nicks removeLastObject];
			} else if (selChannel && [selChannel isChannel]) {
				targetChannelName = [selChannel name];
			} else {
				return;
			}

			for (NSString *nick in nicks) {
				if ([nick isNickname] && [nick isChannelName:self] == NO) {
					[self send:uppercaseCommand, nick, targetChannelName, nil];
				}
			}
			
			break;
		}
		case 5031: // Command: J
		case 5032:  // Command: JOIN
		{
			if (selChannel && [selChannel isChannel] && NSObjectIsEmpty(uncutInput)) {
				targetChannelName = [selChannel name];
			} else {
				NSObjectIsEmptyAssert(uncutInput);

				targetChannelName = [s getTokenAsString];

				if ([targetChannelName isChannelName:self] == NO && [targetChannelName isEqualToString:@"0"] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}

			self.inUserInvokedJoinRequest = YES;

			[self send:IRCPrivateCommandIndex("join"), targetChannelName, [s string], nil];

			break;
		}
		case 5033: // Command: KICK
		{
			NSObjectIsEmptyAssert(uncutInput);
				
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelName:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *nickname = [s getTokenAsString];
			NSString *reason = [s trimmedString];

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

			NSString *nickname = [s getTokenAsString];
			NSString *reason = [s trimmedString];

			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences IRCopDefaultKillMessage];
			}

			[self send:IRCPrivateCommandIndex("kill"), nickname, reason, nil];

			break;
		}
		case 5037: // Command: LIST
		{
			if ([self listDialog] == nil) {
				[self createChannelListDialog];
			}

			[self send:IRCPrivateCommandIndex("list"), [s string], nil];

			break;
		}
		case 5048: // Command: NICK
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSString *newnick = [s getTokenAsString];
			
			if ([TPCPreferences nickAllConnections]) {
				for (IRCClient *client in [worldController() clientList]) {
					[client changeNickname:newnick];
				}
			} else {
				[self changeNickname:newnick];
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

			/* Destination. */
			if (selChannel && type == TVCLogLineActionType && secretMsg == NO) {
				targetChannelName = [selChannel name];
			} else if (selChannel && [selChannel isChannel] && [[s string] isChannelName:self] == NO && opMsg) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			if (type == TVCLogLineActionType) {
				if (NSObjectIsEmpty(s)) {
					/* If the input is empty, then set one space character as our input
					 when using the /me command so that the use of /me without any input
					 still sends an action. */

					s = [NSMutableAttributedString mutableStringWithBase:NSStringWhitespacePlaceholder attributes:nil];
				}
			} else {
				NSObjectIsEmptyAssert(s);
			}
			
			NSObjectIsEmptyAssert(targetChannelName);
			
			NSArray *targets = [targetChannelName componentsSeparatedByString:@","];

			while ([s length] > 0)
			{
				NSString *t = [s attributedStringToASCIIFormatting:&s lineType:type channel:targetChannelName hostmask:self.cachedLocalHostmask];

				for (__strong NSString *channelName in targets) {
					BOOL opPrefix = NO;

					if ([channelName hasPrefix:@"@"]) {
						opPrefix = YES;

						channelName = [channelName substringFromIndex:1];
					}

					IRCChannel *channel = [self findChannel:channelName];

					if (channel == nil && secretMsg == NO) {
						if ([channelName isChannelName:self] == NO) {
							channel = [worldController() createPrivateMessage:channelName client:self];
						}
					}

					if (channel) {
                        BOOL encrypted = (doNotEncrypt == NO && [self isSupportedMessageEncryptionFormat:t channel:channel]);

						[self print:channel
							   type:type
						   nickname:[self localNickname]
						messageBody:t
						isEncrypted:encrypted
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
						[mainWindow() select:channel];
					}
				}
			}

			break;
		}
		case 5054: // Command: PART
		case 5036: // Command: LEAVE
		{
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelName:self] == NO) {
				targetChannelName = [selChannel name];
			} else if (selChannel && [selChannel isPrivateMessage] && [uncutInput isChannelName:self] == NO) {
				[worldController() destroyChannel:selChannel];

				return;
			} else {
				NSObjectIsEmptyAssert(uncutInput);
				
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *reason = [s trimmedString];

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
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelName:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
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
			NSString *nickname1 = [s getTokenAsString];
			NSString *nickname2 = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname1)) {
				if (selChannel.isPrivateMessage) {
					nickname1 = [selChannel name];
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
			if (selChannel && [selChannel isPrivateMessage]) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSString *subCommand = [s uppercaseGetToken];

			NSObjectIsEmptyAssert(subCommand);
			NSObjectIsEmptyAssert(targetChannelName);

			if ([subCommand isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
				[self sendCTCPPing:targetChannelName];
			} else {
				[self sendCTCPQuery:targetChannelName command:subCommand text:[s string]];
			}

			break;
		}
		case 5015: // Command: CTCPREPLY
		{
			if (selChannel && [selChannel isPrivateMessage]) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}
			
			NSString *subCommand = [s uppercaseGetToken];
			
			NSObjectIsEmptyAssert(subCommand);
			NSObjectIsEmptyAssert(targetChannelName);

			[self sendCTCPReply:targetChannelName command:subCommand text:[s string]];
			
			break;
		}
		case 5005: // Command: BAN
		case 5072: // Command: UNBAN
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelName:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *banmask = [s getTokenAsString];
			
			NSObjectIsEmptyAssert(banmask);

			IRCChannel *channel = [self findChannel:targetChannelName];

			if (channel) {
				IRCUser *user = [channel findMember:banmask];

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
				
				lowercaseCommand = [uppercaseCommand lowercaseString];
			}
			
			BOOL isModeCommand = [uppercaseCommand isEqualToString:IRCPublicCommandIndex("mode")];
			
			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("halfop")] ||
				[uppercaseCommand isEqualToString:IRCPublicCommandIndex("dehalfop")])
			{
				/* Do not try mode changes when they are not supported. */
				BOOL modeHSupported = [[self supportInfo] modeIsSupportedUserPrefix:@"h"];

				if (modeHSupported == NO) {
					[self printDebugInformation:BLS(1042)];

					return;
				}
			}

			if (isModeCommand) {
				if (selChannel && [selChannel isChannel] && [[s string] isModeChannelName] == NO) {
					targetChannelName = [selChannel name];
				} else if (([[s string] hasPrefix:@"+"] || [[s string] hasPrefix:@"-"]) == NO) {
					targetChannelName = [s getTokenAsString];
				}
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("umode")]) {
				[s insertAttributedString:[NSAttributedString emptyStringWithBase:NSStringWhitespacePlaceholder]	atIndex:0];
				[s insertAttributedString:[NSAttributedString emptyStringWithBase:[self localNickname]]				atIndex:0];
			} else {
				if (selChannel && [selChannel isChannel] && [[s string] isModeChannelName] == NO) {
					targetChannelName = [selChannel name];
				} else {
					targetChannelName = [s getTokenAsString];
				}

				NSString *sign;

				if ([uppercaseCommand hasPrefix:@"DE"] || [uppercaseCommand hasPrefix:@"UN"]) {
					sign = @"-";

					uppercaseCommand = [uppercaseCommand substringFromIndex:2];
					
					lowercaseCommand = [uppercaseCommand lowercaseString];
				} else {
					sign = @"+";
				}

				NSArray *params = [[s string] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

				NSObjectIsEmptyAssert(params);
				
				NSMutableString *ms = [NSMutableString stringWithString:sign];

				NSString *modeCharStr = [lowercaseCommand substringToIndex:1];

				for (NSInteger i = ([params count] - 1); i >= 0; --i) {
					[ms appendString:modeCharStr];
				}

				[ms appendString:NSStringWhitespacePlaceholder];
				[ms appendString:[s string]];

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
				[line appendString:[s string]];
			} else {
				if (isModeCommand) {
					/* If we have a /mode command and nothing other than a destination
					 channel, then we set flag so when we return channel modes, they
					 are handled properly. */
					
					if ([targetChannelName isChannelName:self]) {
						self.inUserInvokedModeRequest = YES;
					}
				}
			}

			[self sendLine:line];

			break;
		}
		case 5010: // Command: CLEAR
		{
			if (selChannel) {
				[worldController() clearContentsOfChannel:selChannel inClient:self];
			} else if (u) {
				[worldController() clearContentsOfClient:u];
			}

			break;
		}
		case 5012: // Command: CLOSE
		case 5061: // Command: REMOVE
		{
			if (selChannel && NSObjectIsEmpty(uncutInput)) {
				[worldController() destroyChannel:selChannel];
			} else {
				NSString *channel = [s getTokenAsString];
				
				IRCChannel *oc = [self findChannel:channel];

				if (oc) {
					[worldController() destroyChannel:oc];
				}
			}

			break;
		}
		case 5060: // Command: REJOIN
		case 5016: // Command: CYCLE
		case 5027: // Command: HOP
		{
			if (selChannel && [selChannel isChannel]) {
				NSString *password = nil;

				if ([[c modeInfo] modeIsDefined:@"k"]) {
					password = [[[c modeInfo] modeInfoFor:@"k"] modeParamater];
				}

				[self partChannel:c];
				
				[self forceJoinChannel:[c name] password:password];
			}

			break;
		}
		case 5029: // Command: IGNORE
		case 5073: // Command: UNIGNORE
		{
#warning Add back way to skip dialog.
			BOOL isIgnoreCommand = [uppercaseCommand isEqualToString:IRCPublicCommandIndex("ignore")];

			if (isIgnoreCommand) {
				NSString *nickname = [s getTokenAsString];

				if (NSObjectIsNotEmpty(nickname) || PointerIsEmpty(selChannel)) {
					[menuController() showServerPropertyDialog:self withDefaultView:TDCServerSheetNewIgnoreEntryNavigationSelection	andContext:nickname];
				} else {
					[menuController() showServerPropertyDialog:self withDefaultView:TDCServerSheetNewIgnoreEntryNavigationSelection	andContext:@"--"];
				}
			} else {
				[menuController() showServerPropertyDialog:self withDefaultView:TDCServerSheetAddressBookNavigationSelection andContext:nil];
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

			for (IRCClient *client in [worldController() clientList]) {
				[client sendLine:uncutInput];
			}

			break;
		}
		case 5056: // Command: QUERY
		{
			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsNotEmpty(nickname)) {
				if ([nickname isChannelName:self] == NO && [nickname isNickname]) {
					IRCChannel *channel = [self findChannelOrCreate:nickname isPrivateMessage:YES];

					[mainWindow() select:channel];
				}
			}

			break;
		}
		case 5069: // Command: TIMER
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSInteger interval = [[s getTokenAsString] integerValue];

			NSObjectIsEmptyAssert(s);

			if (interval > 0) {
				TLOTimerCommand *cmd = [TLOTimerCommand new];

				if ([[s string] hasPrefix:@"/"]) {
					[s deleteCharactersInRange:NSMakeRange(0, 1)];
				}

				if (selChannel) {
					[cmd setChannelID:[selChannel treeUUID]];
				} else {
					[cmd setChannelID:nil];
				}
				
				[cmd setRawInput:[s string]];
				
				[cmd setTimerInterval:([NSDate epochTime] + interval)];

				[self addCommandToCommandQueue:cmd];
			} else {
				[self printDebugInformation:BLS(1173)];
			}

			break;
		}
		case 5022: // Command: ECHO
		case 5018: // Command: DEBUG
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			if ([uncutInput isEqualIgnoringCase:@"raw on"]) {
				self.rawModeEnabled = YES;

				[self printDebugInformation:BLS(1175)];

				LogToConsole(@"%@", BLS(1177));
			} else if ([uncutInput isEqualIgnoringCase:@"raw off"]) {
				self.rawModeEnabled = NO;

				[self printDebugInformation:BLS(1174)];

				LogToConsole(@"%@", BLS(1176));
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
				[worldController() clearContentsOfClient:self];

				@synchronized(self.channels) {
					for (IRCChannel *channel in self.channels) {
						[worldController() clearContentsOfChannel:channel inClient:self];
					}
				}

				[worldController() markAllAsRead:self];
			} else {
				[worldController() destroyAllEvidence];
			}

			break;
		}
		case 5003: // Command: AMSG
		{
			NSObjectIsEmptyAssert(uncutInput);

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *client in [worldController() clientList]) {
                    if ([client isConnected]) {
                        for (IRCChannel *channel in [client channelList]) {
                            if ([channel isActive]) {
                                [client setUnreadState:channel];
								
                                [client sendText:s command:IRCPrivateCommandIndex("privmsg") channel:channel];
                            }
                        }
                    }
				}
			} else {
				@synchronized(self.channels) {
					for (IRCChannel *channel in self.channels) {
						[self setUnreadState:channel];
						
						[self sendText:s command:IRCPrivateCommandIndex("privmsg") channel:channel];
					}
				}
			}

			break;
		}
		case 5002: // Command: AME
		{
			NSObjectIsEmptyAssert(uncutInput);

			if ([TPCPreferences amsgAllConnections]) {
				for (IRCClient *client in [worldController() clientList]) {
                    if ([client isConnected]) {
                        for (IRCChannel *channel in [client channelList]) {
                            if ([channel isActive]) {
                                [client setUnreadState:channel];
								
                                [client sendText:s command:IRCPrivateCommandIndex("action") channel:channel];
                            }
                        }
                    }
				}
			} else {
				@synchronized(self.channels) {
					for (IRCChannel *channel in self.channels) {
						[self setUnreadState:channel];
					
						[self sendText:s command:IRCPrivateCommandIndex("action") channel:channel];
					}
				}
			}

			break;
		}
		case 5083: // Command: KB
		case 5034: // Command: KICKBAN
		{
			NSObjectIsEmptyAssert(uncutInput);

			if (selChannel && [selChannel isChannel] && [uncutInput isChannelName:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelName:self]);

			NSString *nickname = [s getTokenAsString];
			
			NSString *banmask = nickname;

			NSObjectIsEmptyAssert(banmask);

			IRCChannel *channel = [self findChannel:targetChannelName];

			if (channel) {
				IRCUser *user = [channel findMember:banmask];

				if (user) {
					nickname = [user nickname];
					
					banmask = [user banMask];
				}
			}
			
			NSString *reason = [s getTokenAsString];
			
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
			
			NSArray *data = [[s string] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

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
			if (NSObjectIsNotEmpty(uncutInput)) {
				self.serverRedirectAddressTemporaryStore = [s getTokenAsString];
			}
			
			if (self.isConnected) {
				[self quit];
			}

			if (self.isQuitting) {
				[self performSelector:@selector(connect) withObject:nil afterDelay:2.0];
			} else {
				[self connect];
			}

			break;
		}
		case 5046: // Command: MYVERSION
		{
			NSString *gref = [TPCApplicationInfo gitBuildReference];
			NSString *name = [TPCApplicationInfo applicationName];
			NSString *vers = [TPCApplicationInfo applicationInfoPlist][@"CFBundleVersion"];
			NSString *code = [TPCApplicationInfo applicationInfoPlist][@"TXBundleBuildCodeName"];
			NSString *ccnt = [TPCApplicationInfo gitCommitCount];

			if (NSObjectIsEmpty(gref)) {
				gref = BLS(1218);
			}

			NSString *text;
			
			if ([uncutInput isEqualIgnoringCase:@"-d"]) {
				text = BLS(1113, name, vers, gref, code);
			} else {
				text = BLS(1112, name, vers, ccnt);
			}

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:text];
			} else {
				text = BLS(1114, text);

				[self sendPrivmsg:text toChannel:selChannel];
			}

			break;
		}
		case 5044: // Command: MUTE
		{
			if ([sharedGrowlController() areNotificationSoundsDisabled]) {
				[self printDebugInformation:BLS(1220)];
			} else {
				[self printDebugInformation:BLS(1223)];

				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOffState];
			}

			break;
		}
		case 5075: // Command: UNMUTE
		{
			if ([sharedGrowlController() areNotificationSoundsDisabled]) {
				[self printDebugInformation:BLS(1221)];

				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOnState];
			} else {
				[self printDebugInformation:BLS(1222)];
			}

			break;
		}
		case 5093: // Command: TAGE
		{
			/* Textual Age — Developr mode only. */

			NSTimeInterval timeDiff = [NSDate secondsSinceUnixTimestamp:TXBirthdayReferenceDate];

			NSString *message = BLS(1226, TXHumanReadableTimeInterval(timeDiff, NO, 0));

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:message];
			} else {
				[self sendPrivmsg:message toChannel:selChannel];
			}
			
			break;
		}
		case 5091: // Command: LOADED_PLUGINS
		{
			NSArray *loadedBundles = [sharedPluginManager() allLoadedExtensions];
			NSArray *loadedScripts = [sharedPluginManager() supportedAppleScriptCommands];

			NSString *bundleResult = [loadedBundles componentsJoinedByString:@", "];
			NSString *scriptResult = [loadedScripts componentsJoinedByString:@", "];

			if (NSObjectIsEmpty(bundleResult)) {
				bundleResult = BLS(1105);
			}

			if (NSObjectIsEmpty(scriptResult)) {
				scriptResult = BLS(1105);
			}

			[self printDebugInformation:BLS(1103, bundleResult)];
			[self printDebugInformation:BLS(1104, scriptResult)];

			break;
		}
		case 5084: // Command: LAGCHECK
		case 5045: // Command: MYLAG
		{
			self.lastLagCheck = [NSDate epochTime];

			if ([uppercaseCommand isEqualIgnoringCase:IRCPublicCommandIndex("mylag")]) {
				self.lagCheckDestinationChannel = [mainWindow() selectedChannelOn:self];
			}

			[self sendCTCPQuery:[self localNickname] command:IRCPrivateCommandIndex("ctcp_lagcheck") text:[NSString stringWithDouble:self.lastLagCheck]];

			[self printDebugInformation:BLS(1107)];

			break;
		}
		case 5082: // Command: ZLINE
		case 5023: // Command: GLINE
		case 5025: // Command: GZLINE
		{
			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname)) {
				[self send:uppercaseCommand, [s string], nil];
			} else {
				if ([nickname hasPrefix:@"-"]) {
					[self send:uppercaseCommand, nickname, [s string], nil];
				} else {
					NSString *gltime = [s getTokenAsString];
					NSString *reason = [s trimmedString];

					if (NSObjectIsEmpty(reason)) {
						reason = [TPCPreferences IRCopDefaultGlineMessage];

						/* Remove the time from our default reason. */
						if ([reason contains:NSStringWhitespacePlaceholder]) {
							NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

							if (NSObjectIsEmpty(gltime)) {
								gltime = [reason substringToIndex:spacePos];
							}

							reason = [reason substringAfterIndex:spacePos];
						}
					}

					[self send:uppercaseCommand, nickname, gltime, reason, nil];
				}
			}

			break;
		}
		case 5063:  // Command: SHUN
		case 5068: // Command: TEMPSHUN
		{
			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname)) {
				[self send:uppercaseCommand, [s string], nil];
			} else {
				if ([nickname hasPrefix:@"-"]) {
					[self send:uppercaseCommand, nickname, [s string], nil];
				} else {
					if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("tempshun")]) {
						NSString *reason = [s getTokenAsString];

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
						NSString *shtime = [s getTokenAsString];
						NSString *reason = [s trimmedString];

						if (NSObjectIsEmpty(reason)) {
							reason = [TPCPreferences IRCopDefaultShunMessage];

							/* Remove the time from our default reason. */
							if ([reason contains:NSStringWhitespacePlaceholder]) {
								NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

								if (NSObjectIsEmpty(shtime)) {
									shtime = [reason substringToIndex:spacePos];
								}

								reason = [reason substringAfterIndex:spacePos];
							}
						}

						[self send:uppercaseCommand, nickname, shtime, reason, nil];
					}
				}
			}

			break;
		}
		case 5006: // Command: CAP
		case 5007: // Command: CAPS
		{
			NSString *caps = [self enabledCapacitiesStringValue];
			
			if (NSObjectIsNotEmpty(caps)) {
				[self printDebugInformation:BLS(1121, caps)];
			} else {
				[self printDebugInformation:BLS(1120)];
			}

			break;
		}
		case 5008: // Command: CCBADGE
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			NSString *channel = [s getTokenAsString];
			NSString *bacount = [s getTokenAsString];

			NSObjectIsEmptyAssert(bacount);

			NSString *ishl = [s getTokenAsString];

			IRCChannel *oc = [self findChannel:channel];

			PointerIsEmptyAssert(oc);
			
			[oc setTreeUnreadCount:[bacount integerValue]];

			if ([ishl isEqualToString:@"-h"]) {
				[oc setNicknameHighlightCount:1];
			}
			
			[mainWindow() reloadTreeItem:oc];

			break;
		}
		case 5049: // Command: NNCOLORESET
		{
			if (selChannel && [selChannel isChannel]) {
				for (IRCUser *user in [selChannel sortedByChannelRankMemberList]) {
					user.colorNumber = -1;
				}
			}

			break;
		}
		case 5066: // Command: SSLCONTEXT
		{
			if ( self.socket.connectionUsesSSL && self.socket.isConnected) {
				[self.socket openSSLCertificateTrustDialog];
			}
			
			break;
		}
		case 5087: // Command: FAKERAWDATA
		{
			[self ircConnectionDidReceive:[s string]];

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
			
			for (IRCClient *client in [worldController() clientList]) {
				for (IRCChannel *channel in [client channelList]) {
					NSString *name = [[channel name] channelNameTokenByTrimmingAllPrefixes:self];
					
					NSInteger score = [uncutInput compareWithWord:name matchGain:10 missingCost:1];
					
					[results addObject:@{@"score" : @(score), @"item" : channel}];
				}
			}
			
			NSObjectIsEmptyAssertLoopBreak(results);

			[results sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
				return [obj1[@"score"] compare:obj2[@"score"]];
			}];
			
			NSDictionary *topResult = (id)results[0];
			
			[mainWindow() select:topResult[@"item"]];
			
			break;
		}
		case 5092: // Command: DEFAULTS
		{
			/* Check base string. */
			if (NSObjectIsEmpty(uncutInput)) {
				[self printDebugInformation:BLS(1033)];

				return;
			}

			/* Begin processing input. */
			NSString *section1 = [s getTokenAsString];
			
			NSString *section2 = [[s getTokenIncludingQuotes] string];
			NSString *section3 = [[s getTokenIncludingQuotes] string];

			BOOL applyToAll = NSObjectsAreEqual(section2, @"-a");

			NSDictionary *providedKeys = @{
				@"Send Authentication Requests to UserServ"				: @"setHideNetworkUnavailabilityNotices:",
				@"Hide Network Unavailability Notices on Reconnect"		: @"setSaslAuthenticationUsesExternalMechanism:",
				@"SASL Authentication Uses External Mechanism"			: @"setSendAuthenticationRequestsToUserServ:"
			};
			
			void (^applyKey)(IRCClient *, NSString *, BOOL) = ^(IRCClient *client, NSString *valueKey, BOOL valueValue) {
				SEL selectorActl = NSSelectorFromString(providedKeys[valueKey]);
				
				objc_msgSend([client config], selectorActl, valueValue);
			};
				
			if (NSObjectsAreEqual(section1, @"help"))
			{
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][01]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][02]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][03]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][04]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][05]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][06]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][07]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][08]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][09]")];
				[self printDebugInformation:TXTLS(@"BasicLanguage[1034][10]")];
			}
			else if (NSObjectsAreEqual(section1, @"features"))
			{
				[TLOpenLink openWithString:@"http://www.codeux.com/textual/wiki/Command-Reference.wiki?command=defaults"];
			}
			else if (NSObjectsAreEqual(section1, @"enable"))
			{
				if ((applyToAll == NO && NSObjectIsEmpty(section2)) ||
					(applyToAll		  && NSObjectIsEmpty(section3)))
				{
					[self printDebugInformation:BLS(1033)];
				} else {
					if ((applyToAll == NO && [providedKeys containsKey:section2] == NO) ||
						(applyToAll		  && [providedKeys containsKey:section3] == NO))
					{
						if (applyToAll) {
							[self printDebugInformation:BLS(1035, section3)];
						} else {
							[self printDebugInformation:BLS(1035, section2)];
						}
					} else {
						if (applyToAll) {
							for (IRCClient *u in [worldController() clientList]) {
								applyKey(u, section3, YES);

								if (u == self) {
									[u printDebugInformation:BLS(1037, section3)];
								} else {
									[u printDebugInformationToConsole:BLS(1037, section3)];
								}
							}
						} else {
							applyKey(self, section2, YES);

							[self printDebugInformation:BLS(1037, section2)];
						}

						[worldController() save];
					}
				}
			}
			else if (NSObjectsAreEqual(section1, @"disable"))
			{
				if ((applyToAll == NO && NSObjectIsEmpty(section2)) ||
					(applyToAll		  && NSObjectIsEmpty(section3)))
				{
					[self printDebugInformation:BLS(1033)];
				} else {
					if ((applyToAll == NO && [providedKeys containsKey:section2] == NO) ||
						(applyToAll		  && [providedKeys containsKey:section3] == NO))
					{
						if (applyToAll) {
							[self printDebugInformation:BLS(1036, section3)];
						} else {
							[self printDebugInformation:BLS(1036, section2)];
						}
					} else {
						if (applyToAll) {
							for (IRCClient *u in [worldController() clientList]) {
								applyKey(u, section3, NO);

								if (u == self) {
									[u printDebugInformation:BLS(1038, section3)];
								} else {
									[u printDebugInformationToConsole:BLS(1038, section3)];
								}
							}
						} else {
							applyKey(self, section2, NO);

							[self printDebugInformation:BLS(1038, section2)];
						}

						[worldController() save];
					}
				}
			}

			break;
		}
		default:
		{
			/* Scan scripts first. */
			NSDictionary *scriptPaths = [sharedPluginManager() supportedAppleScriptCommands:YES];

			NSString *scriptPath = nil;

			for (NSString *scriptCommand in scriptPaths) {
				if ([scriptCommand isEqualToString:lowercaseCommand]) {
					scriptPath = [scriptPaths objectForKey:lowercaseCommand];
				}
			}

			BOOL scriptFound = NSObjectIsNotEmpty(scriptPath);

			/* Scan plugins second. */
			BOOL pluginFound = [[sharedPluginManager() supportedUserInputCommands] containsObject:lowercaseCommand];

			/* Perform script or plugin. */
			if (pluginFound && scriptFound) {
				LogToConsole(BLS(1193), uppercaseCommand);
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
							@"channel"			: NSStringNilValueSubstitute([selChannel name]),
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
	if ([TPCPreferences logToDiskIsEnabled]) {
		if ( self.logFile) {
			[self.logFile reopenIfNeeded];
		}
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	if ( self.logFile) {
		[self.logFile close];
	}
}

- (void)writeToLogFile:(TVCLogLine *)line
{
	if ([TPCPreferences logToDiskIsEnabled]) {
		if (self.logFile == nil) {
			self.logFile = [TLOFileLogger new];
			
			self.logFile.client = self;
		}

		[self.logFile writeLine:line];
	}
}

- (void)logFileRecordSessionChanges:(BOOL)newSession /* @private */
{
	NSString *langkey = @"BasicLanguage[1178]";

	if (newSession == NO) {
		langkey = @"BasicLanguage[1179]";
	}

	TVCLogLine *top = [TVCLogLine new];
	TVCLogLine *mid = [TVCLogLine new];
	TVCLogLine *end = [TVCLogLine new];

	[mid setMessageBody:TXTLS(langkey)];
	[top setMessageBody:NSStringWhitespacePlaceholder];
	[end setMessageBody:NSStringWhitespacePlaceholder];

	[self writeToLogFile:top];
	[self writeToLogFile:mid];
	[self writeToLogFile:end];
	
	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			[channel writeToLogFile:top];
			[channel writeToLogFile:mid];
			[channel writeToLogFile:end];
		}
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

- (NSString *)formatNickname:(NSString *)nick channel:(IRCChannel *)channel
{
	return [self formatNickname:nick channel:channel formatOverride:nil];
}

- (NSString *)formatNickname:(NSString *)nick channel:(IRCChannel *)channel formatOverride:(NSString *)forcedFormat
{
	/* Validate input. */
	NSObjectIsEmptyAssertReturn(nick, nil);

	PointerIsEmptyAssertReturn(channel, nil);

	/* Define default formats. */
	NSString *nmformat = [TPCPreferences themeNicknameFormat];

	NSString *override = [themeSettings() nicknameFormat];

	/* Use theme based format? */
	if (NSObjectIsNotEmpty(override)) {
		nmformat = override;
	}

	/* Use default format? */
	if (NSObjectIsEmpty(nmformat)) {
		nmformat = TVCLogLineUndefinedNicknameFormat;
	}

	/* Use a forced format? */
	if (NSObjectIsNotEmpty(forcedFormat)) {
		nmformat = forcedFormat;
	}

	/* Find mark character. */
	NSString *mark = NSStringEmptyPlaceholder;

	if (channel && [channel isChannel]) {
		IRCUser *m = [channel findMember:nick];

		if (m) {
			NSString *_mark = [m mark];
			
			if (_mark) {
			 	 mark = _mark;
			}
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

		if (oValue) {
			/* Check math and perform final append. */
			if (width < 0 && ABS(width) > [oValue length]) {
				[buffer appendString:[NSStringEmptyPlaceholder stringByPaddingToLength:(ABS(width) - [oValue length]) withString:@" " startingAtIndex:0]];
			}

			[buffer appendString:oValue];

			if (width > 0 && width > [oValue length]) {
				[buffer appendString:[NSStringEmptyPlaceholder stringByPaddingToLength:(width - [oValue length]) withString:@" " startingAtIndex:0]];
			}
		}
	}

	return [NSString stringWithString:buffer];
}

- (void)printAndLog:(TVCLogLine *)line completionBlock:(IRCClientPrintToWebViewCallbackBlock)completionBlock
{
	[self.viewController print:line completionBlock:completionBlock];
	
	[self writeToLogFile:line];
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text command:(NSString *)command
{
	TEXTUAL_DEPRECATED_ASSERT
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	TEXTUAL_DEPRECATED_ASSERT
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	TEXTUAL_DEPRECATED_ASSERT
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command message:(IRCMessage *)rawMessage
{
	TEXTUAL_DEPRECATED_ASSERT
}

- (void)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command message:(IRCMessage *)rawMessage completionBlock:(IRCClientPrintToWebViewCallbackBlock)completionBlock
{
	TEXTUAL_DEPRECATED_ASSERT
}

- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody command:(NSString *)command
{
	[self printToWebView:chan type:type command:command nickname:nickname messageBody:messageBody isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	[self printToWebView:chan type:type command:command nickname:nickname messageBody:messageBody isEncrypted:NO receivedAt:receivedAt referenceMessage:nil completionBlock:nil];
}

- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody isEncrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command
{
	[self printToWebView:chan type:type command:command nickname:nickname messageBody:messageBody isEncrypted:isEncrypted receivedAt:receivedAt referenceMessage:nil completionBlock:nil];
}

- (void)print:(id)chan type:(TVCLogLineType)type nickname:(NSString *)nickname messageBody:(NSString *)messageBody isEncrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt command:(NSString *)command referenceMessage:(IRCMessage *)referenceMessage
{
	[self printToWebView:chan type:type command:command nickname:nickname messageBody:messageBody isEncrypted:isEncrypted receivedAt:receivedAt referenceMessage:referenceMessage completionBlock:nil];
}

- (void)printToWebView:(id)channel type:(TVCLogLineType)type command:(NSString *)command nickname:(NSString *)nickname messageBody:(NSString *)messageBody isEncrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt referenceMessage:(IRCMessage *)referenceMessage completionBlock:(void (^)(BOOL))completionBlock
{
	NSObjectIsEmptyAssert(messageBody);
	NSObjectIsEmptyAssert(command);
	
	if ([self outputRuleMatchedInMessage:messageBody inChannel:channel withLineType:type] == YES) {
		return;
	}

	IRCChannel *destination = nil;

	TVCLogLineMemberType memberType = TVCLogLineMemberNormalType;

	NSInteger colorNumber = 0;

	NSArray *matchKeywords = nil;
	NSArray *excludeKeywords = nil;

	if (NSObjectsAreEqual(nickname, [self localNickname])) {
		memberType = TVCLogLineMemberLocalUserType;
	}

	if ([channel isKindOfClass:[IRCChannel class]]) {
		destination = channel;
	} else {
		/* We only want chan to be an IRCChannel for an actual
		 channel or nil for the console. Anything else should be
		 ignored and stopped from printing. */

		NSObjectIsNotEmptyAssert(channel);
	}

	if ((type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType) && memberType == TVCLogLineMemberNormalType) {
		if (channel && [[channel config] ignoreHighlights] == NO) {
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

	/* If client is not connected, we set our configured nickname when we have none. */
	if (self.isLoggedIn == NO && NSObjectIsEmpty(nickname)) {
		if (type == TVCLogLinePrivateMessageType ||
			type == TVCLogLineActionType ||
			type == TVCLogLineNoticeType)
		{
			nickname = self.config.nickname;

			memberType = TVCLogLineMemberLocalUserType;
		}
	}

	if (nickname && destination && (type == TVCLogLinePrivateMessageType ||
									type == TVCLogLineActionType))
	{
		IRCUser *user = [channel findMember:nickname];

		if (user) {
			colorNumber = [user colorNumber];
		}
	} else {
		colorNumber = -1;
	}

	/* Create new log entry. */
	TVCLogLine *c = [TVCLogLine new];

	/* Data types. */
	c.lineType				= type;
	c.memberType			= memberType;

	/* Encrypted message? */
	c.isEncrypted           = isEncrypted;

	/* Highlight words. */
	c.excludeKeywords		= excludeKeywords;
	c.highlightKeywords		= matchKeywords;

	/* Message body. */
	c.messageBody			= messageBody;

	/* Sender. */
	c.nickname				= nickname;
	c.nicknameColorNumber	= colorNumber;

	/* Send date. */
	c.receivedAt			= receivedAt;

	/* Actual command. */
	c.rawCommand			= [command lowercaseString];

	if (channel) {
		if ([TPCPreferences autoAddScrollbackMark]) {
			if (NSDissimilarObjects(channel, [mainWindow() selectedChannel]) || [mainWindow() isMainWindow] == NO) {
				if ([destination isUnread] == NO) {
					if (type == TVCLogLinePrivateMessageType ||
						type == TVCLogLineActionType ||
						type == TVCLogLineNoticeType)
					{
						[[destination viewController] mark];
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
	[self printToWebView:nil type:TVCLogLineDebugType command:[m command] nickname:nil messageBody:[m sequence:1] isEncrypted:NO receivedAt:[m receivedAt] referenceMessage:nil completionBlock:nil];
}

- (void)printUnknownReply:(IRCMessage *)m
{
	[self printToWebView:nil type:TVCLogLineDebugType command:[m command] nickname:nil messageBody:[m sequence:1] isEncrypted:NO receivedAt:[m receivedAt] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformation:(NSString *)m
{
	[self printToWebView:[mainWindow() selectedChannelOn:self] type:TVCLogLineDebugType command:TVCLogLineDefaultRawCommandValue nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformation:(NSString *)m forCommand:(NSString *)command
{
	[self printToWebView:[mainWindow() selectedChannelOn:self] type:TVCLogLineDebugType command:command nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[self printToWebView:nil type:TVCLogLineDebugType command:TVCLogLineDefaultRawCommandValue nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformationToConsole:(NSString *)m forCommand:(NSString *)command
{
	[self printToWebView:nil type:TVCLogLineDebugType command:command nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel
{
	[self printToWebView:channel type:TVCLogLineDebugType command:TVCLogLineDefaultRawCommandValue nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel command:(NSString *)command
{
	[self printToWebView:channel type:TVCLogLineDebugType command:command nickname:nil messageBody:m isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

- (void)printErrorReply:(IRCMessage *)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel
{
	NSString *text = BLS(1139, [m numericReply], [m sequence]);

	[self printToWebView:channel type:TVCLogLineDebugType command:[m command] nickname:nil messageBody:text isEncrypted:NO receivedAt:[m receivedAt] referenceMessage:nil completionBlock:nil];
}

- (void)printError:(NSString *)error forCommand:(NSString *)command
{
	[self printToWebView:nil type:TVCLogLineDebugType command:command nickname:nil messageBody:error isEncrypted:NO receivedAt:[NSDate date] referenceMessage:nil completionBlock:nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)resetAllPropertyValues
{
	self.inUserInvokedNamesRequest = NO;
	self.inUserInvokedWatchRequest = NO;
	self.inUserInvokedWhoRequest = NO;
	self.inUserInvokedWhowasRequest = NO;
	self.inUserInvokedModeRequest = NO;
	self.inUserInvokedJoinRequest = NO;
	self.inUserInvokedWatchRequest = NO;
	
	self.isAutojoined = NO;
	self.isAway = NO;
	self.isConnected = NO;
	self.isConnecting = NO;
	self.isIdentifiedWithNickServ = NO;
	self.isInvokingISONCommandForFirstTime = NO;
	self.isLoggedIn = NO;
	self.isQuitting = NO;
	self.isWaitingForNickServ = NO;
	self.isZNCBouncerConnection = NO;
	
	self.autojoinInProgress = NO;
	self.rawModeEnabled = NO;
	self.reconnectEnabled = NO;
	self.serverHasNickServ = NO;
	self.timeoutWarningShownToUser = NO;
	
	self.lagCheckDestinationChannel = nil;
	
	self.lastLagCheck = 0;
	
	self.cachedLocalHostmask = nil;
	self.cachedLocalNickname = self.config.nickname;
	
	self.tryingNicknameSentNickname = self.config.nickname;
	self.tryingNicknameNumber = -1;
	
	self.preAwayNickname = nil;
	
	self.lastMessageReceived = 0;
	
	self.CAPPausedStatus = 0;
	
	self.capacitiesPending = 0;
	self.capacities = 0;

	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}
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

	[self.printingQueue cancelAllOperations];

#ifdef TEXTUAL_TRIAL_BINARY
	[self stopTrialPeriodTimer];
#endif

	if (self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	[self.supportInfo reset];

	static NSDictionary *disconnectMessages = nil;
	
	if (disconnectMessages == nil) {
		disconnectMessages = @{
			@(IRCClientDisconnectNormalMode) :				@(1136),
			@(IRCClientDisconnectComputerSleepMode) :		@(1131),
			@(IRCClientDisconnectTrialPeriodMode) :			@(1134),
			@(IRCClientDisconnectBadSSLCertificateMode) :	@(1133),
			@(IRCClientDisconnectServerRedirectMode) :		@(1132),
			@(IRCClientDisconnectReachabilityChangeMode) :	@(1135)
		};
	}
	
	NSNumber *disconnectMessage = [disconnectMessages objectForKey:@(self.disconnectType)];

	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c isActive]) {
				[c deactivate];

				[self printDebugInformation:BLS([disconnectMessage integerValue]) channel:c];
			}
		}
	}

	[self.viewController mark];
	
	[self printDebugInformationToConsole:BLS([disconnectMessage integerValue])];

	if (self.isConnected) {
		[self notifyEvent:TXNotificationDisconnectType lineType:TVCLogLineDebugType];
	}

	[self logFileWriteSessionEnd];
	
	[self resetAllPropertyValues];

	[mainWindow() reloadTreeGroup:self];
}

- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	[self startRetryTimer];

	/* If the address we are connecting to is not an IP address,
	 then we report back the actual IP address it was resolved to. */
	if ([self.socket.serverAddress isIPAddress]) {
		[self printDebugInformationToConsole:BLS(1129)];
	} else {
		[self printDebugInformationToConsole:BLS(1130, [self.socket connectedAddress])];
	}

	self.isLoggedIn	= NO;
	self.isConnected = YES;
	self.reconnectEnabled = YES;

	self.cachedLocalNickname = self.config.nickname;
	
	self.tryingNicknameSentNickname = self.config.nickname;

	[self.supportInfo reset];

	NSString *username = self.config.username;
	NSString *realname = self.config.realname;
	
	NSString *modeParam = @"0";

	if (self.config.invisibleMode) {
		modeParam = @"8";
	}

	if (NSObjectIsEmpty(username)) {
		username = self.config.nickname;
	}

	if (NSObjectIsEmpty(realname)) {
		realname = self.config.nickname;
	}

	[self send:IRCPrivateCommandIndex("cap"), @"LS", nil];

	if (self.config.serverPasswordIsSet) {
		[self send:IRCPrivateCommandIndex("pass"), self.config.serverPassword, nil];
	}

	[self send:IRCPrivateCommandIndex("nick"), self.tryingNicknameSentNickname, nil];
	[self send:IRCPrivateCommandIndex("user"), username, modeParam, @"*", realname, nil];

	[mainWindow() reloadTreeGroup:self];
}

#pragma mark -

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender withError:(NSError *)distcError;
{
	[self disconnect];

	if (self.disconnectType == IRCClientDisconnectBadSSLCertificateMode) {
		[self presentSSLCertificateTrustPanelWithError:distcError];
	}
}

- (void)presentSSLCertificateTrustPanelWithError:(NSError *)distcError
{
	[self cancelReconnect];

	if (distcError) {
		SecTrustRef trustRef = (__bridge SecTrustRef)([[distcError userInfo] objectForKey:@"peerCertificateTrustRef"]);

		if (trustRef) {
			TVCQueuedCertificateTrustPanel *panel = [TXSharedApplication sharedQueuedCertificateTrustPanel];

			[panel enqueue:trustRef withCompletionBlock:^(BOOL isTrusted) {
				if (isTrusted) {
					[self connect:IRCClientConnectBadSSLCertificateMode];
				}
			}];
		}
	}
}

#pragma mark -

- (void)ircConnectionDidError:(NSString *)error
{
	[self printError:error forCommand:TVCLogLineDefaultRawCommandValue];
}

- (void)ircConnectionDidReceive:(NSString *)data
{
	if ([masterController() applicationIsTerminating]) {
		return;
	}
	
	NSString *s = data;

	self.lastMessageReceived = [NSDate epochTime];

	NSObjectIsEmptyAssert(s);

	worldController().messagesReceived += 1;
	worldController().bandwidthIn += [s length];

	[self logToConsoleIncomingTraffic:s];

	if ([TPCPreferences removeAllFormatting]) {
		s = [s stripIRCEffects];
	}

	IRCMessage *m = [IRCMessage new];

	[m parseLine:s forClient:self];

    /* Intercept input. */
    m = [sharedPluginManager() processInterceptedServerInput:m for:self];

    PointerIsEmptyAssert(m);

	/* Keep track of the server time of the last seen message. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityServerTime]) {
		if ([m isHistoric]) {
			NSTimeInterval serverTime = [[m receivedAt] timeIntervalSince1970];

			if (serverTime > [self lastMessageServerTimeWithCachedValue]) {
				/* If znc playback module is in use, then all messages are
				 set as historic so we set any lines above our current reference
				 date as not historic to avoid collisions. */
				if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
					[m setIsHistoric:NO];
				}

				/* Update last server time flag. */
				self.lastMessageServerTime = serverTime;
			}
		}
	}

	if ([m numericReply] > 0) {
		[self receiveNumericReply:m];
	} else {
		NSInteger switchNumeric = [IRCCommandIndex indexOfIRCommand:[m command] publicSearch:NO];

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
			{;
				NSMutableArray *params = [NSMutableArray arrayWithArray:[m params]];

				[params insertObject:[self localNickname] atIndex:0];

				NSString *text = [params objectAtIndex:1];

				[params removeObjectAtIndex:1];
				
				[params insertObject:[NSString stringWithFormat:TVCLogLineSpecialNoticeMessageFormat, [m command], text]  atIndex:1];
				
				[m setParams:params];
				
				[m setCommand:IRCPrivateCommandIndex("notice")];

				[self receivePrivmsgAndNotice:m];

				break;
			}
			case 1005: // Command: AUTHENTICATE
			case 1004: // Command: CAP
			{
				if (self.isZNCBouncerConnection == NO) {
					/* ZNC sends CAPs using its own server hostmask so we will use that to detect 
					 if the connection is ZNC based. */

					if ([@"irc.znc.in" isEqualToString:[m senderNickname]] && [m senderIsServer]) {
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
		LogToConsole(@"OUTGOING [\"%@\"]: << %@", [self altNetworkName], line);
	}
}

- (void)logToConsoleIncomingTraffic:(NSString *)line
{
	if (self.rawModeEnabled) {
		LogToConsole(@"INCOMING [\"%@\"]: >> %@", [self altNetworkName], line);
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
	NSAssertReturn([m paramsCount] > 1);
	
	NSString *text = [m paramAt:1];

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIdentifyCTCP] && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		text = [text substringFromIndex:1];
	} else if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIdentifyMsg] && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
		text = [text substringFromIndex:1];
	}

	if ([text hasPrefix:@"\x01"]) {
		text = [text substringFromIndex:1];

		NSInteger n = [text stringPosition:@"\x01"];

		if (n >= 0) {
			text = [text substringToIndex:n];
		}

		if ([[m command] isEqualToString:IRCPrivateCommandIndex("privmsg")]) {
			if ([text hasPrefixIgnoringCase:@"ACTION "]) {
				text = [text substringFromIndex:7];

				[self receiveText:m command:IRCPrivateCommandIndex("action") text:text];
			} else {
				[self receiveCTCPQuery:m text:text];
			}
		} else {
			[self receiveCTCPReply:m text:text];
		}
	} else {
		[self receiveText:m command:[m command] text:text];
	}
}

- (void)receiveText:(IRCMessage *)m command:(NSString *)command text:(NSString *)text
{
	NSAssertReturn([m paramsCount] > 0);

	NSObjectIsEmptyAssert(command);
	
	/* Message type. */
	TVCLogLineType type = TVCLogLinePrivateMessageType;
	
	if ([command isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([command isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	}

	/* Basic validation. */
	if (type == TVCLogLineActionType) {
		if (NSObjectIsEmpty(text)) {
			/* Use a single space if an action is empty. */
			
			text = NSStringWhitespacePlaceholder;
		}
	} else {
		/* Allow in actions without a body. */
		
		NSObjectIsEmptyAssert(text);
	}
	
	/* Beginw ork. */
	NSString *sender = [m senderNickname];

	NSString *target = [m paramAt:0];

	BOOL isEncrypted = NO;

	/* Operator message? */
	if ([target hasPrefix:@"@"]) {
		target = [target substringFromIndex:1];
	}

	/* Ignore dictionary. */
	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
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
			   nickname:sender
			messageBody:text
			isEncrypted:isEncrypted
			 receivedAt:[m receivedAt]
				command:[m command]
	   referenceMessage:m];

			if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
				[self notifyText:TXNotificationChannelNoticeType lineType:type target:c nickname:sender text:text];
			}
		} else {
			/* Post regular message and inform Growl. */
			
			[self printToWebView:c
							type:type
						 command:[m command]
						nickname:sender
					 messageBody:text
					 isEncrypted:isEncrypted
					  receivedAt:[m receivedAt]
				referenceMessage:m
				 completionBlock:^(BOOL isHighlight)
				{
					 if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
						 BOOL postevent = NO;
						 
						 if (isHighlight) {
							 postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nickname:sender text:text];
							 
							 if (postevent) {
								 [self setKeywordState:c];
							 }
						 } else {
							 postevent = [self notifyText:TXNotificationChannelMessageType lineType:type target:c nickname:sender text:text];
						 }
						 
						 /* Mark channel as unread. */
						 if (postevent) {
							 [self setUnreadState:c isHighlight:isHighlight];
						 }
					 } else {
						 if (isHighlight) {
							 [self setKeywordState:c];
						 }
						 
						 [self setUnreadState:c isHighlight:isHighlight];
					 }
				 }];

			/* Weights. */
			IRCUser *owner = [c findMember:sender];

			PointerIsEmptyAssert(owner);

			NSString *trimmedMyNick = [[self localNickname] trimCharacters:@"_"]; // Remove any underscores from around nickname. (Guest___ becomes Guest)

			/* If we are mentioned in this piece of text, then update our weight for the user. */
			if ([text stringPositionIgnoringCase:trimmedMyNick] > -1) {
				[owner outgoingConversation];
			} else {
				[owner conversation];
			}
		}
	}
	else // The target is not a channel.
	{
		/* Is the sender a server? */
		if ([m senderIsServer]) {
			[self print:nil type:type nickname:nil messageBody:text receivedAt:[m receivedAt] command:[m command]];
		} else {
			/* Ignore message? */
			if ([ignoreChecks ignoreNotices] && type == TVCLogLineNoticeType) {
				return;
			} else if ([ignoreChecks ignorePrivateMessages]) {
				return;
			}

			/* Detect privmsg module messages */
			BOOL isZNCprivmsg = NO;

			if (self.isZNCBouncerConnection == YES) {
				if ([sender isEqualToString:[self localNickname]]) {
					isZNCprivmsg = YES;
				}
			}

			/* Does the query for the sender already exist?… */
			IRCChannel *c;

			if (isZNCprivmsg == YES) {
				c = [self findChannel:target];
			} else {
				c = [self findChannel:sender];
			}

			BOOL newPrivateMessage = NO;

			if (c == nil && NSDissimilarObjects(type, TVCLogLineNoticeType)) {
				if (isZNCprivmsg) {
					c = [worldController() createPrivateMessage:target client:self];
				} else {
					c = [worldController() createPrivateMessage:sender client:self];
				}

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
					c = [mainWindow() selectedChannelOn:self];
				}

				if ([sender isEqualIgnoringCase:@"ChanServ"]) {
					/* Forward entry messages to the channel they are associated with. */
					/* Format we are going for: -ChanServ- [#channelname] blah blah… */
					NSInteger spacePos = [text stringPosition:NSStringWhitespacePlaceholder];

					if ([text hasPrefix:@"["] && spacePos > 3) {
						NSString *textHead = [text substringToIndex:spacePos];

						if ([textHead hasSuffix:@"]"]) {
							textHead = [textHead substringToIndex:([textHead length] - 1)]; // Remove the ]
							textHead = [textHead substringFromIndex:1]; // Remove the [

							if ([textHead isChannelName:self]) {
								IRCChannel *thisChannel = [self findChannel:textHead];

								if (thisChannel) {
									text = [text substringFromIndex:([textHead length] + 2)]; // Remove the [#channelname] from the text.'

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
								
								/* Accessing nickname password is very slow because it has to access the
								 keychain on the disk so set it as a single variable then define the actual
								 identification message its formatted into later on. */
								NSString *password = self.config.nicknamePassword;
								
								if ([self.networkAddress hasSuffix:@"dal.net"])
								{
									NSString *IDMessage = [NSString stringWithFormat:@"IDENTIFY %@", password];
									
									[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ@services.dal.net", IDMessage, nil];
								}
								else if (self.config.sendAuthenticationRequestsToUserServ)
								{
									NSString *IDMessage = [NSString stringWithFormat:@"login %@ %@", self.config.nickname, self.config.nicknamePassword];
									
									[self send:IRCPrivateCommandIndex("privmsg"), @"userserv", IDMessage, nil];
								}
								else
								{
									NSString *IDMessage = [NSString stringWithFormat:@"IDENTIFY %@", password];
									
									[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ", IDMessage, nil];
								}
								
								self.isWaitingForNickServ = YES;
								
								password = nil;
								
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
				[self printToWebView:c
								type:type
							 command:[m command]
							nickname:sender
						 messageBody:text
						 isEncrypted:isEncrypted
						  receivedAt:[m receivedAt]
					referenceMessage:m
					 completionBlock:^(BOOL isHighlight)
					{
						 /* Set the query as unread and inform Growl. */
						 [self setUnreadState:c];
						 
						 if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
							 if (isZNCprivmsg == NO) {
								 [self notifyText:TXNotificationPrivateNoticeType lineType:type target:c nickname:sender text:text];
							 }
						 }
					 }];
			} else {
				/* Post regular message and inform Growl. */
				[self printToWebView:c
								type:type
							 command:[m command]
							nickname:sender
						 messageBody:text
						 isEncrypted:isEncrypted
						  receivedAt:[m receivedAt]
					referenceMessage:m
					 completionBlock:^(BOOL isHighlight)
					{
					 if ([self isSafeToPostNotificationForMessage:m inChannel:c]) {
						 if (isZNCprivmsg == NO) {
							 BOOL postevent = NO;
							 
							 if (isHighlight) {
								 postevent = [self notifyText:TXNotificationHighlightType lineType:type target:c nickname:sender text:text];
								 
								 if (postevent) {
									 [self setKeywordState:c];
								 }
							 } else {
								 if (newPrivateMessage) {
									 postevent = [self notifyText:TXNotificationNewPrivateMessageType lineType:type target:c nickname:sender text:text];
								 } else {
									 postevent = [self notifyText:TXNotificationPrivateMessageType lineType:type target:c nickname:sender text:text];
								 }
							 }
							 
							 /* Mark query as unread. */
							 if (postevent) {
								 [self setUnreadState:c isHighlight:isHighlight];
							 }
						 } else {
							 if (isHighlight) {
								 [self setKeywordState:c];
							 }
							 
							 [self setUnreadState:c isHighlight:isHighlight];
						 }
					 }
				}];

				/* Set the query topic to the host of the sender. */
				/* Internally this is how Textual sets the title of the window. 
				 It is kind of hackish, but it's really not that bad. */
				NSString *hostTopic = [m senderHostmask];

				if ([hostTopic isEqualIgnoringCase:[c topic]] == NO) {
					[c setTopic:hostTopic];

                    [mainWindow() updateTitleFor:c];
				}

				/* Update query status. */
				if ([c isActive] == NO) {
					[c activate];

					[mainWindow() reloadTreeItem:c];
				}
			}
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSObjectIsEmptyAssert(text);

	NSMutableString *s = [text mutableCopy];

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[@"ignoreCTCP",
																		   @"ignoreFileTransferRequests"]];

	NSAssertReturn([ignoreChecks ignoreCTCP] == NO);
	
	NSString *sendern = [m senderNickname];
	
	NSString *command = [s uppercaseGetToken];
	
	NSObjectIsEmptyAssert(command);

	if ([TPCPreferences replyToCTCPRequests] == NO) {
		return [self printDebugInformationToConsole:BLS(1116, command, sendern)];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("dcc")]) {
		[self receivedDCCQuery:m message:s ignoreInfo:ignoreChecks];
		
		return; // Above method does all the work.
	} else {
		IRCChannel *target = nil;

		if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
			target = [mainWindow() selectedChannelOn:self];
		}

		NSString *textm = BLS(1148, command, sendern);

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")] == NO) {
			[self print:target
				   type:TVCLogLineCTCPType
			   nickname:nil
			messageBody:textm
			 receivedAt:[m receivedAt]
				command:[m command]];
		}

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
			NSAssertReturn([s length] < 50);

			[self sendCTCPReply:sendern command:command text:s];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_time")]) {
			textm = [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]];
			
			[self sendCTCPReply:sendern command:command text:textm];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_cap")]) {
			if ([s isEqualIgnoringCase:@"LS"]) {
				[self sendCTCPReply:sendern command:command text:BLS(1117)];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")] ||
				   [command isEqualToString:IRCPrivateCommandIndex("ctcp_version")])
		{
			NSString *fakever = [TPCPreferences masqueradeCTCPVersion];

			if (NSObjectIsNotEmpty(fakever)) {
				[self sendCTCPReply:sendern command:command text:fakever];
			} else {
				NSString *name = [TPCApplicationInfo applicationName];
				NSString *vers = [TPCApplicationInfo applicationInfoPlist][@"CFBundleVersion"];
				NSString *code = [TPCApplicationInfo applicationInfoPlist][@"TXBundleBuildCodeName"];

				NSString *textoc = BLS(1111, name, vers, code);

				[self sendCTCPReply:sendern command:command text:textoc];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_finger")]) {
			[self sendCTCPReply:sendern command:command text:BLS(1119)];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_clientinfo")]) {
			[self sendCTCPReply:sendern command:command text:BLS(1118)];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")]) {
			double time = [NSDate epochTime];

			if (time > self.lastLagCheck && self.lastLagCheck > 0 && [sendern isEqualIgnoringCase:[self localNickname]]) {
				double delta = (time -		self.lastLagCheck);

				NSString *rating;

					   if (delta < 0.01) {						rating = TXTLS(@"BasicLanguage[1109][00]");
				} else if (delta >= 0.01 && delta < 0.1) {		rating = TXTLS(@"BasicLanguage[1109][01]");
				} else if (delta >= 0.1 && delta < 0.2) {		rating = TXTLS(@"BasicLanguage[1109][02]");
				} else if (delta >= 0.2 && delta < 0.5) {		rating = TXTLS(@"BasicLanguage[1109][03]");
				} else if (delta >= 0.5 && delta < 1.0) {		rating = TXTLS(@"BasicLanguage[1109][04]");
				} else if (delta >= 1.0 && delta < 2.0) {		rating = TXTLS(@"BasicLanguage[1109][05]");
				} else if (delta >= 2.0 && delta < 5.0) {		rating = TXTLS(@"BasicLanguage[1109][06]");
				} else if (delta >= 5.0 && delta < 10.0) {		rating = TXTLS(@"BasicLanguage[1109][07]");
				} else if (delta >= 10.0 && delta < 30.0) {		rating = TXTLS(@"BasicLanguage[1109][08]");
				} else if (delta >= 30.0) {						rating = TXTLS(@"BasicLanguage[1109][09]"); }

				textm = BLS(1106, [self networkAddress], delta, rating);
			} else {
				textm = BLS(1108);
			}

			if (self.lagCheckDestinationChannel) {
				[self sendPrivmsg:textm toChannel:self.lagCheckDestinationChannel];

				self.lagCheckDestinationChannel = nil;
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

	NSMutableString *s = [text mutableCopy];

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[@"ignoreCTCP"]];

	NSAssertReturn([ignoreChecks ignoreCTCP] == NO);

	NSString *sendern = [m senderNickname];
	
	NSString *command = [s uppercaseGetToken];

	IRCChannel *c = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
		c = [mainWindow() selectedChannelOn:self];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
		double delta = ([NSDate epochTime] - [s doubleValue]);
		
		text = BLS(1146, sendern, command, delta);
	} else {
		text = BLS(1147, sendern, command, s);
	}

	[self print:c
		   type:TVCLogLineCTCPType
	   nickname:nil
	messageBody:text
	 receivedAt:[m receivedAt]
		command:[m command]];
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);
	
	NSString *sendern = [m senderNickname];

	NSString *channel = [m paramAt:0];

	BOOL myself = [sendern isEqualIgnoringCase:[self localNickname]];

	IRCChannel *c = [self findChannelOrCreate:channel];

	if (myself) {
		if ([c status] == IRCChannelStatusJoined) {
			return;
		}

		[c activate];
		
		if (self.autojoinInProgress == NO) {
			if (self.inUserInvokedJoinRequest) {
				[mainWindow() expandClient:self];
				
				[mainWindow() select:c];
			}
		}
		
		[mainWindow() reloadTreeItem:c];

		if (c.config.encryptionKeyIsSet) {
			[self printDebugInformation:BLS(1003) channel:c];
		}
		
		self.cachedLocalHostmask = [m senderHostmask];
		
		self.inUserInvokedJoinRequest = NO;
	}

	if ([m isPrintOnlyMessage] == NO) {
		if ([c memberExists:sendern] == NO) {
			IRCUser *u = [IRCUser newUserOnClient:self withNickname:[m senderNickname]];
			
			[u setUsername:[m senderUsername]];
			[u setAddress:[m senderAddress]];
			
			[c addMember:u];
			
			/* Add to existing query? */
			IRCChannel *query = [self findChannel:sendern];
			
			if (query) {
				if ([query isActive] == NO) {
					[query activate];
					
					[self print:query
						   type:TVCLogLineJoinType
					   nickname:nil
					messageBody:BLS(1155, sendern)
					 receivedAt:[m receivedAt]
						command:[m command]];
					
					[mainWindow() reloadTreeItem:query];
				}
			}
		}
	}

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[@"ignoreJPQE",
																		   @"notifyJoins"]];
	
	if ([m isPrintOnlyMessage] == NO) {
		[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
	}

	if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
		return;
	}

	if ([TPCPreferences showJoinLeave] || myself) {
		NSString *text = BLS(1161, sendern, [m senderUsername], [m senderAddress]);

		[self print:c
			   type:TVCLogLineJoinType
		   nickname:nil
		messageBody:text
		 receivedAt:[m receivedAt]
			command:[m command]];
	}

	if ([m isPrintOnlyMessage] == NO) {
		[mainWindow() updateTitleFor:c];

		if (myself) {
			[c setInUserInvokedModeRequest:YES];

			[self send:IRCPrivateCommandIndex("mode"), [c name], nil];
		}
	}
}

- (void)receivePart:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:0];
	NSString *comment = [m paramAt:1];

	IRCChannel *c = [self findChannel:channel];
	
	PointerIsEmptyAssert(c);
	
	BOOL myself = [sendern isEqualIgnoringCase:[self localNickname]];
	
	if ([m isPrintOnlyMessage] == NO) {
		if (myself) {
			[c deactivate];

			[mainWindow() reloadTreeItem:c];
		}

		[c removeMember:sendern];
	}

	if ([TPCPreferences showJoinLeave] || myself) {
		IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
																 withMatches:@[@"ignoreJPQE"]];

		if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
			return;
		}

		NSString *message = BLS(1163, sendern, [m senderUsername], [m senderAddress]);

		if (NSObjectIsNotEmpty(comment)) {
			message = BLS(1164, message, comment);
		}
		
		[self print:c
			   type:TVCLogLinePartType
		   nickname:nil
		messageBody:message
		 receivedAt:[m receivedAt]
			command:[m command]];
	}

	if ([m isPrintOnlyMessage] == NO) {
		[mainWindow() updateTitleFor:c];
	}
}

- (void)receiveKick:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 1);
	
	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:0];
	NSString *targetu = [m paramAt:1];
	NSString *comment = [m paramAt:2];

	IRCChannel *c = [self findChannel:channel];
	
	PointerIsEmptyAssert(c);
	
	BOOL myself = [sendern isEqualIgnoringCase:[self localNickname]];
	
	if ([m isPrintOnlyMessage] == NO) {
		if (myself) {
			[c deactivate];

			[mainWindow() reloadTreeItem:c];

			[self notifyEvent:TXNotificationKickType lineType:TVCLogLineKickType target:c nickname:sendern text:comment];

			if ([TPCPreferences rejoinOnKick] && [c errorOnLastJoinAttempt] == NO) {
				[self printDebugInformation:BLS(1127) channel:c];

				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(joinKickedChannel:) object:c];
				
				[self performSelector:@selector(joinKickedChannel:) withObject:c afterDelay:3.0];
			}
		}
		
		[c removeMember:targetu];
	}

	if ([TPCPreferences showJoinLeave] || myself) {
		IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
																 withMatches:@[@"ignoreJPQE"]];

		if (([ignoreChecks ignoreJPQE] || c.config.ignoreJPQActivity) && myself == NO) {
			return;
		}

		NSString *message = BLS(1162, sendern, targetu, comment);

		[self print:c
			   type:TVCLogLineKickType
		   nickname:nil
		messageBody:message
		 receivedAt:[m receivedAt]
			command:[m command]];
	}

	if ([m isPrintOnlyMessage] == NO) {
		[mainWindow() updateTitleFor:c];
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSString *sendern = [m senderNickname];
	
	NSString *comment = [m paramAt:0];
	
	NSString *target = nil;

	BOOL myself = [sendern isEqualIgnoringCase:[self localNickname]];

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

	/* When m.isPrintOnlyMessage is set for quit messages the order in which
	 the paramas is handled is a little different. Index 0 is the target channel
	 for the print and index 1 is the quit message. In a normal quit message, 
	 where [m isPrintOnlyMessage] == NO, then 0 is quit message and 1 is nothing. */
	if ([m isPrintOnlyMessage]) {
		NSAssert(([m paramsCount] == 2), @"Bad [m isPrintOnlyMessage] conditions.");

		comment = [m paramAt:1];
		target = [m paramAt:0];
	}

	/* Continue. */
	NSString *text = BLS(1153, sendern, [m senderUsername], [m senderNickname]);

	if (NSObjectIsNotEmpty(comment)) {
		/* Crude regular expression for matching netsplits. */
		static NSString *nsrgx = @"^((([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)) (([a-zA-Z0-9-_\\.\\*]+)\\.([a-zA-Z0-9-_]+)))$";
		
		if ([TLORegularExpression string:comment isMatchedByRegex:nsrgx]) {
			comment = BLS(1149, comment);
		}

		text = BLS(1150, text, comment);
	}
	
#define	_showQuitInChannel		([TPCPreferences showJoinLeave] && [ignoreChecks ignoreJPQE] == NO && c.config.ignoreJPQActivity == NO)

	/* Is this a targetted print message? */
	if ([m isPrintOnlyMessage]) {
		IRCChannel *c = [self findChannel:target];

		if ([c isChannel]) {
			if (_showQuitInChannel) {
				[self print:c
					   type:TVCLogLineQuitType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}
		}

		/* Once a targetted print occurs, we can stop here. Nothing else
		 in this method should be used when it is a print only job. */
		return;
	}

	/* Continue with normal operations. */
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c memberExists:sendern]) {
				if (_showQuitInChannel || myself || [c isPrivateMessage]) {
					if ([c isPrivateMessage]) {
						text = BLS(1154, sendern);
					}

					[self print:c
						   type:TVCLogLineQuitType
					   nickname:nil
					messageBody:text
					 receivedAt:[m receivedAt]
						command:[m command]];
				}

				[c removeMember:sendern];

				if (myself || [c isPrivateMessage]) {
					[c deactivate];

					if (myself == NO) {
						[mainWindow() reloadTreeItem:c];
					}
				}
			}
		}
	}

#undef _showQuitInChannel

	[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];

	if (myself) {
		[mainWindow() reloadTreeGroup:self];
	}

	[mainWindow() updateTitle];
}

- (void)receiveKill:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	NSString *target = [m paramAt:0];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c findMember:target]) {
				[c removeMember:target];
			}
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	IRCAddressBookEntry *ignoreChecks;

	NSString *oldNick = [m senderNickname];
	
	NSString *newNick;
	NSString *target;

	/* Check input conditions. */
	if ([m isPrintOnlyMessage] == NO) {
		NSAssert(([m paramsCount] == 1), @"Bad receiveNick: conditions.");

        newNick = [m paramAt:0];
	} else {
		NSAssert(([m paramsCount] == 2), @"Bad [m isPrintOnlyMessage] conditions.");

		target = [m paramAt:0];
        newNick = [m paramAt:1];
	}

	/* Are they exactly the same? */
	if ([oldNick isEqualToString:newNick]) {
		return;
	}

	/* Prepare ignore checks. */
	BOOL myself = [oldNick isEqualIgnoringCase:[self localNickname]];

	if (myself) {
		if ([m isPrintOnlyMessage] == NO) {
			self.cachedLocalNickname = newNick;
			
			self.tryingNicknameSentNickname = newNick;
		}
	} else {
		if ([m isPrintOnlyMessage] == NO) {
			/* Check new nickname in address book user check. */
			ignoreChecks = [self checkIgnoreAgainstHostmask:[newNick stringByAppendingString:@"!-@-"]
												withMatches:@[@"notifyJoins"]];

			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}

		/* Check old nickname in address book user check. */
		ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
											withMatches:@[@"ignoreJPQE", @"notifyJoins"]];

		if ([m isPrintOnlyMessage] == NO) {
			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}
	}

	/* Is this a targetted print message? */
	if ([m isPrintOnlyMessage]) {
		IRCChannel *c = [self findChannel:target];

		if (c) {
			NSString *text = nil;
			
			if (myself == NO && [TPCPreferences showJoinLeave] && [ignoreChecks ignoreJPQE] == NO && c.config.ignoreJPQActivity == NO) {
				text = TXTLS(@"BasicLanguage[1152][0]", oldNick, newNick);

			}
            
			if (myself == YES) {
				text = TXTLS(@"BasicLanguage[1152][1]", newNick);
			}
			
			if (text) {
				[self print:c
					   type:TVCLogLineNickType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}
		}

		/* Once a targetted print occurs, we can stop here. Nothing else
		 ini this method should be used when it is a print only job. */
		return;
	}

	/* Continue with normal operations. */
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c memberExists:oldNick]) {
				NSString *text = nil;
				
				if ((myself == NO && [TPCPreferences showJoinLeave] && [ignoreChecks ignoreJPQE] == NO && c.config.ignoreJPQActivity == NO)) {
					text = TXTLS(@"BasicLanguage[1152][0]", oldNick, newNick);
				}
				
				if (myself == YES) {
					text = TXTLS(@"BasicLanguage[1152][1]", newNick);
				}
				
				if (text) {
					[self print:c
						   type:TVCLogLineNickType
					   nickname:nil
					messageBody:text
					 receivedAt:[m receivedAt]
						command:[m command]];
				}
				
				[c renameMember:oldNick to:newNick];
			}
		}
	}

	IRCChannel *c = [self findChannel:oldNick];
	IRCChannel *t = [self findChannel:newNick];

	PointerIsEmptyAssert(c);

	if (t) {
		/* If a query of this name already exists, then we
		 destroy it before changing name of old. */
		if (NSObjectsAreEqual([c name], [t name]) == NO) {
			[worldController() destroyChannel:t];
		}
	}

	[c setName:newNick];

	[mainWindow() reloadTreeItem:c];
	
	if (myself) {
		[mainWindow() updateTitleFor:c];
	}
	
	[[self fileTransferController] nicknameChanged:oldNick toNickname:newNick client:self];
}

- (void)receiveMode:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 1);

	NSString *sendern = [m senderNickname];
	
	NSString *targetc = [m paramAt:0];
	NSString *modestr = [m sequence:1];

	if ([targetc isChannelName:self]) {
		IRCChannel *c = [self findChannel:targetc];

		PointerIsEmptyAssert(c);
		
		if ([m isPrintOnlyMessage] == NO) {
			NSArray *info = [[c modeInfo] update:modestr];

			BOOL performWho = NO;

			for (IRCModeInfo *h in info) {
				[c changeMember:[h modeParamater] mode:[h modeToken] value:[h modeIsSet]];

				if ([h modeIsSet] == NO && [self isCapacityEnabled:ClientIRCv3SupportedCapacityMultiPreifx] == NO) {
					performWho = YES;
				}
			}

			if (performWho) {
				[self send:IRCPrivateCommandIndex("who"), [c name], nil, nil];
			}
		}

		if ([TPCPreferences showJoinLeave] && c.config.ignoreJPQActivity == NO) {
			[self print:c
				   type:TVCLogLineModeType
			   nickname:nil
			messageBody:BLS(1145, sendern, modestr)
			 receivedAt:[m receivedAt]
				command:[m command]];
		}

		if ([m isPrintOnlyMessage] == NO) {
			[mainWindow() updateTitleFor:c];
		}
	} else {
		[self print:nil
			   type:TVCLogLineModeType
		   nickname:nil
		messageBody:BLS(1145, sendern, modestr)
		 receivedAt:[m receivedAt]
			command:[m command]];
	}
}

- (void)receiveTopic:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] == 2);

	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:0];
	NSString *topicav = [m paramAt:1];

	IRCChannel *c = [self findChannel:channel];

	BOOL isEncrypted = [self isMessageEncrypted:topicav channel:c];

	if (isEncrypted) {
		[self decryptIncomingMessage:&topicav channel:c];
	}
	
	if ([m isPrintOnlyMessage] == NO) {
		[c setTopic:topicav];
	}

	[self print:c
		   type:TVCLogLineTopicType
	   nickname:nil
	messageBody:BLS(1128, sendern, topicav)
	isEncrypted:isEncrypted
	 receivedAt:[m receivedAt]
		command:[m command]];
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] == 2);

	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:1];
	
	NSString *text = BLS(1158, sendern, [m senderUsername], [m senderAddress], channel);
	
	/* Invite notifications are sent to frontmost channel on server of if it is
	 not on server, then it will be redirected to console. */
	[self print:[mainWindow() selectedChannelOn:self]
		   type:TVCLogLineInviteType
	   nickname:nil
	messageBody:text
	 receivedAt:[m receivedAt]
		command:[m command]];
	
	[self notifyEvent:TXNotificationInviteType lineType:TVCLogLineInviteType target:nil nickname:sendern text:channel];
	
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
		[menuController() showServerPropertyDialog:self withDefaultView:TDCServerSheetFloodControlNavigationSelection andContext:nil];
    }
}

- (void)receiveError:(IRCMessage *)m
{
	NSString *message = [m sequence];

    /* This match is pretty general, but it works in most situations. */
    if (([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Excess Flood)"]) ||
		([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Max SendQ exceeded)"]))
	{
		[mainWindow() select:self]; // Bring server to attention before popping view.

        /* Cancel any active reconnect before asking if the user wants to do it. */
        /* We cancel after 1.0 second to allow this popup prompt to be called and then 
         for Textual to process the actual drop in socket. receiveError: is called before
         our reconnect begins so we have to race it. */
        [self performSelector:@selector(cancelReconnect) withObject:nil afterDelay:2.0];

        /* Prompt user about disconnect. */
        TLOPopupPrompts *prompt = [TLOPopupPrompts new];

        [prompt sheetWindowWithQuestion:mainWindow()
                                 target:self
                                 action:@selector(receiveErrorExcessFloodWarningPopupCallback:withOriginalAlert:)
                                   body:TXTLS(@"BasicLanguage[1041][2]")
                                  title:TXTLS(@"BasicLanguage[1041][1]")
                          defaultButton:BLS(1219)
                        alternateButton:BLS(1182)
                            otherButton:TXTLS(@"BasicLanguage[1041][3]")
                         suppressionKey:nil
                        suppressionText:nil];
    } else {
		[self printError:message forCommand:[m command]];
    }
}

#pragma mark -
#pragma mark Server CAP

- (void)enableCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	if ([self isCapacityEnabled:capacity] == NO) {
		_capacities |= capacity;
	}
}

- (void)disableCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	if ([self isCapacityEnabled:capacity]) {
		_capacities &= ~capacity;
	}
}

- (BOOL)isCapacityEnabled:(ClientIRCv3SupportedCapacities)capacity
{
	return (_capacities & capacity);
}

- (NSString *)stringValueOfCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	NSString *stringValue = nil;
	
	switch (capacity) {
		case ClientIRCv3SupportedCapacityAwayNotify:
		{
			stringValue = @"away-notify";
			
			break;
		}
		case ClientIRCv3SupportedCapacityIdentifyCTCP:
		{
			stringValue = @"identify-ctcp";
			
			break;
		}
		case ClientIRCv3SupportedCapacityIdentifyMsg:
		{
			stringValue = @"identify-msg";
			
			break;
		}
		case ClientIRCv3SupportedCapacityMultiPreifx:
		{
			stringValue = @"multi-prefix";
			
			break;
		}
		case ClientIRCv3SupportedCapacitySASLExternal:
		case ClientIRCv3SupportedCapacitySASLPlainText:
		{
			stringValue = @"sasl";
			
			break;
		}
		case ClientIRCv3SupportedCapacityServerTime:
		{
			stringValue = @"server-time";
			
			break;
		}
		case ClientIRCv3SupportedCapacityUserhostInNames:
		{
			stringValue = @"away-notify";
			
			break;
		}
		case ClientIRCv3SupportedCapacityWatchCommand:
		{
			stringValue = @"watch-command";
			
			break;
		}
		case ClientIRCv3SupportedCapacityZNCPlaybackModule:
		{
			stringValue = @"znc.in/playback";
			
			break;
		}
		case ClientIRCv3SupportedCapacityZNCServerTime:
		{
			stringValue = @"znc.in/server-time";
			
			break;
		}
		case ClientIRCv3SupportedCapacityZNCServerTimeISO:
		{
			stringValue = @"znc.in/server-time-iso";
			
			break;
		}
		default:
		{
			break;
		}
	}
	
	return stringValue;
}

- (void)appendStringValueOfCapacity:(ClientIRCv3SupportedCapacities)capacity toSource:(NSMutableArray **)writePoint
{
	if ([self isCapacityEnabled:capacity]) {
		[*writePoint addObject:[self stringValueOfCapacity:capacity]];
	}
}

- (NSString *)enabledCapacitiesStringValue
{
	NSMutableArray *enabledCaps = [NSMutableArray array];
	
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityAwayNotify toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityIdentifyCTCP toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityIdentifyMsg toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityMultiPreifx toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacitySASLPlainText toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacitySASLExternal toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityServerTime toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityUserhostInNames toSource:&enabledCaps];
	[self appendStringValueOfCapacity:ClientIRCv3SupportedCapacityZNCPlaybackModule toSource:&enabledCaps];
	
	NSString *stringValue = [enabledCaps componentsJoinedByString:@", "];
	
	return stringValue;
}

- (BOOL)maybeSendNextCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	if (_capacitiesPending & capacity) {
		NSString *capVaule = [self stringValueOfCapacity:capacity];
		
		[self send:IRCPrivateCommandIndex("cap"), @"REQ", capVaule, nil];
		
		_capacitiesPending &= ~capacity;
		
		return YES; // Let receiver know we sent this cap.
	}
	
	return NO;
}

- (void)sendNextCap
{
	/* We try to send each cap. First one to return a YES for sending
	 itself will break the chain and we'll try next one later. */
#define _rony(s)		if ([self maybeSendNextCapacity:(s)] == YES) { return; }
	
	if (_capacitiesPending == 0) {
		[self send:IRCPrivateCommandIndex("cap"), @"END", nil];
	} else {
		_rony(ClientIRCv3SupportedCapacityAwayNotify)
		_rony(ClientIRCv3SupportedCapacityIdentifyCTCP)
		_rony(ClientIRCv3SupportedCapacityIdentifyMsg)
		_rony(ClientIRCv3SupportedCapacityMultiPreifx)
		_rony(ClientIRCv3SupportedCapacityServerTime)
		_rony(ClientIRCv3SupportedCapacityUserhostInNames)
		_rony(ClientIRCv3SupportedCapacityZNCPlaybackModule)
		_rony(ClientIRCv3SupportedCapacityZNCServerTime)
		_rony(ClientIRCv3SupportedCapacityZNCServerTimeISO)
	}
	
#undef _rony
}

- (void)pauseCap
{
	self.CAPPausedStatus++;
}

- (void)resumeCap
{
	self.CAPPausedStatus--;

	[self sendNextCap];
}

- (BOOL)isCapAvailable:(NSString *)cap
{
	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org
	
	BOOL condition1 = ([cap isEqualIgnoringCase:@"identify-msg"]			||
					   [cap isEqualIgnoringCase:@"identify-ctcp"]			||
					   [cap isEqualIgnoringCase:@"away-notify"]				||
					   [cap isEqualIgnoringCase:@"multi-prefix"]			||
					   [cap isEqualIgnoringCase:@"userhost-in-names"]		||
					   [cap isEqualIgnoringCase:@"server-time"]				||
					   [cap isEqualIgnoringCase:@"znc.in/playback"]			||
					   [cap isEqualIgnoringCase:@"znc.in/server-time"]		||
					   [cap isEqualIgnoringCase:@"znc.in/server-time-iso"]);
	
	if (condition1 == NO) {
		if ([cap isEqualIgnoringCase:@"sasl"]) {
			return [self isSASLInformationAvailable];
		} else {
			return NO;
		}
	} else {
		return YES;
	}
}

- (ClientIRCv3SupportedCapacities)capacityFromStringValue:(NSString *)stringValue
{
	if ([stringValue isEqualIgnoringCase:@"userhost-in-names"]) {
		return ClientIRCv3SupportedCapacityUserhostInNames;
	} else if ([stringValue isEqualIgnoringCase:@"multi-prefix"]) {
		return ClientIRCv3SupportedCapacityMultiPreifx;
	} else if ([stringValue isEqualIgnoringCase:@"identify-msg"]) {
		return ClientIRCv3SupportedCapacityIdentifyMsg;
	} else if ([stringValue isEqualIgnoringCase:@"identify-ctcp"]) {
		return ClientIRCv3SupportedCapacityIdentifyCTCP;
	} else if ([stringValue isEqualIgnoringCase:@"away-notify"]) {
		return ClientIRCv3SupportedCapacityAwayNotify;
	} else if ([stringValue isEqualIgnoringCase:@"server-time"]) {
		return ClientIRCv3SupportedCapacityServerTime;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/server-time"]) {
		return ClientIRCv3SupportedCapacityZNCServerTime;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/server-time-iso"]) {
		return ClientIRCv3SupportedCapacityZNCServerTimeISO;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/playback"]) {
		return ClientIRCv3SupportedCapacityZNCPlaybackModule;
	} else {
		return 0;
	}
}

- (void)cap:(NSString *)cap result:(BOOL)supported
{
	if ([cap isEqualIgnoringCase:@"sasl"]) {
		if (supported) {
			[self pauseCap];
			
			[self sendSASLIdentificationRequest];
		}
	} else {
		ClientIRCv3SupportedCapacities capacity = [self capacityFromStringValue:cap];
		
		if (capacity == 0) {
			; // Unknown capacity.
		} else {
			if (capacity == ClientIRCv3SupportedCapacityZNCServerTime ||
				capacity == ClientIRCv3SupportedCapacityZNCServerTimeISO)
			{
				capacity = ClientIRCv3SupportedCapacityServerTime;
			}
			
			if (supported) {
				[self enableCapacity:capacity];
			} else {
				[self disableCapacity:capacity];
			}
		}
	}
}

- (IRCClientIdentificationWithSASLMechanism)identificationMechanismForSASL
{
	/* If we have certificate, we will use the fingerprint from that 
	 for identification if the user configured that. */
	if (self.socket.isConnectedWithClientSideCertificate) {
		if (self.config.sendAuthenticationRequestsToUserServ) {
			return IRCClientIdentificationWithSASLExternalMechanism;
		}
	}

	/* If the user has a configured nickname password, then we will
	 use that instead for plain text authentication. */
	if (self.config.nicknamePasswordIsSet) {
		return IRCClientIdentificationWithSASLPlainTextMechanism;
	}

	/* Cannot use SASL for identification. */
	return IRCClientIdentificationWithSASLNoMechanism;
}

- (BOOL)isSASLInformationAvailable
{
	IRCClientIdentificationWithSASLMechanism idtype = [self identificationMechanismForSASL];

	return NSDissimilarObjects(idtype, IRCClientIdentificationWithSASLNoMechanism);
}

- (void)sendSASLIdentificationInformation
{
	switch ([self identificationMechanismForSASL]) {
		case IRCClientIdentificationWithSASLPlainTextMechanism:
		{
			NSString *authStringD = [NSString stringWithFormat:@"%@%C%@%C%@",
									 self.config.username, 0x00,
									 self.config.username, 0x00,
									 self.config.nicknamePassword];

			NSString *authStringE = [authStringD base64EncodingWithLineLength:400];

			NSArray *authStrings = [authStringE componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

			for (NSString *string in authStrings) {
				[self send:IRCPrivateCommandIndex("cap_authenticate"), string, nil];
			}

			/* I don't really know when the condition below would be true. It's a
			 copy over from Colloquy. Is it even needed? */
			if (NSObjectIsEmpty(authStrings) || [(NSString *)[authStrings lastObject] length] == 400) {
				[self send:IRCPrivateCommandIndex("cap_authenticate"), @"+", nil];
			}

			break;
		}
		case IRCClientIdentificationWithSASLExternalMechanism:
		{
			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"+", nil];

			break;
		}
		default:
		{
			break;
		}
	}
}

- (void)sendSASLIdentificationRequest
{
	[self enableCapacity:ClientIRCv3SupportedCapacityIsInSASLNegotiation];

	switch ([self identificationMechanismForSASL]) {
		case IRCClientIdentificationWithSASLPlainTextMechanism:
		{
			[self enableCapacity:ClientIRCv3SupportedCapacitySASLPlainText];
			
			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"PLAIN", nil];

			break;
		}
		case IRCClientIdentificationWithSASLExternalMechanism:
		{
			[self enableCapacity:ClientIRCv3SupportedCapacitySASLExternal];

			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"EXTERNAL", nil];

			break;
		}
		default:
		{
			break;
		}
	}
}

- (void)receiveCapacityOrAuthenticationRequest:(IRCMessage *)m
{
	/* Implementation based off Colloquy's own. */

	NSAssertReturn([m paramsCount] > 0);

	NSString *command = [m command];
	NSString *starprt = [m paramAt:0];
	NSString *baseprt = [m paramAt:1];
	NSString *actions = [m sequence:2];

	if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap")]) {
		if ([baseprt isEqualIgnoringCase:@"LS"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				if ([self isCapAvailable:cap]) {
					ClientIRCv3SupportedCapacities capacity = [self capacityFromStringValue:cap];
					
					if ((_capacitiesPending & capacity) == 0) {
						 _capacitiesPending |= capacity;
					}
				}
			}
		} else if ([baseprt isEqualIgnoringCase:@"ACK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
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
			[self sendSASLIdentificationInformation];
		}
	}
}

- (void)receivePing:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	[self send:IRCPrivateCommandIndex("pong"), [m sequence:0], nil];
}

- (void)receiveAwayNotifyCapacity:(IRCMessage *)m
{
    NSAssertReturn([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]);

    /* What are we changing to? */
    BOOL isAway = NSObjectIsNotEmpty([m sequence]);

    /* Find all users matching user info. */
	NSString *nickname = [m senderNickname];

	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			IRCUser *user = [channel findMember:nickname];

			if (user) {
				[user setIsAway:isAway];
				
				[channel updateMemberOnTableView:user]; // Redraw the user in the user list.
			}
		}
	}
}

- (void)receiveInit:(IRCMessage *)m // Raw numeric = 001
{
	/* Manage timers. */
#ifdef TEXTUAL_TRIAL_BINARY
	[self startTrialPeriodTimer];
#endif
	
	[self startPongTimer];
	[self stopRetryTimer];

	/* Manage local variables. */
	self.supportInfo.networkAddress = [m senderHostmask];

	self.isLoggedIn = YES;
	self.isConnected = YES;
	
	self.isInvokingISONCommandForFirstTime = YES;

	self.serverRedirectAddressTemporaryStore = nil;
	self.serverRedirectPortTemporaryStore = 0;

	self.cachedLocalNickname = [m paramAt:0];
	
	self.tryingNicknameSentNickname = [m paramAt:0];
	
	/* Post event. */
	[self postEventToViewController:@"serverConnected"];

	/* Notify Growl. */
	[self notifyEvent:TXNotificationConnectType lineType:TVCLogLineDebugType];

	/* Perform login commands. */
	for (__strong NSString *s in self.config.loginCommands) {
		if ([s hasPrefix:@"/"]) {
			s = [s substringFromIndex:1];
		}

		[self sendCommand:s completeTarget:NO target:nil];
	}

	/* Request playback since the last seen message when previously connected. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
		NSString *timetosend = [NSString stringWithFloat:[self lastMessageServerTimeWithCachedValue]];
		
		[self send:IRCPrivateCommandIndex("privmsg"), @"*playback", @"play", @"*", timetosend, nil];
	}

	/* Activate existing queries. */
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c isPrivateMessage]) {
				[c activate];
			}
		}
	}

	[mainWindow() reloadTreeGroup:self];
    [mainWindow() updateTitle];

	[mainWindowTextField() updateSegmentedController];

	/* Everything else. */
	if ([TPCPreferences autojoinWaitsForNickServ] == NO || [self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL]) {
		[self performAutoJoin];
	} else {
        /* If we wait for NickServ we set a timer of 3.0 seconds before performing auto join.
         When this timer is executed, if we do not have any knowledge of NickServ existing
         on the current server, then we perform the autojoin. This is primarly a fix for the
         ZNC SASL module which will complete identification before connecting and once connected
         Textual will have no knowledge of whether the local user is identified or not. 
         
         NickServ will send a notice asking for identification as soon as connection occurs so
         this is the best patch. At least for right now. */

		if (self.isZNCBouncerConnection) {
			[self performSelector:@selector(performAutoJoin) withObject:nil afterDelay:3.0];
		}
	}
	
	/* We need time for the server to send its configuration. */
	[self performSelector:@selector(populateISONTrackedUsersList:) withObject:self.config.ignoreList afterDelay:10.0];
}

- (void)receiveNumericReply:(IRCMessage *)m
{
	NSInteger n = [m numericReply];

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
            [self.supportInfo update:[m sequence:1] client:self];
            
			if (self.rawModeEnabled || [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken]) {
                NSArray *configRep = [self.supportInfo buildConfigurationRepresentation];

                [self printDebugInformationToConsole:[configRep lastObject] forCommand:[m command]];
            }

			[mainWindow() reloadTreeGroup:self];

			break;
		}
		case 10: // RPL_REDIR
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *address = [m paramAt:1];
			NSString *portraw = [m paramAt:2];

			self.disconnectType = IRCClientDisconnectServerRedirectMode;

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
		case 222: // RPL_(?????) — Legacy code. What goes here?
		{
			break;
		}
		case 265 ... 266: // RPL_LOCALUSERS, RPL_GLOBALUSERS
        {
            NSString *message = [m sequence];

            if ([m paramsCount] == 4) {
                /* Removes user count from in front of messages on IRCds that send them.
                 Example: ">> :irc.example.com 265 Guest 2 3 :Current local users 2, max 3" */
                
                message = [m sequence:3];
            }
			
			[self print:nil
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:message
			 receivedAt:[m receivedAt]
				command:[m command]];

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
			NSAssertReturnLoopBreak([m paramsCount] > 1);
			
			NSString *modestr = [m paramAt:1];

			if ([modestr isEqualToString:@"+"]) {
				break;
			}
			
			[self print:nil
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:BLS(1156, [self localNickname], modestr)
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 290: // RPL_CAPAB (freenode)
		{
			NSAssertReturnLoopBreak([m paramsCount] > 1);

			NSString *kind = [m paramAt:1];

			if ([kind isEqualIgnoringCase:@"identify-msg"]) {
				[self enableCapacity:ClientIRCv3SupportedCapacityIdentifyMsg];
			} else if ([kind isEqualIgnoringCase:@"identify-ctcp"]) {
				[self enableCapacity:ClientIRCv3SupportedCapacityIdentifyCTCP];
			}

			[self printReply:m];

			break;
		}
		case 301: // RPL_AWAY
		{
			NSAssertReturnLoopBreak([m paramsCount] > 1);

			NSString *awaynick = [m paramAt:1];
			NSString *comment = [m paramAt:2];

			IRCChannel *ac = [self findChannel:awaynick];

			NSString *text = BLS(1159, awaynick, comment);

            if (ac == nil) {
				ac = [mainWindow() selectedChannelOn:self];
            }
			
			[self print:ac
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 305: // RPL_UNAWAY
		case 306: // RPL_NOWAWAY
		{
			self.isAway = ([m numericReply] == 306);

			[self printUnknownReply:m];
            
            /* Update our own status. This has to only be done with away-notify CAP enabled.
             Old, WHO based information requests will still show our own status. */
            NSAssertReturnLoopBreak([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]);

			@synchronized(self.channels) {
				for (IRCChannel *channel in self.channels) {
					IRCUser *myself = [channel findMember:[self localNickname]];
					
					if (myself) {
						[myself setIsAway:self.isAway];
						
						[channel updateMemberOnTableView:myself];
					}
				}
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
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];

			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 338: // RPL_WHOISACTUALLY (ircu, Bahamut)
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 311: // RPL_WHOISUSER
		case 314: // RPL_WHOWASUSER
		{
			NSAssertReturnLoopBreak([m paramsCount] >= 6);

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *hostmask = [m paramAt:3];
			NSString *realname = [m paramAt:5];

			NSString *text = nil;

			self.inUserInvokedWhowasRequest = (n == 314);

			if ([realname hasPrefix:@":"]) {
				realname = [realname substringFromIndex:1];
			}

			if (self.inUserInvokedWhowasRequest) {
				text = BLS(1170, nickname, username, hostmask, realname);
			} else {
				/* Update local cache of our hostmask. */
				if ([nickname isEqualIgnoringCase:[self localNickname]]) {
					NSString *completehost = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];

					self.cachedLocalHostmask = completehost;
				}

				/* Continue normal WHOIS event. */
				text = BLS(1167, nickname, username, hostmask, realname);
			}
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 312: // RPL_WHOISSERVER
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *nickname = [m paramAt:1];
			NSString *serverHost = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];

			NSString *text = nil;

			if (self.inUserInvokedWhowasRequest) {
				NSString *timeInfo = [NSDateFormatter localizedStringFromDate:[NSDate dateWithNaturalLanguageString:serverInfo]
																	dateStyle:NSDateFormatterLongStyle
																	timeStyle:NSDateFormatterLongStyle];
				
				text = BLS(1169, nickname, serverHost, timeInfo);
			} else {
				text = BLS(1166, nickname, serverHost, serverInfo);
			}
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 317: // RPL_WHOISIDLE
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *nickname = [m paramAt:1];
			NSString *idleTime = [m paramAt:2];
			NSString *connTime = [m paramAt:3];

			idleTime = TXHumanReadableTimeInterval([idleTime doubleValue], NO, 0);
			
			connTime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[connTime doubleValue]]
													  dateStyle:NSDateFormatterLongStyle
													  timeStyle:NSDateFormatterLongStyle];

			NSString *text = BLS(1168, nickname, connTime, idleTime);
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 319: // RPL_WHOISCHANNELS
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *nickname = [m paramAt:1];
			NSString *channels = [m paramAt:2];

			NSString *text = BLS(1165, nickname, channels);
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 324: // RPL_CHANNELMODES
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *modestr = [m sequence:2];

			if ([modestr isEqualToString:@"+"]) {
				break;
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if ([c isActive]) {
				[[c modeInfo] clear];
				[[c modeInfo] update:modestr];
			}

			if (self.inUserInvokedModeRequest || c.inUserInvokedModeRequest) {
				NSString *fmodestr = [[c modeInfo] format:NO];

				[self print:c
					   type:TVCLogLineModeType
				   nickname:nil
				messageBody:BLS(1123, fmodestr)
				 receivedAt:[m receivedAt]
					command:[m command]];

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
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *topicva = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			BOOL isEncrypted = [self isMessageEncrypted:topicva channel:c];

			if (isEncrypted) {
				[self decryptIncomingMessage:&topicva channel:c];
			}

			if ([c isActive]) {
				[c setTopic:topicva];
				
				[self print:c
					   type:TVCLogLineTopicType
				   nickname:nil
				messageBody:BLS(1124, topicva)
				isEncrypted:isEncrypted
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 333: // RPL_TOPICWHOTIME
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *channel = [m paramAt:1];
			NSString *topicow = [m paramAt:2];
			NSString *settime = [m paramAt:3];

			topicow = [topicow nicknameFromHostmask];

			settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[settime doubleValue]]
													 dateStyle:NSDateFormatterLongStyle
													 timeStyle:NSDateFormatterLongStyle];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if ([c isActive]) {
				NSString *text = BLS(1125, topicow, settime);

				[self print:c
					   type:TVCLogLineTopicType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}
			
			break;
		}
		case 341: // RPL_INVITING
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);
			
			NSString *nickname = [m paramAt:1];
			NSString *channel = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			if ([c isActive]) {
				[self print:c
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:BLS(1157, nickname, channel)
				 receivedAt:[m receivedAt]
					command:[m command]];
			}
			
			break;
		}
		case 303: // RPL_ISON
		{
			/* Cut the users up. */
			NSString *userInfo = [[m sequence] lowercaseString];
			
			NSArray *users = [userInfo split:NSStringWhitespacePlaceholder];

			/* Start going over the list of tracked nicknames. */
			@synchronized(self.trackedUsers) {
				NSArray *trackedUsers = [self.trackedUsers allKeys];
				
				for (NSString *name in trackedUsers) {
					NSInteger langKey = 0;
					
					/* Was the user on during the last check? */
					BOOL ison = [self.trackedUsers boolForKey:name];
					
					if (ison) {
						/* If the user was on before, but is not in the list of ISON
						 users in this reply, then they are considered gone. Log that. */
						if ([users containsObjectIgnoringCase:name] == NO) {
							if (self.isInvokingISONCommandForFirstTime == NO) {
								langKey = 1084;
							}
							
							[self.trackedUsers setBool:NO forKey:name];
						}
					} else {
						/* If they were not on but now are, then log that too. */
						if ([users containsObjectIgnoringCase:name]) {
							if (self.isInvokingISONCommandForFirstTime) {
								langKey = 1082;
							} else {
								langKey = 1085;
							}
							
							[self.trackedUsers setBool:YES forKey:name];
						}
					}
					
					/* If we have a langkey, then there was something logged. We will now
					 find the actual tracking rule that matches the name and post that to the
					 end user to see the user status. */
					if (langKey > 0) {
						for (IRCAddressBookEntry *g in self.config.ignoreList) {
							NSString *trname = [g trackingNickname];
							
							if ([trname isEqualIgnoringCase:name]) {
								[self handleUserTrackingNotification:g nickname:name langitem:langKey];
							}
						}
					}
				}
			}

			if (self.isInvokingISONCommandForFirstTime) { // Reset internal var.
				self.isInvokingISONCommandForFirstTime = NO;
			}

			/* Update private messages. */
			@synchronized(self.channels) {
				for (IRCChannel *channel in self.channels) {
					if ([channel isPrivateMessage]) {
						if ([channel isActive]) {
							/* If the user is no longer on, deactivate the private message. */
							if ([users containsObjectIgnoringCase:[channel name]] == NO) {
								[channel deactivate];

								[mainWindow() reloadTreeItem:channel];
							}
						} else {
							/* Activate the private message if the user is back on. */
							if ([users containsObjectIgnoringCase:[channel name]]) {
								[channel activate];

								[mainWindow() reloadTreeItem:channel];
							}
						}
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

            [mainWindow() updateTitleFor:c];

			break;
		}
		case 352: // RPL_WHOREPLY
		{
			NSAssertReturnLoopBreak([m paramsCount] > 6);

			NSString *channel = [m paramAt:1];

			if (self.inUserInvokedWhoRequest) {
				[self printUnknownReply:m];
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);
			
			BOOL isSelectedChannel = (c == [mainWindow() selectedItem]);
			
			/* Example incoming data:
				<channel> <user> <host> <server> <nick> <H|G>[*][@|+] <hopcount> <real name>
			 
				#freenode znc unaffiliated/namikaze kornbluth.freenode.net Namikaze G 0 Christian
				#freenode ~D unaffiliated/solprefixer kornbluth.freenode.net solprefixer H 0 solprefixer
			*/
			
			NSString *nickname = [m paramAt:5];
			NSString *username = [m paramAt:2];
			NSString *hostmask = [m paramAt:3];
			NSString *flfields = [m paramAt:6];

            BOOL isIRCop = NO;
            BOOL isAway = NO;

			// Field Syntax: <H|G>[*][@|+]
			// Strip G or H (away status).
			if (self.inUserInvokedWhoRequest == NO) {
				if ([flfields hasPrefix:@"G"]) {
					if ([TPCPreferences trackUserAwayStatusMaximumChannelSize] > 0 || [self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]) {
						isAway = YES;
					}
				}
			}

			flfields = [flfields substringFromIndex:1];

			if ([flfields contains:@"*"]) {
				flfields = [flfields substringFromIndex:1];

                isIRCop = YES;
			}

			/* Textual handles changes from the WHO command differently than you may expect.
			 Given a user, a copy of that user is created. The copy of the user is then
			 modified based on the changes in the WHO reply. Once changed, the original 
			 user and the copied user is compared and based on some predetermined if 
			 statements, we will decide if the actual instance of the user in the visible
			 user list requires a redraw. If it does, the only then is the user removed
			 from the internal user list of the associated channel and readded. */
			IRCUser *oldUser = [c findMember:nickname];
			IRCUser *newUser;
			
			BOOL insertNewUser = NO;

			if (oldUser == nil) {
				newUser = [IRCUser newUserOnClient:self withNickname:nickname];
				
				insertNewUser = YES;
			} else {
				newUser = [oldUser copy];
			}
			
			[newUser setUsername:username];
			[newUser setAddress:hostmask];
			
			[newUser setIsAway:isAway];
			[newUser setIsCop:isIRCop];

#define _userModeSymbol(s)		([prefix isEqualTo:[self.supportInfo userModePrefixSymbol:(s)]])
			
			for (NSInteger i = 0; i < [flfields length]; i++) {
				NSString *prefix = [flfields stringCharacterAtIndex:i];
				
				if (_userModeSymbol(@"q")) {
					[newUser setQ:YES];
				} else if (_userModeSymbol(@"O")) { // binircd-1.0.0
					[newUser setQ:YES];
					[newUser setBinircd_O:YES];
				} else if (_userModeSymbol(@"a")) {
					[newUser setA:YES];
				} else if (_userModeSymbol(@"o")) {
					[newUser setO:YES];
				} else if (_userModeSymbol(@"h")) {
					[newUser setH:YES];
				} else if (_userModeSymbol(@"v")) {
					[newUser setV:YES];
				} else if (_userModeSymbol(@"y")) { // InspIRCd-2.0
					[newUser setIsCop:YES];
					[newUser setInspIRCd_y_lower:YES];
				} else if (_userModeSymbol(@"Y")) { // InspIRCd-2.0
					[newUser setIsCop:YES];
					[newUser setInspIRCd_y_upper:YES];
				} else {
					break;
				}
			}
			
			/* Update local cache of our hostmask. */
			if ([nickname isEqualIgnoringCase:[self localNickname]]) {
				NSString *completehost = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];

				self.cachedLocalHostmask = completehost;
			}

			/* Continue normal WHO reply tracking. */
			if (insertNewUser) {
				[c addMember:newUser];
			} else {
				BOOL requiresRedraw = [c memberRequiresRedraw:oldUser comparedTo:newUser];
				
				[oldUser migrate:newUser];
				
				/* If the member list is visible, we are the selected channel, and
				 the user requires redraw, then we remove them and readd them. */
				/* We actually remove them instead of calling redraw method because
				 the sort order could have changed. */
				if (requiresRedraw) {
					if (isSelectedChannel) {
						if ([c isChannel]) {
							if ([mainWindow() isMemberListVisible]) {
								[c removeMember:[oldUser nickname]];
								
								[c addMember:oldUser];
							}
						}
					}
				}
			}

			break;
		}
		case 353: // RPL_NAMEREPLY
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *channel = [m paramAt:2];
			NSString *nameblob = [m paramAt:3];
			
			if (self.inUserInvokedNamesRequest) {
				[self printUnknownReply:m];
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);

			NSArray *items = [nameblob componentsSeparatedByString:NSStringWhitespacePlaceholder];

			for (__strong NSString *nickname in items) {
				/* Create shell user. */
				IRCUser *member = [IRCUser newUserOnClient:self withNickname:nil];

				NSInteger i;
				
				/* Apply modes. */
				for (i = 0; i < [nickname length]; i++) {
					NSString *prefix = [nickname stringCharacterAtIndex:i];

					if (_userModeSymbol(@"q")) {
						[member setQ:YES];
					} else if (_userModeSymbol(@"O")) { // binircd-1.0.0
						[member setQ:YES];
						[member setBinircd_O:YES];
					} else if (_userModeSymbol(@"a")) {
						[member setA:YES];
					} else if (_userModeSymbol(@"o")) {
						[member setO:YES];
					} else if (_userModeSymbol(@"h")) {
						[member setH:YES];
					} else if (_userModeSymbol(@"v")) {
						[member setV:YES];
					} else if (_userModeSymbol(@"y")) { // InspIRCd-2.0
						[member setIsCop:YES];
						[member setInspIRCd_y_lower:YES];
					} else if (_userModeSymbol(@"Y")) { // InspIRCd-2.0
						[member setIsCop:YES];
						[member setInspIRCd_y_upper:YES];
					} else {
						break;
					}
				}
				
#undef _userModeSymbol

				/* Split away hostmask if available. */
				nickname = [nickname substringFromIndex:i];

				NSString *nicknameInt = nil;
				NSString *usernameInt = nil;
				NSString *addressInt = nil;

				if ([nickname hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt] == NO) {
					/* When NAMES reply is not a host, then set the nicknameInt
					 to the value of nickname and leave the rest as nil. */

					nicknameInt = nickname;
				}

				[member setNickname:nicknameInt];
				[member setUsername:usernameInt];
				[member setAddress:addressInt];
				
				/* Populate user list. */
				/* This data is populated if the user invoked the NAMES command
				 directly so we must remove any placement of the user. */
				[c removeMember:nicknameInt];
				
				[c addMember:member];
			}

			break;
		}
		case 366: // RPL_ENDOFNAMES
		{
			NSAssertReturnLoopBreak([m paramsCount] > 1);
			
			NSString *channel = [m paramAt:1];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssertLoopBreak(c);
			
			if (self.inUserInvokedNamesRequest == NO) {
				if ([c numberOfMembers] <= 1) {
					NSString *mode = c.config.defaultModes;

					if (NSObjectIsNotEmpty(m)) {
						[self send:IRCPrivateCommandIndex("mode"), [c name], mode, nil];
					}
				}

				if ([c numberOfMembers] <= 1 && [channel isModeChannelName]) {
					NSString *topic = c.config.defaultTopic;

					if (NSObjectIsNotEmpty(topic)) {
						if ([self encryptOutgoingMessage:&topic channel:c] == YES) {
							[self send:IRCPrivateCommandIndex("topic"), [c name], topic, nil];
						}
					}
				}

				[self send:IRCPrivateCommandIndex("who"), [c name], nil, nil];
			}

			if (self.inUserInvokedNamesRequest) {
				self.inUserInvokedNamesRequest = NO;
			}
            
            [mainWindow() updateTitleFor:c];

			break;
		}
		case 320: // RPL_WHOISSPECIAL
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);
			
			NSString *text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m sequence:2]];

			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 321: // RPL_LISTSTART
		{
            TDCListDialog *channelListDialog = [self listDialog];

			if ( channelListDialog) {
				[channelListDialog clear];
				
				[channelListDialog setContentAlreadyReceived:NO];
			}

			break;
		}
		case 322: // RPL_LIST
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);
			
			NSString *channel = [m paramAt:1];
			NSString *uscount = [m paramAt:2];
			NSString *topicva = [m sequence:3];

            TDCListDialog *channelListDialog = [self listDialog];

			if (channelListDialog) {
				[channelListDialog addChannel:channel count:[uscount integerValue] topic:topicva];
			}

			break;
		}
		case 323: // RPL_LISTEND
		{
			TDCListDialog *channelListDialog = [self listDialog];
			
			if ( channelListDialog) {
				[channelListDialog setContentAlreadyReceived:YES];
			}

			break;
		}
		case 329: // RPL_CREATIONTIME
		case 318: // RPL_ENDOFWHOIS
		{
			break; // Ignored numerics.
		}
		case 330: // RPL_WHOISACCOUNT (ircu)
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			NSString *text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			
			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 367: // RPL_BANLIST
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			NSString *banowner = BLS(1218);
			NSString *settime = BLS(1218);

			BOOL extendedLine = ([m paramsCount] > 5);

			if (extendedLine) {
				banowner = [m paramAt:3];
				settime = [m paramAt:4];

				settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[settime doubleValue]]
														 dateStyle:NSDateFormatterLongStyle
														 timeStyle:NSDateFormatterLongStyle];
			}

            TDChanBanSheet *chanBanListSheet = [menuController() windowFromWindowList:@"TDChanBanSheet"];

            if (chanBanListSheet) {
				if ([chanBanListSheet contentAlreadyReceived]) {
					[chanBanListSheet clear];

					[chanBanListSheet setContentAlreadyReceived:NO];
				}

				[chanBanListSheet addBan:hostmask tset:settime setby:banowner];
			} else {
				NSString *nick = [banowner nicknameFromHostmask];

				NSString *text;

				if (extendedLine) {
					text = TXTLS(@"BasicLanguage[1230][1]", channel, hostmask, nick, settime);
				} else {
					text = TXTLS(@"BasicLanguage[1230][2]", channel, hostmask);
				}
				
				[self print:nil
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 368: // RPL_ENDOFBANLIST
		{
			TDChanBanSheet *chanBanListSheet = [menuController() windowFromWindowList:@"TDChanBanSheet"];

			if (chanBanListSheet) {
				[chanBanListSheet setContentAlreadyReceived:YES];
			} else {
				[self printReply:m];
			}

			break;
		}
		case 346: // RPL_INVITELIST
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			NSString *banowner = BLS(1218);
			NSString *settime = BLS(1218);

			BOOL extendedLine = ([m paramsCount] > 5);

			if (extendedLine) {
				banowner = [m paramAt:3];
				settime = [m paramAt:4];

				settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[settime doubleValue]]
														 dateStyle:NSDateFormatterLongStyle
														 timeStyle:NSDateFormatterLongStyle];
			}

            TDChanInviteExceptionSheet *inviteExceptionSheet = [menuController() windowFromWindowList:@"TDChanInviteExceptionSheet"];

			if (inviteExceptionSheet) {
				if ([inviteExceptionSheet contentAlreadyReceived]) {
					[inviteExceptionSheet clear];

					[inviteExceptionSheet setContentAlreadyReceived:NO];
				}

				[inviteExceptionSheet addException:hostmask tset:settime setby:banowner];
			} else {
				NSString *nick = [banowner nicknameFromHostmask];

				NSString *text;

				if (extendedLine) {
					text = TXTLS(@"BasicLanguage[1231][1]", channel, hostmask, nick, settime);
				} else {
					text = TXTLS(@"BasicLanguage[1231][2]", channel, hostmask);
				}
				
				[self print:nil
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 347: // RPL_ENDOFINVITELIST
		{
			TDChanInviteExceptionSheet *inviteExceptionSheet = [menuController() windowFromWindowList:@"TDChanInviteExceptionSheet"];

			if (inviteExceptionSheet) {
				[inviteExceptionSheet setContentAlreadyReceived:YES];
			} else {
				[self printReply:m];
			}

			break;
		}
		case 348: // RPL_EXCEPTLIST
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			NSString *banowner = BLS(1218);
			NSString *settime = BLS(1218);

			BOOL extendedLine = ([m paramsCount] > 5);

			if (extendedLine) {
				banowner = [m paramAt:3];
				settime = [m paramAt:4];

				settime = [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[settime doubleValue]]
														 dateStyle:NSDateFormatterLongStyle
														 timeStyle:NSDateFormatterLongStyle];
			}

            TDChanBanExceptionSheet *banExceptionSheet = [menuController() windowFromWindowList:@"TDChanBanExceptionSheet"];

			if (banExceptionSheet) {
				if ([banExceptionSheet contentAlreadyReceived]) {
					[banExceptionSheet clear];

					[banExceptionSheet setContentAlreadyReceived:NO];
				}

				[banExceptionSheet addException:hostmask tset:settime setby:banowner];
			} else {
				NSString *nick = [banowner nicknameFromHostmask];

				NSString *text;

				if (extendedLine) {
					text = TXTLS(@"BasicLanguage[1232][1]", channel, hostmask, nick, settime);
				} else {
					text = TXTLS(@"BasicLanguage[1232][2]", channel, hostmask);
				}
				
				[self print:nil
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 349: // RPL_ENDOFEXCEPTLIST
		{
			TDChanBanExceptionSheet *banExceptionSheet = [menuController() windowFromWindowList:@"TDChanBanExceptionSheet"];

			if (banExceptionSheet) {
				[banExceptionSheet setContentAlreadyReceived:YES];
			} else {
				[self printReply:m];
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
				   nickname:nil
				messageBody:BLS(1160, [m senderNickname])
				 receivedAt:[m receivedAt]
					command:[m command]];

				self.hasIRCopAccess = YES;
			}

			break;
		}
		case 328: // RPL_CHANNEL_URL
		{
			NSAssertReturnLoopBreak([m paramsCount] > 2);
			
			NSString *channel = [m paramAt:1];
			NSString *website = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			if (c) {
				if (website) {
					[self print:c
						   type:TVCLogLineWebsiteType
					   nickname:nil
					messageBody:BLS(1126, website)
					 receivedAt:[m receivedAt]
						command:[m command]];
				}
			}

			break;
		}
		case 369: // RPL_ENDOFWHOWAS
		{
			self.inUserInvokedWhowasRequest = NO;

			[self print:[mainWindow() selectedChannelOn:self]
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:[m sequence]
			 receivedAt:[m receivedAt]
				command:[m command]];

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
			NSAssertReturnLoopBreak([m paramsCount] > 5);

			if (self.inUserInvokedWatchRequest) {
				[self printUnknownReply:m];

				return;
			}

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];

			NSString *hostmaskwon = nil; // Hostmask without nickname
			NSString *hostmaskwnn = nil; // Hostmask with nickname

			IRCAddressBookEntry *ignoreChecks = nil;

			if (NSDissimilarObjects(n, 605)) {
				/* 605 does not have the host, but the rest do. */
				hostmaskwon = [NSString stringWithFormat:@"%@@%@", username, address];
				hostmaskwnn = [NSString stringWithFormat:@"%@!%@", nickname, hostmaskwon];

				ignoreChecks = [self checkIgnoreAgainstHostmask:hostmaskwnn withMatches:@[@"notifyJoins"]];
			} else {
				ignoreChecks = [self checkIgnoreAgainstHostmask:[nickname stringByAppendingString:@"!-@-"] withMatches:@[@"notifyJoins"]];
			}

			/* We only continue if there is an actual address book match for the nickname. */
			PointerIsEmptyAssertLoopBreak(ignoreChecks);

			if (n == 600) // logged online
			{
				[self handleUserTrackingNotification:ignoreChecks nickname:nickname langitem:1085];
			}
			else if (n == 601) // logged offline
			{
				[self handleUserTrackingNotification:ignoreChecks nickname:nickname langitem:1084];
			}
			else if (n == 604 || // is online
					 n == 605)   // is offline
			{
				@synchronized(self.trackedUsers) {
					[self.trackedUsers setBool:(n == 604) forKey:[ignoreChecks trackingNickname]];
				}
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
			NSAssertReturnLoopBreak([m paramsCount] == 3);

			NSString *sendern = [m paramAt:1];
			
			[self printDebugInformation:BLS(1171, sendern)];
			
			break;
		}
		case 718:
		{
			NSAssertReturnLoopBreak([m paramsCount] == 4);
			
			NSString *sendern = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			if ([TPCPreferences locationToSendNotices] == TXNoticeSendCurrentChannelType) {
				IRCChannel *c = [mainWindow() selectedChannelOn:self];

				[self printDebugInformation:BLS(1172, sendern, hostmask) channel:c];
			} else {
				[self printDebugInformation:BLS(1172, sendern, hostmask)];
			}

			break;
		}
		case 900: // RPL_LOGGEDIN
		{
			NSAssertReturnLoopBreak([m paramsCount] > 3);

			[self enableCapacity:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL];

			[self print:nil
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:[m sequence:3]
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 903: // RPL_SASLSUCCESS
		case 904: // ERR_SASLFAIL
		case 905: // ERR_SASLTOOLONG
		case 906: // ERR_SASLABORTED
		case 907: // ERR_SASLALREADY
		{
			if (n == 903) { // success
				[self print:nil
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:[m sequence:1]
				 receivedAt:[m receivedAt]
					command:[m command]];
			} else {
				[self printReply:m];
			}

			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIsInSASLNegotiation]) {
				[self disableCapacity:ClientIRCv3SupportedCapacityIsInSASLNegotiation];
				
				[self resumeCap];
			}

			break;
		}
		default:
		{
			NSString *numericString = [NSString stringWithInteger:n];

			if ([[sharedPluginManager() supportedServerInputCommands] containsObject:numericString]) {
				break;
			}

			[self printUnknownReply:m];

			break;
		}
	}
}

- (void)receiveErrorNumericReply:(IRCMessage *)m
{
	NSInteger n = [m numericReply];

	switch (n) {
		case 401: // ERR_NOSUCHNICK
		{
			IRCChannel *c = [self findChannel:[m paramAt:1]];

			if ([c isActive]) {
				[self printErrorReply:m channel:c];
			} else {
				[self printErrorReply:m];
			}

			break;
		}
		case 402: // ERR_NOSUCHSERVER
		{
			NSString *text = BLS(1139, n, [m sequence:1]);
			
			[self print:nil
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 433: // ERR_NICKNAMEINUSE
		case 437: // ERR_NICKCHANGETOOFAST
		{
			if (self.isLoggedIn) {
				[self printUnknownReply:m];

				break;
			}
			
			[self receiveNickCollisionError:m];

			break;
		}
		case 404: // ERR_CANNOTSENDTOCHAN
		{
			NSString *text = BLS(1139, n, [m sequence:2]);

			IRCChannel *c = [self findChannel:[m paramAt:1]];
			
			[self print:c
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:text
			 receivedAt:[m receivedAt]
				command:[m command]];

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
				[c setErrorOnLastJoinAttempt:YES];
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
	if (self.isLoggedIn == NO) {
		NSArray *altNicks = self.config.alternateNicknames;
		
			self.tryingNicknameNumber += 1;
		
		if ([altNicks count] >		  self.tryingNicknameNumber) {
			NSString *nick = altNicks[self.tryingNicknameNumber];

			[self send:IRCPrivateCommandIndex("nick"), nick, nil];
		} else {
			[self tryAnotherNickname];
		}
	}
}

- (void)tryAnotherNickname
{
	NSString *tryingNickname = self.tryingNicknameSentNickname;
	
	const NSInteger nicknameLength = IRCProtocolDefaultNicknameMaximumLength;
	
	if ([tryingNickname length] >= nicknameLength) {
		NSString *nick = [tryingNickname substringToIndex:nicknameLength];

		BOOL found = NO;

		for (NSInteger i = ([nick length] - 1); i >= 0; --i) {
			UniChar c = [nick characterAtIndex:i];
			
			if (NSDissimilarObjects(c, '_')) {
				found = YES;
				
				NSString *head = [nick substringToIndex:i];
				
				NSMutableString *s = [head mutableCopy];
				
				for (NSInteger ii = (nicknameLength - [s length]); ii > 0; --ii) {
					[s appendString:@"_"];
				}
				
				self.tryingNicknameSentNickname = s;
				
				break;
			}
		}
		
		if (found == NO) {
			self.tryingNicknameSentNickname = @"0";
		}
	} else {
		self.tryingNicknameSentNickname = [tryingNickname stringByAppendingString:@"_"];
	}
	
	[self send:IRCPrivateCommandIndex("nick"), self.tryingNicknameSentNickname, nil];
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
	/* Ignore autojoin based on ZNC preferences. */
	if (self.isZNCBouncerConnection && self.config.zncIgnoreConfiguredAutojoin) {
		self.isAutojoined = YES;
		
		return;
	}
	
	/* Do nothing unless certain conditions are met. */
	if ([TPCPreferences autojoinWaitsForNickServ]) {
		if (self.serverHasNickServ && self.isIdentifiedWithNickServ == NO) {
			return;
		}
	}
	
	/* Begin work. */
	@synchronized(self.channels) {
		/* Do nothing with no channels (obviously). */
		if ([self.channels count] < 1) {
			self.isAutojoined = YES;
			
			return;
		}
		
		/* Post status. */
		self.autojoinInProgress = YES;
		
		/* Perform actual autojoin. */
		NSMutableArray *ary = [NSMutableArray array];
		
		for (IRCChannel *c in self.channels) {
			if ([c isChannel]) {
				if ([c isActive] == NO) {
					if (c.config.autoJoin) {
						[ary addObject:c];
					}
				}
			}
		}
		
		[self quickJoin:ary];
		
		/* Update status later. */
		[self performSelector:@selector(updateAutoJoinStatus) withObject:nil afterDelay:15.0];
	}
}

#pragma mark -
#pragma mark Post Events

- (void)postEventToViewController:(NSString *)eventToken
{
    [self.viewController executeScriptCommand:@"handleEvent" withArguments:@[eventToken] onQueue:NO];

	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			[self postEventToViewController:eventToken forChannel:channel];
		}
	}
}

- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel
{
	[[channel viewController] executeScriptCommand:@"handleEvent" withArguments:@[eventToken] onQueue:NO];
}

#pragma mark -
#pragma mark Timers

- (void)startPongTimer
{
	if ( self.pongTimer.timerIsActive == NO) {
		[self.pongTimer start:_pongCheckInterval];
	}
}

- (void)stopPongTimer
{
	if ( self.pongTimer.timerIsActive) {
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
			[self printDebugInformation:BLS(1137, (timeSpent / 60.0)) channel:nil];

			[self disconnect];
		} else if (self.timeoutWarningShownToUser == NO) {
			[self printDebugInformation:BLS(1138, (timeSpent / 60.0)) channel:nil];
			
			self.timeoutWarningShownToUser = YES;
		}
	} else if (timeSpent >= _pingInterval) {
		[self send:IRCPrivateCommandIndex("ping"), [self networkAddress], nil];
	}
}

- (void)startReconnectTimer
{
	if (self.config.autoReconnect) {
		if ( self.reconnectTimer.timerIsActive == NO) {
			[self.reconnectTimer start:_reconnectInterval];
		}
	}
}

- (void)stopReconnectTimer
{
	if ( self.reconnectTimer.timerIsActive) {
		[self.reconnectTimer stop];
	}
}

- (void)onReconnectTimer:(id)sender
{
	if ([self isHostReachable] == NO) {
		/* If the host is not reachable at the time of connect,
		 then inform the user. */
		if (self.config.hideNetworkUnavailabilityNotices == NO) {
			[self printDebugInformationToConsole:BLS(1032, @(_reconnectInterval))];
		}

		/* Restart timer. */
		[self startReconnectTimer];

		return; // Break chain.
	}

	/* Perform actual reconnect attempt. */
	[self connect:IRCClientConnectReconnectMode];
}

- (void)startRetryTimer
{
	if ( self.retryTimer.timerIsActive == NO) {
		[self.retryTimer start:_retryInterval];
	}
}

- (void)stopRetryTimer
{
	if ( self.retryTimer.timerIsActive) {
		[self.retryTimer stop];
	}
}

- (void)onRetryTimer:(id)sender
{
	[self disconnect];
	
	[self connect:IRCClientConnectRetryMode];
}

#pragma mark -
#pragma mark Trial Period Timer

#ifdef TEXTUAL_TRIAL_BINARY

- (void)startTrialPeriodTimer
{
	if ( self.trialPeriodTimer.timerIsActive == NO) {
		[self.trialPeriodTimer start:_trialPeriodInterval];
	}
}

- (void)stopTrialPeriodTimer
{
	if ( self.trialPeriodTimer.timerIsActive) {
		[self.trialPeriodTimer stop];
	}
}

- (void)onTrialPeriodTimer:(id)sender
{
	if (self.isLoggedIn) {
		self.disconnectType = IRCClientDisconnectTrialPeriodMode;

		[self quit];
	}
}

#endif

#pragma mark -
#pragma mark Plugins and Scripts

- (void)outputTextualCmdScriptError:(NSString *)scriptPath input:(NSString *)scriptInput context:(NSDictionary *)userInfo error:(NSError *)originalError
{
	BOOL devmode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];

	NSString *script = [scriptPath lastPathComponent];

	id errord;
	id errorb;

	if (NSObjectIsEmpty(userInfo) && originalError) {
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
		[self printDebugInformation:BLS(1196, script, scriptInput, errord)];
	}

	LogToConsole(BLS(1195), errorb);
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

	[self performBlockOnMainThread:^{
		for (NSAttributedString *s in lines) {
			if ([[s string] hasPrefix:@"/"]) {
				/* We do not have to worry about whether this is an actual command or an escaped one
				 by using double slashes (//) at this point because inputText:command: will do all that
				 hard work for us. We only care if it starts with a slash. */

				[self inputText:s command:IRCPrivateCommandIndex("privmsg")];
			} else {
				/* If there is no destination, then we are fucked. */
				if (NSObjectIsEmpty(destination)) {
					/* Do not send a normal message to the console. What? */
				} else {
					NSString *msgcmd = [NSString stringWithFormat:@"/msg %@ %@", destination, [s string]];

					[self inputText:msgcmd command:IRCPrivateCommandIndex("privmsg")];
				}
			}
		}
	}];
}

- (void)executeTextualCmdScript:(NSDictionary *)details
{
	TXPerformBlockAsynchronouslyOnQueue([sharedPluginManager() dispatchQueue], ^{
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
	NSString *userScriptsPath = [TPCPathInfo systemUnsupervisedScriptFolderPath];

	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
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

		NSURL *filePath = [NSURL fileURLWithPath:scriptPath];
		
		/* /////////////////////////////////////////////////////// */
		/* Execute Event — Mountain Lion, Non-sandboxed Script */
		/* /////////////////////////////////////////////////////// */

		if (MLNonsandboxedScript) {
			NSError *aserror = nil;

			NSUserAppleScriptTask *applescript = [[NSUserAppleScriptTask alloc] initWithURL:filePath error:&aserror];

			if (applescript == nil || aserror) {
				[self outputTextualCmdScriptError:scriptPath input:scriptInput context:[aserror userInfo] error:aserror];
			} else {
				[applescript executeWithAppleEvent:event
								 completionHandler:^(NSAppleEventDescriptor *result, NSError *error)
				{
					 if (result == nil) {
						 [self outputTextualCmdScriptError:scriptPath input:scriptInput context:[error userInfo] error:error];
					 } else {
						 [self postTextualCmdScriptResult:[result stringValue] to:destinationChannel];
					 }
				}];
			}

			return;
		}

		/* /////////////////////////////////////////////////////// */
		/* Execute Event — All Other */
		/* /////////////////////////////////////////////////////// */

		NSDictionary *errors = @{};

		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:filePath error:&errors];

		if (appleScript) {
			NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:&errors];

			if (errors && result == nil) {
				[self outputTextualCmdScriptError:scriptPath input:scriptInput context:errors error:nil];
			} else {
				[self postTextualCmdScriptResult:[result stringValue] to:destinationChannel];
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
		
		/* Build list of arguments. */
		NSMutableArray *arguments = [NSMutableArray array];
		
		if (destinationChannel) {
			[arguments addObject:destinationChannel];
		} else {
			[arguments addObject:[NSNull null]];
		}
		
		[arguments addObjectsFromArray:[scriptInput split:NSStringWhitespacePlaceholder]];

		/* Create task object. */
		NSURL *userScriptURL = [NSURL fileURLWithPath:scriptPath];

		NSError *aserror = nil;
		
		NSUserUnixTask *unixTask = [[NSUserUnixTask alloc] initWithURL:userScriptURL error:&aserror];

		if (unixTask == nil || aserror) {
			[self outputTextualCmdScriptError:scriptPath input:scriptInput context:nil error:aserror];

			return;
		}

		/* Prepare pipe. */
		NSPipe *standardOutputPipe = [NSPipe pipe];
		
		NSFileHandle *writingPipe = [standardOutputPipe fileHandleForWriting];
		NSFileHandle *readingPipe = [standardOutputPipe fileHandleForReading];
		
		[unixTask setStandardOutput:writingPipe];

		/* Try performing task. */
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
	[sharedPluginManager() sendUserInputDataToBundles:self message:message command:command];
}

- (void)processBundlesServerMessage:(IRCMessage *)message
{
	[sharedPluginManager() sendServerInputDataToBundles:self message:message];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:IRCClientConnectNormalMode preferringIPv6:self.config.connectionPrefersIPv6];
}

- (void)connect:(IRCClientConnectMode)mode
{
	[self connect:mode preferringIPv6:self.config.connectionPrefersIPv6];
}

- (void)connect:(IRCClientConnectMode)mode preferringIPv6:(BOOL)preferIPv6
{
	/* Why would we try and connect now? */
	if (self.isQuitting) {
		return;
	}
	
	/* Post event to WebView. */
    [self postEventToViewController:@"serverConnecting"];
	
	/* Stop trying to reconnect. */
	[self stopReconnectTimer];

	/* Establish basic status. */
	self.connectType = mode;
	self.disconnectType = IRCClientDisconnectNormalMode;

	self.isConnecting = YES;
	self.reconnectEnabled = YES;

	/* Begin populating configuration. */
	NSString *socketAddress = nil;

	NSInteger socketPort = IRCConnectionDefaultServerPort;

	/* Do we have a temporary redirect? */
	if (self.serverRedirectAddressTemporaryStore) {
		socketAddress = self.serverRedirectAddressTemporaryStore;
	} else {
		socketAddress = self.config.serverAddress;
	}

	if (self.serverRedirectPortTemporaryStore > 0) {
		socketPort = self.serverRedirectPortTemporaryStore;
	} else {
		socketPort = self.config.serverPort;
	}

	/* Continue connection… */
	[self logFileWriteSessionBegin];

	if (mode == IRCClientConnectReconnectMode) {
		[self printDebugInformationToConsole:BLS(1143)];
	} else if (mode == IRCClientConnectBadSSLCertificateMode) {
		[self printDebugInformationToConsole:BLS(1143)];
	} else if (mode == IRCClientConnectRetryMode) {
		[self printDebugInformationToConsole:BLS(1144)];
	}

	/* Create socket. */
	if (self.socket == nil) {
		self.socket = [IRCConnection new];
		
		self.socket.associatedClient = self;
	}

	/* Begin populating configuration. */
	self.socket.serverAddress = socketAddress;
	self.socket.serverPort = socketPort;

	self.socket.connectionPrefersIPv6 = preferIPv6;
	self.socket.connectionUsesSSL = self.config.connectionUsesSSL;

	if (self.config.proxyType == IRCConnectionSocketSystemSocksProxyType)
	{
		self.socket.connectionUsesSystemSocks = YES;

		[self printDebugInformationToConsole:BLS(1142, socketAddress, socketPort)];
	}
	else if (self.config.proxyType == IRCConnectionSocketSocks4ProxyType ||
			 self.config.proxyType == IRCConnectionSocketSocks5ProxyType)
	{
		self.socket.connectionUsesNormalSocks = YES;
		
		self.socket.proxyPort = self.config.proxyPort;
		self.socket.proxyAddress = self.config.proxyAddress;
		self.socket.proxyPassword = self.config.proxyPassword;
		self.socket.proxyUsername = self.config.proxyUsername;
		self.socket.proxySocksVersion = self.config.proxyType;

		[self printDebugInformationToConsole:BLS(1141, socketAddress, socketPort, self.config.proxyAddress, self.config.proxyPort)];
	}
	else
	{
		[self printDebugInformationToConsole:BLS(1140, socketAddress, socketPort)];
	}

	self.socket.connectionUsesFloodControl = self.config.outgoingFloodControl;

	self.socket.floodControlDelayInterval = self.config.floodControlDelayTimerInterval;
	self.socket.floodControlMaximumMessageCount = self.config.floodControlMaximumMessages;

	/* Try to establish connection. */
	[self.socket open];

	/* Update visible status. */
	[mainWindow() reloadTreeGroup:self];
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

	if ([self isHostReachable]) {
		[self connect:IRCClientConnectReconnectMode];
	} else {
		[self printDebugInformationToConsole:BLS(1031, @(self.connectDelay))];

		[self performSelector:@selector(autoConnectAfterWakeUp) withObject:nil afterDelay:self.connectDelay];
	}
}

- (void)disconnect
{
	/* This does nothing if there was no previous call to performSelector:withObject:afterDelay:
		but is super important to call if there was. */
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];

	if ( self.socket) {
		[self.socket close];
	}

	[self changeStateOff];

	if ([masterController() applicationIsTerminating]) {
		 masterController().terminatingClientCount -= 1;
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
	/* If we are already quitting… derp. */
    if (self.isQuitting) {
        return;
    }
	
	/* If isLoggedIn is NO, then it means that the socket
	 was just opened and we haven't received the welcome 
	 message from the IRCd yet. We do not have to gracefully
	 disconnect at this point. */
	if (self.isLoggedIn == NO) {
		[self disconnect];

		return;
	}

	/* Post status event. */
    [self postEventToViewController:@"serverDisconnecting"];

	/* Update status. */
	self.isQuitting	= YES;
	self.reconnectEnabled = NO;

	/* Clear any existing send operations. */
	[self.socket clearSendQueue];

	/* Send quit message. */
	if (NSObjectIsEmpty(comment)) {
		comment = self.config.normalLeavingComment;
	}

	[self send:IRCPrivateCommandIndex("quit"), comment, nil];

	/* We give it two seconds before forcefully breaking so that the graceful
	 quit with the quit message above can be performed. */
	[self performSelector:@selector(disconnect) withObject:nil afterDelay:2.0];
}

- (void)cancelReconnect
{
	self.reconnectEnabled = NO;
	
	[self stopReconnectTimer];
}

- (void)changeNickname:(NSString *)newNick
{
	if (self.isConnected == NO) {
		return;
	}

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
	
	NSAssertReturn([channel isChannel]);
	NSAssertReturn([channel isActive] == NO);

	[channel setStatus:IRCChannelStatusJoining];

	if (NSObjectIsEmpty(password)) {
		if (channel.config.secretKey) {
			password = [channel secretKey];
		} else {
			password = nil;
		}
	}
	
	[self forceJoinChannel:[channel name] password:password];
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

	NSAssertReturn([channel status] == IRCChannelStatusParted);

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

	NSAssertReturn([channel isChannel]);
	NSAssertReturn([channel isActive]);

	// [channel setStatus:IRCChannelStatusParted];   Let -deactive post change.

	if (NSObjectIsEmpty(comment)) {
		comment = self.config.normalLeavingComment;
	}

	[self send:IRCPrivateCommandIndex("part"), [channel name], comment, nil];
}

- (void)sendWhois:(NSString *)nick
{
	NSAssertReturn(self.isLoggedIn);

	[self send:IRCPrivateCommandIndex("whois"), nick, nick, nil];
}

- (void)kick:(IRCChannel *)channel target:(NSString *)nick
{
	NSAssertReturn(self.isLoggedIn);

	[self send:IRCPrivateCommandIndex("kick"), [channel name], nick, [TPCPreferences defaultKickMessage], nil];
}

- (void)quickJoin:(NSArray *)chans withKeys:(BOOL)passKeys
{
	NSAssertReturn(self.isLoggedIn);

	NSMutableString *channelList = [NSMutableString string];
	NSMutableString *passwordList = [NSMutableString string];

	NSInteger channelCount = 0;

	for (IRCChannel *c in chans) {
		if ([c status] == IRCChannelStatusParted) {
			NSMutableString *previousChannelList = [channelList mutableCopy];
			NSMutableString *previousPasswordList = [passwordList mutableCopy];
			
			BOOL channelListEmpty = NSObjectIsEmpty(channelList);
			BOOL passwordListEmpty = NSObjectIsEmpty(passwordList);
			
			BOOL keyIsSet = c.config.secretKeyIsSet;

			[c setStatus:IRCChannelStatusJoining];

			if (keyIsSet) {
				if (passKeys == NO) {
					continue;
				}
				
				if ( passwordListEmpty == NO) {
					[passwordList appendString:@","];
				}

				[passwordList appendString:[c secretKey]];
			} else {
				if (passKeys) {
					continue;
				}
			}

			if ( channelListEmpty == NO) {
				[channelList appendString:@","];
			}

			[channelList appendString:[c name]];

			if (channelCount > [TPCPreferences autojoinMaxChannelJoins]) {
				/* Send previous lists. */
				if (NSObjectIsEmpty(previousPasswordList)) {
					[self send:IRCPrivateCommandIndex("join"), previousChannelList, nil];
				} else {
					[self send:IRCPrivateCommandIndex("join"), previousChannelList, previousPasswordList, nil];
				}

				[channelList setString:[c name]];

				if (keyIsSet) {
					[passwordList setString:[c secretKey]];
				}

				channelCount = 1; // To match setString: statements up above.
			} else {
				channelCount += 1;
			}
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
    [self toggleAwayStatus:setAway withReason:BLS(1115)];
}

- (void)toggleAwayStatus:(BOOL)setAway withReason:(NSString *)reason
{
	NSAssertReturn(self.isLoggedIn);

    /* Our internal isAway status will be updated by the numeric replies. */
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
		[self changeNickname:newNick];
	}
}


#pragma mark -
#pragma mark File Transfers

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize
{
	NSString *description = nil;
	
	switch (type) {
		case TXNotificationFileTransferSendSuccessfulType:
		{
			description = BLS(1078, filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			description = BLS(1079, filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			description = BLS(1080, filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			description = BLS(1081, filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			description = BLS(1082, filename, totalFilesize);
			
			break;
		}
		default:
		{
			break;
		}
	}
	
	[self notifyEvent:type lineType:0 target:nil nickname:nickname text:description];
}

- (void)receivedDCCQuery:(IRCMessage *)m message:(NSMutableString *)rawMessage ignoreInfo:(IRCAddressBookEntry *)ignoreChecks
{
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		/* Gather inital information. */
		NSString *nickname = [m senderNickname];
		
		/* Only target ourself. */
		if (NSObjectsAreEqual([m paramAt:0], [self localNickname]) == NO) {
			return;
		}
		
		/* Gather basic information. */
		NSString *subcommand = [rawMessage uppercaseGetToken];
		
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
				if ([transferToken length] > 0) {
					/* Validate the transfer token is a number. */
					if ([transferToken isNumericOnly]) {
						/* Is part of reverse DCC request. Let's check if the token
						 already exists somewhere. If it does, we ignore this request. */
						BOOL transferExists = [[self fileTransferController] fileTransferExistsWithToken:transferToken];

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
								TDCFileTransferDialogTransferController *e = [[self fileTransferController] fileTransferSenderMatchingToken:transferToken];

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
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:BLS(1020) command:TVCLogLineDefaultRawCommandValue];
}

- (void)receivedDCCSend:(NSString *)nickname filename:(NSString *)filename address:(NSString *)address port:(NSInteger)port filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	/* Inform of the DCC and possibly ignore it. */
	NSString *message = BLS(1040, nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:message command:TVCLogLineDefaultRawCommandValue];
	
	if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyIgnoreAction) {
		return;
	}
	
	/* Post notification. */
	[self notifyFileTransfer:TXNotificationFileTransferReceiveRequestedType nickname:nickname filename:filename filesize:totalFilesize];
	
	/* Add file. */
	[[self fileTransferController] addReceiverForClient:self
											   nickname:nickname
												address:address
												   port:port
											   filename:filename
											   filesize:totalFilesize
												  token:transferToken];
}

- (void)sendFile:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	/* DCC is mountain lion or later. */
	NSAssertReturn([CSFWSystemInformation featureAvailableToOSXMountainLion]);
	
	/* Build a safe filename. */
	NSString *escapedFileName = [filename stringByReplacingOccurrencesOfString:NSStringWhitespacePlaceholder withString:@"_"];
	
	/* Build the address information. */
	NSString *address = [self DCCTransferAddress];
	
	NSObjectIsEmptyAssert(address);
	
	/* Send file information. */
	NSString *trail;

	if ([transferToken length] > 0) {
		trail = [NSString stringWithFormat:@"%@ %@ %i %qi %@", escapedFileName, address, port, totalFilesize, transferToken];
	} else {
		trail = [NSString stringWithFormat:@"%@ %@ %i %qi", escapedFileName, address, port, totalFilesize];
	}
	
	[self sendCTCPQuery:nickname command:@"DCC SEND" text:trail];
	
	NSString *message = BLS(1039, nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:message command:TVCLogLineDefaultRawCommandValue];
}

- (NSString *)DCCTransferAddress
{
	NSString *address;
	NSString *baseaddr = [[self fileTransferController] cachedIPAddress];
	
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

	@synchronized(self.commandQueue) {
		while ([self.commandQueue count]) {
			TLOTimerCommand *m = self.commandQueue[0];

			if ([m timerInterval] <= now) {
				NSString *target = nil;

				IRCChannel *c = [worldController() findChannelByClientId:[self treeUUID] channelId:[m channelID]];

				if (c) {
					target = [c name];
				}

				[self sendCommand:[m rawInput] completeTarget:YES target:target];

				[self.commandQueue removeObjectAtIndex:0];
			} else {
				break;
			}
		}

		if ([self.commandQueue count]) {
			TLOTimerCommand *m = self.commandQueue[0];

			NSTimeInterval delta = ([m timerInterval] - [NSDate epochTime]);

			[self.commandQueueTimer start:delta];
		} else {
			[self.commandQueueTimer stop];
		}
	}
}

- (void)addCommandToCommandQueue:(TLOTimerCommand *)m
{
	BOOL added = NO;

	NSInteger i = 0;

	@synchronized(self.commandQueue) {
		for (TLOTimerCommand *c in self.commandQueue) {
			if ([m timerInterval] < [c timerInterval]) {
				added = YES;

				[self.commandQueue insertObject:m atIndex:i];

				break;
			}

			++i;
		}

		if (added == NO) {
			[self.commandQueue addObject:m];
		}
	}

	if (i == 0) {
		[self processCommandsInCommandQueue];
	}
}

- (void)clearCommandQueue
{
	[self.commandQueueTimer stop];

	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}
}

- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark User Tracking

- (void)handleUserTrackingNotification:(IRCAddressBookEntry *)ignoreItem
							  nickname:(NSString *)nick
							  langitem:(NSInteger)localKey
{
	if ([ignoreItem notifyJoins]) {
		NSString *text = BLS(localKey, nick);

		[self notifyEvent:TXNotificationAddressBookMatchType lineType:TVCLogLineNoticeType target:nil nickname:nick text:text];
	}
}

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores
{
    NSAssertReturn(self.isLoggedIn);
	
	BOOL useWatchCommand = [self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand];

	BOOL populatingForFirstTime = NO;
	
	if (self.trackedUsers == nil) {
		self.trackedUsers = [NSMutableDictionary new];
		
		populatingForFirstTime = YES;
	}

	/* Create a copy of all old entries. */
	NSMutableDictionary *oldEntriesNicknames = nil;

	if (populatingForFirstTime == NO) {
		oldEntriesNicknames = [NSMutableDictionary dictionary];
		
		@synchronized(self.trackedUsers) {
			for (NSString *lname in self.trackedUsers) {
				oldEntriesNicknames[lname] = self.trackedUsers[lname];
			}
		}
	}

	/* Store for the new entries. */
	NSMutableDictionary *newEntries = [NSMutableDictionary dictionary];

	/* Additions & Removels for WATCH command. ISON does not access these. */
	NSMutableArray *watchAdditions = nil;
	NSMutableArray *watchRemovals = nil;
	
	if (useWatchCommand) {
		watchAdditions = [NSMutableArray array];
		watchRemovals = [NSMutableArray array];
	}

	/* First we go through all the new entries fed to this method and add them. */
	for (IRCAddressBookEntry *g in ignores) {
		if ([g notifyJoins]) {
			NSString *lname = [g trackingNickname];

			if ([lname isNickname]) {
				/* Check if we have a value that already exists. */
				if (populatingForFirstTime == NO) {
					if ([oldEntriesNicknames containsKeyIgnoringCase:lname]) {
						newEntries[lname] = oldEntriesNicknames[lname];
						
						continue; // No need to add when we just did above.
					}
				}
				
				/* Add entry. */
				[newEntries setBool:NO forKey:lname];
				
				if (useWatchCommand) {
					[watchAdditions addObject:lname];
				}
			}
		}
	}

	/* Now that we have an established list of entries that either already
	 existed or are newly added; we now have to go through the old entries
	 and find ones that are not in the new. Those are removals. */
	if (useWatchCommand) {
		if (populatingForFirstTime == NO) {
			for (NSString *lname in oldEntriesNicknames) {
				if ([newEntries containsKeyIgnoringCase:lname]) {
					[watchRemovals addObject:lname];
				}
			}
		}

		/* Send additions. */
		if ([watchAdditions count]) {
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
	@synchronized(self.trackedUsers) {
		[self.trackedUsers removeAllObjects];
		
		[self.trackedUsers addEntriesFromDictionary:newEntries];
	}

    [self startISONTimer];
}

- (void)startISONTimer
{
	if ( self.isonTimer.timerIsActive == NO) {
        [self.isonTimer start:_isonCheckInterval];
    }
}

- (void)stopISONTimer
{
	if ( self.isonTimer.timerIsActive) {
		[self.isonTimer stop];
	}
	
	@synchronized(self.trackedUsers) {
		[self.trackedUsers removeAllObjects];
	}
}

- (void)onISONTimer:(id)sender
{
    NSAssertReturn(self.isLoggedIn);

    NSMutableString *userstr = [NSMutableString string];

	/* Given all channels, we build a list of users if a channel is private message.
	 If a channel is an actual channel and it meets certain conditions, then we send
	 a WHO request here to gather away status information. */
	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify] == NO) {
				if ([channel isChannel]) {
					if ([channel isActive]) {
						if ([channel numberOfMembers] <= [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
							[self send:IRCPrivateCommandIndex("who"), [channel name], nil];
						}
					}
				}
			}

			if ([channel isPrivateMessage]) {
				[userstr appendFormat:@" %@", [channel name]];
			}
		}
	}

	/* If there is no WATCH command, then we populate ISON list. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand] == NO) {
		@synchronized(self.trackedUsers) {
			for (NSString *name in self.trackedUsers) {
				[userstr appendFormat:@" %@", name];
			}
		}
	}

	/* We send a ISON request to track private messages as well as tracked users. */
	NSObjectIsEmptyAssert(userstr);

    [self send:IRCPrivateCommandIndex("ison"), userstr, nil];
}

- (void)checkAddressBookForTrackedUser:(IRCAddressBookEntry *)abEntry inMessage:(IRCMessage *)message
{
    PointerIsEmptyAssert(abEntry);

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand]) {
		return; // Nothing to do here.
	}
	
    NSString *tracker = [abEntry trackingNickname];

	@synchronized(self.trackedUsers) {
		BOOL ison = [self.trackedUsers boolForKey:tracker];
		
		/* Notification Type: JOIN Command. */
		if ([[message command] isEqualIgnoringCase:@"JOIN"]) {
			if (ison == NO) {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] langitem:1085];
				
				[self.trackedUsers setBool:YES forKey:tracker];
			}
			
			return;
		}
		
		/* Notification Type: QUIT Command. */
		if ([[message command] isEqualIgnoringCase:@"QUIT"]) {
			if (ison) {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] langitem:1084];
				
				[self.trackedUsers setBool:NO forKey:tracker];
			}
			
			return;
		}
		
		/* Notification Type: NICK Command. */
		if ([[message command] isEqualIgnoringCase:@"NICK"]) {
			if (ison) {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] langitem:1084];
			} else {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] langitem:1085];
			}
			
			[self.trackedUsers setBool:(ison == NO) forKey:tracker];
		}
	}
}

#pragma mark -
#pragma mark Channel Ban List Dialog

- (void)createChanBanListDialog
{
    [menuController() popWindowSheetIfExists];
    
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    
    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanBanSheet *chanBanListSheet = [TDChanBanSheet new];
	
	[chanBanListSheet setDelegate:self];
	[chanBanListSheet setWindow:mainWindow()];
	
	[chanBanListSheet setClientID:[u uniqueIdentifier]];
	[chanBanListSheet setChannelID:[c uniqueIdentifier]];

	[chanBanListSheet show];

    [menuController() addWindowToWindowList:chanBanListSheet];
}

- (void)chanBanDialogOnUpdate:(TDChanBanSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];

	if (c) {
		[self send:IRCPrivateCommandIndex("mode"), [c name], @"+b", nil];
	}
}

- (void)chanBanDialogWillClose:(TDChanBanSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		NSArray *changedModes = [NSArray arrayWithArray:[sender changeModeList]];
		
		for (NSString *mode in changedModes) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [c name], mode]];
		}
	}

    [menuController() removeWindowFromWindowList:@"TDChanBanSheet"];
}

#pragma mark -
#pragma mark Channel Invite Exception List Dialog

- (void)createChanInviteExceptionListDialog
{
	[menuController() popWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanInviteExceptionSheet *inviteExceptionSheet = [TDChanInviteExceptionSheet new];

	[inviteExceptionSheet setDelegate:self];
	[inviteExceptionSheet setWindow:mainWindow()];
	
	[inviteExceptionSheet setClientID:[u uniqueIdentifier]];
	[inviteExceptionSheet setChannelID:[c uniqueIdentifier]];

    [inviteExceptionSheet show];

    [menuController() addWindowToWindowList:inviteExceptionSheet];
}

- (void)chanInviteExceptionDialogOnUpdate:(TDChanInviteExceptionSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		[self send:IRCPrivateCommandIndex("mode"), [c name], @"+I", nil];
	}
}

- (void)chanInviteExceptionDialogWillClose:(TDChanInviteExceptionSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		NSArray *changedModes = [NSArray arrayWithArray:[sender changeModeList]];
		
		for (NSString *mode in changedModes) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [c name], mode]];
		}
	}
	
    [menuController() removeWindowFromWindowList:@"TDChanInviteExceptionSheet"];
}

#pragma mark -
#pragma mark Chan Ban Exception List Dialog

- (void)createChanBanExceptionListDialog
{
	[menuController() popWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

    TDChanBanExceptionSheet *banExceptionSheet = [TDChanBanExceptionSheet new];

	[banExceptionSheet setDelegate:self];
	[banExceptionSheet setWindow:mainWindow()];
	
	[banExceptionSheet setClientID:[u uniqueIdentifier]];
	[banExceptionSheet setChannelID:[c uniqueIdentifier]];
	[banExceptionSheet show];

    [menuController() addWindowToWindowList:banExceptionSheet];
}

- (void)chanBanExceptionDialogOnUpdate:(TDChanBanExceptionSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		[self send:IRCPrivateCommandIndex("mode"), [c name], @"+e", nil];
	}
}

- (void)chanBanExceptionDialogWillClose:(TDChanBanExceptionSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		NSArray *changedModes = [NSArray arrayWithArray:[sender changeModeList]];
		
		for (NSString *mode in changedModes) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [c name], mode]];
		}
	}
	
    [menuController() removeWindowFromWindowList:@"TDChanBanExceptionSheet"];
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (NSString *)listDialogWindowKey
{
	/* Create a different window so each client can have its own window open. */

	return [NSString stringWithFormat:@"TDCListDialog -> %@", [self uniqueIdentifier]];
}

- (TDCListDialog *)listDialog
{
    return [menuController() windowFromWindowList:[self listDialogWindowKey]];
}

- (void)createChannelListDialog
{
	if ([menuController() popWindowViewIfExists:[self listDialogWindowKey]]) {
		return; // The window was brought forward already.
	}

    TDCListDialog *channelListDialog = [TDCListDialog new];

	[channelListDialog setClientID:[self uniqueIdentifier]];
	
	[channelListDialog setDelegate:self];
    
    [channelListDialog start];

    [menuController() addWindowToWindowList:channelListDialog withKeyValue:[self listDialogWindowKey]];
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
    [menuController() removeWindowFromWindowList:[self listDialogWindowKey]];
}

@end
