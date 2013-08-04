/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

/* 
	 This source file contains work created by a third-party developer.
	 
	 The piece of the source file in question is the method defenition for 
	 the method call -repairedCharacterBufferForUTF8Encoding.
	 
	 The original license is as follows:
	 
	 // Author: Oleg Andreev <oleganza@gmail.com>
	 // May 28, 2011
	 // Do What The Fuck You Want Public License <http://www.wtfpl.net>
	 
	 https://gist.github.com/oleganza/997155
 */

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

- (NSData *)repairedCharacterBufferForUTF8Encoding
{
	NSUInteger length = [self length];

	if (length == 0) {
		return self;
	}

	//  bits
	//  7   	U+007F      0xxxxxxx
	//  11   	U+07FF      110xxxxx	10xxxxxx
	//  16  	U+FFFF      1110xxxx	10xxxxxx	10xxxxxx
	//  21  	U+1FFFFF    11110xxx	10xxxxxx	10xxxxxx	10xxxxxx
	//  26  	U+3FFFFFF   111110xx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
	//  31  	U+7FFFFFFF  1111110x	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx

#define b00000000 0x00
#define b10000000 0x80
#define b11000000 0xc0
#define b11100000 0xe0
#define b11110000 0xf0
#define b11111000 0xf8
#define b11111100 0xfc
#define b11111110 0xfe

	NSString *replacementCharacter = [NSString stringWithFormat:@"%C", 0xfffd];

	NSData *replacementCharacterData = [replacementCharacter dataUsingEncoding:NSUTF8StringEncoding];

	NSMutableData *resultData = [NSMutableData dataWithCapacity:[self length]];

	const char *bytes = [self bytes];

	static const NSUInteger bufferMaxSize = 1024;

	char buffer[bufferMaxSize]; // not initialized, but will be filled in completely before copying to resultData

	NSUInteger bufferIndex = 0;

#define FlushBuffer()	if (bufferIndex > 0) {												\
							[resultData appendBytes:buffer length:bufferIndex];				\
																							\
							bufferIndex = 0;												\
						}

