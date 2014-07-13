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

#define _WindowContentBorderTotalPaddingYosemite		23.0
#define _WindowContentBorderTotalPaddingMavericks		23.0

#define _WindowSegmentedControllerDefaultWidth			150.0

#define _WindowSegmentedControllerLeadingVisibleEdge	10.0
#define _WindowSegmentedControllerLeadingHiddenEdge		0.0

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

- (void)updateBackgroundColor
{
	/* Set background appearance. */
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([TPCPreferences invertSidebarColors]) {
			[self.contentView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		} else {
			[self.contentView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
		}
	}
	
	/* Use font color depending on appearance. */
	[self setPreferredFontColor:[self.backgroundView systemSpecificTextFieldTextFontColor]];
	
	/* We changed the font color so we must inform our parent. */
	[self updateTypeSetterAttributesBasedOnAppearanceSettings];
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
		[self.segmentedControllerWidthConstraint setConstant:0];
		[self.segmentedControllerLeadingConstraint setConstant:_WindowSegmentedControllerLeadingHiddenEdge];
	} else {
		[self.segmentedControllerWidthConstraint setConstant:_WindowSegmentedControllerDefaultWidth];
		[self.segmentedControllerLeadingConstraint setConstant:_WindowSegmentedControllerLeadingVisibleEdge];
	}
	
	/* There seems to be a slight delay while the constraints are updated
	 so we set a very small timer to resize the text field. */
	if (resetSize) {
		[self performSelector:@selector(resetTextFieldCellSize:) withObject:@(YES) afterDelay:1.0];
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
		
		[self.segmentedController setEnabled:(condition1 && condition2)];
		
		/* Selection Settings. */
		IRCClient *u = [mainWindow() selectedClient];
		IRCChannel *c = [mainWindow() selectedChannel];

		/* Segment 0 menu. */
		[self.segmentedController setMenu:[menuController() segmentedControllerMenu] forSegment:0];
		
		/* Set menu for segment 1. */
		NSMenuItem *segmentOneMenuItem;
		
		if (c == nil) {
			segmentOneMenuItem = [menuController() serverMenuItem];
		} else {
			segmentOneMenuItem = [menuController() channelMenuItem];
		}
		
		[self.segmentedController setMenu:[segmentOneMenuItem submenu] forSegment:1];
		
		/* Open Address Book. */
		[self.segmentedController setEnabled:(u && [u isConnected]) forSegment:2];
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
				if (self.cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
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
	return [self.backgroundView systemSpecificPlaceholderTextFontColor];
}

- (void)updateTextBoxCachedPreferredFontSize
{
	/* Update the font. */
	self.cachedFontSize = [TPCPreferences mainTextViewFontSize];

	if (self.cachedFontSize == TVCMainWindowTextViewFontNormalSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:14.0]];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontExtraLargeSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:16.0]];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontHumongousSize) {
		[self setPreferredFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
	}

	/* Update the placeholder string. */
	NSDictionary *attrs = @{
		NSFontAttributeName				: [self preferredFont],
		NSForegroundColorAttributeName	: [self placeholderTextFontColor]
	};
	
	self.placeholderString = nil;
	self.placeholderString = [NSAttributedString stringWithBase:TXTLS(@"TDCMainWindow[1000]") attributes:attrs];

	/* Prepare draw. */
	[self setNeedsDisplay:YES];
}

