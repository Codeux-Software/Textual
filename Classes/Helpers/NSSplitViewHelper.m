// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSSplitView (NSSplitViewHelper)

- (NSInteger)currentPosition 
{
	NSView *leftFrame = [[self subviews] safeObjectAtIndex:0];
	
	return leftFrame.frame.size.width;
}

@end