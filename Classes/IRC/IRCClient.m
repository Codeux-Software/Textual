/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or Codeux Software, nor the names of
      its contributors may be used to endorse or promote products derived
	  from this software without specific prior written permission.

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

/* A portion of this source file contains copyrighted work derived from one or more
 3rd-party, open source projects. The use of this work is hereby acknowledged. */

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

#import "IRCUserPrivate.h"

#import <objc/message.h>

#define _isonCheckInterval			30
#define _pingInterval				270
#define _pongCheckInterval			30
#define _reconnectInterval			20
#define _retryInterval				240
#define _timeoutInterval			360

enum {
	ClientIRCv3SupportedCapacitySASLGeneric			= 1 << 9,
	ClientIRCv3SupportedCapacitySASLPlainText		= 1 << 10, // YES if SASL=plain CAP is supported.
	ClientIRCv3SupportedCapacitySASLExternal		= 1 << 11, // YES if SASL=external CAP is supported.
	ClientIRCv3SupportedCapacityZNCServerTime		= 1 << 12, // YES if the ZNC vendor specific CAP supported.
	ClientIRCv3SupportedCapacityZNCServerTimeISO	= 1 << 13, // YES if the ZNC vendor specific CAP supported.
};

NSString * const IRCClientConfigurationWasUpdatedNotification = @"IRCClientConfigurationWasUpdatedNotification";
NSString * const IRCClientChannelListWasModifiedNotification = @"IRCClientChannelListWasModifiedNotification";

@interface IRCClient ()
/* These are all considered private. */

@property (nonatomic, strong) IRCConnection *socket;
@property (nonatomic, assign) BOOL isInvokingISONCommandForFirstTime;
@property (nonatomic, assign) BOOL timeoutWarningShownToUser;
@property (nonatomic, assign) BOOL isTerminating; // Is being destroyed
@property (nonatomic, assign) BOOL CAPNegotiationIsPaused;
@property (nonatomic, assign) BOOL reconnectEnabledBecauseOfSleepMode;
@property (nonatomic, assign) BOOL zncBouncerIsPlayingBackHistory;
@property (nonatomic, assign) BOOL zncBoucnerIsSendingCertificateInfo;
@property (nonatomic, assign) NSInteger successfulConnects;
@property (nonatomic, assign) NSInteger tryingNicknameNumber;
@property (nonatomic, assign) NSUInteger lastWhoRequestChannelListIndex;
@property (nonatomic, assign) NSTimeInterval lastLagCheck;
@property (nonatomic, copy) NSString *cachedLocalHostmask;
@property (nonatomic, copy) NSString *cachedLocalNickname;
@property (nonatomic, copy) NSString *tryingNicknameSentNickname;
@property (nonatomic, strong) NSMutableString *zncBouncerCertificateChainDataMutable;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;
@property (nonatomic, assign) ClientIRCv3SupportedCapacities capacitiesPending;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableDictionary *trackedUsers;
@property (nonatomic, weak) IRCChannel *lagCheckDestinationChannel;
@property (nonatomic, strong) IRCMessageBatchMessageContainer *batchMessages;
@property (readonly) BOOL isBrokenIRCd_aka_Twitch;
@end

@implementation IRCClient

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		self.supportInfo = [IRCISupportInfo new];

		self.batchMessages = [IRCMessageBatchMessageContainer new];

		self.connectType = IRCClientConnectNormalMode;
		self.disconnectType = IRCClientDisconnectNormalMode;

		self.inUserInvokedNamesRequest = NO;
		self.inUserInvokedWatchRequest = NO;
		self.inUserInvokedWhoRequest = NO;
		self.inUserInvokedWhowasRequest = NO;
		self.inUserInvokedModeRequest = NO;
		self.inUserInvokedJoinRequest = NO;
		self.inUserInvokedWatchRequest = NO;

		self.CAPNegotiationIsPaused = NO;

		self.capacitiesPending = 0;
		self.capacities = 0;

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
		self.zncBouncerIsPlayingBackHistory = NO;
		self.zncBoucnerIsSendingCertificateInfo = NO;
		self.zncBouncerCertificateChainDataMutable = nil;

		self.autojoinInProgress = NO;
		self.rawModeEnabled = NO;
		self.serverHasNickServ = NO;
		self.timeoutWarningShownToUser = NO;

		self.reconnectEnabled = NO;

		self.cachedHighlights = nil;

		self.lastSelectedChannel = nil;
		
		self.lastWhoRequestChannelListIndex = 0;

		self.lastLagCheck = 0;

		self.cachedLocalHostmask = nil;
		self.cachedLocalNickname = nil;

		self.tryingNicknameSentNickname = nil;
		self.tryingNicknameNumber = -1;

		self.channels = [NSMutableArray array];
		self.commandQueue = [NSMutableArray array];

		self.trackedUsers = [NSMutableDictionary dictionary];

		self.preAwayNickname = nil;

		self.successfulConnects = 0;

		self.lastMessageReceived = 0;

		self.serverRedirectAddressTemporaryStore = nil;
		self.serverRedirectPortTemporaryStore = 0;

		 self.reconnectTimer = [TLOTimer new];
		[self.reconnectTimer setReqeatTimer:YES];
		[self.reconnectTimer setTarget:self];
		[self.reconnectTimer setAction:@selector(onReconnectTimer:)];

		 self.retryTimer = [TLOTimer new];
		[self.retryTimer setReqeatTimer:NO];
		[self.retryTimer setTarget:self];
		[self.retryTimer setAction:@selector(onRetryTimer:)];

		 self.commandQueueTimer = [TLOTimer new];
		[self.commandQueueTimer setReqeatTimer:NO];
		[self.commandQueueTimer setTarget:self];
		[self.commandQueueTimer setAction:@selector(onCommandQueueTimer:)];

		 self.pongTimer = [TLOTimer new];
		[self.pongTimer setReqeatTimer:YES];
		[self.pongTimer setTarget:self];
		[self.pongTimer setAction:@selector(onPongTimer:)];

	  	 self.isonTimer	= [TLOTimer new];
		[self.isonTimer setReqeatTimer:YES];
		[self.isonTimer setTarget:self];
		[self.isonTimer setAction:@selector(onISONTimer:)];
	}
	
	return self;
}

- (void)dealloc
{
	[self.batchMessages clearQueue];

	[self.commandQueueTimer stop];
	[self.isonTimer	stop];
	[self.pongTimer	stop];
	[self.reconnectTimer stop];
	[self.retryTimer stop];

	[self.commandQueueTimer setTarget:nil];
	[self.isonTimer setTarget:nil];
	[self.pongTimer setTarget:nil];
	[self.reconnectTimer setTarget:nil];
	[self.retryTimer setTarget:nil];

	[self cancelPerformRequests];
}

- (void)setup:(id)seed
{
	if (self.config == nil) {
		if ([seed isKindOfClass:[NSDictionary class]]) {
			self.config = [[IRCClientConfig alloc] initWithDictionary:seed];
		} else if ([seed isKindOfClass:[IRCClientConfig class]]) {
			self.config = seed; // Setter will copy.
		} else {
			NSAssert(NO, @"Bad configuration type.");
		}

		[self resetAllPropertyValues];
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCClient [%@]: %@>", [self altNetworkName], [self networkAddress]];
}

- (void)updateConfigFromTheCloud:(IRCClientConfig *)seed
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	BOOL syncToCloudIsSame = (self.config.excludedFromCloudSyncing == [seed excludedFromCloudSyncing]);
#endif

	[self updateConfig:seed withSelectionUpdate:YES isImportingFromCloud:YES];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if (syncToCloudIsSame == NO) {
			if (self.config.excludedFromCloudSyncing == NO) {
				[worldController() cloud_removeClientFromListOfDeletedClients:[self uniqueIdentifier]];
			}
		}
	}
#endif
}

- (void)updateConfig:(IRCClientConfig *)seed
{
	[self updateConfig:seed withSelectionUpdate:YES];
}

- (void)updateConfig:(IRCClientConfig *)seed withSelectionUpdate:(BOOL)reloadSelection
{
	[self updateConfig:seed withSelectionUpdate:reloadSelection isImportingFromCloud:NO];
}

- (void)updateConfig:(IRCClientConfig *)seed withSelectionUpdate:(BOOL)reloadSelection isImportingFromCloud:(BOOL)importingFromCloud
{
	/* Ignore if we have equality. */
	NSAssertReturn([seed isEqualToClientConfiguration:self.config] == NO);
	
	/* Did the ignore list change at all? */
	BOOL ignoreListIsSame = NSObjectsAreEqual(self.config.ignoreList, [seed ignoreList]);
	
	/* Write all channel keychains before copying over new configuration. */
	for (IRCChannelConfig *i in [seed channelList]) {
		[i writeKeychainItemsToDisk];
	}
	
	/* Populate new seed. */
	/* When dealing with an IRCClientConfig instance from iCloud, we populate the existing
	 configuration with its value instead of copying over the new values. There are certain
	 keys stored in IRCClientConfig that are excluded from iCloud. Therefore, the existing 
	 values are populated to merge with the existing configuration. */
	if (importingFromCloud) {
		[self.config populateDictionaryValue:[seed dictionaryValue]];
	} else {
		 self.config = seed; // Setter handles copy.
	}

	/* Begin normal operations. */
	/* List of channels that are in current configuration. */
	NSArray *channelConfigurations = self.config.channelList;
	
	/* List of channels actively particpating with this client. */
	NSMutableArray *originalChannelList = nil;
	
	@synchronized(self.channels) {
		originalChannelList = [NSMutableArray arrayWithArray:self.channels];
	}
	
	/* New list of channels to reflect configuration. */
	NSMutableArray *newChannelList = [NSMutableArray array];

	for (IRCChannelConfig *i in channelConfigurations) {
		/* First we check whether the configured channel 
		 exists in the current context of the client. */
		IRCChannel *cinl = [self findChannel:[i channelName] inList:originalChannelList];

		if (cinl) {
			/* It exists so we update its configuration. */
			[cinl updateConfig:i fireChangedNotification:NO updateStoredChannelList:NO];

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
			[worldController() destroyChannel:c reload:NO];
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

	/* Update navigation list. */
	[menuController() populateNavgiationChannelList];

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
		[mainWindow() setIgnoreOutlineViewSelectionChanges:YES];

		[mainWindowServerList() beginUpdates];
		[mainWindowServerList() reloadItem:self reloadChildren:YES];
		[mainWindowServerList() endUpdates];

		[mainWindow() adjustSelection];

		[mainWindow() setIgnoreOutlineViewSelectionChanges:NO];
	}
	
	/* Update title. */
	[mainWindow() updateTitleFor:self];
	
	/* Post notification. */
	[RZNotificationCenter() postNotificationName:IRCClientConfigurationWasUpdatedNotification object:self];
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

	[RZNotificationCenter() postNotificationName:IRCClientChannelListWasModifiedNotification object:self];
}

- (IRCClientConfig *)copyOfStoredConfig
{
	return [self.config copyWithoutPrivateMessages];
}

- (NSDictionary *)dictionaryValue
{
	return [self.config dictionaryValue:NO];
}

- (NSDictionary *)dictionaryValue:(BOOL)isCloudDictionary
{
	return [self.config dictionaryValue:isCloudDictionary];
}

- (void)prepareForApplicationTermination
{
	self.isTerminating = YES;

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
	self.isTerminating = YES;
	
	[self closeDialogs];
	[self closeLogFile];
	
	[self.config destroyKeychains];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c prepareForPermanentDestruction];
		}
	}

	[[TXSharedApplication sharedInputHistoryManager] destroy:self];
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)closeDialogs
{
	id listDialog = [windowController() windowFromWindowList:[self listDialogWindowKey]];
	
	if (listDialog) {
		[listDialog close];
	}
	
	NSArray *openWindows = [windowController() windowsFromWindowList:@[@"TDChannelInviteSheet",
																	   @"TDCServerChangeNicknameSheet",
																	   @"TDCServerHighlightListSheet",
																	   @"TDCServerPropertiesSheet"]];

	for (id windowObject in openWindows) {
		if (NSObjectsAreEqual([windowObject clientID], [self uniqueIdentifier])) {
			[windowObject cancel:nil];
		}
	}
}

- (void)preferencesChanged
{
	[self reopenLogFileIfNeeded];

	[self.viewController preferencesChanged];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c preferencesChanged];

			[self maybeResetUserAwayStatusForChannel:c];
		}
	}
}

- (void)maybeResetUserAwayStatusForChannel:(IRCChannel *)channel
{
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify] == NO) {
		if ([channel numberOfMembers] > [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
			for (IRCUser *u in [channel memberList]) {
				u.isAway = NO;
			}
		}
	}
}

- (void)willDestroyChannel:(IRCChannel *)channel
{
	if ([channel isPrivateMessage] &&
		[channel isPrivateMessageOwnedByZNC] == NO)
	{
		if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
			[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameWithZNCUserPrefix:@"playback"], @"clear", [channel name], nil];
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
	return self.config.connectionName;
}

- (NSString *)networkName
{
	return self.supportInfo.networkNameFormatted;
}

- (NSString *)altNetworkName
{
	if (NSObjectIsEmpty(self.supportInfo.networkNameFormatted)) {
		return self.config.connectionName;
	} else {
		return self.supportInfo.networkNameFormatted;
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

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (NSString *)encryptionAccountNameForLocalUser
{
	return [sharedEncryptionManager() accountNameWithUser:[self localNickname] onClient:self];
}

- (NSString *)encryptionAccountNameForUser:(NSString *)nickname
{
	return [sharedEncryptionManager() accountNameWithUser:nickname onClient:self];
}
#endif

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

- (void)setLastMessageServerTime:(NSTimeInterval)lastMessageServerTime
{
	self.config.lastMessageServerTime = lastMessageServerTime;

	/* Save configuration periodically so that our timestamp is not lost
	 in the event of a crash (like those never happen). The configuration
	 schemes needs a overhaul so we don't to save the entire world just 
	 for one value. It's like we're putting a cast on a scratch. */
	[worldController() savePeriodically];
}

- (NSTimeInterval)lastMessageServerTime
{
	return self.config.lastMessageServerTime;
}

- (BOOL)connectionIsSecured
{
	if (self.socket) {
		return self.socket.isSecured;
	} else {
		return NO;
	}
}

- (NSData *)zncBouncerCertificateChainData
{
	/* If the data is stll being processed, then return
	 nil so that partial data is not returned. */
	if (self.isZNCBouncerConnection == NO ||
		self.zncBoucnerIsSendingCertificateInfo ||
		self.zncBouncerCertificateChainDataMutable == nil)
	{
		return nil;
	}

	return [self.zncBouncerCertificateChainDataMutable dataUsingEncoding:NSASCIIStringEncoding];
}

- (BOOL)isBrokenIRCd_aka_Twitch
{
	return [self.networkAddress hasSuffix:@".twitch.tv"];
}

#pragma mark -
#pragma mark Highlights

- (void)clearCachedHighlights
{
	@synchronized(self.cachedHighlights) {
		self.cachedHighlights = nil;
	}
}

- (void)cacheHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine lineNumber:(NSString *)lineNumber
{
	PointerIsEmptyAssert(channel);
	PointerIsEmptyAssert(logLine);

	NSObjectIsEmptyAssert(lineNumber);
	
	if ([TPCPreferences logHighlights]) {
		/* Render message. */
		NSString *messageBody = nil;

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
		NSAttributedString *renderedMessage = [messageBody attributedStringWithIRCFormatting:[NSTableView preferredGlobalTableViewFont] preferredFontColor:[NSColor blackColor]];

		IRCHighlightLogEntryMutable *newEntry = [IRCHighlightLogEntryMutable new];

		[newEntry setClientId:[self uniqueIdentifier]];
		[newEntry setChannelId:[channel uniqueIdentifier]];

		[newEntry setLineNumber:lineNumber];

		[newEntry setRenderedMessage:renderedMessage];

		[newEntry setTimeLogged:[NSDate date]];

		/* We insert at head so that latest is always on top. */
		@synchronized(self.cachedHighlights) {
			if (self.cachedHighlights == nil) {
				self.cachedHighlights = @[];
			}

			NSMutableArray *highlightData = [self.cachedHighlights mutableCopy];

			[highlightData insertObject:newEntry atIndex:0];

			self.cachedHighlights = highlightData;
		}
		
		/* Reload table if the window is open. */
		TDCServerHighlightListSheet *highlightSheet = [windowController() windowFromWindowList:@"TDCServerHighlightListSheet"];
		
		if ( highlightSheet) {
			[highlightSheet addEntry:[newEntry copy]];
		}
	}
}

#pragma mark -
#pragma mark Reachability

- (BOOL)isHostReachable
{
	return [[TXSharedApplication sharedNetworkReachabilityNotifier] isReachable];
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
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			channelCount = [self.channels count];
		}
	});
	
	return channelCount;
}

- (void)addChannel:(IRCChannel *)channel
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			if ([channel isChannel] == NO) {
				[self.channels addObjectWithoutDuplication:channel];
			} else {
				NSInteger i = 0;
				
				BOOL completedInsert = NO;
				
				for (IRCChannel *e in self.channels) {
					if ([e isPrivateMessage]) {
						completedInsert = YES;
						
						[self.channels insertObject:channel atIndex:i];
						
						break;
					}
					
					i += 1;
				}
				
				if (completedInsert == NO) {
					[self.channels addObject:channel];
				}
			}
			
			[self updateStoredChannelList];
		}
	});
}

- (void)addChannel:(IRCChannel *)channel atPosition:(NSInteger)pos
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels insertObject:channel atIndex:pos];
			
			[self updateStoredChannelList];
		}
	});
}

- (void)removeChannel:(IRCChannel *)channel
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			[self.channels removeObjectIdenticalTo:channel];
			
			[self updateStoredChannelList];
		}
	});
}

- (NSInteger)indexOfChannel:(IRCChannel *)channel
{
	__block NSInteger i = 0;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			i = [self.channels indexOfObject:channel];
		}
	});
	
	return -1;
}

- (void)selectFirstChannelInChannelList
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
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
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.channels) {
			channelList = [NSArray arrayWithArray:self.channels];
		}
	});
	
	return channelList;
}

- (void)setChannelList:(NSArray *)channelList
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
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
	@synchronized(self.channels) {
		return self.channels[index];
	}
}

- (NSString *)label
{
	return [self.config.connectionName uppercaseString];
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
		LogToConsoleCurrentStackTrace
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
		LogToConsoleCurrentStackTrace
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

	if ([TPCPreferences removeAllFormatting] == NO) {
		raw = [raw stripIRCEffects];
	}

	NSArray *rules = [sharedPluginManager() pluginOutputSuppressionRules];

	for (THOPluginOutputSuppressionRule *ruleData in rules) {
		if ([XRRegularExpression string:raw isMatchedByRegex:[ruleData match]]) {
			if (chan) {
				if (([chan isChannel] && [ruleData restrictChannel]) ||
					([chan isPrivateMessage] && [ruleData restrictPrivateMessage]))
				{
					return YES;
				}
			} else {
				if ([ruleData restrictConsole]) {
					return YES;
				}
			}
		}
	}

	return NO;
}

#pragma mark -
#pragma mark Encryption and Decryption

- (NSDictionary *)listOfNicknamesToDisallowEncryption
{
	/* Add entries as lowercase because thats how they are compared. */
	NSDictionary *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
								  @"IRCClient -> IRCClient List of Nicknames that Encryption Forbids"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		NSDictionary *_blockedNames = [staticValues dictionaryForKey:@"IRCClient List of Nicknames that Encryption Forbids"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"IRCClient -> IRCClient List of Nicknames that Encryption Forbids"];

		cachedValues = _blockedNames;
	}

	return cachedValues;
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (BOOL)encryptionAllowedForNickname:(NSString *)nickname
{
	PointerIsEmptyAssertReturn(nickname, NO)

	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return NO;
	} else if ([nickname isChannelNameOn:self]) { // Do not allow channel names...
		return NO;
	} else if ([[self localNickname] isEqualIgnoringCase:nickname]) { // Do not allow the local user...
		return NO;
	} else if ([self nicknameIsPrivateZNCUser:nickname]) { // Do not allow a ZNC private user...
		return NO;
	} else {
		/* Build context information for lookup */
		NSDictionary *exceptionRules = [self listOfNicknamesToDisallowEncryption];

		NSString *lowercaseNickname = [nickname lowercaseString];

		/* Check network specific rules (such as "X" on UnderNet) */
		NSString *networkName = [[self supportInfo] networkName];

		if (networkName) {
			NSArray *networkSpecificData = [exceptionRules arrayForKey:networkName];

			if (networkSpecificData) {
				if ([networkSpecificData containsObject:lowercaseNickname]) {
					return NO;
				}
			}
		}

		/* Look up rules for all networks */
		NSArray *defaultsData = exceptionRules[@"-default-"];

		if (defaultsData) {
			if ([defaultsData containsObject:lowercaseNickname]) {
				return NO;
			}
		}

		/* Allow the nickname through when there are no rules */
		return YES;
	}
}
#endif

- (NSInteger)lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSInteger)maximumLength
{
	return (-1);
}

- (void)encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user. */
	if ([self encryptionAllowedForNickname:messageTo] == NO) {
#endif
		if (encodingCallback) {
			encodingCallback(messageBody, NO);
		}

		if (injectionCallback) {
			injectionCallback(messageBody);
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		return; // Do not continue with this operation...
	}

	/* Continue with normal encryption operations. */
	[sharedEncryptionManager() encryptMessage:messageBody
										 from:[self encryptionAccountNameForLocalUser]
										   to:[self encryptionAccountNameForUser:messageTo]
							 encodingCallback:encodingCallback
							injectionCallback:injectionCallback];
#endif
}

- (void)decryptMessage:(NSString *)messageBody referenceMessage:(IRCMessage *)referenceMessage decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	NSString *target = [referenceMessage paramAt:0];

	if ([referenceMessage senderIsServer] || [target isChannelNameOn:self]) {
		if (decodingCallback) {
			decodingCallback(messageBody, NO);
		}
	} else {
		[self decryptMessage:messageBody directedAt:[referenceMessage senderNickname] decodingCallback:decodingCallback];
	}
}

- (void)decryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user. */
	if ([self encryptionAllowedForNickname:messageTo] == NO) {
#endif
		if (decodingCallback) {
			decodingCallback(messageBody, NO);
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		return; // Do not continue with this operation...
	}

	/* Continue with normal encryption operations. */
	[sharedEncryptionManager() decryptMessage:messageBody
										 from:[self encryptionAccountNameForUser:messageTo]
										   to:[self encryptionAccountNameForLocalUser]
							 decodingCallback:decodingCallback];
#endif
}

#pragma mark -
#pragma mark Growl

/* Spoken events are only called from within the following calls so we are going to 
 shove the key value matching in here to make it all in one place for management. */
