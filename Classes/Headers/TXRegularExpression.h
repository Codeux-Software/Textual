// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class NSRegularExpression;

@interface TXRegularExpression : NSObject
+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle;
+ (NSArray *)matchesInString:(NSString *)haystack withRegex:(NSString *)needle withoutCase:(BOOL)caseless;

+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle;
+ (BOOL)string:(NSString *)haystack isMatchedByRegex:(NSString *)needle withoutCase:(BOOL)caseless;

+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle;
+ (NSRange)string:(NSString *)haystack rangeOfRegex:(NSString *)needle withoutCase:(BOOL)caseless;

+ (NSString *)string:(NSString *)haystack replacedByRegex:(NSString *)needle withString:(NSString *)puppy;
@end