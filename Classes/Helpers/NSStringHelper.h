// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "NSNumberHelper.h"

#define IsAlpha(c)							('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define IsNumeric(c)						('0' <= (c) && (c) <= '9' && !IsAlpha(c)) 
#define IsAlphaNum(c)						(IsAlpha(c) || IsNumeric(c))
#define IsWordLetter(c)						(IsAlphaNum(c) || (c) == '_')
#define IsIRCColor(c,f)						([NSNumber compareIRCColor:c against:f])
#define IsAlphaWithDiacriticalMark(c)		(0xc0 <= c && c <= 0xff && c != 0xd7 && c != 0xf7)

@interface NSString (NSStringHelper)
- (NSString *)safeSubstringFromIndex:(NSUInteger)anIndex;
- (NSString *)safeSubstringToIndex:(NSUInteger)anIndex;

- (NSString*)fastChopEndWithChars:(NSArray*)chars;

- (BOOL)isEqualNoCase:(NSString*)other;
- (BOOL)isEmpty;
- (BOOL)contains:(NSString*)str;
- (BOOL)containsIgnoringCase:(NSString*)str;
- (NSInteger)findCharacter:(UniChar)c;
- (NSInteger)findCharacter:(UniChar)c start:(NSInteger)start;
- (NSInteger)findString:(NSString*)str;
- (NSArray*)split:(NSString*)delimiter;
- (NSArray*)splitIntoLines;
- (NSString*)trim;

- (NSInteger)stringPosition:(NSString*)needle;

- (id)attributedStringWithIRCFormatting;

- (BOOL)isAlphaNumOnly;
- (BOOL)isNumericOnly;

- (NSInteger)firstCharCodePoint;
- (NSInteger)lastCharCodePoint;

- (NSString*)safeUsername;
- (NSString*)safeFileName;

- (NSString*)stripEffects;

- (NSRange)rangeOfUrl;
- (NSRange)rangeOfUrlStart:(NSInteger)start;

- (NSRange)rangeOfAddress;
- (NSRange)rangeOfAddressStart:(NSInteger)start;

- (NSRange)rangeOfChannelName;
- (NSRange)rangeOfChannelNameStart:(NSInteger)start;

- (NSString*)encodeURIComponent;
- (NSString*)encodeURIFragment;

- (BOOL)isChannelName;
- (BOOL)isModeChannelName;
- (NSString*)canonicalName;

+ (NSString*)bundleString:(NSString*)key;
@end

@interface NSMutableString (NSMutableStringHelper)
- (NSString*)getToken;
- (NSString*)getIgnoreToken;
@end