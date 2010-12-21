// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define BOOLReverseValue(b)		((b == YES) ? NO : YES)

typedef unsigned long long TXFSLongInt; // filesizes

extern NSString *TXTLS(NSString *key);

extern void TXDevNullDestroyObject(void* objt); // Send any object into blackhole - Good for "variable not used" warnings. 
extern void TXDevNullDestroyBOOLObject(BOOL objt);

extern NSInteger TXRandomThousandNumber(void);
extern NSUserDefaults *TXNSUserDefaultsPointer(void);

extern NSString *TXFormattedTimestamp(NSString *format);
extern NSString *TXFormattedTimestampWithOverride(NSString *format, NSString *override);
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