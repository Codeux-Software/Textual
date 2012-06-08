// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface TimerCommand : NSObject
{
	NSInteger cid;
	
	NSString *input;
	
	CFAbsoluteTime time;
}

@property (assign) CFAbsoluteTime time;
@property (assign) NSInteger cid;
@property (copy) NSString *input;
@end