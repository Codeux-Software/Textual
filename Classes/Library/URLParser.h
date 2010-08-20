// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

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