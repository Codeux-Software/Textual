// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TimerCommand

@synthesize time;
@synthesize cid;
@synthesize input;

- (void)dealloc
{
	[input drain];
	
	[super dealloc];
}

@end