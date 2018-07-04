/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TVCWK1AutoScrollerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCWK1AutoScroller ()
{
	CGFloat _scrollHeightCurrentValue;
	CGFloat _scrollHeightPreviousValue;
	CGFloat _scrollPositionCurrentValue;
	CGFloat _scrollPositionPreviousValue;
	BOOL _userScrolled;
	BOOL _scrolledUpwards;
	BOOL _restoreScrollerPosition;
/*	NSRect _lastFrame; */
}

@property (nonatomic, weak) WebFrameView *frameView;
@property (readonly) NSView *documentView;
@end

@implementation TVCWK1AutoScroller

/* Maximum distance user can scroll up before automatic scrolling is disabled. */
static CGFloat _userScrolledMinimum = 25.0;

- (instancetype)initWitFrameView:(WebFrameView *)frameView
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
	WebFrameView *frameView = self.frameView;

	NSView *documentView = frameView.documentView;

	[RZNotificationCenter() addObserver:self
							   selector:@selector(webViewDidChangeFrame:)
								   name:NSViewFrameDidChangeNotification
								 object:frameView];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(webViewDidChangeFrame:)
								   name:NSViewFrameDidChangeNotification
								 object:documentView];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(webViewDidChangeBounds:)
								   name:NSViewBoundsDidChangeNotification
								 object:documentView.enclosingScrollView.contentView];

	self->_automaticScrollingEnabled = YES;

	self->_scrollPositionCurrentValue = 0.0;
	self->_scrollPositionPreviousValue = 0.0;

	self->_userScrolled = NO;

	self->_restoreScrollerPosition = YES;
}

- (NSView *)documentView
{
	return self.frameView.documentView;
}

- (BOOL)viewingBottom
{
	if (self->_userScrolled == NO) {
		return YES;
	}

	return [self viewIsScrolledToBottom:self.documentView];
}

- (BOOL)viewIsScrolledToBottom:(NSView *)aView
{
	NSRect visibleRect = aView.visibleRect;

	CGFloat scrollHeight = (aView.frame.size.height - visibleRect.size.height);

	CGFloat scrollPosition = visibleRect.origin.y;

	return CGFloatAreEqual(scrollHeight, scrollPosition);
}

- (void)resetScrollerPosition
{
	[self resetScrollerPositionTo:NO];
}

- (void)resetScrollerPositionTo:(BOOL)scrolledToBottom
{
	self->_restoreScrollerPosition = scrolledToBottom;
}

- (void)saveScrollerPosition
{
	self->_restoreScrollerPosition = self.viewingBottom;
}

- (void)restoreScrollerPosition
{
	if (self->_restoreScrollerPosition) {
		self->_restoreScrollerPosition = NO;
	} else {
		return;
	}

	[self scrollViewToBottom:self.documentView];
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
	WebFrameView *frameView = self.frameView;

	NSRect frameRect = frameView.frame;

	NSRect contentRect = frameView.documentView.frame;

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
		(TEXTUAL_RUNNING_ON_YOSEMITE &&
		 TEXTUAL_RUNNING_ON_ELCAPITAN == NO);
	});

	if (_performForceRedraw == NO) {
		return;
	}

	[self redrawFrame];
}

- (void)redrawFrame
{
	[self.documentView setNeedsLayout:YES];
}

- (void)webViewDidChangeBounds:(NSNotification *)aNotification
{
	/* Context */
	NSView *documentView = self.documentView;

	NSRect visibleRect = documentView.visibleRect;

	/* The maximum scrollPosition can equal. The bottom */
	CGFloat scrollHeightCurrent = (documentView.frame.size.height - visibleRect.size.height);

	CGFloat scrollHeightPrevious = self->_scrollHeightPreviousValue;

	/* The current position. When at bottom, will == scrollHeight */
	CGFloat scrollPositionCurrent = visibleRect.origin.y;

	CGFloat scrollPositionPrevious = self->_scrollPositionPreviousValue;

	/* If nothing changed, we ignore the event.
	 It is possible to receive a scroll event but nothing changes
	 because we ignore elastic scrolling. User can reach bottom,
	 elsastic scroll, then bounce back. We get notification for
	 both times we reach bottom, but values do not change. */
	if (CGFloatAreEqual(scrollHeightPrevious, scrollHeightCurrent) &&
		CGFloatAreEqual(scrollPositionPrevious, scrollPositionCurrent))
	{
		return;
	}

	/* Even if user is elastic scrolling, we want to record
	 the latest scroll height values. */
	self->_scrollHeightPreviousValue = scrollHeightPrevious;
	self->_scrollHeightCurrentValue = scrollHeightCurrent;

	/* Ignore elastic scrolling */
	if (scrollPositionCurrent < 0 ||
		scrollPositionCurrent > scrollHeightCurrent)
	{
		return;
	}

	/* Only record scroll position changes if we weren't elastic scrolling. */
	self->_scrollPositionPreviousValue = scrollPositionPrevious;
	self->_scrollPositionCurrentValue = scrollPositionCurrent;

	/* Scrolled upwards? */
	BOOL scrolledUpwards = (scrollPositionCurrent < scrollPositionPrevious);

	self->_scrolledUpwards = scrolledUpwards;

	/* User scrolled above bottom? */
	BOOL userScrolled = ((scrollHeightCurrent - scrollPositionCurrent) > _userScrolledMinimum);

	if (self->_userScrolled != userScrolled) {
		self->_userScrolled = userScrolled;

		if (userScrolled) {
			LogToConsoleDebug("User scrolled above threshold. Disabled auto scroll.");
		} else {
			LogToConsoleDebug("Scrolled below threshold. Enabled auto scroll.");
		}
	}

	[self redrawFrameIfNeeded];
}

- (void)webViewDidChangeFrame:(NSNotification *)aNotification
{
	/* Never scroll if user scrolled up */
	if (self->_automaticScrollingEnabled == NO || self->_userScrolled) {
		return;
	}

	[self scrollViewToBottom:self.documentView];
}

@end

NS_ASSUME_NONNULL_END
