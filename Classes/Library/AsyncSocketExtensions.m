// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#pragma mark -
#pragma mark Grand Central Dispatch AsyncSocket Extensions

@implementation GCDAsyncSocket (GCDAsyncSocketExtensions)

+ (id)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
	return [[self alloc] initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq];
}

- (void)useSSL
{
	IRCClient *client = [[delegate delegate] delegate]; // Everything is interconnected
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	[settings setObject:CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL) forKey:CFItemRefToID(kCFStreamSSLLevel)];
	
	if (client.config.isTrustedConnection) {
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLIsServer)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsAnyRoot)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)];
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLValidatesCertificateChain)];
	}
	
	[self startTLS:settings];
}

@end

#pragma mark -
#pragma mark Run Loop Mode AsyncSocket Extensions

@implementation AsyncSocket (RLMAsyncSocketExtensions) 

+ (id)socketWithDelegate:(id)delegate
{
	return [[self alloc] initWithDelegate:delegate];
}

- (void)useSSL
{
	IRCClient *client = [[theDelegate delegate] delegate]; // Everything is interconnected
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	[settings setObject:CFItemRefToID(kCFNull)										forKey:CFItemRefToID(kCFStreamSSLPeerName)];
	[settings setObject:CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL)	forKey:CFItemRefToID(kCFStreamSSLLevel)];
	
	if (client.config.isTrustedConnection) {
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLIsServer)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsAnyRoot)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue)	forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)];
		[settings setObject:CFItemRefToID(kCFBooleanFalse)	forKey:CFItemRefToID(kCFStreamSSLValidatesCertificateChain)];
	}
	
	[self startTLS:settings];
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

+ (NSString *)posixErrorStringFromErrno:(NSInteger)code
{
	const char *error = strerror(code);
	
	if (error) {
		return [NSString stringWithCString:error encoding:NSASCIIStringEncoding];
	}
	
	return nil;
}

@end