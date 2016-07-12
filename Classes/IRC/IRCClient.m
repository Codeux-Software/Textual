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

#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

#define _isonCheckInterval			30
#define _pingInterval				270
#define _pongCheckInterval			30
#define _reconnectInterval			20
#define _retryInterval				240
#define _timeoutInterval			360

NSString * const IRCClientConfigurationWasUpdatedNotification = @"IRCClientConfigurationWasUpdatedNotification";

NSString * const IRCClientChannelListWasModifiedNotification = @"IRCClientChannelListWasModifiedNotification";

@interface IRCClient ()
// Properies that are public in IRCClient.h
@property (nonatomic, copy, readwrite) IRCClientConfig *config;
@property (nonatomic, strong, readwrite) IRCISupportInfo *supportInfo;
@property (nonatomic, assign, readwrite) BOOL isAutojoined;
@property (nonatomic, assign, readwrite) BOOL isAutojoining;
@property (nonatomic, assign, readwrite) BOOL isConnecting;
@property (nonatomic, assign, readwrite) BOOL isConnected;
@property (nonatomic, assign, readwrite) BOOL isConnectedToZNC;
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, assign, readwrite) BOOL isQuitting;
@property (nonatomic, assign, readwrite) BOOL isReconnecting;
@property (nonatomic, assign, readwrite) BOOL isSecured;
@property (nonatomic, assign, readwrite) BOOL userIsAway;
@property (nonatomic, assign, readwrite) BOOL userIsIRCop;
@property (nonatomic, assign, readwrite) BOOL userIsIdentifiedWithNickServ;
@property (nonatomic, assign, readwrite) BOOL isWaitingForNickServ;
@property (nonatomic, assign, readwrite) BOOL serverHasNickServ;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedIsonRequest;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedNamesRequest;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedWhoRequest;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedWhowasRequest;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedWatchRequest;
@property (nonatomic, assign, readwrite) BOOL inUserInvokedModeRequest;
@property (nonatomic, assign, readwrite) NSTimeInterval lastMessageReceived;
@property (nonatomic, assign, readwrite) NSTimeInterval lastMessageServerTime;
@property (nonatomic, assign, readwrite) ClientIRCv3SupportedCapacities capacities;
@property (nonatomic, copy, readwrite) NSArray<IRCHighlightLogEntry *> *cachedHighlights;
@property (nonatomic, copy, readwrite, nullable) NSString *userHostmask;
@property (nonatomic, copy, readwrite) NSString *userNickname;
@property (nonatomic, copy, readwrite, nullable) NSString *serverAddress;
@property (nonatomic, copy, readwrite, nullable) NSString *preAwayUserNickname;

// Properties private
@property (nonatomic, assign) BOOL configurationIsStale;
@property (nonatomic, strong, nullable) IRCConnection *socket;
@property (nonatomic, strong) IRCMessageBatchMessageContainer *batchMessages;
@property (nonatomic, strong, nullable) TLOFileLogger *logFile;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, weak, nullable) IRCChannel *lagCheckDestinationChannel;
@property (nonatomic, assign) BOOL capacityNegotiationIsPaused;
@property (nonatomic, assign) BOOL invokingISONCommandForFirstTime;
@property (nonatomic, assign) BOOL isTerminating; // Is being destroyed
@property (nonatomic, assign) BOOL rawModeEnabled;
@property (nonatomic, assign) BOOL reconnectEnabled;
@property (nonatomic, assign) BOOL reconnectEnabledBecauseOfSleepMode;
@property (nonatomic, assign) BOOL timeoutWarningShownToUser;
@property (nonatomic, assign) BOOL zncBoucnerIsSendingCertificateInfo;
@property (nonatomic, assign) BOOL zncBouncerIsPlayingBackHistory;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *capacitiesPending;
@property (nonatomic, assign) NSTimeInterval lagCheckLastCheck;
@property (nonatomic, assign) NSUInteger connectDelay;
@property (nonatomic, assign) NSUInteger lastWhoRequestChannelListIndex;
@property (nonatomic, assign) NSUInteger successfulConnects;
@property (nonatomic, assign) NSUInteger tryingNicknameNumber;
@property (nonatomic, copy, nullable) NSString *tryingNicknameSentNickname;
@property (nonatomic, strong) NSMutableArray<IRCChannel *> *channelListPrivate;
@property (nonatomic, strong) NSMutableArray<IRCTimerCommandContext *> *commandQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *trackedNicknames;
@property (nonatomic, strong, nullable) NSMutableString *zncBouncerCertificateChainDataMutable;
@property (nonatomic, copy) NSString *temporaryServerAddressOverride;
@property (nonatomic, assign) uint16_t temporaryServerPortOverride;
@property (readonly) BOOL isBrokenIRCd_aka_Twitch;
@property (readonly, copy) NSArray<NSString *> *nickServSupportedNeedIdentificationTokens;
@property (readonly, copy) NSArray<NSString *> *nickServSupportedSuccessfulIdentificationTokens;
@end

@implementation IRCClient

#pragma mark -
#pragma mark Initialization (Signed)

ClassWithDesignatedInitializerInitMethod

/* Signed */
DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	IRCClientConfig *config = [[IRCClientConfig alloc] initWithDictionary:dic];

	return [self initWithConfig:config];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

/* Signed */
- (instancetype)initWithConfig:(IRCClientConfig *)config
{
	NSParameterAssert(config != nil);

	if ((self = [super init])) {
		self.config = config;

		[self writePasswordsToKeychain];

		[self prepareInitialState];

		return self;
	}

	return nil;
}

/* Signed */
- (void)prepareInitialState
{
	self.batchMessages = [IRCMessageBatchMessageContainer new];

	self.supportInfo = [[IRCISupportInfo alloc] initWithClient:self];

	self.connectType = IRCClientConnectNormalMode;
	self.disconnectType = IRCClientDisconnectNormalMode;

	self.cachedHighlights = @[];

	self.capacitiesPending = [NSMutableArray array];
	self.channelListPrivate = [NSMutableArray array];
	self.commandQueue = [NSMutableArray array];

	self.trackedNicknames = [NSMutableDictionary dictionary];

	self.lastMessageServerTime = self.config.lastMessageServerTime;

#if defined(DEBUG)
	self.rawModeEnabled = YES;
#endif

	self.commandQueueTimer = [TLOTimer new];
	self.commandQueueTimer.repeatTimer = NO;
	self.commandQueueTimer.target = self;
	self.commandQueueTimer.action = @selector(onCommandQueueTimer:);

	self.isonTimer	= [TLOTimer new];
	self.isonTimer.repeatTimer = YES;
	self.isonTimer.target = self;
	self.isonTimer.action = @selector(onISONTimer:);

	self.reconnectTimer = [TLOTimer new];
	self.reconnectTimer.repeatTimer = YES;
	self.reconnectTimer.target = self;
	self.reconnectTimer.action = @selector(onReconnectTimer:);

	self.retryTimer = [TLOTimer new];
	self.retryTimer.repeatTimer = NO;
	self.retryTimer.target = self;
	self.retryTimer.action = @selector(onRetryTimer:);

	self.pongTimer = [TLOTimer new];
	self.pongTimer.repeatTimer = YES;
	self.pongTimer.target = self;
	self.pongTimer.action = @selector(onPongTimer:);
}

/* Signed */
- (void)dealloc
{
	[self.batchMessages clearQueue];

	[self.commandQueueTimer stop];
	[self.isonTimer	stop];
	[self.pongTimer	stop];
	[self.reconnectTimer stop];
	[self.retryTimer stop];

	self.commandQueueTimer = nil;
	self.isonTimer = nil;
	self.pongTimer = nil;
	self.reconnectTimer = nil;
	self.retryTimer = nil;

	[self cancelPerformRequests];
}

/* Signed */
- (void)updateConfigFromTheCloud:(IRCClientConfig *)config
{
	NSParameterAssert(config != nil);

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	IRCClientConfig *currentConfig = self.config;
#endif

	[self updateConfig:config updateSelection:YES importingFromCloud:YES];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	if (self.config.excludedFromCloudSyncing != currentConfig.excludedFromCloudSyncing &&
		self.config.excludedFromCloudSyncing == NO)
	{
		[worldController() cloud_removeClientFromListOfDeletedClients:self.uniqueIdentifier];
	}
#endif
}

/* Signed */
- (void)updateConfig:(IRCClientConfig *)config
{
	[self updateConfig:config updateSelection:YES];
}

/* Signed */
- (void)updateConfig:(IRCClientConfig *)config updateSelection:(BOOL)updateSelection
{
	[self updateConfig:config updateSelection:updateSelection importingFromCloud:NO];
}

/* Signed */
- (void)updateConfig:(IRCClientConfig *)config updateSelection:(BOOL)updateSelection importingFromCloud:(BOOL)importingFromCloud
{
	NSParameterAssert(config != nil);

	if (self.isTerminating) {
		return;
	}

	IRCClientConfig *currentConfig = self.config;

	if (currentConfig) {
		if ([currentConfig isEqual:config]) {
			return;
		}

		if (NSObjectsAreEqual(currentConfig.uniqueIdentifier, config.uniqueIdentifier) == NO) {
			LogToConsoleError("Tried to load configuration for incorrect client")

			return;
		}
	}

	/* Populate new configuration */
	/* Some configuration properties (such as -identityClientSideCertificate) cannot be synced
	 between devices. So that this property is not lost when importing a configuration from 
	 iCloud that is missing it, the configurations are merged, instead of copying.
	 This process has overhead which means its only used for cloud imports. */
	if (importingFromCloud) {
		self.config = [IRCClientConfig newConfigByMerging:currentConfig with:config];
	} else {
		self.config = config;
	}

	/* Update channel list */
	{
		NSMutableArray<IRCChannel *> *channelListOld = [self.channelList mutableCopy];

		NSMutableArray<IRCChannel *> *channelListNew = [NSMutableArray array];

		NSMutableArray<NSString *> *channelListNewNames = [NSMutableArray array];

		NSArray *channelConfigurations = self.config.channelList;

		for (IRCChannelConfig *channelConfig in channelConfigurations) {
			/* Block duplicate channel names by maintaining array of names */
			NSString *channelName = channelConfig.channelName;

			if ([channelListNewNames containsObject:channelName] == NO) {
				[channelListNewNames addObject:channelName];
			} else {
				continue;
			}

			/* Check whether the channel exists in the current list of channels */
			/* If it does not exist, then create it. Otherwise, update it. */
			IRCChannel *channel = [self findChannel:channelConfig.channelName inList:channelListOld];

			if (channel == nil) {
				channel = [worldController() createChannelWithConfig:channelConfig onClient:self add:NO adjust:NO reload:NO];
			} else {
				[channel updateConfig:channelConfig fireChangedNotification:NO updateStoredChannelList:NO];

				[channelListOld removeObjectIdenticalTo:channel];
			}

			[channelListNew addObject:channel];
		}

		/* Any channels left in the old array can be destroyed 
		 or if they are not a channel, then they can be reinserted
		 because we do not care about private messages being updated
		 above so they must be reinserted here. */
		for (IRCChannel *channel in channelListOld) {
			if (channel.isPrivateMessage) {
				[channelListNew addObject:channel];
			} else {
				[worldController() destroyChannel:channel reload:NO];
			}
		}

		/* Save updated channel list then safe its contents */
		self.channelList = channelListNew;
	}
	
	/* -reloadItem will drop the views and reload them. */
	/* We need to remember the selection because of this. */
	if (updateSelection) {
		[self reloadServerListItems];
	}

	/* Update navigation list */
	[menuController() populateNavgiationChannelList];

	/* Write passwords to keychain */
	[self writePasswordsToKeychain];

	/* Update main window title */
	[mainWindow() updateTitleFor:self];

	/* Rebuild list of users that are ignored and/or tracked */
	[self populateISONTrackedUsersList];
	
	/* Post notification */
	[RZNotificationCenter() postNotificationName:IRCClientConfigurationWasUpdatedNotification object:self];
}

/* Signed */
- (void)reloadServerListItems
{
	mainWindow().ignoreOutlineViewSelectionChanges = YES;

	[mainWindowServerList() beginUpdates];

	[mainWindowServerList() reloadItem:self reloadChildren:YES];

	[mainWindowServerList() endUpdates];

	[mainWindow() adjustSelection];

	mainWindow().ignoreOutlineViewSelectionChanges = NO;
}

/* Signed */
- (void)writePasswordsToKeychain
{
	[self.config writeItemsToKeychain];
}

/* Signed */
- (void)updateStoredConfiguration
{
	if (self.configurationIsStale == NO) {
		return;
	}

	IRCClientConfigMutable *configMutable = [self.config mutableCopy];

	configMutable.lastMessageServerTime = self.lastMessageServerTime;

	configMutable.sidebarItemExpanded = self.sidebarItemIsExpanded;

	self.config = configMutable;
}

/* Signed */
- (void)updateStoredChannelList
{
	/* Rebuild list of channel configurations */
	NSMutableArray<IRCChannelConfig *> *channelList = [NSMutableArray array];

	for (IRCChannel *channel in self.channelList) {
		if (channel.isChannel == NO && [TPCPreferences rememberServerListQueryStates] == NO) {
			continue;
		}

		[channelList addObject:channel.config];
	}

	/* Save list */
	IRCClientConfigMutable *mutableConfig = [self.config mutableCopy];
	
	mutableConfig.channelList = channelList;

	self.config = mutableConfig;

	/* Post notificaion */
	[RZNotificationCenter() postNotificationName:IRCClientChannelListWasModifiedNotification object:self];
}

/* Signed */
- (NSDictionary<NSString *, id> *)configurationDictionary
{
	[self updateStoredConfiguration];

	return [self.config dictionaryValue];
}

/* Signed */
- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud
{
	[self updateStoredConfiguration];

	return [self.config dictionaryValue:YES];
}

/* Signed */
- (void)prepareForApplicationTermination
{
	self.isTerminating = YES;

	[self closeDialogs];

	if (self.isConnecting || self.isConnected) {
		__weak IRCClient *weakSelf = self;

		self.disconnectCallback = ^{
			[weakSelf prepareForApplicationTerminationPostflight];
		};

		[self quit];

		return;
	}

	[self prepareForApplicationTerminationPostflight];
}

- (void)prepareForApplicationTerminationPostflight
{
	[self closeLogFile];

	for (IRCChannel *c in self.channelList) {
		[c prepareForApplicationTermination];
	}

	[self.viewController prepareForApplicationTermination];

	masterController().terminatingClientCount -= 1;
}

/* Signed */
- (void)prepareForPermanentDestruction
{
	self.isTerminating = YES;

//	[self disconnect];	// Disconnect is called by IRCWorld for us
	
	[self closeDialogs];

	[self closeLogFile];
	
	[self.config destroyKeychainItems];

	for (IRCChannel *c in self.channelList) {
		[c prepareForPermanentDestruction];
	}

	[[mainWindow() inputHistoryManager] destroy:self];
	
	[self.viewController prepareForPermanentDestruction];
}

/* Signed */
- (void)closeDialogs
{
	TDCServerChannelListDialog *channelListDialog = [self channelListDialog];
	
	if (channelListDialog) {
		[channelListDialog close];
	}
	
	NSArray *openWindows =
	[windowController() windowsFromWindowList:@[@"TDCChannelInviteSheet",
												@"TDCServerChangeNicknameSheet",
												@"TDCServerHighlightListSheet",
												@"TDCServerPropertiesSheet"]];

	for (TDCSheetBase <TDCClientPrototype> *windowObject in openWindows) {
		if (NSObjectsAreEqual(windowObject.clientId, self.uniqueIdentifier)) {
			[windowObject close];
		}
	}
}

/* Signed */
- (void)preferencesChanged
{
	[self reopenLogFileIfNeeded];

	[self.viewController preferencesChanged];

	for (IRCChannel *c in self.channelList) {
		[c preferencesChanged];

		[self maybeResetUserAwayStatusForChannel:c];
	}
}

/* Signed */
- (void)maybeResetUserAwayStatusForChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]) {
		return;
	}

	NSArray *memberList = channel.memberList;

	if (memberList.count < [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
		return;
	}

	for (IRCUser *member in memberList) {
		[member markAsReturned];
	}
}

/* Signed */
- (void)willDestroyChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self zncPlaybackClearChannel:channel];
}

#pragma mark -
#pragma mark Properties (Signed)

/* Signed */
- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCClient [%@]: %@>", self.networkNameAlt, self.serverAddress];
}

/* Signed */
- (NSString *)uniqueIdentifier
{
	return self.config.uniqueIdentifier;
}

/* Signed */
- (NSString *)name
{
	return self.config.connectionName;
}

/* Signed */
- (nullable NSString *)networkName
{
	return self.supportInfo.networkNameFormatted;
}

/* Signed */
- (NSString *)networkNameAlt
{
	NSString *networkName = self.networkName;

	if (networkName) {
		return networkName;
	}

	return self.config.connectionName;
}

/* Signed */
- (nullable NSString *)serverAddress
{
	return self.supportInfo.serverAddress;
}

/* Signed */
- (NSString *)userNickname
{
	NSString *userNickname = self->_userNickname;

	if (userNickname) {
		return userNickname;
	}

	return self.config.nickname;
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (NSString *)encryptionAccountNameForLocalUser
{
	return [sharedEncryptionManager() accountNameForUser:self.userNickname onClient:self];
}

- (NSString *)encryptionAccountNameForUser:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	return [sharedEncryptionManager() accountNameForUser:nickname onClient:self];
}
#endif

/* Signed */
- (TDCFileTransferDialog *)fileTransferController
{
	return menuController().fileTransferController;
}

/* Signed */
- (BOOL)isReconnecting
{
	return self.reconnectTimer.timerIsActive;
}

/* Signed */
- (void)setSidebarItemIsExpanded:(BOOL)sidebarItemIsExpanded
{
	/* This is a non-critical property that can be saved periodically */
	if (self->_sidebarItemIsExpanded != sidebarItemIsExpanded) {
		self->_sidebarItemIsExpanded = sidebarItemIsExpanded;

		self.configurationIsStale = YES;

		[worldController() savePeriodically];
	}
}

/* Signed */
- (void)setLastMessageServerTime:(NSTimeInterval)lastMessageServerTime
{
	/* This is a non-critical property that can be saved periodically */
	if (self->_lastMessageServerTime != lastMessageServerTime) {
		self->_lastMessageServerTime = lastMessageServerTime;

		self.configurationIsStale = YES;

		[worldController() savePeriodically];
	}
}

/* Signed */
- (BOOL)isSecured
{
	if (self.socket) {
		return self.socket.isSecured;
	}

	return NO;
}

/* Signed */
- (nullable NSData *)zncBouncerCertificateChainData
{
	/* If the data is stll being processed, then return
	 nil so that partial data is not returned. */
	if (self.isConnectedToZNC == NO ||
		self.zncBoucnerIsSendingCertificateInfo ||
		self.zncBouncerCertificateChainDataMutable == nil)
	{
		return nil;
	}

	return [self.zncBouncerCertificateChainDataMutable dataUsingEncoding:NSASCIIStringEncoding];
}

/* Signed */
- (BOOL)isBrokenIRCd_aka_Twitch
{
	return [self.serverAddress hasSuffix:@".twitch.tv"];
}

#pragma mark -
#pragma mark Standalone Utilities

/* Signed */
- (BOOL)messageIsFromMyself:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	return [self nicknameIsMyself:message.senderNickname];
}

/* Signed */
- (BOOL)nicknameIsMyself:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	return NSObjectsAreEqual(nickname, self.userNickname);
}

/* Signed */
- (BOOL)stringIsNickname:(NSString *)string
{
	NSParameterAssert(string != nil);

	return ([string isHostmaskNicknameOn:self] && [string isChannelNameOn:self] == NO);
}

/* Signed */
- (BOOL)stringIsChannelName:(NSString *)string
{
	NSParameterAssert(string != nil);

	return [string isChannelNameOn:self];
}

- (BOOL)stringIsChannelNameOrZero:(NSString *)string
{
	NSParameterAssert(string != nil);

	return ([self stringIsChannelName:string] || [string isEqualToString:@"0"]);
}

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet paramaterString:(NSString *)paramaterString
{
	return [self compileListOfModeChangesForModeSymbol:modeSymbol modeIsSet:modeIsSet paramaterString:paramaterString characterSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet paramaterString:(NSString *)paramaterString characterSet:(NSCharacterSet *)characterList
{
	NSParameterAssert(paramaterString != nil);
	NSParameterAssert(characterList != nil);

	NSArray *modeParamaters = [paramaterString componentsSeparatedByCharactersInSet:characterList];

	return [self compileListOfModeChangesForModeSymbol:modeSymbol modeIsSet:modeIsSet modeParamaters:modeParamaters];
}

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet modeParamaters:(NSArray<NSString *> *)modeParamaters
{
	NSParameterAssert(modeSymbol.length == 1);
	NSParameterAssert(modeParamaters != nil);

	if (modeParamaters.count == 0) {
		return @[];
	}

	NSMutableArray<NSString *> *listOfChanges = [NSMutableArray array];

	NSMutableString *modeSetString = [NSMutableString string];
	NSMutableString *modeParamString = [NSMutableString string];

	NSUInteger numberOfEntries = 0;

	for (NSString *modeParamater in modeParamaters) {
		if (modeParamater.length == 0) {
			continue;
		}

		if (modeSetString.length == 0) {
			if (modeIsSet) {
				[modeSetString appendFormat:@"+%@", modeSymbol];
			} else {
				[modeSetString appendFormat:@"-%@", modeSymbol];
			}
		} else {
			[modeSetString appendString:modeSymbol];
		}

		[modeParamString appendFormat:@" %@", modeParamater];

		numberOfEntries += 1;

		if (numberOfEntries == self.supportInfo.maximumModeCount) {
			numberOfEntries = 0;

			NSString *modeSetCombined = [modeSetString stringByAppendingString:modeParamString];

			[listOfChanges addObject:modeSetCombined];

			[modeSetString setString:NSStringEmptyPlaceholder];
			[modeParamString setString:NSStringEmptyPlaceholder];
		}
	}

	if (modeSetString.length > 0 && modeParamString.length > 0) {
		NSString *modeSetCombined = [modeSetString stringByAppendingString:modeParamString];

		[listOfChanges addObject:modeSetCombined];
	}

	return [listOfChanges copy];
}

#pragma mark -
#pragma mark Highlights (Signed)

/* Signed */
- (void)clearCachedHighlights
{
	self.cachedHighlights = @[];
}

/* Signed */
- (void)cacheHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(logLine != nil);

	if ([TPCPreferences logHighlights] == NO) {
		return;
	}

	/* Render message */
	NSString *nicknameBody = [logLine formattedNicknameInChannel:channel];
	
	NSString *messageBody = nil;

	if (logLine.lineType == TVCLogLineActionType) {
		if ([nicknameBody hasSuffix:@":"]) {
			messageBody = [NSString stringWithFormat:TXNotificationHighlightLogAlternativeActionFormat, nicknameBody.trim, logLine.messageBody];
		} else {
			messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardActionFormat, nicknameBody.trim, logLine.messageBody];
		}
	} else {
		messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardMessageFormat, nicknameBody.trim, logLine.messageBody];
	}

	NSAttributedString *messageBodyRendered = [messageBody attributedStringWithIRCFormatting:[NSTableView preferredGlobalTableViewFont] preferredFontColor:[NSColor blackColor]];

	/* Create entry */
	IRCHighlightLogEntryMutable *newEntry = [IRCHighlightLogEntryMutable new];

	newEntry.clientId = self.uniqueIdentifier;
	newEntry.channelId = channel.uniqueIdentifier;

	newEntry.lineNumber = logLine.uniqueIdentifier;

	newEntry.renderedMessage = messageBodyRendered;

	newEntry.timeLogged = [NSDate date];

	/* We insert at head so that latest is always on top. */
	NSMutableArray *cachedHighlights = [self.cachedHighlights mutableCopy];

	[cachedHighlights insertObject:[newEntry copy] atIndex:0];

	self.cachedHighlights = cachedHighlights;
	
	/* Reload table if the window is open. */
	TDCServerHighlightListSheet *highlightListSheet = [windowController() windowFromWindowList:@"TDCServerHighlightListSheet"];

	if (NSObjectsAreEqual(highlightListSheet.clientId, self.uniqueIdentifier) == NO) {
		return;
	}

	[highlightListSheet addEntry:self.cachedHighlights.firstObject];
}

#pragma mark -
#pragma mark Reachability (Signed)

/* Signed */
- (void)noteReachabilityChanged:(BOOL)reachable
{
	if (reachable) {
		return;
	}

	[self disconnectOnReachabilityChange];
}

/* Signed */
- (void)disconnectOnReachabilityChange
{
	if (self.isLoggedIn == NO) {
		return;
	}

	if (self.config.performDisconnectOnReachabilityChange == NO) {
		return;
	}

	self.disconnectType = IRCClientDisconnectReachabilityChangeMode;

	self.reconnectEnabled = YES;

	[self performBlockOnMainThread:^{
		[self disconnect];
	}];
}

#pragma mark -
#pragma mark Channel Storage

/* Signed */
- (void)selectFirstChannelInChannelList
{
	NSArray *channelList = self.channelList;

	if (channelList.count == 0) {
		return;
	}

	[mainWindow() select:channelList[0]];
}

/* Signed */
- (void)addChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized(self.channelListPrivate) {
		if ([self.channelListPrivate containsObject:channel]) {
			return;
		}

		if (channel.isChannel == NO)
		{
			[self.channelListPrivate addObject:channel];
		}
		else
		{
			NSUInteger privateMessageIndex =
			[self.channelListPrivate indexOfObjectPassingTest:^BOOL(IRCChannel *object, NSUInteger index, BOOL *stop) {
				return object.isPrivateMessage;
			}];

			if (privateMessageIndex == NSNotFound) {
				[self.channelListPrivate addObject:channel];
			} else {
				[self.channelListPrivate insertObject:channel atIndex:privateMessageIndex];
			}
		}

		[self updateStoredChannelList];
	}
}

/* Signed */
- (void)addChannel:(IRCChannel *)channel atPosition:(NSUInteger)position
{
	NSParameterAssert(channel != nil);

	@synchronized(self.channelListPrivate) {
		if ([self.channelListPrivate containsObject:channel]) {
			return;
		}

		[self.channelListPrivate insertObject:channel atIndex:position];
		
		[self updateStoredChannelList];
	}
}

/* Signed */
- (void)removeChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized(self.channelListPrivate) {
		[self.channelListPrivate removeObjectIdenticalTo:channel];
		
		[self updateStoredChannelList];
	}
}

/* Signed */
- (NSUInteger)indexOfChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized (self.channelListPrivate) {
		return [self.channelListPrivate indexOfObject:channel];
	}
}

/* Signed */
- (NSUInteger)channelCount
{
	@synchronized (self.channelListPrivate) {
		return self.channelListPrivate.count;
	}
}

/* Signed */
- (NSArray<IRCChannel *> *)channelList
{
	@synchronized (self.channelListPrivate) {
		return [self.channelListPrivate copy];
	}
}

/* Signed */
- (void)setChannelList:(NSArray<IRCChannel *> *)channelList
{
	NSParameterAssert(channelList != nil);

	@synchronized (self.channelListPrivate) {
		[self.channelListPrivate removeAllObjects];
		
		[self.channelListPrivate addObjectsFromArray:channelList];
		
		[self updateStoredChannelList];
	}
}

#pragma mark -
#pragma mark IRCTreeItem (Signed)

/* Signed */
- (BOOL)isClient
{
	return YES;
}

/* Signed */
- (BOOL)isActive
{
	return self.isLoggedIn;
}

/* Signed */
- (IRCClient *)associatedClient
{
	return self;
}

/* Signed */
- (nullable IRCChannel *)associatedChannel
{
	return nil;
}

/* Signed */
- (NSUInteger)numberOfChildren
{
	return self.channelCount;
}

/* Signed */
- (id)childAtIndex:(NSUInteger)index
{
	return self.channelList[index];
}

/* Signed */
- (NSString *)label
{
	return self.config.connectionName.uppercaseString;
}

#pragma mark -
#pragma mark Encoding (Signed)

/* Signed */
- (nullable NSData *)convertToCommonEncoding:(NSString *)string
{
	NSParameterAssert(string != nil);

	NSData *data = [string dataUsingEncoding:self.config.primaryEncoding allowLossyConversion:NO];

	if (data == nil) {
		data = [string dataUsingEncoding:self.config.fallbackEncoding allowLossyConversion:NO];

		if (data == nil) {
			data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		}
	}

	if (data == nil) {
		LogToConsoleError("NSData encode failure (%@)", string);
		LogToConsoleCurrentStackTrace
	}

	return data;
}

/* Signed */
- (nullable NSString *)convertFromCommonEncoding:(NSData *)data
{
	NSParameterAssert(data != nil);

	NSString *string = [NSString stringWithBytes:data.bytes length:data.length encoding:self.config.primaryEncoding];

	if (string == nil) {
		string = [NSString stringWithBytes:data.bytes length:data.length encoding:self.config.fallbackEncoding];

		if (string == nil) {
			string = [NSString stringWithBytes:data.bytes length:data.length encoding:NSASCIIStringEncoding];
		}
	}

	if (string == nil) {
		LogToConsoleError("NSData decode failure (%@)", data);
		LogToConsoleCurrentStackTrace
	}

	return string;
}

#pragma mark -
#pragma mark Ignore Matching (Signed)

/* Signed */
- (nullable IRCAddressBookEntry *)checkIgnoreAgainstHostmask:(NSString *)hostmask withMatches:(NSArray<NSString *> *)matches
{
	NSParameterAssert(hostmask != nil);
	NSParameterAssert(matches != nil);

	for (IRCAddressBookEntry *g in self.config.ignoreList) {
		if ([g checkMatch:hostmask] == NO) {
			continue;
		}

		NSDictionary *attributes = [g dictionaryValue];

		for (NSString *match in matches) {
			if ([attributes boolForKey:match]) {
				return g;
			}
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Output Rules (Signed)

/* Signed */
- (BOOL)outputRuleMatchedInMessage:(NSString *)message inChannel:(nullable IRCChannel *)channel
{
	NSParameterAssert(message != nil);

	if ([TPCPreferences removeAllFormatting] == NO) {
		message = message.stripIRCEffects;
	}

	NSArray *rules = sharedPluginManager().pluginOutputSuppressionRules;

	for (THOPluginOutputSuppressionRule *rule in rules) {
		if ([XRRegularExpression string:message isMatchedByRegex:rule.match] == NO) {
			continue;
		}

		if (channel) {
			if ((channel.isChannel && rule.restrictChannel) ||
				(channel.isPrivateMessage && rule.restrictPrivateMessage))
			{
				return YES;
			}
		} else {
			if (rule.restrictConsole) {
				return YES;
			}
		}
	}

	return NO;
}

#pragma mark -
#pragma mark Encryption and Decryption (Signed)

/* Signed */
- (NSDictionary<NSString *, NSString *> *)listOfNicknamesToDisallowEncryption
{
	static NSDictionary<NSString *, NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValue = [staticValues dictionaryForKey:@"IRCClient List of Nicknames that Encryption Forbids"];
	});

	return cachedValue;
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
/* Signed */
- (BOOL)encryptionAllowedForNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	/* Encryption is disabled */
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return NO;
	}

	/* General rules */
	if ([self stringIsChannelName:nickname]) { // Do not allow channel names
		return NO;
	} else if ([self nicknameIsMyself:nickname]) { // Do not allow the local user
		return NO;
	} else if ([self nicknameIsZNCUser:nickname]) { // Do not allow a ZNC private user
		return NO;
	}

	/* Build context information for lookup */
	NSDictionary *exceptionRules = [self listOfNicknamesToDisallowEncryption];

	NSString *lowercaseNickname = nickname.lowercaseString;

	/* Check network specific rules (such as "X" on UnderNet) */
	NSString *networkName = self.supportInfo.networkName;

	if (networkName) {
		NSArray *networkSpecificData = [exceptionRules arrayForKey:networkName];

		if ([networkSpecificData containsObject:lowercaseNickname]) {
			return NO;
		}
	}

	/* Look up rules for all networks */
	NSArray *defaultsData = exceptionRules[@"-default-"];

	if ([defaultsData containsObject:lowercaseNickname]) {
		return NO;
	}

	/* Allow the nickname through when there are no rules */
	return YES;
}
#endif

/* Signed */
- (NSUInteger)lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSUInteger)maximumLength
{
	return 0;
}

