// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient, IRCChannel;

@interface FileLogger : NSObject
{
	IRCClient *__weak client;
	IRCChannel *__weak channel;
	
	NSString *filename;
	NSFileHandle *file;
}

@property (weak) IRCClient *client;
@property (weak) IRCChannel *channel;
@property (strong) NSString *filename;
@property (strong) NSFileHandle *file;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString *)s;

- (NSString *)buildPath;
- (NSString *)buildFileName;
@end