// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSTextField (NSTextFieldHelper)
- (void)setFontColor:(NSColor *)color;

- (void)pasteFilteredAttributedStringValue:(NSAttributedString *)string;
- (void)setFilteredAttributedStringValue:(NSAttributedString *)string;
@end