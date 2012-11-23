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

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [s1.name.lowercaseString compare:s2.name.lowercaseString];
}

@implementation IRCClientConfig

@synthesize password = _password;
@synthesize nickPassword = _nickPassword;

- (id)init
{
	if ((self = [super init])) {
		self.cuid = TXRandomNumber(9999);
		self.guid = [NSString stringWithUUID];
		
		self.ignores         = [NSMutableArray new];
		self.altNicks        = [NSMutableArray new];
		self.channels        = [NSMutableArray new];
		self.loginCommands   = [NSMutableArray new];
		
		self.host         = NSStringEmptyPlaceholder;
		self.port         = 6667;
		self.password     = NSStringEmptyPlaceholder;
		self.nickPassword = NSStringEmptyPlaceholder;
		
		self.proxyHost       = NSStringEmptyPlaceholder;
		self.proxyPort       = 1080;
		self.proxyUser       = NSStringEmptyPlaceholder;
		self.proxyPassword   = NSStringEmptyPlaceholder;
        
        self.prefersIPv6 = NO;
		
		self.encoding         = NSUTF8StringEncoding;
		self.fallbackEncoding = NSISOLatin1StringEncoding;
        
        self.outgoingFloodControl            = NO;
        self.floodControlMaximumMessages     = TXFloodControlDefaultMessageCount;
		self.floodControlDelayTimerInterval  = TXFloodControlDefaultDelayTimer;
		
		self.name        = TXTLS(@"DefaultNewConnectionName");
		self.nick        = [TPCPreferences defaultNickname];
		self.username    = [TPCPreferences defaultUsername];
		self.realName    = [TPCPreferences defaultRealname];
		
		self.leavingComment      = TXTLS(@"DefaultDisconnectQuitMessage");
		self.sleepQuitMessage    = TXTLS(@"OSXGoingToSleepQuitMessage");
	}
	
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)nickPassword
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(_nickPassword)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
												withItemKind:@"application password" 
												 forUsername:[TPCPreferences applicationName] 
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];

		if (kcPassword) {
			kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
													withItemKind:@"application password"
													 forUsername:nil // Compatible with 2.1.0
													 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
		}
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:_nickPassword] == NO) {
			_nickPassword = nil;
			_nickPassword = kcPassword;
		}
	}
	
	return _nickPassword;
}

- (void)setNickPassword:(NSString *)pass
{
	if ([_nickPassword isEqualToString:pass] == NO) {	
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
							  withItemKind:@"application password"
							   forUsername:[TPCPreferences applicationName]
							   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
								   withItemKind:@"application password"
									forUsername:[TPCPreferences applicationName]
								withNewPassword:pass
									serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
		}
		
		_nickPassword = nil;
		_nickPassword = pass;
	}
}

- (NSString *)password
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(_password)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
												withItemKind:@"application password" 
												 forUsername:[TPCPreferences applicationName]
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];

		if (kcPassword) {
			kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
													withItemKind:@"application password"
													 forUsername:nil // Compatible with 2.1.0
													 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
		}
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:_password] == NO) {
			_password = nil;
			_password = kcPassword;
		}
	}
	
	return _password;
}

- (void)setPassword:(NSString *)pass
{
	if ([_password isEqualToString:pass] == NO) {
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
							  withItemKind:@"application password"
							   forUsername:[TPCPreferences applicationName]
							   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
								   withItemKind:@"application password"
									forUsername:[TPCPreferences applicationName]
								withNewPassword:pass
									serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];			
		}
		
		_password = nil;
		_password = pass;
	}
}

