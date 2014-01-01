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

#define RECORDS_LEN     10
#define MAX_QUEUE_SIZE  2
#define BUF_SIZE        (1024 * 64)
#define RATE_LIMIT      (1024 * 1024 * 5)

#import "TextualApplication.h"

@implementation TDCFileTransferDialogTransferSender

#pragma mark -
#pragma mark Initialization

- (void)createDispatchQueues
{
	NSString *uniqueID = [NSString stringWithUUID];
	
	NSString *serverDispatchQueueName = [NSString stringWithFormat:@"DCCServerDispatchQueue-%@", uniqueID];
	NSString *serverSocketQueueName = [NSString stringWithFormat:@"DCCServerSocketQueue-%@", uniqueID];
	
	_serverDispatchQueue = dispatch_queue_create([serverDispatchQueueName UTF8String], NULL);
	_serverSocketQueue = dispatch_queue_create([serverSocketQueueName UTF8String], NULL);
}

- (void)destroyDispatchQueues
{
	if (self.serverSocketQueue) {
		dispatch_release(self.serverSocketQueue);
		
		_serverSocketQueue = nil;
	}
	
	if (self.serverDispatchQueue) {
		dispatch_release(self.serverDispatchQueue);
		
		_serverDispatchQueue = nil;
	}
}

- (void)prepareForDestruction
{
	[self close];
}

#pragma mark -
#pragma mark Opening/Closing Transfer

- (void)open
{
	/* Important check. */
	NSString *senderAddress = [self.transferDialog cachedIPAddress];
	
	if (senderAddress == nil) {
		[self setDidErrorOnBadSenderAddress];

		return; // Break chain.
	}
		
	/* Reset information. */
	[self close];
	
	[self resetProperties];
	[self createDispatchQueues];
	
	_sendQueueSize = 0;
	
	/* Establish status. */
	self.transferStatus = TDCFileTransferDialogTransferInitializingStatus;
	
	/* Try to find an open port and open. */
	self.transferPort = [TPCPreferences fileTransferPortRangeStart];
	
	while ([self tryToOpen] == NO) {
        self.transferPort += 1;
		
		if (self.transferPort > [TPCPreferences fileTransferPortRangeEnd]) {
			self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
			
			self.errorMessageToken = @"FileTransferDialogTransferFailedWithUnavailablePort";
        
			[self close]; // Destroy everything.
			
			return; // Break the chain.
		}
    }
	
	/* Update status information. */
	[self reloadStatusInformation];
}

- (BOOL)tryToOpen
{
	/* Create the server and try opening it. */
	_socketServer = [GCDAsyncSocket socketWithDelegate:self
										 delegateQueue:self.serverDispatchQueue
										   socketQueue:self.serverSocketQueue];
	
	BOOL isActive = [self.socketServer acceptOnPort:self.transferPort error:NULL]; // We only care about return not error.
	
	/* Are we listening on the port? */
	if (isActive) {
		self.transferStatus = TDCFileTransferDialogTransferListeningStatus;
		
		if ([self openFileHandle]) {
			[self sendTransferRequestToClient];
		}
		
		return YES;
	}
	
	return NO; // Return bad port error.
}

- (void)sendTransferRequestToClient
{
	/* We will send actual request to the user from here. */
	NSDictionary *fileAttrs = [RZFileManager() attributesOfItemAtPath:[self completePath] error:NULL];
	
	/* If we had problem reading file, then we need to stop now… */
	if (PointerIsEmpty(fileAttrs))
	{
		self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
		
		self.errorMessageToken = @"FileTransferDialogTransferFailedWithBadFileHandle";
	
		[self close]; // We failed to read file, no reason to continue…
	
		return; // Break chain.
	}
	
	/* Send to user. */
	TXFSLongInt filesize = [fileAttrs longLongForKey:NSFileSize];
	
	[self.associatedClient sendFile:self.peerNickname
							   port:self.transferPort
						   filename:self.filename
							   size:filesize];
}

- (void)close
{
	/* Destroy sockets. */
    if (self.socketServer) {
		[self.socketServer disconnect];
		     _socketServer = nil;
	}
	
	if (self.client) {
		[self.client disconnect];
		     _client = nil;
	}
	
	[self destroyDispatchQueues];
	
	/* Close the file. */
    [self closeFileHandle];
	
	/* Update status. */
	if (NSDissimilarObjects(self.transferStatus, TDCFileTransferDialogTransferErrorStatus) &&
		NSDissimilarObjects(self.transferStatus, TDCFileTransferDialogTransferCompleteStatus))
	{
		self.transferStatus = TDCFileTransferDialogTransferStoppedStatus;
	}
	
	/* Update status information. */
	[self.transferDialog updateMaintenanceTimer];
	
	[self reloadStatusInformation];
}

