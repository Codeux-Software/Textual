// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSTextView (NSTextViewHelper)

- (BOOL)isFocused
{
    return BOOLReverseValue(NSDissimilarObjects([self.window firstResponder], self));
}

- (void)focus
{
    if ([self isFocused] == NO) {
        [self.window makeFirstResponder:self];
        
        NSRange newRange = NSMakeRange([self stringLength], 0);
        
        [self setSelectedRange:newRange];
        [self scrollRangeToVisible:newRange];
    }
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
