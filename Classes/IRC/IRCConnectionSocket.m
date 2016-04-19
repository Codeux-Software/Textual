/* *********************************************************************
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

/* A portion of this source file contains copyrighted work derived from one or more
 3rd-party, open source projects. The use of this work is hereby acknowledged. */

//
//  GCDAsyncProxySocket.m
//  OnionKit
//
//  Created by Christopher Ballinger on 11/19/13.
//  Copyright (c) 2013 ChatSecure. All rights reserved.
//

#import "TextualApplication.h"

#import "IRCConnectionPrivate.h"

#include <sys/socket.h>
#include <netinet/in.h>

#define SOCKS_PROXY_OPEN_TAG					10100
#define SOCKS_PROXY_CONNECT_TAG					10200
#define SOCKS_PROXY_CONNECT_REPLY_1_TAG			10300
#define SOCKS_PROXY_AUTH_USERPASS_TAG			10500

#define SOCKS_PROXY_READ_TIMEOUT			30.00

#define CONNECT_TIMEOUT						30.0

#define _httpHeaderResponseStatusRegularExpression		@"^HTTP\\/([1-2]{1})(\\.([0-2]{1}))?\\s([0-9]{3,4})\\s(.*)$"

NSString * const IRCConnectionSocketTorBrowserTypeProxyAddress = @"127.0.0.1";
NSInteger const IRCConnectionSocketTorBrowserTypeProxyPort = 9150;

@implementation IRCConnection (IRCConnectionSocket)

#pragma mark -
#pragma mark Grand Centeral Dispatch

- (void)destroyDispatchQueue
{
	self.dispatchQueue = NULL;

	self.socketQueue = NULL;
}

- (void)createDispatchQueue
{
	NSString *dispatchID = [NSString stringWithUUID];

	// A socket queue exists regardless of what library is in use.
	// This class reads on data on this queue just so the work is not passed to the main thread.
	NSString *dqname = [@"socketDispatchQueue." stringByAppendingString:dispatchID];

	self.dispatchQueue = dispatch_queue_create([dqname UTF8String], DISPATCH_QUEUE_SERIAL);

	// Create secondary queue incase we are using GCDAsyncSocket
	NSString *sqname = [@"socketReadWriteQueue." stringByAppendingString:dispatchID];

	self.socketQueue = dispatch_queue_create([sqname UTF8String], DISPATCH_QUEUE_SERIAL);
}

#pragma mark -
#pragma mark Open/Close Socket

- (void)openSocket
{
    [self createDispatchQueue];
	
	self.isConnecting = YES;

	self.socketConnection = [GCDAsyncSocket socketWithDelegate:self
												 delegateQueue:self.dispatchQueue
												   socketQueue:self.socketQueue];

	[self.socketConnection setIPv4PreferredOverIPv6:(self.connectionPrefersIPv6 == NO)];

	/* Attempt to connect using a configured proxy */
	BOOL connectedUsingProxy = NO;

	if ([self usesSocksProxy]) {
		NSString *proxyPopulateError = nil;

		if ([self socksProxyPopulateSystemSocksProxy:&proxyPopulateError] == NO) {
			if (proxyPopulateError) {
				LogToConsole(@"%@", proxyPopulateError);
			}
		} else {
			connectedUsingProxy = YES;

			[self tpcClientWillConnectToProxy:self.proxyAddress port:self.proxyPort];

			[self performConnectToHost:self.proxyAddress onPort:self.proxyPort];
		}
	}

	if (connectedUsingProxy == NO) {
		[self performConnectToHost:self.serverAddress onPort:self.serverPort];
	}
}

- (void)performConnectToHost:(NSString *)serverAddress onPort:(uint16_t)serverPort
{
	NSError *connError = nil;

	if ([self.socketConnection connectToHost:serverAddress
									  onPort:serverPort
								 withTimeout:CONNECT_TIMEOUT
									   error:&connError] == NO)
	{
		[self socketDidDisconnect:self.socketConnection withError:connError];
	}
}

- (void)closeSocket
{
	if ( self.socketConnection) {
		[self.socketConnection disconnect];
	}
}

