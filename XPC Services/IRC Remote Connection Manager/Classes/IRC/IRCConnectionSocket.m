/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
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

#include <sys/socket.h>
#include <netinet/in.h>

NS_ASSUME_NONNULL_BEGIN

#define SOCKS_PROXY_OPEN_TAG					10100
#define SOCKS_PROXY_CONNECT_TAG					10200
#define SOCKS_PROXY_CONNECT_REPLY_1_TAG			10300
#define SOCKS_PROXY_AUTH_USERPASS_TAG			10500

#define SOCKS_PROXY_READ_TIMEOUT			30.00

#define CONNECT_TIMEOUT						30.0

#define _httpHeaderResponseStatusRegularExpression		@"^HTTP\\/([1-2]{1})(\\.([0-2]{1}))?\\s([0-9]{3,4})\\s(.*)$"

NSString * const IRCConnectionSocketTorBrowserTypeProxyAddress = @"127.0.0.1";
NSInteger const IRCConnectionSocketTorBrowserTypeProxyPort = 9150;

@interface IRCConnection ()
@property (readonly) BOOL usesSocksProxy;
@property (readonly) BOOL socksProxyInUse;
@property (readonly) BOOL socksProxyCanAuthenticate;
@end

@implementation IRCConnection (IRCConnectionSocket)

#pragma mark -
#pragma mark Grand Centeral Dispatch

- (void)destroySocketDispatchQueue
{
	self.socketDelegateQueue = NULL;

	self.socketReadWriteQueue = NULL;
}

- (void)createSocketDispatchQueue
{
	NSString *socketDelegateQueueName =
	[@"Textual.IRCConnection.socketDelegateQueue." stringByAppendingString:self.uniqueIdentifier];

	self.socketDelegateQueue =
	XRCreateDispatchQueueWithPriority(socketDelegateQueueName.UTF8String, DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT);

	NSString *socketReadWriteQueueName =
	[@"Textual.IRCConnection.socketReadWriteQueue." stringByAppendingString:self.uniqueIdentifier];

	self.socketReadWriteQueue =
	XRCreateDispatchQueueWithPriority(socketReadWriteQueueName.UTF8String, DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT);
}

#pragma mark -
#pragma mark Open/Close Socket

- (void)openSocket
{
	[self createSocketDispatchQueue];

	self.isConnecting = YES;

	self.socketConnection = [GCDAsyncSocket socketWithDelegate:self
												 delegateQueue:self.socketDelegateQueue
												   socketQueue:self.socketReadWriteQueue];

//	self.socketConnection.autoDisconnectOnClosedReadStream = NO;

	self.socketConnection.useStrictTimers = YES;

	self.socketConnection.IPv4PreferredOverIPv6 = self.config.connectionPrefersIPv4;

	/* Attempt to connect using a configured proxy */
	if (self.usesSocksProxy) {
		NSString *proxyPopulateError = nil;

		if ([self socksProxyPopulateSystemSocksProxy:&proxyPopulateError] == NO) {
			if (proxyPopulateError) {
				LogToConsoleError("%@", proxyPopulateError);
			}
		} else {
			[self tpcClientWillConnectToProxy:self.config.proxyAddress port:self.config.proxyPort];

			[self performConnectToHost:self.config.proxyAddress onPort:self.config.proxyPort];

			return;
		}
	}

	[self performConnectToHost:self.config.serverAddress onPort:self.config.serverPort];
}

- (void)performConnectToHost:(NSString *)serverAddress onPort:(uint16_t)serverPort
{
	NSParameterAssert(serverAddress != nil);
	NSParameterAssert(serverPort > 0);

	NSError *connectError = nil;

	BOOL connectResult =
	[self.socketConnection connectToHost:serverAddress
								  onPort:serverPort
							 withTimeout:CONNECT_TIMEOUT
								   error:&connectError];

	if (connectResult == NO) {
		[self socketDidDisconnect:self.socketConnection withError:connectError];
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
	NSParameterAssert(errorMessage != nil);

	NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorMessage};

	self.alternateDisconnectError = [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketOtherError userInfo:userInfo];

	[self closeSocket];
}

