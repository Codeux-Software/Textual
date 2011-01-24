// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TIME_BUFFER_SIZE 256

#pragma mark -
#pragma mark Variable Distruction 

extern void TXDevNullDestroyObject(void* objt) { return; }
extern void TXDevNullDestroyBOOLObject(BOOL objt) { return; }
extern void TXDevNullDestroyOSStatusObject(OSStatus objt) { return; }

#pragma mark -
#pragma mark Miscellaneous Special Functions

extern NSInteger TXRandomThousandNumber(void)
{
	return ((1 + arc4random()) % (9999 + 1));
}

extern NSString *TXTLS(NSString *key)
{
	return [LanguagePreferences localizedStringWithKey:key];
}

#pragma mark -
#pragma mark Input/Confirmation Prompts

extern BOOL promptWithSuppression(NSString *whatFor,
								  NSString *title,
								  NSString *defaultButton,
								  NSString *altButton,
								  NSString *suppressionKey,
								  NSString *suppressionText)
{
	BOOL suppCheck = [TXNSUserDefaults() boolForKey:suppressionKey];
	
	if (suppCheck == YES) return YES;

	NSAlert *alert = [NSAlert alertWithMessageText:((title == nil) ? TXTLS(@"INPUT_REQUIRED_TO_CONTINUE") : title)
									 defaultButton:((defaultButton == nil) ? TXTLS(@"OK_BUTTON") : defaultButton)
								   alternateButton:((altButton == nil) ? TXTLS(@"CANCEL_BUTTON") : altButton)
									   otherButton:nil
						 informativeTextWithFormat:whatFor];
	
	[alert setShowsSuppressionButton:YES];
	
	[[alert suppressionButton] setTitle:((suppressionText == nil) ? TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE") : suppressionText)];
	
	if ([alert runModal] == NSAlertDefaultReturn) {
		[TXNSUserDefaults() setBool:[[alert suppressionButton] state] forKey:suppressionKey];
		
		return YES;
	} else {
		return NO;
	}
}

extern NSString *promptForInput(NSString *whatFor, 
								NSString *title, 
								NSString *defaultButton, 
								NSString *altButton, 
								NSString *defaultInput)
{
	InputPromptDialog *dialog = [[InputPromptDialog alloc] init];
	
	[dialog alertWithMessageText:title 
				   defaultButton:defaultButton 
				 alternateButton:altButton 
				 informativeText:whatFor
				defaultUserInput:defaultInput];
	
	[dialog runModal];
	
	NSInteger button = [dialog buttonClicked];
	NSString *result = [dialog promptValue];
	
	[dialog release];
	
	return ((NSStringIsEmpty(result) == NO && button == NSAlertDefaultReturn) ? result : nil);
}

#pragma mark -
#pragma mark Time/Date Handling

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
	
	if (secs < 0) secs *= -1;
	
	breaks = [[[desc allKeys] mutableCopy] autorelease];
	[breaks sortUsingSelector:@selector(compare:)];
	
	while(i < [breaks count] && secs >= [[breaks safeObjectAtIndex:i] doubleValue]) i++;
	if (i > 0) i--;
	stop = [[breaks safeObjectAtIndex:i] unsignedIntegerValue];
	
	val = (NSUInteger)(secs / (CGFloat)stop);
	use = ((val > 1) ? plural : desc);
	retval = [NSString stringWithFormat:@"%u%@", val, [use objectForKey:[NSNumber numberWithUnsignedLong:stop]]];
	
	if ( longFormat && i > 0 ) {
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
	if (NSStringIsEmpty(format)) format = @"[%H:%M:%S]";
	if (override) format = override;
	
	time_t global = time(NULL);
	struct tm* local = localtime(&global);
	char buf[TIME_BUFFER_SIZE+1];
	strftime(buf, TIME_BUFFER_SIZE, [format UTF8String], local);
	buf[TIME_BUFFER_SIZE] = 0;
	NSString *result = [[[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding] autorelease];
	
	return result;
}

extern NSString *TXFormattedTimestamp(NSString *format) 
{
	return TXFormattedTimestampWithOverride(format, nil);
}

#pragma mark -
#pragma mark Establish Common Pointers

static NSWorkspace *TXNSWorkspacePNTR = nil;
static NSFileManager *TXNSFileManagerPNTR = nil;
static NSUserDefaults *TXNSUserDefaultsPNTR = nil;
static NSNotificationCenter *TXNSNotificationCenterPNTR = nil;

extern NSUserDefaults *TXNSUserDefaults(void) 
{
	if (TXNSUserDefaultsPNTR == nil) TXNSUserDefaultsPNTR = [NSUserDefaults standardUserDefaults];
	
	return TXNSUserDefaultsPNTR;
}

extern NSFileManager *TXNSFileManager(void) 
{
	if (TXNSFileManagerPNTR == nil) TXNSFileManagerPNTR = [NSFileManager defaultManager];
	
	return TXNSFileManagerPNTR;
}

extern NSWorkspace *TXNSWorkspace(void) 
{
	if (TXNSWorkspacePNTR == nil) TXNSWorkspacePNTR = [NSWorkspace sharedWorkspace];
	
	return TXNSWorkspacePNTR;
}

extern NSNotificationCenter *TXNSNotificationCenter(void) 
{
	if (TXNSNotificationCenterPNTR == nil) TXNSNotificationCenterPNTR = [NSNotificationCenter defaultCenter];
	
	return TXNSNotificationCenterPNTR;
}
