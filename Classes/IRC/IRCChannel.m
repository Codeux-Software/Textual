/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#include <objc/message.h>

#import "NSObjectHelperPrivate.h"
#import "TXMasterController.h"
#import "TXWindowControllerPrivate.h"
#import "TVCMainWindowPrivate.h"
#import "TVCMemberListPrivate.h"
#import "TVCMemberListCellPrivate.h"
#import "TVCMemberListSharedUserInterfacePrivate.h"
#import "TVCLogControllerPrivate.h"
#import "TDCSharedProtocolDefinitionsPrivate.h"
#import "TDCSheetBase.h"
#import "TPCPreferencesLocal.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOEncryptionManagerPrivate.h"
#import "TLOFileLoggerPrivate.h"
#import "TLOInputHistoryPrivate.h"
#import "TLOLanguagePreferences.h"
#import "IRCClientPrivate.h"
#import "IRCChannelConfigPrivate.h"
#import "IRCChannelModePrivate.h"
#import "IRCChannelUserPrivate.h"
#import "IRCISupportInfo.h"
#import "IRCTreeItemPrivate.h"
#import "IRCUser.h"
#import "IRCUserRelationsPrivate.h"
#import "IRCWorldPrivate.h"
#import "IRCChannelPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const IRCChannelConfigurationWasUpdatedNotification = @"IRCChannelConfigurationWasUpdatedNotification";

@interface IRCChannel ()
@property (readonly) BOOL isSelectedChannel;
@property (nonatomic, assign) BOOL statusChangedByAction;
@property (nonatomic, assign) BOOL reloadingMemberList;
@property (nonatomic, copy, readwrite) IRCChannelConfig *config;
@property (nonatomic, assign, readwrite) NSTimeInterval channelJoinTime;
@property (nonatomic, strong, readwrite, nullable) IRCChannelMode *modeInfo;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, assign, readwrite) NSUInteger logFileSessionCount;

/* memberListStandardSortedContainer is a copy of the member list sorted by the channel
 rank of each member.*/
@property (nonatomic, strong) NSMutableArray<IRCChannelUser *> *memberListStandardSortedContainer;
@end

@implementation IRCChannel

@synthesize associatedClient = _associatedClient;

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

		[self.config writeSecretKeyToKeychain];

		[self prepareInitialState];
	}

	return self;
}

- (void)prepareInitialState
{
	self.memberListStandardSortedContainer = [NSMutableArray array];
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
			[currentConfig.channelName isEqualToString:config.channelName] == NO ||
			[currentConfig.uniqueIdentifier isEqualToString:config.uniqueIdentifier] == NO)
		{
			LogToConsoleError("Tried to load configuration for incorrect channel");

			return;
		}
	}

	self.config = config;

	[self.config writeSecretKeyToKeychain];

	if (updateStoredChannelList) {
		[self.associatedClient updateStoredChannelList];
	}

	if (fireChangedNotification) {
		[RZNotificationCenter() postNotificationName:IRCChannelConfigurationWasUpdatedNotification object:self];
	}
}

- (NSDictionary<NSString *, id> *)configurationDictionary
{
	return [self.config dictionaryValue];
}

- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud
{
	return [self.config dictionaryValueForCloud];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	/* Implement this method to allow channel to be 
	 used as a dictionary key. */

	return self;
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

- (BOOL)isUtility
{
	return (self.config.type == IRCChannelUtilityType);
}

- (BOOL)isPrivateMessageForZNCUser
{
	if (self.isPrivateMessage == NO) {
		return NO;
	}

	IRCClient *client = self.associatedClient;

	return [client nicknameIsZNCUser:self.name];
}

- (IRCChannelType)type
{
	return self.config.type;
}

- (NSString *)channelTypeString
{
	switch (self.config.type) {
		case IRCChannelChannelType:
		{
			return @"channel";
		}
		case IRCChannelPrivateMessageType:
		{
			return @"query";
		}
		case IRCChannelUtilityType:
		{
			return @"utility";
		}
	}
}

- (nullable NSURL *)logFilePath
{
	NSString *writePath = nil;

	if (self.logFile == nil) {
		writePath = [TLOFileLogger writePathForItem:self];
	} else {
		writePath = self.logFile.writePath.stringByDeletingLastPathComponent;
	}

	return [NSURL fileURLWithPath:writePath];
}

#pragma mark -
#pragma mark Property Setter

- (void)setAutoJoin:(BOOL)autoJoin
{
	if (self.isChannel == NO) {
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

	if (self.isChannel) {
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
	if ([TPCPreferences displayPublicMessageCountOnDockBadge] == NO) {
		if (self.isChannel) {
			self.dockUnreadCount = 0;
		}
	}
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

	self.channelModesReceived = NO;
	self.channelNamesReceived = NO;
	self.errorOnLastJoinAttempt = NO;
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
		IRCUser *user1 = [self.associatedClient findUserOrCreate:self.name];

		[self addUser:user1];

		IRCUser *user2 = [self.associatedClient findUserOrCreate:client.userNickname];

		[self addUser:user2];
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

	[self.config destroySecretKeyKeychainItem];

	NSArray *openWindows = [windowController()
							windowsFromWindowList:@[@"TDCChannelPropertiesSheet",
													@"TDCChannelModifyTopicSheet",
													@"TDCChannelModifyModesSheet",
													@"TDCChannelBanListSheet"]];

	for (TDCSheetBase <TDCChannelPrototype> *windowObject in openWindows) {
		if ([windowObject.channelId isEqualToString:self.uniqueIdentifier]) {
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
		[self.config destroySecretKeyKeychainItem];
	}

	[self.viewController prepareForApplicationTermination];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logToDiskIsEnabled] && self.isUtility == NO

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
		&&
		(TLOAppStoreTextualIsRegistered() || TLOAppStoreIsTrialExpired() == NO)
#endif

		)
	{
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

- (void)logFileWriteSessionBegin
{
	[self.associatedClient logFileRecordSessionChanged:YES inChannel:self];
}

- (void)logFileWriteSessionEnd
{
	[self.associatedClient logFileRecordSessionChanged:NO inChannel:self];

	self.logFileSessionCount = 0;
}

#pragma mark -
#pragma mark Printing

- (void)writeToLogLineToLogFile:(TVCLogLine *)logLine
{
	NSParameterAssert(logLine != nil);

	if ([TPCPreferences logToDiskIsEnabled] == NO || self.isUtility) {
		return;
	}

	// Perform addition before if statement to avoid infinite loop
	self.logFileSessionCount += 1;

	if (self.logFileSessionCount == 1) {
		[self logFileWriteSessionBegin];
	}

	if (self.logFile == nil) {
		self.logFile = [[TLOFileLogger alloc] initWithChannel:self];
	}

	[self.logFile writeLogLine:logLine];
}

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:nil];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(logLine != nil);

	[self.viewController print:logLine completionBlock:completionBlock];

	[self writeToLogLineToLogFile:logLine];
}

#pragma mark -
#pragma mark Grand Central Dispatch

/* All modifications to the member list occur on this serial queue to
 gurantee that there is only ever one person accessing the mutable 
 store at any given time. */
+ (dispatch_queue_t)modifyMembmerListSerialQueue
{
	static dispatch_queue_t workerQueue = NULL;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		workerQueue =
		XRCreateDispatchQueueWithPriority("IRCChannel.modifyMembmerListSerialQueue", DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT);
	});

	return workerQueue;
}

+ (void)resumeMemberListSerialQueues
{
	dispatch_resume([self modifyMembmerListSerialQueue]);
}

+ (void)suspendMemberListSerialQueues
{
	dispatch_suspend([self modifyMembmerListSerialQueue]);
}

+ (void)accessMemberListUsingBlock:(dispatch_block_t)block
{
	NSCParameterAssert(block != NULL);

	dispatch_queue_t workerQueue = [self modifyMembmerListSerialQueue];

	static void *IsOnWorkerQueueKey = NULL;

	if (IsOnWorkerQueueKey == NULL) {
		IsOnWorkerQueueKey = &IsOnWorkerQueueKey;

		dispatch_queue_set_specific(workerQueue, IsOnWorkerQueueKey, (void *)1, NULL);
	}

	if (dispatch_get_specific(IsOnWorkerQueueKey)) {
		block();

		return;
	}

	dispatch_sync(workerQueue, ^{
		@autoreleasepool {
			block();
		}
	});
}

#pragma mark -
#pragma mark Member List

- (NSUInteger)_sortedIndexForMember:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	NSUInteger index = [self.memberListStandardSortedContainer
							indexOfObject:member
							inSortedRange:self.memberListStandardSortedContainer.range
								  options:NSBinarySearchingInsertionIndex
						  usingComparator:[IRCChannelUser channelRankComparator]];

	return index;
}

- (NSInteger)_sortedInsert:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	NSInteger insertedIndex = [self _sortedIndexForMember:member];

	[self.memberListStandardSortedContainer insertObject:member atIndex:insertedIndex];

	return insertedIndex;
}

