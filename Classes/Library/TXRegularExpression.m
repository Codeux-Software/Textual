// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* It is always best to trust native developer APIs. Therefore, on versions
 of Mac OS X that support NSRegularExpression let us use it instead of relying
 on open source libraries to do the work for us. */

@interface TXRegularExpression (Private)
+ (BOOL)useNewRegularExpressionEngine;
@end

@implementation TXRegularExpression

+ (BOOL)useNewRegularExpressionEngine
{
	return [Preferences applicationRanOnLion];
}

+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle
{
	return [self string:haystack isMatchedByRegex:needle withoutCase:NO];
}

+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	if ([self useNewRegularExpressionEngine]) {
		NSRegularExpression *regex;
        
        if (caseless) {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:NSRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:0 error:NULL];
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

#ifdef _USES_MODERN_REGULAR_EXPRESSION
	}
#endif
}

+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle
{
	return [self string:haystack rangeOfRegex:needle withoutCase:NO];
}

+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	if ([self useNewRegularExpressionEngine]) {
		NSRegularExpression *regex;
        
        if (caseless) {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:NSRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:0 error:NULL];
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
		
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	}
#endif
}

+ (NSString *)string:(NSString *)haystack replacedByRegex:(NSString *)needle withString:(NSString *)puppy
{
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	if ([self useNewRegularExpressionEngine]) {
		NSRange strRange = NSMakeRange(0, [haystack length]);
		
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:needle options:0 error:NULL];
		
		NSString *newString = [regex stringByReplacingMatchesInString:haystack options:0 range:strRange withTemplate:puppy];
		
		return newString;
	} else {
#endif
		
		return [haystack stringByReplacingOccurrencesOfRegex:needle withString:puppy];
		
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	}
#endif
}
	
+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle
{
	return [self matchesInString:haystack withRegex:needle withoutCase:NO];
}

+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle withoutCase:(BOOL)caseless
{
    NSRange strRange = NSMakeRange(0, [haystack length]);
    
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	if ([self useNewRegularExpressionEngine]) {
		NSRegularExpression *regex;
        
        if (caseless) {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:NSRegularExpressionCaseInsensitive error:NULL];
        } else {
            regex = [NSRegularExpression regularExpressionWithPattern:needle options:0 error:NULL];
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
		
#ifdef _USES_MODERN_REGULAR_EXPRESSION
	}
#endif	
}

@end