- (void)destroySocket
{
	self.socketConnection = nil;

	[self destroySocketDispatchQueue];

	self.alternateDisconnectError = nil;

	self.isConnectedWithClientSideCertificate = NO;

	self.isConnected = NO;
	self.isConnecting = NO;

	self.isSecured = NO;
}

#pragma mark -
#pragma mark Socket Read & Write

- (void)writeDataToSocket:(NSData *)data
{
	NSParameterAssert(data != nil);

	if (self.isConnected == NO) {
		return;
	}

	[self.socketConnection writeData:data withTimeout:(-1) tag:0];
}

- (void)waitForData
{
	if (self.isConnected == NO) {
		return;
	}

	[self.socketConnection readDataToData:[GCDAsyncSocket LFData]
							  withTimeout:(-1)
								maxLength:(1000 * 1000 * 100) // 100 megabytes
									  tag:0];
}

#pragma mark -
#pragma mark Properties

- (nullable NSString *)connectedAddress
{
	if (self.socksProxyInUse) {
		return nil;
	}

	return self.socketConnection.connectedHost;
}

- (NSArray *)clientSideCertificateForAuthentication
{
	NSData *certificateDataIn = self.config.identityClientSideCertificate;

	if (certificateDataIn == nil) {
		return @[];
	}

	/* ====================================== */

	SecKeychainItemRef certificateRef;

	CFDataRef certificateDataInRef = (__bridge CFDataRef)certificateDataIn;

	OSStatus status = SecKeychainItemCopyFromPersistentReference(certificateDataInRef, &certificateRef);

	if (status != noErr) {
		LogToConsoleError("Operation Failed (1): %i", status);

		return @[];
	}

	/* ====================================== */

	SecIdentityRef identityRef;

	status = SecIdentityCreateWithCertificate(NULL, (SecCertificateRef)certificateRef, &identityRef);

	if (status != noErr) {
		CFRelease(certificateRef);

		LogToConsoleError("Operation Failed (2): %i", status);

		return @[];
	}

	/* ====================================== */

	NSArray *returnValue = @[(__bridge id)identityRef, (__bridge id)certificateRef];

	CFRelease(identityRef);
	CFRelease(certificateRef);

	return returnValue;
}

#pragma mark -
#pragma mark Primary Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
	if (self.config.connectionShouldValidateCertificateChain == NO) {
		completionHandler(YES);

		return;
	}

	SecTrustResultType evaluationResult;

	OSStatus evaluationStatus = SecTrustEvaluate(trust, &evaluationResult);

	if (evaluationStatus == errSecSuccess) {
		if (evaluationResult == kSecTrustResultUnspecified || evaluationResult == kSecTrustResultProceed) {
			completionHandler(YES);

			return;
		} else if (evaluationResult == kSecTrustResultRecoverableTrustFailure) {
			[self tcpClientRequestInsecureCertificateTrust:completionHandler];

			return;
		}
	}

	completionHandler(NO);
}

- (void)maybeBeginTLSNegotiation
{
	if (self.config.connectionPrefersSecuredConnection == NO) {
		return;
	}

	NSMutableDictionary *settings = [NSMutableDictionary dictionary];

	settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);

	if (self.config.cipherSuites != GCDAsyncSocketCipherSuiteNonePreferred) {
		settings[GCDAsyncSocketSSLCipherSuites] =
		[GCDAsyncSocket cipherListOfVersion:self.config.cipherSuites
				   includeDeprecatedCiphers:self.config.connectionPrefersModernCiphersOnly];
	}

	settings[GCDAsyncSocketSSLProtocolVersionMin] = @(kTLSProtocol1);

	settings[(id)kCFStreamSSLIsServer] = (id)kCFBooleanFalse;

	settings[(id)kCFStreamSSLPeerName] = (id)self.config.serverAddress;

	NSArray *clientSideCertificate = [self clientSideCertificateForAuthentication];

	if (clientSideCertificate.count > 0) {
		settings[(id)kCFStreamSSLCertificates] = (id)clientSideCertificate;

		self.isConnectedWithClientSideCertificate = YES;
	}

	[self.socketConnection startTLS:settings];
}

