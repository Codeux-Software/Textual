/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "TPISystemProfilerModelIDRequestController.h"

#define _localVolumeBaseDirectory		@"/Volumes"

#define _systemMemoryDivisor			1.073741824

@interface WKWebView ()
@property (nonatomic, readonly) pid_t _webProcessIdentifier;
@end

@interface TPI_SP_WebViewProcessInfo : NSObject
@property (nonatomic, assign) pid_t processIdentifier;
@property (nonatomic, assign) TXUnsignedLongLong processMemoryUse;
@property (nonatomic, strong) NSArray *processViewNames;
@end

@implementation TPI_SP_CompiledOutput

+ (NSString *)applicationActiveStyle
{
	NSMutableString *resultString = [NSMutableString string];

	NSString *fname = [themeController() name];
	
	TPCThemeControllerStorageLocation storageLocation = [themeController() storageLocation];
	
    if (storageLocation == TPCThemeControllerStorageBundleLocation) {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1033]", fname)];
    } else if (storageLocation == TPCThemeControllerStorageCustomLocation) {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1034]", fname)];
    } else if (storageLocation == TPCThemeControllerStorageCloudLocation) {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1035]", fname)];
	}

	if ([TPCPreferences invertSidebarColors] == NO) {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1036]")];
	} else {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1037]")];
	}

	if ([NSColor currentControlTint] == NSGraphiteControlTint) {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1039]")];
	} else {
		[resultString appendString:TPILocalizedString(@"BasicLanguage[1038]")];
	}

	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		if ([TXUserInterface systemWideDarkModeEnabledInYosemite]) {
			[resultString appendString:TPILocalizedString(@"BasicLanguage[1051]", [XRSystemInformation systemOperatingSystemName])];
		} else {
			[resultString appendString:TPILocalizedString(@"BasicLanguage[1050]", [XRSystemInformation systemOperatingSystemName])];
		}
	}

	return resultString;
}

