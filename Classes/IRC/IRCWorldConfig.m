// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation IRCWorldConfig

- (id)init
{
	if ((self = [super init])) {
		self.clients = [NSMutableArray new];
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		NSArray *ary = [dic arrayForKey:@"clients"];
		
		for (NSDictionary *e in ary) {
			IRCClientConfig *c = [[IRCClientConfig alloc] initWithDictionary:e];
			
			[self.clients safeAddObject:c];
		}
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	NSMutableArray *clientAry = [NSMutableArray array];
	
	for (IRCClientConfig *e in self.clients) {
		[clientAry safeAddObject:[e dictionaryValue]];
	}
	
	dic[@"clients"] = clientAry;
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCWorldConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end