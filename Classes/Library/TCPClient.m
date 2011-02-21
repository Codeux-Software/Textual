// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define LF	0xa
#define CR	0xd

#define txCFStreamErrorDomainSSL @"kCFStreamErrorDomainSSL"

@interface TCPClient (Private)
- (void)waitRead;
@end

@implementation TCPClient

@synthesize delegate;
@synthesize host;
@synthesize port;
@synthesize useSSL;
@synthesize useSystemSocks;
@synthesize useSocks;
@synthesize socksVersion;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;
@synthesize sendQueueSize;
@synthesize active;
@synthesize connecting;
@synthesize conn;
@synthesize buffer;

- (id)init
{
	if ((self = [super init])) {
		buffer = [NSMutableData new];
	}
	
	return self;
}

- (id)initWithExistingConnection:(GCDAsyncSocket *)socket
{
	[self init];
	
	conn = [socket retain];
	conn.delegate = self;
	
	active = YES;
	connecting = YES;
	
	sendQueueSize = 0;
	
	return self;
}

- (void)dealloc
{
	if (conn) {
		conn.delegate = nil;
		
		[conn disconnect];
		[conn autorelease];
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
	
	conn = [GCDAsyncSocket socketWithDelegate:self delegateQueue:[delegate dispatchQueue]];
	
	if ([conn connectToHost:host onPort:port error:&connError] == NO) {
		NSLog(@"Silently ignoring connection error: %@", [connError localizedDescription]);
	}
	
	active = YES;
	connecting = YES;
	
	sendQueueSize = 0;
}

- (void)close
{
	if (PointerIsEmpty(conn)) return;
	
	[conn disconnect];
	[conn autorelease];
	conn = nil;
	
	active = NO;
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
	
	[conn writeData:data withTimeout:-1 tag:0];
	
	[self waitRead];
}

- (BOOL)connected
{
	if (PointerIsEmpty(conn)) return NO;
	
	return [conn isConnected];
}

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)aHost port:(UInt16)aPort
{
	if (useSystemSocks) {
		[conn useSystemSocksProxy];
	} else if (useSocks) {
		[conn useSocksProxyVersion:socksVersion host:proxyHost port:proxyPort user:proxyUser password:proxyPassword];
	} else if (useSSL) {
		[conn useSSL];
	}
	
	[self waitRead];
	
	connecting = NO;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		/* Connections are ran on a separate queue so that means we have
		 to invoke the delegate on the main thread. If we do not, then that
		 means that WebKit will throw an exception for not. */
		
		[[delegate invokeOnMainThread] tcpClientDidConnect:self];
	}
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock 
{
	[self close];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[[delegate invokeOnMainThread] tcpClientDidDisconnect:self];
	}	
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
	NSString *msg    = nil;
	NSString *domain = [error domain];
	
	if ([error code] == -9805) { /* connection closed gracefully */
		[self socketDidDisconnect:sock];
	} else {
		if ([domain isEqualToString:NSPOSIXErrorDomain]) {
			msg = [GCDAsyncSocket posixErrorStringFromErrno:[error code]];
		} else {
			if ([domain isEqualToString:txCFStreamErrorDomainSSL] && [self badSSLCertErrorFound:[error code]]) {
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
		
		if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
			[[delegate invokeOnMainThread] tcpClient:self error:msg];
		}
		
		[self socketDidDisconnect:sock];
	}
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)aTag
{
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[[delegate invokeOnMainThread] tcpClientDidReceiveData:self];
	}
	
	[self waitRead];
}

- (void)socket:(GCDAsyncSocket *)sender didWriteDataWithTag:(long)aTag
{
	--sendQueueSize;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[[delegate invokeOnMainThread] tcpClientDidSendData:self];
	}
}

- (void)waitRead
{
	[conn readDataWithTimeout:-1 tag:0];
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
						   [NSNumber numberWithInteger:errSSLPeerUnknownCA], nil];
	
	NSNumber *errorCode = [NSNumber numberWithInteger:code];
	
	return [errorCodes containsObject:errorCode];
}

@end