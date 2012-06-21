// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@interface TVCMemberList : TVCListView
- (void)updateBackgroundColor;
@end

@interface NSObject (MemberListViewDelegate)
- (void)memberListViewKeyDown:(NSEvent *)e;
@end