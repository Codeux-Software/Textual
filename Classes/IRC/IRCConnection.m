#import "IRCConnection.h"
#include <SystemConfiguration/SystemConfiguration.h>
#import "IRC.h"
#import "NSData+Kana.h"

@interface IRCConnection (Private)
- (void)tryToSend;
@end

@implementation IRCConnection

@synthesize delegate;
@synthesize host;
@synthesize port;
@synthesize useSSL;
@synthesize encoding;
@synthesize useSystemSocks;
@synthesize useSocks;
@synthesize socksVersion;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;
@synthesize loggedIn;

- (id)init
{
	if (self = [super init]) {
		encoding = NSUTF8StringEncoding;
		sendQueue = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[host release];
	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[conn close];
	[conn autorelease];
	
	[sendQueue release];
	
	[super dealloc];
}

- (void)open
{
	[self close];
	
	conn = [TCPClient new];
	conn.delegate = self;
	conn.host = host;
	conn.port = port;
	conn.useSSL = useSSL;
	
	if (useSystemSocks) {
		CFDictionaryRef proxyDic = SCDynamicStoreCopyProxies(NULL);
		NSNumber* num = (NSNumber*)CFDictionaryGetValue(proxyDic, kSCPropNetProxiesSOCKSEnable);
		BOOL systemSocksEnabled = [num integerValue] != 0;
		CFRelease(proxyDic);
		
		conn.useSocks = systemSocksEnabled;
		conn.useSystemSocks = systemSocksEnabled;
	} else {
		conn.useSocks = useSocks;
		conn.socksVersion = socksVersion;
	}
	
	conn.proxyHost = proxyHost;
	conn.proxyPort = proxyPort;
	conn.proxyUser = proxyUser;
	
	[conn open];
}

- (void)close
{
	loggedIn = NO;
	[sendQueue removeAllObjects];
	[conn close];
	[conn autorelease];
	conn = nil;
}

- (BOOL)active
{
	return [conn active];
}

- (BOOL)connecting
{
	return [conn connecting];
}

- (BOOL)connected
{
	return [conn connected];
}

- (BOOL)readyToSend
{
	return !sending;
}

- (void)clearSendQueue
{
	[sendQueue removeAllObjects];
}

- (void)sendLine:(NSString*)line
{
	[sendQueue addObject:line];
	[self tryToSend];
}

- (NSData*)convertToCommonEncoding:(NSString*)s
{
	NSData* data = [s dataUsingEncoding:encoding];
	if (!data) {
		data = [s dataUsingEncoding:encoding allowLossyConversion:YES];
		if (!data) {
			data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		}
	}
	
	if (encoding == NSISO2022JPStringEncoding) {
		if (data) {
			data = [data convertKanaFromISO2022ToNative];
		}
	}
	
	return data;
}

- (void)tryToSend
{
	if ([sendQueue count] == 0) return;
	if (sending) return;
	
	NSString* s = [sendQueue safeObjectAtIndex:0];
	s = [s stringByAppendingString:@"\r\n"];
	[sendQueue removeObjectAtIndex:0];
	
	NSData* data = [self convertToCommonEncoding:s];
	
	if (data) {
		sending = YES;
		
		[conn write:data];
		
		if ([delegate respondsToSelector:@selector(ircConnectionWillSend:)]) {
			[delegate ircConnectionWillSend:s];
		}
	}
}

- (void)tcpClientDidConnect:(TCPClient*)sender
{
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidConnect:)]) {
		[delegate ircConnectionDidConnect:self];
	}
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)error
{
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
		[delegate ircConnectionDidError:error];
	}
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
		[delegate ircConnectionDidDisconnect:self];
	}
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
	while (1) {
		NSData* data = [conn readLine];
		if (!data) break;
		
		if ([delegate respondsToSelector:@selector(ircConnectionDidReceive:)]) {
			[delegate ircConnectionDidReceive:data];
		}
	}
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
	sending = NO;
	[self tryToSend];
}

@synthesize conn;
@synthesize sendQueue;
@synthesize sending;
@end