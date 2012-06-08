// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCConnection : NSObject
{
	id __unsafe_unretained delegate;
	
	NSString *host;
	
	NSInteger port;
	NSInteger proxyPort;
	NSInteger socksVersion;
	NSInteger maxMsgCount;
	
	NSStringEncoding encoding;
	
	NSString *proxyHost;
	NSString *proxyUser;
	NSString *proxyPassword;
	
	TCPClient *conn;
	
	Timer *timer;
	
	BOOL useSystemSocks;
	BOOL loggedIn;
	BOOL useSocks;
	BOOL sending;
	BOOL useSSL;
	
	NSMutableArray *sendQueue;
}

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) Timer *timer;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) NSInteger socksVersion;
@property (nonatomic, assign) NSInteger maxMsgCount;
@property (nonatomic, strong) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, strong) NSString *proxyUser;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL readyToSend;
@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, strong) TCPClient *conn;
@property (nonatomic, strong) NSMutableArray *sendQueue;
@property (nonatomic, assign) BOOL sending;

- (void)open;
- (void)close;
- (void)clearSendQueue;
- (void)sendLine:(NSString *)line;

- (NSData *)convertToCommonEncoding:(NSString *)s;
@end

@interface NSObject (IRCConnectionDelegate)
- (void)ircConnectionDidConnect:(IRCConnection *)sender;
- (void)ircConnectionDidDisconnect:(IRCConnection *)sender;
- (void)ircConnectionDidError:(NSString *)error;
- (void)ircConnectionDidReceive:(NSData *)data;
- (void)ircConnectionWillSend:(NSString *)line;
@end