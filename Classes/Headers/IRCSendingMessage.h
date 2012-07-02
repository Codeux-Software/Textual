// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface IRCSendingMessage : NSObject
@property (nonatomic, assign) NSString *command;
@property (nonatomic, strong) NSMutableArray *params;
@property (nonatomic, assign) BOOL completeColon;
@property (nonatomic, weak) NSString *string;

- (id)initWithCommand:(NSString *)aCommand;
- (void)addParameter:(NSString *)parameter;
@end