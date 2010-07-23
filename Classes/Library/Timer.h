#import <Cocoa/Cocoa.h>

@interface Timer : NSObject
{
	id delegate;
	BOOL reqeat;
	SEL selector;
	NSTimer* timer;
}

@property (assign) id delegate;
@property (assign) BOOL reqeat;
@property (assign) SEL selector;
@property (readonly) BOOL isActive;
@property (retain) NSTimer* timer;

- (void)start:(NSTimeInterval)interval;
- (void)stop;
@end

@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer*)sender;
@end