// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCMessage : NSObject
{
	NSDate *receivedAt;
	IRCPrefix *sender;
	NSString *command;
	NSInteger numericReply;
	NSMutableArray *params;
}

@property (strong) NSDate *receivedAt;
@property (strong) IRCPrefix *sender;
@property (strong) NSString *command;
@property (assign) NSInteger numericReply;
@property (strong) NSMutableArray *params;

- (id)initWithLine:(NSString *)line;

- (NSString *)paramAt:(NSInteger)index;

- (NSString *)sequence;
- (NSString *)sequence:(NSInteger)index;
@end
