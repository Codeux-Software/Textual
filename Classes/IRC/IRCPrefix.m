// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCPrefix

@synthesize raw;
@synthesize nick;
@synthesize user;
@synthesize address;
@synthesize isServer;

- (id)init
{
	if ((self = [super init])) {
		raw = @"";
		nick = @"";
		user = @"";
		address = @"";
	}

	return self;
}

- (void)dealloc
{
	[raw release];
	[nick release];
	[user release];
	[address release];
	[super dealloc];
}

@end