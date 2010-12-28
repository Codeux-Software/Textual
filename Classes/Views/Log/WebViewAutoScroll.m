// Created by Allan Odgaard.

@implementation WebViewAutoScroll

- (void)scrollViewToBottom:(NSView *)aView
{
	NSRect visibleRect = [aView visibleRect];
	visibleRect.origin.y = NSHeight([aView frame]) - NSHeight(visibleRect);
	[aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
	self.webFrame = nil;
	[super dealloc];
}

- (WebFrameView *)webFrame
{
	return webFrame;
}

- (void)setWebFrame:(WebFrameView *)aWebFrame
{
	if (aWebFrame == webFrame)
		return;
	
	webFrame = aWebFrame;
	
	if (webFrame) {
		[TXNSNotificationCenter() addObserver:self selector:@selector(webViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:nil];
		[TXNSNotificationCenter() addObserver:self selector:@selector(webViewDidChangeBounds:) name:NSViewBoundsDidChangeNotification object:nil];
		
		lastFrame = [[webFrame documentView] frame];
		lastVisibleRect = [[webFrame documentView] visibleRect];
	} else {
		[TXNSNotificationCenter() removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
		[TXNSNotificationCenter() removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
	}
}

- (void)webViewDidChangeBounds:(NSNotification *)aNotification
{
	NSClipView *clipView = [[[webFrame documentView] enclosingScrollView] contentView];
	if (clipView != [aNotification object])
		return;
	
	lastVisibleRect = [[clipView documentView] visibleRect];
}

- (void)webViewDidChangeFrame:(NSNotification *)aNotification
{
	NSView *view = [aNotification object];
	if (view != webFrame && view != [webFrame documentView])
		return;
	
	if (view == [webFrame documentView]) {
		if (NSMaxY(lastVisibleRect) >= NSMaxY(lastFrame)) {
			[self scrollViewToBottom:view];
			lastVisibleRect = [view visibleRect];
		}
		lastFrame = [view frame];
	}
	
	if (view == webFrame) {
		if (NSMaxY(lastVisibleRect) >= NSMaxY(lastFrame)) {
			[self scrollViewToBottom:[webFrame documentView]];
		}
	}
}

@end