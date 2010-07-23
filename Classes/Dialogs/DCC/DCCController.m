#import "DCCController.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "Preferences.h"
#import "DCCReceiver.h"
#import "DCCSender.h"
#import "DCCFileTransferCell.h"
#import "TableProgressIndicator.h"
#import "SoundPlayer.h"
#import "NSDictionaryHelper.h"


#define TIMER_INTERVAL	1


@interface DCCController (Private)
- (void)reloadReceiverTable;
- (void)reloadSenderTable;
- (void)updateClearButton;
- (void)updateTimer;

@end

@implementation DCCController

@synthesize delegate;
@synthesize world;
@synthesize mainWindow;

- (id)init
{
	if (self = [super init]) {
		receivers = [NSMutableArray new];
		senders = [NSMutableArray new];
		
		timer = [Timer new];
		timer.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	[receivers release];
	[senders release];
	
	[timer stop];
	[timer release];
	[super dealloc];
}

- (void)show:(BOOL)key
{
	if (!loaded) {
		loaded = YES;
		[NSBundle loadNibNamed:@"DCCDialog" owner:self];
		[splitter setFixedViewIndex:1];
		
		DCCFileTransferCell* senderCell = [[DCCFileTransferCell new] autorelease];
		[[[senderTable tableColumns] safeObjectAtIndex:0] setDataCell:senderCell];
		
		DCCFileTransferCell* receiverCell = [[DCCFileTransferCell new] autorelease];
		[[[receiverTable tableColumns] safeObjectAtIndex:0] setDataCell:receiverCell];
		
		for (DCCReceiver* e in receivers) {
			if (e.status == DCC_RECEIVING) {
				[self dccReceiveOnOpen:e];
			}
		}
		
		for (DCCSender* e in senders) {
			if (e.status == DCC_SENDING) {
				[self dccSenderOnConnect:e];
			}
		}
	}
	
	if (key) {
		[self.window makeKeyAndOrderFront:nil];
	} else {
		[self.window orderFront:nil];
	}
	
	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)close
{
	if (!loaded) return;
	
	[self.window close];
}

- (void)terminate
{
	[self close];
}

- (void)nickChanged:(NSString*)nick toNick:(NSString*)toNick client:(IRCClient*)client
{
	NSInteger uid = client.uid;
	BOOL found = NO;
	
	for (DCCReceiver* e in receivers) {
		if (e.uid == uid && [e.peerNick isEqualToString:nick]) {
			e.peerNick = toNick;
			found = YES;
		}
	}
	
	for (DCCSender* e in senders) {
		if (e.uid == uid && [e.peerNick isEqualToString:nick]) {
			e.peerNick = toNick;
			found = YES;
		}
	}
	
	if (found) {
		[self reloadReceiverTable];
		[self reloadSenderTable];
	}
}

- (void)addReceiverWithUID:(NSInteger)uid nick:(NSString*)nick host:(NSString*)host port:(NSInteger)port path:(NSString*)path fileName:(NSString*)fileName size:(long long)size
{
	DCCReceiver* c = [[DCCReceiver new] autorelease];
	c.delegate = self;
	c.uid = uid;
	c.peerNick = nick;
	c.host = host;
	c.port = port;
	c.path = path;
	c.fileName = fileName;
	c.size = size;
	[receivers insertObject:c atIndex:0];
	
	if ([Preferences dccAction] == DCC_AUTO_ACCEPT) {
		[c open];
	}
	[self show:NO];
}

- (void)addSenderWithUID:(NSInteger)uid nick:(NSString*)nick fileName:(NSString*)fileName autoOpen:(BOOL)autoOpen
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSDictionary* attr = [fm attributesOfItemAtPath:fileName error:NULL];
	if (!attr) return;
	NSNumber* sizeNum = [attr objectForKey:NSFileSize];
	long long size = [sizeNum longLongValue];
	
	if (!size) return;
	
	DCCSender* c = [[DCCSender new] autorelease];
	c.delegate = self;
	c.uid = uid;
	c.peerNick = nick;
	c.fullFileName = fileName;
	[senders insertObject:c atIndex:0];
	
	IRCClient* u = [world findClientById:uid];
	if (!u || !u.myAddress) {
		[c setAddressError];
		return;
	}
	
	if (autoOpen) {
		[c open];
	}
	
	[self reloadSenderTable];
	[self show:YES];
}

