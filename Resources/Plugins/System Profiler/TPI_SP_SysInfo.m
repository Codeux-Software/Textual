/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TPI_SP_SysInfo.h"

#define _localVolumeBaseDirectory		@"/Volumes"
#define _systemMemoryDivisor			1.073741824

@implementation TPI_SP_CompiledOutput

+ (NSString *)applicationConfiguredFontInformation
{
	return TPIFLS(@"SystemInformationSFontCommandResult", [TPCPreferences themeChannelViewFontName], [TPCPreferences themeChannelViewFontSize]);
}

+ (NSString *)applicationActiveStyle
{
	NSString *fname = [TPCThemeController extractThemeName:[TPCPreferences themeName]];
    NSString *ftype = [TPCThemeController extractThemeSource:[TPCPreferences themeName]];

	NSMutableString *resultString = [NSMutableString string];

    if ([ftype isEqualIgnoringCase:TPCThemeControllerCustomStyleNameBasicPrefix]) {
		[resultString appendString:TPIFLS(@"SystemInformationStyleCommandResultCustom", fname)];
    } else {
		[resultString appendString:TPIFLS(@"SystemInformationStyleCommandResultBundle", fname)];
    }

	if ([TPCPreferences invertSidebarColors]) {
		[resultString appendString:TPILS(@"SystemInformationStyleCommandResultDarkMode")];
	} else {
		[resultString appendString:TPILS(@"SystemInformationStyleCommandResultLightMode")];
	}

	if ([NSColor currentControlTint] == NSGraphiteControlTint) {
		[resultString appendString:TPILS(@"SystemInformationStyleCommandResultGraphiteMode")];
	} else {
		[resultString appendString:TPILS(@"SystemInformationStyleCommandResultAquaMode")];
	}

	return resultString;
}

+ (NSString *)applicationAndSystemUptime
{
	NSArray *dateFormat = @[@"day", @"hour", @"minute", @"second"];
	
	NSString *systemUptime = TXSpecialReadableTime([TPI_SP_SysInfo systemUptime], NO, dateFormat);
	NSString *textualUptime = TXSpecialReadableTime([TPI_SP_SysInfo applicationUptime], NO, dateFormat);

	return TPIFLS(@"SystemInformationUptimeCommandResult", systemUptime, textualUptime);
}

+ (NSString *)applicationBandwidthStatistics
{
    IRCWorld *world = [TPI_SP_CompiledOutput worldController];

	IRCClient *client = world.selectedClient;

	NSTimeInterval lastMsg = [NSDate secondsSinceUnixTimestamp:client.lastMessageReceived];
	
	return TPIFLS(@"SystemInformationMsgcountCommandResult",
				  TXFormattedNumber(world.messagesSent),
				  TXFormattedNumber(world.messagesReceived),
				  TXSpecialReadableTime(lastMsg, YES, @[@"second"]),
				  [TPI_SP_SysInfo formattedDiskSize:world.bandwidthIn],
				  [TPI_SP_SysInfo formattedDiskSize:world.bandwidthOut]);
}

+ (NSString *)applicationMemoryUsage
{
	NSDictionary *mem = [TPI_SP_SysInfo applicationMemoryInformation];

	NSString *shared  = [TPI_SP_SysInfo formattedDiskSize:[mem integerForKey:@"shared"]];
	NSString *private = [TPI_SP_SysInfo formattedDiskSize:[mem integerForKey:@"private"]];

	return TPIFLS(@"SystemInformationApplicationMemoryUse", private, shared);
}

+ (NSString *)applicationRuntimeStatistics
{
	NSTimeInterval runtime = [TPCPreferences timeIntervalSinceApplicationInstall];

	NSTimeInterval birthday = [NSDate secondsSinceUnixTimestamp:TXBirthdayReferenceDate];

	if (runtime > birthday) {
		runtime = birthday;
	}

	return TPIFLS(@"SystemInformationRuncountCommandResult",
				  TXFormattedNumber([TPCPreferences applicationRunCount]),
				  TXReadableTime(runtime));
}

+ (NSString *)systemCPULoadInformation
{
	NSUInteger _cpu_count_v	= [TPI_SP_SysInfo processorVirtualCoreCount];
	
	return TPIFLS(@"SystemInformationLoadavgCommandResult", [TPI_SP_SysInfo loadAverageWithCores:_cpu_count_v]);
}

