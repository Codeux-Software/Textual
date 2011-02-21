// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define LF	0xa
#define CR	0xd

#define txCFStreamErrorDomainSSL @"kCFStreamErrorDomainSSL"

@interface TCPClient (Private)
- (void)waitRead;
@end

@implementation TCPClient

@synthesize active;
@synthesize buffer;
@synthesize conn;
@synthesize connecting;
@synthesize delegate;
@synthesize delegateQueue;
@synthesize host;
@synthesize port;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize sendQueueSize;
@synthesize socketQueue;
@synthesize socksVersion;
@synthesize useSocks;
@synthesize useSSL;
@synthesize useSystemSocks;

#pragma mark -
#pragma mark Client Structure

- (id)init
{
	if ((self = [super init])) {
		buffer = [NSMutableData new];
	}
	
	return self;
}

- (id)initWithExistingConnection:(AsyncSocket *)socket
{
	[self init];
	
	conn = [socket retain];
	[conn setDelegate:self];
	
	active	   = YES;
	connecting = YES;
	
	sendQueueSize = 0;
	
	return self;
}

- (void)dealloc
{
	if (conn) {
		[conn setDelegate:nil];
		
		[conn disconnect];
		[conn autorelease];
	}
	
	if (delegateQueue) {
		dispatch_release(delegateQueue);
	}
	
	if (socketQueue) {
		dispatch_release(socketQueue);
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
	
	if ([self usingNewSocketEngine]) {
		delegateQueue = dispatch_queue_create([[NSString stringWithUUID] UTF8String], NULL);
		socketQueue   = dispatch_queue_create([[NSString stringWithUUID] UTF8String], NULL);
		
		conn = [GCDAsyncSocket socketWithDelegate:self delegateQueue:delegateQueue socketQueue:socketQueue];
	} else {
		conn = [AsyncSocket socketWithDelegate:self];
	}
	
	if ([conn connectToHost:host onPort:port error:&connError] == NO) {
		NSLog(@"Silently ignoring connection error: %@", [connError localizedDescription]);
	}
	
	active     = YES;
	connecting = YES;
	
	sendQueueSize = 0;
}

- (void)close
{
	if (PointerIsEmpty(conn)) return;
	
	[conn disconnect];
	[conn autorelease];
	conn = nil;
	
	active	   = NO;
	connecting = NO;
	
	sendQueueSize = 0;
}

- (NSData *)read
{
	NSData *result = [buffer autorelease];
	
	buffer = [NSMutableData new];
	
	return result;
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
	
	NSMutableData *result = [buffer autorelease];
	
	++p;
	
	if (p < (bytes + len)) {
		buffer = [[NSMutableData alloc] initWithBytes:p length:(bytes + len - p)];
	} else {
		buffer = [NSMutableData new];
	}
	
	[result setLength:n];
	
	return result;
}

- (void)write:(NSData *)data
{
	if ([self connected] == NO) return;
	
	++sendQueueSize;
	
	[conn writeData:data withTimeout:10 tag:0];
	
	[self waitRead];
}

#pragma mark -
#pragma mark Run Loop AsyncSocket Delegate Methods

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
	if (useSystemSocks) {
		[conn useSystemSocksProxy];
	} else if (useSocks) {
		[conn useSocksProxyVersion:socksVersion host:proxyHost port:proxyPort user:proxyUser password:proxyPassword];
	} else if (useSSL) {
		[conn performSelector:@selector(useSSL)];
	}
	
	return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self waitRead];
	
	connecting = NO;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[[delegate invokeOnMainThread] tcpClientDidConnect:self];
	}
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[self close];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[[delegate invokeOnMainThread] tcpClientDidDisconnect:self];
	}	
}

- (void)onSocket:(AsyncSocket *)sender willDisconnectWithError:(NSError *)error
{
	if (PointerIsEmpty(error)) {
		[self onSocketDidDisconnect:sender];
	} else {
		NSString *msg    = nil;
		NSString *domain = [error domain];
		
		if ([error code] == -9805) { /* connection closed gracefully */
			[self onSocketDidDisconnect:sender];
		} else {
			if ([domain isEqualToString:NSPOSIXErrorDomain]) {
				msg = [AsyncSocket posixErrorStringFromErrno:[error code]];
			} else {
				if ([domain isEqualToString:txCFStreamErrorDomainSSL] && [self badSSLCertErrorFound:[error code]]) 
				{
					IRCClient *client = [delegate delegate];
					
					NSString *suppKey = [@"Preferences.prompts.cert_trust_error." stringByAppendingString:client.config.guid];
					
					if (client.config.isTrustedConnection == NO) {
						BOOL status = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_MESSAGE") 
																	   title:TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_TITLE") 
															   defaultButton:TXTLS(@"TRUST_BUTTON") 
															 alternateButton:TXTLS(@"CANCEL_BUTTON") 
															  suppressionKey:suppKey
															 suppressionText:@"-"];
						
						if (status) {
							client.disconnectType = DISCONNECT_BAD_SSL_CERT;
						}
						
						client.config.isTrustedConnection = status;
						
						[_NSUserDefaults() setBool:status forKey:suppKey];
						
						if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
							[[delegate invokeOnMainThread] tcpClient:self error:nil];
						}
						
						return;
					}
				}
			}
			
			if (NSObjectIsEmpty(msg)) {
				msg = [error localizedDescription];
			}
			
			[self onSocketDidDisconnect:sender];
		}
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[[delegate invokeOnMainThread] tcpClientDidReceiveData:self];
	}
	
	[self waitRead];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	--sendQueueSize;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[[delegate invokeOnMainThread] tcpClientDidSendData:self];
	}
}

#pragma mark -
#pragma mark Grand Central Dispatch Delegate Methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self onSocketWillConnect:nil];
	[self onSocket:nil didConnectToHost:ahost port:aport];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[self onSocket:nil didReadData:data withTag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	[self onSocket:nil didWriteDataWithTag:tag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
	[self onSocket:nil willDisconnectWithError:error];
}

#pragma mark -
#pragma mark Misc. Methods

- (void)waitRead
{
	[conn readDataWithTimeout:-1 tag:0];
}

- (BOOL)connected
{
	if (PointerIsEmpty(conn)) return NO;
	
	return [conn isConnected];
}

- (BOOL)badSSLCertErrorFound:(NSInteger)code
{
	NSArray *errorCodes = [NSArray arrayWithObjects:
						   [NSNumber numberWithInteger:errSSLBadCert], 
						   [NSNumber numberWithInteger:errSSLNoRootCert], 
						   [NSNumber numberWithInteger:errSSLCertExpired],  
						   [NSNumber numberWithInteger:errSSLPeerBadCert], 
						   [NSNumber numberWithInteger:errSSLPeerCertRevoked], 
						   [NSNumber numberWithInteger:errSSLPeerCertExpired], 
						   [NSNumber numberWithInteger:errSSLPeerCertUnknown], 
						   [NSNumber numberWithInteger:errSSLUnknownRootCert], 
						   [NSNumber numberWithInteger:errSSLCertNotYetValid],
						   [NSNumber numberWithInteger:errSSLXCertChainInvalid], 
						   [NSNumber numberWithInteger:errSSLPeerUnsupportedCert], 
						   [NSNumber numberWithInteger:errSSLPeerUnknownCA], 
						   [NSNumber numberWithInteger:errSSLHostNameMismatch], nil];
	
	NSNumber *errorCode = [NSNumber numberWithInteger:code];
	
	return [errorCodes containsObject:errorCode];
}

- (BOOL)usingNewSocketEngine
{
	return (useSocks == NO && useSystemSocks == NO);
}

@end