// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TCPServer : NSObject
{
	id delegate;
	
	BOOL isActive;
	
	NSInteger port;
	AsyncSocket *conn;
	NSMutableArray *clients;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSArray *clients;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, retain) AsyncSocket *conn;

- (BOOL)open;
- (void)close;

- (void)closeClient:(TCPClient *)client;
- (void)closeAllClients;
@end

@interface NSObject (TCPServerDelegate)
- (void)tcpServer:(TCPServer *)sender didAccept:(TCPClient *)client;
- (void)tcpServer:(TCPServer *)sender didConnect:(TCPClient *)client;
- (void)tcpServer:(TCPServer *)sender client:(TCPClient *)client error:(NSString *)error;
- (void)tcpServer:(TCPServer *)sender didDisconnect:(TCPClient *)client;
- (void)tcpServer:(TCPServer *)sender didReceiveData:(TCPClient *)client;
- (void)tcpServer:(TCPServer *)sender didSendData:(TCPClient *)client;
@end
