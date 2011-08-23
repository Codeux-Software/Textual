// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

static NSString *txCFStreamErrorDomainSSL = @"kCFStreamErrorDomainSSL";

@implementation GCDAsyncSocket (GCDsyncSocketExtensions)

+ (id)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
    return [[self alloc] initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq];
}

+ (void)useSSLWithConnection:(id)socket delegate:(id)theDelegate
{
	IRCClient *client = [theDelegate performSelector:@selector(delegate)];
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	[settings setObject:CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL)	forKey:CFItemRefToID(kCFStreamSSLLevel)];
	[settings setObject:CFItemRefToID(kCFNull)										forKey:CFItemRefToID(kCFStreamSSLPeerName)];
	
	if (client.config.isTrustedConnection) {
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLIsServer)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsAnyRoot)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)];
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLValidatesCertificateChain)];
	}
	
	[socket startTLS:settings];
}

+ (BOOL)badSSLCertErrorFound:(NSError *)error
{
	NSInteger  code   = [error code];
	NSString  *domain = [error domain];
	
	if ([domain isEqualToString:txCFStreamErrorDomainSSL]) {
		NSArray *errorCodes = [NSArray arrayWithObjects:
							   NSNumberWithInteger(errSSLBadCert), 
							   NSNumberWithInteger(errSSLNoRootCert), 
							   NSNumberWithInteger(errSSLCertExpired),  
							   NSNumberWithInteger(errSSLPeerBadCert), 
							   NSNumberWithInteger(errSSLPeerCertRevoked), 
							   NSNumberWithInteger(errSSLPeerCertExpired), 
							   NSNumberWithInteger(errSSLPeerCertUnknown), 
							   NSNumberWithInteger(errSSLUnknownRootCert), 
							   NSNumberWithInteger(errSSLCertNotYetValid),
							   NSNumberWithInteger(errSSLXCertChainInvalid), 
							   NSNumberWithInteger(errSSLPeerUnsupportedCert), 
							   NSNumberWithInteger(errSSLPeerUnknownCA), 
							   NSNumberWithInteger(errSSLHostNameMismatch), nil];
		
		NSNumber *errorCode = NSNumberWithInteger(code);
		
		return [errorCodes containsObject:errorCode];
	}
	
	return NO;
}

+ (NSString *)posixErrorStringFromErrno:(NSInteger)code
{
	const char *error = strerror(code);
	
	if (error) {
		return [NSString stringWithCString:error encoding:NSASCIIStringEncoding];
	}
	
	return nil;
}

@end

@implementation AsyncSocket (RLMAsyncSocketExtensions) 

+ (id)socketWithDelegate:(id)delegate
{
	return [[self alloc] initWithDelegate:delegate];
}

- (void)useSystemSocksProxy
{
	CFDictionaryRef settings = SCDynamicStoreCopyProxies(NULL);
	
	CFReadStreamSetProperty(theReadStream,		kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream,	kCFStreamPropertySOCKSProxy, settings);
	
	CFRelease(settings);
}

- (void)useSocksProxyVersion:(NSInteger)version 
						host:(NSString *)host 
						port:(NSInteger)port 
						user:(NSString *)user 
					password:(NSString *)password
{
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	if (version == 4) {
		[settings setObject:CFItemRefToID(kCFStreamSocketSOCKSVersion4) forKey:CFItemRefToID(kCFStreamPropertySOCKSVersion)];
	} else {
		[settings setObject:CFItemRefToID(kCFStreamSocketSOCKSVersion5) forKey:CFItemRefToID(kCFStreamPropertySOCKSVersion)];
	}
	
	[settings setObject:host	forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyHost)];
	[settings setInteger:port	forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyPort)];
	
	if (NSObjectIsNotEmpty(user))		[settings setObject:user		forKey:CFItemRefToID(kCFStreamPropertySOCKSUser)];
	if (NSObjectIsNotEmpty(password))	[settings setObject:password	forKey:CFItemRefToID(kCFStreamPropertySOCKSPassword)];
	
	CFReadStreamSetProperty(theReadStream,		kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream,	kCFStreamPropertySOCKSProxy, settings);
}

@end