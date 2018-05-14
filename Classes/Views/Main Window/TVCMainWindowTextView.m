/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "NSViewHelperPrivate.h"
#import "IRCColorFormat.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TVCMainWindow.h"
#import "TVCMainWindowTextViewMavericksUserInteracePrivate.h"
#import "TVCMainWindowTextViewYosemiteUserInteracePrivate.h"
#import "TVCMainWindowSegmentedControlPrivate.h"
#import "TVCTextViewWithIRCFormatterPrivate.h"
#import "TVCMainWindowTextViewPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _WindowContentBorderTotalPaddingMavericks		23.0
#define _WindowContentBorderTotalPaddingYosemite		23.0

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
@property (readonly, copy) NSColor *placeholderStringFontColor;
@property (nonatomic, assign) TVCMainWindowTextViewFontSize cachedFontSize;
@property (nonatomic, copy) NSAttributedString *placeholderString;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *windowContentViewMinimumHeight;
@property (nonatomic, weak) IBOutlet TVCMainWindowTextViewBackground *backgroundView;
@property (nonatomic, weak) IBOutlet TVCMainWindowTextViewContentView *contentView;
@property (nonatomic, weak) IBOutlet TVCMainWindowSegmentedController *segmentedController;
@property (nonatomic, weak) IBOutlet TVCMainWindowSegmentedControllerCell *segmentedControllerCell;
@end

@interface TVCMainWindowTextViewContentView ()
@property (nonatomic, weak) IBOutlet TVCMainWindowSegmentedController *segmentedController;
@end

@implementation TVCMainWindowTextView

#pragma mark -
#pragma mark Drawing

- (void)awakeFromNib
{
	for (NSString *key in _KeyObservingArray) {
		[RZUserDefaults() addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:NULL];
	}

	self.backgroundColor = [NSColor clearColor];

	[self reloadOriginPointsAndRecalculateSize];

	[self updateTextDirection];
}

- (void)dealloc
{
	for (NSString *key in _KeyObservingArray) {
		[RZUserDefaults() removeObserver:self forKeyPath:key];
	}
}

- (void)updateBackgroundColorOnYosemite
{
	if (self.mainWindow.usingVibrantDarkAppearance) {
		self.segmentedController.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	} else {
		self.segmentedController.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}

	self.backgroundView.needsDisplay = YES;

	self.contentView.needsDisplay = YES;
}

- (void)updateBackgroundColor
{
	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateBackgroundColorOnYosemite];
	}

	self.preferredFontColor = self.backgroundView.systemSpecificFontColor;

	[self updateTextBoxCachedPreferredFontSize];

	[self resetTypeSetterAttributes];

	[self updateAllFontColorsToMatchTheDefaultFont];
}

- (void)windowDidChangeKeyState
{
	; // Nothing to do here...
}

#pragma mark -
#pragma mark Segmented Controller

- (void)reloadOriginPointsAndRecalculateSize
{
	[self reloadOriginPoints];

	/* Reload size on next go around to allow constraint layout to occur before so */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self recalculateTextViewSizeForced];
	});
}

- (void)reloadOriginPoints
{
	[self.segmentedController updateSegmentedControllerOrigin];
}

- (void)updateSegmentedController
{
	[self.segmentedController updateSegmentedController];
}

#pragma mark -
#pragma mark Utilities

- (void)updateAllFontColorsToMatchTheDefaultFont
{
	[self.textStorage beginEditing];

	[self.textStorage enumerateAttributesInRange:self.range
										 options:0
									  usingBlock:^(NSDictionary *attributes, NSRange effectiveRange, BOOL *stop)
		{
			if ([attributes containsKey:IRCTextFormatterForegroundColorAttributeName]) {
				return;
			}

			[self resetFontColorInRange:effectiveRange];
		}];

	[self.textStorage endEditing];
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
	super.attributedStringValue = attributedStringValue;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateAllFontColorsToMatchTheDefaultFont];
	}
}

