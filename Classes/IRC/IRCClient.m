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

#import "NSObjectHelperPrivate.h"
#import "NSStringHelper.h"
#import "GCDAsyncSocketExtensions.h"
#import "TPCApplicationInfo.h"
#import "TPCPathInfo.h"
#import "TPCPreferencesCloudSyncExtension.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TPCResourceManager.h"
#import "TPCThemeController.h"
#import "TPCThemeSettings.h"
#import "THOPluginDispatcherPrivate.h"
#import "THOPluginManagerPrivate.h"
#import "THOPluginProtocol.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOEncryptionManagerPrivate.h"
#import "TLOGrowlControllerPrivate.h"
#import "TLOFileLoggerPrivate.h"
#import "TLOInputHistoryPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TLOpenLink.h"
#import "TLOPopupPrompts.h"
#import "TLOSoundPlayer.h"
#import "TLOSpeechSynthesizerPrivate.h"
#import "TLOSpokenNotificationPrivate.h"
#import "TLOTimer.h"
#import "TXGlobalModelsPrivate.h"
#import "TXMasterControllerPrivate.h"
#import "TXMenuControllerPrivate.h"
#import "TXWindowControllerPrivate.h"
#import "TVCDockIconPrivate.h"
#import "TVCLogControllerPrivate.h"
#import "TVCLogControllerInlineMediaServicePrivate.h"
#import "TVCLogControllerOperationQueuePrivate.h"
#import "TVCLogRenderer.h"
#import "TVCLogViewPrivate.h"
#import "TVCMainWindowPrivate.h"
#import "TVCMainWindowTextViewPrivate.h"
#import "TVCServerListPrivate.h"
#import "TDCChannelBanListSheetPrivate.h"
#import "TDCFileTransferDialogPrivate.h"
#import "TDCFileTransferDialogTransferControllerPrivate.h"
#import "TDCInAppPurchaseDialogPrivate.h"
#import "TDCServerChannelListDialogPrivate.h"
#import "TDCServerHighlightListSheetPrivate.h"
#import "IRC.h"
#import "IRCAddressBook.h"
#import "IRCAddressBookUserTrackingPrivate.h"
#import "IRCChannelConfig.h"
#import "IRCChannelModePrivate.h"
#import "IRCChannelUserPrivate.h"
#import "IRCChannelPrivate.h"
#import "IRCClientConfigPrivate.h"
#import "IRCColorFormatPrivate.h"
#import "IRCConnectionPrivate.h"
#import "IRCConnectionConfig.h"
#import "IRCExtrasPrivate.h"
#import "IRCHighlightLogEntryPrivate.h"
#import "IRCHighlightMatchCondition.h"
#import "IRCISupportInfoPrivate.h"
#import "IRCMessagePrivate.h"
#import "IRCMessageBatchPrivate.h"
#import "IRCModeInfo.h"
#import "IRCSendingMessage.h"
#import "IRCServerPrivate.h"
#import "IRCTimerCommandPrivate.h"
#import "IRCTreeItemPrivate.h"
#import "IRCUserPrivate.h"
#import "IRCUserRelationsPrivate.h"
#import "IRCWorldPrivate.h"
#import "IRCWorldPrivateCloudExtension.h"
#import "IRCClientPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _autojoinDelayedWarningInterval		90
#define _autojoinDelayedWarningMaxCount		3

#define _isonCheckInterval			30
#define _pingInterval				270
#define _pongCheckInterval			30
#define _reconnectInterval			20
#define _retryInterval				240
#define _timeoutInterval			360
#define _whoCheckInterval			120

NSString * const IRCClientConfigurationWasUpdatedNotification = @"IRCClientConfigurationWasUpdatedNotification";

NSString * const IRCClientChannelListWasModifiedNotification = @"IRCClientChannelListWasModifiedNotification";

NSString * const IRCClientWillConnectNotification = @"IRCClientWillConnectNotification";
NSString * const IRCClientDidConnectNotification = @"IRCClientDidConnectNotification";

NSString * const IRCClientWillSendQuitNotification = @"IRCClientWillSendQuitNotification";
NSString * const IRCClientWillDisconnectNotification = @"IRCClientWillDisconnectNotification";
NSString * const IRCClientDidDisconnectNotification = @"IRCClientDidDisconnectNotification";

NSString * const IRCClientUserNicknameChangedNotification = @"IRCClientUserNicknameChangedNotification";

@interface IRCClient ()
// Properies that are public in IRCClient.h
@property (nonatomic, copy, readwrite) IRCClientConfig *config;
@property (nonatomic, copy, readwrite, nullable) IRCServer *server;
@property (nonatomic, strong, readwrite) IRCISupportInfo *supportInfo;
@property (nonatomic, assign, readwrite) BOOL isAutojoined;
@property (nonatomic, assign, readwrite) BOOL isAutojoining;
@property (nonatomic, assign, readwrite) BOOL isConnecting;
@property (nonatomic, assign, readwrite) BOOL isConnected;
@property (nonatomic, assign, readwrite) BOOL isConnectedToZNC;
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, assign, readwrite) BOOL isQuitting;
@property (nonatomic, assign, readwrite) BOOL isDisconnecting;
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
@property (nonatomic, assign, readwrite) ClientIRCv3SupportedCapabilities capabilities;
@property (nonatomic, copy, readwrite) NSArray<IRCHighlightLogEntry *> *cachedHighlights;
@property (nonatomic, copy, readwrite, nullable) NSString *userHostmask;
@property (nonatomic, copy, readwrite) NSString *userNickname;
@property (nonatomic, copy, readwrite) NSString *serverAddress;
@property (nonatomic, copy, readwrite, nullable) NSString *preAwayUserNickname;

// Properties private
@property (nonatomic, assign) BOOL configurationIsStale;
@property (nonatomic, strong, nullable) IRCConnection *socket;
@property (nonatomic, strong) IRCMessageBatchMessageContainer *batchMessages;
@property (nonatomic, strong, nullable) TLOFileLogger *logFile;
@property (nonatomic, strong) TLOTimer *autojoinTimer;
@property (nonatomic, strong) TLOTimer *autojoinDelayedWarningTimer;
@property (nonatomic, strong) TLOTimer *commandQueueTimer;
@property (nonatomic, strong) TLOTimer *isonTimer;
@property (nonatomic, strong) TLOTimer *pongTimer;
@property (nonatomic, strong) TLOTimer *reconnectTimer;
@property (nonatomic, strong) TLOTimer *retryTimer;
@property (nonatomic, strong) TLOTimer *whoTimer;
@property (nonatomic, weak) IRCChannel *lagCheckDestinationChannel;
@property (nonatomic, assign) BOOL capabilityNegotiationIsPaused;
@property (nonatomic, assign) BOOL invokingISONCommandForFirstTime;
@property (nonatomic, assign) BOOL isTerminating; // Is being destroyed
@property (nonatomic, assign) BOOL reconnectEnabled;
@property (nonatomic, assign) BOOL reconnectEnabledBecauseOfSleepMode;
@property (nonatomic, assign) BOOL timeoutWarningShownToUser;
@property (nonatomic, assign) BOOL zncBoucnerIsSendingCertificateInfo;
@property (nonatomic, assign) BOOL zncBouncerIsPlayingBackHistory;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *capabilitiesPending;
@property (nonatomic, assign) NSTimeInterval lagCheckLastCheck;
@property (nonatomic, assign) NSUInteger connectDelay;
@property (nonatomic, assign) NSUInteger lastServerSelected;
@property (nonatomic, assign) NSUInteger lastWhoRequestChannelListIndex;
@property (nonatomic, assign) NSUInteger successfulConnects;
@property (nonatomic, assign) NSUInteger tryingNicknameNumber;
@property (nonatomic, assign) NSUInteger autojoinDelayedWarningCount;
@property (nonatomic, copy, nullable) NSString *tryingNicknameSentNickname;
@property (nonatomic, strong) NSMutableArray<IRCChannel *> *channelListPrivate;
@property (nonatomic, strong) NSMutableArray<IRCChannel *> *channelsToAutojoin;
@property (nonatomic, strong) NSMutableArray<IRCTimerCommandContext *> *commandQueue;
@property (nonatomic, strong) IRCAddressBookUserTrackingContainer *trackedUsers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, IRCUser *> *userListPrivate;
@property (nonatomic, strong, nullable) NSMutableString *zncBouncerCertificateChainDataMutable;
@property (nonatomic, copy) NSString *temporaryServerAddressOverride;
@property (nonatomic, assign) uint16_t temporaryServerPortOverride;
@property (readonly) BOOL isBrokenIRCd_aka_Twitch;
@property (readonly) BOOL monitorAwayStatus;
@property (readonly) BOOL supportsAdvancedTracking;
@property (readonly, copy) NSArray<NSString *> *nickServSupportedNeedIdentificationTokens;
@property (readonly, copy) NSArray<NSString *> *nickServSupportedSuccessfulIdentificationTokens;
@property (nonatomic, strong, nullable) IRCChannel *rawDataLogQuery;

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
@property (nonatomic, strong, nullable) TLOTimer *softwareTrialTimer;
#endif
@end

@implementation IRCClient

#pragma mark -
#pragma mark Initialization

ClassWithDesignatedInitializerInitMethod

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	IRCClientConfig *config = [[IRCClientConfig alloc] initWithDictionary:dic];

	return [self initWithConfig:config];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

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

- (void)prepareInitialState
{
	self.batchMessages = [IRCMessageBatchMessageContainer new];

	self.supportInfo = [[IRCISupportInfo alloc] initWithClient:self];

	self.connectType = IRCClientConnectNormalMode;
	self.disconnectType = IRCClientDisconnectNormalMode;

	self.cachedHighlights = @[];

	self.capabilitiesPending = [NSMutableArray array];
	self.channelListPrivate = [NSMutableArray array];
	self.commandQueue = [NSMutableArray array];

	self.userListPrivate = [NSMutableDictionary dictionary];

	self.trackedUsers = [[IRCAddressBookUserTrackingContainer alloc] initWithClient:self];

	self.lastMessageServerTime = self.config.lastMessageServerTime;

	self.lastServerSelected = NSNotFound;

	self.autojoinTimer = [TLOTimer new];
	self.autojoinTimer.repeatTimer = YES;
	self.autojoinTimer.target = self;
	self.autojoinTimer.action = @selector(onAutojoinTimer:);

	self.autojoinDelayedWarningTimer = [TLOTimer new];
	self.autojoinDelayedWarningTimer.repeatTimer = YES;
	self.autojoinDelayedWarningTimer.target = self;
	self.autojoinDelayedWarningTimer.action = @selector(onAutojoinDelayedWarningTimer:);

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

	self.whoTimer = [TLOTimer new];
	self.whoTimer.repeatTimer = YES;
	self.whoTimer.target = self;
	self.whoTimer.action = @selector(onWhoTimer:);

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	self.softwareTrialTimer = [TLOTimer new];
	self.softwareTrialTimer.repeatTimer = NO;
	self.softwareTrialTimer.target = self;
	self.softwareTrialTimer.action = @selector(onSoftwareTrialTimer:);
#endif

	[RZNotificationCenter() addObserver:self selector:@selector(willDestroyChannel:) name:IRCWorldWillDestroyChannelNotification object:nil];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[RZNotificationCenter() addObserver:self selector:@selector(onInAppPurchaseTransactionFinished:) name:TDCInAppPurchaseDialogTransactionFinishedNotification object:nil];
#endif
}

- (void)dealloc
{
	[RZNotificationCenter() removeObserver:self];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[self.softwareTrialTimer stop];
	self.softwareTrialTimer = nil;
#endif

	[self.autojoinTimer stop];
	[self.autojoinDelayedWarningTimer stop];
	[self.commandQueueTimer stop];
	[self.isonTimer	stop];
	[self.pongTimer	stop];
	[self.reconnectTimer stop];
	[self.retryTimer stop];
	[self.whoTimer stop];

	self.autojoinTimer = nil;
	self.autojoinDelayedWarningTimer = nil;
	self.commandQueueTimer = nil;
	self.isonTimer = nil;
	self.pongTimer = nil;
	self.reconnectTimer = nil;
	self.retryTimer = nil;
	self.whoTimer = nil;

	self.batchMessages = nil;
	self.cachedHighlights = nil;
	self.channelListPrivate = nil;
	self.channelsToAutojoin = nil;
	self.commandQueue = nil;
	self.logFile = nil;
	self.socket = nil;
	self.supportInfo = nil;
	self.trackedUsers = nil;
	self.userListPrivate = nil;

	[self cancelPerformRequests];
}

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

- (void)updateConfig:(IRCClientConfig *)config
{
	[self updateConfig:config updateSelection:YES];
}

- (void)updateConfig:(IRCClientConfig *)config updateSelection:(BOOL)updateSelection
{
	[self updateConfig:config updateSelection:updateSelection importingFromCloud:NO];
}

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
			LogToConsoleError("Tried to load configuration for incorrect client");

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
			if (channel.isChannel == NO) {
				[channelListNew addObject:channel];
			} else {
				[worldController() destroyChannel:channel reload:NO];
			}
		}

		/* Save updated channel list then safe its contents */
		self.channelList = channelListNew;
	}

	/* Update server list */
	{
		/* To update the server list, we first make a map of all existing
		 servers in a dictionary with the key as the identifier and the
		 object is the server itself. */
		NSArray *serverListOld = currentConfig.serverList;

		NSMutableDictionary<NSString *, IRCServer *> *serverListOldMap =
		[[NSMutableDictionary alloc] initWithCapacity:serverListOld.count];

		for (IRCServer *server in serverListOld) {
			serverListOldMap[server.uniqueIdentifier] = server;
		}

		/* We then make a map of the new server list */
		NSArray *serverListNew = self.config.serverList;

		NSMutableDictionary<NSString *, IRCServer *> *serverListNewMap =
		[[NSMutableDictionary alloc] initWithCapacity:serverListNew.count];

		for (IRCServer *server in serverListNew) {
			serverListNewMap[server.uniqueIdentifier] = server;
		}

		/* Record information about the current server (if any). */
		IRCServer *serverInUse = self.server;

		NSString *uniqueIdentifierInUse = serverInUse.uniqueIdentifier;

		/* Enumerate old server list */
		/* If an old server no longer appears in the new list of identifiers,
		 then we destroy its keychain items. If the server is the active server,
		 then we mark the keychain items to be destroyed later, incase they
		 need to be reused by IRCClient. */
		[serverListOldMap enumerateKeysAndObjectsUsingBlock:^(NSString *uniqueIdentifier, IRCServer *server, BOOL *stop) {
			if ([serverListNewMap containsKey:uniqueIdentifier]) {
				return;
			}

			if ([uniqueIdentifier isEqualToString:uniqueIdentifierInUse]) {
				serverInUse.destroyKeychainItemsDuringDealloc = YES;
			} else {
				[server destroyServerPasswordKeychainItem];
			}
		}];

		/* Enumerate new server list */
		/* All servers in the new server list have their keychain item written. */
		if (serverListNew.count == 0) {
			self.lastServerSelected = NSNotFound;
		} else {
			[serverListNewMap enumerateKeysAndObjectsUsingBlock:^(NSString *uniqueIdentifier, IRCServer *server, BOOL *stop) {
				[server writeServerPasswordToKeychain];
			}];
		}
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

	[self destroyServerPasswordKeychainItemAfterMigration];

	/* Update main window title */
	[mainWindow() updateTitleFor:self];

	/* Rebuild list of users that are ignored and/or tracked */
	[self populateISONTrackedUsersList];

	/* Post notification */
	[RZNotificationCenter() postNotificationName:IRCClientConfigurationWasUpdatedNotification object:self];
}

- (void)reloadServerListItems
{
	mainWindow().ignoreOutlineViewSelectionChanges = YES;

	[mainWindowServerList() beginUpdates];

	[mainWindowServerList() reloadItem:self reloadChildren:YES];

	[mainWindowServerList() endUpdates];

	[mainWindow() adjustSelection];

	mainWindow().ignoreOutlineViewSelectionChanges = NO;
}

- (void)writePasswordsToKeychain
{
	[self.config writeNicknamePasswordToKeychain];
	[self.config writeProxyPasswordToKeychain];
}

- (void)destroyServerPasswordKeychainItemAfterMigration
{
	[self.config destroyServerPasswordKeychainItemAfterMigration];
}

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

- (void)updateStoredChannelList
{
	/* Rebuild list of channel configurations */
	NSMutableArray<IRCChannelConfig *> *channelList = [NSMutableArray array];

	for (IRCChannel *channel in self.channelList) {
		if (channel.isUtility) {
			continue;
		}

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

- (NSDictionary<NSString *, id> *)configurationDictionary
{
	[self updateStoredConfiguration];

	return [self.config dictionaryValue];
}

- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud
{
	[self updateStoredConfiguration];

	return [self.config dictionaryValueForCloud];
}

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

	[self clearEventsToSpeak];

	[self clearTrackedUsers];

	for (IRCChannel *c in self.channelList) {
		[c prepareForApplicationTermination];
	}

	[self.viewController prepareForApplicationTermination];

	masterController().terminatingClientCount -= 1;
}

- (void)prepareForPermanentDestruction
{
	self.isTerminating = YES;

//	[self disconnect];	// Disconnect is called by IRCWorld for us

	[self closeDialogs];

	[self closeLogFile];

	[self clearEventsToSpeak];

	[self clearTrackedUsers];

	[self.config destroyNicknamePasswordKeychainItem];
	[self.config destroyProxyPasswordKeychainItem];

	[self destroyServerPasswordsKeychainItems];

	for (IRCChannel *c in self.channelList) {
		[c prepareForPermanentDestruction];
	}

	[[mainWindow() inputHistoryManager] destroy:self];

	[self.viewController prepareForPermanentDestruction];
}

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

- (void)preferencesChanged
{
	for (IRCChannel *c in self.channelList) {
		[c preferencesChanged];
	}

	if (self.monitorAwayStatus == NO) {
		[self resetAwayStatusForUsers];
	}
}

- (void)willDestroyChannel:(NSNotification *)notification
{
	IRCChannel *channel = notification.object;

	if (channel.associatedClient != self) {
		return;
	}

	[self zncPlaybackClearChannel:channel];

	if (self.rawDataLogQuery == channel) {
		self.rawDataLogQuery = nil;
	}
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	/* Implement this method to allow client to be
	 used as a dictionary key. */

	return self;
}

#pragma mark -
#pragma mark Servers

- (void)enumerateServers:(void (NS_NOESCAPE ^)(IRCServer *server, NSUInteger idnex, BOOL *stop))block
{
	[self.config.serverList enumerateObjectsUsingBlock:block];
}

- (void)writeServerPasswordsToKeychain
{
	[self enumerateServers:^(IRCServer *server, NSUInteger idnex, BOOL *stop) {
		[server writeServerPasswordToKeychain];
	}];
}

- (void)destroyServerPasswordsKeychainItems
{
	[self enumerateServers:^(IRCServer *server, NSUInteger idnex, BOOL *stop) {
		[server destroyServerPasswordKeychainItem];
	}];
}

#pragma mark -
#pragma mark Properties

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCClient [%@]: %@>", self.networkNameAlt, self.serverAddress];
}

- (NSString *)uniqueIdentifier
{
	return self.config.uniqueIdentifier;
}

- (NSString *)name
{
	return self.config.connectionName;
}

- (nullable NSString *)networkName
{
	return self.supportInfo.networkNameFormatted;
}

- (NSString *)networkNameAlt
{
	NSString *networkName = self.networkName;

	if (networkName) {
		return networkName;
	}

	return self.config.connectionName;
}

- (nullable NSString *)serverAddress
{
	NSString *serverAddress = self.supportInfo.serverAddress;

	if (serverAddress) {
		return serverAddress;
	}

	NSString *serverAddressOnSocket = self.socket.config.serverAddress;

	if (serverAddressOnSocket) {
		return serverAddressOnSocket;
	}

	return self.server.serverAddress;
}

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

- (TDCFileTransferDialog *)fileTransferController
{
	return [TXSharedApplication sharedFileTransferDialog];
}

- (BOOL)isReconnecting
{
	return self.reconnectTimer.timerIsActive;
}

- (void)setSidebarItemIsExpanded:(BOOL)sidebarItemIsExpanded
{
	/* This is a non-critical property that can be saved periodically */
	if (self->_sidebarItemIsExpanded != sidebarItemIsExpanded) {
		self->_sidebarItemIsExpanded = sidebarItemIsExpanded;

		self.configurationIsStale = YES;

		[worldController() savePeriodically];
	}
}

- (void)setLastMessageServerTime:(NSTimeInterval)lastMessageServerTime
{
	/* This is a non-critical property that can be saved periodically */
	if (self->_lastMessageServerTime != lastMessageServerTime) {
		self->_lastMessageServerTime = lastMessageServerTime;

		self.configurationIsStale = YES;

		[worldController() savePeriodically];
	}
}

- (BOOL)isSecured
{
	if (self.socket) {
		return self.socket.isSecured;
	}

	return NO;
}

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

- (BOOL)isBrokenIRCd_aka_Twitch
{
	return [self.serverAddress hasSuffix:@".twitch.tv"];
}

- (BOOL)supportsAdvancedTracking
{
	return ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityMonitorCommand] ||
			[self isCapabilityEnabled:ClientIRCv3SupportedCapabilityWatchCommand]);
}

- (BOOL)monitorAwayStatus
{
	return ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityAwayNotify] ||
			[TPCPreferences trackUserAwayStatusMaximumChannelSize] > 0);
}

#pragma mark -
#pragma mark Standalone Utilities

- (BOOL)messageIsFromMyself:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	return [self nicknameIsMyself:message.senderNickname];
}

- (BOOL)nicknameIsMyself:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	return [self.userNickname isEqualIgnoringCase:nickname];
}

