// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TimerCommand.h"

@implementation TimerCommand

@synthesize time;
@synthesize cid;
@synthesize input;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[input release];
	[super dealloc];
}

@end