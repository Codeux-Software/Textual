/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

- (void)setUp
{
	self.altDividerThickness = 1;
}

- (id)initWithFrame:(NSRect)rect
{
	if ((self = [super initWithFrame:rect])) {
		[self setUp];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self setUp];
	}
	
	return self;
}

- (void)awakeFromNib
{
	self.altDividerThickness = (([self isVertical]) ? 1 : 5);
	
	[self updatePosition];
}

- (void)setFixedViewIndex:(NSInteger)value
{
	if (NSDissimilarObjects(self.fixedViewIndex, value)) {
		_fixedViewIndex = value;
		
		if (self.inverted) {
			_fixedViewIndex = ((self.fixedViewIndex) ? 0 : 1);
		}
	}
}

- (void)setPosition:(NSInteger)value
{
	if (self.position == value) return;
	
	_position = value;
	
	[self adjustSubviews];
}

- (void)setAltDividerThickness:(NSInteger)value
{
	if (self.altDividerThickness == value) return;

	_altDividerThickness = value;

	[self adjustSubviews];
}

- (void)setInverted:(BOOL)value
{
	if (_inverted == value) return;
	
	_inverted = value;
	
	NSView *a = [[self subviews] safeObjectAtIndex:0];
	NSView *b = [[self subviews] safeObjectAtIndex:1];
	
	[a removeFromSuperviewWithoutNeedingDisplay];
	[b removeFromSuperviewWithoutNeedingDisplay];
	
	[self addSubview:b];
	[self addSubview:a];
	
	_fixedViewIndex = ((self.fixedViewIndex) ? 0 : 1);
	
	[self adjustSubviews];
}

- (void)setVertical:(BOOL)value
{
	[super setVertical:value];
	
	_altDividerThickness = ((value) ? 1 : 5);
	
	[self adjustSubviews];
}

- (void)setHidden:(BOOL)value
{
	if (self.hidden == value) return;
	
	_hidden = value;
	
	[self adjustSubviews];
}

- (void)drawDividerInRect:(NSRect)rect
{
	if (self.hidden) return;

	NSColor *dividerColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1];

	if ([TPCPreferences invertSidebarColors]) {
		dividerColor = [dividerColor invertColor];
	}

	[dividerColor set];
	
	if ([self isVertical]) {
		NSRectFill(rect);
	} else {
		NSPoint left, right;
		
		left = rect.origin;
		
		right = left;
		right.x += rect.size.width;
		
		[NSBezierPath strokeLineFromPoint:left toPoint:right];
		
		left = rect.origin;
		left.y += rect.size.height;
		
		right = left;
		right.x += rect.size.width;
		
		[NSBezierPath strokeLineFromPoint:left toPoint:right];
	}
}

- (void)mouseDown:(NSEvent *)e
{
	[super mouseDown:e];
	
	[self updatePosition];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[self adjustSubviews];
}

- (void)adjustSubviews
{
    NSArray *subviews_ = [self subviews];
    
	if (NSDissimilarObjects([subviews_ count], 2)) {
		[super adjustSubviews];
		
		return;
	}
    
    if ([self isSubviewCollapsed:subviews_[self.fixedViewIndex]]) {
        [super adjustSubviews];
        
        return;
    }
	
	NSSize size = self.frame.size;
	
	NSInteger width = size.width;
	NSInteger height = size.height;
	NSInteger w = self.altDividerThickness;
	
	NSView *fixedView = [[self subviews] safeObjectAtIndex:self.fixedViewIndex];
	NSView *flyingView = [[self subviews] safeObjectAtIndex:((self.fixedViewIndex) ? 0 : 1)];
	
	NSRect fixedFrame = fixedView.frame;
	NSRect flyingFrame = flyingView.frame;

	if (self.hidden) {
		if ([self isVertical]) {
			fixedFrame = NSMakeRect(0, 0, 0, height);
			flyingFrame.origin = NSZeroPoint;
			flyingFrame.size = size;
		} else {
			fixedFrame = NSMakeRect(0, 0, width, 0);
			flyingFrame.origin = NSZeroPoint;
			flyingFrame.size = size;
		}
	} else {
		if ([self isVertical]) {
			flyingFrame.size.width = (width - w - self.position);
			flyingFrame.size.height = height;
			flyingFrame.origin.x = ((self.fixedViewIndex) ? 0 : self.position + w);
			flyingFrame.origin.y = 0;
			
			if (flyingFrame.size.width < 0) flyingFrame.size.width = 0;
			
			fixedFrame.size.width = self.position;
			fixedFrame.size.height = height;
			fixedFrame.origin.x = ((self.fixedViewIndex) ? (flyingFrame.size.width + w) : 0);
			fixedFrame.origin.y = 0;
			
			if (fixedFrame.size.width > (width - w)) fixedFrame.size.width = (width - w);
		} else {
			flyingFrame.size.width = width;
			flyingFrame.size.height = (height - w - self.position);
			flyingFrame.origin.x = 0;
			flyingFrame.origin.y = ((self.fixedViewIndex) ? 0 : self.position + w);
			
			if (flyingFrame.size.height < 0) flyingFrame.size.height = 0;
			
			fixedFrame.size.width = width;
			fixedFrame.size.height = self.position;
			fixedFrame.origin.x = 0;
			fixedFrame.origin.y = ((self.fixedViewIndex) ? (flyingFrame.size.height + w) : 0);
			
			if (fixedFrame.size.height > (height - w)) fixedFrame.size.height = (height - w);
		}
	}
	
	[fixedView  setFrame:fixedFrame];
	[flyingView setFrame:flyingFrame];
	
	[self setNeedsDisplay:YES];
	
	[self.window invalidateCursorRectsForView:self];
}

- (void)updatePosition
{
	NSView *view =  [[self subviews] safeObjectAtIndex:self.fixedViewIndex];
	NSSize size = view.frame.size;
	
	self.position = (([self isVertical]) ? size.width : size.height);
}

@end