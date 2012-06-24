// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation NSDictionary (TXDictionaryHelper)

- (BOOL)boolForKey:(NSString *)key
{
	if (self.count <= 0) {
		return NO;
	}
	
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	
	return NO;
}

- (NSInteger)integerForKey:(NSString *)key
{
	if (self.count <= 0) {
		return 0;
	}
	
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(integerValue)]) {
		return [obj integerValue];
	}
	
	return 0;
}

- (long long)longLongForKey:(NSString *)key
{
	if (self.count <= 0) {
		return 0;
	}
	
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	
	return 0;
}

- (TXNSDouble)doubleForKey:(NSString *)key
{
	if (self.count <= 0) {
		return 0;
	}
	
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	
	return 0;
}

- (NSString *)stringForKey:(NSString *)key
{
	if (self.count <= 0) {
		return nil;
	}
	
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
	if (self.count <= 0) {
		return nil;
	}
	
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	
	return nil;
}

- (NSArray *)arrayForKey:(NSString *)key
{
	if (self.count <= 0) {
		return nil;
	}
	
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	
	return nil;
}

- (void *)pointerForKey:(NSString *)key
{
	if (self.count <= 0) {
		return nil;
	}
	
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSValue class]]) {
		return [obj pointerValue];
	}
	
	return nil;
}

- (BOOL)containsKey:(NSString *)baseKey
{	
	return BOOLValueFromObject([self objectForKey:baseKey]);
}
	
- (BOOL)containsKeyIgnoringCase:(NSString *)baseKey
{
	return NSObjectIsNotEmpty([self keyIgnoringCase:baseKey]);
}

- (NSString *)keyIgnoringCase:(NSString *)baseKey
{
	for (NSString *key in [self allKeys]) {
		if ([key isEqualNoCase:baseKey]) {
			return key;
		} 
	}
	
	return nil;
}

- (NSDictionary *)sortedDictionary
{
	NSArray *sortedKeys = [self.allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
	
	for (NSString *key in sortedKeys) {
		newDict[key] = self[key];
	}

	return newDict;
}

@end

@implementation NSMutableDictionary (TXMutableDictionaryHelper)

- (void)safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey
{
	if (PointerIsNotEmpty(anObject)) {
		self[aKey] = anObject;
	}
}

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setLongLong:(long long)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setDouble:(TXNSDouble)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setPointer:(void *)value forKey:(NSString *)key
{
	self[key] = [NSValue valueWithPointer:value];
}

- (NSMutableDictionary *)sortedDictionary
{
	NSArray *sortedKeys = [self.allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
	
	for (NSString *key in sortedKeys) {
		newDict[key] = self[key];
	}
	
	return newDict;
}

@end