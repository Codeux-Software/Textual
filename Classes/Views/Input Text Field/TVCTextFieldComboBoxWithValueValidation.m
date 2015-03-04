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

#import "TextualApplication.h"

@interface TVCTextFieldComboBoxWithValueValidation ()
/* Maintain cached value so that the drawing does not call
 the validaton block every time that it is called. */
@property (nonatomic, assign) BOOL cachedValidValue;
@property (nonatomic, assign) BOOL lastOperationWasPredefinedSelection;
@end

@interface TVCTextFieldComboBoxWithValueValidationCell ()
- (void)recalculatePositionOfClipView:(NSClipView *)clipView;
@end

@implementation TVCTextFieldComboBoxWithValueValidation

#pragma mark -
#pragma mark Public API (Combo Box Text Field)

- (void)awakeFromNib
{
	[self setCachedValidValue:NO];

	[self setLastOperationWasPredefinedSelection:NO];

	[self setDelegate:self];
}

- (NSString *)actualValue
{
	if (self.lastOperationWasPredefinedSelection == NO) {
		return [self stringValue];
	} else {
		NSInteger selectedItemIndex = [self indexOfSelectedItem];

		if (selectedItemIndex > -1) {
			return [self itemObjectValueAtIndex:selectedItemIndex];
		} else {
			return NSStringEmptyPlaceholder;
		}
	}
}

- (NSString *)value
{
	NSString *stringValue = [self actualValue];
	
	if (self.stringValueUsesOnlyFirstToken) {
		stringValue = [stringValue trim];
		
		NSInteger spacePosition = [stringValue stringPosition:NSStringWhitespacePlaceholder];
		
		if (spacePosition >= 1) {
			stringValue = [stringValue substringToIndex:spacePosition];
		}
	} else {
		if (self.stringValueIsTrimmed) {
			stringValue = [stringValue trim];
		}
	}
	
	return stringValue;
}

- (NSString *)lowercaseValue
{
	return [[self value] lowercaseString];
}

- (NSString *)uppercaseValue
{
	return [[self value] uppercaseString];
}

- (NSInteger)integerValue
{
	return [[self value] integerValue];
}

- (BOOL)valueIsEmpty
{
	return NSObjectIsEmpty([self stringValue]);
}

- (BOOL)valueIsValid
{
	return self.cachedValidValue;
}

#pragma mark -
#pragma mark Interval Validation

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	/* Validate new value. */
	[self setLastOperationWasPredefinedSelection:YES];
	
	[self performValidation];
	
	[self informCallbackTextDidChange];
	
	[self recalculatePositionOfClipView];
}

- (void)textDidChange:(NSNotification *)notification
{
	/* Validate new value. */
	[self setLastOperationWasPredefinedSelection:NO];

	[self performValidation];
	
	[self informCallbackTextDidChange];
	
	[self recalculatePositionOfClipView];
}

- (void)setStringValue:(NSString *)aString
{
	/* Set string value. */
	[super setStringValue:aString];
	
	/* Validate new value. */
	[self setLastOperationWasPredefinedSelection:NO];

	[self performValidation];
	
	[self informCallbackTextDidChange];
	
	[self recalculatePositionOfClipView];
}

- (void)informCallbackTextDidChange
{
	if (self.textDidChangeCallback) {
		if ([self.textDidChangeCallback respondsToSelector:@selector(validatedTextFieldTextDidChange:)]) {
			[self.textDidChangeCallback performSelector:@selector(validatedTextFieldTextDidChange:) withObject:self];
		}
	}
}

- (void)performValidation
{
	if ([self valueIsEmpty] == NO) {
		if (self.validationBlock) {
			self.cachedValidValue = self.validationBlock([self actualValue]);
		} else {
			self.cachedValidValue = YES;
		}
	} else {
		if (self.performValidationWhenEmpty) {
			self.cachedValidValue = self.validationBlock([self actualValue]);
		} else {
			self.cachedValidValue = (self.stringValueIsInvalidOnEmpty == NO);
		}
	}
}

