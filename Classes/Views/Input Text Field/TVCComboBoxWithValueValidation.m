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
#import "TVCComboBoxWithValueValidation.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCComboBoxWithValueValidation ()
/* Maintain cached value so that the drawing does not call
 the validaton block every time that it is called. */
@property (nonatomic, assign) BOOL cachedValidValue;
@property (nonatomic, assign) BOOL lastOperationWasPredefinedSelection;
@end

@interface TVCComboBoxWithValueValidationCell ()
@property (readonly) NSColor *erroneousValueBackgroundColor;
@property (readonly) BOOL onlyShowStatusIfErrorOccurs;
@property (readonly) BOOL parentValueIsEmpty;
@property (readonly) BOOL parentValueIsValid;
@property (readonly) NSRect parentViewFrame;
@property (readonly) TVCComboBoxWithValueValidation *parentField;

- (void)recalculatePositionOfClipView:(NSClipView *)clipView;
@end

@implementation TVCComboBoxWithValueValidation

#pragma mark -
#pragma mark Public API (Combo Box Text Field)

- (void)awakeFromNib
{
	self.cachedValidValue = NO;

	self.lastOperationWasPredefinedSelection = NO;

	self.delegate = (id)self;
}

- (BOOL)drawsBackground
{
	return NO;
}

- (nullable NSString *)predefinedSelectionValue
{
	if (self.lastOperationWasPredefinedSelection == NO) {
		return nil;
	}

	NSInteger selectedItemIndex = self.indexOfSelectedItem;

	if (selectedItemIndex >= 0) {
		return [self itemObjectValueAtIndex:selectedItemIndex];
	}

	return nil;
}

- (NSString *)value
{
	NSString *stringValue = [self predefinedSelectionValue];

	if (stringValue == nil) {
		if (self.stringValueUsesOnlyFirstToken) {
			stringValue = self.trimmedFirstTokenStringValue;
		} else {
			stringValue = self.stringValue;

			if (self.stringValueIsTrimmed) {
				stringValue = stringValue.trim;
			}
		}
	}

	if (stringValue.length == 0) {
		if (	   self.defaultValue && self.stringValueIsInvalidOnEmpty == NO) {
			return self.defaultValue;
		}
	}

	return stringValue;
}

- (NSString *)lowercaseValue
{
	return self.value.lowercaseString;
}

- (NSString *)uppercaseValue
{
	return self.value.uppercaseString;
}

- (NSInteger)integerValue
{
	return self.value.integerValue;
}

- (void)setIntegerValue:(NSInteger)integerValue
{
	self.stringValue = [NSString stringWithInteger:integerValue];
}

- (BOOL)valueIsEmpty
{
	return NSObjectIsEmpty(self.stringValue);
}

- (BOOL)valueIsValid
{
	return self.cachedValidValue;
}

#pragma mark -
#pragma mark Interval Validation

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	self.lastOperationWasPredefinedSelection = YES;

	[self performValidation];

	[self informCallbackTextDidChange];

	[self recalculatePositionOfClipView];
}

- (void)textDidChange:(NSNotification *)notification
{
	NSInteger objectIndex = [self indexOfItemWithObjectValue:self.stringValue];

	if (objectIndex != NSNotFound) {
		[self selectItemAtIndex:objectIndex];

		return;
	}

	self.lastOperationWasPredefinedSelection = NO;

	[self performValidation];

	[self informCallbackTextDidChange];

	[self recalculatePositionOfClipView];
}

- (void)setStringValue:(NSString *)stringValue
{
	super.stringValue = stringValue;

	[self textDidChange:nil];
}

- (void)informCallbackTextDidChange
{
	if (self.doNotInformCallbackOfNextChange) {
		self.doNotInformCallbackOfNextChange = NO;

		return;
	}

	if (self.textDidChangeCallback == nil) {
		return;
	}

	if ([self.textDidChangeCallback respondsToSelector:@selector(validatedTextFieldTextDidChange:)]) {
		[self.textDidChangeCallback performSelector:@selector(validatedTextFieldTextDidChange:) withObject:self];
	}
}

- (void)performValidation
{
	/* If a predefined selection is selected, then consider the value
	 valid no matter what because it is a valid WE defined. */
	NSString *predefinedSelectionValue = [self predefinedSelectionValue];

	if (predefinedSelectionValue) {
		self.cachedValidValue = YES;

		return;
	}

	/* Perform validation on user entered string value */
	NSString *validationValue = self.stringValue;

	if (NSObjectIsEmpty(validationValue) == NO) {
		if (self.validationBlock) {
			self.cachedValidValue = self.validationBlock(validationValue);
		} else {
			self.cachedValidValue = YES;
		}
	} else {
		if (self.performValidationWhenEmpty) {
			self.cachedValidValue = self.validationBlock(validationValue);
		} else {
			self.cachedValidValue = (self.stringValueIsInvalidOnEmpty == NO);
		}
	}
}

