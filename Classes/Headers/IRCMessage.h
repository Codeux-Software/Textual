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

@property (nonatomic, strong) NSDate *receivedAt;
@property (nonatomic, strong) IRCPrefix *sender;
@property (nonatomic, strong) NSString *command;
@property (nonatomic, assign) NSInteger numericReply;
@property (nonatomic, strong) NSMutableArray *params;

- (id)initWithLine:(NSString *)line;

- (NSString *)paramAt:(NSInteger)index;

- (NSString *)sequence;
- (NSString *)sequence:(NSInteger)index;
@end
