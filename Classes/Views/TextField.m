// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextField.h"

@implementation TextField

- (void)focus
{
	[self.window makeFirstResponder:self];
	NSText *e = [self currentEditor];
	[e setSelectedRange:NSMakeRange([[self stringValue] length], 0)];
	[e scrollRangeToVisible:[e selectedRange]];
}

@end