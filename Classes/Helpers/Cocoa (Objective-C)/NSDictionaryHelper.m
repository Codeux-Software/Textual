/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

@implementation NSDictionary (TXDictionaryHelper)

- (BOOL)boolForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	
	return NO;
}

- (NSInteger)integerForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(integerValue)]) {
		return [obj integerValue];
	}
	
	return 0;
}

- (long long)longLongForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	
	return 0;
}

- (double)doubleForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	
	return 0;
}

- (float)floatForKey:(NSString *)key
{
	id obj = self[key];

	if ([obj respondsToSelector:@selector(floatValue)]) {
		return [obj floatValue];
	}

	return 0;
}

- (NSString *)stringForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	
	return nil;
}

- (NSArray *)arrayForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	
	return nil;
}

- (void *)pointerForKey:(NSString *)key
{
	id obj = self[key];
	
	if ([obj isKindOfClass:[NSValue class]]) {
		return [obj pointerValue];
	}
	
	return nil;
}

- (id)objectForKey:(id)key orUseDefault:(id)defaultValue
{
	if ([self containsKey:key]) {
		return self[key];
	} else {
		return defaultValue;
	}
}

- (NSString *)stringForKey:(id)key orUseDefault:(NSString *)defaultValue
{
	if ([self containsKey:key]) {
		return [self stringForKey:key];
	} else {
		return defaultValue;
	}
}

- (BOOL)boolForKey:(NSString *)key orUseDefault:(BOOL)defaultValue
{
	if ([self containsKey:key]) {
		return [self boolForKey:key];
	} else {
		return defaultValue;
	}
}

- (NSArray *)arrayForKey:(NSString *)key orUseDefault:(NSArray *)defaultValue
{
	if ([self containsKey:key]) {
		return [self arrayForKey:key];
	} else {
		return defaultValue;
	}
}

- (NSDictionary *)dictionaryForKey:(NSString *)key orUseDefault:(NSDictionary *)defaultValue
{
	if ([self containsKey:key]) {
		return [self dictionaryForKey:key];
	} else {
		return defaultValue;
	}
}

- (NSInteger)integerForKey:(NSString *)key orUseDefault:(NSInteger)defaultValue
{
	if ([self containsKey:key]) {
		return [self integerForKey:key];
	} else {
		return defaultValue;
	}
}

- (long long)longLongForKey:(NSString *)key orUseDefault:(long long)defaultValue
{
	if ([self containsKey:key]) {
		return [self longLongForKey:key];
	} else {
		return defaultValue;
	}
}

- (double)doubleForKey:(NSString *)key orUseDefault:(double)defaultValue
{
	if ([self containsKey:key]) {
		return [self doubleForKey:key];
	} else {
		return defaultValue;
	}
}

- (float)floatForKey:(NSString *)key orUseDefault:(float)defaultValue
{
	if ([self containsKey:key]) {
		return [self floatForKey:key];
	} else {
		return defaultValue;
	}
}

- (void)assignObjectTo:(__strong id *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = self[key];
	}
}

- (void)assignObjectTo:(__strong id *)pointer forKey:(NSString *)key performCopy:(BOOL)copyValue
{
	if ([self containsKey:key]) {
		if (copyValue) {
			*pointer = [self[key] copy];
		} else {
			*pointer =  self[key];
		}
	}
}

- (void)assignStringTo:(__strong NSString **)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [[self stringForKey:key] copy];
	}
}

- (void)assignBoolTo:(BOOL *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [self boolForKey:key];
	}
}

- (void)assignArrayTo:(__strong NSArray **)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [[self arrayForKey:key] copy];
	}
}

- (void)assignDictionaryTo:(__strong NSDictionary **)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [[self dictionaryForKey:key] copy];
	}
}

- (void)assignIntegerTo:(NSInteger *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [self integerForKey:key];
	}
}

- (void)assignLongLongTo:(long long *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [self longLongForKey:key];
	}
}

- (void)assignDoubleTo:(double *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [self doubleForKey:key];
	}
}

- (void)assignFloatTo:(float *)pointer forKey:(NSString *)key
{
	if ([self containsKey:key]) {
		*pointer = [self floatForKey:key];
	}
}

- (BOOL)containsKey:(NSString *)baseKey
{	
	return NSDissimilarObjects(nil, self[baseKey]);
}
	
- (BOOL)containsKeyIgnoringCase:(NSString *)baseKey
{
	NSString *caslessKey = [self keyIgnoringCase:baseKey];
	
	return ([caslessKey length] > 0);
}

- (NSString *)firstKeyForObject:(id)object
{
	for (NSString *key in [self allKeys]) {
		if ([self[key] isEqual:object]) {
			return key;
		}
	}

	return nil;
}

- (NSString *)keyIgnoringCase:(NSString *)baseKey
{
	for (NSString *key in [self allKeys]) {
		if ([key isEqualIgnoringCase:baseKey]) {
			return key;
		} 
	}
	
	return nil;
}

- (id)sortedDictionary
{
	return [self sortedDictionary:NO];
}

- (id)sortedReversedDictionary
{
	return [self sortedDictionary:YES];
}

- (NSArray *)sortedDictionaryKeys
{
	return [self sortedDictionaryKeys:NO];
}

- (NSArray *)sortedDictionaryReversedKeys
{
	return [self sortedDictionaryKeys:YES];
}

- (NSArray *)sortedDictionaryKeys:(BOOL)reversed
{
	NSArray *keys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	if (reversed) {
		return [[keys reverseObjectEnumerator] allObjects];
	}

	return keys;
}

- (id)sortedDictionary:(BOOL)reversed
{
	NSArray *sortedKeys = [self sortedDictionaryKeys:reversed];

	NSMutableDictionary *newDict = [NSMutableDictionary dictionary];

	for (NSString *key in sortedKeys) {
		newDict[key] = self[key];
	}

	return newDict;
}

@end

@implementation NSMutableDictionary (TXMutableDictionaryHelper)

- (void)setObjectWithoutOverride:(id)value forKey:(NSString *)key
{
	if (PointerIsNotEmpty(value)) {
		if ([self containsKey:key] == NO) {
			self[key] = value;
		}
	}
}

- (void)maybeSetObject:(id)value forKey:(NSString *)key
{
	if (PointerIsNotEmpty(value)) {
		self[key] = value;
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

- (void)setDouble:(double)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setFloat:(float)value forKey:(NSString *)key
{
	self[key] = @(value);
}

- (void)setPointer:(void *)value forKey:(NSString *)key
{
	self[key] = [NSValue valueWithPointer:value];
}

@end
