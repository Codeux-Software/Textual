// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSDictionary (NSDictionaryHelper)
- (BOOL)boolForKey:(NSString*)key;
- (NSInteger)intForKey:(NSString*)key;
- (long long)longLongForKey:(NSString*)key;
- (double)doubleForKey:(NSString*)key;
- (NSString*)stringForKey:(NSString*)key;
- (NSDictionary*)dictionaryForKey:(NSString*)key;
- (NSArray*)arrayForKey:(NSString*)key;
@end

@interface NSMutableDictionary (NSMutableDictionaryHelper)
- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (void)setInt:(NSInteger)value forKey:(NSString*)key;
- (void)setLongLong:(long long)value forKey:(NSString*)key;
- (void)setDouble:(double)value forKey:(NSString*)key;
@end