+ (NSString *)systemDiskspaceInformation
{
	NSMutableString *result = [NSMutableString string];

	NSArray *drives = [RZFileManager() contentsOfDirectoryAtPath:_localVolumeBaseDirectory error:NULL];

	NSInteger objectIndex = 0;

	for (NSString *name in drives) {
		NSString *fullpath = [_localVolumeBaseDirectory stringByAppendingPathComponent:name];

		FSRef fsRef;
		FSCatalogInfo catalogInfo;

		struct statfs stat;

		const char *fsRep = [fullpath fileSystemRepresentation];

		if ((FSPathMakeRef((const UInt8 *)fsRep, &fsRef, NULL) == 0) == NO) {
			continue;
		}

		if ((FSGetCatalogInfo(&fsRef, kFSCatInfoParentDirID, &catalogInfo, NULL, NULL, NULL) == 0) == NO) {
			continue;
		}

		BOOL isVolume = (catalogInfo.parentDirID == fsRtParID);

		if (isVolume) {
			if (statfs(fsRep, &stat) == 0) {
				NSString *fileSystemName = [RZFileManager() stringWithFileSystemRepresentation:stat.f_fstypename length:strlen(stat.f_fstypename)];

				if ([fileSystemName isEqualToString:@"hfs"]) {
					NSDictionary *diskInfo = [RZFileManager() attributesOfFileSystemForPath:fullpath error:NULL];

					if (diskInfo) {
						TXFSLongInt totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
						TXFSLongInt freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];

						if (objectIndex == 0) {
							[result appendString:TPIFLS(@"SystemInformationDiskspaceCommandResultBase", name,
														[TPI_SP_SysInfo formattedDiskSize:totalSpace],
														[TPI_SP_SysInfo formattedDiskSize:freeSpace])];
						} else {
							[result appendString:TPIFLS(@"SystemInformationDiskspaceCommandResultMiddle", name,
														[TPI_SP_SysInfo formattedDiskSize:totalSpace],
														[TPI_SP_SysInfo formattedDiskSize:freeSpace])];
						}

						objectIndex++;
					}
				}
			}
		}
	}

	if (NSObjectIsEmpty(result)) {
		return TPILS(@"SystemInformationDiskspaceCommandResultError");
	} else {
		return TPIFLS(@"SystemInformationDiskspaceCommandResultPrefix", result);
	}
}

+ (NSString *)systemDisplayInformation
{
	NSArray *screens = [NSScreen screens];

	if (screens.count == 1) {
		NSScreen *maiScreen = RZMainScreen();

		NSString *result = TPIFLS(@"SystemInformationScreensCommandResultSingle",
								  maiScreen.frame.size.width,
								  maiScreen.frame.size.height);

		if ([TPCPreferences runningInHighResolutionMode]) {
			result = [result stringByAppendingString:TPILS(@"SystemInformationScreensCommandResultHighResoMode")];
		}

		return result;
	} else {
		NSMutableString *result = [NSMutableString string];

		for (NSScreen *screen in screens) {
			NSInteger screenNumber = ([screens indexOfObject:screen] + 1);

			if (screenNumber == 1) {
				[result appendString:TPIFLS(@"SystemInformationScreensCommandResultMultiBase",
											screenNumber,
											screen.frame.size.width,
											screen.frame.size.height)];
			} else {
				[result appendString:TPIFLS(@"SystemInformationScreensCommandResultMultiMiddle",
											screenNumber,
											screen.frame.size.width,
											screen.frame.size.height)];
			}

			if ([screen runningInHighResolutionMode]) {
				[result appendString:@"SystemInformationScreensCommandResultHighResoMode"];
			}
		}

		return result;
	}
}

