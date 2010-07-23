// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Regex.h"


#define U_PARSE_CONTEXT_LEN	16

typedef struct UParseError {
	int32_t line;
	int32_t offset;
	UniChar preContext[U_PARSE_CONTEXT_LEN];
	UniChar postContext[U_PARSE_CONTEXT_LEN];
} UParseError;

typedef int32_t UErrorCode;

URegularExpression* uregex_open(const UniChar* pattern, int32_t patternLength, uint32_t flags, UParseError* pe, UErrorCode* status);
void uregex_close(URegularExpression* regexp);
void uregex_reset(URegularExpression* regexp, int32_t index, UErrorCode* status);
void uregex_setText(URegularExpression* regexp, const UniChar* text, int32_t textLength, UErrorCode* status);
BOOL uregex_find(URegularExpression* regexp, int32_t startIndex, UErrorCode* status);
BOOL uregex_findNext(URegularExpression* regexp, UErrorCode* status);
int32_t uregex_appendReplacement(URegularExpression* regexp, const UniChar* replacementText, int32_t replacementLength, UniChar** destBuf, int32_t* destCapacity, UErrorCode* status);
int32_t uregex_appendTail(URegularExpression* regexp, UniChar** destBuf, int32_t* destCapacity, UErrorCode* status);
int32_t uregex_groupCount(URegularExpression* regexp, UErrorCode* status);
int32_t uregex_start(URegularExpression* regexp, int32_t groupNum, UErrorCode* status);
int32_t uregex_end(URegularExpression* regexp, int32_t groupNum, UErrorCode* status);
const char* u_errorName(UErrorCode status);


@implementation Regex

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (id)initWithString:(NSString*)pattern
{
	return [self initWithString:pattern options:0];
}

- (id)initWithStringNoCase:(NSString*)pattern
{
	return [self initWithString:pattern options:UREGEX_CASE_INSENSITIVE];
}

- (id)initWithString:(NSString*)pattern options:(URegexOption)options
{
	[self init];
	
	NSInteger len = pattern.length;
	UniChar buf[len];
	CFStringGetCharacters((CFStringRef)pattern, CFRangeMake(0, len), buf);
	
	int32_t status = 0;
	regex = uregex_open(buf, len, options, NULL, &status);
	
	return self;
}

- (void)dealloc
{
	if (regex) uregex_close(regex);
	[super dealloc];
}

- (NSRange)match:(NSString*)string
{
	return [self match:string start:0];
}

- (NSRange)match:(NSString*)string start:(NSInteger)start
{
	NSInteger len = string.length;
	if (!len || len <= start) return NSMakeRange(NSNotFound, 0);
	
	UniChar buf[len];
	CFStringGetCharacters((CFStringRef)string, CFRangeMake(0, len), buf);
	
	int32_t status = 0;
	uregex_reset(regex, 0, &status);
	
	status = 0;
	uregex_setText(regex, buf, len, &status);
	
	status = 0;
	BOOL res = uregex_find(regex, start, &status);
	if (res) {
		return [self groupAt:0];
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSInteger)groupCount
{
	int32_t status = 0;
	return uregex_groupCount(regex, &status);
}

- (NSRange)groupAt:(NSInteger)groupNum
{
	int32_t status = 0;
	int32_t location = uregex_start(regex, groupNum, &status);
	status = 0;
	int32_t end = uregex_end(regex, groupNum, &status);
	return NSMakeRange(location, end - location);
}

- (void)reset
{
	int32_t status = 0;
	uregex_reset(regex, 0, &status);
}

@end
