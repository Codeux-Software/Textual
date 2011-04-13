// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSObject (NSObjectHelper)
+ (id)newad; // New Auto Drained Instance
- (id)adrv; // Auto Drained Retained Value
- (id)autodrain;
- (oneway void)drain;
- (oneway void)forcedrain;
@end