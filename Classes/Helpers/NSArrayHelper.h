#import <Cocoa/Cocoa.h>

@interface NSArray (NSArrayHelper)
- (id)safeObjectAtIndex:(NSInteger)n;
@end