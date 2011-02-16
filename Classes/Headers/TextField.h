// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface TextField : NSTextField
{
	id _oldInputValue;
	NSColor *_oldTextColor;
	BOOL _usesCustomUndoManager;
}

@property (nonatomic, readonly) id _oldInputValue;
@property (nonatomic, readonly) NSColor *_oldTextColor;
@property (nonatomic, readonly) BOOL _usesCustomUndoManager;

- (void)setFontColor:(NSColor *)color;

- (void)removeAllUndoActions;
- (void)setUsesCustomUndoManager:(BOOL)customManager;

- (void)pasteFilteredAttributedString:(NSRange)selectedRange;

- (void)setStringValue:(NSString *)aString;
- (void)setAttributedStringValue:(NSAttributedString *)obj;
- (void)setFilteredAttributedStringValue:(NSAttributedString *)string;

- (void)setObjectValue:(id)obj recordUndo:(BOOL)undo;
@end