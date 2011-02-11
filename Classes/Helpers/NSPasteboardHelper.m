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

- (NSAttributedString *)attributedStringContent
{
	NSData *rtfData = [self dataForType:NSRTFPboardType];
	
	if (rtfData) {
		NSAttributedString *attrString = [[NSAttributedString alloc] initWithRTF:rtfData documentAttributes:nil];
		
		return [attrString autorelease];
	}	
	
	return nil;
}

- (void)setAttributedStringContent:(NSAttributedString *)s
{
	NSData *stringData = [s RTFFromRange:NSMakeRange(0, [s length]) documentAttributes:nil];
	
	if (stringData) {
		[self declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
		[self setData:stringData forType:NSRTFPboardType];	
	}
}

@end