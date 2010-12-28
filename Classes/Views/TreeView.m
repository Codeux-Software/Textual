// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TreeView

@synthesize keyDelegate;

- (NSInteger)countSelectedRows
{
	return [[self selectedRowIndexes] count];
}

- (void)selectItemAtIndex:(NSInteger)index
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[self scrollRowToVisible:index];
}

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];
	NSInteger i = [self rowAtPoint:p];
	if (i >= 0) {
		[self selectItemAtIndex:i];
	}
	return [self menu];
}

- (void)setFont:(NSFont *)font
{
	for (NSTableColumn *column in [self tableColumns]) {
		[[column dataCell] setFont:font];
	}
	
	NSRect frame = self.frame;
	frame.size.height = 1e+37;
	CGFloat height = [[[[self tableColumns] safeObjectAtIndex:0] dataCell] cellSizeForBounds:frame].height;
	[self setRowHeight:ceil(height)];
	[self setNeedsDisplay:YES];
}

- (NSFont *)font
{
	return [[[[self tableColumns] safeObjectAtIndex:0] dataCell] font];
}

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([keyDelegate respondsToSelector:@selector(treeViewKeyDown:)]) {
					[keyDelegate treeViewKeyDown:e];
				}
				break;
		}
	}
	
	[super keyDown:e];
}

@end