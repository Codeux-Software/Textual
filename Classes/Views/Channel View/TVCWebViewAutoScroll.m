// Created by Allan Odgaard.

#import "TextualApplication.h"

@implementation TVCWebViewAutoScroll

- (void)scrollViewToBottom:(NSView *)aView
{
	NSRect visibleRect = [aView visibleRect];
	
	visibleRect.origin.y = (NSHeight([aView frame]) - NSHeight(visibleRect));
	
	[aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
	[self setWebFrame:nil];
}

- (void)setWebFrame:(WebFrameView *)aWebFrame
{
	if (aWebFrame == self.webFrame) {
		return;
	}
	
	_webFrame = aWebFrame;
	
	if (self.webFrame) {
		[RZNotificationCenter() addObserver:self selector:@selector(webViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:nil];
		[RZNotificationCenter() addObserver:self selector:@selector(webViewDidChangeBounds:) name:NSViewBoundsDidChangeNotification object:nil];
		
		self.lastFrame		 = [[self.webFrame documentView] frame];
		self.lastVisibleRect = [[self.webFrame documentView] visibleRect];
	} else {
		[RZNotificationCenter() removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
		[RZNotificationCenter() removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
	}
}

- (BOOL)canScroll
{
	NSRect frameRect = [self.webFrame frame];

	NSRect contentRect = [[self.webFrame documentView] frame];

	return (contentRect.size.height > frameRect.size.height);
}

- (void)forceFrameRedraw
{
	/* WebKit uses layered compositing for position: fixed elements as of Yosemite.
	 However, there are some issues related to this change which results in position
	 fixed elements flickering while scrolling. This has been filed as radar #18211024
	 but in the meantime, we redraw the WebView on scroll to workaround this issue. */
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		[[self.webFrame documentView] setNeedsDisplay:YES];
	}
}

- (void)webViewDidChangeBounds:(NSNotification *)aNotification
{
	/* Update last visible rect for notification. */
	NSClipView *clipView = [[[self.webFrame documentView] enclosingScrollView] contentView];
	
	if (NSDissimilarObjects(clipView, [aNotification object])) {
		return;
	}
	
	self.lastVisibleRect = [clipView.documentView visibleRect];

	[self forceFrameRedraw];
}

- (void)webViewDidChangeFrame:(NSNotification *)aNotification
{
	NSView *view = [aNotification object];
	
	if (NSDissimilarObjects(view,  self.webFrame) &&
		NSDissimilarObjects(view, [self.webFrame documentView]))
	{
		return;
	}
	
	if (view == [self.webFrame documentView]) {
		if (NSMaxY(self.lastVisibleRect) >= NSMaxY(self.lastFrame)) {
			[self scrollViewToBottom:view];
			
			self.lastVisibleRect = [view visibleRect];
		}
		
		self.lastFrame = [view frame];
	}
	
	if (view == self.webFrame) {
		if (NSMaxY(self.lastVisibleRect) >= NSMaxY(self.lastFrame)) {
			[self scrollViewToBottom:[self.webFrame documentView]];
		}
	}
}

@end
