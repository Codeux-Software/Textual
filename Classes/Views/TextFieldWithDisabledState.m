// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextFieldWithDisabledState.h"

@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	[self setTextColor:value ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
}

@end