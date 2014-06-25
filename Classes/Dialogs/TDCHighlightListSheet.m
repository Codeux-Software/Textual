/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#define _rowHeightMultiplier		17

@interface TDCHighlightListSheet ()
@property (nonatomic, copy) NSArray *highlightList;
@end

@implementation TDCHighlightListSheet

- (id)init
{
    if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCHighlightListSheet" owner:self topLevelObjects:nil];
    }
    
    return self;
}

- (void)releaseTableViewDataSourceBeforeSheetClosure
{
	[_highlightListTable setDelegate:nil];
	[_highlightListTable setDataSource:nil];
}

- (void)show
{
	IRCClient *currentNetwork = [worldController() findClientById:_clientID];

	NSString *network = [currentNetwork altNetworkName];

	[_headerTitleField setStringValue:[NSString stringWithFormat:[_headerTitleField stringValue], network]];

	[_highlightListTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	
    [self startSheet];
	[self reloadTable];
}

- (void)onClearList:(id)sender
{
	IRCClient *currentNetwork = [worldController() findClientById:_clientID];
	
	[currentNetwork setHighlights:@[]];

    [self reloadTable];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (void)reloadTable
{
	IRCClient *currentNetwork = [worldController() findClientById:_clientID];

	[self setHighlightList:[currentNetwork highlights]];
	
    [_highlightListTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return [_highlightList count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	/* See the addHighlight… in IRCClieht.m for a description of the format
	 of highlight entries for a client. */
	NSObjectIsEmptyAssertReturn(_highlightList, _rowHeightMultiplier);
	
	NSRect columnRect = [tableView rectOfColumn:1];
	
	NSArray *data = [_highlightList objectAtIndex:row];

	NSAttributedString *baseString = [data objectAtIndex:2];

	NSInteger totalLines = [baseString wrappedLineCount:columnRect.size.width
										 lineMultiplier:_rowHeightMultiplier
											 forcedFont:[NSFont systemFontOfSize:13.0]];

	return (totalLines * _rowHeightMultiplier);
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *item = _highlightList[row];
	
    if ([[column identifier] isEqualToString:@"chan"]) {
		return item[0];
	} else if ([[column identifier] isEqualToString:@"time"]) {
		NSInteger timeInterval = [item integerAtIndex:1];
		
		NSString *timestring = TXHumanReadableTimeInterval([NSDate secondsSinceUnixTimestamp:timeInterval], YES, 0);
		
		return TXTLS(@"BasicLanguage[1216]", timestring);
    } else {
		return item[2];
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
