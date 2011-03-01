// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_PreferencePaneExample.h"

@implementation TPI_PreferencePaneExample

- (NSView *)preferencesView
{
	if (ourView == nil) {
		if ([NSBundle loadNibNamed:@"PreferencePane" owner:self] == NO) {
			NSLog(@"TPI_PrefsTest: Failed to load view.");
		}
	}
	
	return ourView;
}

- (NSString *)preferencesMenuItemName
{
	return @"My Test Plugin";
}

@end