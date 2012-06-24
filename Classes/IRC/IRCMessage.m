// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation IRCMessage

- (id)init
{
	if ((self = [super init])) {
		[self parseLine:NSStringEmptyPlaceholder];
	}
	
	return self;
}

- (id)initWithLine:(NSString *)line
{
	if ((self = [super init])) {
		[self parseLine:line];
	}
	
	return self;
}

- (void)parseLine:(NSString *)line
{
	self.command = NSStringEmptyPlaceholder;
	
	self.sender = [IRCPrefix new];
	self.params = [NSMutableArray new];
	
	NSMutableString *s = [line mutableCopy];
	
	if ([s hasPrefix:@"@t="]) { // znc server-time
		NSString *t;
		
		t = [s getToken];
		t = [t substringFromIndex:3];
		
		self.receivedAt = [NSDate dateWithTimeIntervalSince1970:[t longLongValue]];
	} else {
		self.receivedAt = [NSDate date];
	}
	
	if ([s hasPrefix:@":"]) {
		NSString *t;
		
		t = [s getToken];
		t = [t safeSubstringFromIndex:1];
		
		self.sender.raw = t;
		
		NSInteger i = [t findCharacter:'!'];
		
		if (i < 0) {
			self.sender.nick = t;
			self.sender.isServer = YES;
		} else {
			self.sender.nick = [t safeSubstringToIndex:i];
			
			t = [t safeSubstringAfterIndex:i];
			i = [t findCharacter:'@'];
			
			if (i >= 0) {
				self.sender.user = [t safeSubstringToIndex:i];
				self.sender.address = [t safeSubstringAfterIndex:i];
			}
		}
	}
	
	self.command = [s.getToken uppercaseString];
	
	self.numericReply = [self.command integerValue];
	
	while (NSObjectIsNotEmpty(s)) {
		if ([s hasPrefix:@":"]) {
			[self.params safeAddObject:[s safeSubstringFromIndex:1]];
			
			break;
		} else {
			[self.params safeAddObject:[s getToken]];
		}
	}
	
}

- (NSString *)paramAt:(NSInteger)index
{
	if (index < self.params.count) {
		return [self.params safeObjectAtIndex:index];
	} else {
		return NSStringEmptyPlaceholder;
	}
}

- (NSString *)sequence
{
	if ([self.params count] < 2) {
		return [self sequence:0];
	} else {
		return [self sequence:1];
	}
}

- (NSString *)sequence:(NSInteger)index
{
	NSMutableString *s = [NSMutableString string];
	
	for (NSInteger i = index; i < self.params.count; i++) {
		NSString *e = [self.params safeObjectAtIndex:i];
		
		if (NSDissimilarObjects(i, index)) {
			[s appendString:NSStringWhitespacePlaceholder];
		}
		
		[s appendString:e];
	}
	
	return s;
}

- (NSString *)description
{
	NSMutableString *ms = [NSMutableString string];
	
	[ms appendString:@"<IRCMessage "];
	[ms appendString:self.command];
	
	for (NSString *s in self.params) {
		[ms appendString:NSStringWhitespacePlaceholder];
		[ms appendString:s];
	}
	
	[ms appendString:@">"];
	
	return ms;
}

@end