- (NSInteger)_replaceMemberInMemberList:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	NSInteger replacedIndex = (-1);

	NSUInteger standardSortedMemberIndex =
	[self.memberListStandardSortedContainer indexOfObjectIdenticalTo:member1];

	if (standardSortedMemberIndex != NSNotFound) {
		replacedIndex = standardSortedMemberIndex;

		self.memberListStandardSortedContainer[standardSortedMemberIndex] = member2;
	}

	return replacedIndex;
}

- (void)_removeMemberFromTableView:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	NSInteger rowIndex = [mainWindowMemberList() rowForItem:member];

	if (rowIndex >= 0) {
		[mainWindowMemberList() removeItemFromListAtIndex:rowIndex];
	}
}

- (BOOL)_removeMemberFromMemberList:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	BOOL removedMember = NO;

	NSUInteger standardSortedMemberIndex =
	[self.memberListStandardSortedContainer indexOfObjectIdenticalTo:member];

	if (standardSortedMemberIndex != NSNotFound) {
		removedMember = YES;

		[self.memberListStandardSortedContainer removeObjectAtIndex:standardSortedMemberIndex];
	}

	return removedMember;
}

- (void)addUser:(IRCUser *)user
{
	NSParameterAssert(user != nil);

	IRCChannelUser *member = [[IRCChannelUser alloc] initWithUser:user];

	[self addMember:member];
}

- (void)addMember:(IRCChannelUser *)member
{
	/* checkForDuplicates defaults to NO because to avoid extra work */

	[self addMember:member checkForDuplicates:NO];
}

- (void)addMember:(IRCChannelUser *)member checkForDuplicates:(BOOL)checkForDuplicates
{
	NSParameterAssert(member != nil);

	if (checkForDuplicates) {
		IRCChannelUser *oldMember = [member.user userAssociatedWithChannel:self];

		if (oldMember != nil) {
			[self replaceMember:oldMember withMember:member];

			return;
		}
	}

	if ([member isKindOfClass:[IRCChannelUserMutable class]]) {
		member = [member copy];
	}

	[member associateWithChannel:self];

	[self willChangeValueForKey:@"numberOfMembers"];
	[self willChangeValueForKey:@"memberList"];

	__block NSInteger sortedIndex = (-1);

	[self.class accessMemberListUsingBlock:^{
		sortedIndex = [self _sortedInsert:member];
	}];

	[self didChangeValueForKey:@"numberOfMembers"];
	[self didChangeValueForKey:@"memberList"];

	if (self.isChannel == NO) {
		return;
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		if (self.isSelectedChannel) {
			[self _informMemberListViewOfAdditionalMemberAtIndex:sortedIndex];
		}

		[self.associatedClient postEventToViewController:@"channelMemberAdded" forChannel:self];
	});
}

- (void)removeMemberWithNickname:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	IRCChannelUser *member = [self findMember:nickname];

	if (member) {
		[self removeMember:member];
	}
}

- (void)removeMember:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	[member disassociateWithChannel:self];

	__block BOOL memberRemoved = NO;

	[self.class accessMemberListUsingBlock:^{
		memberRemoved = [self _removeMemberFromMemberList:member];
	}];

	if (memberRemoved == NO || self.isChannel == NO) {
		return;
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		if (self.isSelectedChannel) {
			[self _removeMemberFromTableView:member];
		}

		[self.associatedClient postEventToViewController:@"channelMemberRemoved" forChannel:self];
	});
}

#pragma mark -

- (void)resortMember:(IRCChannelUser *)member
{
	NSParameterAssert(member != nil);

	if ([member isKindOfClass:[IRCChannelUserMutable class]]) {
		member = [member copy];
	}

	[self _replaceMember:member withMember:member resort:YES];
}

- (void)_replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2 resort:(BOOL)resort
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	[member1 disassociateWithChannel:self];

	[member2 associateWithChannel:self];

	__block NSInteger sortedIndex = (-1);

	[self.class accessMemberListUsingBlock:^{
		if (resort) {
			[self _removeMemberFromMemberList:member1];

			sortedIndex = [self _sortedInsert:member2];
		} else {
			sortedIndex = [self _replaceMemberInMemberList:member1 withMember:member2];
		}
	}];

	if (sortedIndex < 0 || self.isChannel == NO) {
		return;
	}

	XRPerformBlockSynchronouslyOnMainQueue(^{
		if (self.isSelectedChannel == NO) {
			return;
		}

		[mainWindowMemberList() beginUpdates];

		if (resort) {
			[self _removeMemberFromTableView:member1];

			[self _informMemberListViewOfAdditionalMemberAtIndex:sortedIndex];
		} else {
			/* We reload the old member because the new member has not been
			 added to the table yet. By reloading it, we request the index 
			 that the old member is at, replacing it with the new member. */
			[self _reloadMemberInMemberList:member1];
		}

		[mainWindowMemberList() endUpdates];
	});
}

- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2
{
	[self replaceMember:member1 withMember:member2 resort:YES replaceInAllChannels:NO];
}

- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2 resort:(BOOL)resort
{
	[self replaceMember:member1 withMember:member2 resort:YES replaceInAllChannels:NO];
}

/* The replaceInAllChannels: flag should only be used in extreme cases because there is A LOT 
 of overhead to setting it. Textual only does it when the user list is configured to sort IRCop 
 at top and IRCop status changes. That change requires the user to be resorted in every channel 
 they are in. Knowing which channels they are in is easy because of IRCUserRelations, but the 
 actual process of finding where to sort them at is very costly. */
- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2 resort:(BOOL)resort replaceInAllChannels:(BOOL)replaceInAllChannels
{
	NSParameterAssert(member1 != nil);
	NSParameterAssert(member2 != nil);

	if ([member2 isKindOfClass:[IRCChannelUserMutable class]]) {
		member2 = [member2 copy];
	}

	[self _replaceMember:member1 withMember:member2 resort:resort];

	if (replaceInAllChannels) {
		NSDictionary *relations = member2.user.relations;

		[relations enumerateKeysAndObjectsUsingBlock:^(IRCChannel *channel, IRCChannelUser *member, BOOL *stop) {
			if (channel == self) {
				return;
			}

			[channel _replaceMember:member withMember:member resort:resort];
		}];
	}
}

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value
{
	NSParameterAssert(nickname != nil);
	NSParameterAssert(mode.length == 1);

	// Find member and create mutable copy for editing
	IRCChannelUser *member = [self findMember:nickname];

	if (member == nil) {
		return;
	}

	IRCChannelUserMutable *memberMutable = [member mutableCopy];

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

		NSString *newMemberModes = [newModeSymbols componentsJoinedByString:@""];

		memberMutable.modes = newMemberModes;
	}

	BOOL replaceInAllChannels = NO;

	if (value && [mode isEqualToString:@"Y"] && member.user.isIRCop == NO) {
		/* InspIRCd treats +Y as an IRCop. */
		/* If the user wasn't already marked as an IRCop, then we
		 mark them at this point. */

		[self.associatedClient modifyUser:member.user withBlock:^(IRCUserMutable *userMutable) {
			userMutable.isIRCop = YES;
		}];

		if ([TPCPreferences memberListSortFavorsServerStaff]) {
			replaceInAllChannels = YES;
		}
	}

	// Remove the user from the member list and insert sorted
	[self replaceMember:member
			 withMember:memberMutable
				 resort:YES
   replaceInAllChannels:replaceInAllChannels];
}

#pragma mark -

- (void)clearMembers
{
	[self.class accessMemberListUsingBlock:^{
		[self willChangeValueForKey:@"numberOfMembers"];
		[self willChangeValueForKey:@"memberList"];

		[self.memberListStandardSortedContainer makeObjectsPerformSelector:@selector(disassociateWithChannel:) withObject:self];

		[self.memberListStandardSortedContainer removeAllObjects];

		[self didChangeValueForKey:@"numberOfMembers"];
		[self didChangeValueForKey:@"memberList"];
	}];
}

- (NSUInteger)numberOfMembers
{
	__block NSUInteger memberCount = 0;

	[self.class accessMemberListUsingBlock:^{
		memberCount = self.memberListStandardSortedContainer.count;
	}];

	return memberCount;
}

- (NSArray<IRCChannelUser *> *)memberList
{
	__block NSArray<IRCChannelUser *> *memberList = nil;

	[self.class accessMemberListUsingBlock:^{
		memberList = [self.memberListStandardSortedContainer copy];
	}];

	return memberList;
}

#pragma mark -

