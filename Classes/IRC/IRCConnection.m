// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCConnection.h"

#import "IRC.h"
#import "Timer.h"
#import "NSData+Kana.h"
#import "Preferences.h"

#include <SystemConfiguration/SystemConfiguration.h>

@interface IRCConnection (Private)
- (void)updateTimer;
- (BOOL)tryToSend;
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
@synthesize conn;
@synthesize timer;
@synthesize maxMsgCount;
@synthesize sendQueue;
@synthesize sending;

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
	[host release];
	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[conn close];
	[conn autorelease];
	
	[sendQueue release];
	
	[timer stop];
	[timer release];
	
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
	return (!sending && maxMsgCount < [Preferences floodControlMaxMessages]);
}

- (void)clearSendQueue
{
	[sendQueue removeAllObjects];
	[self updateTimer];
}

- (void)sendLine:(NSString*)line
{
	[sendQueue addObject:line];
	[self tryToSend];
	[self updateTimer];
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

- (BOOL)tryToSend
{
	if ([sendQueue count] == 0) return NO;
	if (sending) return NO;
	if (maxMsgCount > [Preferences floodControlMaxMessages]) return NO;
	
	NSString* s = [sendQueue safeObjectAtIndex:0];
	s = [s stringByAppendingString:@"\r\n"];
	[sendQueue safeRemoveObjectAtIndex:0];
	
	NSData* data = [self convertToCommonEncoding:s];
	
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
	if (sendQueue.count < 1 && maxMsgCount < 1) {
		if (timer.isActive) {
			[timer stop];
		}
	} else {
		if (!timer.isActive) {
			if ([Preferences floodControlIsEnabled]) {
				[timer start:[Preferences floodControlDelayTimer]];
			}
		}
	}
}

- (void)timerOnTimer:(id)sender
{
	maxMsgCount = 0;
	
	if (sendQueue.count > 0) {
		while (sendQueue.count > 0) {
			if ([self tryToSend] == NO) {
				break;
			}
			
			[self updateTimer];
		}
	} else {
		[self updateTimer];
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
	[timer stop];
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
		[delegate ircConnectionDidError:error];
	}
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	[timer stop];
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

@end
