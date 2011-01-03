
int main(int argc, const char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if !defined(DEBUG) && !defined(IS_TRIAL_BINARY)
#ifdef VALIDATE_APPSTORE_RECEIPT
#if VALIDATE_APPSTORE_RECEIPT == 1
	
	[Preferences validateStoreReceipt];
	
#endif
#endif
#endif
	
    NSApplicationMain(argc, argv);
	[pool release];
    return 0;
}
