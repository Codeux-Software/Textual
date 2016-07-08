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

#include <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const IRCChannelConfigurationWasUpdatedNotification = @"IRCChannelConfigurationWasUpdatedNotification";

#define _cancelOnNotSelectedChannel			if (self.isChannel == NO || self.isSelectedChannel == NO) {			\
												return;															\
											}

@interface IRCChannel ()
@property (nonatomic, assign) BOOL statusChangedByAction;
@property (nonatomic, copy, readwrite) IRCChannelConfig *config;
@property (nonatomic, assign, readwrite) NSTimeInterval channelJoinTime;
@property (nonatomic, strong, readwrite, nullable) IRCChannelMode *modeInfo;
@property (nonatomic, strong) TLOFileLogger *logFile;

/* memberListStandardSortedContainer is a copy of the member list sorted by the channel
 rank of each member.*/
@property (nonatomic, strong) NSMutableArray<IRCUser *> *memberListStandardSortedContainer;

/* memberListLengthSortedContainer is a copy of the member list sorted by the length of
 nicknames. TVCLogRenderer requires the member list to be in a specific order each time
 it renders a message and it is too costly to sort our container thousands of times 
 every minute.*/
@property (nonatomic, strong) NSMutableArray<IRCUser *> *memberListLengthSortedContainer;
@end

@implementation IRCChannel

@synthesize associatedClient = _associatedClient;
@synthesize printingQueue = _printingQueue;

ClassWithDesignatedInitializerInitMethod

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	IRCChannelConfig *config = [[IRCChannelConfig alloc] initWithDictionary:dic];

	return [self initWithConfig:config];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (instancetype)initWithConfig:(IRCChannelConfig *)config
{
	if ((self = [super init])) {
		self.config = config;

		[self.config writeItemsToKeychain];

		[self prepareInitialState];
	}
	
	return self;
}

- (void)prepareInitialState
{
	self.memberListStandardSortedContainer = [NSMutableArray array];
	self.memberListLengthSortedContainer = [NSMutableArray array];
}

- (void)updateConfig:(IRCChannelConfig *)config
{
	[self updateConfig:config fireChangedNotification:YES updateStoredChannelList:YES];
}

- (void)updateConfig:(IRCChannelConfig *)config fireChangedNotification:(BOOL)fireChangedNotification
{
	[self updateConfig:config fireChangedNotification:fireChangedNotification updateStoredChannelList:YES];
}

- (void)updateConfig:(IRCChannelConfig *)config fireChangedNotification:(BOOL)fireChangedNotification updateStoredChannelList:(BOOL)updateStoredChannelList
{
	NSParameterAssert(config != nil);

	IRCChannelConfig *currentConfig = self.config;

	if (currentConfig) {
		if ([config isEqual:currentConfig]) {
			return;
		}

		if (currentConfig.type != config.type ||
			NSObjectsAreEqual(currentConfig.channelName, config.channelName) == NO ||
			NSObjectsAreEqual(currentConfig.uniqueIdentifier, config.uniqueIdentifier) == NO)
		{
			LogToConsoleError("Tried to load configuration for incorrect channel")

			return;
		}
	}

	self.config = config;

	[self.config writeItemsToKeychain];

	if (updateStoredChannelList) {
		[self.associatedClient updateStoredChannelList];
	}

	if (fireChangedNotification) {
		[RZNotificationCenter() postNotificationName:IRCChannelConfigurationWasUpdatedNotification object:self];
	}
}

- (NSDictionary<NSString *, id> *)configurationDictionary
{
	return self.config.dictionaryValue;
}

- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud
{
	return [self.config dictionaryValue:YES];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCChannel [%@]: %@>", self.associatedClient.description, self.name];
}

#pragma mark -
#pragma mark Property Getter

- (NSString *)uniqueIdentifier
{
	return self.config.uniqueIdentifier;
}

- (NSString *)name
{
	return self.config.channelName;
}

