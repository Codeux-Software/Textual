// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TableProgressIndicator.h"

@implementation TableProgressIndicator

- (void)mouseDown:(NSEvent *)e
{
	[[self superview] mouseDown:e];
}

- (void)rightMouseDown:(NSEvent *)e
{
	[[self superview] rightMouseDown:e];
}

@end