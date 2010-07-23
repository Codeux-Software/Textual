#import <Cocoa/Cocoa.h>

@class IRCClient;
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

@end