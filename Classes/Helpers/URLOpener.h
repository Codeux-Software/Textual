#import <Cocoa/Cocoa.h>

@interface URLOpener : NSObject
+ (void)open:(NSURL*)url;
+ (void)openAndActivate:(NSURL*)url;
@end