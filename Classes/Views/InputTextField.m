// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Much of the following drawing has been created by Dan Messing for the class "SSTextField" */

#define LION_ACTIVE_START_GRADIENT			[NSColor colorWithCalibratedRed:(109.0/255.0) green:(109.0/255.0) blue:(109.0/255.0) alpha:1]
#define LION_ACTIVE_STOP_GRADIENT			[NSColor colorWithCalibratedRed:(122.0/255.0) green:(122.0/255.0) blue:(122.0/255.0) alpha:1]
#define LION_INACTIVE_START_GRADIENT		[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]
#define LION_INACTIVE_STOP_GRADIENT			[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]
#define LION_BODY_GRADIENT_START			[NSColor colorWithCalibratedRed:(221.0/255.0) green:(221.0/255.0) blue:(221.0/255.0) alpha:1]
#define LION_BODY_GRADIENT_STOP				[NSColor whiteColor]

#define InputTextFieldWidthPadding			4.0
#define InputTextFieldHeightPadding			5.0
#define InputTextFiedMaxHeight				401.0
#define InputBoxDefaultHeight				26.0
#define InputBoxReszieHeightMultiplier		15.0

@implementation InputTextField

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
		[self setDrawsBackground:NO];
		[self setFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
		
		if ([Preferences rightToLeftFormatting]) {
			[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
		} else {
			[self setBaseWritingDirection:NSWritingDirectionNatural];
		}
    }
	
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect cellBounds		= [self bounds];
	NSRect hightlightFrame	= NSMakeRect(0.0, 10.0, cellBounds.size.width, (cellBounds.size.height - 10.0));
	
	NSBezierPath *highlightPath  = [NSBezierPath bezierPathWithRoundedRect:hightlightFrame xRadius:3.6 yRadius:3.6];
	NSColor		 *highlightColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.394];
	
	[highlightColor set];
	[highlightPath fill];
	
	NSRect blackOutlineFrame = NSMakeRect(0.0, 0.0, cellBounds.size.width, (cellBounds.size.height - 1.0));
	
	NSGradient   *gradient;
	NSBezierPath *gradientPath = [NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:3.6 yRadius:3.6];
	
	if ([NSApp isActive]) {
		gradient = [[NSGradient alloc] initWithStartingColor:LION_ACTIVE_START_GRADIENT endingColor:LION_ACTIVE_STOP_GRADIENT];
	} else {
		gradient = [[NSGradient alloc] initWithStartingColor:LION_INACTIVE_START_GRADIENT endingColor:LION_INACTIVE_STOP_GRADIENT];
	}
	
	[gradient drawInBezierPath:gradientPath angle:90];
	
	NSRect shadowFrame = NSMakeRect(1, 1, (cellBounds.size.width - 2.0), 10.0);
	
	NSColor		 *shadowColor = [NSColor colorWithCalibratedWhite:0.88 alpha:1.0];
	NSBezierPath *shadowPath  = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:2.9 yRadius:2.9];
	
	[shadowColor set];
	[shadowPath fill];
	
	NSRect whiteFrame = NSMakeRect(1, 2, (cellBounds.size.width - 2.0), (cellBounds.size.height - 4.0));
	
	NSColor		 *frameColor    = [NSColor whiteColor];
	NSBezierPath *framePath     = [NSBezierPath bezierPathWithRoundedRect:whiteFrame xRadius:2.6 yRadius:2.6];
	NSGradient   *frameGradient = [[NSGradient alloc] initWithStartingColor:LION_BODY_GRADIENT_START endingColor:LION_BODY_GRADIENT_STOP];
	
	[frameColor set];
	[framePath fill];
	
	if (dirtyRect.size.height > 198.0) {
		whiteFrame.size.height = 198.0; 
	}
	
	framePath = [NSBezierPath bezierPathWithRoundedRect:whiteFrame xRadius:2.6 yRadius:2.6];
		
	[frameGradient drawInBezierPath:framePath angle:90];
	
	[gradient drain];
	[frameGradient drain];
	
	[super drawRect:dirtyRect];
}

