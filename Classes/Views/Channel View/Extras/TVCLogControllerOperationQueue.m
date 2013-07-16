/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

#pragma mark -
#pragma mark Define Private Header

@interface TVCLogControllerOperationItem : NSOperation
@property (nonatomic, nweak) TVCLogController *controller;
@property (nonatomic, strong) void (^executionBlock)(void);
@property (nonatomic, assign) BOOL isCompleted;

- (id)initWithQueue:(TVCLogControllerOperationQueue *)queue controller:(TVCLogController *)controller;
@end

#pragma mark -
#pragma mark Operation Queue

@implementation TVCLogControllerOperationQueue

#pragma mark -
#pragma mark Queue Additions

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender
{
	[self enqueueMessageBlock:callbackBlock for:sender context:nil];
}

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender context:(NSDictionary *)context
{
	dispatch_async(dispatch_get_main_queue(), ^{
		PointerIsEmptyAssert(callbackBlock);
		PointerIsEmptyAssert(sender);

		TVCLogControllerOperationItem *operation = [[TVCLogControllerOperationItem alloc] initWithQueue:self controller:sender];

		/* We keep a week reference to our operation to remove it from our controller's 
		 operations array after isCompleted has flown. */
		__weak TVCLogControllerOperationItem *operationRef = operation;

		operation.executionBlock = ^{
			callbackBlock(operationRef, context);
		};

		/* Add the operations. */
		[sender.pendingPrintOperations addObject:operation];

		[self addOperation:operation];
	});
}

#pragma mark -
#pragma mark cancelAllOperations Substitue

/* cancelOperationsForViewController should be called from the main queue. */
- (void)cancelOperationsForViewController:(TVCLogController *)controller
{
	/* Pause queue. */
	[self setSuspended:YES];

	/* Pending operations. */
	NSArray *pendingOperations = controller.pendingPrintOperations;

	NSObjectIsEmptyAssert(pendingOperations);

	/* Cancel all. */
	for (NSOperation *operation in pendingOperations) {
		[operation cancel];
	}

	/* Remove them. */
	[controller.pendingPrintOperations removeAllObjects];

	/* Resume queue. */
	[self setSuspended:NO];
}

- (void)destroyOperationsForChannel:(IRCChannel *)channel
{
	[self cancelOperationsForViewController:channel.viewController];
}

- (void)destroyOperationsForClient:(IRCClient *)client
{
	[self cancelOperationsForViewController:client.viewController];
}

#pragma mark -
#pragma mark State Changes

- (void)updateReadinessState:(TVCLogController *)controller
{
	dispatch_async(dispatch_get_main_queue(), ^{
		PointerIsEmptyAssert(controller);

		/* Pending operations. */
		NSArray *pendingOperations = controller.pendingPrintOperations;

		NSObjectIsEmptyAssert(pendingOperations);

		/* We only have to update the state of the top-most operation which will
		 be the oldest because once that finishes printing… the dependencies will
		 follow it. */
		TVCLogControllerOperationItem *topOp = pendingOperations[0];

		[topOp willChangeValueForKey:@"isReady"];
		[topOp didChangeValueForKey:@"isReady"];
	});
}

- (void)updateCompletionStatusForOperation:(TVCLogControllerOperationItem *)operation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		PointerIsEmptyAssert(operation);
		
		operation.isCompleted = YES;

		[operation willChangeValueForKey:@"isFinished"];
		[operation didChangeValueForKey:@"isFinished"];

		[operation.controller.pendingPrintOperations removeObject:operation];
	});
}

#pragma mark -
#pragma mark Dependency

- (NSOperation *)dependencyOfLastQueueItem:(TVCLogController *)controller
{
	/* This is called internally already from a method that is running on the
	 main queue so we will not wrap this in it. */
	
	PointerIsEmptyAssertReturn(controller, nil);

	/* Pending operations. */
	NSArray *pendingOperations = controller.pendingPrintOperations;

	NSObjectIsEmptyAssertReturn(pendingOperations, nil);

	/* The last object is the newest object pending. */
	return [pendingOperations lastObject];
}

@end

#pragma mark -
#pragma mark Operation Queue Items

@implementation TVCLogControllerOperationItem

- (id)initWithQueue:(TVCLogControllerOperationQueue *)queue controller:(TVCLogController *)controller
{
	if ((self = [super init])) {
		PointerIsEmptyAssertReturn(queue, nil);
		PointerIsEmptyAssertReturn(controller, nil);
		
		NSOperation *lastOp = [queue dependencyOfLastQueueItem:controller];

		if (lastOp) {
			/* Make this queue item dependent on the execution on the item above it to
			 make sure they are executed in the order they are received. */

			[self addDependency:lastOp];
		}

		self.controller = controller;

		return self;

	}

	return nil;
}

- (void)main
{
	self.executionBlock();
}

- (BOOL)isFinished
{
	return self.isCompleted;
}

- (BOOL)isReady
{
	if (self.dependencies.count < 1) {
		return ([self.controller.view isLoading] == NO && self.controller.isLoaded);
	} else {
		return [self.dependencies[0] isFinished];
	}
}

@end
