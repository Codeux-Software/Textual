// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TLONickCompletionStatus

- (id)init
{
	if ((self = [super init])) {
		[self clear];
	}

	return self;
}

- (void)clear
{
	self.text = nil;
	self.range = NSMakeRange(NSNotFound, 0);
}

@end