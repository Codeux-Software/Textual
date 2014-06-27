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

#include <objc/message.h>

#define _treeUserlistHeight					18.0

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

- (id)init
{
	if ((self = [super init])) {
		/* Channel mode info. */
		self.modeInfo = [IRCChannelMode new];
		
		/* Channel ranked member list used internally. */
		self.memberListStandardSortedContainer = [NSMutableArray array];
		
		/* Length sorted member list used by renderer. */
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
	TXLockMethodForOneTimeFire();
	
	if (seed) {
		if (self.config == nil) {
			self.config = seed; // Value is copied on assign.
		}
	}
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	if (seed) {
		/* We do not want to bother on equality. */
		NSAssertReturn([seed isEqualToChannelConfiguration:_config] == NO);
		
		/* Is the current key equal to the temporary store. */
		NSString *temporaryKey = [seed temporaryEncryptionKey];
		
		/* Both values are either going to be nil or one will be different than the other. */
		BOOL encryptionUnchanged = NSObjectsAreEqual(temporaryKey, self.config.encryptionKey);

		/* Update the actual local config. */
		self.config = seed; // Value is copied on assign.
		
		/* Save any temporary changes to disk. */
		[self.config writeKeychainItemsToDisk];
		
		/* Inform view of changes. */
		if (encryptionUnchanged == NO) {
			[self.viewController channelLevelEncryptionChanged];
		}
	}
}

- (NSMutableDictionary *)dictionaryValue
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
	/* The channelName property which is automatically created 
	 will handle isEqual comparison for the new value. */
	
	self.config.channelName = value;
}

- (void)setTopic:(NSString *)topic
{
	if ([_topic isEqualToString:topic] == NO) {
		 _topic = [topic copy];
	}

    [self.viewController setTopic:topic];
}

- (void)setEncryptionKey:(NSString *)encryptionKey
{
	/* This is a helper method so that Textual's view controller can
	 be made aware of encryption changes. This method should be called.
	 Do not call setEncryptionKey: direction on self.config or that
	 will only be written to the temporary store. */
	
	BOOL encryptionUnchanged = NSObjectsAreEqual(encryptionKey, self.config.encryptionKey);
	
	if (encryptionUnchanged == NO) {
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

    self.topic = nil;
	
	[self.modeInfo clear];

	[self clearMembers];
	[self reloadDataForTableView];
}

- (void)activate
{
	[self resetStatus:IRCChannelStatusJoined];
  
	if (self.isChannel) {
		/* Fireoff join event. */
		[self.associatedClient postEventToViewController:@"channelJoined" forChannel:self];
    }

	if (self.isPrivateMessage) {
		/* Populate private message users. */
		IRCUser *m1 = [IRCUser newUserOnClient:self.associatedClient withNickname:self.associatedClient.localNickname];
		IRCUser *m2 = [IRCUser newUserOnClient:self.associatedClient withNickname:self.name];

		[self addMember:m1];
		[self addMember:m2];
	}

	self.channelJoinTime = [NSDate epochTime];
}

- (void)deactivate
{
	[self resetStatus:IRCChannelStatusParted];
  
	if (self.isChannel) {
		[self.associatedClient postEventToViewController:@"channelParted" forChannel:self];
		
		[self.viewController setTopic:nil];
    }

	self.channelJoinTime = -1;
}

- (void)prepareForPermanentDestruction
{
	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)prepareForApplicationTermination
{
	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];

	[self.viewController prepareForApplicationTermination];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logToDisk]) {
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
	if ([TPCPreferences logToDisk]) {
		if (self.logFile == nil) {
			self.logFile = [TLOFileLogger new];

			self.logFile.client = self.associatedClient;
			self.logFile.channel = self;
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

- (void)_removeMemberWithNickname:(NSString *)nickname
{
	/* Find in normal member list. */
	/* This also removes matched user from tree view. */
	@synchronized(self.memberListStandardSortedContainer) {
		NSInteger crmi = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListStandardSortedContainer];
		
		if (NSDissimilarObjects(crmi, NSNotFound)) {
			/* Get matched user. */
			IRCUser *matchedUser = self.memberListStandardSortedContainer[crmi];
			
			/* Remove from array archive. */
			[self.memberListStandardSortedContainer removeObjectAtIndex:crmi];
			
			/* Maybe remove from tree view. */
			[self _removeMemberFromTreeView:matchedUser];
		}
	}
	
	/* Find in alternate list. */
	@synchronized(self.memberListLengthSortedContainer) {
		NSInteger crmi = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListLengthSortedContainer];
		
		if (NSDissimilarObjects(crmi, NSNotFound)) {
			[self.memberListLengthSortedContainer removeObjectAtIndex:crmi];
		}
	}
}

- (void)_removeMember:(IRCUser *)user
{
	[self _removeMemberWithNickname:[user nickname]];
}

- (void)addMember:(IRCUser *)user
{
	PointerIsEmptyAssert(user);
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
		/* Do sorted insert. */
		NSInteger insertedIndex = [self _sortedInsert:user];
		
		/* Post event to the style. */
		if (self.isChannel) {
			[self.associatedClient postEventToViewController:@"channelMemberAdded" forChannel:self];
		}
		
		/* Update the actual member list view. */
		[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
	});
}

