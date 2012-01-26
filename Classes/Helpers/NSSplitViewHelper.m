// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSSplitView (NSSplitViewHelper)

- (BOOL)hasHiddenView
{
	NSView *leftSide  = [[self subviews] objectAtIndex:0];
	NSView *rightSide = [[self subviews] objectAtIndex:1];
	
	return ([self isSubviewCollapsed:leftSide] || [self isSubviewCollapsed:rightSide]);
}

@end