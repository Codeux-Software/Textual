/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#define _treeUserlistHeight					18.0

#define _cancelOnNotSelectedChannel			NSAssertReturn(self.isSelectedChannel && self.isChannel);

@interface IRCChannel ()
@property (nonatomic, strong) NSMutableDictionary *memberList; // Unsorted dictionary of all users.
@property (nonatomic, strong) NSMutableArray *memberListNormalSorted; // Sorted by IRCuser compare: — excludes ignores.
@property (nonatomic, strong) NSMutableArray *memberListLengthSorted; // Sorted by nickname length. — includes ignores.
@end

@implementation IRCChannel

@synthesize client = _client;
@synthesize printingQueue = _printingQueue;

- (id)init
{
	if ((self = [super init])) {
		self.modeInfo = [IRCChannelMode new];
		
		self.memberList = [NSMutableDictionary new];

		self.memberListNormalSorted = [NSMutableArray new];
		self.memberListLengthSorted = [NSMutableArray new];
	}
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCChannel [%@]: %@>", [_client altNetworkName], [self name]];
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
	
	/* We do not want to bother on equality. */
	if ([self.config isEqualToChannelConfiguration:seed]) {
		return;
	}
	
	/* Is the current key equal to the temporary store. */
	NSString *temporaryKey = [seed temporaryEncryptionKey];
	
	BOOL encryptionChanged = (temporaryKey && NSObjectsAreEqual(temporaryKey, self.config.encryptionKey) == NO);

	/* Update the actual local config. */
	self.config = [seed mutableCopy];
	
	/* Save any temporary changes to disk. */
	[self.config writeKeychainItemsToDisk];
	
	/* Inform view of changes. */
	if (encryptionChanged) {
		[self.viewController channelLevelEncryptionChanged];
	}
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self.config dictionaryValue];
}

#pragma mark -
#pragma mark Property Getter

- (NSString *)name
{
	return [self.config channelName];
}

- (NSString *)secretKey
{
	return [self.config secretKey];
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

- (void)setEncryptionKey:(NSString *)encryptionKey
{
	/* This is a helper method so that Textual's view controller can
	 be made aware of encryption changes. This method should be called.
	 Do not call setEncryptionKey: direction on self.config or that
	 will only be written to the temporary store. */
	
	NSString *oldKey = [self.config encryptionKey];
	
	if (NSObjectsAreEqual(oldKey, encryptionKey) == NO) {
		[self.config setEncryptionKey:encryptionKey];
		[self.config writeEncryptionKeyKeychainItemToDisk];
		
		[self.viewController channelLevelEncryptionChanged];
	}
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
	[self resetStatus:IRCChannelJoined];
  
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelJoined" forChannel:self];
    }

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
	[self resetStatus:IRCChannelParted];
  
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelParted" forChannel:self];
		
		[self.viewController setTopic:nil];
    }

	self.channelJoinTime = -1;
}

- (void)prepareForPermanentDestruction
{
	[self resetStatus:IRCChannelTerminated];
	
	[self closeLogFile];
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)prepareForApplicationTermination
{
	[self resetStatus:IRCChannelTerminated];
	
	[self closeLogFile];

	[self.viewController prepareForApplicationTermination];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logTranscript]) {
		PointerIsEmptyAssert(self.logFile);

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
	[self.memberList setObject:item forKey:[item lowercaseNickname]];
	
	/* Conversation tracking scans based on nickname length. */
	[self.memberListLengthSorted insertSortedObject:item usingComparator:[IRCUser nicknameLengthComparator]];

	/* Member list without ignores used by view. */
	IRCAddressBook *ignoreChecks = [self.client checkIgnoreAgainstHostmask:[item hostmask] withMatches:@[@"hideInMemberList"]];
	
	if (PointerIsEmpty(ignoreChecks) || (ignoreChecks && [ignoreChecks hideInMemberList] == NO)) {
		[self.memberListNormalSorted insertSortedObject:item usingComparator:NSDefaultComparator];
	}
}

- (void)addMember:(IRCUser *)user
{
	PointerIsEmptyAssert(user);

	/* Do sorted insert. */
	[self sortedInsert:user];

	/* Post event to the style. */
	if (self.isChannel) {
		[self.client postEventToViewController:@"channelMemberAdded" forChannel:self];
	}

	/* Update the actual member list view. */
	[self informMemberListViewOfAdditionalUser:user];
}

