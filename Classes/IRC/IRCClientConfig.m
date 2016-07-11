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
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "IRCClientConfigInternal.h"

NS_ASSUME_NONNULL_BEGIN

#define IRCClientConfigFloodControlDefaultDelayIntervalForFreenode		2
#define IRCClientConfigFloodControlDefaultMessageCountForFreenode		2 // freenode gets a special case 'cause they are strict about flood control

@implementation IRCClientConfig

#pragma mark -
#pragma mark Defaults

- (void)populateDefaultsPreflight
{
	ObjectIsAlreadyInitializedAssert

	/* Even if a value is NO, include it as a default. */
	/* This allows NO values to be stripped from output dictionary. */
	NSMutableDictionary<NSString *, id> *defaults = [NSMutableDictionary dictionary];

	defaults[@"autoConnect"] = @(NO);
	defaults[@"autoReconnect"] = @(NO);
	defaults[@"autoSleepModeDisconnect"] = @(YES);

TEXTUAL_IGNORE_DEPRECATION_BEGIN
	defaults[@"autojoinWaitsForNickServ"] = @([TPCPreferences autojoinWaitsForNickServ]);
TEXTUAL_IGNORE_DEPRECATION_END

	defaults[@"cachedLastServerTimeCapacityReceivedAtTimestamp"] = @(0);
	defaults[@"connectionName"] = TXTLS(@"BasicLanguage[1004]");
	defaults[@"connectionPrefersIPv4"] = @(NO);
	defaults[@"connectionPrefersModernCiphers"] = @(YES);
	defaults[@"excludedFromCloudSyncing"] = @(NO);
	defaults[@"fallbackEncoding"] = @(TXDefaultFallbackStringEncoding);
	defaults[@"floodControlDelayTimerInterval"] = @(IRCConnectionConfigFloodControlDefaultDelayInterval);
	defaults[@"floodControlMaximumMessages"] = @(IRCConnectionConfigFloodControlDefaultMessageCount);
	defaults[@"hideNetworkUnavailabilityNotices"] = @(NO);
	defaults[@"normalLeavingComment"] = TXTLS(@"BasicLanguage[1003]");
	defaults[@"performDisconnectOnPongTimer"] = @(NO);
	defaults[@"performDisconnectOnReachabilityChange"] = @(YES);
	defaults[@"performPongTimer"] = @(YES);
	defaults[@"prefersSecuredConnection"] = @(NO);
	defaults[@"primaryEncoding"] = @(TXDefaultPrimaryStringEncoding);
	defaults[@"proxyPort"] = @(IRCConnectionDefaultProxyPort);
	defaults[@"proxyType"] = @(IRCConnectionSocketSystemSocksProxyType);
	defaults[@"saslAuthenticationUsesExternalMechanism"] = @(NO);
	defaults[@"sendAuthenticationRequestsToUserServ"] = @(NO);
	defaults[@"sendWhoCommandRequestsToChannels"] = @(YES);
	defaults[@"serverPort"] = @(IRCConnectionDefaultServerPort);
	defaults[@"setInvisibleModeOnConnect"] = @(NO);
	defaults[@"sidebarItemExpanded"] = @(YES);

	{
		NSString *macintoshModel = [XRSystemInformation systemModelName];

		if (macintoshModel == nil) {
			defaults[@"sleepModeLeavingComment"] = TXTLS(@"BasicLanguage[1006]");
		} else {
			defaults[@"sleepModeLeavingComment"] = TXTLS(@"BasicLanguage[1005]", macintoshModel);
		}
	}

	defaults[@"validateServerCertificateChain"] = @(YES);
	defaults[@"zncIgnoreConfiguredAutojoin"] = @(NO);
	defaults[@"zncIgnorePlaybackNotifications"] = @(YES);
	defaults[@"zncIgnoreUserNotifications"] = @(NO);

	self->_defaults = [defaults copy];
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNilCopy(self->_uniqueIdentifier, [NSString stringWithUUID])

	SetVariableIfNilCopy(self->_nickname, [TPCPreferences defaultNickname])
	SetVariableIfNilCopy(self->_awayNickname, [TPCPreferences defaultAwayNickname])
	SetVariableIfNilCopy(self->_username, [TPCPreferences defaultUsername])
	SetVariableIfNilCopy(self->_realName, [TPCPreferences defaultRealName])

	SetVariableIfNilCopy(self->_ignoreList, @[])
	SetVariableIfNilCopy(self->_channelList, @[])
	SetVariableIfNilCopy(self->_highlightList, @[])

	SetVariableIfNilCopy(self->_alternateNicknames, @[])

	SetVariableIfNilCopy(self->_loginCommands, @[])

	[self modifyFloodControlDefaultsForFreenode];
}

- (void)populateDefaultsByAppendingDictionary:(NSDictionary<NSString *, id> *)defaultsToAppend
{
	NSParameterAssert(defaultsToAppend != nil);

	ObjectIsAlreadyInitializedAssert

	self->_defaults = [self->_defaults dictionaryByAddingEntries:defaultsToAppend];
}

- (void)modifyFloodControlDefaultsForFreenode
{
	ObjectIsAlreadyInitializedAssert

	if ([self.serverAddress hasSuffix:@".freenode.net"] == NO) {
		return;
	}

	if (self.floodControlDelayTimerInterval != IRCConnectionConfigFloodControlDefaultDelayInterval ||
		self.floodControlMaximumMessages != IRCConnectionConfigFloodControlDefaultMessageCount)
	{
		return;
	}

	NSUInteger floodControlDelayTimerInterval = IRCClientConfigFloodControlDefaultDelayIntervalForFreenode;
	NSUInteger floodControlMaximumMessages = IRCClientConfigFloodControlDefaultMessageCountForFreenode;

	[self populateDefaultsByAppendingDictionary:@{
		@"floodControlDelayTimerInterval" : @(floodControlDelayTimerInterval),
		@"floodControlMaximumMessages" : @(floodControlMaximumMessages)
	}];

	self->_floodControlDelayTimerInterval = floodControlDelayTimerInterval;
	self->_floodControlMaximumMessages = floodControlMaximumMessages;
}

