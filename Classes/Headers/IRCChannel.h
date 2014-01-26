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
	IRCChannelParted,
	IRCChannelJoining,
	IRCChannelJoined,
	IRCChannelTerminated,
} IRCChannelStatus;

@interface IRCChannel : IRCTreeItem <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (nonatomic, nweak) NSString *name;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, strong) IRCChannelMode *modeInfo;
@property (nonatomic, strong) IRCChannelConfig *config;
@property (nonatomic, assign) IRCChannelStatus status;
@property (nonatomic, assign) BOOL errorOnLastJoinAttempt;
@property (nonatomic, assign) BOOL inUserInvokedModeRequest;
@property (nonatomic, assign) NSInteger channelJoinTime;

- (void)setup:(IRCChannelConfig *)seed;
- (void)updateConfig:(IRCChannelConfig *)seed;

- (NSMutableDictionary *)dictionaryValue;

- (NSString *)uniqueIdentifier;

- (NSString *)secretKey;

- (BOOL)isChannel;
- (BOOL)isPrivateMessage;

- (NSString *)channelTypeString;

- (void)prepareForApplicationTermination;
- (void)prepareForPermanentDestruction;

- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;

- (void)writeToLogFile:(TVCLogLine *)line;

- (void)print:(TVCLogLine *)logLine;
- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock;

- (IRCUser *)findMember:(NSString *)nickname;
- (IRCUser *)findMember:(NSString *)nickname options:(NSStringCompareOptions)mask;

- (IRCUser *)memberWithNickname:(NSString *)nickname;
- (IRCUser *)memberAtIndex:(NSInteger)idx; // idx must be on table view.

- (void)addMember:(IRCUser *)user;
- (void)removeMember:(NSString *)nickname;
- (void)renameMember:(NSString *)fromNickname to:(NSString *)toNickname;
- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value;

- (void)clearMembers;

- (NSInteger)numberOfMembers;

- (NSArray *)unsortedMemberList;
- (NSArray *)sortedByNicknameLengthMemberList;

- (void)setEncryptionKey:(NSString *)encryptionKey; // Use this instead of config to inform view of change.

/* For redrawing the member cells in table view. */
- (BOOL)memberRequiresRedraw:(IRCUser *)user1 comparedTo:(IRCUser *)user2;

- (void)updateAllMembersOnTableView;
- (void)updateMemberOnTableView:(IRCUser *)user;

- (void)reloadDataForTableView;
- (void)reloadDataForTableViewBySortingMembers;

- (void)updateTableViewByRemovingIgnoredUsers;
@end
