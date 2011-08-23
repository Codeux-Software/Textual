// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ServerList

@synthesize keyDelegate;

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row 
{
	NSRect nrect = [super frameOfCellAtColumn:column row:row];
	
	id childItem = [self itemAtRow:row];
	
	if ([self isGroupItem:childItem] == NO) {
		if ([Preferences applicationRanOnLion]) {
			nrect.origin.x   += 35;
			nrect.size.width  = ([self frame].size.width - 35);
		} else {
			nrect.origin.x   += 35;
			nrect.size.width -= 35;
		}
	} else {
		nrect.origin.x   += 15;
		nrect.size.width -= 15;
	} 
	
	return nrect;
}

- (void)toggleAddServerButton
{
	NSRect clipRect = [self frame];
	
	MasterController *master = [keyDelegate master];
	MenuController   *menucl = [master menu];
	
	if (NSObjectIsEmpty([keyDelegate clients])) { 
		[master.addServerButton setHidden:NO];
		[master.addServerButton setTarget:menucl];
		[master.addServerButton setAction:@selector(onAddServer:)];
		
		NSRect winRect = [master.serverSplitView frame];
		NSRect oldRect = [master.addServerButton frame];
		
		oldRect.origin = NSMakePoint((NSMidX(clipRect) - (oldRect.size.width / 2.0)), 
									 (NSMidY(winRect) - (oldRect.size.height / 2.0)));
		
		[master.addServerButton setFrame:oldRect];
	} else {
		[master.addServerButton setHidden:YES];
	}
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

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	[self toggleAddServerButton];
}

@end