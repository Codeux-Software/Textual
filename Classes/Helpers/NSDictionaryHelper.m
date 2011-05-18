// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSDictionary (NSDictionaryHelper)

- (BOOL)boolForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	
	return NO;
}

- (NSInteger)integerForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj respondsToSelector:@selector(integerValue)]) {
		return [obj integerValue];
	}
	
	return 0;
}

- (long long)longLongForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	
	return 0;
}

- (NSDoubleN)doubleForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	
	return 0;
}

- (NSString *)stringForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	
	return nil;
}

- (NSArray *)arrayForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	
	return nil;
}

- (void *)pointerForKey:(NSString *)key
{
	id obj = [self objectForKey:key];
	
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

@end

@implementation NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
	[self setObject:NSNumberWithBOOL(value) forKey:key];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
	[self setObject:NSNumberWithInteger(value) forKey:key];
}

- (void)setLongLong:(long long)value forKey:(NSString *)key
{
	[self setObject:NSNumberWithLongLong(value) forKey:key];
}

- (void)setDouble:(NSDoubleN)value forKey:(NSString *)key
{
	[self setObject:NSNumberWithDouble(value) forKey:key];
}

- (void)setPointer:(void *)value forKey:(NSString *)key
{
	[self setObject:[NSValue valueWithPointer:value] forKey:key];
}

@end