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

- (double)doubleForKey:(NSString *)key
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

- (BOOL)containsKey:(id)anObject
{	
	return BOOLValueFromObject([self objectForKey:anObject]);
}
	
- (BOOL)containsKeyIgnoringCase:(id)anObject
{
	for (id object in [self allKeys]) {
		if ([object isKindOfClass:[NSString class]]) {
			if ([object isEqualNoCase:anObject]) {
				return YES;
			}
		} 
	}
	
	return [self containsKey:anObject];
}

@end

@implementation NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

- (void)setLongLong:(long long)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithLongLong:value] forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

@end