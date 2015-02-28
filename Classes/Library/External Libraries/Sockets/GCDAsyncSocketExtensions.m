/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

@implementation GCDAsyncSocket (GCDsyncSocketExtensions)

+ (instancetype)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
    return [[self alloc] initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq];
}

- (void)useSSLWithClient:(IRCClient *)client connectionController:(IRCConnection *)controller
{
	if (client == nil) {
		NSAssert(NO, @"'client' cannot be nil");
	}

	if (controller == nil) {
		NSAssert(NO, @"'controller' cannot be nil");
	}

	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
	settings[GCDAsyncSocketSSLProtocolVersionMin] = @(kTLSProtocol1);
	
	settings[(id)kCFStreamSSLIsServer] = (id)kCFBooleanFalse;
	settings[(id)kCFStreamSSLPeerName] = (id)[controller serverAddress];
	
	NSData *localCertData = [[client config] identityClientSideCertificate];
	
	if (localCertData) {
		SecKeychainItemRef cert;
		
		CFDataRef rawCertData = (__bridge CFDataRef)(localCertData);
		
		OSStatus status = SecKeychainItemCopyFromPersistentReference(rawCertData, &cert);
		
		if (status == noErr) {
			SecIdentityRef identity;
			
			status = SecIdentityCreateWithCertificate(NULL, (SecCertificateRef)cert, &identity);
			
			if (status == noErr) {
				settings[(id)kCFStreamSSLCertificates] = @[(__bridge id)identity, (__bridge id)cert];

				[controller setIsConnectedWithClientSideCertificate:YES];

				CFRelease(identity);
			} else {
				LogToConsole(@"User supplied client-side certificate produced an error trying to read it: %i (#2)", status);
			}
			
			CFRelease(cert);
		}else {
			LogToConsole(@"User supplied client-side certificate produced an error trying to read it: %i (#1)", status);
		}
	}

	[self startTLS:settings];
}

+ (BOOL)badSSLCertificateErrorFound:(NSError *)error
{
	if ([[error domain] isEqualToString:@"kCFStreamErrorDomainSSL"]) {
		static NSArray *errorCodes = nil;

		if (errorCodes == nil) {
			errorCodes = @[
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
				@(errSSLHostNameMismatch
			)];
		}

		return [errorCodes containsObject:@([error code])];
	}

	return NO;
}

+ (NSString *)posixErrorStringFromError:(NSInteger)errorCode
{
	const char *error = strerror((int)errorCode);

	if (error) {
		return @(error);
	}

	return nil;
}

- (SecTrustRef)sslCertificateTrustInformation
{
	__block SecTrustRef trust;

	dispatch_block_t block = ^{
		OSStatus status = SSLCopyPeerTrust(self.sslContext, &trust);

#pragma unused(status)
	};

	[self performBlock:block];

	return trust;
}

- (NSString *)sslCertificateLocalizedOwnershipInformation
{
	SecTrustRef trustRef = [self sslCertificateTrustInformation];

	if (trustRef) {
		CFIndex certificateCount = SecTrustGetCertificateCount(trustRef);

		if (certificateCount > 0) {
			SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trustRef, (certificateCount - 1)); // Get last certificate in chain.

			if (certificate) {
				if (CFGetTypeID(certificate) == SecCertificateGetTypeID()) {
					CFDictionaryRef certificateProperties = SecCertificateCopyValues(certificate, NULL, NULL);

					if (certificateProperties) {
						if (CFGetTypeID(certificateProperties) == CFDictionaryGetTypeID()) {
							static id (^getTopLevelObjectValue)(id, CFTypeRef) = ^id (id inputValues, CFTypeRef childKey)
							{
								id childValue = [inputValues objectForKey:(__bridge id)childKey];

								if (childValue) {
									if ([childValue isKindOfClass:[NSDictionary class]]) {
										return [childValue objectForKey:(__bridge id)kSecPropertyKeyValue];
									}
								}

								return nil;
							};

							static id (^getObjectValueForChild)(id, CFTypeRef) = ^id (id inputValues, CFTypeRef childKey)
							{
								if ([inputValues isKindOfClass:[NSArray class]] == NO) {
									return nil;
								}

								NSString *childKeyString = (__bridge NSString *)(childKey);

								for (id object in inputValues) {
									if ([object isKindOfClass:[NSDictionary class]]) {
										id objectLabel = [object objectForKey:(__bridge id)(kSecPropertyKeyLabel)];

										if (objectLabel) {
											if ([childKeyString isEqual:objectLabel] == NO) {
												continue; // Skp this entry…
											}
										}

										return [object objectForKey:(__bridge id)kSecPropertyKeyValue];
									}
								}

								return nil;
							};

							id issuerInformation = getTopLevelObjectValue((__bridge NSDictionary *)(certificateProperties), kSecOIDX509V1IssuerName);
							id subjectInformation = getTopLevelObjectValue((__bridge NSDictionary *)(certificateProperties), kSecOIDX509V1SubjectName);

							if (issuerInformation == nil) {
								CFRelease(certificateProperties);

								return nil;
							}

							if (subjectInformation == nil) {
								CFRelease(certificateProperties);

								return nil;
							}

							NSString *issuerOrganization = getObjectValueForChild(issuerInformation, kSecOIDOrganizationName);

							NSString *subjectOrganization = getObjectValueForChild(subjectInformation, kSecOIDOrganizationName);
							NSString *subjectLocationCountry = getObjectValueForChild(subjectInformation, kSecOIDCountryName);
							NSString *subjectLocationState = getObjectValueForChild(subjectInformation, kSecOIDStateProvinceName);
							NSString *subjectLocationCity = getObjectValueForChild(subjectInformation, kSecOIDLocalityName);

							NSString *builtResult = nil;

							if (issuerOrganization &&
								subjectOrganization &&
								subjectLocationCountry &&
								subjectLocationState &&
								subjectLocationCity)
							{
								builtResult = TXTLS(@"BasicLanguage[1229][3]",
													issuerOrganization,
													subjectOrganization,
													subjectLocationCity,
													subjectLocationState,
													subjectLocationCountry);
							}

							CFRelease(certificateProperties);

							return builtResult;
						}

						CFRelease(certificateProperties); // Placed here to quiet analyzer
					}
				}
			}
		}
	}

	return nil;
}