- (nullable NSString *)secretKey
{
	return self.config.secretKey;
}

- (BOOL)autoJoin
{
	return self.config.autoJoin;
}

- (BOOL)isChannel
{
	return (self.config.type == IRCChannelChannelType);
}

- (BOOL)isPrivateMessage
{
	return (self.config.type == IRCChannelPrivateMessageType);
}

- (BOOL)isPrivateMessageForZNCUser
{
	if (self.isPrivateMessage == NO) {
		return NO;
	}

	IRCClient *client = self.associatedClient;

	return [client nicknameIsZNCUser:self.name];
}

- (NSString *)channelTypeString
{
	if (self.isPrivateMessage) {
		return @"query";
	} else {
		return @"channel";
	}
}

- (nullable NSURL *)logFilePath
{
	if (self.logFile == nil) {
		return nil;
	}

	NSString *writePath = self.logFile.writePath.stringByDeletingLastPathComponent;

	return [NSURL fileURLWithPath:writePath];
}

#pragma mark -
#pragma mark Property Setter

- (void)setAutoJoin:(BOOL)autoJoin
{
	if (self.isPrivateMessage) {
		return;
	}

	if (self.autoJoin == autoJoin) {
		return;
	}

	IRCChannelConfigMutable *mutableConfig = [self.config mutableCopy];

	mutableConfig.autoJoin = autoJoin;

	self.config = mutableConfig;
}

- (void)setName:(NSString *)name
{
	NSParameterAssert(name != nil);

	if (self.isPrivateMessage == NO) {
		return;
	}

	if ([self.name isEqualToString:name]) {
		return;
	}

	IRCChannelConfigMutable *mutableConfig = [self.config mutableCopy];

	mutableConfig.channelName = name;

	self.config = mutableConfig;
}

- (void)setTopic:(nullable NSString *)topic
{
	if (self->_topic != topic) {
		self->_topic = [topic copy];

		[self.viewController setTopic:self->_topic];
	}
}

#pragma mark -
#pragma mark Utilities

- (void)preferencesChanged
{
	[self.viewController preferencesChanged];

	if ([TPCPreferences displayPublicMessageCountOnDockBadge] == NO) {
		if (self.isChannel) {
			self.dockUnreadCount = 0;
		}
	}

	[self reopenLogFileIfNeeded];
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (OTRKitMessageState)encryptionState
{
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return OTRKitMessageStatePlaintext;
	}

	if (self.isPrivateMessage == NO) {
		return OTRKitMessageStatePlaintext;
	}

	IRCClient *client = self.associatedClient;

	return [sharedEncryptionManager() messageStateFor:[client encryptionAccountNameForUser:self.name]
												 from:[client encryptionAccountNameForLocalUser]];
}

- (BOOL)encryptionStateIsEncrypted
{
	return ([self encryptionState] == OTRKitMessageStateEncrypted);
}

- (void)noteEncryptionStateDidChange
{
	self.viewController.encrypted = self.encryptionStateIsEncrypted;

	[mainWindow() updateTitleFor:self];
}

- (void)closeOpenEncryptionSessions
{
	if (self.encryptionStateIsEncrypted == NO) {
		return;
	}

	IRCClient *client = self.associatedClient;

	[sharedEncryptionManager() endConversationWith:[client encryptionAccountNameForUser:self.name]
											  from:[client encryptionAccountNameForLocalUser]];
}
#endif

#pragma mark -
#pragma mark Channel Status

- (void)setStatus:(IRCChannelStatus)status
{
	if (self->_status != status) {
		self->_status = status;

		[self performActionOnStatusChange];
	}
}

- (void)performActionOnStatusChange
{
	if (self.statusChangedByAction) {
		self.statusChangedByAction = NO;

		return;
	}

	if (self.status == IRCChannelStatusJoined) {
		[self activate];
	} else if (self.status == IRCChannelStatusParted) {
		[self deactivate];
	}
}

