// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient;

typedef enum {
	IRCChannelParted,
	IRCChannelJoining,
	IRCChannelJoined,
	IRCChannelTerminated,
} ChannelStatus;

@interface IRCChannel : IRCTreeItem
{
	IRCClient *__weak client;
	IRCChannelMode *mode;
	IRCChannelConfig *config;
	
	NSMutableArray *members;
	
	NSString *topic;
	NSString *storedTopic;
	
	NSString *logDate;
	
	BOOL isOp;
	BOOL isHalfOp;
	BOOL isModeInit;
	BOOL isActive;
	BOOL errLastJoin;
	
	ChannelStatus status;
	
	FileLogger *logFile;
}

@property (weak) IRCClient *client;
@property (readonly) IRCChannelMode *mode;
@property (readonly) IRCChannelConfig *config;
@property (readonly) NSMutableArray *members;
@property (weak, readonly) NSString *channelTypeString;
@property (strong) NSString *topic;
@property (strong) NSString *storedTopic;
@property (strong) NSString *logDate;
@property (assign) BOOL isOp;
@property (assign) BOOL isHalfOp;
@property (assign) BOOL isModeInit;
@property (assign) BOOL isActive;
@property (assign) BOOL errLastJoin;
@property (assign) ChannelStatus status;
@property (readonly) BOOL isChannel;
@property (readonly) BOOL isTalk;
@property (strong) FileLogger *logFile;
@property (weak) NSString *name;
@property (weak, readonly) NSString *password;

- (void)setup:(IRCChannelConfig *)seed;
- (void)updateConfig:(IRCChannelConfig *)seed;
- (NSMutableDictionary *)dictionaryValue;

- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;
- (void)detectOutgoingConversation:(NSString *)text;

- (BOOL)print:(LogLine *)line;
- (BOOL)print:(LogLine *)line withHTML:(BOOL)rawHTML;

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