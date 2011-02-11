// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSColor (NSColorHelper)

static NSDictionary *nameMap = nil;

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
			
			return RGB(r, g, b);
		} else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);
			
			NSInteger r = ((n >> 8) & 0xf);
			NSInteger g = ((n >> 4) & 0xf);
			NSInteger b = (n & 0xf);
			
			return [NSColor colorWithCalibratedRed:(r / 15.0) 
											 green:(g / 15.0) 
											  blue:(b / 15.0) 
											 alpha:1];
		}
	}
	
	if (NSObjectIsEmpty(nameMap)) {
		nameMap = [NSDictionary dictionaryWithObjectsAndKeys:
				   RGB(0, 0, 0), @"black",
				   RGB(0xC0, 0xC0, 0xC0), @"silver",
				   RGB(0x80, 0x80, 0x80), @"gray",
				   RGB(0xFF, 0xFF, 0xFF), @"white",
				   RGB(0x80, 0, 0), @"maroon",
				   RGB(0xFF, 0, 0), @"red",
				   RGB(0x80, 0, 0x80), @"purple",
				   RGB(0xFF, 0, 0xFF), @"fuchsia",
				   RGB(0, 0x80, 0), @"green",
				   RGB(0, 0xFF, 0), @"lime",
				   RGB(0x80, 0x80, 0), @"olive",
				   RGB(0xFF, 0xFF, 0), @"yellow",
				   RGB(0, 0, 0x80), @"navy",
				   RGB(0, 0, 0xFF), @"blue",
				   RGB(0, 0x80, 0x80), @"teal",
				   RGB(0, 0xFF, 0xFF), @"aqua",
				   RGBA(0, 0, 0, 0), @"transparent", nil];
		
		[nameMap retain];
	}
	
	return [nameMap objectForKey:[s lowercaseString]];
}

@end