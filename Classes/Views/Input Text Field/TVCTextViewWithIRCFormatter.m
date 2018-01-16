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

#import "NSStringHelper.h"
#import "IRCColorFormat.h"
#import "TPCPreferencesLocal.h"
#import "TVCTextViewWithIRCFormatterPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define TVCTextViewWithIRCFormatterWidthPadding		1.0
#define TVCTextViewWithIRCFormatterHeightPadding	2.0

@interface TVCTextViewWithIRCFormatter ()
@property (nonatomic, strong) TLOKeyEventHandler *keyEventHandler;
@end

@implementation TVCTextViewWithIRCFormatter

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	self.delegate = (id)self;

	if ([TPCPreferences rightToLeftFormatting]) {
		self.baseWritingDirection = NSWritingDirectionRightToLeft;
	} else {
		self.baseWritingDirection = NSWritingDirectionLeftToRight;
	}

	self.textContainerInset =
	 NSMakeSize(TVCTextViewWithIRCFormatterWidthPadding,
				TVCTextViewWithIRCFormatterHeightPadding);

	self.keyEventHandler = [[TLOKeyEventHandler alloc] initWithTarget:self];

	// The following serve as defaults and are supposed to be replaced
	self.preferredFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	self.preferredFontColor = [NSColor blackColor];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[self.window makeFirstResponder:self];

	[super mouseDown:theEvent];
}

#pragma mark -
#pragma mark Keyboard Shorcuts

- (void)setKeyHandlerTarget:(id)target
{
	[self.keyEventHandler setKeyHandlerTarget:target];
}

- (void)registerSelector:(SEL)selector key:(NSUInteger)keyCode modifiers:(NSUInteger)modifiers
{
	[self.keyEventHandler registerSelector:selector key:keyCode modifiers:modifiers];
}

- (void)registerSelector:(SEL)selector character:(UniChar)character modifiers:(NSUInteger)modifiers
{
	[self.keyEventHandler registerSelector:selector character:character modifiers:modifiers];
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)modifiers
{
	[self.keyEventHandler registerSelector:selector characters:characterRange modifiers:modifiers];
}

- (BOOL)performedCustomKeyboardEvent:(NSEvent *)e
{
	if ([self.keyEventHandler processKeyEvent:e]) {
		return YES;
	}

	return NO;
}

- (void)keyDownToSuper:(NSEvent *)e
{
	[super keyDown:e];
}

#pragma mark -
#pragma mark Value Management

- (NSArray<NSString *> *)readablePasteboardTypes
{
	return @[NSPasteboardTypeString, NSFilenamesPboardType];
}

- (NSArray<NSString *> *)acceptableDragTypes
{
	return @[NSPasteboardTypeString, NSFilenamesPboardType];
}

- (NSString *)stringValue
{
	return [self.string copy];
}

- (NSString *)stringValueWithIRCFormatting
{
	return [self attributedString].attributedStringToASCIIFormatting;
}

- (void)setStringValue:(NSString *)stringValue
{
	NSParameterAssert(stringValue != nil);

	[self.textStorage replaceCharactersInRange:self.range withString:stringValue];

	[self didChangeText];
}

- (NSAttributedString *)attributedStringValue
{
	return [[self attributedString] copy];
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
	NSParameterAssert(attributedStringValue != nil);

	[self.undoManager removeAllActions];

	[self.textStorage replaceCharactersInRange:self.range withAttributedString:attributedStringValue];

	[self didChangeText];
}

- (void)setStringValueWithIRCFormatting:(NSString *)stringValueWithIRCFormatting
{
	NSParameterAssert(stringValueWithIRCFormatting != nil);

	NSAttributedString *formattedValue =
	[stringValueWithIRCFormatting attributedStringWithIRCFormatting:self.preferredFont
												 preferredFontColor:self.preferredFontColor
										  honorFormattingPreference:NO];

	if (formattedValue) {
		self.attributedStringValue = formattedValue;
	}
}

#pragma mark -

- (void)textDidChange:(NSNotification *)aNotification
{
	if (self.stringLength < 1) {
		[self resetTypeSetterAttributes];
	}
}

#pragma mark -

- (void)updateAllFontSizesToMatchTheDefaultFont
{
	CGFloat newPointSize = self.preferredFont.pointSize;

	[self.textStorage beginEditing];

	[self.textStorage enumerateAttribute:NSFontAttributeName
								 inRange:self.range
								 options:0
							  usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		if (fabs([value pointSize]) == fabs(newPointSize)) {
			return;
		}

		NSFont *font = [RZFontManager() convertFont:value toSize:newPointSize];

		if (font) {
			[self.textStorage removeAttribute:NSFontAttributeName range:range];

			[self.textStorage addAttribute:NSFontAttributeName value:font range:range];
		}
	}];

	[self.textStorage endEditing];
}

