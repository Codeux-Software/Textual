/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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
#define _WindowContentBorderDefaultHeight		38.0

#define _WindowSegmentedControllerDefaultX		10.0
#define _InputTextFieldOriginDefaultX			166.0

#define _KeyObservingArray 	@[	@"TextFieldAutomaticSpellCheck", \
								@"TextFieldAutomaticGrammarCheck", \
								@"TextFieldAutomaticSpellCorrection", \
								@"TextFieldSmartCopyPaste", \
								@"TextFieldSmartQuotes", \
								@"TextFieldSmartDashes", \
								@"TextFieldSmartLinks", \
								@"TextFieldDataDetectors", \
								@"TextFieldTextReplacement"]

@interface TVCInputTextField ()
@property (nonatomic, assign) NSInteger lastDrawLineCount;
@property (nonatomic, assign) TXMainTextBoxFontSize cachedFontSize;
@end

@implementation TVCInputTextField

#pragma mark -
#pragma mark Drawing

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
	
	if (self) {
		[self updateTextBoxCachedPreferredFontSize]; // Set preferred font.
		[self defineDefaultTypeSetterAttributes]; // Have parent text field inherit that.
		[self updateTypeSetterAttributes]; // --------------/

		for (NSString *key in _KeyObservingArray) {
			[RZUserDefaults() addObserver:self
							   forKeyPath:key
								  options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
								  context:NULL];
		}
    }
	
    return self;
}

- (void)dealloc
{
	for (NSString *key in _KeyObservingArray) {
		[RZUserDefaults() removeObserver:self forKeyPath:key];
	}
}

#pragma mark -
#pragma mark Events

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSWindowNegateActionWithAttachedSheet();

	[super rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSWindowNegateActionWithAttachedSheet();

	/* Don't know why control click is broken in the text field. 
	 Possibly because of how hacked together it is… anyways, this
	 is a quick fix for control click to open the right click menu. */
	if ([NSEvent modifierFlags] & NSControlKeyMask) {
		[super rightMouseDown:theEvent];

		return;
	}

	[super mouseDown:theEvent];
}

#pragma mark -
#pragma mark Segmented Controller

- (void)redrawOriginPoints
{
	NSInteger defaultSegmentX = _WindowSegmentedControllerDefaultX;
	NSInteger defaultInputbxX = _InputTextFieldOriginDefaultX;

	NSInteger resultOriginX = 0;
	NSInteger resultSizeWth = (defaultInputbxX - defaultSegmentX);
	
	if ([TPCPreferences hideMainWindowSegmentedController]) {
		[self.masterController.mainWindowButtonController setHidden:YES];

		resultOriginX = defaultSegmentX;
	} else {
		[self.masterController.mainWindowButtonController setHidden:NO];
		
		resultOriginX  = defaultInputbxX;
		resultSizeWth *= -1;
	}

	NSRect fronFrame = self.scrollView.frame;
	NSRect backFrame = self.backgroundView.frame;
	
	if (NSDissimilarObjects(resultOriginX, fronFrame.origin.x) &&
		NSDissimilarObjects(resultOriginX, backFrame.origin.x))
	{
		fronFrame.size.width += resultSizeWth;
		backFrame.size.width += resultSizeWth;
		
		fronFrame.origin.x = resultOriginX;
		backFrame.origin.x = resultOriginX;
		
		[self.scrollView setFrame:fronFrame];
		[self.backgroundView setFrame:backFrame];
	}
}

#pragma mark -
#pragma mark Everything Else.

- (void)updateTextDirection
{
	if ([TPCPreferences rightToLeftFormatting]) {
		[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
	} else {
		[self setBaseWritingDirection:NSWritingDirectionLeftToRight];
	}
}

- (void)internalTextDidChange:(NSNotification *)aNotification
{
	[self resetTextFieldCellSize:NO];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect]) {
		NSString *value = [self stringValue];
		
		if (NSObjectIsEmpty(value)) {
			if (NSDissimilarObjects([self baseWritingDirection], NSWritingDirectionRightToLeft)) {
				if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
					[self.placeholderString drawAtPoint:NSMakePoint(6, 2)];
				} else {
					[self.placeholderString drawAtPoint:NSMakePoint(6, 1)];
				}
			}
		} else {
			[super drawRect:dirtyRect];
		}
	}
}

