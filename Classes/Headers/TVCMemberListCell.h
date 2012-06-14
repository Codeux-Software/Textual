// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@interface TVCMemberListCell : NSTextFieldCell
@property (nonatomic, unsafe_unretained) id cellItem;
@property (nonatomic, weak) IRCUser *member;
@property (nonatomic, weak) TVCMemberList *parent;
@end