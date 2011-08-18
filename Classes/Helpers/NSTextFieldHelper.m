// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSTextView (NSTextViewHelper)

- (BOOL)isFocused
{
    return BOOLReverseValue(NSDissimilarObjects([self.window firstResponder], self));
}

- (void)focus
{
    if ([self isFocused]) {
        return;
    }
    
    [self.window makeFirstResponder:self];
}

- (NSRange)fullSelectionRange
{
    return NSMakeRange(0, [self stringLength]);
}

- (NSInteger)stringLength
{
    return [self.string length];
}

- (NSScrollView *)scrollView
{
    return (id)self.superview.superview;
}

@end