- (void)removeMember:(NSString *)nickname
{
	NSObjectIsEmptyAssert(nickname);
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
		/* Internal list. */
		[self _removeMemberWithNickname:nickname];
		
		/* Post event to the style. */
		if (self.isChannel) {
			[self.associatedClient postEventToViewController:@"channelMemberRemoved" forChannel:self];
		}
	});
}

- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname
{
	NSObjectIsEmptyAssert(fromNickname);
	NSObjectIsEmptyAssert(toNickname);

	/* Find user. */
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
		IRCUser *user = [self findMember:fromNickname options:NSCaseInsensitiveSearch];
	
		if (user) {
			/* Remove existing user from user list. */
			[self _removeMember:user];
			
			/* Update nickname. */
			[user setNickname:toNickname];
			
			/* Insert new copy of user. */
			NSInteger insertedIndex = [self _sortedInsert:user];

			/* Update the actual member list view. */
			[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
		}
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
	BOOL hasEqualStatus = ([user1 binircd_O]			== [user2 binircd_O]			&&
						   [user1 InspIRCd_y_lower]		== [user1 InspIRCd_y_lower]		&&
						   [user1 InspIRCd_y_upper]		== [user2 InspIRCd_y_upper]		&&
						   [user1 isCop]				== [user2 isCop]				&&
						   [user1 isAway]				== [user2 isAway]				&&
						   [user1 q]					== [user2 q]					&&
						   [user1 a]					== [user2 a]					&&
						   [user1 o]					== [user2 o]					&&
						   [user1 h]					== [user2 h]					&&
						   [user1 v]					== [user2 v]);
	
	return (hasEqualStatus == NO);
}

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value
{
	NSObjectIsEmptyAssert(nickname);
	NSObjectIsEmptyAssert(mode);
	
	/* Find user. */
	IRCUser *user = [self findMember:nickname options:NSCaseInsensitiveSearch];
	
	PointerIsEmptyAssert(user); // What are we removing?

	/* We create new copy of this user in order to compare them and deterine
	 if there are changes when we are done. Modifying /user/ directly would
	 change all instances inside our member lists and we don't want to do 
	 that right away. */
	IRCUser *newUser = [user copy];
	
	UniChar modeChar = [mode characterAtIndex:0];
	
	switch (modeChar) {
		case 'O':
		{
			/* Why would an IRCd define a differnet mode for this? */
			newUser.binircd_O = value;
			
			/* We will still treat it as q (owner). ,,|,, */
			newUser.q = value;
			
			break;
		}
		case 'Y': // Lower Y cannot change…
		{
			/* Mode Y is treated as an IRCop. */
			newUser.InspIRCd_y_upper = value;
			
			/* If the user wasn't already marked as an IRCop, then we 
			 mark them at this point. However, if they were already 
			 marked and it was -Y, then we do not remove it. We still 
			 want to know they are an IRCop even if mode isn't set in
			 this particular channel. */
			if (newUser.isCop == NO && value) {
				newUser.isCop = YES;
			}
			
			break;
		}
		case 'q':
		case 'a':
		case 'o':
		case 'h':
		case 'v':
		{
			SEL changeSelector = NSSelectorFromString([NSString stringWithFormat:@"set%C:", modeChar]);
			
			objc_msgSend(newUser, changeSelector, value);
			
			break;
		}
	}

	/* Did something change. */
	if ([self memberRequiresRedraw:user comparedTo:newUser]) {
		TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
			/* Remove existing user from user list. */
			[self _removeMember:user];
			
			/* Merge the settings of the new user with those of the old. */
			[user migrate:newUser];
			
			/* Insert new copy of user. */
			NSInteger insertedIndex = [self _sortedInsert:user];
			
			/* Update the actual member list view. */
			[self informMemberListViewOfAdditionalUserAtIndex:insertedIndex];
		});
	}
}

