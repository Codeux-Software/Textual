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

@property (assign) NSInteger uid;
@property (strong) LogController *log;
@property (assign) BOOL isKeyword;
@property (assign) BOOL isUnread;
@property (assign) BOOL isNewTalk;
@property (assign) NSInteger keywordCount;
@property (assign) NSInteger dockUnreadCount;
@property (assign) NSInteger treeUnreadCount;
@property (readonly) BOOL isActive;
@property (readonly) BOOL isClient;
@property (assign) BOOL isExpanded;
@property (weak, readonly) IRCClient *client;
@property (weak, readonly) NSString *label;
@property (weak, readonly) NSString *name;
@property (strong) InputHistory *inputHistory;

- (void)resetState;
- (NSInteger)numberOfChildren;
- (IRCTreeItem *)childAtIndex:(NSInteger)index;

- (void)resetLogView:(IRCWorld *)world withChannel:(IRCChannel *)c andClient:(IRCClient *)u;
@end