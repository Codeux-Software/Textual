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

@implementation TDChanBanSheet

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDChanBanSheet" owner:self];
		
		self.banList = [NSMutableArray new];
        self.changeModeList = [NSMutableArray new];
    }
    
    return self;
}

- (void)show
{
	IRCChannel *c = self.worldController.selectedChannel;

	self.headerTitleField.stringValue = [NSString stringWithFormat:self.headerTitleField.stringValue, c.name];

    [self startSheet];
}

- (void)clear
{
    [self.banList removeAllObjects];
	
    [self reloadTable];
}

- (void)addBan:(NSString *)host tset:(NSString *)timeSet setby:(NSString *)owner
{
    [self.banList safeAddObject:@[host, [owner nicknameFromHostmask], timeSet]];
    
    [self reloadTable];
}

- (void)reloadTable
{
    [self.banTable reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)onUpdate:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(chanBanDialogOnUpdate:)]) {
		[self.delegate chanBanDialogOnUpdate:self];
    }
}

- (void)onRemoveBans:(id)sender
{
    NSString *modeString;

	NSMutableString *mdstr = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];

	NSIndexSet *indexes = [self.banTable selectedRowIndexes];

    NSInteger indexTotal = 0;

	for (NSNumber *index in [indexes arrayFromIndexSet]) {
        indexTotal++;

		NSArray *iteml = [self.banList safeObjectAtIndex:index.unsignedIntegerValue];

		if (NSObjectIsNotEmpty(iteml)) {
			[mdstr appendString:@"b"];
			[trail appendFormat:@" %@", [iteml safeObjectAtIndex:0]];
		}

		if (indexTotal == TXMaximumNodesPerModeCommand) {
            modeString = (id)[mdstr stringByAppendingString:trail];

            [self.changeModeList safeAddObject:modeString];

            [mdstr setString:@"-"];
            [trail setString:NSStringEmptyPlaceholder];

            indexTotal = 0;
        }
	}

    if (NSObjectIsNotEmpty(mdstr)) {
        modeString = (id)[mdstr stringByAppendingString:trail];

        [self.changeModeList safeAddObject:modeString];
    }

	[super cancel:nil];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return self.banList.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray *item = [self.banList safeObjectAtIndex:row];

    if ([column.identifier isEqualToString:@"mask"]) {
		return [item safeObjectAtIndex:0];
    } else if ([column.identifier isEqualToString:@"setby"]) {
		return [item safeObjectAtIndex:1];
    } else {
		return [item safeObjectAtIndex:2];
    }
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(chanBanDialogWillClose:)]) {
		[self.delegate chanBanDialogWillClose:self];
	}
}

@end
