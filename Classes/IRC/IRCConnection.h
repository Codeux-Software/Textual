#import <Cocoa/Cocoa.h>
#import "TCPClient.h"
#import "Timer.h"

@interface IRCConnection : NSObject
{
	id delegate;
	
	NSString* host;
	NSInteger port;
	NSStringEncoding encoding;
	
	NSString* proxyHost;
	NSInteger proxyPort;
	NSString* proxyUser;
	NSInteger socksVersion;
	NSString* proxyPassword;
	
	TCPClient* conn;
	
	Timer* timer;
	NSInteger maxMsgCount;
	NSMutableArray* sendQueue;
	
	BOOL useSystemSocks;
	BOOL loggedIn;
	BOOL useSocks;
	BOOL sending;
	BOOL useSSL;
}

@property (assign) id delegate;
@property (assign) Timer* timer;
@property (retain) NSString* host;
@property (assign) NSInteger port;
@property (assign) BOOL useSSL;
@property (assign) NSStringEncoding encoding;
@property (assign) BOOL useSystemSocks;
@property (assign) BOOL useSocks;
@property (assign) NSInteger socksVersion;
@property (assign) NSInteger maxMsgCount;
@property (retain) NSString* proxyHost;
@property (assign) NSInteger proxyPort;
@property (retain) NSString* proxyUser;
@property (retain) NSString* proxyPassword;
@property (readonly) BOOL active;
@property (readonly) BOOL connecting;
@property (readonly) BOOL connected;
@property (readonly) BOOL readyToSend;
@property (assign) BOOL loggedIn;
@property (retain) TCPClient* conn;
@property (retain) NSMutableArray* sendQueue;
@property BOOL sending;

- (void)open;
- (void)close;
- (void)clearSendQueue;
- (void)sendLine:(NSString*)line;

- (NSData*)convertToCommonEncoding:(NSString*)s;
@end

@interface NSObject (IRCConnectionDelegate)
- (void)ircConnectionDidConnect:(IRCConnection*)sender;
- (void)ircConnectionDidDisconnect:(IRCConnection*)sender;
- (void)ircConnectionDidError:(NSString*)error;
- (void)ircConnectionDidReceive:(NSData*)data;
- (void)ircConnectionWillSend:(NSString*)line;
@end