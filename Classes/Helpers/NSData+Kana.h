#import <Foundation/Foundation.h>

@interface NSData (Kana)
- (NSData*)convertKanaFromISO2022ToNative;
- (NSData*)convertKanaFromNativeToISO2022;
@end