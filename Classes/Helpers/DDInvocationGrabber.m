#import "DDInvocationGrabber.h"

@implementation DDInvocationGrabber

+ (id)invocationGrabber
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    _target = nil;
    _invocation = nil;
    _forwardInvokesOnMainThread = NO;
    _waitUntilDone = NO;
    
    return self;
}

- (void)dealloc
{
    [self setTarget:NULL];
    [self setInvocation:NULL];
    //
    [super dealloc];
}

#pragma mark -

- (id)target
{
    return _target;
}

- (void)setTarget:(id)inTarget
{
    if (_target != inTarget)
	{
        [_target autorelease];
        _target = [inTarget retain];
	}
}

- (NSInvocation *)invocation
{
    return _invocation;
}

- (void)setInvocation:(NSInvocation *)inInvocation
{
    if (_invocation != inInvocation)
	{
        [_invocation autorelease];
        _invocation = [inInvocation retain];
	}
}

- (BOOL)forwardInvokesOnMainThread;
{
    return _forwardInvokesOnMainThread;
}

- (void)setForwardInvokesOnMainThread:(BOOL)forwardInvokesOnMainThread;
{
    _forwardInvokesOnMainThread = forwardInvokesOnMainThread;
}

- (BOOL)waitUntilDone;
{
    return _waitUntilDone;
}

- (void)setWaitUntilDone:(BOOL)waitUntilDone;
{
    _waitUntilDone = waitUntilDone;
}

#pragma mark -

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [[self target] methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)ioInvocation
{
    [ioInvocation setTarget:[self target]];
    [self setInvocation:ioInvocation];
    if (_forwardInvokesOnMainThread)
    {
        if (!_waitUntilDone)
            [_invocation retainArguments];
        [_invocation performSelectorOnMainThread:@selector(invoke)
                                      withObject:nil
                                   waitUntilDone:_waitUntilDone];
    }
}
@end

#pragma mark -

@implementation DDInvocationGrabber (DDnvocationGrabber_Conveniences)

- (id)prepareWithInvocationTarget:(id)inTarget
{
    [self setTarget:inTarget];
    return(self);
}

@end