+ (NSString *)applicationAndSystemUptime
{
	NSInteger dateFormat = (NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
	
	NSString *systemUptime = TXHumanReadableTimeInterval([TPI_SP_SysInfo systemUptime], NO, dateFormat);
	NSString *textualUptime = TXHumanReadableTimeInterval([TPI_SP_SysInfo applicationUptime], NO, dateFormat);

	return TPILocalizedString(@"BasicLanguage[1045]", systemUptime, textualUptime);
}

+ (NSString *)applicationBandwidthStatistics
{
	IRCClient *client = [mainWindow() selectedClient];

	NSTimeInterval lastMsg = [NSDate secondsSinceUnixTimestamp:[client lastMessageReceived]];
	
	return TPILocalizedString(@"BasicLanguage[1049]",
				  TXFormattedNumber([worldController() messagesSent]),
				  TXFormattedNumber([worldController() messagesReceived]),
				  TXHumanReadableTimeInterval(lastMsg, YES, NSCalendarUnitSecond),
				  [TPI_SP_SysInfo formattedDiskSize:[worldController() bandwidthIn]],
				  [TPI_SP_SysInfo formattedDiskSize:[worldController() bandwidthOut]]);
}

+ (NSString *)applicationMemoryUsage
{
	NSInteger totalScrollbackSize = 0;

	for (IRCClient *u in [worldController() clientList]) {
		totalScrollbackSize += [[u viewController] numberOfLines];

		for (IRCChannel *c in [u channelList]) {
			totalScrollbackSize += [[c viewController] numberOfLines];
		}
	}

	TXUnsignedLongLong textualMemoryUse = [TPI_SP_SysInfo applicationMemoryInformation];

	return TPILocalizedString(@"BasicLanguage[1020]",
		[TPI_SP_SysInfo formattedDiskSize:textualMemoryUse],
		 TXFormattedNumber(totalScrollbackSize));
}

+ (NSString *)webKitFrameworkMemoryUsage
{
	if ([TPCPreferences webKit2Enabled]) {
		NSArray *webViewProcesses = [TPI_SP_SysInfo webViewProcessIdentifiers];

		if ([webViewProcesses count] == 0) {
			return nil;
		}

		TPI_SP_WebViewProcessInfo *topProcess = webViewProcesses[0];

		NSArray *viewNameArray = [topProcess processViewNames];

		if ([viewNameArray count] == 0) {
			return nil;
		}

		NSString *viewName = [viewNameArray componentsJoinedByString:@", "];

		NSMutableString *resultString = [NSMutableString string];

		if ([viewNameArray count] == 1) {
			[resultString appendString:
			 TPILocalizedString(@"BasicLanguage[1052]",
				[topProcess processIdentifier],
				 viewName,
				[TPI_SP_SysInfo formattedDiskSize:[topProcess processMemoryUse]])];
		} else {
			[resultString appendString:
			 TPILocalizedString(@"BasicLanguage[1053]",
				[topProcess processIdentifier],
				 viewName,
				[TPI_SP_SysInfo formattedDiskSize:[topProcess processMemoryUse]])];
		}

		[resultString appendString:NSStringNewlinePlaceholder];

		TXUnsignedLongLong totalMemoryUse = 0;

		for (TPI_SP_WebViewProcessInfo *processInfo in webViewProcesses) {
			totalMemoryUse += [processInfo processMemoryUse];
		}

		[resultString appendString:
		 TPILocalizedString(@"BasicLanguage[1054]",
			[webViewProcesses count],
			[TPI_SP_SysInfo formattedDiskSize:totalMemoryUse])];

		return [resultString copy];
	}

	return nil;
}

+ (NSString *)applicationRuntimeStatistics
{
	NSTimeInterval runtime = [TPCApplicationInfo timeIntervalSinceApplicationInstall];

	NSTimeInterval birthday = [NSDate secondsSinceUnixTimestamp:TXBirthdayReferenceDate];

	if (runtime > birthday) {
		runtime = birthday;
	}

	return TPILocalizedString(@"BasicLanguage[1047]",
				  TXFormattedNumber([TPCApplicationInfo applicationRunCount]),
				  TXHumanReadableTimeInterval(runtime, NO, 0));
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
		
TEXTUAL_IGNORE_DEPRECATION_BEGIN
		if ((FSPathMakeRef((const UInt8 *)fsRep, &fsRef, NULL) == 0) == NO) {
			continue;
		}

		if ((FSGetCatalogInfo(&fsRef, kFSCatInfoParentDirID, &catalogInfo, NULL, NULL, NULL) == 0) == NO) {
			continue;
		}
TEXTUAL_IGNORE_DEPRECATION_END
		
		BOOL isVolume = (catalogInfo.parentDirID == fsRtParID);

		if (isVolume) {
			if (statfs(fsRep, &stat) == 0) {
				NSString *fileSystemName = [RZFileManager() stringWithFileSystemRepresentation:stat.f_fstypename length:strlen(stat.f_fstypename)];

				if ([fileSystemName isEqualToString:@"hfs"]) {
					NSDictionary *diskInfo = [RZFileManager() attributesOfFileSystemForPath:fullpath error:NULL];

					if (diskInfo) {
						TXUnsignedLongLong totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
						TXUnsignedLongLong freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];

						if (objectIndex == 0) {
							[result appendString:TPILocalizedString(@"BasicLanguage[1022]", name,
														[TPI_SP_SysInfo formattedDiskSize:totalSpace],
														[TPI_SP_SysInfo formattedDiskSize:freeSpace])];
						} else {
							[result appendString:TPILocalizedString(@"BasicLanguage[1023]", name,
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
		return TPILocalizedString(@"BasicLanguage[1024]");
	} else {
		return TPILocalizedString(@"BasicLanguage[1021]", result);
	}
}

+ (NSString *)systemDisplayInformation
{
	NSArray *screens = [NSScreen screens];

	if ([screens count] == 1) {
		NSScreen *maiScreen = RZMainScreen();

		NSString *result = TPILocalizedString(@"BasicLanguage[1040]",
								  [maiScreen frame].size.width,
								  [maiScreen frame].size.height);

		if ([maiScreen runningInHighResolutionMode]) {
			result = [result stringByAppendingString:TPILocalizedString(@"BasicLanguage[1043]")];
		}

		return result;
	} else {
		NSMutableString *result = [NSMutableString string];

		for (NSScreen *screen in screens) {
			NSInteger screenNumber = ([screens indexOfObject:screen] + 1);

			if (screenNumber == 1) {
				[result appendString:TPILocalizedString(@"BasicLanguage[1041]",
											screenNumber,
											[screen frame].size.width,
											[screen frame].size.height)];
			} else {
				[result appendString:TPILocalizedString(@"BasicLanguage[1042]",
											screenNumber,
											[screen frame].size.width,
											[screen frame].size.height)];
			}

			if ([screen runningInHighResolutionMode]) {
				[result appendString:TPILocalizedString(@"BasicLanguage[1043]")];
			}
		}

		return result;
	}
}

+ (NSString *)systemInformation
{
	NSString *sysinfo = TPILocalizedString(@"BasicLanguage[1001]");

	NSString *_new = nil;

	NSString *_model			= [TPI_SP_SysInfo model];
	NSString *_cpu_model		= [TPI_SP_SysInfo processor];
	NSString *_cpu_speed		= [TPI_SP_SysInfo processorClockSpeed];

	NSUInteger _cpu_count_p		= [TPI_SP_SysInfo processorPhysicalCoreCount];
	NSUInteger _cpu_count_v		= [TPI_SP_SysInfo processorVirtualCoreCount];

	NSString *_memory		= [TPI_SP_SysInfo formattedTotalMemorySize];
	NSString *_gpu_model	= [TPI_SP_SysInfo formattedGraphicsCardInformation];

	NSBundle *_bundle		= [NSBundle bundleForClass:[self class]];

	_cpu_model = [XRRegularExpression string:_cpu_model replacedByRegex:@"(\\s*@.*)|CPU|\\(R\\)|\\(TM\\)"	withString:NSStringWhitespacePlaceholder];
	_cpu_model = [XRRegularExpression string:_cpu_model replacedByRegex:@"\\s+"								withString:NSStringWhitespacePlaceholder];

	_cpu_model = [_cpu_model trim];

	BOOL _show_cpu_model	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> CPU Model"] == NO);
	BOOL _show_gpu_model	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> GPU Model"] == NO);
	BOOL _show_diskinfo		= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Disk Information"] == NO);
	BOOL _show_sys_uptime	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> System Uptime"] == NO);
	BOOL _show_sys_memory	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Memory Information"] == NO);
	BOOL _show_screen_res	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> Screen Resolution"] == NO);
	BOOL _show_os_version	= ([RZUserDefaults() boolForKey:@"System Profiler Extension -> Feature Disabled -> OS Version"] == NO);

	/* Mac Model. */
	if (NSObjectIsNotEmpty(_model)) {
		NSString *_exact_model = nil;

		NSString *_realModel = [[TPISystemProfilerModelIDRequestController sharedController] cachedIdentifier];

		if (_realModel) {
			_exact_model = _realModel;
		} else {
			NSString *_all_models_path = [_bundle pathForResource:@"MacintoshModels" ofType:@"plist"];

			NSDictionary *_all_models = [NSDictionary dictionaryWithContentsOfFile:_all_models_path];

			if (NSObjectIsEmpty(_all_models)) {
				NSAssert(NO, @"_all_models");
			}

			if ([_model hasPrefix:@"VMware"]) {
				_exact_model = _all_models[@"VMware"];
			} else {
				_exact_model = [XRSystemInformation systemModelName];

				if ([_all_models containsKey:_model]) {
					_exact_model = _all_models[_model];
				}
			}
		}

		_new = TPILocalizedString(@"BasicLanguage[1002]", _exact_model);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_cpu_model) {
		/* CPU Information. */
		if (_cpu_count_p >= 1 && NSObjectIsNotEmpty(_cpu_speed)) {
			_new = TPILocalizedString(@"BasicLanguage[1003]", _cpu_model, _cpu_count_v, _cpu_count_p, _cpu_speed);

			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}

	if (_show_sys_memory && _memory) {
		_new = TPILocalizedString(@"BasicLanguage[1004]", _memory);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_sys_uptime) {
		/* System Uptime. */
		_new = TPILocalizedString(@"BasicLanguage[1005]", TXHumanReadableTimeInterval([TPI_SP_SysInfo systemUptime], YES, 0));

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_diskinfo) {
		/* Disk Space Information. */
		_new = TPILocalizedString(@"BasicLanguage[1006]", [TPI_SP_SysInfo formattedLocalVolumeDiskUsage]);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_gpu_model) {
		/* GPU Information. */
		if (NSObjectIsNotEmpty(_gpu_model)) {
			_new = TPILocalizedString(@"BasicLanguage[1008]", _gpu_model);

			sysinfo = [sysinfo stringByAppendingString:_new];
		}
	}

	if (_show_screen_res) {
		/* Screen Resolution. */
		NSScreen *maiScreen = RZMainScreen();

		if ([maiScreen runningInHighResolutionMode]) {
			_new = TPILocalizedString(@"BasicLanguage[1010]",
						  [maiScreen frame].size.width,
						  [maiScreen frame].size.height);
		} else {
			_new = TPILocalizedString(@"BasicLanguage[1009]",
						  [maiScreen frame].size.width,
						  [maiScreen frame].size.height);
		}

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if (_show_os_version) {
		/* Operating System. */
		_new = TPILocalizedString(@"BasicLanguage[1012]",
					  [XRSystemInformation systemOperatingSystemName],
					  [XRSystemInformation systemStandardVersion],
					  [XRSystemInformation systemBuildVersion]);

		sysinfo = [sysinfo stringByAppendingString:_new];
	}

	if ([sysinfo hasSuffix:@" \002•\002"]) {
		sysinfo = [sysinfo substringToIndex:([sysinfo length] - 3)];
	}

	/* Compiled Output. */
	return sysinfo;
}

+ (NSString *)systemMemoryInformation
{
	TXUnsignedLongLong totalMemory = [TPI_SP_SysInfo totalMemorySize];
	TXUnsignedLongLong freeMemory  = [TPI_SP_SysInfo freeMemorySize];
	TXUnsignedLongLong usedMemory  = (totalMemory - freeMemory);

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

	return TPILocalizedString(@"BasicLanguage[1046]",
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
				[netstat appendString:TPILocalizedString(@"BasicLanguage[1026]",
											 @(ifa->ifa_name),
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_ibytes],
											 [TPI_SP_SysInfo formattedDiskSize:if_data->ifi_obytes])];
			} else {
				[netstat appendString:TPILocalizedString(@"BasicLanguage[1027]",
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
		return TPILocalizedString(@"BasicLanguage[1028]");
	} else {
		return TPILocalizedString(@"BasicLanguage[1025]", netstat);
	}

	return netstat;
}

@end

@implementation TPI_SP_SysInfo

#pragma mark -
#pragma mark Formatting/Processing 

+ (NSString *)formattedDiskSize:(TXUnsignedLongLong)size
{
	return [NSByteCountFormatter stringFromByteCountWithPaddedDigits:size];
}

+ (NSString *)formattedCPUFrequency:(double)rate
{
	if ((rate / 1000000) >= 990) {
		return TPILocalizedString(@"BasicLanguage[1018]", ((rate / 100000000.0) / 10.0));
	} else {
		return TPILocalizedString(@"BasicLanguage[1019]", rate);
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
		TXUnsignedLongLong totalSpace = [diskInfo longLongForKey:NSFileSystemSize];

		return [self formattedDiskSize:totalSpace];
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
			const void *class = CFDictionaryGetValue(serviceDictionary, @"class-code");

			if (PointerIsEmpty(model) || PointerIsEmpty(class)) {
				continue;
			}

			if (CFGetTypeID(class) == CFDataGetTypeID() && CFDataGetLength(class) > 1) {
				if ((*(UInt32 *)CFDataGetBytePtr(class) == 0x30000) == NO) {
					continue;
				}
			}

			if (CFGetTypeID(model) == CFDataGetTypeID() && CFDataGetLength(model) > 1) {
				NSString *s = [NSString stringWithBytes:[(__bridge NSData *)model bytes] length:CFDataGetLength(model) encoding:NSASCIIStringEncoding];

				s = [s stringByReplacingOccurrencesOfString:@"\0" withString:NSStringEmptyPlaceholder];

				[gpuList addObject:s];
			}

            CFRelease(serviceDictionary);
        }

		// ---- //

		NSInteger objectIndex = 0;

        NSMutableString *result = [NSMutableString string];

		for (NSString *model in gpuList) {
			if (objectIndex == 0) {
				[result appendString:TPILocalizedString(@"BasicLanguage[1013]", model)];
			} else {
				[result appendString:TPILocalizedString(@"BasicLanguage[1014]", model)];
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
	return [TPCApplicationInfo timeIntervalSinceApplicationLaunch];
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

+ (TXUnsignedLongLong)freeMemorySize
{
	mach_msg_type_number_t infoCount = (sizeof(vm_statistics_data_t) / sizeof(natural_t));
	
	vm_size_t  pagesize;
	
	host_page_size(mach_host_self(), &pagesize);

	vm_statistics_data_t vm_stat;
	
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &infoCount) == KERN_SUCCESS) {
		return ((vm_stat.inactive_count + vm_stat.free_count) * pagesize);
	}
	
	return -1;
}

+ (TXUnsignedLongLong)totalMemorySize
{
	uint64_t linesize = 0L;
	
	size_t len = sizeof(linesize);
	
	if (sysctlbyname("hw.memsize", &linesize, &len, NULL, 0) >= 0) {
		return (linesize / _systemMemoryDivisor);
	} 
	
	return -1;
}

+ (NSInteger)applicationMemoryInformation
{
	pid_t processIdentifier = (pid_t)[[NSProcessInfo processInfo] processIdentifier];

	return [TPI_SP_SysInfo memoryUseForProcess:processIdentifier];
}

+ (NSInteger)memoryUseForProcess:(pid_t)processIdentifier
{
	if (processIdentifier == 0) {
		return 0;
	}

	int processLookupResult = 0;

	struct proc_regioninfo processRegionInfo;

	uint64_t processAddress = 0;

	TXUnsignedLongLong memoryUse = 0;

	int memoryPageSize = getpagesize();

	do {
		processLookupResult =
		proc_pidinfo(processIdentifier, PROC_PIDREGIONINFO, processAddress, &processRegionInfo, PROC_PIDREGIONINFO_SIZE);

		processAddress = (processRegionInfo.pri_address + processRegionInfo.pri_size);

		if (processRegionInfo.pri_share_mode == SM_PRIVATE) {
			memoryUse += (processRegionInfo.pri_private_pages_resident * memoryPageSize);
		}
	}
	while (processLookupResult > 0);

	return memoryUse;
}

+ (NSArray *)webViewProcessIdentifiers
{
	/* Create a dictionary with key as identifier and value as an array of 
	 views managed by the process. */
	NSMutableDictionary *webViewProcesses = [NSMutableDictionary dictionary];

	void (^_addEntry)(IRCTreeItem *) = ^void (IRCTreeItem *treeItem)
	{
		pid_t processIdentifier = [TPI_SP_SysInfo webViewProcessIdentifierForTreeItem:treeItem];

		if (processIdentifier == 0)
			return;

		NSNumber *processIdentifierObj = [NSNumber numberWithInt:processIdentifier];

		NSMutableArray *viewArray = webViewProcesses[processIdentifierObj];

		if (viewArray == nil) {
			viewArray = [NSMutableArray array];

			[webViewProcesses setObject:viewArray forKey:processIdentifierObj];
		}

		if ([treeItem isClient])
			return;

		[viewArray addObject:[treeItem name]];
	};


	for (IRCClient *u in [worldController() clientList]) {
		_addEntry(u);

		for (IRCChannel *c in [u channelList]) {
			_addEntry(c);
		}
	}

	/* Create array of TPI_SP_WebViewProcessInfo objects */
	NSMutableArray *webViewProcessObjects =
	[NSMutableArray arrayWithCapacity:[webViewProcesses count]];

	[webViewProcesses enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		/* Object values */
		pid_t processIdentifier = [key intValue];

		TXUnsignedLongLong processMemoryUse = [TPI_SP_SysInfo memoryUseForProcess:processIdentifier];

		NSArray *processViewNames = [object sortedArrayUsingSelector:@selector(compare:)];

		TPI_SP_WebViewProcessInfo *processInfoObject = [TPI_SP_WebViewProcessInfo new];

		/* Set values */
		[processInfoObject setProcessIdentifier:processIdentifier];

		[processInfoObject setProcessMemoryUse:processMemoryUse];

		[processInfoObject setProcessViewNames:processViewNames];

		/* Add object */
		[webViewProcessObjects addObject:processInfoObject];
	}];

	/* Sort objects based on memory use (highest to lowest) */
	[webViewProcessObjects sortUsingComparator:^NSComparisonResult(id object1, id object2) {
		TXUnsignedLongLong processMemoryUse1 = [object1 processMemoryUse];
		TXUnsignedLongLong processMemoryUse2 = [object2 processMemoryUse];

		if (processMemoryUse1 > processMemoryUse2) {
			return NSOrderedAscending;
		} else if (processMemoryUse1 < processMemoryUse2) {
			return NSOrderedDescending;
		}

		return NSOrderedSame;
	}];

	/* Return a copy of mutable array */
	return [webViewProcessObjects copy];
}

+ (pid_t)webViewProcessIdentifierForTreeItem:(IRCTreeItem *)treeItem
{
	TVCLogView *backingView = [[treeItem viewController] backingView];

	id webView = [backingView webView];

	if ([webView respondsToSelector:@selector(_webProcessIdentifier)]) {
		return [webView _webProcessIdentifier];
	}

	return 0;
}

@end

@implementation TPI_SP_WebViewProcessInfo
@end
