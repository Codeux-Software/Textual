// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class LogController, LogPolicy;

@interface LogScriptEventSink : NSObject
@property (nonatomic, unsafe_unretained) id owner;
@property (nonatomic, strong) id policy;
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end