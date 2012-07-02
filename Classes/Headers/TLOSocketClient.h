// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TLOSocketClient : NSObject
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSMutableData *buffer; 
@property (nonatomic, strong) id conn;
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
@property (nonatomic, assign) NSInteger sendQueueSize;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_queue_t socketQueue;

- (void)open;
- (void)close;

- (NSData *)readLine;
- (void)write:(NSData *)data;
@end

@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TLOSocketClient *)sender;
- (void)tcpClientDidDisconnect:(TLOSocketClient *)sender;
- (void)tcpClient:(TLOSocketClient *)sender error:(NSString *)error;
- (void)tcpClientDidReceiveData:(TLOSocketClient *)sender;
- (void)tcpClientDidSendData:(TLOSocketClient *)sender;
@end