- (void)updateTextDirection
{
	if ([TPCPreferences rightToLeftFormatting]) {
		self.baseWritingDirection = NSWritingDirectionRightToLeft;
	} else {
		self.baseWritingDirection = NSWritingDirectionLeftToRight;
	}
}

- (void)textDidChange:(NSNotification *)aNotification
{
	[super textDidChange:aNotification];

	[self recalculateTextViewSize];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	NSString *stringValue = self.stringValue;

	if (stringValue.length == 0) {
		/* The place holder string is not drawn for right to left users */
		if (self.baseWritingDirection == NSWritingDirectionLeftToRight) {
			if (self.cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
				[self.placeholderString drawAtPoint:NSMakePoint(6, 2)];
			} else {
				[self.placeholderString drawAtPoint:NSMakePoint(6, 1)];
			}
		}

		return;
	}

	[super drawRect:dirtyRect];
}

- (void)paste:(nullable id)sender
{
	[super paste:self];

	[self recalculateTextViewSize];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (aSelector == @selector(insertNewline:)) {
		[self.mainWindow textEntered];

		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Multi-line Text Box Drawing

- (NSColor *)placeholderStringFontColor
{
	return self.backgroundView.systemSpecificPlaceholderStringFontColor;
}

- (void)updateTextBoxCachedPreferredFontSize
{
	TVCMainWindowTextViewFontSize newFontSize = [TPCPreferences mainTextViewFontSize];

	if (self.cachedFontSize != newFontSize) {
		self.cachedFontSize = newFontSize;
	} else {
		return;
	}

	if (self.cachedFontSize == TVCMainWindowTextViewFontNormalSize) {
		self.preferredFont = [self.backgroundView systemSpecificFontWithSize:12.0];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontLargeSize) {
		self.preferredFont = [self.backgroundView systemSpecificFontWithSize:14.0];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontExtraLargeSize) {
		self.preferredFont = [self.backgroundView systemSpecificFontWithSize:16.0];
	} else if (self.cachedFontSize == TVCMainWindowTextViewFontHumongousSize) {
		self.preferredFont = [self.backgroundView systemSpecificFontWithSize:24.0];
	}

	/* Update the placeholder string */
	NSDictionary *placeholderStringAttributes = @{
		NSFontAttributeName	: self.preferredFont,
		NSForegroundColorAttributeName : self.placeholderStringFontColor
	};

	self.placeholderString =
	[NSAttributedString attributedStringWithString:TXTLS(@"TVCMainWindow[1011]") attributes:placeholderStringAttributes];

	self.needsDisplay = YES;
}

- (void)updateTextBasedOnPreferredFontSize
{
	TVCMainWindowTextViewFontSize cachedFontSize = self.cachedFontSize;

	[self updateTextBoxCachedPreferredFontSize];

	if (self.cachedFontSize != cachedFontSize) {
		[self updateAllFontSizesToMatchTheDefaultFont];
	}

	[self recalculateTextViewSizeForced];
}

- (CGFloat)backgroundViewDefaultHeight
{
	return [self.layoutManager defaultLineHeightForFont:self.preferredFont];
}

- (void)recalculateTextViewSize
{
	[self recalculateTextViewSizeForced:NO];
}

- (void)recalculateTextViewSizeForced
{
	[self recalculateTextViewSizeForced:YES];
}

- (void)recalculateTextViewSizeForced:(BOOL)forceRecalculate
{
	NSWindow *window = self.window;

	NSRect windowFrame = window.frame;

	CGFloat contentBorderPadding = 0;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		contentBorderPadding = _WindowContentBorderTotalPaddingYosemite;
	} else {
		contentBorderPadding = _WindowContentBorderTotalPaddingMavericks;
	}

	CGFloat backgroundHeight = 0;

	CGFloat backgroundHeightDefault = [self backgroundViewDefaultHeight];

	if (self.stringLength < 1) {
		backgroundHeight = (backgroundHeightDefault + contentBorderPadding);
	} else {
		CGFloat backgroundHeightMaximum = (NSHeight(windowFrame) - (self.windowContentViewMinimumHeight.constant + contentBorderPadding));

		backgroundHeight = [self highestHeightBelowHeight:backgroundHeightMaximum withPadding:contentBorderPadding];

		if ((backgroundHeight - contentBorderPadding) < backgroundHeightDefault) {
			backgroundHeight = (backgroundHeightDefault + contentBorderPadding);
		}
	}

	self.textViewHeightConstraint.constant = backgroundHeight;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO) {
		[window setContentBorderThickness:backgroundHeight forEdge:NSMinYEdge];
	}

	id scrollViewContentView = self.enclosingScrollView.contentView;

	NSRect contentViewBounds = [scrollViewContentView bounds];

	if (contentViewBounds.origin.x > 0) {
		contentViewBounds.origin.x = 0;

		[scrollViewContentView scrollToPoint:contentViewBounds.origin];
	}
}

