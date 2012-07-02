// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define _DefaultTextFieldWidthPadding		1.0
#define _DefaultTextFieldHeightPadding		2.0

@implementation TVCTextField

- (void)dealloc
{
	dispatch_release(self.formattingQueue);
	self.formattingQueue = NULL;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

	if (self) {
		if ([TPCPreferences rightToLeftFormatting]) {
			[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
		} else {
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
		}
        
        [super setTextContainerInset:NSMakeSize(_DefaultTextFieldWidthPadding, _DefaultTextFieldHeightPadding)];
        
        if (PointerIsEmpty(self.keyHandler)) {
            self.keyHandler = [TLOKeyEventHandler new];
        }
        
        self.formattingQueue = dispatch_queue_create("formattingQueue", NULL);
    }
	
    return self;
}

- (dispatch_queue_t)formattingQueue
{
    return _formattingQueue;
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
    return @[NSPasteboardTypeString];
}

- (NSAttributedString *)attributedStringValue
{
    return self.attributedString.copy;
}

- (void)setAttributedStringValue:(NSAttributedString *)string
{
	NSData *stringData = [string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil];
    
    [self replaceCharactersInRange:[self fullSelectionRange] withRTF:stringData];
}

- (NSString *)stringValue
{
    return [self string];
}

- (void)setStringValue:(NSString *)string
{
    [self replaceCharactersInRange:[self fullSelectionRange] withString:string];
}

- (void)removeAttribute:(id)attr inRange:(NSRange)local
{
    [self.textStorage removeAttribute:attr range:local];
}

- (void)setAttributes:(id)attrs inRange:(NSRange)local
{
    [self.textStorage setAttributes:attrs range:local];
}

- (void)sanitizeTextField:(BOOL)paste
{
	[self sanitizeIRCCompatibleAttributedString:BOOLReverseValue(paste)];
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
	
	NSString *stringv = self.stringValue;
	
	if (selr.location <= stringv.length) {
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
		
		if (blr.location == lineRange.location &&
			blr.length == lineRange.length) {
			
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