- (BOOL)stringIsNickname:(NSString *)string
{
	NSParameterAssert(string != nil);

	return ([string isHostmaskNicknameOn:self] && [string isChannelNameOn:self] == NO);
}

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

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet parameterString:(NSString *)parameterString
{
	return [self compileListOfModeChangesForModeSymbol:modeSymbol modeIsSet:modeIsSet parameterString:parameterString characterSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet parameterString:(NSString *)parameterString characterSet:(NSCharacterSet *)characterList
{
	NSParameterAssert(parameterString != nil);
	NSParameterAssert(characterList != nil);

	NSArray *modeParameters = [parameterString componentsSeparatedByCharactersInSet:characterList];

	return [self compileListOfModeChangesForModeSymbol:modeSymbol modeIsSet:modeIsSet modeParameters:modeParameters];
}

- (NSArray<NSString *> *)compileListOfModeChangesForModeSymbol:(NSString *)modeSymbol modeIsSet:(BOOL)modeIsSet modeParameters:(NSArray<NSString *> *)modeParameters
{
	NSParameterAssert(modeSymbol.length == 1);
	NSParameterAssert(modeParameters != nil);

	if (modeParameters.count == 0) {
		return @[];
	}

	NSMutableArray<NSString *> *listOfChanges = [NSMutableArray array];

	NSMutableString *modeSetString = [NSMutableString string];
	NSMutableString *modeParamString = [NSMutableString string];

	NSUInteger numberOfEntries = 0;

	for (NSString *modeParameter in modeParameters) {
		if (modeParameter.length == 0) {
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

		[modeParamString appendFormat:@" %@", modeParameter];

		numberOfEntries += 1;

		if (numberOfEntries == self.supportInfo.maximumModeCount) {
			numberOfEntries = 0;

			NSString *modeSetCombined = [modeSetString stringByAppendingString:modeParamString];

			[listOfChanges addObject:modeSetCombined];

			[modeSetString setString:@""];
			[modeParamString setString:@""];
		}
	}

	if (modeSetString.length > 0 && modeParamString.length > 0) {
		NSString *modeSetCombined = [modeSetString stringByAppendingString:modeParamString];

		[listOfChanges addObject:modeSetCombined];
	}

	return [listOfChanges copy];
}

#pragma mark -
#pragma mark Highlights

- (void)clearCachedHighlights
{
	self.cachedHighlights = @[];
}

- (void)cacheHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(logLine != nil);

	if ([TPCPreferences logHighlights] == NO) {
		return;
	}

	/* Create entry */
	IRCHighlightLogEntryMutable *newEntry = [IRCHighlightLogEntryMutable new];

	newEntry.clientId = self.uniqueIdentifier;
	newEntry.channelId = channel.uniqueIdentifier;

	newEntry.lineLogged = logLine;

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
#pragma mark Reachability

- (void)noteReachabilityChanged:(BOOL)reachable
{
	if (reachable) {
		return;
	}

	[self disconnectOnReachabilityChange];
}

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

- (void)selectFirstChannelInChannelList
{
	NSArray *channelList = self.channelList;

	if (channelList.count == 0) {
		return;
	}

	[mainWindow() select:channelList[0]];
}

- (void)addChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized(self.channelListPrivate) {
		if ([self.channelListPrivate containsObject:channel]) {
			return;
		}

		/* Add channels atop of the first non-channel (private message).
		 Private messages can be add to the bottom of the array. */
		if (channel.isChannel == NO)
		{
			[self.channelListPrivate addObject:channel];
		}
		else
		{
			NSUInteger privateMessageIndex =
			[self.channelListPrivate indexOfObjectPassingTest:^BOOL(IRCChannel *object, NSUInteger index, BOOL *stop) {
				return (object.isChannel == NO);
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

- (void)removeChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized(self.channelListPrivate) {
		[self.channelListPrivate removeObjectIdenticalTo:channel];

		[self updateStoredChannelList];
	}
}

- (NSUInteger)indexOfChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized (self.channelListPrivate) {
		return [self.channelListPrivate indexOfObject:channel];
	}
}

- (NSUInteger)channelCount
{
	@synchronized (self.channelListPrivate) {
		return self.channelListPrivate.count;
	}
}

- (NSArray<IRCChannel *> *)channelList
{
	@synchronized (self.channelListPrivate) {
		return [self.channelListPrivate copy];
	}
}

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
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (BOOL)isActive
{
	return self.isLoggedIn;
}

- (nullable IRCClient *)associatedClient
{
	return self;
}

- (nullable IRCChannel *)associatedChannel
{
	return nil;
}

- (NSUInteger)numberOfChildren
{
	return self.channelCount;
}

- (id)childAtIndex:(NSUInteger)index
{
	return self.channelList[index];
}

- (NSString *)label
{
	__block BOOL usesUppercaseLabel = NO;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		usesUppercaseLabel = (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO);
	});

	if (usesUppercaseLabel) {
		return self.config.connectionName.uppercaseString;
	} else {
		return self.config.connectionName;
	}
}

#pragma mark -
#pragma mark Encoding

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
#pragma mark Ignore Matching

- (nullable IRCAddressBookEntry *)findIgnoreForHostmask:(NSString *)hostmask
{
	NSParameterAssert(hostmask != nil);

	for (IRCAddressBookEntry *g in self.config.ignoreList) {
		if (g.entryType != IRCAddressBookIgnoreEntryType) {
			continue;
		}

		if ([g checkMatch:hostmask] == NO) {
			continue;
		}

		return g;
	}

	return nil;
}

- (nullable IRCAddressBookEntry *)findAddressBookEntryForHostmask:(NSString *)hostmask withMatches:(NSArray<NSString *> *)matches
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
#pragma mark Output Rules

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
#pragma mark Encryption and Decryption

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
- (BOOL)encryptionAllowedForTarget:(NSString *)target
{
	return [self encryptionAllowedForTarget:target lenient:NO];
}

- (BOOL)encryptionAllowedForTarget:(NSString *)target lenient:(BOOL)lenient
{
	NSParameterAssert(target != nil);

	/* Encryption is disabled */
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return NO;
	}

	/* General rules */
	if ([self stringIsNickname:target] == NO) { // Do not allow channel names
		return NO;
	} else if ([self nicknameIsMyself:target] && lenient == NO) { // Do not allow the local user
		return NO;
	} else if ([self nicknameIsZNCUser:target] && lenient == NO) { // Do not allow a ZNC private user
		return NO;
	}

	/* Build context information for lookup */
	NSDictionary *exceptionRules = [self listOfNicknamesToDisallowEncryption];

	NSString *lowercaseNickname = target.lowercaseString;

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

- (NSUInteger)lengthOfEncryptedMessageDirectedAt:(NSString *)messageTo thatFitsWithinBounds:(NSUInteger)maximumLength
{
	return 0;
}

- (void)encryptMessage:(NSString *)messageBody directedAt:(NSString *)messageTo encodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)encodingCallback injectionCallback:(TLOEncryptionManagerInjectCallbackBlock)injectionCallback
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(messageTo != nil);
	NSParameterAssert(encodingCallback != nil);
	NSParameterAssert(injectionCallback != nil);

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user */
	if (messageBody.length == 0 || [self encryptionAllowedForTarget:messageTo] == NO) {
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

- (void)decryptMessage:(NSString *)messageBody from:(NSString *)messageFrom target:(NSString *)target decodingCallback:(TLOEncryptionManagerEncodingDecodingCallbackBlock)decodingCallback
{
	NSParameterAssert(messageBody != nil);
	NSParameterAssert(messageFrom != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(decodingCallback != nil);

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Check if we are accepting encryption from this user */
	if (messageBody.length == 0 || [self encryptionAllowedForTarget:target lenient:YES] == NO) {
#endif
		if (decodingCallback) {
			decodingCallback(messageBody, NO);
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		return;
	}

	/* Continue with normal encryption operations */
	[sharedEncryptionManager() decryptMessage:messageBody
										 from:[self encryptionAccountNameForUser:messageFrom]
										   to:[self encryptionAccountNameForLocalUser]
							 decodingCallback:decodingCallback];
#endif
}

- (void)encryptionAuthenticateUser:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	/* Encryption is disabled */
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return;
	}

	/* General rules */
	if ([self stringIsNickname:nickname] == NO) {
		return;
	}

	if ([self nicknameIsMyself:nickname]) {
		return;
	}

	/* Authenticate user */
	[sharedEncryptionManager() authenticateUser:[self encryptionAccountNameForUser:nickname]
										   from:[self encryptionAccountNameForLocalUser]];
#endif

}

#pragma mark -
#pragma mark Growl

- (nullable NSString *)formatNotificationToSpeak:(TLOSpokenNotification *)notification
{
	NSParameterAssert(notification != nil);

	if (self.isTerminating) {
		return nil;
	}

	NSString *formattedMessage = nil;

	TXNotificationType eventType = notification.notificationType;

	IRCChannel *channel = notification.channel;

	NSString *nickname = notification.nickname;

	NSString *text = notification.text;

	if (text) {
		text = text.trim;

		if ([TPCPreferences removeAllFormatting] == NO) {
			text = text.stripIRCEffects;
		}
	}

	switch (eventType) {
		case TXNotificationHighlightType:
		{
			NSParameterAssert(channel != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			if (text.length == 0) {
				break;
			}

			/* Highlights are spoken regardless of whether the user has configured
			 Channel Messages to be only spoken for selection. When the user has 
			 configured that preference, then we exclude the channel name at least
			 because that information is uninteresting. */
			/* For private messages, we speak everything, regardless of any preference. */
			BOOL isChannel = channel.isChannel;

			BOOL onlySpeakEventsForSelection = [TPCPreferences onlySpeakEventsForSelection];

			BOOL speakChannelName =
			/* 1 */	(isChannel == NO ||
			/* 2 */ (onlySpeakEventsForSelection == NO &&
					 [TPCPreferences channelMessageSpeakChannelName]) ||
			/* 2 */	(onlySpeakEventsForSelection &&
					 [mainWindow() isItemSelected:channel] == NO));

			BOOL speakNickname = (isChannel == NO ||
					[TPCPreferences channelMessageSpeakNickname]);

			NSMutableString *mutableMessage = [NSMutableString string];

			[mutableMessage appendString:TXTLS(@"Notifications[1003]")];

			if (speakChannelName || speakNickname) {
				if (speakChannelName) {
					if (isChannel) {
						[mutableMessage appendString:TXTLS(@"Notifications[1061]", channel.name.channelNameWithoutBang)]; // Channel
					} else {
						[mutableMessage appendString:TXTLS(@"Notifications[1062]")]; // Private Message
					}
				}

				if (speakNickname) {
					if (isChannel) {
						[mutableMessage appendString:TXTLS(@"Notifications[1063]", nickname)]; // by <nickname>
					} else {
						[mutableMessage appendString:TXTLS(@"Notifications[1064]", nickname)]; // from <nickname>
					}
				}

				[mutableMessage appendString:TXTLS(@"Notifications[1065]")];
			}

			[mutableMessage appendString:text];

			formattedMessage = [mutableMessage copy];

			break;
		}
		case TXNotificationChannelMessageType:
		case TXNotificationChannelNoticeType:
		{
			NSParameterAssert(channel != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			if (text.length == 0) {
				break;
			}

			BOOL onlySpeakEventsForSelection = [TPCPreferences onlySpeakEventsForSelection];

			BOOL channelIsSelected = [mainWindow() isItemSelected:channel];

			if (onlySpeakEventsForSelection && channelIsSelected == NO) {
				break;
			}

			BOOL speakChannelName = (onlySpeakEventsForSelection == NO &&
									 [TPCPreferences channelMessageSpeakChannelName]);

			BOOL speakNickname = [TPCPreferences channelMessageSpeakNickname];

			NSMutableString *mutableMessage = [NSMutableString string];

			if (speakChannelName || speakNickname) {
				if (eventType == TXNotificationChannelMessageType) {
					[mutableMessage appendString:TXTLS(@"Notifications[1001]")];
				} else if (eventType == TXNotificationChannelNoticeType) {
					[mutableMessage appendString:TXTLS(@"Notifications[1002]")];
				}

				if (speakChannelName) {
					[mutableMessage appendString:TXTLS(@"Notifications[1061]", channel.name.channelNameWithoutBang)];
				}

				if (speakNickname) {
					[mutableMessage appendString:TXTLS(@"Notifications[1063]", nickname)];
				}

				[mutableMessage appendString:TXTLS(@"Notifications[1065]")];
			}

			[mutableMessage appendString:text];

			formattedMessage = [mutableMessage copy];

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

			NSString *formatter = nil;

			if (eventType == TXNotificationNewPrivateMessageType) {
				formatter = @"Notifications[1006]";
			} else if (eventType == TXNotificationPrivateMessageType) {
				formatter = @"Notifications[1007]";
			} else if (eventType == TXNotificationPrivateNoticeType) {
				formatter = @"Notifications[1008]";
			}

			formattedMessage = TXTLS(formatter, nickname, text);

			break;
		}
		case TXNotificationKickType:
		{
			NSParameterAssert(channel != nil);
			NSParameterAssert(nickname != nil);

			NSString *formatter = @"Notifications[1005]";

			formattedMessage = TXTLS(formatter, channel.name.channelNameWithoutBang, nickname);

			break;
		}
		case TXNotificationInviteType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			NSString *formatter = @"Notifications[1004]";

			formattedMessage = TXTLS(formatter, text.channelNameWithoutBang, nickname);

			break;
		}
		case TXNotificationConnectType:
		case TXNotificationDisconnectType:
		{
			NSString *formatter = nil;

			if (eventType == TXNotificationConnectType) {
				formatter = @"Notifications[1009]";
			} else if (eventType == TXNotificationDisconnectType) {
				formatter = @"Notifications[1010]";
			}

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

			NSString *formatter = nil;

			if (eventType == TXNotificationFileTransferSendSuccessfulType) {
				formatter = @"Notifications[1011]";
			} else if (eventType == TXNotificationFileTransferReceiveSuccessfulType) {
				formatter = @"Notifications[1012]";
			} else if (eventType == TXNotificationFileTransferSendFailedType) {
				formatter = @"Notifications[1012]";
			} else if (eventType == TXNotificationFileTransferReceiveFailedType) {
				formatter = @"Notifications[1014]";
			} else if (eventType == TXNotificationFileTransferReceiveRequestedType) {
				formatter = @"Notifications[1015]";
			}

			formattedMessage = TXTLS(formatter, nickname);

			break;
		}
		case TXNotificationUserJoinedType:
		case TXNotificationUserPartedType:
		{
			NSParameterAssert(channel != nil);
			NSParameterAssert(nickname != nil);

			NSString *formatter = nil;

			if (eventType == TXNotificationUserJoinedType) {
				formatter = @"Notifications[1066]";
			} else if (eventType == TXNotificationUserPartedType) {
				formatter = @"Notifications[1068]";
			}

			formattedMessage = TXTLS(formatter, nickname, channel.name.channelNameWithoutBang);

			break;
		}
		case TXNotificationUserDisconnectedType:
		{
			NSParameterAssert(nickname != nil);

			NSString *formatter = @"Notifications[1081]";

			formattedMessage = TXTLS(formatter, nickname);

			break;
		}
	}

	return formattedMessage;
}

- (void)clearEventsToSpeak
{
	[[TXSharedApplication sharedSpeechSynthesizer] clearQueueForClient:self];
}

- (void)speakEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(null_unspecified IRCTreeItem *)target nickname:(null_unspecified NSString *)nickname text:(null_unspecified NSString *)text
{
	if ([sharedGrowlController() speakEvent:eventType inChannel:(IRCChannel *)target] == NO) {
		return;
	}

	if (target == nil) {
		target = self;
	}

	TLOSpokenNotification *notification =
	[[TLOSpokenNotification alloc] initWithNotification:eventType
											   lineType:lineType
												 target:target
											   nickname:nickname
												   text:text];

	[[TXSharedApplication sharedSpeechSynthesizer] speak:notification];
}

- (BOOL)notifyText:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(IRCChannel *)target nickname:(NSString *)nickname text:(NSString *)text
{
	return [self notifyEvent:eventType lineType:lineType target:target nickname:nickname text:text userInfo:nil];
}

- (BOOL)notifyEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType
{
	return [self notifyEvent:eventType lineType:lineType target:nil nickname:nil text:nil userInfo:nil];
}

- (BOOL)notifyEvent:(TXNotificationType)eventType lineType:(TVCLogLineType)lineType target:(null_unspecified IRCChannel *)target nickname:(null_unspecified NSString *)nickname text:(null_unspecified NSString *)text
{
	return [self notifyEvent:eventType lineType:lineType target:target nickname:nickname text:text userInfo:nil];
}

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

	if (target && text != nil) {
		if ([self outputRuleMatchedInMessage:text inChannel:target]) {
			return NO;
		}
	}

	IRCChannelConfig *targetConfig = nil;

	if (target) {
		targetConfig = target.config;

		if (eventType == TXNotificationHighlightType) {
			if (targetConfig.ignoreHighlights) {
				return YES;
			}
		} else {
			if (targetConfig.pushNotifications == NO) {
				return YES;
			}
		}
	}

	if ([sharedGrowlController() bounceDockIconForEvent:eventType inChannel:target]) {
		if ([sharedGrowlController() bounceDockIconRepeatedlyForEvent:eventType inChannel:target]) {
			[NSApp requestUserAttention:NSCriticalRequest];
		} else {
			[NSApp requestUserAttention:NSInformationalRequest];
		}
	}

	if (sharedGrowlController().areNotificationsDisabled) {
		return YES;
	}

	BOOL mainWindowIsFocused = (mainWindow().inactive == NO);

	BOOL postNotificationsWhileFocused = [TPCPreferences postNotificationsWhileInFocus];

	BOOL targetIsSelected = [mainWindow() isItemSelected:target];

	BOOL onlySpeakEvent = (postNotificationsWhileFocused && mainWindowIsFocused && targetIsSelected);

	if ([TPCPreferences soundIsMuted] == NO) {
		if (onlySpeakEvent == NO) {
			NSString *soundName = [sharedGrowlController() soundForEvent:eventType inChannel:target];

			if (soundName) {
				[TLOSoundPlayer playAlertSound:soundName];
			}
		}

		[self speakEvent:eventType lineType:lineType target:target nickname:nickname text:text];
	}

	if (onlySpeakEvent) {
		return YES;
	}

	if ([sharedGrowlController() growlEnabledForEvent:eventType inChannel:target] == NO) {
		return YES;
	}

	if (postNotificationsWhileFocused == NO && mainWindowIsFocused) {
		if (eventType != TXNotificationAddressBookMatchType) {
			return YES;
		}
	}

	if ([sharedGrowlController() disabledWhileAwayForEvent:eventType inChannel:target]) {
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

			eventTitle = self.networkNameAlt;

			eventDescription = TXTLS(@"Notifications[1035]", nickname, target.name, text);

			break;
		}
		case TXNotificationInviteType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = self.networkNameAlt;

			eventDescription = TXTLS(@"Notifications[1034]", nickname, text);

			break;
		}
		case TXNotificationUserJoinedType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);

			eventTitle = self.networkNameAlt;

			eventDescription = TXTLS(@"Notifications[1073]", nickname, target.name);

			break;
		}
		case TXNotificationUserPartedType:
		{
			NSParameterAssert(target != nil);
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = self.networkNameAlt;

			if (text == nil || text.length == 0) {
				eventDescription = TXTLS(@"Notifications[1074]", nickname, target.name);
			} else {
				eventDescription = TXTLS(@"Notifications[1075]", nickname, target.name, text);
			}

			break;
		}
		case TXNotificationUserDisconnectedType:
		{
			NSParameterAssert(nickname != nil);
			NSParameterAssert(text != nil);

			eventTitle = self.networkNameAlt;

			if (text == nil || text.length == 0) {
				eventDescription = TXTLS(@"Notifications[1076]", nickname);
			} else {
				eventDescription = TXTLS(@"Notifications[1077]", nickname, text);
			}

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
#pragma mark Playback

- (void)playbackClearChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityPlayback] == NO) {
		return;
	}

	if (channel.isPrivateMessage == NO || channel.isPrivateMessageForZNCUser) {
		return;
	}

	NSString *command = [NSString stringWithFormat:@"clear %@", channel.name];

	if (self.isConnectedToZNC) {
		[self sendCommand:command toZNCModuleNamed:@"playback"];

		return;
	}

	[self send:IRCPrivateCommandIndex("privmsg"), @"*playback", command, nil];
}

- (void)requestPlayback
{
	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityPlayback] == NO) {
		return;
	}

	/* For our first connect, only playback using timestamp if logging was enabled. */
	/* For all other connects, then playback timestamp regardless of logging. */
	NSString *command = nil;

	if ((self.successfulConnects > 1 || (self.successfulConnects == 1 && self.config.zncOnlyPlaybackLatest)) && self.lastMessageServerTime > 0) {
		command = [NSString stringWithFormat:@"play * %.0f", self.lastMessageServerTime];
	} else {
		command = @"play * 0";
	}

	if (self.isConnectedToZNC) {
		[self sendCommand:command toZNCModuleNamed:@"playback"];

		return;
	}

	[self send:IRCPrivateCommandIndex("privmsg"), @"*playback", command, nil];
}

#pragma mark -
#pragma mark ZNC Bouncer Accessories

- (void)zncPlaybackClearChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (self.isConnectedToZNC == NO) {
		return;
	}

	[self playbackClearChannel:channel];
}

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

- (BOOL)nickname:(NSString *)nickname isZNCUser:(NSString *)zncNickname
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(zncNickname != nil);
	
	return [nickname isEqualToString:[self nicknameAsZNCUser:zncNickname]];
}

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

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityBatch]) {
		NSString *batchType = message.parentBatchMessage.batchType;

		return (NSObjectsAreEqual(batchType, @"znc.in/playback") == NO);
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

		LogToConsoleInfo("ZNC detected...");
	}
}