- (void)onSocketConnectedToHost
{
	[self maybeBeginTLSNegotiation];

	self.isConnecting = NO;
	self.isConnected = YES;

	[self waitForData];

	[self tcpClientDidConnectToHost:self.connectedAddress];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	if (self.socksProxyInUse) {
		[self socksProxyOpen];

		return;
	}

	[self onSocketConnectedToHost];
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock
{
	[self tcpClientDidCloseReadStream];
}

- (void)_socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)error
{
	[self destroySocket];

	[self tcpClientDidDisconnect:error];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)error
{
	if (error == nil) {
		error = self.alternateDisconnectError;
	}

	if (error == nil || error.code == errSSLClosedGraceful) {
		[self _socketDidDisconnect:sock withError:nil];

		return;
	}

	NSString *errorMessage = nil;

	if ([GCDAsyncSocket isBadSSLCertificateError:error]) {
		errorMessage = [GCDAsyncSocket sslHandshakeErrorStringFromError:error.code];
	}

	if (errorMessage == nil) {
		errorMessage = error.localizedDescription;
	}

	LogToConsoleInfo("Disconnect failure reason: %", error.localizedFailureReason);

	[self tcpClientDidError:errorMessage];

	[self _socketDidDisconnect:sock withError:error];
}

- (void)completeReadForNormalData:(NSData *)data
{
	NSData *readData = data;

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

		mutableReadData.length = (mutableReadData.length - readDataTrimLength);

		readData = [mutableReadData copy];
	}

	[self tcpClientDidReceiveData:readData];
}

