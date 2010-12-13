// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface UnicodeHelper : NSObject
+ (BOOL)isPrivate:(UniChar)c;
+ (BOOL)isIdeographic:(UniChar)c;
+ (BOOL)isIdeographicOrPrivate:(UniChar)c;
+ (BOOL)isAlphabeticalCodePoint:(NSInteger)c;
@end