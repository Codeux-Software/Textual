// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation InputTextField

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[[self backgroundColor] set];
	
	NSFrameRectWithWidth([self bounds], 3);
}

@end