// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define LF	0xa
#define CR	0xd

@implementation NSString (NSStringHelper)

/* Private Header */
BOOL isSurrogate(UniChar c);
BOOL isHighSurrogate(UniChar c);
BOOL isLowSurrogate(UniChar c);
BOOL isUnicharDigit(unichar c);

NSInteger ctoi(unsigned char c);

/* Helper Methods */
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding
{
	return [[[NSString alloc] initWithBytes:bytes length:length encoding:encoding] autodrain];
}

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[[NSString alloc] initWithData:data encoding:encoding] autodrain];
}

- (NSString *)safeSubstringWithRange:(NSRange)range;
{
	if (range.location == NSNotFound) return nil;
	if (range.length > [self length]) return nil;
	if (range.location > [self length]) return nil;
	
	return [self substringWithRange:range];
}

- (NSString *)safeSubstringAfterIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex + 1)];
}

- (NSString *)safeSubstringBeforeIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex - 1)];
}

- (NSString *)safeSubstringFromIndex:(NSInteger)anIndex
{
	if ([self length] < anIndex || anIndex < 0) return nil;
	
	return [self substringFromIndex:anIndex];
}

- (NSString *)safeSubstringToIndex:(NSInteger)anIndex
{
	if ([self length] < anIndex || anIndex < 0) return nil;
	
	return [self substringToIndex:anIndex];
}

- (UniChar)safeCharacterAtIndex:(NSInteger)index
{
	if ([self length] < index || index < 0) return 0;
	
	if (NSObjectIsNotEmpty(self)) {
		return [self characterAtIndex:index];
	}
	
	return 0;
}

- (NSString *)stringCharacterAtIndex:(NSInteger)index
{
	if (NSObjectIsNotEmpty(self)) {
		UniChar charValue = [self safeCharacterAtIndex:index];
		
		return [NSString stringWithUniChar:charValue];
	}
	
	return nil;
}

- (NSString *)fastChopEndWithChars:(NSArray *)chars
{
	NSInteger chopMnt = 0;
	NSInteger slnt	  = [self length];
	
	NSString *slchar	 = nil;
	NSString *strChopper = self;
	
	for (NSInteger i = 1; i < slnt; i++) {
		slchar     = [strChopper safeSubstringFromIndex:([strChopper length] - 1)];
		strChopper = [strChopper safeSubstringToIndex:([strChopper length] - 1)];
		
		if ([chars containsObject:slchar] == NO) {
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
	
	if (buffer == NULL) {
		NSMutableData *data = [NSMutableData dataWithLength:(len * sizeof(UniChar))];
		if (NSObjectIsEmpty(data)) return NULL;
		
		[self getCharacters:[data mutableBytes]];
		buffer = [data bytes];
		
		if (buffer == NULL) return NULL;
	}
	
	return buffer;
}

- (BOOL)isEqualNoCase:(NSString *)other
{
	return ([self caseInsensitiveCompare:other] == NSOrderedSame);
}

- (BOOL)contains:(NSString *)str
{
	NSRange r = [self rangeOfString:str];
	
	return BOOLReverseValue(r.location == NSNotFound);
}

- (BOOL)containsIgnoringCase:(NSString *)str
{
	NSRange r = [self rangeOfString:str options:NSCaseInsensitiveSearch];
	
	return BOOLReverseValue(r.location == NSNotFound);
}

- (NSInteger)findCharacter:(UniChar)c
{
	return [self findCharacter:c start:0];
}

- (NSInteger)findCharacter:(UniChar)c start:(NSInteger)start
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(c, 1)] 
									  options:0 range:NSMakeRange(start, ([self length] - start))];
	
	return ((r.location == NSNotFound) ? -1 : r.location);
}

- (NSArray *)split:(NSString *)delimiter
{
	return [self componentsSeparatedByString:delimiter];
}

