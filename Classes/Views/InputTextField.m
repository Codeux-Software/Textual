// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* Much of the following drawing has been created by Dan Messing for the class "SSTextField" */

#define LION_ACTIVE_START_GRADIENT			[NSColor _colorWithCalibratedRed:109.0 green:109.0 blue:109.0 alpha:1]
#define LION_ACTIVE_STOP_GRADIENT			[NSColor _colorWithCalibratedRed:122.0 green:122.0 blue:122.0 alpha:1]
#define LION_INACTIVE_START_GRADIENT		[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]
#define LION_INACTIVE_STOP_GRADIENT			[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]
#define LION_BODY_GRADIENT_START			[NSColor _colorWithCalibratedRed:221.0 green:221.0 blue:221.0 alpha:1]
#define LION_BODY_GRADIENT_STOP				[NSColor whiteColor]

#define InputTextFiedMaxHeight				404.0
#define InputBoxDefaultHeight				26.0
#define InputBoxReszieHeightMultiplier		14.0

@implementation InputTextField

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
        self.delegate = self;
        
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        
        /* Default Value */
        [attrs setObject:DefaultTextFieldFont forKey:NSFontAttributeName];
        [attrs setObject:[NSColor grayColor]  forKey:NSForegroundColorAttributeName];
        
        _placeholderString = [NSAttributedString alloc];
        _placeholderString = [_placeholderString initWithString:TXTLS(@"INPUT_TEXT_FIELD_PLACE_HOLDER") attributes:attrs];
        
        /* Set Text Color */
        [attrs setObject:DefaultTextFieldFontColor forKey:NSForegroundColorAttributeName];
        
        NSAttributedString *temps;
        
        temps = [NSAttributedString alloc];
        temps = [temps initWithString:@"-" attributes:attrs];
        
        [self setAttributedStringValue:temps];
        [self setStringValue:NSNullObject];
        
        [temps drain];
    }
	
    return self;
}

- (void)dealloc
{
    [_placeholderString drain];
    
    [super dealloc];
}

- (NSView *)splitterView
{
    return [self.superview.superview.superview.subviews objectAtIndex:0];
}

- (void)resetTextFieldCellSize
{
	NSWindow     *mainWindow = [self window];
	NSView       *superView	 = [self splitterView];
    NSScrollView *scroller   = [self scrollView];
	
	NSRect textBoxFrame		= [scroller frame];
	NSRect superViewFrame	= [superView frame];
	NSRect mainWindowFrame	= [mainWindow frame];
	
	if (NSObjectIsEmpty([self string])) {
		textBoxFrame.size.height = InputBoxDefaultHeight;
	} else {
        NSAttributedString *value = [self attributedStringValue];
        
        NSInteger cellHeight = [value pixelHeightInWidth:(textBoxFrame.size.width - 12)];
		CGFloat totalLines = ceil(cellHeight / 14.0f);
		
		if (totalLines <= 1) {
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
    
	[scroller	setFrame:textBoxFrame];
	[superView	setFrame:superViewFrame];
    
    [scroller setNeedsDisplay:YES];
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if (_lastChangeWasPaste) {
        _lastChangeWasPaste = NO;
        
        return;
    }
    
    [super textDidChange:self pasted:NO range:[self fullSelectionRange]];
    
    [self resetTextFieldCellSize];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSScrollView *scroller = [self scrollView];
    
    if (scroller.frame.size.height == InputTextFiedMaxHeight) {
        BOOL cleanSubview = NO;
        
        if ([scroller hasVerticalScroller]) {
            if (self.frame.size.height > scroller.frame.size.height) {
                if (NSDissimilarObjects(1.0f, scroller.verticalScroller.floatValue)) {
                    cleanSubview = YES;
                }
            }
        }
        
        if (cleanSubview) {
            dirtyRect.size.height -= 4;
        }
    }
    
    [super drawRect:dirtyRect];
    
    NSString *value = [self stringValue];
            
    if (NSObjectIsEmpty(value) && NSDissimilarObjects([self baseWritingDirection], NSWritingDirectionRightToLeft)) {
        [_placeholderString drawAtPoint:NSMakePoint(6, 5)];
    }
}

- (void)paste:(id)sender
{
    _lastChangeWasPaste = YES;
    
    [super paste:self];
    
    [self resetTextFieldCellSize];
}

- (void)setReturnActionWithSelector:(SEL)selector owner:(id)owner
{
    _actionTarget  = owner;
    _actonSelector = selector;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertNewline:)) {
        [_actionTarget performSelector:_actonSelector];
        
        [self toggleFontResetStatus:YES];
        [self resetTextFieldCellSize];
        
        return YES;
    }
    
    return NO;
}

@end

@implementation InputTextFieldScroller

- (void)drawRect:(NSRect)dirtyRect
{
	NSWindow *parentWindow = [self window];
	
	NSRect cellBounds		= [self bounds];
	NSRect hightlightFrame	= NSMakeRect(0.0, 10.0, cellBounds.size.width, (cellBounds.size.height - 10.0));
	
	NSBezierPath *highlightPath  = [NSBezierPath bezierPathWithRoundedRect:hightlightFrame xRadius:3.6 yRadius:3.6];
	NSColor		 *highlightColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.394];
	
	[highlightColor set];
	[highlightPath fill];
	
	NSRect blackOutlineFrame = NSMakeRect(0.0, 0.0, cellBounds.size.width, (cellBounds.size.height - 1.0));
	
	NSGradient   *gradient;
	NSBezierPath *gradientPath = [NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:3.6 yRadius:3.6];
	
	if ([parentWindow isOnCurrentWorkspace]) {
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
    
	[gradient      drain];
	[frameGradient drain];
	
	[super drawRect:dirtyRect];
}

@end
