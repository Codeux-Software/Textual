#import <Cocoa/Cocoa.h>
#import <HIToolbox/Events.h>

@class LogController;

@class LogPolicy;

@interface LogScriptEventSink : NSObject
{
	LogController* owner;
	LogPolicy* policy;
	
	NSInteger x;
	NSInteger y;
	CFAbsoluteTime lastClickTime;
}

@property (assign) id owner;
@property (retain) id policy;
@property NSInteger x;
@property NSInteger y;
@property CFAbsoluteTime lastClickTime;
@end