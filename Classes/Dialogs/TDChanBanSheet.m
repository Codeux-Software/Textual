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

@interface TDChanBanSheet ()
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *banTable;
@property (nonatomic, strong) NSMutableArray *banList;

- (IBAction)onUpdate:(id)sender;
- (IBAction)onRemoveBans:(id)sender;
@end

@implementation TDChanBanSheet

- (instancetype)init
{
    if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDChanBanSheet" owner:self topLevelObjects:nil];
		
		self.banList = [NSMutableArray new];
    }
    
    return self;
}

- (void)releaseTableViewDataSourceBeforeSheetClosure
{
	[self.banTable setDelegate:nil];
	[self.banTable setDataSource:nil];
}

- (void)show
{
	IRCChannel *c = [worldController() findChannelByClientId:self.clientID channelId:self.channelID];

	NSString *headerTitle = [NSString stringWithFormat:[self.headerTitleTextField stringValue], [c name]];

	[self.headerTitleTextField setStringValue:headerTitle];
	
	[self startSheet];
}

- (void)clear
{
	[self.banList removeAllObjects];
	
	[self reloadTable];
}

- (void)addBan:(NSString *)host tset:(NSString *)timeSet setby:(NSString *)owner
{
	[self.banList addObject:@[host, [owner nicknameFromHostmask], timeSet]];
	
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
	[self.banList removeAllObjects];

	if ([self.delegate respondsToSelector:@selector(chanBanDialogOnUpdate:)]) {
		[self.delegate chanBanDialogOnUpdate:self];
	}
}

- (void)onRemoveBans:(id)sender
{
	NSMutableArray *changeArray = [NSMutableArray array];

	NSString *modeString = nil;
	
	NSMutableString *mdstr = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];
	
	NSIndexSet *indexes = [self.banTable selectedRowIndexes];
	
	NSInteger indexTotal = 0;
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		indexTotal++;
		
		NSArray *iteml = (self.banList)[[index unsignedIntegerValue]];
		
		[mdstr appendString:@"b"];
		[trail appendFormat:@" %@", iteml[0]];
		
		if (indexTotal == TXMaximumNodesPerModeCommand) {
			modeString = (id)[mdstr stringByAppendingString:trail];
			
			[changeArray addObject:modeString];
			
			[mdstr setString:@"-"];
			[trail setString:NSStringEmptyPlaceholder];
			
			indexTotal = 0;
		}
	}
	
	if (NSObjectIsNotEmpty(mdstr)) {
		modeString = (id)[mdstr stringByAppendingString:trail];
		
		[changeArray addObject:modeString];
	}
	
	self.changeModeList = changeArray;
	
	[super cancel:nil];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return [self.banList count];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *item = (self.banList)[row];
	
	if ([[column identifier] isEqualToString:@"mask"]) {
		return item[0];
	} else if ([[column identifier] isEqualToString:@"setby"]) {
		return item[1];
	} else {
		return item[2];
	}
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self releaseTableViewDataSourceBeforeSheetClosure];

	if ([self.delegate respondsToSelector:@selector(chanBanDialogWillClose:)]) {
		[self.delegate chanBanDialogWillClose:self];
	}
}

@end