- (void)closeSocketWithError:(NSString *)errorMessage
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];

	self.alternateDisconnectError = [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketOtherError userInfo:userInfo];

	[self closeSocket];
}

- (void)destroySocket
{
	[self tearDownQueuedCertificateTrustDialog];

	if ( self.socketConnection) {
		[self.socketConnection setDelegate:nil];
		 self.socketConnection = nil;
	}

	[self destroyDispatchQueue];

	self.alternateDisconnectError = nil;
	
	self.isConnectedWithClientSideCertificate = NO;
	
	self.isConnected = NO;
	self.isConnecting = NO;

	self.isSecured = NO;
}

- (void)tearDownQueuedCertificateTrustDialog
{
	[[TXSharedApplication sharedQueuedCertificateTrustPanel] dequeueEntryForSocket:self.socketConnection];
}

#pragma mark -
#pragma mark Socket Read & Write

- (void)writeDataToSocket:(NSData *)data
{
	if (self.isConnected) {
		[self.socketConnection writeData:data withTimeout:(-1) tag:0];
	}
}

- (void)waitForData
{
	if (self.isConnected) {
		[self.socketConnection readDataToData:[GCDAsyncSocket LFData] withTimeout:(-1) tag:0];
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)connectedAddress
{
	if ([self socksProxyInUse]) {
		return nil;
	} else {
		return [self.socketConnection connectedHost];
	}
}

- (NSArray *)clientSideCertificateForAuthentication
{
	NSData *localCertData = self.identityClientSideCertificate;

	id returnValue = nil;

	if (localCertData) {
		SecKeychainItemRef cert;

		CFDataRef rawCertData = (__bridge CFDataRef)(localCertData);

		OSStatus status = SecKeychainItemCopyFromPersistentReference(rawCertData, &cert);

		if (status == noErr) {
			SecIdentityRef identity;

			status = SecIdentityCreateWithCertificate(NULL, (SecCertificateRef)cert, &identity);

			if (status == noErr) {
				returnValue = @[(__bridge id)identity, (__bridge id)cert];

				CFRelease(identity);
			} else {
				LogToConsole(@"User supplied client-side certificate produced an error trying to read it: %i (#2)", status);
			}

			CFRelease(cert);
		} else {
			LogToConsole(@"User supplied client-side certificate produced an error trying to read it: %i (#1)", status);
		}
	}

	return returnValue;
}

#pragma mark -
#pragma mark Primary Socket Delegate

- (void)socket:(id)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
	if (self.connectionShouldValidateCertificateChain == NO) {
		completionHandler(YES);
	} else {
		SecTrustResultType result;

		OSStatus trustEvalStatus = SecTrustEvaluate(trust, &result);

		if (trustEvalStatus == errSecSuccess)
		{
			if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
				completionHandler(YES);
			} else if (result == kSecTrustResultRecoverableTrustFailure) {
				[[TXSharedApplication sharedQueuedCertificateTrustPanel] enqueue:self.socketConnection withCompletionBlock:completionHandler];
			} else {
				completionHandler(NO);
			}
		}
		else
		{
			completionHandler(NO);
		}
	}
}

- (void)maybeBeginTLSNegotation
{
	if (self.connectionPrefersSecuredConnection) {
		NSMutableDictionary *settings = [NSMutableDictionary dictionary];

		settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);

		settings[GCDAsyncSocketSSLProtocolVersionMin] = @(kTLSProtocol1);

		settings[(id)kCFStreamSSLIsServer] = (id)kCFBooleanFalse;

		settings[(id)kCFStreamSSLPeerName] = (id)self.serverAddress;

		NSArray *localCertData = [self clientSideCertificateForAuthentication];

		if (localCertData) {
			settings[(id)kCFStreamSSLCertificates] = (id)localCertData;
		}

		if (self.connectionPrefersModernCiphers) {
			settings[GCDAsyncSocketSSLCipherSuites] = [GCDAsyncSocket cipherList];
		}

		[self.socketConnection startTLS:settings];
	}
}

- (void)onSocketConnectedToHost
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self maybeBeginTLSNegotation];

		self.isConnecting = NO;
		self.isConnected = YES;

		[self waitForData];

		[self tcpClientDidConnect];
	});
}

