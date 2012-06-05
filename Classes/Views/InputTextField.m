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
#define InputBoxResizeHeightPadding			12.0

@implementation InputTextField

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
        self.delegate = self;
        
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
        [attrs setObject:DefaultTextFieldFont forKey:NSFontAttributeName];
        [attrs setObject:[NSColor grayColor]  forKey:NSForegroundColorAttributeName];
        
        _placeholderString = [NSAttributedString alloc];
        _placeholderString = [_placeholderString initWithString:TXTLS(@"INPUT_TEXT_FIELD_PLACE_HOLDER") attributes:attrs];
		
		[super sanitizeTextField:YES];

#ifdef _MAC_OS_LION_OR_NEWER
		if ([Preferences featureAvailableToOSXLion]) {
			NSScrollView *scrollView = [self scrollView];
			
			[scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
			[scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
		}
#endif
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
	NSWindow     *mainWindow = self.window;
	NSView       *superView	 = [self splitterView];
    NSScrollView *scroller   = [self scrollView];
	
	NSRect textBoxFrame		= scroller.frame;
	NSRect superViewFrame	= superView.frame;
	NSRect mainWindowFrame	= mainWindow.frame;
	
	NSString *stringv = self.stringValue;
	
	if (NSObjectIsEmpty(stringv)) {
		textBoxFrame.size.height = InputBoxDefaultHeight;
	} else {
		NSInteger totalLines = [self numberOfLines];
		
		textBoxFrame.size.height  = (totalLines * InputBoxReszieHeightMultiplier);
		textBoxFrame.size.height += InputBoxResizeHeightPadding;
		
		if (textBoxFrame.size.height > InputTextFiedMaxHeight) {
			textBoxFrame.size.height = InputTextFiedMaxHeight;
		}
	}	
	
	NSInteger contentBorder = (textBoxFrame.size.height + 13);
	
	superViewFrame.origin.y = contentBorder;
    
	if ([mainWindow isInFullscreenMode]) {
        superViewFrame.size.height = (mainWindowFrame.size.height - contentBorder);
    } else {
        superViewFrame.size.height = (mainWindowFrame.size.height - contentBorder - 22);
    }
	
	[mainWindow setContentBorderThickness:contentBorder forEdge:NSMinYEdge];
    
	[scroller	setFrame:textBoxFrame];
	[superView	setFrame:superViewFrame];
    
    [scroller setNeedsDisplay:YES];
}

- (void)textDidChange:(NSNotification *)aNotification
{
    [self resetTextFieldCellSize];
	
	if (NSObjectIsEmpty(self.stringValue)) {
		[super sanitizeTextField:NO];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSScrollView *scroller = [self scrollView];
    
    if (scroller.frame.size.height == InputTextFiedMaxHeight) {
        BOOL cleanBottomSubview = NO;
		BOOL cleanTopSubview	= NO;
        
        if ([scroller hasVerticalScroller]) {
            if (self.frame.size.height > scroller.frame.size.height) {
                if (NSDissimilarObjects(1.0f, scroller.verticalScroller.floatValue)) {
                    cleanBottomSubview  = YES;
                }
				
                if (NSDissimilarObjects(0.0f, scroller.verticalScroller.floatValue)) {
					cleanTopSubview = YES;
				}
            }
		}
		
		if (cleanBottomSubview) {
			dirtyRect.size.height -= 4;
		}
		
		if (cleanTopSubview) {
			dirtyRect.origin.y += 4;
			dirtyRect.size.height -= 4;
		}
	}
	
	if ([Preferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias: NO];
	}
	
	[super drawRect:dirtyRect];
	
	if ([Preferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() restoreGraphicsState];
	}
	
	NSString *value = [self stringValue];
	
	if (NSObjectIsEmpty(value) && NSDissimilarObjects([self baseWritingDirection], NSWritingDirectionRightToLeft)) {
		if ([Preferences useLogAntialiasing] == NO) {
			[_NSGraphicsCurrentContext() saveGraphicsState];
			[_NSGraphicsCurrentContext() setShouldAntialias: NO];
		}
		
		[_placeholderString drawAtPoint:NSMakePoint(6, 5)];
		
		if ([Preferences useLogAntialiasing] == NO) {
			[_NSGraphicsCurrentContext() restoreGraphicsState];
		}
	}
}

- (void)paste:(id)sender
{
    [super paste:self];
    
    [self resetTextFieldCellSize];
	[self sanitizeTextField:YES];
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
        
        [self resetTextFieldCellSize];
		[self sanitizeTextField:NO];
        
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
