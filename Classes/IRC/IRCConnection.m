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

#import "IRCConnectionInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface IRCConnection ()
@property (nonatomic, strong, readwrite) IRCClient *client;
@property (nonatomic, strong) NSMutableArray<NSString *> *sendQueue;
@property (nonatomic, strong) TLOTimer *floodControlTimer;
@property (nonatomic, assign) NSUInteger floodControlCurrentMessageCount;
@end

@implementation IRCConnection

#pragma mark -
#pragma mark Initialization 

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithConfig:(IRCConnectionConfig *)config onClient:(IRCClient *)client
{
	NSParameterAssert(config != nil);
	NSParameterAssert(client != nil);

	if ((self = [super init])) {
		self.client = client;

		self.config = config;

		[self prepareInitialState];
	}
	
	return self;
}

- (void)prepareInitialState
{
	self.sendQueue = [NSMutableArray new];

	self.floodControlTimer = [TLOTimer new];

	self.floodControlTimer.repeatTimer = YES;

	self.floodControlTimer.target = self;
	self.floodControlTimer.action = @selector(onFloodControlTimer:);
}

- (void)dealloc
{
	[self.floodControlTimer stop];
	 self.floodControlTimer = nil;

	[self close];
}

#pragma mark -
#pragma mark Open/Close Connection

- (void)open
{
	[self startFloodControlTimer];

	[self openSocket];
}

- (void)close
{
	self.isSending = NO;

	self.floodControlCurrentMessageCount = 0;

	[self.sendQueue removeAllObjects];
	
	[self stopFloodControlTimer];
	
	[self closeSocket];
}

#pragma mark -
#pragma mark Encode Data

- (nullable NSString *)convertFromCommonEncoding:(NSData *)data
{
	return [self.client convertFromCommonEncoding:data];
}

- (nullable NSData *)convertToCommonEncoding:(NSString *)data
{
	return [self.client convertToCommonEncoding:data];
}

#pragma mark -
#pragma mark Send Data

- (void)sendLine:(NSString *)line
{
	NSParameterAssert(line != nil);

	/* PONG replies are extremely important. There is no reason they should be
	 placed in the flood control queue. This writes them directly to the socket
	 instead of actuallying waiting for the queue. We only need this check if
	 we actually have flood control enabled. */
	if ([line hasPrefix:@"PONG"]) {
		[self sendData:line removeFromQueue:NO];

		return;
	}

	[self.sendQueue addObject:line];

	[self tryToSend];
}

- (BOOL)tryToSend
{
	if (self.isSending) {
		return NO;
	}

	if (self.sendQueue.count == 0) {
		return NO;
	}

	if (self.client.isLoggedIn) {
		if (self.floodControlCurrentMessageCount >= self.config.floodControlMaximumMessages) {
			return NO;
		}

		self.floodControlCurrentMessageCount += 1;
	}

	[self sendNextLine];
	
	return YES;
}

- (void)sendNextLine
{
	NSString *line = self.sendQueue.firstObject;

	if (line == nil) {
		return;
	}

	self.isSending = YES;

	[self sendData:line removeFromQueue:YES];
}

- (void)sendData:(NSString *)stringToSend
{
	[self sendData:stringToSend removeFromQueue:NO];
}

- (void)sendData:(NSString *)stringToSend removeFromQueue:(BOOL)removeFromQueue
{
	NSParameterAssert(stringToSend != nil);

	if (removeFromQueue) {
		[self.sendQueue removeObjectAtIndex:0];
	}
	
	stringToSend = [stringToSend stringByAppendingString:@"\x0d\x0a"];

	NSData *dataToSend = [self convertToCommonEncoding:stringToSend];

	if (dataToSend) {
		[self writeDataToSocket:dataToSend];

		[self tcpClientWillSendData:stringToSend];
	}
}

- (void)clearSendQueue
{
	[self.sendQueue removeAllObjects];
}

#pragma mark -
#pragma mark Flood Control Timer

- (void)startFloodControlTimer
{
	if (self.floodControlTimer.timerIsActive == NO) {
		[self.floodControlTimer start:self.config.floodControlDelayInterval];
	}
}

- (void)stopFloodControlTimer
{
	if (self.floodControlTimer.timerIsActive) {
		[self.floodControlTimer stop];
	}
}

- (void)onFloodControlTimer:(id)sender
{
	self.floodControlCurrentMessageCount = 0;

	while ([self tryToSend] != NO) {
		;
	}
}

#pragma mark -
#pragma mark Socket Delegate

- (void)tcpClientDidConnect
{
	[self clearSendQueue];

	[self.client ircConnectionDidConnect:self];
}

- (void)tpcClientWillConnectToProxy:(NSString *)proxyHost port:(uint16_t)proxyPort
{
	[self.client ircConnection:self willConnectToProxy:proxyHost port:proxyPort];
}

- (void)tcpClientDidError:(NSString *)error
{
	[self clearSendQueue];

	[self.client ircConnection:self didError:error];
}

- (void)tcpClientDidDisconnect:(nullable NSError *)disconnectError
{
	[self clearSendQueue];

	[self.client ircConnection:self didDisconnectWithError:disconnectError];
}

- (void)tcpClientDidCloseReadStream
{
	[self.client ircConnectionDidCloseReadStream:self];
}

- (void)tcpClientDidReceiveData:(NSString *)data
{
	[self.client ircConnection:self didReceiveData:data];
}

- (void)tcpClientDidSecureConnection
{
	[self.client ircConnectionDidSecureConnection:self];
}

- (void)tcpClientDidReceivedAnInsecureCertificate
{
	[self.client ircConnectionDidReceivedAnInsecureCertificate:self];
}

- (void)tcpClientWillSendData:(NSString *)data
{
	[self.client ircConnection:self willSendData:data];
}

- (void)tcpClientDidSendData
{
	self.isSending = NO;
	
	[self tryToSend];
}

@end

NS_ASSUME_NONNULL_END