- (void)sendCommand:(NSString *)command toZNCModuleNamed:(NSString *)module
{
	NSParameterAssert(command != nil);
	NSParameterAssert(module != nil);

	NSString *destination = [self nicknameAsZNCUser:module];

	if (destination == nil) {
		return;
	}

	NSString *stringToSend = [NSString stringWithFormat:@"ZNC %@ %@", destination, command];

	[self sendLine:stringToSend];
}

#pragma mark -
#pragma mark Channel States

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

- (void)setUnreadStateForChannel:(IRCChannel *)channel
{
	[self setUnreadStateForChannel:channel isHighlight:NO];
}

- (void)setUnreadStateForChannel:(IRCChannel *)channel isHighlight:(BOOL)isHighlight
{
	NSParameterAssert(channel != nil);

	if (mainWindow().keyWindow && [mainWindow() isItemSelected:channel]) {
		return;
	}

	if (channel.isChannel == NO || [TPCPreferences displayPublicMessageCountOnDockBadge]) {
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
#pragma mark Find Channel

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

- (nullable IRCChannel *)findChannel:(NSString *)name
{
	return [self findChannel:name inList:self.channelList];
}

- (nullable IRCChannel *)findChannelOrCreate:(NSString *)name
{
	return [self findChannelOrCreate:name isPrivateMessage:NO];
}

- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName isPrivateMessage:(BOOL)isPrivateMessage
{
	NSParameterAssert(withName != nil);

	if (isPrivateMessage == NO) {
		return [self findChannelOrCreate:withName asType:IRCChannelChannelType];
	} else {
		return [self findChannelOrCreate:withName asType:IRCChannelPrivateMessageType];
	}
}

- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName isUtility:(BOOL)isUtility
{
	NSParameterAssert(withName != nil);

	if (isUtility == NO) {
		return [self findChannelOrCreate:withName asType:IRCChannelChannelType];
	} else {
		return [self findChannelOrCreate:withName asType:IRCChannelUtilityType];
	}
}

- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName asType:(IRCChannelType)type
{
	NSParameterAssert(withName != nil);

	IRCChannel *channel = [self findChannel:withName];

	if (channel) {
		return channel;
	}

	if (type == IRCChannelChannelType) {
		IRCChannelConfig *config = [IRCChannelConfig seedWithName:withName];

		channel = [worldController() createChannelWithConfig:config onClient:self add:YES adjust:YES reload:YES];

		[worldController() savePeriodically];
	} else {
		channel = [worldController() createPrivateMessage:withName onClient:self asType:type];
	}

	return channel;
}

#pragma mark -
#pragma mark User List 

- (nullable IRCUser *)myself
{
	return [self findUser:self.userNickname];
}

- (BOOL)userExists:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	return ([self findUser:nickname] != nil);
}

- (nullable IRCUser *)findUser:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	nickname = nickname.lowercaseString;

	@synchronized (self.userListPrivate) {
		return self.userListPrivate[nickname];
	}
}

- (IRCUserMutable *)mutableCopyOfUserWithNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	IRCUser *user = [self findUser:nickname];

	if (user == nil) {
		return [[IRCUserMutable alloc] initWithNickname:nickname onClient:self];
	} else {
		return [user mutableCopy];
	}
}

- (NSUInteger)numberOfUsers
{
	@synchronized (self.userListPrivate) {
		return self.userListPrivate.count;
	}
}

- (NSArray<IRCUser *> *)userList
{
	@synchronized (self.userListPrivate) {
		return self.userListPrivate.allValues;
	}
}

- (void)addUser:(IRCUser *)user
{
	(void)[self addUserAndReturn:user];
}

- (IRCUser *)addUserAndReturn:(IRCUser *)user
{
	NSParameterAssert(user != nil);

	if ([user isKindOfClass:[IRCUserMutable class]]) {
		user = [user copy];
	}

	NSString *nickname = user.lowercaseNickname;

	@synchronized (self.userListPrivate) {
		self.userListPrivate[nickname] = user;
	}

	[user becamePrimaryUser];

	return user;
}

- (IRCUser *)findUserOrCreate:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	IRCUser *user = [self findUser:nickname];

	if (user == nil) {
		user = [[IRCUser alloc] initWithNickname:nickname onClient:self];

		[self addUser:user];
	}

	return user;
}

- (void)removeUser:(IRCUser *)user
{
	NSParameterAssert(user != nil);

	[user cancelRemoveUserTimer];

	[self removeUserWithNickname:user.nickname];
}

- (void)removeUserWithNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	nickname = nickname.lowercaseString;

	@synchronized (self.userListPrivate) {
		[self.userListPrivate removeObjectForKey:nickname];
	}
}

- (void)renameUser:(IRCUser *)user to:(NSString *)toNickname
{
	NSParameterAssert(user != nil);
	NSParameterAssert(toNickname != nil);

	[self modifyUser:user withBlock:^(IRCUserMutable *userMutable) {
		userMutable.nickname = toNickname;
	}];
}

- (void)renameUserWithNickname:(NSString *)fromNickname to:(NSString *)toNickname
{
	NSParameterAssert(fromNickname != nil);
	NSParameterAssert(toNickname != nil);

	IRCUser *user = [self findUser:fromNickname];

	if (user == nil) {
		return;
	}

	[self renameUser:user to:toNickname];
}

- (void)modifyUser:(IRCUser *)user withBlock:(void(^)(IRCUserMutable *userMutable))block
{
	NSParameterAssert(user != nil);
	NSParameterAssert(block != nil);

	IRCUserMutable *userMutable = [user mutableCopy];

	block(userMutable);

	if ([user.nickname isEqualToString:userMutable.nickname] == NO) {
		[self removeUser:user];
	}

	[self addUser:userMutable];
}

- (void)modifyUserUserWithNickname:(NSString *)nickname withBlock:(void(^)(IRCUserMutable *userMutable))block
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(block != nil);

	IRCUser *user = [self findUser:nickname];

	if (user == nil) {
		return;
	}

	[self modifyUser:user withBlock:block];
}

- (void)modifyUserWithNickname:(NSString *)nickname asAway:(BOOL)away
{
	NSParameterAssert(nickname != nil);
	
	IRCUser *user = [self findUser:nickname];
	
	if (user == nil) {
		return;
	}

	[self modifyUser:user asAway:away];
}

- (void)modifyUser:(IRCUser *)user asAway:(BOOL)away
{
	NSParameterAssert(user != nil);
	
	if (self.monitorAwayStatus == NO) {
		return;
	}

	if (away) {
		[user markAsAway];
	} else {
		[user markAsReturned];
	}
	
	[mainWindow() updateDrawingForUserInUserList:user];
}

- (void)resetAwayStatusForUsers
{
	[self.userList makeObjectsPerformSelector:@selector(markAsReturned)];
}

#pragma mark -
#pragma mark Send Raw Data

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

- (void)send:(NSString *)string arguments:(NSArray<NSString *> *)arguments
{
	NSParameterAssert(string != nil);
	NSParameterAssert(arguments != nil);

	NSString *stringToSend = [IRCSendingMessage stringWithCommand:string arguments:arguments];

	[self sendLine:stringToSend];
}

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
#pragma mark Sending Text

- (void)inputText:(id)string asCommand:(IRCPrivateCommand)command
{
	IRCTreeItem *destination = mainWindow().selectedItem;

	[self inputText:string asCommand:command destination:destination];
}

- (void)inputText:(id)string destination:(IRCTreeItem *)destination
{
	[self inputText:string asCommand:IRCPrivateCommandPrivmsgIndex destination:destination];
}

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

			continue;
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

- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel
{
	[self sendText:string asCommand:command toChannel:channel withEncryption:YES];
}

- (void)sendText:(NSAttributedString *)string asCommand:(IRCPrivateCommand)command toChannel:(IRCChannel *)channel withEncryption:(BOOL)encryptText
{
	NSParameterAssert(string != nil);
	NSParameterAssert(channel != nil);

	if (string.length == 0) {
		return;
	}

	if (channel.isUtility) {
		[self printCannotSendMessageToWindowErrorInChannel:channel];

		return;
	}

	NSString *commandToSend = nil;

	TVCLogLineType lineType = TVCLogLineUndefinedType;

	if (command == IRCPrivateCommandPrivmsgIndex) {
		commandToSend = IRCPrivateCommandIndex("privmsg");

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
				if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage] && wasEncrypted == NO) {
					return;
				}

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

- (void)sendPrivmsg:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandPrivmsgIndex
			 toChannel:channel];
	}];
}

- (void)sendAction:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandPrivmsgActionIndex
			 toChannel:channel];
	}];
}

- (void)sendNotice:(NSString *)message toChannel:(IRCChannel *)channel
{
	[self performBlockOnMainThread:^{
		[self sendText:[NSAttributedString attributedStringWithString:message]
			 asCommand:IRCPrivateCommandNoticeIndex
			 toChannel:channel];
	}];
}

- (void)sendPrivmsgToSelectedChannel:(NSString *)message
{
	IRCChannel *channel = [mainWindow() selectedChannelOn:self];

	if (channel == nil) {
		return;
	}

	[self sendPrivmsg:message toChannel:channel];
}

- (void)sendCTCPQuery:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(command != nil);

	NSString *stringToSend = nil;

	if (text == nil) {
		stringToSend = command;
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, stringToSend, 0x01];

	[self send:IRCPrivateCommandIndex("privmsg"), nickname, message, nil];
}

- (void)sendCTCPReply:(NSString *)nickname command:(NSString *)command text:(nullable NSString *)text
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(command != nil);

	NSString *stringToSend = nil;

	if (text == nil) {
		stringToSend = command;
	} else {
		stringToSend = [NSString stringWithFormat:@"%@ %@", command, text];
	}

	NSString *message = [NSString stringWithFormat:@"%c%@%c", 0x01, stringToSend, 0x01];

	[self send:IRCPrivateCommandIndex("notice"), nickname, message, nil];
}

- (void)sendCTCPPing:(NSString *)nickname
{
	NSString *text = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSince1970]];

	[self sendCTCPQuery:nickname
				command:IRCPrivateCommandIndex("ctcp_ping")
				   text:text];
}

#pragma mark -
#pragma mark Send Command

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

	if (targetChannel.isUtility) {
		[self printCannotSendMessageToWindowErrorInChannel:targetChannel];

		return;
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

			break;
		}
		case IRCPublicCommandBufferdebugIndex:
		{
			IRCTreeItem *treeItem = ((targetChannel) ? targetChannel : self);
			
			TVCLogView *backingView = treeItem.viewController.backingView;

			__weak IRCClient *weakSelf = self;

			[backingView dictionaryByEvaluatingFunction:@"_Textual.bufferDebugInformation"
									  completionHandler:^(NSDictionary<NSString *, id> *result) {
										  IRCChannel *utilityChannel = [weakSelf findChannelOrCreate:@"Buffer Debug" isUtility:YES];
										  
										  [weakSelf printDebugInformation:TXTLS(@"IRC[1128]",
																				result[@"Textual"],
																				result[@"_Textual"],
																				result[@"_TextualScroller"],
																				result[@"_MessageBuffer"],
																				[result unsignedIntegerForKey:@"Unclaimed callbacks"])
																inChannel:utilityChannel
										   
										   /* Message is not escaped because:
											1. Line breaks in localization make it easier for information to be read.
											2. We know for certain where the information is coming from. */
															escapeMessage:NO];

										  [weakSelf setUnreadStateForChannel:utilityChannel];
									  }];
			break;
		}
		case IRCPublicCommandCapIndex: // Command: CAP
		case IRCPublicCommandCapsIndex: // Command: CAPS
		{
			NSString *capabilites = self.enabledCapabilitiesStringValue;

			if (capabilites.length == 0) {
				[self printDebugInformation:TXTLS(@"IRC[1036]")];
			} else {
				[self printDebugInformation:TXTLS(@"IRC[1037]", capabilites)];
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
					LogToConsoleInfo("Silently ignoring bad server address");

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

			if (targetChannel && targetChannel != selectedChannel) {
				targetChannelName = targetChannel.name;
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
		case IRCPublicCommandDehalfopIndex: // Command: DEHALFOP
		case IRCPublicCommandDeopIndex: // Command: DEOP
		case IRCPublicCommandDevoiceIndex: // Command: DEVOICE
		case IRCPublicCommandHalfopIndex: // Command: HALFOP
		case IRCPublicCommandOpIndex: // Command: OP
		case IRCPublicCommandVoiceIndex: // Command: VOICE
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			BOOL modeIsSet = (commandNumeric == IRCPublicCommandOpIndex ||
							  commandNumeric == IRCPublicCommandHalfopIndex ||
							  commandNumeric == IRCPublicCommandVoiceIndex);

			NSString *modeSymbol = nil;

			if (commandNumeric == IRCPublicCommandOpIndex || commandNumeric == IRCPublicCommandDeopIndex) {
				modeSymbol = @"o";
			} else if (commandNumeric == IRCPublicCommandHalfopIndex || commandNumeric == IRCPublicCommandDehalfopIndex) {
				modeSymbol = @"h";
			} else if (commandNumeric == IRCPublicCommandVoiceIndex || commandNumeric == IRCPublicCommandDevoiceIndex) {
				modeSymbol = @"v";
			}

			if ([self.supportInfo modeSymbolIsUserPrefix:modeSymbol] == NO) {
				[self printDebugInformation:TXTLS(@"IRC[1021]", modeSymbol)];

				break;
			}

			if ([self stringIsChannelName:stringInString] == NO) {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *nicknamesString = stringIn.string;

			NSArray *modeChanges =
			[self compileListOfModeChangesForModeSymbol:modeSymbol
											  modeIsSet:modeIsSet
										parameterString:nicknamesString];

			for (NSString *modeChange in modeChanges) {
				[self send:IRCPrivateCommandIndex("mode"), targetChannelName, modeChange, nil];
			}

			break;
		}
		case IRCPublicCommandDebugIndex: // Command: DEBUG
		case IRCPublicCommandEchoIndex: // Command: ECHO
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			if ([stringInString isEqualIgnoringCase:@"raw on"])
			{
				[self createRawDataLogQuery];
			}
			else if ([stringInString isEqualIgnoringCase:@"raw off"])
			{
				[self destroyRawDataLogQuery];
			}
			else
			{
				[self printDebugInformation:stringInString];
			}

			break;
		}
		case IRCPublicCommandDefaultsIndex: // Command: DEFAULTS
		{
			if (stringInStringLength == 0) {
				[self printDebugInformation:TXTLS(@"IRC[1012]")];

				break;
			}

			NSString *action = stringIn.tokenAsString;

			/* Present help */
			if (NSObjectsAreEqual(action, @"help"))
			{
				[self printDebugInformation:TXTLS(@"IRC[1013][01]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][02]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][03]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][04]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][05]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][06]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][07]")];
				[self printDebugInformation:TXTLS(@"IRC[1013][08]")];

				break;
			}

			/* Present list of features */
			else if (NSObjectsAreEqual(action, @"features"))
			{
				[TLOpenLink openWithString:@"https://help.codeux.com/textual/Command-Reference.kb#cr=defaults" inBackground:NO];

				break;
			}

			/* Prepare to toggle feature */
			NSString *feature = stringIn.tokenIncludingQuotes.string;

			BOOL applyToAll = NSObjectsAreEqual(feature, @"-a");

			if (applyToAll) {
				feature = stringIn.tokenIncludingQuotes.string;
			}

			NSDictionary *features = @{
				@"Ignore Notifications by Private ZNC Users"		: @"setZncIgnoreUserNotifications:",
				@"Send Authentication Requests to UserServ"			: @"setSendAuthenticationRequestsToUserServ:",
				@"Disable Automatic SASL EXTERNAL Response"			: @"setSaslAuthenticationDisableExternalMechanism:",
				@"Send WHO Command Requests to Channels"			: @"setSendWhoCommandRequestsToChannels:",
			};

			BOOL enableFeature = NSObjectsAreEqual(action, @"enable");

			/* Cannot toggle feature if the user doesn't tell us which */
			if (feature.length == 0) {
				[self printDebugInformation:TXTLS(@"IRC[1012]")];

				break;
			}

			/* Make sure the feature exists */
			if ([features containsKey:feature] == NO) {
				if (enableFeature) {
					[self printDebugInformation:TXTLS(@"IRC[1014]", feature)];
				} else {
					[self printDebugInformation:TXTLS(@"IRC[1015]", feature)];
				}

				break;
			}

			/* Toggle the feature by mutating the client's configuration,
			 invoking the appropriate method, then saving it. */
			void (^toggleFeature)(IRCClient *, NSString *, BOOL) = ^(IRCClient *client, NSString *featureKey, BOOL featureValue) {
				NSString *selectorString = features[featureKey];

				SEL selector = NSSelectorFromString(selectorString);

				IRCClientConfigMutable *mutableClientConfig = [client.config mutableCopy];

				(void)objc_msgSend(mutableClientConfig, selector, featureValue);

				client.config = mutableClientConfig;
			};

			/* Toggle feature */
			for (IRCClient *client in worldController().clientList) {
				if (client != self && applyToAll == NO) {
					continue;
				}

				toggleFeature(client, feature, enableFeature);

				if (enableFeature) {
					[client printDebugInformation:TXTLS(@"IRC[1016]", feature)];
				} else {
					[client printDebugInformation:TXTLS(@"IRC[1017]", feature)];
				}
			}

			/* Save modified client */
			[worldController() save];

			break;
		}
		case IRCPublicCommandEmptycachesIndex: // Command: EMPTY_CACHES
		{
			XRPerformBlockAsynchronouslyOnGlobalQueue(^{
				[TVCLogView emptyCaches];
			});

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
		case IRCPublicCommandGlineIndex: // Command: GLINE
		case IRCPublicCommandGzlineIndex: // Command: GZLINE
		case IRCPublicCommandShunIndex:  // Command: SHUN
		case IRCPublicCommandTempshunIndex: // Command: TEMPSHUN
		case IRCPublicCommandZlineIndex: // Command: ZLINE
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			NSString *segment1 = stringIn.getTokenAsString;
			NSString *segment2 = stringIn.getTokenAsString;

			[self send:uppercaseCommand, segment1, segment2, stringIn.string, nil];

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

			IRCUser *member = [self findUser:nickname];

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
		case IRCPublicCommandInviteIndex:
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSAssertReturnLoopBreak(self.isLoggedIn);

			NSArray *nicknames = [stringInString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if ([self stringIsChannelName:nicknames.lastObject]) {
				targetChannelName = nicknames.lastObject;
			} else {
				if (targetChannel && targetChannel.isChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			}

			for (NSString *nickname in nicknames) {
				if ([self stringIsNickname:nickname] == NO) {
					continue;
				}

				[self send:IRCPrivateCommandIndex("invite"), nickname, targetChannelName, nil];
			}

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

			IRCTreeItem* targetChannel = [self findChannel: targetChannelName];
			if(targetChannel.isActive)
			{
				[mainWindow() select:targetChannel];
			}
			else
			{
				[self enableInUserInvokedCommandProperty:&self->_inUserInvokedJoinRequest];
				[self send:IRCPrivateCommandIndex("join"), targetChannelName, stringIn.string, nil];
			}

			break;
		}
		case IRCPublicCommandJoinRandomIndex: // Command: JOIN_RANDOM
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			NSInteger numberOfChannelsToJoin = 0;

			if (stringInStringLength > 0) {
				NSString *numberToken = stringIn.tokenAsString;

				if (numberToken.isNumericOnly) {
					numberOfChannelsToJoin = numberToken.integerValue;
				}
			}

			if (numberOfChannelsToJoin <= 0) {
				numberOfChannelsToJoin = 1;
			}

			for (NSUInteger i = 0; i < numberOfChannelsToJoin; i++) {
				NSString *channelName = [NSString stringWithFormat:@"#debug-channel-%ld", TXRandomNumber(9999999)];

				[self send:IRCPrivateCommandIndex("join"), channelName, nil];
			}

			break;
		}
		case IRCPublicCommandBanIndex: // Command: BAN
		case IRCPublicCommandKbIndex: // Command: KB
		case IRCPublicCommandKickIndex: // Command: KICK
		case IRCPublicCommandKickbanIndex: // Command: KICKBAN
		case IRCPublicCommandUnbanIndex: // Command: UNBAN
		case IRCPublicCommandUnquietIndex: // Command: UNQUIET
		case IRCPublicCommandQuietIndex: // Command: QUIET
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
				commandNumeric == IRCPublicCommandUnbanIndex ||
				commandNumeric == IRCPublicCommandQuietIndex ||
				commandNumeric == IRCPublicCommandUnquietIndex)
			{
				IRCChannelUser *member = [targetChannel findMember:nickname];

				NSString *banMask = member.user.banMask;

				if (banMask == nil) {
					banMask = nickname;
				}

				NSString *modeSymbol = nil;

				if (commandNumeric == IRCPublicCommandQuietIndex ||
					commandNumeric == IRCPublicCommandUnquietIndex)
				{
					modeSymbol = @"q";
				} else {
					modeSymbol = @"b";
				}

				if ([self.supportInfo modeSymbolIsUserPrefix:modeSymbol]) {
					[self printDebugInformation:TXTLS(@"IRC[1021]", modeSymbol)];

					break;
				}

				if (commandNumeric == IRCPublicCommandUnbanIndex ||
					commandNumeric == IRCPublicCommandUnquietIndex)
				{
					[self send:IRCPrivateCommandIndex("mode"), targetChannelName, [@"-" stringByAppendingString:modeSymbol], banMask, nil];
				} else {
					[self send:IRCPrivateCommandIndex("mode"), targetChannelName, [@"+" stringByAppendingString:modeSymbol], banMask, nil];
				}
			}

			if (commandNumeric == IRCPublicCommandKbIndex ||
				commandNumeric == IRCPublicCommandKickIndex ||
				commandNumeric == IRCPublicCommandKickbanIndex)
			{
				NSString *reason = stringIn.string;

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
			NSString *reason = stringIn.string;

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
				} else if (targetChannel) {
					[worldController() destroyChannel:targetChannel];

					break;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *reason = stringIn.string;

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
		case IRCPublicCommandMIndex:
		case IRCPublicCommandModeIndex:
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if (stringInStringLength == 0 ||
				([stringInString hasPrefix:@"+"] ||
				 [stringInString hasPrefix:@"-"]))
			{
				if (targetChannel) {
					targetChannelName = targetChannel.name;
				} else {
					break;
				}
			} else {
				targetChannelName = stringIn.tokenAsString;
			}

			NSString *modeString = stringIn.string;

			if (modeString.length == 0) {
				[self enableInUserInvokedCommandProperty:&self->_inUserInvokedModeRequest];

				[self send:IRCPrivateCommandIndex("mode"), targetChannelName, nil];
			} else {
				[self send:IRCPrivateCommandIndex("mode"), targetChannelName, modeString, nil];
			}

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
			NSString *applicationName = [TPCApplicationInfo applicationNameWithoutVersion];
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
		case IRCPublicCommandNotifybubble: // Command: NOTIFYBUBBLE
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			if ([self stringIsChannelName:stringInString]) {
				targetChannel = [self findChannel:stringIn.tokenAsString];
			} else {
				targetChannel = nil;
			}

			NSUserNotification *notification = [NSUserNotification new];

			notification.deliveryDate = [NSDate date];

			notification.title = [TPCApplicationInfo applicationNameWithoutVersion];

			notification.informativeText = stringInString;

			if (targetChannel) {
				notification.userInfo = @{@"clientId": self.uniqueIdentifier, @"channelId": targetChannel.uniqueIdentifier};
			} else {
				notification.userInfo = @{@"clientId": self.uniqueIdentifier};
			}

			[RZUserNotificationCenter() deliverNotification:notification];

			break;
		}
		case IRCPublicCommandNotifysound: // Command: NOTIFYSOUND
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			NSString *soundName = stringIn.tokenAsString;

			[TLOSoundPlayer playAlertSound:soundName];

			break;
		}
		case IRCPublicCommandNotifyspeak: // Command: NOTIFYSPEAK
		{
			NSAssertReturnLoopBreak(stringInStringLength != 0);

			[[TXSharedApplication sharedSpeechSynthesizer] speak:stringInString];

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
			NSTimeInterval timePassed = [NSDate timeIntervalSinceNow:[TPCApplicationInfo applicationBirthday]];

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
		case IRCPublicCommandUmodeIndex:
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if (stringInStringLength == 0) {
				[self send:IRCPrivateCommandIndex("mode"), self.userNickname, nil];
			} else {
				[self send:IRCPrivateCommandIndex("mode"), self.userNickname, stringInString, nil];
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
		case IRCPublicCommandMonitorIndex: // Command: MONITOR
		case IRCPublicCommandWatchIndex: // Command: WATCH
		{
			NSAssertReturnLoopBreak(self.isLoggedIn);

			if ([stringInString hasSuffix:@"-"] || [stringInString hasSuffix:@"+"] ) {
				break;
			}

			[self enableInUserInvokedCommandProperty:&self->_inUserInvokedWatchRequest];

			[self sendCommand:uppercaseCommand withData:stringInString];

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
					LogToConsoleError("User wants to send operator message but there is no +o mode");

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
				LogToConsoleError("Bad target channel name");

				break;
			}

			/* Actions are allowed to have an empty message but all other
			 types are not. Empty actions use a whitespace. */
			if (stringIn.length == 0) {
				if (lineType == TVCLogLineActionType) {
					[stringIn replaceCharactersInRange:NSMakeRange(0, 0)
											withString:@" "];
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

						if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage] && wasEncrypted == NO) {
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
		case IRCPublicCommandReloadICLIndex: // Command: RELOADICL
		{
			[TVCLogControllerInlineMediaSharedInstance() reloadService];

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
				LogToConsoleError("%{public}@", TXTLS(@"IRC[1001]", uppercaseCommand));
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
			[self sendCommand:uppercaseCommand withData:stringInString];

			break;
		}
	}
}

- (void)sendCommand:(NSString *)command withData:(NSString *)data
{
	NSParameterAssert(command != nil);
	NSParameterAssert(data != nil);

	NSString *stringToSend = [NSString stringWithFormat:@"%@ %@", command, data];

	[self sendLine:stringToSend];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logToDiskIsEnabled]

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
		&&
		(TLOAppStoreTextualIsRegistered() || TLOAppStoreIsTrialExpired() == NO)
#endif

		)
	{
		if ( self.logFile) {
			[self.logFile reopenIfNeeded];
		}
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	if (self.logFile == nil) {
		return;
	}

	[self.logFile close];
}

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

	topLine.messageBody = @" ";

	[self writeToLogLineToLogFile:topLine];

	/* ============================ */

	TVCLogLineMutable *middleLine = [TVCLogLineMutable new];

	middleLine.messageBody = TXTLS(localization);

	[self writeToLogLineToLogFile:middleLine];

	/* ============================ */

	TVCLogLineMutable *bottomLine = [TVCLogLineMutable new];

	bottomLine.messageBody = @" ";

	[self writeToLogLineToLogFile:bottomLine];

	/* ============================ */

	for (IRCChannel *channel in self.channelList) {
		if (channel.isUtility) {
			continue;
		}

		[channel writeToLogLineToLogFile:topLine];
		[channel writeToLogLineToLogFile:middleLine];
		[channel writeToLogLineToLogFile:bottomLine];
	}
}

