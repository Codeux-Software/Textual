// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#include "SystemProfiler.h"

@interface TPI_SP_SysInfo : NSObject 
+ (NSString *)compiledOutput;
+ (NSString *)model;
+ (NSString *)processor;
+ (NSNumber *)processorCount;
+ (NSString *)processorL2CacheSize;
+ (NSString *)processorL3CacheSize;
+ (NSString *)processorClockSpeed;
+ (NSString *)kernelArchitecture;
+ (NSString *)getSystemMemoryUsage;
+ (NSString *)physicalMemorySize;
+ (TXFSLongInt)freeMemorySize;
+ (TXFSLongInt)totalMemorySize;
+ (NSString *)loadAveragesWithCores:(NSInteger)cores;
+ (NSString *)systemUptime;
+ (NSString *)systemUptimeUsingShortValue:(BOOL)shortValue;
+ (NSString *)diskInfo;
+ (NSString *)getNetworkStats;
+ (NSString *)graphicsCardInfo;
+ (NSString *)getAllVolumesAndSizes;
+ (NSString *)applicationMemoryUsage;
+ (NSString *)getAllScreenResolutions;
+ (NSString *)applicationAndSystemUptime;
+ (NSString *)getSystemLoadAverage;
+ (NSString *)getTextualRunCount;
+ (NSString *)getBandwidthStats:(IRCWorld *)world;
+ (NSString *)getCurrentThemeInUse:(IRCWorld *)world;
+ (NSString *)formattedDiskSize:(TXFSLongInt)size;
+ (NSString *)formattedCPUFrequency:(NSDoubleN)rate;
@end