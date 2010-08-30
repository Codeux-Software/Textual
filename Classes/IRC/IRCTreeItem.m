// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCTreeItem.h"
#import "IRCWorld.h"
#import "InputHistory.h"

@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize unreadCount;
@synthesize keywordCount;
@synthesize inputHistory;

- (void)dealloc
{
	[log release];
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		[inputHistory release];
	}
	
	[super dealloc];
}

- (void)resetLogView:(IRCWorld*)world withChannel:(IRCChannel*)c andClient:(IRCClient*)u
{
	[log release];
	log = nil;
	
	log = [[world createLogWithClient:u channel:c] retain];
	
	if (c) {
		[log setTopic:c.topic];
	}
}

- (IRCClient*)client
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
	isKeyword = isUnread = isNewTalk = NO;
	keywordCount = unreadCount = 0;
}

- (NSInteger)numberOfChildren
{
	return 0;
}

- (IRCTreeItem*)childAtIndex:(NSInteger)index
{
	return nil;
}

- (NSString*)label
{
	return @"";
}

- (NSString*)name
{
	return @"";
}

@end