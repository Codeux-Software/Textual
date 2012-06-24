// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@implementation TVCListView

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