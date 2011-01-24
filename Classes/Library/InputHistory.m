// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>// You can redistribute it and/or modify it under the new BSD license.

#define INPUT_HISTORY_MAX	50

@implementation InputHistory

@synthesize buf;
@synthesize pos;

- (id)init
{
	if ((self = [super init])) {
		buf = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[buf release];
	[super dealloc];
}

- (void)add:(NSString *)s
{
	pos = buf.count;
	
	if (NSStringIsEmpty(s)) return;
	if ([[buf lastObject] isEqualToString:s]) return;
	
	[buf addObject:s];
	
	if (buf.count > INPUT_HISTORY_MAX) {
		[buf safeRemoveObjectAtIndex:0];
	}
	
	pos = buf.count;
}

- (NSString *)up:(NSString *)s
{
	if (NSStringIsEmpty(s) == NO) {
		NSString *cur = nil;
		
		if (0 <= pos && pos < buf.count) {
			cur = [buf safeObjectAtIndex:pos];
		}
		
		if (cur == nil || [cur isEqualToString:s] == NO) {
			[buf addObject:s];
			
			if (buf.count > INPUT_HISTORY_MAX) {
				[buf safeRemoveObjectAtIndex:0];
				
				--pos;
			}
		}
	}
	
	--pos;
	
	if (pos < 0) {
		pos = 0;
		
		return nil;
	} else if (0 <= pos && pos < buf.count) {
		return [buf safeObjectAtIndex:pos];
	} else {
		return @"";
	}
}

- (NSString *)down:(NSString *)s
{
	if (NSStringIsEmpty(s)) {
		pos = buf.count;
		
		return nil;
	}
	
	NSString *cur = nil;
	
	if (0 <= pos && pos < buf.count) {
		cur = [buf safeObjectAtIndex:pos];
	}

	if (cur == nil || [cur isEqualToString:s] == NO) {
		[self add:s];
		
		return @"";
	} else {
		++pos;
		
		if (0 <= pos && pos < buf.count) {
			return [buf safeObjectAtIndex:pos];
		}
		
		return @"";
	}
}

@end