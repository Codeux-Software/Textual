/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation TPI_SP_SysInfo

#pragma mark -
#pragma mark Output Compiler

+ (NSString *)compiledOutput
{
	NSString *sysinfo = TXTLS(@"SystemInformationCompiledOutputPrefix");
	
	NSString *_new;
	
	NSString *_model			= [self model];
	NSString *_cpu_model		= [self processor];
	NSString *_cpu_count		= [self processorCount];
	NSString *_cpu_speed		= [self processorClockSpeed]; 
	NSInteger _cpu_count_int	= [_cpu_count integerValue];
	
	NSString *_cpu_l2		= [self processorL2CacheSize];
	NSString *_cpu_l3		= [self processorL3CacheSize];
	NSString *_memory		= [self physicalMemorySize];
	NSString *_gpu_model	= [self graphicsCardInfo];
	NSString *_loadavg		= [self loadAveragesWithCores:_cpu_count_int];
	
	NSBundle *_bundle		= [NSBundle bundleForClass:[self class]];
	
	_cpu_model = [TLORegularExpression string:_cpu_model replacedByRegex:@"(\\s*@.*)|CPU|\\(R\\)|\\(TM\\)"	withString:NSStringWhitespacePlaceholder];
	_cpu_model = [TLORegularExpression string:_cpu_model replacedByRegex:@"\\s+"							withString:NSStringWhitespacePlaceholder];
	
	_cpu_model = [_cpu_model trim];
	
	BOOL _show_cpu_model	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> CPU Model"];
	BOOL _show_gpu_model	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> GPU Model"];
	BOOL _show_diskinfo		= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> Disk Information"];
	BOOL _show_sys_uptime	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> System Uptime"];
	BOOL _show_sys_memory	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> Memory Information"];
	BOOL _show_screen_res	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> Screen Resolution"];
	BOOL _show_load_avg		= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> Load Average"];
	BOOL _show_os_version	= [_NSUserDefaults() boolForKey:@"System Profiler Extension -> Feature Enabled -> OS Version"];
	
	/* Mac Model. */
	if (NSObjectIsNotEmpty(_model)) {
		NSDictionary *_all_models = [NSDictionary dictionaryWithContentsOfFile:[_bundle pathForResource:@"MacintoshModels" ofType:@"plist"]];
		
		NSString *_exact_model = _model;
		
		if ([_all_models containsKey:_model]) {
			_exact_model = _all_models[_model];
		}
		
		_new = TXTFLS(@"SystemInformationCompiledOutputModel", _exact_model);
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if (_show_cpu_model) {
		/* CPU Information. */
		if (_cpu_count_int >= 1 && NSObjectIsNotEmpty(_cpu_speed)) {
			if (_cpu_count_int == 1) {
				_new = TXTFLS(@"SystemInformationCompiledOutputCPUSingleCore", _cpu_model, _cpu_count, _cpu_speed);
			} else {
				_new = TXTFLS(@"SystemInformationCompiledOutputCPUMultiCore", _cpu_model, _cpu_count, _cpu_speed);
			}
			
			sysinfo = [sysinfo stringByAppendingString:_new];
		}
		
		/* L2 & L3 Cache. */
		if (_cpu_l2) {
			_new = TXTFLS(@"SystemInformationCompiledOutputL2,3Cache", 2, _cpu_l2);
			
			sysinfo = [sysinfo stringByAppendingString:_new];
		}
		
		if (_cpu_l3) {
			_new = TXTFLS(@"SystemInformationCompiledOutputL2,3Cache", 3, _cpu_l3);
			
			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}
	
	if (_show_sys_memory && _memory) {
		_new = TXTFLS(@"SystemInformationCompiledOutputMemory", _memory);
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if (_show_sys_uptime) {
		/* System Uptime. */
		_new = TXTFLS(@"SystemInformationCompiledOutputUptime", [self systemUptimeUsingShortValue:YES]);
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if (_show_diskinfo) {
		/* Disk Space Information. */
		_new = TXTFLS(@"SystemInformationCompiledOutputDiskspace", [self diskInfo]);
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if (_show_gpu_model) {
		/* GPU Information. */
		if (NSObjectIsNotEmpty(_gpu_model)) {
			_new = TXTFLS(@"SystemInformationCompiledOutputGraphics", _gpu_model);
			
			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}
	
	if (_show_screen_res) {
		/* Screen Resolution. */	
		NSScreen *maiScreen = _NSMainScreen();
		
		if ([TPCPreferences runningInHighResolutionMode]) {
			_new = TXTFLS(@"SystemInformationCompiledOutputScreenResolutionHighResoMode",
						  maiScreen.frame.size.width,
						  maiScreen.frame.size.height);
		} else {
			_new = TXTFLS(@"SystemInformationCompiledOutputScreenResolution",
						  maiScreen.frame.size.width,
						  maiScreen.frame.size.height);
		}
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if (_show_load_avg) {
		/* Load Average. */
		if (NSObjectIsNotEmpty(_loadavg)) {
			_new = TXTFLS(@"SystemInformationCompiledOutputLoad", _loadavg);
			
			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}
	
	if (_show_os_version) {
		/* Operating System. */
		NSString *osname = [self operatingSystemName];
		
		_new = TXTFLS(@"SystemInformationCompiledOutputOSVersion",
					  [TPCPreferences systemInfoPlist][@"ProductName"], 
					  [TPCPreferences systemInfoPlist][@"ProductVersion"], osname,
					  [TPCPreferences systemInfoPlist][@"ProductBuildVersion"]);
		
		sysinfo = [sysinfo stringByAppendingString:_new];
	}
	
	if ([sysinfo hasSuffix:@" \002•\002"]) {
		sysinfo = [sysinfo safeSubstringToIndex:(sysinfo.length - 3)];
	}
	
	/* Compiled Output. */
	return sysinfo;
}

+ (NSString *)activeScreenResolutions 
{
	NSArray *screens = [NSScreen screens];
	
	if ([screens count] == 1) {
		NSScreen *maiScreen = _NSMainScreen();
		
		NSString *result = TXTFLS(@"SystemInformationScreensCommandResultSingle",
								  maiScreen.frame.size.width,
								  maiScreen.frame.size.height);
		
		if ([TPCPreferences runningInHighResolutionMode]) {
			result = [result stringByAppendingString:TXTLS(@"SystemInformationScreensCommandResultHighResoMode")];
		}
		
		return result;
	} else {
		NSMutableString *result = [NSMutableString string];
		
		for (NSScreen *screen in screens) {
			NSInteger screenNumber = ([screens indexOfObject:screen] + 1);
			
			if (screenNumber == 1) {
				[result appendString:TXTFLS(@"SystemInformationScreensCommandResultMultiBase",
											screenNumber,
											screen.frame.size.width,
											screen.frame.size.height)];
			} else {
				[result appendString:TXTFLS(@"SystemInformationScreensCommandResultMultiMiddle",
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

+ (NSString *)applicationAndSystemUptime
{
	NSString *systemUptime = TXSpecialReadableTime([self _internalSystemUptime], NO,
												   @[@"day", @"hour", @"minute", @"second"]);
	
	NSString *textualUptime = TXSpecialReadableTime([NSDate secondsSinceUnixTimestamp:[TPCPreferences startTime]], NO,
													@[@"day", @"hour", @"minute", @"second"]);
	
	return TXTFLS(@"SystemInformationUptimeCommandResult", systemUptime, textualUptime);
}

+ (NSString *)logThemeInformationFrom:(IRCWorld *)world
{
	NSString *fname = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	
	if (fname) {
		return TXTFLS(@"SystemInformationThemeCommandResult", fname);
	}
    
    return TXTLS(@"SystemInformationThemeCommandResultError");
}

+ (NSString *)bandwidthStatsFrom:(IRCWorld *)world
{
	CGFloat messageAvg = (world.messagesReceived / ([NSDate epochTime] - [TPCPreferences startTime]));
	
	return TXTFLS(@"SystemInformationMsgcountCommandResult",
				  TXFormattedNumber(world.messagesSent),
				  TXFormattedNumber(world.messagesReceived),
				  [self formattedDiskSize:world.bandwidthIn],
				  [self formattedDiskSize:world.bandwidthOut],
				  messageAvg);
}

+ (NSString *)systemLoadAverage
{
	return TXTFLS(@"SystemInformationLoadavgCommandResult", [self loadAveragesWithCores:0]);
}

+ (NSString *)applicationRunCount
{
	return TXTFLS(@"SystemInformationRuncountCommandResult",
				  TXFormattedNumber([_NSUserDefaults() integerForKey:@"TXRunCount"]),
				  TXReadableTime([TPCPreferences totalRunTime]));
}

+ (NSString *)networkStats
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
		if (AF_LINK != ifa->ifa_addr->sa_family) continue;
		if ((ifa->ifa_flags & IFF_UP) == NO && (ifa->ifa_flags & IFF_RUNNING) == NO) continue;
		if (ifa->ifa_data == 0) continue;
		
		if (strncmp(ifa->ifa_name, "lo", 2)) {
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;
			
			if (if_data->ifi_ibytes < 20000000 || if_data->ifi_obytes < 2000000) continue;
			
			net_obytes += if_data->ifi_obytes;
			net_ibytes += if_data->ifi_ibytes;
			
			if (objectIndex == 0) {
				[netstat appendString:TXTFLS(@"SystemInformationNetstatsCommandResultBase",
											 @(ifa->ifa_name),
											 [self formattedDiskSize:if_data->ifi_ibytes], 
											 [self formattedDiskSize:if_data->ifi_obytes])];
			} else {
				[netstat appendString:TXTFLS(@"SystemInformationNetstatsCommandResultMiddle",
											 @(ifa->ifa_name),
											 [self formattedDiskSize:if_data->ifi_ibytes], 
											 [self formattedDiskSize:if_data->ifi_obytes])];
			}
			
			objectIndex += 1;
		}
	}
	
	if (ifa_list) {
	    freeifaddrs(ifa_list);
	}
	
	if (NSObjectIsEmpty(netstat)) {
		return TXTLS(@"SystemInformationNetstatsCommandResultError");
	} else {
		return TXTFLS(@"SystemInformationNetstatsCommandResultPrefix", netstat);
	}
	
	return netstat;
}

+ (NSString *)systemMemoryUsage
{
	TXFSLongInt totalMemory = [self totalMemorySize];
	TXFSLongInt freeMemory  = [self freeMemorySize];
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
	
	return TXTFLS(@"SystemInformationSysmemCommandResult",
				  [self formattedDiskSize:freeMemory],
				  [self formattedDiskSize:usedMemory],
				  [self formattedDiskSize:totalMemory], result);
}

+ (NSString *)allVolumesAndSizes
{
	NSMutableString *result = [NSMutableString string];
	
	NSArray *drives = [_NSFileManager() contentsOfDirectoryAtPath:_localVolumeBaseDirectory error:NULL];
	
	NSInteger objectIndex = 0;
	
	for (NSString *name in drives) {
		NSString *fullpath = [_localVolumeBaseDirectory stringByAppendingPathComponent:name];
		
		FSRef			fsRef;
		FSCatalogInfo	catalogInfo;
		
		struct statfs stat;
		
		const char *fsRep = [fullpath fileSystemRepresentation];
		
		if (FSPathMakeRef((const UInt8 *)fsRep, &fsRef, NULL) != 0) {
			continue;
		}
		
		if (FSGetCatalogInfo(&fsRef, kFSCatInfoParentDirID, &catalogInfo, NULL, NULL, NULL) != 0) {
			continue;
		}
		
		BOOL isVolume = (catalogInfo.parentDirID == fsRtParID);
		
		if (isVolume) {
			if (statfs(fsRep, &stat) == 0) {
				NSString *fileSystemName = [_NSFileManager() stringWithFileSystemRepresentation:stat.f_fstypename length:strlen(stat.f_fstypename)];
				
				if ([fileSystemName isEqualToString:@"hfs"]) {
					NSDictionary *diskInfo = [_NSFileManager() attributesOfFileSystemForPath:fullpath error:NULL];
					
					if (diskInfo) {
						TXFSLongInt totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
						TXFSLongInt freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];
						
						if (objectIndex == 0) {
							[result appendString:TXTFLS(@"SystemInformationDiskspaceCommandResultBase", name,
														[self formattedDiskSize:totalSpace],
														[self formattedDiskSize:freeSpace])];
						} else {
							[result appendString:TXTFLS(@"SystemInformationDiskspaceCommandResultMiddle", name,
														[self formattedDiskSize:totalSpace],
														[self formattedDiskSize:freeSpace])];
						}
						
						objectIndex++;
					}
				}
			}
		}
	}
	
	if (NSObjectIsEmpty(result)) {
		return TXTLS(@"SystemInformationDiskspaceCommandResultError");
	} else {
		return TXTFLS(@"SystemInformationDiskspaceCommandResultPrefix", result);
	}
}

#pragma mark -
#pragma mark Formatting/Processing 

+ (NSString *)formattedDiskSize:(TXFSLongInt)size
{
	if (size >= 1000000000000.0) {
		return TXTFLS(@"SystemInformationFilesizeTB", (size / 1000000000000.0));
	} else {
		if (size < 1000000000.0) {
			if (size < 1000000.0) {
				return TXTFLS(@"SystemInformationFilesizeKB", (size / 1000.0));
			} else {
				return TXTFLS(@"SystemInformationFilesizeMB", (size / 1000000.0));
			}
		} else {
			return TXTFLS(@"SystemInformationFilesizeGB", (size / 1000000000.0));
		}
	}
}

+ (NSString *)formattedCPUFrequency:(TXNSDouble)rate
{
	if ((rate / 1000000) >= 990) {
		return TXTFLS(@"SystemInformationCPUClockSpeedGHz", ((rate / 100000000.0) / 10.0));
	} else {
		return TXTFLS(@"SystemInformationCPUClockSpeedMHz", rate);
	}
}

#pragma mark -
#pragma mark System Information

+ (NSString *)applicationMemoryUsage
{
	NSDictionary *mem = [TPI_SP_SysInfo _applicationMemoryInternalInformation];
	
	NSString *shared  = [self formattedDiskSize:[mem integerForKey:@"shared"]];
	NSString *private = [self formattedDiskSize:[mem integerForKey:@"private"]];
	
	return TXTFLS(@"SystemInformationApplicationMemoryUse", private, shared);
}

+ (NSString *)graphicsCardInfo
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
				[result appendString:TXTFLS(@"SystemInformationGraphicsInformationResultBase", model)];
			} else {
				[result appendString:TXTFLS(@"SystemInformationGraphicsInformationResultMiddle", model)];
			}

			objectIndex++;
		}
		
        return result;
    }
	
    return nil;
}

+ (NSString *)diskInfo
{	
	NSDictionary *diskInfo = [_NSFileManager() attributesOfFileSystemForPath:@"/" error:nil];
	
	if (diskInfo) {
		TXFSLongInt totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
		TXFSLongInt freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];
		
		return TXTFLS(@"SystemInformationCompiledOutputDiskspaceExtended",
					  [self formattedDiskSize:totalSpace],
					  [self formattedDiskSize:freeSpace]);
	} else {
		return nil;
	}
}

+ (NSInteger)_internalSystemUptime
{
	struct timeval boottime;
	
	size_t size = sizeof(boottime);
	
	if (sysctlbyname("kern.boottime", &boottime, &size, NULL, 0) == -1) {
		boottime.tv_sec = 0;
	}
	
	return [NSDate secondsSinceUnixTimestamp:boottime.tv_sec];
}

+ (NSString *)systemUptimeUsingShortValue:(BOOL)shortValue
{
	return TXSpecialReadableTime([self _internalSystemUptime], shortValue, nil);
}

+ (NSString *)systemUptime
{
	return [self systemUptimeUsingShortValue:NO];	
}

+ (NSString *)loadAveragesWithCores:(NSInteger)cores
{
	TXNSDouble load_ave[3];
	
	if (getloadavg(load_ave, 3) == 3) {
		if (cores > 0) {
			return [NSString stringWithFormat:@"%.0f", (((CGFloat)load_ave[0] * 100) / cores)];
		} else {
			return [NSString stringWithFormat:@"%.2f %.2f %.2f",
					(CGFloat)load_ave[0],
					(CGFloat)load_ave[1],
					(CGFloat)load_ave[2]];
		}
	}
	
	return nil;
}

+ (NSString *)processor
{
	char buffer[256];
	
	size_t sz = sizeof(buffer);
	
	if (0 == sysctlbyname("machdep.cpu.brand_string", buffer, &sz, NULL, 0)) {
		buffer[(sizeof(buffer) - 1)] = 0;
		
		return @(buffer);
	} else {
		return nil;
	}	
}

+ (NSString *)model
{
	char modelBuffer[256];
	
	size_t sz = sizeof(modelBuffer);
	
	if (0 == sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0)) {
		modelBuffer[(sizeof(modelBuffer) - 1)] = 0;
		
		return @(modelBuffer);
	} else {
		return nil;
	}	
}

+ (NSString *)processorCount
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount = HOST_BASIC_INFO_COUNT;
	
	if (host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount) != KERN_SUCCESS) {
		return nil;
	}
	
	return [NSString stringWithUnsignedInteger:hostInfo.max_cpus];
}

+ (NSString *)processorL2CacheSize
{
	u_int64_t size = 0L;
	
	size_t len = sizeof(size);
	
	if (sysctlbyname("hw.l2cachesize", &size, &len, NULL, 0) >= 0) {
		return [self formattedDiskSize:(TXFSLongInt)size];
	} else {
		return nil;
	}
}

+ (NSString *)processorL3CacheSize
{
	u_int64_t size = 0L;
	
	size_t len = sizeof(size);
	
	if (sysctlbyname("hw.l3cachesize", &size, &len, NULL, 0) >= 0) {
		return [self formattedDiskSize:(TXFSLongInt)size];
	} else {
		return nil;
	}
}

+ (NSString *)processorClockSpeed
{
	u_int64_t clockrate = 0L;
	
	size_t len = sizeof(clockrate);
	
	if (sysctlbyname("hw.cpufrequency", &clockrate, &len, NULL, 0) >= 0) {
		return [self formattedCPUFrequency:clockrate];
	} else {
		return nil;
	}
}

+ (NSString *)operatingSystemName
{
	NSString *productVersion = [TPCPreferences systemInfoPlist][@"ProductVersion"];
	
	if ([productVersion contains:@"10.6"]) {
		return TXTLS(@"SystemInformationOSVersionSnowLeopard");
	}
	
	if ([productVersion contains:@"10.7"]) {
		return TXTLS(@"SystemInformationOSVersionLion");
	}
	
	if ([productVersion contains:@"10.8"]) {
		return TXTLS(@"SystemInformationOSVersionMountainLion");
	}
	
	return nil;
}

+ (TXFSLongInt)freeMemorySize
{
	mach_msg_type_number_t infoCount = (sizeof(vm_statistics_data_t) / sizeof(natural_t));
	
	vm_size_t              pagesize;
	vm_statistics_data_t   vm_stat;
	
	host_page_size(mach_host_self(), &pagesize);
	
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &infoCount) != KERN_SUCCESS) {
		return -1;
	}
	
	return ((vm_stat.inactive_count + vm_stat.free_count) * pagesize);
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

+ (NSString *)physicalMemorySize
{
	return [self formattedDiskSize:[self totalMemorySize]];
}

+ (NSDictionary *)_applicationMemoryInternalInformation
{
	kern_return_t kernr;
	
	mach_vm_address_t addr = 0;
	
	NSInteger shrdmem = 0;
	NSInteger privmem = 0;
	
	int pagesize = getpagesize();
	
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
	
	return @{@"shared" : @(shrdmem), @"private" : @(privmem)};
}

@end