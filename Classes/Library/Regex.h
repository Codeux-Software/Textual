// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


typedef struct URegularExpression URegularExpression;

typedef enum { 
	UREGEX_UNIX_LINES = 1,
	UREGEX_CASE_INSENSITIVE = 2,
	UREGEX_COMMENTS = 4,
	UREGEX_MULTILINE = 8,
	UREGEX_LITERAL = 16,
	UREGEX_DOTALL = 32, 
	UREGEX_CANON_EQ = 128,
	UREGEX_UWORD = 256, 
	UREGEX_ERROR_ON_UNKNOWN_ESCAPES = 512,
} URegexOption;


@interface Regex : NSObject
{
	URegularExpression* regex;
}

- (id)initWithString:(NSString*)pattern;
- (id)initWithStringNoCase:(NSString*)pattern;
- (id)initWithString:(NSString*)pattern options:(URegexOption)options;

- (NSRange)match:(NSString*)string;
- (NSRange)match:(NSString*)string start:(NSInteger)start;

- (NSInteger)groupCount;
- (NSRange)groupAt:(NSInteger)groupNum;

- (void)reset;

@end
