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

@property (nonatomic, retain) NSString *raw;
@property (nonatomic, retain) NSString *nick;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, assign) BOOL isServer;
@end