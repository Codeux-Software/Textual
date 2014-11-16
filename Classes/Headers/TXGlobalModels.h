/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

/* Highest level objects implemented by Textual. */

/* Object state. */
TEXTUAL_EXTERN BOOL NSObjectIsEmpty(id obj);
TEXTUAL_EXTERN BOOL NSObjectIsNotEmpty(id obj);

TEXTUAL_EXTERN BOOL NSObjectsAreEqual(id obj1, id obj2);

/* Localization. */
TEXTUAL_EXTERN NSString *TXTLS(NSString *key, ...);
TEXTUAL_EXTERN NSString *BLS(NSInteger key, ...);

TEXTUAL_EXTERN NSString *TXLocalizedString(NSBundle *bundle, NSString *key, va_list args);
TEXTUAL_EXTERN NSString *TXLocalizedStringAlternative(NSBundle *bundle, NSString *key, ...);

/* Time. */
TEXTUAL_EXTERN NSString *TXFormattedTimestamp(NSDate *date, NSString *format); // Acts as a forward for strftime(). TXDefaultTextualTimestampFormat is used when format is empty.

TEXTUAL_EXTERN NSString *TXHumanReadableTimeInterval(NSInteger dateInterval, BOOL shortValue, NSUInteger orderMatrix);

TEXTUAL_EXTERN NSDateFormatter *TXSharedISOStandardDateFormatter(void);

/* Performance testing. */
/* Given a block, the block is executed. The time that was required to perform
 that work is then printed to system console. */
TEXTUAL_EXTERN void TXMeasurePerformanceOfBlock(NSString *description, TXEmtpyBlockDataType block);

/* Grand Central Dispatch. */
typedef enum TXPerformBlockOnDispatchQueueOperationType	: NSInteger {
	TXPerformBlockOnDispatchQueueBarrierAsyncOperationType,
	TXPerformBlockOnDispatchQueueBarrierSyncOperationType,
	TXPerformBlockOnDispatchQueueAsyncOperationType,
	TXPerformBlockOnDispatchQueueSyncOperationType,
} TXPerformBlockOnDispatchQueueOperationType;

TEXTUAL_EXTERN void TXPerformBlockOnSharedMutableSynchronizationDispatchQueue(dispatch_block_t block);

TEXTUAL_EXTERN void TXPerformBlockOnGlobalDispatchQueue(TXPerformBlockOnDispatchQueueOperationType operationType, dispatch_block_t block); // Uses default priority on queue.
TEXTUAL_EXTERN void TXPerformBlockOnMainDispatchQueue(TXPerformBlockOnDispatchQueueOperationType operationType, dispatch_block_t block);

TEXTUAL_EXTERN void TXPerformDelayedBlockOnGlobalQueue(dispatch_block_t block, NSInteger seconds);
TEXTUAL_EXTERN void TXPerformDelayedBlockOnMainQueue(dispatch_block_t block, NSInteger seconds);

TEXTUAL_EXTERN void TXPerformDelayedBlockOnQueue(dispatch_queue_t queue, dispatch_block_t block, NSInteger seconds);

TEXTUAL_EXTERN void TXPerformBlockSynchronouslyOnMainQueue(dispatch_block_t block);
TEXTUAL_EXTERN void TXPerformBlockAsynchronouslyOnMainQueue(dispatch_block_t block);

TEXTUAL_EXTERN void TXPerformBlockSynchronouslyOnGlobalQueue(dispatch_block_t block);
TEXTUAL_EXTERN void TXPerformBlockAsynchronouslyOnGlobalQueue(dispatch_block_t block);

TEXTUAL_EXTERN void TXPerformBlockSynchronouslyOnQueue(dispatch_queue_t queue, dispatch_block_t block);
TEXTUAL_EXTERN void TXPerformBlockAsynchronouslyOnQueue(dispatch_queue_t queue, dispatch_block_t block);

TEXTUAL_EXTERN void TXPerformBlockOnDispatchQueue(dispatch_queue_t queue, dispatch_block_t block, TXPerformBlockOnDispatchQueueOperationType operationType);

/* Everything else. */
TEXTUAL_EXTERN NSString *TXFormattedNumber(NSInteger number);

TEXTUAL_EXTERN NSInteger TXRandomNumber(NSInteger maxset);

TEXTUAL_EXTERN NSComparator NSDefaultComparator;
