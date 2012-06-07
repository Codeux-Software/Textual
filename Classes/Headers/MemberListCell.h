// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCUser;

@interface MemberListCell : NSTextFieldCell
{
    id __unsafe_unretained cellItem;
	IRCUser *__weak member;
    MemberList *__weak parent;
}

@property (nonatomic, unsafe_unretained) id cellItem;
@property (nonatomic, weak) IRCUser *member;
@property (nonatomic, weak) MemberList *parent;
@end