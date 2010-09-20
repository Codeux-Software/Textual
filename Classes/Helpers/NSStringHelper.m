// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "NSStringHelper.h"
#import "UnicodeHelper.h"
#import "Preferences.h"
#import "LogRenderer.h"
#import "URLParser.h"

#define LF	0xa
#define CR	0xd

@implementation NSString (NSStringHelper)

- (NSString *)safeSubstringFromIndex:(NSUInteger)anIndex
{
	if ([self length] < anIndex) return nil;
	
	return [self substringFromIndex:anIndex];
}

- (NSString *)safeSubstringToIndex:(NSUInteger)anIndex
{
	if ([self length] < anIndex) return nil;
	
	return [self substringToIndex:anIndex];
}

- (NSString*)fastChopEndWithChars:(NSArray*)chars
{
	NSInteger chopMnt = 0;
	NSInteger slnt = [self length];
	
	NSString *slchar = @"";
	NSString *strChopper = self;
	
	for (NSInteger i = 1; i < 4; i++) {
		slchar = [strChopper safeSubstringFromIndex:([strChopper length] - 1)];
		strChopper = [strChopper safeSubstringToIndex:([strChopper length] - 1)];
		
		if (![chars containsObject:slchar]) {
			break;
		}
		
		chopMnt++;
	}
	
	if (chopMnt > 0) {
		return [self safeSubstringToIndex:(slnt - chopMnt)];
	}
	
	return self;
}

- (const UniChar*)getCharactersBuffer
{
	NSUInteger len = self.length;
	const UniChar* buffer = CFStringGetCharactersPtr((CFStringRef)self);
	if (!buffer) {
		NSMutableData* data = [NSMutableData dataWithLength:len * sizeof(UniChar)];
		if (!data) return NULL;
		[self getCharacters:[data mutableBytes]];
		buffer = [data bytes];
		if (!buffer) return NULL;
	}
	return buffer;
}

- (BOOL)isEqualNoCase:(NSString*)other
{
	return [self caseInsensitiveCompare:other] == NSOrderedSame;
}

- (BOOL)isEmpty
{
	return [self length] == 0;
}

- (BOOL)contains:(NSString*)str
{
	NSRange r = [self rangeOfString:str];
	return r.location != NSNotFound;
}

- (BOOL)containsIgnoringCase:(NSString*)str
{
	NSRange r = [self rangeOfString:str options:NSCaseInsensitiveSearch];
	return r.location != NSNotFound;
}

- (NSInteger)findCharacter:(UniChar)c
{
	return [self findCharacter:c start:0];
}

- (NSInteger)findCharacter:(UniChar)c start:(NSInteger)start
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(c, 1)] options:0 range:NSMakeRange(start, [self length] - start)];
	if (r.location != NSNotFound) {
		return r.location;
	} else {
		return -1;
	}
}

- (NSInteger)findString:(NSString*)str
{
	NSRange r = [self rangeOfString:str];
	if (r.location != NSNotFound) {
		return r.location;
	} else {
		return -1;
	}
}

- (NSArray*)split:(NSString*)delimiter
{
	NSMutableArray* ary = [NSMutableArray array];
	NSInteger start = 0;
	
	while (start < self.length) {
		NSRange r = [self rangeOfString:delimiter options:0 range:NSMakeRange(start, self.length-start)];
		if (r.location == NSNotFound) break;
		[ary addObject:[self substringWithRange:NSMakeRange(start, r.location - start)]];
		start = NSMaxRange(r);
	}
	
	if (start < self.length) {
		[ary addObject:[self substringWithRange:NSMakeRange(start, self.length - start)]];
	}
	
	return ary;
}

- (NSArray*)splitIntoLines
{
	NSInteger len = self.length;
	UniChar buf[len];
	[self getCharacters:buf range:NSMakeRange(0, len)];
	
	NSMutableArray* lines = [NSMutableArray array];
	NSInteger start = 0;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buf[i];
		if (c == LF || c == CR) {
			NSInteger pos = i;
			if (c == CR && i+1 < len) {
				UniChar next = buf[i+1];
				if (next == LF) {
					++i;
				}
			}
			
			NSString* s = [[NSString alloc] initWithCharacters:buf+start length:pos - start];
			[lines addObject:s];
			[s release];
			
			start = i + 1;
		}
	}
	
	NSString* s = [[NSString alloc] initWithCharacters:buf+start length:len - start];
	[lines addObject:s];
	[s release];
	
	return lines;
}

- (NSString*)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isIPAddress
{
	BOOL isValidatedIP = YES;
	
	NSArray *chunks = [self componentsSeparatedByString:@"."];
	
	if (chunks || [chunks count] != 4) {
		for (NSString *quad in chunks) {
			NSInteger q = [quad integerValue];
			
			if (!q) isValidatedIP = NO; 
			if (q < 0 || q > 255) isValidatedIP = NO; 
		}
	} else {
		isValidatedIP = NO; 
	}
	
	return isValidatedIP;
}