- (void)setPreferredFont:(NSFont *)preferredFont
{
	NSParameterAssert(preferredFont != nil);

	if (self->_preferredFont != preferredFont) {
		self->_preferredFont = [preferredFont copy];

		[self modifyTypingAttributes:@{
			NSFontAttributeName : self->_preferredFont
		}];
	}
}

- (void)setPreferredFontColor:(NSColor *)preferredFontColor
{
	NSParameterAssert(preferredFontColor != nil);

	if (self->_preferredFontColor != preferredFontColor) {
		self->_preferredFontColor = [preferredFontColor copy];

		[self modifyTypingAttributes:@{
			NSForegroundColorAttributeName : self->_preferredFontColor
		}];

		self.insertionPointColor = self->_preferredFontColor;
	}
}

- (void)resetTypeSetterAttributes
{
	self.typingAttributes = @{
		NSFontAttributeName : self.preferredFont,
		NSForegroundColorAttributeName : self.preferredFontColor
	};
}

- (void)modifyTypingAttributes:(NSDictionary<NSString *, id> *)typingAttributes
{
	NSMutableDictionary *typingAttributesMutable = [self.typingAttributes mutableCopy];

	[typingAttributesMutable addEntriesFromDictionary:typingAttributes];

	self.typingAttributes = typingAttributesMutable;
}

- (void)resetFontInRange:(NSRange)range
{
	NSDictionary *newAttributes = @{
		NSFontAttributeName : self.preferredFont
	};

	[self.textStorage addAttributes:newAttributes range:range];
}

- (void)resetFontColorInRange:(NSRange)range
{
	NSDictionary *newAttributes = @{
		NSForegroundColorAttributeName : self.preferredFontColor
	};

	[self.textStorage addAttributes:newAttributes range:range];
}

#pragma mark -
#pragma mark Line Counting

- (BOOL)isAtBottomOfView
{
	return (self.selectedLineNumber == self.numberOfLines);
}

- (BOOL)isAtTopOfView
{
	return (self.selectedLineNumber == 1);
}

- (NSUInteger)selectedLineNumber
{
	NSLayoutManager *layoutManager = self.layoutManager;

	NSRange selectionRange = self.selectedRange;

	NSRange selectionLineRange;

	(void)[layoutManager lineFragmentRectForGlyphAtIndex:selectionRange.location effectiveRange:&selectionLineRange];

	/* Loop through the range of each line in our text view using
	 the same technique we use for counting our total number of
	 lines. If a range matches our base while looping, then that
	 is our selected line number. */
	NSUInteger numberOfGlyphs = layoutManager.numberOfGlyphs;

	NSUInteger numberOfLines = 0;

	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		NSRange lineRange;

		(void)[layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];

		if (NSEqualRanges(selectionLineRange, lineRange)) {
			return (numberOfLines + 1);
		}

		i = NSMaxRange(lineRange);
	}

	return self.numberOfLines;
}

- (NSUInteger)numberOfLines
{
	NSLayoutManager *layoutManager = self.layoutManager;

	NSUInteger numberOfGlyphs = layoutManager.numberOfGlyphs;

	NSUInteger numberOfLines = 0;

	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		NSRange lineRange;

		(void)[layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];

		i = NSMaxRange(lineRange);
	}

	/* The method used above for counting the number of lines in
	 our text view does not take into consideration blank lines at
	 the end of our field. Therefore, we must manually check if the
	 last line of our input is a blank newline. If it is, then
	 increase our count by one. */
	NSInteger lastIndex = (self.stringLength - 1);

	UniChar lastCharacter = [self.stringValue characterAtIndex:lastIndex];

	if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
		numberOfLines += 1;
	}

	return numberOfLines;
}

- (CGFloat)highestHeightBelowHeight:(CGFloat)maximumHeight withPadding:(CGFloat)valuePadding
{
	NSLayoutManager *layoutManager = self.layoutManager;

	BOOL skipNewlineSymbolCheck = NO;

	NSUInteger numberOfGlyphs = layoutManager.numberOfGlyphs;

	NSUInteger numberOfLines = 0;

	NSUInteger totalLineHeight = valuePadding;

	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		NSRange lineRange;

		NSRect rect = [layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];

		if ((totalLineHeight +  rect.size.height) <= maximumHeight) {
			 totalLineHeight += rect.size.height;
		} else {
			skipNewlineSymbolCheck = YES;

			break;
		}

		i = NSMaxRange(lineRange);
	}

	if (skipNewlineSymbolCheck == NO) {
		NSInteger lastIndex = (self.stringLength - 1);

		UniChar lastCharacter = [self.stringValue characterAtIndex:lastIndex];

		if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
			CGFloat defaultHeight = [layoutManager defaultLineHeightForFont:self.preferredFont];

			if ((totalLineHeight +  defaultHeight) <= maximumHeight) {
				 totalLineHeight += defaultHeight;
			}
		}
	}

	return totalLineHeight;
}

@end

NS_ASSUME_NONNULL_END
