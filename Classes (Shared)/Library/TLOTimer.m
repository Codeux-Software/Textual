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

#import "TLOTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLOTimer ()
@property (nonatomic, assign, readwrite) NSTimeInterval interval;
@property (nonatomic, assign, readwrite) BOOL repeatTimer;
@property (nonatomic, strong, nullable) dispatch_source_t timerSource;
@end

@implementation TLOTimer

+ (instancetype)timerWithActionBlock:(TLOTimerActionBlock)actionBlock
{
	NSParameterAssert(actionBlock != NULL);

	return [self _timerWithActionBlock:actionBlock onQueue:NULL];
}

+ (instancetype)timerWithActionBlock:(TLOTimerActionBlock)actionBlock onQueue:(dispatch_queue_t)queue
{
	NSParameterAssert(actionBlock != NULL);
	NSParameterAssert(queue != NULL);

	return [self _timerWithActionBlock:actionBlock onQueue:queue];
}

+ (instancetype)_timerWithActionBlock:(TLOTimerActionBlock)actionBlock onQueue:(nullable dispatch_queue_t)queue
{
	NSParameterAssert(actionBlock != NULL);

	TLOTimer *timer = [TLOTimer new];

	timer.actionBlock = actionBlock;

	timer.queue = queue;

	return timer;
}

- (void)dealloc
{
	[self stop];
}

- (BOOL)timerIsActive
{
	return (self.timerSource != nil);
}

- (void)start:(NSTimeInterval)timerInterval
{
	[self start:timerInterval onRepeat:NO];
}

- (void)start:(NSTimeInterval)timerInterval onRepeat:(BOOL)repeatTimer
{
	[self stop];

	dispatch_queue_t sourceQueue = self.queue;

	if (sourceQueue == nil) {
		sourceQueue = dispatch_get_main_queue();
	}

	dispatch_source_t timerSource = XRScheduleBlockOnQueue(sourceQueue, ^{
		[self fireTimer];
	}, timerInterval, repeatTimer);

	XRResumeScheduledBlock(timerSource);

	self.interval = timerInterval;

	self.timerSource = timerSource;

	self.repeatTimer = repeatTimer;
}

- (void)stop
{
	dispatch_source_t timerSource = self.timerSource;

	if (timerSource == nil) {
		return;
	}

	XRCancelScheduledBlock(timerSource);

	self.timerSource = nil;
}

- (void)fireTimer
{
	/* Perform block */
	TLOTimerActionBlock actionBlock = self.actionBlock;

	if (actionBlock) {
		actionBlock(self);

		return;
	}

	/* Perform action */
TEXTUAL_IGNORE_DEPRECATION_BEGIN

	id target = self.target;

	SEL action = self.action;

	if (target == nil || action == NULL) {
		return;
	}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	(void)[self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop

TEXTUAL_IGNORE_DEPRECATION_END
}

@end

NS_ASSUME_NONNULL_END
