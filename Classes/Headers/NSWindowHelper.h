// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@interface NSWindow (NSWindowHelper)
- (void)exactlyCenterWindow;
- (void)centerOfWindow:(NSWindow *)window;

- (BOOL)isOnCurrentWorkspace;
- (BOOL)isInFullscreenMode;

- (void)closeExistingSheet;
@end