- (NSString *)localizedSpokenMessageForEvent:(TXNotificationType)event
{
#define _dc(event, id)			case (event): {return ((id)); }

	switch (event) {
		_dc(TXNotificationChannelMessageType, @"Notifications[1001]")
		_dc(TXNotificationChannelNoticeType, @"Notifications[1002]")
		_dc(TXNotificationConnectType, @"Notifications[1009]")
		_dc(TXNotificationDisconnectType, @"Notifications[1010]")
		_dc(TXNotificationInviteType, @"Notifications[1004]")
		_dc(TXNotificationKickType, @"Notifications[1005]")
		_dc(TXNotificationNewPrivateMessageType, @"Notifications[1006]")
		_dc(TXNotificationPrivateMessageType, @"Notifications[1007]")
		_dc(TXNotificationPrivateNoticeType, @"Notifications[1008]")
		_dc(TXNotificationHighlightType, @"Notifications[1003]")

		_dc(TXNotificationFileTransferSendSuccessfulType, @"Notifications[1011]")
		_dc(TXNotificationFileTransferReceiveSuccessfulType, @"Notifications[1012]")
		_dc(TXNotificationFileTransferSendFailedType, @"Notifications[1012]")
		_dc(TXNotificationFileTransferReceiveFailedType, @"Notifications[1014]")
		_dc(TXNotificationFileTransferReceiveRequestedType, @"Notifications[1015]")

		default: { break; }
	}

#undef _dc

	return 0;
}

- (void)speakEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text
{
	text = [text trim]; // Do not leave spaces in text to be spoken.

	if ([TPCPreferences removeAllFormatting] == NO) {
		text = [text stripIRCEffects]; // Do not leave formatting in text to be spoken.
	}

	NSString *formattedMessage = nil;
	
	switch (type) {
		case TXNotificationHighlightType:
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		{
			NSObjectIsEmptyAssert(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];
			
			formattedMessage = TXTLS(nformatString, [[target name] channelNameWithoutBang], nick, text);

			break;
		}
		case TXNotificationNewPrivateMessageType:
		case TXNotificationPrivateMessageType:
		case TXNotificationPrivateNoticeType:
		{
			NSObjectIsEmptyAssert(text); // Do not speak empty messages.

			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, nick, text);
			
			break;
		}
		case TXNotificationKickType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, [[target name] channelNameWithoutBang], nick);

			break;
		}
		case TXNotificationInviteType:
		{
			NSString *nformatString = [self localizedSpokenMessageForEvent:type];

			formattedMessage = TXTLS(nformatString, [text channelNameWithoutBang], nick);

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
		if ([TPCPreferences bounceDockIconRepeatedlyForEvent:type]) {
			[NSApp requestUserAttention:NSCriticalRequest];
		} else {
			[NSApp requestUserAttention:NSInformationalRequest];
		}
	}

	if ([sharedGrowlController() areNotificationsDisabled]) {
		return YES;
	}
	
	BOOL onlySpeakEvent = NO;
	
	if ([TPCPreferences postNotificationsWhileInFocus]) {
		if ([mainWindow() isInactive] == NO) {
			if ([mainWindow() isItemSelected:target]) {
				onlySpeakEvent = YES;
			}
		}
	}
	
	if ([sharedGrowlController() areNotificationSoundsDisabled] == NO) {
		if (onlySpeakEvent == NO) {
			[TLOSoundPlayer playAlertSound:[TPCPreferences soundForEvent:type]];
		}
		
		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}
	
	if (onlySpeakEvent) {
		return YES;
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
	NSString *desc = nil;

	if (ltype == TVCLogLineActionType || ltype == TVCLogLineActionNoHighlightType) {
		desc = [NSString stringWithFormat:TXNotificationDialogActionNicknameFormat, nick, text];
	} else {
		nick = [self formatNickname:nick inChannel:target];

		desc = [NSString stringWithFormat:TXNotificationDialogStandardNicknameFormat, nick, text];
	}

	NSDictionary *userInfo = @{@"client" : self.treeUUID, @"channel" : target.treeUUID};
	
	[sharedGrowlController() notify:type title:title description:desc userInfo:userInfo];

	return YES;
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype
{
	return [self notifyEvent:type lineType:ltype target:nil nickname:NSStringEmptyPlaceholder text:NSStringEmptyPlaceholder userInfo:nil];
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text
{
	return [self notifyEvent:type lineType:ltype target:target nickname:nick text:text userInfo:nil];
}

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nickname:(NSString *)nick text:(NSString *)text userInfo:(NSDictionary *)userInfo
{
	if ([self outputRuleMatchedInMessage:text inChannel:target withLineType:ltype] == YES) {
		return NO;
	}
	
	//NSObjectIsEmptyAssertReturn(text, NO);
	//NSObjectIsEmptyAssertReturn(nick, NO);
    
	if ([TPCPreferences bounceDockIconForEvent:type]) {
		if ([TPCPreferences bounceDockIconRepeatedlyForEvent:type]) {
			[NSApp requestUserAttention:NSCriticalRequest];
		} else {
			[NSApp requestUserAttention:NSInformationalRequest];
		}
	}
	
	if ([sharedGrowlController() areNotificationsDisabled]) {
		return YES;
	}
	
	BOOL onlySpeakEvent = NO;
	
	if ([TPCPreferences postNotificationsWhileInFocus]) {
		if ([mainWindow() isInactive] == NO) {
			if ([mainWindow() isItemSelected:target]) {
				onlySpeakEvent = YES;
			}
		}
	}
	
	if ([sharedGrowlController() areNotificationSoundsDisabled] == NO) {
		if (onlySpeakEvent == NO) {
			[TLOSoundPlayer playAlertSound:[TPCPreferences soundForEvent:type]];
		}
	
		if ([TPCPreferences speakEvent:type]) {
			[self speakEvent:type lineType:ltype target:target nick:nick text:text];
		}
	}

	if (onlySpeakEvent) {
		return YES;
	}
	
	if ([TPCPreferences growlEnabledForEvent:type] == NO) {
		return YES;
	}
	
	if ([TPCPreferences postNotificationsWhileInFocus]) {
		if ([mainWindow() isInactive] == NO) {
			if ([mainWindow() isItemSelected:target]) {
				return YES;
			}
		}
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
	
	if (userInfo) {
		info = userInfo;
	} else {
		if (target) {
			info = @{@"client": self.treeUUID, @"channel": target.treeUUID};
		} else {
			info = @{@"client": self.treeUUID};
		}
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
			
			desc = TXTLS(@"Notifications[1035]", nick, text);

			break;
		}
		case TXNotificationInviteType:
		{
			title = [self altNetworkName];
			
			desc = TXTLS(@"Notifications[1034]", nick, text);

			break;
		}
		default: { return YES; }
	}

	[sharedGrowlController() notify:type title:title description:desc userInfo:info];
	
	return YES;
}

#pragma mark -
#pragma mark ZNC Bouncer Accessories

- (BOOL)nicknameIsPrivateZNCUser:(NSString *)nickname
{
	if ([self isZNCBouncerConnection]) {
		NSString *prefix = [[self supportInfo] privateMessageNicknamePrefix];
		
		if (prefix == nil) {
			return [nickname hasPrefix:@"*"];
		} else {
			return [nickname hasPrefix:prefix];
		}
	} else {
		return NO;
	}
}

- (NSString *)nicknameWithZNCUserPrefix:(NSString *)nickname
{
	NSString *prefix = [[self supportInfo] privateMessageNicknamePrefix];
	
	if (prefix == nil) {
		return [@"*" stringByAppendingString:nickname];
	} else {
		return [prefix stringByAppendingString:nickname];
	}
}

- (BOOL)isSafeToPostNotificationForMessage:(IRCMessage *)m inChannel:(IRCChannel *)channel
{
	PointerIsEmptyAssertReturn(m, NO);
	PointerIsEmptyAssertReturn(channel, NO);

	if (self.config.zncIgnoreUserNotifications) {
		if ([self nicknameIsPrivateZNCUser:[channel name]]) {
			return NO;
		}
	}

	if (self.config.zncIgnorePlaybackNotifications == NO) {
		return YES;
	}

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityBatch] == NO) {
		return (self.isZNCBouncerConnection == NO || [m isHistoric] == NO);
	}

	return ( self.isZNCBouncerConnection == NO ||
			(self.isZNCBouncerConnection && self.zncBouncerIsPlayingBackHistory == NO));
}

#pragma mark -
#pragma mark Channel States

- (void)setKeywordState:(IRCChannel *)t
{
	BOOL isActiveWindow = [mainWindow() isKeyWindow];

	if ([mainWindow() isItemSelected:t] == NO || isActiveWindow == NO) {
		t.nicknameHighlightCount += 1;

		[TVCDockIcon updateDockIcon];
		
		[mainWindow() reloadTreeItem:t];
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
		if ([mainWindow() isItemSelected:t] == NO || isActiveWindow == NO) {
			t.dockUnreadCount += 1;
			
			[TVCDockIcon updateDockIcon];
		}
	}

	if (isActiveWindow == NO || ([mainWindow() isItemSelected:t] == NO && isActiveWindow)) {
		t.treeUnreadCount += 1;

		if (t.config.showTreeBadgeCount || (t.config.showTreeBadgeCount == NO && isHighlight)) {
			[mainWindowServerList() updateMessageCountForItem:t];
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
		[self printDebugInformationToConsole:TXTLS(@"IRC[1005]")];

		return;
	}

	[self.socket sendLine:str];

	worldController().messagesSent += 1;
	worldController().bandwidthOut += [str length];
}

- (void)send:(NSString *)str arguments:(NSArray *)arguments
{
	NSString *s = [IRCSendingMessage stringWithCommand:str arguments:arguments];

	NSObjectIsEmptyAssert(s);

	[self sendLine:s];
}

- (void)send:(NSString *)str, ...
{
	NSMutableArray *arguments = [NSMutableArray array];

	id obj;

	va_list args;
	va_start(args, str);

	while ((obj = va_arg(args, id))) {
		[arguments addObject:obj];
	}

	va_end(args);

	[self send:str arguments:arguments];
}

#pragma mark -
#pragma mark Sending Text

- (void)inputText:(id)str command:(NSString *)command
{
	[self inputText:str command:command destination:[mainWindow() selectedItem]];
}

- (void)inputText:(id)str command:(NSString *)command destination:(IRCTreeItem *)destination
{
	PointerIsEmptyAssert(destination);

	NSObjectIsEmptyAssert(str);
	NSObjectIsEmptyAssert(command);

	if ([str isKindOfClass:[NSString class]]) {
		str = [NSAttributedString attributedStringWithString:str];
	}

	NSArray *lines = [str performSelector:@selector(splitIntoLines)];

	/* Warn if the split value is above 4 lines or if the total string 
	 length exceeds TXMaximumIRCBodyLength times 4. */
	if ([lines count] > 4 || ([str length] > (TXMaximumIRCBodyLength * 4))) {
		BOOL continueInput = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1108][2]")
																title:TXTLS(@"Prompts[1108][1]")
														defaultButton:TXTLS(@"Prompts[0001]")
													  alternateButton:TXTLS(@"Prompts[0002]")
													   suppressionKey:@"input_text_possible_flood_warning"
													  suppressionText:nil];

		if (continueInput == NO) {
			return;
		}
	}

	for (__strong NSAttributedString *s in lines) {
		NSRange chopRange = NSMakeRange(1, ([s length] - 1));

		if ([destination isClient]) {
			if ([[s string] hasPrefix:@"/"]) {
				if ([s length] > 1) {
					s = [s attributedSubstringFromRange:chopRange];
					
					[self sendCommand:s];
				}
			} else {
				[self sendCommand:s];
			}
		} else {
			IRCChannel *channel = (IRCChannel *)destination;

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

	TVCLogLineType type = TVCLogLineUndefinedType;

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
			NSString *unencryptedMessage = [NSAttributedString attributedStringToASCIIFormatting:&strc withClient:self channel:channel lineType:type];

			TLOEncryptionManagerEncodingDecodingCallbackBlock encryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
				[self print:channel
					   type:type
				   nickname:[self localNickname]
				messageBody:originalString
				isEncrypted:wasEncrypted
				 receivedAt:[NSDate date]
					command:commandActual];
			};

			TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
				NSString *sendCommand = command;

				NSString *sendMessage = encodedString;

				if (type == TVCLogLineActionType) {
					sendCommand = IRCPrivateCommandIndex("privmsg");

					sendMessage = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), sendMessage, 0x01];
				}

				[self send:sendCommand, [channel name], sendMessage, nil];
			};

			if (encryptChat == NO) {
				encryptionBlock(unencryptedMessage, NO);

				injectionBlock(unencryptedMessage);
			} else {
				[self encryptMessage:unencryptedMessage directedAt:[channel name] encodingCallback:encryptionBlock injectionCallback:injectionBlock];
			}
		}
	}
	
	[self processBundlesUserMessage:[str string] command:NSStringEmptyPlaceholder];
}

- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			   command:IRCPrivateCommandIndex("privmsg")
			   channel:channel];
	}];
}

- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			   command:IRCPrivateCommandIndex("action")
			   channel:channel];
	}];
}

- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			   command:IRCPrivateCommandIndex("notice")
			   channel:channel];
	}];
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			   command:IRCPrivateCommandIndex("privmsg")
			   channel:[mainWindow() selectedChannelOn:self]];
	}];
}

- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSObjectIsEmptyAssert(target);
	NSObjectIsEmptyAssert(command);

	TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
		NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, encodedString, 0x01];

		[self send:IRCPrivateCommandIndex("privmsg"), target, message, nil];
	};

	NSString *trail = nil;

	if (NSObjectIsEmpty(text)) {
		trail = command;
	} else {
		trail = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	injectionBlock(trail);
}

- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text
{
	NSObjectIsEmptyAssert(target);
	NSObjectIsEmptyAssert(command);

	TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
		NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, encodedString, 0x01];

		[self send:IRCPrivateCommandIndex("notice"), target, message, nil];
	};

	NSString *trail = nil;

	if (NSObjectIsEmpty(text)) {
		trail = command;
	} else {
		trail = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	injectionBlock(trail);
}

