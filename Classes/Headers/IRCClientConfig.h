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

@property (assign) NSInteger cuid;
@property (strong) NSString *guid;
@property (strong) NSString *name;
@property (strong) NSString *host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (strong) NSString *nick;
@property (strong) NSString *password;
@property (strong) NSString *username;
@property (strong) NSString *realName;
@property (strong) NSString *nickPassword;
@property (readonly) NSMutableArray *altNicks;
@property (assign) ProxyType proxyType;
@property (strong) NSString *proxyHost;
@property (assign) NSInteger proxyPort;
@property (strong) NSString *proxyUser;
@property (strong) NSString *proxyPassword;
@property (assign) BOOL autoConnect;
@property (assign) BOOL autoReconnect;
@property (assign) BOOL bouncerMode;
@property (assign) BOOL prefersIPv6;
@property (assign) BOOL isTrustedConnection;
@property (assign) NSStringEncoding encoding;
@property (assign) NSStringEncoding fallbackEncoding;
@property (strong) NSString *leavingComment;
@property (strong) NSString *sleepQuitMessage;
@property (assign) BOOL invisibleMode;
@property (readonly) NSMutableArray *loginCommands;
@property (readonly) NSMutableArray *channels;
@property (readonly) NSMutableArray *ignores;
@property (strong) NSString *server;
@property (strong) NSString *network;
@property (assign) BOOL outgoingFloodControl;
@property (assign) NSInteger floodControlMaximumMessages;
@property (assign) NSInteger floodControlDelayTimerInterval;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

- (void)destroyKeychains;
@end
