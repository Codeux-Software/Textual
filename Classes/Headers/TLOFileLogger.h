// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TLOFileLogger : NSObject
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) IRCChannel *channel;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSFileHandle *file;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString *)s;

- (NSString *)buildPath;
- (NSString *)buildFileName;
@end