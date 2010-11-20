// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "HostResolver.h"

@implementation HostResolver

@synthesize delegate;

- (id)initWithDelegate:(id)aDelegate
{
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)resolve:(NSString*)hostname
{
	if (hostname.length) {
		[NSThread detachNewThreadSelector:@selector(resolveInternal:) toTarget:self withObject:hostname];
	}
}

- (void)resolveInternal:(NSString*)hostname
{
	[self retain];
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSHost* host = [NSHost hostWithName:hostname];
	NSArray* info = [NSArray arrayWithObjects:hostname, host, nil];
	[self performSelectorOnMainThread:@selector(hostResolved:) withObject:info waitUntilDone:YES];
	
	[pool drain];
	
	[self release];
}

- (void)hostResolved:(NSArray*)info
{
	if (!delegate) return;
	
	if ([info count] == 2) {
		NSHost* host = [info safeObjectAtIndex:1];
		if ([delegate respondsToSelector:@selector(hostResolver:didResolve:)]) {
			[delegate hostResolver:self didResolve:host];
		}
	} else {
		NSString* hostname = [info safeObjectAtIndex:0];
		if ([delegate respondsToSelector:@selector(hostResolver:didNotResolve:)]) {
			[delegate hostResolver:self didNotResolve:hostname];
		}
	}
}

@end