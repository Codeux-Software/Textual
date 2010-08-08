// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "GlobalModels.h"
#import "Preferences.h"

#define TIME_BUFFER_SIZE 256

extern void TXDevNullDestroyObject(void* objt)
{
	return;
}

extern NSInteger TXRandomThousandNumber(void)
{
	return (1 + arc4random() % (9999 + 1));
}

void TXCFSpecialRelease(CFTypeRef cf)
{
	if (!cf || cf == NULL || cf == nil) return;
	
	CFRelease(cf);
}

extern NSTimeInterval IntervalSinceTextualStart(void)
{
	return (NSTimeInterval)[Preferences startTime];
}

NSString *TXTLS(NSString *key)
{
	return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);;
}

extern NSString *promptForInput(NSString *whatFor, 
								NSString *title, 
								NSString *defaultButton, 
								NSString *altButton, 
								NSString *defaultInput)
{
	NSAlert *alert = [NSAlert alertWithMessageText:((title == nil) ? TXTLS(@"INPUT_REQUIRED_TO_CONTINUE") : title)
									 defaultButton:((defaultButton == nil) ? TXTLS(@"OK_BUTTON") : defaultButton)
								   alternateButton:((altButton == nil) ? TXTLS(@"CANCEL_BUTTON") : altButton)
									   otherButton:nil
						 informativeTextWithFormat:whatFor];
	
	NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
	
	if (defaultInput != nil) {
		[input setStringValue:defaultInput];
	}
	
	[alert setAccessoryView:input];
	
	NSInteger button = [alert runModal];
	if (button == NSAlertDefaultReturn) {
		NSString *result = [[input stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[input release];
		
		if ([result length] < 1) {
			return nil;
		} else {
			return result;
		}
	} else {
		[input release];
		return nil;
	}
}

extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat) 
{
	NSTimeInterval secs = [[NSDate date] timeIntervalSince1970] - date;
	NSUInteger i = 0, stop = 0;
	NSDictionary *desc = [NSDictionary dictionaryWithObjectsAndKeys:TXTLS(@"TIME_CONVERT_SECOND"), [NSNumber numberWithUnsignedLong:1], TXTLS(@"TIME_CONVERT_MINUTE"), [NSNumber numberWithUnsignedLong:60], TXTLS(@"TIME_CONVERT_HOUR"), [NSNumber numberWithUnsignedLong:3600], TXTLS(@"TIME_CONVERT_DAY"), [NSNumber numberWithUnsignedLong:86400], TXTLS(@"TIME_CONVERT_WEEK"), [NSNumber numberWithUnsignedLong:604800], TXTLS(@"TIME_CONVERT_MONTH"), [NSNumber numberWithUnsignedLong:2628000], TXTLS(@"TIME_CONVERT_YEAR"), [NSNumber numberWithUnsignedLong:31536000], nil];
	NSDictionary *plural = [NSDictionary dictionaryWithObjectsAndKeys:TXTLS(@"TIME_CONVERT_SECOND_PLURAL"), [NSNumber numberWithUnsignedLong:1], TXTLS(@"TIME_CONVERT_MINUTE_PLURAL"), [NSNumber numberWithUnsignedLong:60], TXTLS(@"TIME_CONVERT_HOUR_PLURAL"), [NSNumber numberWithUnsignedLong:3600], TXTLS(@"TIME_CONVERT_DAY_PLURAL"), [NSNumber numberWithUnsignedLong:86400], TXTLS(@"TIME_CONVERT_WEEK_PLURAL"), [NSNumber numberWithUnsignedLong:604800], TXTLS(@"TIME_CONVERT_MONTH_PLURAL"), [NSNumber numberWithUnsignedLong:2628000], TXTLS(@"TIME_CONVERT_YEAR_PLURAL"), [NSNumber numberWithUnsignedLong:31536000], nil];
	NSDictionary *use = nil;
	NSMutableArray *breaks = nil;
	NSUInteger val = 0.;
	NSString *retval = nil;
	
	if( secs < 0 ) secs *= -1;
	
	breaks = [[[desc allKeys] mutableCopy] autorelease];
	[breaks sortUsingSelector:@selector( compare: )];
	
	while( i < [breaks count] && secs >= [[breaks safeObjectAtIndex:i] doubleValue] ) i++;
	if( i > 0 ) i--;
	stop = [[breaks safeObjectAtIndex:i] unsignedIntegerValue];
	
	val = (NSUInteger) ( secs / (CGFloat) stop );
	use = ( val > 1 ? plural : desc );
	retval = [NSString stringWithFormat:@"%u%@", val, [use objectForKey:[NSNumber numberWithUnsignedLong:stop]]];
	if( longFormat && i > 0 ) {
		NSUInteger rest = (NSUInteger) ( (NSUInteger) secs % stop );
		stop = [[breaks safeObjectAtIndex:--i] unsignedIntegerValue];
		rest = (NSUInteger) ( rest / (CGFloat) stop );
		if( rest > 0 ) {
			use = ( rest > 1 ? plural : desc );
			retval = [retval stringByAppendingFormat:@" %u%@", rest, [use objectForKey:[breaks safeObjectAtIndex:i]]];
		}
	}
	
	return retval;
}

extern NSString *TXFormattedTimestamp(NSString *format) 
{
	if ([format length] < 1) {
		format = @"[%m/%d/%Y -:- %I:%M:%S %p]";
	}
	
	time_t global = time(NULL);
	struct tm* local = localtime(&global);
	char buf[TIME_BUFFER_SIZE+1];
	strftime(buf, TIME_BUFFER_SIZE, [format UTF8String], local);
	buf[TIME_BUFFER_SIZE] = 0;
	NSString* result = [[[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding] autorelease];
	return result;
}
