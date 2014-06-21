/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define _WindowContentBorderTotalPadding		14.0

#define _WindowSegmentedControllerDefaultWidth	150.0
#define _WindowSegmentedControllerLeadingEdge	10.0

#define _WindowContentViewMinimumHeightConstraint		35.0

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

@interface TVCMainWindowTextView ()
@property (nonatomic, assign) NSInteger lastDrawLineCount;
@property (nonatomic, assign) TVCMainWindowTextViewFontSize cachedFontSize;
@end

@implementation TVCMainWindowTextView

#pragma mark -
#pragma mark Drawing

- (void)awakeFromNib
{
	/* Observe certain keys. */
	for (NSString *key in _KeyObservingArray) {
		[RZUserDefaults() addObserver:self
						   forKeyPath:key
							  options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
							  context:NULL];
	}
	
	/* Blending background. */
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		/* Comment out a specific variation for debugging purposes. */
		/* The uncommented sections are the defaults. */
		/* nil value indicates that the value is inherited. */
		[_contentView setAppearance:nil];
		
		/* Uncomment one of the following. */
		/* 1. */
		// [_contentView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		
		/* 2. */
		// [_contentView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
		
		/* Use font color depending on appearance. */
		[self setPreferredFontColor:[_backgroundView systemSpecificPlaceholderTextFontColor]];
	}
	
	/* We changed the font color so we must inform our parent. */
	[self updateTypeSetterAttributesBasedOnAppearanceSettings];
}

- (void)dealloc
{
	/* Stop observing keys. */
	for (NSString *key in _KeyObservingArray) {
		[RZUserDefaults() removeObserver:self forKeyPath:key];
	}
}

- (void)updateTypeSetterAttributesBasedOnAppearanceSettings
{
	/* Set all type attributes. */
	[self updateTextBoxCachedPreferredFontSize];
	[self defineDefaultTypeSetterAttributes];
	[self updateTypeSetterAttributes];
}

#pragma mark -
#pragma mark Events