#pragma mark -
#pragma mark Server Configuration

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	return [self initWithDictionary:@{}];
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic
{
	return [self initWithDictionary:dic ignorePrivateMessages:NO];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic ignorePrivateMessages:(BOOL)ignorePrivateMessages
{
	ObjectIsAlreadyInitializedAssert
	
	if ((self = [super init])) {
		[self populateDefaultsPreflight];

		[self populateDictionaryValue:dic ignorePrivateMessages:ignorePrivateMessages applyDefaults:YES];

		[self populateDefaultsPostflight];

		[self initializedClassHealthCheck];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)initializedClassHealthCheck
{
	ObjectIsAlreadyInitializedAssert

	if ([self isMutable]) {
		return;
	}

	NSParameterAssert(self->_connectionName.length > 0);
	NSParameterAssert(self->_serverAddress.length > 0);
	NSParameterAssert(self->_serverPort > 0 && self->_serverPort <= TXMaximumTCPPort);
	NSParameterAssert(self->_proxyPort > 0 && self->_proxyPort <= TXMaximumTCPPort);
}

+ (instancetype)newConfigByMerging:(IRCClientConfig *)config1 with:(IRCClientConfig *)config2
{
	NSParameterAssert(config1 != nil);
	NSParameterAssert(config2 != nil);

	IRCClientConfigMutable *config1Mutable = [config1 mutableCopy];

	[config1Mutable populateDictionaryValue:config2.dictionaryValue ignorePrivateMessages:NO applyDefaults:NO];

	return [config1Mutable copy];
}

- (void)populateDictionaryValue:(NSDictionary<NSString *, id> *)dic ignorePrivateMessages:(BOOL)ignorePrivateMessages applyDefaults:(BOOL)applyDefaults
{
	NSParameterAssert(dic != nil);

	if ([self isMutable] == NO) {
		ObjectIsAlreadyInitializedAssert
	}

	NSMutableDictionary<NSString *, id> *defaultsMutable = nil;

	if (applyDefaults) {
		defaultsMutable = [self->_defaults mutableCopy];

		[defaultsMutable addEntriesFromDictionary:dic];
	} else {
		defaultsMutable = [dic mutableCopy];
	}

	/* Load the newest set of keys. */
	[defaultsMutable assignArrayTo:&self->_alternateNicknames forKey:@"alternateNicknames"];
	[defaultsMutable assignArrayTo:&self->_loginCommands forKey:@"onConnectCommands"];

	[defaultsMutable assignBoolTo:&self->_autoConnect forKey:@"autoConnect"];
	[defaultsMutable assignBoolTo:&self->_autoReconnect forKey:@"autoReconnect"];
	[defaultsMutable assignBoolTo:&self->_autoSleepModeDisconnect forKey:@"autoSleepModeDisconnect"];
	[defaultsMutable assignBoolTo:&self->_autojoinWaitsForNickServ forKey:@"autojoinWaitsForNickServ"];
	[defaultsMutable assignBoolTo:&self->_connectionPrefersIPv4 forKey:@"connectionPrefersIPv4"];
	[defaultsMutable assignBoolTo:&self->_connectionPrefersModernCiphers forKey:@"connectionPrefersModernCiphers"];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[defaultsMutable assignBoolTo:&self->_excludedFromCloudSyncing forKey:@"excludedFromCloudSyncing"];
#endif

	[defaultsMutable assignBoolTo:&self->_hideNetworkUnavailabilityNotices forKey:@"hideNetworkUnavailabilityNotices"];
	[defaultsMutable assignBoolTo:&self->_performDisconnectOnPongTimer forKey:@"performDisconnectOnPongTimer"];
	[defaultsMutable assignBoolTo:&self->_performDisconnectOnReachabilityChange forKey:@"performDisconnectOnReachabilityChange"];
	[defaultsMutable assignBoolTo:&self->_performPongTimer forKey:@"performPongTimer"];
	[defaultsMutable assignBoolTo:&self->_prefersSecuredConnection forKey:@"prefersSecuredConnection"];
	[defaultsMutable assignBoolTo:&self->_saslAuthenticationUsesExternalMechanism forKey:@"saslAuthenticationUsesExternalMechanism"];
	[defaultsMutable assignBoolTo:&self->_sendAuthenticationRequestsToUserServ forKey:@"sendAuthenticationRequestsToUserServ"];
	[defaultsMutable assignBoolTo:&self->_sendWhoCommandRequestsToChannels forKey:@"sendWhoCommandRequestsToChannels"];
	[defaultsMutable assignBoolTo:&self->_setInvisibleModeOnConnect forKey:@"setInvisibleModeOnConnect"];
	[defaultsMutable assignBoolTo:&self->_sidebarItemExpanded forKey:@"sidebarItemExpanded"];
	[defaultsMutable assignBoolTo:&self->_validateServerCertificateChain forKey:@"validateServerCertificateChain"];
	[defaultsMutable assignBoolTo:&self->_zncIgnoreConfiguredAutojoin forKey:@"zncIgnoreConfiguredAutojoin"];
	[defaultsMutable assignBoolTo:&self->_zncIgnorePlaybackNotifications forKey:@"zncIgnorePlaybackNotifications"];
	[defaultsMutable assignBoolTo:&self->_zncIgnoreUserNotifications forKey:@"zncIgnoreUserNotifications"];

	[defaultsMutable assignDoubleTo:&self->_lastMessageServerTime forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];
	[defaultsMutable assignObjectTo:&self->_identityClientSideCertificate forKey:@"identityClientSideCertificate"];
	[defaultsMutable assignStringTo:&self->_awayNickname forKey:@"awayNickname"];
	[defaultsMutable assignStringTo:&self->_connectionName forKey:@"connectionName"];
	[defaultsMutable assignStringTo:&self->_nickname forKey:@"nickname"];
	[defaultsMutable assignStringTo:&self->_normalLeavingComment forKey:@"normalLeavingComment"];
	[defaultsMutable assignStringTo:&self->_proxyAddress forKey:@"proxyAddress"];
	[defaultsMutable assignStringTo:&self->_proxyUsername forKey:@"proxyUsername"];
	[defaultsMutable assignStringTo:&self->_realName forKey:@"realName"];
	[defaultsMutable assignStringTo:&self->_serverAddress forKey:@"serverAddress"];
	[defaultsMutable assignStringTo:&self->_sleepModeLeavingComment forKey:@"sleepModeLeavingComment"];
	[defaultsMutable assignStringTo:&self->_uniqueIdentifier forKey:@"uniqueIdentifier"];
	[defaultsMutable assignStringTo:&self->_username forKey:@"username"];

	[defaultsMutable assignUnsignedIntegerTo:&self->_fallbackEncoding forKey:@"fallbackEncoding"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_floodControlDelayTimerInterval forKey:@"floodControlDelayTimerInterval"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_floodControlMaximumMessages forKey:@"floodControlMaximumMessages"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_primaryEncoding forKey:@"primaryEncoding"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_proxyType forKey:@"proxyType"];

	[defaultsMutable assignUnsignedShortTo:&self->_proxyPort forKey:@"proxyPort"];
	[defaultsMutable assignUnsignedShortTo:&self->_serverPort forKey:@"serverPort"];

	/* Channel list */
	NSMutableArray<IRCChannelConfig *> *channelListOut = [NSMutableArray array];

	NSArray<NSDictionary *> *channelListIn = [defaultsMutable arrayForKey:@"channelList"];

	for (NSDictionary<NSString *, id> *e in channelListIn) {
		IRCChannelConfig *c = [[IRCChannelConfig alloc] initWithDictionary:e];

		if (c.type == IRCChannelPrivateMessageType) {
			if (ignorePrivateMessages == NO) {
				[channelListOut addObject:c];
			}
		} else {
			[channelListOut addObject:c];
		}
	}

	self->_channelList = [channelListOut copy];

	/* Ignore list */
	NSMutableArray<IRCAddressBookEntry *> *ignoreListOut = [NSMutableArray array];

	NSArray<NSDictionary *> *ignoreListIn = [defaultsMutable arrayForKey:@"ignoreList"];

	for (NSDictionary<NSString *, id> *e in ignoreListIn) {
		IRCAddressBookEntry *c = [[IRCAddressBookEntry alloc] initWithDictionary:e];

		[ignoreListOut addObject:c];
	}

	self->_ignoreList = [ignoreListOut copy];

	/* Highlight list */
	NSMutableArray<IRCHighlightMatchCondition *> *highlightListOut = [NSMutableArray array];

	NSArray<NSDictionary *> *highlightListIn = [defaultsMutable arrayForKey:@"highlightList"];

	for (NSDictionary<NSString *, id> *e in highlightListIn) {
		IRCHighlightMatchCondition *c = [[IRCHighlightMatchCondition alloc] initWithDictionary:e];

		[highlightListOut addObject:c];
	}

	self->_highlightList = [highlightListOut copy];

	/* Load legacy keys (if they exist) */
	/* If legacy keys were assigned before new keys, then a transition would not occur properly. */
	/* Since the new keys will read from -defaults if they are not present in /dic/, then those
	 would override legacy keys when performing a first pass. */
	[defaultsMutable assignArrayTo:&self->_alternateNicknames forKey:@"identityAlternateNicknames"];

	[defaultsMutable assignBoolTo:&self->_autoConnect forKey:@"connectOnLaunch"];
	[defaultsMutable assignBoolTo:&self->_autoReconnect forKey:@"connectOnDisconnect"];
	[defaultsMutable assignBoolTo:&self->_autoSleepModeDisconnect forKey:@"disconnectOnSleepMode"];
	[defaultsMutable assignBoolTo:&self->_autojoinWaitsForNickServ forKey:@"autojoinWaitsForNickServIdentification"];
	[defaultsMutable assignBoolTo:&self->_prefersSecuredConnection forKey:@"connectUsingSSL"];
	[defaultsMutable assignBoolTo:&self->_setInvisibleModeOnConnect forKey:@"setInvisibleOnConnect"];
	[defaultsMutable assignBoolTo:&self->_sidebarItemExpanded forKey:@"serverListItemIsExpanded"];
	[defaultsMutable assignBoolTo:&self->_validateServerCertificateChain forKey:@"validateServerSideSSLCertificate"];

	[defaultsMutable assignObjectTo:&self->_identityClientSideCertificate forKey:@"IdentitySSLCertificate"];

	[defaultsMutable assignStringTo:&self->_awayNickname forKey:@"identityAwayNickname"];
	[defaultsMutable assignStringTo:&self->_nickname forKey:@"identityNickname"];
	[defaultsMutable assignStringTo:&self->_normalLeavingComment forKey:@"connectionDisconnectDefaultMessage"];
	[defaultsMutable assignStringTo:&self->_proxyAddress forKey:@"proxyServerAddress"];
	[defaultsMutable assignStringTo:&self->_proxyUsername forKey:@"proxyServerUsername"];
	[defaultsMutable assignStringTo:&self->_realName forKey:@"identityRealname"];
	[defaultsMutable assignStringTo:&self->_sleepModeLeavingComment forKey:@"connectionDisconnectSleepModeMessage"];
	[defaultsMutable assignStringTo:&self->_username forKey:@"identityUsername"];

	[defaultsMutable assignUnsignedIntegerTo:&self->_primaryEncoding forKey:@"characterEncodingDefault"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_fallbackEncoding forKey:@"characterEncodingFallback"];
	[defaultsMutable assignUnsignedIntegerTo:&self->_proxyType forKey:@"proxyServerType"];

	[defaultsMutable assignUnsignedShortTo:&self->_proxyPort forKey:@"proxyServerPort"];

	/* Flood control */
	/* This is here to migrate to the new properties. Saving these values
	 in this dictionary key is no longer preferred. */
	BOOL floodControlSetToDisabled = NO;

	NSDictionary *floodControlDic = [defaultsMutable dictionaryForKey:@"floodControl"];

	if (floodControlDic) {
		NSNumber *serviceEnabled = [floodControlDic objectForKey:@"serviceEnabled"];

		if (serviceEnabled && serviceEnabled.boolValue == NO) {
			floodControlSetToDisabled = YES;
		}

		[floodControlDic assignUnsignedIntegerTo:&self->_floodControlDelayTimerInterval forKey:@"delayTimerInterval"];
		[floodControlDic assignUnsignedIntegerTo:&self->_floodControlMaximumMessages forKey:@"maximumMessageCount"];
	}

	if (floodControlSetToDisabled == NO) {
		NSNumber *floodControlEnabled = [defaultsMutable objectForKey:@"isOutgoingFloodControlEnabled"];

		if (floodControlEnabled && floodControlEnabled.boolValue == NO) {
			floodControlSetToDisabled = YES;
		}
	}

	/* An option to disable flood control no longer exists.
	 If the user had flood control disabled when the option did exist,
	 then set the the current values to appear disabled. */
	if (floodControlSetToDisabled) {
		self->_floodControlDelayTimerInterval = IRCConnectionConfigFloodControlMinimumDelayInterval;
		self->_floodControlMaximumMessages = IRCConnectionConfigFloodControlMaximumMessageCount;
	}

	/* Migrate to keychain. */
	NSString *proxyPassword = [defaultsMutable stringForKey:@"proxyServerPassword"];

	if (proxyPassword) {
		self->_proxyPassword = [proxyPassword copy];

		[self writeProxyPasswordToKeychain];
	}
}

- (BOOL)isEqual:(id)object
{
	if (object == nil) {
		return NO;
	}

	if (object == self) {
		return YES;
	}

	if ([object isKindOfClass:[IRCClientConfig class]] == NO) {
		return NO;
	}

	NSDictionary *s1 = self.dictionaryValue;
	
	NSDictionary *s2 = ((IRCClientConfig *)object).dictionaryValue;

	return (NSObjectsAreEqual(s1, s2) &&
			NSObjectsAreEqual(self->_nicknamePassword, ((IRCClientConfig *)object)->_nicknamePassword) &&
			NSObjectsAreEqual(self->_proxyPassword, ((IRCClientConfig *)object)->_proxyPassword) &&
			NSObjectsAreEqual(self->_serverPassword, ((IRCClientConfig *)object)->_serverPassword));
}

- (NSUInteger)hash
{
	return self.uniqueIdentifier.hash;
}

- (BOOL)isMutable
{
	return NO;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	  IRCClientConfig *config =
	[[IRCClientConfig allocWithZone:zone] initWithDictionary:self.dictionaryValue ignorePrivateMessages:NO];

	// Instance variable is copied because self.nicknamePassward can return
	// the value of the instance variable if present, else it uses keychain.
	config->_nicknamePassword = [self->_nicknamePassword copyWithZone:zone];
	config->_proxyPassword = [self->_proxyPassword copyWithZone:zone];
	config->_serverPassword = [self->_serverPassword copyWithZone:zone];

	return config;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	  IRCClientConfigMutable *config =
	[[IRCClientConfigMutable allocWithZone:zone] initWithDictionary:self.dictionaryValue ignorePrivateMessages:NO];

	config.nicknamePassword = self->_nicknamePassword;
	config.proxyPassword = self->_proxyPassword;
	config.serverPassword = self->_serverPassword;

	return config;
}

- (id)uniqueCopy
{
	return [self uniqueCopyAsMutable:NO];
}

- (id)uniqueCopyMutable
{
	return [self uniqueCopyAsMutable:YES];
}

- (id)uniqueCopyAsMutable:(BOOL)asMutable
{
	IRCClientConfig *object = nil;

	if (asMutable == NO) {
		object = [self copy];
	} else {
		object = [self mutableCopy];
	}

	NSString *nicknamePassword = self.nicknamePassword;
	NSString *proxyPassword = self.proxyPassword;
	NSString *serverPassword = self.serverPassword;

	object->_nicknamePassword = [nicknamePassword copy];
	object->_proxyPassword = [proxyPassword copy];
	object->_serverAddress = [serverPassword copy];

	object->_uniqueIdentifier = [[NSString stringWithUUID] copy];

	NSMutableArray *channelList = [self.channelList mutableCopy];
	NSMutableArray *highlightList = [self.highlightList mutableCopy];
	NSMutableArray *ignoreList = [self.ignoreList mutableCopy];

	[channelList performSelectorOnObjectValueAndReplace:@selector(uniqueCopy)];
	[highlightList performSelectorOnObjectValueAndReplace:@selector(uniqueCopy)];
	[ignoreList performSelectorOnObjectValueAndReplace:@selector(uniqueCopy)];

	object->_channelList = [channelList copy];
	object->_highlightList = [highlightList copy];
	object->_ignoreList = [ignoreList copy];

	return object;
}

- (NSDictionary<NSString *, id> *)dictionaryValue;
{
	return [self dictionaryValue:NO];
}

- (NSDictionary<NSString *, id> *)dictionaryValue:(BOOL)isCloudDictionary
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.alternateNicknames forKey:@"alternateNicknames"];
	[dic maybeSetObject:self.awayNickname forKey:@"awayNickname"];
	[dic maybeSetObject:self.connectionName forKey:@"connectionName"];
	[dic maybeSetObject:self.loginCommands forKey:@"onConnectCommands"];
	[dic maybeSetObject:self.nickname forKey:@"nickname"];
	[dic maybeSetObject:self.normalLeavingComment forKey:@"normalLeavingComment"];
	[dic maybeSetObject:self.proxyAddress forKey:@"proxyAddress"];
	[dic maybeSetObject:self.proxyUsername forKey:@"proxyUsername"];
	[dic maybeSetObject:self.realName forKey:@"realName"];
	[dic maybeSetObject:self.serverAddress forKey:@"serverAddress"];
	[dic maybeSetObject:self.sleepModeLeavingComment forKey:@"sleepModeLeavingComment"];
	[dic maybeSetObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.username forKey:@"username"];

	[dic setBool:self.autoConnect forKey:@"autoConnect"];
	[dic setBool:self.autoReconnect forKey:@"autoReconnect"];
	[dic setBool:self.autoSleepModeDisconnect forKey:@"autoSleepModeDisconnect"];
	[dic setBool:self.autojoinWaitsForNickServ forKey:@"autojoinWaitsForNickServ"];
	[dic setBool:self.connectionPrefersIPv4 forKey:@"connectionPrefersIPv4"];
	[dic setBool:self.connectionPrefersModernCiphers forKey:@"connectionPrefersModernCiphers"];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[dic setBool:self.excludedFromCloudSyncing forKey:@"excludedFromCloudSyncing"];
#endif

	[dic setBool:self.hideNetworkUnavailabilityNotices forKey:@"hideNetworkUnavailabilityNotices"];
	[dic setBool:self.performDisconnectOnPongTimer forKey:@"performDisconnectOnPongTimer"];
	[dic setBool:self.performDisconnectOnReachabilityChange forKey:@"performDisconnectOnReachabilityChange"];
	[dic setBool:self.performPongTimer forKey:@"performPongTimer"];
	[dic setBool:self.prefersSecuredConnection forKey:@"prefersSecuredConnection"];
	[dic setBool:self.saslAuthenticationUsesExternalMechanism forKey:@"saslAuthenticationUsesExternalMechanism"];
	[dic setBool:self.sendAuthenticationRequestsToUserServ forKey:@"sendAuthenticationRequestsToUserServ"];
	[dic setBool:self.sendWhoCommandRequestsToChannels forKey:@"sendWhoCommandRequestsToChannels"];
	[dic setBool:self.setInvisibleModeOnConnect forKey:@"setInvisibleModeOnConnect"];
	[dic setBool:self.validateServerCertificateChain forKey:@"validateServerCertificateChain"];
	[dic setBool:self.zncIgnoreConfiguredAutojoin forKey:@"zncIgnoreConfiguredAutojoin"];
	[dic setBool:self.zncIgnorePlaybackNotifications forKey:@"zncIgnorePlaybackNotifications"];
	[dic setBool:self.zncIgnoreUserNotifications forKey:@"zncIgnoreUserNotifications"];

	[dic setUnsignedInteger:self.fallbackEncoding forKey:@"fallbackEncoding"];
	[dic setUnsignedInteger:self.floodControlDelayTimerInterval forKey:@"floodControlDelayTimerInterval"];
	[dic setUnsignedInteger:self.floodControlMaximumMessages forKey:@"floodControlMaximumMessages"];
	[dic setUnsignedInteger:self.primaryEncoding forKey:@"primaryEncoding"];
	[dic setUnsignedInteger:self.proxyType forKey:@"proxyType"];

	[dic setUnsignedShort:self.proxyPort forKey:@"proxyPort"];
	[dic setUnsignedShort:self.serverPort forKey:@"serverPort"];

	/* These are items that cannot be synced over iCloud because they access data specific to 
	 this device or only contain state information which is not useful to other devices. */
	if (isCloudDictionary == NO) {
		[dic maybeSetObject:self.identityClientSideCertificate forKey:@"identityClientSideCertificate"];

		[dic setBool:self.sidebarItemExpanded forKey:@"sidebarItemExpanded"];

		[dic setDouble:self.lastMessageServerTime forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];
	}

	/* Channel List */
	NSMutableArray<NSDictionary *> *channelListOut = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channelList) {
		NSDictionary *d = e.dictionaryValue;

		[channelListOut addObject:d];
	}

	if (channelListOut.count > 0) {
		[dic setObject:[channelListOut copy] forKey:@"channelList"];
	}

	/* Highlight list */
	NSMutableArray<NSDictionary *> *highlightListOut = [NSMutableArray array];

	for (IRCHighlightMatchCondition *e in self.highlightList) {
		NSDictionary *d = e.dictionaryValue;

		[highlightListOut addObject:d];
	}

	if (highlightListOut.count > 0) {
		[dic setObject:[highlightListOut copy] forKey:@"highlightList"];
	}

	/* Ignore list */
	NSMutableArray<NSDictionary *> *ignoreListOut = [NSMutableArray array];

	for (IRCAddressBookEntry *e in self.ignoreList) {
		NSDictionary *d = e.dictionaryValue;

		[ignoreListOut addObject:d];
	}

	if (ignoreListOut.count > 0) {
		[dic setObject:[ignoreListOut copy] forKey:@"ignoreList"];
	}

	return [dic dictionaryByRemovingDefaults:self->_defaults allowEmptyValues:YES];
}

