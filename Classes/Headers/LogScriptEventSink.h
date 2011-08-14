// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@class LogController, LogPolicy;

@interface LogScriptEventSink : NSObject
{
	LogController *owner;
	LogPolicy *policy;
	
	NSInteger x;
	NSInteger y;
    
	CFAbsoluteTime lastClickTime;
}

@property (nonatomic, assign) id owner;
@property (nonatomic, retain) id policy;
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end