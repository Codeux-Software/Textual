// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface URLParser : NSObject
+ (NSArray *)locatedLinksForString:(NSString *)body;
+ (NSArray *)bannedURLRegexLineTypes;
@end