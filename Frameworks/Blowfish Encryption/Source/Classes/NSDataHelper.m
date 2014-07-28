
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

#import "NSDataHelper.h"

@implementation NSMutableData (BlowfishEncryptionDataHelper)

- (void)removeBadCharacters
{
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x0D" length:1] withBytes:NULL length:0]; // Line break
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x0A" length:1] withBytes:NULL length:0]; // Line feed
	[self replaceAllOccurrencesOfData:[NSData dataWithBytes:"\x00" length:1] withBytes:NULL length:0]; // NULL character
}

- (void)replaceAllOccurrencesOfData:(NSData *)needle withBytes:(const void *)replacementBytes length:(NSUInteger)replacementLength;
{
	NSInteger start = 0;
	
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

@implementation NSData (BlowfishEncryptionDataHelper)

- (NSData *)dataByRemovingBadCharacters
{
	NSMutableData *mut = [self mutableCopy];
	
	[mut removeBadCharacters];
	
	return mut;
}

- (NSData *)repairedCharacterBufferForUTF8Encoding:(NSInteger *)badByteCount
{
	NSUInteger length = [self length];
	
	if (length == 0) {
		return self;
	}
	
	NSInteger totalBadByteCount = 0;
	
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
	
	static NSString* replacementCharacter = @"�";
	
	NSData *replacementCharacterData = [replacementCharacter dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableData *resultData = [NSMutableData dataWithCapacity:[self length]];
	
	const char *bytes = [self bytes];
	
	static const NSUInteger bufferMaxSize = 1024;
	
	char buffer[bufferMaxSize]; // not initialized, but will be filled in completely before copying to resultData
	
	NSUInteger bufferIndex = 0;
	
#define FlushBuffer()	if (bufferIndex > 0) {										\
							[resultData appendBytes:buffer length:bufferIndex];		\
																					\
							bufferIndex = 0;										\
						}
	
#define CheckBuffer()	if ((bufferIndex + 5) >= bufferMaxSize) {					\
							[resultData appendBytes:buffer length:bufferIndex];		\
																					\
							bufferIndex = 0;										\
						}
	
#define UpdateBadByteCount()				*badByteCount = totalBadByteCount;
	
	NSUInteger byteIndex = 0;
	
	BOOL invalidByte = NO;
	
	while (byteIndex < length)
	{
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
				
				UpdateBadByteCount();
				
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
			if ((byteIndex + 2) >= length) {
				FlushBuffer();
				
				UpdateBadByteCount();
				
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
			if ((byteIndex + 3) >= length) {
				FlushBuffer();
				
				UpdateBadByteCount();
				
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
			if ((byteIndex + 4) >= length) {
				FlushBuffer();
				
				UpdateBadByteCount();
				
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
			if ((byteIndex + 5) >= length) {
				FlushBuffer();
				
				UpdateBadByteCount();
				
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
			
			totalBadByteCount += 1;
			
			FlushBuffer();
			
			[resultData appendData:replacementCharacterData];
		}
		
		byteIndex++;
	}
	
	FlushBuffer();
	
	UpdateBadByteCount();
	
	return resultData;
}

@end
