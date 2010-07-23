#import "TextFieldWithDisabledState.h"

@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	[self setTextColor:value ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
}

@end