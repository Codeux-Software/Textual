// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface ThinSplitView (Private)
- (void)updatePosition;
@end

@implementation ThinSplitView

@synthesize hidden;
@synthesize position;
@synthesize inverted;
@synthesize fixedViewIndex;
@synthesize myDividerThickness;

- (void)setUp
{
	myDividerThickness = 1;
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
	myDividerThickness = (([self isVertical]) ? 1 : 5);
	
	[self updatePosition];
}

- (CGFloat)dividerThickness
{
	return myDividerThickness;
}

- (NSInteger)fixedViewIndex
{
	return fixedViewIndex;
}

- (void)setFixedViewIndex:(NSInteger)value
{
	if (fixedViewIndex != value) {
		fixedViewIndex = value;
		
		if (inverted) {
			fixedViewIndex = ((fixedViewIndex) ? 0 : 1);
		}
	}
}

- (NSInteger)position
{
	return position;
}

- (void)setPosition:(NSInteger)value
{
	position = value;
	
	[self adjustSubviews];
}

- (NSInteger)myDividerThickness
{
	return myDividerThickness;
}

- (void)setDividerThickness:(NSInteger)value
{
	myDividerThickness = value;
	
	[self setDividerThickness:myDividerThickness];
	
	[self adjustSubviews];
}

- (BOOL)inverted
{
	return inverted;
}

- (void)setInverted:(BOOL)value
{
	if (inverted == value) return;
	
	inverted = value;
	
	NSView *a = [[[self subviews] safeObjectAtIndex:0] adrv];
	NSView *b = [[[self subviews] safeObjectAtIndex:1] adrv];
	
	[a removeFromSuperviewWithoutNeedingDisplay];
	[b removeFromSuperviewWithoutNeedingDisplay];
	
	[self addSubview:b];
	[self addSubview:a];
	
	fixedViewIndex = ((fixedViewIndex) ? 0 : 1);
	
	[self adjustSubviews];
}

- (void)setVertical:(BOOL)value
{
	[super setVertical:value];
	
	myDividerThickness = ((value) ? 1 : 5);
	
	[self adjustSubviews];
}

- (BOOL)hidden
{
	return hidden;
}

- (void)setHidden:(BOOL)value
{
	if (hidden == value) return;
	
	hidden = value;
	
	[self adjustSubviews];
}

- (void)drawDividerInRect:(NSRect)rect
{
	if (hidden) return;
	
	[[NSColor colorWithCalibratedWhite:0.65 alpha:1] set];
	
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
    
    if ([self isSubviewCollapsed:[subviews_ objectAtIndex:fixedViewIndex]]) {
        [super adjustSubviews];
        
        return;
    }
	
	NSSize size = self.frame.size;
	
	NSInteger width = size.width;
	NSInteger height = size.height;
	NSInteger w = myDividerThickness;
	
	NSView *fixedView = [[self subviews] safeObjectAtIndex:fixedViewIndex];
	NSView *flyingView = [[self subviews] safeObjectAtIndex:((fixedViewIndex) ? 0 : 1)];
	
	NSRect fixedFrame = fixedView.frame;
	NSRect flyingFrame = flyingView.frame;

	if (hidden) {
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
			flyingFrame.size.width = (width - w - position);
			flyingFrame.size.height = height;
			flyingFrame.origin.x = ((fixedViewIndex) ? 0 : position + w);
			flyingFrame.origin.y = 0;
			
			if (flyingFrame.size.width < 0) flyingFrame.size.width = 0;
			
			fixedFrame.size.width = position;
			fixedFrame.size.height = height;
			fixedFrame.origin.x = ((fixedViewIndex) ? (flyingFrame.size.width + w) : 0);
			fixedFrame.origin.y = 0;
			
			if (fixedFrame.size.width > (width - w)) fixedFrame.size.width = (width - w);
		} else {
			flyingFrame.size.width = width;
			flyingFrame.size.height = (height - w - position);
			flyingFrame.origin.x = 0;
			flyingFrame.origin.y = ((fixedViewIndex) ? 0 : position + w);
			
			if (flyingFrame.size.height < 0) flyingFrame.size.height = 0;
			
			fixedFrame.size.width = width;
			fixedFrame.size.height = position;
			fixedFrame.origin.x = 0;
			fixedFrame.origin.y = ((fixedViewIndex) ? (flyingFrame.size.height + w) : 0);
			
			if (fixedFrame.size.height > (height - w)) fixedFrame.size.height = (height - w);
		}
	}
	
	[fixedView  setFrame:fixedFrame];
	[flyingView setFrame:flyingFrame];
	
	[self setNeedsDisplay:YES];
	
	[[self window] invalidateCursorRectsForView:self];
}

- (void)updatePosition
{
	NSView *view =  [[self subviews] safeObjectAtIndex:fixedViewIndex];
	NSSize size = view.frame.size;
	
	position = (([self isVertical]) ? size.width : size.height);
}

@end