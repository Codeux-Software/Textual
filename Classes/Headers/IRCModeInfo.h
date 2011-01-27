// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCModeInfo : NSObject
{
	unsigned char mode;
	
	BOOL op;
	BOOL plus;
	BOOL simpleMode;
	
	NSString *param;
}

@property (nonatomic, assign) unsigned char mode;
@property (nonatomic, assign) BOOL op;
@property (nonatomic, assign) BOOL plus;
@property (nonatomic, assign) BOOL simpleMode;
@property (nonatomic, retain) NSString *param;

+ (IRCModeInfo *)modeInfo;
@end