// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

@interface NSOutlineView (TXOutlineViewHelper)
- (NSArray *)groupItems;
- (BOOL)isGroupItem:(id)item;

- (NSInteger)rowsInGroup:(id)group;
- (NSInteger)countSelectedRows;

- (void)selectItemAtIndex:(NSInteger)index;
@end