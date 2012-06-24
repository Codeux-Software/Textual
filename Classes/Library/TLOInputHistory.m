// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define _inputHistoryMax	50

@implementation TLOInputHistory

- (id)init
{
	if ((self = [super init])) {
		self.buf = [NSMutableArray new];
	}
	
	return self;
}

- (void)add:(NSAttributedString *)s
{
	NSAttributedString *lo = self.buf.lastObject;
	
	self.pos = self.buf.count;
	
	if (NSObjectIsEmpty(s)) return;
	if ([lo.string isEqualToString:s.string]) return;
	
	[self.buf safeAddObject:s];
	
	if (self.buf.count > _inputHistoryMax) {
		[self.buf safeRemoveObjectAtIndex:0];
	}
	
	self.pos = self.buf.count;
}

- (NSAttributedString *)up:(NSAttributedString *)s
{
	if (NSObjectIsNotEmpty(s)) {
		NSAttributedString *cur = nil;
		
		if (0 <= self.pos && self.pos < self.buf.count) {
			cur = [self.buf safeObjectAtIndex:self.pos];
		}
		
		if (NSObjectIsEmpty(cur) || [cur.string isEqualToString:s.string] == NO) {
			[self.buf safeAddObject:s];
			
			if (self.buf.count > _inputHistoryMax) {
				[self.buf safeRemoveObjectAtIndex:0];
				
				--self.pos;
			}
		}
	}	
	
	--self.pos;
	
	if (self.pos < 0) {
		self.pos = 0;
		
		return nil;
	} else if (0 <= self.pos && self.pos < self.buf.count) {
		return [self.buf safeObjectAtIndex:self.pos];
	} else {
		return [NSAttributedString emptyString];
	}
}

- (NSAttributedString *)down:(NSAttributedString *)s
{
	if (NSObjectIsEmpty(s)) {
		self.pos = self.buf.count;
		
		return nil;
	}
	
	NSAttributedString *cur = nil;
	
	if (0 <= self.pos && self.pos < self.buf.count) {
		cur = [self.buf safeObjectAtIndex:self.pos];
	}

	if (NSObjectIsEmpty(cur) || [cur.string isEqualToString:s.string] == NO) {
		[self add:s];
		
		return [NSAttributedString emptyString];
	} else {
		++self.pos;
		
		if (0 <= self.pos && self.pos < self.buf.count) {
			return [self.buf safeObjectAtIndex:self.pos];
		}
		
		return [NSAttributedString emptyString];
	}
}

@end