/* Signed */
- (void)encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(encodingCallback != nil);
	NSParameterAssert(injectionCallback != nil);

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user */
	if ([self encryptionAllowedForNickname:messageTo] == NO) {
#endif
		if (encodingCallback) {
			encodingCallback(messageBody, NO);
		}

		if (injectionCallback) {
			injectionCallback(messageBody);
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		return;
	}

	/* Continue with normal encryption operations */
	[sharedEncryptionManager() encryptMessage:messageBody
										 from:[self encryptionAccountNameForLocalUser]
										   to:[self encryptionAccountNameForUser:messageTo]
							 encodingCallback:encodingCallback
							injectionCallback:injectionCallback];
#endif
}

/* Signed */
- (void)decryptMessage:(NSString *)messageBody referenceMessage:(IRCMessage *)referenceMessage decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(referenceMessage != nil);

	if (referenceMessage.senderIsServer) {
		if (decodingCallback) {
			decodingCallback(messageBody, NO);
		}

		return;
	}

	[self decryptMessage:messageBody directedAt:referenceMessage.senderNickname decodingCallback:decodingCallback];
}

/* Signed */
- (void)decryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(decodingCallback != nil);

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user */
	if ([self encryptionAllowedForNickname:messageTo] == NO) {
#endif
		if (decodingCallback) {
			decodingCallback(messageBody, NO);
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		return;
	}

	/* Continue with normal encryption operations */
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
#define _dv(event, value)			case (event): {return (value); }

	switch (event) {
		_dv(TXNotificationChannelMessageType, @"Notifications[1001]")
		_dv(TXNotificationChannelNoticeType, @"Notifications[1002]")
		_dv(TXNotificationConnectType, @"Notifications[1009]")
		_dv(TXNotificationDisconnectType, @"Notifications[1010]")
		_dv(TXNotificationInviteType, @"Notifications[1004]")
		_dv(TXNotificationKickType, @"Notifications[1005]")
		_dv(TXNotificationNewPrivateMessageType, @"Notifications[1006]")
		_dv(TXNotificationPrivateMessageType, @"Notifications[1007]")
		_dv(TXNotificationPrivateNoticeType, @"Notifications[1008]")
		_dv(TXNotificationHighlightType, @"Notifications[1003]")
		_dv(TXNotificationFileTransferSendSuccessfulType, @"Notifications[1011]")
		_dv(TXNotificationFileTransferReceiveSuccessfulType, @"Notifications[1012]")
		_dv(TXNotificationFileTransferSendFailedType, @"Notifications[1012]")
		_dv(TXNotificationFileTransferReceiveFailedType, @"Notifications[1014]")
		_dv(TXNotificationFileTransferReceiveRequestedType, @"Notifications[1015]")

		default:
		{
			break;
		}
	}

#undef _dc

	return nil;
}

/* Signed */
- (void)speakEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(null_unspecified IRCChannel *)target nickname:(null_unspecified NSString *)nickname text:(null_unspecified NSString *)text
{
#warning TODO: Option to have speak events only occur for selected channel

	if (text) {
		text = text.trim;

		if ([TPCPreferences removeAllFormatting] == NO) {
			text = text.stripIRCEffects;
		}
	}

	NSString *formattedMessage = nil;
	
	switch (eventType) {
		case TXNotificationHighlightType:
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			if (text.length == 0) {
				break;
			}

			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];
			
			formattedMessage = TXTLS(formatter, target.name.channelNameWithoutBang, nickname, text);

			break;
		}
		case TXNotificationNewPrivateMessageType:
		case TXNotificationPrivateMessageType:
		case TXNotificationPrivateNoticeType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			if (text.length == 0) {
				break;
			}

			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];

			formattedMessage = TXTLS(formatter, nickname, text);
			
			break;
		}
		case TXNotificationKickType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);

			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];

			formattedMessage = TXTLS(formatter, target.name.channelNameWithoutBang, nickname);

			break;
		}
		case TXNotificationInviteType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];

			formattedMessage = TXTLS(formatter, text.channelNameWithoutBang, nickname);

			break;
		}
		case TXNotificationConnectType:
		case TXNotificationDisconnectType:
		{
			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];

			formattedMessage = TXTLS(formatter, self.networkNameAlt);
			
			break;
		}
		case TXNotificationAddressBookMatchType:
		{
			NSParameterAssert(text != nil);

			formattedMessage = text;

			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		case TXNotificationFileTransferReceiveSuccessfulType:
		case TXNotificationFileTransferSendFailedType:
		case TXNotificationFileTransferReceiveFailedType:
		case TXNotificationFileTransferReceiveRequestedType:
		{
			NSParameterAssert(nickname != nil);

			NSString *formatter = [self localizedSpokenMessageForEvent:eventType];
			
			formattedMessage = TXTLS(formatter, nickname);

			break;
		}
	}

	if (formattedMessage == nil) {
		return;
	}

	[[TXSharedApplication sharedSpeechSynthesizer] speak:formattedMessage];
}

/* Signed */
- (BOOL)notifyText:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(IRCChannel *)target nickname:(NSString *)nickname text:(NSString *)text
{
	return [self notifyEvent:eventType lineType:lineType target:target nickname:nickname text:text userInfo:nil];
}

/* Signed */
- (BOOL)notifyEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType
{
	return [self notifyEvent:eventType lineType:lineType target:nil nickname:nil text:nil userInfo:nil];
}

/* Signed */
- (BOOL)notifyEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(null_unspecified IRCChannel *)target nickname:(null_unspecified NSString *)nickname text:(null_unspecified NSString *)text
{
	return [self notifyEvent:eventType lineType:lineType target:target nickname:nickname text:text userInfo:nil];
}

/* Signed */
- (BOOL)notifyEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(null_unspecified IRCChannel *)target nickname:(null_unspecified NSString *)nickname text:(null_unspecified NSString *)text userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
{
	if (self.isTerminating) {
		return NO;
	}

	BOOL isTextEvent =
	(eventType == TXNotificationHighlightType			||
	 eventType == TXNotificationNewPrivateMessageType	||
	 eventType == TXNotificationChannelMessageType		||
	 eventType == TXNotificationChannelNoticeType		||
	 eventType == TXNotificationPrivateMessageType		||
	 eventType == TXNotificationPrivateNoticeType);

	if (isTextEvent) {
		if ([self nicknameIsMyself:nickname]) {
			return NO;
		}
	}

	if (target) {
		if ([self outputRuleMatchedInMessage:text inChannel:target]) {
			return NO;
		}

		if (target.config.pushNotifications == NO) {
			return YES;
		}

		if (target.config.ignoreHighlights && eventType == TXNotificationHighlightType) {
			return YES;
		}
	}

	if ([TPCPreferences bounceDockIconForEvent:eventType]) {
		if ([TPCPreferences bounceDockIconRepeatedlyForEvent:eventType] == NO) {
			[NSApp requestUserAttention:NSInformationalRequest];
		} else {
			[NSApp requestUserAttention:NSCriticalRequest];
		}
	}

	if (sharedGrowlController().areNotificationsDisabled) {
		return YES;
	}

	BOOL mainWindowIsFocused = (mainWindow().inactive == NO);

	BOOL postNotificationsWhileFocused = [TPCPreferences postNotificationsWhileInFocus];

	BOOL onlySpeakEvent = (postNotificationsWhileFocused &&
						   mainWindowIsFocused &&
						   [mainWindow() isItemSelected:target]);

	if ([TPCPreferences soundIsMuted] == NO) {
		if (onlySpeakEvent == NO) {
			NSString *soundName = [TPCPreferences soundForEvent:eventType];

			if (soundName) {
				[TLOSoundPlayer playAlertSound:soundName];
			}
		}

		if ([TPCPreferences speakEvent:eventType]) {
			[self speakEvent:eventType lineType:lineType target:target nickname:nickname text:text];
		}
	}

	if (onlySpeakEvent) {
		return YES;
	}

	if ([TPCPreferences growlEnabledForEvent:eventType] == NO) {
		return YES;
	}

	if (postNotificationsWhileFocused == NO && mainWindowIsFocused) {
		if (eventType != TXNotificationAddressBookMatchType) {
			return YES;
		}
	}

	if ([TPCPreferences disabledWhileAwayForEvent:eventType]) {
		if (self.userIsAway) {
			return YES;
		}
	}

	NSString *eventTitle = nil;

	NSString *eventDescription = nil;
	
	if (userInfo == nil) {
		if (target) {
			userInfo = @{@"clientId": self.uniqueIdentifier, @"channelId": target.uniqueIdentifier};
		} else {
			userInfo = @{@"clientId": self.uniqueIdentifier};
		}
	}

	switch (eventType) {
		case TXNotificationHighlightType:
		case TXNotificationNewPrivateMessageType:
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		case TXNotificationPrivateMessageType:
		case TXNotificationPrivateNoticeType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			if (eventType == TXNotificationHighlightType ||
				eventType == TXNotificationChannelMessageType ||
				eventType == TXNotificationChannelNoticeType)
			{
				NSParameterAssert(target != nil);

				eventTitle = target.name;
			}
			
			if (lineType == TVCLogLineActionType || lineType == TVCLogLineActionNoHighlightType) {
				eventDescription = [NSString stringWithFormat:TXNotificationDialogActionNicknameFormat, nickname, text];
			} else {
				nickname = [self formatNickname:nickname inChannel:target];

				eventDescription = [NSString stringWithFormat:TXNotificationDialogStandardNicknameFormat, nickname, text];
			}

			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		case TXNotificationFileTransferReceiveSuccessfulType:
		case TXNotificationFileTransferSendFailedType:
		case TXNotificationFileTransferReceiveFailedType:
		case TXNotificationFileTransferReceiveRequestedType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = nickname;

			eventDescription = text;
			
			break;
		}
		case TXNotificationConnectType:
		{
			eventTitle = self.networkNameAlt;

			break;
		}
		case TXNotificationDisconnectType:
		{
			eventTitle = self.networkNameAlt;

			break;
		}
		case TXNotificationAddressBookMatchType:
		{
			NSParameterAssert(text != nil);

			eventDescription = text;

			break;
		}
		case TXNotificationKickType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = target.name;
			
			eventDescription = TXTLS(@"Notifications[1035]", nickname, text);

			break;
		}
		case TXNotificationInviteType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = self.networkNameAlt;
			
			eventDescription = TXTLS(@"Notifications[1034]", nickname, text);

			break;
		}
		default:
		{
			return YES;
		}
	}

	[sharedGrowlController() notify:eventType title:eventTitle description:eventDescription userInfo:userInfo];
	
	return YES;
}

#pragma mark -
#pragma mark ZNC Bouncer Accessories (Signed)

/* Signed */
- (void)zncPlaybackClearChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isPrivateMessageForZNCUser == NO) {
		return;
	}

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule] == NO) {
		return;
	}

	NSString *nickname = [self nicknameAsZNCUser:@"playback"];

	[self send:IRCPrivateCommandIndex("privmsg"), nickname, @"clear", channel.name, nil];
}

/* Signed */
- (BOOL)nicknameIsZNCUser:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	if (self.isConnectedToZNC == NO) {
		return NO;
	}

	NSString *prefix = self.supportInfo.privateMessageNicknamePrefix;
	
	if (prefix) {
		return [nickname hasPrefix:prefix];
	}

	return [nickname hasPrefix:@"*"];
}

/* Signed */
- (nullable NSString *)nicknameAsZNCUser:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	if (self.isConnectedToZNC == NO) {
		return nil;
	}

	NSString *prefix = self.supportInfo.privateMessageNicknamePrefix;
	
	if (prefix) {
		return [prefix stringByAppendingString:nickname];
	}

	return [@"*" stringByAppendingString:nickname];
}

/* Signed */
- (BOOL)isSafeToPostNotificationForMessage:(IRCMessage *)message inChannel:(nullable IRCChannel *)channel
{
	NSParameterAssert(message != nil);

	if (self.isConnectedToZNC == NO) {
		return YES;
	}

	if (self.config.zncIgnoreUserNotifications) {
		if (channel && [self nicknameIsZNCUser:channel.name]) {
			return NO;
		}
	}

	if (self.config.zncIgnorePlaybackNotifications == NO) {
		return YES;
	}

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityBatch]) {
		return (self.zncBouncerIsPlayingBackHistory == NO);
	}

	return (message.isHistoric == NO);
}

- (void)updateConnectedToZNCPropertyWithMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	if (self.isConnectedToZNC) {
		return;
	}

	if (message.senderIsServer == NO) {
		return;
	}

	if (NSObjectsAreEqual(message.senderNickname, @"irc.znc.in")) {
		self.isConnectedToZNC = YES;

		LogToConsoleInfo("ZNC detected...")
	}
}

#pragma mark -
#pragma mark Channel States (Signed)

/* Signed */
- (void)setHighlightStateForChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (mainWindow().keyWindow && [mainWindow() isItemSelected:channel]) {
		return;
	}

	channel.nicknameHighlightCount += 1;

	[TVCDockIcon updateDockIcon];
	
	[mainWindow() reloadTreeItem:channel];
}

/* Signed */
- (void)setUnreadStateForChannel:(IRCChannel *)channel
{
	[self setUnreadStateForChannel:channel isHighlight:NO];
}

/* Signed */
- (void)setUnreadStateForChannel:(IRCChannel *)channel isHighlight:(BOOL)isHighlight
{
	NSParameterAssert(channel != nil);

	if (mainWindow().keyWindow && [mainWindow() isItemSelected:channel]) {
		return;
	}

	if (channel.isPrivateMessage || [TPCPreferences displayPublicMessageCountOnDockBadge]) {
		channel.dockUnreadCount += 1;
			
		[TVCDockIcon updateDockIcon];
	}

	channel.treeUnreadCount += 1;

	// The isHighlight flag is not sent for the purpose of incrementing
	// a count. It's passed so that we can know whether the option to
	// show badge count should be ignored when performing update.
	if (isHighlight || channel.config.showTreeBadgeCount) {
		[mainWindowServerList() updateMessageCountForItem:channel];
	}
}

#pragma mark -
#pragma mark Find Channel (Signed)

/* Signed */
- (nullable IRCChannel *)findChannel:(NSString *)withName inList:(NSArray<IRCChannel *> *)channelList
{
	NSParameterAssert(withName != nil);
	NSParameterAssert(channelList != nil);

	NSUInteger channelIndex =
	[channelList indexOfObjectWithOptions:NSEnumerationConcurrent
							  passingTest:^BOOL(IRCChannel *channel, NSUInteger index, BOOL *stop) {
								  NSString *channelName = channel.name;

								  return [withName isEqualIgnoringCase:channelName];
							  }];

	if (channelIndex != NSNotFound) {
		return channelList[channelIndex];
	}

	return nil;
}

/* Signed */
- (nullable IRCChannel *)findChannel:(NSString *)name
{
	return [self findChannel:name inList:self.channelList];
}

/* Signed */
- (nullable IRCChannel *)findChannelOrCreate:(NSString *)name
{
	return [self findChannelOrCreate:name isPrivateMessage:NO];
}

/* Signed */
- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName isPrivateMessage:(BOOL)isPrivateMessage
{
	NSParameterAssert(withName != nil);

	IRCChannel *channel = [self findChannel:withName];

	if (channel) {
		return channel;
	}

	if (isPrivateMessage == NO) {
		IRCChannelConfig *config = [IRCChannelConfig seedWithName:withName];

		return [worldController() createChannelWithConfig:config onClient:self add:YES adjust:YES reload:YES];
	} else {
		return [worldController() createPrivateMessage:withName onClient:self];
	}
}

#pragma mark -
#pragma mark Send Raw Data (Signed)

/* Signed */
- (void)sendLine:(NSString *)string
{
	NSParameterAssert(string != nil);

	if (self.isConnected == NO) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1005]")];

		return;
	}

	[self.socket sendLine:string];

	worldController().bandwidthOut += string.length;

	worldController().messagesSent += 1;
}

/* Signed */
- (void)send:(NSString *)string arguments:(NSArray<NSString *> *)arguments
{
	NSParameterAssert(string != nil);
	NSParameterAssert(arguments != nil);

	NSString *stringToSend = [IRCSendingMessage stringWithCommand:string arguments:arguments];

	[self sendLine:stringToSend];
}

/* Signed */
- (void)send:(NSString *)string, ...
{
	NSParameterAssert(string != nil);

	NSMutableArray<NSString *> *argumentsOut = [NSMutableArray array];

	va_list argumentsIn;
	va_start(argumentsIn, string);

	NSString *argumentInString = nil;

	while ((argumentInString = va_arg(argumentsIn, NSString *))) {
		[argumentsOut addObject:argumentInString];
	}

	va_end(argumentsIn);

	[self send:string arguments:argumentsOut];
}

#pragma mark -
#pragma mark Sending Text (Signed)

/* Signed */
- (void)inputText:(id)string asCommand:(IRCPrivateCommand)command
{
	IRCTreeItem *destination = mainWindow().selectedItem;

	[self inputText:string asCommand:command destination:destination];
}

/* Signed */
- (void)inputText:(id)string destination:(IRCTreeItem *)destination
{
	[self inputText:string asCommand:IRCPrivateCommandPrivmsgIndex destination:destination];
}

/* Signed */
- (void)inputText:(id)string asCommand:(IRCPrivateCommand)command destination:(IRCTreeItem *)destination
{
	NSParameterAssert(string != nil);
	NSParameterAssert(destination != nil);

	if (self.isTerminating) {
		return;
	}

	BOOL inputIsNSString = [string isKindOfClass:[NSString class]];

	if (inputIsNSString == NO && [string isKindOfClass:[NSAttributedString class]] == NO) {
		NSAssert(NO, @"'string' must be NSString or NSAttributedString");
	}

	if (command != IRCPrivateCommandPrivmsgIndex &&
		command != IRCPrivateCommandPrivmsgActionIndex &&
		command != IRCPrivateCommandNoticeIndex)
	{
		NSAssert(NO, @"Bad 'command' value");
	}

	if ([string length] == 0) {
		return;
	}

	NSAttributedString *stringIn = nil;

	if (inputIsNSString) {
		stringIn = [NSAttributedString attributedStringWithString:string];
	} else {
		stringIn = string;
	}

	NSArray *lines = ((NSAttributedString *)stringIn).splitIntoLines;

	/* Warn if the split value is above 4 lines or if the total string 
	 length exceeds TXMaximumIRCBodyLength times 4. */
	if (lines.count > 4 || (stringIn.length > (TXMaximumIRCBodyLength * 4))) {
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

	for (__strong NSAttributedString *line in lines) {
		NSString *lineString = line.string;

		BOOL isPrefixed = [lineString hasPrefix:@"/"];

		if (destination.isClient) {
			if (isPrefixed) {
				line = [line attributedSubstringFromIndex:1];
			}

			[self sendCommand:line];

			return;
		}

		NSUInteger lineLength = line.length;

		IRCChannel *channel = (IRCChannel *)destination;

		if (isPrefixed && [lineString hasPrefix:@"//"] == NO && lineLength > 1) {
			line = [line attributedSubstringFromIndex:1];

			[self sendCommand:line];
		} else {
			if (isPrefixed && lineLength > 1) {
				line = [line attributedSubstringFromIndex:1];
			}

			[self sendText:line asCommand:command toChannel:channel];
		}
	}
}

/* Signed */
- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel
{
    [self sendText:string asCommand:command toChannel:channel withEncryption:YES];
}

/* Signed */
- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel withEncryption:(BOOL)encryptText
{
	NSParameterAssert(string != nil);
	NSParameterAssert(channel != nil);

	if (string.length == 0) {
		return;
	}

	NSString *commandToSend = nil;

	TVCLogLineType lineType = TVCLogLineUndefinedType;

	if (command == IRCPrivateCommandPrivmsgIndex) {
		commandToSend = IRCPrivateCommandIndex("notice");

		lineType = TVCLogLinePrivateMessageType;
	} else if (command == IRCPrivateCommandPrivmsgActionIndex) {
		commandToSend = IRCPrivateCommandIndex("privmsg");

		lineType = TVCLogLineActionType;
	} else if (command == IRCPrivateCommandNoticeIndex) {
		commandToSend = IRCPrivateCommandIndex("notice");
		
		lineType = TVCLogLineNoticeType;
	}

	NSParameterAssert(lineType != TVCLogLineUndefinedType);

	NSArray *lines = string.splitIntoLines;

	for (NSAttributedString *line in lines) {
		NSMutableAttributedString *lineMutable = [line mutableCopy];

		while (lineMutable.length > 0)
		{
			NSString *unencryptedMessage = [NSAttributedString attributedStringToASCIIFormatting:&lineMutable inChannel:channel onClient:self withLineType:lineType];

			TLOEncryptionManagerEncodingDecodingCallbackBlock encryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
				[self print:originalString
						 by:self.userNickname
				  inChannel:channel
					 asType:lineType
					command:commandToSend
				 receivedAt:[NSDate date]
				isEncrypted:wasEncrypted];
			};

			TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
				NSString *sendMessage = encodedString;

				if (lineType == TVCLogLineActionType) {
					sendMessage = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), sendMessage, 0x01];
				}

				[self send:commandToSend, channel.name, sendMessage, nil];
			};

			if (encryptText == NO) {
				encryptionBlock(unencryptedMessage, NO);

				injectionBlock(unencryptedMessage);

				continue;
			}

			[self encryptMessage:unencryptedMessage
					  directedAt:channel.name
				encodingCallback:encryptionBlock
			   injectionCallback:injectionBlock];
		}
	}

	[self processBundlesUserMessage:string.string command:commandToSend];
}

/* Signed */
- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandPrivmsgIndex
			 toChannel:channel];
	}];
}

/* Signed */
- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandPrivmsgActionIndex
			 toChannel:channel];
	}];
}

/* Signed */
- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandNoticeIndex
			 toChannel:channel];
	}];
}

/* Signed */
- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	IRCChannel *channel = [mainWindow() selectedChannelOn:self];

	if (channel == nil) {
		return;
	}

	[self sendPrivmsg:message toChannel:channel];
}

/* Signed */
- (void)sendCTCPQuery:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(command != nil);

	TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
		NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, encodedString, 0x01];

		[self send:IRCPrivateCommandIndex("privmsg"), nickname, message, nil];
	};

	NSString *stringToSend = nil;

	if (text == nil) {
		stringToSend = command;
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	injectionBlock(stringToSend);
}

/* Signed */
- (void)sendCTCPReply:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(command != nil);

	TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
		NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, encodedString, 0x01];

		[self send:IRCPrivateCommandIndex("notice"), nickname, message, nil];
	};

	NSString *stringToSend = nil;

	if (text == nil) {
		stringToSend = command;
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	injectionBlock(stringToSend);
}

/* Signed */
- (void)sendCTCPPing:(NSString *)nickname
{
	NSString *text = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSince1970]];

	[self sendCTCPQuery:nickname
				command:IRCPrivateCommandIndex("ctcp_ping")
				   text:text];
}

#pragma mark -
#pragma mark Send Command

/* Signed */
- (void)sendCommand:(id)string
{
	[self sendCommand:string completeTarget:YES target:nil];
}

