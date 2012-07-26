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

#define _rowHeightMultiplier	17

@implementation TDCHighlightSheet

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCHighlightSheet" owner:self];
    }
    
    return self;
}

- (void)show
{
	TXMenuController *menu = self.delegate;
	
	IRCClient *currentNetwork = [menu.world selectedClient];

	NSString *currentHeader = nil;
	NSString *network = currentNetwork.config.network;
	
	if (NSObjectIsEmpty(network)) {
		network = currentNetwork.config.name;
	}
	
	currentHeader = [self.header stringValue];
	currentHeader = [NSString stringWithFormat:currentHeader, network];
	
	[self.header setStringValue:currentHeader];
    [self.table setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	
    [self startSheet];
}

- (void)ok:(id)sender
{
	[self endSheet];
	
	if ([self.delegate respondsToSelector:@selector(highlightSheetWillClose:)]) {
		[self.delegate highlightSheetWillClose:self];
	}
}

- (void)clear
{
    [self.list removeAllObjects];
	
    [self reloadTable];
}

- (void)reloadTable
{
    [self.table reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)onClearList:(id)sender
{
	[self clear];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return self.list.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if (self.list.count <= 0) {
		return _rowHeightMultiplier;
	}
	
	NSRect columnRect = [tableView rectOfColumn:1];
	
	NSArray *data = [self.list safeObjectAtIndex:row];

	NSAttributedString *baseString = [data safeObjectAtIndex:2];

	NSInteger totalLines = [baseString wrappedLineCount:columnRect.size.width
										 lineMultiplier:13.0
											 forcedFont:[NSFont systemFontOfSize:13.0]];

	return (totalLines * _rowHeightMultiplier);
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray  *item = [self.list safeObjectAtIndex:row];
	
    NSString *col  = [column identifier];
    
    if ([col isEqualToString:@"chan"]) {
		return [item safeObjectAtIndex:0];
	} else if ([col isEqualToString:@"time"]) {
		NSInteger time = [item integerAtIndex:1];
		
		return TXTFLS(@"TimeAgo", TXSpecialReadableTime([NSDate secondsSinceUnixTimestamp:time], YES, nil));
    } else {
        return [item safeObjectAtIndex:2];
    }
}

@end
