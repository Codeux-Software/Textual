// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

/* Much of the following drawing has been created by Dan Messing for the class "SSTextField" */

#import <objc/objc-runtime.h>

#define _InputTextFiedMaxHeight					382.0
#define _InputBoxDefaultHeight					18.0
#define _InputBoxHeightMultiplier				14.0
#define _InputBoxBackgroundMaxHeight			387.0
#define _InputBoxBackgroundDefaultHeight		23.0
#define _InputBoxBackgroundHeightMultiplier		14.0
#define _WindowContentBorderDefaultHeight		38.0

@implementation TVCInputTextField
{
	NSInteger _lastDrawnLineCount;
}

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
        self.delegate = self;
        
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
        attrs[NSFontAttributeName] = TXDefaultTextFieldFont;
        attrs[NSForegroundColorAttributeName] = [NSColor grayColor];
        
        self.placeholderString = [NSAttributedString alloc];
        self.placeholderString = [self.placeholderString initWithString:TXTLS(@"InputTextFieldPlaceholderValue") attributes:attrs];
    }
	
    return self;
}

- (NSView *)splitterView
{
    return (self.superview.superview.superview.subviews)[0];
}

- (TVCInputTextFieldBackground *)backgroundView
{
	return (self.superview.superview.superview.subviews)[2];
}

- (void)updateTextDirection
{
	if ([TPCPreferences rightToLeftFormatting]) {
		[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
	} else {
		[self setBaseWritingDirection:NSWritingDirectionLeftToRight];
	}
}

- (void)resetTextFieldCellSize
{
	BOOL drawBezel = YES;
	
	NSWindow     *mainWindow = self.window;
	
	NSView       *superView	 = [self splitterView];
	NSView		 *background = [self backgroundView];
	
    NSScrollView *scroller   = [self scrollView];
	
	NSRect textBoxFrame		= scroller.frame;
	NSRect superViewFrame	= superView.frame;
	NSRect mainWindowFrame	= mainWindow.frame;
	NSRect backgroundFrame  = background.frame;
	
	NSInteger contentBorder;
	
	NSString *stringv = self.stringValue;
	
	if (NSObjectIsEmpty(stringv)) {
		textBoxFrame.size.height    = _InputBoxDefaultHeight;
		backgroundFrame.size.height = _InputBoxBackgroundDefaultHeight;
		
		if (_lastDrawnLineCount >= 2) {
			drawBezel = YES;
		}
		
		_lastDrawnLineCount = 1;
	} else {
		NSInteger totalLinesBase = [self numberOfLines];
		
		if (_lastDrawnLineCount == totalLinesBase) {
			drawBezel = NO;
		}
		
		_lastDrawnLineCount = totalLinesBase;
		
		if (drawBezel) {
			NSInteger totalLinesMath = (totalLinesBase - 1);
			
			textBoxFrame.size.height	= _InputBoxDefaultHeight;
			backgroundFrame.size.height	= _InputBoxBackgroundDefaultHeight;
			
			textBoxFrame.size.height	+= (totalLinesMath * _InputBoxHeightMultiplier);
			backgroundFrame.size.height += (totalLinesMath * _InputBoxBackgroundHeightMultiplier);
			
			if (textBoxFrame.size.height > _InputTextFiedMaxHeight) {
				textBoxFrame.size.height = _InputTextFiedMaxHeight;
			}
			
			if (backgroundFrame.size.height > _InputBoxBackgroundMaxHeight) {
				backgroundFrame.size.height = _InputBoxBackgroundMaxHeight;
			}
		}
	}
	
	if (drawBezel) {
		contentBorder = (backgroundFrame.size.height + 14);
		
		superViewFrame.origin.y = contentBorder;
		
		if ([mainWindow isInFullscreenMode]) {
			superViewFrame.size.height = (mainWindowFrame.size.height - contentBorder);
		} else {
			superViewFrame.size.height = (mainWindowFrame.size.height - contentBorder - 22);
		}
		
		[mainWindow setContentBorderThickness:contentBorder forEdge:NSMinYEdge];
		
		[scroller	setFrame:textBoxFrame];
		[superView	setFrame:superViewFrame];
		[background setFrame:backgroundFrame];
	}
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
	[self updateTextDirection];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias: NO];
	}
	
	NSString *value = [self stringValue];
	
	if (NSObjectIsEmpty(value)) {
		if (NSDissimilarObjects([self baseWritingDirection], NSWritingDirectionRightToLeft)) {
			[self.placeholderString drawAtPoint:NSMakePoint(6, 1)];
		}
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
    self.actionTarget   = owner;
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

@implementation TVCInputTextFieldBackground
{
	BOOL _finishedFirstDraw;
}

- (void)setWindowIsActive:(BOOL)value
{
	if (NSDissimilarObjects(value, self.windowIsActive)) {
		_windowIsActive = value;
	}
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect cellBounds;
	NSRect controlFrame;
	
	cellBounds = [self frame];
	
	NSColor		 *controlColor;
	NSBezierPath *controlPath;
	
	/* Control Outside White Shadow. */
	controlFrame =  NSMakeRect(0.0, 0.0, cellBounds.size.width, 1.0);
	controlColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.394];
	controlPath  = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];
	
	[controlColor set];
	[controlPath fill];
	
	/* Black Outline. */
	controlFrame = NSMakeRect(0.0, 1.0, cellBounds.size.width, (cellBounds.size.height - 1.0));
	
	/* We force focused color during first run because we draw before
	 our window has finished coming to the front so the wrong color
	 is used for our border. */
	if (self.windowIsActive || _finishedFirstDraw == NO) {
		controlColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.4];
	} else {
		controlColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.23];
	}
	
	controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];
	
	[controlColor set];
	[controlPath fill];
	
	/* White Background. */
	controlColor	= [NSColor whiteColor];
	controlFrame	=  NSMakeRect(1, 2, (cellBounds.size.width - 2.0), (cellBounds.size.height - 4.0));
	controlPath		= [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.6 yRadius:2.6];
	
	[controlColor set];
	[controlPath fill];
	
	/* Inside White Shadow. */
	controlFrame =  NSMakeRect(2, (cellBounds.size.height - 2.0), (cellBounds.size.width - 4.0), 1.0);
	controlColor = [NSColor colorWithCalibratedWhite:0.88 alpha:1.0];
	controlPath  = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.9 yRadius:2.9];
	
	[controlColor set];
	[controlPath fill];
	
	if (_finishedFirstDraw == NO) {
		_finishedFirstDraw = YES;
	}
}

@end