/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#define _renderedMessageTextFieldLeftRightPadding		2

@interface TDCServerHighlightListSheet ()
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *highlightListTable;
@property (nonatomic, strong) IBOutlet NSArrayController *highlightListController;

- (IBAction)onClearList:(id)sender;
@end

@implementation TDCServerHighlightListSheet

- (instancetype)init
{
    if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCServerHighlightListSheet" owner:self topLevelObjects:nil];

		[self.highlightListTable setDoubleAction:@selector(highlightDoubleClicked:)];

		[self.highlightListTable setSortDescriptors:@[
			[NSSortDescriptor sortDescriptorWithKey:@"timeLogged" ascending:NO selector:@selector(compare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"channelName" ascending:NO selector:@selector(caseInsensitiveCompare:)]
		]];
	}
    
    return self;
}

- (void)show
{
	IRCClient *currentNetwork = [worldController() findClientWithId:self.clientID];

	NSString *unformattedHeaderTitle = [self.headerTitleTextField stringValue];

	NSString *headerTitle = [NSString stringWithFormat:unformattedHeaderTitle, [currentNetwork altNetworkName]];

	[self.headerTitleTextField setStringValue:headerTitle];

    [self startSheet];

	[self addEntry:[currentNetwork cachedHighlights]]; // Populate current cache...
}

- (void)addEntry:(id)newEntry
{
	if (newEntry && [newEntry isKindOfClass:[NSArray class]])
	{
		for (id arrayObject in newEntry) {
			[self addEntry:arrayObject];
		}
	}
	else if (newEntry && [newEntry isKindOfClass:[IRCHighlightLogEntry class]])
	{
		[self.highlightListController addObject:newEntry];
	}
}

- (void)lazilyDefineHeightForRow:(NSInteger)row
{
	NSTableView *aTableView = [self highlightListTable];

	NSTableColumn *tableColumn = [aTableView tableColumnWithIdentifier:@"renderedMessage"];

	NSTableCellView *cellView = (id)[self tableView:aTableView viewForTableColumn:tableColumn row:row];

	NSRect textFieldFrame = [[cellView textField] frame];

	[self performBlockOnGlobalQueue:^{
		IRCHighlightLogEntry *entryItem = [self.highlightListController arrangedObjects][row];

		CGFloat calculatedTextHeight = [[entryItem renderedMessage] pixelHeightInWidth:(NSWidth(textFieldFrame) - (_renderedMessageTextFieldLeftRightPadding * 2))];

		CGFloat finalRowHeight = (ceil(calculatedTextHeight / [aTableView rowHeight]) * [aTableView rowHeight]);

		[entryItem setRowHeight:finalRowHeight];

		[self performBlockOnMainThread:^{
			NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndex:row];

			[NSAnimationContext beginGrouping];

			[RZAnimationCurrentContext() setDuration:0.0];

			[aTableView noteHeightOfRowsWithIndexesChanged:rowIndexSet];

			[NSAnimationContext endGrouping];
		}];
	}];
}

- (void)onClearList:(id)sender
{
	[self.highlightListController setContent:nil];

	IRCClient *currentNetwork = [worldController() findClientWithId:self.clientID];

	[currentNetwork clearCachedHighlights];
}

- (void)highlightDoubleClicked:(id)sender
{
	NSInteger row = [self.highlightListTable clickedRow];

	if (row >= 0) {
		IRCHighlightLogEntry *entryItem = [self.highlightListController arrangedObjects][row];

		IRCChannel *channel = [entryItem channel];

		PointerIsEmptyAssert(channel);

		TVCLogController *viewController = [channel viewController];

		[viewController jumpToLine:[entryItem lineNumber] completionHandler:^(BOOL result) {
			if (result) {
				[mainWindow() select:channel];

				[self cancel:nil];
			}
		}];
	}
}

#pragma mark -
#pragma mark NSTableView Delegate

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row
{
	IRCHighlightLogEntry *entryItem = [self.highlightListController arrangedObjects][row];

	if ([entryItem rowHeight] > 0) {
		return [entryItem rowHeight];
	} else {
		return [aTableView rowHeight];
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];

	return result;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	[self lazilyDefineHeightForRow:row];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.highlightListTable setDelegate:nil];
	[self.highlightListTable setDataSource:nil];

	if ([self.delegate respondsToSelector:@selector(serverHighlightListSheetWillClose:)]) {
		[self.delegate serverHighlightListSheetWillClose:self];
	}
}

@end
