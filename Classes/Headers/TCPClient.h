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

@property (nonatomic, strong) NSMutableData *buffer; 
@property (nonatomic, strong) AsyncSocket *conn;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) NSInteger socksVersion;
@property (nonatomic, strong) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, strong) NSString *proxyUser;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, readonly) NSInteger sendQueueSize;
@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_queue_t socketQueue;

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
