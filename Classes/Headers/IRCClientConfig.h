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

#define IRCConnectionDefaultServerPort		6667

#define TXFloodControlDefaultDelayTimer       2
#define TXFloodControlDefaultMessageCount     6

#define TXDefaultPrimaryTextEncoding		NSUTF8StringEncoding
#define TXDefaultFallbackTextEncoding		NSISOLatin1StringEncoding

typedef enum TXConnectionProxyType : NSInteger {
	TXConnectionNoProxyType = 0,
	TXConnectionSystemSocksProxyType = 1,
	TXConnectionSocks4ProxyType = 4,
	TXConnectionSocks5ProxyType = 5,
} TXConnectionProxyType;

@interface IRCClientConfig : NSObject <NSMutableCopying>
@property (nonatomic, assign) BOOL autoConnect;
@property (nonatomic, assign) BOOL autoReconnect;
@property (nonatomic, assign) BOOL autoSleepModeDisconnect;
@property (nonatomic, assign) BOOL connectionPrefersIPv6;
@property (nonatomic, assign) BOOL performPongTimer;
@property (nonatomic, assign) BOOL performDisconnectOnPongTimer;
@property (nonatomic, assign) BOOL performDisconnectOnReachabilityChange;
@property (nonatomic, assign) BOOL connectionUsesSSL;
@property (nonatomic, assign) BOOL invisibleMode;
@property (nonatomic, assign) BOOL outgoingFloodControl;
@property (nonatomic, assign) BOOL sidebarItemExpanded;
@property (nonatomic, assign) BOOL validateServerSSLCertificate;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, assign) BOOL excludedFromCloudSyncing;
#endif

@property (nonatomic, assign) BOOL zncIgnoreConfiguredAutojoin;
@property (nonatomic, assign) BOOL zncIgnorePlaybackNotifications;		/* ZNC Related option. */
@property (nonatomic, assign) NSInteger floodControlDelayTimerInterval;
@property (nonatomic, assign) NSInteger floodControlMaximumMessages;
@property (nonatomic, assign) NSInteger fallbackEncoding;
@property (nonatomic, assign) NSInteger primaryEncoding;
@property (nonatomic, assign) TXConnectionProxyType proxyType;
@property (nonatomic, strong) NSMutableArray *alternateNicknames;
@property (nonatomic, strong) NSMutableArray *channelList;
@property (nonatomic, strong) NSMutableArray *ignoreList;
@property (nonatomic, strong) NSMutableArray *highlightList;
@property (nonatomic, strong) NSMutableArray *loginCommands;
@property (nonatomic, strong) NSString *itemUUID; // Unique Identifier (UUID)
@property (nonatomic, strong) NSString *clientName;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *awayNickname;
@property (nonatomic, strong) NSString *nicknamePassword;
@property (nonatomic, strong) NSString *proxyAddress;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, strong) NSString *proxyUsername;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, strong) NSString *serverPassword;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *normalLeavingComment;
@property (nonatomic, strong) NSString *sleepModeLeavingComment;
@property (nonatomic, strong) NSData *identitySSLCertificate;

@property (nonatomic, assign) BOOL serverPasswordIsSet;
@property (nonatomic, assign) BOOL nicknamePasswordIsSet;
@property (nonatomic, assign) BOOL proxyPasswordIsSet;

/* This dictionary contains configuration options that are not
 accessible by the user interface. Instead, they are set bu the
 /defaults command so that server specific features can be used 
 by some users without the need to bloat the user interface with
 a checkbox only a few users may use. */
@property (nonatomic, strong) NSMutableDictionary *auxiliaryConfiguration;

- (BOOL)isEqualToClientConfiguration:(IRCClientConfig *)seed;

- (id)initWithDictionary:(NSDictionary *)dic;

- (NSMutableDictionary *)dictionaryValue;
- (NSMutableDictionary *)dictionaryValue:(BOOL)isCloudDictionary;

/* Keychain. */
- (void)destroyKeychains;

- (NSString *)temporaryNicknamePassword;
- (NSString *)temporaryServerPassword;
- (NSString *)temporaryProxyPassword;

- (void)writeKeychainItemsToDisk;

- (void)writeProxyPasswordKeychainItemToDisk;
- (void)writeServerPasswordKeychainItemToDisk;
- (void)writeNicknamePasswordKeychainItemToDisk;
@end
