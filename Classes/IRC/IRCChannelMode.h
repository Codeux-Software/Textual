// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCChannelMode : NSObject <NSMutableCopying>
{
	IRCISupportInfo *isupport;
	NSMutableArray *allModes;
	NSMutableDictionary *modeIndexes;
}

@property (nonatomic, retain) IRCISupportInfo *isupport;
@property (nonatomic, readonly) NSMutableArray *allModes;
@property (nonatomic, readonly) NSMutableDictionary *modeIndexes;

- (void)clear;
- (NSArray *)update:(NSString *)str;

- (NSString *)getChangeCommand:(IRCChannelMode *)mode;

- (NSString *)string;
- (NSString *)titleString;

- (BOOL)modeIsDefined:(NSString *)mode;
- (IRCModeInfo *)modeInfoFor:(NSString *)mode;
@end