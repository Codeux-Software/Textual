/* ********************************************************************* 
       _____        _               _    ___ ____   ____
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

#import "TextualApplication.h"

@implementation IRCClientConfig

@synthesize serverPassword = _serverPassword;
@synthesize proxyPassword = _proxyPassword;
@synthesize nicknamePassword = _nicknamePassword;

- (id)init
{
	if ((self = [super init])) {
		self.itemUUID = [NSString stringWithUUID];
		
		self.sidebarItemExpanded		= YES;
		
		self.alternateNicknames			= @[];
		self.loginCommands				= @[];
		self.highlightList				= @[];
		self.channelList				= @[];
		self.ignoreList					= @[];

		self.cachedLastServerTimeCapacityReceivedAtTimestamp = 0;
		
		self.hideNetworkUnavailabilityNotices			= NO;
		self.saslAuthenticationUsesExternalMechanism	= NO;
		self.sendAuthenticationRequestsToUserServ		= NO;
		
		self.identitySSLCertificate			= nil;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		self.excludedFromCloudSyncing		= NO;
#endif

		self.autoConnect					= NO;
		self.autoReconnect					= NO;
		self.autoSleepModeDisconnect		= YES;
		
		self.performPongTimer				= YES;

		self.performDisconnectOnPongTimer				= NO;
		self.performDisconnectOnReachabilityChange		= YES;
		
		self.validateServerSSLCertificate = YES;
		
		self.connectionUsesSSL			= NO;
		self.connectionPrefersIPv6		= NO;
		
		self.serverAddress      = NSStringEmptyPlaceholder;
		self.serverPort         = IRCConnectionDefaultServerPort;
		
		self.invisibleMode = NO;

		self.zncIgnoreConfiguredAutojoin = NO;
		self.zncIgnorePlaybackNotifications = YES;

		self.proxyType		 = IRCConnectionSocketNoProxyType;
		self.proxyAddress    = NSStringEmptyPlaceholder;
		self.proxyPort       = 1080;
		self.proxyUsername   = NSStringEmptyPlaceholder;
		
		self.primaryEncoding	= TXDefaultPrimaryStringEncoding;
		self.fallbackEncoding	= TXDefaultFallbackStringEncoding;
        
        self.outgoingFloodControl            = YES;
		
		self.floodControlMaximumMessages     = IRCClientConfigFloodControlDefaultMessageCount;
		self.floodControlDelayTimerInterval  = IRCClientConfigFloodControlDefaultDelayTimer;
		
		self.clientName = BLS(1022);
		
		self.nickname		= [TPCPreferences defaultNickname];
		self.awayNickname	= [TPCPreferences defaultAwayNickname];
		self.username		= [TPCPreferences defaultUsername];
		self.realname		= [TPCPreferences defaultRealname];
		
		self.normalLeavingComment		= BLS(1021);
		
		NSString *modelName = [CSFWSystemInformation systemModelName];
		
		if (modelName == nil) { // Value can be nil in virtual machine.
			self.sleepModeLeavingComment = BLS(1235);
		} else {
			self.sleepModeLeavingComment = BLS(1185, modelName);
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)nicknamePassword
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];

	if (kcPassword == nil) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
												withItemKind:@"application password"
												 forUsername:[TPCApplicationInfo applicationName] // Compatible with 2.1.1
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
		
	}

	return kcPassword;
}

- (NSString *)serverPassword
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];

	if (kcPassword == nil) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
												withItemKind:@"application password"
												 forUsername:[TPCApplicationInfo applicationName] // Compatible with 2.1.1
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	}

	return kcPassword;
}

- (NSString *)proxyPassword
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Proxy Server Password)"
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
	self.nicknamePasswordIsSet = NSObjectIsNotEmpty(pass);
	
	_nicknamePassword = pass;
}

- (void)setServerPassword:(NSString *)pass
{
	self.serverPasswordIsSet = NSObjectIsNotEmpty(pass);
	
	_serverPassword = pass;
}

- (void)setProxyPassword:(NSString *)pass
{
	self.proxyPasswordIsSet = NSObjectIsNotEmpty(pass);

	_proxyPassword = pass;
}

- (void)writeKeychainItemsToDisk
{
	[self writeNicknamePasswordKeychainItemToDisk];
	[self writeProxyPasswordKeychainItemToDisk];
	[self writeServerPasswordKeychainItemToDisk];
}

- (void)writeProxyPasswordKeychainItemToDisk
{
	if (self.proxyPasswordIsSet == NO) {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Proxy Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:NSStringEmptyPlaceholder
								serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];
	} else {
		/* Write proxy password to keychain. */
		NSObjectIsEmptyAssert(_proxyPassword);
		
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Proxy Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_proxyPassword
								serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];
	
		_proxyPassword = nil;
	}
}

