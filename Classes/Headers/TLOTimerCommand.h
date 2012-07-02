// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TLOTimerCommand : NSObject
@property (nonatomic, assign) CFAbsoluteTime time;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *input;
@end