- (NSInteger)countReceivingItems
{
	NSInteger i = 0;
	for (DCCReceiver* e in receivers) {
		if (e.status == DCC_RECEIVING) {
			++i;
		}
	}
	return i;
}

- (NSInteger)countSendingItems
{
	NSInteger i = 0;
	for (DCCSender* e in senders) {
		if (e.status == DCC_SENDING) {
			++i;
		}
	}
	return i;
}

- (void)reloadReceiverTable
{
	[receiverTable reloadData];
	[self updateClearButton];
}

- (void)reloadSenderTable
{
	[senderTable reloadData];
	[self updateClearButton];
}

- (void)updateClearButton
{
	BOOL enabled = NO;
	
	for (NSInteger i=receivers.count-1; i>=0; --i) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
			enabled = YES;
			break;
		}
	}
	
	if (!enabled) {
		for (NSInteger i=senders.count-1; i>=0; --i) {
			DCCSender* e = [senders safeObjectAtIndex:i];
			if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
				enabled = YES;
				break;
			}
		}
	}
	
	[clearButton setEnabled:enabled];
}

- (void)destroyReceiverAtIndex:(NSInteger)i
{
	DCCReceiver* e = [receivers safeObjectAtIndex:i];
	NSProgressIndicator* bar = e.progressBar;
	if (bar) {
		[bar removeFromSuperview];
	}
	[[e retain] autorelease];
	[receivers removeObjectAtIndex:i];
}

- (void)destroySenderAtIndex:(NSInteger)i
{
	DCCSender* e = [senders safeObjectAtIndex:i];
	NSProgressIndicator* bar = e.progressBar;
	if (bar) {
		[bar removeFromSuperview];
	}
	[[e retain] autorelease];
	[senders removeObjectAtIndex:i];
}

#pragma mark -
#pragma mark Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	NSInteger tag = item.tag;
	
	if (tag < 3100) {
		if (![receiverTable countSelectedRows]) return NO;
		
		NSMutableArray* sel = [NSMutableArray array];
		NSIndexSet* indexes = [receiverTable selectedRowIndexes];
		for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
			[sel addObject:[receivers safeObjectAtIndex:i]];
		}
		
		switch (tag) {
			case 3001:	// start receiver
				for (DCCReceiver* e in sel) {
					if (e.status == DCC_INIT || e.status == DCC_ERROR) {
						return YES;
					}
				}
				return NO;
			case 3002:	// resume receiver (not implemented)
				return YES;
			case 3003:	// stop receiver
				for (DCCReceiver* e in sel) {
					if (e.status == DCC_CONNECTING || e.status == DCC_RECEIVING) {
						return YES;
					}
				}
				return NO;
			case 3004:	// delete receiver
				return YES;
			case 3005:	// open file
				for (DCCReceiver* e in sel) {
					if (e.status == DCC_COMPLETE) {
						return YES;
					}
				}
				return NO;
			case 3006:	// reveal in finder
				for (DCCReceiver* e in sel) {
					if (e.status == DCC_COMPLETE || e.status == DCC_ERROR) {
						return YES;
					}
				}
				return NO;
		}
	} else {
		if (![senderTable countSelectedRows]) return NO;
		
		NSMutableArray* sel = [NSMutableArray array];
		NSIndexSet* indexes = [senderTable selectedRowIndexes];
		for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
			[sel addObject:[senders safeObjectAtIndex:i]];
		}
		
		switch (tag) {
			case 3101:	// start sender
				for (DCCSender* e in sel) {
					if (e.status == DCC_INIT || e.status == DCC_ERROR || e.status == DCC_STOP) {
						return YES;
					}
				}
				return NO;
			case 3102:	// stop sender
				for (DCCSender* e in sel) {
					if (e.status == DCC_LISTENING || e.status == DCC_SENDING) {
						return YES;
					}
				}
				return NO;
			case 3103:	// delete sender
				return YES;
		}
	}
	
	return NO;
}

