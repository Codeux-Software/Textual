// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient;

@interface TCPClient : NSObject
{
	AsyncSocket *conn;
	
	id delegate;
	
	NSString *host;
	NSString *proxyHost;
	NSString *proxyUser;
	NSString *proxyPassword;
	
	NSInteger port;
	NSInteger proxyPort;
	NSInteger sendQueueSize;
	NSInteger socksVersion;
	
	BOOL useSSL;
	BOOL useSocks;
	BOOL useSystemSocks;
	
	BOOL active;
	BOOL connecting;
	BOOL connected;
	
	NSThread *socketThread;
	
	NSMutableData *buffer;
}

@property (retain) NSMutableData *buffer; 
@property (retain) AsyncSocket *conn;
@property (assign) id delegate;
@property (retain) NSString *host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (assign) BOOL useSystemSocks;
@property (assign) BOOL useSocks;
@property (assign) NSInteger socksVersion;
@property (retain) NSString *proxyHost;
@property (assign) NSInteger proxyPort;
@property (retain) NSString *proxyUser;
@property (retain) NSString *proxyPassword;
@property (readonly) NSInteger sendQueueSize;
@property (readonly) BOOL active;
@property (readonly) BOOL connecting;
@property (readonly) BOOL connected;
@property (retain) NSThread *socketThread;

- (void)open;
- (void)close;

- (NSData *)readLine;
- (void)write:(NSData *)data;
@end

@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TCPClient *)sender;
- (void)tcpClientDidDisconnect:(TCPClient *)sender;
- (void)tcpClient:(TCPClient *)sender error:(NSString *)error;
- (void)tcpClientDidReceiveData:(TCPClient *)sender;
- (void)tcpClientDidSendData:(TCPClient *)sender;
@end