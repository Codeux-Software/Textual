// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@class IRCClient;

@class IRCChannel;

@interface FileLogger : NSObject
{
	IRCClient* client;
	IRCChannel* channel;
	
	NSString* fileName;
	NSFileHandle* file;
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, assign) IRCChannel* channel;
@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, retain) NSFileHandle* file;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString*)s;
@end