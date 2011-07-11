// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation MemberList

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[keyDelegate memberListViewKeyDown:e];
				}
				
				break;
		}
	}
    
}

- (void)drawContextMenuHighlightForRow:(int)row
{
    // Do not draw focus ring …
}


- (void)awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}




- (NSInteger)draggedRow:(id <NSDraggingInfo>)sender
{
	NSPoint p = [self convertPoint:[sender draggingLocation] fromView:nil];
    
	return [self rowAtPoint:p];
}

- (void)drawDraggingPoisition:(id <NSDraggingInfo>)sender on:(BOOL)on
{
	if (on) {
		NSInteger row = [self draggedRow:sender];
        
		if (row < 0) {
			[self deselectAll:nil];
		} else {
			[self selectItemAtIndex:row];
		}
	} else {
		[self deselectAll:nil];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ([self draggedRow:sender] >= 0) {
		[self drawDraggingPoisition:sender on:YES];
        
		return NSDragOperationCopy;
	} else {
		[self drawDraggingPoisition:sender on:NO];
        
		return NSDragOperationNone;
	}
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[self drawDraggingPoisition:sender on:NO];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self drawDraggingPoisition:sender on:NO];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return ([self draggedRow:sender] >= 0);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}
/* TODO: MAKE DRAG WORK */



@end