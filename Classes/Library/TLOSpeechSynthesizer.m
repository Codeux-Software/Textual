/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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
@property (nonatomic, assign) BOOL isSpeaking;
@end

@implementation TLOSpeechSynthesizer

- (id)init
{
	if ((self = [super init])) {
		self.isSpeaking = NO;
		
		self.itemsToBeSpoken = [NSMutableArray array];

		self.speechSynthesizer = [NSSpeechSynthesizer new];
		self.speechSynthesizer.delegate = self;

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark Public API

- (void)speak:(NSString *)message
{
	NSObjectIsEmptyAssert(message);

	if (self.isSpeaking == NO) {
		/* If we are already speaking, then we will allow the 
		 delegate to the call the next queue entry once it is
		 finished. We will only call it directly from here if
		 nothing is being spoken because the delegate would
		 never be called. */

		self.isSpeaking = YES;

		[self.speechSynthesizer startSpeakingString:message];
	} else {
		/* If we are talking right now, then add the message to the queue
		 so that it can be processed after the delegate has called us. */

		[self.itemsToBeSpoken safeAddObject:message];
	}
}

- (void)stopSpeakingAndMoveForward
{
	NSAssertReturn(self.isSpeaking);

	[self.speechSynthesizer stopSpeaking]; // Will call delegate to do next item.
}

- (void)speakNextQueueEntry
{
	NSObjectIsEmptyAssert(self.itemsToBeSpoken);

	self.isSpeaking = YES;

	NSString *nextMessage = [self.itemsToBeSpoken safeObjectAtIndex:0];

	[self.itemsToBeSpoken removeObjectAtIndex:0];

	[self.speechSynthesizer startSpeakingString:nextMessage];
}

#pragma mark -
#pragma mark Delegate Callback

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
	self.isSpeaking = NO;

	NSObjectIsEmptyAssert(self.itemsToBeSpoken); // Nothing to do.
	
	[self speakNextQueueEntry];
}

@end
