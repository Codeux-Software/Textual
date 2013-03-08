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
		self.name = [NSString stringWithFormat:@"TVCLogControllerOperationQueue-%@", [NSString stringWithUUID]];

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
	[self addOperation:[TVCLogControllerOperationItem operationWithBlock:^{
		[sender handleMessageBlock:messageBlock withContext:context];
	} forController:sender withContext:context]];
}

#pragma mark -

- (void)updateReadinessState
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

	retval.completionBlock	= block;
	retval.queuePriority	= retval.priority;

    NSOperation *lastOp = nil;

	if (controller.channel && [TPCPreferences operationQueueIsChannelSpecific]) {
		lastOp = [controller.channel.operationQueue dependencyOfLastQueueItem];
	} else {
		lastOp = [controller.client.operationQueue dependencyOfLastQueueItem];
	}

    if (lastOp) {
        /* Make this queue item dependent on the execution on the item above it to
         make sure they are executed in the order they are received. */

        [retval addDependency:lastOp];
    }

	return retval;
}

- (NSOperationQueuePriority)priority
{
	id target = self.controller.channel;

	if (PointerIsEmpty(target)) {
		target = self.controller.client;
	}

	id selected = self.worldController.selectedItem;

	NSOperationQueuePriority retval = NSOperationQueuePriorityLow;

	if ((target || selected) && target == selected) {
		retval = NSOperationQueuePriorityNormal;
	}

	if (NSObjectIsNotEmpty(self.context) && self.context[@"highPriority"]) {
		retval += 4L;
	}

	if (NSObjectIsNotEmpty(self.context) && self.context[@"isHistoric"]) {
		retval += 4L;
	}

	return retval;
}

- (BOOL)isReady
{
	if (self.controller.reloadingHistory) {
		BOOL isHistoric = (NSObjectIsNotEmpty(self.context) && self.context[@"isHistoric"]);

		if (isHistoric) {
			return ([self.controller.view isLoading] == NO);
		}
	} else {
		return ([self.controller.view isLoading] == NO);
	}
    
	return NO;
}

@end
