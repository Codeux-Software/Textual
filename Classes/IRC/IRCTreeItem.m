#import "IRCTreeItem.h"

@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize unreadCount;
@synthesize keywordCount;

- (void)dealloc
{
	[log release];
	[super dealloc];
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