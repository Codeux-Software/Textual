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

@property (retain) NSString *raw;
@property (retain) NSString *nick;
@property (retain) NSString *user;
@property (retain) NSString *address;
@property (assign) BOOL isServer;
@end