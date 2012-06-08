// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface Timer : NSObject
{
	id __unsafe_unretained delegate;
	
	BOOL reqeat;
	SEL selector;
	
	NSTimer *timer;
}

@property (unsafe_unretained) id delegate;
@property (assign) BOOL reqeat;
@property (assign) SEL selector;
@property (readonly) BOOL isActive;
@property (strong) NSTimer *timer;

- (void)start:(NSTimeInterval)interval;
- (void)stop;
@end

@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer *)sender;
@end