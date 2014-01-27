/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define TXStringIsAlphabetic(c)						('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define TXStringIsBase10Numeric(c)					('0' <= (c) && (c) <= '9')
#define TXStringIsAlphabeticNumeric(c)				(TXStringIsAlphabetic(c) || TXStringIsBase10Numeric(c))
#define TXStringIsWordLetter(c)						(TXStringIsAlphabeticNumeric(c) || (c) == '_')

#define NSStringEmptyPlaceholder			@""
#define NSStringNewlinePlaceholder			@"\n"
#define NSStringWhitespacePlaceholder		@" "

#define NSStringNilValueSubstitute(s)		((s == nil) ? NSStringEmptyPlaceholder : s)

/* That is one long define name. */
#define TXWesternAlphabetIncludingUnderscoreDashCharacaterSet			@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_"

#pragma mark 
#pragma mark String Helpers

@interface NSString (TXStringHelper)
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

+ (NSString *)stringWithUUID;

+ (NSString *)charsetRepFromStringEncoding:(NSStringEncoding)encoding;

+ (NSArray *)supportedStringEncodings:(BOOL)favorUTF8;

+ (NSDictionary *)supportedStringEncodingsWithTitle:(BOOL)favorUTF8;

- (NSString *)substringAfterIndex:(NSInteger)anIndex;
- (NSString *)substringBeforeIndex:(NSInteger)anIndex;

- (NSString *)safeSubstringFromIndex:(NSInteger)anIndex;
- (NSString *)safeSubstringToIndex:(NSInteger)anIndex;
- (NSString *)safeSubstringWithRange:(NSRange)range;

- (NSString *)stringCharacterAtIndex:(NSInteger)anIndex;

- (NSString *)stringByDeletingPreifx:(NSString *)prefix;

- (NSString *)stringByDeletingAllCharactersInSet:(NSString *)validChars;
- (NSString *)stringByDeletingAllCharactersNotInSet:(NSString *)validChars;

- (NSString *)channelNameToken;
- (NSString *)channelNameTokenByTrimmingAllPrefixes:(IRCClient *)client;

- (NSString *)sha1;

- (NSString *)nicknameFromHostmask;
- (NSString *)usernameFromHostmask;
- (NSString *)addressFromHostmask;
- (NSString *)hostmaskFromRawString;

- (NSString *)cleanedServerHostmask;

- (NSInteger)compareWithWord:(NSString *)stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;

- (BOOL)isEqualIgnoringCase:(NSString *)other;

- (BOOL)contains:(NSString *)str;
- (BOOL)containsIgnoringCase:(NSString *)str;

- (BOOL)onlyContainersCharacters:(NSString *)validChars;

- (NSInteger)stringPosition:(NSString *)needle;
- (NSInteger)stringPositionIgnoringCase:(NSString *)needle;

- (NSArray *)split:(NSString *)delimiter;

- (NSString *)trim;
- (NSString *)trimNewlines;
- (NSString *)trimCharacters:(NSString *)charset;

- (NSString *)removeAllNewlines;

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont honorFormattingPreference:(BOOL)formattingPreference;
- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont;

- (UniChar)safeCharacterAtIndex:(NSInteger)anIndex;

- (BOOL)isAlphabeticNumericOnly;
- (BOOL)isNumericOnly;

- (NSString *)safeFilename;

- (NSString *)stripIRCEffects;

- (NSRange)rangeOfNextSegmentMatchingRegularExpression:(NSString *)regex startingAt:(NSInteger)start;

- (NSString *)encodeURIComponent;
- (NSString *)encodeURIFragment;
- (NSString *)decodeURIFragement;

- (BOOL)isHostmask;

- (BOOL)isIPv4Address;
- (BOOL)isIPv6Address;
- (BOOL)isIPAddress;

- (BOOL)isModeChannelName;

- (BOOL)isNickname;
- (BOOL)isNickname:(IRCClient *)client; // Client to parse CHARSET or CASEMAPPING from.

- (BOOL)isChannelName;
- (BOOL)isChannelName:(IRCClient *)client; // Client to parse CHANTYPES from.

- (NSString *)stringWithValidURIScheme;

- (NSString *)reservedCharactersToIRCFormatting;

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont;

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font;

- (NSString *)base64EncodingWithLineLength:(NSInteger)lineLength;

- (NSString *)string; // Returns self.

/* This call is used internally by getToken and getTokenIncludingQuotes. 
 Call that instead. It is declared in header so that it can be used for 
 these calls internally between categories. */
+ (id)getTokenFromFirstQuoteGroup:(id)stringValue returnedDeletionRange:(NSRange *)quoteRange;
+ (id)getTokenFromFirstWhitespaceGroup:(id)stringValue returnedDeletionRange:(NSRange *)whitespaceRange;
@end

#pragma mark 
#pragma mark String Number Helpers

@interface NSString (TXStringNumberHelper)
+ (NSString *)stringWithChar:(char)value;
+ (NSString *)stringWithUniChar:(UniChar)value;
+ (NSString *)stringWithUnsignedChar:(unsigned char)value;
+ (NSString *)stringWithShort:(short)value;
+ (NSString *)stringWithUnsignedShort:(unsigned short)value;
+ (NSString *)stringWithInt:(int)value;
+ (NSString *)stringWithUnsignedInt:(unsigned int)value;
+ (NSString *)stringWithLong:(long)value;
+ (NSString *)stringWithUnsignedLong:(unsigned long)value;
+ (NSString *)stringWithLongLong:(long long)value;
+ (NSString *)stringWithUnsignedLongLong:(unsigned long long)value;
+ (NSString *)stringWithFloat:(float)value;
+ (NSString *)stringWithDouble:(double)value;
+ (NSString *)stringWithInteger:(NSInteger)value;
+ (NSString *)stringWithUnsignedInteger:(NSUInteger)value;
@end

#pragma mark 
#pragma mark Mutable String Helpers

@interface NSMutableString (TXMutableStringHelper)
- (NSString *)getToken;
- (NSString *)getTokenIncludingQuotes;

- (void)safeDeleteCharactersInRange:(NSRange)range;
@end

#pragma mark 
#pragma mark Attributed String Helpers

@interface NSAttributedString (TXAttributedStringHelper)
- (NSDictionary *)attributes;

+ (NSAttributedString *)emptyString;
+ (NSAttributedString *)emptyStringWithBase:(NSString *)base;

+ (NSAttributedString *)stringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes;

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set frontChop:(NSRangePointer)front;

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;
- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;

- (NSDictionary *)safeAttributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;

- (NSArray *)splitIntoLines;

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight;
- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont;

- (CGFloat)pixelHeightInWidth:(NSInteger)width;
- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font;
@end

#pragma mark 
#pragma mark Mutable Attributed String Helpers

@interface NSMutableAttributedString (TXMutableAttributedStringHelper)
+ (NSMutableAttributedString *)mutableStringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes;

- (NSAttributedString *)getToken;
- (NSAttributedString *)getTokenIncludingQuotes;
@end
