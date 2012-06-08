// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCWorld, IRCClient, IRCChannel, InputHistory, LogController;

@interface IRCTreeItem : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
	NSInteger uid;
	
	LogController *log;
	
	BOOL isKeyword;
	BOOL isUnread;
	BOOL isNewTalk;
	
	BOOL isExpanded;
	
	NSInteger keywordCount;
	NSInteger dockUnreadCount;
	NSInteger treeUnreadCount;
	
	InputHistory *inputHistory;
	NSAttributedString *currentInputHistory;
}

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) LogController *log;
@property (nonatomic, assign) BOOL isKeyword;
@property (nonatomic, assign) BOOL isUnread;
@property (nonatomic, assign) BOOL isNewTalk;
@property (nonatomic, assign) NSInteger keywordCount;
@property (nonatomic, assign) NSInteger dockUnreadCount;
@property (nonatomic, assign) NSInteger treeUnreadCount;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) BOOL isClient;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, weak, readonly) IRCClient *client;
@property (nonatomic, weak, readonly) NSString *label;
@property (nonatomic, weak, readonly) NSString *name;
@property (nonatomic, strong) InputHistory *inputHistory;

- (void)resetState;
- (NSInteger)numberOfChildren;
- (IRCTreeItem *)childAtIndex:(NSInteger)index;

- (void)resetLogView:(IRCWorld *)world withChannel:(IRCChannel *)c andClient:(IRCClient *)u;
@end