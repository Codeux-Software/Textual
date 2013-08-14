/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

#define _treeUserlistHeight					18.0

#define _cancelOnNotSelectedChannel			NSAssertReturn(self.isSelectedChannel && self.isChannel);

@implementation IRCChannel

@synthesize client = _client;
@synthesize printingQueue = _printingQueue;

- (id)init
{
	if ((self = [super init])) {
		self.modeInfo = [IRCChannelMode new];
		
		self.memberList = [NSMutableArray new];
	}
	
	return self;
}

#pragma mark -
#pragma mark Configuration

- (void)setup:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssert(seed);

	if (PointerIsEmpty(self.config)) {
		self.config = [seed mutableCopy];
	}
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssert(seed);
	
	self.config = [seed mutableCopy];
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self.config dictionaryValue];
}

#pragma mark -
#pragma mark Property Getter

- (NSString *)name
{
	return self.config.channelName;
}

- (NSString *)secretKey
{
	return self.config.secretKey;
}

- (BOOL)isChannel
{
	return (self.config.type == IRCChannelNormalType);
}

- (BOOL)isPrivateMessage
{
	return (self.config.type == IRCChannelPrivateMessageType);
}

- (NSString *)channelTypeString
{
	if (self.config.type == IRCChannelPrivateMessageType) {
		return @"query";
	}

	return @"channel";
}

#pragma mark -
#pragma mark Property Setter

- (void)setName:(NSString *)value
{
	if ([self.name isEqualToString:value] == NO) {
		self.config.channelName = value;
	}
}

- (void)setTopic:(NSString *)topic
{
	if ([_topic isEqualToString:topic] == NO) {
		_topic = topic;
	}

    [self.viewController setTopic:topic];
}

#pragma mark -
#pragma mark Utilities

- (void)preferencesChanged
{
	[self.viewController preferencesChanged];

	if ([TPCPreferences displayPublicMessageCountOnDockBadge] == NO) {
		if (self.isPrivateMessage == NO) {
			self.dockUnreadCount = 0; // Reset counter on changes.
		}
	}

	[self reopenLogFileIfNeeded];
}

#pragma mark -
#pragma mark Channel Status

- (void)resetStatus:(IRCChannelStatus)newStatus
{
	self.errorOnLastJoinAttempt = NO;
	self.inUserInvokedModeRequest = NO;

	self.channelJoinTime = -1;
	
	self.status = newStatus;

    _topic = nil;
	
	[self.modeInfo clear];

	[self clearMembers];
	[self reloadDataForTableView];
}

- (void)activate
{
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelJoined" forChannel:self];
    }

	[self resetStatus:IRCChannelJoined];

	if (self.isPrivateMessage) {
		IRCUser *m = nil;

		/* Populate private message users. */
		m = [IRCUser new];
		m.nickname = [self.client localNickname];
		m.supportInfo = [self.client isupport];
		[self addMember:m];

		m = [IRCUser new];
		m.nickname = self.name;
		m.supportInfo = [self.client isupport];
		[self addMember:m];
	}

	self.channelJoinTime = [NSDate epochTime];
}

- (void)deactivate
{
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelParted" forChannel:self];

		[self.viewController setTopic:nil];
    }

	[self resetStatus:IRCChannelParted];

	self.channelJoinTime = -1;
}

- (void)terminate
{
	[self resetStatus:IRCChannelTerminated];
	
	[self closeLogFile];

	[self.viewController terminate];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logTranscript]) {
		PointerIsEmptyAssert(self.logFile);

		[self.logFile updateWriteCacheTimer];
		[self.logFile reopenIfNeeded];
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	PointerIsEmptyAssert(self.logFile);

	[self.logFile close];
}

#pragma mark -
#pragma mark Printing

- (void)writeToLogFile:(TVCLogLine *)line
{
	if ([TPCPreferences logTranscript]) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];

			self.logFile.client = self.client;
			self.logFile.channel = self;
		}

		NSString *logstr = [self.viewController renderedBodyForTranscriptLog:line];

		if (NSObjectIsNotEmpty(logstr)) {
			[self.logFile writePlainTextLine:logstr];
		}
	}
}

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	[self.viewController print:logLine completionBlock:completionBlock];
	
	[self writeToLogFile:logLine];
}

#pragma mark -
#pragma mark Member List

