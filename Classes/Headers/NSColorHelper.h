// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define TXCalibratedRBGColor(r, b, g)		([NSColor internalCalibratedRed:r green:g blue:b alpha:1.0])
#define TXInvertSidebarColor(c)				c // Deprecated, 2.1.1

@interface NSColor (TXColorHelper)
- (NSColor *)invertColor;

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

+ (NSColor *)sourceListBackgroundColor;
+ (NSColor *)outlineViewHeaderTextColor;
+ (NSColor *)outlineViewHeaderDisabledTextColor;

+ (NSColor *)internalColorWithSRGBRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (NSColor *)internalCalibratedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
@end