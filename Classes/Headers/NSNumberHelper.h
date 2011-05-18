// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define DirtyCGFloatsMatch(s, r)			[NSNumber compareCGFloat:s toFloat:r]

@interface NSNumber (NSNumberHelper)
+ (BOOL)compareIRCColor:(UniChar)c against:(NSInteger)firstNumber;
+ (BOOL)compareCGFloat:(CGFloat)num1 toFloat:(CGFloat)num2;

- (NSString *)integerWithLeadingZero;
@end