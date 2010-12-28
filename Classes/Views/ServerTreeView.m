// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ServerTreeView

@synthesize responderDelegate;
@synthesize theme;
@synthesize bgColor;
@synthesize topLineColor;
@synthesize bottomLineColor;
@synthesize gradient;

- (void)setUp
{
	bgColor = [[NSColor colorWithCalibratedRed:229/255.0 green:237/255.0 blue:247/255.0 alpha:1] retain];
	topLineColor = [[NSColor colorWithCalibratedRed:173/255.0 green:187/255.0 blue:208/255.0 alpha:1] retain];
	bottomLineColor = [[NSColor colorWithCalibratedRed:140/255.0 green:152/255.0 blue:176/255.0 alpha:1] retain];
	
	NSColor *start = [NSColor colorWithCalibratedRed:173/255.0 green:187/255.0 blue:208/255.0 alpha:1];
	NSColor *end = [NSColor colorWithCalibratedRed:152/255.0 green:170/255.0 blue:196/255.0 alpha:1];
	gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
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

- (void)dealloc
{
	[theme release];
	[bgColor release];
	[topLineColor release];
	[bottomLineColor release];
	[gradient release];
	[super dealloc];
}

- (BOOL)acceptsFirstResponder
{
	if (responderDelegate) {
		[responderDelegate serverTreeViewAcceptsFirstResponder];
		return NO;
	}
	return YES;
}

- (void)themeChanged
{
	[bgColor release];
	[topLineColor release];
	[bottomLineColor release];
	[gradient release];

	bgColor = [theme.treeBgColor retain];
	topLineColor = [theme.treeSelTopLineColor retain];
	bottomLineColor = [theme.treeSelBottomLineColor retain];
	
	NSColor *start = theme.treeSelTopColor;
	NSColor *end = theme.treeSelBottomColor;
	gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
}

- (NSColor *)_highlightColorForCell:(NSCell *)cell
{
	return nil;
}

- (void)_highlightRow:(NSInteger)row clipRect:(NSRect)clipRect
{
	if (![NSApp isActive]) return;
	
	NSRect frame = [self rectOfRow:row];
	NSRect rect = frame;
	rect.origin.y += 1;
	rect.size.height -= 2;
	[gradient drawInRect:rect angle:90];
	
	[topLineColor set];
	rect = frame;
	rect.size.height = 1;
	NSRectFill(rect);
	
	[bottomLineColor set];
	rect = frame;
	rect.origin.y += rect.size.height - 1;
	rect.size.height = 1;
	NSRectFill(rect);
}

- (void)drawBackgroundInClipRect:(NSRect)rect
{
	[bgColor set];
	NSRectFill(rect);
}

@end