- (void)clear:(id)sender
{
	for (NSInteger i=receivers.count-1; i>=0; --i) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
			[self destroyReceiverAtIndex:i];
		}
	}
	
	for (NSInteger i=senders.count-1; i>=0; --i) {
		DCCSender* e = [senders safeObjectAtIndex:i];
		if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
			[self destroySenderAtIndex:i];
		}
	}

	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)startReceiver:(id)sender
{
	NSIndexSet* indexes = [receiverTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		[e open];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)stopReceiver:(id)sender
{
	NSIndexSet* indexes = [receiverTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		[e close];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)deleteReceiver:(id)sender
{
	NSIndexSet* indexes = [receiverTable selectedRowIndexes];
	for (NSUInteger i=[indexes lastIndex]; i!=NSNotFound; i=[indexes indexLessThanIndex:i]) {
		[self destroyReceiverAtIndex:i];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)openReceiver:(id)sender
{
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	
	NSIndexSet* indexes = [receiverTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		[ws openFile:e.downloadFileName];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)revealReceivedFileInFinder:(id)sender
{
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	
	NSIndexSet* indexes = [receiverTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCReceiver* e = [receivers safeObjectAtIndex:i];
		[ws selectFile:e.downloadFileName inFileViewerRootedAtPath:nil];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)startSender:(id)sender
{
	NSIndexSet* indexes = [senderTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCSender* e = [senders safeObjectAtIndex:i];
		[e open];
	}
	
	[self reloadSenderTable];
	[self updateTimer];
}

- (void)stopSender:(id)sender
{
	NSIndexSet* indexes = [senderTable selectedRowIndexes];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		DCCSender* e = [senders safeObjectAtIndex:i];
		[e close];
	}
	
	[self reloadSenderTable];
	[self updateTimer];
}

- (void)deleteSender:(id)sender
{
	NSIndexSet* indexes = [senderTable selectedRowIndexes];
	for (NSUInteger i=[indexes lastIndex]; i!=NSNotFound; i=[indexes indexLessThanIndex:i]) {
		[self destroySenderAtIndex:i];
	}
	
	[self reloadSenderTable];
	[self updateTimer];
}

#pragma mark -
#pragma mark DCCReceiver Delegate

- (void)removeControlsFromReceiver:(DCCReceiver*)receiver
{
	if (receiver.progressBar) {
		[receiver.progressBar removeFromSuperview];
		receiver.progressBar = nil;
	}
}

- (void)dccReceiveOnOpen:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	if (!sender.progressBar) {
		TableProgressIndicator* bar = [[TableProgressIndicator new] autorelease];
		[bar setIndeterminate:NO];
		[bar setMinValue:0];
		[bar setMaxValue:sender.size];
		[bar setDoubleValue:sender.processedSize];
		[receiverTable addSubview:bar];
		sender.progressBar = bar;
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)dccReceiveOnClose:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromReceiver:sender];
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)dccReceiveOnError:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromReceiver:sender];
	[self reloadReceiverTable];
	[self updateTimer];

	[world notifyOnGrowl:GROWL_FILE_RECEIVE_ERROR title:sender.peerNick desc:sender.fileName context:nil];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_FILE_RECEIVE_ERROR]];
}

- (void)dccReceiveOnComplete:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromReceiver:sender];
	[self reloadReceiverTable];
	[self updateTimer];

	[world notifyOnGrowl:GROWL_FILE_RECEIVE_SUCCESS title:sender.peerNick desc:sender.fileName context:nil];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_FILE_RECEIVE_SUCCESS]];
}

#pragma mark -
#pragma mark DCCSender Delegate

- (void)removeControlsFromSender:(DCCSender*)sender
{
	if (sender.progressBar) {
		[sender.progressBar removeFromSuperview];
		sender.progressBar = nil;
	}
}

- (void)dccSenderOnListen:(DCCSender*)sender
{
	IRCClient* u = [world findClientById:sender.uid];
	if (!u) return;
	
	[u sendFile:sender.peerNick port:sender.port fileName:sender.fileName size:sender.size];

	if (!loaded) return;

	[self reloadSenderTable];
	[self updateTimer];
}

- (void)dccSenderOnConnect:(DCCSender*)sender
{
	if (!loaded) return;
	
	if (!sender.progressBar) {
		TableProgressIndicator* bar = [[TableProgressIndicator new] autorelease];
		[bar setIndeterminate:NO];
		[bar setMinValue:0];
		[bar setMaxValue:sender.size];
		[bar setDoubleValue:sender.processedSize];
		[senderTable addSubview:bar];
		sender.progressBar = bar;
	}
	
	[self reloadSenderTable];
	[self updateTimer];
}

