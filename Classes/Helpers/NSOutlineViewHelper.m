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

- (NSArray *)groupItems
{
	NSMutableArray *groups = [NSMutableArray array];
	
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		id curRow = [self itemAtRow:i];
		
		if ([self isGroupItem:curRow]) {
			[groups addInteger:i];
		}
	}
	
	return groups;
}

- (NSInteger)rowsInGroup:(id)group
{
	NSInteger totalRows = 0;
	
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		id curRow = [self itemAtRow:i];
		
		if ([self isGroupItem:curRow]) {
			id parent = [self parentForItem:curRow];
			
			if ([parent isEqual:group]) {
				totalRows++;
			}
		}
	}
	
	return totalRows;
}

@end