- (void)sortedInsert:(IRCUser *)item
{
	PointerIsEmptyAssert(item);

	/* Normal member list used internally by Textual. */
	self.memberList = [self.memberList arrayByInsertingSortedObject:item usingComparator:NSDefaultComparator];

	/* Conversation tracking scans based on nickname length. */
	self.memberListLengthSorted = [self.memberList arrayByInsertingSortedObject:item usingComparator:[IRCUser nicknameLengthComparator]];
}

- (void)addMember:(IRCUser *)user
{
	PointerIsEmptyAssert(user);

	/* Remove any existing copies of this nickname. */
	[self removeMember:user.nickname fromTable:YES];

	/* Do sorted insert. */
	[self sortedInsert:user];

	/* Post event to the style. */
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelMemberAdded" forChannel:self];
	}

	/* Update the actual member list view. */
	[self informMemberListViewOfAdditionalUser:user];
}

- (void)removeMember:(NSString *)nick
{
	[self removeMember:nick fromTable:YES];
}

- (void)removeMember:(NSString *)nick fromTable:(BOOL)fromTable
{
	NSObjectIsEmptyAssert(nick);

	self.memberListLengthSorted	= [self removeMember:nick fromList:self.memberListLengthSorted blockBeforeRemoval:NULL];

	self.memberList = [self removeMember:nick fromList:self.memberList blockBeforeRemoval:^(NSUInteger idx) {
		/* Find user on member list table and remove if they exist there. */
		if (fromTable && self.isChannel && self.isSelectedChannel) {
			IRCUser *member = self.memberList[idx];

			NSInteger tableIndex = [self.memberListView rowForItem:member];

			if (tableIndex > -1) { // Did they exist on list?
				[self.memberListView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:tableIndex]
												 inParent:nil
											withAnimation:NSTableViewAnimationEffectNone]; // Do the actual removal.
			}
		}

		/* Post event to the style. */
		if (self.isChannel) {
			[self.client postEventToViewController:@"channelMemberRemoved" forChannel:self];
		}
	}];
}

- (NSArray *)removeMember:(NSString *)nick fromList:(NSArray *)memberList blockBeforeRemoval:(void (^)(NSUInteger idx))block
{
	NSInteger n = [self indexOfMember:nick options:NSCaseInsensitiveSearch inList:memberList];

	if (n == NSNotFound || n < 0) {
		return memberList;
	}

	if (PointerIsNotEmpty(block)) {
		block(n);
	}

	return [memberList arrayByRemovingObjectAtIndex:n];
}

- (void)renameMember:(NSString *)fromNick to:(NSString *)toNick performOnChange:(void (^)(IRCUser *user))block
{
	NSObjectIsEmptyAssert(fromNick);
	NSObjectIsEmptyAssert(toNick);

	/* Find user. */
	NSInteger n = [self indexOfMember:fromNick options:NSCaseInsensitiveSearch];

	NSAssertReturn(NSDissimilarObjects(n, NSNotFound));

	IRCUser *m = [self memberAtIndex:n];

	/* Rename. */
	m.nickname = toNick;

	/* Migrate user so that it does a sorted insert. */
	[self migrateUser:m from:m];

	/* Inform upstream. */
	PointerIsEmptyAssert(block);

	block(m);
}

#pragma mark -

- (BOOL)memberRequiresRedraw:(IRCUser *)user1 comparedTo:(IRCUser *)user2
{
	PointerIsEmptyAssertReturn(user1, NO);
	PointerIsEmptyAssertReturn(user2, NO);

	if (NSDissimilarObjects(user1.isCop, user2.isCop)			|| // <--------/
		NSDissimilarObjects(user1.q, user2.q)					|| // <-------/ Different mode information.
		NSDissimilarObjects(user1.a, user2.a)					|| // <------/
		NSDissimilarObjects(user1.o, user2.o)					|| // <-----/
		NSDissimilarObjects(user1.h, user2.h)					|| // <----/
		NSDissimilarObjects(user1.v, user2.v)					|| // <---/
		NSDissimilarObjects(user1.isAway, user2.isAway)			|| // <--/ Away state.
		[user1.hostmask isEqual:user2.hostmask] == NO)			   // <-/ User host.
	{
		return YES;
	}

	return NO;
}

