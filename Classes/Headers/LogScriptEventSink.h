// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class LogController, LogPolicy;

@interface LogScriptEventSink : NSObject
@property (unsafe_unretained) id owner;
@property (strong) id policy;
@property (assign) NSInteger x;
@property (assign) NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end