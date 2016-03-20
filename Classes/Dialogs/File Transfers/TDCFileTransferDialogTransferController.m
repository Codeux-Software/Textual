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

/*
	 The method -networkInterfaceMatchingAddress available below is
	 borrowed from a Stack Overflow comment located at the URL:
	 
	 <http://stackoverflow.com/a/12883978>
	 
	 As no license is specified, it is believed to be released
	 into the Public Domain. Thank you very much to the user that
	 contributed the particular snippet of code.
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>

#define RECORDS_LEN     10
#define MAX_QUEUE_SIZE  2
#define BUF_SIZE        (1024 * 64)
#define RATE_LIMIT      (1024 * 1024 * 5)

#define _connectTimeout			30.0
#define _sendDataTimeout		30.0
#define _resumeAcceptTimeout	6.0

#import "TextualApplication.h"

@implementation TDCFileTransferDialogTransferController

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		self.transferStatus = TDCFileTransferDialogTransferStoppedStatus;
		
		self.speedRecords = [NSMutableArray new];
	}
	
	return self;
}

- (void)createDispatchQueues
{
	NSString *uniqueID = [NSString stringWithUUID];
	
	NSString *clientDispatchQueueName = [NSString stringWithFormat:@"DCC-SocketDispatchQueue-%@", uniqueID];
	NSString *clientSocketQueueName = [NSString stringWithFormat:@"DCC-SocketReadWriteQueue-%@", uniqueID];

	self.serverDispatchQueue = dispatch_queue_create([clientDispatchQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
	self.serverSocketQueue = dispatch_queue_create([clientSocketQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
}

- (void)destroyDispatchQueues
{
	if (self.serverSocketQueue) {
		self.serverSocketQueue = nil;
	}

	if (self.serverDispatchQueue) {
		self.serverDispatchQueue = nil;
	}
}

- (void)prepareForDestruction
{
	self.parentCell = nil;
	self.transferDialog = nil;

	[self close:NO];
}

- (void)postErrorWithErrorMessage:(NSString *)errorToken
{
	[self postErrorWithErrorMessage:errorToken isFatalError:NO];
}

- (void)postErrorWithErrorMessage:(NSString *)errorToken isFatalError:(BOOL)isFatalError
{
	if (isFatalError) {
		self.transferStatus = TDCFileTransferDialogTransferFatalErrorStatus;
	} else {
		self.transferStatus = TDCFileTransferDialogTransferRecoverableErrorStatus;
	}

	self.errorMessageToken = errorToken;

	[self close]; // Destroy everything.
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
		NSString *newFilename = nil;

		if ([filenameExtension length] > 0) {
			newFilename = [NSString stringWithFormat:@"%@_%ld.%@", nameWOExtension, (long)i, filenameExtension];
		} else {
			newFilename = [NSString stringWithFormat:@"%@_%ld", nameWOExtension, (long)i];
		}
		
		filepath = [self.path stringByAppendingPathComponent:newFilename];
		
		i += 1;
	}
	
	/* Update filename if we have to... */
	if (i > 1) {
		self.filename = [filepath lastPathComponent];
	}
}

#pragma mark -
#pragma mark Opening/Closing Transfer

- (void)beginPreventingSystemSleep
{
	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		self.transferProgressHandler = [RZProcessInfo() beginActivityWithOptions:NSActivityUserInitiated reason:@"Transferring file"];
	}
}

- (void)endPreventingSystemSleep
{
	if (self.transferProgressHandler) {
		[RZProcessInfo() endActivity:self.transferProgressHandler];
		
		self.transferProgressHandler = nil;
	}
}

- (void)open
{
	if ([self isSender]) {
		[self openTransfer];
	} else {
		[self sendTransferResumeRequestToClient];
	}
}

- (void)openTransfer
{
	if ([self isSender]) {
		if ([self isReversed]) {
			[self requestLocalIPAddress];
		} else {
			[self openConnectionAsServer];
		}
	} else {
		if ([self isReversed]) {
			[self openConnectionAsServer];
		} else {
			[self openConnectionToHost];
		}
	}
}