- (void)removeMember:(NSString *)nickname
{
	NSObjectIsEmptyAssert(nickname);
	
	/* Table view list. */
	IRCUser *user = [self memberWithNickname:nickname];
	
	PointerIsEmptyAssert(user); // What are we removing?
	
	if (self.isChannel && self.isSelectedChannel) {
		NSInteger idx = [self.memberListView rowForItem:user];
		
		if (idx >= 0) {
			[self.memberListView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:idx]
											 inParent:nil
										withAnimation:NSTableViewAnimationEffectNone]; // Do the actual removal.
		}
	}
	
	/* Internal list. */
	[self.memberList removeObjectForKey:[user lowercaseNickname]];
	
	[self.memberListNormalSorted removeObject:user];
	[self.memberListLengthSorted removeObject:user];
		 
	 /* Post event to the style. */
	 if (self.isChannel) {
		 [self.client postEventToViewController:@"channelMemberRemoved" forChannel:self];
	 }
}

- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname
{
	NSObjectIsEmptyAssert(fromNickname);
	NSObjectIsEmptyAssert(toNickname);

	/* Find user. */
	IRCUser *user = [self memberWithNickname:fromNickname];
	
	PointerIsEmptyAssert(user); // What are we removing?
	
	/* Remove existing user from user list. */
	[self removeMember:[user nickname]];
	
	/* Update nickname. */
	[user setNickname:toNickname];
	
	/* Insert new copy of user. */
	[self sortedInsert:user];

	/* Update the actual member list view. */
	[self informMemberListViewOfAdditionalUser:user];
}

#pragma mark -

- (BOOL)memberRequiresRedraw:(IRCUser *)user1 comparedTo:(IRCUser *)user2
{
	PointerIsEmptyAssertReturn(user1, NO);
	PointerIsEmptyAssertReturn(user2, NO);

	if (NSDissimilarObjects(user1.binircd_O, user2.binircd_O)						|| // <-----------/
		NSDissimilarObjects(user1.InspIRCd_y_upper, user2.InspIRCd_y_upper)			|| // <----------/
		NSDissimilarObjects(user1.InspIRCd_y_lower, user2.InspIRCd_y_lower)			|| // <---------/
		NSDissimilarObjects(user1.isCop, user2.isCop)								|| // <--------/
		NSDissimilarObjects(user1.q, user2.q)										|| // <-------/ Different mode information.
		NSDissimilarObjects(user1.a, user2.a)										|| // <------/
		NSDissimilarObjects(user1.o, user2.o)										|| // <-----/
		NSDissimilarObjects(user1.h, user2.h)										|| // <----/
		NSDissimilarObjects(user1.v, user2.v)										|| // <---/
		NSDissimilarObjects(user1.isAway, user2.isAway))							   // <--/ Away state.
	{
		return YES;
	}

	return NO;
}

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value
{
	NSObjectIsEmptyAssert(nickname);
	NSObjectIsEmptyAssert(mode);
	
	/* Find user. */
	IRCUser *user = [self memberWithNickname:nickname];
	
	PointerIsEmptyAssert(user); // What are we removing?

	/* We create new copy of this user in order to compare them and deterine
	 if there are changes when we are done. */
	IRCUser *newUser = [user copy];

	switch ([mode characterAtIndex:0]) {
		case 'O': { newUser.q = value; newUser.binircd_O = value; break; } // binircd-1.0.0
		case 'q': { newUser.q = value; break; }
		case 'a': { newUser.a = value; break; }
		case 'o': { newUser.o = value; break; }
		case 'h': { newUser.h = value; break; }
		case 'v': { newUser.v = value; break; }
		case 'Y': { newUser.InspIRCd_y_upper = value; break; } // Lower cannot change…
	}

	IRCISupportInfo *isupport = self.client.isupport;

	newUser.q = (newUser.q && ([isupport modeIsSupportedUserPrefix:@"q"] || [isupport modeIsSupportedUserPrefix:@"O"] /* binircd-1.0.0 */));
	newUser.a = (newUser.a &&  [isupport modeIsSupportedUserPrefix:@"a"]);
	newUser.o = (newUser.o &&  [isupport modeIsSupportedUserPrefix:@"o"]);
	newUser.h = (newUser.h &&  [isupport modeIsSupportedUserPrefix:@"h"]);
	newUser.v = (newUser.v &&  [isupport modeIsSupportedUserPrefix:@"v"]);

	/* Handle custom modes. */
	newUser.binircd_O = (newUser.q && [isupport modeIsSupportedUserPrefix:@"O"]); /* binircd-1.0.0 */

	newUser.InspIRCd_y_upper = (newUser.InspIRCd_y_upper && [isupport modeIsSupportedUserPrefix:@"Y"]);

	if (newUser.InspIRCd_y_upper && newUser.isCop == NO) {
		newUser.isCop = YES; // +Y marks a user as an IRCop in the channel.
	}

	/* Did something change. */
	if ([self memberRequiresRedraw:user comparedTo:newUser]) {
		/* Merge the settings of the new user with those of the old. */
		[user migrate:newUser];

		/* Remove existing user from user list. */
		[self removeMember:[user nickname]];
		
		/* Insert new copy of user. */
		[self sortedInsert:user];
		
		/* Update the actual member list view. */
		[self informMemberListViewOfAdditionalUser:user];
	}
}

