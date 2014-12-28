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

@interface TDCListDialog ()
@property (nonatomic, assign) BOOL waitingForReload;
@property (nonatomic, nweak) IBOutlet NSButton *updateButton;
@property (nonatomic, nweak) IBOutlet NSSearchField *searchField;
@property (nonatomic, nweak) IBOutlet NSTextField *networkNameField;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *channelListTable;
@property (nonatomic, strong) NSMutableArray *unfilteredList;
@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic, readonly) NSMutableArray *activeList; // Proxies one of the two above.
@property (nonatomic, readonly) NSInteger listCount; // Proxies one of the two above.
@property (nonatomic, assign) NSComparisonResult sortOrder;
@property (nonatomic, assign) NSInteger sortKey;
@end

@implementation TDCListDialog

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCListDialog" owner:self topLevelObjects:nil];

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
	IRCClient *client = [worldController() findClientById:self.clientID];

    [self.networkNameField setStringValue:TXTLS(@"TDCListDialog[1000]", [client altNetworkName])];

	[self.window restoreWindowStateForClass:[self class]];
	
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[self.window close];
}

- (void)releaseTableViewDataSourceBeforeClosure
{
	[self.channelListTable setDelegate:nil];
	[self.channelListTable setDataSource:nil];
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
		NSArray *item = @[channel, @(count), topic, [topic attributedStringWithIRCFormatting:TXPreferredGlobalTableViewFont]];

		NSString *filter = [self.searchField stringValue];

		if ([filter length] > 0) {
			if (self.filteredList == nil) {
				self.filteredList = [NSMutableArray new];
			}

			NSInteger tr = [topic stringPositionIgnoringCase:filter];
			NSInteger cr = [channel stringPositionIgnoringCase:filter];

			if (tr > -1 || cr > -1) {
				[self.filteredList insertSortedObject:item usingComparator:[self sortComparator]];
			}
		}

		[self.unfilteredList insertSortedObject:item usingComparator:[self sortComparator]];

        /* Reload table instantly until we reach at least 200 channels. 
         At that point we begin reloading every 2.0 seconds. For networks
         large as freenode with 12,000 channels. This is much better than 
         a reload for each. */
        
        if (self.listCount < 200) {
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

	NSString *count1 = TXFormattedNumber([self.unfilteredList count]);
	NSString *count2 = TXFormattedNumber([self.filteredList count]);
	
	NSString *filterText = [self.searchField stringValue];

	if ([filterText length] > 0 && [count1 isEqual:count2] == NO) {
		titleCount = TXTLS(@"TDCListDialog[1003]", count1, count2);
	} else {
		titleCount = TXTLS(@"TDCListDialog[1002]", count1);
	}

	[self.window setTitle:TXTLS(@"TDCListDialog[1001]", titleCount)];

	[self.channelListTable reloadData];
}

- (NSComparator)sortComparator
{
	return [^(NSArray *obj1, NSArray *obj2)
	{
		NSString *str1 = obj1[self.sortKey];
		NSString *str2 = obj2[self.sortKey];
		
		NSComparisonResult result;
		
		if (self.sortKey == 1) {
			result = [str1 compare:str2];
		} else {
			result = [str1 caseInsensitiveCompare:str2];
		}
		
		if (self.sortOrder == NSOrderedDescending) {
			return (NSComparisonResult) -(result);
		} else {
			return (NSComparisonResult)   result;
		}
	} copy];
}

- (void)sort
{
	[self.unfilteredList sortUsingComparator:[self sortComparator]];
}

#pragma mark -
#pragma mark Actions

- (void)onClose:(id)sender
{
	[self close];
}

- (void)onUpdate:(id)sender
{
	[self clear];

	if ([self.delegate respondsToSelector:@selector(listDialogOnUpdate:)]) {
		[self.delegate listDialogOnUpdate:self];
	}
}

/* onJoinChannels: handles join for selected items. */
- (void)onJoinChannels:(id)sender
{
	[self onJoin:sender];
}

/* onJoin: is a legacy method. It handles join on double click. */
- (void)onJoin:(id)sender
{
	NSIndexSet *indexes = [self.channelListTable selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSUInteger i = [index unsignedIntegerValue];
		
		NSArray *item = self.activeList[i];
		
		if ([self.delegate respondsToSelector:@selector(listDialogOnJoin:channel:)]) {
			[self.delegate listDialogOnJoin:self channel:item[0]];
		}
	}
}

- (void)onSearchFieldChange:(id)sender
{
	self.filteredList = nil;

	NSString *filter = [self.searchField stringValue];

	if ([filter length] > 0) {
		NSMutableArray *ary = [NSMutableArray new];

		for (NSArray *item in self.unfilteredList) {
			NSString *channel = item[0];
			NSString *topicva = item[2];

			NSInteger tr = [topicva stringPositionIgnoringCase:filter];
			NSInteger cr = [channel stringPositionIgnoringCase:filter];

			if (tr >= 0 || cr >= 0) {
				[ary addObject:item];
			}
		}

		self.filteredList = [ary mutableCopy];
	}

	[self reloadTable];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)listCount
{
	if (	    self.filteredList) {
		return [self.filteredList count];
	} else {
		return [self.unfilteredList count];
	}
}

- (NSArray *)activeList
{
	if (	   self.filteredList) {
		return self.filteredList;
	} else {
		return self.unfilteredList;
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return self.listCount;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *item = self.activeList[row];

	if ([[column identifier] isEqualToString:@"chname"]) {
		return item[0];
	} else if ([[column identifier] isEqualToString:@"count"]) {
		return item[1];
	} else {
		return item[3];
	}
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column
{
	NSInteger i = 0;

	if ([[column identifier] isEqualToString:@"chname"]) {
		i = 0;
	} else if ([[column identifier] isEqualToString:@"count"]) {
		i = 1;
	} else {
		i = 2;
	}

	if (self.sortKey == i) {
		self.sortOrder = -(self.sortOrder);
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
	[self releaseTableViewDataSourceBeforeClosure];

	[self.window saveWindowStateForClass:[self class]];
	
	if ([self.delegate respondsToSelector:@selector(listDialogWillClose:)]) {
		[self.delegate listDialogWillClose:self];
	}
}

@end
