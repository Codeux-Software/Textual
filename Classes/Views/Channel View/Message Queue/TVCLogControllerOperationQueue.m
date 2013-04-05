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

#pragma mark -
#pragma mark Define Private Header

@interface TVCLogControllerOperationItem : NSOperation
@property (nonatomic, nweak) TVCLogController *controller;
@property (nonatomic, strong) void (^executionBlock)(void);

+ (TVCLogControllerOperationItem *)operationWithBlock:(void(^)(void))block forController:(TVCLogController *)controller;
@end

@interface TVCLogControllerOperationQueue ()
@property (strong) NSDictionary *cachedOperations;
@end

#pragma mark -
#pragma mark Operation Queue

@implementation TVCLogControllerOperationQueue

- (id)init
{
	if ((self = [super init])) {
		/* Cached blocks never actually hit the queue. They are used primarily for style reloads and such where
		 hundreds of messages will be rendered at the same time. Instead of inserting each block to process as
		 an individual queue item, we instead ask for the block that already contains the HTML result and append
		 that to our cached operations array. The array can then be processed to create a single, large HTML
		 block to append to WebKit at the same time instead of processing each message one-by-one.

		 Cached operations are stored an array in the format: @[<callbackBlock>, <context>] — their key is a 
		 unique identifier assigned to each view controller.
		 
		 These operations are never executed within this class. They are only cached here. */
		
		_cachedOperations = [NSMutableDictionary dictionary];

		/* Limit our queue to four threads per client. Our queue is actually client specific not view specific,
		 it is only designed into the view controller because that is where it is used. */
		//self.maxConcurrentOperationCount = 4;
		self.maxConcurrentOperationCount = 1; // Temporary.

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark Queue Additions

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender
{
	[self enqueueMessageBlock:callbackBlock for:sender context:nil];
}

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender context:(NSDictionary *)context
{
	PointerIsEmptyAssert(callbackBlock);
	PointerIsEmptyAssert(sender);

	TVCLogControllerOperationItem *operation = [TVCLogControllerOperationItem operationWithBlock:^{
		callbackBlock(context);
	} forController:sender];

	[self addOperation:operation];
}

#pragma mark -
#pragma mark cancelAllOperations Substitue

- (void)cancelOperationsForViewController:(TVCLogController *)controller
{
	PointerIsEmptyAssert(controller);
	
	/* Controller key. */
	NSString *controllerKey = [controller operationQueueHash];

	/* Pending operations. */
	NSArray *pendingOperations = [self operations];

	/* Cancel the operations. */
	for (TVCLogControllerOperationItem *op in pendingOperations) {
		NSString *ophash = op.controller.operationQueueHash;

		if ([controllerKey isEqualToString:ophash]) {
			[op cancel];
		}
	}
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
#pragma mark Cached Operations

- (void)enqueueMessageCachedBlock:(TVCLogMessageBlock)callbackBlock for:(TVCLogController *)sender context:(NSDictionary *)context
{
	PointerIsEmptyAssert(callbackBlock);
	PointerIsEmptyAssert(sender);
	PointerIsEmptyAssert(context); // context != nil

	/* Controller key. */
	NSString *controllerKey = [sender operationQueueHash];

	/* Get list of pending operations. */
	NSArray *pendingOperations = [self.cachedOperations arrayForKey:controllerKey];

	/* Are there any? */
	if (pendingOperations == nil) {
		pendingOperations = [NSArray array];
	}

	/* Prepare array for changes. */
	NSMutableArray *mutableOperations = [pendingOperations mutableCopy];

	/* Add operation to dictionary. */
	[mutableOperations addObject:@[callbackBlock, context]];

	/* Save array. */
	NSMutableDictionary *mutops = [self.cachedOperations mutableCopy];
	
	[mutops setObject:mutableOperations forKey:controllerKey];

	self.cachedOperations = nil;
	self.cachedOperations = mutops;
}

- (NSArray *)cachedOperationsFor:(TVCLogController *)controller
{
	PointerIsEmptyAssertReturn(controller, nil);

	/* Controller key. */
	NSString *controllerKey = [controller operationQueueHash];

	/* Return cache. */
	return [self.cachedOperations arrayForKey:controllerKey];
}

- (void)destroyCachedOperationsFor:(TVCLogController *)controller
{
	PointerIsEmptyAssert(controller);
	
	/* Controller key. */
	NSString *controllerKey = [controller operationQueueHash];

	/* Destroy cache. */
	NSMutableDictionary *mutops = [self.cachedOperations mutableCopy];

	[mutops removeObjectForKey:controllerKey];

	self.cachedOperations = nil;
	self.cachedOperations = mutops;
}

#pragma mark -
#pragma mark State Changes

- (void)updateReadinessState:(TVCLogController *)controller
{
	PointerIsEmptyAssert(controller);

	/* Controller key. */
	NSString *controllerKey = [controller operationQueueHash];

	/* We only need to update the first object in our queue beause 
	 that object is dependent on WebKit. All other queue items are
	 dependent on that first object. If it is gone, then it means 
	 WebKit is ready to process all of them. */

	/* Pending operations. */
	NSArray *pendingOperations = self.operations;

	/* Cancel the operations. */
	for (TVCLogControllerOperationItem *op in pendingOperations) {
		NSString *ophash = op.controller.operationQueueHash;

		if ([controllerKey isEqualToString:ophash]) {
			[op willChangeValueForKey:@"isReady"];
			[op didChangeValueForKey:@"isReady"];

			return;
		}
	}
}

#pragma mark -
#pragma mark Dependency

- (NSOperation *)dependencyOfLastQueueItem:(TVCLogController *)controller
{
	PointerIsEmptyAssertReturn(controller, nil);

	/* Controller key. */
	NSString *controllerKey = [controller operationQueueHash];

	/* Pending operations. */
	NSArray *pendingOperations = self.operations.reverseObjectEnumerator.allObjects;

	/* Cancel the operations. */
	for (TVCLogControllerOperationItem *op in pendingOperations) {
		NSString *ophash = op.controller.operationQueueHash;

		if ([controllerKey isEqualToString:ophash]) {
			return op;
		}
	}

	return nil;
}

@end

#pragma mark -
#pragma mark Operation Queue Items

@implementation TVCLogControllerOperationItem

+ (TVCLogControllerOperationItem *)operationWithBlock:(void(^)(void))block forController:(TVCLogController *)controller;
{
	PointerIsEmptyAssertReturn(block, nil);
	PointerIsEmptyAssertReturn(controller, nil);

    TVCLogControllerOperationItem *retval = [TVCLogControllerOperationItem new];

	retval.controller = controller;
	retval.executionBlock = block;

    NSOperation *lastOp = [controller.operationQueue dependencyOfLastQueueItem:controller];

    if (lastOp) {
        /* Make this queue item dependent on the execution on the item above it to
         make sure they are executed in the order they are received. */

        [retval addDependency:lastOp];
    }

	return retval;
}

- (void)main
{
	self.executionBlock();
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
