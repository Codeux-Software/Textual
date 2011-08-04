// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define ISUPPORT_SUFFIX		@" are supported by this server"
#define OP_VALUE			100

@interface IRCISupportInfo (Private)
- (void)setValue:(NSInteger)value forMode:(unsigned char)m;
- (NSInteger)valueForMode:(unsigned char)m;
- (BOOL)hasParamForMode:(unsigned char)m plus:(BOOL)plus;
- (void)parsePrefix:(NSString *)value;
- (void)parseChanmodes:(NSString *)s;
@end

@implementation IRCISupportInfo

@synthesize nickLen;
@synthesize modesCount;
@synthesize networkName;
@synthesize userModeQPrefix;
@synthesize userModeAPrefix;
@synthesize userModeOPrefix;
@synthesize userModeHPrefix;
@synthesize userModeVPrefix;

- (id)init
{
	if ((self = [super init])) {
		[self reset];
	}
	
	return self;
}

- (void)dealloc
{
	[networkName drain];
	[userModeQPrefix drain];
	[userModeAPrefix drain];
	[userModeOPrefix drain];
	[userModeHPrefix drain];
	[userModeVPrefix drain];
	
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
    [self setValue:OP_VALUE forMode:'u'];
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

- (BOOL)update:(NSString *)str
{
	if ([str hasSuffix:ISUPPORT_SUFFIX]) {
		str = [str safeSubstringToIndex:(str.length - [ISUPPORT_SUFFIX length])];
	}
	
	NSArray *ary = [str split:@" "];
	
	for (NSString *s in ary) {
		NSRange r = [s rangeOfString:@"="];
		
		if (r.location != NSNotFound) {
			NSString *key = [[s safeSubstringToIndex:r.location] uppercaseString];
			NSString *value = [s safeSubstringFromIndex:NSMaxRange(r)];
			
			if ([key isEqualToString:@"PREFIX"]) {
				[self parsePrefix:value];
			} else if ([key isEqualToString:@"CHANMODES"]) {
				[self parseChanmodes:value];
			} else if ([key isEqualToString:@"NICKLEN"]) {
				nickLen = [value integerValue];
			} else if ([key isEqualToString:@"MODES"]) {
				modesCount = [value integerValue];
			} else if ([key isEqualToString:@"NETWORK"]) {
				networkName = [value retain];
			} 
		}
	}
	
	return NO;
}

- (NSArray *)parseMode:(NSString *)str
{
	NSMutableArray *ary = [NSMutableArray array];
	NSMutableString *s = [[str mutableCopy] autodrain];
	
	BOOL plus = NO;
	
	while (NSObjectIsNotEmpty(s)) {
		NSString *token = [s getToken];
		if (NSObjectIsEmpty(token)) break;
		
		UniChar c = [token characterAtIndex:0];
		
		if (c == '+' || c == '-') {
			plus = (c == '+');
			
			token = [token safeSubstringFromIndex:1];
			
			for (NSInteger i = 0; i < token.length; i++) {
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
						
						IRCModeInfo *m = [IRCModeInfo modeInfo];
						
						if ([self hasParamForMode:c plus:plus]) {
							m.mode = c;
							m.plus = plus;
							m.param = [s getToken];
						} else {
							m.mode = c;
							m.plus = plus;
							m.simpleMode = (v == 4);
						}
						
						[ary safeAddObject:m];
						
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

- (void)parsePrefix:(NSString *)value
{
	if ([value contains:@"("] && [value contains:@")"]) {
		NSInteger endSignPos = [value stringPosition:@")"];
		NSInteger modeLength = 0;
		NSInteger charLength = 0;
		
		NSString *nodes;
		NSString *chars;
		
		nodes = [value safeSubstringToIndex:endSignPos];
		nodes = [nodes safeSubstringFromIndex:1];
		
		chars = [value safeSubstringAfterIndex:endSignPos];
		
		charLength = [chars length];
		modeLength = [nodes length];
		
		if (charLength == modeLength) {
			for (NSInteger i = 0; i < charLength; i++) {
				UniChar  rawKey     = [nodes characterAtIndex:i];
				NSString *modeKey   = [nodes stringCharacterAtIndex:i];
				NSString *modeChar  = [chars stringCharacterAtIndex:i];
				
				if ([modeKey isEqualToString:@"q"] || [modeKey isEqualToString:@"u"]) {
					self.userModeQPrefix = modeChar;
				} else if ([modeKey isEqualToString:@"a"]) {
					self.userModeAPrefix = modeChar;
				} else if ([modeKey isEqualToString:@"o"]) {
					self.userModeOPrefix = modeChar;
				} else if ([modeKey isEqualToString:@"h"]) {
					self.userModeHPrefix = modeChar;
				} else if ([modeKey isEqualToString:@"v"]) {
					self.userModeVPrefix = modeChar;
				}
				
				[self setValue:OP_VALUE forMode:rawKey];
			}
		}
	}
}

- (void)parseChanmodes:(NSString *)str
{
	NSArray *ary = [str split:@","];
	
	for (NSInteger i = 0; i < ary.count; i++) {
		NSString *s = [ary safeObjectAtIndex:i];
		
		for (NSInteger j = 0; j < s.length; j++) {
			UniChar c = [s characterAtIndex:j];
			
			[self setValue:(i + 1) forMode:c];
		}
	}
}

- (void)setValue:(NSInteger)value forMode:(unsigned char)m
{
	if ('a' <= m && m <= 'z') {
		NSInteger n = (m - 'a');
		
		modes[n] = value;
	} else if ('A' <= m && m <= 'Z') {
		NSInteger n = ((m - 'A') + 26);
		
		modes[n] = value;
	}
}

- (NSInteger)valueForMode:(unsigned char)m
{
	if ('a' <= m && m <= 'z') {
		NSInteger n = (m - 'a');
		
		return modes[n];
	} else if ('A' <= m && m <= 'Z') {
		NSInteger n = ((m - 'A') + 26);
		
		return modes[n];
	}
	
	return 0;
}

- (IRCModeInfo *)createMode:(NSString *)mode
{
	IRCModeInfo *m = [IRCModeInfo modeInfo];
	
	m.mode = [mode characterAtIndex:0];
	m.plus = NO;
	m.param = @"";
	
	return m;
}

@end