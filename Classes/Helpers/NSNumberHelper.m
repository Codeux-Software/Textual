// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSNumber (NSNumberHelper)

+ (BOOL)compareIRCColor:(UniChar)c against:(NSInteger)firstNumber
{
	if (IsNumeric(c) && firstNumber < 2) {
		NSInteger ci = (c - '0');
		
		if ((firstNumber == 0 && ((ci >= 1 && ci <= 9) || ci == 0)) || 
			(firstNumber == 1 && ((ci >= 1 && ci <= 5) || ci == 0))) {
			
			return YES;
		}
	}
	
	return NO;
}

+ (BOOL)compareCGFloat:(CGFloat)num1 toFloat:(CGFloat)num2
{
	NSString *bleh1 = [NSString stringWithFormat:@"%.2f", num1];
	NSString *bleh2 = [NSString stringWithFormat:@"%.2f", num2];
	
	return [bleh1 isEqualToString:bleh2];
}

- (NSString *)integerWithLeadingZero
{
	NSString *ints = [self stringValue];
	NSInteger intv = [self integerValue];
	
	if (intv >= 0 && intv <= 9) {
		return [@"0" stringByAppendingString:ints];
	}
	
	return ints;
}

@end