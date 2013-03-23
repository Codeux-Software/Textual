
#import "TextualApplication.h"

int main(int argc, const char *argv[])
{
	[RZUserDefaults() addSuiteNamed:@"com.codeux.textual"];
	[RZUserDefaults() addSuiteNamed:@"com.codeux.irc.textual"];
	[RZUserDefaults() addSuiteNamed:@"com.codeux.irc.textual.trial"];

	NSApplicationMain(argc, argv);

    return 0;
}
