// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ServerList : NSOutlineView
{
	id __unsafe_unretained keyDelegate;
}

@property (nonatomic, unsafe_unretained) id keyDelegate;

- (void)toggleAddServerButton;
@end

@interface NSObject (ServerListDelegate)
- (void)serverListKeyDown:(NSEvent *)e;
@end