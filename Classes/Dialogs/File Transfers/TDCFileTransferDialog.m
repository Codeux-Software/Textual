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

@implementation TDCFileTransferDialog

- (id)init
{
	if (self = [super init]) {
		self.filesReceiving = [NSMutableArray new];
		self.filesSending = [NSMutableArray new];
		
		[RZMainBundle() loadCustomNibNamed:@"TDCFileTransferDialog" owner:self topLevelObjects:nil];
		
		self.maintenanceTimer = [TLOTimer new];
		self.maintenanceTimer.delegate = self;
		self.maintenanceTimer.selector = @selector(onMaintenanceTimer:);
		self.maintenanceTimer.reqeatTimer = YES;
	}
	
	return self;
}

- (void)show:(BOOL)key
{
	if (key) {
		[self.window makeKeyAndOrderFront:nil];
	} else {
		[self.window orderFront:nil];
	}
	
	[self.window restoreWindowStateForClass:self.class];
}

- (void)close
{
	[self.window close];
}

- (void)prepareForApplicationTermination
{
	[self close];
	
	for (TDCFileTransferDialogTransferReceiver *e in self.filesReceiving) {
		[e prepareForDestruction];
	}
	
	for (TDCFileTransferDialogTransferSender *e in self.filesSending) {
		[e prepareForDestruction];
	}
}

- (void)requestIPAddressFromExternalSource
{
	if ([TPCPreferences fileTransferIPAddressDetectionMethod] == TXFileTransferIPAddressAutomaticDetectionMethod) {
		[RZMainOperationQueue() addOperationWithBlock:^{
			@autoreleasepool {
				NSString *resultData;
				
				resultData = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://wtfismyip.com/text"] encoding:NSASCIIStringEncoding error:NULL];
				resultData = [resultData trim];
				
				if (resultData) {
					if ([resultData isIPv4Address]) {
						self.cachedIPAddress = resultData;
					}
				}
			}
		}];
	} else {
		self.cachedIPAddress = [TPCPreferences fileTransferManuallyEnteredIPAddress];
	}
}

- (void)nicknameChanged:(NSString *)oldNickname toNickname:(NSString *)newNickname client:(IRCClient *)client
{
	for (TDCFileTransferDialogTransferReceiver *e in self.filesReceiving) {
		if ([e associatedClient] == client) {
			if (NSObjectsAreEqual([e peerNickname], oldNickname)) {
				[e setPeerNickname:newNickname];
				[e reloadStatusInformation];
			}
		}
	}
	
	for (TDCFileTransferDialogTransferSender *e in self.filesSending) {
		if ([e associatedClient] == client) {
			if (NSObjectsAreEqual([e peerNickname], oldNickname)) {
				[e setPeerNickname:newNickname];
				[e reloadStatusInformation];
			}
		}
	}
}

- (void)addReceiverForClient:(IRCClient *)client nickname:(NSString *)nickname address:(NSString *)hostAddress port:(NSInteger)hostPort path:(NSString *)path filename:(NSString *)filename size:(TXFSLongInt)size
{
	NSView *newView = [self.receivingFilesTable makeViewWithIdentifier:@"GroupView" owner:self];
	
	if ([newView isKindOfClass:[TDCFileTransferDialogTransferReceiver class]]) {
		TDCFileTransferDialogTransferReceiver *groupItem = (TDCFileTransferDialogTransferReceiver *)newView;
		
		[groupItem setTransferDialog:self];
		[groupItem setAssociatedClient:client];
		[groupItem setPeerNickname:nickname];
		[groupItem setHostAddress:hostAddress];
		[groupItem setTransferPort:hostPort];
		[groupItem setPath:path];
		[groupItem setFilename:filename];
		[groupItem setTotalFilesize:size];
		[groupItem setIsReceiving:YES];
		
		[groupItem populateBasicInformation];
		
		[self addReceiver:groupItem];
		
		if ([TPCPreferences fileTransferRequestReplyAction] == TXFileTransferRequestReplyAutomaticallyDownloadAction) {
			[groupItem open];
		} else {
			[groupItem reloadStatusInformation];
		}
		
		[self show:NO];
	}
}

- (void)addSenderForClient:(IRCClient *)client nickname:(NSString *)nickname path:(NSString *)completePath autoOpen:(BOOL)autoOpen
{
	/* Gather file information. */
	NSDictionary *fileAttrs = [RZFileManager() attributesOfItemAtPath:completePath error:NULL];
	
	NSObjectIsEmptyAssert(fileAttrs);
	
	TXFSLongInt filesize = [fileAttrs longLongForKey:NSFileSize];
	
	NSAssertReturn(filesize > 0);
	
	NSString *actualFilename = [completePath lastPathComponent];
	NSString *actualFilePath = [completePath stringByDeletingLastPathComponent];
	
	/* Build view. */
	NSView *newView = [self.sendingFilesTable makeViewWithIdentifier:@"GroupView" owner:self];
	
	if ([newView isKindOfClass:[TDCFileTransferDialogTransferSender class]]) {
		TDCFileTransferDialogTransferSender *groupItem = (TDCFileTransferDialogTransferSender *)newView;
		
		[groupItem setTransferDialog:self];
		[groupItem setAssociatedClient:client];
		[groupItem setPeerNickname:nickname];
		[groupItem setFilename:actualFilename];
		[groupItem setPath:actualFilePath];
		[groupItem setTotalFilesize:filesize];
		[groupItem setIsReceiving:NO];
		
		[groupItem populateBasicInformation];
		
		[self addSender:groupItem];
		
		/* Check if our sender address exists. */
		if (autoOpen) {
			[groupItem open];
		} else {
			[groupItem reloadStatusInformation];
		}
		
		/* Update dialog. */
		[self show:YES];
	}
}