- (void)resetStatus:(IRCChannelStatus)toStatus
{
	if (toStatus == IRCChannelStatusJoining) {
		return;
	}

	self.errorOnLastJoinAttempt = NO;
	self.inUserInvokedModeRequest = NO;
	self.sentInitialWhoRequest = NO;

	self.channelJoinTime = 0;

	self.modeInfo = nil;
	
	self.status = toStatus;

    self.topic = nil;

	[self clearMembers];

	[self reloadDataForTableView];
}

- (void)activate
{
	self.statusChangedByAction = YES;

	[self resetStatus:IRCChannelStatusJoined];

	IRCClient *client = self.associatedClient;

	if (self.isChannel) {
		[client postEventToViewController:@"channelJoined" forChannel:self];

		self.modeInfo = [[IRCChannelMode alloc] initWithChannel:self];
    }

	if (self.isPrivateMessage) {
		IRCUser *member1 = [[IRCUser alloc] initWithNickname:self.name onClient:client];

		[self addMember:member1];

		IRCUser *member2 = [[IRCUser alloc] initWithNickname:client.userNickname onClient:client];

		[self addMember:member2];
	}

	self.channelJoinTime = [NSDate timeIntervalSince1970];
}

- (void)deactivate
{
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if (self.isPrivateMessage) {
		[self closeOpenEncryptionSessions];
	}
#endif

	self.statusChangedByAction = YES;

	[self resetStatus:IRCChannelStatusParted];
  
	if (self.isChannel) {
		[self.associatedClient postEventToViewController:@"channelParted" forChannel:self];
    }
}

- (void)prepareForPermanentDestruction
{
	self.statusChangedByAction = YES;

	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];
	
	[self.config destroyKeychainItems];

	NSArray *openWindows = [windowController()
							windowsFromWindowList:@[@"TDCChannelPropertiesSheet",
													@"TDCChannelModifyTopicSheet",
													@"TDCChannelModifyModesSheet",
													@"TDCChannelBanListSheet"]];

	for (TDCSheetBase <TDCChannelPrototype> *windowObject in openWindows) {
		if (NSObjectsAreEqual(windowObject.channelId, self.uniqueIdentifier)) {
			[windowObject close];
		}
	}

	[[mainWindow() inputHistoryManager] destroy:self];
	
	[self.viewController prepareForPermanentDestruction];
}

- (void)prepareForApplicationTermination
{
	self.statusChangedByAction = YES;

	[self resetStatus:IRCChannelStatusTerminated];
	
	[self closeLogFile];
	
	if (self.isPrivateMessage) {
		[self.config destroyKeychainItems];
	}

	[self.viewController prepareForApplicationTermination];
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
	if (self.logFile == nil) {
		return;
	}

	[self.logFile close];
}

#pragma mark -
#pragma mark Printing

- (void)writeToLogLineToLogFile:(TVCLogLine *)logLine
{
	NSParameterAssert(logLine != nil);

	if ([TPCPreferences logToDiskIsEnabled] == NO) {
		return;
	}

	if (self.logFile == nil) {
		self.logFile = [[TLOFileLogger alloc] initWithChannel:self];
	}

	[self.logFile writeLogLine:logLine];
}

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(logLine != nil);

	[self.viewController print:logLine completionBlock:completionBlock];
	
	[self writeToLogLineToLogFile:logLine];
}

#pragma mark -
#pragma mark Member List

- (NSUInteger)_sortedInsertMember:(IRCUser *)member
{
	NSParameterAssert(member != nil);

	if ([member isKindOfClass:[IRCUserMutable class]]) {
		member = [member copy];
	}

	NSUInteger insertedIndex =
	[self.memberListStandardSortedContainer insertSortedObject:member usingComparator:NSDefaultComparator];

	(void)[self.memberListLengthSortedContainer insertSortedObject:member usingComparator:[IRCUser nicknameLengthComparator]];
	
	return insertedIndex;
}

