/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

NSComparisonResult IRCChannelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [s1.name.lowercaseString compare:s2.name.lowercaseString];
}

@implementation IRCClientConfig

- (id)init
{
	if ((self = [super init])) {
		self.itemUUID = [NSString stringWithUUID];
		
		self.alternateNicknames		= [NSMutableArray new];
		self.loginCommands			= [NSMutableArray new];
		self.highlightList			= [NSMutableArray new];
		self.channelList			= [NSMutableArray new];
		self.ignoreList				= [NSMutableArray new];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		self.excludedFromCloudSyncing = NO;
#endif

		self.autoConnect					= NO;
		self.autoReconnect					= NO;
		self.autoSleepModeDisconnect		= YES;
		self.performPongTimer				= YES;
		self.performDisconnectOnPongTimer	= NO;
		
		self.connectionUsesSSL	= NO;
		self.nicknamePassword	= NSStringEmptyPlaceholder;
		self.serverAddress      = NSStringEmptyPlaceholder;
		self.serverPassword     = NSStringEmptyPlaceholder;
		self.serverPort         = IRCConnectionDefaultServerPort;
		
		self.invisibleMode       = NO;
		self.isTrustedConnection = NO;

		self.zncIgnorePlaybackNotifications = YES;

		self.proxyType		 = TXConnectionNoProxyType;
		self.proxyAddress    = NSStringEmptyPlaceholder;
		self.proxyPort       = 1080;
		self.proxyUsername   = NSStringEmptyPlaceholder;
		self.proxyPassword   = NSStringEmptyPlaceholder;

        self.connectionPrefersIPv6 = NO;
		
		self.primaryEncoding = TXDefaultPrimaryTextEncoding;
		self.fallbackEncoding = TXDefaultFallbackTextEncoding;
        
        self.outgoingFloodControl            = YES;
        self.floodControlMaximumMessages     = TXFloodControlDefaultMessageCount;
		self.floodControlDelayTimerInterval  = TXFloodControlDefaultDelayTimer;
		
		self.clientName = TXTLS(@"DefaultNewConnectionName");
		
		self.nickname = [TPCPreferences defaultNickname];
		self.awayNickname = [TPCPreferences defaultAwayNickname];
		self.username = [TPCPreferences defaultUsername];
		self.realname = [TPCPreferences defaultRealname];
		
		self.normalLeavingComment		= TXTLS(@"DefaultDisconnectQuitMessage");
		self.sleepModeLeavingComment	= TXTFLS(@"OSXGoingToSleepQuitMessage", [CSFWSystemInformation systemModelName]);
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
												 forUsername:[TPCPreferences applicationName] // Compatible with 2.1.1
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
		
	}

	return kcPassword;
}

- (void)setNicknamePassword:(NSString *)pass
{
	self.nicknamePasswordIsSet = NSObjectIsNotEmpty(pass);

	if (self.nicknamePasswordIsSet == NO) {
		[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:pass
								serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.itemUUID]];
	}
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
												 forUsername:[TPCPreferences applicationName] // Compatible with 2.1.1
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	}

	return kcPassword;
}

- (void)setServerPassword:(NSString *)pass
{
	self.serverPasswordIsSet = NSObjectIsNotEmpty(pass);

	if (self.serverPasswordIsSet == NO) {
		[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:pass
								serviceName:[NSString stringWithFormat:@"textual.server.%@", self.itemUUID]];		
	}
}

- (NSString *)proxyPassword
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Proxy Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];

	return kcPassword;
}

