/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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