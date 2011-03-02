// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSColor (NSColorHelper)
+ (NSColor *)formatterWhiteColor;
+ (NSColor *)formatterBlackColor;
+ (NSColor *)formatterNavyBlueColor;
+ (NSColor *)formatterDarkGreenColor;
+ (NSColor *)formatterRedColor;
+ (NSColor *)formatterBrownColor;
+ (NSColor *)formatterPurpleColor;
+ (NSColor *)formatterOrangeColor;
+ (NSColor *)formatterYellowColor;
+ (NSColor *)formatterLimeGreenColor;
+ (NSColor *)formatterTealColor;
+ (NSColor *)formatterAquaCyanColor;
+ (NSColor *)formatterLightBlueColor;
+ (NSColor *)formatterFuchsiaPinkColor;
+ (NSColor *)formatterNormalGrayColor;
+ (NSColor *)formatterLightGrayColor;

- (NSString *)hexadecimalValue;
+ (NSColor *)fromCSS:(NSString *)str;
@end