- (void)sendCommand:(id)string completeTarget:(BOOL)completeTarget target:(nullable NSString *)targetChannelName
{
	NSParameterAssert(string != nil);

	BOOL inputIsNSString = [string isKindOfClass:[NSString class]];

	if (inputIsNSString == NO && [string isKindOfClass:[NSAttributedString class]] == NO) {
		NSAssert(NO, @"'string' must be NSString or NSAttributedString");
	}

	if ([string length] == 0) {
		return;
	}

	NSMutableAttributedString *stringIn = nil;

	if (inputIsNSString) {
		stringIn = [[NSMutableAttributedString alloc] initWithString:string];
	} else {
		stringIn = [string mutableCopy];
	}

	if ([stringIn.string hasPrefix:@"/"]) {
		[stringIn deleteCharactersInRange:NSMakeRange(0, 1)];
	}

	NSString *command = stringIn.tokenAsString;

	NSString *lowercaseCommand = command.lowercaseString;
	NSString *uppercaseCommand = command.uppercaseString;

	NSString *stringInString = stringIn.string;

	NSUInteger stringInStringLength = stringInString.length;

	IRCClient *selectedClient = mainWindow().selectedClient;
	IRCChannel *selectedChannel = mainWindow().selectedChannel;

	IRCChannel *targetChannel = nil;

	NSInteger commandNumeric = [IRCCommandIndex indexOfIRCommand:uppercaseCommand publicSearch:YES];

	if (completeTarget && targetChannelName != nil) {
		targetChannel = [self findChannel:targetChannelName];
	} else if (completeTarget && selectedClient == self && selectedChannel) {
		targetChannel = selectedChannel;
	}

	switch (commandNumeric) {
		case IRCPublicCommandAmeIndex: // Command: AME
		case IRCPublicCommandAmsgIndex: // Command: AMSG
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			IRCPrivateCommand command = 0;

			if (commandNumeric == IRCPublicCommandAmsgIndex) {
				command = IRCPrivateCommandPrivmsgIndex;
			} else {
				command = IRCPrivateCommandPrivmsgActionIndex;
			}

			for (IRCClient *client in worldController().clientList) {
				if (client != self && [TPCPreferences amsgAllConnections] == NO) {
					continue;
				}

				for (IRCChannel *channel in client.channelList) {
					if (channel.isActive == NO || channel.isChannel == NO) {
						continue;
					}

					[client sendText:stringIn asCommand:command toChannel:channel];

					[client setUnreadStateForChannel:channel];
				}
			}

			break;
		}
		case IRCPublicCommandAquoteIndex: // Command: AQUOTE
		case IRCPublicCommandArawIndex: // Command: ARAW
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			for (IRCClient *client in worldController().clientList) {
				[client sendLine:stringInString];
			}

			break;
		}
		case IRCPublicCommandAutojoinIndex: // Command: AUTOJOIN
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self performAutoJoinInitiatedByUser:YES];

			break;
		}
		case IRCPublicCommandAwayIndex: // Command: AWAY
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			for (IRCClient *client in worldController().clientList) {
				if (client != self && [TPCPreferences awayAllConnections] == NO) {
					continue;
				}

				[client toggleAwayStatusWithComment:stringInString];
			}

			break;
		}
		case IRCPublicCommandBackIndex: // Command: BACK
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			for (IRCClient *client in worldController().clientList) {
				if (client != self && [TPCPreferences awayAllConnections] == NO) {
					continue;
				}

				[client toggleAwayStatus:NO withComment:nil];
			}
		}
		case IRCPublicCommandCapIndex: // Command: CAP
		case IRCPublicCommandCapsIndex: // Command: CAPS
		{
			NSString *capacities = self.enabledCapacitiesStringValue;

			if (capacities.length == 0) {
				[self printDebugInformation:TXTLS(@"IRC[1036]")];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1037]", capacities)];
			}

			break;
		}
		case IRCPublicCommandCcbadgeIndex: // Command: CCBADGE
		{
			NSString *channelName = stringIn.tokenAsString;
			NSString *badgeCount = stringIn.tokenAsString;

			if (channelName.length == 0 || badgeCount.length == 0) {
				break;
			}

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			channel.treeUnreadCount = badgeCount.integerValue;

			NSString *isHighlightFlag = stringIn.tokenAsString;

			if ([isHighlightFlag isEqualToString:@"-h"]) {
				channel.nicknameHighlightCount = 1;
			}

			[mainWindow() reloadTreeItem:channel];
			
			break;
		}
		case IRCPublicCommandClearIndex: // Command: CLEAR
		{
			if (targetChannel) {
				[mainWindow() clearContentsOfChannel:targetChannel];
			} else {
				[mainWindow() clearContentsOfClient:self];
			}

			break;
		}
		case IRCPublicCommandClearallIndex: // Command: CLEARALL
		{
			if ([TPCPreferences clearAllOnlyOnActiveServer]) {
				[mainWindow() clearContentsOfClient:self];

				for (IRCChannel *channel in self.channelList) {
					[mainWindow() clearContentsOfChannel:channel];
				}

				break;
			}

			[mainWindow() clearAllViews];

			break;
		}
		case IRCPublicCommandCloseIndex: // Command: CLOSE
		case IRCPublicCommandRemoveIndex: // Command: REMOVE
		{
			if (stringInStringLength == 0) {
				if (targetChannel) {
					[worldController() destroyChannel:targetChannel];
				}

				break;
			}

			NSString *channelName = stringIn.tokenAsString;

			IRCChannel *channel = [self findChannel:channelName];

			if (channel) {
				[worldController() destroyChannel:channel];
			}

			break;
		}
		case IRCPublicCommandConnIndex: // Command: CONN
		{
			if (stringInStringLength > 0) {
				NSString *serverAddress = stringIn.lowercaseGetToken;

				if (serverAddress.isValidInternetAddress == NO) {
					LogToConsoleInfo("Silently ignoring bad server address")

					return;
				}

				self.temporaryServerAddressOverride = serverAddress;
			}

			if (self.isConnected) {
				__weak IRCClient *weakSelf = self;

				self.disconnectCallback = ^{
					[weakSelf connect];
				};

				[self quit];

				break;
			}

			[self connect];
			
			break;
		}
		case IRCPublicCommandCtcpIndex: // Command: CTCP
		case IRCPublicCommandCtcpreplyIndex: // Command: CTCPREPLY
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if ([self stringIsChannelName:stringInString] == NO) {
				if (targetChannel && targetChannel.isPrivateMessage) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *subCommand = stringIn.uppercaseGetToken;

			if (subCommand.length == 0) {
				break;
			}

			if (commandNumeric == IRCPublicCommandCtcpIndex) {
				if ([subCommand isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
					[self sendCTCPPing:targetChannelName];
				} else {
					[self sendCTCPQuery:targetChannelName command:subCommand text:stringIn.string];
				}
			} else {
				[self sendCTCPReply:targetChannelName command:subCommand text:stringIn.string];
			}
			
			break;
		}
		case IRCPublicCommandCycleIndex: // Command: CYCLE
		case IRCPublicCommandHopIndex: // Command: HOP
		case IRCPublicCommandRejoinIndex: // Command: REJOIN
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if (targetChannel == nil || targetChannel.isChannel == NO) {
				break;
			}

			[self partChannel:targetChannel];

			[self forceJoinChannel:targetChannel.name password:targetChannel.secretKey];

			break;
		}
		case IRCPublicCommandDebugIndex: // Command: DEBUG
		case IRCPublicCommandEchoIndex: // Command: ECHO
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			if ([stringInString isEqualIgnoringCase:@"raw on"])
			{
				self.rawModeEnabled = YES;

				(void)[RZWorkspace() launchApplication:@"Console"];

				[self printDebugInformation:TXTLS(@"IRC[1092]")];

				LogToConsoleInfo("%{public}@", TXTLS(@"IRC[1094]"))
			}
			else if ([stringInString isEqualIgnoringCase:@"raw off"])
			{
				self.rawModeEnabled = NO;

				[self printDebugInformation:TXTLS(@"IRC[1091]")];

				LogToConsoleInfo("%{public}@", TXTLS(@"IRC[1093]"))
			}
			else
			{
				[self printDebugInformation:stringInString];
			}
			
			break;
		}
		case IRCPublicCommandFakerawdataIndex: // Command: FAKERAWDATA
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			[self ircConnection:self.socket didReceiveData:stringInString];

			break;
		}
		case IRCPublicCommandGetscriptsIndex: // Command: GETSCRIPTS
		{
			[sharedPluginManager() extrasInstallerLaunchInstaller];

			break;
		}
		case IRCPublicCommandGotoIndex: // Command: GOTO
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSString *needle = stringIn.tokenAsString;

			IRCTreeItem *bestMatch = mainWindow().selectedItem;

			CGFloat bestScore = 0.0;

			for (IRCClient *client in worldController().clientList) {
				for (IRCChannel *channel in client.channelList) {
					CGFloat currentScore = [channel.name compareWithWord:needle lengthPenaltyWeight:0.1];

					if (currentScore > bestScore) {
						bestMatch = channel;

						bestScore = currentScore;
					}
				}
			}

			[mainWindow() select:bestMatch];
			
			break;
		}
		case IRCPublicCommandIcbadgeIndex: // Command: ICBADGE
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSArray *components = [stringInString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if (components.count != 2) {
				return;
			}

			[TVCDockIcon drawWithHighlightCount:[components unsignedLongAtIndex:0]
								   messageCount:[components unsignedLongAtIndex:1]];

			break;
		}
		case IRCPublicCommandIgnoreIndex: // Command: IGNORE
		case IRCPublicCommandUnignoreIndex: // Command: UNIGNORE
		{
			BOOL isIgnoreCommand = (commandNumeric == 5029);

			if (stringInStringLength == 0 || targetChannel == nil) {
				if (isIgnoreCommand) {
					[menuController() showServerPropertiesSheetForClient:self withSelection:TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection context:nil];
				} else {
					[menuController() showServerPropertiesSheetForClient:self withSelection:TDCServerPropertiesSheetAddressBookNavigationSelection context:nil];
				}

				break;
			}

			NSString *nickname = stringIn.tokenAsString;

			IRCUser *member = [targetChannel findMember:nickname];

			if (member == nil) {
				if (isIgnoreCommand) {
					[menuController() showServerPropertiesSheetForClient:self withSelection:TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection context:nickname];
				} else {
					[menuController() showServerPropertiesSheetForClient:self withSelection:TDCServerPropertiesSheetAddressBookNavigationSelection context:nil];
				}

				break;
			}

			/* Build list of ignores that already match the user's host */
			NSString *hostmask = member.hostmask;

			if (hostmask == nil) {
				hostmask = [NSString stringWithFormat:@"%@!*@*", nickname];
			}

			NSMutableArray *matchedIgnores = [NSMutableArray array];

			for (IRCAddressBookEntry *ignore in self.config.ignoreList) {
				if (ignore.entryType != IRCAddressBookIgnoreEntryType) {
					continue;
				}

				if ([ignore checkMatch:hostmask]) {
					[matchedIgnores addObject:ignore];
				}
			}

			/* Cancel if there is nothing to change */
			if (isIgnoreCommand) {
				if (matchedIgnores.count > 0) {
					[self printDebugInformation:TXTLS(@"IRC[1118]", member.nickname)];

					break;
				}
			} else {
				if (matchedIgnores.count == 0) {
					[self printDebugInformation:TXTLS(@"IRC[1117]", member.nickname)];

					break;
				}
			}

			/* Modify ignore list and inform user of change */
			NSMutableArray *mutableIgnoreList = [self.config.ignoreList mutableCopy];

			if (isIgnoreCommand) {
				IRCAddressBookEntry *ignore =
				[IRCAddressBookEntry newIgnoreEntryForHostmask:member.banMask];

				[self printDebugInformation:TXTLS(@"IRC[1115]", member.nickname, ignore.hostmask)];

				[mutableIgnoreList addObject:ignore];
			} else{
				for (IRCAddressBookEntry *ignore in matchedIgnores) {
					[self printDebugInformation:TXTLS(@"IRC[1116]", member.nickname, ignore.hostmask)];

					[mutableIgnoreList removeObjectIdenticalTo:ignore];
				}
			}

			/* Save modified ignore list */
			IRCClientConfigMutable *mutableClientConfig = [self.config mutableCopy];

			mutableClientConfig.ignoreList = mutableIgnoreList;
			
			self.config = mutableClientConfig;
			
			break;
		}
		case IRCPublicCommandIsonIndex: // Command: ISON
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self enableInUserInvokedCommandProperty:&self->_inUserInvokedIsonRequest];

			[self send:IRCPrivateCommandIndex("ison"), stringInString, nil];

			break;
		}
		case IRCPublicCommandJIndex: // Command: J
		case IRCPublicCommandJoinIndex:  // Command: JOIN
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if (stringInStringLength == 0) {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;

				if ([self stringIsChannelNameOrZero:targetChannelName] == NO) {
					targetChannelName = [@"#" stringByAppendingString:targetChannelName];
				}
			}

			[self enableInUserInvokedCommandProperty:&_inUserInvokedJoinRequest];

			[self send:IRCPrivateCommandIndex("join"), targetChannelName, stringIn.string, nil];

			break;
		}
		case IRCPublicCommandBanIndex: // Command: BAN
		case IRCPublicCommandKbIndex: // Command: KB
		case IRCPublicCommandKickIndex: // Command: KICK
		case IRCPublicCommandKickbanIndex: // Command: KICKBAN
		case IRCPublicCommandUnbanIndex: // Command: UNBAN
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if ([self stringIsChannelName:stringInString] == NO) {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;

				targetChannel = [self findChannel:targetChannelName];
			}

			NSString *nickname = stringIn.tokenAsString;

			if (nickname.length == 0) {
				break;
			}

			if (commandNumeric == IRCPublicCommandKickbanIndex ||
				commandNumeric == IRCPublicCommandKbIndex ||
				commandNumeric == IRCPublicCommandBanIndex ||
				commandNumeric == IRCPublicCommandUnbanIndex)
			{
				IRCUser *member = [targetChannel findMember:nickname];

				NSString *banMask = member.banMask;

				if (banMask == nil) {
					banMask = nickname;
				}

				if (commandNumeric == IRCPublicCommandUnbanIndex) { // UNBAN
					[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"-b", banMask, nil];
				} else {
					[self send:IRCPrivateCommandIndex("mode"), targetChannelName, @"+b", banMask, nil];
				}
			}

			if (commandNumeric == IRCPublicCommandKickIndex || commandNumeric == IRCPublicCommandKickbanIndex) {
				NSString *reason = stringIn.tokenAsString;

				if (reason.length == 0) {
					reason = [TPCPreferences defaultKickMessage];
				}

				[self send:IRCPrivateCommandIndex("kick"), targetChannelName, nickname, reason, nil];
			}
			
			break;
		}
		case IRCPublicCommandKillIndex: // Command: KILL
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			NSString *nickname = stringIn.getTokenAsString;
			NSString *reason = stringIn.getTokenAsString;

			if (reason.length == 0) {
				reason = [TPCPreferences IRCopDefaultKillMessage];
			}

			[self send:IRCPrivateCommandIndex("kill"), nickname, reason, nil];

			break;
		}
		case IRCPublicCommandLagcheckIndex: // Command: LAGCHECK
		case IRCPublicCommandMylagIndex: // Command: MYLAG
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			self.lagCheckLastCheck = [NSDate timeIntervalSince1970];

			if (commandNumeric == IRCPublicCommandMylagIndex) {
				self.lagCheckDestinationChannel = [mainWindow() selectedChannelOn:self];
			}

			[self sendCTCPQuery:self.userNickname command:IRCPrivateCommandIndex("ctcp_lagcheck") text:nil];

			[self printDebugInformation:TXTLS(@"IRC[1023]")];

			break;
		}
		case IRCPublicCommandLeaveIndex: // Command: LEAVE
		case IRCPublicCommandPartIndex: // Command: PART
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if ([self stringIsChannelName:stringInString] == NO) {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else if (targetChannel && targetChannel.isPrivateMessage) {
					[worldController() destroyChannel:targetChannel];

					break;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *reason = stringIn.tokenAsString;

			if (reason.length == 0) {
				reason = self.config.normalLeavingComment;
			}

			[self send:IRCPrivateCommandIndex("part"), targetChannelName, reason, nil];
			
			break;
		}
		case IRCPublicCommandListIndex: // Command: LIST
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);
			
			TDCServerChannelListDialog *channelListDialog = [self channelListDialog];

			if (channelListDialog == nil) {
				[self createChannelListDialog];
			}

			[self requestChannelList];

			break;
		}
		case IRCPublicCommandMuteIndex: // Command: MUTE
		{
			if ([TPCPreferences soundIsMuted]) {
				[self printDebugInformation:TXTLS(@"IRC[1097]")];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1100]")];

				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOnState];
			}

			break;
		}
		case IRCPublicCommandMyversionIndex: // Command: MYVERSION
		{
			NSString *applicationName = [TPCApplicationInfo applicationName];
			NSString *versionLong = [TPCApplicationInfo applicationVersion];
			NSString *versionShort = [TPCApplicationInfo applicationVersionShort];
			NSString *buildScheme = [TPCApplicationInfo applicationBuildScheme];

			NSString *downloadSource = nil;

			if ([buildScheme isEqualToString:@"appstore"]) {
				downloadSource = TXTLS(@"IRC[1028]");
			} else {
				downloadSource = TXTLS(@"IRC[1029]");
			}

			NSString *message = TXTLS(@"IRC[1027]", applicationName, versionShort, versionLong, downloadSource);

			if (targetChannel) {
				message = TXTLS(@"IRC[1030]", message);

				[self sendPrivmsg:message toChannel:targetChannel];
			} else {
				[self printDebugInformationToConsole:message];
			}
			
			break;
		}
		case IRCPublicCommandNickIndex: // Command: NICK
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSString *newNickname = stringIn.tokenAsString;

			for (IRCClient *client in worldController().clientList) {
				if (client != self && [TPCPreferences nickAllConnections] == NO) {
					continue;
				}

				[client changeNickname:newNickname];
			}
			
			break;
		}
		case IRCPublicCommandQueryIndex: // Command: QUERY
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSString *nickname = stringIn.tokenAsString;

			if ([self stringIsNickname:nickname] == NO) {
				break;
			}

			IRCChannel *query = [self findChannelOrCreate:nickname isPrivateMessage:YES];

			[mainWindow() select:query];
			
			break;
		}
		case IRCPublicCommandQuoteIndex: // Command: QUOTE
		case IRCPublicCommandRawIndex: // Command: RAW
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			[self sendLine:stringInString];

			break;
		}
		case IRCPublicCommandQuitIndex: // Command: QUIT
		{
			if (stringInStringLength == 0) {
				[self quit];
			} else {
				[self quitWithComment:stringInString];
			}

			break;
		}
		case IRCPublicCommandNamesIndex: // Command: NAMES
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self enableInUserInvokedCommandProperty:&self->_inUserInvokedNamesRequest];

			[self send:IRCPrivateCommandIndex("names"), stringInString, nil];

			break;
		}
		case IRCPublicCommandSetcolorIndex: // Command: SETCOLOR
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

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

			NSString *nickname = stringIn.lowercaseGetToken;

			if ([self stringIsNickname:nickname] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1110]", nickname)];

				return;
			}

			[menuController() memberChangeColor:nickname];
			
			break;
		}
		case IRCPublicCommandServerIndex: // Command: SERVER
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			[IRCExtras createConnectionToServer:stringInString channelList:nil connectWhenCreated:YES];

			break;
		}
		case IRCPublicCommandSslcontextIndex: // Command: SSLCONTEXT
		{
			[self presentCertificateTrustInformation];

			break;
		}
		case IRCPublicCommandTageIndex: // Command: TAGE
		{
			NSTimeInterval timePassed = [NSDate timeIntervalSinceNow:TXBirthdayReferenceDate];

			NSString *message = TXTLS(@"IRC[1101]", TXHumanReadableTimeInterval(timePassed, NO, 0));

			if (targetChannel) {
				[self sendPrivmsg:message toChannel:targetChannel];
			} else {
				[self printDebugInformationToConsole:message];
			}

			break;
		}
		case IRCPublicCommandTimerIndex: // Command: TIMER
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSInteger timerInterval = stringIn.tokenAsString.integerValue;

			if (timerInterval <= 0) {
				[self printDebugInformation:TXTLS(@"IRC[1090]")];

				break;
			}

			NSString *timerCommand = stringIn.string;

			if (timerCommand.length == 0) {
				break;
			}

			IRCTimerCommandContext *timer = [IRCTimerCommandContext new];

			timer.channelId = targetChannel.uniqueIdentifier;

			timer.rawInput = timerCommand;

			timer.timerInterval = ([NSDate timeIntervalSince1970] + timerInterval);

			[self addCommandToCommandQueue:timer];
			
			break;
		}
		case IRCPublicCommandTIndex: // Command: T
		case IRCPublicCommandTopicIndex: // Command: TOPIC
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if ([self stringIsChannelName:stringInString] == NO) {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *topic = stringIn.attributedStringToASCIIFormatting;

			if (topic.length == 0) {
				[self send:IRCPrivateCommandIndex("topic"), targetChannelName, nil];
			} else {
				[self send:IRCPrivateCommandIndex("topic"), targetChannelName, topic, nil];
			}

			break;
		}
		case IRCPublicCommandUnmuteIndex: // Command: UNMUTE
		{
			if ([TPCPreferences soundIsMuted] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1099]")];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1098]")];

				[menuController() toggleMuteOnNotificationSoundsShortcut:NSOffState];
			}

			break;
		}
		case IRCPublicCommandWallopsIndex: // Command: WALLOPS
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self send:IRCPrivateCommandIndex("wallops"), stringInString, nil];

			break;
		}
		case IRCPublicCommandWatchIndex: // Command: WATCH
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self enableInUserInvokedCommandProperty:&self->_inUserInvokedWatchRequest];

			[self send:IRCPrivateCommandIndex("watch"), nil];

			break;
		}
		case IRCPublicCommandWhoIndex: // Command: WHO
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			[self enableInUserInvokedCommandProperty:&self->_inUserInvokedWhoRequest];

			[self send:IRCPrivateCommandIndex("who"), stringInString, nil];

			break;
		}
		case IRCPublicCommandWhoisIndex: // Command: WHOIS
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			NSString *nickname1 = stringIn.tokenAsString;
			NSString *nickname2 = stringIn.tokenAsString;

			if (nickname1.length == 0) {
				if (targetChannel && targetChannel.isPrivateMessage) {
					nickname1 = targetChannel.name;
				} else {
					break;
				}
			}

			if (nickname2.length == 0) {
				[self send:IRCPrivateCommandIndex("whois"), nickname1, nickname1, nil];
			} else {
				[self send:IRCPrivateCommandIndex("whois"), nickname1, nickname2, nil];
			}

			break;
		}
		case IRCPublicCommandMeIndex: // Command: ME
		case IRCPublicCommandMsgIndex: // Command: MSG
		case IRCPublicCommandNoticeIndex: // Command: NOTICE
		case IRCPublicCommandOmsgIndex: // Command: OMSG
		case IRCPublicCommandOnoticeIndex: // Command: ONOTICE
		case IRCPublicCommandSmeIndex: // Command: SME
		case IRCPublicCommandSmsgIndex: // Command: SMSG
		case IRCPublicCommandUmeIndex: // Command: UME
		case IRCPublicCommandUmsgIndex: // Command: UMSG
		case IRCPublicCommandUnoticeIndex: // Command: UNOTICE
		{
			/* Where would se send data to? */
			if (self.isLoggedIn == NO) {
				[self printDebugInformationToConsole:TXTLS(@"IRC[1005]")];

				break;
			}

			/* Establish context for comand */
			NSString *channelNamePrefix = nil;

			BOOL isOperatorMessage = NO;
			BOOL isSecretMessage = NO;
			BOOL isUnencryptedMessag = NO;

			NSString *commandToSend = nil;

			TVCLogLineType lineType = TVCLogLineUndefinedType;

			if (commandNumeric == IRCPublicCommandMsgIndex ||
				commandNumeric == IRCPublicCommandOmsgIndex ||
				commandNumeric == IRCPublicCommandSmsgIndex ||
				commandNumeric == IRCPublicCommandUmsgIndex)
			{
				commandToSend = IRCPrivateCommandIndex("privmsg");

				lineType = TVCLogLinePrivateMessageType;

				isOperatorMessage = (commandNumeric == IRCPublicCommandOmsgIndex);
				isSecretMessage = (commandNumeric == IRCPublicCommandSmsgIndex);
				isUnencryptedMessag = (commandNumeric == IRCPublicCommandUmsgIndex);
			}
			else if (commandNumeric == IRCPublicCommandMeIndex ||
					 commandNumeric == IRCPublicCommandSmeIndex ||
					 commandNumeric == IRCPublicCommandUmeIndex)
			{
				commandToSend = IRCPrivateCommandIndex("privmsg");

				lineType = TVCLogLineActionType;

				isSecretMessage = (commandNumeric == IRCPublicCommandSmeIndex);
				isUnencryptedMessag = (commandNumeric == IRCPublicCommandUmeIndex);
			}
			else if (commandNumeric == IRCPublicCommandNoticeIndex || // Command: NOTICE
					 commandNumeric == IRCPublicCommandOnoticeIndex || // Command: ONOTICE
					 commandNumeric == IRCPublicCommandUnoticeIndex)   // Command: UNOTICE
			{
				commandToSend = IRCPrivateCommandIndex("notice");

				lineType = TVCLogLineNoticeType;

				isOperatorMessage = (commandNumeric == IRCPublicCommandOnoticeIndex);
				isUnencryptedMessag = (commandNumeric == IRCPublicCommandUnoticeIndex);
			}

			if (isOperatorMessage) {
				channelNamePrefix = [self.supportInfo userPrefixForModeSymbol:@"o"];

				/* If the user is sending an operator message and the user mode +o does 
				 not exist, then fail here. The user may be trying to send something 
				 secret with an expectation for privacy and we cannot deliver that. */
				if (channelNamePrefix == nil) {
					LogToConsoleError("User wants to send operator message but there is no +o mode")

					break;
				}
			}

			/* Pick the best target */
			/* All actions except (SME) should use the target channel */
			/* Operator messages should use the target channel unless the
			 string in is a channel name */
			/* All other scenarios use the string in (token) */
			if (isSecretMessage == NO && lineType == TVCLogLineActionType && targetChannel) {
				targetChannelName = targetChannel.name;
			} else if (isOperatorMessage && [self stringIsChannelName:stringInString] == NO && targetChannel.isChannel) {
				targetChannelName = targetChannel.name;
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			if (targetChannelName.length == 0) {
				LogToConsoleError("Bad target channel name")

				break;
			}

			/* Actions are allowed to have an empty message but all other
			 types are not. Empty actions use a whitespace. */
			if (stringIn.length == 0) {
				if (lineType == TVCLogLineActionType) {
					[stringIn replaceCharactersInRange:NSMakeRange(0, 0)
											withString:NSStringWhitespacePlaceholder];
				} else {
					break;
				}
			}

			/* At this point, the following will occur:
			 1. Each destination is looped over
				1. Prefix characters are removed from the destination name
				2. Try to find channel that already exists which matches
				   the destination. If a channel does not exist, then we 
				   create one depending on whether this is a secret message.
				3. The message is then encrypted and sent off.
			 */
			NSArray *destinations = [targetChannelName componentsSeparatedByString:@","];

			IRCChannel *destinationToSelect = nil;

			for (__strong NSString *destinationName in destinations) {
				/* If the user prefixed the target with a mode (e.g. +#channel)
				 to indicate that they want the message only seen by that group
				 of users, then we first have to remove that prefix to perform
				 our own processing of the target. When it comes time to send 
				 the message, then the prefix is added back to the target name. */
				NSString *destinationNamePrefix = [self.supportInfo extractUserPrefixFromChannelNamed:destinationName];

				if (destinationNamePrefix.length == 0) {
					destinationNamePrefix = channelNamePrefix;
				} else {
					destinationName = [destinationName substringFromIndex:1];
				}

				/* Locate object that matches destination */
				IRCChannel *destination = [self findChannel:destinationName];

				if (isSecretMessage == NO) {
					/* If the destination does not exist and this isn't a secret
					 message, then create a private message if the destination 
					 is believed to be a user. */
					if (destination == nil && [self stringIsNickname:destinationName]) {
						destination = [worldController() createPrivateMessage:destinationName onClient:self];
					}

					/* Define the channel that will be selected */
					if ([TPCPreferences giveFocusOnMessageCommand]) {
						if (destinationToSelect == nil) {
							destinationToSelect = destination;
						}
					}
				}

				/* Add prefix back if the destination is a channel */
				BOOL destinationIsChannel =
				(destination.isChannel || (destination == nil && [self stringIsChannelName:destinationName]));

				if (destinationNamePrefix && destinationIsChannel) {
					destinationName = [destinationNamePrefix stringByAppendingString:destinationName];
				}

				/* Break text up into substrings which can then be sent. */
				NSMutableAttributedString *lineMutable = [stringIn mutableCopy];

				while (lineMutable.length > 0)
				{
					NSString *unencryptedMessage = [NSAttributedString attributedStringToASCIIFormatting:&lineMutable inChannel:destination onClient:self withLineType:lineType];

					TLOEncryptionManagerEncodingDecodingCallbackBlock encryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
						if (destination == nil) {
							return;
						}

						[self print:originalString
								 by:self.userNickname
						  inChannel:destination
							 asType:lineType
							command:command
						 receivedAt:[NSDate date]
						isEncrypted:wasEncrypted];
					};

					TLOEncryptionManagerInjectCallbackBlock injectionBlock = ^(NSString *encodedString) {
						NSString *sendMessage = encodedString;

						if (lineType == TVCLogLineActionType) {
							sendMessage = [NSString stringWithFormat:@"%c%@ %@%c", 0x01, IRCPrivateCommandIndex("action"), sendMessage, 0x01];
						}

						[self send:commandToSend, destinationName, sendMessage, nil];
					};

					if (destination == nil || isUnencryptedMessag) {
						encryptionBlock(unencryptedMessage, NO);

						injectionBlock(unencryptedMessage);

						continue;
					}

					[self encryptMessage:unencryptedMessage
							  directedAt:destination.name
						encodingCallback:encryptionBlock
					   injectionCallback:injectionBlock];
				}
			} // destination for()

			/* Focus destination */
			if (destinationToSelect) {
				[mainWindow() select:destinationToSelect];
			}
			
			break;
		}
		default:
		{
			/* Find an addon responsible for this command. */
			NSString *addonPath = nil;
			
			BOOL pluginFound = NO;
			BOOL scriptFound = NO;

			BOOL commandIsReserved = NO;

			[sharedPluginManager() findHandlerForOutgoingCommand:lowercaseCommand path:&addonPath isReserved:&commandIsReserved isScript:&scriptFound isExtension:&pluginFound];

			if (commandIsReserved) {
				[sharedPluginManager() extrasInstallerAskUserIfTheyWantToInstallCommand:lowercaseCommand];
			}

			/* Perform script or plugin. */
			if (pluginFound && scriptFound)
			{
				LogToConsoleError("%{public}@", TXTLS(@"IRC[1001]", uppercaseCommand))
			}
			else if (pluginFound && scriptFound == NO)
			{
				[self processBundlesUserMessage:stringInString command:lowercaseCommand];
					
				break;
			}
			else if (pluginFound == NO && scriptFound)
			{
				NSMutableDictionary<NSString *, NSString *> *context = [NSMutableDictionary dictionaryWithCapacity:3];

				[context maybeSetObject:stringInString forKey:@"inputString"];

				[context maybeSetObject:addonPath forKey:@"path"];
				
				[context maybeSetObject:targetChannel.name forKey:@"targetChannel"];

				[self executeTextualCmdScriptInContext:context];

				break;
			}

			/* Send input to server */
			[self send:uppercaseCommand, stringInString, nil];
			
			break;
		}
	}
}

#pragma mark -
#pragma mark Log File (Signed)

/* Signed */
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

/* Signed */
- (void)closeLogFile
{
	if (self.logFile == nil) {
		return;
	}

	[self.logFile close];
}

/* Signed */
- (void)writeToLogLineToLogFile:(TVCLogLine *)logLine
{
	NSParameterAssert(logLine != nil);

	if ([TPCPreferences logToDiskIsEnabled] == NO) {
		return;
	}

	if (self.logFile == nil) {
		self.logFile = [[TLOFileLogger alloc] initWithClient:self];
	}

	[self.logFile writeLogLine:logLine];
}

/* Signed */
- (void)logFileRecordSessionChanged:(BOOL)toNewSession
{
	NSString *localization = nil;

	if (toNewSession) {
		localization = @"IRC[1095]";
	} else {
		localization = @"IRC[1096]";
	}

	/* ============================ */

	TVCLogLineMutable *topLine = [TVCLogLineMutable new];

	topLine.messageBody = NSStringWhitespacePlaceholder;

	[self writeToLogLineToLogFile:topLine];

	/* ============================ */

	TVCLogLineMutable *middleLine = [TVCLogLineMutable new];

	middleLine.messageBody = TXTLS(localization);

	[self writeToLogLineToLogFile:middleLine];

	/* ============================ */

	TVCLogLineMutable *bottomLine = [TVCLogLineMutable new];

	bottomLine.messageBody = NSStringWhitespacePlaceholder;

	[self writeToLogLineToLogFile:bottomLine];

	/* ============================ */

	for (IRCChannel *channel in self.channelList) {
		[channel writeToLogLineToLogFile:topLine];
		[channel writeToLogLineToLogFile:middleLine];
		[channel writeToLogLineToLogFile:bottomLine];
	}
}

/* Signed */
- (void)logFileWriteSessionBegin
{
	[self logFileRecordSessionChanged:YES];
}

/* Signed */
- (void)logFileWriteSessionEnd
{
	[self logFileRecordSessionChanged:NO];
}

#pragma mark -
#pragma mark Print (Signed)

/* Signed */
- (NSString *)formatNickname:(NSString *)nickname inChannel:(nullable IRCChannel *)channel
{
	return [self formatNickname:nickname inChannel:channel withFormat:nil];
}

- (NSString *)formatNickname:(NSString *)nickname inChannel:(nullable IRCChannel *)channel withFormat:(nullable NSString *)format
{
	NSParameterAssert(nickname != nil);

	if (NSObjectIsEmpty(format)) {
		format = themeSettings().themeNicknameFormat;
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeNicknameFormat];
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeNicknameFormatDefault];
	}

	NSString *modeSymbol = NSStringEmptyPlaceholder;

	if (channel.isChannel) {
		IRCUser *member = [channel findMember:nickname];

		if (member) {
			modeSymbol = member.mark;
		}
	}

	NSString *formatMarker = @"%";
	
	NSString *chunk = nil;

	NSScanner *scanner = [NSScanner scannerWithString:format];

	[scanner setCharactersToBeSkipped:nil];

	NSMutableString *buffer = [NSMutableString new];

	while (scanner.atEnd == NO) {
		if ([scanner scanUpToString:formatMarker intoString:&chunk]) {
			[buffer appendString:chunk];
		}

		if ([scanner scanString:formatMarker intoString:nil] == NO) {
			break;
		}

		NSInteger paddingWidth = 0;

		[scanner scanInteger:&paddingWidth];

		/* Read the output type marker */
		NSString *outputValue = nil;

		if ([scanner scanString:@"@" intoString:nil]) {
			outputValue = modeSymbol;
		} else if ([scanner scanString:@"n" intoString:nil]) {
			outputValue = nickname;
		} else if ([scanner scanString:formatMarker intoString:nil]) {
			outputValue = formatMarker;
		}

		if (outputValue) {
			if (paddingWidth < 0 && ABS(paddingWidth) > outputValue.length) {
				NSString *paddedString = [NSStringEmptyPlaceholder stringByPaddingToLength:(ABS(paddingWidth) - outputValue.length) withString:NSStringWhitespacePlaceholder startingAtIndex:0];

				[buffer appendString:paddedString];
			}

			[buffer appendString:outputValue];

			if (paddingWidth > 0 && paddingWidth > outputValue.length) {
				NSString *paddedString = [NSStringEmptyPlaceholder stringByPaddingToLength:(paddingWidth - outputValue.length) withString:NSStringWhitespacePlaceholder startingAtIndex:0];

				[buffer appendString:paddedString];
			}
		}
	}

	return [buffer copy];
}

/* Signed */
- (void)printAndLog:(TVCLogLine *)logLine completionBlock:(TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(logLine != nil);

	[self.viewController print:logLine completionBlock:completionBlock];
	
	[self writeToLogLineToLogFile:logLine];
}

/* Signed */
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:[NSDate date] isEncrypted:NO referenceMessage:nil completionBlock:nil];
}

/* Signed */
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:NO referenceMessage:nil completionBlock:nil];
}

/* Signed */
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:isEncrypted referenceMessage:nil completionBlock:nil];
}

/* Signed */
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted referenceMessage:(nullable IRCMessage *)referenceMessage
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:isEncrypted referenceMessage:referenceMessage completionBlock:nil];
}

/* Signed */
- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted referenceMessage:(nullable IRCMessage *)referenceMessage completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(command != nil || referenceMessage != nil);

	if (self.isTerminating) {
		return;
	}

	/* If an operation does not specify a command value, 
	 then try to obain it from the reference message. */
	if (command == nil) {
		command = referenceMessage.command;
	}

	/* Prevent stupid plugin authors */
	if ([channel isKindOfClass:[IRCChannel class]] == NO) {
		channel = nil;
	}

	/* Do not print this message? */
	if (channel) {
		if ([self outputRuleMatchedInMessage:messageBody inChannel:channel]) {
			return;
		}
	}

	/* Define where the message originated */
	NSString *localNickname = self.userNickname;

	TVCLogLineMemberType memberType = TVCLogLineMemberNormalType;

	if (NSObjectsAreEqual(nickname, localNickname)) {
		memberType = TVCLogLineMemberLocalUserType;
	}

	/* Define list of highlight keywords */
	NSArray<NSString *> *excludeKeywords = nil;
	NSArray<NSString *> *matchKeywords = nil;

	if (channel &&
		channel.config.ignoreHighlights == NO &&
		(lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLineActionType) &&
		memberType == TVCLogLineMemberNormalType)
	{
		excludeKeywords = [TPCPreferences highlightExcludeKeywords];
		matchKeywords = [TPCPreferences highlightMatchKeywords];

		if ([TPCPreferences highlightMatchingMethod] != TXNicknameHighlightRegularExpressionMatchType &&
			[TPCPreferences highlightCurrentNickname])
		{
			matchKeywords = [matchKeywords arrayByAddingObject:localNickname];
		}
	}

	if (lineType == TVCLogLineActionNoHighlightType) {
		lineType = TVCLogLineActionType;
	} else if (lineType == TVCLogLinePrivateMessageNoHighlightType) {
		lineType = TVCLogLinePrivateMessageType;
	}

	/* Create new log entry */
	TVCLogLineMutable *logLine = [TVCLogLineMutable new];

	logLine.command	= command.lowercaseString;

	logLine.lineType = lineType;
	logLine.memberType = memberType;

	logLine.isEncrypted = isEncrypted;

	logLine.excludeKeywords = excludeKeywords;
	logLine.highlightKeywords = matchKeywords;

	logLine.nickname = nickname;

	logLine.messageBody = messageBody;

	logLine.receivedAt = receivedAt;

	/* Print to server console if there is no channel */
	if (channel == nil) {
		[self printAndLog:logLine completionBlock:completionBlock];

		return;
	}

	/* Add scrollback marker to channel if conditions are met */
	if ([TPCPreferences autoAddScrollbackMark]) {
		if (channel != mainWindow().selectedChannel || mainWindow().mainWindow == NO) {
			if (channel.isUnread == NO &&
				(lineType == TVCLogLinePrivateMessageType ||
				 lineType == TVCLogLineActionType ||
				 lineType == TVCLogLineNoticeType))
			{
				[channel.viewController mark];
			}
		}
	}

	/* Print to channel */
	[channel print:logLine completionBlock:completionBlock];
}

/* Signed */
- (void)printReply:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self print:[message sequence:1] by:nil inChannel:nil asType:TVCLogLineDebugType command:message.command receivedAt:message.receivedAt];
}

/* Signed */
- (void)printUnknownReply:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self print:[message sequence:1] by:nil inChannel:nil asType:TVCLogLineDebugType command:message.command receivedAt:message.receivedAt];
}

/* Signed */
- (void)printErrorReply:(IRCMessage *)message
{
	[self printErrorReply:message inChannel:nil];
}

/* Signed */
- (void)printErrorReply:(IRCMessage *)message inChannel:(nullable IRCChannel *)channel
{
	NSParameterAssert(message != nil);

	NSString *errorMessage = TXTLS(@"IRC[1055]", message.commandNumeric, message.sequence);

	[self print:errorMessage by:nil inChannel:channel asType:TVCLogLineDebugType command:message.command];
}

/* Signed */
- (void)printError:(NSString *)errorMessage asCommand:(NSString *)command
{
	[self print:errorMessage by:nil inChannel:nil asType:TVCLogLineDebugType command:command];
}

