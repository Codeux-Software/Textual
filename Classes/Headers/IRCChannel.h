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

#import "IRCTreeItem.h" // superclass

typedef enum IRCChannelStatus : NSInteger {
	IRCChannelStatusParted,
	IRCChannelStatusJoining,
	IRCChannelStatusJoined,
	IRCChannelStatusTerminated,
} IRCChannelStatus;

#define IRCChannelConfigurationWasUpdatedNotification	@"IRCChannelConfigurationWasUpdatedNotification"

@interface IRCChannel : IRCTreeItem <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (nonatomic, nweak) NSString *name;
@property (nonatomic, copy) NSString *topic;
@property (nonatomic, copy) IRCChannelConfig *config;
@property (nonatomic, strong) IRCChannelMode *modeInfo;
@property (nonatomic, assign) IRCChannelStatus status;
@property (nonatomic, assign) BOOL errorOnLastJoinAttempt;
@property (nonatomic, assign) BOOL sentInitialWhoRequest;
@property (nonatomic, assign) BOOL inUserInvokedModeRequest;
@property (nonatomic, assign) NSInteger channelJoinTime;

- (void)setup:(IRCChannelConfig *)seed;

- (void)updateConfig:(IRCChannelConfig *)seed;
- (void)updateConfig:(IRCChannelConfig *)seed fireChangedNotification:(BOOL)fireChangedNotification;

- (NSMutableDictionary *)dictionaryValue;

@property (readonly, copy) NSString *uniqueIdentifier;

@property (readonly, copy) NSString *secretKey;

@property (getter=isChannel, readonly) BOOL channel;
@property (getter=isPrivateMessage, readonly) BOOL privateMessage;
@property (getter=isPrivateMessageOwnedByZNC, readonly) BOOL privateMessageOwnedByZNC; // For example: *status, *nickserv, etc.

@property (readonly, copy) NSString *channelTypeString;

- (void)prepareForApplicationTermination;
- (void)prepareForPermanentDestruction;

- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;

@property (readonly, copy) NSURL *logFilePath;

- (void)writeToLogFile:(TVCLogLine *)line;

- (void)print:(TVCLogLine *)logLine;
- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock;

@property (nonatomic, copy) NSString *encryptionKey;
@property (nonatomic, assign) CSFWBlowfishEncryptionAlgorithm encryptionAlgorithm;

- (BOOL)memberExists:(NSString *)nickname;

- (IRCUser *)findMember:(NSString *)nickname;
- (IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)mask;

- (void)addMember:(IRCUser *)user;
- (void)removeMember:(NSString *)nickname;
- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname;
- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value;

- (void)clearMembers; // This will not reload table view. 

@property (readonly) NSInteger numberOfMembers;

/* The member list methods returns the actual instance of user stored in 
 the channels internal cache. IRCUser is not KVO based so if you modify a
 user returned, then do Textual the kindness of reloading that member in 
 the member list view. */
@property (readonly, copy) NSArray *sortedByChannelRankMemberList TEXTUAL_DEPRECATED("Use -memberList instead");
@property (readonly, copy) NSArray *sortedByNicknameLengthMemberList TEXTUAL_DEPRECATED("Use -memberListSortedByNicknameLength instead");

@property (readonly, copy) NSArray *memberList; // Automatically sorted by channel rank
@property (readonly, copy) NSArray *memberListSortedByNicknameLength; // Copy of member list automatically sorted by longest nickname to shortest nickname

- (BOOL)memberRequiresRedraw:(IRCUser *)user1 comparedTo:(IRCUser *)user2;

- (void)updateAllMembersOnTableView;
- (void)updateMemberOnTableView:(IRCUser *)user;

- (void)reloadDataForTableView;
- (void)reloadDataForTableViewBySortingMembers;
@end
