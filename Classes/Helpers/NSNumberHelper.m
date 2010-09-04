#import "NSNumberHelper.h"
#import "NSStringHelper.h"

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