// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface IRCSendingMessage : NSObject
{
	NSString* command;
	NSMutableArray* params;
	BOOL completeColon;
	NSString* string;
}

@property (readonly) NSString* command;
@property (readonly) NSMutableArray* params;
@property (assign) BOOL completeColon;
@property (readonly) NSString* string;

- (id)initWithCommand:(NSString*)aCommand;
- (void)addParameter:(NSString*)parameter;
@end