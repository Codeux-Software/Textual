// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
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

@property (nonatomic, assign) unsigned char mode;
@property (nonatomic, assign) BOOL plus;
@property (nonatomic, assign) BOOL op;
@property (nonatomic, assign) BOOL simpleMode;
@property (nonatomic, retain) NSString* param;

+ (IRCModeInfo*)modeInfo;
@end

@interface IRCISupportInfo : NSObject
{
	NSInteger nickLen;
	NSInteger modesCount;
	
	unsigned char modes[MODES_SIZE];
}

@property (nonatomic, readonly) NSInteger nickLen;
@property (nonatomic, readonly) NSInteger modesCount;

- (void)reset;
- (BOOL)update:(NSString*)s;
- (NSArray*)parseMode:(NSString*)s;
- (IRCModeInfo*)createMode:(NSString*)mode;
@end