- (void)destroyKeychains
{	
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:[TPCPreferences applicationName]
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
	
	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:[TPCPreferences applicationName]
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		dic = [TPCPreferencesMigrationAssistant convertIRCClientConfiguration:dic];
		
		self.cuid		= NSDictionaryIntegerKeyValueCompare(dic, @"connectionID", self.cuid);
		self.guid		= NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", self.guid);
		self.name		= NSDictionaryObjectKeyValueCompare(dic, @"connectionName", self.name);
		self.host		= NSDictionaryObjectKeyValueCompare(dic, @"serverAddress", self.host);
		self.port		= NSDictionaryIntegerKeyValueCompare(dic, @"serverPort", self.port);
		self.nick		= NSDictionaryObjectKeyValueCompare(dic, @"identityNickname", self.nick);
		self.username	= NSDictionaryObjectKeyValueCompare(dic, @"identityUsername", self.username);
		self.realName	= NSDictionaryObjectKeyValueCompare(dic, @"identityRealname", self.realName);
		
		[self.altNicks addObjectsFromArray:[dic arrayForKey:@"identityAlternateNicknames"]];
		
		self.proxyType       = (TXConnectionProxyType)[dic integerForKey:@"proxyServerType"];
		self.proxyPort       = NSDictionaryIntegerKeyValueCompare(dic, @"proxyServerPort", self.proxyPort);
		self.proxyHost		 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerAddress", self.proxyHost);
		self.proxyUser		 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerUsername", self.proxyUser);
		self.proxyPassword	 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerPassword", self.proxyPassword);
		
		self.useSSL				 = [dic boolForKey:@"connectUsingSSL"];
		self.autoConnect         = [dic boolForKey:@"connectOnLaunch"];
		self.autoReconnect       = [dic boolForKey:@"connectOnDisconnect"];
		
		self.encoding			 = NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingDefault", self.encoding);
		self.fallbackEncoding	 = NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingFallback", self.fallbackEncoding);
		self.leavingComment		 = NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectDefaultMessage", self.leavingComment);
		self.sleepQuitMessage	 = NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectSleepModeMessage", self.sleepQuitMessage);
		
		self.prefersIPv6         = [dic boolForKey:@"DNSResolverPrefersIPv6"];
		self.invisibleMode       = [dic boolForKey:@"setInvisibleOnConnect"];
		self.isTrustedConnection = [dic boolForKey:@"trustedSSLConnection"];
		
		[self.loginCommands addObjectsFromArray:[dic arrayForKey:@"onConnectCommands"]];
		
		for (NSDictionary *e in [dic arrayForKey:@"channelList"]) {
			IRCChannelConfig *c;
			
			c = [IRCChannelConfig alloc];
			c = [c initWithDictionary:e];
			c = c;
			
			[self.channels safeAddObject:c];
		}
		
		for (NSDictionary *e in [dic arrayForKey:@"ignoreList"]) {
			IRCAddressBook *ignore;
			
			ignore = [IRCAddressBook alloc];
			ignore = [ignore initWithDictionary:e];
			ignore = ignore;
			
			[self.ignores safeAddObject:ignore];
		}
		
		if ([dic containsKey:@"floodControl"]) {
			NSDictionary *e = [dic dictionaryForKey:@"floodControl"];
			
			if (NSObjectIsNotEmpty(e)) {
				self.outgoingFloodControl           = [e boolForKey:@"serviceEnabled"];

				self.floodControlMaximumMessages	= NSDictionaryIntegerKeyValueCompare(e, @"maximumMessageCount", TXFloodControlDefaultMessageCount);
				self.floodControlDelayTimerInterval	= NSDictionaryIntegerKeyValueCompare(e, @"delayTimerInterval", TXFloodControlDefaultDelayTimer);
			}
		} else {
			/* Enable flood control by default for Freenode servers. 
			 They are very strict about flooding. This is required. */
			
			if ([self.host hasSuffix:@"freenode.net"]) {
				self.outgoingFloodControl = YES;
			}
		}
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.port				forKey:@"serverPort"];
	[dic setInteger:self.proxyType			forKey:@"proxyServerType"];
	[dic setInteger:self.proxyPort			forKey:@"proxyServerPort"];
	[dic setInteger:self.encoding			forKey:@"characterEncodingDefault"];
	[dic setInteger:self.fallbackEncoding	forKey:@"characterEncodingFallback"];
	
	[dic setBool:self.useSSL				forKey:@"connectUsingSSL"];
    [dic setBool:self.prefersIPv6			forKey:@"DNSResolverPrefersIPv6"];
	[dic setBool:self.autoConnect			forKey:@"connectOnLaunch"];
	[dic setBool:self.autoReconnect			forKey:@"connectOnDisconnect"];
	[dic setBool:self.invisibleMode			forKey:@"setInvisibleOnConnect"];
	[dic setBool:self.isTrustedConnection	forKey:@"trustedSSLConnection"];
	
	[dic setInteger:self.cuid				forKey:@"connectionID"];
	
	[dic safeSetObject:self.guid				forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.name				forKey:@"connectionName"];
	[dic safeSetObject:self.host				forKey:@"serverAddress"];
	[dic safeSetObject:self.nick				forKey:@"identityNickname"];
	[dic safeSetObject:self.username			forKey:@"identityUsername"];
	[dic safeSetObject:self.realName			forKey:@"identityRealname"];
	[dic safeSetObject:self.altNicks			forKey:@"identityAlternateNicknames"];
	[dic safeSetObject:self.proxyHost			forKey:@"proxyServerAddress"];
	[dic safeSetObject:self.proxyUser			forKey:@"proxyServerUsername"];
	[dic safeSetObject:self.proxyPassword		forKey:@"proxyServerPassword"];
	[dic safeSetObject:self.leavingComment		forKey:@"connectionDisconnectDefaultMessage"];
	[dic safeSetObject:self.sleepQuitMessage	forKey:@"connectionDisconnectSleepModeMessage"];
	[dic safeSetObject:self.loginCommands		forKey:@"onConnectCommands"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:self.floodControlDelayTimerInterval	forKey:@"delayTimerInterval"];
    [floodControl setInteger:self.floodControlMaximumMessages		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:self.outgoingFloodControl forKey:@"serviceEnabled"];
    
	[dic safeSetObject:floodControl forKey:@"floodControl"];
	
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channels) {
		[channelAry safeAddObject:[e dictionaryValue]];
	}
	
	for (IRCAddressBook *e in self.ignores) {
		[ignoreAry safeAddObject:[e dictionaryValue]];
	}
	
	[dic safeSetObject:channelAry forKey:@"channelList"];
	[dic safeSetObject:ignoreAry forKey:@"ignoreList"];
	
	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return [dic sortedDictionary];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end