- (void)updateTextBoxBasedOnPreferredFontSize
{
	TVCMainWindowTextViewFontSize cachedFontSize = self.cachedFontSize;

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

- (NSInteger)backgroundViewDefaultHeight
{
	return [[self layoutManager] defaultLineHeightForFont:self.preferredFont];
}

/* Do actual size math. */
- (void)resetTextFieldCellSize:(BOOL)force
{
	/* Get window data. */
	NSWindow *mainWindow = mainWindow();
	
	NSRect windowFrame = [mainWindow frame];
	
	/* Get scroller data. */
	NSScrollView *scrollView = [self enclosingScrollView];
	
	id scrollViewDocumentView = [scrollView contentView];
	
	NSRect documentViewBounds = [scrollViewDocumentView bounds];
	
	/* Content border padding. */
	NSInteger contentBorderPadding = 0;
	
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		contentBorderPadding = _WindowContentBorderTotalPaddingYosemite;
	} else {
		contentBorderPadding = _WindowContentBorderTotalPaddingMavericks;
	}

	/* Set defaults. */
	NSInteger backgroundHeight;
	
	NSInteger backgroundDefaultHeight = [self backgroundViewDefaultHeight];

	/* Begin works… */
	if ([self stringLength] < 1) {
		backgroundHeight = (backgroundDefaultHeight + contentBorderPadding);
	} else {
		NSInteger backgroundViewMaxHeight = (windowFrame.size.height - (_WindowContentViewMinimumHeightConstraint + contentBorderPadding));
		
		backgroundHeight = [self highestHeightBelowHeight:backgroundViewMaxHeight withPadding:contentBorderPadding];
	}

	if ([CSFWSystemInformation featureAvailableToOSXYosemite] == NO) {
		[mainWindow setContentBorderThickness:backgroundHeight forEdge:NSMinYEdge];
	}

	[self.textFieldHeightConstraint setConstant:backgroundHeight];
	
	if (documentViewBounds.origin.x > 0) {
		documentViewBounds.origin.x = 0;
		
		[scrollViewDocumentView scrollToPoint:documentViewBounds.origin];
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

- (NSColor *)inputTextFieldOutlineColorMavericks
{
	if ([self windowIsActive]) {
		return [NSColor colorWithCalibratedWhite:0.0 alpha:0.42];
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
	if ([self windowIsActive]) {
		return [NSColor colorWithCalibratedWhite:0.88 alpha:1.0];
	} else {
		return [NSColor clearColor];
	}
}

- (NSColor *)inputTextFieldOutsideShadowColorMavericks
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:0.70];
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
	
	CGContextRef context = [RZGraphicsCurrentContext() graphicsPort];
	
	NSRect backgroundFrame = NSMakeRect(0.0, 1.0,   cellBounds.size.width,
												   (cellBounds.size.height - 1.0));
	
	NSRect foregroundFrame = NSMakeRect(1.0, 2.0,  (cellBounds.size.width - 2.0),
												   (cellBounds.size.height - 3.0));
	
	/* Color values. */
	NSColor *backgroundColor = [self inputTextFieldBackgroundColorMavericks];
	NSColor *backgroundBorderColor = [self inputTextFieldOutlineColorMavericks];
	NSColor *innerShadowColor = [self inputTextFieldInsideShadowColorMavericks];
	NSColor *outerShadowColor = [self inputTextFieldOutsideShadowColorMavericks];
	
	/* Shadow values. */
	NSShadow *outterShadow = [NSShadow new];
	
	[outterShadow setShadowColor:outerShadowColor];
	[outterShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[outterShadow setShadowBlurRadius:0.0];
	
	NSShadow *innerShadow = [NSShadow new];
	
	[innerShadow setShadowColor:innerShadowColor];
	[innerShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[innerShadow setShadowBlurRadius:0.0];
	
	/* Draw the background rectangle which will act as the stroke of
	 the foreground rectangle. It will also host the bottom shadow. */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:backgroundFrame xRadius:3.5 yRadius:3.5];
	
	[NSGraphicsContext saveGraphicsState];
	
	[outterShadow set];
	
	[backgroundBorderColor setFill];
	
	[rectanglePath fill];
	
	[NSGraphicsContext restoreGraphicsState];
	
	/* Draw the foreground rectangle. */
	NSBezierPath *rectangle2Path = [NSBezierPath bezierPathWithRoundedRect:foregroundFrame xRadius:3.5 yRadius:3.5];

	[backgroundColor setFill];
	
	[rectangle2Path fill];
	
	/* Draw the inside shadow of the foreground rectangle. */
	[NSGraphicsContext saveGraphicsState];
	
	NSRectClip([rectangle2Path bounds]);
	
	CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
	
	CGContextSetAlpha(context, [innerShadowColor alphaComponent]);
	
	CGContextBeginTransparencyLayer(context, NULL);
	{
		/* Inside shadow drawing. */
		[innerShadow set];
		
		CGContextSetBlendMode(context, kCGBlendModeSourceOut);
		
		CGContextBeginTransparencyLayer(context, NULL);
		
		/* Fill shadow. */
		[innerShadowColor setFill];
		
		[rectangle2Path fill];
		
		/* Complete drawing. */
		CGContextEndTransparencyLayer(context);
	}
	
	CGContextEndTransparencyLayer(context);
	
	[NSGraphicsContext restoreGraphicsState];
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
	if ([self yosemiteIsUsingVibrantDarkMode]) {
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
	
	NSRect controlFrame = NSMakeRect(1.0, 1.0,  (cellBounds.size.width - 2.0),
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
	
	[shadow4 setShadowOffset:NSMakeSize(0.0, -(1.0))];
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

	NSRect controlFrame = NSMakeRect(1.0, 1.0,  (cellBounds.size.width - 2.0),
												(cellBounds.size.height - 2.0));
	
	/* Inner gradient color. */
	NSGradient *gradient = [self whiteInputTextFieldInsideWhiteGradientYosemite];

	/* Shadow colors. */
	NSShadow *shadow3 = [NSShadow new];
	NSShadow *shadow4 = [NSShadow new];
	
	NSColor *shadow3Color = [self whiteInputTextFieldOutsideTopsideWhiteBorderYosemite];

	[shadow3 setShadowColor:shadow3Color];
	[shadow3 setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow3 setShadowBlurRadius:0.0];

	if (inHighresMode) {
		[shadow4 setShadowColor:[self whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithRetinaYosemite]];
		[shadow4 setShadowOffset:NSMakeSize(0.0, -(0.5))];
		[shadow4 setShadowBlurRadius:0.0];
	} else {
		[shadow4 setShadowColor:[self whiteInputTextFieldOutsideBottomGrayShadowColorWithoutRetinaYosemite]];
		[shadow4 setShadowOffset:NSMakeSize(0.0, -(1.0))];
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

	CGContextSetAlpha(context, [shadow3Color alphaComponent]);

	CGContextBeginTransparencyLayer(context, NULL);
	{
		/* Inside shadow drawing. */
		[shadow3 set];

		CGContextSetBlendMode(context, kCGBlendModeSourceOut);

		CGContextBeginTransparencyLayer(context, NULL);

		/* Fill shadow. */
		[shadow3Color setFill];

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
		if ([self yosemiteIsUsingVibrantDarkMode]) {
			return [self blackInputTextFieldPlaceholderTextColorYosemite];
		} else {
			return [self whiteInputTextFieldPlaceholderTextColorYosemite];
		}
	} else {
		return [self inputTextFieldPrimaryTextColorMavericks];
	}
}

- (NSColor *)systemSpecificPlaceholderTextFontColor
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([self yosemiteIsUsingVibrantDarkMode]) {
			return [self blackInputTextFieldPrimaryTextColorYosemite];
		} else {
			return [self whiteInputTextFieldPrimaryTextColorYosemite];
		}
	} else {
		return [self inputTextFieldPlaceholderTextColorMavericks];
	}
}

- (BOOL)yosemiteIsUsingVibrantDarkMode
{
	return [self.contentView yosemiteIsUsingVibrantDarkMode];
}

- (BOOL)windowIsActive
{
	return ([mainWindow() isInactiveForDrawing] == NO);
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