/* Signed */
- (void)printDebugInformationToConsole:(NSString *)message
{
	[self print:message by:nil inChannel:nil asType:TVCLogLineDebugType command:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (void)printDebugInformationToConsole:(NSString *)message asCommand:(NSString *)command
{
	[self print:message by:nil inChannel:nil asType:TVCLogLineDebugType command:command];
}

/* Signed */
- (void)printDebugInformation:(NSString *)message
{
	[self printDebugInformation:message asCommand:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (void)printDebugInformation:(NSString *)message asCommand:(NSString *)command
{
	IRCChannel *channel = [mainWindow() selectedChannelOn:self];

	[self printDebugInformation:message inChannel:channel asCommand:command];
}

/* Signed */
- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel
{
	[self printDebugInformation:message inChannel:channel asCommand:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel asCommand:(NSString *)command
{
	[self print:message by:nil inChannel:channel asType:TVCLogLineDebugType command:command];
}

#pragma mark -
#pragma mark IRCConnection Delegate (Signed)

/* Signed */
- (void)resetAllPropertyValues
{
	// Some properties are purposely excluded from this method
	// because their state must be kept or they are reset elsewhere

	[self.batchMessages clearQueue];

	self.connectDelay = 0;

	self.inUserInvokedJoinRequest = NO;
	self.inUserInvokedModeRequest = NO;
	self.inUserInvokedNamesRequest = NO;
	self.inUserInvokedWatchRequest = NO;
	self.inUserInvokedWhoRequest = NO;
	self.inUserInvokedWhowasRequest = NO;
	
	self.invokingISONCommandForFirstTime = NO;

	self.isAutojoining = NO;
	self.isAutojoined = NO;

	self.isConnected = NO;
	self.isConnecting = NO;
	self.isLoggedIn = NO;
	self.isQuitting = NO;

	self.isWaitingForNickServ = NO;
	self.serverHasNickServ = NO;
	self.userIsIdentifiedWithNickServ = NO;

	self.userIsAway = NO;
	self.userIsIRCop = NO;

	self.isConnectedToZNC = NO;
	self.zncBoucnerIsSendingCertificateInfo = NO;
	self.zncBouncerCertificateChainDataMutable = nil;
	self.zncBouncerIsPlayingBackHistory = NO;

	self.rawModeEnabled = NO;

	self.reconnectEnabled = NO;

	self.timeoutWarningShownToUser = NO;

	self.lagCheckDestinationChannel = nil;
	self.lagCheckLastCheck = 0;

	self.lastWhoRequestChannelListIndex = 0;

	self.userHostmask = nil;
	self.userNickname = nil;

	self.tryingNicknameNumber = 0;
	self.tryingNicknameSentNickname = nil;
	
	self.preAwayUserNickname = nil;
	
	self.lastMessageReceived = 0;

	self.capacities = 0;
	self.capacityNegotiationIsPaused = NO;

	@synchronized (self.capacitiesPending) {
		[self.capacitiesPending removeAllObjects];
	}

	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}
}

/* Signed */
- (void)changeStateOff
{
	if (self.isConnecting == NO && self.isConnected == NO) {
		return;
	}

	BOOL isTerminating = self.isTerminating;

	self.socket = nil;

	[self stopISONTimer];
	[self stopPongTimer];
	[self stopRetryTimer];

	[self cancelPerformRequests];

	[self.printingQueue cancelAllOperations];

	if (isTerminating == NO && self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	[self.supportInfo reset];

	if (isTerminating == NO) {
		NSString *disconnectMessage = nil;

		if (self.disconnectType == IRCClientDisconnectNormalMode) {
			disconnectMessage = TXTLS(@"IRC[1052]");
		} else if (self.disconnectType == IRCClientDisconnectComputerSleepMode) {
			disconnectMessage = TXTLS(@"IRC[1048]");
		} else if (self.disconnectType == IRCClientDisconnectBadCertificateMode) {
			disconnectMessage = TXTLS(@"IRC[1050]");
		} else if (self.disconnectType == IRCClientDisconnectServerRedirectMode) {
			disconnectMessage = TXTLS(@"IRC[1049]");
		} else if (self.disconnectType == IRCClientDisconnectReachabilityChangeMode) {
			disconnectMessage = TXTLS(@"IRC[1051]");
		}

		for (IRCChannel *channel in self.channelList) {
			if (channel.isActive == NO) {
				channel.errorOnLastJoinAttempt = NO;
			} else {
				[channel deactivate];

				[self printDebugInformation:disconnectMessage inChannel:channel];
			}
		}

		[self printDebugInformationToConsole:disconnectMessage];

		[self.viewController mark];

		if (self.isConnected) {
			[self notifyEvent:TXNotificationDisconnectType lineType:TVCLogLineDebugType];
		}

		[self postEventToViewController:@"serverDisconnected"];
	}

	[self logFileWriteSessionEnd];
	
	[self resetAllPropertyValues];

	if (isTerminating == NO) {
		[mainWindow() reloadTreeGroup:self];

		[mainWindow() updateTitleFor:self];
	}
}

/* Signed */
- (void)ircConnection:(IRCConnection *)sender willConnectToProxy:(NSString *)proxyHost port:(uint16_t)proxyPort
{
	NSParameterAssert(sender == self.socket);

	IRCConnectionSocketProxyType proxyType = self.socket.config.proxyType;

	if (proxyType == IRCConnectionSocketSocks4ProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1057]", proxyHost, proxyPort)];
	} else if (proxyType == IRCConnectionSocketSocks5ProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1058]", proxyHost, proxyPort)];
	} else if (proxyType == IRCConnectionSocketHTTPProxyType) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1059]", proxyHost, proxyPort)];
	}
}

/* Signed */
- (void)ircConnectionDidReceivedAnInsecureCertificate:(IRCConnection *)sender
{
	NSParameterAssert(sender == self.socket);

	self.disconnectType = IRCClientDisconnectBadCertificateMode;
}

/* Signed */
- (void)ircConnectionDidSecureConnection:(IRCConnection *)sender
{
	NSParameterAssert(sender == self.socket);

	NSString *sslProtocolString = [self.socket localizedSecureConnectionProtocolString:NO];

	if (sslProtocolString == nil) {
		return;
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1047]", sslProtocolString)];
}

/* Signed */
- (void)ircConnectionDidConnect:(IRCConnection *)sender
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}
	
	[self startRetryTimer];

	/* If the address we are connecting to is not an IP address,
	 then we report back the actual IP address it was resolved to. */
	NSString *connectedAddress = self.socket.connectedAddress;

	if (connectedAddress == nil || connectedAddress.isIPAddress) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1045]")];
	} else {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1046]", connectedAddress)];
	}

	self.isConnecting = NO;
	self.isConnected = YES;

	self.userNickname = self.config.nickname;
	
	self.tryingNicknameSentNickname = self.config.nickname;

	[self.supportInfo reset];

	[mainWindow() updateTitleFor:self];

	NSString *username = self.config.username;
	NSString *realName = self.config.realName;
	
	NSString *modeSymbols = @"0";
	
	NSString *serverPassword = self.config.serverPassword;

	if (self.config.setInvisibleModeOnConnect) {
		modeSymbols = @"8";
	}

	if (username.length == 0) {
		username = self.config.nickname;
	}

	if (realName.length == 0) {
		realName = self.config.nickname;
	}

	[self sendCapacity:@"LS" data:@"302"];

	if (serverPassword) {
		[self sendPassword:serverPassword];
	}

	[self changeNickname:self.tryingNicknameSentNickname];

	[self send:IRCPrivateCommandIndex("user"), username, modeSymbols, @"*", realName, nil];
}

/* Signed */
- (void)ircConnection:(IRCConnection *)sender didDisconnectWithError:(nullable NSError *)disconnectError
{
	NSParameterAssert(sender == self.socket);

//	if (self.isTerminating) {
//		return;
//	}

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self changeStateOff];
		
		if (self.disconnectCallback) {
			self.disconnectCallback();
			self.disconnectCallback = nil;
		}
	});
}

/* Signed */
- (void)ircConnection:(IRCConnection *)sender didError:(NSString *)error
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}

	[self printError:error asCommand:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (void)ircConnection:(IRCConnection *)sender didReceiveData:(NSString *)data
{
	NSParameterAssert(sender == self.socket);

	if (self.isConnected == NO || self.isTerminating) {
		return;
	}

	if (data.length == 0) {
		return;
	}

	self.lastMessageReceived = [NSDate timeIntervalSince1970];

	worldController().bandwidthIn += data.length;

	worldController().messagesReceived += 1;

	[self logToConsoleIncomingTraffic:data];

	if ([TPCPreferences removeAllFormatting]) {
		data = data.stripIRCEffects;
	}

	IRCMessage *message = [[IRCMessage alloc] initWithLine:data onClient:self];

	if (message == nil) {
		return;
	}

	message = [THOPluginDispatcher interceptServerInput:message for:self];

	if (message == nil) {
		return;
	}

	if ([self filterBatchCommandIncomingData:message]) {
		return;
	}

	[self processIncomingMessage:message];
}

/* Signed */
- (void)processIncomingMessageAttributes:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	if (message.isHistoric == NO) {
		return;
	}

	NSTimeInterval receivedTime = message.receivedAt.timeIntervalSince1970;

	if (receivedTime <= self.lastMessageServerTime) {
		return;
	}

	self.lastMessageServerTime = receivedTime;

	/* If the playback module is in use, then all messages are
	 set as historic, so we set any lines above our current 
	 reference date as not historic to avoid collisions. */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
		[message markAsNotHistoric];
	}
}

/* Signed */
- (void)processIncomingMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self processIncomingMessageAttributes:message];

	if (message.commandNumeric > 0) {
		[self receiveNumericReply:message];

		return;
	}

	NSUInteger commandNumeric = [IRCCommandIndex indexOfIRCommand:message.command publicSearch:NO];

	switch (commandNumeric) {
		case IRCPrivateCommandErrorIndex: // Command: ERROR
		{
			[self receiveError:message];
			
			break;
		}
		case IRCPrivateCommandInviteIndex: // Command: INVITE
		{
			[self receiveInvite:message];
			
			break;
		}
		case IRCPrivateCommandJoinIndex: // Command: JOIN
		{
			[self receiveJoin:message];
			
			break;
		}
		case IRCPrivateCommandKickIndex: // Command: KICK
		{
			[self receiveKick:message];
			
			break;
		}
		case IRCPrivateCommandKillIndex: // Command: KILL
		{
			[self receiveKill:message];
			
			break;
		}
		case IRCPrivateCommandModeIndex: // Command: MODE
		{
			[self receiveMode:message];
			
			break;
		}
		case IRCPrivateCommandNickIndex: // Command: NICK
		{
			[self receiveNick:message];
			
			break;
		}
		case IRCPrivateCommandNoticeIndex: // Command: NOTICE
		case IRCPrivateCommandPrivmsgIndex: // Command: PRIVMSG
		{
			[self receivePrivmsgAndNotice:message];
			
			break;
		}
		case IRCPrivateCommandPartIndex: // Command: PART
		{
			[self receivePart:message];
			
			break;
		}
		case IRCPrivateCommandPingIndex: // Command: PING
		{
			[self receivePing:message];
			
			break;
		}
		case IRCPrivateCommandQuitIndex: // Command: QUIT
		{
			[self receiveQuit:message];
			
			break;
		}
		case IRCPrivateCommandTopicIndex: // Command: TOPIC
		{
			[self receiveTopic:message];
			
			break;
		}
		case IRCPrivateCommandWallopsIndex: // Command: WALLOPS
		{
			[self receiveWallops:message];

			break;
		}
		case IRCPrivateCommandAuthenticateIndex: // Command: AUTHENTICATE
		case IRCPrivateCommandCapIndex: // Command: CAP
		{
			[self updateConnectedToZNCPropertyWithMessage:message];

			[self receiveCapacityOrAuthenticationRequest:message];
			
			break;
		}
		case IRCPrivateCommandAwayIndex: // Command: AWAY (away-notify CAP)
		{
			[self receiveAwayNotifyCapacity:message];

			break;
		}
		case IRCPrivateCommandBatchIndex: // BATCH
		{
			[self receiveBatch:message];

			break;
		}
		case IRCPrivateCommandCertinfoIndex: // CERTINFO
		{
			[self receiveCertInfo:message];

			break;
		}
	}

	[self processBundlesServerMessage:message];
}

/* Signed */
- (void)ircConnection:(IRCConnection *)sender willSendData:(NSString *)data
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}
	
	[self logToConsoleOutgoingTraffic:data];
}

/* Signed */
- (void)logToConsoleOutgoingTraffic:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.rawModeEnabled == NO) {
		return;
	}

	LogToConsoleInfo("OUTGOING [\"%{public}@\"]: << %{public}@", self.networkNameAlt, data)
}

/* Signed */
- (void)logToConsoleIncomingTraffic:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.rawModeEnabled == NO) {
		return;
	}

	LogToConsoleInfo("INCOMING [\"%{public}@\"]: >> %{public}@", self.networkNameAlt, data)
}

#pragma mark -
#pragma mark NickServ Information

/* Signed */
- (NSArray<NSString *> *)nickServSupportedNeedIdentificationTokens
{
	static NSArray<NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValue = [staticValues arrayForKey:@"IRCClient List of NickServ Needs Identification Tokens"];
	});

	return cachedValue;
}

/* Signed */
- (NSArray<NSString *> *)nickServSupportedSuccessfulIdentificationTokens
{
	static NSArray<NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValue = [staticValues arrayForKey:@"IRCClient List of NickServ Successfully Identified Tokens"];
	});

	return cachedValue;
}

#pragma mark -
#pragma mark Protocol Handlers

/* Signed */
- (void)receiveWallops:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	/* WALLOPS are rewritten so that they can be parsed as regular notices */
	NSMutableArray *paramsMutable = [m.params mutableCopy];

	[paramsMutable insertObject:self.userNickname atIndex:0];

	NSString *text = [NSString stringWithFormat:TVCLogLineSpecialNoticeMessageFormat, m.command, paramsMutable[1]];

	paramsMutable[1] = text;

	/* ======================================== */

	IRCMessageMutable *messageMutable = [m mutableCopy];

	messageMutable.command = IRCPrivateCommandIndex("notice");

	messageMutable.params = paramsMutable;

	/* ======================================== */

	[self receivePrivmsgAndNotice:[messageMutable copy]];
}

/* Signed */
- (void)receivePrivmsgAndNotice:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 1);

	NSString *text = [m paramAt:1];

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIdentifyCTCP] && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		text = [text substringFromIndex:1];
	} else if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIdentifyMsg] && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
		text = [text substringFromIndex:1];
	}

	TVCLogLineType lineType = TVCLogLinePrivateMessageType;

	BOOL isPlainText = [m.command isEqualToString:IRCPrivateCommandIndex("privmsg")];

	if ([text hasPrefix:@"\x01"]) {
		text = [text substringFromIndex:1];

		NSInteger closingIndex = [text stringPosition:@"\x01"];

		if (closingIndex >= 0) {
			text = [text substringToIndex:closingIndex];
		}

		if (isPlainText) {
			if ([text hasPrefixIgnoringCase:@"ACTION "]) {
				text = [text substringFromIndex:7];

				lineType = TVCLogLineActionType;
			} else {
				lineType = TVCLogLineCTCPQueryType;
			}
		} else {
			lineType = TVCLogLineCTCPReplyType; // notice -> query
		}
	} else if (isPlainText == NO) {
		lineType = TVCLogLineNoticeType;
	}

	TLOEncryptionManagerEncodingDecodingCallbackBlock decryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
		if (lineType == TVCLogLineActionType ||
			lineType == TVCLogLinePrivateMessageType ||
			lineType == TVCLogLineNoticeType)
		{
			[self receiveText:m lineType:lineType text:text wasEncrypted:wasEncrypted];
		} else if (lineType == TVCLogLineCTCPQueryType) {
			[self receiveCTCPQuery:m text:originalString wasEncrypted:wasEncrypted];
		} else if (lineType == TVCLogLineCTCPReplyType) {
			[self receiveCTCPReply:m text:originalString wasEncrypted:wasEncrypted];
		}
	};

	[self decryptMessage:text referenceMessage:m decodingCallback:decryptionBlock];
}

/* Signed */
- (void)receiveText:(IRCMessage *)m lineType:(TVCLogLineType)lineType text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);

	NSParameterAssert(lineType == TVCLogLineActionType ||
					  lineType == TVCLogLineActionNoHighlightType ||
					  lineType == TVCLogLinePrivateMessageType ||
					  lineType == TVCLogLinePrivateMessageNoHighlightType ||
					  lineType == TVCLogLineNoticeType);

	NSParameterAssert(text != nil);

	NSAssertReturn([m paramsCount] > 0);

	/* Allow empty actions but no other type */
	if (text.length == 0) {
		if (lineType == TVCLogLineActionType ||
			lineType == TVCLogLineActionNoHighlightType)
		{
			text = NSStringWhitespacePlaceholder;
		} else {
			return;
		}
	}

	/* Process target */
	NSString *target = [m paramAt:0];

	if (target.length == 0) {
		return;
	}

	/* It is possible for a channel to have a user mode character in front
	 of it when the message is being addressed to a specific group of users.
	 For example, "+#channel" as the channel name means that the message is
	 addressed to only the voiced users of #channel. We don't care about this
	 mode but we still have to remove it while also taking into account
	 channels who use a character other than the pound symbol as their prefix. */
	NSString *targetPrefix = [self.supportInfo extractUserPrefixFromChannelNamed:target];

	if (targetPrefix.length == 1) {
		target = [target substringFromIndex:1];
	}

	/* Perform ignore check */
	IRCAddressBookEntry *ignoreInfo = [self checkIgnoreAgainstHostmask:m.senderHostmask
															 withMatches:@[	IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey,
																			IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey,
																			IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey,
																			IRCAddressBookDictionaryValueIgnorePublicMessagesKey,
																			IRCAddressBookDictionaryValueIgnorePrivateMessagesKey	]];

	if (ignoreInfo.ignorePublicMessageHighlights == YES) {
		if (lineType == TVCLogLineActionType) {
			lineType = TVCLogLineActionNoHighlightType;
		} else if (lineType == TVCLogLinePrivateMessageType) {
			lineType = TVCLogLinePrivateMessageNoHighlightType;
		}
	}

	if (lineType == TVCLogLineNoticeType) {
		if (ignoreInfo.ignoreNoticeMessages) {
			return;
		}
	}

	/* Public message (directed at channel) */
	if ([self stringIsChannelName:target]) {
		if (ignoreInfo.ignorePublicMessages) {
			return;
		}

		[self _receiveText_Public:m lineType:lineType target:target text:text wasEncrypted:wasEncrypted];

		return;
	}

	/* Private message (from user) */
	if (m.senderIsServer == NO) {
		if (ignoreInfo.ignorePrivateMessages) {
			return;
		}

		[self _receiveText_Private:m lineType:lineType target:target text:text wasEncrypted:wasEncrypted];

		return;
	}

	/* Private message (from server) */
	[self _receiveText_PrivateServer:m lineType:lineType target:target text:text wasEncrypted:wasEncrypted];

	return;
}

/* Signed */
- (void)_receiveText_Public:(IRCMessage *)m lineType:(TVCLogLineType)lineType target:(NSString *)target text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(text != nil);

	IRCChannel *channel = [self findChannel:target];

	if (channel == nil) {
		return;
	}

	NSString *sender = m.senderNickname;

	TVCLogControllerPrintOperationCompletionBlock printCompletionBlock = nil;

	BOOL isPlainText = (lineType != TVCLogLineNoticeType);

	if (isPlainText == NO) {
		/* Completion block for notices */

		printCompletionBlock =
		^(TVCLogControllerPrintOperationContext *context)
		{
			if ([self isSafeToPostNotificationForMessage:m inChannel:channel]) {
				(void)[self notifyText:TXNotificationChannelNoticeType lineType:lineType target:channel nickname:sender text:text];
			}
		};
	} else {
		/* Completion block for regular messages */

		printCompletionBlock =
		^(TVCLogControllerPrintOperationContext *context)
		{
			BOOL isHighlight = context.highlight;

			BOOL postEvent = YES;

			if ([self isSafeToPostNotificationForMessage:m inChannel:channel]) {
				if (isHighlight) {
					postEvent = [self notifyText:TXNotificationHighlightType lineType:lineType target:channel nickname:sender text:text];
				} else {
					postEvent = [self notifyText:TXNotificationChannelMessageType lineType:lineType target:channel nickname:sender text:text];
				}
			}

			if (postEvent == NO) {
				return;
			}

			if (isHighlight) {
				[self setHighlightStateForChannel:channel];
			}

			[self setUnreadStateForChannel:channel isHighlight:isHighlight];
		};
	}

	/* Ask for permission to print message */
	BOOL printMessage = YES;

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
		printMessage = [THOPluginDispatcher receivedText:text
											  authoredBy:m.sender
											 destinedFor:channel
											  asLineType:lineType
												onClient:self
											  receivedAt:m.receivedAt
											wasEncrypted:wasEncrypted];
	}

	/* Print message */
	if (printMessage) {
		[self print:text
				 by:sender
		  inChannel:channel
			 asType:lineType
			command:m.command
		 receivedAt:m.receivedAt
		isEncrypted:wasEncrypted
   referenceMessage:m
	completionBlock:printCompletionBlock];
	}

	/* The remaining logic does not apply to notices */
	if (isPlainText == NO) {
		return;
	}

	/* Update weights of user we're talking with */
	IRCUser *senderMember = [channel findMember:sender];

	if (senderMember == nil) {
		return;
	}

	NSString *localNickname = [self.userNickname trimCharacters:@"_"]; // Remove any underscores from around nickname (Guest___ becomes Guest)

	/* If we are mentioned in this piece of text, then update our weight for the user */
	if ([text contains:localNickname]) {
		[senderMember outgoingConversation];
	} else {
		[senderMember conversation];
	}
}

- (void)_receiveText_Private:(IRCMessage *)m lineType:(TVCLogLineType)lineType target:(NSString *)target text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(text != nil);

	NSString *sender = m.senderNickname;

	TVCLogControllerPrintOperationCompletionBlock printCompletionBlock = nil;

	BOOL isPlainText = (lineType != TVCLogLineNoticeType);

	/* If the self-message CAP is not enabled, we still check if we are on a ZNC
	 based connections because older versions of ZNC combined with the privmsg
	 module need the correct behavior which the self-message CAP evolved into. */
	BOOL isSelfMessage = NO;

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCSelfMessage] || self.isConnectedToZNC) {
		isSelfMessage = [self nicknameIsMyself:sender];
	}

	/* Does the query for the sender already exist?... */
	IRCChannel *query = nil;

	if (isSelfMessage == YES) {
		query = [self findChannel:target]; // Look for a query related to target, rather than sender
	} else {
		query = [self findChannel:sender];
	}

	BOOL newPrivateMessage = NO;

	if (isPlainText == NO) {
		/* Logic for notices */

		/* Process services */
		if ([sender isEqualIgnoringCase:@"ChanServ"]) {
			[self _receiveText_PrivateNoticeFromChanServ:&query text:&text];
		} else if ([sender isEqualIgnoringCase:@"NickServ"]) {
			[self _receiveText_PrivateNoticeFromNickServ:&query text:&text];
		}

		/* Determine where to send notice messages */
		if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
			query = [mainWindow() selectedChannelOn:self];
		}

		/* Do not create query until after ChanServ notices have been processed
		 so that entry messages do not create a new window. */
		if (query == nil) {
			if ([TPCPreferences locationToSendNotices] == TXNoticeSendToQueryDestinationType) {
//				newPrivateMessage = YES;

				if (isSelfMessage) {
					query = [worldController() createPrivateMessage:target onClient:self];
				} else {
					query = [worldController() createPrivateMessage:sender onClient:self];
				}
			}
		}

		printCompletionBlock =
		^(TVCLogControllerPrintOperationContext *context)
		{
			if (isSelfMessage) {
				return;
			}

			BOOL postEvent = YES;

			if ([self isSafeToPostNotificationForMessage:m inChannel:query]) {
				postEvent = [self notifyText:TXNotificationPrivateNoticeType lineType:lineType target:query nickname:sender text:text];
			}

			if (postEvent && query != nil) {
				[self setUnreadStateForChannel:query];
			}
		};
	}
	else // NOTICE message
	{
		/* Logic for regular messages */

		if (query == nil) {
			newPrivateMessage = YES;

			if (isSelfMessage) {
				query = [worldController() createPrivateMessage:target onClient:self];
			} else {
				query = [worldController() createPrivateMessage:sender onClient:self];
			}
		}

		printCompletionBlock =
		^(TVCLogControllerPrintOperationContext *context)
		{
			if (isSelfMessage) {
				return;
			}

			BOOL isHighlight = context.highlight;

			BOOL postEvent = YES;

			if ([self isSafeToPostNotificationForMessage:m inChannel:query]) {
				if (isHighlight) {
					postEvent = [self notifyText:TXNotificationHighlightType lineType:lineType target:query nickname:sender text:text];
				} else {
					if (newPrivateMessage) {
						postEvent = [self notifyText:TXNotificationNewPrivateMessageType lineType:lineType target:query nickname:sender text:text];
					} else {
						postEvent = [self notifyText:TXNotificationPrivateMessageType lineType:lineType target:query nickname:sender text:text];
					}
				}
			}

			if (postEvent == NO) {
				return;
			}

			if (isHighlight) {
				[self setHighlightStateForChannel:query];
			}

			[self setUnreadStateForChannel:query isHighlight:isHighlight];
		};
	}

	/* Ask for permission to print message */
	BOOL printMessage = YES;

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
		printMessage = [THOPluginDispatcher receivedText:text
											  authoredBy:m.sender
											 destinedFor:query
											  asLineType:lineType
												onClient:self
											  receivedAt:m.receivedAt
											wasEncrypted:wasEncrypted];
	}

	/* Print message */
	if (printMessage) {
		[self print:text
				 by:sender
		  inChannel:query
			 asType:lineType
			command:m.command
		 receivedAt:m.receivedAt
		isEncrypted:wasEncrypted
   referenceMessage:m
	completionBlock:printCompletionBlock];
	}

	/* The remaining logic does not apply to notices */
	if (isPlainText == NO) {
		return;
	}

	/* Set the query topic to the host of the sender */
	/* Internally this is how Textual sets the title of the window.
	 It is kind of hackish, but it's really not that bad. */
	NSString *senderHostmask = m.senderHostmask;

	if (NSObjectsAreEqual(query.topic, senderHostmask) == NO) {
		query.topic = senderHostmask;
		
		[mainWindow() updateTitleFor:query];
	}
	
	/* Update query status */
	if (query.isActive == NO) {
		[query activate];

		[mainWindow() reloadTreeItem:query];
	}
}

/* Signed */
- (void)_receiveText_PrivateNoticeFromChanServ:(IRCChannel **)target text:(NSString **)text
{
	NSParameterAssert(target != NULL);
	NSParameterAssert(text != NULL);

	NSString *textIn = (*text);

	/* Forward entry messages to the channel they are associated with. */
	/* Format we are going for: -ChanServ- [#channelname] blah blah... */
	NSInteger spacePosition = [textIn stringPosition:NSStringWhitespacePlaceholder];

	if ([textIn hasPrefix:@"["] == NO || spacePosition < 4) {
		return;
	}

	NSString *textHead = [textIn substringToIndex:spacePosition];

	if ([textHead hasSuffix:@"]"] == NO) {
		return;
	}

	textHead = [textHead substringToIndex:(textHead.length - 1)]; // Remove the ]
	textHead = [textHead substringFromIndex:1]; // Remove the [

	if ([self stringIsChannelName:textHead] == NO) {
		return;
	}

	IRCChannel *channel = [self findChannel:textHead];

	if (channel == nil) {
		return;
	}

	*text = [textIn substringFromIndex:(textHead.length + 2)]; // Remove the [#channelname] from the text

	*target = channel;
}

/* Signed */
- (void)_receiveText_PrivateNoticeFromNickServ:(IRCChannel **)target text:(NSString **)text
{
	NSParameterAssert(target != NULL);
	NSParameterAssert(text != NULL);

	self.serverHasNickServ = YES;

	NSString *textIn = nil;

	if ([TPCPreferences removeAllFormatting] == NO) {
		textIn = (*text).stripIRCEffects;
	} else {
		textIn = (*text);
	}

	/* If we are not waiting for a response from NickServ, 
	 then try sending our password if that's what it requested. */
	if (self.isWaitingForNickServ == NO) {
		NSString *nicknamePassword = self.config.nicknamePassword;

		if (nicknamePassword.length == 0) {
			return;
		}

		for (NSString *token in self.nickServSupportedNeedIdentificationTokens) {
			if ([textIn containsIgnoringCase:token] == NO) {
				continue;
			}

			// Send password
			if ([self.serverAddress hasSuffix:@"dal.net"])
			{
				NSString *message = [NSString stringWithFormat:@"IDENTIFY %@", nicknamePassword];

				[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ@services.dal.net", message, nil];
			}
			else if (self.config.sendAuthenticationRequestsToUserServ)
			{
				NSString *message = [NSString stringWithFormat:@"login %@ %@", self.config.nickname, nicknamePassword];

				[self send:IRCPrivateCommandIndex("privmsg"), @"userserv", message, nil];
			}
			else
			{
				NSString *message = [NSString stringWithFormat:@"IDENTIFY %@", nicknamePassword];

				[self send:IRCPrivateCommandIndex("privmsg"), @"NickServ", message, nil];
			}

			// Reset properties
			self.isWaitingForNickServ = YES;

			self.userIsIdentifiedWithNickServ = NO;

			break;
		}

		return;
	}

	/* Scan for messages telling us that we are now identified */
	for (NSString *token in self.nickServSupportedSuccessfulIdentificationTokens) {
		if ([textIn containsIgnoringCase:token] == NO) {
			continue;
		}

		self.isWaitingForNickServ = NO;

		self.userIsIdentifiedWithNickServ = YES;

		if (self.config.autojoinWaitsForNickServ) {
			[self performAutoJoin];
		}

		break;
	}
}

/* Signed */
- (void)_receiveText_PrivateServer:(IRCMessage *)m lineType:(TVCLogLineType)lineType target:(NSString *)target text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(text != nil);

	NSString *sender = m.senderNickname;

	/* Print message */
	BOOL printMessage = YES;

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsDidReceivePlainTextMessageEvent]) {
		printMessage = [THOPluginDispatcher receivedText:text
											  authoredBy:m.sender
											 destinedFor:nil
											  asLineType:lineType
												onClient:self
											  receivedAt:m.receivedAt
											wasEncrypted:wasEncrypted];
	}

	if (printMessage) {
		[self print:text
				 by:sender
		  inChannel:nil
			 asType:lineType
			command:m.command
		 receivedAt:m.receivedAt
		isEncrypted:wasEncrypted];
	}

	/* Disconnect and reconnect if message is believed to be from an irssi proxy */
	/* If we do not do this, the internal state of the client becomes fucked all around */
	if ([sender hasSuffix:@".proxy"] && [text isEqualToString:@"Connected to server"]) {
		__weak IRCClient *weakSelf = self;

		self.disconnectCallback = ^{
			[weakSelf printDebugInformationToConsole:TXTLS(@"IRC[1114]")];

			[weakSelf connect:IRCClientConnectReconnectMode];
		};

		[self disconnect];
	}
}

