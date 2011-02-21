// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <AutoHyperlinks/AutoHyperlinks.h>

@implementation URLParser

+ (NSArray *)locatedLinksForString:(NSString *)body
{
	NSMutableArray *result = [NSMutableArray array];
	
	AHHyperlinkScanner *scanner = [AHHyperlinkScanner new];
	
	result = [scanner matchesForString:body];
	
	[scanner autorelease];
	
	return result;
}

+ (NSArray *)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end