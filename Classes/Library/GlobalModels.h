// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

void TXCFSpecialRelease(CFTypeRef cf);

NSString *TXTLS(NSString *key);

extern NSInteger TXRandomThousandNumber(void);
extern NSTimeInterval IntervalSinceTextualStart(void);
extern NSString *TXFormattedTimestamp(NSString *format);
extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat);
extern NSString *promptForInput(NSString *whatFor, 
					  NSString *title, 
					  NSString *defaultButton, 
					  NSString *altButton, 
					  NSString *defaultInput);