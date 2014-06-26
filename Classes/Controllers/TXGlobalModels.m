/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#pragma mark -
#pragma mark Validity.

BOOL NSObjectIsEmpty(id obj)
{
	/* Check for common string length. */
	if ([obj respondsToSelector:@selector(length)]) {
		return ((NSInteger)objc_msgSend(obj, @selector(length)) < 1);
	}
	
	/* Check for common array types. */
	if ([obj respondsToSelector:@selector(count)]) {
		return ((NSInteger)objc_msgSend(obj, @selector(count)) < 1);
	}
	
	/* Check everything else. */
	return (obj == nil || obj == NULL);
}

BOOL NSObjectIsNotEmpty(id obj)
{
	return (NSObjectIsEmpty(obj) == NO);
}

BOOL NSObjectsAreEqual(id obj1, id obj2)
{
	return ((obj1 == nil && obj2 == nil) || [obj1 isEqual:obj2]);
}

#pragma mark -
#pragma mark Time.

NSString *TXFormattedTimestamp(NSDate *date, NSString *format)
{
	/* If the format is empty, a default is called. */
	if (NSObjectIsEmpty(format)) {
		format = TXDefaultTextualTimestampFormat;
	}
	
	/* Convert time to C object. */
	time_t global = (time_t)[date timeIntervalSince1970];
	
	/* Format time. */
	static NSInteger _timeBufferSize = 256;
	
	struct tm *local = localtime(&global);
	
	char buf[(_timeBufferSize + 1)];
	
	strftime(buf, _timeBufferSize, [format UTF8String], local);
	
	buf[_timeBufferSize] = 0;
	
	/* Return results as UTF-8 string. */
	return [NSString stringWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding];
}

NSString *TXHumanReadableTimeInterval(NSInteger dateInterval, BOOL shortValue, NSUInteger orderMatrix)
{
	/* Default what we will return. */
	if (orderMatrix == 0) {
		orderMatrix = (NSYearCalendarUnit		|
					   NSMonthCalendarUnit		|
					   NSWeekCalendarUnit		|
					   NSDayCalendarUnit		|
					   NSHourCalendarUnit		|
					   NSMinuteCalendarUnit		|
					   NSSecondCalendarUnit);
	}
	
	/* Convert calander units to a text rep. */
	NSMutableArray *orderStrings = [NSMutableArray array];
	
	if (orderMatrix & NSYearCalendarUnit) {
		[orderStrings addObject:@"year"];
	}
	
	if (orderMatrix & NSMonthCalendarUnit) {
		[orderStrings addObject:@"month"];
	}
	
	if (orderMatrix & NSWeekCalendarUnit) {
		[orderStrings addObject:@"week"];
	}
	
	if (orderMatrix & NSDayCalendarUnit) {
		[orderStrings addObject:@"day"];
	}
	
	if (orderMatrix & NSHourCalendarUnit) {
		[orderStrings addObject:@"hour"];
	}
	
	if (orderMatrix & NSMinuteCalendarUnit) {
		[orderStrings addObject:@"minute"];
	}
	
	if (orderMatrix & NSSecondCalendarUnit) {
		[orderStrings addObject:@"second"];
	}
	
	/* Build compare information. */
	NSCalendar *sysCalendar = [NSCalendar currentCalendar];
	
	NSDate *date1 = [NSDate date];
	NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:(-(dateInterval + 1))];
	
	/* Perform comparison. */
	NSDateComponents *breakdownInfo = [sysCalendar components:orderMatrix fromDate:date1 toDate:date2 options:0];
	
	if (breakdownInfo) {
		NSMutableString *finalResult = [NSMutableString string];
		
		for (NSString *unit in orderStrings) {
			/* For each entry in the orderMatrix, we call that selector name on the
			 comparison result to retreive whatever information it contains. */
			NSInteger total = (NSInteger)objc_msgSend(breakdownInfo, NSSelectorFromString(unit));
			
			if (total < 0) {
				total *= -1;
			}
			
			/* If results isn't zero, we show it. */
			if (total >= 1) {
				NSString *languageKey;
				
				if (total > 1 || total < 1) {
					languageKey = [NSString stringWithFormat:@"BasicLanguage[1204][%@]", [unit uppercaseString]];
				} else {
					languageKey = [NSString stringWithFormat:@"BasicLanguage[1205][%@]", [unit uppercaseString]];
				}
				
				/* shortValue returns only the first time component. */
				if (shortValue) {
					return [NSString stringWithFormat:@"%ld %@", total, TXTLS(languageKey)];
				} else {
					[finalResult appendFormat:@"%ld %@, ", total, TXTLS(languageKey)];
				}
			}
		}
		
		if ([finalResult length]) {
			/* Delete the end ", " */
			NSRange cutRange = NSMakeRange(([finalResult length] - 2), 2);
			
			[finalResult deleteCharactersInRange:cutRange];
		} else {
			/* Return "0 seconds" when there are no results. */
			NSString *emptyTime = [NSString stringWithFormat:@"0 %@", TXTLS(@"BasicLanguage[1204][SECOND]")];
			
			[finalResult setString:emptyTime];
		}
		
		return finalResult;
	}
	
	return nil;
}

