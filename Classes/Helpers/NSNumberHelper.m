// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSNumber (NSNumberHelper)

+ (BOOL)compareIRCColor:(UniChar)c against:(NSInteger)firstNumber
{
	if (IsNumeric(c) && firstNumber < 2) {
		NSInteger ci = c - '0';
		
		if ((firstNumber == 0 && ((ci >= 1 && ci <= 9) || ci == 0)) || 
			(firstNumber == 1 && ((ci >= 1 && ci <= 5) || ci == 0))) {
			
			return YES;
		}
	}
	
	return NO;
}

@end