/* Signed */
- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(text != nil);

	/* Find ignore for sender and possibly exit method */
	IRCAddressBookEntry *ignoreInfo = [self checkIgnoreAgainstHostmask:m.senderHostmask
														   withMatches:@[IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey,
																		 IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey]];

	if (ignoreInfo.ignoreClientToClientProtocol) {
		return;
	}

	/* Context */
	NSMutableString *textMutable = [text mutableCopy];

	NSString *sender = m.senderNickname;

	NSString *command = textMutable.uppercaseGetToken;

	if (command.length == 0) {
		return;
	}

	/* Ignore query if the user has configured Textual to do so */
	if ([TPCPreferences replyToCTCPRequests] == NO) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1032]", command, sender)];

		return;
	}

	/* Process DCC requests elsewhere */
	if ([command isEqualToString:IRCPrivateCommandIndex("dcc")]) {
		[self receivedDCCQuery:m text:textMutable ignoreInfo:ignoreInfo];
		
		return;
	}

	/* Print message */
	BOOL isLagCheckQuery = [command isEqualToString:IRCPrivateCommandIndex("ctcp_lagcheck")];

	IRCChannel *printTarget = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
		printTarget = [mainWindow() selectedChannelOn:self];
	}

	NSString *messageToPrint = TXTLS(@"IRC[1065]", command, sender);

	if (isLagCheckQuery == NO) {
		[self print:messageToPrint
				 by:nil
		  inChannel:printTarget
			 asType:TVCLogLineCTCPQueryType
			command:m.command
		 receivedAt:m.receivedAt
		isEncrypted:wasEncrypted];
	}

	/* Respond to query with the value asked for */
	if (isLagCheckQuery)
	{
		[self receiveCTCPLagCheckQuery:m];
	}

	/* CAP command */
	/* Textual responding to CTCP CAP command is undocumented and is subject to change. */
	/* Textual responds to this command by replying with the capacities it supports. */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_cap")])
	{
		NSString *subcommand = textMutable.token;

		if ([subcommand isEqualIgnoringCase:@"LS"] == NO) {
			return;
		}

		[self sendCTCPReply:sender command:command text:TXTLS(@"IRC[1033]")];
	}

	/* CLIENTINFO command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_clientinfo")])
	{
		[self sendCTCPReply:sender command:command text:TXTLS(@"IRC[1034]")];
	}

	/* FINGER command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_finger")])
	{
		[self sendCTCPReply:sender command:command text:TXTLS(@"IRC[1035]")];
	}

	/* PING command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")])
	{
		if (textMutable.length > 50) {
			LogToConsoleInfo("Ignoring PING query that exceeds 50 bytes")

			return;
		}

		[self sendCTCPReply:sender command:command text:textMutable];
	}

	/* TIME command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_time")])
	{
		NSString *text = [[NSDate date] descriptionWithLocale:[NSLocale systemLocale]];
		
		[self sendCTCPReply:sender command:command text:text];
	}

	/* USERINFO command and VERSION command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")] ||
			 [command isEqualToString:IRCPrivateCommandIndex("ctcp_version")])
	{
		NSString *fakeVersion = [TPCPreferences masqueradeCTCPVersion];

		if (fakeVersion.length > 0) {
			[self sendCTCPReply:sender command:command text:fakeVersion];

			return;
		}

		NSString *applicationName = [TPCApplicationInfo applicationName];
		NSString *versionShort = [TPCApplicationInfo applicationVersionShort];

		NSString *text = TXTLS(@"IRC[1026]", applicationName, versionShort);

		[self sendCTCPReply:sender command:command text:text];
	}
}

/* Signed */
- (void)receiveCTCPLagCheckQuery:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	if ([self messageIsFromMyself:m] == NO) {
		return;
	}

	if (self.lagCheckLastCheck == 0) {
		return;
	}

	double delta = ([NSDate timeIntervalSince1970] - self.lagCheckLastCheck);

	NSString *ratingString = nil;

	if (delta < 0.01) {
		ratingString = TXTLS(@"IRC[1025][00]");
	} else if (delta >= 0.01 && delta < 0.1) {
		ratingString = TXTLS(@"IRC[1025][01]");
	} else if (delta >= 0.1 && delta < 0.2) {
		ratingString = TXTLS(@"IRC[1025][02]");
	} else if (delta >= 0.2 && delta < 0.5) {
		ratingString = TXTLS(@"IRC[1025][03]");
	} else if (delta >= 0.5 && delta < 1.0) {
		ratingString = TXTLS(@"IRC[1025][04]");
	} else if (delta >= 1.0 && delta < 2.0) {
		ratingString = TXTLS(@"IRC[1025][05]");
	} else if (delta >= 2.0 && delta < 5.0) {
		ratingString = TXTLS(@"IRC[1025][06]");
	} else if (delta >= 5.0 && delta < 10.0) {
		ratingString = TXTLS(@"IRC[1025][07]");
	} else if (delta >= 10.0 && delta < 30.0) {
		ratingString = TXTLS(@"IRC[1025][08]");
	} else if (delta >= 30.0) {
		ratingString = TXTLS(@"IRC[1025][09]");
	}

	NSString *message = TXTLS(@"IRC[1022]", self.serverAddress, delta, ratingString);

	if (self.lagCheckDestinationChannel) {
		[self sendPrivmsg:message toChannel:self.lagCheckDestinationChannel];

		self.lagCheckDestinationChannel = nil;
	} else {
		[self printDebugInformation:message];
	}

	self.lagCheckLastCheck = 0;
}

/* Signed */
- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(text != nil);

	/* Find ignore for sender and possibly exit method */
	IRCAddressBookEntry *ignoreInfo = [self checkIgnoreAgainstHostmask:m.senderHostmask
														   withMatches:@[IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey]];

	if (ignoreInfo.ignoreClientToClientProtocol) {
		return;
	}

	/* Context */
	NSMutableString *textMutable = [text mutableCopy];

	NSString *sender = m.senderNickname;

	NSString *command = textMutable.uppercaseGetToken;

	if (command.length == 0) {
		return;
	}

	/* Print message */
	IRCChannel *printTarget = nil;

	if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
		printTarget = [mainWindow() selectedChannelOn:self];
	}

	NSString *messageToPrint = nil;

	if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_ping")]) {
		double delta = ([NSDate timeIntervalSince1970] - textMutable.doubleValue);
		
		messageToPrint = TXTLS(@"IRC[1063]", sender, command, delta);
	} else {
		messageToPrint = TXTLS(@"IRC[1064]", sender, command, textMutable);
	}

	[self print:messageToPrint
			 by:nil
	  inChannel:printTarget
		 asType:TVCLogLineCTCPReplyType
		command:m.command
	 receivedAt:m.receivedAt
	isEncrypted:wasEncrypted];
}

- (void)receiveJoin:(IRCMessage *)m
{
	NSAssertReturn([m paramsCount] > 0);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;
	
	NSString *sender = m.senderNickname;

	BOOL myself = [self nicknameIsMyself:sender];

	NSString *channelName = [m paramAt:0];

	IRCChannel *channel = nil;

	if (isPrintOnlyMessage == NO && myself)
	{
		channel = [self findChannelOrCreate:channelName];

		if (channel.isActive == NO) {
			[channel activate];
		} else {
			return;
		}

		self.userHostmask = m.senderHostmask;

		if (self.isAutojoining == NO && self.inUserInvokedJoinRequest) {
			[mainWindow() expandClient:self];
					
			[mainWindow() select:channel];
		}

		[self disableInUserInvokedCommandProperty:&self->_inUserInvokedJoinRequest];

		[mainWindow() reloadTreeItem:channel];
	}
	else // myself
	{
		channel = [self findChannel:channelName];
		
		if (channel == nil) {
			return;
		}
	}

	if (isPrintOnlyMessage == NO) {
		IRCUserMutable *member = [[IRCUserMutable alloc] initWithNickname:sender onClient:self];
		
		member.username = m.senderUsername;
		member.address = m.senderAddress;
		
		[channel addMember:member];
	}

	if (isPrintOnlyMessage && myself == NO) {
		IRCChannel *senderQuery = [self findChannel:sender];
		
		if (senderQuery && senderQuery.isActive == NO) {
			[senderQuery activate];

			[self print:TXTLS(@"IRC[1071]", sender)
					 by:nil
			  inChannel:senderQuery
				 asType:TVCLogLineJoinType
				command:m.command
			 receivedAt:m.receivedAt];
			
			[mainWindow() reloadTreeItem:senderQuery];
		}
	}

	IRCAddressBookEntry *ignoreInfo = nil;

	if (myself == NO) {
		ignoreInfo =
		[self checkIgnoreAgainstHostmask:m.senderHostmask
							 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
										   IRCAddressBookDictionaryValueTrackUserActivityKey]];

		if (ignoreInfo && isPrintOnlyMessage == NO) {
			[self updateUserTrackingStatusForEntry:ignoreInfo withMessage:m];
		}
	}

	BOOL printMessage = [self postReceivedMessage:m withText:nil destinedFor:channel];

	if (printMessage && myself == NO)
	{
		if ([TPCPreferences showJoinLeave] == NO) {
			printMessage = NO;
		} else if (channel.config.ignoreGeneralEventMessages) {
			printMessage = NO;
		} else {
			if (ignoreInfo) {
				printMessage = ignoreInfo.ignoreGeneralEventMessages;
			}
		}
	}

	if (printMessage) {
		NSString *message = TXTLS(@"IRC[1077]", sender, m.senderUsername, m.senderAddress.stringByAppendingIRCFormattingStop);

		[self print:message
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineJoinType
			command:m.command
		 receivedAt:m.receivedAt];
	}

	if (isPrintOnlyMessage) {
		return;
	}

	[mainWindow() updateTitleFor:channel];

	if (myself) {
		if (self.config.sendWhoCommandRequestsToChannels && self.isBrokenIRCd_aka_Twitch == NO) {
			channel.inUserInvokedModeRequest = YES;

			[self requestModesForChannel:channel];
		}
	} else {
		[self maybeResetUserAwayStatusForChannel:channel];
	}
}

/* Signed */
- (void)receivePart:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;
	
	NSString *channelName = [m paramAt:0];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil) {
		return;
	}

	NSString *sender = m.senderNickname;

	BOOL myself = [self nicknameIsMyself:sender];
	
	if (isPrintOnlyMessage == NO) {
		if (myself) {
			[channel deactivate];

			[mainWindow() reloadTreeItem:channel];
		} else {
			[channel removeMemberWithNickname:sender];
		}
	}

	NSString *comment = [m paramAt:1];

	BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:channel];

	if (printMessage && myself == NO)
	{
		if ([TPCPreferences showJoinLeave] == NO) {
			printMessage = NO;
		} else if (channel.config.ignoreGeneralEventMessages) {
			printMessage = NO;
		} else {
			IRCAddressBookEntry *ignoreInfo =
			[self checkIgnoreAgainstHostmask:m.senderHostmask
								 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if (ignoreInfo) {
				printMessage = ignoreInfo.ignoreGeneralEventMessages;
			}
		}
	}

	if (printMessage) {
		NSString *message = TXTLS(@"IRC[1079]", sender, m.senderUsername, m.senderAddress.stringByAppendingIRCFormattingStop);

		if (comment.length > 0) {
			message = TXTLS(@"IRC[1080]", message, comment.stringByAppendingIRCFormattingStop);
		}

		[self print:message
				 by:nil
		  inChannel:channel
			 asType:TVCLogLinePartType
			command:m.command
		 receivedAt:m.receivedAt];
	}

	if (isPrintOnlyMessage == NO) {
		[mainWindow() updateTitleFor:channel];
	}
}

/* Signed */
- (void)receiveKick:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 1);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *channelName = [m paramAt:0];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil) {
		return;
	}

	NSString *sender = m.senderNickname;

	NSString *target = [m paramAt:1];
	NSString *comment = [m paramAt:2];

	BOOL myself = [self nicknameIsMyself:target];

	if (isPrintOnlyMessage == NO) {
		if (myself)
		{
			[channel deactivate];

			[mainWindow() reloadTreeItem:channel];

			/* Notify user */
			[self notifyEvent:TXNotificationKickType lineType:TVCLogLineKickType target:channel nickname:sender text:comment];

			/* Rejoin channel */
			if ([TPCPreferences rejoinOnKick] && channel.errorOnLastJoinAttempt == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1043]") inChannel:channel];

				[self cancelPerformRequestsWithSelector:@selector(joinKickedChannel:) object:channel];
				
				[self performSelector:@selector(joinKickedChannel:) withObject:channel afterDelay:3.0];
			}
		}
		else // myself
		{
			[channel removeMemberWithNickname:target];
		}
	}

	BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:channel];

	if (printMessage && myself == NO)
	{
		if ([TPCPreferences showJoinLeave] == NO) {
			printMessage = NO;
		} else if (channel.config.ignoreGeneralEventMessages) {
			printMessage = NO;
		} else {
			IRCAddressBookEntry *ignoreInfo =
			[self checkIgnoreAgainstHostmask:m.senderHostmask
								 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if (ignoreInfo) {
				printMessage = ignoreInfo.ignoreGeneralEventMessages;
			}
		}
	}

	if (printMessage) {
		NSString *message = TXTLS(@"IRC[1078]", sender, target, comment.stringByAppendingIRCFormattingStop);

		[self print:message
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineKickType
			command:m.command
		 receivedAt:m.receivedAt];
	}

	if (isPrintOnlyMessage == NO) {
		[mainWindow() updateTitleFor:channel];
	}
}

- (void)receiveQuit:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *channelName = nil;

	NSString *comment = nil;

	if (isPrintOnlyMessage) {
		channelName = [m paramAt:0];

		comment = [m paramAt:1];
	} else {
		comment = [m paramAt:0];
	}

	NSString *sender = m.senderNickname;

	BOOL myself = [self nicknameIsMyself:sender];

	IRCAddressBookEntry *ignoreInfo = nil;

	if (myself == NO) {
		ignoreInfo =
		[self checkIgnoreAgainstHostmask:m.senderHostmask
							 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
										   IRCAddressBookDictionaryValueTrackUserActivityKey]];

		if (ignoreInfo && isPrintOnlyMessage == NO) {
			[self updateUserTrackingStatusForEntry:ignoreInfo withMessage:m];
		}
	}

	NSString *messageToPrint = TXTLS(@"IRC[1069]", sender, m.senderUsername, m.senderAddress.stringByAppendingIRCFormattingStop);

	if (comment.length > 0) {
		messageToPrint = TXTLS(@"IRC[1066]", messageToPrint, comment.stringByAppendingIRCFormattingStop);
	}

	void (^printingBlock)(IRCChannel *) = ^(IRCChannel *channel)
	{
		if (myself == NO && isPrintOnlyMessage == NO) {
			if (channel.isChannel) {
				IRCUser *member = [channel findMember:sender];

				if (member == nil) {
					return;
				}

				[channel removeMember:member];
			} else {
				if (NSObjectsAreEqual(channel.name, sender) == NO) {
					return;
				}

				if (channel.isActive) {
					[channel deactivate];

					[mainWindow() reloadTreeItem:channel];
				}
			}
		}

		NSString *message = messageToPrint;

		if (channel.isChannel)
		{
			BOOL printMessage = [self postReceivedMessage:m withText:comment destinedFor:channel];

			if (printMessage && myself == NO)
			{
				if ([TPCPreferences showJoinLeave] == NO) {
					printMessage = NO;
				} else if (channel.config.ignoreGeneralEventMessages) {
					printMessage = NO;
				} else {
					if (ignoreInfo) {
						printMessage = ignoreInfo.ignoreGeneralEventMessages;
					}
				}
			}

			if (printMessage == NO) {
				return;
			}
		}
		else // -isChannel
		{
			message = TXTLS(@"IRC[1070]", sender);
		}

		[self print:message
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineQuitType
			command:m.command
		 receivedAt:m.receivedAt];
	};

	if (isPrintOnlyMessage) {
		IRCChannel *channel = [self findChannel:channelName];

		if (channel == nil) {
			return;
		}

		printingBlock(channel);

		return;
	}

	for (IRCChannel *c in self.channelList) {
		printingBlock(c);
	}

	if (myself == NO) {
		[mainWindow() updateTitleFor:self];
	}
}

/* Signed */
- (void)receiveKill:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	NSString *nickname = [m paramAt:0];

	for (IRCChannel *c in self.channelList) {
		[c removeMemberWithNickname:nickname];
	}
}

/* Signed */
- (void)receiveNick:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	/* Print only messages target specific channels which means
	 the index of incoming data will be different */
	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *channelName = nil;

	NSString *newNickname = nil;

	if (isPrintOnlyMessage) {
		channelName = [m paramAt:0];

		newNickname = [m paramAt:1];
	} else {
		newNickname = [m paramAt:0];
	}

	/* There's no reason to perform an udpate if nothing changed */
	NSString *oldNickname = m.senderNickname;

	if ([oldNickname isEqualToString:newNickname]) {
		return;
	}

	BOOL myself = [self nicknameIsMyself:oldNickname];

	/* Find address book entry for old nickname and update tracking
	 status. This entry will also be used later on,	 when printing, 
	 to decide whether to print the message. */
	IRCAddressBookEntry *oldNicknameIgnoreInfo = nil;

	if (myself == NO) {
		oldNicknameIgnoreInfo =
		[self checkIgnoreAgainstHostmask:m.senderHostmask
							 withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey,
										   IRCAddressBookDictionaryValueTrackUserActivityKey]];
	}

	/* Perform restricted actions */
	if (isPrintOnlyMessage == NO) {
		if (myself)
		{
			self.userNickname = newNickname;

			if (self.tryingNicknameSentNickname != nil) {
				self.tryingNicknameSentNickname = newNickname;
			}
		}
		else
		{
			/* Update user tracking status for old nickname */
			if (oldNicknameIgnoreInfo) {
				[self updateUserTrackingStatusForEntry:oldNicknameIgnoreInfo withMessage:m];
			}

			/* Update user tracking status for new nickname */
			NSString *newNicknameHostmask = [newNickname stringByAppendingString:@"!*@*"];

			IRCAddressBookEntry *newNicknameIgnoreInfo =
			[self checkIgnoreAgainstHostmask:newNicknameHostmask
								 withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

			if (newNicknameIgnoreInfo) {
				[self updateUserTrackingStatusForEntry:newNicknameIgnoreInfo withMessage:m];
			}
		}
	}

	/* Setup block that is used by printing operations */
	NSString *messageToPrint = nil;

	if (myself) {
		messageToPrint = TXTLS(@"IRC[1068][1]", newNickname);
	} else {
		messageToPrint = TXTLS(@"IRC[1068][0]", oldNickname, newNickname);
	}

	void (^printingBlock)(IRCChannel *) = ^(IRCChannel *channel)
	{
		if (isPrintOnlyMessage == NO) {
			if (channel.isChannel) {
				/* Rename the user in the channel */
				IRCUser *member = [channel findMember:oldNickname];

				if (member == nil) {
					return;
				}

				[channel renameMember:member to:newNickname];
			} else {
				/* Rename private message if one with old name is found */
				if (NSObjectsAreEqual(channel.name, oldNickname) == NO) {
					return;
				}

				IRCChannel *newNicknameQuery = [self findChannel:newNickname];

				if (newNicknameQuery) {
					/* If a query of this name already exists, then we
					 destroy it before changing name of old. */
					[worldController() destroyChannel:newNicknameQuery];
				}

				channel.name = newNickname;

				[mainWindow() reloadTreeItem:channel];
			}
		}

		/* Determine whether the message should be printed */
		if (channel.isChannel) {
			BOOL printMessage = [self postReceivedMessage:m withText:newNickname destinedFor:channel];

			if (printMessage && myself == NO)
			{
				if ([TPCPreferences showJoinLeave] == NO) {
					printMessage = NO;
				} else if (channel.config.ignoreGeneralEventMessages) {
					printMessage = NO;
				} else {
					if (oldNicknameIgnoreInfo) {
						printMessage = oldNicknameIgnoreInfo.ignoreGeneralEventMessages;
					}
				}
			}

			if (printMessage == NO) {
				return;
			}
		}

		/* Print message */
		[self print:messageToPrint
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineNickType
			command:m.command
		 receivedAt:m.receivedAt];
	};

	/* Target print */
	if (isPrintOnlyMessage) {
		IRCChannel *channel = [self findChannel:channelName];

		if (channel == nil) {
			return;
		}

		printingBlock(channel);

		return;
	}

	/* Continue with normal operations */
	for (IRCChannel *c in self.channelList) {
		printingBlock(c);
	}

	/* Reload window title (our nickname is shown there) */
	if (myself) {
		[mainWindow() updateTitleFor:self];
	}

	/* Inform file transfer controller of name change */
	[[self fileTransferController] nicknameChanged:oldNickname toNickname:newNickname client:self];
}

/* Signed */
- (void)receiveMode:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 1);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *sender = m.senderNickname;
	
	NSString *channelName = [m paramAt:0];
	NSString *modeString = [m sequence:1];

	/* Present user modes */
	if ([self stringIsChannelName:channelName] == NO) {
		BOOL printMessage = [self postReceivedCommand:@"UMODE" withText:modeString destinedFor:nil referenceMessage:m];

		if (printMessage) {
			[self print:TXTLS(@"IRC[1062]", sender, modeString)
					 by:nil
			  inChannel:nil
				 asType:TVCLogLineModeType
				command:m.command
			 receivedAt:m.receivedAt];
		}

		return;
	}

	/* Present channel modes */
	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil) {
		return;
	}
	
	if (isPrintOnlyMessage == NO) {
		NSArray *modes = [channel.modeInfo updateModes:modeString];

		for (IRCModeInfo *mode in modes) {
			if ([mode isModeForChangingMemberModeOn:self] == NO) {
				continue;
			}

			[channel changeMember:mode.modeParamater mode:mode.modeSymbol value:mode.modeIsSet];
		}
	}

	BOOL printMessage = [self postReceivedMessage:m withText:modeString destinedFor:channel];

	if (printMessage) {
		printMessage = ([TPCPreferences showJoinLeave] || channel.config.ignoreGeneralEventMessages == NO);
	}

	if (printMessage) {
		[self print:TXTLS(@"IRC[1062]", sender, modeString)
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineModeType
			command:m.command
		 receivedAt:m.receivedAt];
	}

	if (isPrintOnlyMessage == NO) {
		[mainWindow() updateTitleFor:channel];
	}
}

/* Signed */
- (void)receiveTopic:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] == 2);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;
	
	NSString *sender = m.senderNickname;

	NSString *channelName = [m paramAt:0];
	NSString *topic = [m paramAt:1];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil) {
		return;
	}

	if (isPrintOnlyMessage == NO) {
		channel.topic = topic;
	}

	BOOL printMessage = [self postReceivedMessage:m withText:topic destinedFor:channel];

	if (printMessage) {
		[self print:TXTLS(@"IRC[1044]", sender, topic)
				 by:nil
		  inChannel:channel
			 asType:TVCLogLineTopicType
			command:m.command
		 receivedAt:m.receivedAt];
	}
}

/* Signed */
- (void)receiveInvite:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] == 2);

	NSString *sender = m.senderNickname;
	
	NSString *channelName = [m paramAt:1];
	
	NSString *message = TXTLS(@"IRC[1074]", sender, m.senderUsername, m.senderAddress, channelName);
	
	/* Invite notifications are sent to frontmost channel on server of if it is
	 not on server, then it will be redirected to console. */
	BOOL printMessage = [self postReceivedMessage:m withText:channelName destinedFor:nil];

	if (printMessage) {
		[self print:message
				 by:nil
		  inChannel:[mainWindow() selectedChannelOn:self]
			 asType:TVCLogLineInviteType
			command:m.command
		 receivedAt:m.receivedAt];
	}
	
	[self notifyEvent:TXNotificationInviteType lineType:TVCLogLineInviteType target:nil nickname:sender text:channelName];
	
	if ([TPCPreferences autoJoinOnInvite]) {
		[self joinUnlistedChannel:channelName];
	}
}

/* Signed */
- (void)receiveError:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSString *message = m.sequence;

    if (([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Excess Flood)"]) ||
		([message hasPrefix:@"Closing Link:"] && [message hasSuffix:@"(Max SendQ exceeded)"]))
	{
		__weak IRCClient *weakSelf = self;
		
		self.disconnectCallback = ^{
			[weakSelf cancelReconnect];
		};
	}

	[self printError:message asCommand:m.command];
}

/* Signed */
- (void)receiveCertInfo:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] == 2);

	/* CERTINFO is not a standard command for Textual to
	 receive which means we should be strict about what
	 conditions we will accept it under. */
	if (self.zncBoucnerIsSendingCertificateInfo == NO ||
		m.senderIsServer == NO ||
		NSObjectsAreEqual(m.senderNickname, @"znc.in") == NO)
	{
		return;
	}

	/* The data we expect to receive should be chunk split 
	 which means it is safe to assume a maximum length. */
	NSString *data = m.sequence;

	if (data.length < 2 || data.length > 65) {
		return;
	}

	/* Write line to the mutable buffer */
	if ( self.zncBouncerCertificateChainDataMutable) {
		[self.zncBouncerCertificateChainDataMutable appendFormat:@"%@\n", data];
	}
}

/* Signed */
- (void)receiveBatch:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] >= 1);

	NSString *batchToken = [m paramAt:0];

	if (batchToken.length <= 1) {
		LogToConsoleError("Cannot process BATCH command because [batchToken length] <= 1")

		return;
	}

	NSString *batchType = [m paramAt:1];

	BOOL isBatchOpening = NO;

	if ([batchToken hasPrefix:@"+"]) {
		 batchToken = [batchToken substringFromIndex:1];

		isBatchOpening = YES;
	} else if ([batchToken hasPrefix:@"-"]) {
		batchToken = [batchToken substringFromIndex:1];

		isBatchOpening = NO;
	} else {
		LogToConsoleError("Cannot process BATCH command because there was no open or close modifier")

		return;
	}

	if (batchToken.length < 4 && [batchToken onlyContainsCharacters:CS_AtoZUnderscoreDashCharacters] == NO) {
		LogToConsoleError("Cannot process BATCH command because the batch token contains illegal characters")

		return;
	}

	if (isBatchOpening == NO)
	{
		/* Find batch message matching known token */
		IRCMessageBatchMessage *thisBatchMessage = [self.batchMessages queuedEntryWithBatchToken:batchToken];

		if (thisBatchMessage == nil) {
			LogToConsoleError("Cannot process BATCH command because -queuedEntryWithBatchToken: returned nil")

			return;
		}

		thisBatchMessage.batchIsOpen = NO;

		/* If this batch message has a parent batch, then we 
		 do not remove this batch or process it until the close
		 statement for the parent is received. */
		if (thisBatchMessage.parentBatchMessage) {
			return; // Nothing left to do...
		}

		batchType = thisBatchMessage.batchType;

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
		/* Check batch= value to look for possible parent batch.*/
		IRCMessageBatchMessage *parentBatchMessage = nil;

		NSString *parentBatchMessageToken = m.batchToken;

		if (parentBatchMessageToken) {
			parentBatchMessage = [self.batchMessages queuedEntryWithBatchToken:parentBatchMessageToken];
		}

		/* Create new batch message and queue it. */
		IRCMessageBatchMessage *newBatchMessage = [IRCMessageBatchMessage new];

		[newBatchMessage setBatchIsOpen:YES];

		newBatchMessage.batchToken = batchToken;
		newBatchMessage.batchType = batchType;

		newBatchMessage.parentBatchMessage = parentBatchMessage;

		[self.batchMessages queueEntry:newBatchMessage];

		/* Set vendor specific flags based on BATCH command values */
		if (NSObjectsAreEqual(batchType, @"znc.in/playback")) {
			self.zncBouncerIsPlayingBackHistory = self.isConnectedToZNC;
		} else if (NSObjectsAreEqual(batchType, @"znc.in/tlsinfo")) {
			self.zncBoucnerIsSendingCertificateInfo = self.isConnectedToZNC;

			/* If this is parent batch (there is no @batch=), then we
			 reset the mutable object to read new data. */
			if (parentBatchMessageToken == nil) {
				self.zncBouncerCertificateChainDataMutable = [NSMutableString string];
			}
		}
	}
}

#pragma mark -
#pragma mark BATCH Command (Signed)

/* Signed */
- (BOOL)filterBatchCommandIncomingData:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSString *batchToken = m.batchToken;

	if (batchToken) {
		IRCMessageBatchMessage *thisBatchMessage = [self.batchMessages queuedEntryWithBatchToken:batchToken];

		if (thisBatchMessage.batchIsOpen) {
			[thisBatchMessage queueEntry:m];

			return YES;
		}
	}

	return NO;
}

/* Signed */
- (void)recursivelyProcessBatchMessage:(IRCMessageBatchMessage *)batchMessage
{
	[self recursivelyProcessBatchMessage:batchMessage depth:0];
}

/* Signed */
- (void)recursivelyProcessBatchMessage:(IRCMessageBatchMessage *)batchMessage depth:(NSInteger)recursionDepth
{
	NSParameterAssert(batchMessage != nil);

	if (batchMessage.batchIsOpen) {
		return;
	}

	NSArray *queuedEntries = batchMessage.queuedEntries;

	for (id queuedEntry in queuedEntries) {
		if ([queuedEntry isKindOfClass:[IRCMessage class]]) {
			[self processIncomingMessage:queuedEntry];
		} else if ([queuedEntry isKindOfClass:[IRCMessageBatchMessage class]]) {
			[self recursivelyProcessBatchMessage:queuedEntry depth:(recursionDepth + 1)];
		}
	}

	if (recursionDepth == 0) {
		[self.batchMessages dequeueEntry:batchMessage];
	}
}

#pragma mark -
#pragma mark Server Capacity (Signed)

/* Signed */
- (void)enableCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	if ([self isCapacityEnabled:capacity] == NO) {
		self->_capacities |= capacity;
	}
}

/* Signed */
- (void)disableCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	if ([self isCapacityEnabled:capacity]) {
		self->_capacities &= ~capacity;
	}
}

/* Signed */
- (BOOL)isCapacityEnabled:(ClientIRCv3SupportedCapacities)capacity
{
	return ((self->_capacities & capacity) == capacity);
}

/* Signed */
- (void)enablePendingCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	@synchronized (self.capacitiesPending) {
		[self.capacitiesPending addObjectWithoutDuplication:@(capacity)];
	}
}

/* Signed */
- (void)disablePendingCapacity:(ClientIRCv3SupportedCapacities)capacity
{
	@synchronized (self.capacitiesPending) {
		[self.capacitiesPending removeObject:@(capacity)];
	}
}

/* Signed */
- (BOOL)isPendingCapacityEnabled:(ClientIRCv3SupportedCapacities)capacity
{
	@synchronized (self.capacitiesPending) {
		return [self.capacitiesPending containsObject:@(capacity)];
	}
}

/* Signed */
- (nullable NSString *)capacityStringValue:(ClientIRCv3SupportedCapacities)capacity
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

/* Signed */
- (ClientIRCv3SupportedCapacities)capacityFromStringValue:(NSString *)capacityString
{
	NSParameterAssert(capacityString != nil);

	if ([capacityString isEqualIgnoringCase:@"userhost-in-names"]) {
		return ClientIRCv3SupportedCapacityUserhostInNames;
	} else if ([capacityString isEqualIgnoringCase:@"multi-prefix"]) {
		return ClientIRCv3SupportedCapacityMultiPreifx;
	} else if ([capacityString isEqualIgnoringCase:@"identify-msg"]) {
		return ClientIRCv3SupportedCapacityIdentifyMsg;
	} else if ([capacityString isEqualIgnoringCase:@"identify-ctcp"]) {
		return ClientIRCv3SupportedCapacityIdentifyCTCP;
	} else if ([capacityString isEqualIgnoringCase:@"away-notify"]) {
		return ClientIRCv3SupportedCapacityAwayNotify;
	} else if ([capacityString isEqualIgnoringCase:@"batch"]) {
		return ClientIRCv3SupportedCapacityBatch;
	} else if ([capacityString isEqualIgnoringCase:@"server-time"]) {
		return ClientIRCv3SupportedCapacityServerTime;
	} else if ([capacityString isEqualIgnoringCase:@"znc.in/self-message"]) {
		return ClientIRCv3SupportedCapacityZNCSelfMessage;
	} else if ([capacityString isEqualIgnoringCase:@"znc.in/server-time"]) {
		return ClientIRCv3SupportedCapacityZNCServerTime;
	} else if ([capacityString isEqualIgnoringCase:@"znc.in/server-time-iso"]) {
		return ClientIRCv3SupportedCapacityZNCServerTimeISO;
	} else if ([capacityString isEqualIgnoringCase:@"znc.in/tlsinfo"]) {
		return ClientIRCv3SupportedCapacityZNCCertInfoModule;
	} else if ([capacityString isEqualIgnoringCase:@"znc.in/playback"]) {
		return ClientIRCv3SupportedCapacityZNCPlaybackModule;
	} else if ([capacityString isEqualIgnoringCase:@"sasl"]) {
		return ClientIRCv3SupportedCapacitySASLGeneric;
	}

	return 0;
}

