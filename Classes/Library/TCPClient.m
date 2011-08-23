// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define LF	0xa
#define CR	0xd

@implementation TCPClient

@synthesize active;
@synthesize buffer;
@synthesize conn;
@synthesize connected;
@synthesize connecting;
@synthesize delegate;
@synthesize dispatchQueue;
@synthesize host;
@synthesize port;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize sendQueueSize;
@synthesize socksVersion;
@synthesize socketQueue;
@synthesize useSocks;
@synthesize useSSL;
@synthesize useSystemSocks;

- (id)init
{
	if ((self = [super init])) {
		buffer = [NSMutableData new];
	}
	
	return self;
}

- (NSInteger)timeoutInterval
{
    IRCClient *connd = [delegate delegate];
    
    NSInteger time = connd.config.timeoutInterval;
    
    if (time <= 0) {
        return -1;
    }
    
    return time;
}

- (BOOL)useNewSocketEngine
{
	return (useSystemSocks == NO && useSocks == NO && [_NSUserDefaults() boolForKey:@"disableNewSocketEngine"] == NO);
}

- (void)destroyDispatchQueue
{
    if ([self useNewSocketEngine]) {
        if (dispatchQueue) {
            dispatch_release(dispatchQueue);
            dispatchQueue = NULL;
        }
        
        if (socketQueue) {
            dispatch_release(socketQueue);
            socketQueue = NULL;
        }
    }
}

- (void)createDispatchQueue
{
	if ([self useNewSocketEngine]) {
		NSString *dqname = [NSString stringWithUUID];
        NSString *sqname = [NSString stringWithUUID];
        
        socketQueue = dispatch_queue_create([sqname UTF8String], NULL);
		dispatchQueue = dispatch_queue_create([dqname UTF8String], NULL);
	}
}

- (void)dealloc
{
	if (conn) {
		[conn setDelegate:nil];
		[conn disconnect];
		[conn autodrain];
	}
	
	[buffer drain];
    
    [self destroyDispatchQueue];
	
	[host drain];
	[proxyHost drain];
	[proxyUser drain];
	[proxyPassword drain];
	
	[super dealloc];
}

- (void)open
{
	[self createDispatchQueue];
    [self close];
	
	[buffer setLength:0];
	
	NSError *connError = nil;
	
	if ([self useNewSocketEngine]) {
        conn = [GCDAsyncSocket socketWithDelegate:self delegateQueue:dispatchQueue socketQueue:socketQueue];
        
        IRCClient *clin = [delegate delegate];
        
        [conn setPreferIPv4OverIPv6:BOOLReverseValue(clin.config.prefersIPv6)];
	} else {
		conn = [AsyncSocket socketWithDelegate:self];
	}
	
	if ([conn connectToHost:host onPort:port withTimeout:[self timeoutInterval] error:&connError] == NO) {
		NSLog(@"Silently ignoring connection error: %@", [connError localizedDescription]);
	}
	
	active     = YES;
	connecting = YES;
	connected  = NO;
	
	sendQueueSize = 0;
}

- (void)close
{
	if (PointerIsEmpty(conn)) return;
	
	[conn setDelegate:nil];
    [conn disconnect];
    
    [self destroyDispatchQueue];
	
	active	   = NO;
	connecting = NO;
	connected  = NO;
	
	sendQueueSize = 0;
}

- (NSData *)readLine
{
	NSInteger len = [buffer length];
	if (len < 1) return nil;
	
	const char *bytes = [buffer bytes];
	char *p = memchr(bytes, LF, len);
	
	if (p == NULL) return nil;
	
	NSInteger n = (p - bytes);
	
	if (n > 0) {
		char prev = *(p - 1);
		
		if (prev == CR) {
			--n;
		}
	}
	
	NSMutableData *result = [buffer autodrain];
	
	++p;
	
	if (p < (bytes + len)) {
		buffer = [[NSMutableData alloc] initWithBytes:p length:((bytes + len) - p)];
	} else {
		buffer = [NSMutableData new];
	}
	
	[result setLength:n];
	
	return result;
}

- (void)write:(NSData *)data
{
	if (connected == NO) return;
	
	++sendQueueSize;
	
	[conn writeData:data withTimeout:[self timeoutInterval]	tag:0];
	[conn readDataWithTimeout:[self timeoutInterval]		tag:0];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
	if (useSystemSocks) {
		[conn useSystemSocksProxy];
	} else if (useSocks) {
		[conn useSocksProxyVersion:socksVersion 
							  host:proxyHost 
							  port:proxyPort 
							  user:proxyUser 
						  password:proxyPassword];
	} else if (useSSL) {
		[GCDAsyncSocket useSSLWithConnection:conn delegate:delegate];
	}
	
	return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[conn readDataWithTimeout:[self timeoutInterval] tag:0]; 
	
	connecting = NO;
	connected  = YES;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[delegate tcpClientDidConnect:self];
	}
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[self close];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[delegate tcpClientDidDisconnect:self];
	}	
}

- (void)onSocket:(AsyncSocket *)sender willDisconnectWithError:(NSError *)error
{
	if (PointerIsEmpty(error) || [error code] == errSSLClosedGraceful) {
		[self onSocketDidDisconnect:sender];
	} else {
		NSString *msg    = nil;
		NSString *domain = [error domain];
		
		if ([GCDAsyncSocket badSSLCertErrorFound:error]) {
			IRCClient *client = [delegate performSelector:@selector(delegate)];
			
			client.disconnectType = DISCONNECT_BAD_SSL_CERT;
		} else {
			if ([domain isEqualToString:NSPOSIXErrorDomain]) {
				msg = [GCDAsyncSocket posixErrorStringFromErrno:[error code]];
			} 
			
			if (NSObjectIsEmpty(msg)) {
				msg = [error localizedDescription];
			}
			
			if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
				[delegate tcpClient:self error:msg];
			}
		}
		
		if ([self useNewSocketEngine]) {
			[self onSocketDidDisconnect:sender];
		}
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (PointerIsEmpty(delegate)) {
        return;
    }
    
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[delegate tcpClientDidReceiveData:self];
	}
	
	[conn readDataWithTimeout:[self timeoutInterval] tag:0]; 
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	--sendQueueSize;
	
    if (PointerIsEmpty(delegate)) {
        return;
    }
    
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[delegate tcpClientDidSendData:self];
	}
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[[self iomt] onSocketWillConnect:nil];
	[[self iomt] onSocket:nil didConnectToHost:ahost port:aport];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	[[self iomt] onSocket:nil willDisconnectWithError:err];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[[self iomt] onSocket:nil didReadData:data withTag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	[[self iomt] onSocket:nil didWriteDataWithTag:tag];
}

@end