#import <Foundation/Foundation.h>
#import "SheetBase.h"

@interface TopicSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;

	IBOutlet NSTextField* text;
}

@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (retain) NSTextField* text;

- (void)start:(NSString*)topic;
@end

@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic;
- (void)topicSheetWillClose:(TopicSheet*)sender;
@end