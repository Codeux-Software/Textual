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

/* This source file contains modified work of the original Dirt IRC proxy
 project hosted at: http://sourceforge.net/projects/dirtirc */

// Copyright (c) 2005-2013 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see License.txt for further information.

#import "Base64Encoding.h"

static NSString *base64CharacterList = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation CSFWBase64Encoding

#pragma mark -
#pragma mark Data Encoding.

+ (NSString *)encodeData:(NSString *)input
{
	NSInteger inputLength = input.length;
	
	if (inputLength <= 0) {
		return nil;
	}

	// ================================================ //

	NSMutableString *encodedResult = [NSMutableString string];

	unsigned char *is = (unsigned char *)[input cStringUsingEncoding:[NSString defaultCStringEncoding]];

	unsigned long data;
	unsigned long di;

	// ================================================ //

	for (NSInteger i = 0; i < inputLength; i += 3)
	{
		data  = (*is++ << 16);
		data += (*is++ << 8);
		data += (*is++);

		// ================================================ //

		for (NSInteger d = 0; d < 4; d++) {
			if (d >= 2 && (i + d) > inputLength) {
				[encodedResult appendString:@"="];
			} else {
				di = ((data >> 18) & 63);

				[encodedResult appendFormat:@"%C", [base64CharacterList characterAtIndex:di]];
			}

			data = (data << 6);
		}
	}

	// ================================================ //
	
	if (encodedResult.length <= 0) {
		return nil;
	}

	return encodedResult;
}

#pragma mark -
#pragma mark Data Decoding.

+ (NSString *)decodeData:(NSString *)input
{
	NSInteger inputLength = input.length;
	
	if (inputLength <= 0 || ((inputLength % 4) == 0) == NO) {
		return nil;
	}

	// ================================================ //

	unsigned char *is = (unsigned char *)[input cStringUsingEncoding:[NSString defaultCStringEncoding]];
	unsigned char  di;
	
	unsigned long data;

	// ================================================ //

	NSMutableString *decodedResult = [NSMutableString string];
	
	NSInteger charPosition = 0;
	NSInteger charPosShift = 0;

	// ================================================ //

	for (NSInteger i = 0; i < inputLength; i += 4)
	{
		di = [input characterAtIndex:i];

		if ((di == '=') == NO && [self find:di in:base64CharacterList] == -1) {
			return nil; // Cancel decode if we found a di that is not Base64 standard.
		}

		// ================================================ //
		
		charPosition = [self find:(*is++) in:base64CharacterList];
		if (charPosition > -1) { data = (charPosition << 18);	}

		charPosition = [self find:(*is++) in:base64CharacterList];
		if (charPosition > -1) { data += (charPosition << 12);	}

		charPosition = [self find:(*is++) in:base64CharacterList];
		if (charPosition > -1) { data += (charPosition << 6);	}

		charPosition = [self find:(*is++) in:base64CharacterList];
		if (charPosition > -1) { data += charPosition;			}

		// ================================================ //

		[decodedResult appendFormat:@"%c", ((data >> 16) & 255)];

		// ================================================ //

		charPosShift = (i + 2);
		
		if (charPosShift < inputLength) {
			di = is[charPosShift];

			if ((di == '=') == NO) {
				[decodedResult appendFormat:@"%c", ((data >> 8) & 255)];
			}
		}

		// ================================================ //
		
		charPosShift = (i + 3);

		if (charPosShift < inputLength) {
			di = is[charPosShift];

			if ((di == '=') == NO) {
				[decodedResult appendFormat:@"%c", (data & 255)];
			}
		}
	}

	// ================================================ //
	
	if (decodedResult.length <= 0) {
		return nil;
	}

	return decodedResult;
}

#pragma mark -
#pragma mark Utilities.

+ (NSInteger)find:(unsigned char)uchar in:(NSString *)stack
{
	NSRange r = [stack rangeOfString:[NSString stringWithFormat:@"%c", uchar]];

	if ((r.location == NSNotFound) == NO) {
		return r.location;
	}

	return -1;
}

@end
