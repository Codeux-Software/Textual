// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@implementation Timer

@synthesize delegate;
@synthesize reqeat;
@synthesize selector;
@synthesize timer;
@synthesize isActive;

- (id)init
{
	if ((self = [super init])) {
		self.reqeat = YES;
		self.selector = @selector(timerOnTimer:);
	}
	
	return self;
}

- (void)dealloc
{
	[self stop];
}

- (BOOL)isActive
{
	return BOOLValueFromObject(self.timer);
}

- (void)start:(NSTimeInterval)interval
{
	[self stop];
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:interval 
											  target:self 
											selector:@selector(onTimer:) 
											userInfo:nil repeats:self.reqeat];
	
	[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
	[self.timer invalidate];
	self.timer = nil;
}

- (void)onTimer:(id)sender
{
	if (self.isActive == NO) return;
	
	if (self.reqeat == NO) {
		[self stop];
	}
	
	if ([self.delegate respondsToSelector:self.selector]) {
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self.delegate performSelector:self.selector withObject:self];
#pragma clang diagnostic pop
		
	}
}

@end