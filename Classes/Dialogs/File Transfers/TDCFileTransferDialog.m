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

/* Refuse to have more than X number of items incoming at any given time. */
#define _addReceiverHardLimit			100

@interface TDCFileTransferDialog ()
@property (nonatomic, strong) TLOTimer *maintenanceTimer;
@property (nonatomic, strong) NSMutableArray *fileTransfers;
@property (nonatomic, weak) IBOutlet NSButton *clearButton;
@property (nonatomic, weak) IBOutlet NSSegmentedCell *navigationControllerCell;

- (IBAction)hideWindow:(id)sender;

- (IBAction)clear:(id)sender;

- (IBAction)startTransferOfFile:(id)sender;
- (IBAction)stopTransferOfFile:(id)sender;
- (IBAction)removeTransferFromList:(id)sender;
- (IBAction)openReceivedFile:(id)sender;
- (IBAction)revealReceivedFileInFinder:(id)sender;

- (IBAction)navigationSelectionDidChange:(id)sender;
@end

@implementation TDCFileTransferDialog

- (instancetype)init
{
	if ((self = [super init])) {
		self.fileTransfers = [NSMutableArray array];
		
		[RZMainBundle() loadNibNamed:@"TDCFileTransferDialog" owner:self topLevelObjects:nil];
		
		self.maintenanceTimer = [TLOTimer new];
		
		[self.maintenanceTimer setTarget:self];
		[self.maintenanceTimer setAction:@selector(onMaintenanceTimer:)];
		[self.maintenanceTimer setReqeatTimer:YES];
	}
	
	return self;
}

- (void)dealloc
{
	[self.maintenanceTimer stop];
	[self.maintenanceTimer setTarget:nil];
}

- (void)show:(BOOL)key restorePosition:(BOOL)restoreFrame
{
	if (key) {
		[[self window] makeKeyAndOrderFront:nil];
	} else {
		[[self window] orderFront:nil];
	}
	
	if (restoreFrame) {
		[[self window] restoreWindowStateForClass:[self class]];
	}
}

- (void)close
{
	[[self window] close];
}

- (TDCFileTransferDialogTransferController *)fileTransferMatchingCondition:(BOOL (^)(TDCFileTransferDialogTransferController *controller))matchBlock
{
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			if (matchBlock(e)) {
				return e;
			}
		}
	}

	return nil;
}

- (TDCFileTransferDialogTransferController *)fileTransferMatchingPort:(NSInteger)port
{
	return [self fileTransferMatchingCondition:^BOOL(TDCFileTransferDialogTransferController *controller) {
		return ([controller transferPort] == port);
	}];
}

- (TDCFileTransferDialogTransferController *)fileTransferFromUniqueIdentifier:(NSString *)identifier
{
	return [self fileTransferMatchingCondition:^BOOL(TDCFileTransferDialogTransferController *controller) {
		return NSObjectsAreEqual(identifier, [controller uniqueIdentifier]);
	}];
}

- (BOOL)fileTransferExistsWithToken:(NSString *)transferToken
{
	TDCFileTransferDialogTransferController *e =
	[self fileTransferMatchingCondition:^BOOL(TDCFileTransferDialogTransferController *controller) {
		return NSObjectsAreEqual(transferToken, [controller transferToken]);
	}];

	return (e != nil);
}

- (TDCFileTransferDialogTransferController *)fileTransferSenderMatchingToken:(NSString *)transferToken
{
	return [self fileTransferMatchingCondition:^BOOL(TDCFileTransferDialogTransferController *controller) {
		return (NSObjectsAreEqual(transferToken, [controller transferToken]) && [controller isSender]);
	}];
}

- (TDCFileTransferDialogTransferController *)fileTransferReceiverMatchingToken:(NSString *)transferToken
{
	return [self fileTransferMatchingCondition:^BOOL(TDCFileTransferDialogTransferController *controller) {
		return (NSObjectsAreEqual(transferToken, [controller transferToken]) && [controller isSender] == NO);
	}];
}

