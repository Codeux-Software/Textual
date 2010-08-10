// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@class IRCWorld;
@class IRCClient;
@class IRCChannel;
@class LogController;

@interface IRCTreeItem : NSObject 
{
	NSInteger uid;
	LogController* log;
	BOOL isKeyword;
	BOOL isUnread;
	BOOL isNewTalk;
	NSInteger keywordCount;
	NSInteger unreadCount;
}

@property (assign) NSInteger uid;
@property (retain) LogController* log;
@property (assign) BOOL isKeyword;
@property (assign) BOOL isUnread;
@property (assign) BOOL isNewTalk;
@property (assign) NSInteger keywordCount;
@property (assign) NSInteger unreadCount;
@property (readonly) BOOL isActive;
@property (readonly) BOOL isClient;
@property (readonly) IRCClient* client;
@property (readonly) NSString* label;
@property (readonly) NSString* name;

- (void)resetState;
- (NSInteger)numberOfChildren;
- (IRCTreeItem*)childAtIndex:(NSInteger)index;

- (void)resetLogView:(IRCWorld*)world withChannel:(IRCChannel*)c andClient:(IRCClient*)u;

@end