- (void)sendCTCPPing:(NSString *)target
{
	[self sendCTCPQuery:target
				command:IRCPrivateCommandIndex("ctcp_ping")
				   text:[NSString stringWithFormat:@"%f", [NSDate unixTime]]];
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

	NSInteger n = [IRCCommandIndex indexOfIRCommand:uppercaseCommand publicSearch:YES];

	switch (n) {
		case 5101: // Command: AUTOJOIN
		{
			[self performAutoJoin:YES];

			break;
		}
		case 5004: // Command: AWAY
		{
			if (NSObjectIsEmpty(uncutInput)) {
                uncutInput = TXTLS(@"IRC[1031]");
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

			NSArray *nicks = [uncutInput componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if (NSObjectIsNotEmpty(nicks) && [[nicks lastObject] isChannelNameOn:self]) {
				targetChannelName = [nicks lastObject];

				NSMutableArray *nicksMutable = [nicks mutableCopy];

				[nicksMutable removeLastObject];

				nicks = nicksMutable;
			} else if (selChannel && [selChannel isChannel]) {
				targetChannelName = [selChannel name];
			} else {
				return;
			}

			for (NSString *nick in nicks) {
				if ([nick isHostmaskNicknameOn:self] && [nick isChannelNameOn:self] == NO) {
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

				if ([targetChannelName isChannelNameOn:self] == NO && [targetChannelName isEqualToString:@"0"] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}

			[self enableInUserInvokedCommandProperty:&_inUserInvokedJoinRequest];

			[self send:IRCPrivateCommandIndex("join"), targetChannelName, [s string], nil];

			break;
		}
		case 5033: // Command: KICK
		{
			NSObjectIsEmptyAssert(uncutInput);
				
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelNameOn:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelNameOn:self]);

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
			NSString *destinationPrefix = nil;
			
			BOOL secretMessage = NO;
            BOOL doNotEncrypt = NO;

			TVCLogLineType type = TVCLogLinePrivateMessageType;

			/* Command Type. */
			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("msg")]) {
				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("smsg")]) {
				secretMessage = YES;

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("omsg")]) {
				destinationPrefix = [self.supportInfo userModePrefixSymbolWithMode:@"o"];

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("umsg")]) {
				doNotEncrypt = YES;

				type = TVCLogLinePrivateMessageType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("notice")]) {
				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("onotice")]) {
				destinationPrefix = [self.supportInfo userModePrefixSymbolWithMode:@"o"];

				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("unotice")]) {
				doNotEncrypt = YES;

				type = TVCLogLineNoticeType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("me")]) {
				type = TVCLogLineActionType;
			} else if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("sme")]) {
				secretMessage = YES;

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
			if (selChannel && type == TVCLogLineActionType && secretMessage == NO) {
				targetChannelName = [selChannel name];
			} else if (selChannel && [selChannel isChannel] && [[s string] isChannelNameOn:self] == NO && destinationPrefix) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			if (type == TVCLogLineActionType) {
				if (NSObjectIsEmpty(s)) {
					/* If the input is empty, then set one space character as our input
					 when using the /me command so that the use of /me without any input
					 still sends an action. */

					s = [NSMutableAttributedString mutableAttributedStringWithString:NSStringWhitespacePlaceholder attributes:nil];
				}
			} else {
				NSObjectIsEmptyAssert(s);
			}
			
			NSObjectIsEmptyAssert(targetChannelName);
			
			NSArray *userModePrefixes = [self.supportInfo userModePrefixes];

			NSString *validTargetPrefixes = [self.supportInfo channelNamePrefixes];

			NSArray *targets = [targetChannelName componentsSeparatedByString:@","];

			IRCChannel *channelToSelect = nil;

			for (NSString *target in targets) {
				NSString *destinationChannelName = target;

				for (NSArray *prefixData in userModePrefixes) {
					NSString *symbol = prefixData[1];

					if ([destinationChannelName hasPrefix:symbol]) {
						NSString *nch = [destinationChannelName stringCharacterAtIndex:1];

						if ([validTargetPrefixes contains:nch]) {
							destinationPrefix = symbol;

							destinationChannelName = [destinationChannelName substringFromIndex:1];
						}

						break;
					}
				}

				IRCChannel *channel = [self findChannel:destinationChannelName];

				if (secretMessage == NO) {
					if (channel == nil) {
						if ([destinationChannelName isChannelNameOn:self] == NO) {
							channel = [worldController() createPrivateMessage:destinationChannelName client:self];
						}
					}

					if ([TPCPreferences giveFocusOnMessageCommand]) {
						if (channelToSelect == nil) {
							channelToSelect = channel;
						}
					}
				}

				NSMutableAttributedString *strCopy = [s mutableCopy];

				while ([strCopy length] > 0)
				{
					NSString *unencryptedMessage = [NSAttributedString attributedStringToASCIIFormatting:&strCopy withClient:self channel:channel lineType:type];

					TLOEncryptionManagerEncodingDecodingCallbackBlock encryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
						if (channel) {
							[self print:channel
								   type:type
							   nickname:[self localNickname]
							messageBody:originalString
							isEncrypted:wasEncrypted
							 receivedAt:[NSDate date]
								command:uppercaseCommand];
						}
					};

					TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
						NSString *sendCommand = uppercaseCommand;

						NSString *sendChannelName = destinationChannelName;

						NSString *sendMessage = encodedString;

						if ([sendChannelName isChannelNameOn:self]) {
							if (destinationPrefix) {
								sendChannelName = [destinationPrefix stringByAppendingString:sendChannelName];
							}
						}

						if (type == TVCLogLineActionType) {
							sendMessage = [NSString stringWithFormat:@"%C%@ %@%C", 0x01, IRCPrivateCommandIndex("action"), sendMessage, 0x01];
						}

						[self send:sendCommand, sendChannelName, sendMessage, nil];
					};

					if (channel == nil || doNotEncrypt) {
						encryptionBlock(unencryptedMessage, NO);

						injectionBlock(unencryptedMessage);
					} else {
						[self encryptMessage:unencryptedMessage directedAt:[channel name] encodingCallback:encryptionBlock injectionCallback:injectionBlock];
					}
				}
			}

			if (channelToSelect) {
				[mainWindow() select:channelToSelect];
			}

			break;
		}
		case 5054: // Command: PART
		case 5036: // Command: LEAVE
		{
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelNameOn:self] == NO) {
				targetChannelName = [selChannel name];
			} else if (selChannel && [selChannel isPrivateMessage] && [uncutInput isChannelNameOn:self] == NO) {
				[worldController() destroyChannel:selChannel];

				return;
			} else {
				NSObjectIsEmptyAssert(uncutInput);
				
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelNameOn:self]);

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
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelNameOn:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelNameOn:self]);

			NSString *topic = [s attributedStringToASCIIFormatting];

			if (NSObjectIsEmpty(topic)) {
				[self send:IRCPrivateCommandIndex("topic"), targetChannelName, nil];
			} else {
				[self send:IRCPrivateCommandIndex("topic"), targetChannelName, topic, nil];
			}

			break;
		}
		case 5079: // Command: WHO
		{
			NSObjectIsEmptyAssert(uncutInput);

			[self enableInUserInvokedCommandProperty:&_inUserInvokedWhoRequest];

			[self send:IRCPrivateCommandIndex("who"), uncutInput, nil];

			break;
		}
		case 5100: // Command: ISON
		{
			[self enableInUserInvokedCommandProperty:&_inUserInvokedIsonRequest];
			
			[self send:IRCPrivateCommandIndex("ison"), uncutInput, nil];
			
			break;
		}
		case 5077: // Command: WALLOPS
		{
			[self send:IRCPrivateCommandIndex("wallops"), uncutInput, nil];
			
			break;
		}
		case 5097: // Command: WATCH
		{
			[self enableInUserInvokedCommandProperty:&_inUserInvokedWatchRequest];

			[self send:IRCPrivateCommandIndex("watch"), nil];

			break;
		}
		case 5094: // Command: NAMES
		{
			NSObjectIsEmptyAssert(uncutInput);

			[self enableInUserInvokedCommandProperty:&_inUserInvokedNamesRequest];

			[self send:IRCPrivateCommandIndex("names"), uncutInput, nil];

			break;
		}
		case 5080: // Command: WHOIS
		{
			NSString *nickname1 = [s getTokenAsString];
			NSString *nickname2 = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname1)) {
				if ([selChannel isPrivateMessage]) {
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
			
			if (selChannel && [selChannel isChannel] && [uncutInput isChannelNameOn:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelNameOn:self]);

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
					[self printDebugInformation:TXTLS(@"IRC[1021]")];

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
				[s insertAttributedString:[NSAttributedString attributedStringWithString:NSStringWhitespacePlaceholder]	atIndex:0];
				[s insertAttributedString:[NSAttributedString attributedStringWithString:[self localNickname]]			atIndex:0];
			} else {
				if (selChannel && [selChannel isChannel] && [[s string] isModeChannelName] == NO) {
					targetChannelName = [selChannel name];
				} else {
					targetChannelName = [s getTokenAsString];
				}

				NSString *sign = nil;

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

				[s setAttributedString:[NSAttributedString attributedStringWithString:ms]];
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
					
					if ([targetChannelName isChannelNameOn:self]) {
						[self enableInUserInvokedCommandProperty:&_inUserInvokedModeRequest];
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
			BOOL isIgnoreCommand = [uppercaseCommand isEqualToString:IRCPublicCommandIndex("ignore")];
			
			if (NSObjectIsEmpty(uncutInput) || PointerIsEmpty(selChannel)) {
				if (isIgnoreCommand) {
					[menuController() showServerPropertyDialog:self withDefaultView:TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection andContext:nil];
				} else {
					[menuController() showServerPropertyDialog:self withDefaultView:TDCServerPropertiesSheetAddressBookNavigationSelection andContext:nil];
				}
			} else {
				NSString *nickname = [s getTokenAsString];
				
				IRCUser *user = [selChannel findMember:nickname];
				
				if (user == nil) {
					if (isIgnoreCommand) {
						[menuController() showServerPropertyDialog:self withDefaultView:TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection andContext:nickname];
					} else {
						[menuController() showServerPropertyDialog:self withDefaultView:TDCServerPropertiesSheetAddressBookNavigationSelection andContext:nil];
					}
					
					return;
				}
				
				IRCAddressBookEntry *g = [IRCAddressBookEntry new];
				
				[g setHostmask:[user banMask]];

				[g setIgnoreClientToClientProtocol:YES];
				[g setIgnoreGeneralEventMessages:YES];
				[g setIgnoreFileTransferRequests:YES];
				[g setIgnoreMessagesContainingMatchh:NO];
				[g setIgnoreNoticeMessages:YES];
				[g setIgnorePrivateMessageHighlights:YES];
				[g setIgnorePrivateMessages:YES];
				[g setIgnorePublicMessageHighlights:YES];
				[g setIgnorePublicMessages:YES];

				[g setTrackUserActivity:NO];
				
				if (isIgnoreCommand) {
					BOOL found = NO;
					
					for (IRCAddressBookEntry *e in self.config.ignoreList) {
						if (NSObjectsAreEqual([g hostmask], [e hostmask])) {
							found = YES;
							
							break;
						}
					}
					
					if (found == NO) {
						@synchronized(self.config.ignoreList) {
							self.config.ignoreList = [self.config.ignoreList arrayByAddingObject:g];
						}
					}
				} else {
					for (IRCAddressBookEntry *e in self.config.ignoreList) {
						if ([[g hostmask] isEqualToString:[e hostmask]]) {
							@synchronized(self.config.ignoreList) {
								NSMutableArray *newArray = [self.config.ignoreList mutableCopy];
								
								[newArray removeObject:e];
								
								self.config.ignoreList = newArray;
							}
							
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

			for (IRCClient *client in [worldController() clientList]) {
				[client sendLine:uncutInput];
			}

			break;
		}
		case 5056: // Command: QUERY
		{
			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsNotEmpty(nickname)) {
				if ([nickname isChannelNameOn:self] == NO && [nickname isHostmaskNicknameOn:self]) {
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
					[cmd setChannelID:[selChannel uniqueIdentifier]];
				} else {
					[cmd setChannelID:nil];
				}
				
				[cmd setRawInput:[s string]];
				
				[cmd setTimerInterval:([NSDate unixTime] + interval)];

				[self addCommandToCommandQueue:cmd];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1090]")];
			}

			break;
		}
		case 5022: // Command: ECHO
		case 5018: // Command: DEBUG
		{
			NSObjectIsEmptyAssert(uncutInput);
			
			if ([uncutInput isEqualIgnoringCase:@"raw on"]) {
				self.rawModeEnabled = YES;

				[RZWorkspace() launchApplication:@"Console"];

				[self printDebugInformation:TXTLS(@"IRC[1092]")];

				LogToConsole(@"%@", TXTLS(@"IRC[1094]"));
			} else if ([uncutInput isEqualIgnoringCase:@"raw off"]) {
				self.rawModeEnabled = NO;

				[self printDebugInformation:TXTLS(@"IRC[1091]")];

				LogToConsole(@"%@", TXTLS(@"IRC[1093]"));
			} else if ([uncutInput isEqualIgnoringCase:@"devmode on"]) {
				[TPCPreferences setDeveloperModeEnabled:YES];
			} else if ([uncutInput isEqualIgnoringCase:@"devmode off"]) {
				[TPCPreferences setDeveloperModeEnabled:NO];
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
		case 5002: // Command: AME
		{
			NSObjectIsEmptyAssert(uncutInput);

			NSString *command = nil;

			if (n == 5003) {
				command = IRCPrivateCommandIndex("privmsg");
			} else {
				command = IRCPrivateCommandIndex("action");
			}

			if ([TPCPreferences amsgAllConnections])
			{
				for (IRCClient *client in [worldController() clientList]) {
                    if ([client isConnected] == NO) {
						continue;
					}

					for (IRCChannel *channel in [client channelList]) {
						if ([channel isActive] == NO || [channel isChannel] == NO) {
							continue;
						}

						[client setUnreadState:channel];
							
						[client sendText:s command:command channel:channel];
					}
				}
			}
			else
			{
				@synchronized(self.channels) {
					for (IRCChannel *channel in self.channels) {
						if ([channel isActive] == NO || [channel isChannel] == NO) {
							continue;
						}

						[self setUnreadState:channel];
					
						[self sendText:s command:command channel:channel];
					}
				}
			}

			break;
		}
		case 5083: // Command: KB
		case 5034: // Command: KICKBAN
		{
			NSObjectIsEmptyAssert(uncutInput);

			if (selChannel && [selChannel isChannel] && [uncutInput isChannelNameOn:self] == NO) {
				targetChannelName = [selChannel name];
			} else {
				targetChannelName = [s getTokenAsString];
			}

			NSAssertReturn([targetChannelName isChannelNameOn:self]);

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
			
			NSString *reason = [s trimmedString];
			
			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences defaultKickMessage];
			}

			[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"+b", banmask, nil];
			[self send:IRCPrivateCommandIndex("kick"), targetChannelName, nickname, reason, nil];

			break;
		}
		case 5028: // Command: ICBADGE
		{
			NSArray *data = [uncutInput componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if ([data count] < 2) {
				return;
			}

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
				NSString *serverAddress = [s getTokenAsString];

				if ([serverAddress isValidInternetAddress] == NO) {
					LogToConsole(@"Silently ignoring bad server address");

					return;
				}

				self.serverRedirectAddressTemporaryStore = serverAddress;
			}
			
			if (self.isConnected) {
				__weak IRCClient *weakSelf = self;
				
				self.disconnectCallback = ^{
					[weakSelf connect];
				};
				
				[self quit];
			} else {
				[self connect];
			}

			break;
		}
		case 5046: // Command: MYVERSION
		{
			NSString *name = [TPCApplicationInfo applicationName];
			NSString *versionLong = [TPCApplicationInfo applicationVersion];
			NSString *versionShort = [TPCApplicationInfo applicationVersionShort];
			NSString *buildScheme = [TPCApplicationInfo applicationBuildScheme];

			NSString *downloadSource = nil;

			if ([buildScheme isEqualToString:@"appstore"]) {
				downloadSource = TXTLS(@"IRC[1028]");
			} else {
				downloadSource = TXTLS(@"IRC[1029]");
			}

			NSString *text = TXTLS(@"IRC[1027]", name, versionShort, versionLong, downloadSource);

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:text];
			} else {
				text = TXTLS(@"IRC[1030]", text);

				[self sendPrivmsg:text toChannel:selChannel];
			}

			break;
		}
		case 5044: // Command: MUTE
		{
			if ([sharedGrowlController() areNotificationSoundsDisabled]) {
				[self printDebugInformation:TXTLS(@"IRC[1097]")];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1100]")];
				
				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOnState];
			}

			break;
		}
		case 5075: // Command: UNMUTE
		{
			if ([sharedGrowlController() areNotificationSoundsDisabled]) {
				[self printDebugInformation:TXTLS(@"IRC[1098]")];
				
				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOffState];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1099]")];
			}

			break;
		}
		case 5093: // Command: TAGE
		{
			/* Textual Age — Developr mode only. */

			NSTimeInterval timeDiff = [NSDate secondsSinceUnixTimestamp:TXBirthdayReferenceDate];

			NSString *message = TXTLS(@"IRC[1101]", TXHumanReadableTimeInterval(timeDiff, NO, 0));

			if (PointerIsEmpty(selChannel)) {
				[self printDebugInformationToConsole:message];
			} else {
				[self sendPrivmsg:message toChannel:selChannel];
			}
			
			break;
		}
		case 5084: // Command: LAGCHECK
		case 5045: // Command: MYLAG
		{
			self.lastLagCheck = [NSDate unixTime];

			if ([uppercaseCommand isEqualIgnoringCase:IRCPublicCommandIndex("mylag")]) {
				self.lagCheckDestinationChannel = [mainWindow() selectedChannelOn:self];
			}

			[self sendCTCPQuery:[self localNickname] command:IRCPrivateCommandIndex("ctcp_lagcheck") text:[NSString stringWithDouble:self.lastLagCheck]];

			[self printDebugInformation:TXTLS(@"IRC[1023]")];

			break;
		}
		case 5082: // Command: ZLINE
		case 5023: // Command: GLINE
		case 5025: // Command: GZLINE
		{
			BOOL appendReason = [TPCPreferences appendReasonToCommonIRCopCommands];

			if (appendReason == NO) {
				[self send:uppercaseCommand, [s string], nil];

				return;
			}

			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname)) {
				[self send:uppercaseCommand, [s string], nil];

				return;
			} else if ([nickname hasPrefix:@"-"]) {
				[self send:uppercaseCommand, nickname, [s string], nil];

				return;
			}

			NSString *gltime = [s getTokenAsString];
			NSString *reason = [s trimmedString];

			if (NSObjectIsEmpty(reason)) {
				reason = [TPCPreferences IRCopDefaultGlineMessage];

				/* Remove the time from our default reason. */
				NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

				if (spacePos > 0) {
					if (NSObjectIsEmpty(gltime)) {
						gltime = [reason substringToIndex:spacePos];
					}

					reason = [reason substringAfterIndex:spacePos];
				}
			}

			[self send:uppercaseCommand, nickname, gltime, reason, nil];

			break;
		}
		case 5063:  // Command: SHUN
		case 5068: // Command: TEMPSHUN
		{
			BOOL appendReason = [TPCPreferences appendReasonToCommonIRCopCommands];

			if (appendReason == NO) {
				[self send:uppercaseCommand, [s string], nil];

				return;
			}

			NSString *nickname = [s getTokenAsString];

			if (NSObjectIsEmpty(nickname)) {
				[self send:uppercaseCommand, [s string], nil];

				return;
			} else if ([nickname hasPrefix:@"-"]) {
				[self send:uppercaseCommand, nickname, [s string], nil];

				return;
			}

			if ([uppercaseCommand isEqualToString:IRCPublicCommandIndex("tempshun")]) {
				NSString *reason = [s trimmedString];

				if (NSObjectIsEmpty(reason)) {
					reason = [TPCPreferences IRCopDefaultShunMessage];

					/* Remove the time from our default reason. */
					NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

					if (spacePos > 0) {
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
					NSInteger spacePos = [reason stringPosition:NSStringWhitespacePlaceholder];

					if (spacePos > 0) {
						if (NSObjectIsEmpty(shtime)) {
							shtime = [reason substringToIndex:spacePos];
						}

						reason = [reason substringAfterIndex:spacePos];
					}
				}

				[self send:uppercaseCommand, nickname, shtime, reason, nil];
			}

			break;
		}
		case 5006: // Command: CAP
		case 5007: // Command: CAPS
		{
			NSString *caps = [self enabledCapacitiesStringValue];
			
			if (NSObjectIsNotEmpty(caps)) {
				[self printDebugInformation:TXTLS(@"IRC[1037]", caps)];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1036]")];
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
		case 5066: // Command: SSLCONTEXT
		{
			[self presentCertificateTrustInformation];

			break;
		}
		case 5087: // Command: FAKERAWDATA
		{
			[self ircConnectionDidReceive:[s string]];

			break;
		}
		case 5098: // Command: GETSCRIPTS
		{
			[sharedPluginManager() extrasInstallerLaunchInstaller];
			
			break;
		}
		case 5099: // Command: GOTO
		{
			NSObjectIsEmptyAssert(uncutInput);

			IRCTreeItem *bestMatch = [mainWindow() selectedItem];

			CGFloat bestScore = 0.0;

			for (IRCClient *client in [worldController() clientList]) {
				for (IRCChannel *channel in [client channelList]) {
					CGFloat score = [[channel name] compareWithWord:uncutInput lengthPenaltyWeight:0.1];

					if (score > bestScore) {
						bestMatch = channel;
						
						bestScore = score;
					}
				}
			}

			[mainWindow() select:bestMatch];

			break;
		}
		case 5092: // Command: DEFAULTS
		{
			/* Check base string. */
			if (NSObjectIsEmpty(uncutInput)) {
				[self printDebugInformation:TXTLS(@"IRC[1012]")];

				break;
			}

			/* Begin processing input. */
			NSString *section1 = [s getTokenAsString];
			
			NSString *section2 = [[s getTokenIncludingQuotes] string];
			NSString *section3 = [[s getTokenIncludingQuotes] string];

			BOOL applyToAll = NSObjectsAreEqual(section2, @"-a");

			NSDictionary *providedKeys = @{
				@"Ignore Notifications by Private ZNC Users"			: @"setZncIgnoreUserNotifications:",
				@"Send Authentication Requests to UserServ"				: @"setSendAuthenticationRequestsToUserServ:",
				@"Hide Network Unavailability Notices on Reconnect"		: @"setHideNetworkUnavailabilityNotices:",
				@"SASL Authentication Uses External Mechanism"			: @"setSaslAuthenticationUsesExternalMechanism:",
				@"Send WHO Command Requests to Channels"				: @"setSendWhoCommandRequestsToChannels:",
			};
			
			void (^applyKey)(IRCClient *, NSString *, BOOL) = ^(IRCClient *client, NSString *valueKey, BOOL valueValue) {
				SEL selectorActl = NSSelectorFromString(providedKeys[valueKey]);
				
				objc_msgSend([client config], selectorActl, valueValue);
			};
				
			if (NSObjectsAreEqual(section1, @"help"))
			{
				[self printDebugInformation:TXTLS(@"IRC[1013][01]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][02]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][03]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][04]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][05]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][06]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][07]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][08]")];
			}
			else if (NSObjectsAreEqual(section1, @"features"))
			{
				[TLOpenLink openWithString:@"https://help.codeux.com/textual/Command-Reference.kb#cr=defaults"];
			}
			else if (NSObjectsAreEqual(section1, @"enable"))
			{
				if ((applyToAll == NO && NSObjectIsEmpty(section2)) ||
					(applyToAll		  && NSObjectIsEmpty(section3)))
				{
					[self printDebugInformation:TXTLS(@"IRC[1012]")];
				} else {
					if ((applyToAll == NO && [providedKeys containsKey:section2] == NO) ||
						(applyToAll		  && [providedKeys containsKey:section3] == NO))
					{
						if (applyToAll) {
							[self printDebugInformation:TXTLS(@"IRC[1014]", section3)];
						} else {
							[self printDebugInformation:TXTLS(@"IRC[1014]", section2)];
						}
					} else {
						if (applyToAll) {
							for (IRCClient *uu in [worldController() clientList]) {
								applyKey(uu, section3, YES);

								if (uu == self) {
									[uu printDebugInformation:TXTLS(@"IRC[1016]", section3)];
								} else {
									[uu printDebugInformationToConsole:TXTLS(@"IRC[1016]", section3)];
								}
							}
						} else {
							applyKey(self, section2, YES);

							[self printDebugInformation:TXTLS(@"IRC[1016]", section2)];
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
					[self printDebugInformation:TXTLS(@"IRC[1012]")];
				} else {
					if ((applyToAll == NO && [providedKeys containsKey:section2] == NO) ||
						(applyToAll		  && [providedKeys containsKey:section3] == NO))
					{
						if (applyToAll) {
							[self printDebugInformation:TXTLS(@"IRC[1015]", section3)];
						} else {
							[self printDebugInformation:TXTLS(@"IRC[1015]", section2)];
						}
					} else {
						if (applyToAll) {
							for (IRCClient *uu in [worldController() clientList]) {
								applyKey(uu, section3, NO);

								if (uu == self) {
									[uu printDebugInformation:TXTLS(@"IRC[1017]", section3)];
								} else {
									[uu printDebugInformationToConsole:TXTLS(@"IRC[1017]", section3)];
								}
							}
						} else {
							applyKey(self, section2, NO);

							[self printDebugInformation:TXTLS(@"IRC[1017]", section2)];
						}

						[worldController() save];
					}
				}
			}

			break;
		}
		case 5103: // Command: SETCOLOR
		{
			NSObjectIsEmptyAssert(uncutInput);

			if ([TPCPreferences disableNicknameColorHashing]) {
				[self printDebugInformation:TXTLS(@"IRC[1108]")];

				return;
			}

			if ([TPCPreferences nicknameColorHashingComputesRGBValue] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1109]")];

				return;
			}

			if ([themeSettings() nicknameColorStyle] == TPCThemeSettingsNicknameColorLegacyStyle) {
				[self printDebugInformation:TXTLS(@"IRC[1111]")];

				return;
			}

			NSString *nickname = [[s getTokenAsString] lowercaseString];

			if ([nickname isChannelNameOn:self] || [nickname isHostmaskNicknameOn:self] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1110]", nickname)];

				return;
			}

			[menuController() memberChangeColor:nickname];

			break;
		}
		default:
		{
			/* Find an addon responsible for this command. */
			NSString *scriptPath = nil;
			
			BOOL pluginFound = NO;
			BOOL scriptFound = NO;

			BOOL commandIsReserved = NO;

			[sharedPluginManager() findHandlerForOutgoingCommand:lowercaseCommand path:&scriptPath isReserved:&commandIsReserved isScript:&scriptFound isExtension:&pluginFound];

			if (commandIsReserved) {
				[sharedPluginManager() extrasInstallerAskUserIfTheyWantToInstallCommand:lowercaseCommand];
			}

			/* Perform script or plugin. */
			if (pluginFound && scriptFound) {
				LogToConsole(@"%@", TXTLS(@"IRC[1001]", uppercaseCommand))
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
							@"channel"			: NSDictionaryNilValueSubstitue([selChannel name], NSStringEmptyPlaceholder),
							@"target"			: NSDictionaryNilValueSubstitue(targetChannelName, NSStringEmptyPlaceholder)
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
	NSString *localization = nil;

	if (newSession) {
		localization = @"IRC[1095]";
	} else {
		localization = @"IRC[1096]";
	}

	TVCLogLine *topLine = [TVCLogLine new];
	TVCLogLine *middleLine = [TVCLogLine new];
	TVCLogLine *bottomLine = [TVCLogLine new];

	[topLine setMessageBody:NSStringWhitespacePlaceholder];
	[middleLine setMessageBody:TXTLS(localization)];
	[bottomLine setMessageBody:NSStringWhitespacePlaceholder];

	[self writeToLogFile:topLine];
	[self writeToLogFile:middleLine];
	[self writeToLogFile:bottomLine];
	
	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			[channel writeToLogFile:topLine];
			[channel writeToLogFile:middleLine];
			[channel writeToLogFile:bottomLine];
		}
	}

	topLine = nil;
	middleLine = nil;
	bottomLine = nil;
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

- (NSString *)formatNickname:(NSString *)nickname inChannel:(IRCChannel *)channel
{
	return [self formatNickname:nickname inChannel:channel withFormat:nil];
}

- (NSString *)formatNickname:(NSString *)nickname inChannel:(IRCChannel *)channel withFormat:(NSString *)format
{
	/* Validate input. */
	NSObjectIsEmptyAssertReturn(nickname, nil);

	PointerIsEmptyAssertReturn(channel, nil);

	/* Define default formats. */
	if (NSObjectIsEmpty(format)) {
		format = [themeSettings() themeNicknameFormat];
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeNicknameFormat];
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeNicknameFormatDefault];
	}

	/* Find mark character. */
	NSString *mark = NSStringEmptyPlaceholder;

	if ([channel isChannel]) {
		IRCUser *m = [channel findMember:nickname];

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

	NSScanner *scanner = [NSScanner scannerWithString:format];

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
			oValue = nickname; // Actual nickname.
		} else if ([scanner scanString:formatMarker intoString:nil] == YES) {
			oValue = formatMarker; // Format marker.
		}

		if (oValue) {
			/* Check math and perform final append. */
			if (width < 0 && ABS(width) > [oValue length]) {
				[buffer appendString:[NSStringEmptyPlaceholder stringByPaddingToLength:(ABS(width) - [oValue length]) withString:NSStringWhitespacePlaceholder startingAtIndex:0]];
			}

			[buffer appendString:oValue];

			if (width > 0 && width > [oValue length]) {
				[buffer appendString:[NSStringEmptyPlaceholder stringByPaddingToLength:(width - [oValue length]) withString:NSStringWhitespacePlaceholder startingAtIndex:0]];
			}
		}
	}

	return [NSString stringWithString:buffer];
}

- (void)printAndLog:(TVCLogLine *)line completionBlock:(IRCClientPrintToWebViewCompletionBlock)completionBlock
{
	[self.viewController print:line completionBlock:completionBlock];
	
	[self writeToLogFile:line];
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
	NSString *text = TXTLS(@"IRC[1055]", [m commandNumeric], [m sequence]);

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
	self.zncBouncerIsPlayingBackHistory = NO;
	self.zncBoucnerIsSendingCertificateInfo = NO;
	self.zncBouncerCertificateChainDataMutable = nil;
	
	self.autojoinInProgress = NO;
	self.rawModeEnabled = NO;
	self.serverHasNickServ = NO;
	self.timeoutWarningShownToUser = NO;

	self.reconnectEnabled = NO;

	self.lagCheckDestinationChannel = nil;
	
	self.lastLagCheck = 0;
	
	self.lastWhoRequestChannelListIndex = 0;
	
	self.cachedLocalHostmask = nil;
	self.cachedLocalNickname = self.config.nickname;
	
	self.tryingNicknameSentNickname = self.config.nickname;
	self.tryingNicknameNumber = -1;
	
	self.preAwayNickname = nil;
	
	self.lastMessageReceived = 0;

	self.CAPNegotiationIsPaused = NO;
	
	self.capacitiesPending = 0;
	self.capacities = 0;

	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}
}

