// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@implementation IRCPrefix

@synthesize raw;
@synthesize nick;
@synthesize user;
@synthesize address;
@synthesize isServer;

- (id)init
{
	if ((self = [super init])) {
		self.raw = NSNullObject;
		self.nick = NSNullObject;
		self.user = NSNullObject;
		self.address = NSNullObject;
	}

	return self;
}

@end