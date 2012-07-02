// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface IRCTreeItem : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) TVCLogController *log;
@property (nonatomic, assign) BOOL isKeyword;
@property (nonatomic, assign) BOOL isUnread;
@property (nonatomic, assign) BOOL isNewTalk;
@property (nonatomic, assign) NSInteger keywordCount;
@property (nonatomic, assign) NSInteger dockUnreadCount;
@property (nonatomic, assign) NSInteger treeUnreadCount;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL isClient;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) NSString *label;
@property (nonatomic, weak) NSString *name;
@property (nonatomic, strong) TLOInputHistory *inputHistory;
@property (nonatomic, strong) NSAttributedString *currentInputHistory;

- (void)resetState;
- (NSInteger)numberOfChildren;
- (IRCTreeItem *)childAtIndex:(NSInteger)index;

- (void)resetLogView:(IRCWorld *)world withChannel:(IRCChannel *)c andClient:(IRCClient *)u;
@end