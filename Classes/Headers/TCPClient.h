// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient;

@interface TCPClient : NSObject
{
	id conn;
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
	
	dispatch_queue_t delegateQueue;
	dispatch_queue_t socketQueue;
	
	NSMutableData *buffer;
}

@property (nonatomic, retain) id conn;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) NSInteger socksVersion;
@property (nonatomic, retain) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, retain) NSString *proxyUser;
@property (nonatomic, retain) NSString *proxyPassword;
@property (nonatomic, readonly) NSInteger sendQueueSize;
@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, retain) NSMutableData *buffer;
@property (nonatomic, assign) dispatch_queue_t delegateQueue;
@property (nonatomic, assign) dispatch_queue_t socketQueue;

- (id)initWithExistingConnection:(AsyncSocket *)socket;

- (BOOL)usingNewSocketEngine;

- (void)open;
- (void)close;

- (NSData *)read;
- (NSData *)readLine;

- (void)write:(NSData *)data;

- (BOOL)badSSLCertErrorFound:(NSInteger)code;
@end

@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TCPClient *)sender;
- (void)tcpClientDidDisconnect:(TCPClient *)sender;
- (void)tcpClient:(TCPClient *)sender error:(NSString *)error;
- (void)tcpClientDidReceiveData:(TCPClient *)sender;
- (void)tcpClientDidSendData:(TCPClient *)sender;
@end