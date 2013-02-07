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

@implementation NSData (TXDataHelper)

- (BOOL)isValidUTF8
{
	NSInteger len = [self length];
	
	const unsigned char *bytes = [self bytes];
	
	NSInteger rest = 0;
	NSInteger code = 0;
	
	NSRange range;
	
	for (NSInteger i = 0; i < len; i++) {
		unsigned char c = bytes[i];
		
		if (rest <= 0) {
			if (0x1 <= c && c <= 0x7F) {
				rest = 0;
			} else if (0xC0 <= c && c <= 0xDF) {
				rest = 1;
				code = (c & 0x1F);
				range = NSMakeRange(0x00080, (0x000800 - 0x00080));
			} else if (0xE0 <= c && c <= 0xEF) {
				rest = 2;
				code = (c & 0x0F);
				range = NSMakeRange(0x00800, (0x010000 - 0x00800));
			} else if (0xF0 <= c && c <= 0xF7) {
				rest = 3;
				code = (c & 0x07);
				range = NSMakeRange(0x10000, (0x110000 - 0x10000));
			} else {
				return NO;
			}
		} else if (0x80 <= c && c <= 0xBF) {
			code = (code << 6) | (c & 0x3F);
			
			if (--rest <= 0) {
				if (NSLocationInRange(code, range) == NO || (0xD800 <= code && code <= 0xDFFF)) {
					return NO;
				}
			}
		} else {
			return NO;
		}
	}
	
	return YES;
}

- (NSString *)validateUTF8
{
	return [self validateUTF8WithCharacter:0x3F];
}

- (NSString *)validateUTF8WithCharacter:(UniChar)malformChar
{
	NSInteger len = [self length];
	
	const unsigned char *bytes = [self bytes];
    
	UniChar buf[len];
	
	NSInteger n = 0;
	NSInteger rest = 0;
	NSInteger code = 0;
	
	NSRange range;
	
	for (NSInteger i = 0; i < len; i++) {
		unsigned char c = bytes[i];
		
		if (rest <= 0) {
			if (0x1 <= c && c <= 0x7F) {
				rest = 0;
			} else if (0xC0 <= c && c <= 0xDF) {
				rest = 1;
				code = (c & 0x1F);
				range = NSMakeRange(0x00080, (0x000800 - 0x00080));
			} else if (0xE0 <= c && c <= 0xEF) {
				rest = 2;
				code = (c & 0x0F);
				range = NSMakeRange(0x00800, (0x010000 - 0x00800));
			} else if (0xF0 <= c && c <= 0xF7) {
				rest = 3;
				code = (c & 0x07);
				range = NSMakeRange(0x10000, (0x110000 - 0x10000));
			} else {
				return nil;
			}
		} else if (0x80 <= c && c <= 0xBF) {
			code = (code << 6) | (c & 0x3F);
			
			if (--rest <= 0) {
				if (NSLocationInRange(code, range) == NO || (0xD800 <= code && code <= 0xDFFF)) {
					code = malformChar;
				}
				
				buf[n++] = code;
			}
		} else {
			buf[n++] = code;
			rest = 0;
		}
	}
	
	return [[NSString alloc] initWithCharacters:buf length:n];
}

@end