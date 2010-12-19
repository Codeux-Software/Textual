// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TCPClient.h"

#define LF	0xa
#define CR	0xd

#define txCFStreamErrorDomainSSL @"kCFStreamErrorDomainSSL"

@interface TCPClient (Private)
- (BOOL)checkTag:(AsyncSocket *)sock;
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
@synthesize tag;
@synthesize socketBadSSLCertErrorCodes;

- (id)init
{
	if ((self = [super init])) {
		buffer = [NSMutableData new];
		
		socketBadSSLCertErrorCodes = [[NSArray alloc] initWithObjects:
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
	}
	return self;
}

- (id)initWithExistingConnection:(AsyncSocket *)socket
{
	[self init];
	
	conn = [socket retain];
	conn.delegate = self;
	[conn setUserData:tag];
	active = connecting = YES;
	sendQueueSize = 0;
	
	return self;
}

- (void)dealloc
{
	[host release];
	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[socketBadSSLCertErrorCodes release];
	
	if (conn) {
		conn.delegate = nil;
		[conn disconnect];
		[conn autorelease];
	}
	
	[buffer release];
	
	[super dealloc];
}

- (void)open
{
	[self close];
	
	[buffer setLength:0];
	++tag;
	
	conn = [[AsyncSocket alloc] initWithDelegate:self userData:tag];
	[conn connectToHost:host onPort:port error:NULL];
	active = connecting = YES;
	sendQueueSize = 0;
}

- (void)close
{
	if (!conn) return;
	
	++tag;
	
	[conn disconnect];
	[conn autorelease];
	conn = nil;
	
	active = connecting = NO;
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
	if (!len) return nil;
	
	const char* bytes = [buffer bytes];
	char* p = memchr(bytes, LF, len);
	if (!p) return nil;
	NSInteger n = p - bytes;
	
	if (n > 0) {
		char prev = *(p - 1);
		if (prev == CR) {
			--n;
		}
	}
	
	NSMutableData *result = [buffer autorelease];
	
	++p;
	if (p < bytes + len) {
		buffer = [[NSMutableData alloc] initWithBytes:p length:bytes + len - p];
	} else {
		buffer = [NSMutableData new];
	}
	
	[result setLength:n];
	return result;
}

- (void)write:(NSData *)data
{
	if (![self connected]) return;
	
	++sendQueueSize;
	
	[conn writeData:data withTimeout:-1 tag:0];
	[self waitRead];
}

- (BOOL)connected
{
	if (!conn) return NO;
	if (![self checkTag:conn]) return NO;
	return [conn isConnected];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sender
{
	if (useSystemSocks) {
		[conn useSystemSocksProxy];
	} else if (useSocks) {
		[conn useSocksProxyVersion:socksVersion host:proxyHost port:proxyPort user:proxyUser password:proxyPassword];
	} else if (useSSL) {
		[conn useSSL];
	}
	
	return YES;
}

- (void)onSocket:(AsyncSocket *)sender didConnectToHost:(NSString *)aHost port:(UInt16)aPort
{
	if (![self checkTag:sender]) return;
	[self waitRead];
	connecting = NO;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[delegate tcpClientDidConnect:self];
	}
}

- (void)onSocket:(AsyncSocket *)sender willDisconnectWithError:(NSError *)error
{
	if (![self checkTag:sender]) return;
	if (!error) return;
	
	NSString *msg = nil;
	
	if ([[error domain] isEqualToString:NSPOSIXErrorDomain]) {
		msg = [AsyncSocket posixErrorStringFromErrno:[error code]];
	} else {
		if ([[error domain] isEqualToString:txCFStreamErrorDomainSSL]) {
			if ([socketBadSSLCertErrorCodes containsObject:[NSNumber numberWithInteger:[error code]]]) {
				IRCClient *client = (IRCClient *)[delegate delegate];
				
				NSString *suppKey = [NSString stringWithFormat:@"Preferences.prompts.cert_trust_error.%@", client.config.guid];
				BOOL suppValue = [TXNSUserDefaultsPointer() boolForKey:suppKey];
				
				if ((client.config.isTrustedConnection == NO && suppValue == NO) ||
					(client.config.isTrustedConnection == NO && suppValue == YES)) {
					
					BOOL status = promptWithSuppression(TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_MESSAGE"), 
														TXTLS(@"SSL_SOCKET_BAD_CERTIFICATE_ERROR_TITLE"), 
														TXTLS(@"TRUST_BUTTON"), 
														TXTLS(@"CANCEL_BUTTON"), suppKey, nil);
					
					client.config.isTrustedConnection = status;
					client.disconnectType = ((status == YES) ? DISCONNECT_BAD_SSL_CERT : DISCONNECT_NORMAL);
					
					// If we trust this connection and want to connect to it, then 
					// let us override our prompt suppressor to hide every time.
					
					[TXNSUserDefaultsPointer() setBool:status forKey:suppKey];
					
					if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
						[delegate tcpClient:self error:nil];
					}
				}
			}
		}
	}
	
	if (!msg) {
		msg = [error localizedDescription];
	}
	
	if ([delegate respondsToSelector:@selector(tcpClient:error:)]) {
		[delegate tcpClient:self error:msg];
	}
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sender
{
	if (![self checkTag:sender]) return;
	
	[self close];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[delegate tcpClientDidDisconnect:self];
	}
}

- (void)onSocket:(AsyncSocket *)sender didReadData:(NSData *)data withTag:(long)aTag
{
	if (![self checkTag:sender]) return;
	
	[buffer appendData:data];
	
	if ([delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[delegate tcpClientDidReceiveData:self];
	}
	
	[self waitRead];
}

- (void)onSocket:(AsyncSocket *)sender didWriteDataWithTag:(long)aTag
{
	if (![self checkTag:sender]) return;
	
	--sendQueueSize;
	
	if ([delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[delegate tcpClientDidSendData:self];
	}
}

- (BOOL)checkTag:(AsyncSocket *)sock
{
	return tag == [sock userData];
}

- (void)waitRead
{
	[conn readDataWithTimeout:-1 tag:0];
}

@end