- (void)migrateUser:(IRCUser *)user1 from:(IRCUser *)user2
{
	PointerIsEmptyAssert(user1);
	PointerIsEmptyAssert(user2);

	/* Migrate data to the old instance so that the pointer in the table view
	 does not have to be taken out. */
	[user1 migrate:user2];

	/* Remove any existing copies of this nickname. From self.memberList while
	 retaining the actual pointer in the table view. */
	[self removeMember:user1.nickname fromTable:NO];

	/* Do sorted insert. */
	[self sortedInsert:user1];

	/* Reload the position of the user in table view. */
	[self reloadDataForTableViewBySortingMembersForUser:user1];
}

- (void)changeMember:(NSString *)nick mode:(NSString *)mode value:(BOOL)value performOnChange:(void (^)(IRCUser *user))block
{
	NSObjectIsEmptyAssert(nick);
	NSObjectIsEmptyAssert(mode);
	
	NSInteger n = [self indexOfMember:nick options:NSCaseInsensitiveSearch];

	NSAssertReturn(NSDissimilarObjects(n, NSNotFound));

	/* We create new copy of this user in order to compare them and deterine
	 if there are changes when we are done. */
	IRCUser *on = self.memberList[n];
	IRCUser *mn = [on copy];

	switch ([mode characterAtIndex:0]) {
		case 'O': { mn.q = value; break; } // binircd-1.0.0
		case 'q': { mn.q = value; break; }
		case 'a': { mn.a = value; break; }
		case 'o': { mn.o = value; break; }
		case 'h': { mn.h = value; break; }
		case 'v': { mn.v = value; break; }
	}

	IRCISupportInfo *isupport = self.client.isupport;

	mn.q = (mn.q && ([isupport modeIsSupportedUserPrefix:@"q"] || [isupport modeIsSupportedUserPrefix:@"O"] /* binircd-1.0.0 */));
	mn.a = (mn.a &&  [isupport modeIsSupportedUserPrefix:@"a"]);
	mn.o = (mn.o &&  [isupport modeIsSupportedUserPrefix:@"o"]);
	mn.h = (mn.h &&  [isupport modeIsSupportedUserPrefix:@"h"]);
	mn.v = (mn.v &&  [isupport modeIsSupportedUserPrefix:@"v"]);

	/* Did something change. */
	if ([self memberRequiresRedraw:on comparedTo:mn]) {
		/* Migrate data. We want to move any changes applied to the new
		 copy to the old pointer so that we do not have to remove it from
		 the table view. We only have to redraw it. */
		[self migrateUser:on from:mn];

		/* Tell the upstream about the updates. */
		PointerIsEmptyAssert(block);

		block(on);
	}
}

#pragma mark -

- (void)clearMembers
{
	self.memberList = nil;
	self.memberList = @[];

	self.memberListLengthSorted = nil;
	self.memberListLengthSorted = @[];
}

- (NSInteger)numberOfMembers
{
	return self.memberList.count;
}

#pragma mark -
#pragma mark User Search

- (IRCUser *)memberAtIndex:(NSInteger)index
{
	return [self.memberList safeObjectAtIndex:index];
}

- (NSInteger)indexOfMember:(NSString *)nick
{
	return [self indexOfMember:nick options:0];
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	return [self indexOfMember:nick options:mask inList:self.memberList];
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask inList:(NSArray *)memberList
{
	NSObjectIsEmptyAssertReturn(nick, -1);

	if (mask & NSCaseInsensitiveSearch) {
		return [memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualIgnoringCase:)];
	} else {
		return [memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualToString:)];
	}
}

- (IRCUser *)findMember:(NSString *)nick
{
	return [self findMember:nick options:0];
}

- (IRCUser *)findMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger n = [self indexOfMember:nick options:mask];

	NSAssertReturnR(NSDissimilarObjects(n, NSNotFound), nil);
	
	return [self memberAtIndex:n];
}

#pragma mark -
#pragma mark Table View Internal Management

