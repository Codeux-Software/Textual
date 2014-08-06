/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define _LF	0xa
#define _CR	0xd

@implementation IRCConnection (IRCConnectionSocket)

#pragma mark -
#pragma mark Socket Specifics

- (BOOL)useNewSocketEngine
{
	return (self.connectionUsesNormalSocks == NO &&
			self.connectionUsesSystemSocks == NO);
}

#pragma mark -
#pragma mark Grand Centeral Dispatch

- (void)destroyDispatchQueue
{
	self.dispatchQueue = NULL;
	self.socketQueue = NULL;
}

- (void)createDispatchQueue
{
	NSString *dqname = [@"socketDispatchQueue." stringByAppendingString:[self.associatedClient uniqueIdentifier]];

	self.dispatchQueue = dispatch_queue_create([dqname UTF8String], DISPATCH_QUEUE_SERIAL);

	if ([self useNewSocketEngine]) {
		NSString *sqname = [@"socketReadWriteQueue." stringByAppendingString:[self.associatedClient uniqueIdentifier]];

		self.socketQueue = dispatch_queue_create([sqname UTF8String], DISPATCH_QUEUE_SERIAL);
	}
}

#pragma mark -
#pragma mark Open/Close Socket

- (void)openSocket
{
    [self createDispatchQueue];

	self.isConnecting = YES;

	if ([self useNewSocketEngine]) {
        self.socketConnection = [GCDAsyncSocket socketWithDelegate:self
													 delegateQueue:self.dispatchQueue
													   socketQueue:self.socketQueue];

		[self.socketConnection setIPv4PreferredOverIPv6:(self.connectionPrefersIPv6 == NO)];
	} else {
		self.socketConnection = [AsyncSocket socketWithDelegate:self];
	}

	NSError *connError = nil;

	if ([self.socketConnection connectToHost:self.serverAddress onPort:self.serverPort withTimeout:(-1) error:&connError] == NO) {
		[self onSocket:self.socketConnection willDisconnectWithError:connError];

		if ([self useNewSocketEngine] == NO) {
			[self onSocketDidDisconnect:self.socketConnection withError:nil];
		}
	}
}

- (void)closeSocket
{
	if (self.socketConnection) {
		if ([self useNewSocketEngine]) {
			[self.socketConnection setDelegate:nil];
		}
		
		[self.socketConnection disconnect];
	}
}

- (void)destroySocket
{
	if ( self.socketConnection) {
		 self.socketConnection = nil;
	}
	
	[self destroyDispatchQueue];
	
	self.isConnectedWithClientSideCertificate = NO;
	
	self.isConnected = NO;
	self.isConnecting = NO;
}

#pragma mark -
#pragma mark Socket Read & Write

- (NSData *)readLine:(NSMutableData **)refString
{
	NSObjectIsEmptyAssertReturn(*refString, nil);
	
	NSInteger messageSubstringIndex = 0;
	NSInteger messageDeleteIndex = 0;

	NSRange _LFRange = [*refString rangeOfData:[GCDAsyncSocket LFData] options:0 range:NSMakeRange(0, [*refString length])];
	NSRange _CRRange = [*refString rangeOfData:[GCDAsyncSocket CRData] options:0 range:NSMakeRange(0, [*refString length])];

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

- (void)write:(NSData *)data
{
	NSAssertReturn(self.isConnected);

	[self.socketConnection writeData:data withTimeout:(-1) tag:0];
	[self.socketConnection readDataWithTimeout:(-1)	tag:0];
}

#pragma mark -
#pragma mark Primary Socket Delegate

- (NSString *)connectedAddress
{
	return [self.socketConnection connectedHost];
}

- (BOOL)onSocketWillConnect:(id)sock
{
	if (self.connectionUsesSystemSocks) {
		[self.socketConnection useSystemSocksProxy];
	} else if (self.connectionUsesNormalSocks) {
		[self.socketConnection useSocksProxyVersion:self.proxySocksVersion
											address:self.proxyAddress
											   port:self.proxyPort
										   username:self.proxyUsername
										   password:self.proxyPassword];
	}

	if (self.connectionUsesSSL) {
		if ([self useNewSocketEngine]) {
			[self.socketConnection useSSLWithClient:self.associatedClient withConnectionController:self];
		} else {
			[self.socketConnection useSSL];
		}
	}

	return YES;
}

- (void)socket:(id)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
	SecTrustResultType result;
	
	OSStatus trustEvalStatus = SecTrustEvaluate(trust, &result);
	
	if (trustEvalStatus == errSecSuccess)
	{
		if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
			completionHandler(YES);
		} else if (result == kSecTrustResultRecoverableTrustFailure) {
			[[TXSharedApplication sharedQueuedCertificateTrustPanel] enqueue:trust withCompletionBlock:completionHandler];
		} else {
			completionHandler(NO);
		}
	}
	else
	{
		completionHandler(NO);
	}
}
	