- (void)openConnectionToHost
{
	/* Reset information. */
	[self close:NO];

	[self resetProperties];

	[self createDispatchQueues];
	
	/* Establish status. */
	self.transferStatus = TDCFileTransferDialogTransferConnectingStatus;
	
	/* Try to establish connection. */
	self.connectionToRemoteServer = [GCDAsyncSocket socketWithDelegate:self
													 delegateQueue:self.serverDispatchQueue
													   socketQueue:self.serverSocketQueue];
	
	NSError *connError = nil;
	
	BOOL isConnected = NO;
	
	/* Use the interface of the configured IP address instead of the default. */
	/* Default interface is used if IP address is not found locally. */
	NSString *networkInterface = [self networkInterfaceMatchingAddress];
	
	if (networkInterface) {
		isConnected = [self.connectionToRemoteServer connectToHost:self.hostAddress onPort:self.transferPort viaInterface:networkInterface withTimeout:_connectTimeout error:&connError];
	} else {
		isConnected = [self.connectionToRemoteServer connectToHost:self.hostAddress onPort:self.transferPort withTimeout:_connectTimeout error:&connError];
	}
	
	if (isConnected == NO)
	{
		/* Log error to console. */
		if (connError) {
			LogToConsole(@"DCC Connect Error: %@", [connError localizedDescription]);
		}

		/* Could not establish base connection, error. */
		[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1016]"];
		
		return; // Break chain.
	}
	
	/* Update status information. */
	[self reloadStatusInformation];
	
	[self beginPreventingSystemSleep];
}

- (void)openConnectionAsServer
{
	/* Reset information. */
	[self close:NO];

	[self resetProperties];

	[self createDispatchQueues];

	/* Establish status. */
	self.transferStatus = TDCFileTransferDialogTransferInitializingStatus;

	/* Try to find an open port and open. */
	self.transferPort = [TPCPreferences fileTransferPortRangeStart];

	while ([self tryToOpenConnectionAsServer] == NO) {
        self.transferPort += 1;

		if (self.transferPort > [TPCPreferences fileTransferPortRangeEnd]) {
			[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1017]"];

			return; // Break the chain.
		}
    }

	/* Update status information. */
	[self reloadStatusInformation];
	
	[self beginPreventingSystemSleep];
}

- (BOOL)tryToOpenConnectionAsServer
{
	/* Create the server and try opening it. */
	self.listeningServer = [GCDAsyncSocket socketWithDelegate:self
											delegateQueue:self.serverDispatchQueue
											  socketQueue:self.serverSocketQueue];

	BOOL isActive = [self.listeningServer acceptOnPort:self.transferPort error:NULL]; // We only care about return not error.

	/* Are we listening on the port? */
	if (isActive) {
		/* Try to map the port. */
		self.portMapping = [[XRPortMapper alloc] initWithPort:self.transferPort];

		[self.portMapping setMapTCP:YES];
		[self.portMapping setMapUDP:NO];
		[self.portMapping setDesiredPublicPort:self.transferPort];

		[RZNotificationCenter() addObserver:self selector:@selector(portMapperDidFinishWork:) name:XRPortMapperDidChangedNotification object:self.portMapping];

		self.transferStatus = TDCFileTransferDialogTransferMappingListeningPortStatus;

		[self reloadStatusInformation];

		if ([self.portMapping open] == NO) {
			[self portMapperDidFinishWork:nil];
		}

		return YES;
	}

	return NO; // Return bad port error.
}

- (NSString *)networkInterfaceMatchingAddress
{
	struct ifaddrs *allInterfaces;

	NSStringEncoding cstringEncoding = [NSString defaultCStringEncoding];

	NSString *cachedAddress = [self.transferDialog cachedIPAddress];

	if (getifaddrs(&allInterfaces) == 0) {
		struct ifaddrs *interface;

		for (interface = allInterfaces; NSDissimilarObjects(interface, NULL); interface = interface->ifa_next)
		{
			unsigned int flags = interface->ifa_flags;

			struct sockaddr *addr = interface->ifa_addr;

			if ((flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING)) {
				if (addr->sa_family == AF_INET || addr->sa_family == AF_INET6) {
					char host[NI_MAXHOST];

					getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST);

					NSString *networkName = [NSString stringWithCString:interface->ifa_name encoding:cstringEncoding];
					NSString *networkAddr = [NSString stringWithCString:host encoding:cstringEncoding];

					if (NSObjectsAreEqual(networkAddr, cachedAddress)) {
						return networkName;
					}
				}
			}
		}

		freeifaddrs(allInterfaces);
	}

	return nil;
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification
{
	NSAssertReturn(self.transferStatus == TDCFileTransferDialogTransferMappingListeningPortStatus);

	if ([self.portMapping isMapped]) {
		[self requestLocalIPAddress];

		LogToConsole(@"Successful port mapping on port %i", self.transferPort);
	} else {
		LogToConsole(@"Port mapping failed with error code: %i", [self.portMapping error]);

		if ([self isReversed]) {
			[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1017]"];
		} else {
			/* If mapping fails, we silently fail. */
			/* We tried and it was successful, then that is good, but if we
			 did not, still start listening just incase other conditions allow
			 the transfer to still take place. */

			[self requestLocalIPAddress];
		}
	}
}

