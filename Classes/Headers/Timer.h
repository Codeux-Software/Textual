// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface Timer : NSObject
{
	id delegate;
	
	BOOL reqeat;
	SEL selector;
	
	NSTimer *timer;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL reqeat;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, retain) NSTimer *timer;

- (void)start:(NSTimeInterval)interval;
- (void)stop;
@end

@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer *)sender;
@end