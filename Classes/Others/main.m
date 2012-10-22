
#import "TextualApplication.h"

int main(int argc, const char *argv[])
{
	[_NSUserDefaults() addSuiteNamed:@"com.codeux.textual"];
	[_NSUserDefaults() addSuiteNamed:@"com.codeux.irc.textual"];
	[_NSUserDefaults() addSuiteNamed:@"com.codeux.irc.textual.trial"];

	@autoreleasepool {
		NSApplicationMain(argc, argv);
	}
	
    return 0;
}
