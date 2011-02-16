// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSTextField (NSTextFieldHelper)

- (void)focus
{
	[self.window makeFirstResponder:nil];
	[self.window makeFirstResponder:self];
	
	NSText *e = [self currentEditor];
	
	[e setSelectedRange:NSMakeRange([[self stringValue] length], 0)];
	[e scrollRangeToVisible:[e selectedRange]];
}

- (NSRange)selectedRange
{
	return [[self currentEditor] selectedRange];
}

@end