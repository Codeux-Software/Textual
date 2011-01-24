// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation AsyncSocket (AsyncSocketExtensions) 

- (void)useSSL
{
	IRCClient *client = (IRCClient *)[[theDelegate delegate] delegate];
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	[settings setObject:CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL) forKey:CFItemRefToID(kCFStreamSSLLevel)];
	
	if (client.config.isTrustedConnection) {
		[settings setObject:CFItemRefToID(kCFNull) forKey:CFItemRefToID(kCFStreamSSLPeerName)];
		[settings setObject:CFItemRefToID(kCFBooleanFalse) forKey:CFItemRefToID(kCFStreamSSLIsServer)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue) forKey:CFItemRefToID(kCFStreamSSLAllowsAnyRoot)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue) forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)];
		[settings setObject:CFItemRefToID(kCFBooleanTrue) forKey:CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)];
		[settings setObject:CFItemRefToID(kCFBooleanFalse) forKey:CFItemRefToID(kCFStreamSSLValidatesCertificateChain)];
	}
	
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertySSLSettings, settings);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySSLSettings, settings);
}

- (void)useSystemSocksProxy
{
	CFDictionaryRef settings = SCDynamicStoreCopyProxies(NULL);
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySOCKSProxy, settings);
	CFRelease(settings);
}

- (void)useSocksProxyVersion:(NSInteger)version host:(NSString *)host port:(NSInteger)port user:(NSString *)user password:(NSString *)password
{
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	if (version == 4) {
		[settings setObject:CFItemRefToID(kCFStreamSocketSOCKSVersion4) forKey:CFItemRefToID(kCFStreamPropertySOCKSVersion)];
	} else {
		[settings setObject:CFItemRefToID(kCFStreamSocketSOCKSVersion5) forKey:CFItemRefToID(kCFStreamPropertySOCKSVersion)];
	}
	
	[settings setObject:host forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyHost)];
	[settings setObject:[NSNumber numberWithInteger:port] forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyPort)];
	
	if (NSStringIsEmpty(user) == NO) [settings setObject:user forKey:CFItemRefToID(kCFStreamPropertySOCKSUser)];
	if (NSStringIsEmpty(password) == NO) [settings setObject:password forKey:CFItemRefToID(kCFStreamPropertySOCKSPassword)];
	
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySOCKSProxy, settings);
}

+ (NSString *)posixErrorStringFromErrno:(NSInteger)code
{
	const char* error = strerror(code);
	
	return ((error) ? [NSString stringWithCString:error encoding:NSASCIIStringEncoding] : nil);
}

@end