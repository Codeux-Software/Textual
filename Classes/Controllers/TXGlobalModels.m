/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#import <objc/objc-runtime.h>
#import <time.h>

#define _timeBufferSize		256 /* Let's hope to God no one tries to overflow this… */

#pragma mark -
#pragma mark Validity.

BOOL NSObjectIsEmpty(id obj)
{
	if ([obj respondsToSelector:@selector(length)]) {
		return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(length)] < 1);
	}

	if ([obj respondsToSelector:@selector(count)]) {
		return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(count)] < 1);
	}
	
	return PointerIsEmpty(obj);
}

BOOL NSObjectIsNotEmpty(id obj)
{
	return BOOLReverseValue(NSObjectIsEmpty(obj));
}

#pragma mark -
#pragma mark Time.

NSString *TXFormattedTimestampWithOverride(NSDate *date, NSString *format, NSString *override) 
{
	if (NSObjectIsEmpty(format)) {
		format = TXDefaultTextualTimestampFormat;
	}

	if (NSObjectIsNotEmpty(override)) {
		format = override;
	}

	time_t global = (time_t) [date timeIntervalSince1970];
	
	struct tm *local = localtime(&global);
	char buf[(_timeBufferSize + 1)];
	
	strftime(buf, _timeBufferSize, [format UTF8String], local);

	buf[_timeBufferSize] = 0;

	return [NSString stringWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding];
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
	
	NSUInteger unitFlags = 0;

	if ([orderMatrix containsObject:@"year"])		{ unitFlags |= NSYearCalendarUnit;		}
	if ([orderMatrix containsObject:@"month"])		{ unitFlags |= NSMonthCalendarUnit;		}
	if ([orderMatrix containsObject:@"week"])		{ unitFlags |= NSWeekCalendarUnit;		}
	if ([orderMatrix containsObject:@"day"])		{ unitFlags |= NSDayCalendarUnit;		}
	if ([orderMatrix containsObject:@"hour"])		{ unitFlags |= NSHourCalendarUnit;		}
	if ([orderMatrix containsObject:@"minute"])		{ unitFlags |= NSMinuteCalendarUnit;	}
	if ([orderMatrix containsObject:@"second"])		{ unitFlags |= NSSecondCalendarUnit;	}
	
	NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:date1 toDate:date2 options:0];
	
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
					return [NSString stringWithFormat:@"%ld %@", total, TXTLS(languageKey)];
				} else {
					[finalResult appendFormat:@"%ld %@, ", total, TXTLS(languageKey)];
				}
			}
		}
		
		if ([finalResult length] >= 3) {
			[finalResult safeDeleteCharactersInRange:NSMakeRange((finalResult.length - 2), 2)];
		}
		
		return finalResult;
	}
	
	return nil;
}

NSString *TXReadableTime(NSInteger dateInterval)
{
	return TXSpecialReadableTime(dateInterval, NO, nil);
}

#pragma mark -
#pragma mark Localized String File.

NSString *TXTLS(NSString *key)
{
	return [TLOLanguagePreferences localizedStringWithKey:key];
}

NSString *TSBLS(NSString *key, NSBundle *bundle)
{
	return [TLOLanguagePreferences localizedStringWithKey:key from:bundle];
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

NSString *TSBFLS(NSString *key, NSBundle *bundle, ...)
{
	NSString *formattedString = [NSString alloc];
	NSString *languageString  = [TLOLanguagePreferences localizedStringWithKey:key from:bundle];

	va_list args;
	va_start(args, bundle);

	formattedString = [formattedString initWithFormat:languageString arguments:args];

	va_end(args);

	return formattedString;
}

#pragma mark -
#pragma mark Misc.

NSInteger TXRandomNumber(NSInteger maxset)
{
	NSAssertReturnR((maxset > 0), 0); // Only Chuck Norris can divide by zero.
	
	return ((1 + arc4random()) % (maxset + 1));
}

NSString *TXFormattedNumber(NSInteger number)
{
	return [NSNumberFormatter localizedStringFromNumber:@(number) numberStyle:NSNumberFormatterDecimalStyle];
}

NSComparator NSDefaultComparator = ^(id obj1, id obj2)
{
	return [obj1 compare:obj2];
};