/* Signed */
- (NSString *)enabledCapacitiesStringValue
{
	NSMutableArray *enabledCapacities = [NSMutableArray array];
	
	void (^appendValue)(ClientIRCv3SupportedCapacities) = ^(ClientIRCv3SupportedCapacities capacity) {
		if ([self isCapacityEnabled:capacity] == NO) {
			return;
		}

		NSString *stringValue = [self capacityStringValue:capacity];
			
		if (stringValue) {
			[enabledCapacities addObject:stringValue];
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
	
	NSString *stringValue = [enabledCapacities componentsJoinedByString:@", "];
	
	return stringValue;
}

/* Signed */
- (void)sendNextCapacity
{
	if (self.capacityNegotiationIsPaused) {
		return;
	}

	@synchronized (self.capacitiesPending) {
		/* -capacitiesPending can contain values that are used internally for state traking 
		 and should never meet the socket. To workaround this as best we can, we scan the 
		 array for the first capacity that is acceptable for negotation. */
		NSUInteger nextCapacityIndex =
		[self.capacitiesPending indexOfObjectPassingTest:^BOOL(NSNumber *capacityPending, NSUInteger index, BOOL *stop) {
			ClientIRCv3SupportedCapacities capacity = capacityPending.unsignedIntegerValue;

			return
			(capacity == ClientIRCv3SupportedCapacitySASLGeneric			||
			 capacity == ClientIRCv3SupportedCapacityAwayNotify				||
			 capacity == ClientIRCv3SupportedCapacityBatch					||
			 capacity == ClientIRCv3SupportedCapacityIdentifyCTCP			||
			 capacity == ClientIRCv3SupportedCapacityIdentifyMsg			||
			 capacity == ClientIRCv3SupportedCapacityMultiPreifx			||
			 capacity == ClientIRCv3SupportedCapacityServerTime				||
			 capacity == ClientIRCv3SupportedCapacityUserhostInNames		||
			 capacity == ClientIRCv3SupportedCapacityZNCCertInfoModule		||
			 capacity == ClientIRCv3SupportedCapacityZNCPlaybackModule		||
			 capacity == ClientIRCv3SupportedCapacityZNCServerTime			||
			 capacity == ClientIRCv3SupportedCapacityZNCServerTimeISO		||
			 capacity == ClientIRCv3SupportedCapacityZNCSelfMessage);
		}];

		if (nextCapacityIndex == NSNotFound) {
			[self sendCapacity:@"END" data:nil];

			return;
		}

		ClientIRCv3SupportedCapacities capacity =
		[self.capacitiesPending unsignedIntegerAtIndex:nextCapacityIndex];

		[self.capacitiesPending removeObjectAtIndex:nextCapacityIndex];

		NSString *stringValue = [self capacityStringValue:capacity];

		[self sendCapacity:@"REQ" data:stringValue];
	}
}

/* Signed */
- (void)pauseCapacityNegotation
{
	self.capacityNegotiationIsPaused = YES;
}

/* Signed */
- (void)resumeCapacityNegotation
{
	self.capacityNegotiationIsPaused = NO;

	[self sendNextCapacity];
}

/* Signed */
- (BOOL)isCapacitySupported:(NSString *)capacityString
{
	NSParameterAssert(capacityString != nil);

	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org

	return
	([capacityString isEqualIgnoringCase:@"sasl"]					||
	 [capacityString isEqualIgnoringCase:@"identify-msg"]			||
	 [capacityString isEqualIgnoringCase:@"identify-ctcp"]			||
	 [capacityString isEqualIgnoringCase:@"away-notify"]			||
	 [capacityString isEqualIgnoringCase:@"batch"]					||
	 [capacityString isEqualIgnoringCase:@"multi-prefix"]			||
	 [capacityString isEqualIgnoringCase:@"userhost-in-names"]		||
	 [capacityString isEqualIgnoringCase:@"server-time"]			||
	 [capacityString isEqualIgnoringCase:@"znc.in/self-message"]	||
	 [capacityString isEqualIgnoringCase:@"znc.in/tlsinfo"]			||
	 [capacityString isEqualIgnoringCase:@"znc.in/playback"]		||
	 [capacityString isEqualIgnoringCase:@"znc.in/server-time"]		||
	 [capacityString isEqualIgnoringCase:@"znc.in/server-time-iso"]);
}

/* Signed */
- (void)toggleCapacity:(NSString *)capacityString enabled:(BOOL)enabled
{
	[self toggleCapacity:capacityString enabled:enabled isUpdateRequest:NO];
}

/* Signed */
- (void)toggleCapacity:(NSString *)capacityString enabled:(BOOL)enabled isUpdateRequest:(BOOL)isUpdateRequest
{
	NSParameterAssert(capacityString != nil);

	if ([capacityString isEqualIgnoringCase:@"sasl"]) {
		if (enabled) {
			if ([self sendSASLIdentificationRequest]) {
				[self pauseCapacityNegotation];
			}
		}

		return;
	}

	ClientIRCv3SupportedCapacities capacity = [self capacityFromStringValue:capacityString];
	
	if (capacity == 0) {
		return;
	}

	if (capacity == ClientIRCv3SupportedCapacityZNCServerTime ||
		capacity == ClientIRCv3SupportedCapacityZNCServerTimeISO)
	{
		capacity = ClientIRCv3SupportedCapacityServerTime;
	}

	if (enabled) {
		[self enableCapacity:capacity];
	} else {
		[self disableCapacity:capacity];
	}
}

/* Signed */
- (void)processPendingCapacity:(NSString *)capacityString
{
	NSParameterAssert(capacityString != nil);

	NSArray *components = [capacityString componentsSeparatedByString:@"="];

	NSString *capacity = capacityString;

	NSArray<NSString *> *capacityOptions = nil;

	if (components.count == 2) {
		capacity = components[0];

		capacityOptions = [components[1] componentsSeparatedByString:@","];
	}

	[self processPendingCapacity:capacity options:capacityOptions];
}

/* Signed */
- (void)processPendingCapacity:(NSString *)capacityString options:(nullable NSArray<NSString *> *)capacityOpions
{
	NSParameterAssert(capacityString != nil);

	if ([self isCapacitySupported:capacityString] == NO) {
		return;
	}

	if ([capacityString isEqualToString:@"sasl"]) {
		[self processPendingCapacityForSASL:capacityOpions];

		return;
	}

	ClientIRCv3SupportedCapacities capacity = [self capacityFromStringValue:capacityString];

	[self enablePendingCapacity:capacity];
}

/* Signed */
- (void)receiveCapacityOrAuthenticationRequest:(IRCMessage *)m
{
	/* Implementation based off Colloquy's own. */
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	NSString *command = m.command;
	NSString *modifier = [m paramAt:0];
	NSString *subcommand = [m paramAt:1];
	NSString *actions = [m sequence:2];

	if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap")])
	{
		if ([subcommand isEqualIgnoringCase:@"LS"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self processPendingCapacity:cap];
			}
		} else if ([subcommand isEqualIgnoringCase:@"ACK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapacity:cap enabled:YES isUpdateRequest:NO];
			}
		} else if ([subcommand isEqualIgnoringCase:@"NAK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapacity:cap enabled:NO isUpdateRequest:NO];
			}
		} else if ([subcommand isEqualIgnoringCase:@"NEW"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapacity:cap enabled:YES isUpdateRequest:YES];
			}
		} else if ([subcommand isEqualIgnoringCase:@"DEL"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapacity:cap enabled:NO isUpdateRequest:YES];
			}
		}

		[self sendNextCapacity];
	}
	else if ([command isEqualIgnoringCase:IRCPrivateCommandIndex("cap_authenticate")])
	{
		if ([modifier isEqualToString:@"+"]) {
			[self sendSASLIdentificationInformation];
		}
	}

	(void)[self postReceivedMessage:m];
}

#pragma mark -
#pragma mark SASL Negotation (Signed)

/* Signed */
- (void)processPendingCapacityForSASL:(nullable NSArray<NSString *> *)capacityOptions
{
	ClientIRCv3SupportedCapacities identificationMechanism = 0;

	if (capacityOptions.count == 0) {
		if (self.config.saslAuthenticationUsesExternalMechanism) {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLExternal;
		} else {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText;
		}
	} else if ([capacityOptions containsObjectIgnoringCase:@"EXTERNAL"]) {
		identificationMechanism = ClientIRCv3SupportedCapacitySASLExternal;
	} else if ([capacityOptions containsObjectIgnoringCase:@"PLAIN"]) {
		identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText;
	}

	/* Test whether external authentication is even possible (did we connect
	 using a client side certificate?) — If it's not possible, then fall back
	 to using plain text authentication. */
	if (identificationMechanism == ClientIRCv3SupportedCapacitySASLExternal) {
		if (self.socket.isConnectedWithClientSideCertificate == NO) {
			identificationMechanism = ClientIRCv3SupportedCapacitySASLPlainText;
		} else {
			[self enablePendingCapacity:ClientIRCv3SupportedCapacitySASLExternal];
		}
	}

	/* If a password is not configured, then disable any type of authentication */
	if (identificationMechanism == ClientIRCv3SupportedCapacitySASLPlainText) {
		if (self.config.nicknamePassword.length == 0) {
			identificationMechanism = 0;
		} else {
			[self enablePendingCapacity:ClientIRCv3SupportedCapacitySASLPlainText];
		}
	}

	if (identificationMechanism != 0) {
		[self enablePendingCapacity:ClientIRCv3SupportedCapacitySASLGeneric];
	}
}

/* Signed */
- (void)sendSASLIdentificationInformation
{
	if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacityIsInSASLNegotiation] == NO) {
		return;
	}

	if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacitySASLPlainText])
	{
		NSString *authString = [NSString stringWithFormat:@"%@%C%@%C%@",
								 self.config.username, 0x00,
								 self.config.username, 0x00,
								 self.config.nicknamePassword];

		NSArray *authStrings = [authString base64EncodingWithLineLength:400];

		for (NSString *string in authStrings) {
			[self sendCapacityAuthenticate:string];
		}

		if (authStrings.count == 0 || ((NSString *)authStrings.lastObject).length == 400) {
			[self sendCapacityAuthenticate:@"+"];
		}
	}
	else if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacitySASLExternal])
	{
		[self sendCapacityAuthenticate:@"+"];
	}
}

/* Signed */
- (BOOL)sendSASLIdentificationRequest
{
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL]) {
		return NO;
	}

	if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacityIsInSASLNegotiation]) {
		return NO;
	}

	[self enablePendingCapacity:ClientIRCv3SupportedCapacityIsInSASLNegotiation];

	if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacitySASLPlainText]) {
		[self sendCapacityAuthenticate:@"PLAIN"];

		return YES;
	} else if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacitySASLExternal]) {
		[self sendCapacityAuthenticate:@"EXTERNAL"];

		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Protocol Handlers (Signed)

/* Signed */
- (void)receivePing:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	NSString *token = [m sequence:0];

	[self sendPong:token];

	(void)[self postReceivedMessage:m];
}

/* Signed */
- (void)receiveAwayNotifyCapacity:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify] == NO) {
		return;
	}

    BOOL userIsAway = NSObjectIsNotEmpty(m.sequence);

	NSString *nickname = m.senderNickname;

	for (IRCChannel *channel in self.channelList) {
		IRCUser *member = [channel findMember:nickname];

		if (member == nil) {
			continue;
		}

		if (userIsAway) {
			[member markAsAway];
		} else {
			[member markAsReturned];
		}
		
		[channel updateMemberOnTableView:member]; // Redraw
	}
}

- (void)receiveInit:(IRCMessage *)m // Raw numeric = 001
{
	NSParameterAssert(m != nil);

	/* Manage timers */
	[self startPongTimer];

	[self stopRetryTimer];

	/* Manage properties */
	self.isLoggedIn = YES;

	self.supportInfo.serverAddress = m.senderHostmask;

	self.invokingISONCommandForFirstTime = YES;

	self.reconnectEnabledBecauseOfSleepMode = NO;

	self.tryingNicknameSentNickname = nil;

	self.userNickname = [m paramAt:0];

	self.successfulConnects += 1;
	
	/* Post event */
	[self postEventToViewController:@"serverConnected"];

	[self notifyEvent:TXNotificationConnectType lineType:TVCLogLineDebugType];

	/* Perform login commands */
	for (__strong NSString *command in self.config.loginCommands) {
		if ([command hasPrefix:@"/"]) {
			command = [command substringFromIndex:1];
		}

		[self sendCommand:command completeTarget:NO target:nil];
	}

	/* Request certificate information */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCCertInfoModule]) {
		NSString *nickname = [self nicknameAsZNCUser:@"tlsinfo"];

		[self send:IRCPrivateCommandIndex("privmsg"), nickname, @"send-data", nil];
	}

	/* Request playback since the last seen message when previously connected */
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
		/* For our first connect, only playback using timestamp if logging was enabled. */
		/* For all other connects, then playback timestamp regardless of logging. */

		if ((self.successfulConnects > 1 || (self.successfulConnects == 1 && [TPCPreferences logToDiskIsEnabled])) && self.lastMessageServerTime > 0) {
			NSString *timeToSend = [NSString stringWithFormat:@"%.0f", self.lastMessageServerTime];

			[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameAsZNCUser:@"playback"], @"play", @"*", timeToSend, nil];
		} else {
			[self send:IRCPrivateCommandIndex("privmsg"), [self nicknameAsZNCUser:@"playback"], @"play", @"*", @"0", nil];
		}
	}

	/* Activate existing queries */
	for (IRCChannel *c in self.channelList) {
		if (c.privateMessage) {
			[c activate];

			[mainWindow() reloadTreeItem:c];
		}
	}

	[mainWindow() reloadTreeItem:self];

	[mainWindow() updateTitleFor:self];

	[mainWindowTextField() updateSegmentedController];

	/* Everything else */
	if (self.config.autojoinWaitsForNickServ == NO || [self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL]) {
		[self performAutoJoin];
	} else {
        /* If we wait for NickServ we set a timer of 3.0 seconds before performing auto join.
         When this timer is executed, if we do not have any knowledge of NickServ existing
         on the current server, then we perform the autojoin. This is primarly a fix for the
         ZNC SASL module which will complete identification before connecting and once connected
         Textual will have no knowledge of whether the local user is identified or not. */
		/* NickServ will send a notice asking for identification as soon as connection occurs so
         this is the best patch. At least for right now. */

		if (self.isConnectedToZNC) {
			[self performSelector:@selector(performAutoJoin) withObject:nil afterDelay:3.0];
		}
	}
	
	/* We need time for the server to send its configuration */
	[self performSelector:@selector(populateISONTrackedUsersList) withObject:nil afterDelay:10.0];
}