- (void)didReadNormalData:(NSData *)data
{
	[self completeReadForNormalData:data];

	[self waitForData];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if (self.socksProxyInUse) {
		if ([self socksProxyDidReadData:data withTag:tag] == NO) {
			[self didReadNormalData:data];
		}
	} else {
		[self didReadNormalData:data];
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	[self tcpClientDidSendData];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
	self.isSecured = YES;

	[self tcpClientDidSecureConnectionWithProtocolVersion:self.socketConnection.sslNegotiatedProtocolVersion
											  cipherSuite:self.socketConnection.sslNegotiatedCipherSuite];
}

#pragma mark -
#pragma mark SSL Certificate Trust Message

- (void)exportSecureConnectionInformation:(NS_NOESCAPE RCMSecureConnectionInformationCompletionBlock)completionBlock
{
	NSParameterAssert(completionBlock != nil);

	NSString *policyName = self.socketConnection.sslNegotiatedCertificatePolicyName;

	if (policyName == nil) {
		completionBlock(NULL, kSSLProtocolUnknown, SSL_NO_SUCH_CIPHERSUITE, @[]);

		return;
	}

	SSLProtocol protocolVersion = self.socketConnection.sslNegotiatedProtocolVersion;

	SSLCipherSuite cipherSuite = self.socketConnection.sslNegotiatedCipherSuite;

	NSArray *certificateChain = self.socketConnection.sslNegotiatedCertificatesData;

	if (certificateChain == nil) {
		certificateChain = @[];
	}

	completionBlock(policyName, protocolVersion, cipherSuite, certificateChain);
}

#pragma mark -
#pragma mark SOCKS Proxy Support

- (BOOL)usesSocksProxy
{
	IRCConnectionSocketProxyType proxyType = self.config.proxyType;

	return (	proxyType == IRCConnectionSocketSystemSocksProxyType	||
				proxyType == IRCConnectionSocketSocks4ProxyType			||
				proxyType == IRCConnectionSocketSocks5ProxyType			||
				proxyType == IRCConnectionSocketHTTPProxyType			||
				proxyType == IRCConnectionSocketTorBrowserType);
}

- (BOOL)socksProxyInUse
{
	IRCConnectionSocketProxyType proxyType = self.config.proxyType;

	return (proxyType == IRCConnectionSocketSocks4ProxyType ||
			proxyType == IRCConnectionSocketSocks5ProxyType ||
			proxyType == IRCConnectionSocketHTTPProxyType);
}

- (BOOL)socksProxyCanAuthenticate
{
	return (self.config.proxyUsername.length > 0 &&
			self.config.proxyPassword.length > 0);
}

- (BOOL)socksProxyPopulateSystemSocksProxy:(NSString **)errorString
{
	IRCConnectionSocketProxyType proxyType = self.config.proxyType;

	if (proxyType == IRCConnectionSocketSystemSocksProxyType)
	{
		NSDictionary *proxySettings = (__bridge_transfer NSDictionary *)(SCDynamicStoreCopyProxies(NULL));

		if ([proxySettings boolForKey:@"SOCKSEnable"] == NO) {
			return NO;
		}

		id socksProxyHost = proxySettings[@"SOCKSProxy"];
		id socksProxyPort = proxySettings[@"SOCKSPort"];

		if (socksProxyHost == nil || socksProxyPort == nil) {
			return NO;
		}

		id socksProxyUsername = proxySettings[@"SOCKSUser"];
		id socksProxyPassword = nil;

		/* Search keychain for a password related to this SOCKS proxy */
		if (socksProxyUsername) {
			NSDictionary *queryParameters = @{
				(id)kSecClass : (id)kSecClassInternetPassword,
				(id)kSecAttrServer : socksProxyHost,
				(id)kSecAttrProtocol : (id)kSecAttrProtocolSOCKS,
				(id)kSecReturnData : (id)kCFBooleanTrue,
				(id)kSecMatchLimit : (id)kSecMatchLimitOne
			};

			CFDataRef queryResultRef = nil;

			OSStatus queryStatus = SecItemCopyMatching((__bridge CFDictionaryRef)queryParameters, (CFTypeRef *)&queryResultRef);

			if (queryStatus != noErr) {
				*errorString = @"SOCKS Error: Textual encountered a problem trying to retrieve the SOCKS proxy password from System Preferences";

				return NO;
			}

			NSData *queryResult = (__bridge_transfer NSData *)queryResultRef;

			if (queryResult != nil) {
				socksProxyPassword = [NSString stringWithData:queryResult encoding:NSUTF8StringEncoding];
			}
		}

		/* Assign results to the local keys */
		IRCConnectionConfigMutable *mutableConfig = [self.config mutableCopy];

		mutableConfig.proxyAddress = socksProxyHost;
		mutableConfig.proxyPort = [socksProxyPort integerValue];

		mutableConfig.proxyType = IRCConnectionSocketSocks5ProxyType;

		mutableConfig.proxyUsername = socksProxyUsername;
		mutableConfig.proxyPassword = socksProxyPassword;

		self.config = mutableConfig;

		return YES;
	}
	else if (proxyType == IRCConnectionSocketTorBrowserType)
	{
		IRCConnectionConfigMutable *mutableConfig = [self.config mutableCopy];

		mutableConfig.proxyType = IRCConnectionSocketSocks5ProxyType;

		mutableConfig.proxyAddress = IRCConnectionSocketTorBrowserTypeProxyAddress;
		mutableConfig.proxyPort = IRCConnectionSocketTorBrowserTypeProxyPort;

		mutableConfig.proxyUsername = nil;
		mutableConfig.proxyPassword = nil;

		self.config = mutableConfig;

		return YES;
	}

	return YES;
}

- (void)socksProxyOpen
{
	IRCConnectionSocketProxyType proxyType = self.config.proxyType;

	if (proxyType == IRCConnectionSocketSocks4ProxyType) {
		[self socks4ProxyOpen];
	} else if (proxyType == IRCConnectionSocketSocks5ProxyType) {
		[self socks5ProxyOpen];
	} else if (proxyType == IRCConnectionSocketHTTPProxyType) {
		[self httpProxyOpen];
	}
}

- (BOOL)socksProxyDidReadData:(NSData *)data withTag:(long)tag
{
	IRCConnectionSocketProxyType proxyType = self.config.proxyType;

	if (proxyType == IRCConnectionSocketSocks4ProxyType) {
		return [self socks4ProxyDidReadData:data withTag:tag];
	} else if (proxyType == IRCConnectionSocketSocks5ProxyType) {
		return [self socks5ProxyDidReadData:data withTag:tag];
	} else if (proxyType == IRCConnectionSocketHTTPProxyType) {
		return [self httpProxyDidReadData:data withTag:tag];
	}

	return NO;
}

- (void)httpProxyOpen
{
	/* Build connect command that will be sent to the HTTP server */
	NSString *connectionAddress = self.config.serverAddress;

	uint16_t connectionPort = self.config.serverPort;

	NSString *connectionAddressCombined = nil;

	if (connectionAddress.IPv6Address) {
		connectionAddressCombined = [NSString stringWithFormat:@"[%@]:%hu", connectionAddress, connectionPort];
	} else {
		connectionAddressCombined = [NSString stringWithFormat:@"%@:%hu", connectionAddress, connectionPort];
	}

	NSString *connectCommand = [NSString stringWithFormat:@"CONNECT %@ HTTP/1.1\x0d\x0a\x0d\x0a", connectionAddressCombined];

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

		if (headerComponents.count <= 2) {
			[self closeSocketWithError:@"HTTP Error: Server responded with a malformed packet"];

			return YES;
		}

		/* Try our best to extract the status code from the response */
		NSString *statusResponse = headerComponents[0];

		// It is possible to split the response into its components using
		// the space character but by using regular expression we are not
		// only getting the components, we are also validating its format.
		NSRange statusResponseRegexRange = NSMakeRange(0, statusResponse.length);

		NSRegularExpression *statusResponseRegex = [NSRegularExpression regularExpressionWithPattern:_httpHeaderResponseStatusRegularExpression options:0 error:NULL];

		NSTextCheckingResult *statusResponseRegexResult = [statusResponseRegex firstMatchInString:statusResponse options:0 range:statusResponseRegexRange];

		if (statusResponseRegexResult.numberOfRanges != 6) {
			[self closeSocketWithError:@"HTTP Error: Server responded with a malformed packet"];

			return YES;
		}

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
		NSString *statusCode = [statusResponse substringWithRange:statusCodeRange];

		NSRange statusMessageRange = [statusResponseRegexResult rangeAtIndex:5];
		NSString *statusMessage = [statusResponse substringWithRange:statusMessageRange];

		if (statusCode.integerValue == 200) {
			[self onSocketConnectedToHost];
		} else {
			NSString *errorMessage = [NSString stringWithFormat:@"HTTP Error: HTTP proxy server returned status code %@ with the message “%@“", statusCode, statusMessage];

			[self closeSocketWithError:errorMessage];
		}

		return YES;

#undef _httpHeaderResponseStatusRegularExpression
	}

	return NO;
}

