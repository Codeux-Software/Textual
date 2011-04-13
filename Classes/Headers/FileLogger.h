// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient, IRCChannel;

@interface FileLogger : NSObject
{
	IRCClient *client;
	IRCChannel *channel;
	
	NSString *filename;
	NSFileHandle *file;
}

@property (assign) IRCClient *client;
@property (assign) IRCChannel *channel;
@property (retain) NSString *filename;
@property (retain) NSFileHandle *file;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString *)s;

- (NSString *)buildPath;
- (NSString *)buildFileName;
@end