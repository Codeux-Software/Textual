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
@property (nonatomic, assign) BOOL actionValidated;
@property (nonatomic, strong, nullable) dispatch_source_t timerSource;
@end

@implementation TLOTimer

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitalState];

		return self;
	}

	return nil;
}

- (void)prepareInitalState
{
	self.repeatTimer = YES;
}

- (void)dealloc
{
	[self stop];
}

- (void)setAction:(nullable SEL)action
{
	if (self->_action != action) {
		self->_action = action;

		[self invalidateActionValidation];
	}
}

- (void)invalidateActionValidation
{
	self.actionValidated = NO;
}

- (BOOL)timerIsActive
{
	return (self.timerSource != nil);
}

- (void)start:(NSTimeInterval)interval
{
	[self stop];

	dispatch_queue_t sourceQueue = self.queue;

	if (sourceQueue == nil) {
		sourceQueue = dispatch_get_main_queue();
	}

	dispatch_source_t timerSource = XRScheduleBlockOnQueue(sourceQueue, ^{
		[self fireTimer];
	}, interval, self.repeatTimer);

	XRResumeScheduledBlock(timerSource);

	self.interval = interval;

	self.timerSource = timerSource;
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
	if (self.target == nil || self.action == NULL) {
		return;
	}

	if (self.actionValidated == NO) {
		NSMethodSignature *actionSignature = [self.target methodSignatureForSelector:self.action];

		if ([actionSignature validateMethodIsValidSenderDestination] == NO) {
			return;
		}

		self.actionValidated = YES;
	}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	(void)[self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop
}

@end

NS_ASSUME_NONNULL_END
