#import <Cocoa/Cocoa.h>

typedef unsigned long long TXLongInt;

/* Textual specific items header declarations */

extern NSTimeInterval IntervalSinceTextualStart(void);
extern NSString *TXReadableTime(NSTimeInterval date, BOOL longFormat);

/* Plugin Specific Class */

@interface TPI_SP_SysInfo : NSObject 

+ (NSString *)compiledOutput;
+ (NSString *)model;
+ (NSNumber *)processorCount;
+ (NSString *)processorL2CacheSize;
+ (NSString *)processorL3CacheSize;
+ (NSString *)processorClockSpeed;
+ (NSString *)physicalMemorySize;
+ (NSString *)loadAverages;
+ (NSString *)systemUptime;
+ (NSString *)diskInfo;
+ (NSString *)graphicsCardInfo;
+ (NSString *)applicationMemoryUsage;

@end