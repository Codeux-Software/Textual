#import <Cocoa/Cocoa.h>

@interface HostResolver : NSObject
{
	id delegate;
}

@property (assign) id delegate;

- (id)initWithDelegate:(id)aDelegate;
- (void)resolve:(NSString*)hostname;
@end

@interface NSObject (HostResolverDelegate)
- (void)hostResolver:(HostResolver*)sender didResolve:(NSHost*)host;
- (void)hostResolver:(HostResolver*)sender didNotResolve:(NSString*)hostname;
@end