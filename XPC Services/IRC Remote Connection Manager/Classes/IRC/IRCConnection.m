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

NS_ASSUME_NONNULL_BEGIN

@interface IRCConnection ()
@property (nonatomic, strong) NSMutableArray<NSData *> *sendQueue;
@property (nonatomic, strong) TLOTimer *floodControlTimer;
@property (atomic, assign) NSUInteger floodControlCurrentMessageCount;
@property (nonatomic, weak) NSXPCConnection *serviceConnection;
@end

@implementation IRCConnection

#pragma mark -
#pragma mark Initialization 

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithConfig:(IRCConnectionConfig *)config onConnection:(NSXPCConnection *)connection
{
	NSParameterAssert(config != nil);
	NSParameterAssert(connection != nil);

	if ((self = [super init])) {
		self.config = config;

		self.serviceConnection = connection;

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
	self.floodControlTimer.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	self.uniqueIdentifier = [NSString stringWithUUID];
}

- (void)destroyWorkerDispatchQueue
{
	self.workerQueue = NULL;
}

- (void)createWorkerDispatchQueue
{
	NSString *workerQueueName =
	[@"Textual.IRCConnection.workerQueue." stringByAppendingString:self.uniqueIdentifier];

	self.workerQueue =
	XRCreateDispatchQueueWithPriority(workerQueueName.UTF8String, DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT);
}

#pragma mark -
#pragma mark Open/Close Connection

- (void)open
{
	LogToConsoleDebug("Opening connection %@...", self.uniqueIdentifier);

	[self createWorkerDispatchQueue];

	[self startFloodControlTimer];

	[self openSocket];
}

- (void)close
{
	LogToConsoleDebug("Closing connection %@...", self.uniqueIdentifier);

	if (self.isConnecting == NO && self.isConnected == NO) {
		LogToConsoleError("Not connected");
	}

	self.isDisconnecting = YES;

	self.isFloodControlEnforced = NO;

	[self clearSendQueue];

	[self stopFloodControlTimer];

	[self closeSocket];
}

- (void)disconnectTeardown
{
	/* Method invoked when a disconnect occurs. */
	self.isDisconnecting = YES;

	self.isFloodControlEnforced = NO;

	[self clearSendQueue];

	[self stopFloodControlTimer];

	[self destroyWorkerDispatchQueue];
}

#pragma mark -
#pragma mark Send Data

- (BOOL)tryToSend
{
	if (self.isSending) {
		return NO;
	}

	if ([self sendQueueCount] == 0) {
		return NO;
	}

	if (self.isFloodControlEnforced) {
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
	NSData *line = [self nextEntryInSendQueue];

	if (line == nil) {
		return;
	}

	self.isSending = YES;

	[self _sendData:line removeFromQueue:YES];
}

- (void)sendData:(NSData *)data
{
	[self sendData:data bypassQueue:NO];
}

- (void)sendData:(NSData *)data bypassQueue:(BOOL)bypassQueue
{
	NSParameterAssert(data != nil);

	if (self.isConnecting == NO && self.isConnected == NO) {
		LogToConsoleError("Cannot send data while disconnected");

		return;
	}

	if (bypassQueue) {
		[self _sendData:data removeFromQueue:NO];

		return;
	}

	[self addDataToSendQueue:data];

	(void)[self tryToSend];
}

- (void)_sendData:(NSData *)data removeFromQueue:(BOOL)removeFromQueue
{
	NSParameterAssert(data != nil);

	if (removeFromQueue) {
		[self removeDataFromSendQueue:data];
	}

	[self writeDataToSocket:data];

	[self tcpClientWillSendData:data];
}

- (NSUInteger)sendQueueCount
{
	__block NSUInteger sendQueueCount = 0;

	XRPerformBlockSynchronouslyOnQueue(self.workerQueue, ^{
		sendQueueCount = self.sendQueue.count;
	});

	return sendQueueCount;
}

- (nullable NSData *)nextEntryInSendQueue
{
	__block NSData *nextEntry = nil;

	XRPerformBlockSynchronouslyOnQueue(self.workerQueue, ^{
		nextEntry = self.sendQueue.firstObject;
	});

	return nextEntry;
}

- (void)addDataToSendQueue:(NSData *)data
{
	NSParameterAssert(data != nil);

	XRPerformBlockSynchronouslyOnQueue(self.workerQueue, ^{
		[self.sendQueue addObject:data];
	});
}

- (void)removeDataFromSendQueue:(NSData *)data
{
	NSParameterAssert(data != nil);

	XRPerformBlockSynchronouslyOnQueue(self.workerQueue, ^{
		[self.sendQueue removeObject:data];
	});
}

- (void)clearSendQueue
{
	LogToConsoleDebug("Clearing send queue on connection %@", self.uniqueIdentifier);

	XRPerformBlockSynchronouslyOnQueue(self.workerQueue, ^{
		[self.sendQueue removeAllObjects];
	});

	self.floodControlCurrentMessageCount = 0;

	self.isSending = NO;
}

#pragma mark -
#pragma mark Flood Control Timer

- (void)enforceFloodControl
{
	self.isFloodControlEnforced = YES;
}

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

- (id <RCMConnectionManagerClientProtocol>)remoteObjectProxy
{
	return self.serviceConnection.remoteObjectProxy;
}

- (void)tpcClientWillConnectToProxy:(NSString *)proxyHost port:(uint16_t)proxyPort
{
	[[self remoteObjectProxy] ircConnectionWillConnectToProxy:proxyHost port:proxyPort];
}

- (void)tcpClientDidConnectToHost:(nullable NSString *)host
{
	[self clearSendQueue];

	[[self remoteObjectProxy] ircConnectionDidConnectToHost:host];
}

- (void)tcpClientDidSecureConnectionWithProtocolVersion:(SSLProtocol)protocolVersion cipherSuite:(SSLCipherSuite)cipherSuite
{
	[[self remoteObjectProxy] ircConnectionDidSecureConnectionWithProtocolVersion:protocolVersion cipherSuite:cipherSuite];
}

- (void)tcpClientDidCloseReadStream
{
	self.EOFReceived = YES;

	[[self remoteObjectProxy] ircConnectionDidCloseReadStream];
}

- (void)tcpClientDidError:(NSString *)error
{
	[self clearSendQueue];

	[[self remoteObjectProxy] ircConnectionDidError:error];
}

- (void)tcpClientDidDisconnect:(nullable NSError *)disconnectError
{
	[self disconnectTeardown];

	[[self remoteObjectProxy] ircConnectionDidDisconnectWithError:disconnectError];
}

- (void)tcpClientDidReceiveData:(NSData *)data
{
	[[self remoteObjectProxy] ircConnectionDidReceiveData:data];
}

- (void)tcpClientRequestInsecureCertificateTrust:(GCDAsyncSocketTrustResponseCompletionBlock)trustBlock
{
	[[self remoteObjectProxy] ircConnectionRequestInsecureCertificateTrust:trustBlock];
}

- (void)tcpClientWillSendData:(NSData *)data
{
	[[self remoteObjectProxy] ircConnectionWillSendData:data];
}

- (void)tcpClientDidSendData
{
	self.isSending = NO;

	[[self remoteObjectProxy] ircConnectionDidSendData];

	(void)[self tryToSend];
}

@end

NS_ASSUME_NONNULL_END
