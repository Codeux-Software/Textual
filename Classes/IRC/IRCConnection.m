// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCConnection (Private)
- (void)updateTimer;
- (BOOL)tryToSend;
@end

@implementation IRCConnection

@synthesize conn;
@synthesize delegate;
@synthesize encoding;
@synthesize host;
@synthesize loggedIn;
@synthesize maxMsgCount;
@synthesize port;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize sendQueue;
@synthesize sending;
@synthesize socksVersion;
@synthesize timer;
@synthesize useSSL;
@synthesize useSocks;
@synthesize useSystemSocks;

- (id)init
{
	if ((self = [super init])) {
		encoding = NSUTF8StringEncoding;
		
		sendQueue = [NSMutableArray new];
		
		timer = [Timer new];
		timer.delegate = self;
	}

	return self;
}

- (void)dealloc
{
	[conn autorelease];
	[conn close];
	[host release];
	[proxyHost release];
	[proxyPassword release];
	[proxyUser release];
	[sendQueue release];
	
	[timer stop];
	[timer release];
	
	[super dealloc];
}

- (void)open
{
	[self close];
	
	maxMsgCount = 0;
	
	conn = [TCPClient new];
	conn.delegate = self;
	conn.host = host;
	conn.port = port;
	conn.useSSL = useSSL;
	
	if (useSystemSocks) {
		CFDictionaryRef proxyDic = SCDynamicStoreCopyProxies(NULL);
		NSNumber *num = (NSNumber *)CFDictionaryGetValue(proxyDic, kSCPropNetProxiesSOCKSEnable);
		BOOL systemSocksEnabled = BOOLReverseValue([num integerValue] == 0);
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
	
	maxMsgCount = 0;
	
	[timer stop];
	
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
	return (sending == NO && maxMsgCount < [Preferences floodControlMaxMessages]);
}

- (void)clearSendQueue
{
	[sendQueue removeAllObjects];
	
	[self updateTimer];
}

- (void)sendLine:(NSString *)line
{
	[sendQueue addObject:line];
	
	[self tryToSend];
	[self updateTimer];
}

- (NSData *)convertToCommonEncoding:(NSString *)s
{
	NSData *data = [s dataUsingEncoding:encoding];
	
	if (NSObjectIsEmpty(data)) {
		data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	}
	
	return data;
}

- (BOOL)tryToSend
{
	if (sending) return NO;
	if (NSObjectIsEmpty(sendQueue)) return NO;
	if (maxMsgCount > [Preferences floodControlMaxMessages]) return NO;
	
	NSString *s = [[sendQueue safeObjectAtIndex:0] stringByAppendingString:@"\r\n"];
	
	[sendQueue safeRemoveObjectAtIndex:0];
	
	NSData *data = [self convertToCommonEncoding:s];
	
	if (data) {
		sending = YES;
		
		if (loggedIn && [Preferences floodControlIsEnabled]) {
			maxMsgCount++;
		}
		
		[conn write:data];
		
		if ([delegate respondsToSelector:@selector(ircConnectionWillSend:)]) {
			[delegate ircConnectionWillSend:s];
		}
	}
	
	return YES;
}

- (void)updateTimer
{
	if (NSObjectIsEmpty(sendQueue) && maxMsgCount < 1) {
		if (timer.isActive) {
			[timer stop];
		}
	} else {
		if (timer.isActive == NO) {
			if ([Preferences floodControlIsEnabled]) {
				[timer start:[Preferences floodControlDelayTimer]];
			}
		}
	}
}

- (void)timerOnTimer:(id)sender
{
	maxMsgCount = 0;
	
	if (NSObjectIsNotEmpty(sendQueue)) {
		while (NSObjectIsNotEmpty(sendQueue)) {
			if ([self tryToSend] == NO) {
				break;
			}
			
			[self updateTimer];
		}
	} else {
		[self updateTimer];
	}
}

- (void)tcpClientDidConnect:(TCPClient *)sender
{
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidConnect:)]) {
		[delegate ircConnectionDidConnect:self];
	}
}

- (void)tcpClient:(TCPClient *)sender error:(NSString *)error
{
	[timer stop];
	
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
		[delegate ircConnectionDidError:error];
	}
}

- (void)tcpClientDidDisconnect:(TCPClient *)sender
{
	[timer stop];
	
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
		[delegate ircConnectionDidDisconnect:self];
	}
}

- (void)tcpClientDidReceiveData:(TCPClient *)sender
{
	while (1) {
		NSData *data = [conn readLine];
		if (NSObjectIsEmpty(data)) break;
		
		if ([delegate respondsToSelector:@selector(ircConnectionDidReceive:)]) {
			[delegate ircConnectionDidReceive:data];
		}
	}
}

- (void)tcpClientDidSendData:(TCPClient *)sender
{
	sending = NO;
	
	[self tryToSend];
}

@end
