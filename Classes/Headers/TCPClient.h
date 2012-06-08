// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient;

@interface TCPClient : NSObject
{
	id conn;
	id __unsafe_unretained delegate;
	
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
	
	NSMutableData *buffer;
	
	dispatch_queue_t dispatchQueue;
    dispatch_queue_t socketQueue;
}

@property (strong) NSMutableData *buffer; 
@property (strong) AsyncSocket *conn;
@property (unsafe_unretained) id delegate;
@property (strong) NSString *host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (assign) BOOL useSystemSocks;
@property (assign) BOOL useSocks;
@property (assign) NSInteger socksVersion;
@property (strong) NSString *proxyHost;
@property (assign) NSInteger proxyPort;
@property (strong) NSString *proxyUser;
@property (strong) NSString *proxyPassword;
@property (readonly) NSInteger sendQueueSize;
@property (readonly) BOOL active;
@property (readonly) BOOL connecting;
@property (readonly) BOOL connected;
@property (assign) dispatch_queue_t dispatchQueue;
@property (assign) dispatch_queue_t socketQueue;

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
