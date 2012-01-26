// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSTextView (NSTextViewHelper)
- (void)focus;
- (BOOL)isFocused;
- (NSRange)fullSelectionRange;
- (NSInteger)stringLength;
- (NSScrollView *)scrollView;
@end