// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#include "SystemProfiler.h"

@interface TPI_SP_SysInfo : NSObject 
+ (NSString *)compiledOutput;

+ (NSString *)model;
+ (NSString *)processor;
+ (NSString *)processorCount;
+ (NSString *)processorL2CacheSize;
+ (NSString *)processorL3CacheSize;
+ (NSString *)processorClockSpeed;

+ (NSString *)operatingSystemName;

+ (NSString *)systemMemoryUsage;
+ (NSString *)physicalMemorySize;
+ (TXFSLongInt)freeMemorySize;
+ (TXFSLongInt)totalMemorySize;

+ (NSString *)loadAveragesWithCores:(NSInteger)cores;

+ (NSString *)systemUptime;
+ (NSString *)systemUptimeUsingShortValue:(BOOL)shortValue;

+ (NSString *)diskInfo;
+ (NSString *)networkStats;
+ (NSString *)graphicsCardInfo;
+ (NSString *)allVolumesAndSizes;
+ (NSString *)applicationMemoryUsage;
+ (NSString *)activeScreenResolutions;
+ (NSString *)applicationAndSystemUptime;
+ (NSString *)systemLoadAverage;
+ (NSString *)applicationRunCount;
+ (NSString *)bandwidthStatsFrom:(IRCWorld *)world;
+ (NSString *)logThemeInformationFrom:(IRCWorld *)world;

+ (NSString *)formattedDiskSize:(TXFSLongInt)size;
+ (NSString *)formattedCPUFrequency:(TXNSDouble)rate;
@end