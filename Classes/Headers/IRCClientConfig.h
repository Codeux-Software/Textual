// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
{
	NSInteger cuid;
	NSString *guid;
	NSString *name;
	
	NSString *host;
	NSInteger port;
	NSString *server;
	NSString *network;
    
	BOOL useSSL;
	
	NSString *nick;
	NSString *password;
	NSString *username;
	NSString *realName;
	NSString *nickPassword;
	NSMutableArray *altNicks;
	
	ProxyType proxyType;
	NSString *proxyHost;
	NSInteger proxyPort;
	NSString *proxyUser;
	NSString *proxyPassword;
    
    BOOL outgoingFloodControl;
    NSInteger floodControlMaximumMessages;
	NSInteger floodControlDelayTimerInterval;
    
	BOOL autoConnect;
	BOOL autoReconnect;
    BOOL prefersIPv6;
	BOOL bouncerMode;
	BOOL invisibleMode;
	BOOL isTrustedConnection;
	
	NSStringEncoding encoding;
	NSStringEncoding fallbackEncoding;
	
	NSString *leavingComment;
	NSString *sleepQuitMessage;

	NSMutableArray *loginCommands;
	NSMutableArray *channels;
	NSMutableArray *ignores;
}

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
@property (nonatomic, readonly) NSMutableArray *altNicks;
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
@property (nonatomic, readonly) NSMutableArray *loginCommands;
@property (nonatomic, readonly) NSMutableArray *channels;
@property (nonatomic, readonly) NSMutableArray *ignores;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *network;
@property (nonatomic, assign) BOOL outgoingFloodControl;
@property (nonatomic, assign) NSInteger floodControlMaximumMessages;
@property (nonatomic, assign) NSInteger floodControlDelayTimerInterval;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

- (void)destroyKeychains;
@end
