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