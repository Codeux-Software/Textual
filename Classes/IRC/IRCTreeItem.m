// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize unreadCount;
@synthesize keywordCount;
@synthesize inputHistory;
@synthesize currentInputHistory;

- (void)dealloc
{
	[log release];
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		[inputHistory release];
		[currentInputHistory release];
	}
	
	[super dealloc];
}

- (void)resetLogView:(IRCWorld *)world withChannel:(IRCChannel *)c andClient:(IRCClient *)u
{
	[[log view] close];
	 
	[log release];
	log = nil;
	
	log = [[world createLogWithClient:u channel:c] retain];
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
	keywordCount = unreadCount = 0;
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
	return @"";
}

- (NSString *)name
{
	return @"";
}

@end