- (void)prepareForApplicationTermination
{
	if ( self.downloadDestination) {
		[self.downloadDestination stopAccessingSecurityScopedResource];
	}
	
	[self close];
	
	@synchronized(self.fileTransfers) {
		if ([self.fileTransfers count] > 0) {
			for (id e in self.fileTransfers) {
				[e prepareForDestruction];
			}
		}
	}
}

- (void)nicknameChanged:(NSString *)oldNickname toNickname:(NSString *)newNickname client:(IRCClient *)client
{
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			if ([e associatedClient] == client) {
				if (NSObjectsAreEqual([e peerNickname], oldNickname)) {
					[e setPeerNickname:newNickname];
					
					[e reloadStatusInformation];
				}
			}
		}
	}
}

- (NSString *)addReceiverForClient:(IRCClient *)client nickname:(NSString *)nickname address:(NSString *)hostAddress port:(NSInteger)hostPort filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(NSString *)transferToken
{
	if ([self countNumberOfReceivers] > _addReceiverHardLimit) {
		LogToConsoleError("Max receiver count of %{public}i exceeded.", _addReceiverHardLimit)
		
		return nil;
	}

	TDCFileTransferDialogTransferController *groupItem = [TDCFileTransferDialogTransferController new];
	
	[groupItem setIsSender:NO];
	[groupItem setTransferDialog:self];
	[groupItem setAssociatedClient:client];
	[groupItem setPeerNickname:nickname];
	[groupItem setHostAddress:hostAddress];
	[groupItem setTransferPort:hostPort];
	[groupItem setFilename:filename];
	[groupItem setTotalFilesize:totalFilesize];
	[groupItem setUniqueIdentifier:[NSString stringWithUUID]];
	
	if (transferToken && [transferToken length] > 0) {
		[groupItem setTransferToken:transferToken];
		
		[groupItem setIsReversed:YES];
	}
	
	if (self.downloadDestination) {
		[groupItem setPath:[self.downloadDestination path]];
	}

	[self show:YES restorePosition:NO];

	[self addReceiver:groupItem];

	if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyAutomaticallyDownloadAction) {
		/* If the user is set to automatically download, then just save to the downloads folder. */
		if ([groupItem path] == nil) {
			[groupItem setPath:[TPCPathInfo userDownloadsFolderPath]];
		}

		/* Begin the transfer. */
		[groupItem open];
	}
	
	return [groupItem uniqueIdentifier];
}

- (NSString *)addSenderForClient:(IRCClient *)client nickname:(NSString *)nickname path:(NSString *)completePath autoOpen:(BOOL)autoOpen
{
	NSString *fileFilename = [completePath lastPathComponent];

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if ([TPCPreferences textEncryptionIsEnabled]) {
		/* Ask whether we should be allowed to add the file. */
		BOOL allowWithOTR = [sharedEncryptionManager()
			safeToTransferFile:fileFilename
							to:[client encryptionAccountNameForUser:nickname]
						  from:[client encryptionAccountNameForLocalUser]
		isIncomingFileTransfer:NO];

		if (allowWithOTR == NO) {
			return nil; // This operation is not allowed...
		}
	}
#endif

	/* Gather file information. */
	NSDictionary *fileAttributes = [RZFileManager() attributesOfItemAtPath:completePath error:NULL];
	
	NSObjectIsEmptyAssertReturn(fileAttributes, nil);
	
	TXUnsignedLongLong filesize = [fileAttributes fileSize];

	if (filesize == 0) {
		LogToConsoleError("Fatal error: Cannot create sender because filesize == 0")

		return nil;
	}

	NSString *filePath = [completePath stringByDeletingLastPathComponent];
	
	/* Build view. */
	TDCFileTransferDialogTransferController *groupItem = [TDCFileTransferDialogTransferController new];
	
	[groupItem setIsSender:YES];
	[groupItem setTransferDialog:self];
	[groupItem setAssociatedClient:client];
	[groupItem setPeerNickname:nickname];
	[groupItem setFilename:fileFilename];
	[groupItem setPath:filePath];
	[groupItem setTotalFilesize:filesize];
	[groupItem setUniqueIdentifier:[NSString stringWithUUID]];
	
	if ([TPCPreferences fileTransferRequestsAreReversed]) {
		[groupItem setIsReversed:YES];
	}
	
	/* Update dialog. */
	[self show:NO restorePosition:NO];
	
	[self addSender:groupItem];
	
	/* Check if our sender address exists. */
	if (autoOpen) {
		[groupItem open];
	}
	
	return [groupItem uniqueIdentifier];
}

