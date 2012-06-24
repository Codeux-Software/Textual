// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define _LF	0xa
#define _CR	0xd

@implementation TLOSocketClient

- (id)init
{
	if ((self = [super init])) {
		self.buffer = [NSMutableData new];
	}
	
	return self;
}

- (BOOL)useNewSocketEngine
{
	return (self.useSystemSocks == NO && self.useSocks == NO &&
			[_NSUserDefaults() boolForKey:@"DisableNewSocketEngine"] == NO);
}

- (void)destroyDispatchQueue
{
    if ([self useNewSocketEngine]) {
        if (self.dispatchQueue) {
            dispatch_release(self.dispatchQueue);
            self.dispatchQueue = NULL;
        }
        
        if (self.socketQueue) {
            dispatch_release(self.socketQueue);
            self.socketQueue = NULL;
        }
    }
}

- (void)createDispatchQueue
{
	if ([self useNewSocketEngine]) {
		NSString *dqname = [NSString stringWithUUID];
        NSString *sqname = [NSString stringWithUUID];
        
		self.socketQueue = dispatch_queue_create([sqname UTF8String], NULL);
		self.dispatchQueue = dispatch_queue_create([dqname UTF8String], NULL);
	}
}

- (void)dealloc
{
	if (self.conn) {
		[self.conn setDelegate:nil];
		[self.conn disconnect];
	}
	
    [self destroyDispatchQueue];
	
	self.delegate = nil;
}

- (void)open
{
	[self createDispatchQueue];
    [self close];
	
	[self.buffer setLength:0];
	
	NSError *connError = nil;
	
	if ([self useNewSocketEngine]) {
        self.conn = [GCDAsyncSocket socketWithDelegate:self
										 delegateQueue:self.dispatchQueue
										   socketQueue:self.socketQueue];
        
        IRCClient *clin = [self.delegate delegate];
        
        [self.conn setPreferIPv4OverIPv6:BOOLReverseValue(clin.config.prefersIPv6)];
	} else {
		self.conn = [AsyncSocket socketWithDelegate:self];
	}
	
	if ([self.conn connectToHost:self.host onPort:self.port withTimeout:(-1) error:&connError] == NO) {
		NSLog(@"Silently ignoring connection error: %@", [connError localizedDescription]);
	}
	
	self.active     = YES;
	self.connecting = YES;
	self.connected  = NO;
	
	self.sendQueueSize = 0;
}

- (void)close
{
	if (PointerIsEmpty(self.conn)) return;
	
	[self.conn setDelegate:nil];
    [self.conn disconnect];
    
    [self destroyDispatchQueue];
	
	self.active	   = NO;
	self.connecting = NO;
	self.connected  = NO;
	
	self.sendQueueSize = 0;
}

- (NSData *)readLine
{
	NSInteger len = [self.buffer length];
	if (len < 1) return nil;
	
	const char *bytes = [self.buffer bytes];
	char *p = memchr(bytes, _LF, len);
	
	if (p == NULL) return nil;
	
	NSInteger n = (p - bytes);
	
	if (n > 0) {
		char prev = *(p - 1);
		
		if (prev == _CR) {
			--n;
		}
	}
	
	NSMutableData *result = self.buffer;
	
	++p;
	
	if (p < (bytes + len)) {
		self.buffer = [[NSMutableData alloc] initWithBytes:p length:((bytes + len) - p)];
	} else {
		self.buffer = [NSMutableData new];
	}
	
	[result setLength:n];
	
	return result;
}

- (void)write:(NSData *)data
{
	if (self.connected == NO) return;
	
	++self.sendQueueSize;
	
	[self.conn writeData:data withTimeout:(-1)	tag:0];
	[self.conn readDataWithTimeout:(-1)			tag:0];
}

- (BOOL)onSocketWillConnect:(id)sock
{
	if (self.useSystemSocks) {
		[self.conn useSystemSocksProxy];
	} else if (self.useSocks) {
		[self.conn useSocksProxyVersion:self.socksVersion 
							  host:self.proxyHost 
							  port:self.proxyPort 
							  user:self.proxyUser 
						  password:self.proxyPassword];
	} else if (self.useSSL) {
		[GCDAsyncSocket useSSLWithConnection:self.conn delegate:self.delegate];
	}
	
	return YES;
}

- (void)onSocket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self.conn readDataWithTimeout:(-1) tag:0]; 
	
	self.connecting = NO;
	self.connected  = YES;
	
	if ([self.delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[self.delegate tcpClientDidConnect:self];
	}
	
	IRCClient *clin = [self.delegate delegate];
	
	if (clin.rawModeEnabled) {
		NSLog(@"Debug Information:");
		NSLog(@"	Connected Host: %@", [sock connectedHost]);
		NSLog(@"	Connected Address: %@", [NSString stringWithData:[sock connectedAddress] encoding:NSUTF8StringEncoding]);
		NSLog(@"	Connected Port: %hu", [sock connectedPort]);
	}
}

- (void)onSocketDidDisconnect:(id)sock
{
	[self close];
	
	if ([self.delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[self.delegate tcpClientDidDisconnect:self];
	}	
}

- (void)onSocket:(id)sender willDisconnectWithError:(NSError *)error
{
	if (PointerIsEmpty(error) || [error code] == errSSLClosedGraceful) {
		[self onSocketDidDisconnect:sender];
	} else {
		NSString *msg    = nil;
		NSString *domain = [error domain];
		
		if ([GCDAsyncSocket badSSLCertErrorFound:error]) {
			IRCClient *client = [self.delegate performSelector:@selector(delegate)];
			
			client.disconnectType = IRCBadSSLCertificateDisconnectMode;
		} else {
			if ([domain isEqualToString:NSPOSIXErrorDomain]) {
				msg = [GCDAsyncSocket posixErrorStringFromErrno:[error code]];
			} 
			
			if (NSObjectIsEmpty(msg)) {
				msg = [error localizedDescription];
			}
			
			if ([self.delegate respondsToSelector:@selector(tcpClient:error:)]) {
				[self.delegate tcpClient:self error:msg];
			}
		}
		
		if ([self useNewSocketEngine]) {
			[self onSocketDidDisconnect:sender];
		}
	}
}

- (void)onSocket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (PointerIsEmpty(self.delegate)) {
        return;
    }
    
	[self.buffer appendData:data];
	
	if ([self.delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[self.delegate tcpClientDidReceiveData:self];
	}
	
	[self.conn readDataWithTimeout:(-1) tag:0]; 
}

- (void)onSocket:(id)sock didWriteDataWithTag:(long)tag
{
	--self.sendQueueSize;
	
    if (PointerIsEmpty(self.delegate)) {
        return;
    }
    
	if ([self.delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[self.delegate tcpClientDidSendData:self];
	}
}

- (void)socket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self.iomt onSocketWillConnect:sock];
	[self.iomt onSocket:sock didConnectToHost:ahost port:aport];
}

- (void)socketDidDisconnect:(id)sock withError:(NSError *)err
{
	[self.iomt onSocket:sock willDisconnectWithError:err];
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	[self.iomt onSocket:sock didReadData:data withTag:tag];
}

- (void)socket:(id)sock didWriteDataWithTag:(long)tag
{
	[self.iomt onSocket:sock didWriteDataWithTag:tag];
}

@end