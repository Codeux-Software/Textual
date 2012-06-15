// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize isExpanded;
@synthesize keywordCount;
@synthesize inputHistory;
@synthesize treeUnreadCount;
@synthesize dockUnreadCount;
@synthesize currentInputHistory;

#warning FIX: "-resetLogView:withChannel:andClient:" does not function properly. \
		It does not create new view when destroying the old. 

- (void)resetLogView:(IRCWorld *)world
		 withChannel:(IRCChannel *)c
		   andClient:(IRCClient *)u
{
	[self.log.view close];
	
	log = nil;
	log = [world createLogWithClient:u channel:c];
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
	self.dockUnreadCount = self.treeUnreadCount = 0;
	self.keywordCount = 0;
	self.isKeyword = self.isUnread = self.isNewTalk = NO;
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
	return NSStringEmptyPlaceholder;
}

- (NSString *)name
{
	return NSStringEmptyPlaceholder;
}

@end