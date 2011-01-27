// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCSendingMessage : NSObject
{
	NSString *string;
	NSString *command;
	
	BOOL completeColon;
	
	NSMutableArray *params;
}

@property (nonatomic, readonly) NSString *command;
@property (nonatomic, readonly) NSMutableArray *params;
@property (nonatomic, assign) BOOL completeColon;
@property (nonatomic, readonly) NSString *string;

- (id)initWithCommand:(NSString *)aCommand;
- (void)addParameter:(NSString *)parameter;
@end