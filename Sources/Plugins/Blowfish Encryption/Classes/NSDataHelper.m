/* *********************************************************************
 *
 *         Copyright (c) 2015 - 2018 Codeux Software, LLC
 *     Please see ACKNOWLEDGEMENT for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of "Codeux Software, LLC", nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSDataHelper.h"

@implementation NSMutableData (BlowfishEncryptionDataHelper)

- (void)removeBadCharacters
{
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x0D" length:1] withBytes:NULL length:0]; // Line break
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x0A" length:1] withBytes:NULL length:0]; // Line feed
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x00" length:1] withBytes:NULL length:0]; // NULL character
}

- (void)replaceAllOccurrencesOfData:(NSData *)needle withBytes:(const void *)replacementBytes length:(NSUInteger)replacementLength
{
	NSUInteger start = 0;
	
	while (1 == 1) {
		if (start >= [self length]) {
			break;
		}
		
		NSRange r = [self rangeOfData:needle options:0 range:NSMakeRange(start, ([self length] - start))];

		if (r.location == NSNotFound) {
			break;
		}
		
		[self replaceBytesInRange:r withBytes:replacementBytes length:replacementLength];;
		
		start = (r.location + replacementLength + 1);
	}
}

@end

@implementation NSString (BlowfishEncryptionStringHelper)

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding fitToPadding:(NSInteger)bytePadding trimmedCharacters:(NSInteger *)bytesRemoved
{
	if (bytePadding <= 0) {
		return nil;
	}

	NSData *dataObject = [self dataUsingEncoding:encoding allowLossyConversion:NO];

	NSUInteger dataObjectLength = [dataObject length];
	NSUInteger dataObjectLengthRemainder = (dataObjectLength % bytePadding);

	if (dataObjectLengthRemainder > 0) {
		dataObjectLength -= dataObjectLengthRemainder;

		if ( bytesRemoved) {
			*bytesRemoved = dataObjectLengthRemainder;
		}

		return [NSData dataWithBytes:[dataObject bytes] length:dataObjectLength];
	} else {
		if ( bytesRemoved) {
			*bytesRemoved = 0;
		}

		return dataObject;
	}
}

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding paddedByBytes:(NSInteger)bytePadding
{
	if (bytePadding <= 0) {
		return nil;
	}

	NSData *dataObject = [self dataUsingEncoding:encoding allowLossyConversion:NO];

	NSUInteger dataObjectLength = [dataObject length];
	NSUInteger dataObjectLengthRemainder = (dataObjectLength % bytePadding);

	if (dataObjectLengthRemainder > 0) {
		NSMutableData *dataObjectMutable = [dataObject mutableCopy];

		[dataObjectMutable increaseLengthBy:(bytePadding - dataObjectLengthRemainder)];

		return [dataObjectMutable copy];
	} else {
		return dataObject;
	}
}

@end
