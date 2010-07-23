#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WebViewAutoScroll : NSObject
{
	WebFrameView* webFrame;
	NSRect lastFrame, lastVisibleRect;
}

@property (assign, setter=setWebFrame:, getter=webFrame) WebFrameView* webFrame;
@end