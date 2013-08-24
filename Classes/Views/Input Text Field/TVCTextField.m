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

@implementation TVCTextField

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

	if (self) {
		self.delegate = self;

		if ([TPCPreferences rightToLeftFormatting]) {
			[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
		} else {
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
		}

		[self setDefaultTextFieldFont:TXDefaultTextFieldFont];

		[self defineDefaultTypeSetterAttributes];
		[self updateTypeSetterAttributes];

        [super setTextContainerInset:NSMakeSize(TXDefaultTextFieldWidthPadding, TXDefaultTextFieldHeightPadding)];

        if (PointerIsEmpty(self.keyHandler)) {
            self.keyHandler = [TLOKeyEventHandler new];
        }
        
        self.formattingQueue = dispatch_queue_create("formattingQueue", NULL);
    }
	
    return self;
}

- (void)dealloc
{
	dispatch_release(self.formattingQueue);

	self.formattingQueue = NULL;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self.window makeFirstResponder:self];

    [super mouseDown:theEvent];
}


- (NSColor *)defaultTextColor
{
    
    return [NSColor defineUserInterfaceItem:TXDefaultTextFieldFontColor
                               invertedItem:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]
                               withOperator:[TPCPreferences invertSidebarColors]];
}

#pragma mark -
#pragma mark Keyboard Shorcuts

- (void)setKeyHandlerTarget:(id)target
{
	[self.keyHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[self.keyHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[self.keyHandler registerSelector:selector character:c modifiers:mods];
}

- (void)keyDown:(NSEvent *)e
{
	if ([self.keyHandler processKeyEvent:e]) {
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
    return self.attributedString.copy;
}

- (void)setAttributedStringValue:(NSAttributedString *)string
{
	NSData *stringData = [string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil];
    
    [self replaceCharactersInRange:[self fullSelectionRange] withRTF:stringData];

	[self didChangeText];
}

- (NSString *)stringValue
{
    return [self string];
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
	
	//DebugLogToConsole(@"%@; %@", attributes, NSStringFromRange(local));

	[self.undoManager registerUndoWithTarget:self
									selector:@selector(setAttributesWithContext:)
									  object:@[attributes, NSStringFromRange(local)]];
}

- (void)setAttributesWithContext:(NSArray *)contextArray /* @private */
{
	NSRange local = NSRangeFromString(contextArray[1]);

	NSDictionary *attrs = [self.attributedString attributesAtIndex:0
											 longestEffectiveRange:NULL
														   inRange:local];

	[self.undoManager registerUndoWithTarget:self
									selector:@selector(setAttributesWithContext:)
									  object:@[attrs, NSStringFromRange(local)]];

	//DebugLogToConsole(@"old: %@; new: %@", attrs, contextArray[0]);
	
	[self setAttributes:contextArray[0] inRange:local];
}

#pragma mark -

- (void)removeAttribute:(id)attr inRange:(NSRange)local
{
    [self.textStorage removeAttribute:attr range:local];
}

- (void)setAttributes:(id)attrs inRange:(NSRange)local
{
	[self.textStorage addAttributes:attrs range:local];
}

#pragma mark -

- (void)textDidChange:(NSNotification *)aNotification
{
	if (self.string.length < 1) {
		[self defineDefaultTypeSetterAttributes]; // -------------/
		[self updateTypeSetterAttributes]; // Reset these values when field becomes empty.
	}

	if ([self respondsToSelector:@selector(internalTextDidChange:)]) {
		[self performSelector:@selector(internalTextDidChange:) withObject:aNotification];
	}
}

#pragma mark -

- (void)updateAllFontSizesToMatchTheDefaultFont
{
	CGFloat newPointSize = self.defaultTextFieldFont.pointSize;

    [self.textStorage beginEditing];

    [self.textStorage enumerateAttribute:NSFontAttributeName
                            inRange:[self fullSelectionRange]
                            options:0
                         usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		NSFont *oldfont = value;

		if (NSDissimilarObjects(oldfont.pointSize, newPointSize)) {
			NSFont *font = [RZFontManager() convertFont:value toSize:newPointSize];

			if (PointerIsNotEmpty(font)) {
				[self.textStorage removeAttribute:NSFontAttributeName range:range];
				
				[self.textStorage addAttribute:NSFontAttributeName value:font range:range];
			}
		}
	}];

    [self.textStorage endEditing];
}

- (void)updateTypeSetterAttributes
{
	[self setTypingAttributes:@{NSFontAttributeName : self.defaultTextFieldFont, NSForegroundColorAttributeName : TXDefaultTextFieldFontColor}];
}

- (void)defineDefaultTypeSetterAttributes
{
	[self setFont:self.defaultTextFieldFont];

	[self setTextColor:TXDefaultTextFieldFontColor];
	[self setInsertionPointColor:TXDefaultTextFieldFontColor];
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
	NSRange selr = self.selectedRange;
	
	if (selr.location <= self.stringLength) {
		[layoutManager lineFragmentRectForGlyphAtIndex:selr.location effectiveRange:&blr];
	} else {
		return -1;
	}
	
	/* Loop through the range of each line in our text view using
	 the same technique we use for counting our total number of 
	 lines. If a range matches our base while looping, then that 
	 is our selected line number. */
	NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	
	NSRange lineRange;
	
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
		[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];

		if (NSEqualRanges(blr, lineRange)) {
			return (numberOfLines + 1);
		}
		
		index = NSMaxRange(lineRange);
	}

	return [self numberOfLines];
}

- (NSInteger)numberOfLines
{
	/* Base line number count. */
	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	
	NSRange lineRange;
	
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
		[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];

		index = NSMaxRange(lineRange);
	}
	
	/* The method used above for counting the number of lines in
	 our text view does not take into consideration blank lines at
	 the end of our field. Therefore, we must manually check if the 
	 last line of our input is a blank newline. If it is, then 
	 increase our count by one. */
	NSString *lastChar = [self.stringValue stringCharacterAtIndex:(self.stringLength - 1)];
	
	NSRange nlr = [lastChar rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
	
	if (NSDissimilarObjects(nlr.location, NSNotFound)) {
		numberOfLines += 1;
	}
	
	return numberOfLines;
}

@end