- (void)logFileWriteSessionBegin
{
	[self logFileRecordSessionChanged:YES];
}

- (void)logFileWriteSessionEnd
{
	[self logFileRecordSessionChanged:NO];
}

#pragma mark -
#pragma mark Print

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

	NSString *modeSymbol = @"";

	if (channel.isChannel) {
		IRCChannelUser *member = [channel findMember:nickname];

		if (member) {
			modeSymbol = member.mark;
		}
	}

	NSString *formatMarker = @"%";

	NSString *chunk = nil;

	NSScanner *scanner = [NSScanner scannerWithString:format];

	scanner.charactersToBeSkipped = nil;

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
				NSString *paddedString = [@"" stringByPaddingToLength:(ABS(paddingWidth) - outputValue.length) withString:@" " startingAtIndex:0];

				[buffer appendString:paddedString];
			}

			[buffer appendString:outputValue];

			if (paddingWidth > 0 && paddingWidth > outputValue.length) {
				NSString *paddedString = [@"" stringByPaddingToLength:(paddingWidth - outputValue.length) withString:@" " startingAtIndex:0];

				[buffer appendString:paddedString];
			}
		}
	}

	return [buffer copy];
}

- (void)printAndLog:(TVCLogLine *)logLine completionBlock:(TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(logLine != nil);

	[self.viewController print:logLine completionBlock:completionBlock];

	[self writeToLogLineToLogFile:logLine];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:[NSDate date] isEncrypted:NO escapeMessage:YES referenceMessage:nil completionBlock:nil];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command escapeMessage:(BOOL)escapeMessage
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:[NSDate date] isEncrypted:NO escapeMessage:escapeMessage referenceMessage:nil completionBlock:nil];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:NO escapeMessage:YES referenceMessage:nil completionBlock:nil];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:isEncrypted escapeMessage:YES referenceMessage:nil completionBlock:nil];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted referenceMessage:(nullable IRCMessage *)referenceMessage
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:isEncrypted escapeMessage:YES referenceMessage:referenceMessage completionBlock:nil];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted referenceMessage:(nullable IRCMessage *)referenceMessage completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	[self print:messageBody by:nickname inChannel:channel asType:lineType command:command receivedAt:receivedAt isEncrypted:isEncrypted escapeMessage:YES referenceMessage:referenceMessage completionBlock:completionBlock];
}

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(nullable NSString *)command receivedAt:(NSDate *)receivedAt isEncrypted:(BOOL)isEncrypted escapeMessage:(BOOL)escapeMessage referenceMessage:(nullable IRCMessage *)referenceMessage completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock
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
	BOOL matchHighlights =
		(channel &&
		 channel.config.ignoreHighlights == NO &&
		 (lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLineActionType) &&
		 memberType == TVCLogLineMemberNormalType);

	NSMutableArray<NSString *> *excludeKeywords = nil;
	NSMutableArray<NSString *> *matchKeywords = nil;
	
	if (matchHighlights) {
		/* Global highlight keywords */
		excludeKeywords = [[TPCPreferences highlightExcludeKeywords] mutableCopy];
		matchKeywords = [[TPCPreferences highlightMatchKeywords] mutableCopy];

		/* Self nickname keyword */
		if ([TPCPreferences highlightMatchingMethod] != TXNicknameHighlightRegularExpressionMatchType &&
			[TPCPreferences highlightCurrentNickname])
		{
			[matchKeywords addObjectWithoutDuplication:localNickname];
		}

		/* Client/channel specific keywords */
		NSArray *clientHighlightList = self.config.highlightList;

		NSString *channelId = channel.uniqueIdentifier;

		for (IRCHighlightMatchCondition *e in clientHighlightList) {
			NSString *matchChannelId = e.matchChannelId;
			
			if (matchChannelId.length > 0) {
				if ([matchChannelId isEqualToString:channelId] == NO) {
					continue;
				}
			}
			
			if (e.matchIsExcluded) {
				[excludeKeywords addObjectWithoutDuplication:e.matchKeyword];
			} else {
				[matchKeywords addObjectWithoutDuplication:e.matchKeyword];
			}
		}
	} // matchKeywords

	if (lineType == TVCLogLineActionNoHighlightType) {
		lineType = TVCLogLineActionType;
	} else if (lineType == TVCLogLinePrivateMessageNoHighlightType) {
		lineType = TVCLogLinePrivateMessageType;
	}

	/* Renderer attributes */
	NSDictionary<NSString *, id> *rendererAttributes = nil;

	if (escapeMessage == NO) {
		rendererAttributes = @{
			TVCLogRendererConfigurationDoNotEscapeBodyAttribute : @(YES)
		};
	}

	/* Create new log entry */
	TVCLogLineMutable *logLine = [TVCLogLineMutable new];

	logLine.command	= command.lowercaseString;

	logLine.lineType = lineType;
	logLine.memberType = memberType;

	logLine.isEncrypted = isEncrypted;

	logLine.excludeKeywords = excludeKeywords;
	logLine.highlightKeywords = matchKeywords;

	logLine.rendererAttributes = rendererAttributes;

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
		if ([mainWindow() isItemVisible:channel] == NO || mainWindow().mainWindow == NO) {
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

- (void)printReply:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self print:[message sequence:1] by:nil inChannel:nil asType:TVCLogLineDebugType command:message.command receivedAt:message.receivedAt];
}

- (void)printUnknownReply:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self print:[message sequence:1] by:nil inChannel:nil asType:TVCLogLineDebugType command:message.command receivedAt:message.receivedAt];
}

- (void)printErrorReply:(IRCMessage *)message
{
	[self printErrorReply:message inChannel:nil];
}

- (void)printErrorReply:(IRCMessage *)message inChannel:(nullable IRCChannel *)channel
{
	NSParameterAssert(message != nil);

	NSString *errorMessage = TXTLS(@"IRC[1055]", message.commandNumeric, message.sequence);

	[self print:errorMessage by:nil inChannel:channel asType:TVCLogLineDebugType command:message.command];
}

- (void)printError:(NSString *)errorMessage asCommand:(NSString *)command
{
	[self print:errorMessage by:nil inChannel:nil asType:TVCLogLineDebugType command:command];
}

- (void)printDebugInformationToConsole:(NSString *)message
{
	[self printDebugInformationToConsole:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:YES];
}

- (void)printDebugInformationToConsole:(NSString *)message asCommand:(NSString *)command
{
	[self printDebugInformationToConsole:message asCommand:command escapeMessage:YES];
}

- (void)printDebugInformationToConsole:(NSString *)message escapeMessage:(BOOL)escapeMessage
{
	[self printDebugInformationToConsole:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:escapeMessage];
}

- (void)printDebugInformationToConsole:(NSString *)message asCommand:(NSString *)command escapeMessage:(BOOL)escapeMessage
{
	[self print:message by:nil inChannel:nil asType:TVCLogLineDebugType command:command escapeMessage:escapeMessage];
}

- (void)printDebugInformation:(NSString *)message
{
	[self printDebugInformation:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:YES];
}

- (void)printDebugInformation:(NSString *)message asCommand:(NSString *)command
{
	[self printDebugInformation:message asCommand:command escapeMessage:YES];
}

- (void)printDebugInformation:(NSString *)message escapeMessage:(BOOL)escapeMessage
{
	[self printDebugInformation:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:escapeMessage];
}

- (void)printDebugInformation:(NSString *)message asCommand:(NSString *)command escapeMessage:(BOOL)escapeMessage
{
	IRCChannel *channel = [mainWindow() selectedChannelOn:self];

	[self printDebugInformation:message inChannel:channel asCommand:TVCLogLineDefaultCommandValue escapeMessage:YES];
}

- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel
{
	[self printDebugInformation:message inChannel:channel asCommand:TVCLogLineDefaultCommandValue escapeMessage:YES];
}

- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel asCommand:(NSString *)command
{
	[self print:message by:nil inChannel:channel asType:TVCLogLineDebugType command:command escapeMessage:YES];
}

- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel escapeMessage:(BOOL)escapeMessage
{
	[self printDebugInformation:message inChannel:channel asCommand:TVCLogLineDefaultCommandValue escapeMessage:escapeMessage];
}

- (void)printDebugInformation:(NSString *)message inChannel:(IRCChannel *)channel asCommand:(NSString *)command escapeMessage:(BOOL)escapeMessage
{
	[self print:message by:nil inChannel:channel asType:TVCLogLineDebugType command:command escapeMessage:escapeMessage];
}

- (void)printDebugInformationInAllViews:(NSString *)message
{
	[self printDebugInformationInAllViews:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:YES];
}

- (void)printDebugInformationInAllViews:(NSString *)message asCommand:(NSString *)command
{
	[self printDebugInformationInAllViews:message asCommand:command escapeMessage:YES];
}

- (void)printDebugInformationInAllViews:(NSString *)message escapeMessage:(BOOL)escapeMessage
{
	[self printDebugInformationInAllViews:message asCommand:TVCLogLineDefaultCommandValue escapeMessage:escapeMessage];
}

- (void)printDebugInformationInAllViews:(NSString *)message asCommand:(NSString *)command escapeMessage:(BOOL)escapeMessage
{
	for (IRCChannel *channel in self.channelList) {
		[self printDebugInformation:message inChannel:channel asCommand:command escapeMessage:escapeMessage];
	}

	[self printDebugInformationToConsole:message asCommand:command escapeMessage:escapeMessage];
}

- (void)printCannotSendMessageToWindowErrorInChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self printDebugInformation:TXTLS(@"IRC[1121]") inChannel:channel];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)resetAllPropertyValues
{
	// Some properties are purposely excluded from this method
	// because their state must be kept or they are reset elsewhere

	[self.batchMessages dequeueEntries];

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

	self.autojoinDelayedWarningCount = 0;

	self.isConnected = NO;
	self.isConnecting = NO;
	self.isLoggedIn = NO;
	self.isQuitting = NO;
	self.isDisconnecting = NO;

	self.isWaitingForNickServ = NO;
	self.serverHasNickServ = NO;
	self.userIsIdentifiedWithNickServ = NO;

	self.userIsAway = NO;
	self.userIsIRCop = NO;

	self.isConnectedToZNC = NO;
	self.zncBoucnerIsSendingCertificateInfo = NO;
	self.zncBouncerCertificateChainDataMutable = nil;
	self.zncBouncerIsPlayingBackHistory = NO;

	self.reconnectEnabled = NO;

	self.timeoutWarningShownToUser = NO;

	self.lagCheckDestinationChannel = nil;
	self.lagCheckLastCheck = 0;

	self.lastWhoRequestChannelListIndex = 0;

	self.server = nil;

	self.userHostmask = nil;
	self.userNickname = nil;

	self.tryingNicknameNumber = 0;
	self.tryingNicknameSentNickname = nil;

	self.preAwayUserNickname = nil;

	self.lastMessageReceived = 0;

	self.capabilities = 0;
	self.capabilityNegotiationIsPaused = NO;

	@synchronized (self.capabilitiesPending) {
		[self.capabilitiesPending removeAllObjects];
	}

	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}

	@synchronized (self.userListPrivate) {
		[self.userListPrivate removeAllObjects];
	}
}

- (void)changeStateOff
{
	if (self.isConnecting == NO && self.isConnected == NO) {
		return;
	}

	BOOL isTerminating = self.isTerminating;

	self.socket = nil;

	[self stopAutojoinTimer];
	[self stopAutojoinDelayedWarningTimer];
	[self stopISONTimer];
	[self stopPongTimer];
	[self stopRetryTimer];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[self stopSoftwareTrialTimer];
#endif

	[self cancelPerformRequests];

	if (isTerminating == NO && self.reconnectEnabled) {
		[self startReconnectTimer];
	}

	[self.supportInfo reset];

	[self.trackedUsers clearTrackedUsers];

	if (isTerminating == NO) {
		/* -prepareForApplicationTermination in TVCLogController will cancel
		 all operations for this client for us during termination. */
		[[TXSharedApplication sharedPrintingQueue] cancelOperationsForClient:self];

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

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
		else if (self.disconnectType == IRCClientDisconnectSoftwareTrialMode) {
			disconnectMessage = TXTLS(@"IRC[1125]");
		}
#endif

		for (IRCChannel *channel in self.channelList) {
			if (channel.isActive == NO) {
				channel.errorOnLastJoinAttempt = NO;
			} else {
				[channel deactivate];

				if (channel.isUtility) {
					continue;
				}

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

- (void)ircConnectionDidSecureConnection:(IRCConnection *)sender withProtocolVersion:(SSLProtocol)protocolVersion cipherSuite:(SSLCipherSuite)cipherSuite;
{
	NSParameterAssert(sender == self.socket);

	NSString *protocolDescription = [GCDAsyncSocket descriptionForProtocolVersion:protocolVersion];

	NSString *cipherDescription = [GCDAsyncSocket descriptionForCipherSuite:cipherSuite];

	if (protocolDescription == nil || cipherDescription == nil) {
		return;
	}

	NSString *description = nil;

	if ([GCDAsyncSocket isCipherSuiteDeprecated:cipherSuite] == NO) {
		description = TXTLS(@"IRC[1112][1]", protocolDescription, cipherDescription);
	} else {
		description = TXTLS(@"IRC[1112][2]", protocolDescription, cipherDescription);
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1047]", description)];
}

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

	if (connectedAddress == nil || self.socket.config.serverAddress.IPAddress) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1045]")];
	} else {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1046]", connectedAddress)];
	}

	self.isConnecting = NO;
	self.isConnected = YES;

	self.userNickname = self.config.nickname;

	self.tryingNicknameSentNickname = self.config.nickname;

	[mainWindow() updateTitleFor:self];

	[RZNotificationCenter() postNotificationName:IRCClientDidConnectNotification object:self];

	NSString *username = self.config.username;
	NSString *realName = self.config.realName;

	NSString *modeSymbols = @"0";

	NSString *serverPassword = self.server.serverPassword;

	if (self.config.setInvisibleModeOnConnect) {
		modeSymbols = @"8";
	}

	if (username.length == 0) {
		username = self.config.nickname;
	}

	if (realName.length == 0) {
		realName = self.config.nickname;
	}

	[self sendCapability:@"LS" data:@"302"];

	if (serverPassword) {
		[self sendPassword:serverPassword];
	}

	[self changeNickname:self.tryingNicknameSentNickname];

	[self send:IRCPrivateCommandIndex("user"), username, modeSymbols, @"*", realName, nil];
}

- (void)ircConnection:(IRCConnection *)sender didDisconnectWithError:(nullable NSError *)disconnectError
{
	NSParameterAssert(sender == self.socket);

//	if (self.isTerminating) {
//		return;
//	}

	if (disconnectError && [GCDAsyncSocket isBadSSLCertificateError:disconnectError]) {
		self.disconnectType = IRCClientDisconnectBadCertificateMode;
	}

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self changeStateOff];

		if (self.disconnectCallback) {
			self.disconnectCallback();
			self.disconnectCallback = nil;
		}

		[RZNotificationCenter() postNotificationName:IRCClientDidDisconnectNotification object:self];
	});
}

- (void)ircConnection:(IRCConnection *)sender didError:(NSString *)error
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}

	[self printError:error asCommand:TVCLogLineDefaultCommandValue];
}

- (void)ircConnectionDidCloseReadStream:(IRCConnection *)sender
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}

	if (self.isDisconnecting) {
		return;
	}

	if (self.isQuitting) {
		[self disconnect];

		return;
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1120]")];
}

/* This delegate call is not invoked on the main thread
 which means if it is modified to interact with UI,
 then it must invoke on the main thread eventually. */
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

	[self rawDataLogIncomingTraffic:data];

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

- (void)processIncomingMessageAttributes:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

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
	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityPlayback]) {
		[message markAsNotHistoric];
	}
}

- (void)processIncomingMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self _processIncomingMessage:message];
	});
}

- (void)_processIncomingMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[self processIncomingMessageAttributes:message];

	if (message.commandNumeric > 0) {
		[self receiveNumericReply:message];
	} else {
		NSUInteger commandNumeric = [IRCCommandIndex indexOfIRCommand:message.command publicSearch:NO];

		switch (commandNumeric) {
			case IRCPrivateCommandNoticeIndex: // Command: NOTICE
			case IRCPrivateCommandPrivmsgIndex: // Command: PRIVMSG
			{
				[self receivePrivmsgAndNotice:message];

				break;
			}
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

				[self receiveCapabilityOrAuthenticationRequest:message];

				break;
			}
			case IRCPrivateCommandAwayIndex: // Command: AWAY (away-notify CAP)
			{
				[self receiveAwayNotifyCapability:message];

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
		} // switch
	}

	[self processBundlesServerMessage:message];
}

