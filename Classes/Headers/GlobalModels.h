// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Highest level objects implemented by Textual. */

extern BOOL NSObjectIsEmpty(id obj);
extern BOOL NSObjectIsNotEmpty(id obj);

extern void DevNullDestroyObject(BOOL condition, ...);

extern NSString *TXTLS(NSString *key); // Textual Language String
extern NSString *TXTFLS(NSString *key, ...); // Textual Formatted Language String

extern NSInteger TXRandomThousandNumber(void);

extern NSString *TXFormattedTimestamp(NSString *format);
extern NSString *TXFormattedTimestampWithOverride(NSString *format, NSString *override);

extern NSString *TXReadableTime(NSInteger dateInterval);