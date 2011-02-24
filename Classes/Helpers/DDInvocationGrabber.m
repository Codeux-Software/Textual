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

@synthesize target;
@synthesize invocation;
@synthesize threadType;
@synthesize parentThread;
@synthesize waitUntilDone;

+ (id)invocationGrabber
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    target = nil;
    invocation = nil;
	parentThread = nil;
    waitUntilDone = NO;
    threadType = INVOCATION_BACKGROUND_THREAD;
    
    return self;
}

- (id)prepareWithInvocationTarget:(id)inTarget
{
    target = [inTarget retain];
	
    return self;
}

- (void)dealloc
{
    [target release];
	[invocation release];
	[parentThread release];
	
    [super dealloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [target methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)ioInvocation
{
    [ioInvocation setTarget:target];
	
	invocation = [ioInvocation retain];
	
	if (waitUntilDone == NO) {
		[invocation retainArguments];
	}
	
	if (parentThread && threadType == INVOCATION_PARENT_THREAD) {
		[invocation performSelector:@selector(performInvocation:) 
						   onThread:parentThread
						 withObject:invocation
					  waitUntilDone:NO];
	} else {
		if (threadType == INVOCATION_BACKGROUND_THREAD) {
			[invocation performSelectorInBackground:@selector(performInvocation:)
										 withObject:invocation];
		} else {
			[invocation performSelectorOnMainThread:@selector(performInvocation:)
										 withObject:invocation
									  waitUntilDone:waitUntilDone];
		}
	}
}

@end

@implementation NSInvocation (DDInvocationWrapper)

- (void)performInvocation:(NSInvocation *)anInvocation 
{
	/* Mac OS does not automatically place background threads in an
	 autorelease pool like the default application run loop. For that
	 reason let us invoke the invocation within our autorelease pool. */
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	[anInvocation invoke];
	
	[pool drain];
}

@end 