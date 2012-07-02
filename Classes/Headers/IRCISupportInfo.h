// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXModesSize		52

@interface IRCISupportInfo : NSObject
{
	unsigned char modes[TXModesSize];
}

@property (nonatomic, assign) NSInteger nickLen;
@property (nonatomic, assign) NSInteger modesCount;
@property (nonatomic, strong) NSString *networkName;
@property (nonatomic, strong) NSString *userModeQPrefix;
@property (nonatomic, strong) NSString *userModeAPrefix;
@property (nonatomic, strong) NSString *userModeOPrefix;
@property (nonatomic, strong) NSString *userModeHPrefix;
@property (nonatomic, strong) NSString *userModeVPrefix;

- (void)reset;
- (BOOL)update:(NSString *)s client:(IRCClient *)client;

- (NSArray *)parseMode:(NSString *)s;
- (IRCModeInfo *)createMode:(NSString *)mode;
@end
