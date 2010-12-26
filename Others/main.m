#import "ValidateReceipt.h"

int main(int argc, const char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// VALIDATE_APPSTORE_RECEIPT is only defined when the "App Store Release"
	// target is built during compiling. Normal releases ignore this defintiion. 
	
#if !defined(DEBUG) && !defined(IS_TRIAL_BINARY)
#ifdef VALIDATE_APPSTORE_RECEIPT
#if VALIDATE_APPSTORE_RECEIPT == 1
	
    NSString *receipt = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"];
    
    if ([TXNSFileManager() fileExistsAtPath:receipt] == NO) {
		exit(173);
	} else {
		BOOL validRec = validateReceiptAtPath(receipt);
		
		if (validRec == NO) {
			exit(173);
		} else {
			NSLog(@"Valid app store receipt located. Launching.");
		}
	}
	
#endif
#endif
#endif
	
    NSApplicationMain(argc, argv);
	[pool release];
    return 0;
}