- (void)paste:(id)sender
{
    [super paste:self];
    
    [self resetTextFieldCellSize:NO];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertNewline:)) {
		[self.masterController textEntered];
        
        [self resetTextFieldCellSize:NO];
        
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Multi-line Text Box Drawing

- (void)updateTextBoxCachedPreferredFontSize
{
	/* Update the font. */
	self.cachedFontSize = [TPCPreferences mainTextBoxFontSize];

	if (self.cachedFontSize == TXMainTextBoxFontNormalSize) {
		[self setDefaultTextFieldFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
	} else if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
		[self setDefaultTextFieldFont:[NSFont fontWithName:@"Helvetica" size:14.0]];
	} else if (self.cachedFontSize == TXMainTextBoxFontExtraLargeSize) {
		[self setDefaultTextFieldFont:[NSFont fontWithName:@"Helvetica" size:16.0]];
	}

	/* Update the placeholder string. */
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

	attrs[NSFontAttributeName] = [self defaultTextFieldFont];
	attrs[NSForegroundColorAttributeName] = [NSColor grayColor];

	self.placeholderString = nil;
	self.placeholderString = [NSAttributedString stringWithBase:TXTLS(@"InputTextFieldPlaceholderValue") attributes:attrs];

	/* Prepare draw. */
	[self setNeedsDisplay:YES];
}

- (void)updateTextBoxBasedOnPreferredFontSize
{
	TXMainTextBoxFontSize cachedFontSize = self.cachedFontSize;

	/* Update actual cache. */
	[self updateTextBoxCachedPreferredFontSize];

	/* We only update the font sizes if there was a chagne. */
	if (NSDissimilarObjects(cachedFontSize, self.cachedFontSize)) {
		[self updateAllFontSizesToMatchTheDefaultFont];
		[self updateTypeSetterAttributes];
	}

	/* Reset frames. */
	[self resetTextFieldCellSize:YES];
}

- (NSView *)splitterView
{
    return [(self.superview.superview.superview.superview.subviews)[1] subviews][0]; /* Yeah, this is bad… I know! */
}

- (TVCInputTextFieldBackground *)backgroundView
{
	return (self.superview.superview.superview.subviews)[0]; /* This one is not so bad. */
}

/* It is easier for us to define predetermined values for these paramaters instead
 of trying to overcomplicate our math by calculating the point height of our font
 and other variables. We only support three text sizes so why not hard code? */
- (NSInteger)backgroundViewMaximumHeight
{
	return (self.window.frame.size.height - 50);
}

- (NSInteger)backgroundViewDefaultHeight
{
	if (self.cachedFontSize == TXMainTextBoxFontNormalSize) {
		return 23.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
		return 28.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontExtraLargeSize) {
		return 30.0;
	}
	
	return 23.0;
}

- (NSInteger)backgroundViewHeightMultiplier
{
	if (self.cachedFontSize == TXMainTextBoxFontNormalSize) {
		return 14.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
		return 17.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontExtraLargeSize) {
		return 19.0;
	}

	return 14.0;
}

- (NSInteger)textBoxDefaultHeight
{
	if (self.cachedFontSize == TXMainTextBoxFontNormalSize) {
		return 18.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
		return 22.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontExtraLargeSize) {
		return 24.0;
	}

	return 18.0;
}

- (NSInteger)textBoxHeightMultiplier
{
	if (self.cachedFontSize == TXMainTextBoxFontNormalSize) {
		return 14.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontLargeSize) {
		return 17.0;
	} else if (self.cachedFontSize == TXMainTextBoxFontExtraLargeSize) {
		return 19.0;
	}

	return 14.0;
}

/* Do actual size math. */
- (void)resetTextFieldCellSize:(BOOL)force
{
	BOOL drawBezel = YES;

	NSWindow *mainWindow = self.window;

	NSView *superView = [self splitterView];
	NSView *background = [self backgroundView];

    NSScrollView *scroller = [self scrollView];

	NSRect textBoxFrame = scroller.frame;
	NSRect superViewFrame = superView.frame;
	NSRect mainWindowFrame = mainWindow.frame;
	NSRect backgroundFrame = background.frame;

	NSInteger contentBorder;

	NSInteger inputBoxDefaultHeight = [self textBoxDefaultHeight];
	NSInteger inputBoxBackgroundDefaultHeight = [self backgroundViewDefaultHeight];

	NSString *stringv = self.stringValue;

	if (stringv.length < 1) {
		textBoxFrame.size.height    = inputBoxDefaultHeight;
		backgroundFrame.size.height = inputBoxBackgroundDefaultHeight;

		if (self.lastDrawLineCount >= 2) {
			drawBezel = YES;
		}

		self.lastDrawLineCount = 1;
	} else {
		NSInteger totalLinesBase = [self numberOfLines];

		if (self.lastDrawLineCount == totalLinesBase && force == NO) {
			drawBezel = NO;
		}

		self.lastDrawLineCount = totalLinesBase;

		if (drawBezel) {
			NSInteger totalLinesMath = (totalLinesBase - 1);

			NSInteger inputBoxHeightMultiplier = [self textBoxHeightMultiplier];
			NSInteger inputBoxBackgroundHeightMultiplier = [self backgroundViewHeightMultiplier];

			/* Calculate unfiltered height. */
			textBoxFrame.size.height    = inputBoxDefaultHeight;
			backgroundFrame.size.height	= inputBoxBackgroundDefaultHeight;

			textBoxFrame.size.height    += (totalLinesMath * inputBoxHeightMultiplier);
			backgroundFrame.size.height += (totalLinesMath * inputBoxBackgroundHeightMultiplier);

			NSInteger backgroundViewMaxHeight = [self backgroundViewMaximumHeight];

			/* Fix height if it exceeds are maximum. */
			if (backgroundFrame.size.height > backgroundViewMaxHeight) {
				for (NSInteger i = totalLinesMath; i >= 0; i--) {
					NSInteger newSize = 0;

					newSize  =      inputBoxBackgroundDefaultHeight;
					newSize += (i * inputBoxBackgroundHeightMultiplier);

					if (newSize > backgroundViewMaxHeight) {
						continue;
					} else {
						backgroundFrame.size.height = newSize;

						textBoxFrame.size.height  =      inputBoxDefaultHeight;
						textBoxFrame.size.height += (i * inputBoxHeightMultiplier);

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

		[scroller setFrame:textBoxFrame];
		[superView setFrame:superViewFrame];
		[background setFrame:backgroundFrame];
	}
}

#pragma mark -
#pragma mark NSTextView Context Menu Preferences

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticSpellCheck"]) {
		[self setContinuousSpellCheckingEnabled:[TPCPreferences textFieldAutomaticSpellCheck]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticGrammarCheck"]) {
		[self setGrammarCheckingEnabled:[TPCPreferences textFieldAutomaticGrammarCheck]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticSpellCorrection"]) {
		[self setAutomaticSpellingCorrectionEnabled:[TPCPreferences textFieldAutomaticSpellCorrection]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartCopyPaste"]) {
		[self setSmartInsertDeleteEnabled:[TPCPreferences textFieldSmartCopyPaste]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartQuotes"]) {
		[self setAutomaticQuoteSubstitutionEnabled:[TPCPreferences textFieldSmartQuotes]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartDashes"]) {
		[self setAutomaticDashSubstitutionEnabled:[TPCPreferences textFieldSmartDashes]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartLinks"]) {
		[self setAutomaticLinkDetectionEnabled:[TPCPreferences textFieldSmartLinks]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldDataDetectors"]) {
		[self setAutomaticDataDetectionEnabled:[TPCPreferences textFieldDataDetectors]];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldTextReplacement"]) {
		[self setAutomaticTextReplacementEnabled:[TPCPreferences textFieldTextReplacement]];
	} else if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setContinuousSpellCheckingEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldAutomaticSpellCheck:flag];
	
	[super setContinuousSpellCheckingEnabled:flag];
}

- (void)setGrammarCheckingEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldAutomaticGrammarCheck:flag];
	
	[super setGrammarCheckingEnabled:flag];
}

- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldAutomaticSpellCorrection:flag];
	
	[super setAutomaticSpellingCorrectionEnabled:flag];
}

- (void)setSmartInsertDeleteEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldSmartCopyPaste:flag];
	
	[super setSmartInsertDeleteEnabled:flag];
}

- (void)setAutomaticQuoteSubstitutionEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldSmartQuotes:flag];
	
	[super setAutomaticQuoteSubstitutionEnabled:flag];
}

- (void)setAutomaticDashSubstitutionEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldSmartDashes:flag];
	
	[super setAutomaticDashSubstitutionEnabled:flag];
}

- (void)setAutomaticLinkDetectionEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldSmartLinks:flag];
	
	[super setAutomaticLinkDetectionEnabled:flag];
}

- (void)setAutomaticDataDetectionEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldDataDetectors:flag];
	
	[super setAutomaticDataDetectionEnabled:flag];
}

- (void)setAutomaticTextReplacementEnabled:(BOOL)flag
{
	[TPCPreferences setTextFieldTextReplacement:flag];
	
	[super setAutomaticTextReplacementEnabled:flag];
}

@end

#pragma mark -
#pragma mark Background Drawing

@implementation TVCInputTextFieldBackground

- (NSColor *)inputFieldBackgroundColor
{
	return [NSColor whiteColor];
}

- (NSColor *)inputFieldInsideShadowColor
{
	return [NSColor colorWithCalibratedWhite:0.88 alpha:1.0];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect]) {
		NSRect cellBounds = self.frame;
		NSRect controlFrame;
		
		NSColor *controlColor;
		
		NSBezierPath *controlPath;
		
		/* Control Outside White Shadow. */
		controlColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.394];
		controlFrame = NSMakeRect(0.0, 0.0, cellBounds.size.width, 1.0);
		controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];
		
		[controlColor set];
		[controlPath fill];
		
		/* Black Outline. */
		if (self.masterController.mainWindowIsActive) {
			controlColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.4];
		} else {
			controlColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.23];
		}
		
		controlFrame = NSMakeRect(0.0, 1.0, cellBounds.size.width, (cellBounds.size.height - 1.0));
		controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];
		
		[controlColor set];
		[controlPath fill];
		
		/* White Background. */
		controlColor = [self inputFieldBackgroundColor];
		controlFrame = NSMakeRect(1, 2, (cellBounds.size.width - 2.0), (cellBounds.size.height - 4.0));
		controlPath	= [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.6 yRadius:2.6];
		
		[controlColor set];
		[controlPath fill];
		
		/* Inside White Shadow. */
		controlColor = [self inputFieldInsideShadowColor];
		controlFrame = NSMakeRect(2, (cellBounds.size.height - 2.0), (cellBounds.size.width - 4.0), 1.0);
		controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.9 yRadius:2.9];
		
		[controlColor set];
		[controlPath fill];
	}
}

@end
