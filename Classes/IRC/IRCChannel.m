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

#include <objc/message.h>

NSString * const IRCChannelConfigurationWasUpdatedNotification = @"IRCChannelConfigurationWasUpdatedNotification";

#define _cancelOnNotSelectedChannel			if (self.isChannel == NO || self.isSelectedChannel == NO) {			\
												return;															\
											}

@interface IRCChannel ()
/* memberListStandardSortedContainer is a copy of the member list sorted by the channel
 rank of each member. As it is a mutable array, it is not thread safe. It is not recommended 
 to access this property directly. Use the APIs defined in IRCChannel.h as they have been
 designed to synchronize changes on a proper queue. */
@property (nonatomic, strong) NSMutableArray *memberListStandardSortedContainer;

/* memberListLengthSortedContainer is a copy of the member list sorted by the length of
 nicknames. TVCLogRenderer is requires the member list to be in a specific order each time
 it renders a message and it is too costly to sort our container thousands of times 
 every minute. That is why we maintain a local cache. Again, do not access directly as
 NSMutableArray by itself is not thread safe. */
@property (nonatomic, strong) NSMutableArray *memberListLengthSortedContainer;

/* Misc. private properties. */
@property (nonatomic, strong) TLOFileLogger *logFile;
@end

@implementation IRCChannel

@synthesize associatedClient = _associatedClient;
@synthesize printingQueue = _printingQueue;

- (instancetype)init
{
	if ((self = [super init])) {
		self.memberListStandardSortedContainer = [NSMutableArray array];
		self.memberListLengthSortedContainer = [NSMutableArray array];
	}
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCChannel [%@]: %@>", self.associatedClient, self.name];
}

#pragma mark -
#pragma mark Configuration

- (void)setup:(IRCChannelConfig *)seed
{
	if (seed) {
		if (self.config == nil) {
			self.config = seed;
		}
	}
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	[self updateConfig:seed fireChangedNotification:YES updateStoredChannelList:YES];
}

- (void)updateConfig:(IRCChannelConfig *)seed fireChangedNotification:(BOOL)fireChangedNotification
{
	[self updateConfig:seed fireChangedNotification:fireChangedNotification updateStoredChannelList:YES];
}

- (void)updateConfig:(IRCChannelConfig *)seed fireChangedNotification:(BOOL)fireChangedNotification updateStoredChannelList:(BOOL)updateStoredChannelList
{
	if (seed) {
		NSAssertReturn([seed isEqualToChannelConfiguration:self.config] == NO);

		[self setConfig:seed]; // Value is copied on assign.

		[self.config writeKeychainItemsToDisk];

		if (updateStoredChannelList) {
			[self.associatedClient updateStoredChannelList];
		}

		if (fireChangedNotification) {
			[RZNotificationCenter() postNotificationName:IRCChannelConfigurationWasUpdatedNotification object:self];
		}
	}
}

- (NSDictionary *)dictionaryValue
{
	return [self.config dictionaryValue];
}

#pragma mark -
#pragma mark Property Getter

- (NSString *)uniqueIdentifier
{
	return [self.config itemUUID];
}

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
	return ([self.config type] == IRCChannelChannelType);
}

- (BOOL)isPrivateMessage
{
	return ([self.config type] == IRCChannelPrivateMessageType);
}

- (BOOL)isPrivateMessageOwnedByZNC
{
	if ([self isPrivateMessage]) {
		IRCClient *u = [self associatedClient];

		return [u nicknameIsPrivateZNCUser:[self name]];
	}
	
	return NO;
}

- (NSString *)channelTypeString
{
	if ([self.config type] == IRCChannelPrivateMessageType) {
		return @"query";
	} else {
		return @"channel";
	}
}

- (NSURL *)logFilePath
{
	if (self.logFile) {
		return [self.logFile buildPath];
	} else {
		return nil;
	}
}

#pragma mark -
#pragma mark Property Setter

- (void)setName:(NSString *)value
{
	[self.config setChannelName:value];
}

- (void)setTopic:(NSString *)topic
{
	if ([_topic isEqualToString:topic] == NO) {
		_topic = [topic copy];

		[[self viewController] setTopic:_topic]; // Set even for queries incase a style wants to use it...
	}
}

