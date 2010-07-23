#import "NSPasteboardHelper.h"

@implementation NSPasteboard (NSPasteboardHelper)

- (BOOL)hasStringContent
{
	return [self availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] != nil;
}

- (NSString*)stringContent
{
	return [self stringForType:NSStringPboardType];
}

- (void)setStringContent:(NSString*)s
{
	[self declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[self setString:s forType:NSStringPboardType];
}

@end