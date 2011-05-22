// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TIME_BUFFER_SIZE	256

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

void DevNullDestroyObject(BOOL condition, ...)
{
	return;
}

NSString *TXTLS(NSString *key)
{
	return [LanguagePreferences localizedStringWithKey:key];
}

NSString *TXTFLS(NSString *key, ...)
{
	NSString *formattedString = [NSString alloc];
	NSString *languageString  = [LanguagePreferences localizedStringWithKey:key];
	
	va_list args;
	va_start(args, key);
	
	formattedString = [formattedString initWithFormat:languageString arguments:args];
	
	va_end(args);
	
	return [formattedString autodrain];
}

NSString *TXFormattedTimestampWithOverride(NSString *format, NSString *override) 
{
	if (NSObjectIsEmpty(format))      format = @"[%H:%M:%S]";
	if (NSObjectIsNotEmpty(override)) format = override;
	
	return [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:format timeZone:nil]];
}

NSString *TXFormattedTimestamp(NSString *format) 
{
	return TXFormattedTimestampWithOverride(format, nil);
}

NSString *TXSpecialReadableTime(NSInteger dateInterval, BOOL shortValue) 
{
	NSArray *orderMatrix = [NSArray arrayWithObjects:@"year", @"month", @"week", @"day", @"hour", @"minute", @"second", nil];
	
	NSCalendar *sysCalendar = [NSCalendar currentCalendar];
	
	NSDate *date1 = [NSDate date];
	NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:(-(dateInterval + 1))];
	
	NSUInteger unitFlags = (NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | 
							NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
	
	NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:date1 toDate:date2  options:0];
	
	if (breakdownInfo) {
		NSMutableString *finalResult = [NSMutableString string];
		
		for (NSString *unit in orderMatrix) {
			NSInteger total = (NSInteger)[breakdownInfo performSelector:NSSelectorFromString(unit)];
			
			if (total < 0) {
				total *= -1;
			}
			
			if (total >= 1) {
				NSString *languageKey = [@"TIME_CONVERT_" stringByAppendingString:[unit uppercaseString]];
				
				if (total > 1 || total < 1) {
					languageKey = [languageKey stringByAppendingString:@"_PLURAL"];
				}
				
				if (shortValue) {
					return [NSString stringWithFormat:@"%i %@", total, TXTLS(languageKey)];
				} else {
					[finalResult appendFormat:@"%i %@, ", total, TXTLS(languageKey)];
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
	return TXSpecialReadableTime(dateInterval, NO);
}

NSInteger TXRandomNumber(NSInteger maxset)
{
	return ((1 + arc4random()) % (maxset + 1));
}

NSString *TXFormattedNumber(NSInteger number)
{
	NSNumber *numberbar = [NSNumber numberWithInteger:number];
	
	return [NSNumberFormatter localizedStringFromNumber:numberbar numberStyle:kCFNumberFormatterDecimalStyle];
}
