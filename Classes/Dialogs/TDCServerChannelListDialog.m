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

@interface TDCServerChannelListDialogEntry : NSObject
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSNumber *channelMemberCount;
@property (nonatomic, copy) NSString *channelTopicUnformatted;
@property (nonatomic, copy) NSAttributedString *channelTopicFormatted;
@end

@interface TDCServerChannelListDialog ()
@property (nonatomic, assign) BOOL isWaitingForWrites;
@property (nonatomic, strong) NSMutableArray *queuedWrites;
@property (nonatomic, weak) IBOutlet NSButton *updateButton;
@property (nonatomic, weak) IBOutlet NSSearchField *searchTextField;
@property (nonatomic, weak) IBOutlet NSTextField *networkNameTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *channelListTable;
@property (nonatomic, strong) IBOutlet NSArrayController *channelListController;

- (IBAction)onClose:(id)sender;

- (IBAction)onUpdate:(id)sender;
- (IBAction)onJoinChannels:(id)sender;
@end

@implementation TDCServerChannelListDialog

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCServerChannelListDialog" owner:self topLevelObjects:nil];

		self.queuedWrites = [NSMutableArray array];
	}

	return self;
}

- (void)start
{
	[self.channelListTable setDoubleAction:@selector(onJoin:)];

	[self.channelListTable setSortDescriptors:@[
		[NSSortDescriptor sortDescriptorWithKey:@"channelMemberCount" ascending:NO selector:@selector(compare:)]
	]];

	[self show];
}

- (void)show
{
	IRCClient *client = [worldController() findClientById:self.clientID];

    [self.networkNameTextField setStringValue:TXTLS(@"TDCServerChannelListDialog[1000]", [client altNetworkName])];

	[[self window] restoreWindowStateForClass:[self class]];
	
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)close
{
	[[self window] close];
}

- (void)clear
{
	[self.channelListController setContent:nil];

	[self updateDialogTitle];
}

- (void)addChannel:(NSString *)channel count:(NSInteger)count topic:(NSString *)topic
{
	if ([channel isChannelName]) {
		NSAttributedString *renderedTopic = [topic attributedStringWithIRCFormatting:[NSTableView preferredGlobalTableViewFont] preferredFontColor:[NSColor blackColor]];

		TDCServerChannelListDialogEntry *newEntry = [TDCServerChannelListDialogEntry new];

		[newEntry setChannelName:channel];

		[newEntry setChannelMemberCount:@(count)];

		[newEntry setChannelTopicUnformatted:topic];
		[newEntry setChannelTopicFormatted:renderedTopic];

		@synchronized(self.queuedWrites) {
			[self.queuedWrites addObject:newEntry];
		}

		if (self.isWaitingForWrites == NO) {
			self.isWaitingForWrites = YES;

			[self performSelector:@selector(queuedWritesTimer) withObject:nil afterDelay:1.0];
		}
	}
}

- (void)queuedWritesTimer
{
	[self writeQueuedWrites];

	self.isWaitingForWrites = NO;
}

- (void)writeQueuedWrites
{
	@synchronized(self.queuedWrites) {
		if ([self.queuedWrites count] == 0) {
			return; // Cancel write...
		}

		NSPredicate *filterPredicate = [self.channelListController filterPredicate];

		if (filterPredicate) {
			NSMutableArray *queuedWrites = [NSMutableArray array];

			for (TDCServerChannelListDialogEntry *queuedWrite in self.queuedWrites) {
				if ([filterPredicate evaluateWithObject:queuedWrite]) {
					[queuedWrites addObject:queuedWrite];
				}
			}

			[self.channelListController addObjects:queuedWrites];

			[self.queuedWrites removeObjectsInArray:queuedWrites];
		} else {
			[self.channelListController addObjects:self.queuedWrites];

			[self.queuedWrites removeAllObjects];
		}
	}

	[self updateDialogTitle];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	if ([obj object] == self.searchTextField) {
		NSString *currentSearchValue = [self.searchTextField stringValue];

		if ([currentSearchValue length] == 0) {
			[self writeQueuedWrites];
		}
	}
}

- (void)updateDialogTitle
{
	id arrangedObjects = [self.channelListController arrangedObjects];

	NSString *arrangedObjectsCount = TXFormattedNumber([arrangedObjects count]);

	[self.window setTitle:TXTLS(@"TDCServerChannelListDialog[1001]", arrangedObjectsCount)];
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

	if ([self.delegate respondsToSelector:@selector(serverChannelListDialogOnUpdate:)]) {
		[self.delegate serverChannelListDialogOnUpdate:self];
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
	NSArray *selectedRows = [self.channelListTable selectedRows];

	for (NSNumber *indexNumber in selectedRows) {
		NSInteger index = [indexNumber unsignedIntegerValue];

		TDCServerChannelListDialogEntry *channelEntry = [self.channelListController arrangedObjects][index];

		if ([self.delegate respondsToSelector:@selector(serverChannelListDialogOnJoin:channel:)]) {
			[self.delegate serverChannelListDialogOnJoin:self channel:[channelEntry channelName]];
		}
	}

	[self.channelListTable deselectAll:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[[self window] saveWindowStateForClass:[self class]];
	
	if ([self.delegate respondsToSelector:@selector(serverChannelDialogWillClose:)]) {
		[self.delegate serverChannelDialogWillClose:self];
	}
}

@end

#pragma mark -

@implementation TDCServerChannelListDialogEntry
@end