#pragma mark -
#pragma mark Utilities

- (void)preferencesChanged
{
	[[self viewController] preferencesChanged];

	if ([TPCPreferences displayPublicMessageCountOnDockBadge] == NO) {
		if ([self isPrivateMessage] == NO) {
			[self setDockUnreadCount:0]; // Reset counter on changes.
		}
	}

	[self reopenLogFileIfNeeded];
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (OTRKitMessageState)encryptionState
{
	if ([TPCPreferences textEncryptionIsEnabled]) {
		IRCClient *u = [self associatedClient];

		return [sharedEncryptionManager() messageStateFor:[u encryptionAccountNameForUser:[self name]]
													 from:[u encryptionAccountNameForLocalUser]];
	} else {
		return OTRKitMessageStatePlaintext;
	}
}

- (BOOL)encryptionStateIsEncrypted
{
	if ([TPCPreferences textEncryptionIsEnabled]) {
		if ([self isPrivateMessage]) {
			return ([self encryptionState] == OTRKitMessageStateEncrypted);
		} else {
			return NO;
		}
	} else {
		return NO;
	}
}

- (void)noteEncryptionStateDidChange
{
	[[self viewController] setViewIsEncrypted:[self encryptionStateIsEncrypted]];

	[mainWindow() updateTitleFor:self];
}

- (void)closeOpenEncryptionSessions
{
	if ([TPCPreferences textEncryptionIsEnabled]) {
		if ([self encryptionStateIsEncrypted]) {
			IRCClient *u = [self associatedClient];

			[sharedEncryptionManager() endConversationWith:[u encryptionAccountNameForUser:[self name]]
													  from:[u encryptionAccountNameForLocalUser]];
		}
	}
}
#endif

#pragma mark -
#pragma mark Channel Status

- (void)resetStatus:(IRCChannelStatus)newStatus
{
	self.errorOnLastJoinAttempt = NO;
	self.inUserInvokedModeRequest = NO;
	self.sentInitialWhoRequest = NO;

	self.channelJoinTime = -1;
	
	self.status = newStatus;

    self.topic = nil;

	self.modeInfo = nil;

	[self clearMembers];

	[self reloadDataForTableView];
}

- (void)activate
{
	[self resetStatus:IRCChannelStatusJoined];

	if ([self isChannel]) {
		[self.associatedClient postEventToViewController:@"channelJoined" forChannel:self];

	     self.modeInfo = [IRCChannelMode new];
		[self.modeInfo setSupportInfo:[self.associatedClient supportInfo]];
    }

	if ([self isPrivateMessage]) {
		IRCUser *m1 = [IRCUser newUserOnClient:self.associatedClient withNickname:[self.associatedClient localNickname]];
		IRCUser *m2 = [IRCUser newUserOnClient:self.associatedClient withNickname:[self name]];

		[self addMember:m1];
		[self addMember:m2];
	}

	self.channelJoinTime = [NSDate unixTime];
}

- (void)deactivate
{
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if ([self isPrivateMessage]) {
		[self closeOpenEncryptionSessions];
	}
#endif

	[self resetStatus:IRCChannelStatusParted];
  
	if ([self isChannel]) {
		[self.associatedClient postEventToViewController:@"channelParted" forChannel:self];
    }
}

- (void)prepareForPermanentDestruction
{
	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];
	
	[self.config destroyKeychains];

	NSArray *openWindows = [windowController() windowsFromWindowList:@[@"TDChannelPropertiesSheet",
																	   @"TDChannelModifyTopicSheet",
																	   @"TDChannelModifyModesSheet",
																	   @"TDChannelBanListSheet"]];
	
	for (id windowObject in openWindows) {
		if (NSObjectsAreEqual([windowObject channelID], [self uniqueIdentifier])) {
			[windowObject cancel:nil];
		}
	}

	[[TXSharedApplication sharedInputHistoryManager] destroy:self];
	
	[[self viewController] prepareForPermanentDestruction];
}

- (void)prepareForApplicationTermination
{
	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];
	
	if ([self isPrivateMessage]) {
		[self.config destroyKeychains];
	}

	[[self viewController] prepareForApplicationTermination];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logToDiskIsEnabled]) {
		if ( self.logFile) {
			[self.logFile reopenIfNeeded];
		}
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	if ( self.logFile) {
		[self.logFile close];
	}
}

