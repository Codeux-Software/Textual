// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#include <AutoHyperlinks/AutoHyperlinks.h>

@implementation URLParser

+ (NSArray *)locatedLinksForString:(NSString *)body
{
	NSMutableArray *result = [NSMutableArray array];
	
	AHHyperlinkScanner *scanner = [AHHyperlinkScanner new];
	
	for (NSString *link in [scanner matchesForString:body]) {
		NSRange r = NSRangeFromString(link);
		
		if (r.location != NSNotFound) {
			NSString *url = [body safeSubstringWithRange:r];
			
			if ([url contains:@"@"] && [url isMatchedByRegex:@"(.*)://(.*)@(.*)"] == NO) {
				continue;
			}
			
			[result addObject:NSStringFromRange(r)];
		}
	}
	
	[scanner drain];
	scanner = nil;
	
	return result;
}

+ (NSArray *)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end