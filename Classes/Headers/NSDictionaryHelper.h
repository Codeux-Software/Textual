// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSDictionary (NSDictionaryHelper)
- (BOOL)boolForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (long long)longLongForKey:(NSString *)key;
- (NSDoubleN)doubleForKey:(NSString *)key;
- (void *)pointerForKey:(NSString *)key;

- (BOOL)containsKey:(NSString *)baseKey;
- (BOOL)containsKeyIgnoringCase:(NSString *)baseKey;

- (NSString *)keyIgnoringCase:(NSString *)baseKey;
@end

@interface NSMutableDictionary (NSMutableDictionaryHelper)
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setLongLong:(long long)value forKey:(NSString *)key;
- (void)setDouble:(NSDoubleN)value forKey:(NSString *)key;
- (void)setPointer:(void *)value forKey:(NSString *)key;
@end