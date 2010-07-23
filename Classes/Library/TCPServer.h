#import <Foundation/Foundation.h>
#import "TCPClient.h"

@interface TCPServer : NSObject
{
	id delegate;
	
	AsyncSocket* conn;
	NSMutableArray* clients;
	BOOL isActive;
	NSInteger port;
}

@property (assign) id delegate;
@property (readonly) NSArray* clients;
@property (readonly) BOOL isActive;
@property (assign) NSInteger port;
@property (retain) AsyncSocket* conn;

- (BOOL)open;
- (void)close;

- (void)closeClient:(TCPClient*)client;
- (void)closeAllClients;
@end

@interface NSObject (TCPServerDelegate)
- (void)tcpServer:(TCPServer*)sender didAccept:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didConnect:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender client:(TCPClient*)client error:(NSString*)error;
- (void)tcpServer:(TCPServer*)sender didDisconnect:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didReceiveData:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didSendData:(TCPClient*)client;
@end