- (void)requestLocalIPAddress
{
	NSString *cachedIPAddress = [self.transferDialog cachedIPAddress];

	BOOL usesManualDetection = ([TPCPreferences fileTransferIPAddressDetectionMethod] == TXFileTransferIPAddressManualDetectionMethod);

	/* Important check. */
	if (cachedIPAddress == nil && usesManualDetection == NO) {
		if (self.portMapping) {
			NSString *external = [self.portMapping publicAddress];

			if ([external isIPAddress]) {
				[self.transferDialog setCachedIPAddress:external];

				cachedIPAddress = external;
			}
		}
	}

	/* Request address? */
	if (cachedIPAddress == nil) {
		if (usesManualDetection) {
			[self setDidErrorOnBadSenderAddress];
		} else {
			if ([self.transferDialog sourceIPAddressRequestPending] == NO) {
				[self.transferDialog requestIPAddressFromExternalSource];
			}

			self.transferStatus = TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus;

			[self reloadStatusInformation];
		}
	} else {
		[self localIPAddressWasDetermined];
	}
}

- (void)closePortMapping
{
	PointerIsEmptyAssert(self.portMapping);

	[RZNotificationCenter() removeObserver:self name:XRPortMapperDidChangedNotification object:self.portMapping];

	[self performBlockOnMainThread:^{
		[self.portMapping close];
		 self.portMapping = nil;
	}];
}

- (void)localIPAddressWasDetermined
{
	if ([self isSender]) {
		if ([self isReversed]) {
			self.transferStatus = TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus;
		} else {
			self.transferStatus = TDCFileTransferDialogTransferIsListeningAsSenderStatus;
		}
	} else {
		if ([self isReversed]) {
			self.transferStatus = TDCFileTransferDialogTransferIsListeningAsReceiverStatus;
		} else {
			return; // This condition is not possible.
		}
	}

	[self sendTransferRequestToClient];

	[self reloadStatusInformation];
}

- (void)didReceiveResumeRequestFromClient:(TXUnsignedLongLong)proposedPosition
{
	TXUnsignedLongLong currentFilesize = [self currentFilesize];

	if (proposedPosition <= 0 || currentFilesize < proposedPosition) {
		return;
	}

	self.isResume = YES;

	self.processedFilesize = proposedPosition;

	[self sendTransferResumeAcceptToClient];
}

- (void)didReceiveResumeAcceptFromClient:(TXUnsignedLongLong)proposedPosition
{
	[self cancelPerformRequestsWithSelector:@selector(transferResumeRequestTimeout) object:nil];

	TXUnsignedLongLong currentFilesize = [self currentFilesize];

	if (currentFilesize != proposedPosition) {
		[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1022]" isFatalError:YES];

		return;
	}

	self.isResume = YES;

	self.processedFilesize = currentFilesize;

	[self openConnectionToHost];
}

- (void)didReceiveSendRequestFromClient
{
	self.processedFilesize = 0;

	[self openConnectionToHost];
}

- (void)buildTransferToken
{
	NSInteger loopedCount = 0;

	while (self.transferToken == nil) {
		NSAssertReturnLoopBreak(loopedCount < 300);

		NSString *transferToken = [NSString stringWithInteger:TXRandomNumber(9999)];

		BOOL transferExists = [self.transferDialog fileTransferExistsWithToken:transferToken];

		if (transferExists == NO) {
			self.transferToken = transferToken;
		}

		loopedCount += 1; // Bump loop count.
	}
}

