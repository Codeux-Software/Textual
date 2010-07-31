// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCChannelConfig.h"
#import "NSDictionaryHelper.h"

@implementation IRCChannelConfig

@synthesize type;
@synthesize name;
@synthesize password;
@synthesize autoJoin;
@synthesize growl;
@synthesize mode;
@synthesize topic;

- (id)init
{
	if (self = [super init]) {
		type = CHANNEL_TYPE_CHANNEL;
		
		autoJoin = YES;
		growl = YES;
		
		name = @"";
		mode = @"";
		topic = @"";
		password = @"";
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	[self init];
	
	type = [dic intForKey:@"type"];
	
	name = [[dic stringForKey:@"name"] retain] ?: @"";
	password = [[dic stringForKey:@"password"] retain] ?: @"";
	
	growl = [dic boolForKey:@"growl"];
	autoJoin = [dic boolForKey:@"auto_join"];
	
	mode = [[dic stringForKey:@"mode"] retain] ?: @"";
	topic = [[dic stringForKey:@"topic"] retain] ?: @"";
	
	return self;
}

- (void)dealloc
{
	[name release];
	[password release];
	
	[mode release];
	[topic release];
	
	[super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	[dic setInt:type forKey:@"type"];
	
	if (name) [dic setObject:name forKey:@"name"];
	if (password) [dic setObject:password forKey:@"password"];
	
	[dic setBool:growl forKey:@"growl"];
	[dic setBool:autoJoin forKey:@"auto_join"];
	
	if (mode) [dic setObject:mode forKey:@"mode"];
	if (topic) [dic setObject:topic forKey:@"topic"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end