// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation NSPasteboard (TXPasteboardHelper)

- (NSArray *)pasteboardStringType
{
	return @[NSStringPboardType];
}

- (NSString *)stringContent
{
	return [self stringForType:NSStringPboardType];
}

- (void)setStringContent:(NSString *)s
{
	[self declareTypes:[self pasteboardStringType] owner:nil];
	
	[self setString:s forType:NSStringPboardType];
}

@end