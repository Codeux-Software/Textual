// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class IRCTreeItem;

@interface ServerListCell : NSTextFieldCell 
@property (nonatomic, weak) ServerList *parent;
@property (nonatomic, weak) IRCTreeItem *cellItem;
@end