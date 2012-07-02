// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCTopicSheet : TDCSheetBase
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, strong) TVCTextField *text;
@property (nonatomic, strong) NSTextField *header;

- (void)start:(NSString *)topic;
@end

@interface NSObject (TXTopicSheetDelegate)
- (void)topicSheet:(TDCTopicSheet *)sender onOK:(NSString *)topic;
- (void)topicSheetWillClose:(TDCTopicSheet *)sender;
@end