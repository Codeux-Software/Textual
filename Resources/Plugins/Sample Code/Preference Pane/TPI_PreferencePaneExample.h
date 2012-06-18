// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TPI_PreferencePaneExample : NSObject 
{
	IBOutlet NSView *ourView;
} 

- (NSView *)preferencesView;
- (NSString *)preferencesMenuItemName;

@end