- (void)changeStateOff
{
	self.socket = nil;
	
	[self stopPongTimer];
	[self stopRetryTimer];
	[self stopISONTimer];

	[self cancelPerformRequests];

	[self.printingQueue cancelAllOperations];

	if (self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	[self.supportInfo reset];

	static NSDictionary *disconnectMessages = nil;
	
	if (disconnectMessages == nil) {
		disconnectMessages = @{
			@(IRCClientDisconnectNormalMode) :				@"IRC[1052]",
			@(IRCClientDisconnectComputerSleepMode) :		@"IRC[1048]",
			@(IRCClientDisconnectBadSSLCertificateMode) :	@"IRC[1050]",
			@(IRCClientDisconnectServerRedirectMode) :		@"IRC[1049]",
			@(IRCClientDisconnectReachabilityChangeMode) :	@"IRC[1051]"
		};
	}
	
	NSString *disconnectMessageToken = disconnectMessages[@(self.disconnectType)];

	NSString *disconnectMessage = TXTLS(disconnectMessageToken);

	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c isActive]) {
				[c deactivate];

				[self printDebugInformation:disconnectMessage channel:c];
			} else {
				[c setErrorOnLastJoinAttempt:NO];
			}
		}
	}

	[self.viewController mark];
	
	[self printDebugInformationToConsole:disconnectMessage];

	if (self.isConnected) {
		[self notifyEvent:TXNotificationDisconnectType lineType:TVCLogLineDebugType];
	}

	[self logFileWriteSessionEnd];
	
	[self resetAllPropertyValues];

	[mainWindow() reloadTreeGroup:self];
	[mainWindow() updateTitleFor:self];
}

- (void)ircConnectionWillConnectToProxy:(NSString *)proxyHost port:(NSInteger)proxyPort
{
	if (self.socket.proxyType == IRCConnectionSocketSocks4ProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1057]", proxyHost, proxyPort)];
	} else if (self.socket.proxyType == IRCConnectionSocketSocks5ProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1058]", proxyHost, proxyPort)];
	} else if (self.socket.proxyType == IRCConnectionSocketHTTPProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1059]", proxyHost, proxyPort)];
	}
}

- (void)ircConnectionDidReceivedAnInsecureCertificate
{
	[self setDisconnectType:IRCClientDisconnectBadSSLCertificateMode];
}

- (void)ircConnectionDidSecureConnection
{
	NSString *sslProtocolString = [self.socket localizedSecureConnectionProtocolString:NO];

	if (sslProtocolString) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1047]", sslProtocolString)];
	}
}

- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	if ([self isTerminating]) {
		return; // No reason to show this.
	}
	
	[self startRetryTimer];

	/* If the address we are connecting to is not an IP address,
	 then we report back the actual IP address it was resolved to. */
	NSString *connectedAddress = [self.socket connectedAddress];

	if (connectedAddress == nil || [self.socket.serverAddress isIPAddress]) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1045]")];
	} else {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1046]", connectedAddress)];
	}

	self.isLoggedIn	= NO;
	self.isConnected = YES;
	self.isConnecting = NO;

	self.cachedLocalNickname = self.config.nickname;
	
	self.tryingNicknameSentNickname = self.config.nickname;

	[self.supportInfo reset];

	NSString *username = self.config.username;
	NSString *realname = self.config.realName;
	
	NSString *modeParam = @"0";
	
	NSString *serverPassword = self.config.serverPassword;

	if (self.config.setInvisibleModeOnConnect) {
		modeParam = @"8";
	}

	if (NSObjectIsEmpty(username)) {
		username = self.config.nickname;
	}

	if (NSObjectIsEmpty(realname)) {
		realname = self.config.nickname;
	}

	[self send:IRCPrivateCommandIndex("cap"), @"LS", @"302", nil];

	if (NSObjectIsNotEmpty(serverPassword)) {
		[self send:IRCPrivateCommandIndex("pass"), serverPassword, nil];
	}

	[self send:IRCPrivateCommandIndex("nick"), self.tryingNicknameSentNickname, nil];
	[self send:IRCPrivateCommandIndex("user"), username, modeParam, @"*", realname, nil];
}

#pragma mark -

- (void)ircConnectionDidDisconnect:(IRCConnection *)sender withError:(NSError *)distcError
{
	if ([self isTerminating] == NO) {
		XRPerformBlockAsynchronouslyOnMainQueue(^{
			[self _disconnect];
			
			if (self.disconnectCallback) {
				self.disconnectCallback();
				self.disconnectCallback = nil;
			}
		});
	}
}

#pragma mark -

- (void)ircConnectionDidError:(NSString *)error
{
	if ([self isTerminating]) {
		return; // No reason to show this.
	}
	
	[self printError:error forCommand:TVCLogLineDefaultRawCommandValue];
}

- (void)ircConnectionDidReceive:(NSString *)data
{
	if ([self isTerminating]) {
		return; // No reason to show this.
	}
	
	NSAssertReturn(self.isConnected);
	NSAssertReturn(self.isQuitting == NO);

	NSString *s = data;

	self.lastMessageReceived = [NSDate unixTime];

	NSObjectIsEmptyAssert(s);

	worldController().messagesReceived += 1;
	worldController().bandwidthIn += [s length];

	[self logToConsoleIncomingTraffic:s];

	if ([TPCPreferences removeAllFormatting]) {
		s = [s stripIRCEffects];
	}

	IRCMessage *m = [IRCMessage new];

	[m parseLine:s forClient:self];
	
	PointerIsEmptyAssert([m params]);

	m = [THOPluginDispatcher interceptServerInput:m for:self];

    PointerIsEmptyAssert(m);

	if ([self filterBatchCommandIncomingData:m] == NO) {
		[self processIncomingData:m];
	}
}

- (void)processIncomingData:(IRCMessage *)m
{
	/* Keep track of the server time of the last seen message. */
	if (self.isLoggedIn) {
		if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityServerTime]) {
			if ([m isHistoric]) {
				NSTimeInterval serverTime = [[m receivedAt] timeIntervalSince1970];
				
				if (serverTime > self.lastMessageServerTime) {
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
	}

	if ([m commandNumeric] > 0) {
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

				NSString *text = params[1];

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

					if ([m senderIsServer]) {
						if ([@"irc.znc.in" isEqualToString:[m senderNickname]]) {
							self.isZNCBouncerConnection = YES;

							DebugLogToConsole(@"ZNC based connection detected...");
						}
					}
				}
				
				[self receiveCapacityOrAuthenticationRequest:m];
				
				break;
			}
            case 1050: // Command: AWAY (away-notify CAP)
            {
                [self receiveAwayNotifyCapacity:m];

				break;
            }
			case 1054: // BATCH
			{
				[self receiveBatch:m];

				break;
			}
			case 1055: // CERTINFO
			{
				[self receiveCertInfo:m];

				break;
			}
		}
	}

	[self processBundlesServerMessage:m];
}

- (void)ircConnectionWillSend:(NSString *)line
{
	if ([self isTerminating]) {
		return; // No reason to show this.
	}
	
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
	NSArray *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
							 @"IRCClient -> IRCClient List of NickServ Needs Identification Tokens"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		NSArray *_blockedNames = [staticValues arrayForKey:@"IRCClient List of NickServ Needs Identification Tokens"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"IRCClient -> IRCClient List of NickServ Needs Identification Tokens"];

		cachedValues = _blockedNames;
	}

	return cachedValues;
}

- (NSArray *)nickServSupportedSuccessfulIdentificationTokens
{
	NSArray *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
							 @"IRCClient -> IRCClient List of NickServ Successfully Identified Tokens"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		NSArray *_blockedNames = [staticValues arrayForKey:@"IRCClient List of NickServ Successfully Identified Tokens"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"IRCClient -> IRCClient List of NickServ Successfully Identified Tokens"];

		cachedValues = _blockedNames;
	}

	return cachedValues;
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

	TVCLogLineType lineType = TVCLogLineUndefinedType;

	if ([text hasPrefix:@"\x01"]) {
		text = [text substringFromIndex:1];

		NSInteger n = [text stringPosition:@"\x01"];

		if (n >= 0) {
			text = [text substringToIndex:n];
		}

		if ([[m command] isEqualToString:IRCPrivateCommandIndex("privmsg")]) {
			if ([text hasPrefixIgnoringCase:@"ACTION "]) {
				text = [text substringFromIndex:7];

				lineType = TVCLogLineActionType;
			} else {
				lineType = TVCLogLineCTCPQueryType;
			}
		} else {
			lineType = TVCLogLineCTCPReplyType;
		}
	} else {
		lineType = TVCLogLinePrivateMessageType; // could be notice too, just a placeholder
	}

	TLOEncryptionManagerEncodingDecodingCallbackBlock decryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
		if (lineType == TVCLogLinePrivateMessageType) {
			[self receiveText:m command:[m command] text:originalString wasEncrypted:wasEncrypted];
		} else if (lineType == TVCLogLineActionType) {
			[self receiveText:m command:IRCPrivateCommandIndex("action") text:originalString wasEncrypted:wasEncrypted];
		} else if (lineType == TVCLogLineCTCPQueryType) {
			[self receiveCTCPQuery:m text:originalString wasEncrypted:wasEncrypted];
		} else if (lineType == TVCLogLineCTCPReplyType) {
			[self receiveCTCPReply:m text:originalString wasEncrypted:wasEncrypted];
		}
	};

	[self decryptMessage:text referenceMessage:m decodingCallback:decryptionBlock];
}

- (void)receiveText:(IRCMessage *)referenceMessage command:(NSString *)command text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSAssertReturn([referenceMessage paramsCount] > 0);

	NSObjectIsEmptyAssert(command);

	TVCLogLineType type = TVCLogLineUndefinedType;

	if ([command isEqualToString:IRCPrivateCommandIndex("notice")]) {
		type = TVCLogLineNoticeType;
	} else if ([command isEqualToString:IRCPrivateCommandIndex("action")]) {
		type = TVCLogLineActionType;
	} else {
		type = TVCLogLinePrivateMessageType;
	}

	if (type == TVCLogLineActionType) {
		if (NSObjectIsEmpty(text)) {
			text = NSStringWhitespacePlaceholder;
		}
	} else {
		NSObjectIsEmptyAssert(text);
	}

	NSString *sender = [referenceMessage senderNickname];

	NSString *target = [referenceMessage paramAt:0];

	/* Operator message? */
	if ([target length] > 1) {
		/* This logic has to deal with use cases where different symbols would
		 be used for channels instead of being confused about the channel named
		 "+channel" and thinking it is being addressed to all users in the channel
		 named "channel" with a +, we must take this into account. */
		NSArray *userModePrefixes = [self.supportInfo userModePrefixes];

		for (NSArray *prefixData in userModePrefixes) {
			NSString *symbol = prefixData[1];

			if ([target hasPrefix:symbol]) {
				/* We detected a possible prefix match. At this point, we scan ahead
				 and see the next character in our sequence. If the next character is a
				 known channel name prefix, then we count this mode prefix as valid. */
				/* As we are always checking for a prefix, the next character is index 1 */
				NSString *nch = [target stringCharacterAtIndex:1];

				NSString *validTargetPrefixes = [self.supportInfo channelNamePrefixes];

				if ([validTargetPrefixes contains:nch]) {
					target = [target substringFromIndex:1];
				}

				break;
			}
		}
	}

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[referenceMessage senderHostmask]
															 withMatches:@[	IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey,
																			IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey,
																			IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey,
																			IRCAddressBookDictionaryValueIgnorePublicMessagesKey,
																			IRCAddressBookDictionaryValueIgnorePrivateMessagesKey	]];


	/* Ignore highlights? */
	if ([ignoreChecks ignorePublicMessageHighlights] == YES) {
		if (type == TVCLogLineActionType) {
			type = TVCLogLineActionNoHighlightType;
		} else if (type == TVCLogLinePrivateMessageType) {
			type = TVCLogLinePrivateMessageNoHighlightType;
		}
	}

	if (type == TVCLogLineNoticeType) {
		if ([ignoreChecks ignoreNoticeMessages]) {
			return;
		}
	}

	if ([target isChannelNameOn:self]) {
		if ([ignoreChecks ignorePublicMessages]) {
			return;
		}

		[self processPublicMessageComponents:type sender:sender command:command target:target text:text referenceMessage:referenceMessage wasEncrypted:wasEncrypted];
	} else {
		if ([referenceMessage senderIsServer]) {
			if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
				BOOL pluginResult = [THOPluginDispatcher receivedText:text
														   authoredBy:[referenceMessage sender]
														  destinedFor:nil
														   asLineType:type
															 onClient:self
														   receivedAt:[referenceMessage receivedAt]
														 wasEncrypted:wasEncrypted];

				if (pluginResult == NO) {
					return;
				}
			}

			[self print:nil type:type nickname:nil messageBody:text receivedAt:[referenceMessage receivedAt] command:[referenceMessage command]];
		} else {
			if ([ignoreChecks ignorePrivateMessages]) {
				return;
			}

			[self processPrivateMessageComponents:type sender:sender command:command target:target text:text referenceMessage:referenceMessage wasEncrypted:wasEncrypted];
		}
	}
}

- (void)processPublicMessageComponents:(TVCLogLineType)type sender:(NSString *)sender command:(NSString *)command target:(NSString *)target text:(NSString *)text referenceMessage:(IRCMessage *)referenceMessage wasEncrypted:(BOOL)wasEncrypted
{
	/* Does the target exist? */
	IRCChannel *c = [self findChannel:target];

	PointerIsEmptyAssert(c);

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
		BOOL pluginResult = [THOPluginDispatcher receivedText:text
												   authoredBy:[referenceMessage sender]
												  destinedFor:c
												   asLineType:type
													 onClient:self
												   receivedAt:[referenceMessage receivedAt]
												 wasEncrypted:wasEncrypted];

		if (pluginResult == NO) {
			return;
		}
	}

	if (type == TVCLogLineNoticeType) {
		[self print:c
			   type:type
		   nickname:sender
		messageBody:text
		isEncrypted:wasEncrypted
		 receivedAt:[referenceMessage receivedAt]
			command:[referenceMessage command]
   referenceMessage:referenceMessage];

		if ([self isSafeToPostNotificationForMessage:referenceMessage inChannel:c]) {
			[self notifyText:TXNotificationChannelNoticeType lineType:type target:c nickname:sender text:text];
		}
	} else {
		[self printToWebView:c
						type:type
					 command:[referenceMessage command]
					nickname:sender
				 messageBody:text
				 isEncrypted:NO
				  receivedAt:[referenceMessage receivedAt]
			referenceMessage:referenceMessage
			 completionBlock:^(BOOL isHighlight)
		 {
			 if ([self isSafeToPostNotificationForMessage:referenceMessage inChannel:c]) {
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

- (void)processPrivateMessageComponents:(TVCLogLineType)type sender:(NSString *)sender command:(NSString *)command target:(NSString *)target text:(NSString *)text referenceMessage:(IRCMessage *)referenceMessage wasEncrypted:(BOOL)wasEncrypted
{
	/* If the self-message CAP is not enabled, we still check if we are on a ZNC
	 based connections because older versions of ZNC combined with the privmsg
	 module need the correct behavior which the self-message CAP evolved into. */
	BOOL isSelfMessage = NO;

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCSelfMessage] || self.isZNCBouncerConnection == YES) {
		if ([sender isEqualToString:[self localNickname]]) {
			isSelfMessage = YES;
		}
	}

	/* Does the query for the sender already exist?... */
	IRCChannel *c = nil;

	if (isSelfMessage == YES) {
		c = [self findChannel:target]; // Look for a query related to target, rather than sender
	} else {
		c = [self findChannel:sender];
	}

	BOOL newPrivateMessage = NO;

	if (type == TVCLogLineNoticeType) {
		/* Determine where to send notice messages. */
		if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
			c = [mainWindow() selectedChannelOn:self];
		}

		/* It is safe to assume that ChanServ and NickServ will not send encrypted data
		 so we do not make any attempt at this point to decrypt data. Data will be
		 decrypted when it comes time to print the message. */
		if ([sender isEqualIgnoringCase:@"ChanServ"])
		{
			/* Forward entry messages to the channel they are associated with. */
			/* Format we are going for: -ChanServ- [#channelname] blah blah... */
			NSInteger spacePos = [text stringPosition:NSStringWhitespacePlaceholder];

			if ([text hasPrefix:@"["] && spacePos > 3) {
				NSString *textHead = [text substringToIndex:spacePos];

				if ([textHead hasSuffix:@"]"]) {
					textHead = [textHead substringToIndex:([textHead length] - 1)]; // Remove the ]
					textHead = [textHead substringFromIndex:1]; // Remove the [

					if ([textHead isChannelNameOn:self]) {
						IRCChannel *thisChannel = [self findChannel:textHead];

						if (thisChannel) {
							text = [text substringFromIndex:([textHead length] + 2)]; // Remove the [#channelname] from the text.'

							c = thisChannel;
						}
					}
				}
			}
		}
		else if ([sender isEqualIgnoringCase:@"NickServ"])
		{
			self.serverHasNickServ = YES;

			BOOL continueNickServScan = YES;

			NSString *cleanedText = nil;

			if ([TPCPreferences removeAllFormatting] == NO) {
				cleanedText = [text stripIRCEffects];
			} else {
				cleanedText =  text;
			}

			if (self.isWaitingForNickServ == NO) {
				NSString *nicknamePassword = self.config.nicknamePassword;

				if (NSObjectIsNotEmpty(nicknamePassword)) {
					for (NSString *token in [self nickServSupportedNeedIdentificationTokens]) {
						if ([cleanedText containsIgnoringCase:token]) {
							continueNickServScan = NO;

							if ([self.networkAddress hasSuffix:@"dal.net"])
							{
								NSString *IDMessage = [NSString stringWithFormat:@"IDENTIFY %@", nicknamePassword];

								[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ@services.dal.net", IDMessage, nil];
							}
							else if (self.config.sendAuthenticationRequestsToUserServ)
							{
								NSString *IDMessage = [NSString stringWithFormat:@"login %@ %@", self.config.nickname, nicknamePassword];

								[self send:IRCPrivateCommandIndex("privmsg"), @"userserv", IDMessage, nil];
							}
							else
							{
								NSString *IDMessage = [NSString stringWithFormat:@"IDENTIFY %@", nicknamePassword];

								[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ", IDMessage, nil];
							}

							self.isWaitingForNickServ = YES;

							break;
						}
					}

					nicknamePassword = nil;
				}
			}

			/* Scan for messages telling us that we are now identified. */
			if (continueNickServScan) {
				for (NSString *token in [self nickServSupportedSuccessfulIdentificationTokens]) {
					if ([cleanedText containsIgnoringCase:token]) {
						self.isIdentifiedWithNickServ = YES;
						self.isWaitingForNickServ = NO;

						if (self.config.autojoinWaitsForNickServ) {
							if (self.isAutojoined == NO && self.autojoinInProgress == NO) {
								[self performAutoJoin];
							}
						}
					}
				}
			}
		}

		/* Place creation block last so ChanServ entry messages forwarded to a channel
		 does not create a new private message beforehand. */
		if (c == nil) {
			BOOL createNewWindow = YES;

			if (type == TVCLogLineNoticeType) {
				if ([TPCPreferences locationToSendNotices] == TXNoticeSendToQueryDestinationType) {
					;
				} else {
					createNewWindow = NO;
				}
			}

			if (createNewWindow) {
				if (isSelfMessage) {
					if (NSObjectIsEmpty(target) == NO) {
						c = [worldController() createPrivateMessage:target client:self];
					}
				} else {
					if (NSObjectIsEmpty(sender) == NO) {
						c = [worldController() createPrivateMessage:sender client:self];
					}
				}
			}
		}

		if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
			BOOL pluginResult = [THOPluginDispatcher receivedText:text
													   authoredBy:[referenceMessage sender]
													  destinedFor:c
													   asLineType:type
														 onClient:self
													   receivedAt:[referenceMessage receivedAt]
													 wasEncrypted:wasEncrypted];

			if (pluginResult == NO) {
				return;
			}
		}

		/* Post the notice. */
		[self printToWebView:c
						type:type
					 command:[referenceMessage command]
					nickname:sender
				 messageBody:text
				 isEncrypted:wasEncrypted
				  receivedAt:[referenceMessage receivedAt]
			referenceMessage:referenceMessage
			 completionBlock:^(BOOL isHighlight)
		 {
			 /* Set the query as unread and inform Growl. */
			 [self setUnreadState:c];

			 if ([self isSafeToPostNotificationForMessage:referenceMessage inChannel:c]) {
				 if (isSelfMessage == NO) { // Do not notify for self
					 [self notifyText:TXNotificationPrivateNoticeType lineType:type target:c nickname:sender text:text];
				 }
			 }
		 }];
	}
	else // if statement if message is NOTICE
	{
		if (c == nil) {
			if (isSelfMessage) {
				if (NSObjectIsEmpty(target) == NO) {
					c = [worldController() createPrivateMessage:target client:self];
				}
			} else {
				if (NSObjectIsEmpty(sender) == NO) {
					c = [worldController() createPrivateMessage:sender client:self];
				}
			}

			newPrivateMessage = YES;
		}

		if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
			BOOL pluginResult = [THOPluginDispatcher receivedText:text
													   authoredBy:[referenceMessage sender]
													  destinedFor:c
													   asLineType:type
														 onClient:self
													   receivedAt:[referenceMessage receivedAt]
													 wasEncrypted:wasEncrypted];

			if (pluginResult == NO) {
				return;
			}
		}

		[self printToWebView:c
						type:type
					 command:[referenceMessage command]
					nickname:sender
				 messageBody:text
				 isEncrypted:wasEncrypted
				  receivedAt:[referenceMessage receivedAt]
			referenceMessage:referenceMessage
			 completionBlock:^(BOOL isHighlight)
		 {
			 if ([self isSafeToPostNotificationForMessage:referenceMessage inChannel:c]) {
				 if (isSelfMessage == NO) { // Do not notify for self
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
			 else // is safe to post notification
			 {
				 if (isSelfMessage == NO) { // Do not notify for self
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
		NSString *hostTopic = [referenceMessage senderHostmask];

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

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSObjectIsEmptyAssert(text);

	NSMutableString *s = [text mutableCopy];

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey,
																		   IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey]];

	NSAssertReturn([ignoreChecks ignoreClientToClientProtocol] == NO);
	
	NSString *sendern = [m senderNickname];
	
	NSString *command = [s uppercaseGetToken];
	
	NSObjectIsEmptyAssert(command);

	if ([TPCPreferences replyToCTCPRequests] == NO) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1032]", command, sendern)];

		return;
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("dcc")]) {
		[self receivedDCCQuery:m message:s ignoreInfo:ignoreChecks];
		
		return; // Above method does all the work.
	} else {
		IRCChannel *target = nil;

		if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
			target = [mainWindow() selectedChannelOn:self];
		}

		NSString *textm = TXTLS(@"IRC[1065]", command, sendern);

		if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")] == NO) {
			[self print:target
				   type:TVCLogLineCTCPQueryType
			   nickname:nil
			messageBody:textm
			isEncrypted:wasEncrypted
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
				[self sendCTCPReply:sendern command:command text:TXTLS(@"IRC[1033]")];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")] ||
				   [command isEqualToString:IRCPrivateCommandIndex("ctcp_version")])
		{
			NSString *fakever = [TPCPreferences masqueradeCTCPVersion];

			if (NSObjectIsNotEmpty(fakever)) {
				[self sendCTCPReply:sendern command:command text:fakever];
			} else {
				NSString *name = [TPCApplicationInfo applicationName];
				NSString *vers = [TPCApplicationInfo applicationVersionShort];

				NSString *textoc = TXTLS(@"IRC[1026]", name, vers);

				[self sendCTCPReply:sendern command:command text:textoc];
			}
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_finger")]) {
			[self sendCTCPReply:sendern command:command text:TXTLS(@"IRC[1035]")];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_clientinfo")]) {
			[self sendCTCPReply:sendern command:command text:TXTLS(@"IRC[1034]")];
		} else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")]) {
			double time = [NSDate unixTime];

			if (time > self.lastLagCheck && self.lastLagCheck > 0 && [sendern isEqualIgnoringCase:[self localNickname]]) {
				double delta = (time -		self.lastLagCheck);

				NSString *rating = nil;

					   if (delta < 0.01) {						rating = TXTLS(@"IRC[1025][00]");
				} else if (delta >= 0.01 && delta < 0.1) {		rating = TXTLS(@"IRC[1025][01]");
				} else if (delta >= 0.1 && delta < 0.2) {		rating = TXTLS(@"IRC[1025][02]");
				} else if (delta >= 0.2 && delta < 0.5) {		rating = TXTLS(@"IRC[1025][03]");
				} else if (delta >= 0.5 && delta < 1.0) {		rating = TXTLS(@"IRC[1025][04]");
				} else if (delta >= 1.0 && delta < 2.0) {		rating = TXTLS(@"IRC[1025][05]");
				} else if (delta >= 2.0 && delta < 5.0) {		rating = TXTLS(@"IRC[1025][06]");
				} else if (delta >= 5.0 && delta < 10.0) {		rating = TXTLS(@"IRC[1025][07]");
				} else if (delta >= 10.0 && delta < 30.0) {		rating = TXTLS(@"IRC[1025][08]");
				} else if (delta >= 30.0) {						rating = TXTLS(@"IRC[1025][09]"); }

				textm = TXTLS(@"IRC[1022]", [self networkAddress], delta, rating);
			} else {
				textm = TXTLS(@"IRC[1024]");
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

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSObjectIsEmptyAssert(text);

	NSMutableString *s = [text mutableCopy];

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey]];

	NSAssertReturn([ignoreChecks ignoreClientToClientProtocol] == NO);

	NSString *sendern = [m senderNickname];
	
	NSString *command = [s uppercaseGetToken];

	IRCChannel *c = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
		c = [mainWindow() selectedChannelOn:self];
	}

	if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
		double delta = ([NSDate unixTime] - [s doubleValue]);
		
		text = TXTLS(@"IRC[1063]", sendern, command, delta);
	} else {
		text = TXTLS(@"IRC[1064]", sendern, command, s);
	}

	[self print:c
		   type:TVCLogLineCTCPReplyType
	   nickname:nil
	messageBody:text
	isEncrypted:wasEncrypted
	 receivedAt:[m receivedAt]
		command:[m command]];
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);
	
	NSString *sendern = [m senderNickname];

	NSString *channel = [m paramAt:0];

	BOOL myself = [sendern isEqualIgnoringCase:[self localNickname]];

	IRCChannel *c = nil;

	if (myself) {
		c = [self findChannelOrCreate:channel];

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
		
		self.cachedLocalHostmask = [m senderHostmask];

		[self disableInUserInvokedCommandProperty:&_inUserInvokedJoinRequest];
	} else {
		c = [self findChannel:channel];
		
		if (c == nil) {
			return; // Do not continue...
		}
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
					messageBody:TXTLS(@"IRC[1071]", sendern)
					 receivedAt:[m receivedAt]
						command:[m command]];
					
					[mainWindow() reloadTreeItem:query];
				}
			}
		}
	}

	IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
															 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
																		   IRCAddressBookDictionaryValueTrackUserActivityKey]];
	
	if ([m isPrintOnlyMessage] == NO) {
		[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
	}

	BOOL printMessage = [self postReceivedMessage:m withText:nil destinedFor:c];

	if (printMessage) {
		if ([ignoreChecks ignoreGeneralEventMessages] && myself == NO) {
			printMessage = NO;
		} else if ([TPCPreferences showJoinLeave] == NO && myself == NO) {
			printMessage = NO;
		} else if (c.config.ignoreGeneralEventMessages && myself == NO) {
			printMessage = NO;
		}
	}

	if (printMessage) {
		NSString *senderAddress = [m senderAddress];

		NSString *text = TXTLS(@"IRC[1077]", sendern, [m senderUsername], [senderAddress stringByAppendingIRCFormattingStop]);

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
			if (self.config.sendWhoCommandRequestsToChannels &&
				self.isBrokenIRCd_aka_Twitch == NO)
			{
				[c setInUserInvokedModeRequest:YES];

				[self send:IRCPrivateCommandIndex("mode"), [c name], nil];
			}
		} else {
			[self maybeResetUserAwayStatusForChannel:c];
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

	BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:c];

	if (printMessage) {
		if ([TPCPreferences showJoinLeave] == NO && myself == NO) {
			printMessage = NO;
		} else if (c.config.ignoreGeneralEventMessages && myself == NO) {
			printMessage = NO;
		} else {
			IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
																	 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if ([ignoreChecks ignoreGeneralEventMessages] && myself == NO) {
				printMessage = NO;
			}
		}
	}

	if (printMessage) {
		NSString *senderAddress = [m senderAddress];

		NSString *message = TXTLS(@"IRC[1079]", sendern, [m senderUsername], [senderAddress stringByAppendingIRCFormattingStop]);

		if (NSObjectIsNotEmpty(comment)) {
			message = TXTLS(@"IRC[1080]", message, [comment stringByAppendingIRCFormattingStop]);
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
	
	BOOL myself = [targetu isEqualIgnoringCase:[self localNickname]];
	
	if ([m isPrintOnlyMessage] == NO) {
		if (myself) {
			[c deactivate];

			[mainWindow() reloadTreeItem:c];

			[self notifyEvent:TXNotificationKickType lineType:TVCLogLineKickType target:c nickname:sendern text:comment];

			if ([TPCPreferences rejoinOnKick] && [c errorOnLastJoinAttempt] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1043]") channel:c];

				[self cancelPerformRequestsWithSelector:@selector(joinKickedChannel:) object:c];
				
				[self performSelector:@selector(joinKickedChannel:) withObject:c afterDelay:3.0];
			}
		}
		
		[c removeMember:targetu];
	}

	BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:c];

	if (printMessage) {
		if ([TPCPreferences showJoinLeave] == NO && myself == NO) {
			printMessage = NO;
		} else if (c.config.ignoreGeneralEventMessages && myself == NO) {
			printMessage = NO;
		} else {
			IRCAddressBookEntry *ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
																	 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if ([ignoreChecks ignoreGeneralEventMessages] && myself == NO) {
				printMessage = NO;
			}
		}
	}

	if (printMessage) {
		NSString *message = TXTLS(@"IRC[1078]", sendern, targetu, [comment stringByAppendingIRCFormattingStop]);

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
															 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
																		   IRCAddressBookDictionaryValueTrackUserActivityKey]];

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
	NSString *senderAddress = [m senderAddress];

	NSString *text = TXTLS(@"IRC[1069]", sendern, [m senderUsername], [senderAddress stringByAppendingIRCFormattingStop]);

	if (NSObjectIsNotEmpty(comment)) {
		text = TXTLS(@"IRC[1066]", text, [comment stringByAppendingIRCFormattingStop]);
	}

