// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "URLParser.h"
#import "GlobalModels.h"
#import "NSStringHelper.h"

@implementation URLParser

#pragma mark -
#pragma mark URL Parser

+ (NSRange)rangeOfUrlStart:(NSInteger)start withString:(NSString*)string
{
	if ([string length] <= start) return NSMakeRange(NSNotFound, 0);
	
	NSString *shortstring = [string safeSubstringFromIndex:start];
	NSInteger sstring_length = [shortstring length];
	
	NSRange rs = [shortstring rangeOfRegex:[self complexURLRegularExpression]];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSString *leftchar = nil;
	NSString *rightchar = nil;
	
	NSInteger rightcharLocal = (rs.location + rs.length);
	
	if (rs.location > 0) {
		leftchar = [shortstring substringWithRange:NSMakeRange((rs.location - 1), 1)];
	}
	
	if (rightcharLocal < sstring_length) {
		rightchar = [shortstring substringWithRange:NSMakeRange(rightcharLocal, 1)];
	}
	
	if ([[self bannedURLRegexLeftBufferChars] containsObject:leftchar] ||
		[[self bannedURLRegexRightBufferChars] containsObject:rightchar]) {
		
		return NSMakeRange((r.location + r.length), 1000);
	}
	
	return r;
}

+ (NSArray*)fastChopURL:(NSString *)url
{
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
		
		url = [url safeSubstringToIndex:choppedLenth];
		metacontent = [url safeSubstringFromIndex:choppedLenth];
	}
	
	finalurl = url;
	
	if (![url contains:@"://"]) {
		finalurl = [NSString stringWithFormat:@"http://%@", finalurl];
	}
	
	return [NSArray arrayWithObjects:url, finalurl, metacontent, nil];
}

#pragma mark -
#pragma mark Info for Parser

static NSString *urlAddrRegexComplex;

+ (NSString*)complexURLRegularExpression
{
	if (!urlAddrRegexComplex) {
		urlAddrRegexComplex = [NSString stringWithFormat:@"((((\\b(?:[a-zA-Z][a-zA-Z0-9+.-]{2,6}://)?)([a-zA-Z0-9-]+\\.))+%@\\b)|((\\b([a-zA-Z][a-zA-Z0-9+.-]{2,6}://))+(([0-9]{1,3}\\.){3})+([0-9]{1,3})\\b))(?:\\:([0-9]+))?(?:/[a-zA-Z0-9;/\\?\\:\\,\\]\\[\\)\\(\\=\\&\\._\\#\\>\\<\\$\\'\\\"\\}\\{\\`\\~\\!\\@\\^\\|\\*\\+\\-\\%%]*)?", TXTLS(@"ALL_DOMAIN_EXTENSIONS")];
	}
	
	return urlAddrRegexComplex;
}

+ (NSDictionary*)URLRegexSpecialCharactersMapping
{
	return [NSDictionary dictionaryWithObjectsAndKeys:@"(", @")", nil];
}

+ (NSArray*)bannedURLRegexEndChars
{
	return [NSArray arrayWithObjects:@")", @"]", @"'", @"\"", @":", @">", @"<", @"}", @"|", @",", nil];
}

+ (NSArray*)bannedURLRegexLeftBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"!", @"@", @"#", @"$", @"%", @"^", @"&", 
			@"*", @"_", @"+", @"=", @"-", @"`", @":", @";", @"/", @".", @",", @"?", nil];
}

+ (NSArray*)bannedURLRegexRightBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"@", @"#", @"$", @"%", @"^", @"&", 
			@"*", @"_", @"+", @"=", @"-", @"`", @"/", @".", @",", @"!", nil];
}

+ (NSArray*)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end