- (void)reloadFilesReceivingTable
{
	[self.receivingFilesTable reloadData];
	
	[self updateClearButton];
}

- (void)reloadFilesSendingTable
{
	[self.sendingFilesTable reloadData];
	
	[self updateClearButton];
}

- (void)updateClearButton
{
	BOOL enabled = NO;
	
	for (TDCFileTransferDialogTransferReceiver *e in self.filesReceiving) {
		if ([e transferStatus] == TDCFileTransferDialogTransferErrorStatus ||
			[e transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
			[e transferStatus] == TDCFileTransferDialogTransferStoppedStatus)
		{
			enabled = YES;
			
			break;
		}
	}
	
	for (TDCFileTransferDialogTransferSender *e in self.filesSending) {
		if ([e transferStatus] == TDCFileTransferDialogTransferErrorStatus ||
			[e transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
			[e transferStatus] == TDCFileTransferDialogTransferStoppedStatus)
		{
			enabled = YES;
			
			break;
		}
	}
	
	[self.clearButton setEnabled:enabled];
}

- (void)addReceiver:(TDCFileTransferDialogTransferReceiver *)groupItem
{
	[self.filesReceiving insertObject:groupItem atIndex:0];
	
	[self.receivingFilesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
									withAnimation:NSTableViewAnimationSlideRight];
}

- (void)addSender:(TDCFileTransferDialogTransferSender *)groupItem
{
	[self.filesSending insertObject:groupItem atIndex:0];
	
	[self.sendingFilesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
								  withAnimation:NSTableViewAnimationSlideRight];
}

- (void)destroyReceiverAtIndex:(NSInteger)i
{
	TDCFileTransferDialogTransferReceiver *e = [self.filesReceiving safeObjectAtIndex:i];
	
	PointerIsEmptyAssert(e);
	
	[e prepareForDestruction];
	
	[self.receivingFilesTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:i]
									withAnimation:NSTableViewAnimationSlideLeft];
	
	[self.filesReceiving removeObjectAtIndex:i];
}

- (void)destroySenderAtIndex:(NSInteger)i
{
	TDCFileTransferDialogTransferSender *e = [self.filesSending safeObjectAtIndex:i];
	
	PointerIsEmptyAssert(e);
	
	[e prepareForDestruction];
	
	[self.sendingFilesTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:i]
								  withAnimation:NSTableViewAnimationSlideLeft];
	
	[self.filesSending removeObjectAtIndex:i];
}