#pragma mark -
#pragma mark Printing

- (void)writeToLogFile:(TVCLogLine *)line
{
	if ([TPCPreferences logToDiskIsEnabled]) {
		if (self.logFile == nil) {
			self.logFile = [TLOFileLogger new];

			[self.logFile setClient:self.associatedClient];
			[self.logFile setChannel:self];
		}

		[self.logFile writeLine:line];
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

- (NSInteger)_sortedInsert:(IRCUser *)item
{
	NSInteger insertedIndex = 0;
	
	/* Insert into normal list and maybe tree view. */
	@synchronized(self.memberListStandardSortedContainer) {
		insertedIndex = [self.memberListStandardSortedContainer insertSortedObject:item usingComparator:NSDefaultComparator];
	}
	
	/* Conversation tracking scans based on nickname length. */
	@synchronized(self.memberListLengthSortedContainer) {
		(void)[self.memberListLengthSortedContainer insertSortedObject:item usingComparator:[IRCUser nicknameLengthComparator]];
	}
	
	return insertedIndex;
}

- (void)_removeMemberFromTreeView:(IRCUser *)user
{
	/* It is possible for a member to exist in our local cache and but 
	 not exist in the actual tree view. This tries its best to catch 
	 all cases where it exists in member list. */
	_cancelOnNotSelectedChannel
	
	NSInteger idx = [mainWindowMemberList() rowForItem:user];
	
	if (idx > -1) {
		[mainWindowMemberList() removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:idx]
											inParent:nil
									   withAnimation:NSTableViewAnimationEffectNone]; // Do the actual removal.
	}
}

- (BOOL)_removeMemberWithNickname:(NSString *)nickname
{
	/* Find in normal member list. */
	/* This also removes matched user from tree view. */
	BOOL removedUser = NO;

	@synchronized(self.memberListStandardSortedContainer) {
		/* Remove from internal list. */
		NSInteger crmi = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListStandardSortedContainer];
		
		if (NSDissimilarObjects(crmi, NSNotFound)) {
			/* Get matched user. */
			IRCUser *userToRemove = self.memberListStandardSortedContainer[crmi];

			/* Maybe remove from tree view. */
			XRPerformBlockSynchronouslyOnMainQueue(^{
				[self _removeMemberFromTreeView:userToRemove];
			});
			
			/* Remove from array archive. */
			[self.memberListStandardSortedContainer removeObjectAtIndex:crmi];

			/* Remove from alternate arrays */
			@synchronized(self.memberListLengthSortedContainer) {
				[self.memberListLengthSortedContainer removeObject:userToRemove];
			}

			/* Update state information */
			removedUser = YES;
		}
	}

	return removedUser;
}

- (void)_removeMember:(IRCUser *)user
{
	[self _removeMemberWithNickname:[user nickname]];
}

- (void)addMember:(IRCUser *)user
{
	PointerIsEmptyAssert(user);
	
	__block NSInteger insertedIndex = -1;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		insertedIndex = [self _sortedInsert:user];
	});

	XRPerformBlockSynchronouslyOnMainQueue(^{
		/* Update the actual member list view. */
		[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
		
		/* Post event to the style. */
		if ([self isChannel]) {
			[self.associatedClient postEventToViewController:@"channelMemberAdded" forChannel:self];
		}
	});
}

- (void)removeMember:(NSString *)nickname
{
	NSObjectIsEmptyAssert(nickname);

	__block BOOL userRemoved = NO;

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		userRemoved = [self _removeMemberWithNickname:nickname];
	});

	if (userRemoved) {
		XRPerformBlockSynchronouslyOnMainQueue(^{
			if ([self isChannel]) {
				[self.associatedClient postEventToViewController:@"channelMemberRemoved" forChannel:self];
			}
		});
	}
}

- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname
{
	NSObjectIsEmptyAssert(fromNickname);
	NSObjectIsEmptyAssert(toNickname);

	/* Find user. */
	__block NSInteger insertedIndex = -1;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		IRCUser *user = [self findMember:fromNickname options:NSCaseInsensitiveSearch];
	
		if (user) {
			/* Remove existing user from user list. */
			[self _removeMember:user];
			
			/* Update nickname. */
			[user setNickname:toNickname];
			
			/* Insert new copy of user. */
			insertedIndex = [self _sortedInsert:user];
		}
	});
	
	/* Update the actual member list view. */
	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
	});
}

#pragma mark -

- (BOOL)memberRequiresRedraw:(IRCUser *)user1 comparedTo:(IRCUser *)user2
{
	PointerIsEmptyAssertReturn(user1, NO);
	PointerIsEmptyAssertReturn(user2, NO);

	/* When changing certain conditions of a user in the visible member list tree, we create
	 a copy of the user, change what we want changed, then compare the copy with original. If
	 any of these conditions fault, then that means the appearnce of the user in member list 
	 tree will need to be updated. */
	BOOL hasEqualStatus = (NSObjectsAreEqual([user1 modes], [user2 modes])				&&
							                 [user1 isCop]		== [user2 isCop]		&&
						                     [user1 isAway]		== [user2 isAway]);
	
	return (hasEqualStatus == NO);
}

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value
{
	NSObjectIsEmptyAssert(nickname);
	NSObjectIsEmptyAssert(mode);

	NSParameterAssert(([mode length] == 1));
	
	/* Find user. */
	IRCUser *user = [self findMember:nickname options:NSCaseInsensitiveSearch];
	
	PointerIsEmptyAssert(user); // What are we removing?

	/* We create new copy of this user in order to compare them and deterine if there 
	 are changes when we are done. Modifying /user/ directly would change all instances 
	 inside our member lists and we don't want to do  that right away. */
	IRCUser *newUser = [user copy];

	NSString *existingModeValues = [newUser modes];

	if (existingModeValues == nil || [existingModeValues length] == 0) {
		if (value) {
			[newUser setModes:mode];
		}
	} else {
		if ([existingModeValues contains:mode]) {
			if (value) {
				return; // Why add what already exists...
			}
		}

		IRCISupportInfo *supportInfo = [[self associatedClient] supportInfo];

		NSInteger rankOfNewMode = [supportInfo rankForUserPrefixWithMode:mode];

		NSMutableString *newModeValues = [NSMutableString string];

		for (NSInteger i = 0; i < [existingModeValues length]; i++) {
			NSString *cc = [existingModeValues stringCharacterAtIndex:i];

			if (value == NO) {
				/* If we are unsetting a mode value, then all we have to 
				 do is skip over the existing mode, if it exists at all. */

				if (NSObjectsAreEqual(cc, mode)) {
					continue;
				} else {
					[newModeValues appendString:cc];
				}
			} else {
				/* When setting a mode, we have to insert it into our
				 string into its correct rank. */
				NSInteger rankOfCurrentMode = [supportInfo rankForUserPrefixWithMode:cc];

				if (rankOfNewMode > rankOfCurrentMode) {
					[newModeValues appendString:mode];
				}

				[newModeValues appendString:cc];
			}
		}

		if ([newModeValues length] == 0) {
			[newUser setModes:nil]; // Do not set a string of zero length
		} else {
			[newUser setModes:newModeValues];
		}
	}

	/* Make special exceptions. */
	if (value) {
		/* InspIRCd treats +Y as an IRCop. */

		if (NSObjectsAreEqual(mode, @"Y")) {
			/* If the user wasn't already marked as an IRCop, then we
			 mark them at this point. However, if they were already
			 marked and it was -Y, then we do not remove it. We still
			 want to know they are an IRCop even if mode isn't set in
			 this particular channel. */

			if ([newUser isCop] == NO) {
				[newUser setIsCop:YES];
			}
		}
	}

	/* Did something change. */
	__block NSInteger insertedIndex = -1;

	if ([self memberRequiresRedraw:user comparedTo:newUser]) {
		XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
			/* Remove existing user from user list. */
			[self _removeMember:user];
			
			/* Merge the settings of the new user with those of the old. */
			[user migrate:newUser];
			
			/* Insert new copy of user. */
			insertedIndex = [self _sortedInsert:user];
		});
		
		/* Update the actual member list view. */
		XRPerformBlockSynchronouslyOnMainQueue(^{
			[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
		});
	}
}

