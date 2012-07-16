/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation TDCListDialog

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCListDialog" owner:self];
		
		self.list = [NSMutableArray new];
		
		self.sortKey = 1;
		self.sortOrder = NSOrderedDescending;
        
        [self.table setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	}
	
	return self;
}

- (void)start
{
	[self.table setDoubleAction:@selector(onJoin:)];
	
	[self show];
}

- (void)show
{
	if ([self.window isVisible] == NO) {
		[self.window center];
	}
	
	IRCClient *client = self.delegate;
	
	NSString *network = client.config.network;
	
	if (NSObjectIsEmpty(network)) {
		network = client.config.name;
	}
	
	[self.networkName setStringValue:TXTFLS(@"ChannelListNetworkName", network)];
	
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	[self.window close];
}

- (void)clear
{
	[self.list removeAllObjects];
	
	self.filteredList = nil;
	
	[self reloadTable];
}

- (void)addChannel:(NSString *)channel count:(NSInteger)count topic:(NSString *)topic
{
	if ([channel isChannelName]) {
		NSArray *item = @[channel, @(count), topic,
						 [topic attributedStringWithIRCFormatting:TXDefaultListViewControllerFont]];
		
		NSString *filter = [self.filterText stringValue];
		
		if (NSObjectIsNotEmpty(filter)) {
			if (PointerIsEmpty(self.filteredList)) {
				self.filteredList = [NSMutableArray new];
			}
			
			NSInteger tr = [topic stringPositionIgnoringCase:filter];
			NSInteger cr = [channel stringPositionIgnoringCase:filter];
			
			if (tr >= 0 || cr >= 0) {
				[self sortedInsert:item inArray:self.filteredList];
			}
		}
		
		[self sortedInsert:item inArray:self.list];
		[self reloadTable];
	}
}

- (void)reloadTable
{
	if (NSObjectIsNotEmpty([self.filterText stringValue]) && NSDissimilarObjects([self.list count], [self.filteredList count])) {
		[self.channelCount setStringValue:TXTFLS(@"ListDialogHasSearchResults", [self.list count], [self.filteredList count])];
	} else {
		[self.channelCount setStringValue:TXTFLS(@"ListDialogHasChannels", [self.list count])];
	}
	
	[self.table reloadData];
}

static NSInteger compareItems(NSArray *self, NSArray *other, void *context)
{
	TDCListDialog *dialog = (__bridge TDCListDialog *)context;
	
	NSInteger key = dialog.sortKey;
	NSComparisonResult order = dialog.sortOrder;
	
	NSString *mine = [self safeObjectAtIndex:key];
	NSString *others = [other safeObjectAtIndex:key];
	
	NSComparisonResult result;
	
	if (key == 1) {
		result = [mine compare:others];
	} else {
		result = [mine caseInsensitiveCompare:others];
	}
	
	if (order == NSOrderedDescending) {
		return (-result);
	} else {
		return result;
	}
}

- (void)sort
{
	[self.list sortUsingFunction:compareItems context:(__bridge void *)(self)];
}

- (void)sortedInsert:(NSArray *)item inArray:(NSMutableArray *)ary
{
	const NSInteger THRESHOLD = 5;
	
	NSInteger left = 0;
	NSInteger right = ary.count;
	
	while ((right - left) > THRESHOLD) {
		NSInteger pivot = ((left + right) / 2);
		
		if (compareItems([ary safeObjectAtIndex:pivot], item, (__bridge void *)(self)) == NSOrderedDescending) {
			right = pivot;
		} else {
			left = pivot;
		}
	}
	
	for (NSInteger i = left; i < right; ++i) {
		if (compareItems([ary safeObjectAtIndex:i], item, (__bridge void *)(self)) == NSOrderedDescending) {
			[ary safeInsertObject:item atIndex:i];
			
			return;
		}
	}
	
	[ary safeInsertObject:item atIndex:right];
}

#pragma mark -
#pragma mark Actions

- (void)onClose:(id)sender
{
	[self.window close];
}

- (void)onUpdate:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(listDialogOnUpdate:)]) {
		[self.delegate listDialogOnUpdate:self];
	}
}

- (void)onJoin:(id)sender
{
	NSArray *ary = self.list;
	NSString *filter = [self.filterText stringValue];
	
	if (NSObjectIsNotEmpty(filter)) {
		ary = self.filteredList;
	}
	
	NSIndexSet *indexes = [self.table selectedRowIndexes];
	
	for (NSUInteger i = [indexes firstIndex]; NSDissimilarObjects(i, NSNotFound); i = [indexes indexGreaterThanIndex:i]) {
		NSArray *item = [ary safeObjectAtIndex:i];
		
		if ([self.delegate respondsToSelector:@selector(listDialogOnJoin:channel:)]) {
			[self.delegate listDialogOnJoin:self channel:[item safeObjectAtIndex:0]];
		}
	}
}

- (void)onSearchFieldChange:(id)sender
{
	self.filteredList = nil;
	
	NSString *filter = [self.filterText stringValue];
	
	if (NSObjectIsNotEmpty(filter)) {
		NSMutableArray *ary = [NSMutableArray new];
		
		for (NSArray *item in self.list) {
			NSString *channel = [item safeObjectAtIndex:0];
			NSString *topic = [item safeObjectAtIndex:2];
			
			NSInteger tr = [topic stringPositionIgnoringCase:filter];
			NSInteger cr = [channel stringPositionIgnoringCase:filter];
			
			if (tr >= 0 || cr >= 0) {
				[ary safeAddObject:item];
			}
		}
		
		self.filteredList = ary;
	}
	
	[self reloadTable];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (self.filteredList) {
		return self.filteredList.count;
	}
	
	return self.list.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *ary = ((self.filteredList) ? self.filteredList : self.list);
	NSArray *item = [ary safeObjectAtIndex:row];
	
	NSString *col = [column identifier];
	
	if ([col isEqualToString:@"chname"]) {
		return [item safeObjectAtIndex:0];
	} else if ([col isEqualToString:@"count"]) {
		return [item safeObjectAtIndex:1];
	} else {
		return [item safeObjectAtIndex:3];
	}
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column
{
	NSInteger i = 0;
	NSString *col = [column identifier];
	
	if ([col isEqualToString:@"chname"]) {
		i = 0;
	} else if ([col isEqualToString:@"count"]) {
		i = 1;
	} else {
		i = 2;
	}
	
	if (self.sortKey == i) {
		self.sortOrder = - self.sortOrder;
	} else {
		self.sortKey = i;
		self.sortOrder = ((self.sortKey == 1) ? NSOrderedDescending : NSOrderedAscending);
	}
	
	[self sort];
	
	if (self.filteredList) {
		[self onSearchFieldChange:nil];
	}
	
	[self reloadTable];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(listDialogWillClose:)]) {
		[self.delegate listDialogWillClose:self];
	}
}

@end