#define	_hideQuitInChannel		([TPCPreferences showJoinLeave] == NO || [ignoreChecks ignoreGeneralEventMessages] || c.config.ignoreGeneralEventMessages)

	/* Is this a targetted print message? */
	if ([m isPrintOnlyMessage]) {
		IRCChannel *c = [self findChannel:target];

		if ([c isChannel]) {
			BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:c];

			if (printMessage) {
				if (myself == NO && _hideQuitInChannel) {
					printMessage = NO;
				}
			}

			if (printMessage) {
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
				BOOL printMessage = YES;

				if ([c isChannel]) {
					printMessage = [self postReceivedMessage:m withText:comment destinedFor:c];

					if (printMessage) {
						if (myself == NO && _hideQuitInChannel) {
							printMessage = NO;
						}
					}
				} else {
					text = TXTLS(@"IRC[1070]", sendern);
				}

				if (printMessage) {
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
				}

				if (myself == NO) {
					[mainWindow() reloadTreeItem:c];
				}
			}
		}
	}

#undef _showQuitInChannel

	[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];

	if (myself == NO) {
		[mainWindow() updateTitleFor:self];
	}
}

- (void)receiveKill:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	NSString *target = [m paramAt:0];
	
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			[c removeMember:target];
		}
	}
}

- (void)receiveNick:(IRCMessage *)m
{
	IRCAddressBookEntry *ignoreChecks = nil;

	NSString *oldNick = [m senderNickname];
	
	NSString *newNick = nil;
	NSString *target = nil;

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
												withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}

		/* Check old nickname in address book user check. */
		ignoreChecks = [self checkIgnoreAgainstHostmask:[m senderHostmask]
											withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
														  IRCAddressBookDictionaryValueTrackUserActivityKey]];

		if ([m isPrintOnlyMessage] == NO) {
			[self checkAddressBookForTrackedUser:ignoreChecks inMessage:m];
		}
	}

	/* Is this a targetted print message? */
	if ([m isPrintOnlyMessage]) {
		IRCChannel *c = [self findChannel:target];

		if (c) {
			BOOL printMessage = [self postReceivedMessage:m withText:newNick destinedFor:c];

			NSString *text = nil;
			
			if (printMessage && myself == NO && [TPCPreferences showJoinLeave] && [ignoreChecks ignoreGeneralEventMessages] == NO && c.config.ignoreGeneralEventMessages == NO) {
				text = TXTLS(@"IRC[1068][0]", oldNick, newNick);
			} else if (printMessage && myself == YES) {
				text = TXTLS(@"IRC[1068][1]", newNick);
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
				BOOL printMessage = [self postReceivedMessage:m withText:newNick destinedFor:c];

				NSString *text = nil;
				
				if ((printMessage && myself == NO && [TPCPreferences showJoinLeave] && [ignoreChecks ignoreGeneralEventMessages] == NO && c.config.ignoreGeneralEventMessages == NO)) {
					text = TXTLS(@"IRC[1068][0]", oldNick, newNick);
				} else if (printMessage && myself == YES) {
					text = TXTLS(@"IRC[1068][1]", newNick);
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

	if (c) {
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
	} else {
		if (myself) {
			[mainWindow() updateTitleFor:self];
		}
	}
	
	[[self fileTransferController] nicknameChanged:oldNick toNickname:newNick client:self];
}

- (void)receiveMode:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 1);

	NSString *sendern = [m senderNickname];
	
	NSString *targetc = [m paramAt:0];
	NSString *modestr = [m sequence:1];

	if ([targetc isChannelNameOn:self]) {
		IRCChannel *c = [self findChannel:targetc];

		PointerIsEmptyAssert(c);
		
		if ([m isPrintOnlyMessage] == NO) {
			NSArray *info = [[c modeInfo] update:modestr];

			for (IRCModeInfo *h in info) {
				[c changeMember:[h modeParamater] mode:[h modeToken] value:[h modeIsSet]];
			}
		}

		BOOL printMessage = [self postReceivedMessage:m withText:modestr destinedFor:c];

		if (printMessage) {
			if ([TPCPreferences showJoinLeave] == NO || c.config.ignoreGeneralEventMessages) {
				printMessage = NO;
			}
		}

		if (printMessage) {
			[self print:c
				   type:TVCLogLineModeType
			   nickname:nil
			messageBody:TXTLS(@"IRC[1062]", sendern, modestr)
			 receivedAt:[m receivedAt]
				command:[m command]];
		}

		if ([m isPrintOnlyMessage] == NO) {
			[mainWindow() updateTitleFor:c];
		}
	} else {
		BOOL printMessage = [self postReceivedCommand:@"UMODE" withText:modestr destinedFor:nil referenceMessage:m];

		if (printMessage) {
			[self print:nil
				   type:TVCLogLineModeType
			   nickname:nil
			messageBody:TXTLS(@"IRC[1062]", sendern, modestr)
			 receivedAt:[m receivedAt]
				command:[m command]];
		}
	}
}

- (void)receiveTopic:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] == 2);

	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:0];
	NSString *topicav = [m paramAt:1];

	IRCChannel *c = [self findChannel:channel];

	if ([m isPrintOnlyMessage] == NO) {
		[c setTopic:topicav];
	}

	BOOL printMessage = [self postReceivedMessage:m withText:topicav destinedFor:c];

	if (printMessage) {
		[self print:c
			   type:TVCLogLineTopicType
		   nickname:nil
		messageBody:TXTLS(@"IRC[1044]", sendern, topicav)
		isEncrypted:NO
		 receivedAt:[m receivedAt]
			command:[m command]];
	}
}

- (void)receiveInvite:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] == 2);

	NSString *sendern = [m senderNickname];
	
	NSString *channel = [m paramAt:1];
	
	NSString *text = TXTLS(@"IRC[1074]", sendern, [m senderUsername], [m senderAddress], channel);
	
	/* Invite notifications are sent to frontmost channel on server of if it is
	 not on server, then it will be redirected to console. */
	BOOL printMessage = [self postReceivedMessage:m withText:channel destinedFor:nil];

	if (printMessage) {
		[self print:[mainWindow() selectedChannelOn:self]
			   type:TVCLogLineInviteType
		   nickname:nil
		messageBody:text
		 receivedAt:[m receivedAt]
			command:[m command]];
	}
	
	[self notifyEvent:TXNotificationInviteType lineType:TVCLogLineInviteType target:nil nickname:sendern text:channel];
	
	if ([TPCPreferences autoJoinOnInvite]) {
		[self joinUnlistedChannel:channel];
	}
}

- (void)receiveError:(IRCMessage *)m
{
	NSString *message = [m sequence];

    if (([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Excess Flood)"]) ||
		([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Max SendQ exceeded)"]))
	{
		__weak IRCClient *weakSelf = self;
		
		self.disconnectCallback = ^{
			[weakSelf cancelReconnect];
		};
	}

	[self printError:message forCommand:[m command]];
}

- (void)receiveCertInfo:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] == 2);

	/* CERTINFO is not a standard command for Textual to
	 receive which means we should be strict about what
	 conditions we will accept it under. */
	if (self.zncBoucnerIsSendingCertificateInfo == NO ||
		[m senderIsServer] == NO ||
		NSObjectsAreEqual([m senderNickname], @"znc.in") == NO)
	{
		return;
	}

	/* The data we expect to receive should be chunk split 
	 which means it is safe to assume a maximum length. */
	NSString *line = [m sequence];

	if ([line length] < 2 || [line length] > 65) {
		return;
	}

	/* Write line to the mutable buffer */
	if ( self.zncBouncerCertificateChainDataMutable) {
		[self.zncBouncerCertificateChainDataMutable appendFormat:@"%@\n", line];
	}
}

- (void)receiveBatch:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] >= 1);

	NSString *batchToken = [m paramAt:0];

	if ([batchToken length] <= 1) {
		LogToConsole(@"Cannot process BATCH command because [batchToken length] <= 1");

		return; // Cancel operation...
	}

	NSString *batchType = [m paramAt:1];

	BOOL isBatchOpening;

	if ([batchToken hasPrefix:@"+"]) {
		 batchToken = [batchToken substringFromIndex:1];

		isBatchOpening = YES;
	} else if ([batchToken hasPrefix:@"-"]) {
		batchToken = [batchToken substringFromIndex:1];

		isBatchOpening = NO;
	} else {
		LogToConsole(@"Cannot process BATCH command because there was no open or close token");

		return; // Cancel operation...
	}

	if ([batchToken length] < 4 && [batchToken onlyContainsCharacters:CS_LatinAlphabetIncludingUnderscoreDashCharacterSet] == NO) {
		LogToConsole(@"Cannot process BATCH command because the batch token contains illegal characters");

		return; // Cancel operation...
	}

	if (isBatchOpening == NO)
	{
		/* Find batch message matching known token. */
		IRCMessageBatchMessage *thisBatchMessage = [self.batchMessages queuedEntryWithBatchToken:batchToken];

		if (thisBatchMessage == nil) {
			LogToConsole(@"Cannot process BATCH command because -queuedEntryWithBatchToken: returned nil");

			return; // Cancel operation...
		}

		[thisBatchMessage setBatchIsOpen:NO];

		/* If this batch message has a parent batch, then we 
		 do not remove this batch or process it until the close
		 statement for the parent is received. */
		if ([thisBatchMessage parentBatchMessage]) {
			return; // Nothing left to do...
		}

		NSString *batchType = [thisBatchMessage batchType];

		/* Process queued entries for this batch message. */
		/* The method used for processing queued entries will 
		 also remove it from queue once completed. */
		[self recursivelyProcessBatchMessage:thisBatchMessage];

		/* Set vendor specific flags based on BATCH command values */
		if (NSObjectsAreEqual(batchType, @"znc.in/playback")) {
			self.zncBouncerIsPlayingBackHistory = NO;
		} else if (NSObjectsAreEqual(batchType, @"znc.in/tlsinfo")) {
			self.zncBoucnerIsSendingCertificateInfo = NO;
		}
	}
	else // isBatchOpening == NO
	{
		/* Check batch= value to look for possible parent batch. */
		IRCMessageBatchMessage *parentBatchMessage = nil;

		NSString *parentBatchMessageToken = [m batchToken];

		if (parentBatchMessageToken) {
			parentBatchMessage = [self.batchMessages queuedEntryWithBatchToken:parentBatchMessageToken];
		}

		/* Create new batch message and queue it. */
		IRCMessageBatchMessage *newBatchMessage = [IRCMessageBatchMessage new];

		[newBatchMessage setBatchIsOpen:YES];

		[newBatchMessage setBatchToken:batchToken];
		[newBatchMessage setBatchType:batchType];

		[newBatchMessage setParentBatchMessage:parentBatchMessage];

		[self.batchMessages queueEntry:newBatchMessage];

		/* Set vendor specific flags based on BATCH command values */
		if (NSObjectsAreEqual(batchType, @"znc.in/playback")) {
			self.zncBouncerIsPlayingBackHistory = self.isZNCBouncerConnection;
		} else if (NSObjectsAreEqual(batchType, @"znc.in/tlsinfo")) {
			/* If this is parent batch (there is no @batch=), then we
			 reset the mutable object to read new data. */
			if (parentBatchMessageToken == nil) {
				self.zncBouncerCertificateChainDataMutable = [NSMutableString string];
			}

			self.zncBoucnerIsSendingCertificateInfo = self.isZNCBouncerConnection;
		}
	}
}

#pragma mark -
#pragma mark BATCH Command

- (BOOL)filterBatchCommandIncomingData:(IRCMessage *)m
{
	if (m == nil) {
		return NO;
	}

	NSString *batchToken = [m batchToken];

	if (batchToken) {
		IRCMessageBatchMessage *thisBatchMessage = [self.batchMessages queuedEntryWithBatchToken:batchToken];

		if (thisBatchMessage && [thisBatchMessage batchIsOpen]) {
			[thisBatchMessage queueEntry:m];

			return YES;
		}
	}

	return NO;
}

- (void)recursivelyProcessBatchMessage:(IRCMessageBatchMessage *)batchMessage
{
	[self recursivelyProcessBatchMessage:batchMessage depth:0];
}