- (void)socket:(id)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	if ([self socksProxyInUse]) {
		[self socksProxyOpen];
	} else {
		[self onSocketConnectedToHost];
	}
}

- (void)_socketDidDisconnect:(id)sock withError:(NSError *)error
{
	[self closeSocket];

	[self destroySocket];

	[self tcpClientDidDisconnect:error];
}

- (void)socketDidDisconnect:(id)sock withError:(NSError *)error
{
	if (error == nil && self.alternateDisconnectError) {
		error =         self.alternateDisconnectError;
	}

	if (error == nil || [error code] == errSSLClosedGraceful) {
		[self _socketDidDisconnect:sock withError:nil];
	} else {
		NSString *errorMessage = nil;

		if (error) {
			if ([[error domain] isEqualToString:NSPOSIXErrorDomain]) {
				errorMessage = [GCDAsyncSocket posixErrorStringFromError:[error code]];
			} else if ([[error domain] isEqualToString:@"kCFStreamErrorDomainSSL"]) {
				errorMessage = [GCDAsyncSocket sslHandshakeErrorStringFromError:[error code]];

				if ([GCDAsyncSocket badSSLCertificateErrorFound:error]) {
					[self tcpClientDidReceivedAnInsecureCertificate];
				}
			}

			if (NSObjectIsEmpty(errorMessage)) {
				errorMessage = [error localizedDescription];
			}

			[self tcpClientDidError:errorMessage];
		}

		[self _socketDidDisconnect:sock withError:error];
	}
}

- (void)completeReadForNormalData:(NSData *)data
{
	id readData = data;

	NSUInteger readDataTrimLength = 0;

	if ([data hasSuffixBytes:"\x0D\x0A" length:2]) {
		readDataTrimLength = 2;
	} else if ([data hasSuffixBytes:"\x0D" length:1]) {
		readDataTrimLength = 1;
	} else if ([data hasSuffixBytes:"\x0A" length:1]) {
		readDataTrimLength = 1;
	}

	if (readDataTrimLength > 0) {
		NSMutableData *mutableReadData = [readData mutableCopy];

		[mutableReadData setLength:([mutableReadData length] - readDataTrimLength)];

		readData = mutableReadData;
	}

	NSString *sdata = [self convertFromCommonEncoding:readData];

	if (sdata == nil) {
		return;
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self tcpClientDidReceiveData:sdata];
	});
}

- (void)didReadNormalData:(NSData *)data
{
	[self completeReadForNormalData:data];

	[self waitForData];
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([self socksProxyInUse]) {
		if ([self socksProxyDidReadData:data withTag:tag] == NO) {
			[self didReadNormalData:data];
		}
	} else {
		[self didReadNormalData:data];
	}
}

- (void)socket:(id)sock didWriteDataWithTag:(long)tag
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self tcpClientDidSendData];
	});
}

- (void)socketDidSecure:(id)sock
{
	self.isSecured = YES;

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self tcpClientDidSecureConnection];
	});
}

#pragma mark -
#pragma mark SSL Certificate Trust Message

- (NSString *)localizedSecureConnectionProtocolString
{
	return [self localizedSecureConnectionProtocolString:YES];
}

- (NSString *)localizedSecureConnectionProtocolString:(BOOL)plainText
{
	NSString *protocol = [self.socketConnection sslNegotiatedProtocolString];

	NSString *cipher = [self.socketConnection sslNegotiatedCipherSuiteString];

	BOOL cipherDeprecated = [self.socketConnection sslConnectedWithDeprecatedCipher];

	if (plainText && cipherDeprecated) {
		return TXTLS(@"BasicLanguage[1289]", protocol, cipher);
	} else if (plainText && cipherDeprecated == NO) {
		return TXTLS(@"BasicLanguage[1288]", protocol, cipher);
	} else if (plainText == NO && cipherDeprecated) {
		return TXTLS(@"BasicLanguage[1250]", protocol, cipher);
	} else {
		return TXTLS(@"BasicLanguage[1248]", protocol, cipher);
	}
}

