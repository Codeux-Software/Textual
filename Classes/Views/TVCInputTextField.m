// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

/* Much of the following drawing has been created by Dan Messing for the class "SSTextField" */

#import <objc/objc-runtime.h>

#define _ActiveWindowGradientStart			[NSColor internalCalibratedRed:109.0 green:109.0 blue:109.0 alpha:1]
#define _ActiveWindowGradientStop			[NSColor internalCalibratedRed:122.0 green:122.0 blue:122.0 alpha:1]
#define _InactiveWindowGradientStart		[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]
#define _InactiveWindowGradientStop			[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]
#define _bodyGradientStart					[NSColor internalCalibratedRed:221.0 green:221.0 blue:221.0 alpha:1]
#define _bodyGradientStop					[NSColor whiteColor]

#define _InputTextFiedMaxHeight				404.0
#define _InputBoxDefaultHeight				26.0
#define _InputBoxReszieHeightMultiplier		14.0
#define _InputBoxResizeHeightPadding		12.0

@implementation TVCInputTextField

@synthesize placeholderString;
@synthesize actionTarget;
@synthesize actionSelector;

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
        self.delegate = self;
        
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
        [attrs setObject:TXDefaultTextFieldFont forKey:NSFontAttributeName];
        [attrs setObject:[NSColor grayColor]  forKey:NSForegroundColorAttributeName];
        
        self.placeholderString = [NSAttributedString alloc];
        self.placeholderString = [self.placeholderString initWithString:TXTLS(@"InputTextFieldPlaceholderValue") attributes:attrs];
		
		[super sanitizeTextField:YES];

#ifdef TXMacOSLionOrNewer
		if ([TPCPreferences featureAvailableToOSXLion]) {
			NSScrollView *scrollView = [self scrollView];
			
			[scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
			[scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
		}
#endif
    }
	
    return self;
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
		textBoxFrame.size.height = _InputBoxDefaultHeight;
	} else {
		NSInteger totalLines = [self numberOfLines];
		
		textBoxFrame.size.height  = (totalLines * _InputBoxReszieHeightMultiplier);
		textBoxFrame.size.height += _InputBoxResizeHeightPadding;
		
		if (textBoxFrame.size.height > _InputTextFiedMaxHeight) {
			textBoxFrame.size.height = _InputTextFiedMaxHeight;
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
    
    if (scroller.frame.size.height == _InputTextFiedMaxHeight) {
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
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias: NO];
	}
	
	NSString *value = [self stringValue];
	
	if (NSObjectIsEmpty(value) && NSDissimilarObjects([self baseWritingDirection], NSWritingDirectionRightToLeft)) {
		[self.placeholderString drawAtPoint:NSMakePoint(6, 5)];
	} else {
		[super drawRect:dirtyRect];
	}

	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() restoreGraphicsState];
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
    self.actionTarget  = owner;
    self.actionSelector = selector;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertNewline:)) {
		objc_msgSend(self.actionTarget, self.actionSelector);
        
        [self resetTextFieldCellSize];
		[self sanitizeTextField:NO];
        
        return YES;
    }
    
    return NO;
}

@end

@implementation TVCInputTextFieldScroller

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
		gradient = [[NSGradient alloc] initWithStartingColor:_ActiveWindowGradientStart endingColor:_ActiveWindowGradientStop];
	} else {
		gradient = [[NSGradient alloc] initWithStartingColor:_InactiveWindowGradientStart endingColor:_InactiveWindowGradientStop];
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
	NSGradient   *frameGradient = [[NSGradient alloc] initWithStartingColor:_bodyGradientStart endingColor:_bodyGradientStop];
	
	[frameColor set];
	[framePath fill];
	
	if (dirtyRect.size.height > 198.0) {
		whiteFrame.size.height = 198.0; 
	}
	
	framePath = [NSBezierPath bezierPathWithRoundedRect:whiteFrame xRadius:2.6 yRadius:2.6];
    
	[frameGradient drawInBezierPath:framePath angle:90];
    
	
	[super drawRect:dirtyRect];
}

@end