- (void)informMemberListViewOfAdditionalUser:(IRCUser *)user
{
	_cancelOnNotSelectedChannel;

	/* Do not ask me how this fucking works … I don't even know. */
	NSInteger mlindx = [self.memberList indexOfObject:user];

	NSAssertReturn(NSDissimilarObjects(mlindx, NSNotFound));

	if (mlindx > 0) {
		IRCUser *prevItem = [self.memberList objectAtIndex:(mlindx - 1)];

		NSInteger prevIndex = [self.memberListView rowForItem:prevItem];

		if (prevIndex == NSNotFound) {
			[self.memberListView addItemToList:self.memberListView.numberOfRows];
		} else {
			[self.memberListView addItemToList:(prevIndex + 1)];
		}
	} else {
		[self.memberListView addItemToList:0];
	}
}

- (void)reloadDataForTableViewBySortingMembers
{
	_cancelOnNotSelectedChannel;

	self.memberList = [self.memberList sortedArrayUsingComparator:NSDefaultComparator];

	[self reloadDataForTableView];
}

- (void)reloadDataForTableViewBySortingMembersForUser:(IRCUser *)user
{
	_cancelOnNotSelectedChannel;

	/* We are basically comparing the position of an user in the member list to that
	 of the actual table. If one is different, then we move them. This is done so 
	 mode changes can move positions in the list. */
	NSInteger selfIndex = [self.memberList indexOfObject:user];

	NSInteger tablIndex = [self.memberListView rowForItem:user];

	if (NSDissimilarObjects(selfIndex, tablIndex) && tablIndex > -1) {
		[self.memberListView moveItemAtIndex:tablIndex
									inParent:nil
									 toIndex:selfIndex
									inParent:nil];
	}
}

- (void)reloadDataForTableView
{
	_cancelOnNotSelectedChannel;

	[self.memberListView reloadData];
}

- (void)updateTableViewByRemovingIgnoredUsers
{
	NSMutableIndexSet *rowsToRemove = [NSMutableIndexSet indexSet];

	for (NSInteger i = 0; i < [self.memberListView numberOfRows]; i++) {
		IRCUser *uar = [self.memberListView itemAtRow:i];

		IRCAddressBook *ignoreChecks = [self.client checkIgnoreAgainstHostmask:[uar hostmask] withMatches:@[@"hideInMemberList"]];

		if (ignoreChecks && [ignoreChecks hideInMemberList]) {
			[rowsToRemove addIndex:i];
		}
	}

	NSObjectIsEmptyAssert(rowsToRemove);

	[self.memberListView removeItemsAtIndexes:rowsToRemove inParent:nil withAnimation:NSTableViewAnimationEffectNone];
}

- (void)updateAllMembersOnTableView
{
	_cancelOnNotSelectedChannel;

	[self.memberListView reloadAllDrawings];
}

- (void)updateMemberOnTableView:(IRCUser *)user
{
	_cancelOnNotSelectedChannel;

	[self.memberListView updateDrawingForMember:user];
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return [self.memberList count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.memberList[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(IRCUser *)item
{
	return [item nickname];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return _treeUserlistHeight;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(IRCUser *)item
{
	NSView *newView = [outlineView makeViewWithIdentifier:@"GroupView" owner:self];

	if ([newView isKindOfClass:[TVCMemberListCell class]]) {
		TVCMemberListCell *groupItem = (TVCMemberListCell *)newView;

		[groupItem setMemberPointer:item];
	}

	return newView;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	TVCMemberListRowCell *rowView = [[TVCMemberListRowCell alloc] initWithFrame:NSZeroRect];

	return rowView;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	[self.memberListView reloadSelectionDrawingForRow:row];
}

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	/* I could make that method name longer if you would like? */
	[self.memberListView reloadSelectionDrawingBySelectingItemsInIndexSet:proposedSelectionIndexes];

	return proposedSelectionIndexes;
}

#pragma mark -
#pragma mark IRCTreeItem Properties

- (BOOL)isSelectedChannel
{
	return [self isEqual:self.worldController.selectedChannel];
}

- (BOOL)isActive
{
	return (self.status == IRCChannelJoined);
}

- (BOOL)isClient
{
	return NO;
}

- (NSInteger)numberOfChildren
{
	return 0;
}

- (id)childAtIndex:(NSInteger)index
{
	return nil;
}

- (NSString *)label
{
	return self.config.channelName;
}

- (IRCClient *)client
{
	return _client;
}

- (TVCLogControllerOperationQueue *)printingQueue
{
    return [_client printingQueue];
}

- (TVCMemberList *)memberListView
{
	return self.masterController.memberList;
}

@end
