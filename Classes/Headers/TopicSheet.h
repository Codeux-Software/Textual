// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TopicSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;

	IBOutlet TextField *text;
}

@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (retain) TextField *text;

- (void)start:(NSString *)topic;
@end

@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet *)sender onOK:(NSString *)topic;
- (void)topicSheetWillClose:(TopicSheet *)sender;
@end