+ (NSString *)systemInformation
{
	NSString *sysinfo = TPILS(@"SystemInformationCompiledOutputPrefix");

	NSString *_new;

	NSString *_model			= [TPI_SP_SysInfo model];
	NSString *_cpu_model		= [TPI_SP_SysInfo processor];
	NSString *_cpu_speed		= [TPI_SP_SysInfo processorClockSpeed];

	NSUInteger _cpu_count_p		= [TPI_SP_SysInfo processorPhysicalCoreCount];
	NSUInteger _cpu_count_v		= [TPI_SP_SysInfo processorVirtualCoreCount];

	NSString *_memory		= [TPI_SP_SysInfo formattedTotalMemorySize];
	NSString *_gpu_model	= [TPI_SP_SysInfo formattedGraphicsCardInformation];
	NSString *_loadavg		= [TPI_SP_SysInfo loadAverageWithCores:_cpu_count_v];

	NSBundle *_bundle		= [NSBundle bundleForClass:[self class]];

	_cpu_model = [TLORegularExpression string:_cpu_model replacedByRegex:@"(\\s*@.*)|CPU|\\(R\\)|\\(TM\\)"	withString:NSStringWhitespacePlaceholder];
	_cpu_model = [TLORegularExpression string:_cpu_model replacedByRegex:@"\\s+"							withString:NSStringWhitespacePlaceholder];

	_cpu_model = [_cpu_model trim];

	BOOL _show_cpu_model	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> CPU Model"] == NO);
	BOOL _show_gpu_model	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> GPU Model"] == NO);
	BOOL _show_diskinfo		= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Disk Information"] == NO);
	BOOL _show_sys_uptime	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> System Uptime"] == NO);
	BOOL _show_sys_memory	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Memory Information"] == NO);
	BOOL _show_screen_res	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Screen Resolution"] == NO);
	BOOL _show_load_avg		= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Load Average"] == NO);
	BOOL _show_os_version	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> OS Version"] == NO);

	/* Mac Model. */
	if (NSObjectIsNotEmpty(_model)) {
		NSDictionary *_all_models = [NSDictionary dictionaryWithContentsOfFile:[_bundle pathForResource:@"MacintoshModels" ofType:@"plist"]];

		if (NSObjectIsEmpty(_all_models)) {
			NSAssert(NO, @"_all_models");
		}

		NSString *_exact_model = [CSFWSystemInformation systemModelName];

		if ([_all_models containsKey:_model]) {
			_exact_model = _all_models[_model];
		}

		_new = TPIFLS(@"SystemInformationCompiledOutputModel", _exact_model);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_cpu_model) {
		/* CPU Information. */
		if (_cpu_count_p >= 1 && NSObjectIsNotEmpty(_cpu_speed)) {
			_new = TPIFLS(@"SystemInformationCompiledOutputCPUCore", _cpu_model, _cpu_count_v, _cpu_count_p, _cpu_speed);

			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}

	if (_show_sys_memory && _memory) {
		_new = TPIFLS(@"SystemInformationCompiledOutputMemory", _memory);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_sys_uptime) {
		/* System Uptime. */
		_new = TPIFLS(@"SystemInformationCompiledOutputUptime", TXSpecialReadableTime([TPI_SP_SysInfo systemUptime], YES, nil));

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_diskinfo) {
		/* Disk Space Information. */
		_new = TPIFLS(@"SystemInformationCompiledOutputDiskspace", [TPI_SP_SysInfo formattedLocalVolumeDiskUsage]);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_gpu_model) {
		/* GPU Information. */
		if (NSObjectIsNotEmpty(_gpu_model)) {
			_new = TPIFLS(@"SystemInformationCompiledOutputGraphics", _gpu_model);

			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}

	if (_show_screen_res) {
		/* Screen Resolution. */
		NSScreen *maiScreen = RZMainScreen();

		if ([TPCPreferences runningInHighResolutionMode]) {
			_new = TPIFLS(@"SystemInformationCompiledOutputScreenResolutionHighResoMode",
						  maiScreen.frame.size.width,
						  maiScreen.frame.size.height);
		} else {
			_new = TPIFLS(@"SystemInformationCompiledOutputScreenResolution",
						  maiScreen.frame.size.width,
						  maiScreen.frame.size.height);
		}

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_load_avg) {
		/* Load Average. */
		if (NSObjectIsNotEmpty(_loadavg)) {
			_new = TPIFLS(@"SystemInformationCompiledOutputLoad", _loadavg);

			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}

	if (_show_os_version) {
		/* Operating System. */
		NSString *osname = [TPI_SP_SysInfo operatingSystemName];

		_new = TPIFLS(@"SystemInformationCompiledOutputOSVersion",
					  [CSFWSystemInformation systemOperatingSystemName],
					  [CSFWSystemInformation systemStandardVersion], osname,
					  [CSFWSystemInformation systemBuildVersion]);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if ([sysinfo hasSuffix:@" \002•\002"]) {
		sysinfo = [sysinfo safeSubstringToIndex:(sysinfo.length - 3)];
	}

	/* Compiled Output. */
	return sysinfo;
}

+ (NSString *)systemMemoryInformation
{
	TXFSLongInt totalMemory = [TPI_SP_SysInfo totalMemorySize];
	TXFSLongInt freeMemory  = [TPI_SP_SysInfo freeMemorySize];
	TXFSLongInt usedMemory  = (totalMemory - freeMemory);

	CGFloat rawPercent = (usedMemory / (CGFloat)totalMemory);
	CGFloat memPercent = roundf((rawPercent * 100.0f) / 10.0f);
	CGFloat rightCount = (10.0f - memPercent);

	NSMutableString *result = [NSMutableString string];

	[result appendFormat:@"%c04", 0x03];

	for (NSInteger i = 0; i <= memPercent; i++) {
		[result appendString:@"❙"];
	}

	[result appendFormat:@"%c|%c03", 0x03, 0x03];

	for (NSInteger i = 0; i <= rightCount; i++) {
		[result appendString:@"❙"];
	}

	[result appendFormat:@"%c", 0x03];

	return TPIFLS(@"SystemInformationSysmemCommandResult",
				  [TPI_SP_SysInfo formattedDiskSize:freeMemory],
				  [TPI_SP_SysInfo formattedDiskSize:usedMemory],
				  [TPI_SP_SysInfo formattedDiskSize:totalMemory], result);
}

+ (NSString *)systemNetworkInformation
{
	/* Based off the source code of "libtop.c" */

	NSMutableString *netstat = [NSMutableString string];

	long net_ibytes = 0;
	long net_obytes = 0;

	struct ifaddrs *ifa_list = 0, *ifa;

	if (getifaddrs(&ifa_list) == -1) {
		return nil;
	}

	NSInteger objectIndex = 0;

	for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
		if ((AF_LINK == ifa->ifa_addr->sa_family) == NO) {
			continue;
		}
		
		if ((ifa->ifa_flags & IFF_UP) == NO && (ifa->ifa_flags & IFF_RUNNING) == NO) {
			continue;
		}

		if (ifa->ifa_data == 0) {
			continue;
		}

		if (strncmp(ifa->ifa_name, "lo", 2)) {
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;

			if (if_data->ifi_ibytes < 20000000 || if_data->ifi_obytes < 2000000) {
				continue;
			}

			net_obytes += if_data->ifi_obytes;
			net_ibytes += if_data->ifi_ibytes;

			if (objectIndex == 0) {
				[netstat appendString:TPIFLS(@"SystemInformationNetstatsCommandResultBase",
											 @(ifa->ifa_name),
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_ibytes],
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_obytes])];
			} else {
				[netstat appendString:TPIFLS(@"SystemInformationNetstatsCommandResultMiddle",
											 @(ifa->ifa_name),
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_ibytes],
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_obytes])];
			}

			objectIndex += 1;
		}
	}

	if (ifa_list) {
	    freeifaddrs(ifa_list);
	}

	if (NSObjectIsEmpty(netstat)) {
		return TPILS(@"SystemInformationNetstatsCommandResultError");
	} else {
		return TPIFLS(@"SystemInformationNetstatsCommandResultPrefix", netstat);
	}

	return netstat;
}

