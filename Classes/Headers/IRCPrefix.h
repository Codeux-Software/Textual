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

@property (nonatomic, strong) NSString *raw;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) BOOL isServer;
@end