- (void)setDidErrorOnBadSenderAddress
{
	/* Update status. */
	self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
	
	self.errorMessageToken = @"FileTransferDialogTransferFailedWithBadSourceAddress";
	
	/* Close anything that's open. */
	[self close];
}

#pragma mark -
#pragma mark Timer

- (void)onMaintenanceTimer
{
	NSAssertReturn(self.transferStatus == TDCFileTransferDialogTransferSendingStatus);
	
	/* Update record. */
	[self.speedRecords addObject:@(self.currentRecord)];
	
	if ([self.speedRecords count] > RECORDS_LEN) {
		[self.speedRecords removeObjectAtIndex:0];
	}
	
	self.currentRecord = 0;
	
	/* Update progress. */
	[self.progressIndicator setDoubleValue:self.processedFilesize];
	
	[self reloadStatusInformation];
	
	/* Send more. */
    [self send];
}

#pragma mark -
#pragma mark File Handle

- (BOOL)openFileHandle
{
	/* Try to create file handle. */
	self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:[self completePath]];
	
	if (PointerIsEmpty(self.fileHandle)) {
		/* There was a problem opening the file handle. */
		self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
		
		self.errorMessageToken = @"FileTransferDialogTransferFailedWithBadFileHandle";
		
		[self close]; // Destroy the socket if it is open.
		
		return NO;
	}
	
	return YES;
}

- (void)closeFileHandle
{
	PointerIsEmptyAssert(self.fileHandle);
	
	[self.fileHandle closeFile];
	 self.fileHandle = nil;
}

#pragma mark -
#pragma mark Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	/* Do not accept more than a single connection on this port. */
	PointerIsNotEmptyAssert(self.client);
	
	/* Maintain reference to client. */
	_client = newSocket;
	
	/* Update status. */
	self.transferStatus = TDCFileTransferDialogTransferSendingStatus;
	
	[self reloadStatusInformation];
	
	[self.transferDialog updateMaintenanceTimer];
	
	/* Start pushing data. */
	[self send];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	/* Handle disconnects. */
	if (self.transferStatus == TDCFileTransferDialogTransferCompleteStatus ||
		self.transferStatus == TDCFileTransferDialogTransferErrorStatus)
	{
		return; // Do not worry about these status items.
	}
	
	/* Log any errors to console. */
	if (err) {
		LogToConsole(@"DCC Transfer Error: %@", [err localizedDescription]);
	}
	
	/* Normal operations. */
	self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
	
	self.errorMessageToken = @"FileTransferDialogTransferFailedWithUnknownDisconnect";
	
	/* Clean up the sockets. */
	[self close];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	_sendQueueSize -= 1;
	
	if (self.processedFilesize >= self.totalFilesize) {
		if (self.sendQueueSize <= 0) {
			self.transferStatus = TDCFileTransferDialogTransferCompleteStatus;
			
			[self reloadStatusInformation];
		}
	} else {
		[self send];
	}
}

#pragma mark -
#pragma mark Socket Write

- (void)send
{
	/* Important checks. */
	if (self.transferStatus == TDCFileTransferDialogTransferCompleteStatus) {
		return; // Break chain.
	}
	
	if (self.processedFilesize > self.totalFilesize) {
		return; // Break chain.
	}
	
	PointerIsEmptyAssert(self.client);
	
    while (1) {
        if (self.currentRecord >= RATE_LIMIT) {
			return; // Break chain.
		}
		
        if (self.sendQueueSize >= MAX_QUEUE_SIZE) {
			return; // Break chain.
		}
		
		if (self.processedFilesize >= self.totalFilesize) {
			[self closeFileHandle]; // Close the handle to this file.
			
			return; // Break chain.
		}
		
		/* Perform write to socket. */
        NSData *data = [self.fileHandle readDataOfLength:BUF_SIZE];
		
		self.processedFilesize += [data length];
		self.currentRecord += [data length];
		
		_sendQueueSize += 1;
		
		[self.client writeData:data withTimeout:30 tag:0];
    }
}

@end
