// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCWorldConfig

@synthesize clients;

- (id)init
{
	if ((self = [super init])) {
		clients = [NSMutableArray new];
	}
    
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if (!(self = [self init])) return nil;
    
    NSArray *ary = [dic arrayForKey:@"clients"];
    
    for (NSDictionary *e in ary) {
        IRCClientConfig *c = [[IRCClientConfig alloc] initWithDictionary:e];
        
        [clients safeAddObject:c];
    }
    
    return self;
}


- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	NSMutableArray *clientAry = [NSMutableArray array];
	
	for (IRCClientConfig *e in clients) {
		[clientAry safeAddObject:[e dictionaryValue]];
	}
	
	[dic setObject:clientAry forKey:@"clients"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCWorldConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end