// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	NSColor *color = ((value) ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]);
	
	[super setEnabled:value];
	[self setTextColor:color];
}

@end