#define CheckBuffer()	if ((bufferIndex + 5) >= bufferMaxSize) {								\
							[resultData appendBytes:buffer length:bufferIndex];				\
																							\
							bufferIndex = 0;												\
						}

	NSUInteger byteIndex = 0;

	BOOL invalidByte = NO;

	while (byteIndex < length) {
		char byte = bytes[byteIndex];

		// ASCII character is always a UTF-8 character
		if ((byte & b10000000) == b00000000) // 0xxxxxxx
		{
			CheckBuffer();

			buffer[bufferIndex++] = byte;
		}
		else if ((byte & b11100000) == b11000000) // 110xxxxx 10xxxxxx
		{
			if ((byteIndex + 1) >= length) {
				FlushBuffer();

				return resultData;
			}

			char byte2 = bytes[++byteIndex];

			if ((byte2 & b11000000) == b10000000)
			{
				// This 2-byte character still can be invalid. Check if we can create a string with it.
				unsigned char tuple[] = {byte, byte2};

				CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 2, kCFStringEncodingUTF8, false);

				if (cfstr)
				{
					CFRelease(cfstr);

					CheckBuffer();

					buffer[bufferIndex++] = byte;
					buffer[bufferIndex++] = byte2;
				}
				else
				{
					invalidByte = YES;
				}
			}
			else
			{
				byteIndex -= 1;

				invalidByte = YES;
			}
		}
		else if ((byte & b11110000) == b11100000) // 1110xxxx 10xxxxxx 10xxxxxx
		{
			if (byteIndex+2 >= length) {
				FlushBuffer();

				return resultData;
			}
			
			char byte2 = bytes[++byteIndex];
			char byte3 = bytes[++byteIndex];

			if ((byte2 & b11000000) == b10000000 &&
				(byte3 & b11000000) == b10000000)
			{
				// This 3-byte character still can be invalid. Check if we can create a string with it.
				unsigned char tuple[] = {byte, byte2, byte3};

				CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 3, kCFStringEncodingUTF8, false);

				if (cfstr)
				{
					CFRelease(cfstr);

					CheckBuffer();
					
					buffer[bufferIndex++] = byte;
					buffer[bufferIndex++] = byte2;
					buffer[bufferIndex++] = byte3;
				}
				else
				{
					invalidByte = YES;
				}
			}
			else
			{
				byteIndex -= 2;

				invalidByte = YES;
			}
		}
		else if ((byte & b11111000) == b11110000) // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		{
			if (byteIndex+3 >= length) {
				FlushBuffer();

				return resultData;
			}

			char byte2 = bytes[++byteIndex];
			char byte3 = bytes[++byteIndex];
			char byte4 = bytes[++byteIndex];

			if ((byte2 & b11000000) == b10000000 &&
				(byte3 & b11000000) == b10000000 &&
				(byte4 & b11000000) == b10000000)
			{
				// This 4-byte character still can be invalid. Check if we can create a string with it.
				unsigned char tuple[] = {byte, byte2, byte3, byte4};

				CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 4, kCFStringEncodingUTF8, false);

				if (cfstr)
				{
					CFRelease(cfstr);

					CheckBuffer();

					buffer[bufferIndex++] = byte;
					buffer[bufferIndex++] = byte2;
					buffer[bufferIndex++] = byte3;
					buffer[bufferIndex++] = byte4;
				}
				else
				{
					invalidByte = YES;
				}
			}
			else
			{
				byteIndex -= 3;

				invalidByte = YES;
			}
		}
		else if ((byte & b11111100) == b11111000) // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
		{
			if (byteIndex+4 >= length) {
				FlushBuffer();

				return resultData;
			}

			char byte2 = bytes[++byteIndex];
			char byte3 = bytes[++byteIndex];
			char byte4 = bytes[++byteIndex];
			char byte5 = bytes[++byteIndex];

			if ((byte2 & b11000000) == b10000000 &&
				(byte3 & b11000000) == b10000000 &&
				(byte4 & b11000000) == b10000000 &&
				(byte5 & b11000000) == b10000000)
			{
				// This 5-byte character still can be invalid. Check if we can create a string with it.
				unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5};

				CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 5, kCFStringEncodingUTF8, false);

				if (cfstr)
				{
					CFRelease(cfstr);

					CheckBuffer();

					buffer[bufferIndex++] = byte;
					buffer[bufferIndex++] = byte2;
					buffer[bufferIndex++] = byte3;
					buffer[bufferIndex++] = byte4;
					buffer[bufferIndex++] = byte5;
				}
				else
				{
					invalidByte = YES;
				}
			}
			else
			{
				byteIndex -= 4;

				invalidByte = YES;
			}
		}
		else if ((byte & b11111110) == b11111100) // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
		{
			if (byteIndex+5 >= length) {
				FlushBuffer();

				return resultData;
			}

			char byte2 = bytes[++byteIndex];
			char byte3 = bytes[++byteIndex];
			char byte4 = bytes[++byteIndex];
			char byte5 = bytes[++byteIndex];
			char byte6 = bytes[++byteIndex];

			if ((byte2 & b11000000) == b10000000 &&
				(byte3 & b11000000) == b10000000 &&
				(byte4 & b11000000) == b10000000 &&
				(byte5 & b11000000) == b10000000 &&
				(byte6 & b11000000) == b10000000)
			{
				// This 6-byte character still can be invalid. Check if we can create a string with it.
				unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5, byte6};

				CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 6, kCFStringEncodingUTF8, false);

				if (cfstr)
				{
					CFRelease(cfstr);

					CheckBuffer();

					buffer[bufferIndex++] = byte;
					buffer[bufferIndex++] = byte2;
					buffer[bufferIndex++] = byte3;
					buffer[bufferIndex++] = byte4;
					buffer[bufferIndex++] = byte5;
					buffer[bufferIndex++] = byte6;
				}
				else
				{
					invalidByte = YES;
				}

			}
			else
			{
				byteIndex -= 5;

				invalidByte = YES;
			}
		}
		else
		{
			invalidByte = YES;
		}

		if (invalidByte)
		{
			invalidByte = NO;

			FlushBuffer();

			[resultData appendData:replacementCharacterData];
		}

		byteIndex++;
	}

	FlushBuffer();

	return resultData;
}

@end
