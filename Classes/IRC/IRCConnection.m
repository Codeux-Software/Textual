// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@interface IRCConnection (Private)
- (void)updateTimer;
- (BOOL)tryToSend;
@end

@implementation IRCConnection


- (id)init
{
	if ((self = [super init])) {
		self.encoding = NSUTF8StringEncoding;
		
		self.sendQueue = [NSMutableArray new];
		
		self.timer = [TLOTimer new];
		self.timer.delegate = self;
	}
	
	return self;
}

- (void)dealloc
{
	[self.conn close];
	[self.timer stop];
}

- (void)open
{
	[self close];
	
	self.maxMsgCount = 0;
	
	self.conn			= [TLOSocketClient new];
	self.conn.delegate	= self;
	self.conn.host		= self.host;
	self.conn.port		= self.port;
	self.conn.useSSL	= self.useSSL;
	
	if (self.useSystemSocks) {
		CFDictionaryRef proxyDic = SCDynamicStoreCopyProxies(NULL);
		NSNumber *num = (__bridge NSNumber *)CFDictionaryGetValue(proxyDic, kSCPropNetProxiesSOCKSEnable);
		CFRelease(proxyDic);
		
		BOOL systemSocksEnabled = BOOLReverseValue([num integerValue] == 0);
		
		self.conn.useSocks			= systemSocksEnabled;
		self.conn.useSystemSocks	= systemSocksEnabled;
	} else {
		self.conn.useSocks		= self.useSocks;
		self.conn.socksVersion	= self.socksVersion;
	}
	
	self.conn.proxyHost		= self.proxyHost;
	self.conn.proxyPort		= self.proxyPort;
	self.conn.proxyUser		= self.proxyUser;
	self.conn.proxyPassword = self.proxyPassword;
	
	[self.conn open];
}

- (void)close
{
	self.loggedIn = NO;
	
	self.maxMsgCount = 0;
	
	[self.timer stop];
	
	[self.sendQueue removeAllObjects];
	
	[self.conn close];
	self.conn = nil;
}

- (BOOL)active
{
	return [self.conn active];
}

- (BOOL)connecting
{
	return [self.conn connecting];
}

- (BOOL)connected
{
	return [self.conn connected];
}

- (BOOL)readyToSend
{
    IRCClient *c = self.delegate;
    
	return (self.sending == NO && self.maxMsgCount < c.config.floodControlMaximumMessages);
}

- (void)clearSendQueue
{
	[self.sendQueue removeAllObjects];
	
	[self updateTimer];
}

- (void)sendLine:(NSString *)line
{
	[self.sendQueue safeAddObject:line];
	
	[self tryToSend];
	[self updateTimer];
}

- (NSData *)convertToCommonEncoding:(NSString *)s
{
	NSData *data = [s dataUsingEncoding:self.encoding];
	
	if (NSObjectIsEmpty(data)) {
		data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	}
	
	return data;
}

- (BOOL)tryToSend
{
    IRCClient *c = self.delegate;
    
	if (self.sending) return NO;
	if (NSObjectIsEmpty(self.sendQueue)) return NO;
	if (self.maxMsgCount > c.config.floodControlMaximumMessages) return NO;
	
	NSString *s = [[self.sendQueue safeObjectAtIndex:0] stringByAppendingString:@"\r\n"];
	
	[self.sendQueue safeRemoveObjectAtIndex:0];
	
	NSData *data = [self convertToCommonEncoding:s];
	
	if (data) {
		self.sending = YES;
		
		if (self.loggedIn && c.config.outgoingFloodControl) {
			self.maxMsgCount++;
		}
		
		[self.conn write:data];
		
		if ([self.delegate respondsToSelector:@selector(ircConnectionWillSend:)]) {
			[self.delegate ircConnectionWillSend:s];
		}
	}
	
	return YES;
}

- (void)updateTimer
{
    IRCClient *c = self.delegate;
    
	if (NSObjectIsEmpty(self.sendQueue) && self.maxMsgCount < 1) {
		if (self.timer.isActive) {
			[self.timer stop];
		}
	} else {
		if (self.timer.isActive == NO) {
			if (c.config.outgoingFloodControl) {
				[self.timer start:c.config.floodControlDelayTimerInterval];
            }
		}
	}
}

- (void)timerOnTimer:(id)sender
{
	self.maxMsgCount = 0;
	
	if (NSObjectIsNotEmpty(self.sendQueue)) {
		while (NSObjectIsNotEmpty(self.sendQueue)) {
			if ([self tryToSend] == NO) {
				break;
			}
			
			[self updateTimer];
		}
	} else {
		[self updateTimer];
	}
}

- (void)tcpClientDidConnect:(TLOSocketClient *)sender
{
	[self.sendQueue removeAllObjects];
	
	if ([self.delegate respondsToSelector:@selector(ircConnectionDidConnect:)]) {
		[self.delegate ircConnectionDidConnect:self];
	}
}

- (void)tcpClient:(TLOSocketClient *)sender error:(NSString *)error
{
	[self.timer stop];
	
	[self.sendQueue removeAllObjects];
	
	if ([self.delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
		[self.delegate ircConnectionDidError:error];
	}
}

- (void)tcpClientDidDisconnect:(TLOSocketClient *)sender
{
	[self.timer stop];
	
	[self.sendQueue removeAllObjects];
	
	if ([self.delegate respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
		[self.delegate ircConnectionDidDisconnect:self];
	}
}

- (void)tcpClientDidReceiveData:(TLOSocketClient *)sender
{
	while (1 == 1) {
		NSData *data = [self.conn readLine];
		
		if (data == nil) break;
		
		if ([self.delegate respondsToSelector:@selector(ircConnectionDidReceive:)]) {
			[self.delegate ircConnectionDidReceive:data];
		}
	}
}

- (void)tcpClientDidSendData:(TLOSocketClient *)sender
{
	self.sending = NO;
	
	[self tryToSend];
}

@end