- (void)rightMouseDown:(NSEvent *)theEvent
{
	/* Do not pass mouse events with sheet open. */
	TVCMainWindowNegateActionWithAttachedSheet();

	/* Pass event. */
	[super rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	/* Do not pass mouse events with sheet open. */
	TVCMainWindowNegateActionWithAttachedSheet();

	/* Don't know why control click is broken in the text field. 
	 Possibly because of how hacked together it is… anyways, this
	 is a quick fix for control click to open the right click menu. */
	if ([NSEvent modifierFlags] & NSControlKeyMask) {
		[super rightMouseDown:theEvent];

		return;
	}
	
	/* Pass event. */
	[super mouseDown:theEvent];
}

#pragma mark -
#pragma mark Segmented Controller

- (void)redrawOriginPoints
{
	[self redrawOriginPoints:NO];
}

- (void)redrawOriginPoints:(BOOL)resetSize
{
	/* Discussion: With Auto Layout, the frame of a view is still retained even if the view
	 itself is hidden from view. The solution is to maintain a constraint for the view height
	 and update it using a pre-defined width or set it to zero when disabled. A constraint
	 is also maintained for the leading of the segmented controller to allow that spacing to 
	 be removed when it is hidden from view. */
	if ([TPCPreferences hideMainWindowSegmentedController]) {
		[_segmentedControllerWidthConstraint setConstant:0];
		[_segmentedControllerLeadingConstraint setConstant:0];
	} else {
		[_segmentedControllerWidthConstraint setConstant:_WindowSegmentedControllerDefaultWidth];
		[_segmentedControllerLeadingConstraint setConstant:_WindowSegmentedControllerLeadingEdge];
	}
	
	/* There seems to be a slight delay while the constraints are updated
	 so we set a very small timer to resize the text field. */
	if (resetSize) {
		[self performSelector:@selector(resetTextFieldCellSize:) withObject:@(YES) afterDelay:0.1];
	}
}

- (void)reloadSegmentedControllerOrigin
{
	[self redrawOriginPoints:YES];
}

- (void)updateSegmentedController
{
	if ([TPCPreferences hideMainWindowSegmentedController] == NO) {
		/* Enable controller? */
		BOOL condition1 = ([worldController() clientCount] > 0);
		
		BOOL condition2 = ([mainWindowLoadingScreen() viewIsVisible] == NO);
		
		[_segmentedController setEnabled:(condition1 && condition2)];
		
		/* Selection Settings. */
		IRCClient *u = [worldController() selectedClient];
		IRCChannel *c = [worldController() selectedChannel];

		/* Segment 0 menu. */
		[_segmentedController setMenu:[menuController() segmentedControllerMenu] forSegment:0];
		
		/* Set menu for segment 1. */
		NSMenuItem *segmentOneMenuItem;
		
		if (c == nil) {
			segmentOneMenuItem = [menuController() serverMenuItem];
		} else {
			segmentOneMenuItem = [menuController() channelMenuItem];
		}
		
		[_segmentedController setMenu:[segmentOneMenuItem submenu] forSegment:1];
		
		/* Open Address Book. */
		[_segmentedController setEnabled:(u && [u isConnected]) forSegment:2];
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
		
		if ([value length] == 0) {
			if ([self baseWritingDirection] == NSWritingDirectionLeftToRight) {
				if (_cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
					[_placeholderString drawAtPoint:NSMakePoint(6, 2)];
				} else {
					[_placeholderString drawAtPoint:NSMakePoint(6, 1)];
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
		/* -textEntered takes the current value of the text field,
		 copies it into a variable, sends that value off to IRCWorld,
		 then nullifies the text field itsef. */
		[mainWindow() textEntered];
		
		/* -textEntered sets the length of text fied to 0 so we must
		 update the text field size to reflect this fact. */
        [self resetTextFieldCellSize:NO];
		
		/* Let delegate know we handled this event. */
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Multi-line Text Box Drawing

- (NSColor *)placeholderTextFontColor
{
	return [_backgroundView systemSpecificPlaceholderTextFontColor];
}

- (void)updateTextBoxCachedPreferredFontSize
{
	/* Update the font. */
	_cachedFontSize = [TPCPreferences mainTextViewFontSize];

	if (_cachedFontSize == TVCMainWindowTextViewFontNormalSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
	} else if (_cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:14.0]];
	} else if (_cachedFontSize == TVCMainWindowTextViewFontExtraLargeSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:16.0]];
	}

	/* Update the placeholder string. */
	NSDictionary *attrs = @{
		NSFontAttributeName				: [self preferredFont],
		NSForegroundColorAttributeName	: [self placeholderTextFontColor]
	};
	
	_placeholderString = nil;
	_placeholderString = [NSAttributedString stringWithBase:TXTLS(@"TDCMainWindow[1000]") attributes:attrs];

	/* Prepare draw. */
	[self setNeedsDisplay:YES];
}

- (void)updateTextBoxBasedOnPreferredFontSize
{
	TVCMainWindowTextViewFontSize cachedFontSize = _cachedFontSize;

	/* Update actual cache. */
	[self updateTextBoxCachedPreferredFontSize];

	/* We only update the font sizes if there was a chagne. */
	if (NSDissimilarObjects(cachedFontSize, _cachedFontSize)) {
		[self updateAllFontSizesToMatchTheDefaultFont];
		[self updateTypeSetterAttributes];
	}

	/* Reset frames. */
	[self resetTextFieldCellSize:YES];
}

- (NSInteger)backgroundViewDefaultHeight
{
	if (_cachedFontSize == TVCMainWindowTextViewFontNormalSize) {
		return 23.0;
	} else if (_cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
		return 27.0;
	} else if (_cachedFontSize == TVCMainWindowTextViewFontExtraLargeSize) {
		return 28.0;
	}
	
	return 23.0;
}

- (NSInteger)backgroundViewHeightMultiplier
{
	if (_cachedFontSize == TVCMainWindowTextViewFontNormalSize) {
		return 14.0;
	} else if (_cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
		return 17.0;
	} else if (_cachedFontSize == TVCMainWindowTextViewFontExtraLargeSize) {
		return 19.0;
	}

	return 14.0;
}

/* Do actual size math. */
- (void)resetTextFieldCellSize:(BOOL)force
{
	BOOL drawBezel = YES;

	/* Get window data. */
	NSWindow *mainWindow = mainWindow();
	
	NSRect windowFrame = [mainWindow frame];
	
	/* Get scroller data. */
	NSScrollView *scrollView = [self enclosingScrollView];
	
	id scrollViewDocumentView = [scrollView contentView];
	
	NSRect documentViewBounds = [scrollViewDocumentView bounds];

	/* Set defaults. */
	NSInteger backgroundHeight;
	
	NSInteger backgroundDefaultHeight = [self backgroundViewDefaultHeight];
	NSInteger backgroundHeightMultiplier = [self backgroundViewHeightMultiplier];

	NSString *stringv = [self stringValue];

	/* Begin works… */
	if ([stringv length] < 1) {
		backgroundHeight = (backgroundDefaultHeight + _WindowContentBorderTotalPadding);

		if (_lastDrawLineCount > 1 || force) {
			drawBezel = YES;
		}

		_lastDrawLineCount = 1;
	} else {
		NSInteger totalLinesBase = [self numberOfLines];

		if (_lastDrawLineCount == totalLinesBase && force == NO) {
			drawBezel = NO;
		}

		_lastDrawLineCount = totalLinesBase;

		if (drawBezel) {
			NSInteger totalLinesMath = (totalLinesBase - 1);
	
			/* Calculate unfiltered height. */
			backgroundHeight  = _WindowContentBorderTotalPadding;
			
			backgroundHeight +=  backgroundDefaultHeight;
			backgroundHeight += (backgroundHeightMultiplier * totalLinesMath);

			NSInteger backgroundViewMaxHeight = (windowFrame.size.height - (_WindowContentViewMinimumHeightConstraint + _WindowContentBorderTotalPadding));

			/* Fix height if it exceeds are maximum. */
			if (backgroundHeight > backgroundViewMaxHeight) {
				for (NSInteger i = totalLinesMath; i >= 0; i--) {
					NSInteger newSize = 0;
					
					newSize  = _WindowContentBorderTotalPadding;
					
					newSize +=      backgroundDefaultHeight;
					newSize += (i * backgroundHeightMultiplier);

					if (newSize > backgroundViewMaxHeight) {
						continue;
					} else {
						backgroundHeight = newSize;

						break;
					}
				}
			}
		}
	}

	if (drawBezel) {
		if ([CSFWSystemInformation featureAvailableToOSXYosemite] == NO) {
			[mainWindow setContentBorderThickness:backgroundHeight forEdge:NSMinYEdge];
		}

		[_textFieldHeightConstraint setConstant:backgroundHeight];
		
		if (documentViewBounds.origin.x > 0) {
			documentViewBounds.origin.x = 0;
			
			[scrollViewDocumentView scrollToPoint:documentViewBounds.origin];
		}
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

@implementation TVCMainWindowTextViewBackground

#pragma mark -
#pragma mark Mavericks UI Drawing

- (NSColor *)inputTextFieldBlackOutlineColorMavericks
{
	if ([self windowIsActive]) {
		return [NSColor colorWithCalibratedWhite:0.0 alpha:0.4];
	} else {
		return [NSColor colorWithCalibratedWhite:0.0 alpha:0.23];
	}
}

- (NSColor *)inputTextFieldBackgroundColorMavericks
{
	return [NSColor whiteColor];
}

- (NSColor *)inputTextFieldInsideShadowColorMavericks
{
	return [NSColor colorWithCalibratedWhite:0.88 alpha:1.0];
}

- (NSColor *)inputTextFieldOutsideWhiteShadowColorMavericks
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:0.394];
}

- (NSColor *)inputTextFieldPlaceholderTextColorMavericks
{
	return [NSColor grayColor];
}

- (NSColor *)inputTextFieldPrimaryTextColorMavericks
{
	return TXPreferredGlobalTextFieldFontColor;
}

- (void)drawControllerForMavericks
{
	/* General Declarations. */
	NSRect cellBounds = [self frame];
	NSRect controlFrame;

	NSColor *controlColor;

	NSBezierPath *controlPath;

	/* Control Outside White Shadow. */
	controlColor = [self inputTextFieldOutsideWhiteShadowColorMavericks];
	controlFrame = NSMakeRect(0.0, 0.0, cellBounds.size.width, 1.0);
	controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];

	[controlColor set];
	[controlPath fill];

	/* Black Outline. */
	controlColor = [self inputTextFieldBlackOutlineColorMavericks];
	controlFrame = NSMakeRect(0.0, 1.0, cellBounds.size.width, (cellBounds.size.height - 1.0));
	controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.6 yRadius:3.6];

	[controlColor set];
	[controlPath fill];

	/* White Background. */
	controlColor = [self inputTextFieldBackgroundColorMavericks];
	controlFrame = NSMakeRect(1, 2, (cellBounds.size.width - 2.0), (cellBounds.size.height - 4.0));
	controlPath	= [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.6 yRadius:2.6];

	[controlColor set];
	[controlPath fill];

	/* Inside White Shadow. */
	controlColor = [self inputTextFieldInsideShadowColorMavericks];
	controlFrame = NSMakeRect(2, (cellBounds.size.height - 2.0), (cellBounds.size.width - 4.0), 1.0);
	controlPath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:2.9 yRadius:2.9];

	[controlColor set];
	[controlPath fill];
}

