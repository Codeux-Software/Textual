// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TVCMainWindowSegmentedControl
@end

@implementation TVCMainWindowSegmentedCell

@synthesize menuController;

- (SEL)action
{
    if (PointerIsEmpty([self menuForSegment:self.selectedSegment])) {
		[menuController showNicknameChangeDialog:nil];

		return nil;
    } else {
        return [super action];
    }
}

@end