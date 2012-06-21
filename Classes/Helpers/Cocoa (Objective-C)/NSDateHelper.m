// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation NSDate (TXDateHelper)
 
+ (NSInteger)secondsSinceUnixTimestamp:(NSInteger)stamp
{
	return ([self epochTime] - stamp);
}

+ (NSInteger)epochTime
{
	return [[NSDate date] timeIntervalSince1970];
}

@end