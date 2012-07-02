// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TLOInputHistory : NSObject
@property (nonatomic, strong) id lastHistoryItem;
@property (nonatomic, strong) NSMutableArray *buf;
@property (nonatomic, assign) NSInteger pos;

- (void)add:(NSAttributedString *)s;

- (NSAttributedString *)up:(NSAttributedString *)s;
- (NSAttributedString *)down:(NSAttributedString *)s;
@end