// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TVCLogScriptEventSink : NSObject
@property (nonatomic, unsafe_unretained) id owner;
@property (nonatomic, strong) id policy;
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end