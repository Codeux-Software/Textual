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

#define IRCConnectionDefaultServerPort		6667

#define IRCClientConfigFloodControlDefaultDelayTimer					2
#define IRCClientConfigFloodControlDefaultMessageCount					6
#define IRCClientConfigFloodControlDefaultMessageCountForFreenode		2 // freenode gets a special case 'cause they are strict about flood control

typedef enum TXConnectionProxyType : NSInteger {
	IRCConnectionSocketNoProxyType = 0,
	IRCConnectionSocketSystemSocksProxyType = 1,
	IRCConnectionSocketSocks4ProxyType = 4,
	IRCConnectionSocketSocks5ProxyType = 5,
	IRCConnectionSocketHTTPProxyType = 6,
	IRCConnectionSocketHTTPSProxyType = 7
} IRCConnectionSocketProxyType;

@interface IRCClientConfig : NSObject <NSCopying>
@property (nonatomic, assign) BOOL autoConnect;
@property (nonatomic, assign) BOOL autoReconnect;
@property (nonatomic, assign) BOOL autojoinWaitsForNickServ;
@property (nonatomic, assign) BOOL autoSleepModeDisconnect;
@property (nonatomic, assign) BOOL connectionPrefersIPv6;
@property (nonatomic, assign) BOOL performPongTimer;
@property (nonatomic, assign) BOOL performDisconnectOnPongTimer;
@property (nonatomic, assign) BOOL performDisconnectOnReachabilityChange;
@property (nonatomic, assign) BOOL connectionUsesSSL;
@property (nonatomic, assign) BOOL hideNetworkUnavailabilityNotices;
@property (nonatomic, assign) BOOL invisibleMode;
@property (nonatomic, assign) BOOL outgoingFloodControl;
@property (nonatomic, assign) BOOL saslAuthenticationUsesExternalMechanism;
@property (nonatomic, assign) BOOL sendAuthenticationRequestsToUserServ;
@property (nonatomic, assign) BOOL sendWhoCommandRequestsToChannels;
@property (nonatomic, assign) BOOL sidebarItemExpanded;
@property (nonatomic, assign) BOOL validateServerSSLCertificate;
@property (nonatomic, assign) BOOL zncIgnoreConfiguredAutojoin;
@property (nonatomic, assign) BOOL zncIgnorePlaybackNotifications;		/* ZNC Related option. */

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, assign) BOOL excludedFromCloudSyncing;
#endif

@property (nonatomic, assign) NSInteger floodControlDelayTimerInterval;
@property (nonatomic, assign) NSInteger floodControlMaximumMessages;
@property (nonatomic, assign) NSInteger fallbackEncoding;
@property (nonatomic, assign) NSInteger primaryEncoding;
@property (nonatomic, assign) IRCConnectionSocketProxyType proxyType;
@property (nonatomic, copy) NSArray *alternateNicknames;
@property (nonatomic, copy) NSArray *channelList;
@property (nonatomic, copy) NSArray *ignoreList;
@property (nonatomic, copy) NSArray *highlightList;
@property (nonatomic, copy) NSArray *loginCommands;
@property (nonatomic, copy) NSString *itemUUID; // Unique Identifier (UUID)
@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *awayNickname;
@property (nonatomic, copy) NSString *nicknamePassword;
@property (nonatomic, copy) NSString *proxyAddress;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, copy) NSString *proxyPassword;
@property (nonatomic, copy) NSString *proxyUsername;
@property (nonatomic, copy) NSString *realname;
@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, copy) NSString *serverPassword;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *normalLeavingComment;
@property (nonatomic, copy) NSString *sleepModeLeavingComment;
@property (nonatomic, copy) NSData *identitySSLCertificate;
@property (nonatomic, assign) NSTimeInterval cachedLastServerTimeCapacityReceivedAtTimestamp;

- (BOOL)isEqualToClientConfiguration:(IRCClientConfig *)seed;

- (instancetype)initWithDictionary:(NSDictionary *)dic;

- (id)copyWithoutPrivateMessages;

- (NSMutableDictionary *)dictionaryValue;
- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary;

- (void)destroyKeychains;

@property (readonly, copy) NSString *temporaryNicknamePassword;
@property (readonly, copy) NSString *temporaryServerPassword;
@property (readonly, copy) NSString *temporaryProxyPassword;

- (void)writeKeychainItemsToDisk;

- (void)writeProxyPasswordKeychainItemToDisk;
- (void)writeServerPasswordKeychainItemToDisk;
- (void)writeNicknamePasswordKeychainItemToDisk;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)migrateKeychainItemsToCloud;
- (void)migrateKeychainItemsFromCloud;

- (void)destroyKeychainsThatExistOnCloud;
#endif
@end
