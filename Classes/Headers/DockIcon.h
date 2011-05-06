// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface DockIcon : NSObject
+ (void)drawWithoutCounts;
+ (void)drawWithHilightCount:(NSInteger)hilight_count messageCount:(NSInteger)message_count;
@end