- (void)openSSLCertificateTrustDialog
{
	SecTrustRef trust = [self.socketConnection sslCertificateTrustInformation];

	PointerIsEmptyAssert(trust);

	NSString *protocolString = [self localizedSecureConnectionProtocolString:YES];

	NSString *policyName = [self.socketConnection sslCertificateTrustPolicyName];

	SFCertificateTrustPanel *panel = [SFCertificateTrustPanel new];

	[panel setDefaultButtonTitle:TXTLS(@"BasicLanguage[1011]")];
	[panel setAlternateButtonTitle:nil];

	if (protocolString == nil) {
		[panel setInformativeText:TXTLS(@"BasicLanguage[1247][2]", policyName)];
	} else {
		[panel setInformativeText:TXTLS(@"BasicLanguage[1247][3]", policyName, protocolString)];
	}

	[panel beginSheetForWindow:[NSApp mainWindow]
				 modalDelegate:nil
				didEndSelector:NULL
				   contextInfo:NULL
						 trust:trust
					   message:TXTLS(@"BasicLanguage[1247][1]", policyName)];
}

#pragma mark -
#pragma mark SOCKS Proxy Support

- (BOOL)usesSocksProxy
{
	return (	self.proxyType == IRCConnectionSocketSystemSocksProxyType	||
				self.proxyType == IRCConnectionSocketSocks4ProxyType		||
				self.proxyType == IRCConnectionSocketSocks5ProxyType		||
				self.proxyType == IRCConnectionSocketHTTPProxyType			||
				self.proxyType == IRCConnectionSocketTorBrowserType);
}

- (BOOL)socksProxyInUse
{
	return (self.proxyType == IRCConnectionSocketSocks4ProxyType ||
			self.proxyType == IRCConnectionSocketSocks5ProxyType ||
			self.proxyType == IRCConnectionSocketHTTPProxyType);
}

- (BOOL)socksProxyCanAuthenticate
{
	return (NSObjectIsNotEmpty(self.proxyUsername) &&
			NSObjectIsNotEmpty(self.proxyPassword));
}

- (BOOL)socksProxyPopulateSystemSocksProxy:(NSString **)errorString
{
	if (self.proxyType == IRCConnectionSocketSystemSocksProxyType)
	{
		NSDictionary *settings = (__bridge_transfer NSDictionary *)(SCDynamicStoreCopyProxies(NULL));

		if ([settings boolForKey:@"SOCKSEnable"]) {
			id socksProxyHost = [settings objectForKey:@"SOCKSProxy"];
			id socksProxyPort = [settings objectForKey:@"SOCKSPort"];

			id socksProxyUsername = [settings objectForKey:@"SOCKSUser"];
			id socksProxyPassword = nil;

			if (socksProxyHost && socksProxyPort) {
				/* Search keychain for a password related to this SOCKS proxy */
				if (socksProxyUsername) {
					NSDictionary *keychainSearchDict = @{
						(id)kSecClass : (id)kSecClassInternetPassword,
						(id)kSecAttrServer : socksProxyHost,
						(id)kSecAttrProtocol : (id)kSecAttrProtocolSOCKS,
						(id)kSecReturnData : (id)kCFBooleanTrue,
						(id)kSecMatchLimit : (id)kSecMatchLimitOne
					};

					CFDataRef result = nil;

					OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainSearchDict, (CFTypeRef *)&result);

					if (status == noErr) {
						NSData *passwordData = (__bridge_transfer NSData *)result;

						if (NSObjectIsEmpty(passwordData) == NO) {
							socksProxyPassword = [NSString stringWithData:passwordData encoding:NSUTF8StringEncoding];
						}
					} else {
						*errorString = @"SOCKS Error: Textual encountered a problem trying to retrieve the SOCKS proxy password from System Preferences";

						return NO;
					}
				}

				/* Assign results to the local keys */
				self.proxyAddress = socksProxyHost;
				self.proxyPort = [socksProxyPort integerValue];

				self.proxyType = IRCConnectionSocketSocks5ProxyType;
				
				self.proxyUsername = socksProxyUsername;
				self.proxyPassword = socksProxyPassword;

				return YES; // Successful result
			}
		}

		return NO; // Tell caller that this request failed
	}
	else if (self.proxyType == IRCConnectionSocketTorBrowserType)
	{
		self.proxyType = IRCConnectionSocketSocks5ProxyType;

		self.proxyAddress = IRCConnectionSocketTorBrowserTypeProxyAddress;
		self.proxyPort = IRCConnectionSocketTorBrowserTypeProxyPort;

		self.proxyUsername = nil;
		self.proxyPassword = nil;

		return YES; // Successful result
	}
	else
	{
		return YES;
	}
}

