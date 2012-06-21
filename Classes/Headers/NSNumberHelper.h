// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define TXDirtyCGFloatsMatch(s, r)			[NSNumber compareCGFloat:s toFloat:r]

@interface NSNumber (TXNumberHelper)
+ (BOOL)compareIRCColor:(UniChar)c against:(NSInteger)firstNumber;
+ (BOOL)compareCGFloat:(CGFloat)num1 toFloat:(CGFloat)num2;

- (NSString *)integerWithLeadingZero;
@end