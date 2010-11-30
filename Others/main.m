#import "ValidateReceipt.h"

int main(int argc, const char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// VALIDATE_APPSTORE_RECEIPT is only defined when the "App Store Release"
	// target is built during compiling. Normal releases ignore this defintiion. 
	
#ifdef VALIDATE_APPSTORE_RECEIPT
#if VALIDATE_APPSTORE_RECEIPT == 1
	
	if (USE_SAMPLE_RECEIPT) {
		if (validateReceiptAtPath(@"~/Documents/AppStoreReceipt") == NO) {
			exit(173);
		}
	} else {
		if (validateReceiptAtPath([[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"]) == NO) {
			exit(173);
		}
	}
	
#endif
#endif
	
    NSApplicationMain(argc, argv);
	[pool release];
    return 0;
}