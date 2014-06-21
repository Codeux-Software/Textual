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

#import "TextualApplication.h"

#import <TCMPortMapper/TCMPortMapper.h>

@implementation TDCFileTransferDialogTransferController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if (self = [super init]) {
		_transferStatus = TDCFileTransferDialogTransferStoppedStatus;
		
		_speedRecords = [NSMutableArray new];
	}
	
	return self;
}

- (void)createDispatchQueues
{
	NSString *uniqueID = [NSString stringWithUUID];
	
	NSString *clientDispatchQueueName = [NSString stringWithFormat:@"DCC-SocketDispatchQueue-%@", uniqueID];
	NSString *clientSocketQueueName = [NSString stringWithFormat:@"DCC-SocketReadWriteQueue-%@", uniqueID];

	_serverDispatchQueue = dispatch_queue_create([clientDispatchQueueName UTF8String], NULL);
	_serverSocketQueue = dispatch_queue_create([clientSocketQueueName UTF8String], NULL);
}

- (void)destroyDispatchQueues
{
	if (_serverSocketQueue) {
		dispatch_release(_serverSocketQueue);

		_serverSocketQueue = nil;
	}

	if (_serverDispatchQueue) {
		dispatch_release(_serverDispatchQueue);

		_serverDispatchQueue = nil;
	}
}

- (void)prepareForDestruction
{
	_parentCell = nil;
	_transferDialog = nil;

	[self close:NO];
}

- (void)postErrorWithErrorMessage:(NSString *)errorToken
{
	_transferStatus = TDCFileTransferDialogTransferErrorStatus;

	_errorMessageToken = errorToken;

	[self close]; // Destroy everything.
}

- (void)updateTransferInformationWithNonexistentFilename
{
	/* Gather base information. */
	NSString *nameWOExtension = [_filename stringByDeletingPathExtension];
	NSString *filenameExtension = [_filename pathExtension];
	
	NSString *filepath = [self completePath];
	
	NSInteger i = 1;
	
	/* Loop until we find a name that does not exist. */
	while ([RZFileManager() fileExistsAtPath:filepath]) {
		NSString *newFilename;

		if ([filenameExtension length] > 0) {
			newFilename = [NSString stringWithFormat:@"%@_%d.%@", nameWOExtension, i, filenameExtension];
		} else {
			newFilename = [NSString stringWithFormat:@"%@_%d", nameWOExtension, i];
		}
		
		filepath = [_path stringByAppendingPathComponent:newFilename];
		
		i += 1;
	}
	
	/* Update filename if we have to… */
	if (i > 1) {
		_filename = [filepath lastPathComponent];
	}
}

#pragma mark -
#pragma mark Opening/Closing Transfer

- (void)open
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
	_transferStatus = TDCFileTransferDialogTransferConnectingStatus;
	
	/* Try to establish connection. */
	_connectionToRemoteServer = [GCDAsyncSocket socketWithDelegate:self
													 delegateQueue:_serverDispatchQueue
													   socketQueue:_serverSocketQueue];
	
	NSError *connError;
	
	BOOL isConnected = NO;
	
	/* Use the interface of the configured IP address instead of the default. */
	/* Default interface is used if IP address is not found locally. */
	NSString *networkInterface = [self networkInterfaceMatchingAddress];
	
	if (networkInterface) {
		isConnected = [_connectionToRemoteServer connectToHost:_hostAddress onPort:_transferPort viaInterface:networkInterface withTimeout:30.0 error:&connError];
	} else {
		isConnected = [_connectionToRemoteServer connectToHost:_hostAddress onPort:_transferPort withTimeout:30.0 error:&connError];
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
}

- (void)openConnectionAsServer
{
	/* Reset information. */
	[self close:NO];

	[self resetProperties];
	[self createDispatchQueues];

	/* Establish status. */
	_transferStatus = TDCFileTransferDialogTransferInitializingStatus;

	/* Try to find an open port and open. */
	_transferPort = [TPCPreferences fileTransferPortRangeStart];

	while ([self tryToOpenConnectionAsServer] == NO) {
        _transferPort += 1;

		if (_transferPort > [TPCPreferences fileTransferPortRangeEnd]) {
			[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1017]"];

			return; // Break the chain.
		}
    }

	/* Update status information. */
	[self reloadStatusInformation];
}

