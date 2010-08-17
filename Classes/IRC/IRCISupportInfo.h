// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

#define MODES_SIZE	52

@interface IRCModeInfo : NSObject
{
	unsigned char mode;
	BOOL plus;
	BOOL op;
	BOOL simpleMode;
	NSString* param;
}

@property (assign) unsigned char mode;
@property (assign) BOOL plus;
@property (assign) BOOL op;
@property (assign) BOOL simpleMode;
@property (retain) NSString* param;

+ (IRCModeInfo*)modeInfo;
@end

@interface IRCISupportInfo : NSObject
{
	NSInteger nickLen;
	NSInteger modesCount;
	
	unsigned char modes[MODES_SIZE];
}

@property (readonly) NSInteger nickLen;
@property (readonly) NSInteger modesCount;

- (void)reset;
- (BOOL)update:(NSString*)s;
- (NSArray*)parseMode:(NSString*)s;
- (IRCModeInfo*)createMode:(NSString*)mode;
@end