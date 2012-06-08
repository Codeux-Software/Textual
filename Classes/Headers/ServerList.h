// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@interface ServerList : NSOutlineView
@property (unsafe_unretained) id keyDelegate;

- (void)toggleAddServerButton;
@end

@interface NSObject (ServerListDelegate)
- (void)serverListKeyDown:(NSEvent *)e;
@end