- (NSString *)sslCertificateTrustPolicyName
{
	NSString *certificateHost = nil;

	SecTrustRef trustRef = [self sslCertificateTrustInformation];

	if (trustRef) {
		CFArrayRef trustPolicies = NULL;

		SecTrustCopyPolicies(trustRef, &trustPolicies);

		CFIndex trustPolicyCount = CFArrayGetCount(trustPolicies);

		for (CFIndex trustPolicyIndex = 0; trustPolicyIndex < trustPolicyCount; trustPolicyIndex++) {
			SecPolicyRef policy = (SecPolicyRef)CFArrayGetValueAtIndex(trustPolicies, trustPolicyIndex);

			CFDictionaryRef properties = SecPolicyCopyProperties(policy);

			if (properties) {
				if (CFGetTypeID(properties) == CFDictionaryGetTypeID()) {
					CFStringRef name = CFDictionaryGetValue(properties, kSecPolicyName);

					if (name) {
						if (CFGetTypeID(name) == CFStringGetTypeID()) {
							certificateHost = (__bridge NSString *)(name);
						}
					}
				}

				CFRelease(properties);
			}
		}
	}

	return certificateHost;
}

@end

@implementation AsyncSocket (RLMAsyncSocketExtensions)

+ (instancetype)socketWithDelegate:(id)delegate
{
	return [[self alloc] initWithDelegate:delegate];
}

- (void)useSSL
{
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];

	settings[(id)kCFStreamSSLLevel] = (id)kCFStreamSocketSecurityLevelNegotiatedSSL;

	settings[(id)kCFStreamSSLPeerName] = (id)kCFNull;
	
	settings[(id)kCFStreamSSLIsServer] = (id)kCFBooleanFalse;
	settings[(id)kCFStreamSSLValidatesCertificateChain] = (id)kCFBooleanFalse;

    CFReadStreamSetProperty(theReadStream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(settings));
    CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(settings));
}

- (void)useSystemSocksProxy
{
	CFDictionaryRef settings = SCDynamicStoreCopyProxies(NULL);

	CFNumberRef isEnabledRef = CFDictionaryGetValue(settings, (id)kSCPropNetProxiesSOCKSEnable);

	if (isEnabledRef && CFGetTypeID(isEnabledRef) == CFNumberGetTypeID()) {
		NSInteger isEnabledInt = 0;

		CFNumberGetValue(isEnabledRef, kCFNumberIntType, &isEnabledInt);

		if (isEnabledInt == 1) {
			if (CFDictionaryGetValueIfPresent(settings, (id)kCFStreamPropertySOCKSProxyHost, NULL)) {
				CFReadStreamSetProperty(theReadStream, kCFStreamPropertySOCKSProxy, settings);
				CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySOCKSProxy, settings);
			}
		}
	}

	CFRelease(settings);
}

- (void)useSocksProxyVersion:(IRCConnectionSocketProxyType)version address:(NSString *)address port:(NSInteger)port username:(NSString *)username password:(NSString *)password
{
	switch (version) {
		case IRCConnectionSocketSocks4ProxyType:
		case IRCConnectionSocketSocks5ProxyType:
		{
			NSMutableDictionary *settings = [NSMutableDictionary dictionary];

			if (version == IRCConnectionSocketSocks4ProxyType) {
				settings[(id)kCFStreamPropertySOCKSVersion] = (id)kCFStreamSocketSOCKSVersion4;
			} else {
				settings[(id)kCFStreamPropertySOCKSVersion] = (id)kCFStreamSocketSOCKSVersion5;
			}
			
			settings[(id)kCFStreamPropertySOCKSProxyHost] = address;
			settings[(id)kCFStreamPropertySOCKSProxyPort] = @(port);
			
			if (NSObjectIsNotEmpty(username)) {
				settings[(id)kCFStreamPropertySOCKSUser] = username;
			}
			
			if (NSObjectIsNotEmpty(password)) {
				settings[(id)kCFStreamPropertySOCKSPassword] = password;
			}
			
			CFReadStreamSetProperty(theReadStream, kCFStreamPropertySOCKSProxy, (__bridge CFTypeRef)(settings));
			CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySOCKSProxy, (__bridge CFTypeRef)(settings));
		}
		default:
		{
			break;
		}
	}
}

@end