/* Signed */
- (void)receiveNumericReply:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSInteger numeric = m.commandNumeric;

	if (numeric > 400 && numeric < 600 && numeric != 403 && numeric != 422) {
		[self receiveErrorNumericReply:m];

		return;
	}

	BOOL printMessage = YES;

	if (numeric != 324 && numeric != 332) {
		printMessage = [self postReceivedMessage:m];
	}

	switch (numeric) {
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
			[self.supportInfo processConfigurationData:[m sequence:1]];

			if (printMessage) {
				NSString *configString = self.supportInfo.stringValueForLastUpdate;

				[self printDebugInformationToConsole:configString asCommand:m.command];
			}

			break;
		}
		case 10: // RPL_REDIR
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *serverAddress = [m paramAt:0];
			NSString *serverPort = [m paramAt:1];

			self.disconnectType = IRCClientDisconnectServerRedirectMode;

			/* If the address is thought to be invalid, then we still
			 perform the disconnect suggested by the redirect, but
			 we do not go any further than that. */
			if (serverAddress.validInternetAddress == NO ||
				serverPort.validInternetPort == NO)
			{
				[self disconnect];

				return;
			}

			/* Perform reconnect to specified locations */
			__weak IRCClient *weakSelf = self;

			self.disconnectCallback = ^{
				[weakSelf connect];
			};

			[self disconnect];

			/* -disconnect would destroy this so we set them after... */
			self.temporaryServerAddressOverride = serverAddress;
			self.temporaryServerPortOverride = serverPort.integerValue;
			
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

            NSString *message = nil;

            if (m.paramsCount == 4) {
                /* Removes user count from in front of messages on IRCds that send them.
                 Example: ">> :irc.example.com 265 Guest 2 3 :Current local users 2, max 3" */
                
                message = [m sequence:3];
			} else {
				message = m.sequence;
			}

			[self print:message
					 by:nil
			  inChannel:nil
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
        }
		case 372: // RPL_MOTD
		case 375: // RPL_MOTDSTART
		case 376: // RPL_ENDOFMOTD
		case 422: // ERR_NOMOTD
		{
			NSAssertReturn(printMessage);

			if ([TPCPreferences displayServerMOTD] == NO) {
				break;
			}

			if (numeric == 422) {
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
			
			NSString *modeString = [m paramAt:1];

			if ([modeString isEqualToString:@"+"]) {
				break;
			}

			[self print:TXTLS(@"IRC[1072]", self.userNickname, modeString)
					 by:nil
			  inChannel:nil
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

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

			NSString *awayNickname = [m paramAt:1];
			NSString *awayComment = [m paramAt:2];

			IRCChannel *channel = [self findChannel:awayNickname];

			NSString *message = TXTLS(@"IRC[1075]", awayNickname, awayComment);

            if (channel == nil) {
				channel = [mainWindow() selectedChannelOn:self];
			} else {
				IRCUser *member = [channel findMember:awayNickname];

				if ( member) {
					[member markAsAway];

					if (member.presentAwayMessageFor301 == NO) {
						break;
					}
				}
			}

			if (printMessage) {
				[self print:message
						 by:nil
				  inChannel:channel
					 asType:TVCLogLineDebugType
					command:m.command
				 receivedAt:m.receivedAt];
			}

			break;
		}
		case 305: // RPL_UNAWAY
		case 306: // RPL_NOWAWAY
		{
			self.userIsAway = (numeric == 306);

			if (printMessage) {
				[self printUnknownReply:m];
			}

            /* Update our own status. This has to only be done with away-notify CAP enabled.
             Old, WHO based information requests will still show our own status. */
			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify] == NO) {
				break;
			}

			NSString *localNickname = self.userNickname;

			for (IRCChannel *channel in self.channelList) {
				IRCUser *myself = [channel findMember:localNickname];
				
				if (myself == nil) {
					continue;
				}

				if (numeric == 306) {
					[myself markAsAway];
				} else {
					[myself markAsReturned];
				}
				
				[channel updateMemberOnTableView:myself];
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

			NSString *message = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 338: // RPL_WHOISACTUALLY (ircu, Bahamut)
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);

			NSString *message = nil;
			
			if (m.paramsCount == 3) {
				message = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m paramAt:2]];
			} else {
				/* I am not sure in what context this variant is used. It is legacy code from 
				 earlier versions of Textual so it is better to keep it here. */
				message = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];
			}

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 311: // RPL_WHOISUSER
		case 314: // RPL_WHOWASUSER
		{
			NSAssertReturn([m paramsCount] >= 6);

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];
			NSString *realName = [m paramAt:5];

			if ([realName hasPrefix:@":"]) {
				realName = [realName substringFromIndex:1];
			}

			if (numeric == 314) {
				[self enableInUserInvokedCommandProperty:&self->_inUserInvokedWhowasRequest];
			}

			NSString *message = nil;

			if (self.inUserInvokedWhowasRequest) {
				if (printMessage) {
					message = TXTLS(@"IRC[1086]", nickname, username, address, realName);
				}
			} else {
				/* Update local cache of our hostmask */
				if ([self nicknameIsMyself:nickname]) {
					NSString *hostmask = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, address];

					self.userHostmask = hostmask;
				}

				/* Continue normal WHOIS event */
				if (printMessage) {
					message = TXTLS(@"IRC[1083]", nickname, username, address, realName);
				}
			}

			if (message) {
				[self print:message
						 by:nil
				  inChannel:[mainWindow() selectedChannelOn:self]
					 asType:TVCLogLineDebugType
					command:m.command
				 receivedAt:m.receivedAt];
			}

			break;
		}
		case 312: // RPL_WHOISSERVER
		{
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *serverAddress = [m paramAt:2];
			NSString *serverInfo = [m paramAt:3];

			NSString *message = nil;

			if (self.inUserInvokedWhowasRequest) {
				NSString *timeInfo = TXFormatDateTimeStringToCommonFormat(serverInfo, YES);
				
				message = TXTLS(@"IRC[1085]", nickname, serverAddress, timeInfo);
			} else {
				message = TXTLS(@"IRC[1082]", nickname, serverAddress, serverInfo);
			}

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 317: // RPL_WHOISIDLE
		{
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *idleTime = [m paramAt:2];
			NSString *connectTime = [m paramAt:3];

			idleTime = TXHumanReadableTimeInterval(idleTime.doubleValue, NO, 0);

			NSDate *connTimeDate = [NSDate dateWithTimeIntervalSince1970:connectTime.doubleValue];

			connectTime = TXFormatDateTimeStringToCommonFormat(connTimeDate, NO);

			NSString *message = TXTLS(@"IRC[1084]", nickname, connectTime, idleTime);

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 319: // RPL_WHOISCHANNELS
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);

			NSString *nickname = [m paramAt:1];
			NSString *channels = [m paramAt:2];

			NSString *message = TXTLS(@"IRC[1081]", nickname, channels);

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 324: // RPL_CHANNELMODES
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *channelName = [m paramAt:1];
			NSString *modeString = [m sequence:2];

			if ([modeString isEqualToString:@"+"]) {
				return;
			}

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			if (channel.isActive) {
				[channel.modeInfo clear];

				[channel.modeInfo updateModes:modeString];
			}

			/* Do not check after if statement so that filters can interact with
			 input regardless of whether the value was manually invoked. */
			printMessage = [self postReceivedMessage:m withText:modeString destinedFor:channel];

			if (self.inUserInvokedModeRequest == NO && channel.inUserInvokedModeRequest == NO) {
				break;
			}

			if (printMessage) {
				NSString *message = channel.modeInfo.stringWithMaskedPassword;

				[self print:TXTLS(@"IRC[1039]", message)
						 by:nil
				  inChannel:channel
					 asType:TVCLogLineModeType
					command:m.command
				 receivedAt:m.receivedAt];
			}

			if (channel.inUserInvokedModeRequest) {
				channel.inUserInvokedModeRequest = NO;

				break;
			}

			[self disableInUserInvokedCommandProperty:&self->_inUserInvokedModeRequest];
			
			break;
		}
		case 332: // RPL_TOPIC
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *channelName = [m paramAt:1];
			NSString *topic = [m paramAt:2];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			printMessage = [self postReceivedMessage:m withText:topic destinedFor:channel];

			channel.topic = topic;

			if (printMessage) {
				[self print:TXTLS(@"IRC[1040]", topic)
						 by:nil
				  inChannel:channel
					 asType:TVCLogLineTopicType
					command:m.command
				 receivedAt:m.receivedAt];
			}

			break;
		}
		case 333: // RPL_TOPICWHOTIME
		{
			NSAssertReturn([m paramsCount] > 3);

			NSAssertReturn(printMessage);

			NSString *channelName = [m paramAt:1];
			NSString *topicSetter = [m paramAt:2];
			NSString *setTime = [m paramAt:3];

			topicSetter = topicSetter.nicknameFromHostmask;

			NSDate *settimeDate = [NSDate dateWithTimeIntervalSince1970:setTime.doubleValue];

			setTime = TXFormatDateTimeStringToCommonFormat(settimeDate, NO);

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			NSString *message = TXTLS(@"IRC[1041]", topicSetter, setTime);

			[self print:message
					 by:nil
			  inChannel:channel
				 asType:TVCLogLineTopicType
				command:m.command
			 receivedAt:m.receivedAt];
			
			break;
		}
		case 341: // RPL_INVITING
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
			NSString *nickname = [m paramAt:1];
			NSString *channelName = [m paramAt:2];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			[self print:TXTLS(@"IRC[1073]", nickname, channelName)
					 by:nil
			  inChannel:channel
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];
			
			break;
		}
		case 303: // RPL_ISON
		{
			/* If the user requested ISON records, then present the
			 result to the user but do no further processing. */
			if (self.inUserInvokedIsonRequest) {
				if (printMessage) {
					[self printErrorReply:m];
				}

				[self disableInUserInvokedCommandProperty:&self->_inUserInvokedIsonRequest];

				break;
			}

			/* If the ISON records were not requested by the user, then
			 treat the results as user tracking information. */
			NSString *onlineNicknamesString = m.sequence;
			
			NSArray *onlineNicknames = [onlineNicknamesString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			/* Start going over the list of tracked nicknames */
			@synchronized(self.trackedNicknames) {
				NSArray *trackedNicknames = self.trackedNicknames.allKeys;
				
				for (NSString *trackedNickname in trackedNicknames) {
					NSString *trackedNicknameLowercase = trackedNickname.lowercaseString;

					IRCAddressBookUserTrackingStatus trackingStatus =
					IRCAddressBookUserTrackingUnknownStatus;
					
					/* Was the user on during the last check? */
					BOOL ison = [self.trackedNicknames[trackedNicknameLowercase] boolValue];
					
					if (ison) {
						/* If the user was on before, but is not in the list of ISON
						 users in this reply, then they are considered gone. Log that. */
						if ([onlineNicknames containsObjectIgnoringCase:trackedNickname] == NO) {
							if (self.invokingISONCommandForFirstTime == NO) {
								trackingStatus = IRCAddressBookUserTrackingSignedOffStatus;
							}

							self.trackedNicknames[trackedNicknameLowercase] = @(NO);
						}
					} else {
						/* If they were not on but now are, then log that too. */
						if ([onlineNicknames containsObjectIgnoringCase:trackedNickname]) {
							if (self.invokingISONCommandForFirstTime) {
								trackingStatus = IRCAddressBookUserTrackingIsAvailalbeStatus;
							} else {
								trackingStatus = IRCAddressBookUserTrackingSignedOnStatus;
							}

							self.trackedNicknames[trackedNicknameLowercase] = @(YES);
						}
					}

					/* If something changed (non-nil localization string), then scan 
					 the list of address book entries to report the result. */
					[self notifyTrackingStatusOfNickname:trackedNickname changedTo:trackingStatus];
				} // for
			} // @synchronized

			if (self.invokingISONCommandForFirstTime) { // Reset internal property
				self.invokingISONCommandForFirstTime = NO;
			}

			/* Update private messages */
			for (IRCChannel *channel in self.channelList) {
				if (channel.privateMessage == NO) {
					continue;
				}

				if (channel.isActive) {
					/* If the user is no longer on, deactivate the private message */
					if ([onlineNicknames containsObjectIgnoringCase:channel.name] == NO) {
						[channel deactivate];

						[mainWindow() reloadTreeItem:channel];
					}
				} else {
					/* Activate the private message if the user is back online */
					if ([onlineNicknames containsObjectIgnoringCase:channel.name]) {
						[channel activate];

						[mainWindow() reloadTreeItem:channel];
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

				[self disableInUserInvokedCommandProperty:&self->_inUserInvokedWhoRequest];
			}

			break;
		}
		case 352: // RPL_WHOREPLY
		{
			NSAssertReturn([m paramsCount] > 6);

			BOOL inUserInvokedWhoRequest = self.inUserInvokedWhoRequest;

			if (inUserInvokedWhoRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}
			}

			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}
					
			/* Example incoming data:
				<channel> <user> <host> <server> <nick> <H|G>[*][@|+] <hopcount> <real name>
			 
				#freenode znc unaffiliated/namikaze kornbluth.freenode.net Namikaze G 0 Christian
				#freenode ~D unaffiliated/solprefixer kornbluth.freenode.net solprefixer H 0 solprefixer
			*/
			
			NSString *nickname = [m paramAt:5];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];
			NSString *flags = [m paramAt:6];
			NSString *realName = [m paramAt:7];

			BOOL isAway = NO;
            BOOL isIRCop = NO;

			// Field Syntax: <H|G>[*][@|+]
			// Strip G or H (away status).
			if (inUserInvokedWhoRequest == NO) {
				if ([flags hasPrefix:@"G"]) {
					if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify] ||
						[TPCPreferences trackUserAwayStatusMaximumChannelSize] > 0)
					{
						isAway = YES;
					}
				}
			}

			flags = [flags substringFromIndex:1];

			if ([flags contains:@"*"]) {
				flags = [flags substringFromIndex:1];

                isIRCop = YES;
			}

			IRCUser *member = [channel findMember:nickname];

			IRCUserMutable *memberMutable = nil;

			if (member == nil) {
				memberMutable = [[IRCUserMutable alloc] initWithNickname:nickname onClient:self];
			} else {
				memberMutable = [member mutableCopy];
			}
			
			memberMutable.username = username;
			memberMutable.address = address;

			memberMutable.isAway = isAway;
			memberMutable.isCop = isIRCop;

			/* Paramater 7 includes the hop count and real name because it begins with a :
			 Therefore, we cut after the first space to get the real, real name value. */
			NSInteger realNameFirstSpace = [realName stringPosition:NSStringWhitespacePlaceholder];

			if (realNameFirstSpace > 0 && realNameFirstSpace < realName.length) {
				realName = [realName substringAfterIndex:realNameFirstSpace];
			}

			memberMutable.realName = realName;

			/* Update user modes */
			NSMutableString *userModes = [NSMutableString string];

			for (NSUInteger i = 0; i < flags.length; i++) {
				NSString *prefix = [flags stringCharacterAtIndex:i];

				NSString *modeSymbol = [self.supportInfo modeSymbolForUserPrefix:prefix];

				if (modeSymbol == nil) {
					break;
				}

				[userModes appendString:modeSymbol];
			}

			if (userModes.length > 0) {
				memberMutable.modes = userModes;
			}

			/* Write out changed user to channel */
			if (member == nil) {
				[channel addMember:memberMutable];
			} else {
				[channel replaceMember:member withMember:memberMutable];
			}

			/* Update local cache of our hostmask */
			if ([self nicknameIsMyself:nickname]) {
				NSString *hostmask = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, address];

				self.userHostmask = hostmask;
			}

			break;
		}
		case 353: // RPL_NAMEREPLY
		{
			NSAssertReturn([m paramsCount] > 3);
			
			if (self.inUserInvokedNamesRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}

				/* Do not process input if user invokes command */
				break;
			}

			NSString *channelName = [m paramAt:2];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			NSString *nicknamesString = [m paramAt:3];

			NSArray *nicknames = [nicknamesString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *nickname in nicknames) {
				if (nickname.length == 0) {
					continue;
				}

				/* Find first character that is not a user mode */
				NSMutableString *memberModes = [NSMutableString string];

				NSUInteger characterIndex = 0;

				for (characterIndex = 0; characterIndex < nickname.length; characterIndex++) {
					NSString *prefix = [nickname stringCharacterAtIndex:characterIndex];

					NSString *modeSymbol = [self.supportInfo modeSymbolForUserPrefix:prefix];

					if (modeSymbol == nil) {
						break;
					}

					[memberModes appendString:modeSymbol];
				} // for

				/* Split away hostmask if available */
				NSString *newNickname = [nickname substringFromIndex:characterIndex];

				NSString *nicknameInt = nil;
				NSString *usernameInt = nil;
				NSString *addressInt = nil;

				if ([newNickname hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt onClient:self] == NO) {
					/* When NAMES reply is not a host, then set the nicknameInt
					 to the value of nickname and leave the rest as nil. */

					nicknameInt = newNickname;
				}

				IRCUserMutable *memberMutable = [[IRCUserMutable alloc] initWithClient:self];

				memberMutable.modes = memberModes;

				memberMutable.nickname = nicknameInt;
				memberMutable.username = usernameInt;
				memberMutable.address = addressInt;

				/* We already inserted ourselves when we joined. */
				if ([self nicknameIsMyself:nicknameInt]) {
					[channel removeMemberWithNickname:nicknameInt];
				}
				
				/* Populate user list */
				[channel addMember:memberMutable];
			} // for

			break;
		}
		case 366: // RPL_ENDOFNAMES
		{
			NSAssertReturn([m paramsCount] > 1);
			
			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}
			
			if (self.inUserInvokedNamesRequest == NO && self.isBrokenIRCd_aka_Twitch == NO) {
				if (channel.numberOfMembers == 1) {
					NSString *defaultModes = channel.config.defaultModes;

					if (defaultModes.length > 0) {
						[self sendModes:defaultModes withParamatersString:nil inChannel:channel];
					}

					NSString *defaultTopic = channel.config.defaultTopic;

					if (defaultTopic.length > 0) {
						[self sendTopicTo:defaultTopic inChannel:channel];
					}
				}
			}

			[self disableInUserInvokedCommandProperty:&self->_inUserInvokedNamesRequest];
            
            [mainWindow() updateTitleFor:channel];

			break;
		}
		case 320: // RPL_WHOISSPECIAL
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
			NSString *message = [NSString stringWithFormat:@"%@ %@", [m paramAt:1], [m sequence:2]];

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 321: // RPL_LISTSTART
		{
            TDCServerChannelListDialog *channelListDialog = [self channelListDialog];

			if (channelListDialog) {
				channelListDialog.contentAlreadyReceived = NO;

				[channelListDialog clear];
			}

			break;
		}
		case 322: // RPL_LIST
		{
			NSAssertReturn([m paramsCount] > 2);
			
			NSString *channel = [m paramAt:1];
			NSString *userCount = [m paramAt:2];
			NSString *topic = [m sequence:3];

            TDCServerChannelListDialog *channelListDialog = [self channelListDialog];

			if (channelListDialog) {
				[channelListDialog addChannel:channel count:userCount.integerValue topic:topic];
			}

			break;
		}
		case 323: // RPL_LISTEND
		{
			TDCServerChannelListDialog *channelListDialog = [self channelListDialog];
			
			if (channelListDialog) {
				channelListDialog.contentAlreadyReceived = YES;
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

			NSString *message = [NSString stringWithFormat:@"%@ %@ %@", [m paramAt:1], [m sequence:3], [m paramAt:2]];

			[self print:message
					 by:nil
			  inChannel:[mainWindow() selectedChannelOn:self]
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 367: // RPL_BANLIST
		case 346: // RPL_INVITELIST
		case 348: // RPL_EXCEPTLIST
		{
			NSAssertReturn([m paramsCount] > 2);

			NSString *channelName = [m paramAt:1];

			NSString *entryMask = [m paramAt:2];

			NSString *entryAuthor = nil;

			NSDate *entryCreationDate = nil;

			BOOL extendedLine = (m.paramsCount > 4);

			if (extendedLine) {
				entryAuthor = [m paramAt:3].nicknameFromHostmask;

				entryCreationDate = [NSDate dateWithTimeIntervalSince1970:[m paramAt:4].doubleValue];
			}

			TDCChannelBanListSheet *listSheet = [windowController() windowFromWindowList:@"TDCChannelBanListSheet"];

            if (listSheet) {
				if (listSheet.contentAlreadyReceived) {
					listSheet.contentAlreadyReceived = NO;

					[listSheet clear];
				}

				[listSheet addEntry:entryMask setBy:entryAuthor creationDate:entryCreationDate];

				return;
			}

			if (printMessage == NO) {
				return;
			}

			NSString *localization = nil;

			if (numeric == 367) { // RPL_BANLIST
				localization = @"1102";
			} else if (numeric == 346) { // RPL_INVITELIST
				localization = @"1103";
			} else if (numeric == 348) { // RPL_EXCEPTLIST
				localization = @"1104";
			}

			if (extendedLine) {
				localization = [NSString stringWithFormat:@"IRC[%@][1]", localization];
			} else {
				localization = [NSString stringWithFormat:@"IRC[%@][2]", localization];
			}

			NSString *message = nil;

			if (extendedLine) {
				message = TXTLS(localization, channelName, entryMask, entryAuthor, entryCreationDate);
			} else {
				message = TXTLS(localization, channelName, entryMask);
			}

			[self print:message
					 by:nil
			  inChannel:nil
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 368: // RPL_ENDOFBANLIST
		case 347: // RPL_ENDOFINVITELIST
		case 349: // RPL_ENDOFEXCEPTLIST
		{
			TDCChannelBanListSheet *listSheet = [windowController() windowFromWindowList:@"TDCChannelBanListSheet"];

			if (listSheet) {
				listSheet.contentAlreadyReceived = YES;

				break;
			}

			if (printMessage) {
				[self printReply:m];
			}

			break;
		}
		case 381: // RPL_YOUREOPER
		{
			if (self.userIsIRCop == NO) {
				self.userIsIRCop = YES;
			} else {
				break;
			}

			if (printMessage) {
				[self print:TXTLS(@"IRC[1076]", m.senderNickname)
						 by:nil
				  inChannel:nil
					 asType:TVCLogLineDebugType
					command:m.command
				 receivedAt:m.receivedAt];
			}

			break;
		}
		case 328: // RPL_CHANNEL_URL
		{
			NSAssertReturn([m paramsCount] > 2);

			NSAssertReturn(printMessage);
			
			NSString *channelName = [m paramAt:1];
			NSString *website = [m paramAt:2];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				return;
			}

			[self print:TXTLS(@"IRC[1042]", website)
					 by:nil
			  inChannel:channel
				 asType:TVCLogLineWebsiteType
				command:m.command
			 receivedAt:m.receivedAt];

			break;
		}
		case 369: // RPL_ENDOFWHOWAS
		{
			[self disableInUserInvokedCommandProperty:&self->_inUserInvokedWhowasRequest];

			if (printMessage) {
				[self print:m.sequence
						 by:nil
				  inChannel:[mainWindow() selectedChannelOn:self]
					 asType:TVCLogLineDebugType
					command:m.command
				 receivedAt:m.receivedAt];
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

			if (numeric == 608 || numeric == 607) {
				[self disableInUserInvokedCommandProperty:&self->_inUserInvokedWatchRequest];
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

				break;
			}

			NSString *nickname = [m paramAt:1];
			NSString *username = [m paramAt:2];
			NSString *address = [m paramAt:3];

			NSString *hostmask = nil;

			if (numeric == 605) { // 605 does not have the host
				hostmask = [nickname stringByAppendingString:@"!*@*"];
			} else {
				hostmask = [NSString stringWithFormat:@"%@!%@@%@", nickname, username, address];
			}

			IRCAddressBookEntry *addressBookEntry =
			[self checkIgnoreAgainstHostmask:hostmask
								 withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

			if (addressBookEntry == nil) {
				break;
			}

			if (numeric == 600) // logged online
			{
				[self notifyTrackingStatusOfNickname:nickname changedTo:IRCAddressBookUserTrackingSignedOnStatus];
			}
			else if (numeric == 601) // logged offline
			{
				[self notifyTrackingStatusOfNickname:nickname changedTo:IRCAddressBookUserTrackingSignedOffStatus];
			}
			else if (numeric == 604 || // is online
					 numeric == 605) // is offline
			{
				NSString *trackingNickname = addressBookEntry.trackingNickname;

				@synchronized(self.trackedNicknames) {
					self.trackedNicknames[trackingNickname] = @(numeric == 604);
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

			NSString *nickname = [m paramAt:1];
			
			[self printDebugInformation:TXTLS(@"IRC[1088]", nickname)];
			
			break;
		}
		case 718:
		{
			NSAssertReturn([m paramsCount] == 4);

			NSAssertReturn(printMessage);
			
			NSString *nickname = [m paramAt:1];
			NSString *hostmask = [m paramAt:2];

			if ([TPCPreferences locationToSendNotices] == TXNoticeSendSelectedChannelType) {
				IRCChannel *channel = [mainWindow() selectedChannelOn:self];

				[self printDebugInformation:TXTLS(@"IRC[1089]", nickname, hostmask) inChannel:channel];

				break;
			}

			[self printDebugInformationToConsole:TXTLS(@"IRC[1089]", nickname, hostmask)];

			break;
		}
		case 900: // RPL_LOGGEDIN
		{
			NSAssertReturn([m paramsCount] > 3);

			[self enableCapacity:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL];

			if (printMessage) {
				[self print:[m sequence:3]
						 by:nil
				  inChannel:nil
					 asType:TVCLogLineDebugType
					command:m.command
				 receivedAt:m.receivedAt];
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
				if (numeric == 903) { // success
					[self print:[m sequence:1]
							 by:nil
					  inChannel:nil
						 asType:TVCLogLineDebugType
						command:m.command
					 receivedAt:m.receivedAt];
				} else {
					[self printReply:m];
				}
			}

			if ([self isPendingCapacityEnabled:ClientIRCv3SupportedCapacityIsInSASLNegotiation]) {
				[self disablePendingCapacity:ClientIRCv3SupportedCapacityIsInSASLNegotiation];

				[self resumeCapacityNegotation];
			}

			break;
		}
		default:
		{
			NSString *numericString = [NSString stringWithUnsignedInteger:numeric];

			if ([sharedPluginManager().supportedServerInputCommands containsObject:numericString]) {
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
	NSParameterAssert(m != nil);

	NSUInteger numeric = m.commandNumeric;

	BOOL printMessage = [self postReceivedMessage:m];

	switch (numeric) {
		case 401: // ERR_NOSUCHNICK
		{
			NSAssertReturn(printMessage);

			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel.isActive) {
				[self printErrorReply:m inChannel:channel];
			} else {
				[self printErrorReply:m];
			}

			break;
		}
		case 402: // ERR_NOSUCHSERVER
		{
			NSAssertReturn(printMessage);

			NSString *message = TXTLS(@"IRC[1055]", numeric, [m sequence:1]);

			[self print:message
					 by:nil
			  inChannel:nil
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

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
			
			[self receiveNicknameCollisionError:m];

			break;
		}
		case 404: // ERR_CANNOTSENDTOCHAN
		{
			NSAssertReturn(printMessage);

			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			NSString *message = TXTLS(@"IRC[1055]", numeric, [m sequence:2]);

			[self print:message
					 by:nil
			  inChannel:channel
				 asType:TVCLogLineDebugType
				command:m.command
			 receivedAt:m.receivedAt];

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
			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel) {
				channel.errorOnLastJoinAttempt = YES;
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

/* Signed */
- (void)receiveNicknameCollisionError:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	if (self.isConnected == NO || self.isLoggedIn) {
		return;
	}

	NSArray *alternateNicknames = self.config.alternateNicknames;

	NSUInteger tryingNicknameNumber = self.tryingNicknameNumber;

	if (alternateNicknames.count > tryingNicknameNumber) {
		NSString *nickname = alternateNicknames[tryingNicknameNumber];

		[self changeNickname:nickname];
	} else {
		[self tryAnotherNickname];
	}

	self.tryingNicknameNumber += 1;
}

/* Signed */
- (void)tryAnotherNickname
{
	if (self.isConnected == NO || self.isLoggedIn) {
		return;
	}

	/* IRCISupportInfo would not be populated by now which means we cannot use a
	 server-specific maximum nickname length value at this point. */
	const NSUInteger maximumLength = IRCProtocolDefaultNicknameMaximumLength;

	NSString *tryingNickname = [self.tryingNicknameSentNickname padNicknameWithCharacter:'_' maximumLength:maximumLength];

	if (tryingNickname) {
		self.tryingNicknameSentNickname = tryingNickname;
	} else {
		self.tryingNicknameSentNickname = @"0";
	}

	[self changeNickname:self.tryingNicknameSentNickname];
}

#pragma mark -
#pragma mark Autojoin (Signed)

/* Signed */
- (void)updateAutoJoinStatus
{
	self.isAutojoined = YES;

	self.isAutojoining = NO;
}

/* Signed */
- (void)performAutoJoin
{
	[self performAutoJoinInitiatedByUser:NO];
}

/* Signed */
- (void)performAutoJoinInitiatedByUser:(BOOL)initiatedByUser
{
	if (initiatedByUser == NO) {
		/* Ignore previous invocations of this method */
		if (self.isAutojoining || self.isAutojoined) {
			return;
		}

		/* Ignore autojoin based on ZNC preferences */
		if (self.isConnectedToZNC && self.config.zncIgnoreConfiguredAutojoin) {
			self.isAutojoined = YES;
		
			return;
		}

		/* Do nothing unless certain conditions are met */
		if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityIsIdentifiedWithSASL] == NO) {
			if (self.config.autojoinWaitsForNickServ) {
				if (self.serverHasNickServ && self.userIsIdentifiedWithNickServ == NO) {
					return;
				}
			}
		}
	}

	NSArray *channelList = self.channelList;

	if (channelList.count == 0) {
		self.isAutojoined = YES;
		
		return;
	}

	self.isAutojoining = YES;

	NSMutableArray<IRCChannel *> *channelsToJoin = [NSMutableArray array];
	
	for (IRCChannel *c in channelList) {
		if (c.isChannel && c.isActive == NO) {
			if (c.config.autoJoin) {
				[channelsToJoin addObject:c];
			}
		}
	}

	[self autoJoinChannels:channelsToJoin joinChannelsWithPassword:NO];
	[self autoJoinChannels:channelsToJoin joinChannelsWithPassword:YES];

	[self cancelPerformRequestsWithSelector:@selector(autojoinInProgress) object:nil]; // User might invoke -performAutojoin while timer is active

	[self performSelector:@selector(updateAutoJoinStatus) withObject:nil afterDelay:25.0];
}

/* Signed */
- (void)autoJoinChannels:(NSArray<IRCChannel *> *)channelList joinChannelsWithPassword:(BOOL)joinChannelsWithPassword
{
	NSParameterAssert(channelList != nil);

	NSMutableString *channelString = [NSMutableString string];
	NSMutableString *passwordString = [NSMutableString string];

	NSUInteger channelCount = 0;

	for (IRCChannel *channel in channelList) {
		/* Ignore channels that aren't parted */
		if (channel.status != IRCChannelStatusParted) {
			LogToConsoleDebug("Refusing to join %@ because of status: %{public}ld",
					channel.name, channel.status)

			continue;
		}

		/* If we have reached the maximum count, then join channels and reset */
		if (channelCount > [TPCPreferences autojoinMaximumChannelJoins]) {
			[self forceJoinChannel:channelString password:passwordString];

			[channelString setString:NSStringEmptyPlaceholder];
			[passwordString setString:NSStringEmptyPlaceholder];

			channelCount = 0;
		}

		/* Add next channel and increase count */
		NSString *secretKey = channel.secretKey;

		if (joinChannelsWithPassword) {
			if (secretKey.length == 0) {
				continue;
			}

			if (passwordString.length > 0) {
				[passwordString appendString:@","];
			}

			[passwordString appendString:secretKey];
		} else {
			if (secretKey.length > 0) {
				continue;
			}
		}

		if (channelString.length > 0) {
			[channelString appendString:@","];
		}

		[channelString appendString:channel.name];

		channel.status = IRCChannelStatusJoining;

		channelCount += 1;
	}

	/* Join channels that remain */
	if (channelString.length == 0) {
		return;
	}

	[self forceJoinChannel:channelString password:passwordString];
}

#pragma mark -
#pragma mark Post Events (Signed)

/* Signed */
- (void)postEventToViewController:(NSString *)eventToken
{
	if (themeSettings().js_postHandleEventNotifications == NO) {
		return; // Cancel operation...
	}

	[self postEventToViewController:eventToken forItem:self];

	for (IRCChannel *channel in self.channelList) {
		[self postEventToViewController:eventToken forItem:channel];
	}
}

/* Signed */
- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel
{
	if (themeSettings().js_postHandleEventNotifications == NO) {
		return; // Cancel operation...
	}

	[self postEventToViewController:eventToken forItem:channel];
}

/* Signed */
- (void)postEventToViewController:(NSString *)eventToken forItem:(IRCTreeItem *)item
{
	NSParameterAssert(eventToken != nil);
	NSParameterAssert(item != nil);

	if (self.isTerminating) {
		return;
	}

	[item.viewController evaluateFunction:@"Textual.handleEvent" withArguments:@[eventToken] onQueue:NO];
}

#pragma mark -
#pragma mark Timers (Signed)

/* Signed */
- (void)startPongTimer
{
	if (self.pongTimer.timerIsActive) {
		return;
	}

	[self.pongTimer start:_pongCheckInterval];
}

/* Signed */
- (void)stopPongTimer
{
	if (self.pongTimer.timerIsActive == NO) {
		return;
	}

	[self.pongTimer stop];
}

/* Signed */
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

	NSInteger timeSpent = [NSDate timeIntervalSinceNow:self.lastMessageReceived];

	if (timeSpent >= _timeoutInterval)
	{
		if (self.config.performDisconnectOnPongTimer) {
			[self printDebugInformation:TXTLS(@"IRC[1053]", (timeSpent / 60.0)) inChannel:nil];

			[self performBlockOnMainThread:^{
				[self disconnect];
			}];

			return;
		}

		if (self.timeoutWarningShownToUser == NO) {
			self.timeoutWarningShownToUser = YES;

			[self printDebugInformation:TXTLS(@"IRC[1054]", (timeSpent / 60.0)) inChannel:nil];
		}
	}
	else if (timeSpent >= _pingInterval)
	{
		[self sendPing:self.serverAddress];
	}
}

/* Signed */
- (void)startReconnectTimer
{
	if ((self.reconnectEnabledBecauseOfSleepMode		&& self.config.autoSleepModeDisconnect == NO) ||
		(self.reconnectEnabledBecauseOfSleepMode == NO  && self.config.autoReconnect == NO))
	{
		return;
	}

	if (self.reconnectTimer.timerIsActive) {
		return;
	}

	[self.reconnectTimer start:_reconnectInterval];
}

/* Signed */
- (void)stopReconnectTimer
{
	if (self.reconnectTimer.timerIsActive == NO) {
		return;
	}

	[self.reconnectTimer stop];
}

/* Signed */
- (void)onReconnectTimer:(id)sender
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	[self connect:IRCClientConnectReconnectMode];
}

/* Signed */
- (void)startRetryTimer
{
	if (self.retryTimer.timerIsActive) {
		return;
	}

	[self.retryTimer start:_retryInterval];
}

/* Signed */
- (void)stopRetryTimer
{
	if (self.retryTimer.timerIsActive == NO) {
		return;
	}

	[self.retryTimer stop];
}

/* Signed */
- (void)onRetryTimer:(id)sender
{
	if (self.isConnected == NO) {
		return;
	}

	[self performBlockOnMainThread:^{
		__weak IRCClient *weakSelf = self;
		
		self.disconnectCallback = ^{
			[weakSelf connect:IRCClientConnectRetryMode];
		};

		[self disconnect];
	}];
}

#pragma mark -
#pragma mark User Invoked Command Controls (Signed)

/* Signed */
- (void)enableInUserInvokedCommandProperty:(BOOL *)property
{
	NSParameterAssert(property != NULL);

#define _inUserInvokedCommandTimeoutInterval		10.0

	if (*property == NO) {
		*property = YES;

		[self performSelector:@selector(timeoutInUserInvokedCommandProperty:)
				   withObject:[NSValue valueWithPointer:property]
				   afterDelay:_inUserInvokedCommandTimeoutInterval];
	}

#undef _inUserInvokedCommandTimeoutInterval
}

/* Signed */
- (void)disableInUserInvokedCommandProperty:(BOOL *)property
{
	NSParameterAssert(property != NULL);

	if (*property != NO) {
		*property = NO;

		[self cancelPerformRequestsWithSelector:@selector(timeoutInUserInvokedCommandProperty:)
										 object:[NSValue valueWithPointer:property]];
	}
}

/* Signed */
- (void)timeoutInUserInvokedCommandProperty:(NSValue *)propertyPointerValue
{
	NSParameterAssert(propertyPointerValue != nil);

	void *propertyPointer = propertyPointerValue.pointerValue;

	if (propertyPointer != NO) {
		propertyPointer = NO;
	}
}

#pragma mark -
#pragma mark Plugins and Scripts (Signed)

/* Signed */
- (void)outputDescriptionForError:(NSError *)error forTextualCmdScriptAtPath:(NSString *)path inputString:(NSString *)inputString
{
	NSString *filename = path.lastPathComponent;

	NSString *errorDescription = error.userInfo[NSAppleScriptErrorMessage];

	if (errorDescription == nil) {
		errorDescription = error.userInfo[NSAppleScriptErrorBriefMessage];
	}

	if (errorDescription == nil) {
		errorDescription = error.localizedFailureReason;
	}

	if (errorDescription == nil) {
		errorDescription = error.localizedDescription;
	}

	if (inputString.length == 0) {
		inputString = @"(no input)";
	}

	[self printDebugInformation:TXTLS(@"IRC[1003]", filename, inputString, errorDescription)];

	LogToConsoleError("%{public}@", TXTLS(@"IRC[1002]", errorDescription))
}

/* Signed */
- (void)sendTextualCmdScriptResult:(NSString *)resultString toChannel:(nullable NSString *)channel
{
	NSParameterAssert(resultString != nil);

	IRCTreeItem *destination = nil;

	if (channel == nil) {
		destination = self;
	} else {
		destination = [self findChannel:channel];
	}

	if (destination == nil) {
		LogToConsoleError("A script returned a result but its destination no longer exists")

		return;
	}

	resultString = resultString.trim;

	[self performBlockOnMainThread:^{
		[self inputText:resultString destination:destination];
	}];
}

/* Signed */
- (void)executeTextualCmdScriptInContext:(NSDictionary<NSString *, NSString *> *)context
{
	XRPerformBlockAsynchronouslyOnQueue([THOPluginDispatcher dispatchQueue], ^{
		[self _executeTextualCmdScriptInContext:context];
	});
}

/* Signed */
- (void)_executeTextualCmdScriptInContext:(NSDictionary<NSString *, NSString *> *)context
{
	NSParameterAssert(context != nil);

	NSString *inputString = context[@"inputString"];

	NSString *path = context[@"path"];

	NSString *targetChannel = context[@"targetChannel"];

	NSParameterAssert(path != nil);

	NSURL *pathURL = [NSURL fileURLWithPath:path];

	/* Is it AppleScript? */
	if ([path hasSuffix:TPCResourceManagerScriptDocumentTypeExtension]) {
		/* /////////////////////////////////////////////////////// */
		/* Event Descriptor */
		/* /////////////////////////////////////////////////////// */

		NSAppleEventDescriptor *firstParameter = [NSAppleEventDescriptor descriptorWithString:inputString];
		NSAppleEventDescriptor *secondParameter = [NSAppleEventDescriptor descriptorWithString:targetChannel];
		
		NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];

		[parameters insertDescriptor:firstParameter atIndex:1];
		[parameters insertDescriptor:secondParameter atIndex:2];

		ProcessSerialNumber process = { 0, kCurrentProcess };

		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
																						bytes:&process
																					   length:sizeof(ProcessSerialNumber)];

		NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:@"textualcmd"];

		NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																				 eventID:kASSubroutineEvent
																		targetDescriptor:target
																				returnID:kAutoGenerateReturnID
																		   transactionID:kAnyTransactionID];

		[event setParamDescriptor:handler forKeyword:keyASSubroutineName];

		[event setParamDescriptor:parameters forKeyword:keyDirectObject];
		
		/* /////////////////////////////////////////////////////// */
		/* Execute Event */
		/* /////////////////////////////////////////////////////// */

		NSError *appleScriptError = nil;

		NSUserAppleScriptTask *appleScript = [[NSUserAppleScriptTask alloc] initWithURL:pathURL error:&appleScriptError];

		if (appleScript == nil) {
			[self outputDescriptionForError:appleScriptError forTextualCmdScriptAtPath:path inputString:inputString];

			return;
		}

		[appleScript executeWithAppleEvent:event
						 completionHandler:^(NSAppleEventDescriptor *result, NSError *error)
		 {
			 if (result == nil) {
				 [self outputDescriptionForError:error forTextualCmdScriptAtPath:path inputString:inputString];
			 } else {
				 [self sendTextualCmdScriptResult:result.stringValue toChannel:targetChannel];
			 }
		 }];

		return;
	}

	/* /////////////////////////////////////////////////////// */
	/* Execute Shell Script */
	/* /////////////////////////////////////////////////////// */
	
	/* Build list of arguments. */
	NSMutableArray *taskArguments = [NSMutableArray array];
	
	if (targetChannel) {
		[taskArguments addObject:targetChannel];
	} else {
		[taskArguments addObject:[NSNull null]];
	}

	NSArray *inputStringComponents = [inputString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	[taskArguments addObjectsFromArray:inputStringComponents];

	/* Create task object */
	NSError *taskError = nil;
	
	NSUserUnixTask *task = [[NSUserUnixTask alloc] initWithURL:pathURL error:&taskError];

	if (task == nil) {
		[self outputDescriptionForError:taskError forTextualCmdScriptAtPath:path inputString:inputString];

		return;
	}

	/* Prepare pipe */
	NSPipe *standardOutputPipe = [NSPipe pipe];

	NSFileHandle *readingPipe = standardOutputPipe.fileHandleForReading;
	NSFileHandle *writingPipe = standardOutputPipe.fileHandleForWriting;
	
	task.standardOutput = writingPipe;

	/* Try performing task */
	[task executeWithArguments:taskArguments completionHandler:^(NSError *error) {
		if (error) {
			[self outputDescriptionForError:error forTextualCmdScriptAtPath:path inputString:inputString];

			return;
		}

		NSData *result = [readingPipe readDataToEndOfFile];

		NSString *resultString = [NSString stringWithData:result encoding:NSUTF8StringEncoding];

		[self sendTextualCmdScriptResult:resultString toChannel:targetChannel];
	}];
}

/* Signed */
- (void)processBundlesUserMessage:(NSString *)message command:(NSString *)command
{
	NSParameterAssert(message != nil);

	[THOPluginDispatcher userInputCommandInvokedOnClient:self commandString:command messageString:message];
}

/* Signed */
- (void)processBundlesServerMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[THOPluginDispatcher didReceiveServerInput:message onClient:self];
}

/* Signed */
- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage
{
	NSParameterAssert(referenceMessage != nil);

	return [self postReceivedMessage:referenceMessage
							withText:referenceMessage.sequence
						 destinedFor:nil];
}

/* Signed */
- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage withText:(nullable NSString *)text destinedFor:(nullable IRCChannel *)textDestination
{
	NSParameterAssert(referenceMessage != nil);

	return [self postReceivedCommand:referenceMessage.command
							withText:text
						 destinedFor:textDestination
					referenceMessage:referenceMessage];
}

/* Signed */
- (BOOL)postReceivedCommand:(NSString *)command withText:(nullable NSString *)text destinedFor:(nullable IRCChannel *)textDestination referenceMessage:(IRCMessage *)referenceMessage
{
	NSParameterAssert(command != nil);
	NSParameterAssert(referenceMessage != nil);

	return [THOPluginDispatcher receivedCommand:command
									   withText:text
									 authoredBy:referenceMessage.sender
									destinedFor:textDestination
									   onClient:self
									 receivedAt:referenceMessage.receivedAt];
}

#pragma mark -
#pragma mark Commands (Signed)

/* Signed */
- (void)connect
{
	[self connect:IRCClientConnectNormalMode];
}

/* Signed */
- (void)connect:(IRCClientConnectMode)connectMode
{
	BOOL preferIPv4 = self.config.connectionPrefersIPv4;

	[self connect:connectMode preferIPv4:preferIPv4];
}

/* Signed */
- (void)connect:(IRCClientConnectMode)connectMode preferIPv4:(BOOL)preferIPv4
{
	/* Do not allow a connect to occur until the current 
	 socket has completed disconnecting */
	if (self.isConnecting || self.isConnected || self.isQuitting) {
		return;
	}

	/* Reset status */
	self.connectType = connectMode;

	self.disconnectType = IRCClientDisconnectNormalMode;

	self.isConnecting = YES;

	/* Disable reconnect attempt but permit more */
	[self stopReconnectTimer];

	self.reconnectEnabled = YES;

	/* Begin populating configuration */
	NSString *serverAddress = nil;

	uint16_t serverPort = IRCConnectionDefaultServerPort;

	if (self.temporaryServerAddressOverride) {
		serverAddress = self.temporaryServerAddressOverride;
	} else {
		serverAddress = self.config.serverAddress;
	}

	if (self.temporaryServerPortOverride > 0) {
		serverPort = self.temporaryServerPortOverride;
	} else {
		serverPort = self.config.serverPort;
	}

	/* Do not wait for an actual connect before destroying the temporary
	 store. Once its defined, its to be nil'd out no matter what. */
	self.temporaryServerAddressOverride = nil;
	self.temporaryServerPortOverride = 0;

	/* Present status to user */
	[mainWindow() updateTitleFor:self];
	
	[self logFileWriteSessionBegin];

	if (connectMode == IRCClientConnectReconnectMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1060]")];
	} else if (connectMode == IRCClientConnectRetryMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1061]")];
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1056]", serverAddress, serverPort)];

	/* Create socket */
	IRCConnectionConfigMutable *socketConfig = [IRCConnectionConfigMutable new];

	socketConfig.serverAddress = serverAddress;
	socketConfig.serverPort = serverPort;

	socketConfig.connectionPrefersIPv4 = preferIPv4;

	socketConfig.connectionPrefersModernCiphers = self.config.connectionPrefersModernCiphers;
	socketConfig.connectionPrefersSecuredConnection = self.config.prefersSecuredConnection;
	socketConfig.connectionShouldValidateCertificateChain = self.config.validateServerCertificateChain;

	socketConfig.identityClientSideCertificate = self.config.identityClientSideCertificate;

	socketConfig.proxyType = self.config.proxyType;

	if (socketConfig.proxyType == IRCConnectionSocketSocks4ProxyType ||
		socketConfig.proxyType == IRCConnectionSocketSocks5ProxyType ||
		socketConfig.proxyType == IRCConnectionSocketHTTPProxyType ||
		socketConfig.proxyType == IRCConnectionSocketHTTPSProxyType)
	{
		socketConfig.proxyPort = self.config.proxyPort;
		socketConfig.proxyAddress = self.config.proxyAddress;
		socketConfig.proxyPassword = self.config.proxyPassword;
		socketConfig.proxyUsername = self.config.proxyUsername;
	}

	socketConfig.floodControlDelayInterval = self.config.floodControlDelayTimerInterval;
	socketConfig.floodControlMaximumMessages = self.config.floodControlMaximumMessages;

	self.socket = [[IRCConnection alloc] initWithConfig:socketConfig onClient:self];

	[self.socket open];

	/* Pass status to view controller */
	[self postEventToViewController:@"serverConnecting"];
}

/* Signed */
- (void)autoConnectWithDelay:(NSUInteger)delay afterWakeUp:(BOOL)afterWakeUp
{
	self.connectDelay = delay;

	if (afterWakeUp) {
		[self autoConnectAfterWakeUp];
	} else {
		[self autoConnect];
	}
}

/* Signed */
- (void)autoConnect
{
	NSUInteger connectDelay = self.connectDelay;

	if (connectDelay == 0) {
		[self autoConnectPerformConnect];

		return;
	}

	[self performSelector:@selector(autoConnectPerformConnect) withObject:nil afterDelay:connectDelay];
}

/* Signed */
- (void)autoConnectPerformConnect
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	[self connect];
}

/* Signed */
- (void)autoConnectAfterWakeUp
{
	NSUInteger connectDelay = self.connectDelay;

	if (connectDelay == 0) {
		[self autoConnectAfterWakeUpPerformConnect];

		return;
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1010]", connectDelay)];

	[self performSelector:@selector(autoConnectAfterWakeUp) withObject:nil afterDelay:connectDelay];
}

/* Signed */
- (void)autoConnectAfterWakeUpPerformConnect
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	self.reconnectEnabledBecauseOfSleepMode = YES;

	[self connect:IRCClientConnectReconnectMode];
}

/* Signed */
- (void)disconnect
{
	[self cancelPerformRequestsWithSelector:@selector(disconnect) object:nil];

	if (self.isConnecting == NO && self.isConnected == NO) {
		return;
	}

	if (self.socket == nil) {
		return;
	}

	[self.socket close];
}

/* Signed */
- (void)quit
{
	NSString *comment = nil;

	if (self.disconnectType == IRCClientDisconnectComputerSleepMode) {
		comment = self.config.sleepModeLeavingComment;
	} else {
		comment = self.config.normalLeavingComment;
	}

	[self quitWithComment:comment];
}

/* Signed */
- (void)quitWithComment:(NSString *)comment
{
	NSParameterAssert(comment != nil);

    if ((self.isConnecting == NO && self.isConnected == NO) || self.isQuitting) {
        return;
	}

	self.isQuitting	= YES;
	
	[self cancelReconnect];

    [self postEventToViewController:@"serverDisconnecting"];

	[self.socket clearSendQueue];

	/* If -isLoggedIn is NO, then the connection does not need 
	 to be closed gracefully because the user hasn't even joined
	 a channel yet, so who are we doing it for? */
	if (self.isLoggedIn == NO) {
		[self disconnect];

		return;
	}

	[self send:IRCPrivateCommandIndex("quit"), comment, nil];

	/* We give it two seconds before forcefully breaking so that the graceful
	 quit with the quit message above can be performed. */
	[self performSelector:@selector(disconnect) withObject:nil afterDelay:2.0];
}

/* Signed */
- (void)cancelReconnect
{
	self.reconnectEnabled = NO;
	self.reconnectEnabledBecauseOfSleepMode = NO;

	[self stopReconnectTimer];

	[mainWindow() updateTitleFor:self];
}

/* Signed */
- (void)changeNickname:(NSString *)newNickname
{
	NSParameterAssert(newNickname != nil);

	if (self.isConnected == NO) {
		return;
	}

	if (newNickname.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("nick"), newNickname, nil];
}

/* Signed */
- (void)joinKickedChannel:(IRCChannel *)channel
{
	[self joinChannel:channel];
}

/* Signed */
- (void)joinChannel:(IRCChannel *)channel
{
	[self joinChannel:channel password:nil];
}

/* Signed */
- (void)joinUnlistedChannel:(NSString *)channel
{
	[self joinUnlistedChannel:channel password:nil];
}

