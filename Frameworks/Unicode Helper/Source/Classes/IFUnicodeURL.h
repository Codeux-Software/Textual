
// Created by Sean Heber on 4/22/10.

@interface NSURL (IFUnicodeURL)
+ (NSURL *)URLWithUnicodeString:(NSString *)str;

- (NSString *)unicodeAbsoluteString;
- (NSString *)unicodeHost;
@end
