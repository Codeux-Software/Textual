// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

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