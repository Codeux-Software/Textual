/*
 * Copyright (c) 2007-2009 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@implementation DDInvocationGrabber

+ (id)invocationGrabber
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    _target = nil;
    _invocation = nil;
    _waitUntilDone = NO;
    _threadType = INVOCATION_BACKGROUND_THREAD;
    
    return self;
}

- (void)dealloc
{
    [self setTarget:NULL];
    [self setInvocation:NULL];
	
    [super dealloc];
}

- (id)target
{
    return _target;
}

- (void)setTarget:(id)inTarget
{
    if (_target != inTarget) {
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
    if (_invocation != inInvocation) {
        [_invocation autorelease];
        _invocation = [inInvocation retain];
	}
}

- (invocationThreadType)threadType
{
	return _threadType;
}

- (void)setInvocationThreadType:(invocationThreadType)threadType
{
	_threadType = threadType;
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
	
	if (_waitUntilDone == NO) {
		[_invocation retainArguments];
	}
	
    if (_threadType == INVOCATION_MAIN_THREAD)
    {
        [_invocation performSelectorOnMainThread:@selector(invoke)
                                      withObject:nil
                                   waitUntilDone:_waitUntilDone];
    } else {
        [_invocation performSelectorInBackground:@selector(performInvocation:)
									  withObject:_invocation];
	}
}

@end

@implementation DDInvocationGrabber (DDnvocationGrabber_Conveniences)

- (id)prepareWithInvocationTarget:(id)inTarget
{
    [self setTarget:inTarget];
	
    return self;
}

@end

@implementation NSInvocation (DDInvocationWrapper)

- (void)performInvocation:(NSInvocation *)anInvocation {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	[anInvocation invoke];
	
	[pool drain];
}

@end 