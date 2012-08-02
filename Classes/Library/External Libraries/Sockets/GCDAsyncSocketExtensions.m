/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

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

	settings[CFItemRefToID(kCFStreamSSLLevel)]		= CFItemRefToID(kCFStreamSocketSecurityLevelNegotiatedSSL);
	settings[CFItemRefToID(kCFStreamSSLPeerName)]	= CFItemRefToID(kCFNull);

	if (client.config.isTrustedConnection) {
		settings[CFItemRefToID(kCFStreamSSLIsServer)]					= CFItemRefToID(kCFBooleanFalse);
		settings[CFItemRefToID(kCFStreamSSLAllowsAnyRoot)]				= CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLAllowsExpiredRoots)]			= CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLAllowsExpiredCertificates)]	= CFItemRefToID(kCFBooleanTrue);
		settings[CFItemRefToID(kCFStreamSSLValidatesCertificateChain)]	= CFItemRefToID(kCFBooleanFalse);
	}

	[socket startTLS:settings];
}

+ (BOOL)badSSLCertErrorFound:(NSError *)error
{
	NSInteger  code   = [error code];
	NSString  *domain = [error domain];

	if ([domain isEqualToString:TXkCFStreamErrorDomainSSL]) {
		NSArray *errorCodes = @[
		@(errSSLBadCert),
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
	
	DebugLogToConsole(@"SSL Trust Ref: %@", trust);

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

		DebugLogToConsole(@"SSL Context: %@\nTrust Ref: %@\nCopy Status: %i", self.sslContext, trust, status);

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
	settings[CFItemRefToID(kCFStreamPropertySOCKSProxyPort)] = @(port);

	if (NSObjectIsNotEmpty(user))		settings[CFItemRefToID(kCFStreamPropertySOCKSUser)] = user;
	if (NSObjectIsNotEmpty(password))	settings[CFItemRefToID(kCFStreamPropertySOCKSPassword)] = password;

	CFReadStreamSetProperty (theReadStream,		kCFStreamPropertySOCKSProxy, (__bridge CFStringRef)(settings));
	CFWriteStreamSetProperty(theWriteStream,	kCFStreamPropertySOCKSProxy, (__bridge CFStringRef)(settings));
}

@end