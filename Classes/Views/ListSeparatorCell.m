// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ListSeparatorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString *value = [self stringValue];
	
	if ([value isEqualToString:ListSeparatorCellIndex]) {
		CGFloat lineWidth = 0;
		CGFloat lineX = 0;
		CGFloat lineY = 0;
		
		lineWidth = cellFrame.size.width;
		
		lineY = ((cellFrame.size.height - 2) / 2);
		lineY += 1.0;
		
		NSRect lineRect = NSMakeRect((cellFrame.origin.x + lineX), 
									 (cellFrame.origin.y + lineY), lineWidth, 0.5);
		
		[[NSColor darkGrayColor] set];
		NSRectFill(lineRect);
	} else {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

@end