#pragma mark -
#pragma mark Keychain Management

- (nullable NSString *)nicknamePassword
{
	if (self->_nicknamePassword) {
		return self->_nicknamePassword;
	}

	return self.nicknamePasswordFromKeychain;
}

- (nullable NSString *)nicknamePasswordFromKeychain
{
	NSString *nicknamePasswordServiceName = [NSString stringWithFormat:@"textual.nickserv.%@", self.uniqueIdentifier];

	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:nicknamePasswordServiceName];

	return kcPassword;
}

- (nullable NSString *)proxyPassword
{
	if (self->_proxyPassword) {
		return self->_proxyPassword;
	}

	return self.proxyPasswordFromKeychain;
}

- (nullable NSString *)proxyPasswordFromKeychain
{
	NSString *proxyPasswordServiceName = [NSString stringWithFormat:@"textual.proxy-server.%@", self.uniqueIdentifier];

	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Proxy Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:proxyPasswordServiceName];

	return kcPassword;
}

- (nullable NSString *)serverPassword
{
	if (self->_serverPassword) {
		return self->_serverPassword;
	}

	return self.serverPasswordFromKeychain;
}

- (nullable NSString *)serverPasswordFromKeychain
{
	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:serverPasswordServiceName];

	return kcPassword;
}

- (void)writeItemsToKeychain
{
	[self writeNicknamePasswordToKeychain];
	[self writeProxyPasswordToKeychain];
	[self writeServerPasswordToKeychain];
}

