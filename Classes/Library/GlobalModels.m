// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TIME_BUFFER_SIZE	256

extern BOOL NSObjectIsEmpty(id obj)
{
	if ([obj respondsToSelector:@selector(length)]) {
		return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(length)] < 1);
	} else {
		if ([obj respondsToSelector:@selector(count)]) {
			return (PointerIsEmpty(obj) || (NSInteger)[obj performSelector:@selector(count)] < 1);
		}
	}
	
	return (PointerIsEmpty(obj));
}

extern BOOL NSObjectIsNotEmpty(id obj)
{
	return BOOLReverseValue(NSObjectIsEmpty(obj));
}

extern NSInteger TXRandomThousandNumber(void)
{
	return ((1 + arc4random()) % (9999 + 1));
}

extern NSString *TXTLS(NSString *key)
{
	return [LanguagePreferences localizedStringWithKey:key];
}

extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat) 
{
	NSDictionary *use = nil;
	
	NSDictionary *desc = [NSDictionary dictionaryWithObjectsAndKeys:
						  TXTLS(@"TIME_CONVERT_SECOND"), [NSNumber numberWithUnsignedLong:1], 
						  TXTLS(@"TIME_CONVERT_MINUTE"), [NSNumber numberWithUnsignedLong:60], 
						  TXTLS(@"TIME_CONVERT_HOUR"), [NSNumber numberWithUnsignedLong:3600], 
						  TXTLS(@"TIME_CONVERT_DAY"), [NSNumber numberWithUnsignedLong:86400], 
						  TXTLS(@"TIME_CONVERT_WEEK"), [NSNumber numberWithUnsignedLong:604800], 
						  TXTLS(@"TIME_CONVERT_MONTH"), [NSNumber numberWithUnsignedLong:2628000], 
						  TXTLS(@"TIME_CONVERT_YEAR"), [NSNumber numberWithUnsignedLong:31536000], nil];
	
	NSDictionary *plural = [NSDictionary dictionaryWithObjectsAndKeys:
							TXTLS(@"TIME_CONVERT_SECOND_PLURAL"), [NSNumber numberWithUnsignedLong:1], 
							TXTLS(@"TIME_CONVERT_MINUTE_PLURAL"), [NSNumber numberWithUnsignedLong:60], 
							TXTLS(@"TIME_CONVERT_HOUR_PLURAL"), [NSNumber numberWithUnsignedLong:3600], 
							TXTLS(@"TIME_CONVERT_DAY_PLURAL"), [NSNumber numberWithUnsignedLong:86400], 
							TXTLS(@"TIME_CONVERT_WEEK_PLURAL"), [NSNumber numberWithUnsignedLong:604800], 
							TXTLS(@"TIME_CONVERT_MONTH_PLURAL"), [NSNumber numberWithUnsignedLong:2628000], 
							TXTLS(@"TIME_CONVERT_YEAR_PLURAL"), [NSNumber numberWithUnsignedLong:31536000], nil];
	
	NSMutableArray *breaks = [[[desc allKeys] mutableCopy] autorelease];
	NSTimeInterval secs = ([[NSDate date] timeIntervalSince1970] - date);
	
	NSUInteger val = 0.;
	NSUInteger i = 0, stop = 0;
	
	NSString *retval = nil;
	
	if (secs < 0) {
		secs *= -1;
	}
	
	[breaks sortUsingSelector:@selector(compare:)];
	
	while (i < [breaks count] && secs >= [[breaks safeObjectAtIndex:i] doubleValue]) {
		i++;
	}
	
	if (i > 0) {
		i--;
	}
	
	stop = [[breaks safeObjectAtIndex:i] unsignedIntegerValue];
	
	val = (NSUInteger)(secs / (CGFloat)stop);
	use = ((val > 1) ? plural : desc);
	
	retval = [NSString stringWithFormat:@"%u%@", val, [use objectForKey:[NSNumber numberWithUnsignedLong:stop]]];
	
	if (longFormat && i > 0) {
		NSUInteger rest = (NSUInteger)((NSUInteger) secs % stop);
	
		stop = [[breaks safeObjectAtIndex:--i] unsignedIntegerValue];
		rest = (NSUInteger)(rest / (CGFloat)stop);
		
		if (rest > 0) {
			use = ((rest > 1) ? plural : desc);
			
			retval = [retval stringByAppendingFormat:@" %u%@", rest, [use objectForKey:[breaks safeObjectAtIndex:i]]];
		}
	}
	
	return retval;
}

extern NSString *TXFormattedTimestampWithOverride(NSString *format, NSString *override) 
{
	if (NSObjectIsEmpty(format)) format = @"[%H:%M:%S]";
	if (NSObjectIsNotEmpty(override)) format = override;
	
	time_t global = time(NULL);
	struct tm* local = localtime(&global);
	char buf[TIME_BUFFER_SIZE+1];
	strftime(buf, TIME_BUFFER_SIZE, [format UTF8String], local);
	buf[TIME_BUFFER_SIZE] = 0;
	
	return [[[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding] autorelease];
}

extern NSString *TXFormattedTimestamp(NSString *format) 
{
	return TXFormattedTimestampWithOverride(format, nil);
}
