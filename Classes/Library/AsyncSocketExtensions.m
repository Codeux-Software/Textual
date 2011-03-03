// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

static NSString *txCFStreamErrorDomainSSL = @"kCFStreamErrorDomainSSL";

@implementation AsyncSocket (RLMAsyncSocketExtensions) 

+ (id)socketWithDelegate:(id)delegate
{
	return [[self alloc] initWithDelegate:delegate];
}

- (void)useSSL
{
	IRCClient *client = [[theDelegate delegate] delegate]; // Everything is interconnected
	
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
	
	[self startTLS:settings];
}

- (BOOL)badSSLCertErrorFound:(NSError *)error
{
	NSInteger  code   = [error code];
	NSString  *domain = [error domain];
	
	if ([domain isEqualToString:txCFStreamErrorDomainSSL]) {
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
	
	return NO;
}

- (NSString *)posixErrorStringFromErrno:(NSInteger)code
{
	const char *error = strerror(code);
	
	if (error) {
		return [NSString stringWithCString:error encoding:NSASCIIStringEncoding];
	}
	
	return nil;
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
	
	[settings setObject:host								forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyHost)];
	[settings setObject:[NSNumber numberWithInteger:port]	forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyPort)];
	
	if (NSObjectIsNotEmpty(user))		[settings setObject:user		forKey:CFItemRefToID(kCFStreamPropertySOCKSUser)];
	if (NSObjectIsNotEmpty(password))	[settings setObject:password	forKey:CFItemRefToID(kCFStreamPropertySOCKSPassword)];
	
	CFReadStreamSetProperty(theReadStream,		kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream,	kCFStreamPropertySOCKSProxy, settings);
}

@end