/* Signed */
- (void)joinChannel:(IRCChannel *)channel password:(nullable NSString *)password
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO || channel.isActive) {
		return;
	}

	channel.status = IRCChannelStatusJoining;

	if (password == nil) {
		password = channel.secretKey;
	}
	
	[self forceJoinChannel:channel.name password:password];
}

/* Signed */
- (void)joinUnlistedChannel:(NSString *)channel password:(nullable NSString *)password
{
	NSParameterAssert(channel != nil);

	if ([self stringIsChannelName:channel] == NO) {
		// Many IRCd (I don't know of any that don't) use "JOIN 0" as a
		// secret way to have the user part all channels they are in.
		if ([channel isEqualToString:@"0"]) {
			[self forceJoinChannel:channel password:password];
		}

		return;
	}

	IRCChannel *channelPointer = [self findChannel:channel];

	if (channelPointer) {
		[self joinChannel:channelPointer password:password];

		return;
	}

	[self forceJoinChannel:channel password:password];
}

/* Signed */
- (void)forceJoinChannel:(NSString *)channel password:(nullable NSString *)password
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("join"), channel, password, nil];
}

/* Signed */
- (void)partUnlistedChannel:(NSString *)channel
{
	[self partUnlistedChannel:channel withComment:nil];
}

/* Signed */
- (void)partChannel:(IRCChannel *)channel
{
	[self partChannel:channel withComment:nil];
}

/* Signed */
- (void)partUnlistedChannel:(NSString *)channel withComment:(nullable NSString *)comment
{
	NSParameterAssert(channel != nil);

	if ([self stringIsChannelName:channel] == NO) {
		return;
	}

	IRCChannel *channelPointer = [self findChannel:channel];

	if (channelPointer == nil) {
		return;
	}

	[self partChannel:channelPointer withComment:comment];
}

/* Signed */
- (void)partChannel:(IRCChannel *)channel withComment:(nullable NSString *)comment
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.isChannel == NO || channel.isActive == NO) {
		return;
	}

	if (comment == nil) {
		comment = self.config.normalLeavingComment;
	}

	[self send:IRCPrivateCommandIndex("part"), channel.name, comment, nil];
}

/* Signed */
- (void)sendWhoToChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self sendWhoToChannelNamed:channel.name];
}

/* Signed */
- (void)sendWhoToChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("who"), channel, nil];
}

/* Signed */
- (void)sendWhois:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (nickname.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("whois"), nickname, nickname, nil];
}

/* Signed */
- (void)kick:(NSString *)nickname inChannel:(IRCChannel *)channel
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.isChannel == NO || channel.isActive == NO) {
		return;
	}

	if (nickname.length == 0) {
		return;
	}

	NSString *reason = [TPCPreferences defaultKickMessage];

	[self send:IRCPrivateCommandIndex("kick"), channel.name, nickname, reason, nil];
}

/* Signed */
- (void)toggleAwayStatusWithComment:(nullable NSString *)comment
{
	if (self.userIsAway) {
		[self toggleAwayStatus:NO withComment:nil];
	} else {
		if (comment.length == 0) {
			comment = TXTLS(@"IRC[1031]");
		}

		[self toggleAwayStatus:YES withComment:comment];
	}
}

/* Signed */
- (void)toggleAwayStatus:(BOOL)setAway
{
	NSString *comment = TXTLS(@"IRC[1031]");

    [self toggleAwayStatus:setAway withComment:comment];
}

/* Signed */
- (void)toggleAwayStatus:(BOOL)setAway withComment:(nullable NSString *)comment
{
	NSParameterAssert(setAway == NO || comment != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (setAway) {
		[self send:IRCPrivateCommandIndex("away"), comment, nil];
	} else {
		[self send:IRCPrivateCommandIndex("away"), nil];
	}

	NSString *newNickname = nil;
	
	if (setAway) {
		newNickname = self.config.awayNickname;

		self.preAwayUserNickname = self.userNickname;
	} else {
		newNickname = self.preAwayUserNickname;

		self.preAwayUserNickname = nil;
		
		/* If we have an away nickname configured but no preAawayNickname set,
		 then use the configured nickname instead. User probably was on bouncer
		 and relaunched Textual, losing preAwayNickname.*/
		if (newNickname == nil && self.config.awayNickname.length > 0) {
			newNickname = self.config.nickname;
		}
	}

	if (newNickname) {
		[self changeNickname:newNickname];
	}
}

/* Signed */
- (void)presentCertificateTrustInformation
{
	if (self.isSecured == NO) {
		return;
	}

	[self.socket openSSLCertificateTrustDialog];
}

/* Signed */
- (void)requestModesForChannel:(IRCChannel *)channel
{
	[self sendModes:nil withParamaters:nil inChannel:channel];
}

/* Signed */
- (void)requestModesForChannelNamed:(NSString *)channel
{
	[self sendModes:nil withParamaters:nil inChannelNamed:channel];
}

/* Signed */
- (void)sendModes:(nullable NSString *)modeSymbols withParamaters:(nullable NSArray<NSString *> *)paramaters inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self sendModes:modeSymbols withParamaters:paramaters inChannelNamed:channel.name];
}

/* Signed */
- (void)sendModes:(nullable NSString *)modeSymbols withParamatersString:(nullable NSString *)paramatersString inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self sendModes:modeSymbols withParamatersString:paramatersString inChannelNamed:channel.name];
}

/* Signed */
- (void)sendModes:(nullable NSString *)modeSymbols withParamaters:(nullable NSArray<NSString *> *)paramaters inChannelNamed:(NSString *)channel
{
	NSString *paramatersString = [paramaters componentsJoinedByString:NSStringWhitespacePlaceholder];

	[self sendModes:modeSymbols withParamatersString:paramatersString inChannelNamed:channel];
}

/* Signed */
- (void)sendModes:(nullable NSString *)modeSymbols withParamatersString:(nullable NSString *)paramatersString inChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("mode"), channel, modeSymbols, paramatersString, nil];
}

/* Signed */
- (void)sendPing:(NSString *)tokenString
{
	NSParameterAssert(tokenString != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("ping"), tokenString, nil];
}

/* Signed */
- (void)sendPong:(NSString *)tokenString
{
	NSParameterAssert(tokenString != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("pong"), tokenString, nil];
}

/* Signed */
- (void)sendInviteTo:(NSString *)nickname toJoinChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self sendInviteTo:nickname toJoinChannelNamed:channel.name];
}

/* Signed */
- (void)sendInviteTo:(NSString *)nickname toJoinChannelNamed:(NSString *)channel
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(channel != nil);

	if (nickname.length == 0 || channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("invite"), nickname, channel, nil];
}

/* Signed */
- (void)requestTopicForChannel:(IRCChannel *)channel
{
	[self sendTopicTo:nil inChannel:channel];
}

/* Signed */
- (void)requestTopicForChannelNamed:(NSString *)channel
{
	[self sendTopicTo:nil inChannelNamed:channel];
}

/* Signed */
- (void)sendTopicTo:(nullable NSString *)topic inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO || channel.isActive == NO) {
		return;
	}

	[self sendTopicTo:topic inChannelNamed:channel.name];
}

/* Signed */
- (void)sendTopicTo:(nullable NSString *)topic inChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("topic"), channel, topic, nil];
}

/* Signed */
- (void)sendCapacity:(NSString *)subcommand data:(nullable NSString *)data
{
	NSParameterAssert(subcommand != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("cap"), subcommand, data, nil];
}

/* Signed */
- (void)sendCapacityAuthenticate:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.isConnected == NO) {
		return;
	}

	if (data.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("cap_authenticate"), data, nil];
}

/* Signed */
- (void)sendIsonForNicknames:(NSArray<NSString *> *)nicknames
{
	NSParameterAssert(nicknames != nil);

	if (nicknames.count == 0) {
		return;
	}

	NSString *nicknamesString = [nicknames componentsJoinedByString:NSStringWhitespacePlaceholder];

	[self sendIsonForNicknamesString:nicknamesString];
}

/* Signed */
- (void)sendIsonForNicknamesString:(NSString *)nicknames
{
	NSParameterAssert(nicknames != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (nicknames.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("ison"), nicknames, nil];
}

/* Signed */
- (void)requestChannelList
{
	if (self.isLoggedIn == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("list"), nil];
}

/* Signed */
- (void)sendPassword:(NSString *)password
{
	NSParameterAssert(password != nil);

	if (self.isConnected == NO) {
		return;
	}

	if (password.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("pass"), password, nil];
}

/* Signed */
- (void)modifyWatchListBy:(BOOL)adding nicknames:(NSArray<NSString *> *)nicknames
{
	NSParameterAssert(nicknames != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (nicknames.count == 0) {
		return;
	}

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand] == NO) {
		return;
	}

	NSString *modifier = nil;

	if (adding) {
		modifier = @" +";
	} else {
		modifier = @" -";
	}

	NSString *nicknamesString = [nicknames componentsJoinedByString:modifier];

	[self send:IRCPrivateCommandIndex("watch"), [modifier stringByAppendingString:nicknamesString], nil];
}

#pragma mark -
#pragma mark File Transfers (Signed)

/* Signed */
- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize requestIdentifier:(NSString *)identifier
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(filename != nil);
	NSParameterAssert(identifier != nil);

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
	
	[self notifyEvent:type lineType:TVCLogLineUndefinedType target:nil nickname:nickname text:description userInfo:info];
}

/* Signed */
- (void)receivedDCCQuery:(IRCMessage *)m text:(NSString *)text ignoreInfo:(nullable IRCAddressBookEntry *)ignoreInfo
{
	NSParameterAssert(m != nil);
	NSParameterAssert(text != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	/* Do not continue if the user has configured an ignore for file transfers */
	if (ignoreInfo.ignoreFileTransferRequests) {
		return;
	}

	/* Do not continue if we are not the target */
	if ([self nicknameIsMyself:[m paramAt:0]] == NO) {
		return;
	}

	/* Record information */
	NSString *sender = m.senderNickname;

	NSMutableString *textMutable = [text mutableCopy];

	NSString *subcommand = textMutable.uppercaseGetToken;
	
	BOOL isSendRequest = ([subcommand isEqualToString:@"SEND"]);
	BOOL isResumeRequest = ([subcommand isEqualToString:@"RESUME"]);
	BOOL isAcceptRequest = ([subcommand isEqualToString:@"ACCEPT"]);

	if (isSendRequest == NO && isResumeRequest == NO && isAcceptRequest == NO) {
		return;
	}

	NSString *section1 = textMutable.tokenIncludingQuotes;
	NSString *section2 = textMutable.token;
	NSString *section3 = textMutable.token;
	NSString *section4 = textMutable.token;
	NSString *section5 = textMutable.token;

	/* Trim whitespaces in case someone tries to send blank 
	 spaces in a quoted string for filename. */
	section1 = section1.trim;
	
	/* Remove T from in front of token if it is there. */
	if (isSendRequest) {
		if ([section5 hasPrefix:@"T"]) {
			section5 = [section5 substringFromIndex:1];
		}
	} else if (isAcceptRequest || isResumeRequest) {
	   if ([section4 hasPrefix:@"T"]) {
			section4 = [section4 substringFromIndex:1];
	   }
	}
	
	/* Valid values? */
	if ( section1.length == 0 ||
		 section2.length == 0 ||
		(section4.length == 0 && isSendRequest))
	{
		return;
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
		/* Get normal information */
		filename = section1.safeFilename;

		filesize = section4;
		
		hostPort = section3;
		
		transferToken = section5;
		
		/* Translate host address */
		if (section2.numericOnly) {
			long long a = section2.longLongValue;
			
			NSInteger w = (a & 0xff); a >>= 8;
			NSInteger x = (a & 0xff); a >>= 8;
			NSInteger y = (a & 0xff); a >>= 8;
			NSInteger z = (a & 0xff);
			
			hostAddress = [NSString stringWithFormat:@"%ld.%ld.%ld.%ld", (long)z, (long)y, (long)x, (long)w];
		} else {
			hostAddress = section2;
		}
	}
	else if (isResumeRequest || isAcceptRequest)
	{
		filename = section1.safeFilename;

		filesize = section3;

		hostPort = section2;

		transferToken = section4;

		hostAddress = nil;
	}

	if (transferToken && transferToken.length == 0) {
		transferToken = nil;
	}

	/* Important checks */
	if (transferToken.length > 0 && transferToken.numericOnly == NO) {
		LogToConsoleError("Fatal error: Received transfer token that is not a number")

		goto present_error;
	}

	NSInteger hostPortInt = hostPort.integerValue;

	if (hostPortInt == 0 && transferToken == nil) {
		LogToConsoleError("Fatal error: Port cannot be zero without a transfer token")

		goto present_error;
	} else if (hostPortInt < 0 || hostPortInt > TXMaximumTCPPort) {
		LogToConsoleError("Fatal error: Port cannot be less than zero or greater than 65535")

		goto present_error;
	}

	long long filesizeInt = filesize.longLongValue;

	if (filesizeInt <= 0 || filesizeInt > (1000^4)) { // 1 TB
		LogToConsoleError("Fatal error: Filesize is silly")

		goto present_error;
	}

	/* Process invidiual commands */
	if (isSendRequest) {
		/* DCC SEND <filename> <peer-ip> <port> <filesize> [token] */

		if (transferToken) {
			TDCFileTransferDialogTransferController *e = [[self fileTransferController] fileTransferSenderMatchingToken:transferToken];

			/* 0 port indicates a new request in reverse DCC */
			if (hostPortInt == 0)
			{
				if (e != nil) {
					LogToConsoleError("Fatal error: Received reverse DCC request with token '%{public}@' but the token already exists.", transferToken)

					goto present_error;
				}

				[self receivedDCCSend:sender
							 filename:filename
							  address:hostAddress
								 port:hostPortInt
							 filesize:filesizeInt
								token:transferToken];

				return;
			}
			else if (e)
			{
				if (e.transferStatus != TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus) {
					LogToConsoleError("Fatal error: Unexpected request to begin transfer")

					goto present_error;
				}

				e.hostAddress = hostAddress;

				e.transferPort = hostPortInt;

				[e didReceiveSendRequestFromClient];

				return;
			}
		}
		else // transferToken
		{
			/* Treat as normal DCC request */
			[self receivedDCCSend:sender
						 filename:filename
						  address:hostAddress
							 port:hostPort.integerValue
						 filesize:filesize.longLongValue
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
			LogToConsoleError("Fatal error: Could not locate file transfer that matches resume request")

			goto present_error;
		}

		if ((isResumeRequest && e.transferStatus != TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus) ||
			(isAcceptRequest && e.transferStatus != TDCFileTransferDialogTransferWaitingForResumeAcceptStatus))
		{
			LogToConsoleError("Fatal error: Bad transfer status")

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
	[self print:TXTLS(@"IRC[1020]", sender) by:nil inChannel:nil asType:TVCLogLineDCCFileTransferType command:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (void)receivedDCCSend:(NSString *)nickname filename:(NSString *)filename address:(NSString *)address port:(uint16_t)port filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(filename != nil);
	NSParameterAssert(address != nil);

	NSString *message = TXTLS(@"IRC[1019]", nickname, filename, totalFilesize);

	[self print:message by:nil inChannel:nil asType:TVCLogLineDCCFileTransferType command:TVCLogLineDefaultCommandValue];
	
	if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyIgnoreAction) {
		return;
	}

	NSString *addedRequest = [[self fileTransferController] addReceiverForClient:self nickname:nickname address:address port:port filename:filename filesize:totalFilesize token:transferToken];

	if (addedRequest == nil) {
		return;
	}

	[self notifyFileTransfer:TXNotificationFileTransferReceiveRequestedType nickname:nickname filename:filename filesize:totalFilesize requestIdentifier:addedRequest];
}

/* Signed */
- (void)sendFileResume:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(filename != nil);

	NSString *escapedFilename = [self DCCSendEscapeFilename:filename];

	NSString *stringToSend = nil;

	if (transferToken) {
		stringToSend = [NSString stringWithFormat:@"%@ %lu %lli %@", escapedFilename, port, totalFilesize, transferToken];
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %lu %lli", escapedFilename, port, totalFilesize];
	}

	[self sendCTCPQuery:nickname command:@"DCC RESUME" text:stringToSend];
}

/* Signed */
- (void)sendFileResumeAccept:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(filename != nil);

	NSString *escapedFilename = [self DCCSendEscapeFilename:filename];

	NSString *stringToSend = nil;

	if (transferToken) {
		stringToSend = [NSString stringWithFormat:@"%@ %lu %lli %@", escapedFilename, port, totalFilesize, transferToken];
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %lu %lli", escapedFilename, port, totalFilesize];
	}

	[self sendCTCPQuery:nickname command:@"DCC ACCEPT" text:stringToSend];
}

/* Signed */
- (void)sendFile:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(filename != nil);

	NSString *address = [self DCCTransferAddress];

	if (address == nil) {
		return;
	}

	NSString *escapedFilename = [self DCCSendEscapeFilename:filename];

	NSString *stringToSend = nil;

	if (transferToken.length > 0) {
		stringToSend = [NSString stringWithFormat:@"%@ %@ %lu %lli %@", escapedFilename, address, port, totalFilesize, transferToken];
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %@ %lu %lli", escapedFilename, address, port, totalFilesize];
	}
	
	[self sendCTCPQuery:nickname command:@"DCC SEND" text:stringToSend];
	
	NSString *message = TXTLS(@"IRC[1018]", nickname, filename, totalFilesize);

	[self print:message by:nil inChannel:nil asType:TVCLogLineDCCFileTransferType command:TVCLogLineDefaultCommandValue];
}

/* Signed */
- (NSString *)DCCSendEscapeFilename:(NSString *)filename
{
	NSParameterAssert(filename != nil);

	NSString *filenameEscaped = filename.safeFilename;

	if ([filenameEscaped contains:NSStringWhitespacePlaceholder] == NO) {
		return filenameEscaped;
	}

	return [NSString stringWithFormat:@"\"%@\"", filenameEscaped];
}

/* Signed */
- (nullable NSString *)DCCTransferAddress
{
	NSString *address = [self fileTransferController].cachedIPAddress;

	if (address == nil) {
		return nil;
	}

	if (address.IPv6Address) {
		return address;
	}

	NSArray *addressOctets = [address componentsSeparatedByString:@"."];

	if (addressOctets.count != 4) {
		LogToConsoleError("User configured a silly IP address")

		return nil;
	}

	NSInteger w = [addressOctets[0] integerValue];
	NSInteger x = [addressOctets[1] integerValue];
	NSInteger y = [addressOctets[2] integerValue];
	NSInteger z = [addressOctets[3] integerValue];
	
	unsigned long long a = 0;
	
	a |= w; a <<= 8;
	a |= x; a <<= 8;
	a |= y; a <<= 8;
	a |= z;
	
	return [NSString stringWithFormat:@"%llu", a];
}

#pragma mark -
#pragma mark Command Queue (Signed)

/* Signed */
- (void)processCommandsInCommandQueue
{
	NSTimeInterval now = [NSDate timeIntervalSince1970];

	@synchronized(self.commandQueue) {
		while (self.commandQueue.count > 0) {
			IRCTimerCommandContext *command = self.commandQueue[0];

			if (command.timerInterval > now) {
				break;
			}

			[self.commandQueue removeObjectAtIndex:0];

			IRCChannel *channel = (IRCChannel *)[worldController() findItemWithId:command.channelId];

			[self sendCommand:command.rawInput completeTarget:YES target:channel.name];
		}

		if (self.commandQueue.count > 0) {
			IRCTimerCommandContext *command = self.commandQueue[0];

			NSTimeInterval delta = (command.timerInterval - [NSDate timeIntervalSince1970]);

			[self.commandQueueTimer start:delta];
		} else {
			[self.commandQueueTimer stop];
		}
	}
}

/* Signed */
- (void)addCommandToCommandQueue:(IRCTimerCommandContext *)commandIn
{
	NSParameterAssert(commandIn != nil);

	BOOL added = NO;

	NSUInteger i = 0;

	@synchronized(self.commandQueue) {
		for (IRCTimerCommandContext *command in self.commandQueue) {
			if (commandIn.timerInterval < command.timerInterval) {
				added = YES;

				[self.commandQueue insertObject:commandIn atIndex:i];

				break;
			}

			i++;
		}

		if (added == NO) {
			[self.commandQueue addObject:commandIn];
		}
	}

	if (i == 0) {
		[self processCommandsInCommandQueue];
	}
}

/* Signed */
- (void)clearCommandQueue
{
	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}

	[self.commandQueueTimer stop];
}

/* Signed */
- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark User Tracking

/* Signed */
- (void)notifyTrackingStatusOfNickname:(NSString *)nickname changedTo:(IRCAddressBookUserTrackingStatus)newStatus
{
	NSParameterAssert(nickname != nil);

	NSString *message = nil;

	if (newStatus == IRCAddressBookUserTrackingSignedOnStatus) {
		message = TXTLS(@"Notifications[1043]", nickname);
	} else if (newStatus == IRCAddressBookUserTrackingSignedOffStatus) {
		message = TXTLS(@"Notifications[1042]", nickname);
	} else if (newStatus == IRCAddressBookUserTrackingIsAvailalbeStatus) {
		message = TXTLS(@"Notifications[1041]", nickname);
	}

	if (message == nil) {
		return;
	}

	[self notifyEvent:TXNotificationAddressBookMatchType lineType:TVCLogLineNoticeType target:nil nickname:nickname text:message];
}

/* Signed */
- (void)populateISONTrackedUsersList
{
#warning TODO: Support MONITOR instead of WATCH

	if (self.isLoggedIn == NO) {
		return;
	}

	/* Additions & Removels for WATCH command. ISON does not access these. */
	BOOL usesWatchCommand = [self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand];

	NSMutableArray<NSString *> *watchAdditions = [NSMutableArray array];
	NSMutableArray<NSString *> *watchRemovals = [NSMutableArray array];

	@synchronized (self.trackedNicknames) {
		/* Compare configuration to the list of tracked nicknames.
		 * Nicknames that are new are added to watchAdditions */
		NSMutableDictionary<NSString *, NSNumber *> *trackedNicknamesNew = [NSMutableDictionary dictionary];

		for (IRCAddressBookEntry *g in self.config.ignoreList) {
			if (g.entryType != IRCAddressBookUserTrackingEntryType) {
				continue;
			} else if (g.trackUserActivity == NO) {
				continue;
			}

			NSString *trackingNickname = g.trackingNickname;

			/* If this nickname is already tracked, then there is nothing
			 further to do at this time. */
			NSNumber *trackingStatus = self.trackedNicknames[trackingNickname];

			if (trackingStatus) {
				trackedNicknamesNew[trackingNickname] = trackingStatus;

				continue;
			}

			/* Add new entry for nickname not already tracked */
			trackedNicknamesNew[trackingNickname] = @(NO);
					
			if (usesWatchCommand) {
				[watchAdditions addObject:trackingNickname];
			}
		}

		if (usesWatchCommand) {
			/* Compare old list of tracked nicknames to new list to find
			 those that no longer appear. Mark those for removal. */
			for (NSString *trackedNickname in self.trackedNicknames) {
				if ([trackedNicknamesNew containsKey:trackedNickname]) {
					continue;
				}

				[watchRemovals addObject:trackedNickname];
			}
		}

		/* Set new entries */
		[self.trackedNicknames removeAllObjects];

		[self.trackedNicknames addEntriesFromDictionary:trackedNicknamesNew];
	}

	[self modifyWatchListBy:YES nicknames:watchAdditions];

	[self modifyWatchListBy:NO nicknames:watchRemovals];

	[self startISONTimer];
}

/* Signed */
- (void)startISONTimer
{
	if (self.isonTimer.timerIsActive) {
		return;
	}

	[self.isonTimer start:_isonCheckInterval];
}

/* Signed */
- (void)stopISONTimer
{
	if (self.isonTimer.timerIsActive == NO) {
		return;
	}

	[self.isonTimer stop];
	
	@synchronized(self.trackedNicknames) {
		[self.trackedNicknames removeAllObjects];
	}
}

/* Signed */
- (void)onISONTimer:(id)sender
{
	if (self.isLoggedIn == NO || self.isBrokenIRCd_aka_Twitch) {
		return;
	}

	NSArray *channelList = self.channelList;

	[self sendTimedWhoRequestsToChannels:channelList];

	// Request ISON status for private messages
	NSMutableArray<NSString *> *nicknames = [NSMutableArray array];

	for (IRCChannel *channel in self.channelList) {
		if (channel.privateMessage) {
			[nicknames addObject:channel.name];
		}
	}

	[self sendIsonForNicknames:nicknames];

	// Request ISON status for tracked users
	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand]) {
		return;
	}

	[nicknames removeAllObjects];

	@synchronized(self.trackedNicknames) {
		for (NSString *trackedNickname in self.trackedNicknames) {
			[nicknames addObject:trackedNickname];
		}
	}

	[self sendIsonForNicknames:nicknames];
}

- (void)sendTimedWhoRequestsToChannels:(NSArray<IRCChannel *> *)channelList
{
	NSParameterAssert(channelList != nil);

	if (self.isLoggedIn == NO || self.isBrokenIRCd_aka_Twitch) {
		return;
	}

#define _maximumChannelCountPerWhoBatchRequest			5
#define _maximumSingleChannelSizePerWhoBatchRequest		5000
#define _maximumTotalChannelSizePerWhoBatchRequest		2000

	NSUInteger channelCount = channelList.count;

	if (channelCount == 0) {
		return;
	}

	NSUInteger startingPosition = self.lastWhoRequestChannelListIndex;

	NSUInteger endingPosition = (startingPosition + _maximumChannelCountPerWhoBatchRequest);

	if (startingPosition >= channelCount) {
		startingPosition = 0;
	}

	if (endingPosition >= channelCount) {
		endingPosition = (channelCount - 1);
	}

	NSUInteger totalMemberCount = 0;

	NSMutableArray<IRCChannel *> *channelsToQuery = nil;

	for (NSUInteger channelIndex = startingPosition; channelIndex <= endingPosition; channelIndex++) {
		IRCChannel *channel = channelList[channelIndex];

		if (channel.isActive == NO || channel.isChannel == NO) {
			continue;
		}

		/* Update internal state of flag */
		BOOL sentInitialWhoRequest = channel.sentInitialWhoRequest;

		if (sentInitialWhoRequest == NO) {
			channel.sentInitialWhoRequest = YES;
		}

		/* continue to next channel and do not break so that the
		 -sentInitialWhoRequest flag of all channels can be updated. */
		if (self.config.sendWhoCommandRequestsToChannels == NO) {
			continue;
		}

		/* Perform comparisons to know whether channel is acceptable */
		NSUInteger numberOfMembers = channel.numberOfMembers;

		if (sentInitialWhoRequest == NO) {
			if (numberOfMembers > _maximumSingleChannelSizePerWhoBatchRequest) {
				continue;
			}
		} else {
			if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityAwayNotify]) {
				continue;
			}

			if (numberOfMembers > [TPCPreferences trackUserAwayStatusMaximumChannelSize]) {
				continue;
			}
		}

		/* Add channel to list */
		if (channelsToQuery == nil) {
			channelsToQuery = [NSMutableArray new];
		}

		[channelsToQuery addObject:channel];

		/* Update total number of members and maybe break loop */
		totalMemberCount += numberOfMembers;

		if (totalMemberCount > _maximumTotalChannelSizePerWhoBatchRequest) {
			endingPosition = channelIndex;

			break;
		}
	}

	self.lastWhoRequestChannelListIndex = (endingPosition + 1);

	/* Send WHO requests */
	if (channelsToQuery == nil) {
		return;
	}

	for (IRCChannel *channel in channelsToQuery) {
		[self sendWhoToChannel:channel];
	}

#undef _maximumChannelCountPerWhoBatchRequest
#undef _maximumSingleChannelSizePerWhoBatchRequest
#undef _maximumTotalChannelSizePerWhoBatchRequest
}

/* Signed */
- (void)updateUserTrackingStatusForEntry:(IRCAddressBookEntry *)addressBookEntry withMessage:(IRCMessage *)message
{
	NSParameterAssert(addressBookEntry != nil);
	NSParameterAssert(message != nil);

	if ([self isCapacityEnabled:ClientIRCv3SupportedCapacityWatchCommand]) {
		return;
	}
	
    NSString *trackingNickname = addressBookEntry.trackingNickname;

	@synchronized(self.trackedNicknames) {
		BOOL ison = [self.trackedNicknames[trackingNickname] boolValue];
		
		/* Notification Type: JOIN Command */
		if ([message.command isEqualIgnoringCase:@"JOIN"]) {
			if (ison == NO) {
				self.trackedNicknames[trackingNickname] = @(YES);

				[self notifyTrackingStatusOfNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOnStatus];
			}
			
			return;
		}
		
		/* Notification Type: QUIT Command */
		if ([message.command isEqualIgnoringCase:@"QUIT"]) {
			if (ison) {
				self.trackedNicknames[trackingNickname] = @(NO);

				[self notifyTrackingStatusOfNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOffStatus];
			}
			
			return;
		}
		
		/* Notification Type: NICK Command */
		if ([message.command isEqualIgnoringCase:@"NICK"]) {
			if (ison) {
				[self notifyTrackingStatusOfNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOffStatus];
			} else {
				[self notifyTrackingStatusOfNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOnStatus];
			}

			self.trackedNicknames[trackingNickname] = @(ison == NO);

			return;
		}
	}
}

#pragma mark -
#pragma mark Channel Ban List Dialog (Signed)

/* Signed */
- (void)createChannelInviteExceptionListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetInviteExceptionEntryType];
}

/* Signed */
- (void)createChannelBanExceptionListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetBanExceptionEntryType];
}

/* Signed */
- (void)createChannelBanListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetBanEntryType];
}

/* Signed */
- (void)createChannelBanListSheet:(TDCChannelBanListSheetEntryType)entryType
{
	[windowController() popMainWindowSheetIfExists];

    IRCChannel *c = mainWindow().selectedChannel;

	if (c == nil) {
		return;
	}

	TDCChannelBanListSheet *listSheet = [[TDCChannelBanListSheet alloc] initWithEntryType:entryType inChannel:c];

	listSheet.delegate = (id)self;

	listSheet.window = mainWindow();

	[listSheet start];

	[windowController() addWindowToWindowList:listSheet];
}

/* Signed */
- (void)channelBanListSheetOnUpdate:(TDCChannelBanListSheet *)sender
{
	IRCChannel *channel = sender.channel;

	if (channel == nil) {
		return;
	}

	NSString *modeSend = [NSString stringWithFormat:@"+%@", sender.modeSymbol];

	[self sendModes:modeSend withParamatersString:nil inChannel:channel];
}

/* Signed */
- (void)channelBanListSheetWillClose:(TDCChannelBanListSheet *)sender
{
	IRCChannel *channel = sender.channel;

	if (channel == nil) {
		return;
	}

	NSArray *listOfChanges = sender.listOfChanges;
	
	for (NSString *change in listOfChanges) {
		[self sendModes:change withParamatersString:nil inChannel:channel];
	}

	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Network Channel List Dialog (Signed)

/* Signed */
- (NSString *)channelListDialogWindowKey
{
	return [NSString stringWithFormat:@"TDCServerChannelListDialog -> %@", self.uniqueIdentifier];
}

/* Signed */
- (nullable TDCServerChannelListDialog *)channelListDialog
{
	return [windowController() windowFromWindowList:[self channelListDialogWindowKey]];
}

/* Signed */
- (void)createChannelListDialog
{
	if ([windowController() maybeBringWindowForward:[self channelListDialogWindowKey]]) {
		return; // The window was brought forward already.
	}

	TDCServerChannelListDialog *channelListDialog = [[TDCServerChannelListDialog alloc] initWithClient:self];

	channelListDialog.delegate = (id)self;
    
    [channelListDialog show];

	[windowController() addWindowToWindowList:channelListDialog withDescription:[self channelListDialogWindowKey]];
}

/* Signed */
- (void)serverChannelListDialogOnUpdate:(TDCServerChannelListDialog *)sender
{
	[self requestChannelList];
}

/* Signed */
- (void)serverChannelListDialog:(TDCServerChannelListDialog *)sender joinChannel:(NSString *)channel
{
	[self enableInUserInvokedCommandProperty:&self->_inUserInvokedJoinRequest];
	
	[self joinUnlistedChannel:channel];
}

/* Signed */
- (void)serverChannelDialogWillClose:(TDCServerChannelListDialog *)sender
{
	[windowController() removeWindowFromWindowList:[self channelListDialogWindowKey]];
}

@end

NS_ASSUME_NONNULL_END