#pragma mark -

- (void)clearMembers
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			[self.memberListStandardSortedContainer removeAllObjects];
		}
		
		@synchronized(self.memberListLengthSortedContainer) {
			[self.memberListLengthSortedContainer removeAllObjects];
		}
	});
}

- (NSInteger)numberOfMembers
{
	__block NSUInteger memberCount = 0;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			memberCount = [self.memberListStandardSortedContainer count];
		}
	});
	
	return memberCount;
}

- (NSArray *)memberList
{
	__block NSMutableArray *mutlist = [NSMutableArray array];
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			for (IRCUser *user in self.memberListStandardSortedContainer) {
				[mutlist addObject:user];
			}
		}
	});
	
	return mutlist;
}

- (NSArray *)memberListSortedByNicknameLength
{
	__block NSMutableArray *mutlist = [NSMutableArray array];
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListLengthSortedContainer) {
			for (IRCUser *user in self.memberListLengthSortedContainer) {
				[mutlist addObject:user];
			}
		}
	});
	
	return mutlist;
}

- (NSArray *)sortedByNicknameLengthMemberList
{
	return [self memberListSortedByNicknameLength];
}

- (NSArray *)sortedByChannelRankMemberList
{
	return [self memberList];
}

#pragma mark -
#pragma mark User Search

- (BOOL)memberExists:(NSString *)nickname
{
	__block BOOL foundUser;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			NSInteger somi = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListStandardSortedContainer];
			
			if (somi == NSNotFound) {
				foundUser = NO;
			} else {
				foundUser = YES;
			}
		}
	});
	
	return foundUser;
}

- (IRCUser *)findMember:(NSString *)nickname
{
	return [self findMember:nickname options:0];
}

- (IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)mask
{
	__block IRCUser *foundUser;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			NSInteger somi = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListStandardSortedContainer];
			
			if (somi == NSNotFound) {
				foundUser = nil;
			} else {
				foundUser = self.memberListStandardSortedContainer[somi];
			}
		}
	});
	
	return foundUser;
}

- (IRCUser *)memberAtIndex:(NSInteger)index
{
	__block IRCUser *foundUser;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			foundUser = (self.memberListStandardSortedContainer)[index];
		}
	});
	
	return foundUser;
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask inList:(NSArray *)memberList
{
	NSObjectIsEmptyAssertReturn(nick, NSNotFound);

	NSInteger memberIndex =
	[memberList indexOfObjectWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		NSString *nick2 = [(IRCUser *)obj nickname];

		if (mask & NSCaseInsensitiveSearch) {
			return [nick isEqualToString:nick2];
		} else {
			return [nick isEqualIgnoringCase:nick2];
		}
	}];

	return memberIndex;
}

#pragma mark -
#pragma mark Table View Internal Management

- (void)informMemberListViewOfAdditionalUserAtIndex:(NSUInteger)insertedIndex
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() addItemToList:insertedIndex];
}

- (void)reloadDataForTableViewBySortingMembers
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.memberListStandardSortedContainer) {
			[self.memberListStandardSortedContainer sortUsingComparator:NSDefaultComparator];
			
			[self reloadDataForTableView];
		}
	});
}

- (void)reloadDataForTableView
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)updateAllMembersOnTableView
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() reloadAllDrawings];
}

- (void)updateMemberOnTableView:(IRCUser *)user
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() updateDrawingForMember:user];
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return [self numberOfMembers];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	return [userInterfaceObjects cellRowHeight];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return [self memberAtIndex:index];
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
	[mainWindowMemberList() updateDrawingForRow:row];
}

#pragma mark -
#pragma mark IRCTreeItem Properties

- (BOOL)isSelectedChannel
{
	return [self isEqual:[mainWindow() selectedChannel]];
}

- (BOOL)isActive
{
	return (self.status == IRCChannelStatusJoined);
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
	return [self name];
}

- (IRCClient *)associatedClient
{
	return _associatedClient;
}

- (IRCChannel *)associatedChannel
{
	return self;
}

- (TVCLogControllerOperationQueue *)printingQueue
{
    return [self.associatedClient printingQueue];
}

@end