- (BOOL)isNumericOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsNumeric(c))) {
			return NO;
		}
	}
	return YES;
}

- (BOOL)isAlphaNumOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsAlphaNum(c))) {
			return NO;
		}
	}
	return YES;
}

BOOL isSurrogate(UniChar c)
{
	return 0xd800 <= c && c <= 0xdfff;
}

BOOL isHighSurrogate(UniChar c)
{
	return 0xd800 <= c && c <= 0xdbff;
}

BOOL isLowSurrogate(UniChar c)
{
	return 0xdc00 <= c && c <= 0xdfff;
}

- (NSInteger)firstCharCodePoint
{
	NSInteger len = self.length;
	if (len == 0) return -1;
	
	NSInteger c = [self characterAtIndex:0];
	if (isHighSurrogate(c)) {
		if (len <= 1) return c;
		NSInteger d = [self characterAtIndex:1];
		if (isLowSurrogate(d)) {
			return (c - 0xd800) * 0x400 + (d - 0xdc00) + 0x10000;
		} else {
			return -1;
		}
	}
	return c;
}

- (NSInteger)lastCharCodePoint
{
	NSInteger len = self.length;
	if (len == 0) return -1;
	
	NSInteger c = [self characterAtIndex:len-1];
	if (isLowSurrogate(c)) {
		if (len <= 1) return c;
		NSInteger d = [self characterAtIndex:len-2];
		if (isHighSurrogate(d)) {
			return (d - 0xd800) * 0x400 + (c - 0xdc00) + 0x10000;
		} else {
			return -1;
		}
	}
	return c;
}

NSInteger ctoi(unsigned char c)
{
	if ('0' <= c && c <= '9') {
		return c - '0';
	} else if ('a' <= c && c <= 'f') {
		return c - 'a' + 10;
	} else if ('A' <= c && c <= 'F') {
		return c - 'A' + 10;
	} else {
		return 0;
	}
}

BOOL isUnicharDigit(unichar c)
{
	return '0' <= c && c <= '9';
}

- (NSString*)safeUsername
{
	NSInteger len = self.length;
	const UniChar* buf = [self getCharactersBuffer];
	
	UniChar dest[len];
	NSInteger n = 0;
	
	for (NSInteger i=0; i<len; i++) {
		UniChar c = buf[i];
		if (IsWordLetter(c)) {
			dest[n++] = c;
		} else {
			dest[n++] = '_';
		}
	}
	
	return [[[NSString alloc] initWithCharacters:dest length:n] autorelease];
}

