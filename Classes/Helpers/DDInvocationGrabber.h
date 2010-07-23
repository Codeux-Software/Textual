#import <Foundation/Foundation.h>

@interface DDInvocationGrabber : NSProxy
{
	id _target;
	NSInvocation * _invocation;
	BOOL _forwardInvokesOnMainThread;
	BOOL _waitUntilDone;
}

+ (id)invocationGrabber;

- (id)target;
- (void)setTarget:(id)inTarget;

- (NSInvocation *)invocation;
- (void)setInvocation:(NSInvocation *)inInvocation;

- (BOOL)forwardInvokesOnMainThread;
- (void)setForwardInvokesOnMainThread:(BOOL)forwardInvokesOnMainThread;

- (BOOL)waitUntilDone;
- (void)setWaitUntilDone:(BOOL)waitUntilDone;
@end

@interface DDInvocationGrabber (DDInvocationGrabber_Conveniences)
- (id)prepareWithInvocationTarget:(id)inTarget;
@end