// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize keywordCount;
@synthesize inputHistory;
@synthesize treeUnreadCount;
@synthesize dockUnreadCount;

- (void)dealloc
{
	[log drain];
	[inputHistory drain];
	
	[super dealloc];
}

- (void)resetLogView:(IRCWorld *)world withChannel:(IRCChannel *)c andClient:(IRCClient *)u
{
	[log clear];
}

- (IRCClient *)client
{
	return nil;
}

- (BOOL)isClient
{
	return NO;
}

- (BOOL)isActive
{
	return NO;
}

- (void)resetState
{
	dockUnreadCount = treeUnreadCount = 0;
	keywordCount = 0;
	isKeyword = isUnread = isNewTalk = NO;
}

- (NSInteger)numberOfChildren
{
	return 0;
}

- (IRCTreeItem *)childAtIndex:(NSInteger)index
{
	return nil;
}

- (NSString *)label
{
	return NSNullObject;
}

- (NSString *)name
{
	return NSNullObject;
}

@end