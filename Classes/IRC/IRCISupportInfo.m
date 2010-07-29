// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCISupportInfo.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"

#define ISUPPORT_SUFFIX	@" are supported by this server"
#define OP_VALUE		100

@interface IRCISupportInfo (Private)
- (void)setValue:(NSInteger)value forMode:(unsigned char)m;
- (NSInteger)valueForMode:(unsigned char)m;
- (BOOL)hasParamForMode:(unsigned char)m plus:(BOOL)plus;
- (void)parsePrefix:(NSString*)s;
- (void)parseChanmodes:(NSString*)s;
@end

@implementation IRCISupportInfo

@synthesize nickLen;
@synthesize modesCount;
@synthesize supportsWatchCommand;

- (id)init
{
	if (self = [super init]) {
		[self reset];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)reset
{
	memset(modes, 0, MODES_SIZE);
	nickLen = 9;
	modesCount = 3;
	
	[self setValue:OP_VALUE forMode:'o'];
	[self setValue:OP_VALUE forMode:'h'];
	[self setValue:OP_VALUE forMode:'v'];
	[self setValue:OP_VALUE forMode:'a'];
	[self setValue:OP_VALUE forMode:'q'];
	[self setValue:OP_VALUE forMode:'b'];
	[self setValue:OP_VALUE forMode:'e'];
	[self setValue:1 forMode:'I'];
	[self setValue:1 forMode:'R'];
	[self setValue:2 forMode:'k'];
	[self setValue:3 forMode:'l'];
	[self setValue:4 forMode:'i'];
	[self setValue:4 forMode:'m'];
	[self setValue:4 forMode:'n'];
	[self setValue:4 forMode:'p'];
	[self setValue:4 forMode:'s'];
	[self setValue:4 forMode:'t'];
	[self setValue:4 forMode:'r'];
}

- (void)update:(NSString*)str
{
	if ([str hasSuffix:ISUPPORT_SUFFIX]) {
		str = [str safeSubstringToIndex:str.length - [ISUPPORT_SUFFIX length]];
	}
	
	NSArray* ary = [str split:@" "];
	
	for (NSString* s in ary) {
		NSRange r = [s rangeOfString:@"="];
		if (r.location != NSNotFound) {
			NSString* key = [[s safeSubstringToIndex:r.location] uppercaseString];
			NSString* value = [s safeSubstringFromIndex:NSMaxRange(r)];
			
			if ([key isEqualToString:@"PREFIX"]) {
				[self parsePrefix:value];
			} else if ([key isEqualToString:@"CHANMODES"]) {
				[self parseChanmodes:value];
			} else if ([key isEqualToString:@"NICKLEN"]) {
				nickLen = [value integerValue];
			} else if ([key isEqualToString:@"MODES"]) {
				modesCount = [value integerValue];
			} else if ([key isEqualToString:@"WATCH"]) {
				supportsWatchCommand = YES;
			}
		}
	}
}

- (NSArray*)parseMode:(NSString*)str
{
	NSMutableArray* ary = [NSMutableArray array];
	NSMutableString* s = [[str mutableCopy] autorelease];
	BOOL plus = NO;
	
	while (!s.isEmpty) {
		NSString* token = [s getToken];
		if (token.isEmpty) break;
		UniChar c = [token characterAtIndex:0];
		
		if (c == '+' || c == '-') {
			plus = c == '+';
			token = [token safeSubstringFromIndex:1];
			
			NSInteger len = token.length;
			for (NSInteger i=0; i<len; i++) {
				c = [token characterAtIndex:i];
				switch (c) {
					case '-':
						plus = NO;
						break;
					case '+':
						plus = YES;
						break;
					default:
					{
						NSInteger v = [self valueForMode:c];
						if ([self hasParamForMode:c plus:plus]) {
							// 1 param
							IRCModeInfo* m = [IRCModeInfo modeInfo];
							m.mode = c;
							m.plus = plus;
							m.param = [s getToken];
							[ary addObject:m];
						} else {
							// simple mode
							IRCModeInfo* m = [IRCModeInfo modeInfo];
							m.mode = c;
							m.plus = plus;
							m.simpleMode = (v == 4);
							[ary addObject:m];
						}
						break;
					}
				}
			}
		}
	}
	
	return ary;
}

- (BOOL)hasParamForMode:(unsigned char)m plus:(BOOL)plus
{
	switch ([self valueForMode:m]) {
		case 0: return NO;
		case 1: return YES;
		case 2: return YES;
		case 3: return plus;
		case OP_VALUE: return YES;
		default: return NO;
	}
}

- (void)parsePrefix:(NSString*)str
{
	if ([str hasPrefix:@"("]) {
		NSRange r = [str rangeOfString:@")"];
		if (r.location != NSNotFound) {
			str = [str substringWithRange:NSMakeRange(1, r.location - 1)];
			
			NSInteger len = str.length;
			for (NSInteger i=0; i<len; i++) {
				UniChar c = [str characterAtIndex:i];
				[self setValue:OP_VALUE forMode:c];
			}
		}
	}
}

- (void)parseChanmodes:(NSString*)str
{
	NSArray* ary = [str split:@","];
	
	NSInteger count = ary.count;
	for (NSInteger i=0; i<count; i++) {
		NSString* s = [ary safeObjectAtIndex:i];
		NSInteger len = s.length;
		for (NSInteger j=0; j<len; j++) {
			UniChar c = [s characterAtIndex:j];
			[self setValue:i+1 forMode:c];
		}
	}
}

- (void)setValue:(NSInteger)value forMode:(unsigned char)m
{
	if ('a' <= m && m <= 'z') {
		NSInteger n = m - 'a';
		modes[n] = value;
	} else if ('A' <= m && m <= 'Z') {
		NSInteger n = m - 'A' + 26;
		modes[n] = value;
	}
}

- (NSInteger)valueForMode:(unsigned char)m
{
	if ('a' <= m && m <= 'z') {
		NSInteger n = m - 'a';
		return modes[n];
	} else if ('A' <= m && m <= 'Z') {
		NSInteger n = m - 'A' + 26;
		return modes[n];
	}
	return 0;
}

- (IRCModeInfo*)createMode:(NSString*)mode
{
	IRCModeInfo* m = [IRCModeInfo modeInfo];
	m.mode = [mode characterAtIndex:0];
	m.plus = NO;
	m.param = @"";
	return m;
}

@end

@implementation IRCModeInfo

@synthesize mode;
@synthesize plus;
@synthesize op;
@synthesize simpleMode;
@synthesize param;

+ (IRCModeInfo*)modeInfo
{
	return [[[IRCModeInfo alloc] init] autorelease];
}

- (void)dealloc
{
	[param release];
	[super dealloc];
}

@end