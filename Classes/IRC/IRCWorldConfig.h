// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCWorldConfig : NSObject <NSMutableCopying>
{
	NSMutableArray *clients;
}

@property (nonatomic, readonly) NSMutableArray *clients;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

@end