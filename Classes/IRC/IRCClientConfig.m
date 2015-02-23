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

#import "TextualApplication.h"

NSInteger const IRCConnectionDefaultServerPort		= 6667;

@implementation IRCClientConfig

@synthesize serverPassword = _serverPassword;
@synthesize proxyPassword = _proxyPassword;
@synthesize nicknamePassword = _nicknamePassword;

- (NSDictionary *)defaults
{
	static id _defaults = nil;

	if (_defaults == nil) {
		NSDictionary *defaults = @{
			 @"autoConnect" : @(NO),
			 @"autoReconnect" : @(NO),
			 @"autoSleepModeDisconnect" : @(YES),

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			 @"autojoinWaitsForNickServ" : @([TPCPreferences autojoinWaitsForNickServ]),
#pragma clang diagnostic pop

			 @"connectionPrefersIPv6" : @(NO),
			 @"prefersSecuredConnection" : @(NO),

			 @"excludedFromCloudSyncing" : @(NO),

			 @"isOutgoingFloodControlEnabled" : @(YES),

			 @"performPongTimer" : @(YES),
			 @"performDisconnectOnPongTimer" : @(NO),
			 @"performDisconnectOnReachabilityChange" : @(YES),

			 @"hideNetworkUnavailabilityNotices" : @(NO),
			 @"saslAuthenticationUsesExternalMechanism" : @(NO),
			 @"sendAuthenticationRequestsToUserServ" : @(NO),
			 @"sendWhoCommandRequestsToChannels" : @(YES),

			 @"setInvisibleModeOnConnect" : @(NO),

			 @"sidebarItemExpanded" : @(YES),

			 @"validateServerCertificateChain" : @(YES),

			 @"zncIgnoreConfiguredAutojoin" : @(NO),
			 @"zncIgnorePlaybackNotifications" : @(YES),

			 @"proxyType" : @(IRCConnectionSocketNoProxyType),
			 @"proxyPort" : @(1080),

			 @"primaryEncoding" : @(TXDefaultPrimaryStringEncoding),
			 @"fallbackEncoding" : @(TXDefaultFallbackStringEncoding),

			 @"floodControlDelayTimerInterval" : @(IRCClientConfigFloodControlDefaultDelayTimer),
			 @"floodControlMaximumMessages" : @(IRCClientConfigFloodControlDefaultMessageCount),

			 @"connectionName" : BLS(1022),

			 @"serverPort" : @(IRCConnectionDefaultServerPort),

			 @"cachedLastServerTimeCapacityReceivedAtTimestamp" : @(0),

			 @"normalLeavingComment" : BLS(1021),
			 @"sleepModeLeavingComment" : BLS(1235)
		};

		_defaults = [defaults copy];
	}

	return _defaults;
}

