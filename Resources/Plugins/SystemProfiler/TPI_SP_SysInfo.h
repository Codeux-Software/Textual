#import <Cocoa/Cocoa.h>

#include "GlobalModels.h"

typedef unsigned long long TXLongInt;

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
+ (NSString *)applicationAndSystemUptime;

@end