#pragma mark -

- (void)clearMembers
{
	[self.memberList removeAllObjects];
	
	[self.memberListLengthSorted removeAllObjects];
	[self.memberListNormalSorted removeAllObjects];
}

- (NSInteger)numberOfMembers
{
	return [self.memberList count];
}

- (NSArray *)sortedByNicknameLengthMemberList
{
	return [self.memberListLengthSorted copy];
}

- (NSArray *)unsortedMemberList
{
	return [self.memberList allValues];
}

#pragma mark -
#pragma mark User Search

- (IRCUser *)memberAtIndex:(NSInteger)idx
{
	return self.memberListNormalSorted[idx];
}

- (IRCUser *)memberWithNickname:(NSString *)nickname
{
	return [self.memberList objectForKey:[nickname lowercaseString]];
}

- (IRCUser *)findMember:(NSString *)nickname
{
	return [self memberWithNickname:nickname];
}

- (IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)mask;
{
	return [self memberWithNickname:nickname];
}

#pragma mark -
#pragma mark Table View Internal Management

- (void)informMemberListViewOfAdditionalUser:(IRCUser *)user
{
	_cancelOnNotSelectedChannel;

	/* Do not ask me how this fucking works … I don't even know. */
	NSInteger mlindx = [self.memberListNormalSorted indexOfObject:user];

	if (mlindx == NSNotFound) {
		return; // What are we informing on?
	}

	if (mlindx > 0) {
		IRCUser *prevItem = self.memberListNormalSorted[(mlindx - 1)];

		NSInteger prevIndex = [self.memberListView rowForItem:prevItem];

		if (prevIndex == NSNotFound) {
			[self.memberListView addItemToList:([self.memberListView numberOfRows] - 1)];
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

	[self.memberListNormalSorted sortUsingComparator:NSDefaultComparator];

	[self reloadDataForTableView];
}

- (void)reloadDataForTableView
{
	_cancelOnNotSelectedChannel;

	[self.memberListView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
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

- (void)updateTableViewByRemovingIgnoredUsers
{
	NSMutableArray *newlist = [NSMutableArray new];
	
	for (NSString *nickname in self.memberList) {
		IRCUser *u = self.memberList[nickname];

		IRCAddressBook *ignoreChecks = [self.client checkIgnoreAgainstHostmask:[u hostmask] withMatches:@[@"hideInMemberList"]];
		
		if (ignoreChecks == nil || (ignoreChecks && [ignoreChecks hideInMemberList] == NO)) {
			[newlist addObject:u];
		}
	}
	
	[newlist sortUsingComparator:NSDefaultComparator];
	
	if (NSDissimilarObjects([self.memberListNormalSorted count], [newlist count])) {
		self.memberListNormalSorted = [newlist mutableCopy];

		[self reloadDataForTableView];
	}
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return [self.memberListNormalSorted count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.memberListNormalSorted[index];
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
	return [self.config channelName];
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
	return [self.masterController memberList];
}

@end
