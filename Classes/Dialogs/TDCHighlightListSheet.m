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

#define _rowHeightMultiplier		17

@interface TDCHighlightListSheet ()
@property (nonatomic, readonly, nweak) NSMutableArray *highlightList;
@end

@implementation TDCHighlightListSheet

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCHighlightListSheet" owner:self];
    }
    
    return self;
}

- (void)show
{
	IRCClient *currentNetwork = self.worldController.selectedClient;

	NSString *network = [currentNetwork altNetworkName];

	self.headerTitleField.stringValue = [NSString stringWithFormat:self.headerTitleField.stringValue, network];

	self.highlightListTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
	
    [self startSheet];
}

- (void)onClearList:(id)sender
{
    [self.highlightList removeAllObjects];

    [self reloadTable];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSMutableArray *)highlightList
{
	return self.worldController.selectedClient.highlights;
}

- (void)reloadTable
{
    [self.highlightListTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return self.highlightList.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSObjectIsEmptyAssertReturn(self.highlightList, _rowHeightMultiplier);
	
	NSRect columnRect = [tableView rectOfColumn:1];
	
	NSArray *data = [self.highlightList safeObjectAtIndex:row];

	NSAttributedString *baseString = [data safeObjectAtIndex:2];

	NSInteger totalLines = [baseString wrappedLineCount:columnRect.size.width
										 lineMultiplier:_rowHeightMultiplier
											 forcedFont:[NSFont systemFontOfSize:13.0]];

	return (totalLines * _rowHeightMultiplier);
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray *item = [self.highlightList safeObjectAtIndex:row];
	
    if ([column.identifier isEqualToString:@"chan"]) {
		return [item safeObjectAtIndex:0];
	} else if ([column.identifier isEqualToString:@"time"]) {
		NSInteger timeInterval = [item integerAtIndex:1];
		
		return TXTFLS(@"TimeAgo", TXSpecialReadableTime([NSDate secondsSinceUnixTimestamp:timeInterval], YES, nil));
    } else {
        return [item safeObjectAtIndex:2];
    }
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(highlightListSheetWillClose:)]) {
		[self.delegate highlightListSheetWillClose:self];
	}
}

@end
