#import <Cocoa/Cocoa.h>

@interface NSPasteboard (NSPasteboardHelper)
- (BOOL)hasStringContent;
- (NSString*)stringContent;
- (void)setStringContent:(NSString*)s;
@end