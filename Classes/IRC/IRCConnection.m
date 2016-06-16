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

#import "TextualApplication.h"

#import "IRCConnectionPrivate.h"

/* The actual socket is handled by IRCConnectionSocket.m,
 which is an extension of this class. */

@implementation IRCConnection

#pragma mark -
#pragma mark Initialization 

- (instancetype)init
{
	if ((self = [super init])) {
		self.sendQueue = [NSMutableArray new];
		
		self.floodTimer = [TLOTimer new];
		
		[self.floodTimer setTarget:self];
		[self.floodTimer setAction:@selector(timerOnTimer:)];
		
		self.floodControlCurrentMessageCount = 0;
	}
	
	return self;
}

- (void)dealloc
{
	[self.floodTimer stop];
	[self.floodTimer setTarget:nil];

	[self close];
}

#pragma mark -
#pragma mark Open/Close Connection

- (void)open
{
	[self startTimer];

	[self openSocket];
}

- (void)close
{
	self.isSending = NO;

	self.floodControlCurrentMessageCount = 0;

	[self.sendQueue removeAllObjects];
	
	[self stopTimer];
	
	[self closeSocket];
}

#pragma mark -
#pragma mark Encode Data

- (NSString *)convertFromCommonEncoding:(NSData *)data
{
	return [self.associatedClient convertFromCommonEncoding:data];
}

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	return [self.associatedClient convertToCommonEncoding:data];
}

#pragma mark -
#pragma mark Send Data

- (void)sendLine:(NSString *)line
{
	/* PONG replies are extremely important. There is no reason they should be
	 placed in the flood control queue. This writes them directly to the socket
	 instead of actuallying waiting for the queue. We only need this check if
	 we actually have flood control enabled. */
	BOOL isPong = [line hasPrefix:IRCPrivateCommandIndex("pong")];

	if (isPong) {
		[self sendData:line removeFromQueue:NO];

		return; // Exit from entering the queue.
	}

	/* Normal send. */
	[self.sendQueue addObject:line];

	[self tryToSend];
}

- (BOOL)tryToSend
{
	if (self.isSending) {
		return NO;
	}

	if ([self.sendQueue count] == 0) {
		return NO;
	}

	if ([self.associatedClient isLoggedIn]) {
		if (self.floodControlCurrentMessageCount >= self.floodControlMaximumMessageCount) {
			return NO;
		}

		self.floodControlCurrentMessageCount += 1;
	}

	[self sendNextLine];
	
	return YES;
}

- (void)sendNextLine
{
	if ([self.sendQueue count] > 0) {
		self.isSending = YES;

		[self sendData:self.sendQueue[0] removeFromQueue:YES];
	}
}

- (void)sendData:(NSString *)dataToSend
{
	[self sendData:dataToSend removeFromQueue:NO];
}

- (void)sendData:(NSString *)dataToSend removeFromQueue:(BOOL)removeFromQueue
{
	NSString *firstItem = [dataToSend stringByAppendingString:@"\x0d\x0a"];

	if (removeFromQueue) {
		[self.sendQueue removeObjectAtIndex:0];
	}

	NSData *data = [self convertToCommonEncoding:firstItem];

	if (data) {
		[self writeDataToSocket:data];

		[self.associatedClient ircConnectionWillSend:firstItem];
	}
}

- (void)clearSendQueue
{
	[self.sendQueue removeAllObjects];
}

#pragma mark -
#pragma mark Flood Control Timer

- (void)startTimer
{
	if ([self.floodTimer timerIsActive] == NO) {
		[self.floodTimer start:self.floodControlDelayInterval];
	}
}

- (void)stopTimer
{
	if ([self.floodTimer timerIsActive]) {
		[self.floodTimer stop];
	}
}

- (void)timerOnTimer:(id)sender
{
	self.floodControlCurrentMessageCount = 0;

	while ([self tryToSend] == YES) {
		;
	}
}

#pragma mark -
#pragma mark Socket Delegate

- (void)tcpClientDidConnect
{
	[self clearSendQueue];
	
	[self.associatedClient ircConnectionDidConnect:self];
}

- (void)tpcClientWillConnectToProxy:(NSString *)proxyHost port:(NSInteger)proxyPort
{
	[self.associatedClient ircConnectionWillConnectToProxy:proxyHost port:proxyPort];
}

- (void)tcpClientDidError:(NSString *)error
{
	[self clearSendQueue];
	
	[self.associatedClient ircConnectionDidError:error];
}

- (void)tcpClientDidDisconnect:(NSError *)distcError
{
	[self clearSendQueue];
	
	[self.associatedClient ircConnectionDidDisconnect:self withError:distcError];
}

- (void)tcpClientDidReceiveData:(NSString *)data
{
	[self.associatedClient ircConnectionDidReceive:data];
}

- (void)tcpClientDidSecureConnection
{
	[self.associatedClient ircConnectionDidSecureConnection];
}

- (void)tcpClientDidReceivedAnInsecureCertificate
{
	[self.associatedClient ircConnectionDidReceivedAnInsecureCertificate];
}

- (void)tcpClientDidSendData
{
	self.isSending = NO;
	
	[self tryToSend];
}

@end
