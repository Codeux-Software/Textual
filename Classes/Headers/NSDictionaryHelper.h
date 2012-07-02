// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define NSDictionaryObjectKeyValueCompare(o,n,s)			   (id)(([o containsKey:n]) ? [o objectForKey:n] : s)
#define NSDictionaryIntegerKeyValueCompare(o,n,s)		(NSInteger)(([o containsKey:n]) ? [o integerForKey:n] : s)

@interface NSDictionary (TXDictionaryHelper)
- (BOOL)boolForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (long long)longLongForKey:(NSString *)key;
- (TXNSDouble)doubleForKey:(NSString *)key;
- (void *)pointerForKey:(NSString *)key;

- (BOOL)containsKey:(NSString *)baseKey;
- (BOOL)containsKeyIgnoringCase:(NSString *)baseKey;

- (NSString *)keyIgnoringCase:(NSString *)baseKey;

- (NSDictionary *)sortedDictionary;
@end

@interface NSMutableDictionary (TXMutableDictionaryHelper)
- (void)safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setLongLong:(long long)value forKey:(NSString *)key;
- (void)setDouble:(TXNSDouble)value forKey:(NSString *)key;
- (void)setPointer:(void *)value forKey:(NSString *)key;

- (NSMutableDictionary *)sortedDictionary;
@end