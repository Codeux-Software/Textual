// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <AutoHyperlinks/AutoHyperlinks.h>

@implementation URLParser

+ (NSArray *)locatedLinksForString:(NSString *)body
{
	AHHyperlinkScanner *scanner = [AHHyperlinkScanner hyperlinkScannerWithString:body];
	
	NSMutableArray *result = [NSMutableArray array];
	
	for (AHMarkedHyperlink *link in [scanner allURIs]) {
		NSRange r = [link range];
		
		if (r.location != NSNotFound) {
			[result addObject:NSStringFromRange(r)];
		}
	}
	
	return result;
}

+ (NSArray *)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end