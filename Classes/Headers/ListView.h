// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define DefaultListViewFont             [NSFont fontWithName:@"Lucida Grande" size:12.0]

@interface ListView : NSTableView
{
	id __unsafe_unretained keyDelegate;
	id __unsafe_unretained textDelegate;
}

@property (nonatomic, unsafe_unretained) id keyDelegate;
@property (nonatomic, unsafe_unretained) id textDelegate;

- (NSInteger)countSelectedRows;
- (NSArray *)selectedRows;
- (void)selectItemAtIndex:(NSInteger)index;
- (void)selectRows:(NSArray *)indices;
- (void)selectRows:(NSArray *)indices extendSelection:(BOOL)extend;
@end

@interface NSObject (ListViewDelegate)
- (void)listViewDelete;
- (void)listViewMoveUp;
- (void)listViewKeyDown:(NSEvent *)e;
@end