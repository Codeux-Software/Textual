#import <Cocoa/Cocoa.h>

@interface TreeView : NSOutlineView
{
	id keyDelegate;
}

@property (assign) id keyDelegate;

- (NSInteger)countSelectedRows;
- (void)selectItemAtIndex:(NSInteger)index;
@end

@interface NSObject (TreeViewDelegate)
- (void)treeViewKeyDown:(NSEvent*)e;
@end