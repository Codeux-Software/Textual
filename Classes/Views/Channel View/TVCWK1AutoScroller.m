/* *********************************************************************
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

@interface TVCWK1AutoScroller ()
@property (nonatomic, assign) NSRect lastFrame;
@property (nonatomic, assign) NSRect lastVisibleRect;
@property (nonatomic, weak) WebFrameView *frameView;
@property (nonatomic, assign) BOOL wasViewingBottom;
@end

@implementation TVCWK1AutoScroller

- (instancetype)initWitFrameView:(WebFrameView *)frameView;
{
	NSParameterAssert(frameView != nil);

	if ((self = [super init])) {
		self.frameView = frameView;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[RZNotificationCenter() addObserver:self
							   selector:@selector(webViewDidChangeFrame:)
								   name:NSViewFrameDidChangeNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(webViewDidChangeBounds:)
								   name:NSViewBoundsDidChangeNotification
								 object:nil];

	self.lastFrame = self.frameView.documentView.frame;

	self.lastVisibleRect = self.frameView.documentView.visibleRect;

	self.wasViewingBottom = YES;
}

- (BOOL)viewingBottom
{
	/* 25 points (pixels) is the maximum offset the user can be scrolled
	 upward before we are no longer considered to be at the bottom.
	 An offset is used to compensate for small changes to scrolling
	 related to sensitivity of the TrackPad device. */
	/* If this offset is changed, then update autoScroll.js too, so that
	 WebKit2 uses the same offset for its scroller. */
	if (NSMaxY(self.lastVisibleRect) >= (NSMaxY(self.lastFrame) - 25.0)) {
		return YES;
	}

	return NO;
}

- (void)saveScrollerPosition
{
	self.wasViewingBottom = self.viewingBottom;
}

- (void)restoreScrollerPosition
{
	if (self.wasViewingBottom == NO) {
		return;
	}

	NSView *documentView = self.frameView.documentView;

	[self scrollViewToBottom:documentView];
}

- (void)scrollViewToBottom:(NSView *)aView
{
	NSRect visibleRect = aView.visibleRect;

	visibleRect.origin.y = (aView.frame.size.height - visibleRect.size.height);
	
	[aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
	[RZNotificationCenter() removeObserver:self];

	self.frameView = nil;
}

- (BOOL)canScroll
{
	NSRect frameRect = self.frameView.frame;

	NSRect contentRect = self.frameView.documentView.frame;

	return (contentRect.size.height > frameRect.size.height);
}

- (void)redrawFrameIfNeeded
{
	/* WebKit uses layered compositing for position: fixed elements as of Yosemite.
	 However, there are some issues related to this change which results in position
	 fixed elements flickering while scrolling. This has been filed as radar #18211024
	 but in the meantime, we redraw the WebView on scroll to workaround this issue. */
	static BOOL _performForceRedraw = NO;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		_performForceRedraw =
		([XRSystemInformation isUsingOSXYosemiteOrLater] &&
		 [XRSystemInformation isUsingOSXElCapitanOrLater] == NO);
	});

	if (_performForceRedraw == NO) {
		return;
	}

	[self redrawFrame];
}

- (void)redrawFrame
{
	[self.frameView.documentView setNeedsLayout:YES];
}

- (void)webViewDidChangeBounds:(NSNotification *)aNotification
{
	NSClipView *clipView = self.frameView.documentView.enclosingScrollView.contentView;

	if (clipView != aNotification.object) {
		return;
	}

	self.lastVisibleRect = clipView.documentView.visibleRect;

	[self redrawFrameIfNeeded];
}

- (void)webViewDidChangeFrame:(NSNotification *)aNotification
{
	NSView *aView = aNotification.object;

	WebFrameView *frameView = self.frameView;

	NSView *documentView = frameView.documentView;

	if (aView == frameView)
	{
		if (self.viewingBottom) {
			[self scrollViewToBottom:aView];
		}
	}
	else if (aView == documentView)
	{
		if (self.viewingBottom) {
			[self scrollViewToBottom:aView];

			self.lastVisibleRect = aView.visibleRect;
		}

		self.lastFrame = aView.frame;
	}
}

@end

NS_ASSUME_NONNULL_END
