// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

#define _isupportSuffix		@" are supported by this server"
#define _opValue			100

@interface IRCISupportInfo (Private)
- (void)setValue:(NSInteger)value forMode:(unsigned char)m;
- (NSInteger)valueForMode:(unsigned char)m;
- (BOOL)hasParamForMode:(unsigned char)m plus:(BOOL)plus;
- (void)parsePrefix:(NSString *)value;
- (void)parseChanmodes:(NSString *)s;
@end

@implementation IRCISupportInfo


- (id)init
{
	if ((self = [super init])) {
		[self reset];
	}
	
	return self;
}

- (void)reset
{
	memset(modes, 0, TXModesSize);
	
	self.nickLen    = 9;
	self.modesCount = 3;
	
	[self setValue:_opValue forMode:'o'];
	[self setValue:_opValue forMode:'h'];
	[self setValue:_opValue forMode:'v'];
	[self setValue:_opValue forMode:'a'];
	[self setValue:_opValue forMode:'q'];
	[self setValue:_opValue forMode:'b'];
	[self setValue:_opValue forMode:'e'];
    [self setValue:_opValue forMode:'u'];
	
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
	
	[self setUserModeOPrefix:@"@"];
	[self setUserModeVPrefix:@"+"];
}

- (BOOL)update:(NSString *)str client:(IRCClient *)client
{
	if ([str hasSuffix:_isupportSuffix]) {
		str = [str safeSubstringToIndex:(str.length - _isupportSuffix.length)];
	}
	
	NSArray *ary = [str split:NSStringWhitespacePlaceholder];
	
	for (NSString *s in ary) {
		NSString *key   = s;
		NSString *value = nil;
		
		NSRange r = [s rangeOfString:@"="];
		
		if (NSDissimilarObjects(r.location, NSNotFound)) {
			key   = [s safeSubstringToIndex:r.location].uppercaseString;
			value = [s safeSubstringFromIndex:NSMaxRange(r)];
		}
		
		if (value) {
			if ([key isEqualToString:@"PREFIX"]) {
				[self parsePrefix:value];
			} else if ([key isEqualToString:@"CHANMODES"]) {
				[self parseChanmodes:value];
			} else if ([key isEqualToString:@"NICKLEN"]) {
				self.nickLen = [value integerValue];
			} else if ([key isEqualToString:@"MODES"]) {
				self.modesCount = [value integerValue];
			} else if ([key isEqualToString:@"NETWORK"]) {
				self.networkName = value;
			}
		}
		
		if ([key isEqualToString:@"NAMESX"] && client.multiPrefix == NO) {
			[client sendLine:@"PROTOCTL NAMESX"];
			
			client.multiPrefix = YES;
			
			[client.acceptedCaps addObject:@"multi-prefix"];
		} else if ([key isEqualToString:@"UHNAMES"] && client.userhostInNames == NO) {
			[client sendLine:@"PROTOCTL UHNAMES"];
			
			client.userhostInNames = YES;
			
			[client.acceptedCaps addObject:@"userhost-in-names"];
		}
	}
	
	return NO;
}

- (NSArray *)parseMode:(NSString *)str
{
	NSMutableArray *ary = [NSMutableArray array];
	
	NSMutableString *s = [str mutableCopy];
	
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
					case '-': plus = NO; break;
					case '+': plus = YES; break;
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
		case 0: return NO; break;
		case 1: return YES; break;
		case 2: return YES; break;
		case 3: return plus; break;
		case _opValue: return YES; break;
		default: return NO; break;
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
				
				[self setValue:_opValue forMode:rawKey];
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
	
	m.plus  = NO;
	m.param = NSStringEmptyPlaceholder;
	m.mode  = [mode characterAtIndex:0];
	
	return m;
}

@end