@end

@implementation TPI_SP_SysInfo

#pragma mark -
#pragma mark Formatting/Processing 

+ (NSString *)formattedDiskSize:(TXFSLongInt)size
{
	/* Use cocoa API if available. */
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		return [NSByteCountFormatter stringFromByteCountWithPaddedDigits:size];
	}

	/* Use our own math. */
	if (size >= 1000000000000.0) {
		return TPIFLS(@"SystemInformationFilesizeTB", (size / 1000000000000.0));
	} else {
		if (size < 1000000000.0) {
			if (size < 1000000.0) {
				return TPIFLS(@"SystemInformationFilesizeKB", (size / 1000.0));
			} else {
				return TPIFLS(@"SystemInformationFilesizeMB", (size / 1000000.0));
			}
		} else {
			return TPIFLS(@"SystemInformationFilesizeGB", (size / 1000000000.0));
		}
	}
}

+ (NSString *)formattedCPUFrequency:(double)rate
{
	if ((rate / 1000000) >= 990) {
		return TPIFLS(@"SystemInformationCPUClockSpeedGHz", ((rate / 100000000.0) / 10.0));
	} else {
		return TPIFLS(@"SystemInformationCPUClockSpeedMHz", rate);
	}
}

+ (NSString *)formattedTotalMemorySize
{
	return [self formattedDiskSize:[self totalMemorySize]];
}

