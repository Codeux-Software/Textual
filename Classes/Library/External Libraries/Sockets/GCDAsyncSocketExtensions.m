// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#import <SecurityInterface/SFCertificatePanel.h>

#define TXkCFStreamErrorDomainSSL		@"kCFStreamErrorDomainSSL"

@implementation GCDAsyncSocket (GCDsyncSocketExtensions)

+ (id)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
    return [[self alloc] initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq];
}

+ (void)useSSLWithConnection:(id)socket delegate:(id)theDelegate
{
	IRCClient *client = [theDelegate performSelector:@selector(delegate)];

	NSMutableDictionary *settings = [NSMutableDictionary dictionary];

	settings[CFItemRefToID(kCFStreamSSLLevel)] = CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL);
	settings[CFItemRefToID(kCFStreamSSLPeerName)] = CFItemRefToID(kCFNull);

	if (client.config.isTrustedConnection) {
		settings[CFItemRefToID(kCFStreamSSLIsServer)] = CFItemRefToID(kCFBooleanFalse);
		settings[CFItemRefToID(kCFStreamSSLAllowsAnyRoot)] = CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)] = CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)] = CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLValidatesCertificateChain)] = CFItemRefToID(kCFBooleanFalse);
	}

	[socket startTLS:settings];
}

+ (BOOL)badSSLCertErrorFound:(NSError *)error
{
	NSInteger  code   = [error code];
	NSString  *domain = [error domain];

	if ([domain isEqualToString:TXkCFStreamErrorDomainSSL]) {
		NSArray *errorCodes = @[@(errSSLBadCert),
		@(errSSLNoRootCert),
		@(errSSLCertExpired),
		@(errSSLPeerBadCert),
		@(errSSLPeerCertRevoked),
		@(errSSLPeerCertExpired),
		@(errSSLPeerCertUnknown),
		@(errSSLUnknownRootCert),
		@(errSSLCertNotYetValid),
		@(errSSLXCertChainInvalid),
		@(errSSLPeerUnsupportedCert),
		@(errSSLPeerUnknownCA),
		@(errSSLHostNameMismatch)];

		NSNumber *errorCode = @(code);

		return [errorCodes containsObject:errorCode];
	}

	return NO;
}

+ (NSString *)posixErrorStringFromErrno:(NSInteger)code
{
	const char *error = strerror((int)code);

	if (error) {
		return @(error);
	}

	return nil;
}

- (void)requestSSLTrustFor:(NSWindow *)docWindow
			 modalDelegate:(id)adelegate
			didEndSelector:(SEL)didEndSelector
			   contextInfo:(void *)contextInfo
			 defaultButton:(NSString *)defaultButton
		   alternateButton:(NSString *)alternateButton
{
	SecTrustRef trust = [self sslCertificateTrustInformation];

	DLog(@"SSL Trust Ref: %@", trust);

	if (PointerIsNotEmpty(trust)) {
		SFCertificatePanel *panel = [SFCertificatePanel sharedCertificatePanel];

		[panel setDefaultButtonTitle:defaultButton];
		[panel setAlternateButtonTitle:alternateButton];

		[panel beginSheetForWindow:docWindow
					 modalDelegate:adelegate
					didEndSelector:didEndSelector
					   contextInfo:contextInfo
							 trust:trust
						 showGroup:NO];
	}
}

- (SecTrustRef)sslCertificateTrustInformation /* @private */
{
	__block SecTrustRef trust;

	dispatch_block_t block = ^{
		OSStatus status = SSLCopyPeerTrust(self.sslContext, &trust);

		DLog(@"SSL Context: %@\nTrust Ref: %@\nCopy Status: %i", self.sslContext, trust, status);

#pragma unused(status)
	};

	[self performBlock:block];

	return trust;
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
		settings[CFItemRefToID(kCFStreamPropertySOCKSVersion)] = CFItemRefToID(kCFStreamSocketSOCKSVersion4);
	} else {
		settings[CFItemRefToID(kCFStreamPropertySOCKSVersion)] = CFItemRefToID(kCFStreamSocketSOCKSVersion5);
	}

	settings[CFItemRefToID(kCFStreamPropertySOCKSProxyHost)] = host;
	[settings setInteger:port	forKey:CFItemRefToID(kCFStreamPropertySOCKSProxyPort)];

	if (NSObjectIsNotEmpty(user))		settings[CFItemRefToID(kCFStreamPropertySOCKSUser)] = user;
	if (NSObjectIsNotEmpty(password))	settings[CFItemRefToID(kCFStreamPropertySOCKSPassword)] = password;

	CFReadStreamSetProperty(theReadStream,		kCFStreamPropertySOCKSProxy, (__bridge CFStringRef)(settings));
	CFWriteStreamSetProperty(theWriteStream,	kCFStreamPropertySOCKSProxy, (__bridge CFStringRef)(settings));
}

@end