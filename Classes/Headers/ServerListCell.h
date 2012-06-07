// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCTreeItem;

@interface ServerListCell : NSTextFieldCell 
{
	ServerList *__weak parent;
	IRCTreeItem *__weak cellItem;
}

@property (nonatomic, weak) ServerList *parent;
@property (nonatomic, weak) IRCTreeItem *cellItem;
@end