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

@property (assign) unsigned char mode;
@property (assign) BOOL op;
@property (assign) BOOL plus;
@property (assign) BOOL simpleMode;
@property (retain) NSString *param;

+ (IRCModeInfo *)modeInfo;
@end