- (void)socksProxyOpen
{
	if (self.proxyType == IRCConnectionSocketSocks4ProxyType) {
		[self socks4ProxyOpen];
	} else if (self.proxyType == IRCConnectionSocketSocks5ProxyType) {
		[self socks5ProxyOpen];
	} else if (self.proxyType == IRCConnectionSocketHTTPProxyType) {
		[self httpProxyOpen];
	}
}

- (BOOL)socksProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (self.proxyType == IRCConnectionSocketSocks4ProxyType) {
		return [self socks4ProxyDidReadData:data withTag:tag];
	} else if (self.proxyType == IRCConnectionSocketSocks5ProxyType) {
		return [self socks5ProxyDidReadData:data withTag:tag];
	} else if (self.proxyType == IRCConnectionSocketHTTPProxyType) {
		return [self httpProxyDidReadData:data withTag:tag];
	} else {
		return NO;
	}
}

- (void)httpProxyOpen
{
	/* Build connect command that will be sent to the HTTP server */
	NSString *connectionAddress = self.serverAddress;

	NSUInteger connectionPort = self.serverPort;

	NSString *combinedDestinationAddress = nil;

	if ([connectionAddress isIPv6Address]) {
		combinedDestinationAddress = [NSString stringWithFormat:@"[%@]:%lu", connectionAddress, connectionPort];
	} else {
		combinedDestinationAddress = [NSString stringWithFormat:@"%@:%lu", connectionAddress, connectionPort];
	}

	NSString *connectCommand = [NSString stringWithFormat:@"CONNECT %@ HTTP/1.1\x0d\x0a\x0d\x0a", combinedDestinationAddress];

	/* Pass the data along to the HTTP server */
	NSData *connectCommandData = [connectCommand dataUsingEncoding:NSASCIIStringEncoding];

	[self.socketConnection writeData:connectCommandData withTimeout:(-1) tag:SOCKS_PROXY_OPEN_TAG];

	/* Read until the end of the HTTP header response */
	NSData *responseTerminatorData = [@"\x0d\x0a\x0d\x0a" dataUsingEncoding:NSASCIIStringEncoding];

	[self.socketConnection readDataToData:responseTerminatorData withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_OPEN_TAG];
}

- (BOOL)httpProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (tag == SOCKS_PROXY_OPEN_TAG) {
		/* Given data, turn it into string and perform basic validation */
		NSString *dataAsString = [NSString stringWithData:data encoding:NSUTF8StringEncoding];

		NSArray *headerComponents = [dataAsString componentsSeparatedByString:@"\x0d\x0a"];

		if ([headerComponents count] <= 2) {
			[self closeSocketWithError:@"HTTP Error: Server responded with a malformed packet"];

			return YES; // Tell caller we handled the data...
		}

		/* Try our best to extract the status code from the response */
		NSString *statusResponse = headerComponents[0];

		// It is possible to split the response into its components using
		// the space character but by using regular expression we are not
		// only getting the components, we are also validating its format.
		NSRange statusResponseRegexRange = NSMakeRange(0, [statusResponse length]);

		NSRegularExpression *statusResponseRegex = [NSRegularExpression regularExpressionWithPattern:_httpHeaderResponseStatusRegularExpression options:0 error:NULL];

		NSTextCheckingResult *statusResponseRegexResult = [statusResponseRegex firstMatchInString:statusResponse options:0 range:statusResponseRegexRange];

		if ([statusResponseRegexResult numberOfRanges] == 6) {
			//
			// Index values:
			//
			// Complete Line		(0): HTTP/1.1 200 Connection established
			// Major Version		(1): 1
			// Minor Version		(2): .1
			// Minor Version		(3): 1
			// Status Code			(4): 200
			// Status Message		(5): Connection established
			//

			NSRange statusCodeRange = [statusResponseRegexResult rangeAtIndex:4];
			NSRange statusMessageRange = [statusResponseRegexResult rangeAtIndex:5];

			NSString *statusCode = [statusResponse substringWithRange:statusCodeRange];
			NSString *statusMessage = [statusResponse substringWithRange:statusMessageRange];

			if ([statusCode integerValue] == 200) {
				[self onSocketConnectedToHost];
			} else {
				NSString *errorMessage = [NSString stringWithFormat:@"HTTP Error: HTTP proxy server returned status code %@ with the message “%@“", statusCode, statusMessage];

				[self closeSocketWithError:errorMessage];
			}

			return YES;
		} else {
			[self closeSocketWithError:@"HTTP Error: Server responded with a malformed packet"];

			return YES; // Tell caller we handled the data...
		}

#undef _httpHeaderResponseStatusRegularExpression
	}
	else
	{
		return NO;
	}
}

