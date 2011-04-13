// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface TextField : NSTextField
{
	id _oldInputValue;
    
	NSColor *_oldTextColor;
    
	BOOL _usesCustomUndoManager;
    BOOL _spellingAlreadyToggled;
}

@property (readonly) id _oldInputValue;
@property (readonly) NSColor *_oldTextColor;
@property (readonly) BOOL _usesCustomUndoManager;
@property (readonly) BOOL _spellingAlreadyToggled;

- (void)setFontColor:(NSColor *)color;

- (void)removeAllUndoActions;
- (void)setUsesCustomUndoManager:(BOOL)customManager;

- (void)pasteFilteredAttributedString:(NSRange)selectedRange;

- (void)setStringValue:(NSString *)aString;
- (void)setAttributedStringValue:(NSAttributedString *)obj;
- (void)setFilteredAttributedStringValue:(NSAttributedString *)string;

- (void)setObjectValue:(id)obj recordUndo:(BOOL)undo;
@end