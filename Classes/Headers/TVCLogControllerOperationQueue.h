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

/* No plugins should be accessing this. */
@class TVCLogControllerOperationItem;

typedef void (^TVCLogControllerOperationBlock)(NSOperation *sender, NSDictionary *context);

@interface TVCLogControllerOperationQueue : NSOperationQueue
/* Add new operations. */
- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender;
- (void)enqueueMessageBlock:(TVCLogControllerOperationBlock)callbackBlock for:(TVCLogController *)sender context:(NSDictionary *)context;

/* Limit scope of cancelAllOperations. */
- (void)destroyOperationsForChannel:(IRCChannel *)channel;
- (void)destroyOperationsForClient:(IRCClient *)client;

- (void)cancelOperationsForViewController:(TVCLogController *)controller;

/* Update state. */
- (void)updateReadinessState:(TVCLogController *)controller;

/* The block being executed is not declared finished until it actually tells the queue
 that it is done. The design behind this idea is deep. WebKit requires us to append on 
 the main thread but the blocks draw in the background. Once drawing is complete, we 
 execute the rest of the work on the main thread, but that work is not always instant.
 
 By calilng this on the main thread after the work has completed instead of relying on
 the default implementation of isFinish we are making sure our queue can be concurrent
 but also keep stuff in sync. */
- (void)updateCompletionStatusForOperation:(TVCLogControllerOperationItem *)operation;
@end
