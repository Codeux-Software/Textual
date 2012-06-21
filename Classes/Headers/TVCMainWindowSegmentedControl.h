// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TVCMainWindowSegmentedControl : NSSegmentedControl
@end

@interface TVCMainWindowSegmentedCell : NSSegmentedCell
@property (nonatomic, unsafe_unretained) TXMenuController *menuController;
@end