// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCPrefix : NSObject
{
	NSString *raw;
	NSString *nick;
	NSString *user;
	NSString *address;
	
	BOOL isServer;
}

@property (strong) NSString *raw;
@property (strong) NSString *nick;
@property (strong) NSString *user;
@property (strong) NSString *address;
@property (assign) BOOL isServer;
@end