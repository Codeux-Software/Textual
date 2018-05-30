
#import "TPI_PreferencePaneExample.h"

@implementation TPI_PreferencePaneExample

- (instancetype)init
{
    self = [super init];

	if (self) {
		if ([TPIBundleFromClass() loadNibNamed:@"PreferencePane" owner:self topLevelObjects:nil] == NO) {
			NSAssert(NO, @"TPI_PreferencePaneExample: Failed to load view");
		}
    }

    return self;
}

- (NSView *)pluginPreferencesPaneView
{
	return self.ourView;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return @"My Test Plugin";
}

- (void)doSomethingWithPreferences
{
	BOOL isSomethingChecked = [RZUserDefaults() boolForKey:@"TPIPreferencesSomethingCheckboxIsChecked"];
	
	if (isSomethingChecked) {
		LogToConsole("Checkbox is checked");
	} else {
		LogToConsole("Checkbox is not checked");
	}
}

- (IBAction)preferenceChanged:(id)sender
{
	[self doSomethingWithPreferences];
}

@end
