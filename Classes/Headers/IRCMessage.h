// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCMessage : NSObject
{
	IRCPrefix *sender;
	NSString *command;
	NSInteger numericReply;
	NSMutableArray *params;
}

@property (nonatomic, retain) IRCPrefix *sender;
@property (nonatomic, retain) NSString *command;
@property (nonatomic, assign) NSInteger numericReply;
@property (nonatomic, retain) NSMutableArray *params;

- (id)initWithLine:(NSString *)line;

- (NSString *)paramAt:(NSInteger)index;

- (NSString *)sequence;
- (NSString *)sequence:(NSInteger)index;
@end