- (void)_removeMemberFromTableView:(IRCUser *)member
{
	NSParameterAssert(member != nil);

	_cancelOnNotSelectedChannel

	NSInteger rowIndex = [mainWindowMemberList() rowForItem:member];
	
	if (rowIndex >= 0) {
		[mainWindowMemberList() removeItemFromListAtIndex:rowIndex];
	}
}

- (BOOL)_removeMember:(IRCUser *)member
{
	BOOL removedMember = NO;

	NSUInteger standardSortedMemberIndex =
	[self.memberListStandardSortedContainer indexOfObjectIdenticalTo:member];

	if (standardSortedMemberIndex != NSNotFound) {
		removedMember = YES;

		[self.memberListStandardSortedContainer removeObjectAtIndex:standardSortedMemberIndex];
	}

	NSUInteger lengthSortedMemberIndex =
	[self.memberListLengthSortedContainer indexOfObjectIdenticalTo:member];

	if (lengthSortedMemberIndex != NSNotFound) {
		[self.memberListLengthSortedContainer removeObjectAtIndex:lengthSortedMemberIndex];
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self _removeMemberFromTableView:member];
	});

	return removedMember;
}

- (void)addMember:(IRCUser *)member
{
	NSParameterAssert(member != nil);

	__block NSInteger insertedIndex = (-1);
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		insertedIndex = [self _sortedInsertMember:member];
	});

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self informMemberListViewOfAdditionalMemberAtIndex:insertedIndex];

		if (self.isChannel) {
			[self.associatedClient postEventToViewController:@"channelMemberAdded" forChannel:self];
		}
	});
}

- (void)removeMemberWithNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	IRCUser *member = [self findMember:nickname options:NSCaseInsensitiveSearch];

	if (member) {
		[self removeMember:member];
	}
}

- (void)removeMember:(IRCUser *)member
{
	NSParameterAssert(member != nil);

	__block BOOL memberRemoved = NO;

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		memberRemoved = [self _removeMember:member];
	});

	if (memberRemoved == NO || self.isChannel == NO) {
		return;
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self.associatedClient postEventToViewController:@"channelMemberRemoved" forChannel:self];
	});
}

- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname
{
	NSParameterAssert(fromNickname != nil);
	NSParameterAssert(toNickname != nil);

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		IRCUser *member = [self findMember:fromNickname options:NSCaseInsensitiveSearch];

		if (member == nil) {
			return;
		}

		IRCUserMutable *memberMutable = [member mutableCopy];

		memberMutable.nickname = toNickname;

		[self replaceMember:member byInsertingMember:memberMutable];
	});
}

#pragma mark -

- (BOOL)memberRequiresRedraw:(IRCUser *)member1 comparedTo:(IRCUser *)member2
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	/* If the user has been changed in a way which does not require them to be
	 resorted, then we will replace them in the arrays instead of removing then
	 inserting again, incurring the cost of performing sort on hundreds of users. */
	return (NSObjectsAreEqual(member1.modes, member2.modes) == NO ||
			member1.isAway != member2.isAway ||
			member1.isCop != member2.isCop);
}

- (void)replaceMember:(IRCUser *)member1 withMember:(IRCUser *)member2
{
	if ([self memberRequiresRedraw:member1 comparedTo:member2]) {
		[self replaceMember:member1 byInsertingMember:member2];
	} else {
		[self replaceMember:member1 byReplacingMember:member2];
	}
}

- (void)replaceMember:(IRCUser *)member1 byInsertingMember:(IRCUser *)member2
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	__block NSInteger insertedIndex = (-1);

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		[self _removeMember:member1];

		insertedIndex = [self _sortedInsertMember:member2];
	});

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self informMemberListViewOfAdditionalMemberAtIndex:insertedIndex];
	});
}

