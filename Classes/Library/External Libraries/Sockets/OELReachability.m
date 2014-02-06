/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "OELReachability.h"

@interface OELReachability ()
@property (nonatomic, strong) id reachabilityObject;
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, assign) dispatch_queue_t reachabilitySerialQueue;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;
@end

static void TMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    OELReachability *reachability = ((__bridge OELReachability *)info);

    @autoreleasepool {
        [reachability reachabilityChanged:flags];
    }
}

@implementation OELReachability

+ (OELReachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);

	if (ref) {
        return [[self alloc] initWithReachabilityRef:ref];
    }

    return nil;
}

+ (OELReachability *)reachabilityForInternetConnection
{
    struct sockaddr_in zeroAddress;

    bzero(&zeroAddress, sizeof(zeroAddress));

    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    return [self reachabilityWithAddress:&zeroAddress];
}

- (OELReachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref
{
    if (self = [super init])
    {
        self.reachabilityRef = ref;
    }

    return self;
}

- (void)dealloc
{
    [self stopNotifier];

    if (self.reachabilityRef)
    {
        CFRelease(self.reachabilityRef);
				  self.reachabilityRef = nil;
    }

	self.reachableBlock		= nil;
	self.unreachableBlock	= nil;
}

- (BOOL)startNotifier
{
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };

    self.reachabilityObject = self;

    self.reachabilitySerialQueue = dispatch_queue_create("com.tonymillion.reachability", NULL);

	if (self.reachabilitySerialQueue == nil) {
        return NO;
    }

    context.info = (__bridge void *)self;

    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, TMReachabilityCallback, &context) == FALSE) {
        if (self.reachabilitySerialQueue) {
            dispatch_release(self.reachabilitySerialQueue);
						     self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    if (SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue) == FALSE) {
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

        if (self.reachabilitySerialQueue) {
            dispatch_release(self.reachabilitySerialQueue);
							 self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    return YES;
}

- (void)stopNotifier
{
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);

    if (self.reachabilitySerialQueue)
    {
		dispatch_release(self.reachabilitySerialQueue);
						 self.reachabilitySerialQueue = nil;
    }

    self.reachabilityObject = nil;
}

#define testcase (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL connectionUP = YES;

    if ((flags & kSCNetworkReachabilityFlagsReachable) == NO) {
        connectionUP = NO;
	}

	if ((flags & testcase) == testcase) {
		connectionUP = NO;
	}
	
    return connectionUP;
}

- (BOOL)isReachable
{
    SCNetworkReachabilityFlags flags;

    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) == FALSE) {
        return NO;
	}

    return [self isReachableWithFlags:flags];
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if ([self isReachableWithFlags:flags]) {
        if (self.reachableBlock) {
            self.reachableBlock(self);
        }
    } else {
        if (self.unreachableBlock) {
            self.unreachableBlock(self);
        }
    }
}

@end
