/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation NSColor (TXColorHelper)

#pragma mark -
#pragma mark Custom Methods

+ (NSColor *)internalColorWithSRGBRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	CGFloat comps[] = {red, green, blue, alpha};

	return [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace] components:comps count:4];
}

+ (NSColor *)internalCalibratedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	if (red   > 1.0) red   = (red   / 255.99999f);
	if (green > 1.0) green = (green / 255.99999f);
	if (blue  > 1.0) blue  = (blue  / 255.99999f);

	return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

- (NSColor *)invertColor
{
	NSColor *obj = [self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];

	CGFloat red   = [obj redComponent];
	CGFloat green = [obj greenComponent];
	CGFloat blue  = [obj blueComponent];
	CGFloat alpha = [obj alphaComponent];

	return [NSColor colorWithCalibratedRed:(1.0 - red)
									 green:(1.0 - green)
									  blue:(1.0 - blue)
									 alpha:alpha];
}

#pragma mark -
#pragma mark IRC Text Formatting Color Codes

+ (NSColor *)formatterWhiteColor
{
	return TXCalibratedRGBColor(1.00, 1.00, 1.00);
}

+ (NSColor *)formatterBlackColor
{
	return TXCalibratedRGBColor(0.00, 0.00, 0.00);
}

+ (NSColor *)formatterNavyBlueColor
{
	return TXCalibratedRGBColor(0.04, 0.00, 0.52);
}

+ (NSColor *)formatterDarkGreenColor
{
	return TXCalibratedRGBColor(0.00, 0.54, 0.08);
}

+ (NSColor *)formatterRedColor
{
	return TXCalibratedRGBColor(1.00, 0.05, 0.04);
}

+ (NSColor *)formatterBrownColor
{
	return TXCalibratedRGBColor(0.55, 0.02, 0.02);
}

+ (NSColor *)formatterPurpleColor
{
	return TXCalibratedRGBColor(0.55, 0.00, 0.53);
}

+ (NSColor *)formatterOrangeColor
{
	return TXCalibratedRGBColor(1.00, 0.54, 0.09);
}

+ (NSColor *)formatterYellowColor
{
	return TXCalibratedRGBColor(1.00, 1.00, 0.15);
}

+ (NSColor *)formatterLimeGreenColor
{
	return TXCalibratedRGBColor(0.00, 1.00, 0.15);
}

+ (NSColor *)formatterTealColor
{
	return TXCalibratedRGBColor(0.00, 0.53, 0.53);
}

+ (NSColor *)formatterAquaCyanColor
{
	return TXCalibratedRGBColor(0.00, 1.00, 1.00);
}

+ (NSColor *)formatterLightBlueColor
{
	return TXCalibratedRGBColor(0.07, 0.00, 0.98);
}

+ (NSColor *)formatterFuchsiaPinkColor
{
	return TXCalibratedRGBColor(1.00, 0.00, 0.98);
}

+ (NSColor *)formatterNormalGrayColor
{
	return TXCalibratedRGBColor(0.53, 0.53, 0.53);
}

+ (NSColor *)formatterLightGrayColor
{
	return TXCalibratedRGBColor(0.80, 0.80, 0.80);
}

+ (NSArray *)possibleFormatterColors
{
	return @[
	@[[self formatterWhiteColor]],
	@[[self formatterBlackColor]],
	@[[self formatterNavyBlueColor],	TXCalibratedRGBColor(0.0, 0.0, 0.47)],
	@[[self formatterDarkGreenColor],	TXCalibratedRGBColor(0.03, 0.48, 0.0)],
	@[[self formatterRedColor],			TXCalibratedRGBColor(1.00, 0.00, 0.00)],
	@[[self formatterBrownColor],		TXCalibratedRGBColor(0.46, 0.00, 0.00)],
	@[[self formatterPurpleColor],		TXCalibratedRGBColor(0.46, 0.00, 0.47)],
	@[[self formatterOrangeColor],		TXCalibratedRGBColor(1.00, 0.45, 0.00)],
	@[[self formatterYellowColor],		TXCalibratedRGBColor(1.00, 1.00, 0.00)],
	@[[self formatterLimeGreenColor],	TXCalibratedRGBColor(0.06, 1.00, 0.00)],
	@[[self formatterTealColor],		TXCalibratedRGBColor(0.00, 0.46, 0.46)],
	@[[self formatterAquaCyanColor]],
	@[[self formatterLightBlueColor],	TXCalibratedRGBColor(0.00, 0.00, 1.00)],
	@[[self formatterFuchsiaPinkColor], TXCalibratedRGBColor(1.00, 0.00, 1.00)],
	@[[self formatterNormalGrayColor],	TXCalibratedRGBColor(0.46, 0.46, 0.46)],
	@[[self formatterLightGrayColor]]
	];
}

#pragma mark -
#pragma mark Hexadeciam Conversion

- (NSString *)hexadecimalValue
{
	NSInteger redIntValue,   greenIntValue,   blueIntValue;
	CGFloat   redFloatValue, greenFloatValue, blueFloatValue;
	NSString *redHexValue,  *greenHexValue,  *blueHexValue;

	NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if (convertedColor) {
		[convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];

		redIntValue   = (redFloatValue   * 255.99999f);
		greenIntValue = (greenFloatValue * 255.99999f);
		blueIntValue  = (blueFloatValue  * 255.99999f);

		redHexValue   = [NSString stringWithFormat:@"%02d", redIntValue];
		greenHexValue = [NSString stringWithFormat:@"%02d", greenIntValue];
		blueHexValue  = [NSString stringWithFormat:@"%02d", blueIntValue];

		return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
	}

	return nil;
}

+ (NSColor *)fromCSS:(NSString *)s
{
	if ([s hasPrefix:@"#"]) {
		s = [s safeSubstringFromIndex:1];

		NSInteger len = s.length;

		if (len == 6) {
			long n = strtol([s UTF8String], NULL, 16);

			NSInteger r = ((n >> 16) & 0xff);
			NSInteger g = ((n >> 8) & 0xff);
			NSInteger b = (n & 0xff);

			return TXCalibratedRGBColor(r, b, g);
		} else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);

			NSInteger r = ((n >> 8) & 0xf);
			NSInteger g = ((n >> 4) & 0xf);
			NSInteger b = (n & 0xf);

			return TXCalibratedRGBColor((r / 15.0),
										(g / 15.0),
										(b / 15.0));
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Other Colors

+ (NSColor *)sourceListBackgroundColor
{
	return [NSColor colorWithCatalogName:@"System" colorName:@"_sourceListBackgroundColor"];
}

+ (NSColor *)outlineViewHeaderTextColor
{
	return [self internalColorWithSRGBRed:0.439216 green:0.494118 blue:0.54902 alpha:1.0];
}

+ (NSColor *)outlineViewHeaderDisabledTextColor
{
	return [self internalColorWithSRGBRed:0.439216 green:0.494118 blue:0.54902 alpha:0.7];
}

@end