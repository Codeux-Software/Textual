// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

#import <AutoHyperlinks/AutoHyperlinks.h>

@implementation URLParser

+ (NSArray *)locatedLinksForString:(NSString *)body
{
	NSArray *result;
	
	AHHyperlinkScanner *scanner = [AHHyperlinkScanner new];
	
	result = [scanner matchesForString:body];
	
	scanner = nil;
	
	return result;
}

+ (NSArray *)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end