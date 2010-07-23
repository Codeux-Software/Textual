#import <Cocoa/Cocoa.h>

@interface IconManager : NSObject

- (void)drawBlankApplicationIcon;
- (NSString*)badgeFilename:(NSInteger)count;
- (void)drawApplicationIcon:(NSInteger)hlcount msgcount:(NSInteger)pmcount;

@end