- (void)populateDefaults
{
	NSDictionary *defaults = [self defaults];

	NSString *macintoshModel = [XRSystemInformation systemModelName];

	self.itemUUID = [NSString stringWithUUID];

	self.nickname		= [TPCPreferences defaultNickname];
	self.awayNickname	= [TPCPreferences defaultAwayNickname];
	self.username		= [TPCPreferences defaultUsername];
	self.realName		= [TPCPreferences defaultRealname];

	self.alternateNicknames		= @[];
	self.loginCommands			= @[];
	self.highlightList			= @[];
	self.channelList			= @[];
	self.ignoreList				= @[];

	self.autoConnect				= [defaults boolForKey:@"autoConnect"];
	self.autoReconnect				= [defaults boolForKey:@"autoReconnect"];
	self.autoSleepModeDisconnect	= [defaults boolForKey:@"autoSleepModeDisconnect"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	self.autojoinWaitsForNickServ	= [defaults boolForKey:@"autojoinWaitsForNickServ"];
#pragma clang diagnostic pop

	self.connectionPrefersIPv6		= [defaults boolForKey:@"connectionPrefersIPv6"];
	self.prefersSecuredConnection	= [defaults boolForKey:@"prefersSecuredConnection"];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	self.excludedFromCloudSyncing	= [defaults boolForKey:@"excludedFromCloudSyncing"];
#endif

	self.isOutgoingFloodControlEnabled	= [defaults boolForKey:@"isOutgoingFloodControlEnabled"];

	self.floodControlDelayTimerInterval = [defaults integerForKey:@"floodControlDelayTimerInterval"];
	self.floodControlMaximumMessages	= [defaults integerForKey:@"floodControlMaximumMessages"];

	self.performPongTimer						= [defaults boolForKey:@"performPongTimer"];
	self.performDisconnectOnPongTimer			= [defaults boolForKey:@"performDisconnectOnPongTimer"];
	self.performDisconnectOnReachabilityChange	= [defaults boolForKey:@"performDisconnectOnReachabilityChange"];

	self.hideNetworkUnavailabilityNotices			= [defaults boolForKey:@"hideNetworkUnavailabilityNotices"];
	self.saslAuthenticationUsesExternalMechanism	= [defaults boolForKey:@"saslAuthenticationUsesExternalMechanism"];
	self.sendAuthenticationRequestsToUserServ		= [defaults boolForKey:@"sendAuthenticationRequestsToUserServ"];
	self.sendWhoCommandRequestsToChannels			= [defaults boolForKey:@"sendWhoCommandRequestsToChannels"];

	self.setInvisibleModeOnConnect		= [defaults boolForKey:@"setInvisibleModeOnConnect"];

	self.sidebarItemExpanded			= [defaults boolForKey:@"sidebarItemExpanded"];

	self.validateServerCertificateChain		= [defaults boolForKey:@"validateServerCertificateChain"];

	self.zncIgnoreConfiguredAutojoin		= [defaults boolForKey:@"zncIgnoreConfiguredAutojoin"];
	self.zncIgnorePlaybackNotifications		= [defaults boolForKey:@"zncIgnorePlaybackNotifications"];

	self.proxyType = [defaults integerForKey:@"proxyType"];
	self.proxyPort = [defaults integerForKey:@"proxyPort"];

	self.primaryEncoding	= [defaults integerForKey:@"primaryEncoding"];
	self.fallbackEncoding	= [defaults integerForKey:@"fallbackEncoding"];

	self.connectionName		= [defaults stringForKey:@"connectionName"];

	self.serverPort			= [defaults integerForKey:@"serverPort"];

	self.cachedLastServerTimeCapacityReceivedAtTimestamp = [defaults integerForKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];

	self.normalLeavingComment = [defaults stringForKey:@"normalLeavingComment"];

	if (macintoshModel) {
		self.sleepModeLeavingComment = BLS(1185, macintoshModel);
	} else {
		self.sleepModeLeavingComment = [defaults stringForKey:@"sleepModeLeavingComment"];
	}
}

- (instancetype)init
{
	if ((self = [super init])) {
		[self populateDefaults];
	}
	
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)nicknamePassword
{
	return [self nicknamePasswordFromKeychain];
}

- (NSString *)nicknamePasswordFromKeychain
{
	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];

	return kcPassword;
}

- (NSString *)serverPassword
{
	return [self serverPasswordFromKeychain];
}

- (NSString *)serverPasswordFromKeychain
{
	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	
	return kcPassword;
}

- (NSString *)proxyPassword
{
	return [self proxyPasswordFromKeychain];
}

- (NSString *)proxyPasswordFromKeychain
{
	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Proxy Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];

	return kcPassword;
}

- (NSString *)temporaryNicknamePassword
{
	return _nicknamePassword;
}

- (NSString *)temporaryServerPassword
{
	return _serverPassword;
}

- (NSString *)temporaryProxyPassword
{
	return _proxyPassword;
}

- (void)setNicknamePassword:(NSString *)pass
{
	_nicknamePassword = [pass copy];
}

- (void)setServerPassword:(NSString *)pass
{
	_serverPassword = [pass copy];
}

- (void)setProxyPassword:(NSString *)pass
{
	_proxyPassword = [pass copy];
}

- (void)writeKeychainItemsToDisk
{
	[self writeNicknamePasswordKeychainItemToDisk];
	[self writeProxyPasswordKeychainItemToDisk];
	[self writeServerPasswordKeychainItemToDisk];
}

- (void)writeProxyPasswordKeychainItemToDisk
{
	if (_proxyPassword) {
		[XRKeychain modifyOrAddKeychainItem:@"Textual (Proxy Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_proxyPassword
								serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];
	}
	
	_proxyPassword = nil;
}

