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

@implementation NSString (TXStringHelper)

/* Helper Methods */
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding
{
	return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
}

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[NSString alloc] initWithData:data encoding:encoding];
}

+ (NSString *)stringWithUUID
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);

	return uuidString;
}

+ (NSString *)charsetRepFromStringEncoding:(NSStringEncoding)encoding
{
	CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);

	CFStringRef charsetStr = CFStringConvertEncodingToIANACharSetName(cfencoding);

	return (__bridge NSString *)(charsetStr);
}

+ (NSDictionary *)supportedStringEncodingsWithTitle:(BOOL)favorUTF8
{
    NSMutableDictionary *encodingList = [NSMutableDictionary dictionary];

    NSArray *supportedEncodings = [NSString supportedStringEncodings:favorUTF8];

    for (id encoding in supportedEncodings) {
        NSString *encodingTitle = [NSString localizedNameOfStringEncoding:[encoding integerValue]];

        [encodingList safeSetObject:encoding forKey:encodingTitle];
    }

    return encodingList;
}

+ (NSArray *)supportedStringEncodings:(BOOL)favorUTF8
{
    NSMutableArray *encodingList = [NSMutableArray array];

    const NSStringEncoding *encodings = [NSString availableStringEncodings];

    if (favorUTF8) {
        [encodingList safeAddObject:@(NSUTF8StringEncoding)];
    }

    while (1 == 1) {
        NSStringEncoding encoding = (*encodings++);

        if (encoding == 0) {
            break;
        }

        if (favorUTF8 && encoding == NSUTF8StringEncoding) {
            continue;
        }

        [encodingList safeAddObject:@(encoding)];
    }

    return encodingList;
}

- (NSString *)safeSubstringWithRange:(NSRange)range
{
	if (NSRangeIsValidInBounds(range, self.length) == NO) {
		return nil;
	}
	
	return [self substringWithRange:range];
}

- (NSString *)safeSubstringFromIndex:(NSInteger)anIndex
{
	if (anIndex > self.length || anIndex < 0) {
		return nil;
	}

	return [self substringFromIndex:anIndex];
}

- (NSString *)safeSubstringToIndex:(NSInteger)anIndex
{
	if (anIndex > self.length || anIndex < 0) {
		return nil;
	}

	return [self substringToIndex:anIndex];
}

- (UniChar)safeCharacterAtIndex:(NSInteger)anIndex
{
	if (anIndex > self.length || anIndex < 0) {
		return 0;
	}

	return [self characterAtIndex:anIndex];
}

- (NSString *)stringCharacterAtIndex:(NSInteger)anIndex
{
	if (anIndex > self.length || anIndex < 0) {
		return nil;
	}

	return [NSString stringWithUniChar:[self characterAtIndex:anIndex]];
}

- (NSString *)safeSubstringAfterIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex + 1)];
}

- (NSString *)safeSubstringBeforeIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex - 1)];
}

- (BOOL)isEqualIgnoringCase:(NSString *)other
{
	return ([self caseInsensitiveCompare:other] == NSOrderedSame);
}

- (BOOL)contains:(NSString *)str
{
	return ([self stringPosition:str] >= 0);
}

- (BOOL)containsIgnoringCase:(NSString *)str
{
	return ([self stringPositionIgnoringCase:str] >= 0);
}

- (NSArray *)split:(NSString *)delimiter
{
	return [self componentsSeparatedByString:delimiter];
}

- (NSString *)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)trimNewlines
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)trimCharacters:(NSString *)charset
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:charset]];
}

- (NSString *)removeAllNewlines
{
	return [self stringByReplacingOccurrencesOfString:NSStringNewlinePlaceholder withString:NSStringEmptyPlaceholder];
}

- (NSInteger)stringPosition:(NSString *)needle
{
	NSRange searchResult = [self rangeOfString:needle];
	
	if (searchResult.location == NSNotFound) {
		return -1;
	}
	
	return searchResult.location;
}

- (NSInteger)stringPositionIgnoringCase:(NSString *)needle
{
	NSRange searchResult = [self rangeOfString:needle options:NSCaseInsensitiveSearch];

	if (searchResult.location == NSNotFound) {
		return -1;
	}

	return searchResult.location;
}

