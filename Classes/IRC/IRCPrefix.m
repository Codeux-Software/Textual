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
		raw = NSNullObject;
		nick = NSNullObject;
		user = NSNullObject;
		address = NSNullObject;
	}

	return self;
}

- (void)dealloc
{
	[raw drain];
	[nick drain];
	[user drain];
	[address drain];
	
	[super dealloc];
}

@end