- (void)ircConnection:(IRCConnection *)sender willSendData:(NSString *)data
{
	NSParameterAssert(sender == self.socket);

	if (self.isTerminating) {
		return;
	}

	[self rawDataLogOutgoingTraffic:data];
}

#pragma mark -
#pragma mark Raw Data Logging

- (void)createRawDataLogQuery
{
	if (self.isTerminating) {
		return;
	}

	if (self.rawDataLogQuery != nil) {
		return;
	}

	IRCChannel *query = [self findChannelOrCreate:@"Server Traffic" isUtility:YES];

	self.rawDataLogQuery = query;

	[mainWindow() select:self.rawDataLogQuery];

	[self rawDataLog:TXTLS(@"IRC[1092]")];
}

- (void)destroyRawDataLogQuery
{
	if (self.isTerminating) {
		return;
	}

	if (self.rawDataLogQuery == nil) {
		return;
	}

	[worldController() destroyChannel:self.rawDataLogQuery];
}

- (void)rawDataLog:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.isTerminating) {
		return;
	}

	[self printDebugInformation:data inChannel:self.rawDataLogQuery];
}

- (void)rawDataLogOutgoingTraffic:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.rawDataLogQuery == nil) {
		return;
	}

	NSString *dataToLog = [NSString stringWithFormat:@"<< %@", data];

	[self rawDataLog:dataToLog];
}

- (void)rawDataLogIncomingTraffic:(NSString *)data
{
	NSParameterAssert(data != nil);

	if (self.rawDataLogQuery == nil) {
		return;
	}

	NSString *dataToLog = [NSString stringWithFormat:@">> %@", data];

	[self rawDataLog:dataToLog];
}

#pragma mark -
#pragma mark NickServ Information

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

- (void)receivePrivmsgAndNotice:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 1);

	NSString *text = [m paramAt:1];

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityIdentifyCTCP] && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		text = [text substringFromIndex:1];
	} else if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityIdentifyMsg] && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
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

	if (lineType == TVCLogLineActionType ||
		lineType == TVCLogLinePrivateMessageType ||
		lineType == TVCLogLineNoticeType)
	{
		[self receiveText:m lineType:lineType text:text];
	} else if (lineType == TVCLogLineCTCPQueryType) {
		[self receiveCTCPQuery:m text:text];
	} else if (lineType == TVCLogLineCTCPReplyType) {
		[self receiveCTCPReply:m text:text];
	}
}

- (void)receiveText:(IRCMessage *)m lineType:(TVCLogLineType)lineType text:(NSString *)text
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
			text = @" ";
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
	IRCAddressBookEntry *ignoreInfo = [self findAddressBookEntryForHostmask:m.senderHostmask
																withMatches:@[	IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey,
																				IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey,
																				IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey,
																				IRCAddressBookDictionaryValueIgnorePublicMessagesKey,
																				IRCAddressBookDictionaryValueIgnorePrivateMessagesKey	]];

	if (ignoreInfo.ignorePublicMessageHighlights) {
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

	/* Even though OTR doesn't allow channel decryption, we still wrap everything
	 in a decryption block because Blowfish plugin may swizzle the logic.
	 That plugin does support channel decryption. */
	BOOL performDecryption = YES;

	TLOEncryptionManagerEncodingDecodingCallbackBlock decryptionBlock = nil;

	/* Public message (directed at channel) */
	if ([self stringIsChannelName:target]) {
		if (ignoreInfo.ignorePublicMessages) {
			return;
		}

		decryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
			[self _receiveText_Public:m lineType:lineType target:target text:originalString wasEncrypted:wasEncrypted];
		};
	}

	/* Private message (from user) */
	else if (m.senderIsServer == NO) {
		if (ignoreInfo.ignorePrivateMessages) {
			return;
		}

		decryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
			[self _receiveText_Private:m lineType:lineType target:target text:originalString wasEncrypted:wasEncrypted];
		};
	}

	/* Private message (from server) */
	else {
		/* It is not possible to hold an OTR conversation with a server. */
		performDecryption = NO;

		decryptionBlock = ^(NSString *originalString, BOOL wasEncrypted) {
			[self _receiveText_PrivateServer:m lineType:lineType target:target text:originalString wasEncrypted:wasEncrypted];
		};
	}

	/* Perform decryption */
	if (performDecryption) {
		NSString *sender = m.senderNickname;

		[self decryptMessage:text from:sender target:target decodingCallback:decryptionBlock];
	} else {
		decryptionBlock(text, NO);
	}
}

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

	BOOL isSelfMessage = NO;

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage]) {
		isSelfMessage = [self nicknameIsMyself:sender];
	}

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
			if (isSelfMessage) {
				return;
			}

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
	IRCChannelUser *senderMember = [channel findMember:sender];

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

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage] ||
		[self isCapabilityEnabled:ClientIRCv3SupportedCapabilityZNCSelfMessage] ||
		self.isConnectedToZNC)
	{
		isSelfMessage = [self nicknameIsMyself:sender];
	}

	/* Does the query for the sender already exist?... */
	IRCChannel *query = nil;

	if (isSelfMessage) {
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

- (void)_receiveText_PrivateNoticeFromChanServ:(IRCChannel **)target text:(NSString **)text
{
	NSParameterAssert(target != NULL);
	NSParameterAssert(text != NULL);

	NSString *textIn = (*text);

	/* Forward entry messages to the channel they are associated with. */
	/* Format we are going for: -ChanServ- [#channelname] blah blah... */
	NSInteger spacePosition = [textIn stringPosition:@" "];

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

- (void)_receiveText_PrivateServer:(IRCMessage *)m lineType:(TVCLogLineType)lineType target:(NSString *)target text:(NSString *)text wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(m != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(text != nil);

	NSString *sender = m.senderNickname;

	BOOL isPlainText = (lineType != TVCLogLineNoticeType);

	IRCChannel *query = nil;

	/* For notices, send to a query if a query for the server already exists.
	 Otherwise, it is always sent to the console. Plain text messages always
	 create a new query but does not post a notification. */
	if (isPlainText == NO) {
		query = [self findChannel:sender];
	} else { // NOTICE message
		query = [self findChannelOrCreate:sender isPrivateMessage:YES];
	}

	/* Print message */
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

	if (printMessage) {
		[self print:text
				 by:sender
		  inChannel:query
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

- (void)receiveCTCPQuery:(IRCMessage *)m text:(NSString *)text
{
	NSParameterAssert(m != nil);
	NSParameterAssert(text != nil);

	/* Ignore messages echoed back to ourselves */
	NSString *sender = m.senderNickname;

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityEchoMessage]) {
		if ([self nicknameIsMyself:sender]) {
			return;
		}
	}

	/* Find ignore for sender and possibly exit method */
	IRCAddressBookEntry *ignoreInfo = [self findAddressBookEntryForHostmask:m.senderHostmask
																withMatches:@[IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey,
																			  IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey]];

	if (ignoreInfo.ignoreClientToClientProtocol) {
		return;
	}

	/* Context */
	NSMutableString *textMutable = [text mutableCopy];

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
		 receivedAt:m.receivedAt];
	}

	/* Respond to query with the value asked for */
	if (isLagCheckQuery)
	{
		[self receiveCTCPLagCheckQuery:m];
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
			LogToConsoleInfo("Ignoring PING query that exceeds 50 bytes");

			return;
		}

		[self sendCTCPReply:sender command:command text:textMutable];
	}

	/* TIME command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_time")])
	{
		NSDateFormatter *dateFormatter = TXSharedISOStandardDateFormatter();

		NSString *text = [dateFormatter stringFromDate:[NSDate date]];

		[self sendCTCPReply:sender command:command text:text];
	}

	/* USERINFO command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_userinfo")])
	{
		[self sendCTCPReply:sender command:command text:self.config.realName];
	}

	/* VERSION command */
	else if ([command isEqualToString:IRCPrivateCommandIndex("ctcp_version")])
	{
		NSString *fakeVersion = [TPCPreferences masqueradeCTCPVersion];

		if (fakeVersion.length > 0) {
			[self sendCTCPReply:sender command:command text:fakeVersion];

			return;
		}

		NSString *applicationName = [TPCApplicationInfo applicationNameWithoutVersion];
		NSString *versionShort = [TPCApplicationInfo applicationVersionShort];

		NSString *text = TXTLS(@"IRC[1026]", applicationName, versionShort);

		[self sendCTCPReply:sender command:command text:text];
	}
}

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

- (void)receiveCTCPReply:(IRCMessage *)m text:(NSString *)text
{
	NSParameterAssert(m != nil);
	NSParameterAssert(text != nil);

	/* Find ignore for sender and possibly exit method */
	IRCAddressBookEntry *ignoreInfo = [self findAddressBookEntryForHostmask:m.senderHostmask
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
	 receivedAt:m.receivedAt];
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

		if (channel.isActive == NO && channel.isChannel) {
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

		if (channel == nil || channel.isChannel == NO) {
			return;
		}
	}

	if (isPrintOnlyMessage == NO) {
		/* A user might already exist by having a private message open */
		IRCUserMutable *userMutable = [self mutableCopyOfUserWithNickname:sender];

		userMutable.nickname = m.senderNickname;
		userMutable.username = m.senderUsername;
		userMutable.address = m.senderAddress;

		IRCUser *userAdded = [self addUserAndReturn:userMutable];

		IRCChannelUser *member = [[IRCChannelUser alloc] initWithUser:userAdded];

		[channel addMember:member checkForDuplicates:YES];
	}

	if (isPrintOnlyMessage == NO && myself == NO) {
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
		[self findAddressBookEntryForHostmask:m.senderHostmask
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
			if (ignoreInfo && ignoreInfo.entryType == IRCAddressBookIgnoreEntryType) {
				printMessage = (ignoreInfo.ignoreGeneralEventMessages == NO);
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
			[self requestModesForChannel:channel];
		}
	} else {
		(void)[self notifyEvent:TXNotificationUserJoinedType lineType:TVCLogLineJoinType target:channel nickname:sender text:nil];
	}
}

- (void)receivePart:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	/* ZNC sends PART messages for every channel when the client disconnects to force
	 it to update its local status. This is incredibly misleading to the user, as they
	 see the message that they left the channel and believe they did. This condition
	 filters out these messages. Because Textual is intelligent enough to clear status
	 related to channels when the connection is quit, this is safe. */
	if (self.isQuitting && self.isConnectedToZNC) {
		return;
	}

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *channelName = [m paramAt:0];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil || channel.isChannel == NO) {
		return;
	}

	NSString *sender = m.senderNickname;

	NSString *comment = [m paramAt:1];

	BOOL myself = [self nicknameIsMyself:sender];

	if (isPrintOnlyMessage == NO) {
		if (myself) {
			[channel deactivate];

			[mainWindow() reloadTreeItem:channel];
		} else {
			[channel removeMemberWithNickname:sender];

			/* Notify user */
			(void)[self notifyEvent:TXNotificationUserPartedType lineType:TVCLogLinePartType target:channel nickname:sender text:comment];
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
			[self findAddressBookEntryForHostmask:m.senderHostmask
									  withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if (ignoreInfo && ignoreInfo.entryType == IRCAddressBookIgnoreEntryType) {
				printMessage = (ignoreInfo.ignoreGeneralEventMessages == NO);
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

- (void)receiveKick:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 1);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *channelName = [m paramAt:0];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil || channel.isChannel == NO) {
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

				[self performSelectorInCommonModes:@selector(joinKickedChannel:) withObject:channel afterDelay:3.0];
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
			[self findAddressBookEntryForHostmask:m.senderHostmask
									  withMatches:@[IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey]];

			if (ignoreInfo && ignoreInfo.entryType == IRCAddressBookIgnoreEntryType) {
				printMessage = (ignoreInfo.ignoreGeneralEventMessages == NO);
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

	IRCUser *user = nil;

	if (isPrintOnlyMessage == NO) {
		user = [self findUser:sender];

		if (user == nil) {
			return;
		}
	}

	IRCAddressBookEntry *ignoreInfo = nil;

	if (myself == NO) {
		ignoreInfo =
		[self findAddressBookEntryForHostmask:m.senderHostmask
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
			switch (channel.type) {
				case IRCChannelChannelType:
				{
					IRCChannelUser *member = [user userAssociatedWithChannel:channel];

					if (member == nil) {
						return;
					}

					[channel removeMember:member];

					break;
				}
				case IRCChannelPrivateMessageType:
				{
					if ([sender isEqualIgnoringCase:channel.name] == NO) {
						return;
					}

					if (channel.isActive) {
						[channel deactivate];

						[mainWindow() reloadTreeItem:channel];
					}

					break;
				}
				default:
				{
					return;
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
					if (ignoreInfo && ignoreInfo.entryType == IRCAddressBookIgnoreEntryType) {
						printMessage = (ignoreInfo.ignoreGeneralEventMessages == NO);
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

		(void)[self notifyEvent:TXNotificationUserDisconnectedType lineType:TVCLogLineQuitType target:nil nickname:sender text:comment];
	}
}

- (void)receiveKill:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	NSString *nickname = [m paramAt:0];

	for (IRCChannel *c in self.channelList) {
		[c removeMemberWithNickname:nickname];
	}
}

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
		[self findAddressBookEntryForHostmask:m.senderHostmask
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

			/* Reload window title (our nickname is shown there) */
			[mainWindow() updateTitleFor:self];
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
			[self findAddressBookEntryForHostmask:newNicknameHostmask
									  withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

			if (newNicknameIgnoreInfo) {
				[self updateUserTrackingStatusForEntry:newNicknameIgnoreInfo withMessage:m];
			}
		}

		/* Inform style of change */
		[self postEventToViewController:@"nicknameChanged"];
	}

	/* Inform observers */
	[RZNotificationCenter() postNotificationName:IRCClientUserNicknameChangedNotification
										  object:self
										userInfo:@{
											@"oldNickname" : oldNickname,
											@"newNickname" : newNickname
										}];

	/* Look for user */
	IRCUser *user = nil;

	if (isPrintOnlyMessage == NO) {
		user = [self findUser:oldNickname];

		if (user == nil) {
			return;
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
			switch (channel.type) {
				case IRCChannelChannelType:
				{
					/* Rename the user in the channel */
					IRCChannelUser *member = [user userAssociatedWithChannel:channel];

					if (member == nil) {
						return;
					}

					[channel resortMember:member];

					break;
				}
				case IRCChannelPrivateMessageType:
				{
					/* Rename private message if one with old name is found */
					if ([oldNickname isEqualIgnoringCase:channel.name] == NO) {
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

					break;
				}
				default:
				{
					return;
				}
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
					if (oldNicknameIgnoreInfo && oldNicknameIgnoreInfo.entryType == IRCAddressBookIgnoreEntryType) {
						printMessage = (oldNicknameIgnoreInfo.ignoreGeneralEventMessages == NO);
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
	[self renameUser:user to:newNickname];

	for (IRCChannel *c in self.channelList) {
		printingBlock(c);
	}
}

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

	if (channel == nil || channel.isChannel == NO) {
		return;
	}

	if (isPrintOnlyMessage == NO) {
		NSArray *modes = [channel.modeInfo updateModes:modeString];

		for (IRCModeInfo *mode in modes) {
			if ([mode isModeForChangingMemberModeOn:self] == NO) {
				continue;
			}

			[channel changeMember:mode.modeParameter mode:mode.modeSymbol value:mode.modeIsSet];
		}
	}

	BOOL printMessage = [self postReceivedMessage:m withText:modeString destinedFor:channel];

	if (printMessage) {
		printMessage = ([TPCPreferences showJoinLeave] && channel.config.ignoreGeneralEventMessages == NO);
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

- (void)receiveTopic:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] == 2);

	BOOL isPrintOnlyMessage = m.isPrintOnlyMessage;

	NSString *sender = m.senderNickname;

	NSString *channelName = [m paramAt:0];
	NSString *topic = [m paramAt:1];

	IRCChannel *channel = [self findChannel:channelName];

	if (channel == nil || channel.isChannel == NO) {
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

- (void)receiveBatch:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] >= 1);

	NSString *batchToken = [m paramAt:0];

	if (batchToken.length <= 1) {
		LogToConsoleError("Cannot process BATCH command because [batchToken length] <= 1");

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
		LogToConsoleError("Cannot process BATCH command because there was no open or close modifier");

		return;
	}

	if ([batchToken onlyContainsCharactersFromCharacterSet:[NSCharacterSet Ato9UnderscoreDash]] == NO) {
		LogToConsoleError("Cannot process BATCH command because the batch token contains illegal characters");

		return;
	}

	if (isBatchOpening == NO)
	{
		/* Find batch message matching known token */
		IRCMessageBatchMessage *thisBatchMessage = [self.batchMessages queuedEntryWithBatchToken:batchToken];

		if (thisBatchMessage == nil) {
			LogToConsoleError("Cannot process BATCH command because -queuedEntryWithBatchToken: returned nil");

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

		newBatchMessage.batchIsOpen = YES;

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
#pragma mark BATCH Command

- (id)queuedBatchMessageWithToken:(NSString *)batchToken
{
	return [self.batchMessages queuedEntryWithBatchToken:batchToken];
}

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

- (void)recursivelyProcessBatchMessage:(IRCMessageBatchMessage *)batchMessage
{
	[self recursivelyProcessBatchMessage:batchMessage depth:0];
}

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
#pragma mark Server Capability

- (void)enableCapability:(ClientIRCv3SupportedCapabilities)capability
{
	if ([self isCapabilityEnabled:capability] == NO) {
		self->_capabilities |= capability;
	}
}

- (void)disableCapability:(ClientIRCv3SupportedCapabilities)capability
{
	if ([self isCapabilityEnabled:capability]) {
		self->_capabilities &= ~capability;
	}
}

- (BOOL)isCapabilityEnabled:(ClientIRCv3SupportedCapabilities)capability
{
	return ((self->_capabilities & capability) == capability);
}

- (void)enablePendingCapability:(ClientIRCv3SupportedCapabilities)capability
{
	@synchronized (self.capabilitiesPending) {
		[self.capabilitiesPending addObjectWithoutDuplication:@(capability)];
	}
}

- (void)disablePendingCapability:(ClientIRCv3SupportedCapabilities)capability
{
	@synchronized (self.capabilitiesPending) {
		[self.capabilitiesPending removeObject:@(capability)];
	}
}

- (BOOL)isPendingCapabilityEnabled:(ClientIRCv3SupportedCapabilities)capability
{
	@synchronized (self.capabilitiesPending) {
		return [self.capabilitiesPending containsObject:@(capability)];
	}
}

- (nullable NSString *)capabilityStringValue:(ClientIRCv3SupportedCapabilities)capability
{
	NSString *stringValue = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch"

	switch (capability) {
		case ClientIRCv3SupportedCapabilityAwayNotify:
		{
			stringValue = @"away-notify";

			break;
		}
		case ClientIRCv3SupportedCapabilityBatch:
		{
			stringValue = @"batch";

			break;
		}
		case ClientIRCv3SupportedCapabilityEchoMessage:
		{
			stringValue = @"echo-message";

			break;
		}
		case ClientIRCv3SupportedCapabilityIdentifyCTCP:
		{
			stringValue = @"identify-ctcp";

			break;
		}
		case ClientIRCv3SupportedCapabilityIdentifyMsg:
		{
			stringValue = @"identify-msg";

			break;
		}
		case ClientIRCv3SupportedCapabilityMultiPreifx:
		{
			stringValue = @"multi-prefix";

			break;
		}
		case ClientIRCv3SupportedCapabilityPlayback:
		{
			stringValue = @"playback";

			break;
		}
		case ClientIRCv3SupportedCapabilitySASLExternal:
		case ClientIRCv3SupportedCapabilitySASLPlainText:
		case ClientIRCv3SupportedCapabilitySASLGeneric:
		case ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL:
		case ClientIRCv3SupportedCapabilityIsInSASLNegotiation:
		{
			stringValue = @"sasl";

			break;
		}
		case ClientIRCv3SupportedCapabilityServerTime:
		{
			stringValue = @"server-time";

			break;
		}
		case ClientIRCv3SupportedCapabilityUserhostInNames:
		{
			stringValue = @"userhost-in-names";

			break;
		}
		case ClientIRCv3SupportedCapabilityMonitorCommand:
		{
			stringValue = @"monitor-command";

			break;
		}
		case ClientIRCv3SupportedCapabilityWatchCommand:
		{
			stringValue = @"watch-command";

			break;
		}
		case ClientIRCv3SupportedCapabilityPlanioPlayback:
		{
			stringValue = @"plan.io/playback";

			break;
		}
		case ClientIRCv3SupportedCapabilityZNCCertInfoModule:
		{
			stringValue = @"znc.in/tlsinfo";

			break;
		}
		case ClientIRCv3SupportedCapabilityZNCPlaybackModule:
		{
			stringValue = @"znc.in/playback";

			break;
		}
		case ClientIRCv3SupportedCapabilityZNCSelfMessage:
		{
			stringValue = @"znc.in/self-message";

			break;
		}
		case ClientIRCv3SupportedCapabilityZNCServerTime:
		{
			stringValue = @"znc.in/server-time";

			break;
		}
		case ClientIRCv3SupportedCapabilityZNCServerTimeISO:
		{
			stringValue = @"znc.in/server-time-iso";

			break;
		}
	}

#pragma clang diagnostic pop

	return stringValue;
}

- (ClientIRCv3SupportedCapabilities)capabilityFromStringValue:(NSString *)capabilityString
{
	NSParameterAssert(capabilityString != nil);

	if ([capabilityString isEqualIgnoringCase:@"away-notify"]) {
		return ClientIRCv3SupportedCapabilityAwayNotify;
	} else if ([capabilityString isEqualIgnoringCase:@"batch"]) {
		return ClientIRCv3SupportedCapabilityBatch;
	} else if ([capabilityString isEqualIgnoringCase:@"echo-message"]) {
		return ClientIRCv3SupportedCapabilityEchoMessage;
	} else if ([capabilityString isEqualIgnoringCase:@"multi-prefix"]) {
		return ClientIRCv3SupportedCapabilityMultiPreifx;
	} else if ([capabilityString isEqualIgnoringCase:@"identify-msg"]) {
		return ClientIRCv3SupportedCapabilityIdentifyMsg;
	} else if ([capabilityString isEqualIgnoringCase:@"identify-ctcp"]) {
		return ClientIRCv3SupportedCapabilityIdentifyCTCP;
	} else if ([capabilityString isEqualIgnoringCase:@"sasl"]) {
		return ClientIRCv3SupportedCapabilitySASLGeneric;
	} else if ([capabilityString isEqualIgnoringCase:@"server-time"]) {
		return ClientIRCv3SupportedCapabilityServerTime;
	} else if ([capabilityString isEqualIgnoringCase:@"userhost-in-names"]) {
		return ClientIRCv3SupportedCapabilityUserhostInNames;
	} else if ([capabilityString isEqualIgnoringCase:@"plan.io/playback"]) {
		return ClientIRCv3SupportedCapabilityPlanioPlayback;
	} else if ([capabilityString isEqualIgnoringCase:@"znc.in/playback"]) {
		return ClientIRCv3SupportedCapabilityZNCPlaybackModule;
	} else if ([capabilityString isEqualIgnoringCase:@"znc.in/self-message"]) {
		return ClientIRCv3SupportedCapabilityZNCSelfMessage;
	} else if ([capabilityString isEqualIgnoringCase:@"znc.in/server-time"]) {
		return ClientIRCv3SupportedCapabilityZNCServerTime;
	} else if ([capabilityString isEqualIgnoringCase:@"znc.in/server-time-iso"]) {
		return ClientIRCv3SupportedCapabilityZNCServerTimeISO;
	} else if ([capabilityString isEqualIgnoringCase:@"znc.in/tlsinfo"]) {
		return ClientIRCv3SupportedCapabilityZNCCertInfoModule;
	}

	return 0;
}

- (NSString *)enabledCapabilitiesStringValue
{
	NSMutableArray *enabledCapabilities = [NSMutableArray array];

	void (^appendValue)(ClientIRCv3SupportedCapabilities) = ^(ClientIRCv3SupportedCapabilities capability) {
		if ([self isCapabilityEnabled:capability] == NO) {
			return;
		}

		NSString *stringValue = [self capabilityStringValue:capability];

		if (stringValue) {
			[enabledCapabilities addObject:stringValue];
		}
	};

	appendValue(ClientIRCv3SupportedCapabilityAwayNotify);
	appendValue(ClientIRCv3SupportedCapabilityBatch);
	appendValue(ClientIRCv3SupportedCapabilityEchoMessage);
	appendValue(ClientIRCv3SupportedCapabilityIdentifyCTCP);
	appendValue(ClientIRCv3SupportedCapabilityIdentifyMsg);
	appendValue(ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL);
	appendValue(ClientIRCv3SupportedCapabilityMultiPreifx);
	appendValue(ClientIRCv3SupportedCapabilityPlayback);
	appendValue(ClientIRCv3SupportedCapabilityServerTime);
	appendValue(ClientIRCv3SupportedCapabilityUserhostInNames);
	appendValue(ClientIRCv3SupportedCapabilityZNCCertInfoModule);
	appendValue(ClientIRCv3SupportedCapabilityZNCPlaybackModule);
	appendValue(ClientIRCv3SupportedCapabilityZNCSelfMessage);

	NSString *stringValue = [enabledCapabilities componentsJoinedByString:@", "];

	return stringValue;
}

- (void)sendNextCapability
{
	if (self.capabilityNegotiationIsPaused) {
		return;
	}

	@synchronized (self.capabilitiesPending) {
		/* -CapabilitiesPending can contain values that are used internally for state traking 
		 and should never meet the socket. To workaround this as best we can, we scan the 
		 array for the first capability that is acceptable for negotation. */
		NSUInteger nextCapabilityIndex =
		[self.capabilitiesPending indexOfObjectPassingTest:^BOOL(NSNumber *capabilityPending, NSUInteger index, BOOL *stop) {
			ClientIRCv3SupportedCapabilities capability = capabilityPending.unsignedIntegerValue;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"

			return
			(capability == ClientIRCv3SupportedCapabilityAwayNotify				||
			 capability == ClientIRCv3SupportedCapabilityBatch					||
			 capability == ClientIRCv3SupportedCapabilityEchoMessage			||
			 capability == ClientIRCv3SupportedCapabilityIdentifyCTCP			||
			 capability == ClientIRCv3SupportedCapabilityIdentifyMsg			||
			 capability == ClientIRCv3SupportedCapabilityMultiPreifx			||
			 capability == ClientIRCv3SupportedCapabilitySASLGeneric			||
			 capability == ClientIRCv3SupportedCapabilityServerTime				||
			 capability == ClientIRCv3SupportedCapabilityUserhostInNames		||
			 capability == ClientIRCv3SupportedCapabilityPlanioPlayback			||
			 capability == ClientIRCv3SupportedCapabilityZNCCertInfoModule		||
			 capability == ClientIRCv3SupportedCapabilityZNCPlaybackModule		||
			 capability == ClientIRCv3SupportedCapabilityZNCSelfMessage			||
			 capability == ClientIRCv3SupportedCapabilityZNCServerTime			||
			 capability == ClientIRCv3SupportedCapabilityZNCServerTimeISO);

#pragma clang diagnostic pop
		}];

		if (nextCapabilityIndex == NSNotFound) {
			[self sendCapability:@"END" data:nil];

			return;
		}

		ClientIRCv3SupportedCapabilities capability =
		[self.capabilitiesPending unsignedIntegerAtIndex:nextCapabilityIndex];

		[self.capabilitiesPending removeObjectAtIndex:nextCapabilityIndex];

		NSString *stringValue = [self capabilityStringValue:capability];

		[self sendCapability:@"REQ" data:stringValue];
	}
}

- (void)pauseCapabilityNegotation
{
	self.capabilityNegotiationIsPaused = YES;
}

- (void)resumeCapabilityNegotation
{
	self.capabilityNegotiationIsPaused = NO;

	[self sendNextCapability];
}

- (BOOL)isCapabilitySupported:(NSString *)capabilityString
{
	NSParameterAssert(capabilityString != nil);

	// Information about several of these supported CAP
	// extensions can be found at: http://ircv3.atheme.org

	if ([capabilityString isEqualIgnoringCase:@"echo-message"]) {
		return [TPCPreferences enableEchoMessageCapability];
	}

	return
	([capabilityString isEqualIgnoringCase:@"away-notify"]			||
	 [capabilityString isEqualIgnoringCase:@"batch"]					||
	 [capabilityString isEqualIgnoringCase:@"identify-ctcp"]			||
	 [capabilityString isEqualIgnoringCase:@"identify-msg"]			||
	 [capabilityString isEqualIgnoringCase:@"multi-prefix"]			||
	 [capabilityString isEqualIgnoringCase:@"sasl"]					||
	 [capabilityString isEqualIgnoringCase:@"server-time"]			||
	 [capabilityString isEqualIgnoringCase:@"userhost-in-names"]		||
	 [capabilityString isEqualIgnoringCase:@"plan.io/playback"]		||
	 [capabilityString isEqualIgnoringCase:@"znc.in/playback"]		||
	 [capabilityString isEqualIgnoringCase:@"znc.in/self-message"]	||
	 [capabilityString isEqualIgnoringCase:@"znc.in/server-time"]		||
	 [capabilityString isEqualIgnoringCase:@"znc.in/server-time-iso"]	||
	 [capabilityString isEqualIgnoringCase:@"znc.in/tlsinfo"]);
}

- (void)toggleCapability:(NSString *)capabilityString enabled:(BOOL)enabled
{
	[self toggleCapability:capabilityString enabled:enabled isUpdateRequest:NO];
}

- (void)toggleCapability:(NSString *)capabilityString enabled:(BOOL)enabled isUpdateRequest:(BOOL)isUpdateRequest
{
	NSParameterAssert(capabilityString != nil);

	if ([capabilityString isEqualIgnoringCase:@"sasl"]) {
		if (enabled) {
			if ([self sendSASLIdentificationRequest]) {
				[self pauseCapabilityNegotation];
			}
		}

		return;
	}

	ClientIRCv3SupportedCapabilities capability = [self capabilityFromStringValue:capabilityString];

	if (capability == 0) {
		return;
	}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"

	if (capability == ClientIRCv3SupportedCapabilityZNCServerTime ||
		capability == ClientIRCv3SupportedCapabilityZNCServerTimeISO)
	{
		capability = ClientIRCv3SupportedCapabilityServerTime;
	}

	if (capability == ClientIRCv3SupportedCapabilityPlanioPlayback ||
		capability == ClientIRCv3SupportedCapabilityZNCPlaybackModule)
	{
		capability = ClientIRCv3SupportedCapabilityPlayback;
	}

#pragma clang diagnostic pop

	if (enabled) {
		[self enableCapability:capability];
	} else {
		[self disableCapability:capability];
	}
}

- (void)processPendingCapability:(NSString *)capabilityString
{
	NSParameterAssert(capabilityString != nil);

	NSArray *components = [capabilityString componentsSeparatedByString:@"="];

	NSString *capability = capabilityString;

	NSArray<NSString *> *capabilityOptions = nil;

	if (components.count == 2) {
		capability = components[0];

		capabilityOptions = [components[1] componentsSeparatedByString:@","];
	}

	[self processPendingCapability:capability options:capabilityOptions];
}

- (void)processPendingCapability:(NSString *)capabilityString options:(nullable NSArray<NSString *> *)capabilityOpions
{
	NSParameterAssert(capabilityString != nil);

	if ([self isCapabilitySupported:capabilityString] == NO) {
		return;
	}

	if ([capabilityString isEqualToString:@"sasl"]) {
		[self processPendingCapabilityForSASL:capabilityOpions];

		return;
	}

	ClientIRCv3SupportedCapabilities capability = [self capabilityFromStringValue:capabilityString];

	[self enablePendingCapability:capability];
}

- (void)receiveCapabilityOrAuthenticationRequest:(IRCMessage *)m
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
				[self processPendingCapability:cap];
			}
		} else if ([subcommand isEqualIgnoringCase:@"ACK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapability:cap enabled:YES isUpdateRequest:NO];
			}
		} else if ([subcommand isEqualIgnoringCase:@"NAK"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapability:cap enabled:NO isUpdateRequest:NO];
			}
		} else if ([subcommand isEqualIgnoringCase:@"NEW"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapability:cap enabled:YES isUpdateRequest:YES];
			}
		} else if ([subcommand isEqualIgnoringCase:@"DEL"]) {
			NSArray *caps = [actions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			for (NSString *cap in caps) {
				[self toggleCapability:cap enabled:NO isUpdateRequest:YES];
			}
		}

		[self sendNextCapability];
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
#pragma mark SASL Negotation

- (void)processPendingCapabilityForSASL:(nullable NSArray<NSString *> *)capabilityOptions
{
	ClientIRCv3SupportedCapabilities identificationMechanism = 0;

	if (self.socket.isConnectedWithClientSideCertificate &&
		self.config.saslAuthenticationDisableExternalMechanism == NO)
	{
		if (capabilityOptions.count == 0 ||
			[capabilityOptions containsObjectIgnoringCase:@"EXTERNAL"])
		{
			identificationMechanism = ClientIRCv3SupportedCapabilitySASLExternal;

			[self enablePendingCapability:ClientIRCv3SupportedCapabilitySASLExternal];
		}
	}

	if (identificationMechanism == 0 &&
		self.config.nicknamePassword.length > 0)
	{
		if (capabilityOptions.count == 0 ||
			[capabilityOptions containsObjectIgnoringCase:@"PLAIN"])
		{
			identificationMechanism = ClientIRCv3SupportedCapabilitySASLPlainText;

			[self enablePendingCapability:ClientIRCv3SupportedCapabilitySASLPlainText];
		}
	}

	if (identificationMechanism != 0) {
		[self enablePendingCapability:ClientIRCv3SupportedCapabilitySASLGeneric];
	}
}

- (void)sendSASLIdentificationInformation
{
	if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilityIsInSASLNegotiation] == NO) {
		return;
	}

	if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilitySASLPlainText])
	{
		NSString *authString = [NSString stringWithFormat:@"%@%C%@%C%@",
								 self.config.username, 0x00,
								 self.config.username, 0x00,
								 self.config.nicknamePassword];

		NSArray *authStrings = [authString base64EncodingWithLineLength:400];

		for (NSString *string in authStrings) {
			[self sendCapabilityAuthenticate:string];
		}

		if (authStrings.count == 0 || ((NSString *)authStrings.lastObject).length == 400) {
			[self sendCapabilityAuthenticate:@"+"];
		}
	}
	else if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilitySASLExternal])
	{
		[self sendCapabilityAuthenticate:@"+"];
	}
}

- (BOOL)sendSASLIdentificationRequest
{
	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL]) {
		return NO;
	}

	if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilityIsInSASLNegotiation]) {
		return NO;
	}

	[self enablePendingCapability:ClientIRCv3SupportedCapabilityIsInSASLNegotiation];

	if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilitySASLPlainText]) {
		[self sendCapabilityAuthenticate:@"PLAIN"];

		return YES;
	} else if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilitySASLExternal]) {
		[self sendCapabilityAuthenticate:@"EXTERNAL"];

		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Protocol Handlers

- (void)receivePing:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSAssertReturn([m paramsCount] > 0);

	NSString *token = [m sequence:0];

	[self sendPong:token];

	(void)[self postReceivedMessage:m];
}