- (BOOL)isHostmask
{
	NSInteger bang1pos = [self stringPosition:@"!"];
	NSInteger bang2pos = [self stringPosition:@"@"];

	NSAssertReturnR((bang1pos >= 0), NO);
	NSAssertReturnR((bang2pos >= 0), NO);
	NSAssertReturnR((bang2pos > bang1pos), NO);

	return YES;
}

- (BOOL)isNickname
{
	NSObjectIsEmptyAssertReturn(self, NO);

	for (NSInteger i = 0; i < self.length; ++i) {
        NSString *c = [self stringCharacterAtIndex:i];

		if ([IRCNicknameValidCharacters contains:c] == NO) {
            return NO;
        }
	}
    
	return ([self isNotEqualTo:@"*"] && self.length <= TXMaximumIRCNicknameLength);
}

- (BOOL)isChannelName:(IRCClient *)client
{
	NSObjectIsEmptyAssertReturn(self, NO);
	
	if (PointerIsEmpty(client)) {
		return [self isChannelName];
	}

	NSString *validChars = client.isupport.channelNamePrefixes;

	if (self.length == 1) {
		NSString *c = [self stringCharacterAtIndex:0];
		
		return [validChars contains:c];
	} else {
		NSString *c1 = [self stringCharacterAtIndex:0];
		NSString *c2 = [self stringCharacterAtIndex:1];
		
		/* The ~ prefix is considered special. It is used by the ZNC partyline plugin. */
		BOOL isPartyline = ([c1 isEqualToString:@"~"] && [c2 isEqualToString:@"#"]);

		return ([validChars contains:c1] || isPartyline);
	}
}

- (BOOL)isChannelName
{
	NSObjectIsEmptyAssertReturn(self, NO);

	UniChar c = [self characterAtIndex:0];

	return (self.length >= 1 && (c == '#' || c == '&' || c == '+' || c == '!' || c == '~' || c == '?'));
}

- (BOOL)isModeChannelName
{
	NSObjectIsEmptyAssertReturn(self, NO);

	UniChar c = [self characterAtIndex:0];

	return (self.length >= 1 && (c == '#' || c == '&' || c == '!' || c == '~' || c == '?'));
}

- (NSString *)channelNameToken
{
	/* Remove any prefix from in front of channel (e.g. #) or return
	 an untouched copy of the string if there is none. */

	if ([self isChannelName] && self.length > 1) {
		return [self safeSubstringFromIndex:1];
	}

	return self;
}

- (NSString *)hostmaskFromRawString
{
	NSAssertReturnR([self isHostmask], nil);

	NSInteger bang1pos = [self stringPosition:@"!"];

	return [self safeSubstringAfterIndex:bang1pos];
}

- (NSString *)nicknameFromHostmask
{
    if ([self isHostmask] == NO) {
        return self;
    }

	NSInteger bang1pos = [self stringPosition:@"!"];

	return [self safeSubstringToIndex:bang1pos];
}

- (NSString *)usernameFromHostmask
{
	NSAssertReturnR([self isHostmask], nil);

	NSInteger bang1pos = [self stringPosition:@"!"];
	NSInteger bang2pos = [self stringPosition:@"@"];

    NSString *bob = [self safeSubstringToIndex:bang2pos];

	return [bob safeSubstringAfterIndex:bang1pos];
}

- (NSString *)addressFromHostmask
{
	NSAssertReturnR([self isHostmask], nil);

	NSInteger bang2pos = [self stringPosition:@"@"];

	return [self safeSubstringAfterIndex:bang2pos];
}

- (NSString *)reservedCharactersToIRCFormatting
{
	/* 
	 
	 This is an interesting method. Long, long ago when Textual was still a young
	 fork of Limechat we were working on formatting support for the input text field.
	 The feature was sorta, kinda rushed so "reserved characters" were settled on.
	 It was just a rip off of mIRC boxy things they use for formatting.

	 User would select a portion of text they wanted formatted, right click, select
	 the formatting, then Textual would insert the boxes around the text. Of couse
	 Textual now has a more modern system for formatting. This method still exists
	 though so a theme can customize localizations with IRC formatting since the
	 localizations do not support HTML.

	 Maybe a new system is needed? Nah, no rush. No themes even change localizations.

	 Format:
		 ▤<foreground 1-15>,[background 1-15]<text>▤ — color
		 ▥<text>▥ — bold
		 ▧<text>▧ — italics
		 ▨<text>▨ — underline
	 
	 */

	NSString *s = self;

	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x03] withString:@"▤"]; // color
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x02] withString:@"▥"]; // bold
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x16] withString:@"▧"]; // italics
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x1F] withString:@"▨"]; // underline

	return s;
}

