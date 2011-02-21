// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSArray (NSArrayHelper)

- (id)safeObjectAtIndex:(NSInteger)n
{
	if (n >= 0 && n < self.count) {
		return [self objectAtIndex:n];
	}
	
	return nil;
}

- (BOOL)containsObjectIgnoringCase:(id)anObject
{
	for (id object in self) {
		if ([object isKindOfClass:[NSString class]]) {
			if ([object isEqualNoCase:anObject]) {
				return YES;
			}
		} 
	}
	
	return [self containsObject:anObject];
}

@end

@implementation NSMutableArray (NSMutableArrayHelper)

- (void)safeRemoveObjectAtIndex:(NSInteger)n
{
	if (n >= 0 && n < self.count) {
		[self removeObjectAtIndex:n];
	}
}

- (void)safeAddObject:(id)anObject
{
	if (PointerIsEmpty(anObject) == NO) {
		[self addObject:anObject];
	}
}

- (void)safeInsertObject:(id)anObject atIndex:(NSUInteger)index
{
	if (PointerIsEmpty(anObject) == NO) {
		[self insertObject:anObject atIndex:index];
	}
}

@end

@implementation NSIndexSet (NSIndexSetHelper)

- (NSArray *)arrayFromIndexSet
{
	NSMutableArray *ary = [NSMutableArray array];
	
	NSUInteger current_index = [self lastIndex];
	
	while (current_index != NSNotFound) {
		[ary addObject:[NSNumber numberWithUnsignedInteger:current_index]];
		
		current_index = [self indexLessThanIndex:current_index];
	}
	
	return ary;
}

@end