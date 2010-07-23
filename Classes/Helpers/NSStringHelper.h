#import <Foundation/Foundation.h>

#define IsNumeric(c)						('0' <= (c) && (c) <= '9')
#define IsAlpha(c)							('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define IsAlphaNum(c)						(IsAlpha(c) || IsNumeric(c))
#define IsWordLetter(c)						(IsAlphaNum(c) || (c) == '_')
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