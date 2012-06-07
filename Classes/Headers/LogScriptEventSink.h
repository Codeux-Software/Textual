// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@class LogController, LogPolicy;

@interface LogScriptEventSink : NSObject
{
	LogController *__unsafe_unretained owner;
	LogPolicy *policy;
	
	NSInteger x;
	NSInteger y;
    
	CFAbsoluteTime lastClickTime;
}

@property (nonatomic, unsafe_unretained) id owner;
@property (nonatomic, strong) id policy;
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end