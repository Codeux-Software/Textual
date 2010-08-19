// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface HostResolver : NSObject
{
	id delegate;
}

@property (nonatomic, assign) id delegate;

- (id)initWithDelegate:(id)aDelegate;
- (void)resolve:(NSString*)hostname;
@end

@interface NSObject (HostResolverDelegate)
- (void)hostResolver:(HostResolver*)sender didResolve:(NSHost*)host;
- (void)hostResolver:(HostResolver*)sender didNotResolve:(NSString*)hostname;
@end