- (NSString*)safeFileName
{
	NSString* s = [self stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	return [s stringByReplacingOccurrencesOfString:@":" withString:@"_"];
}

- (NSInteger)stringPosition:(NSString*)needle
{
	NSRange r = [self rangeOfString:needle];
	if (r.location == NSNotFound) return -1;
	return r.location;
}

- (id)attributedStringWithIRCFormatting
{
	if ([Preferences removeAllFormatting]) {
		return [[[NSAttributedString alloc] initWithString:[self stripEffects]] autorelease];
	}
	
	return [LogRenderer renderBody:self
						   nolinks:NO
						  keywords:nil
					  excludeWords:nil
					exactWordMatch:NO
					   highlighted:NULL
						 URLRanges:NULL
				  attributedString:YES];
}

- (NSString*)stripEffects
{
	NSInteger len = self.length;
	if (len == 0) return self;
	
	NSInteger buflen = len * sizeof(unichar);
	
	unichar* src = alloca(buflen);
	[self getCharacters:src];
	
	unichar* buf = alloca(buflen);
	NSInteger pos = 0;
	
	for (NSInteger i=0; i<len; i++) {
		unichar c = src[i];
		if (c < 0x20) {
			switch (c) {
				case 0x2:
				case 0xf:
				case 0x16:
				case 0x1f:
					break;
				case 0x3:
					if (i+1 >= len) continue;
					unichar d = src[i+1];
					if (!isUnicharDigit(d)) continue;
					i++;
					
					if (i+1 >= len) continue;
					unichar e = src[i+1];
					if (!IsIRCColor(e, (d - '0')) && e != ',') continue;
					i++;
					BOOL comma = (e == ',');
					
					if (!comma) {
						if (i+1 >= len) continue;
						unichar f = src[i+1];
						if (f != ',') continue;
						i++;
					}
					
					if (i+1 >= len) continue;
					unichar g = src[i+1];
					if (!isUnicharDigit(g)) continue;
					i++;
					
					if (i+1 >= len) continue;
					unichar h = src[i+1];
					if (!IsIRCColor(h, (g - '0'))) continue;
					i++;
					break;
				default:
					buf[pos++] = c;
					break;
			}
		} else {
			buf[pos++] = c;
		}
	}
	
	return [[[NSString alloc] initWithCharacters:buf length:pos] autorelease];
}

- (BOOL)isChannelName
{
	if (self.length == 0) return NO;
	UniChar c = [self characterAtIndex:0];
	return c == '#' || c == '&' || c == '+' || c == '!' || c == '~' || c == '?';
}

- (BOOL)isModeChannelName
{
	if (self.length == 0) return NO;
	UniChar c = [self characterAtIndex:0];
	return c == '#' || c == '&' || c == '!' || c == '~' || c == '?';
}

- (NSString*)canonicalName
{
	return [self lowercaseString];
}

- (NSRange)rangeOfUrl
{
	return [self rangeOfUrlStart:0];
}

- (NSRange)rangeOfUrlStart:(NSInteger)start
{
	return [URLParser rangeOfUrlStart:start withString:self];
}

- (NSRange)rangeOfAddress
{
	return [self rangeOfAddressStart:0];
}

- (NSRange)rangeOfAddressStart:(NSInteger)start
{
	NSInteger len = self.length;
	if (len <= start) return NSMakeRange(NSNotFound, 0);
	
	NSString *shortstring = [self safeSubstringFromIndex:start];
	NSRange rs = [shortstring rangeOfRegex:@"([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}|([a-f0-9]{0,4}:){7}[a-f0-9]{0,4}|([0-9]{1,3}\\.){3}[0-9]{1,3}"];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSInteger prev = r.location - 1;
	if (0 <= prev && prev < len) {
		UniChar c = [self characterAtIndex:prev];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	NSInteger next = NSMaxRange(r);
	if (next < len) {
		UniChar c = [self characterAtIndex:next];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	return r;
}

- (NSRange)rangeOfChannelName
{
	return [self rangeOfChannelNameStart:0];
}

- (NSRange)rangeOfChannelNameStart:(NSInteger)start
{
	NSInteger len = self.length;
	if (len <= start) return NSMakeRange(NSNotFound, 0);
	
	NSString *shortstring = [self safeSubstringFromIndex:start];
	NSRange rs = [shortstring rangeOfRegex:@"(?<![a-zA-Z0-9_])[#\\&][^ \\t,　]+"];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSInteger prev = r.location - 1;
	if (0 <= prev && prev < len) {
		UniChar c = [self characterAtIndex:prev];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	NSInteger next = NSMaxRange(r);
	if (next < len) {
		UniChar c = [self characterAtIndex:next];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	return r;
}

- (NSString*)encodeURIComponent
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString*)encodeURIFragment
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c)
			|| c == '#'
			|| c == '%'
			|| c == '&'
			|| c == '+'
			|| c == ','
			|| c == '-'
			|| c == '.'
			|| c == '/'
			|| c == ':'
			|| c == ';'
			|| c == '='
			|| c == '?'
			|| c == '@'
			|| c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding] autorelease];
}

+ (NSString*)bundleString:(NSString*)key
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}

@end

@implementation NSMutableString (NSMutableStringHelper)

- (NSString*)getToken
{
	static NSCharacterSet* spaceSet = nil;
	if (!spaceSet) {
		spaceSet = [[NSCharacterSet characterSetWithCharactersInString:@" "] retain];
	}
	
	NSRange r = [self rangeOfCharacterFromSet:spaceSet];
	if (r.location != NSNotFound) {
		NSString* result = [self safeSubstringToIndex:r.location];
		NSInteger len = [self length];
		NSInteger pos = r.location + 1;
		while (pos < len && [self characterAtIndex:pos] == ' ') {
			pos++;
		}
		[self deleteCharactersInRange:NSMakeRange(0, pos)];
		return result;
	}
	
	NSString* result = [[self copy] autorelease];
	[self setString:@""];
	return result;
}

- (NSString*)getIgnoreToken
{
	BOOL useAnchor = NO;
	UniChar anchor;
	BOOL escaped = NO;
	
	NSInteger len = [self length];
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (i == 0) {
			if (c == '/') {
				useAnchor = YES;
				anchor = '/';
				continue;
			}
			else if (c == '"') {
				useAnchor = YES;
				anchor = '"';
				continue;
			}
		}
		
		if (escaped) {
			escaped = NO;
		}
		else if (c == '\\') {
			escaped = YES;
		}
		else if (useAnchor && c == anchor || !useAnchor && c == ' ') {
			if (useAnchor) {
				++i;
			}
			NSString* result = [self safeSubstringToIndex:i];
			
			NSInteger right;
			for (right=i+1; right<len; ++right) {
				UniChar c = [self characterAtIndex:right];
				if (c != ' ') {
					break;
				}
			}
			
			if (len <= right) {
				right = len;
			}
			
			[self deleteCharactersInRange:NSMakeRange(0, right)];
			return result;
		}
	}
	
	NSString* result = [[self copy] autorelease];
	[self setString:@""];
	return result;
}

@end
