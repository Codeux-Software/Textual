// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "IRCChannel.h"

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
	NSString* name;
	
	// connection
	NSString* host;
	NSInteger port;
	NSString* server;
	NSString* network;
	BOOL useSSL;
	
	// user
	NSString* nick;
	NSString* password;
	NSString* username;
	NSString* realName;
	NSString* nickPassword;
	NSMutableArray* altNicks;
	
	// proxy
	ProxyType proxyType;
	NSString* proxyHost;
	NSInteger proxyPort;
	NSString* proxyUser;
	NSString* proxyPassword;
	
	// others
	BOOL autoConnect;
	BOOL autoReconnect;
	NSStringEncoding encoding;
	NSStringEncoding fallbackEncoding;
	NSString* leavingComment;
	NSString* userInfo;
	BOOL invisibleMode;
	NSMutableArray* loginCommands;
	NSMutableArray* channels;
	NSMutableArray* ignores;
}

@property (assign) NSInteger cuid;
@property (retain) NSString* name;
@property (retain) NSString* host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (retain) NSString* nick;
@property (retain) NSString* password;
@property (retain) NSString* username;
@property (retain) NSString* realName;
@property (retain) NSString* nickPassword;
@property (readonly) NSMutableArray* altNicks;
@property (assign) ProxyType proxyType;
@property (retain) NSString* proxyHost;
@property (assign) NSInteger proxyPort;
@property (retain) NSString* proxyUser;
@property (retain) NSString* proxyPassword;
@property (assign) BOOL autoConnect;
@property (assign) BOOL autoReconnect;
@property (assign) NSStringEncoding encoding;
@property (assign) NSStringEncoding fallbackEncoding;
@property (retain) NSString* leavingComment;
@property (retain) NSString* userInfo;
@property (assign) BOOL invisibleMode;
@property (readonly) NSMutableArray* loginCommands;
@property (readonly) NSMutableArray* channels;
@property (readonly) NSMutableArray* ignores;
@property (retain) NSString* server;
@property (retain) NSString* network;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

- (void)destroyKeychains;
- (NSString*)keychainServiceID;
- (NSString*)keychainServiceName:(NSInteger)type;
@end