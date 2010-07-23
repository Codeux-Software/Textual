#import <Foundation/Foundation.h>

@interface UnicodeHelper : NSObject
+ (BOOL)isPrivate:(UniChar)c;
+ (BOOL)isIdeographic:(UniChar)c;
+ (BOOL)isIdeographicOrPrivate:(UniChar)c;
+ (BOOL)isAlphabeticalCodePoint:(NSInteger)c;
@end