- (NSString *)cleanedServerHostmask
{
    NSString *bob = self.trim;

    if ([TLORegularExpression string:bob isMatchedByRegex:@"^([^:]+):([0-9]{2,7})$"] ||
        [TLORegularExpression string:bob isMatchedByRegex:@"^\\[([0-9a-f:]+)\\]:([0-9]{2,7})$"])
	{
		NSRange searchRange = [bob rangeOfString:@":" options:NSBackwardsSearch range:NSMakeRange(0, self.length)];

		if (searchRange.location == NSNotFound) {
			return bob;
		}

		return [bob safeSubstringToIndex:searchRange.location];
    }

	return bob;
}

- (BOOL)isIPv6Address
{
	NSArray *matches = [self componentsSeparatedByString:@":"];

	return (matches.count >= 2 && matches.count <= 7);
}

- (NSString *)stringWithValidURIScheme
{
	if ([self contains:@"://"] == NO) {
		return [NSString stringWithFormat:@"http://%@", self];
	}

	return self;
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont honorFormattingPreference:(BOOL)formattingPreference
{
	if (formattingPreference && [TPCPreferences removeAllFormatting]) {
		return [self stripIRCEffects];
	}

    NSDictionary *input = @{@"attributedStringFont" : defaultFont};

	return [TVCLogRenderer renderBody:self
						   controller:self.worldController.selectedViewController
						   renderType:TVCLogRendererAttributedStringType
						   properties:input
						   resultInfo:NULL];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont
{
	return [self attributedStringWithIRCFormatting:defaultFont honorFormattingPreference:NO];
}

- (NSString *)safeFilename
{
	NSString *bob = self.trim;

	bob = [bob stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	bob = [bob stringByReplacingOccurrencesOfString:@":" withString:@"_"];

	return bob;
}

- (BOOL)isNumericOnly
{
	NSObjectIsEmptyAssertReturn(self, NO);
	
	for (NSInteger i = 0; i < self.length; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (TXStringIsBase10Numeric(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)isAlphabeticNumericOnly
{
	NSObjectIsEmptyAssertReturn(self, NO);

	for (NSInteger i = 0; i < self.length; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (TXStringIsAlphabeticNumeric(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (NSString *)stripIRCEffects
{
	NSObjectIsEmptyAssertReturn(self, nil);

	NSInteger pos = 0;
	NSInteger len = self.length;
	
	NSInteger buflen = (len * sizeof(UniChar));
	
	UniChar *src = alloca(buflen);
	UniChar *buf = alloca(buflen);
	
	[self getCharacters:src range:NSMakeRange(0, len)];
	
	for (NSInteger i = 0; i < len; ++i) {
		unichar c = src[i];
		
		if (c < 0x20) {
			switch (c) {
				case 0x2:
				case 0xf:
				case 0x16:
				case 0x1f:
				{
					break;
				}
				case 0x3:
				{
					/* ============================================= */
					/* Begin color stripping.						 */
					/* ============================================= */
					
					if ((i + 1) >= len) {
						continue;
					}

					UniChar d = src[(i + 1)];
					
					if (TXStringIsBase10Numeric(d) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					if ((i + 1) >= len) {
						continue;
					}

					UniChar e = src[(i + 1)];
					
					if (TXStringIsIRCColor(e, (d - '0')) == NO && NSDissimilarObjects(e, ',')) {
						continue;
					}
					
					i++;

					// ---- //
					
					if ((e == ',') == NO) {
						if ((i + 1) >= len) {
							continue;
						}
						
						UniChar f = src[(i + 1)];
						
						if (NSDissimilarObjects(f, ',')) {
							continue;
						}
						
						i++;
					}

					// ---- //

					if ((i + 1) >= len) {
						continue;
					}

					UniChar g = src[(i + 1)];

					if (TXStringIsBase10Numeric(g) == NO) {
						i--;
						
						continue;
					}
					
					i++;

					// ---- //

					if ((i + 1) >= len) {
						continue;
					}

					UniChar h = src[(i + 1)];

					if (TXStringIsIRCColor(h, (g - '0')) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					break;
					
					/* ============================================= */
					/* End color stripping.							 */
					/* ============================================= */
				}
				default:
				{
					buf[pos++] = c;
					
					break;
				}
			}
		} else {
			buf[pos++] = c;
		}
	}
	
	return [NSString stringWithCharacters:buf length:pos];
}

- (NSRange)rangeOfChannelName
{
	return [self rangeOfChannelNameStart:0];
}

- (NSRange)rangeOfChannelNameStart:(NSInteger)start
{
	NSInteger stringLength = self.length;
	
	NSAssertReturnR((self.length > start), NSEmptyRange());
	
	NSString *searchString = [self safeSubstringFromIndex:start];
	
	NSRange searchRange = [TLORegularExpression string:searchString rangeOfRegex:@"#([a-zA-Z0-9\\#\\-]+)"];

	if (searchRange.location == NSNotFound) {
		return NSEmptyRange();
	}

	NSRange r = NSMakeRange((start + searchRange.location), searchRange.length);
	
	NSInteger prev = (r.location - 1);
	
	if (0 <= prev && prev < stringLength) {
		UniChar c = [self characterAtIndex:prev];
		
		if (TXStringIsWordLetter(c)) {
			return NSEmptyRange();
		}
	}
	
	NSInteger next = NSMaxRange(r);
	
	if (next < stringLength) {
		UniChar c = [self characterAtIndex:next];
		
		if (TXStringIsWordLetter(c)) {
			return NSEmptyRange();
		}
	}
	
	return r;
}

- (NSString *)encodeURIComponent
{
	NSObjectIsEmptyAssertReturn(self, NSStringEmptyPlaceholder);
	
	const char *sourcedata = [self UTF8String];
	const char *characters = "0123456789ABCDEF";

	PointerIsEmptyAssertReturn(sourcedata, NSStringEmptyPlaceholder);
	
	NSUInteger datalength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	char  buf[(datalength * 4)];
	char *dest = buf;
	
	for (NSInteger i = (datalength - 1); i >= 0; --i) {
		unsigned char c = *sourcedata++;
		
		if (TXStringIsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[(c / 16)];
			*dest++ = characters[(c % 16)];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)encodeURIFragment
{
	NSObjectIsEmptyAssertReturn(self, NSStringEmptyPlaceholder);

	const char *sourcedata = [self UTF8String];
	const char *characters = "0123456789ABCDEF";

	PointerIsEmptyAssertReturn(sourcedata, NSStringEmptyPlaceholder);

	NSUInteger datalength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char  buf[(datalength * 4)];
	char *dest = buf;

	for (NSInteger i = (datalength - 1); i >= 0; --i) {
		unsigned char c = *sourcedata++;
		
		if (TXStringIsWordLetter(c)
			|| c == '#' || c == '%'
			|| c == '&' || c == '+'
			|| c == ',' || c == '-'
			|| c == '.' || c == '/'
			|| c == ':' || c == ';'
			|| c == '=' || c == '?'
			|| c == '@' || c == '~')
		{
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[(c / 16)];
			*dest++ = characters[(c % 16)];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)decodeURIFragement
{
	return [self stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont
{
	CGFloat boundHeight = [self pixelHeightInWidth:boundWidth forcedFont:textFont];
	
	return (boundHeight / lineHeight);
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font
{
	NSAttributedString *base = [NSAttributedString emptyStringWithBase:self];

	return [base pixelHeightInWidth:width forcedFont:font];
}

- (NSString *)base64EncodingWithLineLength:(NSInteger)lineLength
{
    /*
     *
     * Getting error?:
     *     Use of undeclared identifier 'CSFWBase64Encoding'; did you mean 'kSecBase64Encoding'?
     *
     * Fix: 
     *     Erase the folder "Frameworks/Blowfish Encryption/BlowfishEncryption.framework" then build.
     *
     */

	NSString *encodedResult = [CSFWBase64Encoding encodeData:self];
	
	if (NSObjectIsNotEmpty(encodedResult)) {
		NSMutableString *resultString = [NSMutableString string];
		
		if (encodedResult.length > lineLength) {
			NSInteger rlc = ceil(encodedResult.length / lineLength);

			for (NSInteger i = 1; i <= rlc; i++) {
				NSString *append = [encodedResult safeSubstringToIndex:lineLength];

				[resultString appendString:append];
				[resultString appendString:NSStringNewlinePlaceholder];

				encodedResult = [encodedResult safeSubstringFromIndex:lineLength];
			}
		}
		
		[resultString appendString:encodedResult];

		return resultString;
	}

	return nil;
}

@end

@implementation NSString (NSStringNumberHelper)

+ (NSString *)stringWithChar:(char)value								{ return [NSString stringWithFormat:@"%c", value]; }
+ (NSString *)stringWithUniChar:(UniChar)value							{ return [NSString stringWithFormat:@"%C", value]; }
+ (NSString *)stringWithUnsignedChar:(unsigned char)value				{ return [NSString stringWithFormat:@"%c", value]; }

+ (NSString *)stringWithShort:(short)value								{ return [NSString stringWithFormat:@"%hi", value]; }
+ (NSString *)stringWithUnsignedShort:(unsigned short)value				{ return [NSString stringWithFormat:@"%hu", value]; }

+ (NSString *)stringWithInt:(int)value									{ return [NSString stringWithFormat:@"%i", value]; }
+ (NSString *)stringWithInteger:(NSInteger)value						{ return [NSString stringWithFormat:@"%ld", value]; }

+ (NSString *)stringWithUnsignedInt:(unsigned int)value					{ return [NSString stringWithFormat:@"%u", value]; }
+ (NSString *)stringWithUnsignedInteger:(NSUInteger)value				{ return [NSString stringWithFormat:@"%lu", value]; }

+ (NSString *)stringWithLong:(long)value								{ return [NSString stringWithFormat:@"%ld", value]; }
+ (NSString *)stringWithUnsignedLong:(unsigned long)value				{ return [NSString stringWithFormat:@"%lu", value]; }

+ (NSString *)stringWithLongLong:(long long)value						{ return [NSString stringWithFormat:@"%qi", value]; }
+ (NSString *)stringWithUnsignedLongLong:(unsigned long long)value		{ return [NSString stringWithFormat:@"%qu", value]; }

+ (NSString *)stringWithFloat:(float)value								{ return [NSString stringWithFormat:@"%f", value]; }
+ (NSString *)stringWithDouble:(double)value						{ return [NSString stringWithFormat:@"%f", value]; }

@end

@implementation NSMutableString (NSMutableStringHelper)

- (void)safeDeleteCharactersInRange:(NSRange)range
{
	if (NSRangeIsValidInBounds(range, self.length)) {
		[self deleteCharactersInRange:range];
	}
}

- (NSString *)getToken
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (NSDissimilarObjects(r.location, NSNotFound)) {
		NSString *cutString = [self safeSubstringToIndex:r.location];
		
		NSInteger stringLength = self.length;
		NSInteger stringForward = (r.location + 1);
		
		while ((stringForward < stringLength) && [self characterAtIndex:stringForward] == ' ') {
			stringForward += 1;
		}
		
		[self safeDeleteCharactersInRange:NSMakeRange(0, stringForward)];
		
		return cutString;
	} else {
		NSString *result = self.copy;
	
		[self setString:NSStringEmptyPlaceholder];
	
		return result;
	}
}

@end

@implementation NSAttributedString (NSAttributedStringHelper)

+ (NSAttributedString *)emptyString
{
    return [NSAttributedString emptyStringWithBase:NSStringEmptyPlaceholder];
}

+ (NSAttributedString *)emptyStringWithBase:(NSString *)base
{
	return [[NSAttributedString alloc] initWithString:base];
}

+ (NSAttributedString *)stringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes
{
	return [[NSAttributedString alloc] initWithString:base attributes:baseAttributes];
}

- (NSDictionary *)attributes
{
    return [self safeAttributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0, self.length)];
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
	NSAssertReturnR((location < self.length), nil);
	
	return [self attribute:attrName atIndex:location effectiveRange:range];
}

- (NSDictionary *)safeAttributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
	NSAssertReturnR((location < self.length), nil);

	if (NSRangeIsValidInBounds(rangeLimit, self.length)) {
		return [self attributesAtIndex:location longestEffectiveRange:range inRange:rangeLimit];
	}

	return nil;
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
	NSAssertReturnR((location < self.length), nil);

	if (NSRangeIsValidInBounds(rangeLimit, self.length)) {
		return [self attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit];
	}

	return nil;
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
	return [self attributedStringByTrimmingCharactersInSet:set frontChop:NULL];
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set frontChop:(NSRangePointer)front
{
	NSString *baseString = self.string;
	
	NSRange range;
	
	NSUInteger locati = 0;
	NSUInteger length = 0;
	
	NSCharacterSet *invertedSet = [set invertedSet];
	
	range = [baseString rangeOfCharacterFromSet:invertedSet];

	if (range.length >= 1) {
		locati = range.location;
	} else {
		locati = 0;
	}
	
	if (PointerIsEmpty(front) == NO) {
		*front = range;
	}
	
	range = [baseString rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];

	if (range.length >= 1) {
		length = (NSMaxRange(range) - locati);
	} else {
		length = (baseString.length - locati);
	}
	
	return [self attributedSubstringFromRange:NSMakeRange(locati, length)];
}

- (NSArray *)splitIntoLines
{
    NSMutableArray *lines = [NSMutableArray array];
    
    NSInteger stringLength = self.string.length;
    NSInteger rangeStartIn = 0;
    
    NSMutableAttributedString *copyd = self.mutableCopy;
    
    while (rangeStartIn < stringLength) {
		NSRange srb = NSMakeRange(rangeStartIn, (stringLength - rangeStartIn));
        NSRange srr = [self.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:srb];
        
        if (srr.location == NSNotFound) {
            break;
        }
        
        NSRange delRange = NSMakeRange(0, ((srr.location - rangeStartIn) + 1));
        NSRange cutRange = NSMakeRange(rangeStartIn, (srr.location - rangeStartIn));
        
        NSAttributedString *line = [self attributedSubstringFromRange:cutRange];
        
        [lines safeAddObject:line];
		
        [copyd deleteCharactersInRange:delRange];
        
        rangeStartIn = NSMaxRange(srr);
    }
    
    if (NSObjectIsEmpty(lines)) {
        [lines safeAddObject:self];
    } else {
        if (NSObjectIsNotEmpty(copyd)) {
            [lines safeAddObject:copyd];
        }
    }
    
    return lines;
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight
{
	return [self wrappedLineCount:boundWidth lineMultiplier:lineHeight forcedFont:nil];
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont
{	
	CGFloat boundHeight = [self pixelHeightInWidth:boundWidth forcedFont:textFont];

	return (boundHeight / lineHeight);
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width
{
	return [self pixelHeightInWidth:width forcedFont:nil];
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font
{
	NSMutableAttributedString *baseMutable = self.mutableCopy;
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName, nil];

	if (PointerIsNotEmpty(font)) {
		attributes[NSFontAttributeName] = font;
	}

	[baseMutable setAttributes:attributes range:NSMakeRange(0, baseMutable.length)];

	NSRect bounds = [baseMutable boundingRectWithSize:NSMakeSize(width, 0.0)
											  options:NSStringDrawingUsesLineFragmentOrigin];
	
	return NSHeight(bounds);
}

@end

@implementation NSMutableAttributedString (NSMutableAttributedStringHelper)

+ (NSMutableAttributedString *)mutableStringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes
{
	return [[NSMutableAttributedString alloc] initWithString:base attributes:baseAttributes];
}

- (NSAttributedString *)getToken
{
	NSRange r = [self.string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (NSDissimilarObjects(r.location, NSNotFound)) {
        NSRange cutRange = NSMakeRange(0, r.location);
        
        NSAttributedString *cutString = [self attributedSubstringFromRange:cutRange];
		
		NSInteger stringLength = self.length;
		NSInteger stringForward = (r.location + 1);
		
		while ((stringForward < stringLength) && [self.string characterAtIndex:stringForward] == ' ') {
			stringForward += 1;
		}
		
        [self deleteCharactersInRange:NSMakeRange(0, stringForward)];
		
		return cutString;
	} else {
		NSAttributedString *result = self.copy;
	
		[self setAttributedString:[NSAttributedString emptyString]];
	
		return result;
	}
}

@end