- (NSString *)socks4ProxyResolvedAddress
{
	/* SOCKS4 proxies do not support anything other than IPv4 addresses 
	 (unless you support SOCKS4a, which Textual does not) which means we
	 perform manual DNS lookup for SOCKS4 and rely on end-point proxy to
	 perform lookup when using other proxy types. */

	NSData *resolvedAddress4 = nil;

	NSArray *resolvedAddresses = [GCDAsyncSocket lookupHost:self.serverAddress port:self.serverPort error:NULL];

	for (NSData *address in resolvedAddresses) {
		if (resolvedAddress4 == nil && [GCDAsyncSocket isIPv4Address:address]) {
			resolvedAddress4 = address;
		}
	}

	if (resolvedAddress4) {
		return [GCDAsyncSocket hostFromAddress:resolvedAddress4];
	}

	return nil;
}

- (void)socks4ProxyOpen
{
	[self socksProxyConnect];
}

- (void)socks5ProxyOpen
{
	[self socks5ProxySendGreeting];
}

- (void)socksProxyConnect
{
	//
	// Packet layout for SOCKS4 connect:
	//
	// 	    +----+----+---------+-------------------+---------+....+----+
	// NAME | VN | CD | DSTPORT |      DSTIP        | USERID       |NULL|
	//      +----+----+---------+-------------------+---------+....+----+
	// SIZE	   1    1      2              4           variable       1
	//
	// ---------------------------------------------------------------------------
	//
	// Packet layout for SOCKS5 connect:
	//
	//      +-----+-----+-----+------+------+------+
	// NAME | VER | CMD | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//

	BOOL isVersion4Socks = (self.proxyType == IRCConnectionSocketSocks4ProxyType);

	NSString *connectionAddress = nil;

	if (isVersion4Socks) {
		connectionAddress = [self socks4ProxyResolvedAddress];
	} else {
		connectionAddress = self.serverAddress;
	}

	NSData *connectionAddressBytes4 = [connectionAddress IPv4AddressBytes];
	NSData *connectionAddressBytes6 = [connectionAddress IPv6AddressBytes];

	uint16_t connectionPort = htons(self.serverPort);

	/* Assemble the packet of data that will be sent */
	NSMutableData *packetData = [NSMutableData data];

	/* SOCKS version to use */
	if (isVersion4Socks) {
		[packetData appendBytes:"\x04" length:1];
	} else {
		[packetData appendBytes:"\x05" length:1];
	}

	/* Type of connection (the command) */
	[packetData appendBytes:"\x01" length:1];

	/* Reserved value that must be 0 for SOCKS5 */
	if (isVersion4Socks == NO) {
		[packetData appendBytes:"\x00" length:1];
	}

	/* The address type for our destination */
	if (isVersion4Socks == NO) {
		if (connectionAddressBytes6) {
			[packetData appendBytes:"\x04" length:1];
		} else if (connectionAddressBytes4) {
			[packetData appendBytes:"\x01" length:1];
		} else {
			[packetData appendBytes:"\x03" length:1];
		}
	}

	if (isVersion4Socks) {
		if (connectionAddressBytes4 == nil) {
			[self closeSocketWithError:@"Error: SOCKS 4 proxies only support IPv4 addresses"];

			return;
		} else {
			[packetData appendBytes:&connectionPort length:2];

			[packetData appendData:connectionAddressBytes4];

			[packetData appendBytes:"\x00" length:1];
		}
	}
	else // isVersion4Socks
	{
		if (connectionAddressBytes6) {
			[packetData appendData:connectionAddressBytes6];
		} else if (connectionAddressBytes4) {
			[packetData appendData:connectionAddressBytes4];
		} else {
			NSData *connectionAddressBytes = [connectionAddress dataUsingEncoding:NSASCIIStringEncoding];

			NSInteger connectionAddressLength = [connectionAddressBytes length];

			[packetData appendBytes:&connectionAddressLength length:1];

			[packetData appendBytes:[connectionAddressBytes bytes] length:connectionAddressLength];
		}

		[packetData appendBytes:&connectionPort length:2];
	}

	/* Write the packet to the socket */
	[self.socketConnection writeData:packetData withTimeout:(-1) tag:SOCKS_PROXY_CONNECT_TAG];

	//
	// Packet layout for SOCKS4 connect response:
	//
	//	    +----+----+----+----+----+----+----+----+
	// NAME | VN | CD | DSTPORT |      DSTIP        |
	//      +----+----+----+----+----+----+----+----+
	// SIZE    1    1      2              4
	//
	// Packet layout for SOCKS5 connect response:
	//
	//      +-----+-----+-----+------+------+------+
	// NAME | VER | REP | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//

	/* Wait for a response from the SOCKS server */
	[self.socketConnection readDataWithTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_1_TAG];
}

