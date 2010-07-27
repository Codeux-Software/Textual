// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface NSArray (NSArrayHelper)
- (id)safeObjectAtIndex:(NSInteger)n;
@end