#pragma mark -
#pragma mark Yosemite UI Drawing

- (NSColor *)blackInputTextFieldPlaceholderTextColorYosemite
{
	/* Cannot be exactly white or it will interfere with text formatting engine for IRC. */

	return [NSColor colorWithCalibratedWhite:0.99 alpha:1.0];
}

- (NSColor *)whiteInputTextFieldPlaceholderTextColorYosemite
{
	return TXPreferredGlobalTextFieldFontColor;
}

- (NSColor *)blackInputTextFieldPrimaryTextColorYosemite
{
	return [NSColor colorWithCalibratedRed:0.660 green:0.660 blue:0.660 alpha:1.0];
}

- (NSColor *)whiteInputTextFieldPrimaryTextColorYosemite
{
	return [NSColor grayColor];
}

- (NSColor *)blackInputTextFieldInsideBlackBackgroundColorYosemite
{
	return [NSColor colorWithCalibratedRed:0.386 green:0.386 blue:0.386 alpha:1.0];
}

- (NSColor *)blackInputTextFieldOutsideBottomGrayShadowColorWithRetinaYosemite
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.15];
}

- (NSColor *)blackInputTextFieldOutsideBottomGrayShadowColorWithoutRetinaYosemite
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.10];
}

- (NSColor *)whiteInputTextFieldOutsideTopsideWhiteBorderYosemite
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

