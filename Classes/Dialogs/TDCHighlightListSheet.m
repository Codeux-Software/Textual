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

@interface TDCHighlightListSheet ()
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *highlightListTable;
@property (nonatomic, strong) IBOutlet NSArrayController *highlightListController;

- (IBAction)onClearList:(id)sender;
@end

@implementation TDCHighlightListSheet

- (instancetype)init
{
    if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCHighlightListSheet" owner:self topLevelObjects:nil];

		[self.highlightListTable setSortDescriptors:@[
			[NSSortDescriptor sortDescriptorWithKey:@"timeLoggedFormatted" ascending:NO selector:@selector(caseInsensitiveCompare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"channelName" ascending:NO selector:@selector(caseInsensitiveCompare:)]
		]];
	}
    
    return self;
}

- (void)show
{
	IRCClient *currentNetwork = [worldController() findClientById:self.clientID];

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
	else if (newEntry && [newEntry isKindOfClass:[TDCHighlightListSheetEntry class]])
	{
		[self.highlightListController addObject:newEntry];
	}
}

- (void)onClearList:(id)sender
{
	[self.highlightListController setContent:nil];

	IRCClient *currentNetwork = [worldController() findClientById:self.clientID];

	[currentNetwork clearCachedHighlights];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row
{
	NSTableColumn *tableColumn = [aTableView tableColumnWithIdentifier:@"renderedMessage"];

	NSTableCellView *cellView = (id)[self tableView:aTableView viewForTableColumn:tableColumn row:row];

	NSRect textFieldFrame = [[cellView textField] frame];

	TDCHighlightListSheetEntry *entryItem = [self.highlightListController arrangedObjects][row];

	CGFloat calculatedHeight = [[entryItem renderedMessage] pixelHeightInWidth:(NSWidth(textFieldFrame) - (_renderedMessageTextFieldLeftRightPadding * 2))];

	return (ceilf(calculatedHeight / [aTableView rowHeight]) * [aTableView rowHeight]);
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];

	return result;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.highlightListTable setDelegate:nil];
	[self.highlightListTable setDataSource:nil];

	if ([self.delegate respondsToSelector:@selector(highlightListSheetWillClose:)]) {
		[self.delegate highlightListSheetWillClose:self];
	}
}

@end

#pragma mark -

@implementation TDCHighlightListSheetEntry

- (NSString *)timeLoggedFormatted
{
	if (self.timeLogged == nil) {
		return nil; // What to do with nil?...
	}

	NSTimeInterval timeInterval = [self.timeLogged timeIntervalSinceNow];

	NSString *formattedTimeInterval = TXHumanReadableTimeInterval(timeInterval, YES, 0);

	return BLS(1216, formattedTimeInterval);
}

@end