NSDateFormatter *TXSharedISOStandardDateFormatter(void)
{
	static NSDateFormatter *_isoStandardDateFormatter;
	
	if (_isoStandardDateFormatter == nil) {
		NSDateFormatter *dateFormatter = [NSDateFormatter new];
		
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"]; //2011-10-19T16:40:51.620Z
		
		_isoStandardDateFormatter = dateFormatter;
	}
	
	return _isoStandardDateFormatter;
}

#pragma mark -
#pragma mark Localized String File.

NSString *TXTLS(NSString *key, ...)
{
	/* Build result using newer API. */
	va_list args;
	va_start(args, key);
	
	NSString *result = TXLocalizedString(RZMainBundle(), key, args);
	
	va_end(args);
	
	/* Return result. */
	return result;
}

NSString *BLS(NSInteger key, ...)
{
	/* Build result using newer API. */
	va_list args;
	va_start(args, key);
	
	NSString *resultKey = [NSString stringWithFormat:@"BasicLanguage[%i]", key];
	
	NSString *result = TXLocalizedString(RZMainBundle(), resultKey, args);
	
	va_end(args);
	
	/* Return result. */
	return result;
}

NSString *TXLocalizedString(NSBundle *bundle, NSString *key, va_list args)
{
	/* Get the unformatted value. */
	NSString *languageString  = [TLOLanguagePreferences localizedStringWithKey:key from:bundle];
	
	/* Format it based on input. */
	NSString *formattedString = [[NSString alloc] initWithFormat:languageString arguments:args];
	
	/* Return result. */
	return formattedString;
}

NSString *TXLocalizedStringAlternative(NSBundle *bundle, NSString *key, ...)
{
	/* Build result using newer API. */
	va_list args;
	va_start(args, key);
	
	NSString *result = TXLocalizedString(bundle, key, args);
	
	va_end(args);
	
	/* Return result. */
	return result;
}

#pragma mark -
#pragma mark Grand Central Dispatch

void TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueOperationType operationType, dispatch_block_t block)
{
	dispatch_queue_t workerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	TXPerformBlockOnDispatchQueue(workerQueue, block, operationType);
}

void TXPerformBlockOnMainDispatchQueue(TXPerformBlockOnDispatchQueueOperationType operationType, dispatch_block_t block)
{
	dispatch_queue_t workerQueue = dispatch_get_main_queue();
	
	TXPerformBlockOnDispatchQueue(workerQueue, block, operationType);
}

void TXPerformBlockOnDispatchQueue(dispatch_queue_t queue, dispatch_block_t block, TXPerformBlockOnDispatchQueueOperationType operationType)
{
	if (operationType == TXPerformBlockOnDispatchQueueSyncOperationType) {
		dispatch_sync(queue, block);
	}
	
	if (operationType == TXPerformBlockOnDispatchQueueAsyncOperationType) {
		dispatch_async(queue, block);
	}
	
	if (operationType == TXPerformBlockOnDispatchQueueBarrierSyncOperationType) {
		dispatch_barrier_sync(queue, block);
	}
	
	if (operationType == TXPerformBlockOnDispatchQueueBarrierAsyncOperationType) {
		dispatch_barrier_async(queue, block);
	}
}

#pragma mark -
#pragma mark Misc.

NSInteger TXRandomNumber(NSInteger maxset)
{
	NSAssertReturnR((maxset > 0), 0);
	
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