- (void)updateClearButton
{
	BOOL enabled = NO;
	
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			if ([e transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferStoppedStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferFatalErrorStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferRecoverableErrorStatus)
			{
				enabled = YES;
				
				break;
			}
		}
	}
	
	[self.clearButton setEnabled:enabled];
}

- (void)addReceiver:(TDCFileTransferDialogTransferController *)groupItem
{
	@synchronized(self.fileTransfers) {
		[self.fileTransfers insertObject:groupItem atIndex:0];
	}
	
	if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerAllSelectedTab ||
		[self navigationSelection] == TDCFileTransferDialogNavigationControllerReceivingSelectedTab)
	{
		[self.fileTransferTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
									  withAnimation:NSTableViewAnimationSlideDown];
	}
}

- (void)addSender:(TDCFileTransferDialogTransferController *)groupItem
{
	@synchronized(self.fileTransfers) {
		[self.fileTransfers insertObject:groupItem atIndex:0];
	}
	
	if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerAllSelectedTab ||
		[self navigationSelection] == TDCFileTransferDialogNavigationControllerSendingSelectedTab)
	{
		[self.fileTransferTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
									  withAnimation:NSTableViewAnimationSlideDown];
	}
}

#pragma mark -
#pragma mark Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	NSInteger tag = [item tag];
	
	/* What are we going to do with nothing selected? */
	if ([self.fileTransferTable numberOfSelectedRows] <= 0) {
		return NO;
	}
	
	/* Build array of all selected rows. */
	NSMutableArray *sel = [NSMutableArray array];
	
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];
	
	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actlIndex = [index integerValue];
			
			[sel addObject:self.fileTransfers[actlIndex]];
		}
	}
	
	/* Begin actual validation. */
	switch (tag) {
		case 3001:	// Start Download
		{
			for (id e in sel) {
				if ([e transferStatus] == TDCFileTransferDialogTransferStoppedStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferRecoverableErrorStatus)
				{
					return YES;
				}
			}
			
			return NO;
		}
		case 3003: // Stop Download
		{
			for (id e in sel) {
				if ([e transferStatus] == TDCFileTransferDialogTransferConnectingStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferReceivingStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferIsListeningAsSenderStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferIsListeningAsReceiverStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferSendingStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferMappingListeningPortStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus ||
					[e transferStatus] == TDCFileTransferDialogTransferWaitingForResumeAcceptStatus)
				{
					return YES;
				}
			}
			
			return NO;
		}
		case 3004: // Remove Item
		{
			return YES;
		}
		case 3005: // Open File
		{
			for (id e in sel) {
				NSAssertReturnLoopContinue([e isSender] == NO);
				
				if ([e transferStatus] == TDCFileTransferDialogTransferCompleteStatus) {
					return YES;
				}
			}
			
			return NO;
		}
		case 3006: // Reveal In Finder
		{
			for (id e in sel) {
				NSAssertReturnLoopContinue([e isSender] == NO);
				
				if ([e transferStatus] == TDCFileTransferDialogTransferCompleteStatus) {
					return YES;
				}
			}
			
			return NO;
		}
	}
	
	return NO; // Default validation to NO.
}

