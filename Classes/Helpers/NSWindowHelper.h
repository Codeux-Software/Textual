#import <Foundation/Foundation.h>

@interface NSWindow (NSWindowHelper)
- (void)centerOfWindow:(NSWindow*)window;
- (BOOL)isOnCurrentWorkspace;
- (void)centerWindow;
@end