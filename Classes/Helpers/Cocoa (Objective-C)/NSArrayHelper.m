/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#include <objc/message.h>

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
	id obj = self[n];
	
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	
	return 0;
}

- (NSArray *)arrayAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	
	return nil;
}

- (NSString *)stringAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return nil;
}

- (NSDictionary *)dictionaryAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	
	return nil;
}

- (NSInteger)integerAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj respondsToSelector:@selector(integerValue)]) {
		return [obj integerValue];
	}
	
	return 0;
}

- (long long)longLongAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	
	return 0;
}

- (double)doubleAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	
	return 0;
}

- (void *)pointerAtIndex:(NSInteger)n
{
	id obj = self[n];
	
	if ([obj isKindOfClass:[NSValue class]]) {
		return [obj pointerValue];
	}
	
	return nil;
}

- (BOOL)containsObjectIgnoringCase:(id)anObject
{
	for (id object in self) {
		if ([object isKindOfClass:[NSString class]]) {
			if ([object isEqualIgnoringCase:anObject]) {
				return YES;
			}
		} 
	}
	
	return [self containsObject:anObject];
}

- (NSRange)range
{
	return NSMakeRange(0, [self count]);
}

- (NSArray *)arrayByInsertingSortedObject:(id)obj usingComparator:(NSComparator)comparator
{
	NSMutableArray *arry = [self mutableCopy];

	[arry insertSortedObject:obj usingComparator:comparator];

	return [arry copy];
}

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)idx
{
	NSMutableArray *arry = [self mutableCopy];

	[arry removeObjectAtIndex:idx];

	return [arry copy];
}

- (NSMutableArray *)mutableSubarrayWithRange:(NSRange)range
{
	NSArray *subray = [self subarrayWithRange:range];
	
	return [subray mutableCopy];
}

- (NSUInteger)indexOfObjectMatchingValue:(id)value withKeyPath:(NSString *)keyPath
{
	return [self indexOfObjectMatchingValue:value withKeyPath:keyPath usingSelector:@selector(isEqual:)];
}

- (NSUInteger)indexOfObjectMatchingValue:(id)value withKeyPath:(NSString *)keyPath usingSelector:(SEL)comparison
{
	__block NSUInteger retval = NSNotFound;

	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		id objval = [obj valueForKeyPath:keyPath];
		
		if ([objval respondsToSelector:comparison] == NO) {
			return;
		}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		if ((BOOL)[objval performSelector:comparison withObject:value]) {
#pragma clang diagnostic pop
			retval = idx;
			
			*stop = YES;
		}
	}];

	return retval;
}

@end

@implementation NSMutableArray (TXMutableArrayHelper)

- (void)addObjectWithoutDuplication:(id)anObject
{
	if (PointerIsEmpty(anObject) == NO) {
		if ([self containsObject:anObject] == NO) {
			[self addObject:anObject];
		}
	}
}

- (void)safeRemoveObjectAtIndex:(NSInteger)n
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)safeAddObject:(id)anObject
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)safeAddObjectWithoutDuplication:(id)anObject
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)safeInsertObject:(id)anObject atIndex:(NSUInteger)index
{
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)insertBool:(BOOL)value atIndex:(NSUInteger)index
{
	[self insertObject:@(value) atIndex:index];
}

- (void)insertInteger:(NSInteger)value atIndex:(NSUInteger)index
{
	[self insertObject:@(value) atIndex:index];
}

- (void)insertLongLong:(long long)value atIndex:(NSUInteger)index
{
	[self insertObject:@(value) atIndex:index];
}

- (void)insertDouble:(double)value atIndex:(NSUInteger)index
{
	[self insertObject:@(value) atIndex:index];
}

- (void)insertPointer:(void *)value atIndex:(NSUInteger)index
{
	[self insertObject:[NSValue valueWithPointer:value] atIndex:index];
}

- (void)addBool:(BOOL)value
{
	[self addObject:@(value)];
}

- (void)addInteger:(NSInteger)value
{
	[self addObject:@(value)];
}

- (void)addLongLong:(long long)value
{
	[self addObject:@(value)];
}
	 
- (void)addDouble:(double)value
{
	[self addObject:@(value)];
}

- (void)addPointer:(void *)value
{
	[self addObject:[NSValue valueWithPointer:value]];
}

- (void)performSelectorOnObjectValueAndReplace:(SEL)performSelector
{
	NSArray *oldArray = [self copy];

	[self removeAllObjects];

	for (__strong id object in oldArray) {
		if ([object respondsToSelector:performSelector]) {
			id newObject = objc_msgSend(object, performSelector);
			
			if (newObject) {
				[self addObject:newObject];
			}
		}
	}
}

- (NSUInteger)insertSortedObject:(id)obj usingComparator:(NSComparator)comparator
{
	PointerIsEmptyAssertReturn(obj, NSNotFound);

	NSUInteger idx = [self indexOfObject:obj
						   inSortedRange:[self range]
								 options:NSBinarySearchingInsertionIndex
						 usingComparator:comparator];

	[self insertObject:obj atIndex:idx];
	
	return idx;
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