- (nullable NSString *)socks4ProxyResolvedAddress
{
	/* SOCKS4 proxies do not support anything other than IPv4 addresses 
	 (unless you support SOCKS4a, which Textual does not) which means we
	 perform manual DNS lookup for SOCKS4 and rely on end-point proxy to
	 perform lookup when using other proxy types. */

	NSData *resolvedAddress4 = nil;

	NSArray *resolvedAddresses = [GCDAsyncSocket lookupHost:self.config.serverAddress
													   port:self.config.serverPort
													  error:NULL];

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

	BOOL isVersion4Socks = (self.config.proxyType == IRCConnectionSocketSocks4ProxyType);

	NSString *connectionAddress = nil;

	if (isVersion4Socks) {
		connectionAddress = [self socks4ProxyResolvedAddress];
	} else {
		connectionAddress = self.config.serverAddress;
	}

	NSData *connectionAddressBytes4 = connectionAddress.IPv4AddressBytes;
	NSData *connectionAddressBytes6 = connectionAddress.IPv6AddressBytes;

	uint16_t connectionPort = htons(self.config.serverPort);

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
		}

		[packetData appendBytes:&connectionPort length:2];

		[packetData appendData:connectionAddressBytes4];

		[packetData appendBytes:"\x00" length:1];
	}
	else // isVersion4Socks
	{
		if (connectionAddressBytes6) {
			[packetData appendData:connectionAddressBytes6];
		} else if (connectionAddressBytes4) {
			[packetData appendData:connectionAddressBytes4];
		} else {
			NSData *connectionAddressData = [connectionAddress dataUsingEncoding:NSASCIIStringEncoding];

			NSUInteger connectionAddressLength = connectionAddressData.length;

			[packetData appendBytes:&connectionAddressLength length:1];

			[packetData appendBytes:connectionAddressData.bytes length:connectionAddressLength];
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
		if (data.length != 8) {
			[self closeSocketWithError:@"SOCKS4 Error: Server responded with a malformed packet"];

			return YES;
		}

		uint8_t *bytes = (uint8_t*)data.bytes;

		uint8_t reply = bytes[1];

		if (reply == 0x5a) {
			[self onSocketConnectedToHost];
		} else if (reply == 0x5b) {
			[self closeSocketWithError:@"SOCKS4 Error: Request rejected or failed"];
		} else if (reply == 0x5c) {
			[self closeSocketWithError:@"SOCKS4 Error: Request failed because client is not running an identd (or not reachable from server)"];
		} else if (reply == 0x5d) {
			[self closeSocketWithError:@"SOCKS4 Error: Request failed because client's identd could not confirm the user ID string in the request"];
		} else {
			[self closeSocketWithError:@"SOCKS4 Error: Server replied with unknown status code"];
		}

		return YES;
	}

	return NO;
}

