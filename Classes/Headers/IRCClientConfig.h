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
	
	BOOL autoConnect;
	BOOL autoReconnect;
	BOOL bouncerMode;
	BOOL invisibleMode;
	BOOL isTrustedConnection;
	
	NSStringEncoding encoding;
	NSStringEncoding fallbackEncoding;
	
	NSString *leavingComment;
	NSString *sleepQuitMessage;
	NSString *userInfo;

	NSMutableArray *loginCommands;
	NSMutableArray *channels;
	NSMutableArray *ignores;
}

@property (assign) NSInteger cuid;
@property (retain) NSString *guid;
@property (retain) NSString *name;
@property (retain) NSString *host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (retain) NSString *nick;
@property (retain) NSString *password;
@property (retain) NSString *username;
@property (retain) NSString *realName;
@property (retain) NSString *nickPassword;
@property (readonly) NSMutableArray *altNicks;
@property (assign) ProxyType proxyType;
@property (retain) NSString *proxyHost;
@property (assign) NSInteger proxyPort;
@property (retain) NSString *proxyUser;
@property (retain) NSString *proxyPassword;
@property (assign) BOOL autoConnect;
@property (assign) BOOL autoReconnect;
@property (assign) BOOL bouncerMode;
@property (assign) BOOL isTrustedConnection;
@property (assign) NSStringEncoding encoding;
@property (assign) NSStringEncoding fallbackEncoding;
@property (retain) NSString *leavingComment;
@property (retain) NSString *sleepQuitMessage;
@property (retain) NSString *userInfo;
@property (assign) BOOL invisibleMode;
@property (readonly) NSMutableArray *loginCommands;
@property (readonly) NSMutableArray *channels;
@property (readonly) NSMutableArray *ignores;
@property (retain) NSString *server;
@property (retain) NSString *network;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

- (void)destroyKeychains;
@end