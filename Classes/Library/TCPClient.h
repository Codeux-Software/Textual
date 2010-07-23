#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"

@interface TCPClient : NSObject
{
	id delegate;
	
	NSString* host;
	NSInteger port;
	BOOL useSSL;
	
	BOOL useSystemSocks;
	BOOL useSocks;
	NSInteger socksVersion;
	NSString* proxyHost;
	NSInteger proxyPort;
	NSString* proxyUser;
	NSString* proxyPassword;
	
	NSInteger sendQueueSize;
	
	AsyncSocket* conn;
	NSMutableData* buffer;
	NSInteger tag;
	BOOL active;
	BOOL connecting;
}

@property (assign) id delegate;
@property (retain) NSString* host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;

@property (assign) BOOL useSystemSocks;
@property (assign) BOOL useSocks;
@property (assign) NSInteger socksVersion;
@property (retain) NSString* proxyHost;
@property (assign) NSInteger proxyPort;
@property (retain) NSString* proxyUser;
@property (retain) NSString* proxyPassword;
@property (readonly) NSInteger sendQueueSize;

@property (readonly) BOOL active;
@property (readonly) BOOL connecting;
@property (readonly) BOOL connected;
@property (retain) AsyncSocket* conn;
@property (retain) NSMutableData* buffer;
@property NSInteger tag;

- (id)initWithExistingConnection:(AsyncSocket*)socket;

- (void)open;
- (void)close;

- (NSData*)read;
- (NSData*)readLine;
- (void)write:(NSData*)data;
@end

@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TCPClient*)sender;
- (void)tcpClientDidDisconnect:(TCPClient*)sender;
- (void)tcpClient:(TCPClient*)sender error:(NSString*)error;
- (void)tcpClientDidReceiveData:(TCPClient*)sender;
- (void)tcpClientDidSendData:(TCPClient*)sender;
@end