- (void)receiveAwayNotifyCapability:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityAwayNotify] == NO) {
		return;
	}

	BOOL away = NSObjectIsNotEmpty(m.sequence);

	NSString *nickname = m.senderNickname;

	[self modifyUserWithNickname:nickname asAway:away];
}

- (void)receiveInit:(IRCMessage *)m // Raw numeric = 001
{
	NSParameterAssert(m != nil);

	/* Manage timers */
	[self startPongTimer];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[self startSoftwareTrialTimer];
#endif

	[self stopRetryTimer];

	/* Manage properties */
	self.isLoggedIn = YES;

	self.supportInfo.serverAddress = m.senderHostmask;

	self.invokingISONCommandForFirstTime = YES;

	self.reconnectEnabledBecauseOfSleepMode = NO;

	self.tryingNicknameSentNickname = nil;

	self.userNickname = [m paramAt:0];

	self.successfulConnects += 1;

	/* Begin enforcing flood control */
	[self.socket enforceFloodControl];

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
	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityZNCCertInfoModule]) {
		[self sendCommand:@"send-data" toZNCModuleNamed:@"tlsinfo"];
	}

	/* Request playback since the last seen message when previously connected */
	[self requestPlayback];

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
	if (self.config.autojoinWaitsForNickServ == NO || [self isCapabilityEnabled:ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL]) {
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
			[self performSelectorInCommonModes:@selector(performAutoJoin) withObject:nil afterDelay:3.0];
		} else {
			[self startAutojoinDelayedWarningTimer];
		}
	}

	/* We need time for the server to send its configuration */
	[self performSelectorInCommonModes:@selector(populateISONTrackedUsersList) withObject:nil afterDelay:10.0];
}