- (void)writeNicknamePasswordToKeychain
{
	if (self->_nicknamePassword == nil) {
		return;
	}

	NSString *nicknamePasswordServiceName = [NSString stringWithFormat:@"textual.nickserv.%@", self.uniqueIdentifier];

	[XRKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
						   withItemKind:@"application password"
							forUsername:nil
						withNewPassword:self->_nicknamePassword
							serviceName:nicknamePasswordServiceName];

	self->_nicknamePassword = nil;
}

- (void)writeProxyPasswordToKeychain
{
	if (self->_proxyPassword == nil) {
		return;
	}

	NSString *proxyPasswordServiceName = [NSString stringWithFormat:@"textual.proxy-server.%@", self.uniqueIdentifier];

	[XRKeychain modifyOrAddKeychainItem:@"Textual (Proxy Server Password)"
						   withItemKind:@"application password"
							forUsername:nil
						withNewPassword:self->_proxyPassword
							serviceName:proxyPasswordServiceName];

	self->_proxyPassword = nil;
}

- (void)writeServerPasswordToKeychain
{
	if (self->_serverPassword == nil) {
		return;
	}

	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	[XRKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
						   withItemKind:@"application password"
							forUsername:nil
						withNewPassword:self->_serverPassword
							serviceName:serverPasswordServiceName];

	self->_serverPassword = nil;
}

