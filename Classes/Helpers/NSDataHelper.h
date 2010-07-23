#import <Cocoa/Cocoa.h>

@interface NSData (NSDataHelper)
- (BOOL)isValidUTF8;
- (NSString*)validateUTF8;
- (NSString*)validateUTF8WithCharacter:(UniChar)malformChar;
@end