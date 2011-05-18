// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSArray (NSArrayHelper)
- (id)safeObjectAtIndex:(NSInteger)n;
- (BOOL)boolAtIndex:(NSInteger)n;
- (NSArray *)arrayAtIndex:(NSInteger)n;
- (NSString *)stringAtIndex:(NSInteger)n;
- (NSDictionary *)dictionaryAtIndex:(NSInteger)n;
- (NSInteger)integerAtIndex:(NSInteger)n;
- (long long)longLongAtIndex:(NSInteger)n;
- (NSDoubleN)doubleAtIndex:(NSInteger)n;
- (void *)pointerAtIndex:(NSInteger)n;

- (BOOL)containsObjectIgnoringCase:(id)anObject;
@end

@interface NSMutableArray (NSMutableArrayHelper)
- (void)safeRemoveObjectAtIndex:(NSInteger)n;

- (void)safeAddObject:(id)anObject;
- (void)addBool:(BOOL)value;
- (void)addInteger:(NSInteger)value;
- (void)addLongLong:(long long)value;
- (void)addDouble:(NSDoubleN)value;
- (void)addPointer:(void *)value;

- (void)safeInsertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)insertBool:(BOOL)value atIndex:(NSUInteger)index;
- (void)insertInteger:(NSInteger)value atIndex:(NSUInteger)index;
- (void)insertLongLong:(long long)value atIndex:(NSUInteger)index;
- (void)insertDouble:(NSDoubleN)value atIndex:(NSUInteger)index;
- (void)insertPointer:(void *)value atIndex:(NSUInteger)index;
@end

@interface NSIndexSet (NSIndexSetHelper)
- (NSArray *)arrayFromIndexSet;
@end