- (void)clear:(id)sender
{
	@synchronized(self.fileTransfers) {
		for (NSInteger i = ([self.fileTransfers count] - 1); i >= 0; i--) {
			id obj = self.fileTransfers[i];
			
			if ([obj transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
				[obj transferStatus] == TDCFileTransferDialogTransferStoppedStatus ||
				[obj transferStatus] == TDCFileTransferDialogTransferFatalErrorStatus ||
				[obj transferStatus] == TDCFileTransferDialogTransferRecoverableErrorStatus)
			{
				[obj prepareForDestruction];
				
				[self.fileTransfers removeObjectAtIndex:i];
			}
		}
	}
	
	[self.fileTransferTable reloadData];
	
	[self updateClearButton];
}

- (void)startTransferOfFile:(id)sender
{
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];
	
	__block NSMutableArray *incomingTransfers = [NSMutableArray array];
	
	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actualIndx = [index integerValue];
			
			id e = self.fileTransfers[actualIndx];
			
			if ([e transferStatus] == TDCFileTransferDialogTransferStoppedStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferRecoverableErrorStatus)
			{
				if ([e isSender]) {
					[(TDCFileTransferDialogTransferController *)e open];
				} else {
					if ([e path] == nil) {
						[incomingTransfers addObject:e];
					} else {
						[(TDCFileTransferDialogTransferController *)e open];
					}
				}
			}
		}
	}
	
	if ([incomingTransfers count] > 0) {
		NSOpenPanel *d = [NSOpenPanel openPanel];
		
		NSURL *folderRep = [NSURL fileURLWithPath:[TPCPathInfo userDownloadsFolderPath]];
		
		[d setDirectoryURL:folderRep];
		
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:TXTLS(@"Prompts[0006]")];

		[d setMessage:TXTLS(@"TDCFileTransferDialog[1023]")];
		
		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
			if (result == NSModalResponseOK) {
				NSString *newPath = [d.URL path]; // Define path.
				
				for (TDCFileTransferDialogTransferController *e in incomingTransfers) {
					[e setPath:newPath];
					[e open]; // Begin transfer.
				}
				
				incomingTransfers = nil;
			}
		}];
	}
}

- (void)stopTransferOfFile:(id)sender
{
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];
	
	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actualIndx = [index integerValue];
			
			id e = self.fileTransfers[actualIndx];
			
			[(TDCFileTransferDialogTransferController *)e close:NO];
		}
	}
}

- (void)removeTransferFromList:(id)sender
{
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];
	
	[self.fileTransferTable removeRowsAtIndexes:indexes
								  withAnimation:NSTableViewAnimationSlideUp];
	
	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actualIndx = [index integerValue];
			
			id e = self.fileTransfers[actualIndx];
			
			[e prepareForDestruction];
			
			[self.fileTransfers removeObjectAtIndex:actualIndx];
		}
	}
}

- (void)openReceivedFile:(id)sender
{
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];

	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actualIndx = [index integerValue];
			
			id e = self.fileTransfers[actualIndx];
			
			NSAssertReturnLoopContinue([e isSender] == NO);
			
			[RZWorkspace() openFile:[e completePath]];
		}
	}
}

- (void)revealReceivedFileInFinder:(id)sender
{
	NSIndexSet *indexes = [self.fileTransferTable selectedRowIndexes];

	@synchronized(self.fileTransfers) {
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actualIndx = [index integerValue];
			
			id e = self.fileTransfers[actualIndx];
			
			NSAssertReturnLoopContinue([e isSender] == NO);
			
			[RZWorkspace() selectFile:[e completePath] inFileViewerRootedAtPath:nil];
		}
	}
}

#pragma mark -
#pragma mark Timer

