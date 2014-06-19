/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

- (id)init
{
	if ((self = [super init])) {
		_isStopped = NO;
		
		_itemsToBeSpoken = [NSMutableArray array];

		_speechSynthesizer = [NSSpeechSynthesizer new];
		_speechSynthesizer.delegate = self;

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark Public API

- (void)speak:(NSString *)message
{
	/* Validate input. */
	NSAssertReturn(_isStopped == NO);

	NSObjectIsEmptyAssert(message);

	/* Add item and speak. */
	[_itemsToBeSpoken addObject:message];

	if ([self isSpeaking] == NO) {
		[self speakNextQueueEntry];
	}
}

- (void)speakNextItemWhenSystemFinishes
{
	/* Loop until system is done. */
	while ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
		;
	}

	/* Destroy flag. */
	_isWaitingForSystemToStopSpeaking = NO;

	/* Speak. */
	[self speakNextQueueEntry];
}

- (void)stopSpeakingAndMoveForward
{
	if ([self isSpeaking]) {
		[_speechSynthesizer stopSpeaking]; // Will call delegate to do next item.
	}
}

- (void)speakNextQueueEntry
{
	/* Do not do anything if stopped. */
	NSAssertReturn(_isStopped == NO);

	/* Speak next item. */
	if ([_itemsToBeSpoken count] > 0) {
		if ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
			/* If the system is speaking, then special actions must be performed. */

			/* Loop in background. */
			if (_isWaitingForSystemToStopSpeaking == NO) {
				/* Set flag. */
				_isWaitingForSystemToStopSpeaking = YES;

				/* Start waiting for system to finish. */
				[[self invokeInBackgroundThread] speakNextItemWhenSystemFinishes];
			}

			/* Do not continue. */
			return;
		}

		/* Continue with normal speaking operation. */
		NSString *nextMessage = _itemsToBeSpoken[0]; // Get item.

		[_itemsToBeSpoken removeObjectAtIndex:0]; // Remove from queue.

		[_speechSynthesizer startSpeakingString:nextMessage]; // Speak.
	}
}

- (void)setIsStopped:(BOOL)isStopped
{
	/* Update internal flag. */
	_isStopped = isStopped;

	/* Stop speaking. */
	if ([self isSpeaking]) {
		[_speechSynthesizer stopSpeaking];
	}
}

- (void)clearQueue
{
	[_itemsToBeSpoken removeAllObjects];
}

- (BOOL)isSpeaking
{
	return [_speechSynthesizer isSpeaking];
}

#pragma mark -
#pragma mark Delegate Callback

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
	[self speakNextQueueEntry];
}

@end
