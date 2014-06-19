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

#import "TextualApplication.h"

@implementation DDInvocation

+ (id)invocationGrabber
{
	return [[self alloc] init];
}

- (id)init
{
	_target = nil;
	_invocation = nil;
	_parentThread = nil;
	_waitUntilDone = NO;
	_threadType = DDInvocationBackgroundThread;
	
	return self;
}

- (id)prepareWithInvocationTarget:(id)inTarget
{
	_target = inTarget;
	
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
	return [_target methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)ioInvocation
{
	[ioInvocation setTarget:_target];
	
	_invocation = ioInvocation;
	
	if (_waitUntilDone == NO) {
		[_invocation retainArguments];
	}
	
	if (_parentThread && _threadType == DDInvocationParentThread) {
		[_invocation performSelector:@selector(performInvocation:)
							onThread:_parentThread
						  withObject:_invocation
					   waitUntilDone:NO];
	} else {
		if (_threadType == DDInvocationBackgroundThread) {
			[_invocation performSelectorInBackground:@selector(performInvocation:)
										  withObject:_invocation];
		} else {
			[_invocation performSelectorOnMainThread:@selector(performInvocation:)
										  withObject:_invocation
									   waitUntilDone:_waitUntilDone];
		}
	}
}

@end

@implementation NSInvocation (DDInvocationWrapper)

- (void)performInvocation:(NSInvocation *)anInvocation
{
	/* Mac OS does not automatically place background threads in an
	 autorelease pool like the default application run loop. For that
	 reason, let us invoke the invocation within our autorelease pool. */
	
	@autoreleasepool {
		[anInvocation invoke];
	}
}

@end
