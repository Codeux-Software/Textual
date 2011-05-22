// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Highest level objects implemented by Textual. */

TEXTUAL_EXTERN BOOL NSObjectIsEmpty(id obj);
TEXTUAL_EXTERN BOOL NSObjectIsNotEmpty(id obj);

TEXTUAL_EXTERN void DevNullDestroyObject(BOOL condition, ...);

TEXTUAL_EXTERN NSString *TXTLS(NSString *key); // Textual Language String
TEXTUAL_EXTERN NSString *TXTFLS(NSString *key, ...); // Textual Formatted Language String

TEXTUAL_EXTERN NSInteger TXRandomNumber(NSInteger maxset);

TEXTUAL_EXTERN NSString *TXFormattedTimestamp(NSString *format);
TEXTUAL_EXTERN NSString *TXFormattedTimestampWithOverride(NSString *format, NSString *override);

TEXTUAL_EXTERN NSString *TXReadableTime(NSInteger dateInterval);
TEXTUAL_EXTERN NSString *TXSpecialReadableTime(NSInteger dateInterval, BOOL shortValue);

TEXTUAL_EXTERN NSString *TXFormattedNumber(NSInteger number);