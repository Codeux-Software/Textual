// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@class IRCModeInfo;

@interface IRCChannelMode : NSObject <NSMutableCopying>
@property (nonatomic, weak) IRCISupportInfo *isupport;
@property (nonatomic, strong) NSMutableArray *allModes;
@property (nonatomic, strong) NSMutableDictionary *modeIndexes;

- (void)clear;

- (NSArray *)update:(NSString *)str;
- (IRCModeInfo *)modeInfoFor:(NSString *)mode;

- (NSString *)string;
- (NSString *)titleString;
- (NSString *)getChangeCommand:(IRCChannelMode *)mode;

- (BOOL)modeIsDefined:(NSString *)mode;
@end