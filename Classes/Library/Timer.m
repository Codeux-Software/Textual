// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation Timer

@synthesize delegate;
@synthesize reqeat;
@synthesize selector;
@synthesize timer;

- (id)init
{
	if ((self = [super init])) {
		reqeat = YES;
		selector = @selector(timerOnTimer:);
	}
	
	return self;
}

- (void)dealloc
{
	[self stop];
	
}

- (BOOL)isActive
{
	return BOOLValueFromObject(timer);
}

- (void)start:(NSTimeInterval)interval
{
	[self stop];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:interval 
											  target:self 
											selector:@selector(onTimer:) 
											userInfo:nil repeats:reqeat];
	
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
	[timer invalidate];
	timer = nil;
}

- (void)onTimer:(id)sender
{
	if (self.isActive == NO) return;
	
	if (reqeat == NO) {
		[self stop];
	}
	
	if ([delegate respondsToSelector:selector]) {
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[delegate performSelector:selector withObject:self];
#pragma clang diagnostic pop
		
	}
}

@end