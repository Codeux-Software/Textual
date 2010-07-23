#import <Cocoa/Cocoa.h>

void TXCFSpecialRelease(CFTypeRef cf);

NSString *TXTLS(NSString *key);

extern NSTimeInterval IntervalSinceTextualStart(void);
extern NSString *TXFormattedTimestamp(NSString *format);
extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat);
extern NSString *promptForInput(NSString *whatFor, 
					  NSString *title, 
					  NSString *defaultButton, 
					  NSString *altButton, 
					  NSString *defaultInput);