// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSTextField (NSTextFieldHelper)

static NSColor *_oldTextColor = nil;

- (void)setFontColor:(NSColor *)color
{
	_oldTextColor = [self textColor];
	
	[self setTextColor:color];
}

- (void)pasteFilteredAttributedStringValue:(NSAttributedString *)string
{
	string = [string attributedStringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	string = [string sanitizeNSLinkedAttributedString:[self textColor]];
	
	[self setFilteredAttributedStringValue:string];
}

- (void)setFilteredAttributedStringValue:(NSAttributedString *)string
{
	string = [string attributedStringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	string = [string sanitizeIRCCompatibleAttributedString:[self textColor] 
												  oldColor:_oldTextColor
										   backgroundColor:[self backgroundColor]
											   defaultFont:[self font]];
	
	[super setAttributedStringValue:string];
}

@end