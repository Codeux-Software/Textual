// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TCPServer.h"
#import "AsyncSocket.h"

@interface TCPServer (Private)
@end

@implementation TCPServer

@synthesize delegate;
@synthesize isActive;
@synthesize port;
@synthesize clients;

- (id)init
{
	if ((self = [super init])) {
		clients = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[conn disconnect];
	[clients release];
	[super dealloc];
}

- (BOOL)open
{
	if (conn) {
		[self close];
	}
	
	conn = [[AsyncSocket alloc] initWithDelegate:self];
	isActive = [conn acceptOnPort:port error:NULL];
	if (!isActive) {
		[self close];
	}
	return isActive;
}

- (void)close
{
	[conn disconnect];
	[conn autorelease];
	conn = nil;
	isActive = NO;
}

- (void)closeClient:(TCPClient*)client
{
	[client close];
	[clients removeObjectIdenticalTo:client];
}

- (void)closeAllClients
{
	for (TCPClient* c in clients) {
		[[c retain] autorelease];
		[c close];
	}
	[clients removeAllObjects];
}

- (void)onSocket:(AsyncSocket*)sock didAcceptNewSocket:(AsyncSocket*)newSocket
{
	TCPClient* c = [[[TCPClient alloc] initWithExistingConnection:newSocket] autorelease];
	c.delegate = self;
	[clients addObject:c];
	
	if ([delegate respondsToSelector:@selector(tcpServer:didAccept:)]) {
		[delegate tcpServer:self didAccept:c];
	}
}

- (void)tcpClientDidConnect:(TCPClient*)sender
{
	if ([delegate respondsToSelector:@selector(tcpServer:didConnect:)]) {
		[delegate tcpServer:self didConnect:sender];
	}
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	if ([delegate respondsToSelector:@selector(tcpServer:didDisconnect:)]) {
		[delegate tcpServer:self didDisconnect:sender];
	}
	[self closeClient:sender];
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)error
{
	if ([delegate respondsToSelector:@selector(tcpServer:client:error:)]) {
		[delegate tcpServer:self client:sender error:error];
	}
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
	if ([delegate respondsToSelector:@selector(tcpServer:didReceiveData:)]) {
		[delegate tcpServer:self didReceiveData:sender];
	}
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
	if ([delegate respondsToSelector:@selector(tcpServer:didSendData:)]) {
		[delegate tcpServer:self didSendData:sender];
	}
}

@synthesize conn;
@end