- (void)destroyKeychainItems
{
	NSString *nicknamePasswordServiceName = [NSString stringWithFormat:@"textual.nickserv.%@", self.uniqueIdentifier];

	[XRKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:nicknamePasswordServiceName];

	NSString *proxyPasswordServiceName = [NSString stringWithFormat:@"textual.proxy-server.%@", self.uniqueIdentifier];

	[XRKeychain deleteKeychainItem:@"Textual (Proxy Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:proxyPasswordServiceName];

	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	[XRKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:serverPasswordServiceName];

	[self resetTemporaryKeychainItems];
}

- (void)resetTemporaryKeychainItems
{
	self->_serverPassword = nil;
	self->_proxyPassword = nil;
	self->_nicknamePassword = nil;
}

@end

#pragma mark -

@implementation IRCClientConfigMutable

@dynamic alternateNicknames;
@dynamic autoConnect;
@dynamic autoReconnect;
@dynamic autoSleepModeDisconnect;
@dynamic autojoinWaitsForNickServ;
@dynamic awayNickname;
@dynamic channelList;
@dynamic connectionName;
@dynamic connectionPrefersIPv4;
@dynamic connectionPrefersModernCiphers;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@dynamic excludedFromCloudSyncing;
#endif

@dynamic fallbackEncoding;
@dynamic floodControlDelayTimerInterval;
@dynamic floodControlMaximumMessages;
@dynamic hideNetworkUnavailabilityNotices;
@dynamic highlightList;
@dynamic identityClientSideCertificate;
@dynamic ignoreList;
@dynamic lastMessageServerTime;
@dynamic loginCommands;
@dynamic nickname;
@dynamic nicknamePassword;
@dynamic normalLeavingComment;
@dynamic performDisconnectOnPongTimer;
@dynamic performDisconnectOnReachabilityChange;
@dynamic performPongTimer;
@dynamic prefersSecuredConnection;
@dynamic primaryEncoding;
@dynamic proxyAddress;
@dynamic proxyPassword;
@dynamic proxyPort;
@dynamic proxyType;
@dynamic proxyUsername;
@dynamic realName;
@dynamic saslAuthenticationUsesExternalMechanism;
@dynamic sendAuthenticationRequestsToUserServ;
@dynamic sendWhoCommandRequestsToChannels;
@dynamic serverAddress;
@dynamic serverPassword;
@dynamic serverPort;
@dynamic setInvisibleModeOnConnect;
@dynamic sidebarItemExpanded;
@dynamic sleepModeLeavingComment;
@dynamic username;
@dynamic validateServerCertificateChain;
@dynamic zncIgnoreConfiguredAutojoin;
@dynamic zncIgnorePlaybackNotifications;
@dynamic zncIgnoreUserNotifications;

- (BOOL)isMutable
{
	return YES;
}

- (void)setAutoConnect:(BOOL)autoConnect
{
	if (self->_autoConnect != autoConnect) {
		self->_autoConnect = autoConnect;
	}
}

- (void)setAutoReconnect:(BOOL)autoReconnect
{
	if (self->_autoReconnect != autoReconnect) {
		self->_autoReconnect = autoReconnect;
	}
}

- (void)setAutoSleepModeDisconnect:(BOOL)autoSleepModeDisconnect
{
	if (self->_autoSleepModeDisconnect != autoSleepModeDisconnect) {
		self->_autoSleepModeDisconnect = autoSleepModeDisconnect;
	}
}

- (void)setAutojoinWaitsForNickServ:(BOOL)autojoinWaitsForNickServ
{
	if (self->_autojoinWaitsForNickServ != autojoinWaitsForNickServ) {
		self->_autojoinWaitsForNickServ = autojoinWaitsForNickServ;
	}
}

- (void)setConnectionPrefersIPv4:(BOOL)connectionPrefersIPv4
{
	if (self->_connectionPrefersIPv4 != connectionPrefersIPv4) {
		self->_connectionPrefersIPv4 = connectionPrefersIPv4;
	}
}

- (void)setConnectionPrefersModernCiphers:(BOOL)connectionPrefersModernCiphers
{
	if (self->_connectionPrefersModernCiphers != connectionPrefersModernCiphers) {
		self->_connectionPrefersModernCiphers = connectionPrefersModernCiphers;
	}
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)setExcludedFromCloudSyncing:(BOOL)excludedFromCloudSyncing
{
	if (self->_excludedFromCloudSyncing != excludedFromCloudSyncing) {
		self->_excludedFromCloudSyncing = excludedFromCloudSyncing;
	}
}
#endif

- (void)setHideNetworkUnavailabilityNotices:(BOOL)hideNetworkUnavailabilityNotices
{
	if (self->_hideNetworkUnavailabilityNotices != hideNetworkUnavailabilityNotices) {
		self->_hideNetworkUnavailabilityNotices = hideNetworkUnavailabilityNotices;
	}
}

- (void)setPerformDisconnectOnPongTimer:(BOOL)performDisconnectOnPongTimer
{
	if (self->_performDisconnectOnPongTimer != performDisconnectOnPongTimer) {
		self->_performDisconnectOnPongTimer = performDisconnectOnPongTimer;
	}
}

- (void)setPerformDisconnectOnReachabilityChange:(BOOL)performDisconnectOnReachabilityChange
{
	if (self->_performDisconnectOnReachabilityChange != performDisconnectOnReachabilityChange) {
		self->_performDisconnectOnReachabilityChange = performDisconnectOnReachabilityChange;
	}
}

- (void)setPerformPongTimer:(BOOL)performPongTimer
{
	if (self->_performPongTimer != performPongTimer) {
		self->_performPongTimer = performPongTimer;
	}
}

- (void)setPrefersSecuredConnection:(BOOL)prefersSecuredConnection
{
	if (self->_prefersSecuredConnection != prefersSecuredConnection) {
		self->_prefersSecuredConnection = prefersSecuredConnection;
	}
}

- (void)setSaslAuthenticationUsesExternalMechanism:(BOOL)saslAuthenticationUsesExternalMechanism
{
	if (self->_saslAuthenticationUsesExternalMechanism != saslAuthenticationUsesExternalMechanism) {
		self->_saslAuthenticationUsesExternalMechanism = saslAuthenticationUsesExternalMechanism;
	}
}

- (void)setSendAuthenticationRequestsToUserServ:(BOOL)sendAuthenticationRequestsToUserServ
{
	if (self->_sendAuthenticationRequestsToUserServ != sendAuthenticationRequestsToUserServ) {
		self->_sendAuthenticationRequestsToUserServ = sendAuthenticationRequestsToUserServ;
	}
}

- (void)setSendWhoCommandRequestsToChannels:(BOOL)sendWhoCommandRequestsToChannels
{
	if (self->_sendWhoCommandRequestsToChannels != sendWhoCommandRequestsToChannels) {
		self->_sendWhoCommandRequestsToChannels = sendWhoCommandRequestsToChannels;
	}
}

- (void)setSetInvisibleModeOnConnect:(BOOL)setInvisibleModeOnConnect
{
	if (self->_setInvisibleModeOnConnect != setInvisibleModeOnConnect) {
		self->_setInvisibleModeOnConnect = setInvisibleModeOnConnect;
	}
}

- (void)setSidebarItemExpanded:(BOOL)sidebarItemExpanded
{
	if (self->_sidebarItemExpanded != sidebarItemExpanded) {
		self->_sidebarItemExpanded = sidebarItemExpanded;
	}
}

- (void)setValidateServerCertificateChain:(BOOL)validateServerCertificateChain
{
	if (self->_validateServerCertificateChain != validateServerCertificateChain) {
		self->_validateServerCertificateChain = validateServerCertificateChain;
	}
}

- (void)setZncIgnoreConfiguredAutojoin:(BOOL)zncIgnoreConfiguredAutojoin
{
	if (self->_zncIgnoreUserNotifications != zncIgnoreConfiguredAutojoin) {
		self->_zncIgnoreUserNotifications = zncIgnoreConfiguredAutojoin;
	}
}

- (void)setZncIgnorePlaybackNotifications:(BOOL)zncIgnorePlaybackNotifications
{
	if (self->_zncIgnorePlaybackNotifications != zncIgnorePlaybackNotifications) {
		self->_zncIgnorePlaybackNotifications = zncIgnorePlaybackNotifications;
	}
}

- (void)setZncIgnoreUserNotifications:(BOOL)zncIgnoreUserNotifications
{
	if (self->_zncIgnoreUserNotifications != zncIgnoreUserNotifications) {
		self->_zncIgnoreUserNotifications = zncIgnoreUserNotifications;
	}
}

- (void)setProxyType:(IRCConnectionSocketProxyType)proxyType
{
	if (self->_proxyType != proxyType) {
		self->_proxyType = proxyType;
	}
}

- (void)setIgnoreList:(NSArray<IRCAddressBookEntry *> *)ignoreList
{
	NSParameterAssert(ignoreList != nil);

	if (self->_ignoreList != ignoreList) {
		self->_ignoreList = [ignoreList copy];
	}
}

- (void)setChannelList:(NSArray<IRCChannelConfig *> *)channelList
{
	NSParameterAssert(channelList != nil);

	if (self->_channelList != channelList) {
		self->_channelList = [channelList copy];
	}
}

- (void)setHighlightList:(NSArray<IRCHighlightMatchCondition *> *)highlightList
{
	NSParameterAssert(highlightList != nil);

	if (self->_highlightList != highlightList) {
		self->_highlightList = [highlightList copy];
	}
}

- (void)setAlternateNicknames:(NSArray<NSString *> *)alternateNicknames
{
	NSParameterAssert(alternateNicknames != nil);

	if (self->_alternateNicknames != alternateNicknames) {
		self->_alternateNicknames = [alternateNicknames copy];
	}
}

- (void)setLoginCommands:(NSArray<NSString *> *)loginCommands
{
	NSParameterAssert(loginCommands != nil);

	if (self->_loginCommands != loginCommands) {
		self->_loginCommands = [loginCommands copy];
	}
}

- (void)setIdentityClientSideCertificate:(nullable NSData *)identityClientSideCertificate
{
	if (self->_identityClientSideCertificate != identityClientSideCertificate) {
		self->_identityClientSideCertificate = [identityClientSideCertificate copy];
	}
}

- (void)setAwayNickname:(nullable NSString *)awayNickname
{
	if (self->_awayNickname != awayNickname) {
		self->_awayNickname = [awayNickname copy];
	}
}

- (void)setConnectionName:(NSString *)connectionName
{
	NSParameterAssert(connectionName != nil);

	if (self->_connectionName != connectionName) {
		self->_connectionName = [connectionName copy];
	}
}

- (void)setNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	if (self->_nickname != nickname) {
		self->_nickname = [nickname copy];
	}
}

