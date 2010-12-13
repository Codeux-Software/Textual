// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface URLParser : NSObject
+ (NSRange)rangeOfUrlStart:(NSInteger)start withString:(NSString*)string;
+ (NSArray*)fastChopURL:(NSString *)url;
+ (NSString*)complexURLRegularExpression;
+ (NSDictionary*)URLRegexSpecialCharactersMapping;
+ (NSArray*)bannedURLRegexEndChars;
+ (NSArray*)bannedURLRegexLeftBufferChars;
+ (NSArray*)bannedURLRegexRightBufferChars;
+ (NSArray*)bannedURLRegexLineTypes;
@end