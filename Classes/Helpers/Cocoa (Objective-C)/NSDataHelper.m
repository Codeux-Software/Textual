/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

static char encodingTable[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

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

/* The following method was borrowed from the source code of the 
 Colloquy IRC Client. It is a product of and is copyrighted by the 
 respective ontributors of that project. */

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength 
{
	const unsigned char	*bytes = [self bytes];
    
	NSMutableString *result = [NSMutableString stringWithCapacity:self.length];
    
	unsigned long ixtext = 0;
	unsigned long lentext = self.length;
	unsigned char inbuf[3], outbuf[4];
	unsigned short i = 0;
	unsigned short charsonline = 0, ctcopy = 0;
	unsigned long ix = 0;
    
	long ctremaining = 0;
    
	while (1 == 1) {
		ctremaining = (lentext - ixtext);
        
		if (ctremaining <= 0) {
            break;
        }
        
		for (i = 0; i < 3; i++) {
			ix = (ixtext + i);
			
            if (ix < lentext) {
                inbuf[i] = bytes[ix];
            } else {
                inbuf[i] = 0;
            }
		}
        
		outbuf [0] = ((inbuf [0] & 0xFC) >> 2);
		outbuf [1] = (((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4));
		outbuf [2] = (((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6));
		outbuf [3] = (inbuf [2] & 0x3F);
		ctcopy = 4;
        
		switch (ctremaining) {
            case 1: ctcopy = 2; break;
            case 2: ctcopy = 3; break;
		}
        
		for (i = 0; i < ctcopy; i++) {
			[result appendFormat:@"%c", encodingTable[outbuf[i]]];
        }
        
		for (i = ctcopy; i < 4; i++) {
			[result appendString:@"="];
        }
        
		ixtext      += 3;
		charsonline += 4;
        
		if (lineLength > 0) {
			if (charsonline >= lineLength) {
				charsonline = 0;
				
                [result appendString:@"\n"];
			}
		}
	}
    
	return [NSString stringWithString:result];
}

@end