- (void)setNicknamePassword:(nullable NSString *)nicknamePassword
{
	if (self->_nicknamePassword != nicknamePassword) {
		self->_nicknamePassword = [nicknamePassword copy];
	}
}

- (void)setNormalLeavingComment:(NSString *)normalLeavingComment
{
	NSParameterAssert(normalLeavingComment != nil);

	if (self->_normalLeavingComment != normalLeavingComment) {
		self->_normalLeavingComment = [normalLeavingComment copy];
	}
}

- (void)setProxyAddress:(nullable NSString *)proxyAddress
{
	if (self->_proxyAddress != proxyAddress) {
		self->_proxyAddress = [proxyAddress copy];
	}
}

- (void)setProxyPassword:(nullable NSString *)proxyPassword
{
	if (self->_proxyPassword != proxyPassword) {
		self->_proxyPassword = [proxyPassword copy];
	}
}

- (void)setProxyUsername:(nullable NSString *)proxyUsername
{
	if (self->_proxyUsername != proxyUsername) {
		self->_proxyUsername = [proxyUsername copy];
	}
}

- (void)setRealName:(NSString *)realName
{
	NSParameterAssert(realName != nil);

	if (self->_realName != realName) {
		self->_realName = [realName copy];
	}
}

- (void)setServerAddress:(NSString *)serverAddress
{
	NSParameterAssert(serverAddress != nil);

	if (self->_serverAddress != serverAddress) {
		self->_serverAddress = [serverAddress copy];
	}
}