#pragma mark -
#pragma mark Resizable Text Field

- (NSView *)splitterView
{
	return [[[self superview] subviews] objectAtIndex:0];
}

- (void)resetTextFieldCellSize
{
	/* TODO: Fix italic text font size. */
	
	NSWindow *mainWindow	= [self window];
	NSView   *superView		= [self splitterView];
	
	NSRect textBoxFrame		= [self frame];
	NSRect superViewFrame	= [superView frame];
	NSRect mainWindowFrame	= [mainWindow frame];
	
	if (NSObjectIsEmpty([self stringValue])) {
		textBoxFrame.size.height = InputBoxDefaultHeight;
	} else {
		NSLayoutManager *layoutManager	= [NSLayoutManager new];
		NSTextStorage	*textStorage	= [[NSTextStorage alloc] initWithAttributedString:[self attributedStringValue]];
		NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize:NSMakeSize((textBoxFrame.size.width - 12), FLT_MAX)];
		
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0];
		[layoutManager glyphRangeForTextContainer:textContainer];
		
		NSInteger cellHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		NSInteger totalLines = (cellHeight / 14);
		
		if (totalLines == 1) {
			textBoxFrame.size.height = InputBoxDefaultHeight;
		} else {
			textBoxFrame.size.height = (InputBoxDefaultHeight + ((totalLines - 1) * InputBoxReszieHeightMultiplier));
		}
		
		if (textBoxFrame.size.height > InputTextFiedMaxHeight) {
			textBoxFrame.size.height = InputTextFiedMaxHeight;
		}
	}	
	
	NSInteger contentBorder = (textBoxFrame.size.height + 13);
	
	superViewFrame.origin.y	   = contentBorder;
	superViewFrame.size.height = (mainWindowFrame.size.height - contentBorder - 22);
	
	[mainWindow setContentBorderThickness:contentBorder forEdge:NSMinYEdge];
	
	[self		setFrame:textBoxFrame];
	[superView	setFrame:superViewFrame];
}

- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	
	[self resetTextFieldCellSize];
}

- (void)setObjectValue:(id)obj recordUndo:(BOOL)undo
{
	[super setObjectValue:obj recordUndo:undo];
	
	[self resetTextFieldCellSize];
}

- (void)setStringValue:(NSString *)aString
{
	[super setStringValue:aString];
	
	[self resetTextFieldCellSize];
}

- (void)setAttributedStringValue:(NSAttributedString *)obj
{
	[super setAttributedStringValue:obj];
	
	[self resetTextFieldCellSize];
}

- (void)setFilteredAttributedStringValue:(NSAttributedString *)string
{
	[super setFilteredAttributedStringValue:string];
	
	[self resetTextFieldCellSize];
}

- (void)pasteFilteredAttributedString:(NSRange)selectedRange
{
	[super pasteFilteredAttributedString:selectedRange];
	
	[self resetTextFieldCellSize];
}

@end

@implementation InputTextFieldCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.x		+= InputTextFieldWidthPadding;
	cellFrame.size.width	-= (InputTextFieldWidthPadding * 2);
	
	cellFrame.origin.y		+= InputTextFieldHeightPadding;
	cellFrame.size.height	-= (InputTextFieldHeightPadding * 2);
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)selectWithFrame:(NSRect)aRect
				 inView:(NSView *)controlView
				 editor:(NSText *)textObj
			   delegate:(id)anObject
				  start:(NSInteger)selStart
				 length:(NSInteger)selLength
{
	aRect.origin.x		+= InputTextFieldWidthPadding;
	aRect.size.width	-= (InputTextFieldWidthPadding * 2);
	
	aRect.origin.y		+= InputTextFieldHeightPadding;
	aRect.size.height	-= (InputTextFieldHeightPadding * 2);
	
	[super selectWithFrame:aRect
					inView:controlView
					editor:textObj
				  delegate:anObject
					 start:selStart
					length:selLength];
}

@end