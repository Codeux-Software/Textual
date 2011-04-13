// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define MODES_SIZE		52

@interface IRCISupportInfo : NSObject
{
	NSInteger nickLen;
	NSInteger modesCount;
	
	NSString *networkName;
	
	NSString *userModeQPrefix;
	NSString *userModeAPrefix;
	NSString *userModeOPrefix;
	NSString *userModeHPrefix;
	NSString *userModeVPrefix;
	
	unsigned char modes[MODES_SIZE];
}

@property (readonly) NSInteger nickLen;
@property (readonly) NSInteger modesCount;
@property (retain) NSString *networkName;
@property (retain) NSString *userModeQPrefix;
@property (retain) NSString *userModeAPrefix;
@property (retain) NSString *userModeOPrefix;
@property (retain) NSString *userModeHPrefix;
@property (retain) NSString *userModeVPrefix;

- (void)reset;
- (BOOL)update:(NSString *)s;

- (NSArray *)parseMode:(NSString *)s;
- (IRCModeInfo *)createMode:(NSString *)mode;
@end