- (BOOL)socks4ProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (tag == SOCKS_PROXY_CONNECT_REPLY_1_TAG)
	{
		if (NSDissimilarObjects([data length], 8)) {
			[self closeSocketWithError:@"SOCKS4 Error: Server responded with a malformed packet"];

			return YES; // Tell caller we handled the data...
		}

		uint8_t *bytes = (uint8_t*)[data bytes];

		uint8_t rep = bytes[1];

		if (rep == 0x5a) {
			[self onSocketConnectedToHost];
		} else if (rep == 0x5b) {
			[self closeSocketWithError:@"SOCKS4 Error: Request rejected or failed"];
		} else if (rep == 0x5c) {
			[self closeSocketWithError:@"SOCKS4 Error: Request failed because client is not running an identd (or not reachable from server)"];
		} else if (rep == 0x5d) {
			[self closeSocketWithError:@"SOCKS4 Error: Request failed because client's identd could not confirm the user ID string in the request"];
		} else {
			[self closeSocketWithError:@"SOCKS4 Error: Server replied with unknown status code"];
		}

		return YES;
	}
	else
	{
		return NO;
	}
}

- (BOOL)socks5ProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (tag == SOCKS_PROXY_OPEN_TAG)
	{
		if (NSDissimilarObjects([data length], 2)) {
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];

			return YES; // Tell caller we handled the data...
		}

		uint8_t *bytes = (uint8_t *)[data bytes];

		uint8_t version = bytes[0];
		uint8_t method = bytes[1];

		if (version == 5) {
			if (method == 0)
			{
				[self socksProxyConnect];
			}
			else if (method == 2)
			{
				if ([self socksProxyCanAuthenticate]) {
					[self socks5ProxyUserPassAuth];
				} else {
					[self closeSocketWithError:@"SOCKS5 Error: Server requested that we authenticate but a username and/or password is not configured"];
				}
			}
			else
			{
				[self closeSocketWithError:@"SOCKS5 Error: Server requested authentication method that is not supported"];
			}
		} else {
			[self closeSocketWithError:@"SOCKS5 Error: Server greeting reply contained incorrect version number"];
		}

		return YES;
	}
	else if (tag == SOCKS_PROXY_CONNECT_REPLY_1_TAG)
	{
		if ([data length] <= 8) { // first 4 bytes + 2 for port
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];

			return YES; // Tell caller we handled the data...
		}

		uint8_t *bytes = (uint8_t *)[data bytes];

		uint8_t ver = bytes[0];
		uint8_t rep = bytes[1];

		if (ver == 5 && rep == 0)
		{
			[self onSocketConnectedToHost];
		}
		else
		{
#define _dr(cda, reason)			cda: { failureReason = (reason); break; }

			NSString *failureReason = nil;
			
			switch (rep) {
				_dr(case 1,  @"SOCKS5 Error: General SOCKS server failure")
				_dr(case 2,  @"SOCKS5 Error: Connection not allowed by ruleset")
				_dr(case 3,  @"SOCKS5 Error: Network unreachable")
				_dr(case 4,  @"SOCKS5 Error: Host unreachable")
				_dr(case 5,  @"SOCKS5 Error: Connection refused")
				_dr(case 6,  @"SOCKS5 Error: Time to live (TTL) expired")
				_dr(case 7,  @"SOCKS5 Error: Command not supported")
				_dr(case 8,  @"SOCKS5 Error: Address type not supported")
				_dr(default, @"SOCKS5 Error: Unknown SOCKS error")
			}

			[self closeSocketWithError:failureReason];
#undef _dr
		}

		return YES;
	}
	else if (tag == SOCKS_PROXY_AUTH_USERPASS_TAG)
	{
		/*
		 Server response for username/password authentication:

		 field 1: version, 1 byte
		 field 2: status code, 1 byte.
		 0x00 = success
		 any other value = failure, connection must be closed
		 */

		if ([data length] == 2) {
			uint8_t *bytes = (uint8_t *)[data bytes];

			uint8_t status = bytes[1];

			if (status == 0x00) {
				[self socksProxyConnect];
			} else {
				[self closeSocketWithError:@"SOCKS5 Error: Authentication failed for unknown reason"];
			}
		} else {
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];
		}

		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)socks5ProxySendGreeting
{
	//
	// Packet layout for SOCKS5 greeting:
	//
	//      +-----+-----------+---------+
	// NAME | VER | NMETHODS  | METHODS |
	//      +-----+-----------+---------+
	// SIZE |  1  |    1      | 1 - 255 |
	//      +-----+-----------+---------+
	//

	/* Assemble the packet of data that will be sent */
	NSData *packetData = nil;

	if ([self socksProxyCanAuthenticate] == NO) {
		/* Send instructions that we are asking for version 5 of the SOCKS protocol
		 with one authentication method: anonymous access */

		packetData = [NSData dataWithBytes:"\x05\x01\x00" length:3];
	} else {
		/* Send instructions that we are asking for version 5 of the SOCKS protocol 
		 with two authentication methods: anonymous access and password based. */

		packetData = [NSData dataWithBytes:"\x05\x02\x00\x02" length:4];
	}

	/* Write the packet to the socket */
	[self.socketConnection writeData:packetData withTimeout:(-1) tag:SOCKS_PROXY_OPEN_TAG];

	//
	// Packet layout for SOCKS5 greeting response:
	//
	//      +-----+--------+
	// NAME | VER | METHOD |
	//      +-----+--------+
	// SIZE |  1  |   1    |
	//      +-----+--------+
	//

	/* Wait for a response from the SOCKS server */
	[self.socketConnection readDataWithTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_OPEN_TAG];
}

