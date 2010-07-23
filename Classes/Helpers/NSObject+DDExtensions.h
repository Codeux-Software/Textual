#import <Foundation/Foundation.h>

@interface NSObject (DDExtensions)
- (id)invokeOnMainThread;
- (id)invokeOnMainThreadAndWaitUntilDone:(BOOL)waitUntilDone;
@end

#define ddsynthesize(_X_) @synthesize _X_ = _##_X_