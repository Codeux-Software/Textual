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
		_sendQueue = [NSMutableArray new];
		
		_floodTimer = [TLOTimer new];
		
		[_floodTimer setDelegate:self];
		[_floodTimer setSelector:@selector(timerOnTimer:)];
		
		_floodControlCurrentMessageCount = 0;
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
	[self startTimer];

	[self openSocket];
}

- (void)close
{
	_isConnected = NO;
	_isConnecting = NO;
	_isSending = NO;

	_floodControlCurrentMessageCount = 0;

	[_sendQueue removeAllObjects];
	
	[self stopTimer];
	
	[self closeSocket];
}

#pragma mark -
#pragma mark Encode Data

- (NSString *)convertFromCommonEncoding:(NSData *)data
{
	return [_associatedClient convertFromCommonEncoding:data];
}

- (NSData *)convertToCommonEncoding:(NSString *)data
{
	return [_associatedClient convertToCommonEncoding:data];
}

#pragma mark -
#pragma mark Send Data

- (void)sendLine:(NSString *)line
{
	/* PONG replies are extremely important. There is no reason they should be
	 placed in the flood control queue. This writes them directly to the socket
	 instead of actuallying waiting for the queue. We only need this check if
	 we actually have flood control enabled. */
	if (_connectionUsesOutgoingFloodControl) {
		BOOL isPong = [line hasPrefix:IRCPrivateCommandIndex("pong")];

		if (isPong) {
			NSString *firstItem = [line stringByAppendingFormat:@"%c%c", 0x0d, 0x0a];

			NSData *data = [self convertToCommonEncoding:firstItem];

			if (data) {
				[self write:data];

				[_associatedClient ircConnectionWillSend:firstItem];

				return; // Exit from entering the queue.
			}
		}
	}

	/* Normal send. */
	[_sendQueue addObject:line];

	[self tryToSend];
}

- (BOOL)tryToSend
{
	if (_isSending) {
		return NO;
	}

	if ([_sendQueue count] == 0) {
		return NO;
	}

	if ([_associatedClient isLoggedIn]) {
		if (_connectionUsesOutgoingFloodControl) {
			if (_floodControlCurrentMessageCount >= _floodControlMaximumMessageCount) {
				return NO;
			}

			_floodControlCurrentMessageCount += 1;
		}
	}

	[self sendNextLine];
	
	return YES;
}

- (void)sendNextLine
{
	if ([_sendQueue count] > 0) {
		NSString *firstItem = [_sendQueue[0] stringByAppendingFormat:@"%c%c", 0x0d, 0x0a];

		[_sendQueue removeObjectAtIndex:0];

		NSData *data = [self convertToCommonEncoding:firstItem];

		if (data) {
			_isSending = YES;

			[self write:data];

			[_associatedClient ircConnectionWillSend:firstItem];
		}
	}
}

- (void)clearSendQueue
{
	[_sendQueue removeAllObjects];
}

#pragma mark -
#pragma mark Flood Control Timer

- (void)startTimer
{
	if (_connectionUsesOutgoingFloodControl) {
		if ([_floodTimer timerIsActive] == NO) {
			[_floodTimer start:self.floodControlDelayInterval];
		}
	}
}

- (void)stopTimer
{
	if ([_floodTimer timerIsActive]) {
		[_floodTimer stop];
	}
}

- (void)timerOnTimer:(id)sender
{
	_floodControlCurrentMessageCount = 0;

	while ([self tryToSend] == YES) {
		// …
	}
}

#pragma mark -
#pragma mark Socket Delegate

- (void)tcpClientDidConnect
{
	[self clearSendQueue];
	
	[_associatedClient ircConnectionDidConnect:self];
}

- (void)tcpClientDidError:(NSString *)error
{
	[self clearSendQueue];
	
	[_associatedClient ircConnectionDidError:error];
}

- (void)tcpClientDidDisconnect:(NSError *)distcError
{
	[self clearSendQueue];
	
	[_associatedClient ircConnectionDidDisconnect:self withError:distcError];
}

- (void)tcpClientDidReceiveData:(NSString *)data
{
	[_associatedClient ircConnectionDidReceive:data];
}

- (void)tcpClientDidSecureConnection
{
	[_associatedClient ircConnectionDidSecureConnection];
}

- (void)tcpClientDidSendData
{
	_isSending = NO;
	
	[self tryToSend];
}

@end
