// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation NSArray (TXArrayHelper)

- (id)safeObjectAtIndex:(NSInteger)n
{
	if (n >= 0 && n < self.count) {
		return self[n];
	}
	
	return nil;
}

- (BOOL)boolAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	
	return 0;
}

- (NSArray *)arrayAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	
	return nil;
}

- (NSString *)stringAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return nil;
}

- (NSDictionary *)dictionaryAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	
	return nil;
}

- (NSInteger)integerAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj respondsToSelector:@selector(integerValue)]) {
		return [obj integerValue];
	}
	
	return 0;
}

- (long long)longLongAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	
	return 0;
}

- (TXNSDouble)doubleAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	
	return 0;
}

- (void *)pointerAtIndex:(NSInteger)n
{
	id obj = [self safeObjectAtIndex:n];
	
	if ([obj isKindOfClass:[NSValue class]]) {
		return [obj pointerValue];
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

@implementation NSMutableArray (TXMutableArrayHelper)

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

- (void)insertBool:(BOOL)value atIndex:(NSUInteger)index
{
	[self safeInsertObject:@(value) atIndex:index];
}

- (void)insertInteger:(NSInteger)value atIndex:(NSUInteger)index
{
	[self safeInsertObject:@(value) atIndex:index];
}

- (void)insertLongLong:(long long)value atIndex:(NSUInteger)index
{
	[self safeInsertObject:@(value) atIndex:index];
}

- (void)insertDouble:(TXNSDouble)value atIndex:(NSUInteger)index
{
	[self safeInsertObject:@(value) atIndex:index];
}

- (void)insertPointer:(void *)value atIndex:(NSUInteger)index
{
	[self safeInsertObject:[NSValue valueWithPointer:value] atIndex:index];
}

- (void)addBool:(BOOL)value
{
	[self safeAddObject:@(value)];
}

- (void)addInteger:(NSInteger)value
{
	[self safeAddObject:@(value)];
}

- (void)addLongLong:(long long)value
{
	[self safeAddObject:@(value)];
}
	 
- (void)addDouble:(TXNSDouble)value
{
	[self safeAddObject:@(value)];
}

- (void)addPointer:(void *)value
{
	[self safeAddObject:[NSValue valueWithPointer:value]];
}

@end

@implementation NSIndexSet (TXIndexSetHelper)

- (NSArray *)arrayFromIndexSet
{
	NSMutableArray *ary = [NSMutableArray array];
	
	NSUInteger current_index = [self lastIndex];
	
	while (NSDissimilarObjects(current_index, NSNotFound)) {
		[ary addObject:@(current_index)];
		
		current_index = [self indexLessThanIndex:current_index];
	}
	
	return ary;
}

@end