#pragma mark -
#pragma mark NSTextView Context Menu Preferences

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary *)change context:(nullable void *)context
{
	if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticSpellCheck"]) {
		self.continuousSpellCheckingEnabled = [TPCPreferences textFieldAutomaticSpellCheck];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticGrammarCheck"]) {
		self.grammarCheckingEnabled = [TPCPreferences textFieldAutomaticGrammarCheck];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldAutomaticSpellCorrection"]) {
		self.automaticSpellingCorrectionEnabled = [TPCPreferences textFieldAutomaticSpellCorrection];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartCopyPaste"]) {
		self.smartInsertDeleteEnabled = [TPCPreferences textFieldSmartCopyPaste];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartQuotes"]) {
		self.automaticQuoteSubstitutionEnabled = [TPCPreferences textFieldSmartQuotes];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartDashes"]) {
		self.automaticDashSubstitutionEnabled = [TPCPreferences textFieldSmartDashes];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldSmartLinks"]) {
		self.automaticLinkDetectionEnabled = [TPCPreferences textFieldSmartLinks];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldDataDetectors"]) {
		self.automaticDataDetectionEnabled = [TPCPreferences textFieldDataDetectors];
	} else if ([keyPath isEqualIgnoringCase:@"TextFieldTextReplacement"]) {
		self.automaticTextReplacementEnabled = [TPCPreferences textFieldTextReplacement];
	} else if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setContinuousSpellCheckingEnabled:(BOOL)continuousSpellCheckingEnabled
{
	[TPCPreferences setTextFieldAutomaticSpellCheck:continuousSpellCheckingEnabled];

	super.continuousSpellCheckingEnabled = continuousSpellCheckingEnabled;
}

- (void)setGrammarCheckingEnabled:(BOOL)grammarCheckingEnabled
{
	[TPCPreferences setTextFieldAutomaticGrammarCheck:grammarCheckingEnabled];

	super.grammarCheckingEnabled = grammarCheckingEnabled;
}

- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)automaticSpellingCorrectionEnabled
{
	[TPCPreferences setTextFieldAutomaticSpellCorrection:automaticSpellingCorrectionEnabled];

	super.automaticSpellingCorrectionEnabled = automaticSpellingCorrectionEnabled;
}

- (void)setSmartInsertDeleteEnabled:(BOOL)smartInsertDeleteEnabled
{
	[TPCPreferences setTextFieldSmartCopyPaste:smartInsertDeleteEnabled];

	super.smartInsertDeleteEnabled = smartInsertDeleteEnabled;
}

- (void)setAutomaticQuoteSubstitutionEnabled:(BOOL)automaticQuoteSubstitutionEnabled
{
	[TPCPreferences setTextFieldSmartQuotes:automaticQuoteSubstitutionEnabled];

	super.automaticQuoteSubstitutionEnabled = automaticQuoteSubstitutionEnabled;
}

- (void)setAutomaticDashSubstitutionEnabled:(BOOL)automaticDashSubstitutionEnabled
{
	[TPCPreferences setTextFieldSmartDashes:automaticDashSubstitutionEnabled];

	super.automaticDashSubstitutionEnabled = automaticDashSubstitutionEnabled;
}

- (void)setAutomaticLinkDetectionEnabled:(BOOL)automaticLinkDetectionEnabled
{
	[TPCPreferences setTextFieldSmartLinks:automaticLinkDetectionEnabled];

	super.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled;
}