+ (NSString *)formattedLocalVolumeDiskUsage
{
	NSDictionary *diskInfo = [RZFileManager() attributesOfFileSystemForPath:@"/" error:nil];

	if (diskInfo) {
		TXFSLongInt totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
		TXFSLongInt freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];

		return TPIFLS(@"SystemInformationCompiledOutputDiskspaceExtended",
					  [self formattedDiskSize:totalSpace],
					  [self formattedDiskSize:freeSpace]);
	} else {
		return nil;
	}
}

+ (NSString *)formattedGraphicsCardInformation
{
    CFMutableDictionaryRef pciDevices = IOServiceMatching("IOPCIDevice");

    io_iterator_t entry_iterator;

    if (IOServiceGetMatchingServices(kIOMasterPortDefault, pciDevices, &entry_iterator) == kIOReturnSuccess) {
        NSMutableArray *gpuList = [NSMutableArray new];

        io_iterator_t serviceObject;

        while ((serviceObject = IOIteratorNext(entry_iterator))) {
            CFMutableDictionaryRef serviceDictionary;

			kern_return_t status = IORegistryEntryCreateCFProperties(serviceObject,
																	 &serviceDictionary,
																	 kCFAllocatorDefault,
																	 kNilOptions);

			if (NSDissimilarObjects(status, kIOReturnSuccess)) {
                IOObjectRelease(serviceObject);

                continue;
            }

            const void *model = CFDictionaryGetValue(serviceDictionary, @"model");

            if (PointerIsNotEmpty(model)) {
                if (CFGetTypeID(model) == CFDataGetTypeID() && CFDataGetLength(model) > 1) {
					NSString *s = nil;

					s = [NSString stringWithBytes:[(__bridge NSData *)model bytes]
										   length:CFDataGetLength(model)
										 encoding:NSASCIIStringEncoding];

					s = [s stringByReplacingOccurrencesOfString:@"\0" withString:NSStringEmptyPlaceholder];

                    [gpuList addObject:s];
                }
            }

            CFRelease(serviceDictionary);
        }

		// ---- //

		NSInteger objectIndex = 0;

        NSMutableString *result = [NSMutableString string];

		for (NSString *model in gpuList) {
			if (objectIndex == 0) {
				[result appendString:TPIFLS(@"SystemInformationGraphicsInformationResultBase", model)];
			} else {
				[result appendString:TPIFLS(@"SystemInformationGraphicsInformationResultMiddle", model)];
			}

			objectIndex++;
		}
		
        return result;
    }
	
    return nil;
}

#pragma mark -
#pragma mark System Information

+ (NSInteger)systemUptime
{
	struct timeval boottime;
	
	size_t size = sizeof(boottime);
	
	if (sysctlbyname("kern.boottime", &boottime, &size, NULL, 0) == -1) {
		boottime.tv_sec = 0;
	}
	
	return [NSDate secondsSinceUnixTimestamp:boottime.tv_sec];
}

+ (NSInteger)applicationUptime
{
	return [TPCPreferences timeIntervalSinceApplicationLaunch];
}

+ (NSString *)loadAverageWithCores:(NSInteger)cores
{
	double load_ave[3];
	
	if (getloadavg(load_ave, 3) == 3) {
		return [NSString stringWithFormat:@"%.0f", ((load_ave[0] * 100) / cores)];
	}
	
	return nil;
}

