// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCUser;

@interface MemberListCell : NSTextFieldCell
{
    id cellItem;
	IRCUser *member;
    MemberList *parent;
}

@property (nonatomic, assign) id cellItem;
@property (nonatomic, assign) IRCUser *member;
@property (nonatomic, assign) MemberList *parent;
@end