- (void)updateMaintenanceTimerOnMainThread
{
	BOOL foundActive = NO;

	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			if ([e transferStatus] == TDCFileTransferDialogTransferReceivingStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferSendingStatus)
			{
				foundActive = YES;
				
				break;
			}
		}
	}
	
	if ([self.maintenanceTimer timerIsActive]) {
		if (foundActive == NO) {
			[self.maintenanceTimer stop];
		}
	} else {
		if (foundActive) {
			[self.maintenanceTimer start:1.0];
		}
	}
}

- (void)updateMaintenanceTimer
{
	[self performSelectorOnMainThread:@selector(updateMaintenanceTimerOnMainThread) withObject:nil waitUntilDone:NO];
}

- (void)onMaintenanceTimer:(TLOTimer *)sender
{
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			if ([e transferStatus] == TDCFileTransferDialogTransferReceivingStatus ||
				[e transferStatus] == TDCFileTransferDialogTransferSendingStatus)
			{
				[e onMaintenanceTimer];
			}
		}
	}
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	@synchronized(self.fileTransfers) {
		if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerAllSelectedTab) {
			return [self.fileTransfers count];
		} else if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerReceivingSelectedTab) {
			return [self countNumberOfReceivers];
		} else if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerSendingSelectedTab) {
			return [self countNumberOfSenders];
		}
	}
	
	return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id rowObj;
	
	if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerAllSelectedTab) {
		rowObj = self.fileTransfers[row];
	} else {
		NSInteger count = 0;
		
		for (id e in self.fileTransfers) {
			if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerReceivingSelectedTab) {
				NSAssertReturnLoopContinue([e isSender] == NO);
				
				if (count == row) {
					rowObj = e;
					
					break;
				}
			} else if ([self navigationSelection] == TDCFileTransferDialogNavigationControllerSendingSelectedTab) {
				NSAssertReturnLoopContinue([e isSender]);
				
				if (count == row) {
					rowObj = e;
					
					break;
				}
			}
			
			count += 1;
		}
	}
	
	if (rowObj) {
		NSView *newView = [self.fileTransferTable makeViewWithIdentifier:@"GroupView" owner:self];
		
		if ([newView isKindOfClass:[TDCFileTransferDialogTableCell class]]) {
			TDCFileTransferDialogTableCell *cell = (TDCFileTransferDialogTableCell *)newView;
			
			[cell setAssociatedController:rowObj];
			
			[rowObj setParentCell:cell];
			
			[cell populateBasicInformation];
			[cell reloadStatusInformation];
			
			return cell;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Network Information

- (NSString *)cachedIPAddress
{
	if ([TPCPreferences fileTransferIPAddressDetectionMethod] == TXFileTransferIPAddressManualDetectionMethod) {
		NSString *manualIPAddress = [TPCPreferences fileTransferManuallyEnteredIPAddress];

		if (manualIPAddress && [manualIPAddress length] == 0) {
			return nil;
		}

		return manualIPAddress;
	}

	return _cachedIPAddress;
}

- (void)clearCachedIPAddress
{
	self.cachedIPAddress = nil;
	
	self.sourceIPAddressRequestPending = NO;
}

- (void)requestIPAddressFromExternalSource
{
	self.sourceIPAddressRequestPending = YES;
	
	TDCFileTransferDialogRemoteAddressLookup *request = [TDCFileTransferDialogRemoteAddressLookup new];
	
	[request requestRemoteIPAddressFromExternalSource:self];
}

- (void)fileTransferRemoteAddressRequestDidCloseWithError:(NSError *)errPntr
{
	LogToConsoleError("Failed to complete connection request with error: %{public}@", [errPntr localizedDescription])
	
	self.sourceIPAddressRequestPending = NO;
	
	/* Post source IP address error. */
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			NSAssertReturnLoopContinue([e isSender]);
			
			if ([e transferStatus] == TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus) {
				[e setDidErrorOnBadSenderAddress];
			}
		}
	}
}

