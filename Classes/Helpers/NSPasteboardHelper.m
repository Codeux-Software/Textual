// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSPasteboard (NSPasteboardHelper)

- (BOOL)hasStringContent
{
	return BOOLReverseValue(PointerIsEmpty([self availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]]));
}

- (NSString *)stringContent
{
	return [self stringForType:NSStringPboardType];
}

- (void)setStringContent:(NSString *)s
{
	[self declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[self setString:s forType:NSStringPboardType];
}

@end