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
@property (nonatomic, strong) NSDictionary *context;
@property (nonatomic, nweak) TVCLogController *controller;

+ (TVCLogControllerOperationItem *)operationWithBlock:(void(^)(void))block
                                        forController:(TVCLogController *)controller
                                          withContext:(NSDictionary *)context;
@end

#pragma mark -
#pragma mark Operation Queue

@implementation TVCLogControllerOperationQueue

- (id)init
{
	if ((self = [super init])) {
		self.maxConcurrentOperationCount = 1;

		/* cachedOperations are primarly used by application start message playback
		 and style reloads. Instead of adding a new operation for thousands of lines
		 used by these two actions, we will add the actual blocks to our cache array
		 and then only add one operation to the operation queue.
		 
		 When this operation is called, it has a context that tells the recieving
		 method that our cachedOperations array should be flushed. The cached 
		 operations array is never called during normal prints that may occur
		 during the above mentioned actions. 
		 
		 As long as new operations added use the operation that calls our cached
		 operations array as a dependant, the others should execute in order because
		 they will have to wait until this is finished. 
		 
		 Each cache entry is an array with the format: Index 0 = messageBlock; 
		 Index 1 = the controller, Index 2 = the context. */
		
		_cachedOperations = [NSMutableArray array];

		return self;
	}

	return nil;
}

- (void)enqueueMessageBlock:(id)messageBlock fromSender:(TVCLogController *)sender
{
    [self enqueueMessageBlock:messageBlock fromSender:sender withContext:nil];
}

- (void)enqueueMessageBlock:(id)messageBlock fromSender:(TVCLogController *)sender withContext:(NSDictionary *)context
{
	/* Ask our context whether this item should be inserted into our cache instead of the queue. */
	if (context && [context[@"cacheOperation"] boolValue] == YES) {
		[self.cachedOperations addObject:@[messageBlock, sender, context]];

		return;
	}

	/* It wants in the queue. Create operation and insert. */
	[self addOperation:[TVCLogControllerOperationItem operationWithBlock:^{
		[sender handleMessageBlock:messageBlock withContext:context];
	} forController:sender withContext:context]];
}

#pragma mark -

- (void)destroyCachedOperationsFor:(TVCLogController *)controller
{
	NSArray *cacheCopy = [self.cachedOperations copy];

	for (NSArray *cacheItem in cacheCopy) {
		NSAssertReturnLoopContinue(cacheItem.count == 3);

		TVCLogController *cont = cacheItem[1];

		if (cont == controller) {
			[self.cachedOperations removeObject:cacheItem];
		}
	}
}

- (void)cancelOperationsForViewController:(TVCLogController *)controller
{
	PointerIsEmptyAssert(controller);
	
	NSArray *queues = [self operations];

	for (TVCLogControllerOperationItem *op in queues) {
		if (op.controller == controller) {
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

- (void)updateReadinessState:(TVCLogController *)controller
{
	NSArray *queues = [self operations];

	for (TVCLogControllerOperationItem *op in queues) {
        [op willChangeValueForKey:@"isReady"];
        [op didChangeValueForKey:@"isReady"];
	}
}

- (NSOperation *)dependencyOfLastQueueItem
{
    NSArray *items = [self operations];

    NSObjectIsEmptyAssertReturn(items, nil);

    return [items lastObject];
}

@end

#pragma mark -
#pragma mark Operation Queue Items

@implementation TVCLogControllerOperationItem

+ (TVCLogControllerOperationItem *)operationWithBlock:(void(^)(void))block
                                        forController:(TVCLogController *)controller
                                          withContext:(NSDictionary *)context
{
	PointerIsEmptyAssertReturn(block, nil);
	PointerIsEmptyAssertReturn(controller, nil);

    TVCLogControllerOperationItem *retval = [TVCLogControllerOperationItem new];

	retval.controller		= controller;
	retval.context			= context;

	retval.queuePriority	= NSOperationQueuePriorityNormal;
	retval.completionBlock	= block;

    NSOperation *lastOp = [controller.operationQueue dependencyOfLastQueueItem];

    if (lastOp) {
        /* Make this queue item dependent on the execution on the item above it to
         make sure they are executed in the order they are received. */

        [retval addDependency:lastOp];
    }

	return retval;
}

- (BOOL)isReady
{
	return ([self.controller.view isLoading] == NO);
}

@end
