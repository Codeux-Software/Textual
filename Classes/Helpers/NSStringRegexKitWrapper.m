// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

// TEMPORARY wrapper to emulate the RegexpKit API, can be replaced at some point
// with better methods or direct calls into OrgeKit

#import "NSStringRegexKitWrapper.h"
#import <OgreKit/NSString_OgreKitAdditions.h>

@implementation NSString (NSStringRegexKitWrapper) 

- (BOOL)isMatchedByRegex:(NSString *)aRegex
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:aRegex];
	OGRegularExpressionMatch *match = [regex matchInString:self];
	
	return ((match) ? YES : NO);
}

- (NSRange)rangeOfRegex:(NSString *)aRegex
{
	return [self rangeOfRegularExpressionString:[aRegex copy]];
}

- (NSString *)stringByMatching:(NSString *)aRegex replace:(int)options withReferenceString:(NSString *) replacement
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:aRegex];
	
	return [regex replaceString:self 
					 withString:replacement
						options:OgreNoneOption
						  range:NSMakeRange(0, [self length])
					 replaceAll:(options == RKReplaceAll)];
}

- (BOOL)getCapturesWithRegexAndReferences:(NSString *)aRegex, ...
{
	va_list argumentList;
	NSString * pattern;
	void ** ref;
	
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:aRegex];
	OGRegularExpressionMatch *match = [regex matchInString:self];
	
	if (match == nil) return NO;
	
	unsigned replaced = 0;
	va_start(argumentList, aRegex);
	
	while ((pattern = va_arg(argumentList, NSString *))) {
		ref = va_arg(argumentList, void **);
		
		*ref = [regex replaceString:self 
						 withString:pattern
							options:OgreNoneOption
							  range:NSMakeRange(0, [self length])
						 replaceAll:YES
				numberOfReplacement:&replaced];
	}		
	
	va_end(argumentList);
	
	return YES;
}

@end