- (void)recursivelyProcessBatchMessage:(IRCMessageBatchMessage *)batchMessage depth:(NSInteger)recursionDepth
{
	if (batchMessage == nil) {
		return;
	}

	if ([batchMessage batchIsOpen]) {
		return;
	}

	NSArray *queuedEntries = [batchMessage queuedEntries];

	for (id queuedEntry in queuedEntries) {
		if ([queuedEntry isKindOfClass:[IRCMessage class]]) {
			[self processIncomingData:queuedEntry];
		} else if ([queuedEntry isKindOfClass:[IRCMessageBatchMessage class]]) {
			[self recursivelyProcessBatchMessage:queuedEntry depth:(recursionDepth + 1)];
		}
	}

	if (recursionDepth == 0) {
		[self.batchMessages dequeueEntry:batchMessage];
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
	return ((_capacities & capacity) == capacity);
}

- (NSString *)stringValueOfCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	NSString *stringValue = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch"

	switch (capacity) {
		case ClientIRCv3SupportedCapacityAwayNotify:
		{
			stringValue = @"away-notify";
			
			break;
		}
		case ClientIRCv3SupportedCapacityBatch:
		{
			stringValue = @"batch";

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
		case ClientIRCv3SupportedCapacitySASLGeneric:
		case ClientIRCv3SupportedCapacityIsIdentifiedWithSASL:
		case ClientIRCv3SupportedCapacityIsInSASLNegotiation:
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
			stringValue = @"userhost-in-names";
			
			break;
		}
		case ClientIRCv3SupportedCapacityWatchCommand:
		{
			stringValue = @"watch-command";
			
			break;
		}
		case ClientIRCv3SupportedCapacityZNCCertInfoModule:
		{
			stringValue = @"znc.in/tlsinfo";

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
		case ClientIRCv3SupportedCapacityZNCSelfMessage:
		{
			stringValue = @"znc.in/self-message";

			break;
		}
	}

#pragma clang diagnostic pop
	
	return stringValue;
}

- (NSString *)enabledCapacitiesStringValue
{
	NSMutableArray *enabledCaps = [NSMutableArray array];
	
	void (^appendValue)(ClientIRCv3SupportedCapacities) = ^(ClientIRCv3SupportedCapacities capacity) {
		if ([self isCapacityEnabled:capacity]) {
			NSString *stringValue = [self stringValueOfCapacity:capacity];
			
			if (stringValue) {
				[enabledCaps addObject:stringValue];
			}
		}
	};

	appendValue(ClientIRCv3SupportedCapacityAwayNotify);
	appendValue(ClientIRCv3SupportedCapacityBatch);
	appendValue(ClientIRCv3SupportedCapacityIdentifyCTCP);
	appendValue(ClientIRCv3SupportedCapacityIdentifyMsg);
	appendValue(ClientIRCv3SupportedCapacityMultiPreifx);
	appendValue(ClientIRCv3SupportedCapacityIsIdentifiedWithSASL);
	appendValue(ClientIRCv3SupportedCapacityServerTime);
	appendValue(ClientIRCv3SupportedCapacityUserhostInNames);
	appendValue(ClientIRCv3SupportedCapacityZNCCertInfoModule);
	appendValue(ClientIRCv3SupportedCapacityZNCPlaybackModule);
	appendValue(ClientIRCv3SupportedCapacityZNCSelfMessage);
	
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
	if (self.CAPNegotiationIsPaused == YES) {
		return; // Cannot continue operation...
	}

#define _rony(s)		if ([self maybeSendNextCapacity:(s)] == YES) { return; }

	_rony(ClientIRCv3SupportedCapacitySASLGeneric)
	_rony(ClientIRCv3SupportedCapacityAwayNotify)
	_rony(ClientIRCv3SupportedCapacityBatch)
	_rony(ClientIRCv3SupportedCapacityIdentifyCTCP)
	_rony(ClientIRCv3SupportedCapacityIdentifyMsg)
	_rony(ClientIRCv3SupportedCapacityMultiPreifx)
	_rony(ClientIRCv3SupportedCapacityServerTime)
	_rony(ClientIRCv3SupportedCapacityUserhostInNames)
	_rony(ClientIRCv3SupportedCapacityZNCCertInfoModule)
	_rony(ClientIRCv3SupportedCapacityZNCPlaybackModule)
	_rony(ClientIRCv3SupportedCapacityZNCServerTime)
	_rony(ClientIRCv3SupportedCapacityZNCServerTimeISO)
	_rony(ClientIRCv3SupportedCapacityZNCSelfMessage)

	[self send:IRCPrivateCommandIndex("cap"), @"END", nil];
	
#undef _rony
}

- (void)pauseCap
{
	self.CAPNegotiationIsPaused = YES;
}

- (void)resumeCap
{
	self.CAPNegotiationIsPaused = NO;

	[self sendNextCap];
}

- (BOOL)isCapAvailable:(NSString *)cap
{
	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org
	
	BOOL condition1 = ([cap isEqualIgnoringCase:@"sasl"]					||
					   [cap isEqualIgnoringCase:@"identify-msg"]			||
					   [cap isEqualIgnoringCase:@"identify-ctcp"]			||
					   [cap isEqualIgnoringCase:@"away-notify"]				||
					   [cap isEqualIgnoringCase:@"batch"]					||
					   [cap isEqualIgnoringCase:@"multi-prefix"]			||
					   [cap isEqualIgnoringCase:@"userhost-in-names"]		||
					   [cap isEqualIgnoringCase:@"server-time"]				||
					   [cap isEqualIgnoringCase:@"znc.in/self-message"]		||
					   [cap isEqualIgnoringCase:@"znc.in/tlsinfo"]			||
					   [cap isEqualIgnoringCase:@"znc.in/playback"]			||
					   [cap isEqualIgnoringCase:@"znc.in/server-time"]		||
					   [cap isEqualIgnoringCase:@"znc.in/server-time-iso"]);
	
	return condition1;
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
	} else if ([stringValue isEqualIgnoringCase:@"batch"]) {
		return ClientIRCv3SupportedCapacityBatch;
	} else if ([stringValue isEqualIgnoringCase:@"server-time"]) {
		return ClientIRCv3SupportedCapacityServerTime;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/self-message"]) {
		return ClientIRCv3SupportedCapacityZNCSelfMessage;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/server-time"]) {
		return ClientIRCv3SupportedCapacityZNCServerTime;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/server-time-iso"]) {
		return ClientIRCv3SupportedCapacityZNCServerTimeISO;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/tlsinfo"]) {
		return ClientIRCv3SupportedCapacityZNCCertInfoModule;
	} else if ([stringValue isEqualIgnoringCase:@"znc.in/playback"]) {
		return ClientIRCv3SupportedCapacityZNCPlaybackModule;
	} else if ([stringValue isEqualIgnoringCase:@"sasl"]) {
		return ClientIRCv3SupportedCapacitySASLGeneric;
	} else {
		return 0;
	}
}

- (void)cap:(NSString *)cap result:(BOOL)supported
{
	[self cap:cap result:supported isUpdateRequest:NO];
}

- (void)cap:(NSString *)cap result:(BOOL)supported isUpdateRequest:(BOOL)isUpdateRequest
{
	if ([cap isEqualIgnoringCase:@"sasl"]) {
		if (supported) {
			if ([self sendSASLIdentificationRequest]) {
				[self pauseCap];
			}
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

- (void)processPendingCapacity:(NSString *)cap
{
	NSArray *capSegments = [cap componentsSeparatedByString:@"="];

	NSString *capValue = nil;

	NSArray *capOptions = nil;

	if ([capSegments count] == 2) {
		capValue = capSegments[0];

		capOptions = [capSegments[1] componentsSeparatedByString:@","];
	} else {
		capValue = cap;
	}

	[self processPendingCapacity:capValue options:capOptions];
}

- (void)processPendingCapacity:(NSString *)cap options:(NSArray *)options
{
	if ([self isCapAvailable:cap]) {
		ClientIRCv3SupportedCapacities capacity = [self capacityFromStringValue:cap];

		if ([cap isEqualToString:@"sasl"]) {
			[self processPendingCapacityForSASL:options];
		} else {
			if ((_capacitiesPending &  capacity) == 0) {
				 _capacitiesPending |= capacity;
			}
		}
	}
}

- (void)processPendingCapacityForSASL:(NSArray *)options
{
	ClientIRCv3SupportedCapacities identificationMechanism = 0;

	if (NSObjectIsEmpty(options)) {
		if (self.config.saslAuthenticationUsesExternalMechanism) {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLExternal;
		} else {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText;
		}
	} else {
		if ([options containsObject:@"EXTERNAL"]) {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLExternal;
		} else if ([options containsObject:@"PLAIN"]) {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText;
		}
	}

	if (identificationMechanism == ClientIRCv3SupportedCapacitySASLExternal) {
		if (self.socket.isConnectedWithClientSideCertificate) {
			_capacitiesPending |= ClientIRCv3SupportedCapacitySASLExternal;
		} else {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText; // Use as a fallback...
		}
	}

	if (identificationMechanism == ClientIRCv3SupportedCapacitySASLPlainText) {
		if (NSObjectIsEmpty(self.config.nicknamePassword) == NO) {
			_capacitiesPending |= ClientIRCv3SupportedCapacitySASLPlainText;
		}
	}

	if (identificationMechanism > 0) {
		_capacitiesPending |= ClientIRCv3SupportedCapacitySASLGeneric;
	}
}

- (void)sendSASLIdentificationInformation
{
	if ((_capacitiesPending & ClientIRCv3SupportedCapacityIsInSASLNegotiation) == 0)
	{
		return; // Do not continue operation...
	}

	if ((_capacitiesPending & ClientIRCv3SupportedCapacitySASLPlainText) == ClientIRCv3SupportedCapacitySASLPlainText)
	{
		NSString *authString = [NSString stringWithFormat:@"%@%C%@%C%@",
								 self.config.username, 0x00,
								 self.config.username, 0x00,
								 self.config.nicknamePassword];

		NSArray *authStrings = [authString base64EncodingWithLineLength:400];

		for (NSString *string in authStrings) {
			[self send:IRCPrivateCommandIndex("cap_authenticate"), string, nil];
		}

		if (NSObjectIsEmpty(authStrings) || [(NSString *)[authStrings lastObject] length] == 400) {
			[self send:IRCPrivateCommandIndex("cap_authenticate"), @"+", nil];
		}
	}
	else if ((_capacitiesPending & ClientIRCv3SupportedCapacitySASLExternal) == ClientIRCv3SupportedCapacitySASLExternal)
	{
		[self send:IRCPrivateCommandIndex("cap_authenticate"), @"+", nil];
	}
}

- (BOOL)sendSASLIdentificationRequest
{
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL] ||
		((_capacitiesPending & ClientIRCv3SupportedCapacityIsInSASLNegotiation) == ClientIRCv3SupportedCapacityIsInSASLNegotiation))
	{
		return NO; // Do not continue operation...
	}

	_capacitiesPending |= ClientIRCv3SupportedCapacityIsInSASLNegotiation;

	if ((_capacitiesPending & ClientIRCv3SupportedCapacitySASLPlainText) == ClientIRCv3SupportedCapacitySASLPlainText)
	{
		[self send:IRCPrivateCommandIndex("cap_authenticate"), @"PLAIN", nil];

		return YES;
	}
	else if ((_capacitiesPending & ClientIRCv3SupportedCapacitySASLExternal) == ClientIRCv3SupportedCapacitySASLExternal)
	{
		[self send:IRCPrivateCommandIndex("cap_authenticate"), @"EXTERNAL", nil];

		return YES;
	}

	return NO;
}

- (void)receiveCapacityOrAuthenticationRequest:(IRCMessage *)m
{
	/* Implementation based off Colloquy's own. */

	NSAssertReturn([m paramsCount] > 0);

	NSString *command = [m command];
	NSString *starprt = [m paramAt:0];
	NSString *baseprt = [m paramAt:1];
	NSString *actions = [m sequence:2];

	if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap")])
	{
		if ([baseprt isEqualIgnoringCase:@"LS"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self processPendingCapacity:cap];
			}
		} else if ([baseprt isEqualIgnoringCase:@"ACK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self cap:cap result:YES isUpdateRequest:NO];
			}
		} else if ([baseprt isEqualIgnoringCase:@"NAK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self cap:cap result:NO isUpdateRequest:NO];
			}
		} else if ([baseprt isEqualIgnoringCase:@"NEW"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self cap:cap result:YES isUpdateRequest:YES];
			}
		} else if ([baseprt isEqualIgnoringCase:@"DEL"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self cap:cap result:NO isUpdateRequest:YES];
			}
		}

		[self sendNextCap];
	}
	else if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap_authenticate")])
	{
		if ([starprt isEqualToString:@"+"]) {
			[self sendSASLIdentificationInformation];
		}
	}

	(void)[self postReceivedMessage:m];
}