- (void)writeServerPasswordKeychainItemToDisk
{
	if (_serverPassword) {
		[XRKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_serverPassword
								serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	}

	_serverPassword = nil;
}

- (void)writeNicknamePasswordKeychainItemToDisk
{
	if (_nicknamePassword) {
		[XRKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_nicknamePassword
								serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
	}
	
	_nicknamePassword = nil;
}

- (void)destroyKeychains
{
	[XRKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];

	[XRKeychain deleteKeychainItem:@"Textual (Proxy Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];

	[XRKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
	
	[self resetKeychainStatus];
}

- (void)resetKeychainStatus
{
	/* Reset temporary store. */
	_proxyPassword = nil;
	_serverPassword = nil;
	_nicknamePassword = nil;
}

#pragma mark -
#pragma mark Server Configuration

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
	return [self initWithDictionary:dic ignorePrivateMessages:NO];
}

- (instancetype)initWithDictionary:(NSDictionary *)dic ignorePrivateMessages:(BOOL)ignorePMs
{
	if ((self = [self init])) {
		[self populateDictionaryValue:dic ignorePrivateMessages:ignorePMs];
	}

	return self;
}

- (void)populateDictionaryValue:(NSDictionary *)dic
{
	[self populateDictionaryValue:dic ignorePrivateMessages:NO];
}

- (void)populateDictionaryValue:(NSDictionary *)dic ignorePrivateMessages:(BOOL)ignorePMs
{
	/* Load legacy keys (if they exist) */
	[dic assignBoolTo:&_sidebarItemExpanded forKey:@"serverListItemIsExpanded"];

	[dic assignStringTo:&_nickname		forKey:@"identityNickname"];
	[dic assignStringTo:&_awayNickname	forKey:@"identityAwayNickname"];

	[dic assignArrayTo:&_alternateNicknames forKey:@"identityAlternateNicknames"];

	[dic assignStringTo:&_realName	forKey:@"identityRealname"];
	[dic assignStringTo:&_username	forKey:@"identityUsername"];

	[dic assignObjectTo:&_identityClientSideCertificate forKey:@"IdentitySSLCertificate" performCopy:YES];

	[dic assignBoolTo:&_autojoinWaitsForNickServ forKey:@"autojoinWaitsForNickServIdentification"];

	[dic assignBoolTo:&_autoConnect					forKey:@"connectOnLaunch"];
	[dic assignBoolTo:&_autoReconnect				forKey:@"connectOnDisconnect"];
	[dic assignBoolTo:&_autoSleepModeDisconnect		forKey:@"disconnectOnSleepMode"];

	[dic assignBoolTo:&_prefersSecuredConnection	forKey:@"connectUsingSSL"];
	[dic assignBoolTo:&_connectionPrefersIPv6		forKey:@"DNSResolverPrefersIPv6"];

	[dic assignBoolTo:&_validateServerCertificateChain	forKey:@"validateServerSideSSLCertificate"];

	[dic assignBoolTo:&_setInvisibleModeOnConnect	forKey:@"setInvisibleOnConnect"];

	[dic assignIntegerTo:&_proxyType		forKey:@"proxyServerType"];
	[dic assignIntegerTo:&_proxyPort		forKey:@"proxyServerPort"];
	[dic assignStringTo:&_proxyAddress		forKey:@"proxyServerAddress"];
	[dic assignStringTo:&_proxyUsername		forKey:@"proxyServerUsername"];

	[dic assignIntegerTo:&_primaryEncoding		forKey:@"characterEncodingDefault"];
	[dic assignIntegerTo:&_fallbackEncoding		forKey:@"characterEncodingFallback"];

	[dic assignStringTo:&_normalLeavingComment		forKey:@"connectionDisconnectDefaultMessage"];
	[dic assignStringTo:&_sleepModeLeavingComment	forKey:@"connectionDisconnectSleepModeMessage"];

	/* Flood control. */
	/* This is here to migrate to the new properties. Saving these values
	 in this dictionary key is no longer preferred. */
	if ([dic containsKey:@"floodControl"]) {
		NSDictionary *e = [dic dictionaryForKey:@"floodControl"];

		if (e) {
			[e assignBoolTo:&_isOutgoingFloodControlEnabled			forKey:@"serviceEnabled"];

			[e assignIntegerTo:&_floodControlMaximumMessages		forKey:@"maximumMessageCount"];
			[e assignIntegerTo:&_floodControlDelayTimerInterval		forKey:@"delayTimerInterval"];
		}
	}

	/* Migrate to keychain. */
	NSString *proxyPassword = [dic stringForKey:@"proxyServerPassword"];

	if (proxyPassword) {
		[self setProxyPassword:proxyPassword];
		[self writeProxyPasswordKeychainItemToDisk];
	}

	/* Load the newest set of keys. */
	[dic assignBoolTo:&_autoConnect								forKey:@"autoConnect"];
	[dic assignBoolTo:&_autoReconnect							forKey:@"autoReconnect"];
	[dic assignBoolTo:&_autoSleepModeDisconnect					forKey:@"autoSleepModeDisconnect"];

	[dic assignBoolTo:&_autojoinWaitsForNickServ				forKey:@"autojoinWaitsForNickServ"];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[dic assignBoolTo:&_excludedFromCloudSyncing				forKey:@"excludedFromCloudSyncing"];
#endif

	[dic assignBoolTo:&_performDisconnectOnPongTimer			forKey:@"performDisconnectOnPongTimer"];
	[dic assignBoolTo:&_performDisconnectOnReachabilityChange	forKey:@"performDisconnectOnReachabilityChange"];
	[dic assignBoolTo:&_performPongTimer						forKey:@"performPongTimer"];

	[dic assignBoolTo:&_hideNetworkUnavailabilityNotices		forKey:@"hideNetworkUnavailabilityNotices"];
	[dic assignBoolTo:&_saslAuthenticationUsesExternalMechanism forKey:@"saslAuthenticationUsesExternalMechanism"];
	[dic assignBoolTo:&_sendAuthenticationRequestsToUserServ	forKey:@"sendAuthenticationRequestsToUserServ"];
	[dic assignBoolTo:&_sendWhoCommandRequestsToChannels		forKey:@"sendWhoCommandRequestsToChannels"];
	[dic assignBoolTo:&_setInvisibleModeOnConnect				forKey:@"setInvisibleModeOnConnect"];

	[dic assignBoolTo:&_sidebarItemExpanded						forKey:@"sidebarItemExpanded"];

	[dic assignBoolTo:&_validateServerCertificateChain			forKey:@"validateServerCertificateChain"];

	[dic assignBoolTo:&_zncIgnoreConfiguredAutojoin				forKey:@"zncIgnoreConfiguredAutojoin"];
	[dic assignBoolTo:&_zncIgnorePlaybackNotifications			forKey:@"zncIgnorePlaybackNotifications"];

	[dic assignIntegerTo:&_fallbackEncoding					forKey:@"fallbackEncoding"];
	[dic assignIntegerTo:&_primaryEncoding					forKey:@"primaryEncoding"];

	[dic assignBoolTo:&_isOutgoingFloodControlEnabled		forKey:@"isOutgoingFloodControlEnabled"];
	[dic assignIntegerTo:&_floodControlDelayTimerInterval	forKey:@"floodControlDelayTimerInterval"];
	[dic assignIntegerTo:&_floodControlMaximumMessages		forKey:@"floodControlMaximumMessages"];

	[dic assignDoubleTo:&_cachedLastServerTimeCapacityReceivedAtTimestamp forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];

	[dic assignObjectTo:&_identityClientSideCertificate forKey:@"identityClientSideCertificate" performCopy:YES];

	[dic assignStringTo:&_itemUUID					forKey:@"uniqueIdentifier"];

	[dic assignStringTo:&_nickname					forKey:@"nickname"];
	[dic assignStringTo:&_awayNickname				forKey:@"awayNickname"];
	[dic assignStringTo:&_realName					forKey:@"realName"];
	[dic assignStringTo:&_username					forKey:@"username"];

	[dic assignStringTo:&_connectionName			forKey:@"connectionName"];
	[dic assignStringTo:&_serverAddress				forKey:@"serverAddress"];
	[dic assignIntegerTo:&_serverPort				forKey:@"serverPort"];
	[dic assignBoolTo:&_prefersSecuredConnection	forKey:@"prefersSecuredConnection"];
	[dic assignBoolTo:&_connectionPrefersIPv6		forKey:@"connectionPrefersIPv6"];

	[dic assignIntegerTo:&_proxyType				forKey:@"proxyType"];
	[dic assignStringTo:&_proxyAddress				forKey:@"proxyAddress"];
	[dic assignIntegerTo:&_proxyPort				forKey:@"proxyPort"];
	[dic assignStringTo:&_proxyUsername				forKey:@"proxyUsername"];

	[dic assignStringTo:&_sleepModeLeavingComment	forKey:@"sleepModeLeavingComment"];
	[dic assignStringTo:&_normalLeavingComment		forKey:@"normalLeavingComment"];

	[dic assignArrayTo:&_loginCommands				forKey:@"onConnectCommands"];

	/* Channel list. */
	NSMutableArray *channelList = [NSMutableArray array];

	for (NSDictionary *e in [dic arrayForKey:@"channelList"]) {
		IRCChannelConfig *c = [[IRCChannelConfig alloc] initWithDictionary:e];

		if ([c type] == IRCChannelPrivateMessageType) {
			if (ignorePMs == NO) {
				[channelList addObject:c];
			}
		} else {
			[channelList addObject:c];
		}
	}

	self.channelList = channelList;

	/* Ignore list. */
	NSMutableArray *ignoreList = [NSMutableArray array];

	for (NSDictionary *e in [dic arrayForKey:@"ignoreList"]) {
		IRCAddressBookEntry *ignore = [[IRCAddressBookEntry alloc] initWithDictionary:e];

		[ignoreList addObject:ignore];
	}

	self.ignoreList = ignoreList;

	/* Server specific highlight list. */
	NSMutableArray *highlightList = [NSMutableArray array];

	for (NSDictionary *e in [dic arrayForKey:@"highlightList"]) {
		TDCHighlightEntryMatchCondition *c = [[TDCHighlightEntryMatchCondition alloc] initWithDictionary:e];

		[highlightList addObject:c];
	}

	self.highlightList = highlightList;
}

- (BOOL)isEqualToClientConfiguration:(IRCClientConfig *)seed
{
	PointerIsEmptyAssertReturn(seed, NO);
	
	NSDictionary *s1 = [seed dictionaryValue];
	
	NSDictionary *s2 = [self dictionaryValue];
	
	/* Only declare ourselves as equal when we do not have any
	 temporary keychain items stored in memory. */
	return (NSObjectsAreEqual(s1, s2) &&
			NSObjectsAreEqual(_nicknamePassword, [seed temporaryNicknamePassword]) &&
			NSObjectsAreEqual(_serverAddress, [seed temporaryServerPassword]) &&
			NSObjectsAreEqual(_proxyPassword, [seed temporaryProxyPassword]));
}

- (NSDictionary *)dictionaryValueByStrippingDefaults:(NSMutableDictionary *)dic
{
	NSMutableDictionary *ndic = dic;

	NSDictionary *defaults = [self defaults];

	[dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if (NSObjectsAreEqual(defaults[key], obj)) {
			[ndic removeObjectForKey:key];
		}
	}];

	return [ndic copy];
}

- (NSDictionary *)dictionaryValue
{
	return [self dictionaryValue:NO];
}

- (NSDictionary *)dictionaryValue:(BOOL)isCloudDictionary
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	/* Set all properties into the dictionary. */
	[dic setBool:self.autoConnect						forKey:@"autoConnect"];
	[dic setBool:self.autoReconnect						forKey:@"autoReconnect"];
	[dic setBool:self.autoSleepModeDisconnect			forKey:@"autoSleepModeDisconnect"];

	[dic setBool:self.autojoinWaitsForNickServ			forKey:@"autojoinWaitsForNickServ"];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[dic setBool:self.excludedFromCloudSyncing			forKey:@"excludedFromCloudSyncing"];
#endif

	[dic setBool:self.performDisconnectOnPongTimer				forKey:@"performDisconnectOnPongTimer"];
	[dic setBool:self.performDisconnectOnReachabilityChange		forKey:@"performDisconnectOnReachabilityChange"];
	[dic setBool:self.performPongTimer							forKey:@"performPongTimer"];

	[dic setBool:self.hideNetworkUnavailabilityNotices			forKey:@"hideNetworkUnavailabilityNotices"];
	[dic setBool:self.saslAuthenticationUsesExternalMechanism	forKey:@"saslAuthenticationUsesExternalMechanism"];
	[dic setBool:self.sendAuthenticationRequestsToUserServ		forKey:@"sendAuthenticationRequestsToUserServ"];
	[dic setBool:self.sendWhoCommandRequestsToChannels			forKey:@"sendWhoCommandRequestsToChannels"];
	[dic setBool:self.setInvisibleModeOnConnect					forKey:@"setInvisibleModeOnConnect"];

	if (isCloudDictionary == NO) {
		[dic setBool:self.sidebarItemExpanded				forKey:@"sidebarItemExpanded"];
	}

	[dic setBool:self.validateServerCertificateChain		forKey:@"validateServerCertificateChain"];

	[dic setBool:self.zncIgnoreConfiguredAutojoin			forKey:@"zncIgnoreConfiguredAutojoin"];
	[dic setBool:self.zncIgnorePlaybackNotifications		forKey:@"zncIgnorePlaybackNotifications"];

	[dic setInteger:self.fallbackEncoding					forKey:@"fallbackEncoding"];
	[dic setInteger:self.primaryEncoding					forKey:@"primaryEncoding"];

	[dic setBool:self.isOutgoingFloodControlEnabled			forKey:@"isOutgoingFloodControlEnabled"];
	[dic setInteger:self.floodControlDelayTimerInterval		forKey:@"floodControlDelayTimerInterval"];
	[dic setInteger:self.floodControlMaximumMessages		forKey:@"floodControlMaximumMessages"];

	if (isCloudDictionary == NO) {
		[dic setDouble:self.cachedLastServerTimeCapacityReceivedAtTimestamp	forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];

		[dic maybeSetObject:self.identityClientSideCertificate forKey:@"identityClientSideCertificate"];
	}

	[dic maybeSetObject:self.itemUUID					forKey:@"uniqueIdentifier"];

	[dic maybeSetObject:self.nickname					forKey:@"nickname"];
	[dic maybeSetObject:self.awayNickname				forKey:@"awayNickname"];
	[dic maybeSetObject:self.realName					forKey:@"realName"];
	[dic maybeSetObject:self.username					forKey:@"username"];

	[dic maybeSetObject:self.connectionName				forKey:@"connectionName"];
	[dic maybeSetObject:self.serverAddress				forKey:@"serverAddress"];
	[dic setInteger:self.serverPort						forKey:@"serverPort"];
	[dic setBool:self.prefersSecuredConnection			forKey:@"prefersSecuredConnection"];
	[dic setBool:self.connectionPrefersIPv6				forKey:@"connectionPrefersIPv6"];

	[dic setInteger:self.proxyType						forKey:@"proxyType"];
	[dic maybeSetObject:self.proxyAddress				forKey:@"proxyAddress"];
	[dic setInteger:self.proxyPort						forKey:@"proxyPort"];
	[dic maybeSetObject:self.proxyUsername				forKey:@"proxyUsername"];

	[dic maybeSetObject:self.sleepModeLeavingComment	forKey:@"sleepModeLeavingComment"];
	[dic maybeSetObject:self.normalLeavingComment		forKey:@"normalLeavingComment"];

	[dic maybeSetObject:self.loginCommands				forKey:@"onConnectCommands"];

	/* Build arrays of certain objects. */
	NSMutableArray *highlightAry = [NSMutableArray array];
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channelList) {
		[channelAry addObject:[e dictionaryValue]];
	}
	
	for (IRCAddressBookEntry *e in self.ignoreList) {
		[ignoreAry addObject:[e dictionaryValue]];
	}

	for (TDCHighlightEntryMatchCondition *e in self.highlightList) {
		[highlightAry addObject:[e dictionaryValue]];
	}

	if ([highlightAry count] > 0) {
		[dic maybeSetObject:highlightAry forKey:@"highlightList"];
	}

	if ([channelAry count] > 0) {
		[dic maybeSetObject:channelAry forKey:@"channelList"];
	}

	if ([ignoreAry count] > 0) {
		[dic maybeSetObject:ignoreAry forKey:@"ignoreList"];
	}

	return [self dictionaryValueByStrippingDefaults:dic];
}

- (id)copyWithZone:(NSZone *)zone
{
	IRCClientConfig *mut = [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue] ignorePrivateMessages:NO];
	
	[mut setNicknamePassword:_nicknamePassword];
	[mut setServerPassword:_serverPassword];
	[mut setProxyPassword:_proxyPassword];
	
	return mut;
}

- (id)copyWithoutPrivateMessages
{
	IRCClientConfig *mut = [[IRCClientConfig alloc] initWithDictionary:[self dictionaryValue] ignorePrivateMessages:YES];
	
	[mut setNicknamePassword:_nicknamePassword];
	[mut setServerPassword:_serverPassword];
	[mut setProxyPassword:_proxyPassword];
	
	return mut;
}

@end
