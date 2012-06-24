// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCChannelConfig

- (id)init
{
	if ((self = [super init])) {
		self.type = IRCChannelNormalType;
		
        self.ignoreInlineImages	= NO;
        self.ignoreJPQActivity	= NO;
        self.ignoreHighlights	= NO;
		self.autoJoin			= YES;
		self.growl				= YES;
		
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
		dic = [TPCPreferencesMigrationAssistant convertIRCChannelConfiguration:dic];
		
		self.type			= (IRCChannelType)[dic integerForKey:@"channelType"];
		
		self.name			= (([dic stringForKey:@"channelName"])	 ?: NSStringEmptyPlaceholder);
		self.password		= (([dic stringForKey:@"secretJoinKey"]) ?: NSStringEmptyPlaceholder);
		
		self.growl				= [dic boolForKey:@"enableNotifications"];
		self.autoJoin			= [dic boolForKey:@"joinOnConnect"];
		self.ignoreHighlights	= [dic boolForKey:@"ignoreHighlights"];
		self.ignoreInlineImages	= [dic boolForKey:@"disableInlineMedia"];
		self.ignoreJPQActivity	= [dic boolForKey:@"ignoreJPQActivity"];
		
		self.mode			= (([dic stringForKey:@"defaultMode"])		?: NSStringEmptyPlaceholder);
		self.topic			= (([dic stringForKey:@"defaultTopic"])		?: NSStringEmptyPlaceholder);
		self.encryptionKey	= (([dic stringForKey:@"encryptionKey"])	?: NSStringEmptyPlaceholder);
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.type forKey:@"channelType"];
	
	[dic setBool:self.growl					forKey:@"enableNotifications"];
	[dic setBool:self.autoJoin				forKey:@"joinOnConnect"];
    [dic setBool:self.ignoreHighlights		forKey:@"ignoreHighlights"];
    [dic setBool:self.ignoreInlineImages	forKey:@"disableInlineMedia"];
    [dic setBool:self.ignoreJPQActivity		forKey:@"ignoreJPQActivity"];
	
	[dic safeSetObject:self.name				forKey:@"channelName"];
	[dic safeSetObject:self.password			forKey:@"secretJoinKey"];
	[dic safeSetObject:self.mode				forKey:@"defaultMode"];
	[dic safeSetObject:self.topic				forKey:@"defaultTopic"];
	[dic safeSetObject:self.encryptionKey		forKey:@"encryptionKey"];

	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return [dic sortedDictionary];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end