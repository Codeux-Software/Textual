// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define MODES_SIZE		52

@interface IRCISupportInfo : NSObject
{
	NSInteger nickLen;
	NSInteger modesCount;
	
	unsigned char modes[MODES_SIZE];
}

@property (nonatomic, readonly) NSInteger nickLen;
@property (nonatomic, readonly) NSInteger modesCount;

- (void)reset;
- (BOOL)update:(NSString *)s;

- (NSArray *)parseMode:(NSString *)s;
- (IRCModeInfo *)createMode:(NSString *)mode;
@end