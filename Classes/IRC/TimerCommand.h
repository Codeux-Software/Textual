#import <Foundation/Foundation.h>

@interface TimerCommand : NSObject
{
	CFAbsoluteTime time;
	NSInteger cid;
	NSString* input;
}

@property (assign) CFAbsoluteTime time;
@property (assign) NSInteger cid;
@property (copy) NSString* input;
@end