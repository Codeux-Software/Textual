// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@implementation ListView

@synthesize keyDelegate;
@synthesize textDelegate;

- (NSInteger)countSelectedRows
{
	return [[self selectedRowIndexes] count];
}

- (NSArray *)selectedRows
{
    NSMutableArray *allRows = [NSMutableArray array];
    
    NSIndexSet *indexes = [self selectedRowIndexes];
	
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		[allRows safeAddObject:index];
	}
    
    return allRows;
}

- (void)selectItemAtIndex:(NSInteger)index
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[self scrollRowToVisible:index];
}

- (void)selectRows:(NSArray *)indices
{
	[self selectRows:indices extendSelection:NO];
}

- (void)selectRows:(NSArray *)indices extendSelection:(BOOL)extend
{
	NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
	
	for (NSNumber *n in indices) {
		[set addIndex:[n integerValue]];
	}
	
	[self selectRowIndexes:set byExtendingSelection:extend];
}

- (void)rightMouseDown:(NSEvent *)e
{
	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];
	NSInteger i = [self rowAtPoint:p];
	
	if (i >= 0) {
		if ([[self selectedRowIndexes] containsIndex:i] == NO) {
			[self selectItemAtIndex:i];
		}
	}
	
	[super rightMouseDown:e];
}

- (void)setFont:(NSFont *)font
{
	for (NSTableColumn *column in [self tableColumns]) {
		[[column dataCell] setFont:font];
	}
	
	NSRect f = [self frame];
	
	f.size.height = 1e+37;
	
	CGFloat height = ceil([[[[self tableColumns] safeObjectAtIndex:0] dataCell] cellSizeForBounds:f].height);
	
	[self setRowHeight:height];
	[self setNeedsDisplay:YES];
}

- (NSFont *)font
{
	return [[[[self tableColumns] safeObjectAtIndex:0] dataCell] font];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 51:
			case 117:	
				if ([self countSelectedRows] > 0) {
					if ([self.keyDelegate respondsToSelector:@selector(listViewDelete)]) {
						[self.keyDelegate listViewDelete];
						
						return;
					}
				}
				break;
			case 126:	
			{
				NSIndexSet *set = [self selectedRowIndexes];
				
				if (NSObjectIsNotEmpty(set) && [set containsIndex:0]) {
					if ([self.keyDelegate respondsToSelector:@selector(listViewMoveUp)]) {
						[self.keyDelegate listViewMoveUp];
						
						return;
					}
				}
				break;
			}
			case 116:
			case 121:
			case 123 ... 125:	
				break;
			default:
				if ([self.keyDelegate respondsToSelector:@selector(listViewKeyDown:)]) {
					[self.keyDelegate listViewKeyDown:e];
				}
				
				break;
		}
	}
	
	[super keyDown:e];
}

- (void)textDidEndEditing:(NSNotification *)note
{
	if ([self.textDelegate respondsToSelector:@selector(textDidEndEditing:)]) {
		[self.textDelegate textDidEndEditing:note];
	} else {
		[super textDidEndEditing:note];
	}
}

@end