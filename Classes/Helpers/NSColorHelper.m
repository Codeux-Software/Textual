// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "NSColorHelper.h"

@implementation NSColor (NSColorHelper)

+ (NSColor *)fromCSS:(NSString *)s
{
	if ([s hasPrefix:@"#"]) {
		s = [s safeSubstringFromIndex:1];
		
		NSInteger len = s.length;
		if (len == 6) {
			long n = strtol([s UTF8String], NULL, 16);
			NSInteger r = (n >> 16) & 0xff;
			NSInteger g = (n >> 8) & 0xff;
			NSInteger b = n & 0xff;
			return DEVICE_RGB(r, g, b);
		} else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);
			NSInteger r = (n >> 8) & 0xf;
			NSInteger g = (n >> 4) & 0xf;
			NSInteger b = n & 0xf;
			return [NSColor colorWithDeviceRed:r/15.0 green:g/15.0 blue:b/15.0 alpha:1];
		}
	}
	
	static NSDictionary *nameMap = nil;
	if (!nameMap) {
		nameMap = [[NSDictionary dictionaryWithObjectsAndKeys:
				   DEVICE_RGB(0, 0, 0), @"black",
				   DEVICE_RGB(0xC0, 0xC0, 0xC0), @"silver",
				   DEVICE_RGB(0x80, 0x80, 0x80), @"gray",
				   DEVICE_RGB(0xFF, 0xFF, 0xFF), @"white",
				   DEVICE_RGB(0x80, 0, 0), @"maroon",
				   DEVICE_RGB(0xFF, 0, 0), @"red",
				   DEVICE_RGB(0x80, 0, 0x80), @"purple",
				   DEVICE_RGB(0xFF, 0, 0xFF), @"fuchsia",
				   DEVICE_RGB(0, 0x80, 0), @"green",
				   DEVICE_RGB(0, 0xFF, 0), @"lime",
				   DEVICE_RGB(0x80, 0x80, 0), @"olive",
				   DEVICE_RGB(0xFF, 0xFF, 0), @"yellow",
				   DEVICE_RGB(0, 0, 0x80), @"navy",
				   DEVICE_RGB(0, 0, 0xFF), @"blue",
				   DEVICE_RGB(0, 0x80, 0x80), @"teal",
				   DEVICE_RGB(0, 0xFF, 0xFF), @"aqua",
				   DEVICE_RGBA(0, 0, 0, 0), @"transparent",
				   nil] retain];
	}
	
	return [nameMap objectForKey:[s lowercaseString]];
}

@end