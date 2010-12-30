// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface URLParser (Private)
+ (NSRange)rangeOfUrlStart:(NSInteger)start withString:(NSString *)string;
+ (NSString *)complexURLRegularExpression;
+ (NSDictionary *)URLRegexSpecialCharactersMapping;
+ (NSArray *)bannedURLRegexEndChars;
+ (NSArray *)bannedURLRegexLeftBufferChars;
+ (NSArray *)bannedURLRegexRightBufferChars;
@end

@implementation URLParser

#pragma mark -
#pragma mark URL Parser

+ (NSArray *)locatedLinksForString:(NSString *)body
{
	NSMutableArray *urlRanges = [NSMutableArray array];
	
	NSInteger start = 0;
	NSInteger len = [body length];
	
	while (start < len) {
		NSRange r = [self rangeOfUrlStart:start withString:body];
		
		if (r.location == NSNotFound) {
			break;
		}
		
		if (r.length >= 1) {
			NSString *link = [body substringWithRange:r];
			NSString *choppedString = [link fastChopEndWithChars:[self bannedURLRegexEndChars]];
			
			NSInteger origLenth = [link length];
			NSInteger choppedLenth = [choppedString length];
			
			if (choppedLenth < origLenth) {
				NSString *lastchar = [link substringWithRange:NSMakeRange(choppedLenth, 1)];
				NSString *mapChar = [[self URLRegexSpecialCharactersMapping] objectForKey:lastchar];
				
				if (mapChar && [link contains:mapChar]) {
					choppedLenth += 1;
				} 
				
				r.length = choppedLenth;	
			}
			
			[urlRanges addObject:NSStringFromRange(r)];
		}
		
		start = (NSMaxRange(r) + 1);
	}
	
	return urlRanges;
}

+ (NSRange)rangeOfUrlStart:(NSInteger)start withString:(NSString *)string
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

#pragma mark -
#pragma mark Info for Parser

static NSString *urlAddrRegexComplex;

+ (NSString *)complexURLRegularExpression
{
	if (!urlAddrRegexComplex) {
		urlAddrRegexComplex = [NSString stringWithFormat:@"((((\\b(?:[a-zA-Z][a-zA-Z0-9+.-]{2,6}://)?)([a-zA-Z0-9-]+\\.))+%@\\b)|((\\b([a-zA-Z][a-zA-Z0-9+.-]{2,6}://))+(([0-9]{1,3}\\.){3})+([0-9]{1,3})\\b))(?:\\:([0-9]+))?(?:/[a-zA-Z0-9;áàâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ/\\?\\:\\,\\]\\[\\)\\(\\=\\&\\._\\#\\>\\<\\$\\'\\}\\{\\`\\~\\!\\@\\^\\|\\*\\+\\-\\%%]*)?", TXTLS(@"ALL_DOMAIN_EXTENSIONS")];
	}
	
	return urlAddrRegexComplex;
}

+ (NSDictionary *)URLRegexSpecialCharactersMapping
{
	return [NSDictionary dictionaryWithObjectsAndKeys:@"(", @")", nil];
}

+ (NSArray *)bannedURLRegexEndChars
{
	return [NSArray arrayWithObjects:@")", @"]", @"'", @"\"", @":", @">", @"<", @"}", @"|", @",", @".", nil];
}

+ (NSArray *)bannedURLRegexLeftBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"!", @"@", @"#", @"$", @"%", @"^", @"&", 
			@"*", @"_", @"+", @"=", @"-", @"`", @";", @"/", @".", @",", @"?", nil];
}

+ (NSArray *)bannedURLRegexRightBufferChars
{
	return [NSArray arrayWithObjects:@"~", @"@", @"#", @"$", @"%", @"^", 
			@"&", @"*", @"_", @"+", @"=", @"-", @"`", @"/", @".", @"!", nil];
}

+ (NSArray *)bannedURLRegexLineTypes
{
	return [NSArray arrayWithObjects:@"mode", @"join", @"nick", @"invite", nil];
}

@end