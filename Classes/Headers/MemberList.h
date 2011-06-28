// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface MemberList : ListView
@end

@interface NSObject (MemberListViewDelegate)
- (void)memberListViewKeyDown:(NSEvent *)e;
@end