// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

/* 
	Designed to match latest version of the NSRegularExpression library.
 
	typedef NS_OPTIONS(NSUInteger, NSRegularExpressionOptions) {
		NSRegularExpressionCaseInsensitive             = 1 << 0,    
		NSRegularExpressionAllowCommentsAndWhitespace  = 1 << 1,    
		NSRegularExpressionIgnoreMetacharacters        = 1 << 2,    
		NSRegularExpressionDotMatchesLineSeparators    = 1 << 3,    
		NSRegularExpressionAnchorsMatchLines           = 1 << 4,   
		NSRegularExpressionUseUnixLineSeparators       = 1 << 5,   
		NSRegularExpressionUseUnicodeWordBoundaries    = 1 << 6   
	};
*/

#define _TXRegularExpressionCaseInsensitive         (1 << 0)

/* It is always best to trust native developer APIs. Therefore, on versions
 of Mac OS X that support NSRegularExpression let us use it instead of relying
 on open source libraries to do the work for us. 
 
 In order to work on Snow Leopard and earlier we turn NSRegularExpression into 
 an id object which is defined using NSClassFromString so that Textual does not
 crash from missing symbols. */

@implementation TLORegularExpression

static id _regularExpressionCaller;

+ (void)setupRegularExpressionEngine
{
	if ([self useNewRegularExpressionEngine]) {
		_regularExpressionCaller = NSClassFromString(@"NSRegularExpression");
	}
}

+ (BOOL)useNewRegularExpressionEngine
{
	return [TPCPreferences featureAvailableToOSXLion];
}

+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle
{
	return [self string:haystack isMatchedByRegex:needle withoutCase:NO];
}

+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
	[self setupRegularExpressionEngine];
	
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef TXNativeRegularExpressionAvailable
	if ([self useNewRegularExpressionEngine]) {
		id regex;
        
        if (caseless) {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:_TXRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:0 error:NULL];
        }
        
        NSUInteger numMatches = [regex numberOfMatchesInString:haystack options:0 range:strRange];
		
        return (numMatches >= 1);
	} else {
#endif
		
        if (caseless) {
            return [haystack isMatchedByRegex:needle options:RKLCaseless inRange:strRange error:NULL];
        } else {
            return [haystack isMatchedByRegex:needle];
        }
        
#ifdef TXNativeRegularExpressionAvailable
	}
#endif
}

+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle
{
	return [self string:haystack rangeOfRegex:needle withoutCase:NO];
}

+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
	[self setupRegularExpressionEngine];
	
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef TXNativeRegularExpressionAvailable
	if ([self useNewRegularExpressionEngine]) {
		id regex;
        
        if (caseless) {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:_TXRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:0 error:NULL];
        }
		
		NSRange resultRange = [regex rangeOfFirstMatchInString:haystack options:0 range:strRange];
		
		return resultRange;
	} else {
#endif
		
        if (caseless) {
			return [haystack rangeOfRegex:needle options:RKLCaseless inRange:strRange capture:0 error:NULL];
        } else {
            return [haystack rangeOfRegex:needle];
        }
		
#ifdef TXNativeRegularExpressionAvailable
	}
#endif
}

+ (NSString *)string:(NSString *)haystack replacedByRegex:(NSString *)needle withString:(NSString *)puppy
{
	[self setupRegularExpressionEngine];
	
#ifdef TXNativeRegularExpressionAvailable
	if ([self useNewRegularExpressionEngine]) {
		NSRange strRange = NSMakeRange(0, [haystack length]);
		
		id regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:0 error:NULL];
		
		NSString *newString = [regex stringByReplacingMatchesInString:haystack options:0 range:strRange withTemplate:puppy];
		
		return newString;
	} else {
#endif
		
		return [haystack stringByReplacingOccurrencesOfRegex:needle withString:puppy];
		
#ifdef TXNativeRegularExpressionAvailable
	}
#endif
}

+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle
{
	return [self matchesInString:haystack withRegex:needle withoutCase:NO];
}

+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
	[self setupRegularExpressionEngine];
	
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef TXNativeRegularExpressionAvailable
	if ([self useNewRegularExpressionEngine]) {
		NSRegularExpression *regex;
        
        if (caseless) {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:_TXRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [_regularExpressionCaller regularExpressionWithPattern:needle options:0 error:NULL];
        }
		
		NSMutableArray *realMatches = [NSMutableArray array];
		
		NSArray *matches = [regex matchesInString:haystack options:0 range:strRange];
		
		for (NSTextCheckingResult *result in matches) {
			NSString *newStr = [haystack safeSubstringWithRange:[result range]];
			
			if (NSObjectIsNotEmpty(newStr)) {
				[realMatches safeAddObject:newStr];
			}
		}
		
		return realMatches;
	} else {
#endif
		
        if (caseless) {
			return [haystack componentsSeparatedByRegex:needle options:RKLCaseless range:strRange error:NULL];
        } else {
            return [haystack componentsSeparatedByRegex:needle];
        }
		
#ifdef TXNativeRegularExpressionAvailable
	}
#endif	
}

@end