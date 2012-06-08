// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface InputHistory : NSObject
{
	id lastHistoryItem;
	
	NSMutableArray *buf;
	NSInteger pos;
}

@property (strong) id lastHistoryItem;
@property (strong) NSMutableArray *buf;
@property (assign) NSInteger pos;

- (void)add:(NSAttributedString *)s;

- (NSAttributedString *)up:(NSAttributedString *)s;
- (NSAttributedString *)down:(NSAttributedString *)s;
@end