- (void)dccSenderOnClose:(DCCSender*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromSender:sender];
	[self reloadSenderTable];
	[self updateTimer];
}

- (void)dccSenderOnError:(DCCSender*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromSender:sender];
	[self reloadSenderTable];
	[self updateTimer];
	
	[world notifyOnGrowl:GROWL_FILE_SEND_ERROR title:sender.peerNick desc:sender.fileName context:nil];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_FILE_SEND_ERROR]];
}

- (void)dccSenderOnComplete:(DCCSender*)sender
{
	if (!loaded) return;
	
	[self removeControlsFromSender:sender];
	[self reloadSenderTable];
	[self updateTimer];

	[world notifyOnGrowl:GROWL_FILE_SEND_SUCCESS title:sender.peerNick desc:sender.fileName context:nil];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_FILE_SEND_SUCCESS]];
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == senderTable) {
		return senders.count;
	} else {
		return receivers.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(DCCFileTransferCell*)c forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == senderTable) {
		if (row < 0 || senders.count <= row) return;
		
		DCCSender* e = [senders safeObjectAtIndex:row];
		double speed = e.speed;
		
		c.sendingItem = NO;
		c.stringValue = e.fileName;
		c.peerNick = e.peerNick;
		c.size = e.size;
		c.processedSize = e.processedSize;
		c.speed = speed;
		c.timeRemaining = speed > 0 ? ((e.size - e.processedSize)) / speed : 0;
		c.status = e.status;
		c.error = e.error;
		c.icon = e.icon;
		c.progressBar = e.progressBar;
	} else {
		if (row < 0 || receivers.count <= row) return;
		
		DCCReceiver* e = [receivers safeObjectAtIndex:row];
		double speed = e.speed;
		
		c.sendingItem = NO;
		c.stringValue = (e.status == DCC_COMPLETE) ? [e.downloadFileName lastPathComponent] : e.fileName;
		c.peerNick = e.peerNick;
		c.size = e.size;
		c.processedSize = e.processedSize;
		c.speed = speed;
		c.timeRemaining = speed > 0 ? ((e.size - e.processedSize)) / speed : 0;
		c.status = e.status;
		c.error = e.error;
		c.icon = e.icon;
		c.progressBar = e.progressBar;
	}
}

#pragma mark -
#pragma mark Timer Delegate

- (void)updateTimer
{
	if (timer.isActive) {
		BOOL foundActive = NO;
		
		for (DCCReceiver* e in receivers) {
			if (e.status == DCC_RECEIVING) {
				foundActive = YES;
				break;
			}
		}
		
		if (!foundActive) {
			for (DCCSender* e in senders) {
				if (e.status == DCC_SENDING) {
					foundActive = YES;
					break;
				}
			}
		}
		
		if (!foundActive) {
			[timer stop];
		}
	} else {
		BOOL foundActive = NO;
		
		for (DCCReceiver* e in receivers) {
			if (e.status == DCC_RECEIVING) {
				foundActive = YES;
				break;
			}
		}
		
		if (!foundActive) {
			for (DCCSender* e in senders) {
				if (e.status == DCC_SENDING) {
					foundActive = YES;
					break;
				}
			}
		}
		
		if (foundActive) {
			[timer start:TIMER_INTERVAL];
		}
	}
}

- (void)timerOnTimer:(Timer*)sender
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
	[self updateTimer];
	
	for (DCCReceiver* e in receivers) {
		[e onTimer];
	}
	
	for (DCCSender* e in senders) {
		[e onTimer];
	}
}

#pragma mark -
#pragma mark DialogWindow Delegate

- (void)dialogWindowEscape
{
	[self.window close];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidBecomeMain:(NSNotification *)note
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)windowDidResignMain:(NSNotification *)note
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)windowWillClose:(NSNotification*)note
{
}

@synthesize loaded;
@synthesize receivers;
@synthesize senders;
@synthesize timer;
@synthesize receiverTable;
@synthesize senderTable;
@synthesize splitter;
@synthesize clearButton;
@end