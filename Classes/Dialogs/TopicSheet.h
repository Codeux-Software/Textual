// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TopicSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;

	IBOutlet NSTextField* text;
}

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, retain) NSTextField* text;

- (void)start:(NSString*)topic;
@end

@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic;
- (void)topicSheetWillClose:(TopicSheet*)sender;
@end