// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface InputHistory : NSObject
{
	NSMutableArray *buf;
	NSInteger pos;
}

@property (nonatomic, retain) NSMutableArray *buf;
@property (nonatomic, assign) NSInteger pos;

- (void)add:(NSString *)s;
- (NSString *)up:(NSString *)s;
- (NSString *)down:(NSString *)s;
@end