- (void)sendTransferRequestToClient
{
	if ([self isSender]) {
		/* We will send actual request to the user from here. */
		NSDictionary *fileAttrs = [RZFileManager() attributesOfItemAtPath:[self completePath] error:NULL];

		/* If we had problem reading file, then we need to stop now... */
		if (PointerIsEmpty(fileAttrs)) {
			[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1018]"];

			return; // Break chain.
		}

		/* Send to user. */
		TXUnsignedLongLong filesize = [fileAttrs longLongForKey:NSFileSize];

		/* Determine which type of message is sent... */
		if ([self isReversed]) {
			[self buildTransferToken];

			[self.associatedClient sendFile:self.peerNickname port:0 filename:self.filename filesize:filesize token:self.transferToken];
		} else {
			[self.associatedClient sendFile:self.peerNickname port:self.transferPort filename:self.filename filesize:filesize token:nil];
		}
	} else {
		if ([self isReversed]) {
			[self.associatedClient sendFile:self.peerNickname port:self.transferPort filename:self.filename filesize:self.totalFilesize token:self.transferToken];
		}
	}
}

- (void)sendTransferResumeRequestToClient
{
	TXUnsignedLongLong currentFilesize = [self currentFilesize];

	if (currentFilesize == 0 || currentFilesize > self.totalFilesize) {
		[self transferResumeRequestTimeout];

		return;
	}

	[self performSelector:@selector(transferResumeRequestTimeout) withObject:nil afterDelay:_resumeAcceptTimeout];

	self.transferStatus = TDCFileTransferDialogTransferWaitingForResumeAcceptStatus;

	[self reloadStatusInformation];

	if ([self isReversed]) {
		[self.associatedClient sendFileResume:self.peerNickname port:0 filename:self.filename filesize:currentFilesize token:self.transferToken];
	} else {
		[self.associatedClient sendFileResume:self.peerNickname port:self.transferPort filename:self.filename filesize:currentFilesize token:nil];
	}
}

- (void)sendTransferResumeAcceptToClient
{
	if ([self isReversed]) {
		[self.associatedClient sendFileResume:self.peerNickname port:0 filename:self.filename filesize:self.processedFilesize token:self.transferToken];
	} else {
		[self.associatedClient sendFileResume:self.peerNickname port:self.transferPort filename:self.filename filesize:self.processedFilesize token:nil];
	}
}

- (void)transferResumeRequestTimeout
{
	[self openTransfer];
}

- (void)close
{
	[self close:YES];
}

- (void)close:(BOOL)postNotifications
{
	/* Cancel perform requests */
	[self cancelPerformRequests];

	/* Destroy sockets. */
    if (self.listeningServer) {
	   [self.listeningServer disconnect];
			self.listeningServer = nil;
	}

	if (self.listeningServerConnectedClient) {
	   [self.listeningServerConnectedClient disconnect];
			self.listeningServerConnectedClient = nil;
	}

	if (self.connectionToRemoteServer) {
		[self.connectionToRemoteServer disconnect];
			 self.connectionToRemoteServer = nil;
	}

	[self destroyDispatchQueues];

	[self closePortMapping];

	/* Close the file. */
    [self closeFileHandle];

	/* Update status. */
	if (NSDissimilarObjects(self.transferStatus, TDCFileTransferDialogTransferCompleteStatus) &&
		NSDissimilarObjects(self.transferStatus, TDCFileTransferDialogTransferFatalErrorStatus) &&
		NSDissimilarObjects(self.transferStatus, TDCFileTransferDialogTransferRecoverableErrorStatus))
	{
		self.transferStatus = TDCFileTransferDialogTransferStoppedStatus;
	}

	/* Post notification. */
	if (postNotifications) {
		if (self.transferStatus == TDCFileTransferDialogTransferFatalErrorStatus ||
			self.transferStatus == TDCFileTransferDialogTransferRecoverableErrorStatus)
		{
			if ([self isSender]) {
				[self.associatedClient notifyFileTransfer:TXNotificationFileTransferSendFailedType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize requestIdentifier:[self uniqueIdentifier]];
			} else {
				[self.associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveFailedType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize requestIdentifier:[self uniqueIdentifier]];
			}
		}
	}

	/* Update status information. */
	[self.transferDialog updateMaintenanceTimer];

	[self reloadStatusInformation];

	[self endPreventingSystemSleep];
}

- (void)setDidErrorOnBadSenderAddress
{
	[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1019]"];
}

#pragma mark -
#pragma mark Timer

