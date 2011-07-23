// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSWindow (NSWindowHelper)
- (void)exactlyCenterWindow;
- (void)centerOfWindow:(NSWindow *)window;

- (BOOL)isOnCurrentWorkspace;
@end