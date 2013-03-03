/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation NSNumber (TXNumberHelper)

+ (BOOL)compareIRCColor:(UniChar)c against:(NSInteger)firstNumber
{
	/* An IRC color is interpreted using a value of 00 to 15. This 
	 method is used mainly in situations in which each character of 
	 a string is exaimined one by one. 
	 
	 The firstNumber given to this method is either a 0 or 1. If it is
	 neither, then the number is not valid. Next, the c, or second part
	 of firstNumber has to be 0 to 5 if firstNumber = 1, or it can be 0
	 to 9 if firstNumber = 0. 
	 
	 The method basically combines firstNumber and c to make sure it is
	 within 00 and 15. */
	
	if (TXStringIsBase10Numeric(c) && firstNumber < 2) {
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

- (NSString *)integerWithLeadingZero:(NSInteger)forcedWidth
{
	NSInteger trlzp = (forcedWidth - self.stringValue.length);

	if (trlzp <= 0) {
		return self.stringValue;
	} else {
		NSMutableString *ints = [NSMutableString string];

		for (NSInteger i = 0; i < trlzp; i++) {
			[ints appendString:@"0"];
		}

		[ints appendString:self.stringValue];

		return ints;
	}
}

- (NSString *)integerWithLeadingZero
{
	NSInteger intv = [self integerValue];

	if (intv >= 0 && intv <= 9) {
		return [@"0" stringByAppendingString:self.stringValue];
	}

	return self.stringValue;
}

@end
