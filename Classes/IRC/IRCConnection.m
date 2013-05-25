/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

/* The actual socket is handled by IRCConnectionSocket.m,
 which is an extension of this class. */

@implementation IRCConnection

#pragma mark -
#pragma mark Initialization 

- (id)init
{
	if ((self = [super init])) {
		self.sendQueue = [NSMutableArray new];
		
		self.floodTimer = [TLOTimer new];
		self.floodTimer.delegate = self;
        self.floodTimer.selector = @selector(timerOnTimer:);

		self.floodControlCurrentMessageCount = 0;

		self.socketBuffer = [NSMutableData new];
	}
	
	return self;
}

- (void)dealloc
{
	[self close];
}

#pragma mark -
#pragma mark Open/Close Connection

- (void)open
{
	[self close]; // Reset state.

	[self startTimer];
	[self openSocket];
}

- (void)close
{
	self.isConnected = NO;
	self.isConnecting = NO;
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
	return [self.client convertFromCommonEncoding:data];
}

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	return [self.client convertToCommonEncoding:data];
}

#pragma mark -
#pragma mark Send Data

- (void)sendLine:(NSString *)line
{
	/* PONG replies are extremely important. There is no reason they should be
	 placed in the flood control queue. This writes them directly to the socket
	 instead of actuallying waiting for the queue. We only need this check if
	 we actually have flood control enabled. */
	if (self.connectionUsesFloodControl) {
		BOOL isPong = [line hasPrefix:IRCPrivateCommandIndex("pong")];

		if (isPong) {
			NSString *firstItem = [line stringByAppendingString:@"\r\n"];

			NSData *data = [self convertToCommonEncoding:firstItem];

			if (data) {
				[self write:data];

				return;
			}
		}
	}

	/* Normal send. */
	[self.sendQueue safeAddObject:line];

	[self tryToSend];
}

- (BOOL)tryToSend
{
	/* Build the queue if we are already sending… */
	NSAssertReturnR((self.isSending == NO), NO);

	NSObjectIsEmptyAssertReturn(self.sendQueue, NO);

	/* We are not sending so we need to check our numbers. */
	/* Only count flood control once we are fully connected since the initial connect
	 will flood the server regardless so we do not want to timeout waiting for ourself. */
	if (self.connectionUsesFloodControl && self.client.isLoggedIn) {
		if (self.floodControlCurrentMessageCount > self.floodControlMaximumMessageCount) {
			/* The number of lines sent during our timer period has gone above the 
			 maximum allowed count so we have to return NO to let everyone know we
			 cannot send at this point. */

			return NO;
		}

		self.floodControlCurrentMessageCount += 1;
	}

	/* Send next line. */
	[self sendNextLine];
	
	return YES;
}

- (void)sendNextLine
{
	NSObjectIsEmptyAssert(self.sendQueue);

	NSString *firstItem = [self.sendQueue[0] stringByAppendingString:@"\r\n"];

	[self.sendQueue safeRemoveObjectAtIndex:0];

	NSData *data = [self convertToCommonEncoding:firstItem];

	if (data) {
		self.isSending = YES;

		[self write:data];

		if ([self.client respondsToSelector:@selector(ircConnectionWillSend:)]) {
			[self.client ircConnectionWillSend:firstItem];
		}
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
	if (self.floodTimer.timerIsActive == NO) {
		if (self.connectionUsesFloodControl) {
			[self.floodTimer start:self.floodControlDelayInterval];
		}
	}
}

- (void)stopTimer
{
	if (self.floodTimer.timerIsActive) {
		[self.floodTimer stop];
	}
}

- (void)timerOnTimer:(id)sender
{
	self.floodControlCurrentMessageCount = 0;

	while ([self tryToSend] == YES) {
		// …
	}
}

#pragma mark -
#pragma mark Socket Delegate

- (void)tcpClientDidConnect
{
	[self clearSendQueue];
	
	if ([self.client respondsToSelector:@selector(ircConnectionDidConnect:)]) {
		[self.client ircConnectionDidConnect:self];
	}
}

- (void)tcpClientDidError:(NSString *)error
{
	[self clearSendQueue];
	
	if ([self.client respondsToSelector:@selector(ircConnectionDidError:)]) {
		[self.client ircConnectionDidError:error];
	}
}

- (void)tcpClientDidDisconnect
{
	[self clearSendQueue];
	
	if ([self.client respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
		[self.client ircConnectionDidDisconnect:self];
	}
}

- (void)tcpClientDidReceiveData
{
	while (1 == 1) {
		NSString *data = [self readLine];
		
		if (data == nil) {
			break;
		}
		
		if ([self.client respondsToSelector:@selector(ircConnectionDidReceive:)]) {
			[self.client ircConnectionDidReceive:data];
		}
	}
}

- (void)tcpClientDidSendData
{
	self.isSending = NO;
	
	[self tryToSend];
}

@end
