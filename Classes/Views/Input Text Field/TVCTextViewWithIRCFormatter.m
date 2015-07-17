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

#define TVCTextViewWithIRCFormatterWidthPadding		1.0
#define TVCTextViewWithIRCFormatterHeightPadding	2.0

@implementation TVCTextViewWithIRCFormatter

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

	if (self) {
		[self setDelegate:self];

		if ([TPCPreferences rightToLeftFormatting]) {
			[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
		} else {
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
		}

		self.keyEventHandler = [TLOKeyEventHandler new];

		[super setTextContainerInset:NSMakeSize(TVCTextViewWithIRCFormatterWidthPadding,
												TVCTextViewWithIRCFormatterHeightPadding)];

		/* These are the default values. Any class using this one is expected
		 to define their own values at some point. */
		[self setPreferredFont:[NSFont systemFontOfSize:12.0]];
		
		[self setPreferredFontColor:[NSColor blueColor]];
    }
	
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self window] makeFirstResponder:self];

    [super mouseDown:theEvent];
}

#pragma mark -
#pragma mark Keyboard Shorcuts

- (void)setKeyHandlerTarget:(id)target
{
	[self.keyEventHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[self.keyEventHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[self.keyEventHandler registerSelector:selector character:c modifiers:mods];
}

- (void)keyDown:(NSEvent *)e
{
	if ([self.keyEventHandler processKeyEvent:e]) {
		return;
	}

	[self keyDownToSuper:e];
}

- (void)keyDownToSuper:(NSEvent *)e
{
	[super keyDown:e];
}

#pragma mark -
#pragma mark Value Management

- (NSArray *)readablePasteboardTypes
{
	return @[NSPasteboardTypeString, NSFilenamesPboardType];
}

- (NSArray *)acceptableDragTypes
{
	return @[NSPasteboardTypeString, NSFilenamesPboardType];
}

- (NSAttributedString *)attributedStringValue
{
	return [[self attributedString] copy];
}

- (NSString *)stringValue
{
	return [[self string] copy];
}

- (void)setAttributedStringValue:(NSAttributedString *)string
{
	[[self undoManager] removeAllActions];

	NSData *stringData = [string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil];

    [self replaceCharactersInRange:[self fullSelectionRange] withRTF:stringData];

	[self didChangeText];
}

- (void)setStringValue:(NSString *)string
{
    [self replaceCharactersInRange:[self fullSelectionRange] withString:string];

	[self didChangeText];
}

#pragma mark -
#pragma mark Attribute Management

- (void)addUndoActionForAttributes:(NSDictionary *)attributes inRange:(NSRange)local
{
	if (NSObjectIsEmpty(attributes) || NSRangeIsValid(local) == NO) {
		return;
	}
	
	[[self undoManager] registerUndoWithTarget:self
									  selector:@selector(setAttributesWithContext:)
										object:@[attributes, NSStringFromRange(local)]];
}

- (void)setAttributesWithContext:(NSArray *)contextArray /* @private */
{
	NSRange local = NSRangeFromString(contextArray[1]);
	
	NSDictionary *attrs = [[self attributedString] attributesAtIndex:0
											   longestEffectiveRange:NULL
															 inRange:local];
	
	[[self undoManager] registerUndoWithTarget:self
									  selector:@selector(setAttributesWithContext:)
										object:@[attrs, NSStringFromRange(local)]];
	
	[self setAttributes:contextArray[0] inRange:local];
}

#pragma mark -

- (void)removeAttribute:(id)attr inRange:(NSRange)local
{
    [[self textStorage] removeAttribute:attr range:local];
}

- (void)setAttributes:(id)attrs inRange:(NSRange)local
{
	[[self textStorage] addAttributes:attrs range:local];
}

#pragma mark -

- (void)textDidChange:(NSNotification *)aNotification
{
	if ([self stringLength] < 1) {
		[self resetTypeSetterAttributes];
	}

	if ([self respondsToSelector:@selector(internalTextDidChange:)]) {
		[self performSelector:@selector(internalTextDidChange:) withObject:aNotification];
	}
}

#pragma mark -

- (void)updateAllFontSizesToMatchTheDefaultFont
{
	CGFloat newPointSize = [self.preferredFont pointSize];

    [[self textStorage] beginEditing];

    [[self textStorage] enumerateAttribute:NSFontAttributeName
								inRange:[self fullSelectionRange]
								options:0
							usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		NSFont *oldfont = value;

		if (fabs([oldfont pointSize]) == fabs(newPointSize)) {
			;
		} else {
			NSFont *font = [RZFontManager() convertFont:value toSize:newPointSize];

			if (font) {
				[[self textStorage] removeAttribute:NSFontAttributeName range:range];

				[[self textStorage] addAttribute:NSFontAttributeName value:font range:range];
			}
		}
	}];

    [[self textStorage] endEditing];
}

- (void)setPreferredFont:(NSFont *)preferredFont
{
	if (_preferredFont == preferredFont) {
		;
	} else {
		_preferredFont = [preferredFont copy];

		[self modifyTypingAttributes:@{NSFontAttributeName : _preferredFont}];
	}
}

- (void)setPreferredFontColor:(NSColor *)preferredFontColor
{
	if (_preferredFontColor == preferredFontColor) {
		;
	} else {
		_preferredFontColor = [preferredFontColor copy];

		[self modifyTypingAttributes:@{NSForegroundColorAttributeName : _preferredFontColor}];

		[self setInsertionPointColor:_preferredFontColor];
	}
}

- (void)resetTypeSetterAttributes
{
	[self setTypingAttributes:@{
		NSFontAttributeName : self.preferredFont,

		NSForegroundColorAttributeName : self.preferredFontColor
	}];
}

- (void)modifyTypingAttributes:(NSDictionary *)typingAttributes
{
	NSMutableDictionary *existingAttributes = [[self typingAttributes] mutableCopy];

	[existingAttributes addEntriesFromDictionary:typingAttributes];

	[self setTypingAttributes:existingAttributes];
}

- (void)resetTextColorInRange:(NSRange)range
{
	NSDictionary *newAttributes = @{
		NSForegroundColorAttributeName : self.preferredFontColor
	};

	[[self textStorage] setAttributes:newAttributes range:range];
}

#pragma mark -
#pragma mark Line Counting

- (BOOL)isAtBottomOfView
{
	return ([self selectedLineNumber] == [self numberOfLines]);
}

- (BOOL)isAtTopOfView
{
	return ([self selectedLineNumber] == 1);
}

- (NSInteger)selectedLineNumber
{
	NSLayoutManager *layoutManager = [self layoutManager];
	
	/* Range of selected line. */
	NSRange blr;
	NSRange selr = [self selectedRange];
	
	if (selr.location <= [self stringLength]) {
		[layoutManager lineFragmentRectForGlyphAtIndex:selr.location effectiveRange:&blr];
	} else {
		return -1;
	}
	
	/* Loop through the range of each line in our text view using
	 the same technique we use for counting our total number of
	 lines. If a range matches our base while looping, then that
	 is our selected line number. */
	NSUInteger numberOfLines = 0;
	NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
	
	NSRange lineRange;
	
	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		[layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];
		
		if (NSEqualRanges(blr, lineRange)) {
			return (numberOfLines + 1);
		}
		
		i = NSMaxRange(lineRange);
	}
	
	return [self numberOfLines];
}

