
int main(int argc, const char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[Preferences validateStoreReceipt];
    NSApplicationMain(argc, argv);
	[pool release];
    return 0;
}
