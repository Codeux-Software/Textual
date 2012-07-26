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

@implementation TDChanInviteExceptionSheet

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDChanInviteExceptionSheet" owner:self];
		
		self.list  = [NSMutableArray new];
        self.modes = [NSMutableArray new];
    }
    
    return self;
}

- (void)show
{
	IRCClient  *u = self.delegate;
	IRCChannel *c = [u.world selectedChannel];
	
	NSString *nheader;
	
	nheader = [self.header stringValue];
	nheader = [NSString stringWithFormat:nheader, c.name];
	
	[self.header setStringValue:nheader];
	
    [self startSheet];
}

- (void)ok:(id)sender
{
	[self endSheet];
	
	if ([self.delegate respondsToSelector:@selector(chanInviteExceptionDialogWillClose:)]) {
		[self.delegate chanInviteExceptionDialogWillClose:self];
	}
}

- (void)clear
{
    [self.list removeAllObjects];
	
    [self reloadTable];
}

- (void)addException:(NSString *)host tset:(NSString *)time setby:(NSString *)owner
{
    [self.list safeAddObject:@[host, [owner nicknameFromHostmask], time]];
    
    [self reloadTable];
}

- (void)reloadTable
{
    [self.table reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)onUpdate:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(chanInviteExceptionDialogOnUpdate:)]) {
		[self.delegate chanInviteExceptionDialogOnUpdate:self];
    }
}

- (void)onRemoveExceptions:(id)sender
{
    NSString *modeString;
    
	NSMutableString *str   = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];
	
	NSIndexSet *indexes = [self.table selectedRowIndexes];
	
    NSInteger indexTotal = 0;
    
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
        indexTotal++;
        
		NSArray *iteml = [self.list safeObjectAtIndex:[index unsignedIntegerValue]];
		
		if (NSObjectIsNotEmpty(iteml)) {
			[str   appendString:@"I"];
			[trail appendFormat:@" %@", [iteml safeObjectAtIndex:0]];
		}
        
		if (indexTotal == TXMaximumNodesPerModeCommand) {
            modeString = (id)[str stringByAppendingString:trail];
            
            [self.modes safeAddObject:modeString];
            
            [str   setString:@"-"];
            [trail setString:NSStringEmptyPlaceholder];
            
            indexTotal = 0;
        }
	}
	
    if (NSObjectIsNotEmpty(trail)) {
        modeString = (id)[str stringByAppendingString:trail];
        
        [self.modes safeAddObject:modeString];
    }
    
	[self ok:sender];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return self.list.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray *item = [self.list safeObjectAtIndex:row];

    NSString *col = [column identifier];
    
    if ([col isEqualToString:@"mask"]) {
		return [item safeObjectAtIndex:0];
    } else if ([col isEqualToString:@"setby"]) {
		return [item safeObjectAtIndex:1];
    } else {
		return [item safeObjectAtIndex:2];
    }
}

@end