- (void)replaceMember:(IRCUser *)member1 byReplacingMember:(IRCUser *)member2
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	if ([member2 isKindOfClass:[IRCUserMutable class]]) {
		member2 = [member2 copy];
	}

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		// Replace member in standard sorted container
		NSUInteger standardSortedMemberIndex =
		[self.memberListStandardSortedContainer indexOfObjectIdenticalTo:member1];

		if (standardSortedMemberIndex != NSNotFound) {
			self.memberListStandardSortedContainer[standardSortedMemberIndex] = member2;
		}

		// Replace member in length sorted container
		NSUInteger lengthSortedMemberIndex =
		[self.memberListLengthSortedContainer indexOfObjectIdenticalTo:member1];

		if (lengthSortedMemberIndex != NSNotFound) {
			self.memberListLengthSortedContainer[lengthSortedMemberIndex] = member2;
		}
	});

	XRPerformBlockSynchronouslyOnMainQueue(^{
		[mainWindowMemberList() reloadItem:member1];
	});
}

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(mode.length == 1);

	// Find member and create mutable copy for editing
	IRCUser *member = [self findMember:nickname options:NSCaseInsensitiveSearch];

	if (member == nil) {
		return;
	}

	IRCUserMutable *memberMutable = [member mutableCopy];

	NSString *oldMemberModes = memberMutable.modes;

	// If the member has no modes already and we are setting a mode, then
	// all we have to do is set the value of -modes to new mode
	BOOL processModes = YES;

	if (oldMemberModes.length == 0) {
		if (value) {
			processModes = NO;

			memberMutable.modes = mode;
		} else {
			return; // Can't remove mode from empty string
		}
	} else {
		if (value && [oldMemberModes contains:mode]) {
			return; // Mode is already in string
		}
	}

	// Split up the current user modes into an array of characters.
	// Enumerate over the array of characters to find which mode in the
	// current set has a rank lower than the mode being inserted.
	// Insert before the lower ranked mode or insert at end.
	if (processModes) {
		IRCISupportInfo *clientSupportInfo = self.associatedClient.supportInfo;

		NSArray *oldModeSymbols = oldMemberModes.characterStringBuffer;

		NSMutableArray *newModeSymbols = [oldModeSymbols mutableCopy];

		if (value == NO) {
			[newModeSymbols removeObject:mode];
		} else {
			NSUInteger rankOfNewMode = [clientSupportInfo rankForUserPrefixWithMode:mode];

			NSUInteger lowerRankedMode =
			[oldModeSymbols indexOfObjectPassingTest:^BOOL(NSString *oldModeSymbol, NSUInteger index, BOOL *stop) {
				NSInteger rankOfOldMode = [clientSupportInfo rankForUserPrefixWithMode:oldModeSymbol];

				if (rankOfOldMode < rankOfNewMode) {
					return YES;
				} else {
					return NO;
				}
			}];

			if (lowerRankedMode != NSNotFound) {
				[newModeSymbols insertObject:mode atIndex:lowerRankedMode];
			} else {
				[newModeSymbols addObject:mode];
			}
		}

		NSString *newMemberModes = [newModeSymbols componentsJoinedByString:NSStringEmptyPlaceholder];

		memberMutable.modes = newMemberModes;
	}

	if (value && [mode isEqualToString:@"Y"]) {
		/* InspIRCd treats +Y as an IRCop. */
		/* If the user wasn't already marked as an IRCop, then we
		 mark them at this point. */

		memberMutable.isCop = YES;
	}

	// Remove the user from the member list and insert sorted
	[self replaceMember:member withMember:memberMutable];
}

#pragma mark -

- (void)clearMembers
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		[self.memberListStandardSortedContainer removeAllObjects];
		
		[self.memberListLengthSortedContainer removeAllObjects];
	});
}

- (NSUInteger)numberOfMembers
{
	__block NSUInteger memberCount = 0;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		memberCount = self.memberListStandardSortedContainer.count;
	});
	
	return memberCount;
}

- (NSArray<IRCUser *> *)memberList
{
	__block NSArray<IRCUser *> *memberList = nil;

	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		memberList = [self.memberListStandardSortedContainer copy];
	});

	return memberList;
}

