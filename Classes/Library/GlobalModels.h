// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

#define BOOLReverseValue(b)		((b == YES) ? NO : YES)

void TXCFSpecialRelease(CFTypeRef cf);

typedef unsigned long long TXFSLongInt; // filesizes

extern NSString *TXTLS(NSString *key);
extern void TXDevNullDestroyObject(void* objt); // Send any object into blackhole - Good for "variable not used" warnings. 
extern NSInteger TXRandomThousandNumber(void);
extern NSTimeInterval IntervalSinceTextualStart(void);
extern NSString *TXFormattedTimestamp(NSString *format);
extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat);
extern NSString *promptForInput(NSString *whatFor, 
								NSString *title, 
								NSString *defaultButton, 
								NSString *altButton, 
								NSString *defaultInput);
extern BOOL promptWithSuppression(NSString *whatFor,
								  NSString *title,
								  NSString *defaultButton,
								  NSString *altButton,
								  NSString *suppressionKey,
								  NSString *suppressionText);