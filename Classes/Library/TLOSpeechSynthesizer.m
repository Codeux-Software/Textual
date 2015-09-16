/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

@interface TLOSpeechSynthesizer ()
@property (nonatomic, strong) NSSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) NSMutableArray *itemsToBeSpoken;
@property (nonatomic, assign) BOOL isWaitingForSystemToStopSpeaking;
@end

@implementation TLOSpeechSynthesizer

- (instancetype)init
{
	if ((self = [super init])) {
		self.isStopped = NO;
		
		self.itemsToBeSpoken = [NSMutableArray array];

		 self.speechSynthesizer = [NSSpeechSynthesizer new];
		[self.speechSynthesizer setDelegate:self];

		return self;
	}

	return nil;
}

- (void)dealloc
{
	[self.speechSynthesizer setDelegate:nil];
}

#pragma mark -
#pragma mark Public API

- (void)speak:(NSString *)message
{
	/* Validate input. */
	NSAssertReturn(self.isStopped == NO);

	NSObjectIsEmptyAssert(message);

	/* Add item and speak. */
	@synchronized(self.itemsToBeSpoken) {
		[self.itemsToBeSpoken addObject:message];
	}
	
	if ([self isSpeaking] == NO) {
		[self speakNextQueueEntry];
	}
}

- (void)speakNextItemWhenSystemFinishes
{
	/* Loop until system is done. */
	while ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
		[NSThread sleepForTimeInterval:1.0];
	}

	/* Destroy flag. */
	self.isWaitingForSystemToStopSpeaking = NO;

	/* Speak. */
	[self speakNextQueueEntry];
}

- (void)stopSpeakingAndMoveForward
{
	if ([self isSpeaking]) {
		[self.speechSynthesizer stopSpeaking]; // Will call delegate to do next item.
	}
}

- (void)speakNextQueueEntry
{
	/* Do not do anything if stopped. */
	NSAssertReturn(self.isStopped == NO);

	/* Speak next item. */
	@synchronized(self.itemsToBeSpoken) {
		if ([self.itemsToBeSpoken count] > 0) {
			if ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
				/* If the system is speaking, then special actions must be performed. */

				/* Loop in background. */
				if (self.isWaitingForSystemToStopSpeaking == NO) {
					/* Set flag. */
					self.isWaitingForSystemToStopSpeaking = YES;

					/* Start waiting for system to finish. */
					[self performBlockOnGlobalQueue:^{
						[self speakNextItemWhenSystemFinishes];
					}];
				}

				/* Do not continue. */
				return;
			}

			/* Continue with normal speaking operation. */
			NSString *nextMessage = self.itemsToBeSpoken[0]; // Get item.

			[self.itemsToBeSpoken removeObjectAtIndex:0]; // Remove from queue.

			[self.speechSynthesizer startSpeakingString:nextMessage]; // Speak.
		}
	}
}

- (void)setIsStopped:(BOOL)isStopped
{
	/* Update internal flag. */
	_isStopped = isStopped;

	/* Stop speaking. */
	if ([self isStopped]) {
		if ([self isSpeaking]) {
			[self.speechSynthesizer stopSpeaking];
		}
	}
}

- (void)clearQueue
{
	@synchronized(self.itemsToBeSpoken) {
		[self.itemsToBeSpoken removeAllObjects];
	}
}

- (BOOL)isSpeaking
{
	return [self.speechSynthesizer isSpeaking];
}

#pragma mark -
#pragma mark Delegate Callback

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
	[self speakNextQueueEntry];
}

@end
