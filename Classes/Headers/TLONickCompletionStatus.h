// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

@interface TLONickCompletionStatus : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) NSRange range;

- (void)clear;
@end