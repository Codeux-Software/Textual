// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCTreeItem


- (void)resetLogView:(IRCWorld *)world
		 withChannel:(IRCChannel *)c
		   andClient:(IRCClient *)u
{
	[self.log.view close];
	
	self.log = nil;
	self.log = [world createLogWithClient:u channel:c];
	
	world.logBase.contentView = world.dummyLog.view;
	[world.dummyLog notifyDidBecomeVisible];
	
	world.logBase.contentView = [self.log view];
	[self.log notifyDidBecomeVisible];
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
	self.keywordCount = 0;
	self.dockUnreadCount = self.treeUnreadCount = 0;
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