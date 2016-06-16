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

NS_ASSUME_NONNULL_BEGIN

#warning TODO: Set _compileDebugCode to 0 before version 6.0.0 is complete

#define _compileDebugCode			1

#pragma mark -
#pragma mark Define Private Header

@interface TVCLogControllerOperationItem : NSOperation
@property (nonatomic, copy, nullable) TVCLogControllerOperationBlock executionBlock;
@property (nonatomic, weak, nullable) TVCLogController *viewController;
@property (nonatomic, assign) BOOL isStandalone;

#if _compileDebugCode == 1
@property (nonatomic, copy, nullable) NSString *operationDescription;
#endif

@property (readonly) NSUInteger dependencyCount;
@end

#pragma mark -
#pragma mark Operation Queue

@implementation TVCLogControllerOperationQueue

- (instancetype)init
{
	if ((self = [super init])) {
		self.maxConcurrentOperationCount = 6;
		
		self.name = @"TVCLogControllerOperationQueue";

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark Queue Additions

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)viewController
{
	[self enqueueMessageBlock:callbackBlock for:viewController description:nil isStandalone:NO];
}

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)viewController description:(nullable NSString *)description
{
	[self enqueueMessageBlock:callbackBlock for:viewController description:description isStandalone:NO];
}

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)viewController description:(nullable NSString *)description isStandalone:(BOOL)isStandalone
{
	NSParameterAssert(callbackBlock != nil);
	NSParameterAssert(viewController != nil);

	[self performBlockOnMainThread:^{
		/* Create operation */
		TVCLogControllerOperationItem *operation = [TVCLogControllerOperationItem new];

		TVCLogControllerOperationItem *lastOperation = (id)[self dependencyOfLastOperation:viewController];

		if (lastOperation) {
			[operation addDependency:lastOperation];
		}

#if _compileDebugCode == 1
		if (description) {
			operation.operationDescription = description;
		} else {
			operation.operationDescription = @"No Description";
		}
#endif

		operation.executionBlock = callbackBlock;

		operation.isStandalone = isStandalone;

		operation.viewController = viewController;

		/* Add the operations */
		[self addOperation:operation];
	}];
}

#pragma mark -
#pragma mark cancelAllOperations Substitue

/* cancelOperationsForViewController should be called from the main queue. */
- (void)cancelOperationsForViewController:(TVCLogController *)viewController
{
	NSParameterAssert(viewController != nil);

	for (TVCLogControllerOperationItem *operation in self.operations) {
		if (operation.viewController != viewController) {
			continue;
		}

		[operation cancel];
	}
}

- (void)cancelOperationsForClient:(IRCClient *)client
{
	[self cancelOperationsForViewController:client.viewController];
}

- (void)cancelOperationsForChannel:(IRCChannel *)channel
{
	[self cancelOperationsForViewController:channel.viewController];
}

#pragma mark -
#pragma mark State Changes

- (void)updateReadinessState:(TVCLogController *)viewController
{
	NSParameterAssert(viewController != nil);

	[self performBlockOnMainThread:^{
		/* Mark all objects part of this controller
		 that are not cancelled and have no dependencies
		 as ready or maybe is ready. */
		for (TVCLogControllerOperationItem *operation in self.operations) {
			if (operation.viewController != viewController) {
				continue;
			}

			if (operation.isCancelled) {
				continue;
			}

			if (operation.dependencyCount > 0) {
				continue;
			}

			[operation willChangeValueForKey:@"isReady"];
			[operation didChangeValueForKey:@"isReady"];
		}
	}];
}

#pragma mark -
#pragma mark Dependency

- (nullable NSOperation *)dependencyOfLastOperation:(TVCLogController *)viewController
{
	/* This is called internally already from a method that is 
	 running on the main queue so we will not wrap this in it. */
	NSEnumerator *operationEnumerator = self.operations.reverseObjectEnumerator;

	for (TVCLogControllerOperationItem *operation in operationEnumerator) {
		if (operation.viewController != viewController) {
			continue;
		}

		if (operation.isCancelled || operation.isStandalone) {
			continue;
		}

		return operation;
	}

	return nil;
}

@end

#pragma mark -
#pragma mark Operation Queue Items

@implementation TVCLogControllerOperationItem

- (NSUInteger)dependencyCount
{
	return self.dependencies.count;
}

- (void)cancel
{
	[super cancel];

	[self teardownOperation];
}

- (void)main
{
	[self executeBlock];

	[self teardownOperation];
}

- (void)executeBlock
{
	if (self.isCancelled) {
		return;
	}

	TVCLogControllerOperationBlock executionBlock = self.executionBlock;

#if _compileDebugCode == 1
	if (executionBlock == nil) {
		NSMutableString *exceptionMessage = [NSMutableString string];

		[exceptionMessage appendString:@"\n\nExecution block is nil when it probably shouldn't be.\n"];

		[exceptionMessage appendFormat:@"\tOperation: %@\n", self.description];
		[exceptionMessage appendFormat:@"\tisCancelled: %d\n", self.isCancelled];
		[exceptionMessage appendFormat:@"\tisExecuting: %d\n", self.isExecuting];
		[exceptionMessage appendFormat:@"\tisFinished: %d\n", self.isFinished];
		[exceptionMessage appendFormat:@"\tisReady: %d\n", super.isReady];
		[exceptionMessage appendFormat:@"\tDescription: '%@'\n\n", self.operationDescription];

		NSAssert(NO, exceptionMessage);
	}
#endif

	executionBlock(self);
}

- (void)teardownOperation
{
	/* Dereference everything associated with this operation */
	self.executionBlock = nil;

	self.viewController = nil;

	/* Kill existing dependency */
	/* Discussion: Normally NSOperationQueue removes all strong references to
	 dependencies once all operations have completed. As this operation queue
	 can have thousands of operations chained together, this is not a desired
	 behavior as a pseudo infinite loop can be created. Therefore, once we
	 have executed the block we wanted, we release any dependency assigned. */
	NSOperation *firstDependency = self.dependencies.firstObject;

	if (firstDependency) {
		[self removeDependency:firstDependency];
	}
}

- (BOOL)isReady
{
	if (self.dependencyCount < 1 || self.isStandalone) {
		return (super.isReady && self.viewController.isLoaded);
	} else {
		return  super.isReady;
	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"isReady"]) {
		return YES;
	}

	return [super automaticallyNotifiesObserversForKey:key];
}

@end

NS_ASSUME_NONNULL_END
