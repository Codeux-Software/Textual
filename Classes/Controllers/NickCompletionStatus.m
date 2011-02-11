// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NickCompletionStatus

@synthesize text;
@synthesize range;

- (id)init
{
	if ((self = [super init])) {
		[self clear];
	}

	return self;
}

- (void)dealloc
{
	[text drain];
	
	[super dealloc];
}

- (void)clear
{
	self.text = nil;
	
	range = NSMakeRange(NSNotFound, 0);
}

@end