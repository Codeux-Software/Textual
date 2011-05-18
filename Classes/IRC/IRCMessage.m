// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCMessage (Private)
- (void)parseLine:(NSString *)line;
@end

@implementation IRCMessage

@synthesize sender;
@synthesize command;
@synthesize numericReply;
@synthesize params;

- (id)init
{
	if ((self = [super init])) {
		[self parseLine:NSNullObject];
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

- (void)dealloc
{
	[sender drain];
	[command drain];
	[params drain];
	
	[super dealloc];
}

- (void)parseLine:(NSString *)line
{
	[sender drain];
	[command drain];
	[params drain];
	
	command = NSNullObject;
	sender = [IRCPrefix new];
	params = [NSMutableArray new];
	
	NSMutableString *s = [line mutableCopy];
	
	if ([s hasPrefix:@":"]) {
		NSString *t = [s getToken];
		
		t = [t safeSubstringFromIndex:1];
		
		sender.raw = t;
		
		NSInteger i = [t findCharacter:'!'];
		
		if (i < 0) {
			sender.nick = t;
			sender.isServer = YES;
		} else {
			sender.nick = [t safeSubstringToIndex:i];
			
			t = [t safeSubstringAfterIndex:i];
			i = [t findCharacter:'@'];
			
			if (i >= 0) {
				sender.user = [t safeSubstringToIndex:i];
				sender.address = [t safeSubstringAfterIndex:i];
			}
		}
	}
	
	command = [[[s getToken] uppercaseString] retain];
	numericReply = [command integerValue];
	
	while (NSObjectIsNotEmpty(s)) {
		if ([s hasPrefix:@":"]) {
			[params safeAddObject:[s safeSubstringFromIndex:1]];
			
			break;
		} else {
			[params safeAddObject:[s getToken]];
		}
	}
	
	[s drain];
}

- (NSString *)paramAt:(NSInteger)index
{
	if (index < params.count) {
		return [params safeObjectAtIndex:index];
	} else {
		return NSNullObject;
	}
}

- (NSString *)sequence
{
	if ([params count] < 2) {
		return [self sequence:0];
	} else {
		return [self sequence:1];
	}
}

- (NSString *)sequence:(NSInteger)index
{
	NSMutableString *s = [NSMutableString string];
	
	for (NSInteger i = index; i < params.count; i++) {
		NSString *e = [params safeObjectAtIndex:i];
		
		if (NSDissimilarObjects(i, index)) {
			[s appendString:NSWhitespaceCharacter];
		}
		
		[s appendString:e];
	}
	
	return s;
}

- (NSString *)description
{
	NSMutableString *ms = [NSMutableString string];
	
	[ms appendString:@"<IRCMessage "];
	[ms appendString:command];
	
	for (NSString *s in params) {
		[ms appendString:NSWhitespaceCharacter];
		[ms appendString:s];
	}
	
	[ms appendString:@">"];
	
	return ms;
}

@end