- (NSColor *)whiteInputTextFieldInsideWhiteGradientStartColorYosemite
{
	return [NSColor colorWithCalibratedRed:0.992 green:0.992 blue:0.992 alpha:1.0];
}

- (NSColor *)whiteInputTextFieldInsideWhiteGradientEndColorYosemite
{
	return [NSColor colorWithCalibratedRed:0.988 green:0.988 blue:0.988 alpha:1.0];
}

- (NSGradient *)whiteInputTextFieldInsideWhiteGradientYosemite
{
	return [NSGradient gradientWithStartingColor:[self whiteInputTextFieldInsideWhiteGradientStartColorYosemite]
									 endingColor:[self whiteInputTextFieldInsideWhiteGradientEndColorYosemite]];
}

- (NSColor *)whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithRetinaYosemite
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.15];
}

- (NSColor *)whiteInputTextFieldOutsideBottomSecondaryGrayShadowColorWithRetinaYosemite
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.06];
}

- (NSColor *)whiteInputTextFieldOutsideBottomGrayShadowColorWithoutRetinaYosemite
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.10];
}

- (void)drawControllerForYosemite
{
	if ([_contentView yosemiteIsUsingVibrantDarkMode]) {
		[self drawBlackControllerForYosemiteInFocusedWindow];
	} else {
		[self drawWhiteControllerForYosemiteInFocusedWindow];
	}
}