- (void)onMaintenanceTimer
{
	NSAssertReturn((self.transferStatus == TDCFileTransferDialogTransferReceivingStatus) ||
				   (self.transferStatus == TDCFileTransferDialogTransferSendingStatus));

	XRPerformBlockSynchronouslyOnQueue(self.serverDispatchQueue, ^{
		/* Update record. */
		@synchronized(self.speedRecords) {
			[self.speedRecords addObject:@(self.currentRecord)];
			
			if ([self.speedRecords count] > RECORDS_LEN) {
				[self.speedRecords removeObjectAtIndex:0];
			}
		}
		
		self.currentRecord = 0;
		
		/* Update progress. */
		[self reloadStatusInformation];
	});

	/* Send more. */
	if ([self isSender]) {
		[self send];
	}
}

#pragma mark -
#pragma mark File Handle

- (BOOL)openFileHandle
{
	/* Make sure we are doing something on a file that doesn't exist. */
	if ([self isSender] == NO && [self isResume] == NO) {
		/* Update filename. */
		[self updateTransferInformationWithNonexistentFilename];

		/* Create the file. */
		[RZFileManager() createFileAtPath:[self completePath] contents:[NSData data] attributes:nil];
	}
	
	/* Try to create file handle. */
	self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self completePath]];

	if (self.fileHandle == nil) {
		/* There was a problem opening the file handle. */
		[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1018]"];

		return NO;
	} else if ([self isResume]) {
		[self.fileHandle seekToFileOffset:self.processedFilesize];
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
	/* Check connection type. */
	NSAssertReturn([self isActingAsServer]);

	/* Do not accept more than a single connection on this port. */
	/* If we already have a client, then force disconnect anyone else that tries to join. */
	if (self.listeningServerConnectedClient) {
		[newSocket disconnect];
	}

	/* Maintain reference to client. */
	self.listeningServerConnectedClient = newSocket;

	/* Update status. */
	if ([self isReversed]) {
		self.transferStatus = TDCFileTransferDialogTransferReceivingStatus;
	} else {
		self.transferStatus = TDCFileTransferDialogTransferSendingStatus;
	}

	[self reloadStatusInformation];

	[self.transferDialog updateMaintenanceTimer];

	/* Open file handle. */
	(void)[self openFileHandle];

	/* Start pushing data. */
	if ([self isReversed] == NO) {
		if ([self isSender]) {
			[self send];
		}
	} else {
		if ([self isSender] == NO) {
			[self.listeningServerConnectedClient readDataWithTimeout:(-1) tag:0];
		}
	}
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	/* Check connection type. */
	NSAssertReturn([self isActingAsClient]);

	/* Update status. */
	if ([self isReversed]) {
		self.transferStatus = TDCFileTransferDialogTransferReceivingStatus;
	} else {
		self.transferStatus = TDCFileTransferDialogTransferSendingStatus;
	}
	
	[self reloadStatusInformation];
	
	[self.transferDialog updateMaintenanceTimer];

	/* Open file handle. */
	(void)[self openFileHandle];

	/* Start pushing data. */
	if ([self isReversed]) {
		if ([self isSender]) {
			[self send];
		}
	} else {
		if ([self isSender] == NO) {
			[self.connectionToRemoteServer readDataWithTimeout:(-1) tag:0];
		}
	}
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	/* Handle disconnects. */
	if (self.transferStatus == TDCFileTransferDialogTransferCompleteStatus ||
		self.transferStatus == TDCFileTransferDialogTransferFatalErrorStatus ||
		self.transferStatus == TDCFileTransferDialogTransferRecoverableErrorStatus)
	{
		return; // Do not worry about these status items.
	}
	
	/* Log any errors to console. */
	if (err) {
		LogToConsole(@"DCC Transfer Error: %@", [err localizedDescription]);
	}
	
	/* Normal operations. */
	[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1020]"];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	/* Check connection type. */
	NSAssertReturn([self isSender] == NO);

	/* Update stats. */
	self.processedFilesize += [data length];
	self.currentRecord += [data length];
	
	/* Write data to file. */
	if ([data length] > 0) {
		[self.fileHandle writeData:data];
	}

	/* Tell socket to prepare for read. */
	[[self readSocket] readDataWithTimeout:(-1) tag:0];

	/* Send acknowledgement back to server. */
    uint32_t rsize = (self.processedFilesize & 0xFFFFFFFF);
	
    unsigned char ack[4];
	
    ack[0] = ((rsize >> 24) & 0xFF);
    ack[1] = ((rsize >> 16) & 0xFF);
    ack[2] = ((rsize >>  8) & 0xFF);
    ack[3] =  (rsize & 0xFF);

	[[self readSocket] writeData:[NSData dataWithBytes:ack length:4] withTimeout:(-1) tag:0];
	
	/* Did we complete transfer? */
    if (self.processedFilesize >= self.totalFilesize) {
		self.transferStatus = TDCFileTransferDialogTransferCompleteStatus;
		
		[self.associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveSuccessfulType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize requestIdentifier:[self uniqueIdentifier]];
		
		[self close]; // Close Connection
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	/* Connection check. */
	NSAssertReturn([self isSender]);

	/* Update pending sends. */
	self.sendQueueSize -= 1;

	/* Update transfer information. */
	if (self.processedFilesize >= self.totalFilesize) {
		if (self.sendQueueSize <= 0) {
			self.transferStatus = TDCFileTransferDialogTransferCompleteStatus;

			[self.associatedClient notifyFileTransfer:TXNotificationFileTransferSendSuccessfulType nickname:self.peerNickname filename:self.filename filesize:self.totalFilesize requestIdentifier:[self uniqueIdentifier]];

			[self reloadStatusInformation];
		}
	} else {
		/* Try to write more data. */
		[self send];
	}
}

#pragma mark -
#pragma mark Socket Write

- (void)send
{
	/* Important checks. */
	NSAssertReturn([self isSender]);

	if (self.transferStatus == TDCFileTransferDialogTransferCompleteStatus) {
		return; // Break chain.
	}

	if (self.processedFilesize > self.totalFilesize) {
		return; // Break chain.
	}

	PointerIsEmptyAssert([self writeSocket]);

    while (1) {
        if (self.currentRecord >= RATE_LIMIT) {
			return; // Break chain.
		}

        if (self.sendQueueSize >= MAX_QUEUE_SIZE) {
			return; // Break chain.
		}

		if (self.processedFilesize >= self.totalFilesize) {
			[self closeFileHandle];

			return; // Break chain.
		}

		/* Perform write to socket. */
        NSData *data = [self.fileHandle readDataOfLength:BUF_SIZE];

		self.processedFilesize += [data length];
		self.currentRecord += [data length];

		self.sendQueueSize += 1;

		[[self writeSocket] writeData:data withTimeout:_sendDataTimeout tag:0];
    }
}

#pragma mark -
#pragma mark Properties

- (GCDAsyncSocket *)writeSocket
{
	if ([self isReversed]) {
		return self.connectionToRemoteServer;
	} else {
		return self.listeningServerConnectedClient;
	}
}

- (GCDAsyncSocket *)readSocket
{
	if ([self isReversed]) {
		return self.listeningServerConnectedClient;
	} else {
		return self.connectionToRemoteServer;
	}
}

- (BOOL)isActingAsServer
{
	return (([self isSender]	   && [self isReversed] == NO) ||
			([self isSender] == NO && [self isReversed]));
}

- (BOOL)isActingAsClient
{
	return (([self isSender] == NO && [self isReversed] == NO) ||
			([self isSender]	   && [self isReversed]));
}

- (void)updateClearButton
{
	[self.transferDialog updateClearButton];
}

- (void)reloadStatusInformation
{
	PointerIsEmptyAssert(self.parentCell);
	
	[self.parentCell reloadStatusInformation];
}

- (NSString *)completePath
{
	NSObjectIsEmptyAssertReturn(self.path, nil);
	
	return [self.path stringByAppendingPathComponent:self.filename];
}

- (TXUnsignedLongLong)currentFilesize
{
	NSString *completePath = [self completePath];

	NSObjectIsEmptyAssertReturn(completePath, 0);

	if ([RZFileManager() fileExistsAtPath:completePath] == NO) {
		return 0;
	}

	NSDictionary *pathInfo = [RZFileManager() attributesOfItemAtPath:completePath error:NULL];

	return [pathInfo fileSize];
}

- (void)resetProperties
{
	if ([self isResume] == NO) {
		self.processedFilesize = 0;
	}

	self.currentRecord = 0;
	
	self.errorMessageToken = nil;

	self.sendQueueSize = 0;
	
	@synchronized(self.speedRecords) {
		[self.speedRecords removeAllObjects];
	}
}

@end
