// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSTextField (NSTextFieldHelper)

- (void)focus
{
	NSText		*edito = [self currentEditor];
	NSTextField *field = [self.window selectedTextField];	
	
	if (field != self) {
		[self.window makeFirstResponder:nil];
		[self.window makeFirstResponder:self];
		
		NSRange newRange = NSMakeRange([self stringLength], 0);
		
		[edito setSelectedRange:newRange];
		[edito scrollRangeToVisible:newRange];
	}
}

- (NSInteger)stringLength
{
	return [[self stringValue] length];
}

- (NSRange)selectedRange
{
	return [[self currentEditor] selectedRange];
}

@end