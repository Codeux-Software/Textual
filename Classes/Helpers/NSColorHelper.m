// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

// Internal declaration 
#define _NSCalibratedRBGColor(r, b, g)		([NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0])

@implementation NSColor (NSColorHelper)

#pragma mark -
#pragma mark IRC Text Formatting Color Codes

/* The following formatter colors were specifically calibrated to 
 match the exact color WebKit sets to the pasteboard when text is
 copied from its view. This is done so that when IRC formatted text 
 is pasted the end user can easily recopy it to paste and modify 
 immediately. DO NOT EDIT FOR ANY CIRCUMSTANCE. */

+ (NSColor *)formatterWhiteColor
{
	return _NSCalibratedRBGColor(1.00, 1.00, 1.00);
}

+ (NSColor *)formatterBlackColor
{
	return _NSCalibratedRBGColor(0.00, 0.00, 0.00);
}

+ (NSColor *)formatterNavyBlueColor
{
	return _NSCalibratedRBGColor(0.04, 0.52, 0.00); 
}

+ (NSColor *)formatterDarkGreenColor
{
	return _NSCalibratedRBGColor(0.00, 0.08, 0.54);
}

+ (NSColor *)formatterRedColor
{
	return _NSCalibratedRBGColor(1.00, 0.04, 0.05);
}

+ (NSColor *)formatterBrownColor
{
	return _NSCalibratedRBGColor(0.55, 0.02, 0.02);
}

+ (NSColor *)formatterPurpleColor
{
	return _NSCalibratedRBGColor(0.55, 0.53, 0.00);
}

+ (NSColor *)formatterOrangeColor
{
	return _NSCalibratedRBGColor(1.00, 0.09, 0.54);
}

+ (NSColor *)formatterYellowColor
{
	return _NSCalibratedRBGColor(1.00, 0.15, 1.00);
}

+ (NSColor *)formatterLimeGreenColor
{
	return _NSCalibratedRBGColor(0.00, 0.15, 1.00);
}

+ (NSColor *)formatterTealColor
{
	return _NSCalibratedRBGColor(0.00, 0.53, 0.53);
}

+ (NSColor *)formatterAquaCyanColor
{
	return _NSCalibratedRBGColor(0.00, 1.00, 1.00);
}

+ (NSColor *)formatterLightBlueColor
{
	return _NSCalibratedRBGColor(0.07, 0.98, 0.00);
}

+ (NSColor *)formatterFuchsiaPinkColor
{
	return _NSCalibratedRBGColor(1.00, 0.98, 0.00);
}

+ (NSColor *)formatterNormalGrayColor
{
	return _NSCalibratedRBGColor(0.53, 0.53, 0.53);
}

+ (NSColor *)formatterLightGrayColor
{
	return _NSCalibratedRBGColor(0.80, 0.80, 0.80);
}

+ (NSArray *)possibleFormatterColors
{
	NSMutableArray *combo  = [NSMutableArray array];
	NSMutableArray *colors = [NSMutableArray array];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterWhiteColor], nil];
	[colors safeInsertObject:combo atIndex:0];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterBlackColor], nil];
	[colors safeInsertObject:combo atIndex:1];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterNavyBlueColor], _NSCalibratedRBGColor(0.0, 0.47, 0.0), nil];
	[colors safeInsertObject:combo atIndex:2];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterDarkGreenColor], _NSCalibratedRBGColor(0.03, 0.0, 0.48), nil];
	[colors safeInsertObject:combo atIndex:3];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterRedColor], _NSCalibratedRBGColor(1.00, 0.00, 0.00), nil];
	[colors safeInsertObject:combo atIndex:4];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterBrownColor], _NSCalibratedRBGColor(0.46, 0.00, 0.00), nil];
	[colors safeInsertObject:combo atIndex:5];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterPurpleColor], _NSCalibratedRBGColor(0.46, 0.47, 0.00), nil];
	[colors safeInsertObject:combo atIndex:6];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterOrangeColor], _NSCalibratedRBGColor(1.00, 0.00, 0.45), nil];
	[colors safeInsertObject:combo atIndex:7];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterYellowColor], _NSCalibratedRBGColor(1.00, 0.00, 1.00), nil];
	[colors safeInsertObject:combo atIndex:8];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterLimeGreenColor], _NSCalibratedRBGColor(0.06, 0.00, 1.00), nil];
	[colors safeInsertObject:combo atIndex:9];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterTealColor], _NSCalibratedRBGColor(0.00, 0.46, 0.46), nil];
	[colors safeInsertObject:combo atIndex:10];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterAquaCyanColor], nil];
	[colors safeInsertObject:combo atIndex:11];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterLightBlueColor], _NSCalibratedRBGColor(0.00, 1.00, 0.00), nil];
	[colors safeInsertObject:combo atIndex:12];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterFuchsiaPinkColor], _NSCalibratedRBGColor(1.00, 1.00, 0.00), nil];
	[colors safeInsertObject:combo atIndex:13];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterNormalGrayColor], _NSCalibratedRBGColor(0.46, 0.46, 0.46), nil];
	[colors safeInsertObject:combo atIndex:14];
	
	combo = [NSMutableArray arrayWithObjects:[self formatterLightGrayColor], nil];
	[colors safeInsertObject:combo atIndex:15];
	
	return colors;
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
		
		redHexValue   = [NSString stringWithFormat:@"%02x", redIntValue];
		greenHexValue = [NSString stringWithFormat:@"%02x", greenIntValue];
		blueHexValue  = [NSString stringWithFormat:@"%02x", blueIntValue];
		
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
			
			return _NSCalibratedRBGColor((r / 255.99999f), 
										 (b / 255.99999f), 
										 (g / 255.99999f));
		} else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);
			
			NSInteger r = ((n >> 8) & 0xf);
			NSInteger g = ((n >> 4) & 0xf);
			NSInteger b = (n & 0xf);
			
			return _NSCalibratedRBGColor((r / 15.0), 
										 (b / 15.0), 
										 (g / 15.0));
		}
	}
	
	return nil;
}

@end