- (NSString *)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isNumericOnly
{
	NSUInteger len = self.length;
	if (len == 0) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (buffer == NULL) return NO;
	
	for (NSInteger i = 0; i < len; ++i) {
		UniChar c = buffer[i];
		
		if (IsNumeric(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)isAlphaNumOnly
{
	NSUInteger len = self.length;
	if (len == 0) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (buffer == NULL) return NO;
	
	for (NSInteger i = 0; i < len; ++i) {
		UniChar c = buffer[i];
		
		if (IsAlphaNum(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

BOOL isSurrogate(UniChar c)
{
	return (0xd800 <= c && c <= 0xdfff);
}

BOOL isHighSurrogate(UniChar c)
{
	return (0xd800 <= c && c <= 0xdbff);
}

BOOL isLowSurrogate(UniChar c)
{
	return (0xdc00 <= c && c <= 0xdfff);
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
			return (((((c - 0xd800) * 0x400) + (d - 0xdc00)) + 0x10000));
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
	
	NSInteger c = [self characterAtIndex:(len - 1)];
	
	if (isLowSurrogate(c)) {
		if (len <= 1) return c;
		
		NSInteger d = [self characterAtIndex:(len - 2)];
		
		if (isHighSurrogate(d)) {
			return (((((c - 0xd800) * 0x400) + (d - 0xdc00)) + 0x10000));
		} else {
			return -1;
		}
	}
	
	return c;
}

NSInteger ctoi(unsigned char c)
{
	if ('0' <= c && c <= '9') {
		return (c - '0');
	} else if ('a' <= c && c <= 'f') {
		return ((c - 'a') + 10);
	} else if ('A' <= c && c <= 'F') {
		return ((c - 'A') + 10);
	} else {
		return 0;
	}
}

BOOL isUnicharDigit(unichar c)
{
	return ('0' <= c && c <= '9');
}

- (NSString *)safeUsername
{
	NSInteger n = 0;
	NSInteger len = self.length;
	
	const UniChar* buf = [self getCharactersBuffer];
	
	UniChar dest[len];
	
	for (NSInteger i = 0; i < len; ++i) {
		UniChar c = buf[i];
		
		if (IsWordLetter(c)) {
			dest[n++] = c;
		} else {
			dest[n++] = '_';
		}
	}
	
	return [NSString stringWithCharacters:dest length:n];
}

- (NSString *)safeFileName
{
	self = [self stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	return [self stringByReplacingOccurrencesOfString:@":" withString:@"_"];
}

- (NSInteger)stringPosition:(NSString *)needle
{
	NSRange r = [self rangeOfString:needle];
	if (r.location == NSNotFound) return -1;
	
	return r.location;
}

- (NSInteger)stringPositionIgnoringCase:(NSString *)needle
{
	NSRange r = [self rangeOfString:needle options:NSCaseInsensitiveSearch];
	if (r.location == NSNotFound) return -1;
	
	return r.location;
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont followFormattingPreference:(BOOL)formattingPreference
{
	if (formattingPreference && [Preferences removeAllFormatting]) {
		return [self stripEffects];
	}
    
    NSDictionary *input = [NSDictionary dictionaryWithObjectsAndKeys:defaultFont, @"attributedStringFont", nil];
	
	return [LogRenderer renderBody:self 
                        controller:nil 
                        renderType:ASCII_TO_ATTRIBUTED_STRING 
                        properties:input resultInfo:NULL];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont {
	return [self attributedStringWithIRCFormatting:defaultFont followFormattingPreference:YES];
}

- (NSString *)stripEffects
{
	NSInteger pos = 0;
	NSInteger len = self.length;
	
	if (len == 0) return self;
	
	NSInteger buflen = (len * sizeof(unichar));
	
	unichar* src = alloca(buflen);
	unichar* buf = alloca(buflen);
	
	[self getCharacters:src];
	
	for (NSInteger i = 0; i < len; ++i) {
		unichar c = src[i];
		
		if (c < 0x20) {
			switch (c) {
				case 0x2:
				case 0xf:
				case 0x16:
				case 0x1f:
					break;
				case 0x3:
					if ((i + 1) >= len) continue;
					unichar d = src[i+1];
					if (isUnicharDigit(d) == NO) continue;
					i++;
					
					if ((i + 1) >= len) continue;
					unichar e = src[i+1];
					if (IsIRCColor(e, (d - '0')) == NO && NSDissimilarObjects(e, ',')) continue;
					i++;
					
					if ((e == ',') == NO) {
						if ((i + 1) >= len) continue;
						unichar f = src[i+1];
						if (NSDissimilarObjects(f, ',')) continue;
						i++;
					}
					
					if ((i + 1) >= len) continue;
					unichar g = src[i+1];
					if (isUnicharDigit(g) == NO) {
						i--;
						continue;
					}
					i++;
					
					if ((i + 1) >= len) continue;
					unichar h = src[i+1];
					if (IsIRCColor(h, (g - '0')) == NO) continue;
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
	
	return [NSString stringWithCharacters:buf length:pos];
}

- (BOOL)isNickname
{
	if (NSObjectIsEmpty(self)) return NO;
	
	return ([self isNotEqualTo:@"*"] && [self contains:@"."] == NO);
}

- (BOOL)isChannelName
{
	if (NSObjectIsEmpty(self)) return NO;
	
	UniChar c = [self characterAtIndex:0];
	
	return (c == '#' || c == '&' || c == '+' || c == '!' || c == '~' || c == '?');
}

- (BOOL)isModeChannelName
{
	if (NSObjectIsEmpty(self)) return NO;
	
	UniChar c = [self characterAtIndex:0];
	
	return (c == '#' || c == '&' || c == '!' || c == '~' || c == '?');
}

- (NSString *)canonicalName
{
	return [self lowercaseString];
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
	
	NSRange rs = [TXRegularExpression string:shortstring rangeOfRegex:@"([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}|([a-f0-9]{0,4}:){7}[a-f0-9]{0,4}|([0-9]{1,3}\\.){3}[0-9]{1,3}"];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSInteger prev = (r.location - 1);
	
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
	
	NSRange rs = [TXRegularExpression string:shortstring rangeOfRegex:@"#([a-zA-Z0-9\\#\\-]+)"];
	if (rs.location == NSNotFound) return NSMakeRange(NSNotFound, 0);
	NSRange r = NSMakeRange((rs.location + start), rs.length);
	
	NSInteger prev = (r.location - 1);
	
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

- (NSString *)encodeURIComponent
{
	if (NSObjectIsEmpty(self)) return NSNullObject;
	
	const char* src		   = [self UTF8String];
	const char* characters = "0123456789ABCDEF";
	
	if (src == NULL) return NSNullObject;
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i = (len - 1); i >= 0; --i) {
		unsigned char c = *src++;
		
		if (IsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)encodeURIFragment
{
	if (NSObjectIsEmpty(self)) return NSNullObject;
	
	const char* src		   = [self UTF8String];
	const char* characters = "0123456789ABCDEF";
	
	if (src == NULL) return NSNullObject;
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i = (len - 1); i >= 0; --i) {
		unsigned char c = *src++;
		
		if (IsWordLetter(c)
			|| c == '#' || c == '%'
			|| c == '&' || c == '+'
			|| c == ',' || c == '-'
			|| c == '.' || c == '/'
			|| c == ':' || c == ';'
			|| c == '=' || c == '?'
			|| c == '@' || c == '~') {
			
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)decodeURIFragement
{
	return [self stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
}

+ (NSString *)stringWithUUID 
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuidString = CFItemRefToID(CFUUIDCreateString(nil, uuidObj));
	CFRelease(uuidObj);
	
	return [uuidString autodrain];
}

- (NSString *)hostmaskFromRawString
{
	if ([self contains:@"!"] == NO || [self contains:@"@"] == NO) return self;
	
	return [self safeSubstringAfterIndex:[self stringPosition:@"!"]];
}

- (NSString *)nicknameFromHostmask
{
	if ([self contains:@"!"] == NO) return self;
	
	return [self safeSubstringToIndex:[self stringPosition:@"!"]];	
}

- (NSString *)reservedCharactersToIRCFormatting
{
	NSString *s = self;
	
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x03] withString:@"▤"]; // color
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x02] withString:@"▥"]; // bold
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x16] withString:@"▧"]; // italics
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x1F] withString:@"▨"]; // underline
	
	return s;
}

- (NSString *)cleanedServerHostmask
{
    /* We do not want ports in server address. */
    self = [self trim];
    
    if ([TXRegularExpression string:self isMatchedByRegex:@"^([^:]+):([0-9]{2,7})$"] ||
        [TXRegularExpression string:self isMatchedByRegex:@"^\\[([0-9a-f:]+)\\]:([0-9]{2,7})$"]) {
        
        NSInteger stringPos = [self rangeOfString:@":" options:NSBackwardsSearch range:NSMakeRange(0, self.length)].location;
        
        if (stringPos > 0) {
            self = [self safeSubstringToIndex:stringPos];
        }
    }
	
	return self;
}

- (BOOL)isIPv6Address
{
	/* Basic matching. No need to overcomplicate it ... yet. */
	NSArray *matches = [self componentsSeparatedByString:@":"];
	
	return ([matches count] >= 2 && [matches count] <= 7);
}

- (NSInteger)pixelHeightInWidth:(NSInteger)width
{
    NSTextStorage *textStorage = [NSTextStorage alloc];
	NSLayoutManager *layoutManager = [NSLayoutManager new];
	NSTextContainer *textContainer = [NSTextContainer alloc];
	
    [textStorage initWithString:self];
    [textContainer initWithContainerSize:NSMakeSize(width, FLT_MAX)];
    
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger cellHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
    
    return cellHeight;
}

@end

@implementation NSString (NSStringNumberHelper)

+ (NSString *)stringWithChar:(char)value								{ return [NSString stringWithFormat:@"%c", value]; }
+ (NSString *)stringWithUniChar:(UniChar)value							{ return [NSString stringWithFormat:@"%C", value]; }
+ (NSString *)stringWithUnsignedChar:(unsigned char)value				{ return [NSString stringWithFormat:@"%c", value]; }

+ (NSString *)stringWithShort:(short)value								{ return [NSString stringWithFormat:@"%hi", value]; }
+ (NSString *)stringWithUnsignedShort:(unsigned short)value				{ return [NSString stringWithFormat:@"%hu", value]; }

+ (NSString *)stringWithInt:(int)value									{ return [NSString stringWithFormat:@"%i", value]; }
+ (NSString *)stringWithInteger:(NSInteger)value						{ return [NSString stringWithFormat:@"%i", value]; }
+ (NSString *)stringWithUnsignedInt:(unsigned int)value					{ return [NSString stringWithFormat:@"%u", value]; }
+ (NSString *)stringWithUnsignedInteger:(NSUInteger)value				{ return [NSString stringWithFormat:@"%u", value]; }

+ (NSString *)stringWithLong:(long)value								{ return [NSString stringWithFormat:@"%ld", value]; }
+ (NSString *)stringWithUnsignedLong:(unsigned long)value				{ return [NSString stringWithFormat:@"%lu", value]; }

+ (NSString *)stringWithLongLong:(long long)value						{ return [NSString stringWithFormat:@"%qi", value]; }
+ (NSString *)stringWithUnsignedLongLong:(unsigned long long)value		{ return [NSString stringWithFormat:@"%qu", value]; }

+ (NSString *)stringWithFloat:(float)value								{ return [NSString stringWithFormat:@"%f", value]; }
+ (NSString *)stringWithDouble:(NSDoubleN)value							{ return [NSString stringWithFormat:@"%d", value]; }

@end

@implementation NSMutableString (NSMutableStringHelper)

- (void)safeDeleteCharactersInRange:(NSRange)range
{
	if (range.location == NSNotFound) return;
	if (range.length > [self length]) return;
	if (range.location > [self length]) return;
	
	[self deleteCharactersInRange:range];
}

- (NSString *)getToken
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:NSWhitespaceCharacter]];
	
	if (NSDissimilarObjects(r.location, NSNotFound)) {
		NSString *result = [self safeSubstringToIndex:r.location];
		
		NSInteger len = [self length];
		NSInteger pos = (r.location + 1);
		
		while (pos < len && [self characterAtIndex:pos] == ' ') {
			pos++;
		}
		
		[self safeDeleteCharactersInRange:NSMakeRange(0, pos)];
		
		return result;
	}
	
	NSString *result = [[self copy] autodrain];
	
	[self setString:NSNullObject];
	
	return result;
}

@end

@implementation NSAttributedString (NSAttributedStringHelper)

- (NSDictionary *)attributes
{
    return [self safeAttributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0, [self length])];
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
	if (location > [self length]) return nil;
	
	return [self attribute:attrName atIndex:location effectiveRange:range];
}

- (NSDictionary *)safeAttributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
	if (location > [self length]) return nil;
	if (rangeLimit.location == NSNotFound) return nil;
	if (rangeLimit.length > [self length]) return nil;
	if (rangeLimit.location > [self length]) return nil;
	
	return [self attributesAtIndex:location longestEffectiveRange:range inRange:rangeLimit];
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{	
	if (location > [self length]) return nil;
	if (rangeLimit.location == NSNotFound) return nil;
	if (rangeLimit.length > [self length]) return nil;
	if (rangeLimit.location > [self length]) return nil;
	
	return [self attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit];
}

+ (NSAttributedString *)emptyString
{
    return [NSAttributedString emptyStringWithBase:NSNullObject];
}

+ (NSAttributedString *)emptyStringWithBase:(NSString *)base
{
	NSAttributedString *newstr;
    
    newstr = [NSAttributedString alloc];
    newstr = [newstr initWithString:base];
    newstr = [newstr autodrain];
    
	return newstr;
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
	return [self attributedStringByTrimmingCharactersInSet:set frontChop:NULL];
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set frontChop:(NSRangePointer)front
{
	NSString *str = [self string];
	
	NSRange range;
	
	NSUInteger loc = 0;
	NSUInteger len = 0;
	
	NSCharacterSet *invertedSet = [set invertedSet];
	
	range = [str rangeOfCharacterFromSet:invertedSet];
	loc   = ((range.length >= 1) ? range.location : 0);
	
	if (PointerIsEmpty(front) == NO) {
		*front = range;
	}
	
	range = [str rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];
	len   = ((range.length >= 1) ? (NSMaxRange(range) - loc) : ([str length] - loc));
	
	return [self attributedSubstringFromRange:NSMakeRange(loc, len)];
}

- (NSArray *)splitIntoLines
{
    NSMutableArray *lines = [NSMutableArray array];
    
    NSInteger len   = self.string.length;
    NSInteger start = 0;
    
    NSMutableAttributedString *copyd = [self.mutableCopy autodrain];
    
    while (start < len) {
        NSRange r = [self.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] 
                                                 options:NSCaseInsensitiveSearch 
                                                   range:NSMakeRange(start, (len - start))];
        
        if (r.location == NSNotFound) {
            break;
        }
        
        NSRange delRange = NSMakeRange(0, ((r.location - start) + 1));
        NSRange cutRange = NSMakeRange(start, (r.location - start));
        
        NSAttributedString *line = [self attributedSubstringFromRange:cutRange];
        
        [lines safeAddObject:line];
        [copyd deleteCharactersInRange:delRange];
        
        start = NSMaxRange(r);
    }
    
    if (NSObjectIsEmpty(lines)) {
        [lines safeAddObject:self];
    } else {
        if (copyd.string.length) {
            [lines safeAddObject:copyd];
        }
    }
    
    return lines;
}

- (NSInteger)pixelHeightInWidth:(NSInteger)width
{
    NSTextStorage *textStorage = [NSTextStorage alloc];
	NSLayoutManager *layoutManager = [NSLayoutManager new];
	NSTextContainer *textContainer = [NSTextContainer alloc];
	
    [textStorage initWithAttributedString:self];
    [textContainer initWithContainerSize:NSMakeSize(width, FLT_MAX)];
    
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger cellHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
    
    return cellHeight;
}

@end

@implementation NSMutableAttributedString (NSMutableAttributedStringHelper)

- (NSAttributedString *)getToken
{
	NSRange r = [self.string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (NSDissimilarObjects(r.location, NSNotFound)) {
        NSRange sr = NSMakeRange(0, r.location);
        
        NSAttributedString *result = [self attributedSubstringFromRange:sr];
		
		NSInteger len = [self length];
		NSInteger pos = (r.location + 1);
		
		while (pos < len && [self.string characterAtIndex:pos] == ' ') {
			pos++;
		}
		
        [self deleteCharactersInRange:NSMakeRange(0, pos)];
		
		return result;
	}
	
	NSAttributedString *result = [self.copy autodrain];
	
    [self setAttributedString:[NSAttributedString emptyString]];
	
	return result;
}

@end