- (void)receiveNumericReply:(IRCMessage *)m
{
	NSParameterAssert(m != nil);

	NSInteger numeric = m.commandNumeric;

	if (numeric > 400 && numeric < 597 && numeric != 403 && numeric != 422) {
		[self receiveErrorNumericReply:m];

		return;
	}

	BOOL printMessage = YES;

	if (numeric != 324 &&
		numeric != 332 &&
		numeric != 333)
	{
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
			NSAssertReturn([m paramsCount] >= 2);

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
				[self enableCapability:ClientIRCv3SupportedCapabilityIdentifyMsg];
			} else if ([kind isEqualIgnoringCase:@"identify-ctcp"]) {
				[self enableCapability:ClientIRCv3SupportedCapabilityIdentifyCTCP];
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
			}

			IRCUser *user = [self findUser:awayNickname];

			if ( user) {
				if (self.monitorAwayStatus) {
					[user markAsAway];
				}

				if (user.presentAwayMessageFor301 == NO) {
					break;
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
			
			[mainWindow() updateTitleFor:self];

			if (printMessage) {
				[self printUnknownReply:m];
			}

			/* Update our own status. This has to only be done with away-notify CAP enabled.
			 Old, WHO based information requests will still show our own status. */
			if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityAwayNotify] == NO) {
				break;
			}

			IRCUser *myself = self.myself;

			if (myself == nil) {
				break;
			}
			
			BOOL away = (numeric == 306);

			[self modifyUser:myself asAway:away];

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
				NSString *timeInfo = TXFormatDateLongStyle(serverInfo, YES);

				if (timeInfo == nil) {
					timeInfo = serverInfo;
				}

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

			connectTime = TXFormatDateLongStyle(connTimeDate, YES);

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

			if (channel.channelModesReceived == NO) {
				channel.channelModesReceived = YES;
			} else {
				if (self.inUserInvokedModeRequest) {
					[self disableInUserInvokedCommandProperty:&self->_inUserInvokedModeRequest];
				} else {
					break;
				}
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

			NSString *channelName = [m paramAt:1];

			IRCChannel *channel = [self findChannel:channelName];

			if (channel == nil) {
				break;
			}

			printMessage = [self postReceivedMessage:m withText:nil destinedFor:channel];

			if (printMessage == NO) {
				return;
			}

			NSString *topicSetter = [m paramAt:2];
			NSString *setTime = [m paramAt:3];

			topicSetter = topicSetter.nicknameFromHostmask;

			NSDate *setTimeDate = [NSDate dateWithTimeIntervalSince1970:setTime.doubleValue];

			setTime = TXFormatDateLongStyle(setTimeDate, YES);

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
			NSDictionary *trackedUsers = self.trackedUsers.trackedUsers;

			[trackedUsers enumerateKeysAndObjectsUsingBlock:^(NSString *trackedUser, NSNumber *trackingStatusInt, BOOL *stop) {
				IRCAddressBookUserTrackingStatus trackingStatus =
				IRCAddressBookUserTrackingUnknownStatus;

				/* Was the user on during the last check? */
				BOOL ison = trackingStatusInt.boolValue;

				if (ison) {
					/* If the user was on before, but is not in the list of ISON
					 users in this reply, then they are considered gone. Log that. */
					if ([onlineNicknames containsObjectIgnoringCase:trackedUser] == NO) {
						if (self.invokingISONCommandForFirstTime == NO) {
							trackingStatus = IRCAddressBookUserTrackingSignedOffStatus;
						}
					}
				} else {
					/* If they were not on but now are, then log that too. */
					if ([onlineNicknames containsObjectIgnoringCase:trackedUser]) {
						if (self.invokingISONCommandForFirstTime) {
							trackingStatus = IRCAddressBookUserTrackingIsAvailalbeStatus;
						} else {
							trackingStatus = IRCAddressBookUserTrackingSignedOnStatus;
						}
					}
				}

				/* If something changed (non-nil localization string), then scan 
				 the list of address book entries to report the result. */
				if (trackingStatus != IRCAddressBookUserTrackingUnknownStatus) {
					[self statusOfTrackedNickname:trackedUser changedTo:trackingStatus notify:YES];
				}
			}]; // for

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
					if (self.monitorAwayStatus) {
						isAway = YES;
					}
				}
			}

			flags = [flags substringFromIndex:1];

			if ([flags contains:@"*"]) {
				flags = [flags substringFromIndex:1];

				isIRCop = YES;
			}

			/* Find global user and create mutable copy */
			IRCUser *user = [self findUser:nickname];

			IRCUserMutable *userMutable = nil;

			if (user == nil) {
				userMutable = [[IRCUserMutable alloc] initWithNickname:nickname onClient:self];
			} else {
				userMutable = [user mutableCopy];
			}

			userMutable.nickname = nickname;
			userMutable.username = username;
			userMutable.address = address;

			userMutable.isAway = isAway;
			userMutable.isIRCop = isIRCop;

			/* Parameter 7 includes the hop count and real name because it begins with a :
			 Therefore, we cut after the first space to get the real, real name value. */
			NSInteger realNameFirstSpace = [realName stringPosition:@" "];

			if (realNameFirstSpace > 0 && realNameFirstSpace < realName.length) {
				realName = [realName substringAfterIndex:realNameFirstSpace];
			}

			userMutable.realName = realName;

			/* Insert the user into the client and return the final copy that was */
			IRCUser *userAdded = [self addUserAndReturn:userMutable];

			/* Find the user associated with this channel and create mutable copy */
			IRCChannelUser *member = [user userAssociatedWithChannel:channel];

			IRCChannelUserMutable *memberMutable = nil;

			if (member == nil) {
				memberMutable = [[IRCChannelUserMutable alloc] initWithUser:userAdded];
			} else {
				memberMutable = [member mutableCopy];
			}

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
				/* Dtermine whether the users were modified in such a way that
				 they require their cell in the user list be resorted. */
				/* We do not want to resort unless absolutely necessary because
				 sorting a user with a few hundred users has overhead. */
				BOOL IRCopStatusChanged = (user.isIRCop != userMutable.isIRCop);

				BOOL resortMember =
				(IRCopStatusChanged || NSObjectsAreEqual(member.modes, memberMutable.modes) == NO);

				BOOL replaceInAllChannels =
				(IRCopStatusChanged && [TPCPreferences memberListSortFavorsServerStaff]);

				[channel replaceMember:member
							withMember:memberMutable
								resort:resortMember
				  replaceInAllChannels:replaceInAllChannels];
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

				/* If we are connected to a bouncer, then we may receive a NAMES reply
				 multiple times, even after first joining channels. Because of this, 
				 we create a mutable copy of the user if they already exist, similiar
				 to how WHO replies are handled, so that we do not lose any state. */

				/* Create global user */
				IRCUserMutable *userMutable = [self mutableCopyOfUserWithNickname:nicknameInt];

				userMutable.nickname = nicknameInt;
				userMutable.username = usernameInt;
				userMutable.address = addressInt;

				IRCUser *userAdded = [self addUserAndReturn:userMutable];

				/* Create local user */
				IRCChannelUser *member = [userMutable userAssociatedWithChannel:channel];

				IRCChannelUserMutable *memberMutable = nil;

				if (member == nil) {
					memberMutable = [[IRCChannelUserMutable alloc] initWithUser:userAdded];
				} else {
					memberMutable = [member mutableCopy];
				}

				memberMutable.modes = memberModes;

				/* Add user to channel */
				[channel addMember:memberMutable checkForDuplicates:YES];
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
						[self sendModes:defaultModes withParametersString:nil inChannel:channel];
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

			if ([channel isEqualToString:@"*"]) {
				break;
			}

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
		case 728: // RPL_QUIETLIST
		{
			NSAssertReturn([m paramsCount] > 2);

			NSUInteger paramsOffset = 0;

			if (numeric == 728 && m.paramsCount == 6) { // server author was like "fuck you"
				paramsOffset = 1;
			}

			NSString *channelName = [m paramAt:1];

			NSString *entryMask = [m paramAt:(2 + paramsOffset)];

			NSString *entryAuthor = nil;

			NSDate *entryCreationDate = nil;

			BOOL extendedLine = (m.paramsCount > (4 + paramsOffset));

			if (extendedLine) {
				entryAuthor = [m paramAt:(3 + paramsOffset)].nicknameFromHostmask;

				entryCreationDate = [NSDate dateWithTimeIntervalSince1970:[m paramAt:(4 + paramsOffset)].doubleValue];
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
			} else if (numeric == 728) { // RPL_QUIETLIST
				localization = @"1119";
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
		case 729: // RPL_ENDOFQUIETLIST
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
		case 732: // RPL_MONLIST
		case 733: // RPL_ENDOFMONLIST
		case 734: // ERR_MONLISTFULL
		{
			if (self.inUserInvokedWatchRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}
			}

			if (numeric == 608 || numeric == 607 || numeric == 733) {
				[self disableInUserInvokedCommandProperty:&self->_inUserInvokedWatchRequest];
			}

			break;
		}
		case 597: // RPL_REAWAY
		case 598: // RPL_GONEAWAY
		case 599: // RPL_NOTAWAY
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
			[self findAddressBookEntryForHostmask:hostmask
									  withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

			if (addressBookEntry == nil) {
				break;
			}

			switch (numeric) {
				case 600: // logged online
				{
					[self statusOfTrackedNickname:nickname changedTo:IRCAddressBookUserTrackingSignedOnStatus notify:YES];
					
					break;
				}
				case 601: // logged offline
				{
					[self statusOfTrackedNickname:nickname changedTo:IRCAddressBookUserTrackingSignedOffStatus notify:YES];
					
					break;
				}
				case 604: // is online
				{
					[self statusOfTrackedNickname:nickname changedTo:IRCAddressBookUserTrackingIsAvailalbeStatus notify:NO];
					
					break;
				}
				case 605: // is offline
				{
					[self statusOfTrackedNickname:nickname changedTo:IRCAddressBookUserTrackingIsNotAvailalbeStatus notify:NO];
					
					break;
				}
				case 597:
				case 598: // is away
				{
					[self modifyUserWithNickname:nickname asAway:YES];
					
					break;
				}
				case 599: // is no longer away
				{
					[self modifyUserWithNickname:nickname asAway:NO];
					
					break;
				}
				default:
				{
					break;
				}
			} // switch()

			break;
		}
		case 730: // RPL_MONONLINE
		case 731: // RPL_MONOFFLINE
		{
			NSAssertReturn([m paramsCount] == 2);

			if (self.inUserInvokedWatchRequest) {
				if (printMessage) {
					[self printUnknownReply:m];
				}

				break;
			}

			NSString *changedUsersString = [m paramAt:1];

			NSArray *changedUsers = [changedUsersString componentsSeparatedByString:@","];

			for (NSString *changedUser in changedUsers) {
				NSString *hostmask = nil;

				NSString *nicknameInt = nil;
				NSString *usernameInt = nil;
				NSString *addressInt = nil;

				if ([changedUser hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt onClient:self]) {
					hostmask = changedUser;
				} else {
					hostmask = [NSString stringWithFormat:@"%@!*@*", changedUser];

					nicknameInt = changedUser;
				}

				IRCAddressBookEntry *addressBookEntry =
				[self findAddressBookEntryForHostmask:hostmask
										  withMatches:@[IRCAddressBookDictionaryValueTrackUserActivityKey]];

				if (addressBookEntry == nil) {
					continue;
				}

				if (numeric == 730) { // logged online
					[self statusOfTrackedNickname:nicknameInt changedTo:IRCAddressBookUserTrackingSignedOnStatus notify:YES];
				} else {
					[self statusOfTrackedNickname:nicknameInt changedTo:IRCAddressBookUserTrackingSignedOffStatus notify:YES];
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

			[self enableCapability:ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL];

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

			if ([self isPendingCapabilityEnabled:ClientIRCv3SupportedCapabilityIsInSASLNegotiation]) {
				[self disablePendingCapability:ClientIRCv3SupportedCapabilityIsInSASLNegotiation];

				[self resumeCapabilityNegotation];
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
#pragma mark Autojoin

- (void)startAutojoinDelayedWarningTimer
{
	if (self.autojoinDelayedWarningTimer.timerIsActive) {
		return;
	}

	[self.autojoinDelayedWarningTimer start:_autojoinDelayedWarningInterval];
}

- (void)stopAutojoinDelayedWarningTimer
{
	if (self.autojoinDelayedWarningTimer.timerIsActive == NO) {
		return;
	}

	[self.autojoinDelayedWarningTimer stop];
}

- (void)onAutojoinDelayedWarningTimer:(id)sender
{
	if (self.isLoggedIn == NO ||
		self.config.hideAutojoinDelayedWarnings ||
		self.autojoinDelayedWarningCount >= _autojoinDelayedWarningMaxCount)
	{
		[self stopAutojoinDelayedWarningTimer];

		return;
	}

	self.autojoinDelayedWarningCount += 1;

	/* This message is posted to the server console and the 
	 front most channel if it is on this server. */
	NSString *text = TXTLS(@"IRC[1122]");

	[self printDebugInformationToConsole:text];

	IRCChannel *c = [mainWindow() selectedChannelOn:self];

	if (c != nil) {
		[self printDebugInformation:text inChannel:c];
	}
}

- (void)startAutojoinTimer
{
	if (self.autojoinTimer.timerIsActive) {
		return;
	}

	NSTimeInterval interval = [TPCPreferences autojoinDelayBetweenChannelJoins];

	[self.autojoinTimer start:interval];
}

- (void)stopAutojoinTimer
{
	if (self.autojoinTimer.timerIsActive == NO) {
		return;
	}

	[self.autojoinTimer stop];

	self.channelsToAutojoin = nil;
}

- (void)onAutojoinTimer:(id)sender
{
	[self autojoinNextChannel];
}

- (void)autojoinNextChannel
{
	if (self.isAutojoining == NO) {
		return;
	}

	@synchronized (self.channelsToAutojoin) {
		NSUInteger numberOfChannelsRemaining = self.channelsToAutojoin.count;

		NSUInteger maximumNumberOfJoins = [TPCPreferences autojoinMaximumChannelJoins];

		NSRange arrayRange;

		BOOL endOfArray = (numberOfChannelsRemaining <= maximumNumberOfJoins);

		if (endOfArray == NO) {
			arrayRange = NSMakeRange(0, maximumNumberOfJoins);
		} else {
			arrayRange = NSMakeRange(0, numberOfChannelsRemaining);
		}

		NSArray *channelsToJoin = [self.channelsToAutojoin subarrayWithRange:arrayRange];

		[self autojoinChannels:channelsToJoin];

		if (endOfArray == NO) {
			[self.channelsToAutojoin removeObjectsInRange:arrayRange];
		} else {
			self.isAutojoining = NO;

			self.isAutojoined = YES;

			[self stopAutojoinTimer];
		}
	}
}

- (void)autojoinChannels:(NSArray<IRCChannel *> *)channels
{
	NSParameterAssert(channels != nil);

	[self joinChannels:channels];
}

- (void)performAutoJoin
{
	[self performAutoJoinInitiatedByUser:NO];
}

- (void)performAutoJoinInitiatedByUser:(BOOL)initiatedByUser
{
	if (self.isAutojoining) {
		return;
	}

	[self stopAutojoinDelayedWarningTimer];

	if (initiatedByUser == NO) {
		/* Ignore previous invocations of this method */
		if (self.isAutojoined) {
			return;
		}

		/* Ignore autojoin based on ZNC preferences */
		if (self.isConnectedToZNC && self.config.zncIgnoreConfiguredAutojoin) {
			self.isAutojoined = YES;

			return;
		}

		/* Do nothing unless certain conditions are met */
		if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityIsIdentifiedWithSASL] == NO) {
			if (self.config.autojoinWaitsForNickServ) {
				if (self.serverHasNickServ && self.userIsIdentifiedWithNickServ == NO) {
					return;
				}
			}
		}
	}

	NSMutableArray<IRCChannel *> *channelsToAutojoin = [NSMutableArray array];

	for (IRCChannel *c in self.channelList) {
		if (c.isChannel && c.isActive == NO) {
			if (c.config.autoJoin) {
				[channelsToAutojoin addObject:c];
			}
		}
	}

	if (channelsToAutojoin.count == 0) {
		self.isAutojoining = YES;

		return;
	}

	self.isAutojoining = YES;

	@synchronized (self.channelsToAutojoin) {
		[channelsToAutojoin shuffle];

		self.channelsToAutojoin = channelsToAutojoin;
	}

	[self startAutojoinTimer];

	[self onAutojoinTimer:nil];
}

#pragma mark -
#pragma mark Post Events

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

- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel
{
	if (themeSettings().js_postHandleEventNotifications == NO) {
		return; // Cancel operation...
	}

	[self postEventToViewController:eventToken forItem:channel];
}

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
	if (self.pongTimer.timerIsActive == NO) {
		return;
	}

	[self.pongTimer stop];
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
	NSTimeInterval timeSpent = [NSDate timeIntervalSinceNow:self.lastMessageReceived];

	if (timeSpent >= _timeoutInterval)
	{
		/* If EOF Received when we were not expecting it, then timeout regardless
		 of user preference once our timeout interval is reached. */
		if (self.socket.EOFReceived || self.config.performDisconnectOnPongTimer) {
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
		if (self.config.performPongTimer == NO) {
			return;
		}

		[self sendPing:self.serverAddress];
	}
}

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

- (void)stopReconnectTimer
{
	if (self.reconnectTimer.timerIsActive == NO) {
		return;
	}

	[self.reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	[self connect:IRCClientConnectReconnectMode];
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
	if (self.retryTimer.timerIsActive == NO) {
		return;
	}

	[self.retryTimer stop];
}

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

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
#define _softwareTrialWarningInterval1 			5400 // 1 hour, 30 minutes
#define _softwareTrialWarningInterval2 			6300 // 1 hour, 45 minutes
#define _softwareTrialWarningInterval3 			6900 // 1 hour, 55 minutes
#define _softwareTrialWarningInterval4 			7140 // 1 hour, 59 minutes
#define _softwareTrialDisconnectInterval 		7200 // 2 hours

- (void)onInAppPurchaseTransactionFinished:(NSNotification *)notification
{
	[self toggleSoftwareTrialTimer];
}

- (void)toggleSoftwareTrialTimer
{
	if (TLOAppStoreTextualIsRegistered()) {
		[self stopSoftwareTrialTimer];

		return;
	}
}

- (void)startSoftwareTrialTimer
{
	if (self.softwareTrialTimer.timerIsActive) {
		return;
	}

	if (TLOAppStoreTextualIsRegistered()) {
		return;
	}

	NSTimeInterval timeReaminingInTrial = (TLOAppStoreTimeReaminingInTrial() * (-1.0));
	NSTimeInterval timeRemaining = (timeReaminingInTrial + _softwareTrialWarningInterval1);

	[self.softwareTrialTimer start:timeRemaining];

	self.softwareTrialTimer.context = @(0);
}

- (void)stopSoftwareTrialTimer
{
	if (self.softwareTrialTimer.timerIsActive == NO) {
		return;
	}

	[self.softwareTrialTimer stop];
}

- (void)onSoftwareTrialTimer:(id)sender
{
	NSUInteger timerStep = ((NSNumber *)self.softwareTrialTimer.context).unsignedIntegerValue;

	if (timerStep <= 2)
	{
		NSTimeInterval timerInterval = self.softwareTrialTimer.interval;

		/* The interval can be greater than the first because in
		 -startSoftwareTrialTimer, we add the remainder of the trial
		 period to determine when we will start the timer. */
		if (timerInterval >= _softwareTrialWarningInterval1) {
			timerInterval = _softwareTrialWarningInterval1;
		}

		NSTimeInterval timeRemaining = (_softwareTrialDisconnectInterval - timerInterval);

		[self printDebugInformationInAllViews:TXTLS(@"IRC[1126]", (timeRemaining / 60.0)) escapeMessage:NO];

		NSTimeInterval nextStepInterval = 0;

		if (timerStep == 0) {
			nextStepInterval = _softwareTrialWarningInterval2;
		} else if (timerStep == 1) {
			nextStepInterval = _softwareTrialWarningInterval3;
		} else if (timerStep == 2) {
			nextStepInterval = _softwareTrialWarningInterval4;
		}

		[self.softwareTrialTimer start:(nextStepInterval - timeRemaining)];

		self.softwareTrialTimer.context = @(timerStep + 1);
	}
	else
	{
		self.disconnectType = IRCClientDisconnectSoftwareTrialMode;

		[self quit];
	}
}

#undef _softwareTrialWarningInterval1
#undef _softwareTrialWarningInterval2
#undef _softwareTrialWarningInterval3
#undef _softwareTrialWarningInterval4
#undef _softwareTrialDisconnectInterval
#endif

#pragma mark -
#pragma mark User Invoked Command Controls

/* Textual sends IRC many commands such as WHO, which the user may not care about when
 the response is received. So that we only show responses to the user when they care,
 IRCClient has many -inUserInvoked*Command properties. Because IRC is stupid and many
 IRCd do not follow the RFC, unsetting these properties when an error is received or
 a valid response is received is not foolproof because IRCd tend to invent their own
 responses sometimes, which Textual has no knowledge of. */
/* So that we can guarantee out properties are reset, we place a timer on the property
 by invoking -enableInUserInvokedCommandProperty:, then if
 -disableInUserInvokedCommandProperty: is not invoked, we time the property out
 and reset it in -timeoutInUserInvokedCommandProperty: */
/* That's why this ridiculous logic exists here. */
- (void)enableInUserInvokedCommandProperty:(BOOL *)property
{
	NSParameterAssert(property != NULL);

#define _inUserInvokedCommandTimeoutInterval		10.0

	if (*property == NO) {
		*property = YES;

		[self performSelectorInCommonModes:@selector(timeoutInUserInvokedCommandProperty:)
								withObject:[NSValue valueWithPointer:property]
								afterDelay:_inUserInvokedCommandTimeoutInterval];
	}

#undef _inUserInvokedCommandTimeoutInterval
}

- (void)disableInUserInvokedCommandProperty:(BOOL *)property
{
	NSParameterAssert(property != NULL);

	if (*property != NO) {
		*property = NO;

		[self cancelPerformRequestsWithSelector:@selector(timeoutInUserInvokedCommandProperty:)
										 object:[NSValue valueWithPointer:property]];
	}
}

- (void)timeoutInUserInvokedCommandProperty:(NSValue *)propertyPointerValue
{
	NSParameterAssert(propertyPointerValue != nil);

	BOOL *propertyPointer = propertyPointerValue.pointerValue;

	if (propertyPointer != NO) {
		*propertyPointer = NO;
	}
}

#pragma mark -
#pragma mark Plugins and Scripts

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

	LogToConsoleError("%{public}@", TXTLS(@"IRC[1002]", errorDescription));
}

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
		LogToConsoleError("A script returned a result but its destination no longer exists");

		return;
	}

	resultString = resultString.trim;

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self inputText:resultString destination:destination];
	});
}

- (void)executeTextualCmdScriptInContext:(NSDictionary<NSString *, NSString *> *)context
{
	XRPerformBlockAsynchronouslyOnQueue([THOPluginDispatcher dispatchQueue], ^{
		[self _executeTextualCmdScriptInContext:context];
	});
}

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
		BOOL isBuiltinScript = [path hasPrefix:[TPCPathInfo applicationResources]];

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
		/* NSUserAppleScriptTask expects the script to be in the Application Scripts folder 
		 which means if we want to execute scripts in the app's Resources folder, we use a
		 regular call to NSAppleScript. It's pretty safe to say that scripts we make ourselves
		 wont produce errors which means the logic for handling errors is ignored for scripts
		 that are performed in the Resources folder. */

		if (isBuiltinScript)
		{
			NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:pathURL error:NULL];

			if (appleScript == nil) {
				return;
			}

			NSAppleEventDescriptor *result = [appleScript executeAppleEvent:event error:NULL];

			if (result == nil) {
				return;
			}

			[self sendTextualCmdScriptResult:result.stringValue toChannel:targetChannel];
		}
		else // isBuiltinScript
		{
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
		}

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
		[taskArguments addObject:@""];
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

- (void)processBundlesUserMessage:(NSString *)message command:(NSString *)command
{
	NSParameterAssert(message != nil);

	[THOPluginDispatcher userInputCommandInvokedOnClient:self commandString:command messageString:message];
}

- (void)processBundlesServerMessage:(IRCMessage *)message
{
	NSParameterAssert(message != nil);

	[THOPluginDispatcher didReceiveServerInput:message onClient:self];
}

- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage
{
	NSParameterAssert(referenceMessage != nil);

	return [self postReceivedMessage:referenceMessage
							withText:referenceMessage.sequence
						 destinedFor:nil];
}

- (BOOL)postReceivedMessage:(IRCMessage *)referenceMessage withText:(nullable NSString *)text destinedFor:(nullable IRCChannel *)textDestination
{
	NSParameterAssert(referenceMessage != nil);

	return [self postReceivedCommand:referenceMessage.command
							withText:text
						 destinedFor:textDestination
					referenceMessage:referenceMessage];
}

- (BOOL)postReceivedCommand:(NSString *)command withText:(nullable NSString *)text destinedFor:(nullable IRCChannel *)textDestination referenceMessage:(IRCMessage *)referenceMessage
{
	NSParameterAssert(command != nil);
	NSParameterAssert(referenceMessage != nil);

	return [THOPluginDispatcher receivedCommand:command
									   withText:text
									 authoredBy:referenceMessage.sender
									destinedFor:textDestination
									   onClient:self
									 receivedAt:referenceMessage.receivedAt
							   referenceMessage:referenceMessage];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:IRCClientConnectNormalMode];
}

- (void)connect:(IRCClientConnectMode)connectMode
{
	BOOL preferIPv4 = self.config.connectionPrefersIPv4;

	[self connect:connectMode preferIPv4:preferIPv4 bypassProxy:NO];
}

- (void)connect:(IRCClientConnectMode)connectMode preferIPv4:(BOOL)preferIPv4 bypassProxy:(BOOL)bypassProxy
{
	/* Do not allow a connect to occur until the current 
	 socket has completed disconnecting */
	if (self.isConnecting || self.isConnected || self.isQuitting || self.isDisconnecting) {
		return;
	}

	/* Check if system is sleeping. */
	if ([XRSystemInformation systemIsSleeping]) {
		LogToConsole("Refusing to connect because system is sleeping");

		return;
	}

	/* Do we have somewhere to connect to? */
	NSArray *servers = self.config.serverList;

	if (servers.count == 0) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1123]")];

		return;
	}

	/* Begin populating configuration */
	/* Temporary values take priority. When a temporary server
	 address is specified, then the temporary port is used too,
	 or 6667 without SSL is used. Nothing from the current
	 server configuration is read if there is temporary server. */
	NSString *serverAddress = nil;

	uint16_t serverPort = IRCConnectionDefaultServerPort;

	BOOL connectionPrefersSecuredConnection = NO;

	if (self.temporaryServerAddressOverride) {
		serverAddress = self.temporaryServerAddressOverride;

		if (self.temporaryServerPortOverride > 0 &&
			self.temporaryServerPortOverride <= TXMaximumTCPPort)
		{
			serverPort = self.temporaryServerPortOverride;
		}
	}

	if (serverAddress.isValidInternetAddress == NO) {
		NSUInteger serverIndex = self.lastServerSelected;

		if (serverIndex == NSNotFound) {
			serverIndex = 0;
		} else {
			serverIndex += 1;

			if (serverIndex >= servers.count) {
				serverIndex = 0;
			}
		}

		self.lastServerSelected = serverIndex;

		IRCServer *server = servers[serverIndex];

		serverAddress = server.serverAddress;
		serverPort = server.serverPort;

		connectionPrefersSecuredConnection = server.prefersSecuredConnection;

		self.server = server;
	}

	/* Do not wait for an actual connect before destroying the temporary
	 store. Once its defined, its to be nil'd out no matter what. */
	self.temporaryServerAddressOverride = nil;
	self.temporaryServerPortOverride = 0;

	/* Reset status */
	self.connectType = connectMode;

	self.disconnectType = IRCClientDisconnectNormalMode;

	self.isConnecting = YES;

	/* Disable reconnect attempt but permit more */
	[self stopReconnectTimer];

	self.reconnectEnabled = YES;

	/* Present status to user */
	[mainWindow() updateTitleFor:self];

	[self logFileWriteSessionBegin];

	if (connectMode == IRCClientConnectReconnectMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1060]")];
	} else if (connectMode == IRCClientConnectRetryMode) {
		[self printDebugInformationToConsole:TXTLS(@"IRC[1061]")];
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1056]", serverAddress, serverPort)];

	[RZNotificationCenter() postNotificationName:IRCClientWillConnectNotification object:self];

	/* Create socket */
	IRCConnectionConfigMutable *socketConfig = [IRCConnectionConfigMutable new];

	socketConfig.serverAddress = serverAddress;
	socketConfig.serverPort = serverPort;

	socketConfig.connectionPrefersIPv4 = preferIPv4;

	socketConfig.cipherSuites = self.config.cipherSuites;

	socketConfig.connectionPrefersSecuredConnection = connectionPrefersSecuredConnection;
	socketConfig.connectionShouldValidateCertificateChain = self.config.validateServerCertificateChain;

	socketConfig.identityClientSideCertificate = self.config.identityClientSideCertificate;

	if (bypassProxy == NO) {
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
	}

	socketConfig.floodControlDelayInterval = self.config.floodControlDelayTimerInterval;
	socketConfig.floodControlMaximumMessages = self.config.floodControlMaximumMessages;

	// TODO: Make this configurable outside of command line
	socketConfig.connectionPrefersModernCiphersOnly = [RZUserDefaults() boolForKey:@"GCDAsyncSocket Cipher List Includes Deprecated Ciphers"];

	self.socket = [[IRCConnection alloc] initWithConfig:socketConfig onClient:self];

	[self.socket open];

	/* Pass status to view controller */
	[self postEventToViewController:@"serverConnecting"];
}

