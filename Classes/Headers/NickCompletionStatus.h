// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NickCompletionStatus : NSObject
{
	NSString *text;
	NSRange range;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) NSRange range;

- (void)clear;
@end