// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TVCMainWindowSegmentedControl
@end

@implementation TVCMainWindowSegmentedCell

- (SEL)action
{
    if (PointerIsEmpty([self menuForSegment:self.selectedSegment])) {
		[self.menuController showNicknameChangeDialog:nil];

		return nil;
    } else {
        return [super action];
    }
}

@end