- (void)fileTransferRemoteAddressRequestDidDetectAddress:(NSString *)address
{
	/* Trim input. */
	address = [address trim];
	
	/* Is it even IP? */
	NSAssertReturn([address isIPAddress]);
	
	/* Okay, we are good... */
	self.cachedIPAddress = address;
	
	self.sourceIPAddressRequestPending = NO;
	
	/* Open pending transfers. */
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			NSAssertReturnLoopContinue([e isSender]);
			
			if ([e transferStatus] == TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus) {
				[e localIPAddressWasDetermined];
			}
		}
	}
}

#pragma mark -
#pragma mark Navigation

- (TDCFileTransferDialogNavigationControllerSelectedTab)navigationSelection
{
	return [self.navigationControllerCell selectedSegment];
}

- (NSInteger)countNumberOfReceivers
{
	NSInteger count = 0;
	
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			NSAssertReturnLoopContinue([e isSender] == NO);
			
			count += 1;
		}
	}
	
	return count;
}

- (NSInteger)countNumberOfSenders
{
	NSInteger count = 0;
	
	@synchronized(self.fileTransfers) {
		for (id e in self.fileTransfers) {
			NSAssertReturnLoopContinue([e isSender]);
			
			count += 1;
		}
	}
	
	return count;
}

- (void)navigationSelectionDidChange:(id)sender
{
	@synchronized(self.fileTransfers) {
		[self.fileTransfers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		 {
			 BOOL selectedAll = ([self navigationSelection] == TDCFileTransferDialogNavigationControllerAllSelectedTab);
			 
			 if (selectedAll) {
				 [obj setIsHidden:NO];
				 
				 [obj reloadStatusInformation];
			 } else {
				 BOOL objIsReceiver = ([obj isSender] == NO);
				 BOOL objIsSender = ([obj isSender]);
				 
				 if (([self navigationSelection] == TDCFileTransferDialogNavigationControllerReceivingSelectedTab && objIsReceiver) ||
					 ([self navigationSelection] == TDCFileTransferDialogNavigationControllerSendingSelectedTab && objIsSender))
				 {
					 [obj setIsHidden:NO];
					 
					 [obj reloadStatusInformation];
				 } else {
					 [obj setIsHidden:YES];
				 }
			 }
		 }];
	}
	
	[self.fileTransferTable reloadData];
}

#pragma mark -
#pragma mark Destination Folder

- (void)startUsingDownloadDestinationFolderSecurityScopedBookmark
{
	NSData *bookmark = [RZUserDefaults() dataForKey:@"File Transfers -> File Transfer Download Folder Bookmark"];
	
	NSObjectIsEmptyAssert(bookmark);
	
	NSError *resolveError = nil;
	
	BOOL isStale = YES;
	
	NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:&isStale
														  error:&resolveError];
	
	if (resolveError) {
		LogToConsoleError("Error creating bookmark for URL: %{public}@", [resolveError localizedDescription]);
	} else {
		self.downloadDestination = resolvedBookmark;
		
		if ([self.downloadDestination startAccessingSecurityScopedResource] == NO) {
			LogToConsoleError("Failed to access bookmark");
		}
	}
}

- (void)setDownloadDestinationFolder:(NSData *)value
{
	/* Destroy old pointer if needed. */
	if ( self.downloadDestination) {
		[self.downloadDestination stopAccessingSecurityScopedResource];
		 self.downloadDestination = nil;
	}
	
	/* Set new location. */
	[RZUserDefaults() setObject:value forKey:@"File Transfers -> File Transfer Download Folder Bookmark"];
	
	/* Reset our folder. */
	[self startUsingDownloadDestinationFolderSecurityScopedBookmark];
}

#pragma mark -
#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[[self window] saveWindowStateForClass:[self class]];
}

- (void)hideWindow:(id)sender
{
	[[self window] close];
}

@end
