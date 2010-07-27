// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface TimerCommand : NSObject
{
	CFAbsoluteTime time;
	NSInteger cid;
	NSString* input;
}

@property (assign) CFAbsoluteTime time;
@property (assign) NSInteger cid;
@property (copy) NSString* input;
@end