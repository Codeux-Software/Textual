// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "AsyncSocketExtensions.h"

@implementation AsyncSocket (AsyncSocketExtensions) 

- (void)useSSL
{
	IRCClient *client = (IRCClient *)[[theDelegate delegate] delegate];
	
	NSDictionary *settings = nil;
	
	if (client.config.isTrustedConnection) {
		settings = [NSDictionary dictionaryWithObjectsAndKeys:
					(NSString*)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
					kCFNull, kCFStreamSSLPeerName,
					kCFBooleanFalse, kCFStreamSSLIsServer,
					kCFBooleanTrue, kCFStreamSSLAllowsAnyRoot,
					kCFBooleanTrue, kCFStreamSSLAllowsExpiredRoots,
					kCFBooleanTrue, kCFStreamSSLAllowsExpiredCertificates,
					kCFBooleanFalse, kCFStreamSSLValidatesCertificateChain,
					nil];
	} else {
		settings = [NSDictionary dictionaryWithObjectsAndKeys:(NSString*)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,  nil];
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

- (void)useSocksProxyVersion:(NSInteger)version host:(NSString*)host port:(NSInteger)port user:(NSString*)user password:(NSString*)password
{
	NSMutableDictionary* settings = [NSMutableDictionary dictionary];
	
	if (version == 4) {
		[settings setObject:(NSString*)kCFStreamSocketSOCKSVersion4 forKey:(NSString*)kCFStreamPropertySOCKSVersion];
	} else {
		[settings setObject:(NSString*)kCFStreamSocketSOCKSVersion5 forKey:(NSString*)kCFStreamPropertySOCKSVersion];
	}
	
	[settings setObject:host forKey:(NSString*)kCFStreamPropertySOCKSProxyHost];
	[settings setObject:[NSNumber numberWithInteger:port] forKey:(NSString*)kCFStreamPropertySOCKSProxyPort];
	
	if ([user length]) [settings setObject:user forKey:(NSString*)kCFStreamPropertySOCKSUser];
	if ([password length]) [settings setObject:password forKey:(NSString*)kCFStreamPropertySOCKSPassword];
	
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertySOCKSProxy, settings);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySOCKSProxy, settings);
}

+ (NSString*)posixErrorStringFromErrno:(NSInteger)code
{
	const char* error = strerror(code);
	
	if (error) {
		return [NSString stringWithCString:error encoding:NSASCIIStringEncoding];
	} else {
		return nil;
	}
}

@end