#import <Cocoa/Cocoa.h>

@interface ListView : NSTableView
{
	id keyDelegate;
	id textDelegate;
}

@property (assign) id keyDelegate;
@property (assign) id textDelegate;

- (NSInteger)countSelectedRows;
- (void)selectItemAtIndex:(NSInteger)index;
- (void)selectRows:(NSArray*)indices;
- (void)selectRows:(NSArray*)indices extendSelection:(BOOL)extend;
@end

@interface NSObject (ListViewDelegate)
- (void)listViewDelete;
- (void)listViewMoveUp;
- (void)listViewKeyDown:(NSEvent*)e;
@end