- (void)setServerPassword:(nullable NSString *)serverPassword
{
	if (self->_serverPassword != serverPassword) {
		self->_serverPassword = [serverPassword copy];
	}
}

- (void)setSleepModeLeavingComment:(NSString *)sleepModeLeavingComment
{
	NSParameterAssert(sleepModeLeavingComment != nil);

	if (self->_sleepModeLeavingComment != sleepModeLeavingComment) {
		self->_sleepModeLeavingComment = [sleepModeLeavingComment copy];
	}
}

- (void)setUsername:(NSString *)username
{
	NSParameterAssert(username != nil);

	if (self->_username != username) {
		self->_username = [username copy];
	}
}

- (void)setFallbackEncoding:(NSStringEncoding)fallbackEncoding
{
	if (self->_fallbackEncoding != fallbackEncoding) {
		self->_fallbackEncoding = fallbackEncoding;
	}
}

- (void)setPrimaryEncoding:(NSStringEncoding)primaryEncoding
{
	if (self->_primaryEncoding != primaryEncoding) {
		self->_primaryEncoding = primaryEncoding;
	}
}

- (void)setLastMessageServerTime:(NSTimeInterval)lastMessageServerTime
{
	if (self->_lastMessageServerTime != lastMessageServerTime) {
		self->_lastMessageServerTime = lastMessageServerTime;
	}
}

