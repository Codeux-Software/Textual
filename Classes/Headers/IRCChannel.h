// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCTreeItem.h" // superclass

typedef enum IRCChannelStatus : NSInteger {
	IRCChannelParted,
	IRCChannelJoining,
	IRCChannelJoined,
	IRCChannelTerminated,
} IRCChannelStatus;

@interface IRCChannel : IRCTreeItem
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, strong) IRCChannelMode *mode;
@property (nonatomic, strong) IRCChannelConfig *config;
@property (nonatomic, strong) NSMutableArray *members;
@property (nonatomic, weak) NSString *channelTypeString;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSString *storedTopic;
@property (nonatomic, strong) NSString *logDate;
@property (nonatomic, assign) BOOL isOp;
@property (nonatomic, assign) BOOL isHalfOp;
@property (nonatomic, assign) BOOL isModeInit;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL errLastJoin;
@property (nonatomic, assign) IRCChannelStatus status;
@property (nonatomic, assign) BOOL isChannel;
@property (nonatomic, assign) BOOL isTalk;
@property (nonatomic, strong) TLOFileLogger *logFile;
@property (nonatomic, weak) NSString *name;
@property (nonatomic, weak) NSString *password;

- (void)setup:(IRCChannelConfig *)seed;
- (void)updateConfig:(IRCChannelConfig *)seed;
- (NSMutableDictionary *)dictionaryValue;

- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;
- (void)detectOutgoingConversation:(NSString *)text;

- (BOOL)print:(TVCLogLine *)line;
- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)rawHTML;

- (void)addMember:(IRCUser *)user;
- (void)addMember:(IRCUser *)user reload:(BOOL)reload;

- (void)removeMember:(NSString *)nick;
- (void)removeMember:(NSString *)nick reload:(BOOL)reload;

- (void)renameMember:(NSString *)fromNick to:(NSString *)toNick;

- (void)updateOrAddMember:(IRCUser *)user;
- (void)changeMember:(NSString *)nick mode:(char)mode value:(BOOL)value;

- (void)clearMembers;

- (IRCUser *)memberAtIndex:(NSInteger)index;

- (IRCUser *)findMember:(NSString *)nick;
- (IRCUser *)findMember:(NSString *)nick options:(NSStringCompareOptions)mask;

- (NSInteger)indexOfMember:(NSString *)nick;
- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask;

- (NSInteger)numberOfMembers;

- (void)reloadMemberList;
@end