// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import <OgreKit/NSString_OgreKitAdditions.h>

#define RKReplaceAll INT_MAX

@interface NSString (NSStringRegexKitWrapper) 

- (BOOL)isMatchedByRegex:(NSString *)aRegex;
- (NSRange)rangeOfRegex:(NSString *)aRegex;
- (NSString *)stringByMatching:(NSString *)aRegex replace:(int)options withReferenceString:(NSString *) replacement;
- (BOOL) getCapturesWithRegexAndReferences:(NSString *)aRegex, ...;

@end
