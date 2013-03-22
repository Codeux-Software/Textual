/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#import "TextualApplication.h"

@implementation TVCThinSplitView

- (void)awakeFromNib
{
	[self updatePosition];
}

- (void)setFixedViewIndex:(NSInteger)value
{
	if (NSDissimilarObjects(self.fixedViewIndex, value)) {
		_fixedViewIndex = value;

		if (self.viewIsInverted) {
			if (_fixedViewIndex == 1) {
				_fixedViewIndex = 0;
			} else {
				_fixedViewIndex = 1;
			}
		}

		[self adjustSubviews];
	}
}

- (void)setDividerPosition:(NSInteger)value
{
	if (NSDissimilarObjects(self.dividerPosition, value)) {
		_dividerPosition = value;

		[self adjustSubviews];
	}
}

- (void)setViewIsHidden:(BOOL)value
{
	if (NSDissimilarObjects(self.viewIsHidden, value)) {
		_viewIsHidden = value;

		[self adjustSubviews];
	}
}

- (void)setViewIsInverted:(BOOL)value
{
	if (NSDissimilarObjects(self.viewIsInverted, value)) {
		_viewIsInverted = value;
		
		NSView *a = [self.subviews safeObjectAtIndex:0];
		NSView *b = [self.subviews safeObjectAtIndex:1];

		[a removeFromSuperviewWithoutNeedingDisplay];
		[b removeFromSuperviewWithoutNeedingDisplay];

		[self addSubview:b];
		[self addSubview:a];

		if (self.fixedViewIndex == 1) {
			_fixedViewIndex = 0;
		} else {
			_fixedViewIndex = 1;
		}

		[self adjustSubviews];
	}
}

- (void)drawDividerInRect:(NSRect)rect
{
	NSColor *dividerColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];

	if ([TPCPreferences invertSidebarColors]) {
		dividerColor = [dividerColor invertColor];
	}

	[dividerColor set];

	NSRectFill(rect);
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[self adjustSubviews];
}

- (void)mouseDown:(NSEvent *)e
{
	[super mouseDown:e];

	[self updatePosition];
}

- (void)adjustSubviews
{
	NSInteger fixedIndex = self.fixedViewIndex;
	
	if (NSDissimilarObjects(self.subviews.count, 2)) {
		[super adjustSubviews];

		return;
	}

    if ([self isSubviewCollapsed:self.subviews[fixedIndex]]) {
        [super adjustSubviews];

        return;
    }

	NSSize frameSize = self.frame.size;

	NSInteger frameWidth = frameSize.width;
	NSInteger frameHeight = frameSize.height;

	NSView *flyingView = nil;
	NSView *fixedView = [self.subviews safeObjectAtIndex:fixedIndex];

	if (fixedIndex == 1) {
		flyingView = [self.subviews safeObjectAtIndex:0];
	} else {
		flyingView = [self.subviews safeObjectAtIndex:1];
	}
	
	NSRect fixedFrame = fixedView.frame;
	NSRect flyingFrame = flyingView.frame;
	
	if (self.viewIsHidden) {
		fixedFrame = NSMakeRect(0, 0, 0, frameHeight);
		flyingFrame.origin = NSZeroPoint;
		flyingFrame.size = frameSize;
	} else {
		flyingFrame.size.width = ((frameWidth - self.dividerThickness) - self.dividerPosition);
		flyingFrame.size.height = frameHeight;
		flyingFrame.origin.x = 0;
		flyingFrame.origin.y = 0;

		if (fixedIndex == 0) {
			flyingFrame.origin.x = (self.dividerPosition + self.dividerThickness);
		}

		if (flyingFrame.size.width < 0) {
			flyingFrame.size.width = 0;
		}
		
		fixedFrame.size.width = self.dividerPosition;
		fixedFrame.size.height = frameHeight;
		fixedFrame.origin.x = 0;
		fixedFrame.origin.y = 0;

		if (fixedIndex == 1) {
			fixedFrame.origin.x = (flyingFrame.size.width + self.dividerThickness);
		}

		if (fixedFrame.size.width > (frameWidth	- self.dividerThickness)) {
			fixedFrame.size.width = (frameWidth	- self.dividerThickness);
		}
	}

	[fixedView setFrame:fixedFrame];
	[flyingView setFrame:flyingFrame];

	[self setNeedsDisplay:YES];

	[self.window invalidateCursorRectsForView:self];
}

- (void)updatePosition
{
	NSView *view = [self.subviews safeObjectAtIndex:self.fixedViewIndex];

	self.dividerPosition = view.frame.size.width;
}

@end
