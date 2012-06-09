
int main(int argc, const char *argv[])
{
	@autoreleasepool {
		[_NSUserDefaults() addSuiteNamed:@"com.codeux.irc.textual.trial"];
		
		NSApplicationMain(argc, argv);
	}
	
    return 0;
}
