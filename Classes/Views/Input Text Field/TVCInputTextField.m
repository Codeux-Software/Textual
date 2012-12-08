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

/* Much of the following drawing has been created by Dan Messing for the class "SSTextField" */

#import <objc/objc-runtime.h>

#define _InputBoxDefaultHeight					18.0
#define _InputBoxHeightMultiplier				14.0
#define _InputBoxBackgroundMaxHeight			387.0
#define _InputBoxBackgroundDefaultHeight		23.0
#define _InputBoxBackgroundHeightMultiplier		14.0
#define _WindowContentBorderDefaultHeight		38.0

#define _WindowSegmentedControllerDefaultX		10.0
#define _InputTextFieldOriginDefaultX			144.0

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

- (void)redrawOriginPoints
{
	TXMasterController *master = [TPCPreferences masterController];

	NSInteger defaultSegmentX = _WindowSegmentedControllerDefaultX;
	NSInteger defaultInputbxX = _InputTextFieldOriginDefaultX;

	NSInteger resultOriginX = 0;
	NSInteger resultSizeWth = (defaultInputbxX - defaultSegmentX);
	
	if ([TPCPreferences hideMainWindowSegmentedController]) {
		[master.windowButtonController setHidden:YES];

		resultOriginX = defaultSegmentX;
	} else {
		[master.windowButtonController setHidden:NO];
		
		resultOriginX  = defaultInputbxX;
		resultSizeWth *= -1;
	}

	NSRect fronFrame = [self.scrollView		frame];
	NSRect backFrame = [self.backgroundView frame];
	
	if (NSDissimilarObjects(resultOriginX, fronFrame.origin.x) &&
		NSDissimilarObjects(resultOriginX, backFrame.origin.x)) {

		fronFrame.size.width += resultSizeWth;
		backFrame.size.width += resultSizeWth;
		
		fronFrame.origin.x = resultOriginX;
		backFrame.origin.x = resultOriginX;
		
		[self.scrollView	 setFrame:fronFrame];
		[self.backgroundView setFrame:backFrame];
	}
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

- (NSInteger)backgroundViewMaximumHeight
{
	return (self.window.frame.size.height - 50);
}

- (void)resetTextFieldCellSize:(BOOL)force
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
		
		if (_lastDrawnLineCount == totalLinesBase && force == NO) {
			drawBezel = NO;
		}
		
		_lastDrawnLineCount = totalLinesBase;
		
		if (drawBezel) {
			NSInteger totalLinesMath = (totalLinesBase - 1);

			/* Calculate unfiltered height. */
			textBoxFrame.size.height	= _InputBoxDefaultHeight;
			backgroundFrame.size.height	= _InputBoxBackgroundDefaultHeight;
			
			textBoxFrame.size.height	+= (totalLinesMath * _InputBoxHeightMultiplier);
			backgroundFrame.size.height += (totalLinesMath * _InputBoxBackgroundHeightMultiplier);

			NSInteger backgroundViewMaxHeight = [self backgroundViewMaximumHeight];

			/* Fix height if it exceeds are maximum. */
			if (backgroundFrame.size.height > backgroundViewMaxHeight) {
				for (NSInteger i = totalLinesMath; i >= 0; i--) {
					NSInteger newSize = 0;

					newSize  =	   _InputBoxBackgroundDefaultHeight;
					newSize += (i * _InputBoxBackgroundHeightMultiplier);

					if (newSize > backgroundViewMaxHeight) {
						continue;
					} else {
						backgroundFrame.size.height  = newSize;

						textBoxFrame.size.height  = _InputBoxDefaultHeight;
						textBoxFrame.size.height += (i * _InputBoxHeightMultiplier);

						break;
					}
				}
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
    [self resetTextFieldCellSize:NO];
	
	if (NSObjectIsEmpty(self.stringValue)) {
		[super sanitizeTextField:NO];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self updateTextDirection];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias:NO];
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
    
    [self resetTextFieldCellSize:NO];
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
        
        [self resetTextFieldCellSize:NO];
		[self sanitizeTextField:NO];
        
        return YES;
    }
    
    return NO;
}

@end

@implementation TVCInputTextFieldBackground

- (void)setWindowIsActive:(BOOL)value
{
	/* We set a property stating we are active instead of
	 calling our NSWindow and asking it because there are
	 times that we are going to be drawing to a focused
	 window, but it has not became visible yet. Therefore,
	 the call to NSWindow would tell us to draw an inactive
	 input box when it should be active. */
	
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
	
	if (self.windowIsActive) {
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
}

@end