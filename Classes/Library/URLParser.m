// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "URLParser.h"

@implementation URLParser

#pragma mark -
#pragma mark URL Parser

+ (NSRange)rangeOfUrlStart:(NSInteger)start withString:(NSString*)string
{
	if ([string length] <= start) return NSMakeRange(NSNotFound, 0);
	
	NSString *shortstring = [string safeSubstringFromIndex:start];
	
	NSRange rs = [shortstring rangeOfRegex:[self complexURLRegularExpression]];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSString *leftchar = nil;
	NSString *rightchar = nil;
	
	NSInteger rightcharLocal = (r.location + r.length);
	
	if (r.location > 0) {
		leftchar = [string substringWithRange:NSMakeRange((r.location - 1), 1)];
	}
	
	if (rightcharLocal < [string length]) {
		rightchar = [string substringWithRange:NSMakeRange(rightcharLocal, 1)];
	}
	
	if ([[self bannedURLRegexLeftBufferChars] containsObject:leftchar] ||
		[[self bannedURLRegexRightBufferChars] containsObject:rightchar]) {
		
		return NSMakeRange(rightcharLocal, 0);
	}
	
	return r;
}

+ (NSArray*)fastChopURL:(NSString *)url
{
	NSString* link = url;
	
	NSString* lastchar = nil;
	NSString* finalurl = nil;
	NSString* metacontent = nil;
	
	NSString* choppedString = [url fastChopEndWithChars:[self bannedURLRegexEndChars]];

	NSInteger origLenth = [url length];
	NSInteger choppedLenth = [choppedString length];
	
	if (choppedLenth < origLenth) {
		lastchar = [url substringWithRange:NSMakeRange(choppedLenth, 1)];
		
		NSString* mapChar = [[self URLRegexSpecialCharactersMapping] objectForKey:lastchar];
		
		if (mapChar && [url contains:mapChar]) {
			choppedLenth += 1;
		} 
		
		link = [url safeSubstringToIndex:choppedLenth];
		metacontent = [url safeSubstringFromIndex:choppedLenth];		
	}
	
	finalurl = link;
	
	if (![link contains:@"://"]) {
		finalurl = [NSString stringWithFormat:@"http://%@", finalurl];
	}
	
	return [NSArray arrayWithObjects:link, finalurl, metacontent, nil];
}

#pragma mark -
#pragma mark Info for Parser

static NSString *urlAddrRegexComplex;

+ (NSString*)complexURLRegularExpression
{
	if (!urlAddrRegexComplex) {
		urlAddrRegexComplex = [NSString stringWithFormat:@"((((\\b(?:[a-zA-Z][a-zA-Z0-9+.-]{2,6}://)?)([a-zA-Z0-9-]+\\.))+%@\\b)|((\\b([a-zA-Z][a-zA-Z0-9+.-]{2,6}://))+(([0-9]{1,3}\\.){3})+([0-9]{1,3})\\b))(?:\\:([0-9]+))?(?:/[a-zA-Z0-9;áàâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ/\\?\\:\\,\\]\\[\\)\\(\\=\\&\\._\\#\\>\\<\\$\\'\\}\\{\\`\\~\\!\\@\\^\\|\\*\\+\\-\\%%]*)?", TXTLS(@"ALL_DOMAIN_EXTENSIONS")];
	}
	
	return urlAddrRegexComplex;
}

+ (NSDictionary*)URLRegexSpecialCharactersMapping
{
	return [NSDictionary dictionaryWithObjectsAndKeys:@"(", @")", nil];
}

+ (NSArray*)bannedURLRegexEndChars
{
	return [NSArray arrayWithObjects:@")", @"]", @"'", @"\"", @":", @">", @"<", @"}", @"|", @",", @".", nil];
}

+ (NSArray*)bannedURLRegexLeftBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"!", @"@", @"#", @"$", @"%", @"^", @"&", 
			@"*", @"_", @"+", @"=", @"-", @"`", @";", @"/", @".", @",", @"?", nil];
}

+ (NSArray*)bannedURLRegexRightBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"@", @"#", @"$", @"%", @"^", 
			@"&", @"*", @"_", @"+", @"=", @"-", @"`", @"/", @".", @"!", nil];
}

+ (NSArray*)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end