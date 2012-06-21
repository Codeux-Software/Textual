// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCModeInfo

@synthesize mode;
@synthesize op;
@synthesize plus;
@synthesize simpleMode;
@synthesize param;

+ (IRCModeInfo *)modeInfo
{
	return [IRCModeInfo new];
}

@end