- (void)recalculatePositionOfClipView
{
	NSClipView *clipView = nil;

	for (NSView *subview in self.subviews) {
		if ([subview isKindOfClass:[NSClipView class]]) {
			clipView = (id)subview;

			break;
		}
	}

	if (clipView == nil) {
		return;
	}

	[self.cell recalculatePositionOfClipView:clipView];

}

@end

#pragma mark -
#pragma mark Text Field Cell

@implementation TVCComboBoxWithValueValidationCell

- (NSRect)correctedDrawingRect:(NSRect)aRect
{
	if (self.onlyShowStatusIfErrorOccurs) {
		if (self.parentValueIsValid) {
			return aRect;
		}
	}

	aRect.size.width = [self correctedWidthForClipViewRect];

	return aRect;
}

- (CGFloat)correctedWidthForClipViewRect
{
	NSRect parentRect = self.parentViewFrame;

	CGFloat parentWidth = NSWidth(parentRect);

	if (self.onlyShowStatusIfErrorOccurs) {
		if (self.parentValueIsValid) {
			return (parentWidth - 24.0);
		}
	}

	parentWidth -= 47.0;

	return parentWidth;
}

- (NSColor *)erroneousValueBackgroundColor
{
	return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.05];
}

- (NSRect)erroneousValueBadgeIconRectInParentRect:(NSRect)aRect
{
	/* Look at all those magic numbers... */
	CGFloat rightEdge = (NSMaxX(aRect) - 40.0);

	if (TEXTUAL_RUNNING_ON(10.11, ElCapitan) && self.window.runningInHighResolutionMode) {
		return NSMakeRect(rightEdge, 5.0, 14.0, 14.0);
	} else if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		return NSMakeRect(rightEdge, 6.0, 14.0, 14.0);
	} else {
		return NSMakeRect(rightEdge, 7.0, 14.0, 14.0);
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (self.parentValueIsValid == NO) {
		NSRect backgroundFrame = cellFrame;

		backgroundFrame.origin.x += 1.0;
		backgroundFrame.origin.y += 1.0;

		backgroundFrame.size.width -= 2.0;
		backgroundFrame.size.height -= 2.0;

		NSColor *backgroundColor = self.erroneousValueBackgroundColor;

		NSBezierPath *backgroundFill = [NSBezierPath bezierPathWithRect:backgroundFrame];

		[backgroundColor set];

		[backgroundFill fill];
	}

	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[super drawWithFrame:cellFrame inView:controlView];

	/* Maybe not draw icon */
	if (self.onlyShowStatusIfErrorOccurs) {
		if (self.parentValueIsValid) {
			return; // Do not continue, we have valid value.
		}
	}

	/* Draw status image badge */
	NSImage *statusImage = nil;

	if (self.parentValueIsValid == NO) {
		statusImage = [NSImage imageNamed:@"ErroneousTextFieldValueIndicator"];
	} else if (self.parentValueIsEmpty == NO) {
		statusImage = [NSImage imageNamed:@"ProperlyFormattedTextFieldValueIndicator"];
	}

	if (statusImage) {
		NSRect statusImageDrawRect = [self erroneousValueBadgeIconRectInParentRect:cellFrame];

		[statusImage drawInRect:statusImageDrawRect
					   fromRect:NSZeroRect
					  operation:NSCompositeSourceOver
					   fraction:1.0
				 respectFlipped:YES
						  hints:nil];
	}
}

#ifdef TXSystemIsOSXSierraOrLater
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(nullable id)anObject event:(nullable NSEvent *)theEvent
#else
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(nullable id)anObject event:(NSEvent *)theEvent
#endif
{
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];

	[self recalculatePositionOfClipView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(nullable id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];

	[self recalculatePositionOfClipView];
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	NSRect fixedRect = [super drawingRectForBounds:theRect];

	return [self correctedDrawingRect:fixedRect];
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
	NSRect fixedRect = [super titleRectForBounds:theRect];

	return [self correctedDrawingRect:fixedRect];
}

- (void)recalculatePositionOfClipView:(NSClipView *)clipView
{
	NSRect clipViewRect = clipView.frame;

	clipViewRect.size.width = [self correctedWidthForClipViewRect];

	clipView.frame = clipViewRect;

	[self.parentField resetCursorRects];
}

- (TVCComboBoxWithValueValidation *)parentField
{
	return (TVCComboBoxWithValueValidation *)self.controlView;
}

- (NSRect)parentViewFrame
{
	return self.parentField.frame;
}

- (void)recalculatePositionOfClipView
{
	[self.parentField recalculatePositionOfClipView];
}

- (BOOL)parentValueIsEmpty
{
	return self.parentField.valueIsEmpty;
}

- (BOOL)parentValueIsValid
{
	return self.parentField.valueIsValid;
}

- (BOOL)onlyShowStatusIfErrorOccurs
{
	return self.parentField.onlyShowStatusIfErrorOccurs;
}

@end

NS_ASSUME_NONNULL_END