- (void)writeServerPasswordKeychainItemToDisk
{
	if (self.serverPasswordIsSet == NO) {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:NSStringEmptyPlaceholder
								serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	} else {
		/* Write server password to keychain. */
		NSObjectIsEmptyAssert(_serverPassword);
		
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_serverPassword
								serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	
		_serverPassword = nil;
	}
}

- (void)writeNicknamePasswordKeychainItemToDisk
{
	if (self.nicknamePasswordIsSet == NO) {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:NSStringEmptyPlaceholder
								serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
	} else {
		/* Write nickname password to keychain. */
		NSObjectIsEmptyAssert(_nicknamePassword);
		
		[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_nicknamePassword
								serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
		
		_nicknamePassword = nil;
	}
}

- (void)destroyKeychains
{	
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];

	[AGKeychain deleteKeychainItem:@"Textual (Proxy Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];

	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];

	self.serverPasswordIsSet = NO;
	self.nicknamePasswordIsSet = NO;
	self.proxyPasswordIsSet = NO;
	
	_serverPassword = nil;
	_nicknamePassword = nil;
	_proxyPassword = nil;
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	return [self initWithDictionary:dic ignorePrivateMessages:NO checkKeychainStatus:YES];
}

- (id)initWithDictionary:(NSDictionary *)dic ignorePrivateMessages:(BOOL)ignorePMs checkKeychainStatus:(BOOL)checkKeychainIsSet
{
	if ((self = [self init])) {
		/* If any key does not exist, then its value is inherited from the -init method. */
        [dic assignBoolTo:&_sidebarItemExpanded forKey:@"serverListItemIsExpanded"];

		[dic assignStringTo:&_itemUUID forKey:@"uniqueIdentifier"];
		
		[dic assignStringTo:&_clientName forKey:@"connectionName"];

		[dic assignStringTo:&_nickname forKey:@"identityNickname"];
		[dic assignStringTo:&_awayNickname forKey:@"identityAwayNickname"];
		
		[dic assignArrayTo:&_alternateNicknames forKey:@"identityAlternateNicknames"];
		
		[dic assignStringTo:&_realname forKey:@"identityRealname"];
		[dic assignStringTo:&_username forKey:@"identityUsername"];

		[dic assignObjectTo:&_identitySSLCertificate forKey:@"IdentitySSLCertificate" performCopy:YES];
		
		[dic assignStringTo:&_serverAddress forKey:@"serverAddress"];
		
		[dic assignIntegerTo:&_serverPort forKey:@"serverPort"];
		
		[dic assignBoolTo:&_autoConnect forKey:@"connectOnLaunch"];
		[dic assignBoolTo:&_autoReconnect forKey:@"connectOnDisconnect"];
		[dic assignBoolTo:&_autoSleepModeDisconnect forKey:@"disconnectOnSleepMode"];
		
		[dic assignBoolTo:&_connectionUsesSSL forKey:@"connectUsingSSL"];
		[dic assignBoolTo:&_connectionPrefersIPv6 forKey:@"DNSResolverPrefersIPv6"];
		
		[dic assignBoolTo:&_validateServerSSLCertificate forKey:@"validateServerSideSSLCertificate"];
		
		[dic assignBoolTo:&_performPongTimer forKey:@"performPongTimer"];
		
		[dic assignBoolTo:&_invisibleMode forKey:@"setInvisibleOnConnect"];
		
		[dic assignBoolTo:&_performDisconnectOnPongTimer forKey:@"performDisconnectOnPongTimer"];
		[dic assignBoolTo:&_performDisconnectOnReachabilityChange forKey:@"performDisconnectOnReachabilityChange"];
		
		[dic assignIntegerTo:&_proxyType forKey:@"proxyServerType"];
		
		[dic assignStringTo:&_proxyAddress forKey:@"proxyServerAddress"];
		[dic assignIntegerTo:&_proxyPort forKey:@"proxyServerPort"];
		[dic assignStringTo:&_proxyUsername forKey:@"proxyServerUsername"];
		
		[dic assignIntegerTo:&_primaryEncoding forKey:@"characterEncodingDefault"];
		[dic assignIntegerTo:&_fallbackEncoding forKey:@"characterEncodingFallback"];
		
		[dic assignStringTo:&_normalLeavingComment forKey:@"connectionDisconnectDefaultMessage"];
		[dic assignStringTo:&_sleepModeLeavingComment forKey:@"connectionDisconnectSleepModeMessage"];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		[dic assignBoolTo:&_excludedFromCloudSyncing forKey:@"excludeFromCloudSyncing"];
#endif
		
		[dic assignBoolTo:&_zncIgnoreConfiguredAutojoin forKey:@"ZNC —> Ignore Pre-configured Autojoin"];
		[dic assignBoolTo:&_zncIgnorePlaybackNotifications forKey:@"ZNC —> Ignore Playback Buffer Highlights"];
		
		[dic assignBoolTo:&_hideNetworkUnavailabilityNotices forKey:@"hideNetworkUnavailabilityNotices"];
		[dic assignBoolTo:&_saslAuthenticationUsesExternalMechanism forKey:@"saslAuthenticationUsesExternalMechanism"];
		[dic assignBoolTo:&_sendAuthenticationRequestsToUserServ forKey:@"sendAuthenticationRequestsToUserServ"];
		
		[dic assignDoubleTo:&_cachedLastServerTimeCapacityReceivedAtTimestamp forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];
		
		[dic assignArrayTo:&_loginCommands forKey:@"onConnectCommands"];
		
		/* Channel list. */
		NSMutableArray *channelList = [NSMutableArray array];

		for (NSDictionary *e in [dic arrayForKey:@"channelList"]) {
			IRCChannelConfig *c = [[IRCChannelConfig alloc] initWithDictionary:e];
			
			if (c.type == IRCChannelPrivateMessageType) {
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

		/* Flood control. */
		if ([dic containsKey:@"floodControl"]) {
			NSDictionary *e = [dic dictionaryForKey:@"floodControl"];
			
			if (e) {
				[e assignBoolTo:&_outgoingFloodControl forKey:@"serviceEnabled"];
			
				[e assignIntegerTo:&_floodControlMaximumMessages forKey:@"maximumMessageCount"];
				[e assignIntegerTo:&_floodControlDelayTimerInterval forKey:@"delayTimerInterval"];
			}
		}

		/* Migrate to keychain. */
		NSString *proxyPassword = [dic stringForKey:@"proxyServerPassword"];

		if (proxyPassword) {
			[self setProxyPassword:proxyPassword];
			[self writeProxyPasswordKeychainItemToDisk];
		}

		/* Get a base reading. */
		if (checkKeychainIsSet) {
			self.proxyPasswordIsSet		= NSObjectIsNotEmpty(self.proxyPassword);
			self.serverPasswordIsSet	= NSObjectIsNotEmpty(self.serverPassword);
			self.nicknamePasswordIsSet	= NSObjectIsNotEmpty(self.nicknamePassword);
		}
		
		/* We're done. */
		return self;
	}
	
	return nil;
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
			NSObjectsAreEqual(_proxyPassword, [seed temporaryProxyPassword]) &&
			_nicknamePasswordIsSet == [seed nicknamePasswordIsSet] &&
			_serverPasswordIsSet == [seed serverPasswordIsSet] &&
			_proxyPasswordIsSet == [seed proxyPasswordIsSet]);
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self dictionaryValue:NO];
}

- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.fallbackEncoding	forKey:@"characterEncodingFallback"];
	[dic setInteger:self.primaryEncoding	forKey:@"characterEncodingDefault"];
	[dic setInteger:self.proxyPort			forKey:@"proxyServerPort"];
	[dic setInteger:self.proxyType			forKey:@"proxyServerType"];
	[dic setInteger:self.serverPort			forKey:@"serverPort"];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[dic setBool:self.excludedFromCloudSyncing forKey:@"excludeFromCloudSyncing"];
#endif

	[dic setBool:self.autoConnect					forKey:@"connectOnLaunch"];
	[dic setBool:self.autoReconnect					forKey:@"connectOnDisconnect"];
	[dic setBool:self.autoSleepModeDisconnect		forKey:@"disconnectOnSleepMode"];
	[dic setBool:self.connectionUsesSSL				forKey:@"connectUsingSSL"];
	[dic setBool:self.performPongTimer				forKey:@"performPongTimer"];
	[dic setBool:self.invisibleMode					forKey:@"setInvisibleOnConnect"];
	[dic setBool:self.connectionPrefersIPv6			forKey:@"DNSResolverPrefersIPv6"];

    [dic setBool:self.sidebarItemExpanded			forKey:@"serverListItemIsExpanded"];
	
	[dic setBool:self.performDisconnectOnPongTimer				forKey:@"performDisconnectOnPongTimer"];
	[dic setBool:self.performDisconnectOnReachabilityChange		forKey:@"performDisconnectOnReachabilityChange"];
	
	if (isCloudDictionary == NO) {
		/* Identify certificate is stored as a referenced to the actual keychain. */
		/* This cannot be transmitted over the cloud. */

		[dic maybeSetObject:self.identitySSLCertificate forKey:@"IdentitySSLCertificate"];
	}

	[dic setBool:self.validateServerSSLCertificate		forKey:@"validateServerSideSSLCertificate"];

	[dic setBool:self.zncIgnorePlaybackNotifications	forKey:@"ZNC —> Ignore Playback Buffer Highlights"];
	[dic setBool:self.zncIgnoreConfiguredAutojoin		forKey:@"ZNC —> Ignore Pre-configured Autojoin"];

	[dic setBool:self.hideNetworkUnavailabilityNotices			forKey:@"hideNetworkUnavailabilityNotices"];
	[dic setBool:self.saslAuthenticationUsesExternalMechanism	forKey:@"saslAuthenticationUsesExternalMechanism"];
	[dic setBool:self.sendAuthenticationRequestsToUserServ		forKey:@"sendAuthenticationRequestsToUserServ"];
	
	[dic setDouble:self.cachedLastServerTimeCapacityReceivedAtTimestamp		forKey:@"cachedLastServerTimeCapacityReceivedAtTimestamp"];
	
	[dic maybeSetObject:self.alternateNicknames			forKey:@"identityAlternateNicknames"];
	[dic maybeSetObject:self.clientName					forKey:@"connectionName"];
	[dic maybeSetObject:self.itemUUID					forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.loginCommands				forKey:@"onConnectCommands"];
	[dic maybeSetObject:self.nickname					forKey:@"identityNickname"];
	[dic maybeSetObject:self.awayNickname				forKey:@"identityAwayNickname"];
	[dic maybeSetObject:self.normalLeavingComment		forKey:@"connectionDisconnectDefaultMessage"];
	[dic maybeSetObject:self.proxyAddress				forKey:@"proxyServerAddress"];
	[dic maybeSetObject:self.proxyUsername				forKey:@"proxyServerUsername"];
	[dic maybeSetObject:self.realname					forKey:@"identityRealname"];
	[dic maybeSetObject:self.serverAddress				forKey:@"serverAddress"];
	[dic maybeSetObject:self.sleepModeLeavingComment	forKey:@"connectionDisconnectSleepModeMessage"];
	[dic maybeSetObject:self.username					forKey:@"identityUsername"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:self.floodControlDelayTimerInterval	forKey:@"delayTimerInterval"];
    [floodControl setInteger:self.floodControlMaximumMessages		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:self.outgoingFloodControl forKey:@"serviceEnabled"];
    
	[dic maybeSetObject:floodControl forKey:@"floodControl"];

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

	[dic maybeSetObject:highlightAry forKey:@"highlightList"];
	[dic maybeSetObject:channelAry forKey:@"channelList"];
	[dic maybeSetObject:ignoreAry forKey:@"ignoreList"];
	
	return dic;
}

- (id)copyWithZone:(NSZone *)zone
{
	IRCClientConfig *mut = [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue] ignorePrivateMessages:NO checkKeychainStatus:NO];
	
	[mut setNicknamePassword:_nicknamePassword];
	[mut setServerPassword:_serverPassword];
	[mut setProxyPassword:_proxyPassword];
	
	[mut setNicknamePasswordIsSet:_nicknamePasswordIsSet];
	[mut setServerPasswordIsSet:_serverPasswordIsSet];
	[mut setProxyPasswordIsSet:_proxyPasswordIsSet];
	
	return mut;
}

- (id)copyWithoutPrivateMessages
{
	IRCClientConfig *mut = [[IRCClientConfig alloc] initWithDictionary:[self dictionaryValue] ignorePrivateMessages:YES checkKeychainStatus:NO];
	
	[mut setNicknamePassword:_nicknamePassword];
	[mut setServerPassword:_serverPassword];
	[mut setProxyPassword:_proxyPassword];
	
	[mut setNicknamePasswordIsSet:_nicknamePasswordIsSet];
	[mut setServerPasswordIsSet:_serverPasswordIsSet];
	[mut setProxyPasswordIsSet:_proxyPasswordIsSet];
	
	return mut;
}

@end
