#import "NSObject+DDExtensions.h"
#import "DDInvocationGrabber.h"

@implementation NSObject (DDExtensions)

- (id)invokeOnMainThread;
{
    return [self invokeOnMainThreadAndWaitUntilDone:NO];
}

- (id)invokeOnMainThreadAndWaitUntilDone:(BOOL)waitUntilDone;
{
    DDInvocationGrabber * grabber = [DDInvocationGrabber invocationGrabber];
    [grabber setForwardInvokesOnMainThread:YES];
    [grabber setWaitUntilDone:waitUntilDone];
    return [grabber prepareWithInvocationTarget:self];
}

@end