- (void)onSocket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self.socketConnection readDataWithTimeout:(-1) tag:0];

	self.isConnecting = NO;
	self.isConnected = YES;

	[self performSelector:@selector(tcpClientDidConnect)];
}

- (void)onSocketDidDisconnect:(id)sock
{
	if ([self useNewSocketEngine] == NO) {
		[self closeSocket];
		[self destroySocket];
	}
}

- (void)onSocketDidDisconnect:(id)sock withError:(NSError *)distcError
{
	if ([self useNewSocketEngine]) {
		[self closeSocket];
		[self destroySocket];
	}

	[self performSelector:@selector(tcpClientDidDisconnect:) withObject:distcError];
}

- (void)onSocket:(id)sender willDisconnectWithError:(NSError *)error
{
	if (PointerIsEmpty(error) || [error code] == errSSLClosedGraceful) {
		if ([self useNewSocketEngine]) {
			[self onSocketDidDisconnect:sender withError:nil];
		}
	} else {
		NSString *errorMessage = nil;

		if ([GCDAsyncSocket badSSLCertificateErrorFound:error]) {
			[self.associatedClient setDisconnectType:IRCClientDisconnectBadSSLCertificateMode];
		} else {
			if ([error.domain isEqualToString:NSPOSIXErrorDomain]) {
				errorMessage = [GCDAsyncSocket posixErrorStringFromError:[error code]];
			}

			if (NSObjectIsEmpty(errorMessage)) {
				errorMessage = [error localizedDescription];
			}

			[self performSelector:@selector(tcpClientDidError:) withObject:errorMessage];
		}

		[self onSocketDidDisconnect:sender withError:error];
	}
}

- (void)completeReadForData:(NSData *)data
{
	NSMutableData *readBuffer;

	BOOL hasOverflowPrefix = ([self.bufferOverflowString length] > 0);

	if (hasOverflowPrefix) {
		readBuffer = [self.bufferOverflowString mutableCopy];

		self.bufferOverflowString = nil; // Destroy old overflow;

		[readBuffer appendBytes:[data bytes] length:[data length]];
	} else {
		readBuffer = [data mutableCopy];
	}

	while (1 == 1) {
		NSData *data = [self readLine:&readBuffer];

		if (data == nil) {
			break;
		}

		NSString *sdata = [self convertFromCommonEncoding:data];

		if (sdata == nil) {
			break;
		}

		TXPerformBlockSynchronouslyOnMainQueue(^{
			[self performSelector:@selector(tcpClientDidReceiveData:) withObject:sdata];
		});
	}
}

- (void)onSocket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([self useNewSocketEngine] == NO) {
		/* The classic socket does not use GCD, but seeing as read events can be
		 time consuming we chose to perform all read actions on a dispatch queue. */
		/* This behavior is inherited automatically when using the new socket
		 engine which is pretty much anytime a proxy is not enabled. */
		TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
			[self completeReadForData:data];
		});
	} else {
		[self completeReadForData:data];
	}

	[self.socketConnection readDataWithTimeout:(-1) tag:0];
}

- (void)onSocket:(id)sock didWriteDataWithTag:(long)tag
{
	[self performSelector:@selector(tcpClientDidSendData)];
}

#pragma mark -
#pragma mark Secondary Socket Delegate

- (void)socket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	TXPerformBlockSynchronouslyOnMainQueue(^{
		[self onSocketWillConnect:sock];

		[self onSocket:sock didConnectToHost:ahost port:aport];
	});
}

- (void)socketDidDisconnect:(id)sock withError:(NSError *)err
{
	TXPerformBlockSynchronouslyOnMainQueue(^{
		[self onSocket:sock willDisconnectWithError:err];
	});
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	[self onSocket:sock didReadData:data withTag:tag];
}

- (void)socket:(id)sock didWriteDataWithTag:(long)tag
{
	TXPerformBlockSynchronouslyOnMainQueue(^{
		[self onSocket:sock didWriteDataWithTag:tag];
	});
}

#pragma mark -
#pragma mark SSL Certificate Trust Message

- (void)openSSLCertificateTrustDialog
{
	if ([self useNewSocketEngine]) {
		[self.socketConnection requestSSLTrustFor:[NSApp mainWindow]
									modalDelegate:nil
								   didEndSelector:nil
									  contextInfo:nil
									defaultButton:BLS(1011)
								  alternateButton:nil];
	}
}

@end