- (void)receivePing:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	[self send:IRCPrivateCommandIndex("pong"), [m sequence:0], nil];

	(void)[self postReceivedMessage:m];
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
	[self startPongTimer];
	[self stopRetryTimer];

	/* Manage local variables. */
	self.reconnectEnabledBecauseOfSleepMode = NO;

	self.supportInfo.networkAddress = [m senderHostmask];

	self.isLoggedIn = YES;
	self.isConnected = YES;
	
	self.isInvokingISONCommandForFirstTime = YES;

	self.cachedLocalNickname = [m paramAt:0];
	
	self.tryingNicknameSentNickname = [m paramAt:0];

	self.successfulConnects += 1;
	
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

	/* Request certificate information */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCCertInfoModule]) {
		[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameWithZNCUserPrefix:@"tlsinfo"], @"send-data", nil];
	}

	/* Request playback since the last seen message when previously connected. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
		/* For our first connect, only playback using timestamp if logging was enabled. */
		/* For all other connects, then playback timestamp regardless of logging. */

		if ((self.successfulConnects > 1 || (self.successfulConnects == 1 && [TPCPreferences logToDiskIsEnabled])) && self.lastMessageServerTime > 0) {
			NSString *timetosend = [NSString stringWithFormat:@"%.0f", self.lastMessageServerTime];

			[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameWithZNCUserPrefix:@"playback"], @"play", @"*", timetosend, nil];
		} else {
			[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameWithZNCUserPrefix:@"playback"], @"play", @"*", @"0", nil];
		}
	}

	/* Activate existing queries. */
	@synchronized(self.channels) {
		for (IRCChannel *c in self.channels) {
			if ([c isPrivateMessage]) {
				[c activate];

				[mainWindow() reloadTreeItem:c];
			}
		}
	}

	[mainWindow() reloadTreeItem:self];
	[mainWindow() updateTitleFor:self];

	[mainWindowTextField() updateSegmentedController];

	/* Everything else. */
	if (self.config.autojoinWaitsForNickServ == NO || [self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL]) {
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
	NSInteger n = [m commandNumeric];

	if (400 <= n && n < 600 && (n == 403) == NO && (n == 422) == NO) {
		[self receiveErrorNumericReply:m];

		return;
	}

	BOOL printMessage = YES;

	if (n != 324 && n != 332) {
		printMessage = [self postReceivedMessage:m];
	}

	switch (n) {
		case 1: // RPL_WELCOME
		{
			[self receiveInit:m];

			if (printMessage) {
				[self printReply:m];
			}

			break;
		}
		case 2: // RPL_YOURHOST
		case 3: // RPL_CREATED
		case 4: // RPL_MYINFO
		{
			if (printMessage) {
				[self printReply:m];
			}

			break;
		}
		case 5: // RPL_ISUPPORT
		{
            [self.supportInfo update:[m sequence:1] client:self];

			if (printMessage) {
				NSString *configRep = [self.supportInfo buildConfigurationRepresentationForLastEntry];

				[self printDebugInformationToConsole:configRep forCommand:[m command]];
			}

			break;
		}
		case 10: // RPL_REDIR
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *address = [m paramAt:0];
			NSString *portraw = [m paramAt:1];

			self.disconnectType = IRCClientDisconnectServerRedirectMode;

			[self disconnect]; // No worry about gracefully disconnecting by using quit: since it is just a redirect.

			/* If the address is thought to be invalid, then we still
			 perform the disconnected suggested by the redirect, but
			 we do not go any further than that. */
			if ([address isValidInternetAddress] == NO) {
				return;
			}

			/* -disconnect would destroy this so we set them after... */
			self.serverRedirectAddressTemporaryStore = address;
			self.serverRedirectPortTemporaryStore = [portraw integerValue];
			
			__weak IRCClient *weakSelf = self;
			
			self.disconnectCallback = ^{
				[weakSelf connect];
			};
			
			break;
		}
		case 20: // RPL_(?????) — Legacy code. What goes here?
		case 42: // RPL_(?????) — Legacy code. What goes here?
		case 250 ... 255: // RPL_STATSCONN, RPL_LUSERCLIENT, RPL_LUSERHOP, RPL_LUSERUNKNOWN, RPL_LUSERCHANNELS, RPL_LUSERME
		{
			if (printMessage) {
				[self printReply:m];
			}

			break;
		}
		case 222: // RPL_(?????) — Legacy code. What goes here?
		{
			break;
		}
		case 265 ... 266: // RPL_LOCALUSERS, RPL_GLOBALUSERS
        {
			NSAssertReturn(printMessage);

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
			NSAssertReturn([TPCPreferences displayServerMOTD]);

			NSAssertReturn(printMessage);

			if (n == 422) {
				[self printErrorReply:m];
			} else {
				[self printReply:m];
			}
			
			break;
		}
		case 221: // RPL_UMODES
		{
			NSAssertReturn([m paramsCount] > 1);

			NSAssertReturn(printMessage);
			
			NSString *modestr = [m paramAt:1];

			if ([modestr isEqualToString:@"+"]) {
				break;
			}
			
			[self print:nil
				   type:TVCLogLineDebugType
			   nickname:nil
			messageBody:TXTLS(@"IRC[1072]", [self localNickname], modestr)
			 receivedAt:[m receivedAt]
				command:[m command]];

			break;
		}
		case 290: // RPL_CAPAB (freenode)
		{
			NSAssertReturn([m paramsCount] > 1);

			NSString *kind = [m paramAt:1];

			if ([kind isEqualIgnoringCase:@"identify-msg"]) {
				[self enableCapacity:ClientIRCv3SupportedCapacityIdentifyMsg];
			} else if ([kind isEqualIgnoringCase:@"identify-ctcp"]) {
				[self enableCapacity:ClientIRCv3SupportedCapacityIdentifyCTCP];
			}

			if (printMessage) {
				[self printReply:m];
			}

			break;
		}
		case 301: // RPL_AWAY
		{
			NSAssertReturn([m paramsCount] > 1);

			NSString *awaynick = [m paramAt:1];
			NSString *comment = [m paramAt:2];

			IRCChannel *ac = [self findChannel:awaynick];

			NSString *text = TXTLS(@"IRC[1075]", awaynick, comment);

            if (ac == nil) {
				ac = [mainWindow() selectedChannelOn:self];
			} else {
				IRCUser *user = [ac findMember:awaynick];

				if ( user) {
					[user setIsAway:YES];

					if ([user presentAwayMessageFor301] == NO) {
						return;
					}
				}
			}

			if (printMessage) {
				[self print:ac
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 305: // RPL_UNAWAY
		case 306: // RPL_NOWAWAY
		{
			self.isAway = (n == 306);

			if (printMessage) {
				[self printUnknownReply:m];
			}

            /* Update our own status. This has to only be done with away-notify CAP enabled.
             Old, WHO based information requests will still show our own status. */
            NSAssertReturn([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]);

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
		case 275: // RPL_WHOISSECURE (bahamut)
		case 276: // RPL_WHOIS? — (is using a client certificate, hybrid)
		case 307: // RPL_WHOISREGNICK
		case 310: // RPL_WHOISHELPOP
		case 313: // RPL_WHOISOPERATOR
		case 335: // RPL_WHOISBOT
		case 336: // RPL_WHOIS? — (is on private/secret channels..., InspIRCd)
		case 378: // RPL_WHOISHOST
		case 379: // RPL_WHOISMODES
		case 616: // RPL_WHOISHOST
		case 671: // RPL_WHOISSECURE
		case 672: // RPL_WHOIS? — (is a CGI:IRC client from..., hybrid)
		case 727: // RPL_WHOIS? — (is captured, hybrid)
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);

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
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);

			NSString *text = nil;
			
			if ([m paramsCount] == 3) {
				text = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];
			} else {
				/* I am not sure in what context this variant is used. It is legacy code from 
				 earlier versions of Textual so it is better to keep it here. */
				text = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			}
			
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
			NSAssertReturn([m paramsCount] >= 6);

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *hostmask = [m paramAt:3];
			NSString *realname = [m paramAt:5];

			NSString *text = nil;

			if (n == 314) {
				[self enableInUserInvokedCommandProperty:&_inUserInvokedWhowasRequest];
			}

			if (printMessage) {
				if ([realname hasPrefix:@":"]) {
					 realname = [realname substringFromIndex:1];
				}
			}

			if (self.inUserInvokedWhowasRequest) {
				if (printMessage) {
					text = TXTLS(@"IRC[1086]", nickname, username, hostmask, realname);
				}
			} else {
				/* Update local cache of our hostmask. */
				if ([nickname isEqualIgnoringCase:[self localNickname]]) {
					NSString *completehost = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, hostmask];

					self.cachedLocalHostmask = completehost;
				}

				/* Continue normal WHOIS event. */
				if (printMessage) {
					text = TXTLS(@"IRC[1083]", nickname, username, hostmask, realname);
				}
			}

			if (text) {
				[self print:[mainWindow() selectedChannelOn:self]
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:text
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 312: // RPL_WHOISSERVER
		{
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *serverHost = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];

			NSString *text = nil;

			if (self.inUserInvokedWhowasRequest) {
				NSString *timeInfo = TXFormatDateTimeStringToCommonFormat(serverInfo, YES);
				
				text = TXTLS(@"IRC[1085]", nickname, serverHost, timeInfo);
			} else {
				text = TXTLS(@"IRC[1082]", nickname, serverHost, serverInfo);
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
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *idleTime = [m paramAt:2];
			NSString *connTime = [m paramAt:3];

			idleTime = TXHumanReadableTimeInterval([idleTime doubleValue], NO, 0);

			NSDate *connTimeDate = [NSDate dateWithTimeIntervalSince1970:[connTime doubleValue]];

			connTime = TXFormatDateTimeStringToCommonFormat(connTimeDate, NO);

			NSString *text = TXTLS(@"IRC[1084]", nickname, connTime, idleTime);
			
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
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *channels = [m paramAt:2];

			NSString *text = TXTLS(@"IRC[1081]", nickname, channels);
			
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
			NSAssertReturn([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *modestr = [m sequence:2];

			if ([modestr isEqualToString:@"+"]) {
				return;
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);

			if ([c isActive]) {
				[[c modeInfo] clear];
				[[c modeInfo] update:modestr];
			}

			printMessage = [self postReceivedMessage:m withText:modestr destinedFor:c];

			if (self.inUserInvokedModeRequest || c.inUserInvokedModeRequest) {
				if (printMessage) {
					NSString *fmodestr = [[c modeInfo] format:YES];

					[self print:c
						   type:TVCLogLineModeType
					   nickname:nil
					messageBody:TXTLS(@"IRC[1039]", fmodestr)
					 receivedAt:[m receivedAt]
						command:[m command]];
				}

				if (c.inUserInvokedModeRequest) {
					c.inUserInvokedModeRequest = NO;
				} else {
					[self disableInUserInvokedCommandProperty:&_inUserInvokedModeRequest];
				}
			}
			
			break;
		}
		case 332: // RPL_TOPIC
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *channel = [m paramAt:1];
			NSString *topicva = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);

			printMessage = [self postReceivedMessage:m withText:topicva destinedFor:c];

			if ([c isActive]) {
				[c setTopic:topicva];

				if (printMessage) {
					[self print:c
						   type:TVCLogLineTopicType
					   nickname:nil
					messageBody:TXTLS(@"IRC[1040]", topicva)
					isEncrypted:NO
					 receivedAt:[m receivedAt]
						command:[m command]];
				}
			}

			break;
		}
		case 333: // RPL_TOPICWHOTIME
		{
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *channel = [m paramAt:1];
			NSString *topicow = [m paramAt:2];
			NSString *settime = [m paramAt:3];

			topicow = [topicow nicknameFromHostmask];

			NSDate *settimeDate = [NSDate dateWithTimeIntervalSince1970:[settime doubleValue]];

			settime = TXFormatDateTimeStringToCommonFormat(settimeDate, NO);

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);

			if ([c isActive]) {
				NSString *text = TXTLS(@"IRC[1041]", topicow, settime);

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
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
			NSString *nickname = [m paramAt:1];
			NSString *channel = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);

			if ([c isActive]) {
				[self print:c
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:TXTLS(@"IRC[1073]", nickname, channel)
				 receivedAt:[m receivedAt]
					command:[m command]];
			}
			
			break;
		}
		case 303: // RPL_ISON
		{
			/* Cut the users up. */
			if (self.inUserInvokedIsonRequest) {
				if (printMessage) {
					[self printErrorReply:m];
				}

				[self disableInUserInvokedCommandProperty:&_inUserInvokedIsonRequest];
			} else {
				NSString *userInfo = [[m sequence] lowercaseString];
				
				NSArray *users = [userInfo split:NSStringWhitespacePlaceholder];

				/* Start going over the list of tracked nicknames. */
				@synchronized(self.trackedUsers) {
					NSArray *trackedUsers = [self.trackedUsers allKeys];
					
					for (NSString *name in trackedUsers) {
						NSString *localization = nil;
						
						/* Was the user on during the last check? */
						BOOL ison = [self.trackedUsers boolForKey:name];
						
						if (ison) {
							/* If the user was on before, but is not in the list of ISON
							 users in this reply, then they are considered gone. Log that. */
							if ([users containsObjectIgnoringCase:name] == NO) {
								if (self.isInvokingISONCommandForFirstTime == NO) {
									localization = @"Notifications[1042]";
								}
								
								[self.trackedUsers setBool:NO forKey:name];
							}
						} else {
							/* If they were not on but now are, then log that too. */
							if ([users containsObjectIgnoringCase:name]) {
								if (self.isInvokingISONCommandForFirstTime) {
									localization = @"Notifications[1041]";
								} else {
									localization = @"Notifications[1043]";
								}
								
								[self.trackedUsers setBool:YES forKey:name];
							}
						}
						
						/* If we have a ocalization, then there was something logged. We will now
						 find the actual tracking rule that matches the name and post that to the
						 end user to see the user status. */
						if (localization) {
							for (IRCAddressBookEntry *g in self.config.ignoreList) {
								NSString *trname = [g trackingNickname];
								
								if ([trname isEqualIgnoringCase:name]) {
									[self handleUserTrackingNotification:g nickname:name localization:localization];
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
			}

			break;
		}
		case 315: // RPL_ENDOFWHO
		{
			if (self.inUserInvokedWhoRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}

				[self disableInUserInvokedCommandProperty:&_inUserInvokedWhoRequest];
			}

			break;
		}
		case 352: // RPL_WHOREPLY
		{
			NSAssertReturn([m paramsCount] > 6);

			NSString *channel = [m paramAt:1];

			if (self.inUserInvokedWhoRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);
					
			/* Example incoming data:
				<channel> <user> <host> <server> <nick> <H|G>[*][@|+] <hopcount> <real name>
			 
				#freenode znc unaffiliated/namikaze kornbluth.freenode.net Namikaze G 0 Christian
				#freenode ~D unaffiliated/solprefixer kornbluth.freenode.net solprefixer H 0 solprefixer
			*/
			
			NSString *nickname = [m paramAt:5];
			NSString *username = [m paramAt:2];
			NSString *hostmask = [m paramAt:3];
			NSString *flfields = [m paramAt:6];
			NSString *realname = [m paramAt:7];

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
			IRCUser *newUser = nil;
			
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

			/* Paramater 7 includes the hop count and real name because it begins with a :
			 Therefore, we cut after the first space to get the real, real name value. */
			NSInteger realnameFirstSpace = [realname stringPosition:NSStringWhitespacePlaceholder];

			if (realnameFirstSpace > -1) {
				if (realnameFirstSpace < [realname length]) {
					realname = [realname substringAfterIndex:realnameFirstSpace];
				}
			}

			[newUser setRealname:realname];

			/* Update user modes */
			NSMutableString *userModes = [NSMutableString string];

			for (NSUInteger i = 0; i < [flfields length]; i++) {
				NSString *prefix = [flfields stringCharacterAtIndex:i];

				NSString *mode = [self.supportInfo modeCharacterFromUserPrefixSymbol:prefix];

				if (mode == nil) {
					break;
				} else {
					[userModes appendString:mode];
				}
			}

			if ([userModes length] > 0) {
				[newUser setModes:userModes];
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
				
				if (requiresRedraw) {
					if ([c isChannel]) {
						[c removeMember:[oldUser nickname]];
						
						[c addMember:oldUser];
					}
				}
			}

			break;
		}
		case 353: // RPL_NAMEREPLY
		{
			NSAssertReturn([m paramsCount] > 3);

			NSString *channel = [m paramAt:2];
			NSString *nameblob = [m paramAt:3];
			
			if (self.inUserInvokedNamesRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}
			}

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);

			NSArray *items = [nameblob split:NSStringWhitespacePlaceholder];

			for (NSString *nickname in items) {
				NSObjectIsEmptyAssertLoopContinue(nickname); // Some networks append empty spaces...
				
				IRCUser *member = [IRCUser newUserOnClient:self withNickname:nil];

				NSUInteger i;
				
				/* Find first character that is not mode prefix. */
				NSMutableString *userModes = [NSMutableString string];

				for (i = 0; i < [nickname length]; i++) {
					NSString *prefix = [nickname stringCharacterAtIndex:i];

					NSString *mode = [self.supportInfo modeCharacterFromUserPrefixSymbol:prefix];

					if (mode == nil) {
						break;
					} else {
						[userModes appendString:mode];
					}
				}

				if ([userModes length] > 0) {
					[member setModes:userModes];
				}
				
#undef _userModeSymbol

				/* Split away hostmask if available. */
				NSString *newNickname = [nickname substringFromIndex:i];

				NSString *nicknameInt = nil;
				NSString *usernameInt = nil;
				NSString *addressInt = nil;

				if ([newNickname hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt onClient:self] == NO) {
					/* When NAMES reply is not a host, then set the nicknameInt
					 to the value of nickname and leave the rest as nil. */

					nicknameInt = newNickname;
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
			NSAssertReturn([m paramsCount] > 1);
			
			NSString *channel = [m paramAt:1];

			IRCChannel *c = [self findChannel:channel];

			PointerIsEmptyAssert(c);
			
			if (self.inUserInvokedNamesRequest == NO && self.isBrokenIRCd_aka_Twitch == NO) {
				if ([c numberOfMembers] <= 1) {
					NSString *mode = c.config.defaultModes;

					if (NSObjectIsNotEmpty(m)) {
						[self send:IRCPrivateCommandIndex("mode"), [c name], mode, nil];
					}

					if ([channel isModeChannelName]) {
						NSString *topic = c.config.defaultTopic;

						if (NSObjectIsNotEmpty(topic)) {
							[self send:IRCPrivateCommandIndex("topic"), [c name], topic, nil];
						}
					}
				}
			}

			[self disableInUserInvokedCommandProperty:&_inUserInvokedNamesRequest];
            
            [mainWindow() updateTitleFor:c];

			break;
		}
		case 320: // RPL_WHOISSPECIAL
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
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
            TDCServerChannelListDialog *channelListDialog = [self listDialog];

			if ( channelListDialog) {
				[channelListDialog clear];
				
				[channelListDialog setContentAlreadyReceived:NO];
			}

			break;
		}
		case 322: // RPL_LIST
		{
			NSAssertReturn([m paramsCount] > 2);
			
			NSString *channel = [m paramAt:1];
			NSString *uscount = [m paramAt:2];
			NSString *topicva = [m sequence:3];

            TDCServerChannelListDialog *channelListDialog = [self listDialog];

			if (channelListDialog) {
				[channelListDialog addChannel:channel count:[uscount integerValue] topic:topicva];
			}

			break;
		}
		case 323: // RPL_LISTEND
		{
			TDCServerChannelListDialog *channelListDialog = [self listDialog];
			
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
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

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
		case 346: // RPL_INVITELIST
		case 348: // RPL_EXCEPTLIST
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *channelName = [m paramAt:1];

			NSString *entryMask = [m paramAt:2];
			NSString *entryAuthor = TXTLS(@"BasicLanguage[1002]");

			BOOL extendedLine = ([m paramsCount] > 4);

			NSDate *entryCreationDate = nil;

			if (extendedLine) {
				entryCreationDate = [NSDate dateWithTimeIntervalSince1970:[[m paramAt:4] doubleValue]];

				entryAuthor = [[m paramAt:3] nicknameFromHostmask];
			}

			TDChannelBanListSheet *listSheet = [windowController() windowFromWindowList:@"TDChannelBanListSheet"];

            if (listSheet) {
				if ([listSheet contentAlreadyReceived]) {
					[listSheet clear];

					[listSheet setContentAlreadyReceived:NO];
				}

				[listSheet addEntry:entryMask setBy:entryAuthor creationDate:entryCreationDate];
			} else {
				if (printMessage == NO) {
					return;
				}

				NSString *localization = nil;

				if (n == 367) { // RPL_BANLIST
					localization = @"1102";
				} else if (n == 346) { // RPL_INVITELIST
					localization = @"1103";
				} else if (n == 348) { // RPL_EXCEPTLIST
					localization = @"1104";
				}

				if (extendedLine) {
					localization = [NSString stringWithFormat:@"IRC[%@][1]", localization];
				} else {
					localization = [NSString stringWithFormat:@"IRC[%@][2]", localization];
				}

				NSString *text = nil;

				if (extendedLine) {
					text = TXTLS(localization, channelName, entryMask, entryAuthor, entryCreationDate);
				} else {
					text = TXTLS(localization, channelName, entryMask);
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
		case 347: // RPL_ENDOFINVITELIST
		case 349: // RPL_ENDOFEXCEPTLIST
		{
			TDChannelBanListSheet *listSheet = [windowController() windowFromWindowList:@"TDChannelBanListSheet"];

			if ( listSheet) {
				[listSheet setContentAlreadyReceived:YES];
			} else {
				if (printMessage) {
					[self printReply:m];
				}
			}

			break;
		}
		case 381: // RPL_YOUREOPER
		{
			if (self.hasIRCopAccess == NO) {
				/* If we are already an IRCOp, then we do not need to see this line again.
				 We will assume that if we are seeing it again, then it is the result of a
				 user opening two connections to a single bouncer session. */

				if (printMessage) {
					[self print:nil
						   type:TVCLogLineDebugType
					   nickname:nil
					messageBody:TXTLS(@"IRC[1076]", [m senderNickname])
					 receivedAt:[m receivedAt]
						command:[m command]];
				}

				self.hasIRCopAccess = YES;
			}

			break;
		}
		case 328: // RPL_CHANNEL_URL
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
			NSString *channel = [m paramAt:1];
			NSString *website = [m paramAt:2];

			IRCChannel *c = [self findChannel:channel];

			if (c) {
				if (website) {
					[self print:c
						   type:TVCLogLineWebsiteType
					   nickname:nil
					messageBody:TXTLS(@"IRC[1042]", website)
					 receivedAt:[m receivedAt]
						command:[m command]];
				}
			}

			break;
		}
		case 369: // RPL_ENDOFWHOWAS
		{
			[self disableInUserInvokedCommandProperty:&_inUserInvokedWhowasRequest];

			if (printMessage) {
				[self print:[mainWindow() selectedChannelOn:self]
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:[m sequence]
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 602: // RPL_WATCHOFF
		case 606: // RPL_WATCHLIST
		case 607: // RPL_ENDOFWATCHLIST
		case 608: // RPL_CLEARWATCH
		{
			if (self.inUserInvokedWatchRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}
			}

			if (n == 608 || n == 607) {
				[self disableInUserInvokedCommandProperty:&_inUserInvokedWatchRequest];
			}

			break;
		}
		case 600: // RPL_LOGON
		case 601: // RPL_LOGOFF
		case 604: // RPL_NOWON
		case 605: // RPL_NOWOFF
		{
			NSAssertReturn([m paramsCount] > 4);

			if (self.inUserInvokedWatchRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}

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

				ignoreChecks = [self checkIgnoreAgainstHostmask:hostmaskwnn withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];
			} else {
				ignoreChecks = [self checkIgnoreAgainstHostmask:[nickname stringByAppendingString:@"!-@-"] withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];
			}

			/* We only continue if there is an actual address book match for the nickname. */
			PointerIsEmptyAssert(ignoreChecks);

			if (n == 600) // logged online
			{
				[self handleUserTrackingNotification:ignoreChecks nickname:nickname localization:@"Notifications[1043]"];
			}
			else if (n == 601) // logged offline
			{
				[self handleUserTrackingNotification:ignoreChecks nickname:nickname localization:@"Notifications[1042]"];
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
			NSAssertReturn([m paramsCount] == 3);

			NSAssertReturn(printMessage);

			NSString *sendern = [m paramAt:1];
			
			[self printDebugInformation:TXTLS(@"IRC[1088]", sendern)];
			
			break;
		}
		case 718:
		{
			NSAssertReturn([m paramsCount] == 4);

			NSAssertReturn(printMessage);
			
			NSString *sendern = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
				IRCChannel *c = [mainWindow() selectedChannelOn:self];

				[self printDebugInformation:TXTLS(@"IRC[1089]", sendern, hostmask) channel:c];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1089]", sendern, hostmask)];
			}

			break;
		}
		case 900: // RPL_LOGGEDIN
		{
			NSAssertReturn([m paramsCount] > 3);

			[self enableCapacity:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL];

			if (printMessage) {
				[self print:nil
					   type:TVCLogLineDebugType
				   nickname:nil
				messageBody:[m sequence:3]
				 receivedAt:[m receivedAt]
					command:[m command]];
			}

			break;
		}
		case 903: // RPL_SASLSUCCESS
		case 904: // ERR_SASLFAIL
		case 905: // ERR_SASLTOOLONG
		case 906: // ERR_SASLABORTED
		case 907: // ERR_SASLALREADY
		{
			if (printMessage) {
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
			}

			if (_capacitiesPending &   ClientIRCv3SupportedCapacityIsInSASLNegotiation) {
				_capacitiesPending &= ~ClientIRCv3SupportedCapacityIsInSASLNegotiation;

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

			if (printMessage) {
				[self printUnknownReply:m];
			}

			break;
		}
	}
}

- (void)receiveErrorNumericReply:(IRCMessage *)m
{
	NSInteger n = [m commandNumeric];

	BOOL printMessage = [self postReceivedMessage:m];

	switch (n) {
		case 401: // ERR_NOSUCHNICK
		{
			NSAssertReturn(printMessage);

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
			NSAssertReturn(printMessage);

			NSString *text = TXTLS(@"IRC[1055]", n, [m sequence:1]);
			
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
				if (printMessage) {
					[self printUnknownReply:m];
				}

				break;
			}
			
			[self receiveNickCollisionError:m];

			break;
		}
		case 404: // ERR_CANNOTSENDTOCHAN
		{
			NSAssertReturn(printMessage);

			NSString *text = TXTLS(@"IRC[1055]", n, [m sequence:2]);

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

			if (printMessage) {
				[self printErrorReply:m];
			}

			break;
		}
		default:
		{
			if (printMessage) {
				[self printErrorReply:m];
			}

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
	[self performAutoJoin:NO];
}

- (void)performAutoJoin:(BOOL)userInitialized
{
	if (userInitialized == NO) {
		/* Ignore previous invocations of this method. */
		if (self.autojoinInProgress || self.isAutojoined) {
			return;
		}

		/* Ignore autojoin based on ZNC preferences. */
		if (self.isZNCBouncerConnection && self.config.zncIgnoreConfiguredAutojoin) {
			self.isAutojoined = YES;
		
			return;
		}

		/* Do nothing unless certain conditions are met. */
		if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL] == NO) {
			if (self.config.autojoinWaitsForNickServ) {
				if (self.serverHasNickServ && self.isIdentifiedWithNickServ == NO) {
					return;
				}
			}
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
			if ([c isChannel] && [c isActive] == NO) {
				if (c.config.autoJoin) {
					[ary addObject:c];
				}
			}
		}

		[self joinAutoJoinChannels:ary withKeys:NO];
		[self joinAutoJoinChannels:ary withKeys:YES];
		
		/* Update status later. */
		[self cancelPerformRequestsWithSelector:@selector(autojoinInProgress) object:nil]; // User might invoke -performAutojoin while timer is active

		[self performSelector:@selector(updateAutoJoinStatus) withObject:nil afterDelay:25.0];
	}
}


- (void)joinAutoJoinChannels:(NSArray *)channels withKeys:(BOOL)passKeys
{
	NSMutableString *channelList = [NSMutableString string];
	NSMutableString *passwordList = [NSMutableString string];

	NSInteger channelCount = 0;

	for (IRCChannel *c in channels) {
		if ([c status] != IRCChannelStatusParted) {
			LogToConsole(@"Refusing to join %@ because of status: %ld", [c name], [c status]);

			continue;
		}

		NSMutableString *previousChannelList = [channelList mutableCopy];
		NSMutableString *previousPasswordList = [passwordList mutableCopy];

		BOOL channelListEmpty = NSObjectIsEmpty(channelList);
		BOOL passwordListEmpty = NSObjectIsEmpty(passwordList);

		NSString *secretKey = [c secretKey];

		if (NSObjectIsNotEmpty(secretKey)) {
			if (passKeys == NO) {
				continue;
			}

			if ( passwordListEmpty == NO) {
				[passwordList appendString:@","];
			}

			[passwordList appendString:secretKey];
		} else {
			if (passKeys) {
				continue;
			}
		}

		if ( channelListEmpty == NO) {
			[channelList appendString:@","];
		}

		[channelList appendString:[c name]];

		[c setStatus:IRCChannelStatusJoining];

		if (channelCount > [TPCPreferences autojoinMaximumChannelJoins]) {
			/* Send previous lists. */
			if (NSObjectIsEmpty(previousPasswordList)) {
				[self send:IRCPrivateCommandIndex("join"), previousChannelList, nil];
			} else {
				[self send:IRCPrivateCommandIndex("join"), previousChannelList, previousPasswordList, nil];
			}

			[channelList setString:[c name]];

			if (NSObjectIsNotEmpty(secretKey)) {
				[passwordList setString:secretKey];
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

#pragma mark -
#pragma mark Post Events

- (void)postEventToViewController:(NSString *)eventToken
{
	if ([themeSettings() js_postHandleEventNotifications] == NO) {
		return; // Cancel operation...
	}

	[self postEventToViewController:eventToken forItem:self];

	@synchronized(self.channels) {
		for (IRCChannel *channel in self.channels) {
			[self postEventToViewController:eventToken forItem:channel];
		}
	}
}

- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel
{
	if ([themeSettings() js_postHandleEventNotifications] == NO) {
		return; // Cancel operation...
	}

	[self postEventToViewController:eventToken forItem:channel];
}

- (void)postEventToViewController:(NSString *)eventToken forItem:(IRCTreeItem *)item
{
	[[item viewController] evaluateFunction:@"Textual.handleEvent" withArguments:@[eventToken] onQueue:NO];
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
		[self stopPongTimer];

		return;
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
			[self printDebugInformation:TXTLS(@"IRC[1053]", (timeSpent / 60.0)) channel:nil];

			[self performBlockOnMainThread:^{
				[self disconnect];
			}];
		} else if (self.timeoutWarningShownToUser == NO) {
			[self printDebugInformation:TXTLS(@"IRC[1054]", (timeSpent / 60.0)) channel:nil];
			
			self.timeoutWarningShownToUser = YES;
		}
	} else if (timeSpent >= _pingInterval) {
		[self send:IRCPrivateCommandIndex("ping"), [self networkAddress], nil];
	}
}

- (void)startReconnectTimer
{
	if ((self.reconnectEnabledBecauseOfSleepMode	   && self.config.autoSleepModeDisconnect) ||
		(self.reconnectEnabledBecauseOfSleepMode == NO && self.config.autoReconnect))
	{
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
		if (self.config.hideNetworkUnavailabilityNotices == NO) {
			[self printDebugInformationToConsole:TXTLS(@"IRC[1011]", _reconnectInterval)];
		}
	} else {
		if (self.isConnected == NO) {
			[self connect:IRCClientConnectReconnectMode];
		}
	}
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
	[self performBlockOnMainThread:^{
		__weak IRCClient *weakSelf = self;
		
		self.disconnectCallback = ^{
			[weakSelf connect:IRCClientConnectRetryMode];
		};

		[self disconnect];
	}];
}

#pragma mark -
#pragma mark User Invoked Command Controls

- (void)enableInUserInvokedCommandProperty:(BOOL *)property
{
#define _inUserInvokedCommandTimeoutInterval		10.0

	if ( property && *property == NO) {
		*property = YES;

		[self performSelector:@selector(timeoutInUserInvokedCommandProperty:)
				   withObject:[NSValue valueWithPointer:property]
				   afterDelay:_inUserInvokedCommandTimeoutInterval];
	}

#undef _inUserInvokedCommandTimeoutInterval
}

- (void)disableInUserInvokedCommandProperty:(BOOL *)property
{
	if ( property && *property) {
		*property = NO;

		[self cancelPerformRequestsWithSelector:@selector(timeoutInUserInvokedCommandProperty:)
										 object:[NSValue valueWithPointer:property]];
	}
}

- (void)timeoutInUserInvokedCommandProperty:(NSValue *)propertyPointerValue
{
	void *pointerPointer = [propertyPointerValue pointerValue];

	if (pointerPointer) {
		pointerPointer = NO;
	}
}

#pragma mark -
#pragma mark Plugins and Scripts

- (void)outputTextualCmdScriptError:(NSString *)scriptPath input:(NSString *)scriptInput context:(NSDictionary *)userInfo error:(NSError *)originalError
{
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

	[self printDebugInformation:TXTLS(@"IRC[1003]", script, scriptInput, errord)];

	LogToConsole(@"%@", TXTLS(@"IRC[1002]", errorb))
}

- (void)postTextualCmdScriptResult:(NSString *)resultString to:(NSString *)destination
{
	IRCChannel *destinationChannel = [self findChannel:destination];

	PointerIsEmptyAssert(destinationChannel);

	[self performBlockOnMainThread:^{
		[self inputText:[resultString trim] command:IRCPrivateCommandIndex("privmsg") destination:destinationChannel];
	}];
}

- (void)executeTextualCmdScript:(NSDictionary *)details
{
	XRPerformBlockAsynchronouslyOnQueue([THOPluginDispatcher dispatchQueue], ^{
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
	NSString *userScriptsPath = [TPCPathInfo customScriptsFolderPath];

	if ([scriptPath hasPrefix:userScriptsPath]) {
		MLNonsandboxedScript = YES;
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

		NSArray *splitInputArray = [scriptInput split:NSStringWhitespacePlaceholder];

		[arguments addObjectsFromArray:splitInputArray];

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
	[THOPluginDispatcher userInputCommandInvokedOnClient:self commandString:command messageString:message];
}

- (void)processBundlesServerMessage:(IRCMessage *)message
{
	[THOPluginDispatcher didReceiveServerInput:message onClient:self];
}

- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage
{
	return [self postReceivedMessage:referenceMessage withText:[referenceMessage sequence] destinedFor:nil];
}

- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage withText:(NSString *)text destinedFor:(IRCChannel *)textDestination
{
	return [self postReceivedCommand:[referenceMessage command] withText:text destinedFor:textDestination referenceMessage:referenceMessage];
}

- (BOOL)postReceivedCommand:(NSString *)command withText:(NSString *)text destinedFor:(IRCChannel *)textDestination referenceMessage:(IRCMessage *)referenceMessage
{
	return [THOPluginDispatcher receivedCommand:command
									   withText:text
									 authoredBy:[referenceMessage sender]
									destinedFor:textDestination
									   onClient:self
									 receivedAt:[referenceMessage receivedAt]];
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
	
	/* Do not wait for an actual connect before destroying the temporary
	 store. Once its defined, its to be nil'd out no matter what. */
	self.serverRedirectAddressTemporaryStore = nil;
	self.serverRedirectPortTemporaryStore = 0;

	/* Continue connection... */
	[self logFileWriteSessionBegin];

	if (mode == IRCClientConnectReconnectMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1060]")];
	} else if (mode == IRCClientConnectRetryMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1061]")];
	}

	/* Create socket. */
	self.socket = [IRCConnection new];
		
	self.socket.associatedClient = self;

	/* Begin populating configuration. */
	self.socket.serverAddress = socketAddress;
	self.socket.serverPort = socketPort;

	self.socket.connectionPrefersIPv6 = preferIPv6;

	self.socket.connectionPrefersSecuredConnection = self.config.prefersSecuredConnection;
	self.socket.connectionPrefersModernCiphers = self.config.connectionPrefersModernCiphers;
	self.socket.connectionShouldValidateCertificateChain = self.config.validateServerCertificateChain;

	self.socket.identityClientSideCertificate = self.config.identityClientSideCertificate;

	self.socket.proxyType = self.config.proxyType;

	if (self.socket.proxyType == IRCConnectionSocketSocks4ProxyType ||
		self.socket.proxyType == IRCConnectionSocketSocks5ProxyType ||
		self.socket.proxyType == IRCConnectionSocketHTTPProxyType ||
		self.socket.proxyType == IRCConnectionSocketHTTPSProxyType)
	{
		self.socket.proxyPort = self.config.proxyPort;
		self.socket.proxyAddress = self.config.proxyAddress;
		self.socket.proxyPassword = self.config.proxyPassword;
		self.socket.proxyUsername = self.config.proxyUsername;
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1056]", socketAddress, socketPort)];

	self.socket.floodControlDelayInterval = self.config.floodControlDelayTimerInterval;
	self.socket.floodControlMaximumMessageCount = self.config.floodControlMaximumMessages;

	/* Try to establish connection. */
	[self.socket open];
}

- (void)autoConnect:(NSInteger)delay afterWakeUp:(BOOL)afterWakeUp
{
	self.connectDelay = delay;

	if (afterWakeUp) {
		[self autoConnectAfterWakeUp];
	} else {
		if (self.connectDelay <= 0) {
			[self connect];
		} else {
			[self performSelector:@selector(connect) withObject:nil afterDelay:self.connectDelay];
		}
	}
}

- (void)autoConnectAfterWakeUp
{
	if (self.isLoggedIn) {
		return;
	}

	self.reconnectEnabledBecauseOfSleepMode = YES;

	if (self.connectDelay <= 0 || [self isHostReachable]) {
		[self connect:IRCClientConnectReconnectMode];
	} else {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1010]", self.connectDelay)];

		[self performSelector:@selector(autoConnectAfterWakeUp) withObject:nil afterDelay:self.connectDelay];
	}
}

- (void)disconnect
{
	[self cancelPerformRequestsWithSelector:@selector(disconnect) object:nil];

	if ( self.socket) {
		[self.socket close];
	}
	
	if ([masterController() applicationIsTerminating]) {
		masterController().terminatingClientCount -= 1;
	} else {
		[self postEventToViewController:@"serverDisconnected"];
	}
}

- (void)_disconnect
{
	[self changeStateOff];
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
	
	[self cancelReconnect];

	/* If isLoggedIn is NO, then it means that the socket
	 was just opened and we haven't received the welcome 
	 message from the IRCd yet. We do not have to gracefully
	 disconnect at this point. */
	if (self.isLoggedIn == NO) {
		[self disconnect];

		return;
	}

    [self postEventToViewController:@"serverDisconnecting"];

	self.isQuitting	= YES;

	[self.socket clearSendQueue];

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
	self.reconnectEnabledBecauseOfSleepMode = NO;

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
	[self joinChannel:channel password:nil];
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
		NSString *secretKey = [channel secretKey];

		if (NSObjectIsNotEmpty(secretKey)) {
			password = secretKey;
		} else {
			password = nil;
		}
	}
	
	[self forceJoinChannel:[channel name] password:password];
}

- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password
{
	NSObjectIsEmptyAssert(channel);
	
	if ([channel isChannelNameOn:self]) {
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
	
	if ([channel isChannelNameOn:self]) {
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

- (void)toggleAwayStatus:(BOOL)setAway
{
    [self toggleAwayStatus:setAway withReason:TXTLS(@"IRC[1031]")];
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
		
		/* If we have an away nickname configured but no preAawayNickname set,
		 then use the configured nickname instead. User probably was on bouncer
		 and relaunched Textual losing preAwayNickname.*/
		if (newNick == nil) {
			if (NSObjectIsNotEmpty(self.config.awayNickname)) {
				newNick = self.config.nickname;
			}
		}
	}

	if (NSObjectIsNotEmpty(newNick)) {
		[self changeNickname:newNick];
	}
}

- (void)presentCertificateTrustInformation
{
	if (     self.socket.isSecured) {
		if ( self.socket.connectionPrefersSecuredConnection) {
			[self.socket openSSLCertificateTrustDialog];
		}
	}
}

#pragma mark -
#pragma mark File Transfers

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize requestIdentifier:(NSString *)identifier
{
	NSString *description = nil;
	
	switch (type) {
		case TXNotificationFileTransferSendSuccessfulType:
		{
			description = TXTLS(@"Notifications[1036]", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			description = TXTLS(@"Notifications[1037]", filename, totalFilesize);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			description = TXTLS(@"Notifications[1038]", filename);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			description = TXTLS(@"Notifications[1039]", filename);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			description = TXTLS(@"Notifications[1040]", filename, totalFilesize);
			
			break;
		}
		default:
		{
			break;
		}
	}
	
	NSDictionary *info = @{
	   @"isFileTransferNotification" : @(YES),
	   @"fileTransferUniqeIdentifier" : identifier,
	   @"fileTransferNotificationType" : @(type)
	};
	
	[self notifyEvent:type lineType:0 target:nil nickname:nickname text:description userInfo:info];
}

- (void)receivedDCCQuery:(IRCMessage *)m message:(NSMutableString *)rawMessage ignoreInfo:(IRCAddressBookEntry *)ignoreChecks
{
	/* Gather inital information. */
	NSString *nickname = [m senderNickname];
	
	/* Only target ourself. */
	if (NSObjectsAreEqual([m paramAt:0], [self localNickname]) == NO) {
		return;
	}
	
	/* Gather basic information. */
	NSString *subcommand = [rawMessage uppercaseGetToken];
	
	BOOL isSendRequest = ([subcommand isEqualToString:@"SEND"]);
	BOOL isResumeRequest = ([subcommand isEqualToString:@"RESUME"]);
	BOOL isAcceptRequest = ([subcommand isEqualToString:@"ACCEPT"]);
	
	// Process file transfer requests.
	if (isSendRequest == NO &&
		isResumeRequest == NO &&
		isAcceptRequest == NO)
	{
		return;
	}

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
	}  else if (isAcceptRequest || isResumeRequest) {
	   if ([section4 hasPrefix:@"T"]) {
			section4 = [section4 substringFromIndex:1];
	   }
	}
	
	/* Valid values? */
	NSObjectIsEmptyAssert(section1);
	NSObjectIsEmptyAssert(section2);

	if (isSendRequest) {
		NSObjectIsEmptyAssert(section4);
	}

	/* Start data association. */
	NSString *hostAddress = nil;
	NSString *hostPort = nil;
	NSString *filename = nil;
	NSString *filesize = nil;
	NSString *transferToken = nil;
	
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
			
			hostAddress = [NSString stringWithFormat:@"%ld.%ld.%ld.%ld",(long) z, (long)y, (long)x, (long)w];
		} else {
			hostAddress = section2;
		}
	}
	else if (isResumeRequest || isAcceptRequest)
	{
		filename = [section1 safeFilename];
		filesize =  section3;

		hostPort = section2;

		transferToken = section4;

		hostAddress = nil;
	}

	if (transferToken && [transferToken length] == 0) {
		transferToken = nil;
	}

	/* Important check. */
	NSAssertReturn([filesize longLongValue] > 0);

	if ([transferToken length] > 0 && [transferToken isNumericOnly] == NO) {
		LogToConsole(@"Fatal error: Received transfer token that is not a number");

		goto present_error;
	}

	NSInteger hostPortInt = [hostPort integerValue];

	if (hostPortInt == 0 && transferToken == nil) {
		LogToConsole(@"Fatal error: Port cannot be zero without a transfer token");

		goto present_error;
	} else if (hostPortInt < 0 || hostPortInt > TXMaximumTCPPort) {
		LogToConsole(@"Fatal error: Port cannot be less than zero or greater than 65535");

		goto present_error;
	}

	NSInteger filesizeInt = [filesize integerValue];

	if (filesizeInt <= 0 || filesizeInt > 1000000000000000) { // 1 PB
		LogToConsole(@"Fatal error: Filesize is silly");

		goto present_error;
	}

	/* Process invidiual commands. */
	if (isSendRequest) {
		/* DCC SEND <filename> <peer-ip> <port> <filesize> [token] */

		if (transferToken) {
			TDCFileTransferDialogTransferController *e = [[self fileTransferController] fileTransferSenderMatchingToken:transferToken];

			/* 0 port indicates a new request in reverse DCC */
			if (hostPortInt == 0)
			{
				if (e == nil) {
					[self receivedDCCSend:nickname
								 filename:filename
								  address:hostAddress
									 port:hostPortInt
								 filesize:filesizeInt
									token:transferToken];

					return;
				} else {
					LogToConsole(@"Fatal error: Received reverse DCC request with token '%@' but the token already exists.", transferToken);

					goto present_error;
				}
			}
			else if (e)
			{
				if ([e transferStatus] != TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus) {
					LogToConsole(@"Fatal error: Unexpected request to begin transfer");

					goto present_error;
				} else {
					[e setHostAddress:hostAddress];

					[e setTransferPort:hostPortInt];

					[e didReceiveSendRequestFromClient];

					return;
				}
			}
		}
		else // transferToken
		{
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
	else if (isResumeRequest || isAcceptRequest)
	{
		TDCFileTransferDialogTransferController *e = nil;

		if (transferToken && hostPortInt == 0) {
			e = [[self fileTransferController] fileTransferSenderMatchingToken:transferToken];
		} else if (transferToken == nil && hostPortInt > 0) {
			e = [[self fileTransferController] fileTransferMatchingPort:hostPortInt];
		}

		if (e == nil) {
			LogToConsole(@"Fatal error: Could not locate file transfer that matches resume request");

			goto present_error;
		}

		if ((isResumeRequest && [e transferStatus] != TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus) ||
			(isAcceptRequest && [e transferStatus] != TDCFileTransferDialogTransferWaitingForResumeAcceptStatus))
		{
			LogToConsole(@"Fatal error: Bad transfer status");

			goto present_error;
		}

		if (isResumeRequest) {
			[e didReceiveResumeRequestFromClient:filesizeInt];
		} else {
			[e didReceiveResumeAcceptFromClient:filesizeInt];
		}

		return;
	}

	// Report an error
present_error:
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:TXTLS(@"IRC[1020]", nickname) command:TVCLogLineDefaultRawCommandValue];
}

- (void)receivedDCCSend:(NSString *)nickname filename:(NSString *)filename address:(NSString *)address port:(NSInteger)port filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	/* Inform of the DCC and possibly ignore it. */
	NSString *message = TXTLS(@"IRC[1019]", nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:message command:TVCLogLineDefaultRawCommandValue];
	
	if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyIgnoreAction) {
		return;
	}
	
	/* Add file. */
	NSString *addedRequest = [[self fileTransferController] addReceiverForClient:self nickname:nickname address:address port:port filename:filename filesize:totalFilesize token:transferToken];
	
	/* Value returned is nil if it failed to add. */
	if (addedRequest) {
		/* Post notification. */
		[self notifyFileTransfer:TXNotificationFileTransferReceiveRequestedType nickname:nickname filename:filename filesize:totalFilesize requestIdentifier:addedRequest];
	}
}

- (void)sendFileResume:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	NSString *escapedFileName = [self DCCSendEscapeFilename:filename];

	NSString *trail = nil;

	if ([transferToken length] > 0) {
		trail = [NSString stringWithFormat:@"%@ %lu %lli %@", escapedFileName, port, totalFilesize, transferToken];
	} else {
		trail = [NSString stringWithFormat:@"%@ %lu %lli", escapedFileName, port, totalFilesize];
	}

	[self sendCTCPQuery:nickname command:@"DCC RESUME" text:trail];
}

- (void)sendFileResumeAccept:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	NSString *escapedFileName = [self DCCSendEscapeFilename:filename];

	NSString *trail = nil;

	if ([transferToken length] > 0) {
		trail = [NSString stringWithFormat:@"%@ %lu %lli %@", escapedFileName, port, totalFilesize, transferToken];
	} else {
		trail = [NSString stringWithFormat:@"%@ %lu %lli", escapedFileName, port, totalFilesize];
	}

	[self sendCTCPQuery:nickname command:@"DCC ACCEPT" text:trail];
}

- (void)sendFile:(NSString *)nickname port:(NSInteger)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	NSString *escapedFileName = [self DCCSendEscapeFilename:filename];

	NSString *address = [self DCCTransferAddress];
	
	NSObjectIsEmptyAssert(address);

	NSString *trail = nil;

	if ([transferToken length] > 0) {
		trail = [NSString stringWithFormat:@"%@ %@ %lu %lli %@", escapedFileName, address, port, totalFilesize, transferToken];
	} else {
		trail = [NSString stringWithFormat:@"%@ %@ %lu %lli", escapedFileName, address, port, totalFilesize];
	}
	
	[self sendCTCPQuery:nickname command:@"DCC SEND" text:trail];
	
	NSString *message = TXTLS(@"IRC[1018]", nickname, filename, totalFilesize);
	
	[self print:nil type:TVCLogLineDCCFileTransferType nickname:nil messageBody:message command:TVCLogLineDefaultRawCommandValue];
}

- (NSString *)DCCSendEscapeFilename:(NSString *)filename
{
	NSString *filenameEscaped = [filename safeFilename];

	if ([filenameEscaped contains:NSStringWhitespacePlaceholder]) {
		return [NSString stringWithFormat:@"\"%@\"", filenameEscaped];
	}

	return filenameEscaped;
}

- (NSString *)DCCTransferAddress
{
	NSString *address = nil;

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
		
		address = [NSString stringWithFormat:@"%llu", a];
	}
	
	return address;
}

#pragma mark -
#pragma mark Command Queue

- (void)processCommandsInCommandQueue
{
	NSTimeInterval now = [NSDate unixTime];

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

			NSTimeInterval delta = ([m timerInterval] - [NSDate unixTime]);

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

- (void)handleUserTrackingNotification:(IRCAddressBookEntry *)ignoreItem nickname:(NSString *)nickname localization:(NSString *)localization
{
	if ([ignoreItem trackUserActivity]) {
		NSString *text = TXTLS(localization, nickname);

		[self notifyEvent:TXNotificationAddressBookMatchType lineType:TVCLogLineNoticeType target:nil nickname:nickname text:text];
	}
}

- (void)populateISONTrackedUsersList:(NSArray *)ignores
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
		if ([g trackUserActivity]) {
			NSString *lname = [g trackingNickname];

			if ([lname isHostmaskNicknameOn:self]) {
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
				if ([newEntries containsKeyIgnoringCase:lname] == NO) {
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

	NSAssertReturn(self.isBrokenIRCd_aka_Twitch == NO);

    NSMutableString *userstr = [NSMutableString string];

	/* Given all channels, we build a list of users if a channel is private message.
	 If a channel is an actual channel and it meets certain conditions, then we send
	 a WHO request here to gather away status information. */
	@synchronized(self.channels) {
		[self sendTimedWhoRequests];

		for (IRCChannel *channel in self.channels) {
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

- (void)sendTimedWhoRequests
{
#define _maximumChannelCountPerWhoBatchRequest			5
#define _maximumSingleChannelSizePerWhoBatchRequest		5000
#define _maximumTotalChannelSizePerWhoBatchRequest		2000

	NSInteger channelCount = [self.channels count];

	NSInteger startingPosition = self.lastWhoRequestChannelListIndex;

	if (startingPosition >= channelCount) {
		startingPosition = 0;
	}

	NSInteger currentPosition = startingPosition;

	NSInteger memberCount = 0;

	NSMutableArray *channelsToQuery = nil;

	while (1 == 1) {
		/* Break loop once if we will exceed hard limit by adding another channel. */
		if ([channelsToQuery count] == _maximumChannelCountPerWhoBatchRequest) {
			break;
		}

		/* Take current value and add it */
		NSInteger i = currentPosition;

		currentPosition += 1;

		if (currentPosition == channelCount) {
			currentPosition = 0;
		}

		if (currentPosition == startingPosition) {
			break;
		}

		/* Get channel and disregard it if it is not joined */
		IRCChannel *c = self.channels[i];

		if ([c isChannel] == NO || [c isActive] == NO) {
			continue;
		}

		/* Update internal state of flag */
		BOOL sentInitialWhoRequest = [c sentInitialWhoRequest];

		if (sentInitialWhoRequest == NO) {
			[c setSentInitialWhoRequest:YES];
		}

		/* continue to next channel and do not break so that the
		 -sentInitialWhoRequest flag of all channels can be updated. */
		if (self.config.sendWhoCommandRequestsToChannels == NO) {
			continue;
		}

		/* Perform comparisons to know whether channel is acceptable */
		NSInteger memberCountC = [c numberOfMembers];

		if (sentInitialWhoRequest == NO) {
			if (memberCountC > _maximumSingleChannelSizePerWhoBatchRequest) {
				continue;
			}
		} else {
			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]) {
				continue;
			}

			if (memberCountC > [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
				continue;
			}
		}

		/* Add channel to list */
		if (channelsToQuery == nil) {
			channelsToQuery = [NSMutableArray new];
		}

		[channelsToQuery addObject:c];

		/* Update total number of members and maybe break loop */
		memberCount += memberCountC;

		if (memberCount > _maximumTotalChannelSizePerWhoBatchRequest) {
			break;
		}
	}

	self.lastWhoRequestChannelListIndex = currentPosition;

	/* Send WHO requests */
	for (IRCChannel *c in channelsToQuery) {
		[self send:IRCPrivateCommandIndex("who"), [c name], nil];
	}

#undef _maximumChannelCountPerWhoBatchRequest
#undef _maximumSingleChannelSizePerWhoBatchRequest
#undef _maximumTotalChannelSizePerWhoBatchRequest
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
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] localization:@"Notifications[1043]"];
				
				[self.trackedUsers setBool:YES forKey:tracker];
			}
			
			return;
		}
		
		/* Notification Type: QUIT Command. */
		if ([[message command] isEqualIgnoringCase:@"QUIT"]) {
			if (ison) {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] localization:@"Notifications[1042]"];
				
				[self.trackedUsers setBool:NO forKey:tracker];
			}
			
			return;
		}
		
		/* Notification Type: NICK Command. */
		if ([[message command] isEqualIgnoringCase:@"NICK"]) {
			if (ison) {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] localization:@"Notifications[1042]"];
			} else {
				[self handleUserTrackingNotification:abEntry nickname:[message senderNickname] localization:@"Notifications[1043]"];
			}
			
			[self.trackedUsers setBool:(ison == NO) forKey:tracker];
		}
	}
}

