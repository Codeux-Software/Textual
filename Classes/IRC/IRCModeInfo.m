// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCModeInfo

@synthesize mode;
@synthesize op;
@synthesize plus;
@synthesize simpleMode;
@synthesize param;

+ (IRCModeInfo *)modeInfo
{
	return [IRCModeInfo newad];
}

- (void)dealloc
{
	[param drain];
	
	[super dealloc];
}

@end