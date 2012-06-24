// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

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

	NSColor *dividerColor;

	dividerColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1];
	dividerColor = TXInvertSidebarColor(dividerColor);

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