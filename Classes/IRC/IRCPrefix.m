// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCPrefix


- (id)init
{
	if ((self = [super init])) {
		self.raw		= NSStringEmptyPlaceholder;
		self.nick		= NSStringEmptyPlaceholder;
		self.user		= NSStringEmptyPlaceholder;
		self.address	= NSStringEmptyPlaceholder;
	}

	return self;
}

@end