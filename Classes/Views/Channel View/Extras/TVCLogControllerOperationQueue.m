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

#pragma mark -
#pragma mark Define Private Header

@interface TVCLogControllerOperationItem : NSOperation
@property (nonatomic, nweak) TVCLogController *controller;
@property (nonatomic, strong) TVCLogControllerOperationBlock executionBlock;

- (id)initWithQueue:(TVCLogControllerOperationQueue *)queue controller:(TVCLogController *)controller;
@end

#pragma mark -
#pragma mark Operation Queue

@implementation TVCLogControllerOperationQueue

- (id)init
{
	if (self = [super init]) {
		[self setName:@"TVCLogControllerOperationQueue"];

		return self;
	}

	return nil;
}

#pragma mark -
#pragma mark Queue Additions

- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		PointerIsEmptyAssert(callbackBlock);
		PointerIsEmptyAssert(sender);

		TVCLogControllerOperationItem *operation = [[TVCLogControllerOperationItem alloc] initWithQueue:self controller:sender];

		[operation setExecutionBlock:callbackBlock];

		/* Add the operations. */
		[self addOperation:operation];
	});
}

#pragma mark -
#pragma mark cancelAllOperations Substitue

/* cancelOperationsForViewController should be called from the main queue. */
- (void)cancelOperationsForViewController:(TVCLogController *)controller
{
	/* Cancel all. */
	for (id operation in [self operations]) {
		if ([operation controller] == controller) {
			[operation cancel];
		}
	}
}

- (void)destroyOperationsForChannel:(IRCChannel *)channel
{
	[self cancelOperationsForViewController:[channel viewController]];
}

- (void)destroyOperationsForClient:(IRCClient *)client
{
	[self cancelOperationsForViewController:[client viewController]];
}

#pragma mark -
#pragma mark State Changes

- (void)updateReadinessState:(TVCLogController *)controller
{
	dispatch_async(dispatch_get_main_queue(), ^{
		PointerIsEmptyAssert(controller);

		for (id operation in [self operations]) {
			if ([operation controller] == controller) {
				if ([operation isCancelled] == NO) {
					[operation willChangeValueForKey:@"isReady"];
					[operation didChangeValueForKey:@"isReady"];

					break; // Only update oldest operation matching controller.
				}
			}
		}
	});
}

#pragma mark -
#pragma mark Dependency

- (NSOperation *)dependencyOfLastQueueItem:(TVCLogController *)controller
{
	/* This is called internally already from a method that is running on the
	 main queue so we will not wrap this in it. */
	for (id operation in [[self operations] reverseObjectEnumerator]) {
		if ([operation controller] == controller) {
			if ([operation isCancelled] == NO) {
				return operation;
			}
		}
	}

	return nil;
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

		[self setController:controller];

		return self;
	}

	return nil;
}

- (void)main
{
	self.executionBlock(self);
}

- (BOOL)isReady
{
	if ([[self dependencies] count] < 1) {
		return ([super isReady] && [[self controller] isLoaded]);
	} else {
		return [super isReady];
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
