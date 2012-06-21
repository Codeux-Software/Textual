// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCChannelConfig

@synthesize type;
@synthesize name;
@synthesize password;
@synthesize autoJoin;
@synthesize growl;
@synthesize mode;
@synthesize topic;
@synthesize ihighlights;
@synthesize encryptionKey;
@synthesize iJPQActivity;
@synthesize inlineImages;

- (id)init
{
	if ((self = [super init])) {
		self.type = IRCChannelNormalType;
		
        self.inlineImages	= NO;
        self.iJPQActivity	= NO;
        self.ihighlights	= NO;
		self.autoJoin		= YES;
		self.growl			= YES;
		
		self.name			= NSStringEmptyPlaceholder;
		self.mode			= NSStringEmptyPlaceholder;
		self.topic			= NSStringEmptyPlaceholder;
		self.password		= NSStringEmptyPlaceholder;
		self.encryptionKey	= NSStringEmptyPlaceholder;
	}
    
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		self.type			= (IRCChannelType)[dic integerForKey:@"type"];
		
		self.name			= (([dic stringForKey:@"name"]) ?: NSStringEmptyPlaceholder);
		self.password		= (([dic stringForKey:@"password"]) ?: NSStringEmptyPlaceholder);
		
		self.growl			= [dic boolForKey:@"growl"];
		self.autoJoin		= [dic boolForKey:@"auto_join"];
		self.ihighlights	= [dic boolForKey:@"ignore_highlights"];
		self.inlineImages	= [dic boolForKey:@"disable_images"];
		self.iJPQActivity	= [dic boolForKey:@"ignore_join,leave"];
		
		self.mode			= (([dic stringForKey:@"mode"]) ?: NSStringEmptyPlaceholder);
		self.topic			= (([dic stringForKey:@"topic"]) ?: NSStringEmptyPlaceholder);
		self.encryptionKey	= (([dic stringForKey:@"encryptionKey"]) ?: NSStringEmptyPlaceholder);
		
		return self;
	}
	
	return nil;
}


- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.type forKey:@"type"];
	
	[dic setBool:self.growl			forKey:@"growl"];
	[dic setBool:self.autoJoin		forKey:@"auto_join"];
    [dic setBool:self.ihighlights	forKey:@"ignore_highlights"];
    [dic setBool:self.inlineImages	forKey:@"disable_images"];
    [dic setBool:self.iJPQActivity	forKey:@"ignore_join,leave"];
	
	if (self.name)			[dic setObject:self.name			forKey:@"name"];
	if (self.password)		[dic setObject:self.password		forKey:@"password"];
	if (self.mode)			[dic setObject:self.mode			forKey:@"mode"];
	if (self.topic)			[dic setObject:self.topic			forKey:@"topic"];
	if (self.encryptionKey)	[dic setObject:self.encryptionKey	forKey:@"encryptionKey"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end