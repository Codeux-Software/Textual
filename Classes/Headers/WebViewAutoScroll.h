// Created by Allan Odgaard.

@interface WebViewAutoScroll : NSObject
{
	WebFrameView *webFrame;
	
	NSRect lastFrame;
	NSRect lastVisibleRect;
}

@property (nonatomic, assign, setter=setWebFrame:, getter=webFrame) WebFrameView *webFrame;
@end