// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation MarkedScroller

@synthesize dataSource;

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if (dataSource == nil) return;
	if ([dataSource respondsToSelector:@selector(markedScrollerColor:)] == NO) return;
	if ([dataSource respondsToSelector:@selector(markedScrollerPositions:)] == NO) return;
	
	NSScrollView *scrollView = (NSScrollView *)[self superview];
	NSInteger contentHeight = [[scrollView contentView] documentRect].size.height;
	NSArray *ary = [dataSource markedScrollerPositions:self];
	
	if (ary == nil || ary.count < 1) return;
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	
	NSInteger width = [MarkedScroller scrollerWidth];
	NSInteger offset = [self rectForPart:NSScrollerKnobSlot].origin.y;
	CGFloat scale = ([self rectForPart:NSScrollerKnobSlot].size.height / (CGFloat)contentHeight);
	
	[transform scaleXBy:1 yBy:scale];
	[transform translateXBy:0 yBy:offset];
	
	NSPoint prev = NSMakePoint(-1, -1);
	NSMutableArray *lines = [NSMutableArray array];
	
	for (NSNumber *e in ary) {
		NSInteger i = [e integerValue];
		NSPoint pt = NSMakePoint(0, i);
		
		pt = [transform transformPoint:pt];
		
		pt.x = ceil(pt.x);
		pt.y = (ceil(pt.y) + 0.5);
		
		if (pt.x == prev.x && pt.y == prev.y) continue;
		
		prev = pt;
		
		NSBezierPath *line = [NSBezierPath bezierPath];
		
		[line setLineWidth:1];
		[line moveToPoint:pt];
		[line relativeLineToPoint:NSMakePoint(width, 0)];
		
		[lines addObject:line];
	}
	
	NSRectClip(NSInsetRect([self rectForPart:NSScrollerKnobSlot], 3, 4));

	[[dataSource markedScrollerColor:self] set];
	
	for (NSBezierPath *e in lines) {
		[e stroke];
	}
	
	[self drawKnob];
}

@end