
#import "TextualApplication.h"

int main(int argc, const char *argv[])
{
	@autoreleasepool {
		/* Backwards compatibility for 2.1.0 and earlier 
		 which used a different bundle identifier. */
		
		[_NSUserDefaults() addSuiteNamed:TPCPreferencesMigrationAssistantOldBundleIdentifier];
		
		NSApplicationMain(argc, argv);
	}
	
    return 0;
}