- (void)setProxyPassword:(NSString *)pass
{
	self.proxyPasswordIsSet = NSObjectIsNotEmpty(pass);

	if (self.proxyPasswordIsSet == NO) {
		[AGKeychain deleteKeychainItem:@"Textual (Proxy Server Password)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Proxy Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:pass
								serviceName:[NSString stringWithFormat:@"textual.proxy-server.%@", self.itemUUID]];
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
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		/* General preferences. */
        self.sidebarItemExpanded = NSDictionaryBOOLKeyValueCompare(dic, @"serverListItemIsExpanded", YES);

		self.itemUUID		= NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", self.itemUUID);
		self.clientName		= NSDictionaryObjectKeyValueCompare(dic, @"connectionName", self.clientName);
		self.nickname		= NSDictionaryObjectKeyValueCompare(dic, @"identityNickname", self.nickname);
		self.awayNickname	= NSDictionaryObjectKeyValueCompare(dic, @"identityAwayNickname", self.awayNickname);
		self.realname		= NSDictionaryObjectKeyValueCompare(dic, @"identityRealname", self.realname);
		self.serverAddress	= NSDictionaryObjectKeyValueCompare(dic, @"serverAddress", self.serverAddress);
		self.serverPort		= NSDictionaryIntegerKeyValueCompare(dic, @"serverPort", self.serverPort);
		self.username		= NSDictionaryObjectKeyValueCompare(dic, @"identityUsername", self.username);

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		self.excludedFromCloudSyncing = NSDictionaryBOOLKeyValueCompare(dic, @"excludeFromCloudSyncing", self.excludedFromCloudSyncing);
#endif

		self.zncIgnorePlaybackNotifications	= NSDictionaryBOOLKeyValueCompare(dic, @"ZNC —> Ignore Playback Buffer Highlights", self.zncIgnorePlaybackNotifications);

		[self.alternateNicknames addObjectsFromArray:[dic arrayForKey:@"identityAlternateNicknames"]];
		
		self.proxyType       = (TXConnectionProxyType)NSDictionaryIntegerKeyValueCompare(dic, @"proxyServerType", self.proxyType);
		
		self.proxyAddress	= NSDictionaryObjectKeyValueCompare(dic, @"proxyServerAddress", self.proxyAddress);
		self.proxyPort      = NSDictionaryIntegerKeyValueCompare(dic, @"proxyServerPort", self.proxyPort);
		self.proxyUsername	= NSDictionaryObjectKeyValueCompare(dic, @"proxyServerUsername", self.proxyUsername);
		
		self.autoConnect				= NSDictionaryBOOLKeyValueCompare(dic, @"connectOnLaunch", self.autoConnect);
		self.autoReconnect				= NSDictionaryBOOLKeyValueCompare(dic, @"connectOnDisconnect", self.autoReconnect);
		self.autoSleepModeDisconnect	= NSDictionaryBOOLKeyValueCompare(dic, @"disconnectOnSleepMode", self.autoSleepModeDisconnect);
		self.connectionUsesSSL			= NSDictionaryBOOLKeyValueCompare(dic, @"connectUsingSSL", self.connectionUsesSSL);

		self.performPongTimer				= NSDictionaryBOOLKeyValueCompare(dic, @"performPongTimer", self.performPongTimer);
		self.performDisconnectOnPongTimer	= NSDictionaryBOOLKeyValueCompare(dic, @"performDisconnectOnPongTimer", self.performDisconnectOnPongTimer);

		self.fallbackEncoding			= NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingFallback", self.fallbackEncoding);
		self.normalLeavingComment		= NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectDefaultMessage", self.normalLeavingComment);
		self.primaryEncoding			= NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingDefault", self.primaryEncoding);
		self.sleepModeLeavingComment	= NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectSleepModeMessage", self.sleepModeLeavingComment);
		
		self.connectionPrefersIPv6  = NSDictionaryBOOLKeyValueCompare(dic, @"DNSResolverPrefersIPv6", self.connectionPrefersIPv6);
		self.invisibleMode			= NSDictionaryBOOLKeyValueCompare(dic, @"setInvisibleOnConnect", self.invisibleMode);
		self.isTrustedConnection	= NSDictionaryBOOLKeyValueCompare(dic, @"trustedSSLConnection", self.isTrustedConnection);
		
		[self.loginCommands addObjectsFromArray:[dic arrayForKey:@"onConnectCommands"]];

		/* Channel list. */
		for (NSDictionary *e in [dic arrayForKey:@"channelList"]) {
			IRCChannelConfig *c = [[IRCChannelConfig alloc] initWithDictionary:e];
			
			[self.channelList safeAddObject:c];
		}

		/* Ignore list. */
		for (NSDictionary *e in [dic arrayForKey:@"ignoreList"]) {
			IRCAddressBook *ignore = [[IRCAddressBook alloc] initWithDictionary:e];
			
			[self.ignoreList safeAddObject:ignore];
		}

		/* Server specific highlight list. */
		for (NSDictionary *e in [dic arrayForKey:@"highlightList"]) {
			TDCHighlightEntryMatchCondition *c = [[TDCHighlightEntryMatchCondition alloc] initWithDictionary:e];

			[self.highlightList safeAddObject:c];
		}

		/* Flood control. */
		if ([dic containsKey:@"floodControl"]) {
			NSDictionary *e = [dic dictionaryForKey:@"floodControl"];
			
			if (NSObjectIsNotEmpty(e)) {
				self.outgoingFloodControl = NSDictionaryBOOLKeyValueCompare(e, @"serviceEnabled", self.outgoingFloodControl);

				self.floodControlMaximumMessages = NSDictionaryIntegerKeyValueCompare(e, @"maximumMessageCount", TXFloodControlDefaultMessageCount);
				self.floodControlDelayTimerInterval	= NSDictionaryIntegerKeyValueCompare(e, @"delayTimerInterval", TXFloodControlDefaultDelayTimer);
			}
		}

		/* Migrate to keychain. */
		NSString *proxyPassword = [dic stringForKey:@"proxyServerPassword"];

		if (NSObjectIsNotEmpty(proxyPassword)) {
			[self setProxyPassword:proxyPassword];
		}

		/* Get a base reading. */
		self.serverPasswordIsSet = NSObjectIsNotEmpty(self.serverPassword);
		self.nicknamePasswordIsSet = NSObjectIsNotEmpty(self.nicknamePassword);
		self.proxyPasswordIsSet = NSObjectIsNotEmpty(self.proxyPassword);

		/* We're done. */
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
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
	[dic setBool:self.performDisconnectOnPongTimer	forKey:@"performDisconnectOnPongTimer"];	
	[dic setBool:self.invisibleMode					forKey:@"setInvisibleOnConnect"];
	[dic setBool:self.isTrustedConnection			forKey:@"trustedSSLConnection"];
    [dic setBool:self.connectionPrefersIPv6			forKey:@"DNSResolverPrefersIPv6"];
    [dic setBool:self.sidebarItemExpanded			forKey:@"serverListItemIsExpanded"];

	[dic setBool:self.zncIgnorePlaybackNotifications	forKey:@"ZNC —> Ignore Playback Buffer Highlights"];

	[dic safeSetObject:self.alternateNicknames			forKey:@"identityAlternateNicknames"];
	[dic safeSetObject:self.clientName					forKey:@"connectionName"];
	[dic safeSetObject:self.itemUUID					forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.loginCommands				forKey:@"onConnectCommands"];
	[dic safeSetObject:self.nickname					forKey:@"identityNickname"];
	[dic safeSetObject:self.awayNickname				forKey:@"identityAwayNickname"];
	[dic safeSetObject:self.normalLeavingComment		forKey:@"connectionDisconnectDefaultMessage"];
	[dic safeSetObject:self.proxyAddress				forKey:@"proxyServerAddress"];
	[dic safeSetObject:self.proxyUsername				forKey:@"proxyServerUsername"];
	[dic safeSetObject:self.realname					forKey:@"identityRealname"];
	[dic safeSetObject:self.serverAddress				forKey:@"serverAddress"];
	[dic safeSetObject:self.sleepModeLeavingComment		forKey:@"connectionDisconnectSleepModeMessage"];
	[dic safeSetObject:self.username					forKey:@"identityUsername"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:self.floodControlDelayTimerInterval	forKey:@"delayTimerInterval"];
    [floodControl setInteger:self.floodControlMaximumMessages		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:self.outgoingFloodControl forKey:@"serviceEnabled"];
    
	[dic safeSetObject:floodControl forKey:@"floodControl"];

	NSMutableArray *highlightAry = [NSMutableArray array];
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channelList) {
		[channelAry safeAddObject:[e dictionaryValue]];
	}
	
	for (IRCAddressBook *e in self.ignoreList) {
		[ignoreAry safeAddObject:[e dictionaryValue]];
	}

	for (TDCHighlightEntryMatchCondition *e in self.highlightList) {
		[highlightAry safeAddObject:[e dictionaryValue]];
	}

	[dic safeSetObject:highlightAry forKey:@"highlightList"];
	[dic safeSetObject:channelAry forKey:@"channelList"];
	[dic safeSetObject:ignoreAry forKey:@"ignoreList"];
	
	NSUInteger dictHash = [dic phash];
	
	[dic safeSetObject:@(dictHash) forKey:@"dictionaryHash"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
