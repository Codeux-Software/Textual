// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define TXIsAlpha(c)						('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define TXIsNumeric(c)						('0' <= (c) && (c) <= '9' && TXIsAlpha(c) == NO) 
#define TXIsAlphaNumeric(c)					(TXIsAlpha(c) || TXIsNumeric(c))
#define TXIsWordLetter(c)					(TXIsAlphaNumeric(c) || (c) == '_')
#define TXIsIRCColor(c,f)					([NSNumber compareIRCColor:c against:f])
#define TXIsAlphaWithDiacriticalMark(c)		(0xc0 <= c && c <= 0xff && c != 0xd7 && c != 0xf7)

#define NSStringNilValueSubstitute(s)		((s == nil) ? NSStringEmptyPlaceholder : s)

#pragma mark 
#pragma mark String Helpers

@interface NSString (TXStringHelper)
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

- (NSString *)safeSubstringAfterIndex:(NSInteger)anIndex;
- (NSString *)safeSubstringBeforeIndex:(NSInteger)anIndex;

- (NSString *)safeSubstringFromIndex:(NSInteger)anIndex;
- (NSString *)safeSubstringToIndex:(NSInteger)anIndex;
- (NSString *)safeSubstringWithRange:(NSRange)range;

- (NSString *)stringCharacterAtIndex:(NSInteger)index;

- (NSString *)nicknameFromHostmask;
- (NSString *)identFromHostmask;
- (NSString *)hostFromHostmask;
- (NSString *)hostmaskFromRawString;

- (NSString *)cleanedServerHostmask;

- (BOOL)isEqualNoCase:(NSString *)other;

- (BOOL)contains:(NSString *)str;
- (BOOL)containsIgnoringCase:(NSString *)str;

- (NSInteger)findCharacter:(UniChar)c;
- (NSInteger)findCharacter:(UniChar)c start:(NSInteger)start;

- (NSInteger)stringPosition:(NSString *)needle;
- (NSInteger)stringPositionIgnoringCase:(NSString *)needle;

- (NSArray *)split:(NSString *)delimiter;
- (NSString *)trim;

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont followFormattingPreference:(BOOL)formattingPreference;
- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont;

- (UniChar)safeCharacterAtIndex:(NSInteger)index;

- (BOOL)isAlphaNumOnly;
- (BOOL)isNumericOnly;

- (NSInteger)firstCharCodePoint;
- (NSInteger)lastCharCodePoint;

- (NSString *)safeUsername;
- (NSString *)safeFileName;
- (NSString *)canonicalName;

- (NSString *)stripEffects;

- (NSRange)rangeOfChannelName;
- (NSRange)rangeOfChannelNameStart:(NSInteger)start;

- (NSString *)encodeURIComponent;
- (NSString *)encodeURIFragment;
- (NSString *)decodeURIFragement;

- (BOOL)isNickname;
- (BOOL)isIPv6Address;
- (BOOL)isChannelName;
- (BOOL)isModeChannelName;

+ (NSString *)stringWithUUID;

- (NSString *)reservedCharactersToIRCFormatting;

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont;

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font;
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
+ (NSString *)stringWithDouble:(TXNSDouble)value;
+ (NSString *)stringWithInteger:(NSInteger)value;
+ (NSString *)stringWithUnsignedInteger:(NSUInteger)value;
@end

#pragma mark 
#pragma mark Mutable String Helpers

@interface NSMutableString (TXMutableStringHelper)
- (NSString *)getToken;
- (void)safeDeleteCharactersInRange:(NSRange)range;
@end

#pragma mark 
#pragma mark Attributed String Helpers

@interface NSAttributedString (TXAttributedStringHelper)
- (NSDictionary *)attributes;

+ (NSAttributedString *)emptyString;
+ (NSAttributedString *)emptyStringWithBase:(NSString *)base;

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
- (NSAttributedString *)getToken;
@end
