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
@synthesize host;
@synthesize port;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize sendQueueSize;
@synthesize socksVersion;
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

- (void)dealloc
{
	if (conn) {
		[conn setDelegate:nil];
		[conn disconnect];
		
		[conn autodrain];
	}
	
	[buffer drain];
	
	[host drain];
	[proxyHost drain];
	[proxyUser drain];
	[proxyPassword drain];
	
	[super dealloc];
}

- (void)open
{
	[self close];
	
	[buffer setLength:0];
	
	NSError *connError = nil;
	
	conn = [AsyncSocket socketWithDelegate:self];
	
	if ([conn connectToHost:host onPort:port withTimeout:15.0 error:&connError] == NO) {
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
	
	[conn autodrain];
	conn = nil;
	
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
	
	[conn writeData:data withTimeout:15.0 tag:0];
	[conn readDataWithTimeout:(-1)		tag:0];
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
		[conn performSelector:@selector(useSSL)];
	}
	
	return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[conn readDataWithTimeout:(-1) tag:0]; 
	
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
	if (PointerIsEmpty(error)) {
		[self onSocketDidDisconnect:sender];
	} else {
		NSString *msg    = nil;
		NSString *domain = [error domain];
		
		if ([conn badSSLCertErrorFound:error]) {
			IRCClient *client = [delegate delegate];
			
			client.disconnectType = DISCONNECT_BAD_SSL_CERT;
		} else {
			if ([domain isEqualToString:NSPOSIXErrorDomain]) {
				msg = [conn posixErrorStringFromErrno:[error code]];
			} 
			
			if (NSObjectIsEmpty(msg)) {
				msg = [error localizedDescription];
			}
			
			if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
				[delegate tcpClient:self error:msg];
			}
		}
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[delegate tcpClientDidReceiveData:self];
	}
	
	[conn readDataWithTimeout:(-1) tag:0]; 
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	--sendQueueSize;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[delegate tcpClientDidSendData:self];
	}
}

@end