- (void)setAutomaticDataDetectionEnabled:(BOOL)automaticDataDetectionEnabled
{
	[TPCPreferences setTextFieldDataDetectors:automaticDataDetectionEnabled];

	super.automaticDataDetectionEnabled = automaticDataDetectionEnabled;
}

- (void)setAutomaticTextReplacementEnabled:(BOOL)automaticTextReplacementEnabled
{
	[TPCPreferences setTextFieldTextReplacement:automaticTextReplacementEnabled];

	super.automaticTextReplacementEnabled = automaticTextReplacementEnabled;
}

@end

#pragma mark -
#pragma mark Background Drawing

@implementation TVCMainWindowTextViewBackground

#pragma mark -
#pragma mark Mavericks UI Drawing

- (void)drawControllerForMavericks
{
	NSRect cellBounds = self.frame;

	CGContextRef context = RZGraphicsCurrentContext().graphicsPort;

	NSRect backgroundFrame = NSMakeRect(0.0, 1.0,   cellBounds.size.width,
												   (cellBounds.size.height - 1.0));

	NSRect foregroundFrame = NSMakeRect(1.0, 2.0,  (cellBounds.size.width - 2.0),
												   (cellBounds.size.height - 3.0));

	NSColor *backgroundColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldBackgroundColor];
	NSColor *outerShadowColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldOutsideShadowColor];

	NSColor *backgroundBorderColor = nil;
	NSColor *innerShadowColor = nil;

	if (self.mainWindow.activeForDrawing) {
		backgroundBorderColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldOutlineColorForActiveWindow];

		innerShadowColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldInsideShadowColorForActiveWindow];
	} else {
		backgroundBorderColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldOutlineColorForInactiveWindow];

		innerShadowColor = [TVCMainWindowTextViewMavericksUserInterace inputTextFieldInsideShadowColorForInactiveWindow];
	}

	/* Shadow values */
	NSShadow *outterShadow = [NSShadow new];

	outterShadow.shadowColor = outerShadowColor;
	outterShadow.shadowOffset = NSMakeSize(0.0, (-1.0));
	outterShadow.shadowBlurRadius = 0.0;

	NSShadow *innerShadow = [NSShadow new];

	innerShadow.shadowColor = innerShadowColor;
	innerShadow.shadowOffset = NSMakeSize(0.0, (-1.0));
	innerShadow.shadowBlurRadius = 0.0;

	/* Draw the background rectangle which will act as the stroke of
	 the foreground rectangle. It will also host the bottom shadow. */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:backgroundFrame xRadius:3.5 yRadius:3.5];

	[NSGraphicsContext saveGraphicsState];

	[outterShadow set];

	[backgroundBorderColor setFill];

	[rectanglePath fill];

	[NSGraphicsContext restoreGraphicsState];

	/* Draw the foreground rectangle */
	NSBezierPath *rectangle2Path = [NSBezierPath bezierPathWithRoundedRect:foregroundFrame xRadius:3.5 yRadius:3.5];

	[backgroundColor setFill];

	[rectangle2Path fill];

	/* Draw the inside shadow of the foreground rectangle */
	[NSGraphicsContext saveGraphicsState];

	NSRectClip(rectangle2Path.bounds);

	CGContextSetShadowWithColor(context, CGSizeZero, 0.0, NULL);

	CGContextSetAlpha(context, innerShadowColor.alphaComponent);

	CGContextBeginTransparencyLayer(context, NULL);

	{
		/* Inside shadow drawing */
		[innerShadow set];

		CGContextSetBlendMode(context, kCGBlendModeSourceOut);

		CGContextBeginTransparencyLayer(context, NULL);

		/* Fill shadow */
		[innerShadowColor setFill];

		[rectangle2Path fill];

		/* Complete drawing */
		CGContextEndTransparencyLayer(context);
	}

	CGContextEndTransparencyLayer(context);

	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark -
#pragma mark Yosemite UI Drawing

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
	NSRect cellBounds = self.frame;

	BOOL inHighresMode = self.mainWindow.runningInHighResolutionMode;

	NSRect controlFrame = NSMakeRect(0.0, 1.0,   cellBounds.size.width,
												(cellBounds.size.height - 2.0));

	/* Inner background color */
	NSColor *background = [TVCMainWindowTextViewYosemiteUserInterace blackInputTextFieldInsideBlackBackgroundColor];

	/* Shadow colors */
	NSShadow *shadow4 = [NSShadow new];

	if (inHighresMode) {
		shadow4.shadowColor = [TVCMainWindowTextViewYosemiteUserInterace blackInputTextFieldOutsideBottomGrayShadowColorWithRetina];
	} else {
		shadow4.shadowColor = [TVCMainWindowTextViewYosemiteUserInterace blackInputTextFieldOutsideBottomGrayShadowColorWithoutRetina];
	}

	shadow4.shadowOffset = NSMakeSize(0.0, (-1.0));
	shadow4.shadowBlurRadius = 0.0;

	/* Rectangle drawing */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.0 yRadius:3.0];

	[NSGraphicsContext saveGraphicsState];

	[shadow4 set];

	[background setFill];

	[rectanglePath fill];

	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawWhiteControllerForYosemiteInFocusedWindow
{
	NSRect cellBounds = self.frame;

	CGContextRef context = RZGraphicsCurrentContext().graphicsPort;

	BOOL inHighresMode = self.mainWindow.runningInHighResolutionMode;

	NSRect controlFrame = NSMakeRect(0.0, 1.0,   cellBounds.size.width,
												(cellBounds.size.height - 2.0));

	/* Inner gradient color */
	NSGradient *gradient = [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldInsideWhiteGradient];

	/* Shadow colors */
	NSShadow *shadow3 = [NSShadow new];

	NSColor *shadow3Color = [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldOutsideTopsideWhiteBorder];

	shadow3.shadowColor = shadow3Color;
	shadow3.shadowOffset = NSMakeSize(0.0, (-1.0));
	shadow3.shadowBlurRadius = 0.0;

	NSShadow *shadow4 = [NSShadow new];

	if (inHighresMode) {
		shadow4.shadowColor = [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithRetina];
		shadow4.shadowOffset = NSMakeSize(0.0, (-0.5));
		shadow4.shadowBlurRadius = 0.0;
	} else {
		shadow4.shadowColor = [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithoutRetina];
		shadow4.shadowOffset = NSMakeSize(0.0, (-1.0));
		shadow4.shadowBlurRadius = 0.0;
	}

	/* Rectangle drawing */
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRoundedRect:controlFrame xRadius:3.0 yRadius:3.0];

	[shadow4 set];

	CGContextBeginTransparencyLayer(context, NULL);

	[gradient drawInBezierPath:rectanglePath angle:(-90)];

	CGContextEndTransparencyLayer(context);

	/* Prepare drawing for inside shadow */
	CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);

	CGContextSetAlpha(context, shadow3Color.alphaComponent);

	CGContextBeginTransparencyLayer(context, NULL);

	{
		/* Inside shadow drawing */
		[shadow3 set];

		CGContextSetBlendMode(context, kCGBlendModeSourceOut);

		CGContextBeginTransparencyLayer(context, NULL);

		/* Fill shadow */
		[shadow3Color setFill];

		[rectanglePath fill];

		/* Complete drawing */
		CGContextEndTransparencyLayer(context);
	}

	CGContextEndTransparencyLayer(context);

	/* On retina, we fake a second shadow under the bottommost one */
	if (inHighresMode) {
		NSPoint linePoint1 = NSMakePoint(4.0, 0.0);
		NSPoint linePoint2 = NSMakePoint((cellBounds.size.width - 4.0), 0.0);

		NSColor *controlColor = [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldOutsideBottomSecondaryGrayShadowColorWithRetina];

		[controlColor setStroke];

		[NSBezierPath strokeLineFromPoint:linePoint1 toPoint:linePoint2];
	}
}

#pragma mark -
#pragma mark Drawing Factory