#pragma mark -

- (void)clearMembers
{
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
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
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueSyncOperationType, ^{
		@synchronized(self.memberListStandardSortedContainer) {
			memberCount = [self.memberListStandardSortedContainer count];
		}
	});
	
	return memberCount;
}

- (NSArray *)sortedByNicknameLengthMemberList
{
	__block NSMutableArray *mutlist = [NSMutableArray array];
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueSyncOperationType, ^{
		@synchronized(self.memberListLengthSortedContainer) {
			for (IRCUser *user in self.memberListLengthSortedContainer) {
				[mutlist addObject:[user copy]];
			}
		}
	});
	
	return mutlist;
}

- (NSArray *)sortedByChannelRankMemberList
{
	__block NSMutableArray *mutlist = [NSMutableArray array];
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueSyncOperationType, ^{
		@synchronized(self.memberListStandardSortedContainer) {
			for (IRCUser *user in self.memberListStandardSortedContainer) {
				[mutlist addObject:[user copy]];
			}
		}
	});
	
	return mutlist;
}

- (NSArray *)unsortedMemberList
{
	return [self sortedByChannelRankMemberList];
}

#pragma mark -
#pragma mark User Search

- (IRCUser *)memberWithNickname:(NSString *)nickname
{
	return [self findMember:nickname options:0];
}

- (IRCUser *)findMember:(NSString *)nickname
{
	return [self findMember:nickname options:0];
}

- (IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)mask;
{
	__block IRCUser *foundUser;
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueSyncOperationType, ^{
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
	
	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueSyncOperationType, ^{
		@synchronized(self.memberListStandardSortedContainer) {
			foundUser = [self.memberListStandardSortedContainer objectAtIndex:index];
		}
	});
	
	return foundUser;
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask inList:(NSArray *)memberList
{
	NSObjectIsEmptyAssertReturn(nick, NSNotFound);
	
	if (mask & NSCaseInsensitiveSearch) {
		return [memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualIgnoringCase:)];
	} else {
		return [memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualToString:)];
	}
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
	_cancelOnNotSelectedChannel;

	TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueBarrierAsyncOperationType, ^{
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

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return [self memberAtIndex:index];
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
	[mainWindowMemberList() reloadSelectionDrawingForRow:row];
}

#pragma mark -
#pragma mark IRCTreeItem Properties

- (BOOL)isSelectedChannel
{
	return [self isEqual:[worldController() selectedChannel]];
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
    return [_associatedClient printingQueue];
}

@end