#pragma mark -
#pragma mark Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	NSInteger tag = [item tag];
	
	/* < 3100 tags are receiving files. */
    if (tag < 3100) {
		/* What are we going to do with nothing selected? */
		if ([self.receivingFilesTable countSelectedRows] <= 0) {
			return NO;
		}
		
		/* Build array of all selected rows. */
        NSMutableArray *sel = [NSMutableArray array];
		
		NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
		
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actlIndex = [index integerValue];
			
			[sel addObject:self.filesReceiving[actlIndex]];
		}
		
		/* Begin actual validation. */
        switch (tag) {
            case 3001:	// Start Download
			{
				for (TDCFileTransferDialogTransferReceiver *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferErrorStatus ||
						e.transferStatus == TDCFileTransferDialogTransferStoppedStatus)
					{
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
            case 3003: // Stop Download
			{
				for (TDCFileTransferDialogTransferReceiver *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferConnectingStatus ||
						e.transferStatus == TDCFileTransferDialogTransferReceivingStatus)
					{
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
            case 3004: // Remove Item
			{
				return YES;
				
				break;
			}
            case 3005: // Open File
			{
				for (TDCFileTransferDialogTransferReceiver *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferCompleteStatus) {
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
            case 3006: // Reveal In Finder
			{
				for (TDCFileTransferDialogTransferReceiver *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferCompleteStatus) {
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
        }
    } else {
		/* Begin validation of items being sent. */
		
		/* What are we going to do with nothing selected? */
		if ([self.sendingFilesTable countSelectedRows] <= 0) {
			return NO;
		}
		
		/* Build array of all selected rows. */
        NSMutableArray *sel = [NSMutableArray array];
		
		NSIndexSet *indexes = [self.sendingFilesTable selectedRowIndexes];
		
		for (NSNumber *index in [indexes arrayFromIndexSet]) {
			NSInteger actlIndex = [index integerValue];
			
			[sel addObject:self.filesSending[actlIndex]];
		}
		
		/* Begin actual validation. */
        switch (tag) {
            case 3101: // Start Sending
			{
				for (TDCFileTransferDialogTransferSender *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferErrorStatus ||
						e.transferStatus == TDCFileTransferDialogTransferStoppedStatus)
					{
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
            case 3102: // Stop Sending
			{
				for (TDCFileTransferDialogTransferSender *e in sel) {
					if (e.transferStatus == TDCFileTransferDialogTransferListeningStatus ||
						e.transferStatus == TDCFileTransferDialogTransferSendingStatus)
					{
						return YES;
					}
				}
				
                return NO;
				
				break;
			}
            case 3103: // Remove Item
			{
				return YES;
			}
        }
    }
	
	return NO; // Default validation to NO.
}

- (void)clear:(id)sender
{
	for (NSInteger i = 0; i < [self.filesReceiving count]; i++) {
		TDCFileTransferDialogTransferReceiver *obj = self.filesReceiving[i];
		
		if ([obj transferStatus] == TDCFileTransferDialogTransferErrorStatus ||
			[obj transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
			[obj transferStatus] == TDCFileTransferDialogTransferStoppedStatus)
		{
			[self destroyReceiverAtIndex:i];
		}
	}
	
	for (NSInteger i = 0; i < [self.filesSending count]; i++) {
		TDCFileTransferDialogTransferReceiver *obj = self.filesSending[i];
		
		if ([obj transferStatus] == TDCFileTransferDialogTransferErrorStatus ||
			[obj transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
			[obj transferStatus] == TDCFileTransferDialogTransferStoppedStatus)
		{
			[self destroySenderAtIndex:i];
		}
	}
}

- (void)startDownloadingReceivedFile:(id)sender
{
	NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferReceiver *e = self.filesReceiving[actualIndx];
		
		[e open];
	}
}

- (void)stopDownloadingReceivedFile:(id)sender
{
	NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferReceiver *e = self.filesReceiving[actualIndx];
		
		[e close];
	}
}

- (void)removeReceivedFile:(id)sender
{
	NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		[self destroyReceiverAtIndex:actualIndx];
	}
}

- (void)openReceivedFile:(id)sender
{
	NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferReceiver *e = self.filesReceiving[actualIndx];
		
		[RZWorkspace() openFile:[e completePath]];
	}
}

- (void)revealReceivedFileInFinder:(id)sender
{
	NSIndexSet *indexes = [self.receivingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferReceiver *e = self.filesReceiving[actualIndx];
		
		[RZWorkspace() selectFile:[e completePath] inFileViewerRootedAtPath:nil];
	}
}

- (void)startSendingFile:(id)sender
{
	NSIndexSet *indexes = [self.sendingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferSender *e = self.filesSending[actualIndx];
		
		[e open];
	}
}

- (void)stopSendingFile:(id)sender
{
	NSIndexSet *indexes = [self.sendingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		TDCFileTransferDialogTransferSender *e = self.filesSending[actualIndx];
		
		[e close];
	}
}

- (void)removeSentFile:(id)sender
{
	NSIndexSet *indexes = [self.sendingFilesTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSInteger actualIndx = [index integerValue];
		
		[self destroySenderAtIndex:actualIndx];
	}
}

#pragma mark -
#pragma mark Timer

- (void)updateMaintenanceTimerOnMainThread
{
	BOOL foundActive = NO;
	
	for (TDCFileTransferDialogTransferReceiver *e in self.filesReceiving) {
		if ([e transferStatus] == TDCFileTransferDialogTransferReceivingStatus) {
			foundActive = YES;
			
			break;
		}
	}
	
	for (TDCFileTransferDialogTransferSender *e in self.filesSending) {
		if ([e transferStatus] == TDCFileTransferDialogTransferSendingStatus) {
			foundActive = YES;
			
			break;
		}
	}
	
    if ([self.maintenanceTimer timerIsActive]) {
        if (foundActive == NO) {
            [self.maintenanceTimer stop];
        }
    } else {
        if (foundActive) {
            [self.maintenanceTimer start:1];
        }
    }
}

- (void)updateMaintenanceTimer
{
	[self performSelectorOnMainThread:@selector(updateMaintenanceTimerOnMainThread) withObject:nil waitUntilDone:NO];
}

- (void)onMaintenanceTimer:(TLOTimer *)sender
{
	for (TDCFileTransferDialogTransferReceiver *e in self.filesReceiving) {
		if ([e transferStatus] == TDCFileTransferDialogTransferReceivingStatus) {
			[e onMaintenanceTimer];
		}
	}
	
	for (TDCFileTransferDialogTransferSender *e in self.filesSending) {
		if ([e transferStatus] == TDCFileTransferDialogTransferSendingStatus) {
			[e onMaintenanceTimer];
		}
	}
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == self.sendingFilesTable) {
		return [self.filesSending count];
	} else {
		return [self.filesReceiving count];
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id e;
	
	if (tableView == self.sendingFilesTable) {
		e = self.filesSending[row];
	} else {
		e = self.filesReceiving[row];
	}
	
	return e;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return @"";
}

#pragma mark -
#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.window saveWindowStateForClass:self.class];
}

@end
