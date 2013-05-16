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

@interface TDCListDialog ()
@property (nonatomic, assign) BOOL waitingForReload;
@end

@implementation TDCListDialog

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCListDialog" owner:self];

		self.unfilteredList = [NSMutableArray new];

		self.sortKey = 1;
		self.sortOrder = NSOrderedDescending;
	}

	return self;
}

- (void)start
{
	[self.channelListTable setDoubleAction:@selector(onJoin:)];

	[self show];
}

- (void)show
{
    [self.networkNameField setStringValue:TXTFLS(@"ChannelListDialogNetworkName", self.client.altNetworkName)];

	[self.window restoreWindowStateForClass:self.class];
	
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	[self.window close];
}

- (void)clear
{
	[self.unfilteredList removeAllObjects];

	self.filteredList = nil;

	[self reloadTable];
}

- (void)addChannel:(NSString *)channel count:(NSInteger)count topic:(NSString *)topic
{
	if ([channel isChannelName]) {
		NSArray *item = @[channel, @(count), topic, [topic attributedStringWithIRCFormatting:TXDefaultListViewControllerFont]];

		NSString *filter = self.searchField.stringValue;

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

		[self sortedInsert:item inArray:self.unfilteredList];

        /* Reload table instantly until we reach at least 200 channels. 
         At that point we begin reloading every 2.0 seconds. For networks
         large as freenode with 12,000 channels. This is much better than 
         a reload for each. */
        
        if (self.unfilteredList.count < 200) {
            [self reloadTable];
        } else {
            if (self.waitingForReload == NO) {
                self.waitingForReload = YES;
                
                [self performSelector:@selector(reloadTable) withObject:nil afterDelay:2.0];
            }
        }
	}
}

- (void)reloadTable
{
    self.waitingForReload = NO;

	NSString *titleCount;

	NSString *count1 = TXFormattedNumber(self.unfilteredList.count);
	NSString *count2 = TXFormattedNumber(self.filteredList.count);

	if (NSObjectIsNotEmpty(self.searchField.stringValue) && NSDissimilarObjects(self.unfilteredList.count, self.filteredList.count)) {
		titleCount = TXTFLS(@"ChannelListDialogHasSearchResults", count1, count2);
	} else {
		titleCount = TXTFLS(@"ChannelListDialogHasChannels", count1);
	}

	[self.window setTitle:TXTFLS(@"ChannelListDialogTitle", titleCount)];

	[self.channelListTable reloadData];
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
	[self.unfilteredList sortUsingFunction:compareItems context:(__bridge void *)(self)];
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
    [self.unfilteredList removeAllObjects];

	if ([self.delegate respondsToSelector:@selector(listDialogOnUpdate:)]) {
		[self.delegate listDialogOnUpdate:self];
	}

    [self reloadTable];
}

/* onJoinChannels: handles join for selected items. */
- (void)onJoinChannels:(id)sender
{
	[self onJoin:sender];
}

/* onJoin: is a legacy method. It handles join on double click. */
- (void)onJoin:(id)sender
{
	NSArray *list = self.unfilteredList;

	if (self.filteredList) {
		list = self.filteredList;
	}

	NSIndexSet *indexes = [self.channelListTable selectedRowIndexes];

	for (NSUInteger i = indexes.firstIndex; NSDissimilarObjects(i, NSNotFound); i = [indexes indexGreaterThanIndex:i]) {
		NSArray *item = [list safeObjectAtIndex:i];

		if ([self.delegate respondsToSelector:@selector(listDialogOnJoin:channel:)]) {
			[self.delegate listDialogOnJoin:self channel:[item safeObjectAtIndex:0]];
		}
	}
}

- (void)onSearchFieldChange:(id)sender
{
	self.filteredList = nil;

	NSString *filter = self.searchField.stringValue;

	if (NSObjectIsNotEmpty(filter)) {
		NSMutableArray *ary = [NSMutableArray new];

		for (NSArray *item in self.unfilteredList) {
			NSString *channel = [item safeObjectAtIndex:0];
			NSString *topicva = [item safeObjectAtIndex:2];

			NSInteger tr = [topicva stringPositionIgnoringCase:filter];
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

	return self.unfilteredList.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *list = self.unfilteredList;

    if (self.filteredList) {
        list = self.filteredList;
    }

	NSArray *item = [list safeObjectAtIndex:row];

	if ([column.identifier isEqualToString:@"chname"]) {
		return [item safeObjectAtIndex:0];
	} else if ([column.identifier isEqualToString:@"count"]) {
		return [item safeObjectAtIndex:1];
	} else {
		return [item safeObjectAtIndex:3];
	}
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column
{
	NSInteger i = 0;

	if ([column.identifier isEqualToString:@"chname"]) {
		i = 0;
	} else if ([column.identifier isEqualToString:@"count"]) {
		i = 1;
	} else {
		i = 2;
	}

	if (self.sortKey == i) {
		self.sortOrder = - self.sortOrder;
	} else {
		self.sortKey = i;

        if (self.sortKey == 1) {
            self.sortOrder = NSOrderedDescending;
        } else {
            self.sortOrder = NSOrderedAscending;
        }
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
	[self.window saveWindowStateForClass:self.class];
	
	if ([self.delegate respondsToSelector:@selector(listDialogWillClose:)]) {
		[self.delegate listDialogWillClose:self];
	}
}

@end