- (void)autoConnectWithDelay:(NSUInteger)delay afterWakeUp:(BOOL)afterWakeUp
{
	self.connectDelay = delay;

	if (afterWakeUp) {
		[self autoConnectAfterWakeUp];
	} else {
		[self autoConnect];
	}
}

- (void)autoConnect
{
	NSUInteger connectDelay = self.connectDelay;

	if (connectDelay == 0) {
		[self autoConnectPerformConnect];

		return;
	}

	[self performSelectorInCommonModes:@selector(autoConnectPerformConnect) withObject:nil afterDelay:connectDelay];
}

- (void)autoConnectPerformConnect
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	[self connect];
}

- (void)autoConnectAfterWakeUp
{
	NSUInteger connectDelay = self.connectDelay;

	if (connectDelay == 0) {
		[self autoConnectAfterWakeUpPerformConnect];

		return;
	}

	[self printDebugInformationToConsole:TXTLS(@"IRC[1010]", connectDelay)];

	[self performSelectorInCommonModes:@selector(autoConnectAfterWakeUpPerformConnect) withObject:nil afterDelay:connectDelay];
}

- (void)autoConnectAfterWakeUpPerformConnect
{
	if (self.isConnecting || self.isConnected) {
		return;
	}

	self.reconnectEnabledBecauseOfSleepMode = YES;

	[self connect:IRCClientConnectReconnectMode];
}

- (void)disconnect
{
	[self cancelPerformRequestsWithSelector:@selector(disconnect) object:nil];

	if (self.isConnecting == NO && self.isConnected == NO) {
		return;
	}

	if (self.socket == nil) {
		return;
	}

	self.isDisconnecting = YES;

	[RZNotificationCenter() postNotificationName:IRCClientWillDisconnectNotification object:self];

	[self.socket close];
}

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

- (void)quitWithComment:(NSString *)comment
{
	NSParameterAssert(comment != nil);

	if ((self.isConnecting == NO && self.isConnected == NO) || self.isQuitting || self.isDisconnecting) {
		return;
	}

	self.isQuitting	= YES;

	[self cancelReconnect];

	if (self.isTerminating == NO) {
		[self postEventToViewController:@"serverDisconnecting"];
	}

	[RZNotificationCenter() postNotificationName:IRCClientWillSendQuitNotification object:self];

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
	[self performSelectorInCommonModes:@selector(disconnect) withObject:nil afterDelay:2.0];
}

- (void)cancelReconnect
{
	self.reconnectEnabled = NO;
	self.reconnectEnabledBecauseOfSleepMode = NO;

	[self stopReconnectTimer];

	[mainWindow() updateTitleFor:self];
}

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

- (void)joinKickedChannel:(IRCChannel *)channel
{
	[self joinChannel:channel];
}

- (void)joinChannel:(IRCChannel *)channel
{
	[self joinChannel:channel password:nil];
}

- (void)joinUnlistedChannel:(NSString *)channel
{
	[self joinUnlistedChannel:channel password:nil];
}

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

- (void)joinChannels:(NSArray<IRCChannel *> *)channels
{
	NSParameterAssert(channels != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channels.count == 0) {
		return;
	}

	NSMutableString *joinStringWithoutKey = nil;
	NSMutableString *joinStringWithKey = nil;

	NSMutableString *keyString = nil;

	for (IRCChannel *channel in channels) {
		if (channel.isChannel == NO || channel.isActive) {
			continue;
		}

		channel.status = IRCChannelStatusJoining;

		NSString *password = nil;

		if (password == nil) {
			password = channel.secretKey;
		}

		if (password.length == 0) {
			if (joinStringWithoutKey == nil) {
				joinStringWithoutKey = [NSMutableString stringWithString:channel.name];
			} else {
				[joinStringWithoutKey appendFormat:@",%@", channel.name];
			}
		} else {
			if (joinStringWithKey == nil) {
				joinStringWithKey = [NSMutableString stringWithString:channel.name];
			} else {
				[joinStringWithKey appendFormat:@",%@", channel.name];
			}

			if (keyString == nil) {
				keyString = [NSMutableString stringWithString:password];
			} else {
				[keyString appendFormat:@",%@", password];
			}
		}
	}

	if (joinStringWithoutKey) {
		[self send:IRCPrivateCommandIndex("join"), joinStringWithoutKey, nil];
	}

	if (joinStringWithKey && keyString) {
		[self send:IRCPrivateCommandIndex("join"), joinStringWithKey, keyString, nil];
	}
}

- (void)partUnlistedChannel:(NSString *)channel
{
	[self partUnlistedChannel:channel withComment:nil];
}

- (void)partChannel:(IRCChannel *)channel
{
	[self partChannel:channel withComment:nil];
}

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

- (void)sendWhoToChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self sendWhoToChannelNamed:channel.name];
}

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

- (void)toggleAwayStatus:(BOOL)setAway
{
	NSString *comment = TXTLS(@"IRC[1031]");

	[self toggleAwayStatus:setAway withComment:comment];
}

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

- (void)presentCertificateTrustInformation
{
	if (self.isSecured == NO) {
		return;
	}

	[self.socket openSecuredConnectionCertificateModal];
}

- (void)requestModesForChannel:(IRCChannel *)channel
{
	[self sendModes:nil withParameters:nil inChannel:channel];
}

- (void)requestModesForChannelNamed:(NSString *)channel
{
	[self sendModes:nil withParameters:nil inChannelNamed:channel];
}

- (void)sendModes:(nullable NSString *)modeSymbols withParameters:(nullable NSArray<NSString *> *)parameters inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self sendModes:modeSymbols withParameters:parameters inChannelNamed:channel.name];
}

- (void)sendModes:(nullable NSString *)modeSymbols withParametersString:(nullable NSString *)parametersString inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	[self sendModes:modeSymbols withParametersString:parametersString inChannelNamed:channel.name];
}

- (void)sendModes:(nullable NSString *)modeSymbols withParameters:(nullable NSArray<NSString *> *)parameters inChannelNamed:(NSString *)channel
{
	NSString *parametersString = [parameters componentsJoinedByString:@" "];

	[self sendModes:modeSymbols withParametersString:parametersString inChannelNamed:channel];
}

- (void)sendModes:(nullable NSString *)modeSymbols withParametersString:(nullable NSString *)parametersString inChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("mode"), channel, modeSymbols, parametersString, nil];
}

- (void)sendPing:(NSString *)tokenString
{
	NSParameterAssert(tokenString != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("ping"), tokenString, nil];
}

- (void)sendPong:(NSString *)tokenString
{
	NSParameterAssert(tokenString != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("pong"), tokenString, nil];
}

- (void)sendInviteTo:(NSString *)nickname toJoinChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self sendInviteTo:nickname toJoinChannelNamed:channel.name];
}

- (void)sendInviteTo:(NSString *)nickname toJoinChannelNamed:(NSString *)channel
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(channel != nil);

	if (nickname.length == 0 || channel.length == 0) {
		return;
	}

	[self send:IRCPrivateCommandIndex("invite"), nickname, channel, nil];
}

- (void)requestTopicForChannel:(IRCChannel *)channel
{
	[self sendTopicTo:nil inChannel:channel];
}

- (void)requestTopicForChannelNamed:(NSString *)channel
{
	[self sendTopicTo:nil inChannelNamed:channel];
}

- (void)sendTopicTo:(nullable NSString *)topic inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO || channel.isActive == NO) {
		return;
	}

	[self sendTopicTo:topic inChannelNamed:channel.name];
}

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

- (void)sendCapability:(NSString *)subcommand data:(nullable NSString *)data
{
	NSParameterAssert(subcommand != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("cap"), subcommand, data, nil];
}

- (void)sendCapabilityAuthenticate:(NSString *)data
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

- (void)sendIsonForNicknames:(NSArray<NSString *> *)nicknames
{
	NSParameterAssert(nicknames != nil);

	if (nicknames.count == 0) {
		return;
	}

	NSString *nicknamesString = [nicknames componentsJoinedByString:@" "];

	[self sendIsonForNicknamesString:nicknamesString];
}

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

- (void)requestChannelList
{
	if (self.isLoggedIn == NO) {
		return;
	}

	[self send:IRCPrivateCommandIndex("list"), nil];
}

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

- (void)modifyWatchListBy:(BOOL)adding nicknames:(NSArray<NSString *> *)nicknames
{
	NSParameterAssert(nicknames != nil);

	if (self.isLoggedIn == NO) {
		return;
	}

	if (nicknames.count == 0) {
		return;
	}

	NSString *modifier = nil;

	if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityMonitorCommand])
	{
		if (adding) {
			modifier = @"+";
		} else {
			modifier = @"-";
		}

		NSString *nicknamesString = [nicknames componentsJoinedByString:@","];

		[self send:IRCPrivateCommandIndex("monitor"), modifier, nicknamesString, nil];
	}
	else if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityWatchCommand])
	{
		if (adding) {
			modifier = @" +";
		} else {
			modifier = @" -";
		}

		NSString *nicknamesString = [nicknames componentsJoinedByString:modifier];

		[self send:IRCPrivateCommandIndex("watch"), [modifier stringByAppendingString:nicknamesString], nil];
	}
}

#pragma mark -
#pragma mark File Transfers

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
		LogToConsoleError("Fatal error: Received transfer token that is not a number");

		goto present_error;
	}

	NSInteger hostPortInt = hostPort.integerValue;

	if (hostPortInt == 0 && transferToken == nil) {
		LogToConsoleError("Fatal error: Port cannot be zero without a transfer token");

		goto present_error;
	} else if (hostPortInt < 0 || hostPortInt > TXMaximumTCPPort) {
		LogToConsoleError("Fatal error: Port cannot be less than zero or greater than 65535");

		goto present_error;
	}

	long long filesizeInt = filesize.longLongValue;

	if (filesizeInt <= 0 || filesizeInt > powl(1000, 4)) { // 1 TB
		LogToConsoleError("Fatal error: Filesize is silly");

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
					LogToConsoleError("Fatal error: Received reverse DCC request with token '%{public}@' but the token already exists.", transferToken);

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
					LogToConsoleError("Fatal error: Unexpected request to begin transfer");

					goto present_error;
				}

				[e didReceiveSendRequest:hostAddress hostPort:hostPortInt];

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
			LogToConsoleError("Fatal error: Could not locate file transfer that matches resume request");

			goto present_error;
		}

		if ((isResumeRequest && (e.transferStatus != TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus &&
								 e.transferStatus != TDCFileTransferDialogTransferIsListeningAsSenderStatus)) ||
			(isAcceptRequest && e.transferStatus != TDCFileTransferDialogTransferWaitingForResumeAcceptStatus))
		{
			LogToConsoleError("Fatal error: Bad transfer status");

			goto present_error;
		}

		if (isResumeRequest) {
			[e didReceiveResumeRequest:filesizeInt];
		} else {
			[e didReceiveResumeAccept:filesizeInt];
		}

		return;
	}

	// Report an error
present_error:
	[self print:TXTLS(@"IRC[1020]", sender) by:nil inChannel:nil asType:TVCLogLineDCCFileTransferType command:TVCLogLineDefaultCommandValue];
}

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

- (NSString *)DCCSendEscapeFilename:(NSString *)filename
{
	NSParameterAssert(filename != nil);

	NSString *filenameEscaped = filename.safeFilename;

	if ([filenameEscaped contains:@" "] == NO) {
		return filenameEscaped;
	}
	
	/* Escape double quotes because the filename will be wrapped.
	 February 20, 2017: Maybe we should replace the double quote
	 with another character or remove completely? Untested how other
	 clients will handle an escaped double quote. */
	filenameEscaped = [filenameEscaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

	return [NSString stringWithFormat:@"\"%@\"", filenameEscaped];
}

- (nullable NSString *)DCCTransferAddress
{
	NSString *address = [self fileTransferController].IPAddress;

	if (address == nil) {
		return nil;
	}

	if (address.IPv6Address) {
		return address;
	}

	NSArray *addressOctets = [address componentsSeparatedByString:@"."];

	if (addressOctets.count != 4) {
		LogToConsoleError("User configured a silly IP address");

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
#pragma mark Command Queue

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

- (void)clearCommandQueue
{
	@synchronized(self.commandQueue) {
		[self.commandQueue removeAllObjects];
	}

	[self.commandQueueTimer stop];
}

- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark User Tracking

- (void)clearTrackedUsers
{
	[self.trackedUsers clearTrackedUsers];
}

- (void)statusOfTrackedNickname:(NSString *)nickname changedTo:(IRCAddressBookUserTrackingStatus)newStatus
{
	[self statusOfTrackedNickname:nickname changedTo:newStatus notify:NO];
}

- (void)statusOfTrackedNickname:(NSString *)nickname changedTo:(IRCAddressBookUserTrackingStatus)newStatus notify:(BOOL)notify
{
	NSParameterAssert(nickname != nil);

	[self.trackedUsers statusOfTrackedNickname:nickname changedTo:newStatus];

	if (notify) {
		[self notifyStatusOfTrackedNickname:nickname changedTo:newStatus];
	}
}

- (void)notifyStatusOfTrackedNickname:(NSString *)nickname changedTo:(IRCAddressBookUserTrackingStatus)newStatus
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

- (void)populateISONTrackedUsersList
{
	if (self.isLoggedIn == NO) {
		return;
	}

	/* Additions & Removels for WATCH command. ISON does not access these. */
	NSMutableArray<NSString *> *watchAdditions = [NSMutableArray array];
	NSMutableArray<NSString *> *watchRemovals = [NSMutableArray array];

	/* Compare configuration to the list of tracked nicknames.
	 * Nicknames that are new are added to watchAdditions */
	NSDictionary *trackedUsersOld = self.trackedUsers.trackedUsers;

	NSMutableArray<NSString *> *trackedUsersNew = [NSMutableArray array];

	for (IRCAddressBookEntry *g in self.config.ignoreList) {
		if (g.trackUserActivity == NO) {
			continue;
		}

		NSString *trackingNickname = g.trackingNickname;

		IRCAddressBookUserTrackingStatus trackingStatus = [self.trackedUsers statusOfUser:trackingNickname];

		if (trackingStatus != IRCAddressBookUserTrackingUnknownStatus) {
			[trackedUsersNew addObject:trackingNickname];

			continue;
		}

		[watchAdditions addObject:trackingNickname];

		[self.trackedUsers _addTrackedUser:trackingNickname];
	}

	/* Compare old list of tracked nicknames to new list to find
	 those that no longer appear. Mark those for removal. */
	for (NSString *trackedUser in trackedUsersOld) {
		if ([trackedUsersNew containsObjectIgnoringCase:trackedUser]) {
			continue;
		}

		[watchRemovals addObject:trackedUser];

		[self.trackedUsers _removeTrackedUser:trackedUser];
	}

	/* Set new entries */
	[self modifyWatchListBy:YES nicknames:watchAdditions];

	[self modifyWatchListBy:NO nicknames:watchRemovals];

	[self startISONTimer];
}

- (void)startISONTimer
{
	if (self.isonTimer.timerIsActive) {
		return;
	}

	[self.isonTimer start:_isonCheckInterval];

	[self startWhoTimer];
}

- (void)stopISONTimer
{
	if (self.isonTimer.timerIsActive == NO) {
		return;
	}

	[self.isonTimer stop];

	[self stopWhoTimer];
}

- (void)onISONTimer:(id)sender
{
	if (self.isLoggedIn == NO || self.isBrokenIRCd_aka_Twitch) {
		return;
	}

	NSMutableArray<NSString *> *nicknames = [NSMutableArray array];

	// Request ISON status for tracked users
	if (self.supportsAdvancedTracking == NO) {
		for (NSString *trackedUser in self.trackedUsers.trackedUsers) {
			[nicknames addObject:trackedUser];
		}
	}

	// Request ISON status for private messages
	for (IRCChannel *channel in self.channelList) {
		if (channel.privateMessage) {
			[nicknames addObject:channel.name];
		}
	}

	[self sendIsonForNicknames:nicknames];
}

- (void)startWhoTimer
{
	if (self.whoTimer.timerIsActive) {
		return;
	}

	[self.whoTimer start:_whoCheckInterval];
}

- (void)stopWhoTimer
{
	if (self.whoTimer.timerIsActive == NO) {
		return;
	}

	[self.whoTimer stop];
}

- (void)onWhoTimer:(id)sender
{
	if (self.isLoggedIn == NO || self.isBrokenIRCd_aka_Twitch) {
		return;
	}

	NSArray *channelList = self.channelList;

	[self sendTimedWhoRequestsToChannels:channelList];
}

- (void)sendTimedWhoRequestsToChannels:(NSArray<IRCChannel *> *)channelList
{
	NSParameterAssert(channelList != nil);

	if (self.isLoggedIn == NO || self.isBrokenIRCd_aka_Twitch) {
		return;
	}

#define _maximumChannelCountPerWhoBatchRequest			4
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
			if ([self isCapabilityEnabled:ClientIRCv3SupportedCapabilityAwayNotify]) {
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

- (void)updateUserTrackingStatusForEntry:(IRCAddressBookEntry *)addressBookEntry withMessage:(IRCMessage *)message
{
	NSParameterAssert(addressBookEntry != nil);
	NSParameterAssert(message != nil);

	if (self.supportsAdvancedTracking) {
		return;
	}

	IRCAddressBookUserTrackingStatus trackingStatus = [self.trackedUsers statusOfEntry:addressBookEntry];

	if (trackingStatus == IRCAddressBookUserTrackingUnknownStatus) {
		return;
	}

	BOOL ison = (trackingStatus == IRCAddressBookUserTrackingIsAvailalbeStatus);

	/* Notification Type: JOIN Command */
	if ([message.command isEqualIgnoringCase:@"JOIN"]) {
		if (ison == NO) {
			[self statusOfTrackedNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOnStatus notify:YES];
		}

		return;
	}

	/* Notification Type: QUIT Command */
	if ([message.command isEqualIgnoringCase:@"QUIT"]) {
		if (ison) {
			[self statusOfTrackedNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOffStatus notify:YES];
		}

		return;
	}

	/* Notification Type: NICK Command */
	if ([message.command isEqualIgnoringCase:@"NICK"]) {
		if (ison) {
			[self statusOfTrackedNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOffStatus notify:YES];
		} else {
			[self statusOfTrackedNickname:message.senderNickname changedTo:IRCAddressBookUserTrackingSignedOnStatus notify:YES];
		}

		return;
	}
}

#pragma mark -
#pragma mark Channel Ban List Dialog

- (void)createChannelInviteExceptionListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetInviteExceptionEntryType];
}

- (void)createChannelBanExceptionListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetBanExceptionEntryType];
}

- (void)createChannelBanListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetBanEntryType];
}

- (void)createChannelQuietListSheet
{
	[self createChannelBanListSheet:TDCChannelBanListSheetQuietEntryType];
}

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

- (void)channelBanListSheetOnUpdate:(TDCChannelBanListSheet *)sender
{
	IRCChannel *channel = sender.channel;

	if (channel == nil) {
		return;
	}

	NSString *modeSend = [NSString stringWithFormat:@"+%@", sender.modeSymbol];

	[self sendModes:modeSend withParametersString:nil inChannel:channel];
}

- (void)channelBanListSheetWillClose:(TDCChannelBanListSheet *)sender
{
	IRCChannel *channel = sender.channel;

	if (channel == nil) {
		return;
	}

	NSArray *listOfChanges = sender.listOfChanges;

	for (NSString *change in listOfChanges) {
		[self sendModes:change withParametersString:nil inChannel:channel];
	}

	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Network Channel List Dialog

- (NSString *)channelListDialogWindowKey
{
	return [NSString stringWithFormat:@"TDCServerChannelListDialog -> %@", self.uniqueIdentifier];
}

- (nullable TDCServerChannelListDialog *)channelListDialog
{
	return [windowController() windowFromWindowList:[self channelListDialogWindowKey]];
}

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

- (void)serverChannelListDialogOnUpdate:(TDCServerChannelListDialog *)sender
{
	[self requestChannelList];
}

- (void)serverChannelListDialog:(TDCServerChannelListDialog *)sender joinChannel:(NSString *)channel
{
	[self enableInUserInvokedCommandProperty:&self->_inUserInvokedJoinRequest];

	[self joinUnlistedChannel:channel];
}

- (void)serverChannelDialogWillClose:(TDCServerChannelListDialog *)sender
{
	[windowController() removeWindowFromWindowList:[self channelListDialogWindowKey]];
}

@end

NS_ASSUME_NONNULL_END
