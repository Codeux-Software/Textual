// Created by Allan Odgaard.
// Converted to ARC Support on Thursday, June 07, 2012

@implementation TVCWebViewAutoScroll

@synthesize lastVisibleRect;
@synthesize lastFrame;
@synthesize webFrame;

- (void)scrollViewToBottom:(NSView *)aView
{
	NSRect visibleRect = [aView visibleRect];
	
	visibleRect.origin.y = (NSHeight([aView frame]) - NSHeight(visibleRect));
	
	[aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
	self.webFrame = nil;
}

- (void)setWebFrame:(WebFrameView *)aWebFrame
{
	if (aWebFrame == self.webFrame) {
		return;
	}
	
	webFrame = aWebFrame;
	
	if (self.webFrame) {
		[_NSNotificationCenter() addObserver:self selector:@selector(webViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:nil];
		[_NSNotificationCenter() addObserver:self selector:@selector(webViewDidChangeBounds:) name:NSViewBoundsDidChangeNotification object:nil];
		
		self.lastFrame		 = [[self.webFrame documentView] frame];
		self.lastVisibleRect = [[self.webFrame documentView] visibleRect];
	} else {
		[_NSNotificationCenter() removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
		[_NSNotificationCenter() removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
	}
}

- (void)webViewDidChangeBounds:(NSNotification *)aNotification
{
	NSClipView *clipView = [[[self.webFrame documentView] enclosingScrollView] contentView];
	
	if (NSDissimilarObjects(clipView, [aNotification object])) {
		return;
	}
	
	self.lastVisibleRect = [[clipView documentView] visibleRect];
}

- (void)webViewDidChangeFrame:(NSNotification *)aNotification
{
	NSView *view = [aNotification object];
	
	if (NSDissimilarObjects(view, self.webFrame) && NSDissimilarObjects(view, [self.webFrame documentView])) {
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