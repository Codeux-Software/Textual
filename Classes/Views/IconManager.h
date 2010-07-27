// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface IconManager : NSObject

- (void)drawBlankApplicationIcon;
- (NSString*)badgeFilename:(NSInteger)count;
- (void)drawApplicationIcon:(NSInteger)hlcount msgcount:(NSInteger)pmcount;

@end