+ (NSString *)processor
{
	char buffer[256];
	
	size_t sz = sizeof(buffer);
	
	if (sysctlbyname("machdep.cpu.brand_string", buffer, &sz, NULL, 0) == 0) {
		buffer[(sizeof(buffer) - 1)] = 0;
		
		return @(buffer);
	}

	return nil;
}

+ (NSString *)model
{
	char modelBuffer[256];
	
	size_t sz = sizeof(modelBuffer);
	
	if (sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0) == 0) {
		modelBuffer[(sizeof(modelBuffer) - 1)] = 0;
		
		return @(modelBuffer);
	}

	return nil;
}

+ (NSUInteger)processorPhysicalCoreCount
{
	u_int64_t size = 0L;

	size_t len = sizeof(size);

	if (sysctlbyname("hw.physicalcpu", &size, &len, NULL, 0) == 0) {
		return size;
	}

	return 0;
}

+ (NSUInteger)processorVirtualCoreCount
{
	u_int64_t size = 0L;

	size_t len = sizeof(size);

	if (sysctlbyname("hw.logicalcpu", &size, &len, NULL, 0) == 0) {
		return size;
	}

	return 0;
}

+ (NSString *)processorClockSpeed
{
	u_int64_t clockrate = 0L;
	
	size_t len = sizeof(clockrate);
	
	if (sysctlbyname("hw.cpufrequency", &clockrate, &len, NULL, 0) >= 0) {
		return [self formattedCPUFrequency:clockrate];
	}

	return nil;
}

+ (NSString *)operatingSystemName
{
	NSString *productVersion = [CSFWSystemInformation systemStandardVersion];
	
	if ([productVersion hasPrefix:@"10.7"]) {
		return TPILS(@"SystemInformationOSVersionLion");
	}
	
	if ([productVersion hasPrefix:@"10.8"]) {
		return TPILS(@"SystemInformationOSVersionMountainLion");
	}
	
	return nil;
}

+ (TXFSLongInt)freeMemorySize
{
	mach_msg_type_number_t infoCount = (sizeof(vm_statistics_data_t) / sizeof(natural_t));
	
	vm_size_t              pagesize;
	vm_statistics_data_t   vm_stat;
	
	host_page_size(mach_host_self(), &pagesize);
	
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &infoCount) == KERN_SUCCESS) {
		return ((vm_stat.inactive_count + vm_stat.free_count) * pagesize);
	}
	
	return -1;
}

+ (TXFSLongInt)totalMemorySize
{
	uint64_t linesize = 0L;
	
	size_t len = sizeof(linesize);
	
	if (sysctlbyname("hw.memsize", &linesize, &len, NULL, 0) >= 0) {
		return (linesize / _systemMemoryDivisor);
	} 
	
	return -1;
}

+ (NSDictionary *)applicationMemoryInformation
{
	kern_return_t kernr;
	
	mach_vm_address_t addr = 0;
	
	NSInteger shrdmem = -1;
	NSInteger privmem = 0;
	
	NSInteger pagesize = getpagesize();
	
	while (1 == 1) {
		mach_vm_address_t size;

		vm_region_top_info_data_t info;

		mach_msg_type_number_t count = VM_REGION_TOP_INFO_COUNT;
		mach_port_t object_name;

		kernr = mach_vm_region(mach_task_self(), &addr, &size, VM_REGION_TOP_INFO,
							   (vm_region_info_t)&info, &count, &object_name);

		if (NSDissimilarObjects(kernr, KERN_SUCCESS)) {
			break;
		}
		
		if (info.share_mode == SM_PRIVATE) {
			privmem += (info.private_pages_resident * pagesize);
			shrdmem += (info.shared_pages_resident * pagesize);
		} else if (info.share_mode == SM_COW) {
			privmem += (info.private_pages_resident * pagesize);
			shrdmem += (info.shared_pages_resident * (pagesize / info.ref_count));
		} else if (info.share_mode == SM_SHARED) {
			shrdmem += (info.shared_pages_resident * (pagesize / info.ref_count));
		}
		
		addr += size;
	}
	
	return @{
		@"shared" : @(shrdmem),
		@"private" : @(privmem)
	};
}

@end
