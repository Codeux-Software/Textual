#import "NSArrayHelper.h"

@implementation NSArray (NSArrayHelper)

- (id)safeObjectAtIndex:(NSInteger)n
{
	if (n >= 0 && n < self.count) {
		return [self objectAtIndex:n];
	}
	
	return nil;
}

@end