- (NSInteger)numberOfLines
{
	/* Base line number count. */
	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSUInteger numberOfLines = 0;
	NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
	
	NSRange lineRange;
	
	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		[layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];
		
		i = NSMaxRange(lineRange);
	}
	
	/* The method used above for counting the number of lines in
	 our text view does not take into consideration blank lines at
	 the end of our field. Therefore, we must manually check if the
	 last line of our input is a blank newline. If it is, then
	 increase our count by one. */
	NSInteger lastIndex = ([self stringLength] - 1);
	
	UniChar lastChar = [[self stringValue] characterAtIndex:lastIndex];
	
	if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) {
		numberOfLines += 1;
	}
	
	return numberOfLines;
}

- (NSInteger)highestHeightBelowHeight:(NSInteger)maximumHeight withPadding:(NSInteger)valuePadding
{
	/* Base line number count. */
	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSUInteger totalLineHeight = valuePadding;
	
	NSUInteger numberOfLines = 0;
	NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
	
	BOOL skipNewlineSymbolCheck = NO;
	
	NSRange lineRange;
	
	for (NSUInteger i = 0; i < numberOfGlyphs; numberOfLines++) {
		NSRect r = [layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:&lineRange];
		
		if ((totalLineHeight +  r.size.height) <= maximumHeight) {
			 totalLineHeight += r.size.height;
		} else {
			skipNewlineSymbolCheck = YES;
			
			break;
		}
		
		i = NSMaxRange(lineRange);
	}
	
	if (skipNewlineSymbolCheck == NO) {
		NSInteger lastIndex = ([self stringLength] - 1);
		
		UniChar lastChar = [[self stringValue] characterAtIndex:lastIndex];
		
		if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) {
			CGFloat defaultHeight = [layoutManager defaultLineHeightForFont:self.preferredFont];
			
			if ((totalLineHeight +  defaultHeight) <= maximumHeight) {
				 totalLineHeight += defaultHeight;
			}
		}
	}
	
	return totalLineHeight;
}

@end
