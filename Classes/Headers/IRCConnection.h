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

@property (unsafe_unretained) id delegate;
@property (strong) Timer *timer;
@property (strong) NSString *host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (assign) NSStringEncoding encoding;
@property (assign) BOOL useSystemSocks;
@property (assign) BOOL useSocks;
@property (assign) NSInteger socksVersion;
@property (assign) NSInteger maxMsgCount;
@property (strong) NSString *proxyHost;
@property (assign) NSInteger proxyPort;
@property (strong) NSString *proxyUser;
@property (strong) NSString *proxyPassword;
@property (readonly) BOOL active;
@property (readonly) BOOL connecting;
@property (readonly) BOOL connected;
@property (readonly) BOOL readyToSend;
@property (assign) BOOL loggedIn;
@property (strong) TCPClient *conn;
@property (strong) NSMutableArray *sendQueue;
@property (assign) BOOL sending;

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