- (void)setFloodControlDelayTimerInterval:(NSUInteger)floodControlDelayTimerInterval
{
	NSParameterAssert(floodControlDelayTimerInterval >= IRCConnectionConfigFloodControlMinimumDelayInterval &&
					  floodControlDelayTimerInterval <= IRCConnectionConfigFloodControlMaximumDelayInterval);

	if (self->_floodControlDelayTimerInterval != floodControlDelayTimerInterval) {
		self->_floodControlDelayTimerInterval = floodControlDelayTimerInterval;
	}
}

- (void)setFloodControlMaximumMessages:(NSUInteger)floodControlMaximumMessages
{
	NSParameterAssert(floodControlMaximumMessages >= IRCConnectionConfigFloodControlMinimumMessageCount &&
					  floodControlMaximumMessages <= IRCConnectionConfigFloodControlMaximumMessageCount);

	if (self->_floodControlMaximumMessages != floodControlMaximumMessages) {
		self->_floodControlMaximumMessages = floodControlMaximumMessages;
	}
}

- (void)setProxyPort:(uint16_t)proxyPort
{
	if (self->_proxyPort != proxyPort) {
		self->_proxyPort = proxyPort;
	}
}

- (void)setServerPort:(uint16_t)serverPort
{
	if (self->_serverPort != serverPort) {
		self->_serverPort = serverPort;
	}
}

@end

NS_ASSUME_NONNULL_END