- (NSFont *)systemSpecificFontWithSize:(CGFloat)fontSize
{
	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		return [NSFont systemFontOfSize:fontSize];
	} else {
		return [NSFont fontWithName:@"Helvetica" size:fontSize];
	}
}

- (NSColor *)systemSpecificFontColor
{
	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		if ([self yosemiteIsUsingVibrantDarkMode]) {
			return [TVCMainWindowTextViewYosemiteUserInterace blackInputTextFieldPlaceholderTextColor];
		} else {
			return [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldPlaceholderTextColor];
		}
	} else {
		return [TVCMainWindowTextViewMavericksUserInterace inputTextFieldPrimaryTextColor];
	}
}

- (NSColor *)systemSpecificPlaceholderStringFontColor
{
	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		if ([self yosemiteIsUsingVibrantDarkMode]) {
			return [TVCMainWindowTextViewYosemiteUserInterace blackInputTextFieldPrimaryTextColor];
		} else {
			return [TVCMainWindowTextViewYosemiteUserInterace whiteInputTextFieldPrimaryTextColor];
		}
	} else {
		return [TVCMainWindowTextViewMavericksUserInterace inputTextFieldPlaceholderTextColor];
	}
}

- (BOOL)yosemiteIsUsingVibrantDarkMode
{
	return self.mainWindow.usingVibrantDarkAppearance;
}

- (BOOL)windowIsActive
{
	return self.mainWindow.activeForDrawing;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self drawControllerForYosemite];
	} else {
		[self drawControllerForMavericks];
	}
}

@end

#pragma mark -
#pragma mark Text Field Background Vibrant View

/* The content view layer only exists on Yosemite and later. 
 Textual on Mavericks and earlier uses the content border of
 the window in place of this layer for the content view. */
@implementation TVCMainWindowTextViewContentView

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	TVCMainWindow *mainWindow = self.mainWindow;

	/* Draw background color */
	NSColor *backgroundColor = self.backgroundColor;

	[backgroundColor set];

	NSRectFill(dirtyRect);

	/* Draw divider */
	NSRect contentViewFrame = self.frame;

	contentViewFrame.origin.x = 0.0;
	contentViewFrame.origin.y = (NSMaxY(contentViewFrame) - 1.0);

	contentViewFrame.size.height = 1.0;

	NSBezierPath *dividerPath = [NSBezierPath bezierPathWithRect:contentViewFrame];

	NSColor *dividierColor = self.dividerColor;

	[dividierColor set];

	[dividerPath fill];

	/* Discussion: On Yosemite, when a segmented controller is set as vibrant dark,
	 it inherits whatever color is behind it in a translucent manor. To allow for
	 a darker controller in Textual, we set the background of ours to black. To
	 achive this, we create a bezier path that replicate the frame of segmented
	 controller. This is a very ugly hack and can break easily in an OS update. */
	if ([TPCPreferences hideMainWindowSegmentedController]) {
		return;
	}

	if (mainWindow.isUsingVibrantDarkAppearance == NO) {
		return;
	}

	/* Get controller and controller frame */
	{
		TVCMainWindowSegmentedController *controller = self.segmentedController;

		NSRect controllerFrame = controller.frame;

		controllerFrame.size.width -= 4.0;
		controllerFrame.size.height -= 3.0;

		controllerFrame.origin.y += 2.0;

		NSBezierPath *controllerPath  = [NSBezierPath bezierPathWithRoundedRect:controllerFrame xRadius:4.0 yRadius:4.0];

		NSColor *controllerColor = [NSColor blackColor];

		[controllerColor set];

		[controllerPath fill];
	}
}

- (NSColor *)backgroundColor
{
	if (self.mainWindow.usingVibrantDarkAppearance) {
		return [self vibrantDarkBackgroundColor];
	} else {
		return [self vibrantLightBackgroundColor];
	}
}

- (NSColor *)dividerColor
{
	if (self.mainWindow.usingVibrantDarkAppearance) {
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

- (BOOL)isOpaque
{
	return YES;
}

@end

NS_ASSUME_NONNULL_END
