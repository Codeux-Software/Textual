// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#import <objc/objc-runtime.h>

BOOL NSObjectIsEmpty(id obj)
{
	if ([obj respondsToSelector:@selector(length)]) {
		return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(length)] < 1);
	} else {
		if ([obj respondsToSelector:@selector(count)]) {
			return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(count)] < 1);
		}
	}
	
	return PointerIsEmpty(obj);
}

BOOL NSObjectIsNotEmpty(id obj)
{
	return BOOLReverseValue(NSObjectIsEmpty(obj));
}

NSString *TXTLS(NSString *key)
{
	return [TLOLanguagePreferences localizedStringWithKey:key];
}

NSString *TXTFLS(NSString *key, ...)
{
	NSString *formattedString = [NSString alloc];
	NSString *languageString  = [TLOLanguagePreferences localizedStringWithKey:key];
	
	va_list args;
	va_start(args, key);
	
	formattedString = [formattedString initWithFormat:languageString arguments:args];
	
	va_end(args);
	
	return formattedString;
}

NSString *TXFormattedTimestampWithOverride(NSDate *date, NSString *format, NSString *override) 
{
	if (NSObjectIsEmpty(format))      format = TXDefaultTextualTimestampFormat;
	if (NSObjectIsNotEmpty(override)) format = override;
	
	return [NSString stringWithFormat:@"%@", [date dateWithCalendarFormat:format timeZone:nil]];
}

NSString *TXFormattedTimestamp(NSDate *date, NSString *format) 
{
	return TXFormattedTimestampWithOverride(date, format, nil);
}

NSString *TXSpecialReadableTime(NSInteger dateInterval, BOOL shortValue, NSArray *orderMatrix)
{
	if (NSObjectIsEmpty(orderMatrix)) {
		orderMatrix = @[@"year", @"month", @"week", @"day", @"hour", @"minute", @"second"];
	}
	
	NSCalendar *sysCalendar = [NSCalendar currentCalendar];
	
	NSDate *date1 = [NSDate date];
	NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:(-(dateInterval + 1))];
	
	NSUInteger unitFlags = (NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | 
							NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
	
	NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:date1 toDate:date2  options:0];
	
	if (breakdownInfo) {
		NSMutableString *finalResult = [NSMutableString string];
		
		for (NSString *unit in orderMatrix) {
			NSInteger total = (NSInteger)objc_msgSend(breakdownInfo, NSSelectorFromString(unit));
			
			if (total < 0) {
				total *= -1;
			}
			
			if (total >= 1) {
				NSString *languageKey;

				if (total > 1 || total < 1) {
					languageKey = [NSString stringWithFormat:@"TimeConvertPlural[%@]", unit.uppercaseString];
				} else {
					languageKey = [NSString stringWithFormat:@"TimeConvert[%@]", unit.uppercaseString];
				}
				
				if (shortValue) {
					return [NSString stringWithFormat:@"%d %@", total, TXTLS(languageKey)];
				} else {
					[finalResult appendFormat:@"%d %@, ", total, TXTLS(languageKey)];
				}
			}
		}
		
		if ([finalResult length] >= 3) {
			[finalResult safeDeleteCharactersInRange:NSMakeRange(([finalResult length] - 2), 2)];
		}
		
		return finalResult;
	}
	
	return nil;
}

NSString *TXReadableTime(NSInteger dateInterval)
{
	return TXSpecialReadableTime(dateInterval, NO, nil);
}

NSInteger TXRandomNumber(NSInteger maxset)
{
	return ((1 + arc4random()) % (maxset + 1));
}

NSString *TXFormattedNumber(NSInteger number)
{
	NSNumber *numberbar = @(number);
	
	return [NSNumberFormatter localizedStringFromNumber:numberbar numberStyle:kCFNumberFormatterDecimalStyle];
}
