
int main(int argc, const char* argv[])
{
	@autoreleasepool {

		[_NSUserDefaults() addSuiteNamed:@"com.codeux.irc.textual.trial"];
		
#if !defined(DEBUG) && !defined(IS_TRIAL_BINARY)
#ifdef VALIDATE_APPSTORE_RECEIPT
#if VALIDATE_APPSTORE_RECEIPT == 1
		
		[Preferences validateStoreReceipt];
		
#endif
#endif
#endif
		
    NSApplicationMain(argc, argv);
	}
    return 0;
}
