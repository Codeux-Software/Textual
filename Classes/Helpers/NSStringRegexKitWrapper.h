// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define RKReplaceAll INT_MAX

@interface NSString (NSStringRegexKitWrapper) 
- (NSRange)rangeOfRegex:(NSString *)aRegex;
- (BOOL)isMatchedByRegex:(NSString *)aRegex;
- (BOOL)getCapturesWithRegexAndReferences:(NSString *)aRegex, ...;
- (NSString *)stringByMatching:(NSString *)aRegex replace:(int)options withReferenceString:(NSString *) replacement;
@end