// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

#define FLOOD_CONTROL_DEFAULT_DELAY_TIMER       2
#define FLOOD_CONTROL_DEFAULT_MESSAGE_COUNT     2

typedef enum {
	PROXY_NONE = 0,
	PROXY_SOCKS_SYSTEM = 1,
	PROXY_SOCKS4 = 4,
	PROXY_SOCKS5 = 5,
} ProxyType;

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context);

@interface IRCClientConfig : NSObject <NSMutableCopying>
@property (nonatomic, assign) NSInteger cuid;
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic, strong) NSString *nickPassword;
@property (nonatomic, strong) NSMutableArray *altNicks;
@property (nonatomic, assign) ProxyType proxyType;
@property (nonatomic, strong) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, strong) NSString *proxyUser;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, assign) BOOL autoConnect;
@property (nonatomic, assign) BOOL autoReconnect;
@property (nonatomic, assign) BOOL bouncerMode;
@property (nonatomic, assign) BOOL prefersIPv6;
@property (nonatomic, assign) BOOL isTrustedConnection;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) NSStringEncoding fallbackEncoding;
@property (nonatomic, strong) NSString *leavingComment;
@property (nonatomic, strong) NSString *sleepQuitMessage;
@property (nonatomic, assign) BOOL invisibleMode;
@property (nonatomic, strong) NSMutableArray *loginCommands;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *ignores;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *network;
@property (nonatomic, assign) BOOL outgoingFloodControl;
@property (nonatomic, assign) NSInteger floodControlMaximumMessages;
@property (nonatomic, assign) NSInteger floodControlDelayTimerInterval;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

- (void)destroyKeychains;
@end