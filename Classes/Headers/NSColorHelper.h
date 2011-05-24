// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define NSCalibratedRBGColor(r, b, g)		([NSColor _colorWithCalibratedRed:r green:g blue:b alpha:1.0])

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

+ (NSArray *)possibleFormatterColors;

- (NSString *)hexadecimalValue;
+ (NSColor *)fromCSS:(NSString *)str;

+ (NSColor *)outlineViewHeaderTextColor;
+ (NSColor *)_colorWithSRGBRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (NSColor *)_colorWithCalibratedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
@end