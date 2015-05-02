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

#define SOCKS_PROXY_OPEN_TAG					10100
#define SOCKS_PROXY_CONNECT_TAG					10200
#define SOCKS_PROXY_CONNECT_REPLY_1_TAG			10300
#define SOCKS_PROXY_CONNECT_REPLY_2_TAG			10400
#define SOCKS_PROXY_AUTH_USERPASS_TAG			10500

#define SOCKS_PROXY_CONNECT_TIMEOUT			8.00
#define SOCKS_PROXY_READ_TIMEOUT			5.00
#define SOCKS_PROXY_TOTAL_TIMEOUT			80.00

#define CONNECT_TIMEOUT						30.0

#warning IRCConnectionSocket TODO: Add SOCKS4(a) support
#warning IRCConnectionSocket TODO: Add support for system-wide SOCKS proxy
#warning IRCConnectionSocket TODO: Add better error checking for incoming and outgoing SOCKS communications
#warning IRCConnectionSocket TODO: Fix TLS negotiation in SOCKS proxy mode. It is prone to failure, very commonly.

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

	if ([self usesSocksProxy]) {
		[self socksProxyPopulateSystemSocksProxy];

		[self performConnectToHost:self.proxyAddress onPort:self.proxyPort];
	} else {
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

- (void)destroySocket
{
	[self tearDownQueuedCertificateTrustDialog];

	if ( self.socketConnection) {
		[self.socketConnection setDelegate:nil];
		 self.socketConnection = nil;
	}

	[self destroyDispatchQueue];
	
	self.isConnectedWithClientSideCertificate = NO;
	
	self.isConnected = NO;
	self.isConnecting = NO;
}

- (void)tearDownQueuedCertificateTrustDialog
{
	[[TXSharedApplication sharedQueuedCertificateTrustPanel] dequeueEntryForSocket:self.socketConnection];
}

#pragma mark -
#pragma mark Socket Read & Write

- (NSData *)readLineFromMutableData:(NSMutableData * __autoreleasing *)refString
{
	NSObjectIsEmptyAssertReturn(*refString, nil);
	
	NSInteger messageSubstringIndex = 0;
	NSInteger messageDeleteIndex = 0;

	NSRange _LFRange = [*refString rangeOfData:[NSData lineFeed] options:0 range:NSMakeRange(0, [*refString length])];
	NSRange _CRRange = [*refString rangeOfData:[NSData carriageReturn] options:0 range:NSMakeRange(0, [*refString length])];

	if (_LFRange.location == NSNotFound) {
		/* If we do not have any line end for this fragment and the refString is not
		 empty, then we save the remaining fragment for processing once we have more
		 information. */

		NSObjectIsEmptyAssertReturn(*refString, nil);

		self.bufferOverflowString = *refString;
	
		return nil;
	}

	messageSubstringIndex = _LFRange.location;
	messageDeleteIndex = (_LFRange.location + 1);

	if ((_LFRange.location - 1) == _CRRange.location) {
		messageSubstringIndex -= 1;
	}
	
	NSData *readLine = [*refString subdataWithRange:NSMakeRange(0, messageSubstringIndex)];

	[*refString replaceBytesInRange:NSMakeRange(0, messageDeleteIndex) withBytes:NULL length:0];

	return readLine;
}

- (void)writeDataToSocket:(NSData *)data
{
	if (self.isConnected) {
		[self.socketConnection writeData:data withTimeout:(-1) tag:0];
	}
}

- (void)waitForData
{
	if (self.isConnected) {
		[self.socketConnection readDataWithTimeout:(-1) tag:0];
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)connectedAddress
{
	if ([self usesSocksProxy]) {
		return nil;
	} else {
		return [self.socketConnection connectedHost];
	}
}

- (NSArray *)clientSideCertificateForAuthentication
{
	NSData *localCertData = [[[self associatedClient] config] identityClientSideCertificate];

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
				[[TXSharedApplication sharedQueuedCertificateTrustPanel] enqueue:trust withCompletionBlock:completionHandler forSocket:self.socketConnection];
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
	if ([self usesSocksProxy]) {
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
	NSMutableData *readBuffer = nil;

	BOOL hasOverflowPrefix = ([self.bufferOverflowString length] > 0);

	if (hasOverflowPrefix) {
		readBuffer = [self.bufferOverflowString mutableCopy];

		self.bufferOverflowString = nil; // Destroy old overflow;

		[readBuffer appendBytes:[data bytes] length:[data length]];
	} else {
		readBuffer = [data mutableCopy];
	}

	while (1 == 1) {
		NSData *rdata = [self readLineFromMutableData:&readBuffer];

		if (rdata == nil) {
			break;
		}

		NSString *sdata = [self convertFromCommonEncoding:rdata];

		if (sdata == nil) {
			break;
		}

		XRPerformBlockSynchronouslyOnMainQueue(^{
			[self tcpClientDidReceiveData:sdata];
		});
	}
}

- (void)didReadNormalData:(NSData *)data
{
	[self completeReadForNormalData:data];

	[self waitForData];
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([self usesSocksProxy]) {
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

	if (plainText) {
		return BLS(1250, protocol, cipher);
	} else {
		return BLS(1248, protocol, cipher);
	}
}

- (void)openSSLCertificateTrustDialog
{
	SecTrustRef trust = [self.socketConnection sslCertificateTrustInformation];

	PointerIsEmptyAssert(trust);

	NSString *protocolString = [self localizedSecureConnectionProtocolString:YES];

	NSString *policyName = [self.socketConnection sslCertificateTrustPolicyName];

	SFCertificateTrustPanel *panel = [SFCertificateTrustPanel new];

	[panel setDefaultButtonTitle:BLS(1011)];
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
	return (/*	self.proxyType == IRCConnectionSocketSystemSocksProxyType	|| */ // Not supported yet
				self.proxyType == IRCConnectionSocketSocks4ProxyType		||
				self.proxyType == IRCConnectionSocketSocks5ProxyType		  );
}

- (void)socksProxyPopulateSystemSocksProxy
{
	if (self.proxyType == IRCConnectionSocketSystemSocksProxyType) {
		CFDictionaryRef settings = SCDynamicStoreCopyProxies(NULL);

		CFNumberRef isEnabledRef = CFDictionaryGetValue(settings, (id)kSCPropNetProxiesSOCKSEnable);

		if (isEnabledRef && CFGetTypeID(isEnabledRef) == CFNumberGetTypeID()) {
			NSInteger isEnabledInt = 0;

			CFNumberGetValue(isEnabledRef, kCFNumberIntType, &isEnabledInt);

			if (isEnabledInt == 1) {
				if (CFDictionaryGetValueIfPresent(settings, (id)kCFStreamPropertySOCKSProxyHost, NULL)) {
					// TODO: Implement
				}
			}
		}

		CFRelease(settings);
	}
}

/**
 * Sends the SOCKS5 open/handshake/authentication data, and starts reading the response.
 * We attempt to gain anonymous access (no authentication).
 **/
- (void)socksProxyOpen
{
	//      +-----+-----------+---------+
	// NAME | VER | NMETHODS  | METHODS |
	//      +-----+-----------+---------+
	// SIZE |  1  |    1      | 1 - 255 |
	//      +-----+-----------+---------+
	//
	// Note: Size is in bytes
	//
	// Version    = 5 (for SOCKS5)
	// NumMethods = 1
	// Method     = 0 (No authentication, anonymous access)

	NSUInteger byteBufferLength = 3;

	uint8_t *byteBuffer = malloc((byteBufferLength * sizeof(uint8_t)));

	uint8_t version = 5; // VER
	byteBuffer[0] = version;

	uint8_t numMethods = 1; // NMETHODS
	byteBuffer[1] = numMethods;

	uint8_t method = 0; // 0 == no auth
	if ([self.proxyUsername length] > 0 ||
		[self.proxyPassword length] > 0)
	{
		method = 2; // username/password
	}
	byteBuffer[2] = method;

	NSData *data = [NSData dataWithBytesNoCopy:byteBuffer length:byteBufferLength freeWhenDone:YES];

	[self.socketConnection writeData:data withTimeout:(-1) tag:SOCKS_PROXY_OPEN_TAG];

	//      +-----+--------+
	// NAME | VER | METHOD |
	//      +-----+--------+
	// SIZE |  1  |   1    |
	//      +-----+--------+
	//
	// Note: Size is in bytes
	//
	// Version = 5 (for SOCKS5)
	// Method  = 0 (No authentication, anonymous access)

	[self.socketConnection readDataToLength:2 withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_OPEN_TAG];
}

/*
 For username/password authentication the client's authentication request is

 field 1: version number, 1 byte (must be 0x01)
 field 2: username length, 1 byte
 field 3: username
 field 4: password length, 1 byte
 field 5: password
 */

- (void)socksProxyUserPassAuth
{
	NSData *usernameData = [self.proxyUsername dataUsingEncoding:NSUTF8StringEncoding];
	NSData *passwordData = [self.proxyPassword dataUsingEncoding:NSUTF8StringEncoding];

	uint8_t usernameLength = (uint8_t)[usernameData length];
	uint8_t passwordLength = (uint8_t)[passwordData length];

	NSMutableData *authData = [NSMutableData dataWithCapacity:(1 + 1 + usernameLength + 1 + passwordLength)];

	uint8_t version[1] = {0x01};

	[authData appendBytes:version length:1];
	[authData appendBytes:&usernameLength length:1];
	[authData appendBytes:[usernameData bytes] length:usernameLength];
	[authData appendBytes:&passwordLength length:1];
	[authData appendBytes:[passwordData bytes] length:passwordLength];

	[self.socketConnection writeData:authData withTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];

	[self.socketConnection readDataToLength:2 withTimeout:(-1) tag:SOCKS_PROXY_AUTH_USERPASS_TAG];
}

/**
 * Sends the SOCKS5 connect data (according to XEP-65), and starts reading the response.
 **/
- (void)socksProxyConnect
{
	//      +-----+-----+-----+------+------+------+
	// NAME | VER | CMD | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//
	// Note: Size is in bytes
	//
	// Version      = 5 (for SOCKS5)
	// Command      = 1 (for Connect)
	// Reserved     = 0
	// Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
	// Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
	// Port         = 0

	NSUInteger hostLength = [self.serverAddress length];

	NSData *hostData = [self.serverAddress dataUsingEncoding:NSUTF8StringEncoding];

	NSUInteger byteBufferLength = (uint)(4 + 1 + hostLength + 2);

	uint8_t *byteBuffer = malloc((byteBufferLength * sizeof(uint8_t)));

	NSUInteger offset = 0;

	// VER
	uint8_t version = 0x05;
	byteBuffer[0] = version;
	offset++;

	/* CMD
	 o  CONNECT X'01'
	 o  BIND X'02'
	 o  UDP ASSOCIATE X'03'
	 */
	uint8_t command = 0x01;
	byteBuffer[offset] = command;
	offset++;

	byteBuffer[offset] = 0x00; // Reserved, must be 0
	offset++;

	/* ATYP
	 o  IP V4 address: X'01'
	 o  DOMAINNAME: X'03'
	 o  IP V6 address: X'04'
	 */
	uint8_t addressType = 0x03;
	byteBuffer[offset] = addressType;
	offset++;

	/* ADDR
	 o  X'01' - the address is a version-4 IP address, with a length of 4 octets
	 o  X'03' - the address field contains a fully-qualified domain name.  The first
	 octet of the address field contains the number of octets of name that
	 follow, there is no terminating NUL octet.
	 o  X'04' - the address is a version-6 IP address, with a length of 16 octets.
	 */
	byteBuffer[offset] = hostLength;
	offset++;

	memcpy((byteBuffer + offset), [hostData bytes], hostLength);
	offset += hostLength;

	uint16_t port = htons((uint16_t)self.serverPort);
	NSUInteger portLength = 2;
	memcpy((byteBuffer + offset), &port, portLength);
	offset += portLength;

	NSData *data = [NSData dataWithBytesNoCopy:byteBuffer length:byteBufferLength freeWhenDone:YES];

	[self.socketConnection writeData:data withTimeout:(-1) tag:SOCKS_PROXY_CONNECT_TAG];

	//      +-----+-----+-----+------+------+------+
	// NAME | VER | REP | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//
	// Note: Size is in bytes
	//
	// Version      = 5 (for SOCKS5)
	// Reply        = 0 (0=Succeeded, X=ErrorCode)
	// Reserved     = 0
	// Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
	// Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
	// Port         = 0
	//
	// It is expected that the SOCKS server will return the same address given in the connect request.
	// But according to XEP-65 this is only marked as a SHOULD and not a MUST.
	// So just in case, we'll read up to the address length now, and then read in the address+port next.

	[self.socketConnection readDataToLength:5 withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_1_TAG];
}

- (BOOL)socksProxyDidReadData:(NSData *)data withTag:(long)tag
{
	if (tag == SOCKS_PROXY_OPEN_TAG)
	{
		NSAssert(([data length] == 2), @"SOCKS_OPEN reply length must be 2!");

		uint8_t *bytes = (uint8_t*)[data bytes];

		uint8_t version = bytes[0];
		uint8_t method = bytes[1];

		if (version == 5) {
			if (method == 0) { // No Auth
				[self socksProxyConnect];
			} else if (method == 2) { // Username / password
				[self socksProxyUserPassAuth];
			} else {
				[self closeSocket];
			}
		} else {
			[self closeSocket];
		}

		return YES;
	}
	else if (tag == SOCKS_PROXY_CONNECT_REPLY_1_TAG)
	{
		NSAssert(([data length] == 5), @"SOCKS_CONNECT_REPLY_1 length must be 5!");

		uint8_t *bytes = (uint8_t*)[data bytes];

		uint8_t ver = bytes[0];
		uint8_t rep = bytes[1];

		if (ver == 5 && rep == 0)
		{
			// We read in 5 bytes which we expect to be:
			// 0: ver  = 5
			// 1: rep  = 0
			// 2: rsv  = 0
			// 3: atyp = 3
			// 4: size = size of addr field
			//
			// However, some servers don't follow the protocol, and send a atyp value of 0.

			uint8_t addressType = bytes[3];
			uint8_t portLength = 2;

			if (addressType == 1) { // IPv4
									// only need to read 3 address bytes instead of 4 + portlength because we read an extra byte already

				[self.socketConnection readDataToLength:(3 + portLength) withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_2_TAG];
			}
			else if (addressType == 3) // Domain name
			{
				uint8_t addrLength = bytes[4];

				[self.socketConnection readDataToLength:(addrLength+portLength) withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_2_TAG];
			} else if (addressType == 4) { // IPv6
				[self.socketConnection readDataToLength:(16 + portLength) withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_2_TAG];
			} else if (addressType == 0) {
				// The size field was actually the first byte of the port field
				// We just have to read in that last byte

				[self.socketConnection readDataToLength:1 withTimeout:SOCKS_PROXY_READ_TIMEOUT tag:SOCKS_PROXY_CONNECT_REPLY_2_TAG];
			} else {
				[self closeSocket];
			}
		}
		else
		{
			[self closeSocket];
		}

		return YES;
	}
	else if (tag == SOCKS_PROXY_CONNECT_REPLY_2_TAG)
	{
		[self onSocketConnectedToHost];

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
				[self closeSocket];
			}
		} else {
			[self closeSocket];
		}

		return YES;
	}
	else
	{
		return NO;
	}
}

@end
