/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#import <objc/objc-runtime.h>

@interface TLOTimer ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation TLOTimer

- (instancetype)init
{
	if ((self = [super init])) {
		_reqeatTimer = YES;
		
		_selector = nil;
		_delegate = nil;
	}

	return self;
}

- (void)dealloc
{
	[self stop];
}

- (BOOL)timerIsActive
{
	return ((_timer == nil) == NO);
}

- (void)start:(NSTimeInterval)interval
{
	PointerIsEmptyAssert(_delegate);
	PointerIsEmptyAssert(_selector);

	[self stop];

	_timer = [NSTimer scheduledTimerWithTimeInterval:interval
											  target:self
											selector:@selector(onTimer:)
											userInfo:nil
											 repeats:_reqeatTimer];

	[RZCurrentRunLoop() addTimer:_timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
	if ( _timer) {
		[_timer invalidate];
		 _timer = nil;
	}
}

- (void)onTimer:(id)sender
{
	NSAssertReturn([self timerIsActive]);

	if (_reqeatTimer == NO) {
		[self stop];
	}

	if ([_delegate respondsToSelector:_selector]) {
		objc_msgSend(_delegate, _selector, self);
	}
}

@end
