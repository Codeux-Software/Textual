/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#define TXCalibratedRGBColor(r, g, b)		([NSColor internalCalibratedRed:r green:g blue:b alpha:1.0])
#define TXCalibratedDeviceColor(r, g, b)	([NSColor internalDeviceRed:r green:g blue:b alpha:1.0])

@implementation NSColor (TXColorHelper)

#pragma mark -
#pragma mark Custom Methods

+ (NSColor *)internalCalibratedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	if (red   > 1.0) {
		red /= 255.99999f;
	}
	
	if (green > 1.0) {
		green /= 255.99999f;
	}
	
	if (blue  > 1.0) {
		blue  /= 255.99999f;
	}

	return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

+ (NSColor *)internalDeviceRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	if (red   > 1.0) {
		red /= 255.99999f;
	}
	
	if (green > 1.0) {
		green /= 255.99999f;
	}
	
	if (blue  > 1.0) {
		blue  /= 255.99999f;
	}
	
	return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}

- (NSColor *)invertColor
{
	NSColor *obj = [self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];

	return [NSColor colorWithCalibratedRed:(1.0 - [obj redComponent])
									 green:(1.0 - [obj greenComponent])
									  blue:(1.0 - [obj blueComponent])
									 alpha:[obj alphaComponent]];
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
		[self formatterWhiteColor],
		[self formatterBlackColor],
		[self formatterNavyBlueColor],
		[self formatterDarkGreenColor],
		[self formatterRedColor],
		[self formatterBrownColor],
		[self formatterPurpleColor],
		[self formatterOrangeColor],
		[self formatterYellowColor],
		[self formatterLimeGreenColor],
		[self formatterTealColor],
		[self formatterAquaCyanColor],
		[self formatterLightBlueColor],
		[self formatterFuchsiaPinkColor],
		[self formatterNormalGrayColor],
		[self formatterLightGrayColor]
	];
}

#pragma mark -
#pragma mark Hexadeciam Conversion

+ (NSColor *)fromCSS:(NSString *)s
{
	if ([s hasPrefix:@"#"]) {
		s = [s substringFromIndex:1];

		NSInteger len = [s length];

		if (len == 6) {
			long n = strtol([s UTF8String], NULL, 16);

			NSInteger r = ((n >> 16) & 0xff);
			NSInteger g = ((n >> 8) & 0xff);
			NSInteger b = (n & 0xff);

			return TXCalibratedDeviceColor(r, b, g);
		} else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);

			NSInteger r = ((n >> 8) & 0xf);
			NSInteger g = ((n >> 4) & 0xf);
			NSInteger b = (n & 0xf);

			return TXCalibratedDeviceColor((r / 15.0), (g / 15.0), (b / 15.0));
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
	return [self colorWithCalibratedRed:0.439216 green:0.494118 blue:0.54902 alpha:1.0];
}

+ (NSColor *)outlineViewHeaderDisabledTextColor
{
	return [NSColor colorWithCalibratedRed:0.619 green:0.635 blue:0.678 alpha:1.0];
}

@end

@implementation NSGradient (TXGradientHelper)

+ (NSGradient *)gradientWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor
{
	return [[self alloc] initWithStartingColor:startingColor endingColor:endingColor];
}

+ (NSGradient *)sourceListBackgroundGradientColor
{
	return [self gradientWithStartingColor:[NSColor colorWithCalibratedRed:0.917 green:0.929 blue:0.949 alpha:1.0]
							   endingColor:[NSColor colorWithCalibratedRed:0.780 green:0.811 blue:0.847 alpha:1.0]];
}

@end