- (NSData *)pasteboardDataForMembers:(NSArray<IRCChannelUser *> *)members
{
	NSParameterAssert(members != nil);

	NSString *channelId = self.uniqueIdentifier;

	NSMutableArray<NSString *> *nicknames = [NSMutableArray arrayWithCapacity:members.count];

	for (IRCChannelUser *member in members) {
		[nicknames addObject:member.user.nickname];
	}

	NSDictionary *pasteboardDictionary = @{
	   @"channelId" : channelId,
	   @"nicknames" : nicknames
	};

	NSData *pasteboardData = [NSKeyedArchiver archivedDataWithRootObject:pasteboardDictionary];

	return pasteboardData;
}

+ (BOOL)readNicknamesFromPasteboardData:(NSData *)pasteboardData withBlock:(void (NS_NOESCAPE ^)(IRCChannel *channel, NSArray<NSString *> *nicknames))callbackBlock
{
	NSParameterAssert(pasteboardData != nil);
	NSParameterAssert(callbackBlock != nil);

	/* This is a private method which means that we are very lazy about
	 validating the input, but this is a TODO to myself: add strict type
	 checks if you end up making this method public. */
	NSDictionary *pasteboardDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:pasteboardData];

	if ([pasteboardDictionary isKindOfClass:[NSDictionary class]] == NO) {
		return NO;
	}

	NSString *channelId = pasteboardDictionary[@"channelId"];

	IRCChannel *channel = (IRCChannel *)[worldController() findItemWithId:channelId];

	if (channel == nil) {
		return NO;
	}

	NSArray *nicknames = pasteboardDictionary[@"nicknames"];

	callbackBlock(channel, nicknames);

	return YES;
}

+ (BOOL)readMembersFromPasteboardData:(NSData *)pasteboardData withBlock:(void (NS_NOESCAPE ^)(IRCChannel *channel, NSArray<IRCChannelUser *> *members))callbackBlock
{
	NSParameterAssert(pasteboardData != nil);
	NSParameterAssert(callbackBlock != nil);

	return
	[self readNicknamesFromPasteboardData:pasteboardData withBlock:^(IRCChannel *channel, NSArray<NSString *> *nicknames) {
		NSMutableArray *members = [NSMutableArray arrayWithCapacity:nicknames.count];

		for (NSString *nickname in nicknames) {
			IRCChannelUser *member = [channel findMember:nickname];

			if (member == nil) {
				continue;
			}

			[members addObject:member];
		}

		callbackBlock(channel, [members copy]);
	}];
}

#pragma mark -
#pragma mark User Search

- (BOOL)memberExists:(NSString *)nickname
{
	return ([self findMember:nickname] != nil);
}

- (nullable IRCChannelUser *)findMember:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	IRCUser *user = [self.associatedClient findUser:nickname];

	if (user == nil) {
		return nil;
	}

	IRCChannelUser *member = [user userAssociatedWithChannel:self];

	if (member == nil) {
		return nil;
	}

	return member;
}

- (IRCChannelUser *)memberAtIndex:(NSUInteger)index
{
	__block IRCChannelUser *member = nil;

	[self.class accessMemberListUsingBlock:^{
		member = self.memberListStandardSortedContainer[index];
	}];

	return member;
}

#pragma mark -
#pragma mark Table View Internal Management

- (void)_reloadMemberInMemberList:(IRCChannelUser *)member
{
	[mainWindowMemberList() reloadItem:member];
}

- (void)_informMemberListViewOfAdditionalMemberAtIndex:(NSUInteger)insertedIndex
{
	[mainWindowMemberList() addItemToList:insertedIndex];
}

- (void)reloadDataForTableViewBySortingMembers
{
	if (self.isChannel == NO) {
		return;
	}

	[self.class accessMemberListUsingBlock:^{
		[self.memberListStandardSortedContainer sortUsingComparator:[IRCChannelUser channelRankComparator]];
	}];

	[self reloadDataForTableView];
}

- (void)reloadDataForTableView
{
	if (self.isChannel == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		if (self.isSelectedChannel == NO) {
			return;
		}

		[mainWindowMemberList() reloadData];
	});
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

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];

	return [userInterfaceObjects cellRowHeight];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	return [self memberAtIndex:index];
}

- (nullable id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item
{
	return item;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	NSView *newView = [outlineView makeViewWithIdentifier:@"GroupView" owner:self];

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

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	NSData *draggedData = [self pasteboardDataForMembers:items];

	[pasteboard declareTypes:@[TVCMemberListDragType] owner:self];

	[pasteboard setData:draggedData forType:TVCMemberListDragType];

	return YES;
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

- (nullable IRCClient *)associatedClient
{
	return self->_associatedClient;
}

- (nullable IRCChannel *)associatedChannel
{
	return self;
}

@end

NS_ASSUME_NONNULL_END
