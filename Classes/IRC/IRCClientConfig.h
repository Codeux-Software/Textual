// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
	
	// connection
	NSString *host;
	NSInteger port;
	NSString *server;
	NSString *network;
	BOOL useSSL;
	
	// user
	NSString *nick;
	NSString *password;
	NSString *username;
	NSString *realName;
	NSString *nickPassword;
	NSMutableArray *altNicks;
	
	// proxy
	ProxyType proxyType;
	NSString *proxyHost;
	NSInteger proxyPort;
	NSString *proxyUser;
	NSString *proxyPassword;
	
	// others
	BOOL autoConnect;
	BOOL autoReconnect;
	BOOL isTrustedConnection;
	NSStringEncoding encoding;
	NSStringEncoding fallbackEncoding;
	NSString *leavingComment;
	NSString *sleepQuitMessage;
	NSString *userInfo;
	BOOL invisibleMode;
	NSMutableArray *loginCommands;
	NSMutableArray *channels;
	NSMutableArray *ignores;
}

@property (nonatomic, assign) NSInteger cuid;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, retain) NSString *nick;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *realName;
@property (nonatomic, retain) NSString *nickPassword;
@property (nonatomic, readonly) NSMutableArray *altNicks;
@property (nonatomic, assign) ProxyType proxyType;
@property (nonatomic, retain) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, retain) NSString *proxyUser;
@property (nonatomic, retain) NSString *proxyPassword;
@property (nonatomic, assign) BOOL autoConnect;
@property (nonatomic, assign) BOOL autoReconnect;
@property (nonatomic, assign) BOOL isTrustedConnection;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) NSStringEncoding fallbackEncoding;
@property (nonatomic, retain) NSString *leavingComment;
@property (nonatomic, retain) NSString *sleepQuitMessage;
@property (nonatomic, retain) NSString *userInfo;
@property (nonatomic, assign) BOOL invisibleMode;
@property (nonatomic, readonly) NSMutableArray *loginCommands;
@property (nonatomic, readonly) NSMutableArray *channels;
@property (nonatomic, readonly) NSMutableArray *ignores;
@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *network;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

- (void)destroyKeychains;
@end