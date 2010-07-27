// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCMessage.h"
#import "NSStringHelper.h"

@interface IRCMessage (Private)
- (void)parseLine:(NSString*)line;

@end

@implementation IRCMessage

@synthesize sender;
@synthesize command;
@synthesize numericReply;
@synthesize params;

- (id)init
{
	if (self = [super init]) {
		[self parseLine:@""];
	}
	return self;
}

- (id)initWithLine:(NSString*)line
{
	if (self = [super init]) {
		[self parseLine:line];
	}
	return self;
}

- (void)dealloc
{
	[sender release];
	[command release];
	[params release];
	[super dealloc];
}

- (void)parseLine:(NSString*)line
{
	[sender release];
	[command release];
	[params release];
	
	sender = [IRCPrefix new];
	command = @"";
	params = [NSMutableArray new];
	
	NSMutableString* s = [line mutableCopy];
	
	if ([s hasPrefix:@":"]) {
		NSString* t = [s getToken];
		t = [t safeSubstringFromIndex:1];
		sender.raw = t;
		
		NSInteger i = [t findCharacter:'!'];
		if (i < 0) {
			sender.nick = t;
			sender.isServer = YES;
		} else {
			sender.nick = [t safeSubstringToIndex:i];
			t = [t safeSubstringFromIndex:i+1];
			
			i = [t findCharacter:'@'];
			if (i >= 0) {
				sender.user = [t safeSubstringToIndex:i];
				sender.address = [t safeSubstringFromIndex:i+1];
			}
		}
	}
	
	command = [[[s getToken] uppercaseString] retain];
	numericReply = [command integerValue];
	
	while (!s.isEmpty) {
		if ([s hasPrefix:@":"]) {
			[params addObject:[s safeSubstringFromIndex:1]];
			break;
		} else {
			[params addObject:[s getToken]];
		}
	}
	
	[s release];
}

- (NSString*)paramAt:(NSInteger)index
{
	if (index < params.count) {
		return [params safeObjectAtIndex:index];
	} else {
		return @"";
	}
}

- (NSString*)sequence
{
	if ([params count] < 2) {
		return [self sequence:0];
	} else {
		return [self sequence:1];
	}
}

- (NSString*)sequence:(NSInteger)index
{
	NSMutableString* s = [NSMutableString string];
	
	NSInteger count = params.count;
	for (NSInteger i=index; i<count; i++) {
		NSString* e = [params safeObjectAtIndex:i];
		if (i != index) [s appendString:@" "];
		[s appendString:e];
	}
	
	return s;
}

- (NSString*)description
{
	NSMutableString* ms = [NSMutableString string];
	[ms appendString:@"<IRCMessage "];
	[ms appendString:command];
	for (NSString* s in params) {
		[ms appendString:@" "];
		[ms appendString:s];
	}
	[ms appendString:@">"];
	return ms;
}

@end