- (void)drawBlackControllerForYosemiteInFocusedWindow
{
	/* General Declarations. */
	NSRect cellBounds = [self frame];
	
	BOOL inHighresMode = [mainWindow() runningInHighResolutionMode];
	
	NSRect controlFrame = NSMakeRect(1, 1,  (cellBounds.size.width - 2.0),
											(cellBounds.size.height - 2.0));

	/* Inner background color. */
	NSColor *background = [self blackInputTextFieldInsideBlackBackgroundColorYosemite];
	
	/* Shadow colors. */
	NSShadow *shadow4 = [NSShadow new];
	
	if (inHighresMode) {
		[shadow4 setShadowColor:[self blackInputTextFieldOutsideBottomGrayShadowColorWithRetinaYosemite]];
	} else {
		[shadow4 setShadowColor:[self blackInputTextFieldOutsideBottomGrayShadowColorWithoutRetinaYosemite]];
	}
	
	[shadow4 setShadowOffset:NSMakeSize(0.1, -1.1)];
	[shadow4 setShadowBlurRadius:0.0];
	
	/* Rectangle drawing. */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.0 yRadius:3.0];
	
	[NSGraphicsContext saveGraphicsState];
	
	/* Draw shadow. */
	[shadow4 set];
	
	/* Draw background. */
	[background setFill];
	
	/* Draw rectangle. */
	[rectanglePath fill];
	
	/* Finish up. */
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawWhiteControllerForYosemiteInFocusedWindow
{
	/* General Declarations. */
	NSRect cellBounds = [self frame];

	CGContextRef context = [RZGraphicsCurrentContext() graphicsPort];

	BOOL inHighresMode = [mainWindow() runningInHighResolutionMode];

	NSRect controlFrame = NSMakeRect(1, 1,  (cellBounds.size.width - 2.0),
											(cellBounds.size.height - 2.0));
	
	/* Inner gradient color. */
	NSGradient *gradient = [self whiteInputTextFieldInsideWhiteGradientYosemite];

	/* Shadow colors. */
	NSShadow *shadow3 = [NSShadow new];
	NSShadow *shadow4 = [NSShadow new];

	[shadow3 setShadowColor:[self whiteInputTextFieldOutsideTopsideWhiteBorderYosemite]];
	[shadow3 setShadowOffset:NSMakeSize(0.1, -1.1)];
	[shadow3 setShadowBlurRadius:0.0];

	if (inHighresMode) {
		[shadow4 setShadowColor:[self whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithRetinaYosemite]];
		[shadow4 setShadowOffset:NSMakeSize(0.1, -0.5)];
		[shadow4 setShadowBlurRadius:0.0];
	} else {
		[shadow4 setShadowColor:[self whiteInputTextFieldOutsideBottomGrayShadowColorWithoutRetinaYosemite]];
		[shadow4 setShadowOffset:NSMakeSize(0.1, -1.1)];
		[shadow4 setShadowBlurRadius:0.0];
	}

	/* Rectangle drawing. */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.0 yRadius:3.0];

	[shadow4 set];

	CGContextBeginTransparencyLayer(context, NULL);

	[gradient drawInBezierPath:rectanglePath angle:-(90)];

	CGContextEndTransparencyLayer(context);

	/* Prepare drawing for inside shadow. */
	CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);

	CGContextSetAlpha(context, [[shadow3 shadowColor] alphaComponent]);

	CGContextBeginTransparencyLayer(context, NULL);
	{
		/* Inside shadow drawing. */
		[shadow3 set];

		CGContextSetBlendMode(context, kCGBlendModeSourceOut);

		CGContextBeginTransparencyLayer(context, NULL);

		/* Fill shadow. */
		[[shadow3 shadowColor] setFill];

		[rectanglePath fill];

		/* Complete drawing. */
		CGContextEndTransparencyLayer(context);
	}

	CGContextEndTransparencyLayer(context);

	/* On retina, we fake a second shadow under the bottommost one. */
	if (inHighresMode) {
		NSPoint linePoint1 = NSMakePoint(4.0, 0.0);
		NSPoint linePoint2 = NSMakePoint((cellBounds.size.width - 4.0), 0.0);

		NSColor *controlColor = [self whiteInputTextFieldOutsideBottomSecondaryGrayShadowColorWithRetinaYosemite];

		[controlColor setStroke];

		[NSBezierPath strokeLineFromPoint:linePoint1 toPoint:linePoint2];
	}
}

#pragma mark -
#pragma mark Drawing Factory

