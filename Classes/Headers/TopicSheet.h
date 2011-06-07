// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TopicSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;

	IBOutlet TextField   *text;
	IBOutlet NSTextField *header;
}

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, retain) TextField *text;
@property (nonatomic, retain) NSTextField *header;

- (void)start:(NSString *)topic;
@end

@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet *)sender onOK:(NSString *)topic;
- (void)topicSheetWillClose:(TopicSheet *)sender;
@end