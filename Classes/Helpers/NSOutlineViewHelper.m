// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSOutlineView (NSOutlineViewHelper)

- (NSInteger)countSelectedRows
{
	return [[self selectedRowIndexes] count];
}

- (void)selectItemAtIndex:(NSInteger)index
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[self scrollRowToVisible:index];
}

- (BOOL)isGroupItem:(id)item
{
	return ([self levelForItem:item] == 0);
}

@end