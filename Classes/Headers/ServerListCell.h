// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCTreeItem;

@interface ServerListCell : NSTextFieldCell 
{
	ServerList *parent;
	IRCTreeItem *cellItem;
}

@property (nonatomic, assign) ServerList *parent;
@property (nonatomic, assign) IRCTreeItem *cellItem;
@end