- (BOOL)tryToOpenConnectionAsServer
{
	/* Create the server and try opening it. */
	_listeningServer = [GCDAsyncSocket socketWithDelegate:self
											delegateQueue:_serverDispatchQueue
											  socketQueue:_serverSocketQueue];

	BOOL isActive = [_listeningServer acceptOnPort:_transferPort error:NULL]; // We only care about return not error.

	/* Are we listening on the port? */
	if (isActive) {
		/* Try to map the port. */
		TCMPortMapper *pm = [TCMPortMapper sharedInstance];

		[RZNotificationCenter() addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
		[RZNotificationCenter() addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];

		[pm addPortMapping:[TCMPortMapping portMappingWithLocalPort:(int)_transferPort
												desiredExternalPort:(int)_transferPort
												  transportProtocol:TCMPortMappingTransportProtocolTCP
														   userInfo:nil]];

		[pm start];

		return YES;
	}

	return NO; // Return bad port error.
}

- (NSString *)networkInterfaceMatchingAddress
{
	struct ifaddrs *allInterfaces;

	NSStringEncoding cstringEncoding = [NSString defaultCStringEncoding];

	NSString *cachedAddress = [_transferDialog cachedIPAddress];

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

- (void)portMapperDidStartWork:(NSNotification *)aNotification
{
	PointerIsNotEmptyAssert(_portMapping);

	TCMPortMapping *e = [self portMappingForSelf];

	PointerIsEmpty(e);

	_portMapping = e;

	_transferStatus = TDCFileTransferDialogTransferMappingListeningPortStatus;

	[self reloadStatusInformation];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification
{
	NSAssertReturn(_transferStatus == TDCFileTransferDialogTransferMappingListeningPortStatus);

	TCMPortMapping *e = _portMapping;

	PointerIsEmptyAssert(e);

	if ([e desiredExternalPort] == _transferPort) {
		if ([e mappingStatus] == TCMPortMappingStatusTrying)
		{
			; // Other mappings may be doing work.
		}
		else
		{
			if ([self isReversed]) {
				if ([e mappingStatus] == TCMPortMappingStatusUnmapped) {
					[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1017]"];
				} else {
					[self requestLocalIPAddress];
				}
			} else {
				/* If mapping fails, we silently fail. */
				/* We tried and it was successful, then that is good, but if we
				 did not, still start listening just incase other conditions allow
				 the transfer to still take place. */

				[self requestLocalIPAddress];
			}
		}
	}
}

- (void)requestLocalIPAddress
{
	NSString *cachedIPAddress = [_transferDialog cachedIPAddress];

	BOOL usesManualDetection = ([TPCPreferences fileTransferIPAddressDetectionMethod] == TXFileTransferIPAddressManualDetectionMethod);

	/* What did user specify? */
	if (cachedIPAddress == nil && usesManualDetection) {
		cachedIPAddress = [TPCPreferences fileTransferManuallyEnteredIPAddress];
	}

	/* Important check. */
	if (cachedIPAddress == nil && usesManualDetection == NO) {
		NSString *external = [[TCMPortMapper sharedInstance] externalIPAddress];

		if ([external isIPAddress]) {
			[_transferDialog setCachedIPAddress:external];

			cachedIPAddress = external;
		}
	}

	/* Request address? */
	if (cachedIPAddress == nil) {
		if (usesManualDetection) {
			[self setDidErrorOnBadSenderAddress];
		} else {
			if ([_transferDialog sourceIPAddressRequestPending] == NO) {
				[_transferDialog requestIPAddressFromExternalSource];
			}

			_transferStatus = TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus;

			[self reloadStatusInformation];
		}
	} else {
		[self localIPAddressWasDetermined];
	}
}

- (void)closePortMapping
{
	PointerIsEmptyAssert(_portMapping);

	TCMPortMapper *pm = [TCMPortMapper sharedInstance];

	[pm removePortMapping:_portMapping];

	_portMapping = nil;

	[RZNotificationCenter() removeObserver:self name:TCMPortMapperDidStartWorkNotification object:pm];
	[RZNotificationCenter() removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:pm];
}

- (TCMPortMapping *)portMappingForSelf
{
	TCMPortMapper *pm = [TCMPortMapper sharedInstance];

	/* Enumrate all mappings to find our own. */
	NSArray *allMappings = [[pm portMappings] allObjects];

	for (TCMPortMapping *e in allMappings) {
		/* Return the mapping matching our transfer port. */

		if ([e desiredExternalPort] == _transferPort) {
			return e;
		}
	}

	return nil;
}

- (void)localIPAddressWasDetermined
{
	if ([self isSender]) {
		if ([self isReversed]) {
			_transferStatus = TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus;
		} else {
			_transferStatus = TDCFileTransferDialogTransferIsListeningAsSenderStatus;
		}
	} else {
		if ([self isReversed]) {
			_transferStatus = TDCFileTransferDialogTransferIsListeningAsReceiverStatus;
		} else {
			return; // This condition is not possible.
		}
	}

	[self sendTransferRequestToClient];

	[self reloadStatusInformation];
}

- (void)didReceiveSendRequestFromClient
{
	[self openConnectionToHost];
}

- (void)buildTransferToken
{
	/* This is an infinite loop. That's bad programming. */
	NSInteger loopedCount = 0;

	while (1 == 1) {
		/* No matter what, this loop shall never reach more than 300 passes. */
		NSAssertReturnLoopBreak(loopedCount < 300);

		/* If last pass set token, break it… */
		if (_transferToken == nil) {
			/* Build token. */
			NSString *transferToken = [NSString stringWithInteger:TXRandomNumber(9999)];

			/* Does it already exist? */
			BOOL transferExists = [_transferDialog fileTransferExistsWithToken:transferToken];

			if (transferExists == NO) {
				_transferToken = transferToken;

				break; // Break loop.
			}
		} else {
			break;
		}

		loopedCount += 1; // Bump loop count.
	}
}

- (void)sendTransferRequestToClient
{
	if ([self isSender]) {
		/* We will send actual request to the user from here. */
		NSDictionary *fileAttrs = [RZFileManager() attributesOfItemAtPath:[self completePath] error:NULL];

		/* If we had problem reading file, then we need to stop now… */
		if (PointerIsEmpty(fileAttrs)) {
			[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1018]"];

			return; // Break chain.
		}

		/* Send to user. */
		TXUnsignedLongLong filesize = [fileAttrs longLongForKey:NSFileSize];

		/* Determine which type of message is sent… */
		if ([self isReversed]) {
			[self buildTransferToken];

			[_associatedClient sendFile:_peerNickname port:0 filename:_filename filesize:filesize token:_transferToken];
		} else {
			[_associatedClient sendFile:_peerNickname port:_transferPort filename:_filename filesize:filesize token:nil];
		}
	} else {
		if ([self isReversed]) {
			[_associatedClient sendFile:_peerNickname port:_transferPort filename:_filename filesize:_totalFilesize token:_transferToken];
		}
	}
}

- (void)close
{
	[self close:YES];
}

- (void)close:(BOOL)postNotifications
{
	/* Destroy sockets. */
    if (_listeningServer) {
	   [_listeningServer disconnect];
		_listeningServer = nil;
	}

	if (_listeningServerConnectedClient) {
	   [_listeningServerConnectedClient disconnect];
		_listeningServerConnectedClient = nil;
	}

	if (_connectionToRemoteServer) {
		[_connectionToRemoteServer disconnect];
		 _connectionToRemoteServer = nil;
	}

	[self destroyDispatchQueues];

	[self closePortMapping];

	/* Close the file. */
    [self closeFileHandle];

	/* Update status. */
	if (NSDissimilarObjects(_transferStatus, TDCFileTransferDialogTransferErrorStatus) &&
		NSDissimilarObjects(_transferStatus, TDCFileTransferDialogTransferCompleteStatus))
	{
		_transferStatus = TDCFileTransferDialogTransferStoppedStatus;
	}

	/* Post notification. */
	if (postNotifications) {
		if (_transferStatus == TDCFileTransferDialogTransferErrorStatus) {
			if ([self isSender]) {
				[_associatedClient notifyFileTransfer:TXNotificationFileTransferSendFailedType nickname:_peerNickname filename:_filename filesize:_totalFilesize];
			} else {
				[_associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveFailedType nickname:_peerNickname filename:_filename filesize:_totalFilesize];
			}
		}
	}

	/* Update status information. */
	[_transferDialog updateMaintenanceTimer];

	[self reloadStatusInformation];
}

- (void)setDidErrorOnBadSenderAddress
{
	[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1019]"];
}

#pragma mark -
#pragma mark Timer

- (void)onMaintenanceTimer
{
	NSAssertReturn((_transferStatus == TDCFileTransferDialogTransferReceivingStatus) ||
				   (_transferStatus == TDCFileTransferDialogTransferSendingStatus));
	
	dispatch_async(_serverDispatchQueue, ^{
		/* Update record. */
		[_speedRecords addObject:@(_currentRecord)];
		
		if ([_speedRecords count] > RECORDS_LEN) {
			[_speedRecords removeObjectAtIndex:0];
		}
		
		_currentRecord = 0;
		
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
	if ([self isSender] == NO) {
		/* Update filename. */
		[self updateTransferInformationWithNonexistentFilename];

		/* Create the file. */
		[RZFileManager() createFileAtPath:[self completePath] contents:[NSData data] attributes:nil];
	}
	
	/* Try to create file handle. */
	_fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self completePath]];
	
	if (_fileHandle == nil) {
		/* There was a problem opening the file handle. */
		[self postErrorWithErrorMessage:@"TDCFileTransferDialog[1018]"];

		return NO;
	}

	return YES;
}

- (void)closeFileHandle
{
	PointerIsEmptyAssert(_fileHandle);
	
	[_fileHandle closeFile];
	 _fileHandle = nil;
}

#pragma mark -
#pragma mark Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	/* Check connection type. */
	NSAssertReturn([self isActingAsServer]);

	/* Do not accept more than a single connection on this port. */
	/* If we already have a client, then force disconnect anyone else that tries to join. */
	if (_listeningServerConnectedClient) {
		[newSocket disconnect];
	}

	/* Maintain reference to client. */
	_listeningServerConnectedClient = newSocket;

	/* Update status. */
	if ([self isReversed]) {
		_transferStatus = TDCFileTransferDialogTransferReceivingStatus;
	} else {
		_transferStatus = TDCFileTransferDialogTransferSendingStatus;
	}

	[self reloadStatusInformation];

	[_transferDialog updateMaintenanceTimer];

	/* Open file handle. */
	(void)[self openFileHandle];

	/* Start pushing data. */
	if ([self isReversed] == NO) {
		if ([self isSender]) {
			[self send];
		}
	} else {
		if ([self isSender] == NO) {
			[_listeningServerConnectedClient readDataWithTimeout:(-1) tag:0];
		}
	}
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	/* Check connection type. */
	NSAssertReturn([self isActingAsClient]);

	/* Update status. */
	if ([self isReversed]) {
		_transferStatus = TDCFileTransferDialogTransferReceivingStatus;
	} else {
		_transferStatus = TDCFileTransferDialogTransferSendingStatus;
	}
	
	[self reloadStatusInformation];
	
	[_transferDialog updateMaintenanceTimer];

	/* Open file handle. */
	(void)[self openFileHandle];

	/* Start pushing data. */
	if ([self isReversed]) {
		if ([self isSender]) {
			[self send];
		}
	} else {
		if ([self isSender] == NO) {
			[_connectionToRemoteServer readDataWithTimeout:(-1) tag:0];
		}
	}
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	/* Handle disconnects. */
	if (_transferStatus == TDCFileTransferDialogTransferCompleteStatus ||
		_transferStatus == TDCFileTransferDialogTransferErrorStatus)
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
	_processedFilesize += [data length];
	_currentRecord += [data length];
	
	/* Write data to file. */
	if ([data length] > 0) {
		[_fileHandle writeData:data];
	}

	/* Tell socket to prepare for read. */
	[[self readSocket] readDataWithTimeout:(-1) tag:0];

	/* Send acknowledgement back to server. */
    uint32_t rsize = (_processedFilesize & 0xFFFFFFFF);
	
    unsigned char ack[4];
	
    ack[0] = ((rsize >> 24) & 0xFF);
    ack[1] = ((rsize >> 16) & 0xFF);
    ack[2] = ((rsize >>  8) & 0xFF);
    ack[3] =  (rsize & 0xFF);

	[[self readSocket] writeData:[NSData dataWithBytes:ack length:4] withTimeout:(-1) tag:0];
	
	/* Did we complete transfer? */
    if (_processedFilesize >= _totalFilesize) {
		_transferStatus = TDCFileTransferDialogTransferCompleteStatus;
		
		[_associatedClient notifyFileTransfer:TXNotificationFileTransferReceiveSuccessfulType nickname:_peerNickname filename:_filename filesize:_totalFilesize];
		
		[self close]; // Close Connection
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	/* Connection check. */
	NSAssertReturn([self isSender]);

	/* Update pending sends. */
	_sendQueueSize -= 1;

	/* Update transfer information. */
	if (_processedFilesize >= _totalFilesize) {
		if (_sendQueueSize <= 0) {
			_transferStatus = TDCFileTransferDialogTransferCompleteStatus;

			[_associatedClient notifyFileTransfer:TXNotificationFileTransferSendSuccessfulType nickname:_peerNickname filename:_filename filesize:_totalFilesize];

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

	if (_transferStatus == TDCFileTransferDialogTransferCompleteStatus) {
		return; // Break chain.
	}

	if (_processedFilesize > _totalFilesize) {
		return; // Break chain.
	}

	PointerIsEmptyAssert([self writeSocket]);

    while (1) {
        if (_currentRecord >= RATE_LIMIT) {
			return; // Break chain.
		}

        if (_sendQueueSize >= MAX_QUEUE_SIZE) {
			return; // Break chain.
		}

		if (_processedFilesize >= _totalFilesize) {
			[self closeFileHandle];

			return; // Break chain.
		}

		/* Perform write to socket. */
        NSData *data = [_fileHandle readDataOfLength:BUF_SIZE];

		_processedFilesize += [data length];
		_currentRecord += [data length];

		_sendQueueSize += 1;

		[[self writeSocket] writeData:data withTimeout:30 tag:0];
    }
}

#pragma mark -
#pragma mark Properties

- (GCDAsyncSocket *)writeSocket
{
	if ([self isReversed]) {
		return _connectionToRemoteServer;
	} else {
		return _listeningServerConnectedClient;
	}
}

- (GCDAsyncSocket *)readSocket
{
	if ([self isReversed]) {
		return _listeningServerConnectedClient;
	} else {
		return _connectionToRemoteServer;
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
	[_transferDialog updateClearButton];
}

- (void)reloadStatusInformation
{
	PointerIsEmptyAssert(_parentCell);
	
	[_parentCell reloadStatusInformation];
}

- (NSString *)completePath
{
	NSObjectIsEmptyAssertReturn(_path, nil);
	
	return [_path stringByAppendingPathComponent:_filename];
}

- (void)resetProperties
{
	_processedFilesize = 0;
	_currentRecord = 0;
	
	_errorMessageToken = nil;

	_sendQueueSize = 0;
	
	[_speedRecords removeAllObjects];
}

@end