- (BOOL)socks5ProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (tag == SOCKS_PROXY_OPEN_TAG)
	{
		if (data.length != 2) {
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];

			return YES;
		}

		uint8_t *bytes = (uint8_t *)data.bytes;

		uint8_t version = bytes[0];
		uint8_t method = bytes[1];

		if (version != 5) {
			[self closeSocketWithError:@"SOCKS5 Error: Server greeting reply contained incorrect version number"];

			return YES;
		}

		if (method == 0) {
			[self socksProxyConnect];
		} else if (method == 2) {
			if (self.socksProxyCanAuthenticate) {
				[self socks5ProxyUserPassAuth];
			} else {
				[self closeSocketWithError:@"SOCKS5 Error: Server requested that we authenticate but a username and/or password is not configured"];
			}
		} else {
			[self closeSocketWithError:@"SOCKS5 Error: Server requested authentication method that is not supported"];
		}

		return YES;
	}
	else if (tag == SOCKS_PROXY_CONNECT_REPLY_1_TAG)
	{
		if (data.length <= 8) { // first 4 bytes + 2 for port
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];

			return YES;
		}

		uint8_t *bytes = (uint8_t *)data.bytes;

		uint8_t version = bytes[0];
		uint8_t reply = bytes[1];

		if (version == 5 && reply == 0) {
			[self onSocketConnectedToHost];
		} else
		{
#define _dr(case, reason)			case: { failureReason = (reason); break; }

			NSString *failureReason = nil;

			switch (reply) {
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
		//
		// Server response for username/password authentication:
		//
		// field 1: version, 1 byte
		// field 2: status code, 1 byte.
		// 0x00 = success
		// any other value = failure, connection must be closed
		//

		if (data.length != 2) {
			[self closeSocketWithError:@"SOCKS5 Error: Server responded with a malformed packet"];

			return YES;
		}

		uint8_t *bytes = (uint8_t *)data.bytes;

		uint8_t status = bytes[1];

		if (status == 0x00) {
			[self socksProxyConnect];
		} else {
			[self closeSocketWithError:@"SOCKS5 Error: Authentication failed for unknown reason"];
		}

		return YES;
	}

	return NO;
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

	if (self.socksProxyCanAuthenticate == NO) {
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

//
// For username/password authentication the client's authentication request is
//
// field 1: version number, 1 byte (must be 0x01)
// field 2: username length, 1 byte
// field 3: username
// field 4: password length, 1 byte
// field 5: password
//

- (void)socks5ProxyUserPassAuth
{
	/* Assemble the packet of data that will be sent */
	NSData *usernameData = [self.config.proxyUsername dataUsingEncoding:NSUTF8StringEncoding];
	NSData *passwordData = [self.config.proxyPassword dataUsingEncoding:NSUTF8StringEncoding];

	uint8_t usernameLength = (uint8_t)usernameData.length;
	uint8_t passwordLength = (uint8_t)passwordData.length;

	NSMutableData *authData = [NSMutableData dataWithCapacity:(1 + 1 + usernameLength + 1 + passwordLength)];

	[authData appendBytes:"\x01" length:1];
	[authData appendBytes:&usernameLength length:1];
	[authData appendBytes:usernameData.bytes length:usernameLength];
	[authData appendBytes:&passwordLength length:1];
	[authData appendBytes:passwordData.bytes length:passwordLength];

	/* Write the packet to the socket */
	[self.socketConnection writeData:authData withTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];

	/* Wait for a response from the SOCKS server */
	[self.socketConnection readDataWithTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];
}

@end

NS_ASSUME_NONNULL_END