- (void)recalculatePositionOfClipView
{
	NSArray *subviews = [self subviews];
	
	id internalClipView = nil;
	
	if ([subviews count] > 0) {
		for (id object in subviews) {
			if ([[object class] isSubclassOfClass:[NSClipView class]]) {
				internalClipView = object;
				
				break;
			}
		}
	}
	
	if (internalClipView) {
		[[self cell] recalculatePositionOfClipView:internalClipView];
	}
}

@end

#pragma mark -
#pragma mark Text Field Cell

@implementation TVCTextFieldComboBoxWithValueValidationCell

- (NSRect)correctedDrawingRect:(NSRect)aRect
{
	if ([self onlyShowStatusIfErrorOccurs]) {
		if ([self parentValueIsValid]) {
			return aRect;
		}
	}
	
	/* Update size. */
	aRect.size.width = [self correctedWidthForClipViewRect];
	
	/* Return frame. */
	return aRect;
}

- (NSInteger)correctedWidthForClipViewRect
{
	NSRect parentRect = [self parentViewFrame];
	
	NSInteger parentWidth = NSWidth(parentRect);
	
	if ([self onlyShowStatusIfErrorOccurs]) {
		if ([self parentValueIsValid]) {
			return (parentWidth - 24.0);
		}
	}
	
	/* Update size. */
	parentWidth -= 47;
	
	/* Return frame. */
	return parentWidth;
}

- (NSColor *)erroneousValueBackgroundColor
{
	return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.05];
}

- (NSRect)erroneousValueBadgeIconRectInParentRect:(NSRect)aRect
{
	/* Look at all those magic numbers… */
	NSInteger rightEdge = (NSMaxX(aRect) - 40.0);
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		return NSMakeRect(rightEdge, 6.0, 14.0, 14.0);
	} else {
		return NSMakeRect(rightEdge, 7.0, 14.0, 14.0);
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Draw a background color. */
	if ([self parentValueIsValid] == NO) {
		/* Define frame. */
		NSRect backgroundFrame = cellFrame;
		
		backgroundFrame.origin.x += 1.0;
		backgroundFrame.origin.y += 1.0;
		
		backgroundFrame.size.width -= 2.0;
		backgroundFrame.size.height -= 2.0;
		
		/* Define color and fill it. */
		NSColor *backgroundColor = [self erroneousValueBackgroundColor];
		
		NSBezierPath *backgroundFill = [NSBezierPath bezierPathWithRect:backgroundFrame];
		
		[backgroundColor set];
		
		[backgroundFill fill];
	}
	
	/* Draw rest of text field. */
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Draw to super. */
	[super drawWithFrame:cellFrame inView:controlView];
	
	/* Maybe not draw icon. */
	if ([self onlyShowStatusIfErrorOccurs]) {
		if ([self parentValueIsValid]) {
			return; // Do not continue, we have valid value.
		}
	}
	
	/* Draw status image badge. */
	NSImage *statusImage = nil;
	
	if ([self parentValueIsValid] == NO) {
		statusImage = [NSImage imageNamed:@"ErroneousTextFieldValueIndicator"];
	} else {
		if ([self parentValueIsEmpty] == NO) {
			statusImage = [NSImage imageNamed:@"ProperlyFormattedTextFieldValueIndicator"];
		}
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

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	
	[self recalculatePositionOfClipView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
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
	NSRect clipViewRect = [clipView frame];
	
	clipViewRect.size.width = [self correctedWidthForClipViewRect];
	
	[clipView setFrame:clipViewRect];
	
	[[self parentField] resetCursorRects];
}

- (NSRect)parentViewFrame
{
	return [[self parentField] frame];
}

- (void)recalculatePositionOfClipView
{
	[[self parentField] recalculatePositionOfClipView];
}

- (BOOL)parentValueIsEmpty
{
	return [[self parentField] valueIsEmpty];
}

- (BOOL)parentValueIsValid
{
	return [[self parentField] valueIsValid];
}

- (BOOL)onlyShowStatusIfErrorOccurs
{
	return [[self parentField] onlyShowStatusIfErrorOccurs];
}

@end