- (NSColor *)systemSpecificTextFieldTextFontColor
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([_contentView yosemiteIsUsingVibrantDarkMode]) {
			return [self blackInputTextFieldPlaceholderTextColorYosemite];
		} else {
			return [self whiteInputTextFieldPlaceholderTextColorYosemite];
		}
	} else {
		return [self inputTextFieldPlaceholderTextColorMavericks];
	}
}

- (NSColor *)systemSpecificPlaceholderTextFontColor
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([_contentView yosemiteIsUsingVibrantDarkMode]) {
			return [self blackInputTextFieldPrimaryTextColorYosemite];
		} else {
			return [self whiteInputTextFieldPrimaryTextColorYosemite];
		}
	} else {
		return [self inputTextFieldPrimaryTextColorMavericks];
	}
}

- (BOOL)windowIsActive
{
	return ([mainWindow() isInactive] == NO);
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect]) {
		if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
			[self drawControllerForYosemite];
		} else {
			[self drawControllerForMavericks];
		}
	}
}

@end

#pragma mark -
#pragma mark Text Field Background Vibrant View

@implementation TVCMainWindowTextViewContentView

- (BOOL)yosemiteIsUsingVibrantDarkMode
{
	NSAppearance *currentDesign = [self appearance];
	
	NSString *name = [currentDesign name];
	
	if ([name hasPrefix:NSAppearanceNameVibrantDark]) {
		return YES;
	} else {
		return NO;
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect]) {
		/* Draw background color. */
		NSColor *drawColor = [self backgroundColor];
		
		[drawColor set];
		
		NSRectFill(dirtyRect);
		
		/* Draw divider. */
		NSRect contentViewFrame = [self frame];
		
		contentViewFrame.origin.x = 0;
		contentViewFrame.origin.y = (NSMaxY(contentViewFrame) - 1);
		
		contentViewFrame.size.height = 1;
		
		NSBezierPath *dividerPath = [NSBezierPath bezierPathWithRect:contentViewFrame];
		
		drawColor = [self dividerColor];
		
		[drawColor set];
		
		[dividerPath fill];
		
		/* Discussion: On Yosemite, when a segmented controller is set as vibrant dark,
		 it inherits whatever color is behind it in a translucent manor. To allow for
		 a darker controller in Textual, we set the background of ours to black. To
		 achive this, we create a bezier path that replicate the frame of segmented
		 controller. This is a very ugly hack and can break easily in an OS update. */
		if ([TPCPreferences hideMainWindowSegmentedController] == NO) {
			if ([self yosemiteIsUsingVibrantDarkMode]) {
				/* Get controller and controller frame. */
				TVCMainWindowSegmentedController *controller = [mainWindowTextField() segmentedController];
				
				NSRect controllerFrame = [controller frame];
				
				/* Update frame with some magic numbers. */
				controllerFrame.size.width -= 4;
				controllerFrame.size.height -= 3;
				
				controllerFrame.origin.y += 2;
				
				/* Define new path and color. */
				dividerPath  = [NSBezierPath bezierPathWithRoundedRect:controllerFrame xRadius:4.0 yRadius:4.0];
				
				drawColor = [NSColor blackColor];
				
				/* Complete draw. */
				[drawColor set];
				
				[dividerPath fill];
			}
		}
	}
}

- (NSColor *)backgroundColor
{
	if ([self yosemiteIsUsingVibrantDarkMode]) {
		return [self vibrantDarkBackgroundColor];
	} else {
		return [self vibrantLightBackgroundColor];
	}
}

- (NSColor *)dividerColor
{
	if ([self yosemiteIsUsingVibrantDarkMode]) {
		return [self vibrantDarkDividerColor];
	} else {
		return [self vibrantLightDividerColor];
	}
}

- (NSColor *)vibrantDarkBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.248 green:0.248 blue:0.248 alpha:1.0];
}

- (NSColor *)vibrantLightBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.957 green:0.957 blue:0.957 alpha:1.0];
}

- (NSColor *)vibrantDarkDividerColor
{
	return [NSColor colorWithCalibratedRed:0.150 green:0.150 blue:0.150 alpha:1.0];
}

- (NSColor *)vibrantLightDividerColor
{
	return [NSColor lightGrayColor];
}

- (BOOL)allowsVibrancy
{
	return NO;
}

@end