- (NSArray<IRCUser *> *)memberListSortedByNicknameLength
{
	__block NSArray<IRCUser *> *memberList = nil;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		memberList = [self.memberListLengthSortedContainer copy];
	});
	
	return memberList;
}

#pragma mark -
#pragma mark User Search

- (BOOL)memberExists:(NSString *)nickname
{
	__block BOOL memberExists = NO;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		NSUInteger memberIndex = [self indexOfMember:nickname options:NSCaseInsensitiveSearch inList:self.memberListStandardSortedContainer];

		memberExists = (memberIndex != NSNotFound);
	});
	
	return memberExists;
}

- (nullable IRCUser *)findMember:(NSString *)nickname
{
	return [self findMember:nickname options:NSCaseInsensitiveSearch];
}

- (nullable IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)options
{
	NSParameterAssert(nickname != nil);

	__block IRCUser *member = nil;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		NSUInteger memberIndex = [self indexOfMember:nickname options:options inList:self.memberListStandardSortedContainer];
		
		if (memberIndex != NSNotFound) {
			member = self.memberListStandardSortedContainer[memberIndex];
		}
	});
	
	return member;
}

- (IRCUser *)memberAtIndex:(NSUInteger)index
{
	__block IRCUser *member = nil;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		member = self.memberListStandardSortedContainer[index];
	});
	
	return member;
}

- (NSUInteger)indexOfMember:(NSString *)nickname options:(NSStringCompareOptions)options inList:(NSArray *)memberList
{
	NSParameterAssert(nickname != nil);

	NSUInteger memberIndex =
	[memberList indexOfObjectWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
		NSString *nickname2 = ((IRCUser *)object).nickname;

		if ((options & NSCaseInsensitiveSearch) == NSCaseInsensitiveSearch) {
			return [nickname isEqualIgnoringCase:nickname2];
		} else {
			return [nickname isEqualToString:nickname2];
		}
	}];

	return memberIndex;
}

#pragma mark -
#pragma mark Table View Internal Management

- (void)informMemberListViewOfAdditionalMemberAtIndex:(NSUInteger)insertedIndex
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() addItemToList:insertedIndex];
}

- (void)reloadDataForTableViewBySortingMembers
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		[self.memberListStandardSortedContainer sortUsingComparator:NSDefaultComparator];
		
		[self reloadDataForTableView];
	});
}

- (void)reloadDataForTableView
{
	_cancelOnNotSelectedChannel;

	[self performBlockOnMainThread:^{
		[mainWindowMemberList() reloadData];
	}];
}

- (void)updateAllMembersOnTableView
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() reloadAllDrawings];
}

- (void)updateMemberOnTableView:(IRCUser *)member
{
	_cancelOnNotSelectedChannel;

	[mainWindowMemberList() updateDrawingForMember:member];
}

#pragma mark -
#pragma mark Table View Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	return self.numberOfMembers;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item;
{
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	return [userInterfaceObjects cellRowHeight];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	return [self memberAtIndex:index];
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	NSView *newView = [outlineView makeViewWithIdentifier:@"GroupView" owner:self];

	((TVCMemberListCell *)newView).cellItem = item;

	return newView;
}

- (nullable NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
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
	return (self == mainWindow().selectedItem);
}

- (BOOL)isActive
{
	return (self.status == IRCChannelStatusJoined);
}

- (BOOL)isClient
{
	return NO;
}

- (NSUInteger)numberOfChildren
{
	return 0;
}

- (id)childAtIndex:(NSUInteger)index
{
	return nil;
}

- (NSString *)label
{
	return self.name;
}

- (IRCClient *)associatedClient
{
	return _associatedClient;
}

- (nullable IRCChannel *)associatedChannel
{
	return self;
}

- (TVCLogControllerOperationQueue *)printingQueue
{
	return self.associatedClient.printingQueue;
}

@end

NS_ASSUME_NONNULL_END
