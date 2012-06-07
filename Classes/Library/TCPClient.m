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
	}
	
    
    [self destroyDispatchQueue];
	
	
	delegate = nil;
	
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
	
	if ([conn connectToHost:host onPort:port withTimeout:(-1) error:&connError] == NO) {
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
	
	NSMutableData *result = buffer;
	
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
	
	[conn writeData:data withTimeout:(-1)	tag:0];
	[conn readDataWithTimeout:(-1)			tag:0];
}

- (BOOL)onSocketWillConnect:(id)sock
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

- (void)onSocket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[conn readDataWithTimeout:(-1) tag:0]; 
	
	connecting = NO;
	connected  = YES;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[delegate tcpClientDidConnect:self];
	}
	
	IRCClient *clin = [delegate delegate];
	
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
	
	if ([delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[delegate tcpClientDidDisconnect:self];
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

- (void)onSocket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (PointerIsEmpty(delegate)) {
        return;
    }
    
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[delegate tcpClientDidReceiveData:self];
	}
	
	[conn readDataWithTimeout:(-1) tag:0]; 
}

- (void)onSocket:(id)sock didWriteDataWithTag:(long)tag
{
	--sendQueueSize;
	
    if (PointerIsEmpty(delegate)) {
        return;
    }
    
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[delegate tcpClientDidSendData:self];
	}
}

- (void)socket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[[self iomt] onSocketWillConnect:sock];
	[[self iomt] onSocket:sock didConnectToHost:ahost port:aport];
}

- (void)socketDidDisconnect:(id)sock withError:(NSError *)err
{
	[[self iomt] onSocket:sock willDisconnectWithError:err];
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	[[self iomt] onSocket:sock didReadData:data withTag:tag];
}

- (void)socket:(id)sock didWriteDataWithTag:(long)tag
{
	[[self iomt] onSocket:sock didWriteDataWithTag:tag];
}

@end