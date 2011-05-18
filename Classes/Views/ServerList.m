// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ServerList

@synthesize keyDelegate;

- (NSRect)rectOfRow:(NSInteger)row
{
	NSRect rect = [super rectOfRow:row];
	
	id childItem  = [self itemAtRow:row];
	
	if ([self isGroupItem:childItem] == NO) {
		rect.origin.y    += 4;
		rect.size.height += 1;
	} 
	
	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row 
{
	NSRect superFrame = [super frameOfCellAtColumn:column row:row];
	
	id childItem  = [self itemAtRow:row];
	
	if ([self isGroupItem:childItem] == NO) {
		superFrame.origin.x   += 25;
		superFrame.size.width -= 25;
	} 
	
	return superFrame;
}

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint   p = [self convertPoint:[e locationInWindow] fromView:nil];
	NSInteger i = [self rowAtPoint:p];
	
	if (i >= 0) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return [keyDelegate treeMenu];
	}
	
	return [self menu];
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
				if ([keyDelegate respondsToSelector:@selector(serverListKeyDown:)]) {
					[keyDelegate serverListKeyDown:e];
				}
				
				break;
		}
	}
}

@end