#pragma mark -
#pragma mark Channel Ban List Dialog

- (void)createChannelInviteExceptionListSheet
{
	[self createChannelBanListSheet:TDChannelBanListSheetInviteExceptionEntryType];
}

- (void)createChannelBanExceptionListSheet
{
	[self createChannelBanListSheet:TDChannelBanListSheetBanExceptionEntryType];
}

- (void)createChannelBanListSheet
{
	[self createChannelBanListSheet:TDChannelBanListSheetBanEntryType];
}

- (void)createChannelBanListSheet:(TDChannelBanListSheetEntryType)entryType
{
	[windowController() popMainWindowSheetIfExists];

    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    
    PointerIsEmptyAssert(u);
    PointerIsEmptyAssert(c);

	TDChannelBanListSheet *listSheet = [TDChannelBanListSheet new];

	[listSheet setEntryType:entryType];

	[listSheet setDelegate:self];
	[listSheet setWindow:mainWindow()];
	
	[listSheet setClientID:[u uniqueIdentifier]];
	[listSheet setChannelID:[c uniqueIdentifier]];

	[listSheet show];

	[windowController() addWindowToWindowList:listSheet];
}

- (void)channelBanListSheetOnUpdate:(TDChannelBanListSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];

	if (c) {
		NSString *modeSend = [NSString stringWithFormat:@"+%@", [sender mode]];

		[self send:IRCPrivateCommandIndex("mode"), [c name], modeSend, nil];
	}
}

- (void)channelBanListSheetWillClose:(TDChannelBanListSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
	
	if (c) {
		NSArray *changedModes = [sender changeModeList];
		
		for (NSString *mode in changedModes) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [c name], mode]];
		}
	}

	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (NSString *)listDialogWindowKey
{
	return [NSString stringWithFormat:@"TDCServerChannelListDialog -> %@", [self uniqueIdentifier]];
}

- (TDCServerChannelListDialog *)listDialog
{
	return [windowController() windowFromWindowList:[self listDialogWindowKey]];
}

- (void)createChannelListDialog
{
	if ([windowController() maybeBringWindowForward:[self listDialogWindowKey]]) {
		return; // The window was brought forward already.
	}

    TDCServerChannelListDialog *channelListDialog = [TDCServerChannelListDialog new];

	[channelListDialog setClientID:[self uniqueIdentifier]];
	
	[channelListDialog setDelegate:self];
    
    [channelListDialog start];

	[windowController() addWindowToWindowList:channelListDialog withDescription:[self listDialogWindowKey]];
}

- (void)serverChannelListDialogOnUpdate:(TDCServerChannelListDialog *)sender
{
	[self sendLine:IRCPrivateCommandIndex("list")];
}

- (void)serverChannelListDialogOnJoin:(TDCServerChannelListDialog *)sender channel:(NSString *)channel
{
	[self enableInUserInvokedCommandProperty:&_inUserInvokedJoinRequest];
	
	[self joinUnlistedChannel:channel];
}

- (void)serverChannelDialogWillClose:(TDCServerChannelListDialog *)sender
{
	[windowController() removeWindowFromWindowList:[self listDialogWindowKey]];
}

@end
