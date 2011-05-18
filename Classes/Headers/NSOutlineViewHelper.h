// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSOutlineView (NSOutlineViewHelper)
- (BOOL)isGroupItem:(id)item;
- (NSInteger)countSelectedRows;
- (void)selectItemAtIndex:(NSInteger)index;
@end