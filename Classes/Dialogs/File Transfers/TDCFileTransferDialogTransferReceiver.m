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

#define RECORDS_LEN			10

@implementation TDCFileTransferDialogTransferReceiver

#pragma mark -
#pragma mark Initialization

- (void)createDispatchQueues
{
	NSString *uniqueID = [NSString stringWithUUID];
	
	NSString *clientDispatchQueueName = [NSString stringWithFormat:@"DCC-ClientDispatchQueue-%@", uniqueID];
	NSString *clientSocketQueueName = [NSString stringWithFormat:@"DCC-ClientSocketQueue-%@", uniqueID];
	
	_clientDispatchQueue = dispatch_queue_create([clientDispatchQueueName UTF8String], NULL);
	_clientSocketQueue = dispatch_queue_create([clientSocketQueueName UTF8String], NULL);
}

- (void)destroyDispatchQueues
{
	if (self.clientSocketQueue) {
		dispatch_release(self.clientSocketQueue);
		
		_clientSocketQueue = nil;
	}
	
	if (self.clientDispatchQueue) {
		dispatch_release(self.clientDispatchQueue);
		
		_clientDispatchQueue = nil;
	}
}

- (void)prepareForDestruction
{
	[self close:NO];
}

- (void)updateTransferInformationWithNonexistentFilename
{
	/* Gather base information. */
	NSString *nameWOExtension = [self.filename stringByDeletingPathExtension];
	NSString *filenameExtension = [self.filename pathExtension];
	
	NSString *filepath = [self completePath];
	
	NSInteger i = 1;
	
	/* Loop until we find a name that does not exist. */
	while ([RZFileManager() fileExistsAtPath:filepath]) {
		NSString *newFilename = [NSString stringWithFormat:@"%@_%d.%@", nameWOExtension, i, filenameExtension];
		
		filepath = [self.path stringByAppendingPathComponent:newFilename];
		
		i += 1;
	}
	
	/* Update filename if we have to… */
	if (i > 1) {
		self.filename = [filepath lastPathComponent];
	}
}

#pragma mark -
#pragma mark Opening/Closing Transfer

- (void)open
{
	/* Reset information. */
	[self close:NO];
	
	[self resetProperties];
	[self createDispatchQueues];
	
	/* Establish status. */
	self.transferStatus = TDCFileTransferDialogTransferConnectingStatus;
	
	/* Try to establish connection. */
	_client = [GCDAsyncSocket socketWithDelegate:self
								   delegateQueue:self.clientDispatchQueue
									 socketQueue:self.clientSocketQueue];
	
	NSError *connError;
	
	if ([self.client connectToHost:self.hostAddress onPort:self.transferPort withTimeout:30.0 error:&connError] == NO)
	{
		/* Could not establish base connection, error. */
		self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
		
		self.errorMessageToken = @"FileTransferDialogTransferFailedWithBadSenderConnect";
		
		/* Log error to console. */
		if (connError) {
			LogToConsole(@"DCC Connect Error: %@", [connError localizedDescription]);
		}
		
		[self close]; // Destroy everything.
		
		return; // Break chain.
	}
	
	/* Update status information. */
	[self reloadStatusInformation];
}

- (void)close
{
	[self close:YES];
}

- (void)close:(BOOL)postNotifications
{
	/* Destroy sockets. */
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
	
	/* Post notification. */
	if (postNotifications) {
		if (self.transferStatus == TDCFileTransferDialogTransferErrorStatus) {
			[self.associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveFailedType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize];
		}
	}
	
	/* Update status information. */
	[self.transferDialog updateMaintenanceTimer];
	
	[self reloadStatusInformation];
}

#pragma mark -
#pragma mark Timer

- (void)onMaintenanceTimer
{
	NSAssertReturn(self.transferStatus == TDCFileTransferDialogTransferReceivingStatus);
	
	/* Update record. */
	[self.speedRecords addObject:@(self.currentRecord)];
	
	if ([self.speedRecords count] > RECORDS_LEN) {
		[self.speedRecords removeObjectAtIndex:0];
	}
	
	self.currentRecord = 0;
	
	/* Update progress. */
	[self.progressIndicator setDoubleValue:self.processedFilesize];
	
	[self reloadStatusInformation];
}

#pragma mark -
#pragma mark File Handle

- (void)openFileHandle
{
	/* Make sure we are doing something on a file that doesn't exist. */
	[self updateTransferInformationWithNonexistentFilename];
	
	/* Create the file. */
	[RZFileManager() createFileAtPath:[self completePath] contents:[NSData data] attributes:nil];
	
	/* Try to create file handle. */
	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self completePath]];
	
	if (PointerIsEmpty(self.fileHandle)) {
		/* There was a problem opening the file handle. */
		self.transferStatus = TDCFileTransferDialogTransferErrorStatus;
		
		self.errorMessageToken = @"FileTransferDialogTransferFailedWithBadFileHandle";
		
		[self close]; // Destroy the socket if it is open.
	}
}

- (void)closeFileHandle
{
	PointerIsEmptyAssert(self.fileHandle);
	
	[self.fileHandle closeFile];
	 self.fileHandle = nil;
}

#pragma mark -
#pragma mark Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	/* Update status. */
	self.transferStatus = TDCFileTransferDialogTransferReceivingStatus;
	
	[self reloadStatusInformation];
	
	[self.transferDialog updateMaintenanceTimer];
	
	/* Open file handle. */
	[self openFileHandle];
	
	/* Tell socket to prepare for read. */
	[self.client readDataWithTimeout:(-1) tag:0];
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

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	/* Update stats. */
	self.processedFilesize += [data length];
	self.currentRecord += [data length];
	
	/* Write data to file. */
	if ([data length] > 0) {
		[self.fileHandle writeData:data];
	}
	
	/* Tell socket to prepare for read. */
	[self.client readDataWithTimeout:(-1) tag:0];
	
	/* Send acknowledgement back to server. */
    uint32_t rsize = (self.processedFilesize & 0xFFFFFFFF);
	
    unsigned char ack[4];
	
    ack[0] = ((rsize >> 24) & 0xFF);
    ack[1] = ((rsize >> 16) & 0xFF);
    ack[2] = ((rsize >>  8) & 0xFF);
    ack[3] =  (rsize & 0xFF);
	
	[self.client writeData:[NSData dataWithBytes:ack length:4]
			   withTimeout:(-1)
					   tag:0];
	
	/* Did we complete transfer? */
    if (self.processedFilesize >= self.totalFilesize) {
		self.transferStatus = TDCFileTransferDialogTransferCompleteStatus;
		
		[self.associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveSuccessfulType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize];
			
		[self close]; // Close Connection
    }
}

@end
