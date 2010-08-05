// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class LogController;

@class LogPolicy;

@interface LogScriptEventSink : NSObject
{
	LogController* owner;
	LogPolicy* policy;
	
	NSInteger x;
	NSInteger y;
	CFAbsoluteTime lastClickTime;
}

@property (assign) id owner;
@property (retain) id policy;
@property NSInteger x;
@property NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end