/*
 For username/password authentication the client's authentication request is

 field 1: version number, 1 byte (must be 0x01)
 field 2: username length, 1 byte
 field 3: username
 field 4: password length, 1 byte
 field 5: password
 */

- (void)socks5ProxyUserPassAuth
{
	/* Assemble the packet of data that will be sent */
	NSData *usernameData = [self.proxyUsername dataUsingEncoding:NSUTF8StringEncoding];
	NSData *passwordData = [self.proxyPassword dataUsingEncoding:NSUTF8StringEncoding];

	uint8_t usernameLength = (uint8_t)[usernameData length];
	uint8_t passwordLength = (uint8_t)[passwordData length];

	NSMutableData *authData = [NSMutableData dataWithCapacity:(1 + 1 + usernameLength + 1 + passwordLength)];

	[authData appendBytes:"\x01" length:1];
	[authData appendBytes:&usernameLength length:1];
	[authData appendBytes:[usernameData bytes] length:usernameLength];
	[authData appendBytes:&passwordLength length:1];
	[authData appendBytes:[passwordData bytes] length:passwordLength];

	/* Write the packet to the socket */
	[self.socketConnection writeData:authData withTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];

	/* Wait for a response from the SOCKS server */
	[self.socketConnection readDataWithTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];
}

@end
