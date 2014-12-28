/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#define TXDefaultPrimaryStringEncoding		NSUTF8StringEncoding
#define TXDefaultFallbackStringEncoding		NSISOLatin1StringEncoding

#define TXStringIsAlphabetic(c)						('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define TXStringIsBase10Numeric(c)					('0' <= (c) && (c) <= '9')
#define TXStringIsAlphabeticNumeric(c)				(TXStringIsAlphabetic(c) || TXStringIsBase10Numeric(c))
#define TXStringIsWordLetter(c)						(TXStringIsAlphabeticNumeric(c) || (c) == '_')

#define NSStringEmptyPlaceholder			@""
#define NSStringNewlinePlaceholder			@"\n"
#define NSStringWhitespacePlaceholder		@" "

/* That is one long define name. */
#define TXWesternAlphabetIncludingUnderscoreDashCharacterSet			@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_"

#pragma mark 
#pragma mark String Helpers

/* Providing an IRCClient pointer to many of these methods can
 help provide server specific configuration validation. */

@interface NSString (TXStringHelper)
+ (instancetype)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
+ (instancetype)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

+ (NSString *)stringWithUUID;

+ (NSString *)charsetRepFromStringEncoding:(NSStringEncoding)encoding;

+ (NSArray *)supportedStringEncodings:(BOOL)favorUTF8;

+ (NSDictionary *)supportedStringEncodingsWithTitle:(BOOL)favorUTF8;

- (NSString *)stringByAppendingIRCFormattingStop;

- (NSString *)substringAfterIndex:(NSUInteger)anIndex;
- (NSString *)substringBeforeIndex:(NSUInteger)anIndex;

- (NSString *)stringCharacterAtIndex:(NSUInteger)anIndex;

- (NSString *)stringByDeletingPreifx:(NSString *)prefix;

- (NSString *)stringByDeletingAllCharactersInSet:(NSString *)validChars;
- (NSString *)stringByDeletingAllCharactersNotInSet:(NSString *)validChars;

@property (readonly, copy) NSString *channelNameToken;
- (NSString *)channelNameTokenByTrimmingAllPrefixes:(IRCClient *)client;

@property (readonly, copy) NSString *sha1;
@property (readonly, copy) NSString *sha256;
@property (readonly, copy) NSString *md5;

@property (readonly, copy) NSString *nicknameFromHostmask;
@property (readonly, copy) NSString *usernameFromHostmask;
@property (readonly, copy) NSString *addressFromHostmask;

@property (readonly, copy) NSString *cleanedServerHostmask;

- (CGFloat)compareWithWord:(NSString *)stringB lengthPenaltyWeight:(CGFloat)weight;

- (BOOL)hasPrefixIgnoringCase:(NSString *)aString;

- (BOOL)isEqualIgnoringCase:(NSString *)other;

- (BOOL)contains:(NSString *)str;
- (BOOL)containsIgnoringCase:(NSString *)str;

- (BOOL)containsCharacters:(NSString *)validChars;
- (BOOL)onlyContainsCharacters:(NSString *)validChars;

- (NSInteger)stringPosition:(NSString *)needle;
- (NSInteger)stringPositionIgnoringCase:(NSString *)needle;

- (NSArray *)split:(NSString *)delimiter;

@property (readonly, copy) NSString *trim;
@property (readonly, copy) NSString *trimNewlines;
- (NSString *)trimCharacters:(NSString *)charset;

@property (readonly, copy) NSString *removeAllNewlines;

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont honorFormattingPreference:(BOOL)formattingPreference;
- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont;

@property (getter=isAlphabeticNumericOnly, readonly) BOOL alphabeticNumericOnly;
@property (getter=isNumericOnly, readonly) BOOL numericOnly;

@property (readonly, copy) NSString *safeFilename;

@property (readonly, copy) NSString *stripIRCEffects;

- (NSRange)rangeOfNextSegmentMatchingRegularExpression:(NSString *)regex startingAt:(NSUInteger)start;

@property (readonly, copy) NSString *encodeURIComponent;
@property (readonly, copy) NSString *encodeURIFragment;
@property (readonly, copy) NSString *decodeURIFragement;

@property (getter=isHostmask, readonly) BOOL hostmask;

@property (getter=isIPv4Address, readonly) BOOL IPv4Address;
@property (getter=isIPv6Address, readonly) BOOL IPv6Address;
@property (getter=isIPAddress, readonly) BOOL IPAddress;

@property (getter=isModeChannelName, readonly) BOOL modeChannelName;

- (BOOL)hostmaskComponents:(NSString **)nickname username:(NSString **)username address:(NSString **)address;

@property (getter=isNickname, readonly) BOOL nickname TEXTUAL_DEPRECATED("Use -isHostmaskNickname instead");

@property (getter=isHostmaskNickname, readonly) BOOL hostmaskNickname;
@property (getter=isHostmaskAddress, readonly) BOOL hostmaskAddress;
@property (getter=isHostmaskUsername, readonly) BOOL hostmaskUsername;

@property (getter=isChannelName, readonly) BOOL channelName;
- (BOOL)isChannelName:(IRCClient *)client; // Client to parse CHANTYPES from.

@property (readonly, copy) NSString *stringWithValidURIScheme;

- (NSUInteger)wrappedLineCount:(NSUInteger)boundWidth lineMultiplier:(NSUInteger)lineHeight forcedFont:(NSFont *)textFont;

- (CGFloat)pixelHeightInWidth:(NSUInteger)width forcedFont:(NSFont *)font;

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength;

@property (readonly, copy) NSString *string; // Returns self.

@property (readonly, copy) NSString *trimAndGetFirstToken;

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
@property (getter=getToken, readonly, copy) NSString *token;
@property (getter=getTokenIncludingQuotes, readonly, copy) NSString *tokenIncludingQuotes;

@property (readonly, copy) NSString *uppercaseGetToken;
@end

#pragma mark 
#pragma mark Attributed String Helpers

@interface NSAttributedString (TXAttributedStringHelper)
@property (readonly, copy) NSDictionary *attributes;

+ (NSAttributedString *)emptyString;
+ (NSAttributedString *)emptyStringWithBase:(NSString *)base;

+ (NSAttributedString *)stringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes;

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set frontChop:(NSRangePointer)front;

@property (readonly, copy) NSArray *splitIntoLines;

- (NSUInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSUInteger)lineHeight;
- (NSUInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSUInteger)lineHeight forcedFont:(NSFont *)textFont;

- (CGFloat)pixelHeightInWidth:(NSUInteger)width;
- (CGFloat)pixelHeightInWidth:(NSUInteger)width forcedFont:(NSFont *)font;
@end

#pragma mark 
#pragma mark Mutable Attributed String Helpers

@interface NSMutableAttributedString (TXMutableAttributedStringHelper)
+ (NSMutableAttributedString *)mutableStringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes;

@property (getter=getTokenAsString, readonly, copy) NSString *tokenAsString;
@property (readonly, copy) NSString *uppercaseGetToken;

@property (readonly, copy) NSString *trimmedString;

@property (getter=getToken, readonly, copy) NSAttributedString *token;
@property (getter=getTokenIncludingQuotes, readonly, copy) NSAttributedString *tokenIncludingQuotes;
@end
