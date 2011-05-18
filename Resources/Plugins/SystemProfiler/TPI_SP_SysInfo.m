// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_SP_SysInfo.h"

#define LOCAL_VOLUME_DICTIONARY @"/Volumes"
#define MEMORY_DIVISION_SIZE	1.073741824

@implementation TPI_SP_SysInfo

#pragma mark -
#pragma mark Output Compiler

+ (NSString *)compiledOutput
{
	NSString *sysinfo = @"System Information:";
	
	NSString *_model			= [self model];
	NSString *_cpu_model		= [self processor];
	NSNumber *_cpu_count		= [self processorCount];
	NSString *_cpu_speed		= [self processorClockSpeed]; 
	NSInteger _cpu_count_int	= [_cpu_count integerValue];
			
	NSString *_cpu_l2		= [self processorL2CacheSize];
	NSString *_cpu_l3		= [self processorL3CacheSize];
	NSString *_memory		= [self physicalMemorySize];
	NSString *_gpu_model	= [self graphicsCardInfo];
	NSString *_loadavg		= [self loadAveragesWithCores:_cpu_count_int];
	
	NSBundle *_bundle		= [NSBundle bundleForClass:[self class]];
	
	_cpu_model = [TXRegularExpression string:_cpu_model replacedByRegex:@"(\\s*@.*)|CPU|\\(R\\)|\\(TM\\)"	withString:NSWhitespaceCharacter];
	_cpu_model = [TXRegularExpression string:_cpu_model replacedByRegex:@"\\s+"								withString:NSWhitespaceCharacter];
	
	_cpu_model = [_cpu_model trim];
	
	if (NSObjectIsNotEmpty(_model)) {
		NSDictionary *_all_models = [NSDictionary dictionaryWithContentsOfFile:[_bundle pathForResource:@"MacintoshModels" ofType:@"plist"]];
		
		NSString *_exact_model = _model;
		
		if ([_all_models containsKey:_model]) {
			_exact_model = [_all_models objectForKey:_model];
		}
		
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Model:\002 %@ \002•\002", _exact_model];
	}
	
	if (_cpu_count_int >= 1 && NSObjectIsNotEmpty(_cpu_speed)) {
		if (_cpu_count_int == 1) {
			sysinfo = [sysinfo stringByAppendingFormat:@" \002CPU:\002 %1$@ (%2$@ Core) @ %3$@ \002•\002", _cpu_model, _cpu_count, _cpu_speed];
		} else {
			sysinfo = [sysinfo stringByAppendingFormat:@" \002CPU:\002 %1$@ (%2$@ Cores) @ %3$@ \002•\002", _cpu_model, _cpu_count, _cpu_speed];
		}
	}
	
	if (_cpu_l2) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002L%1$i:\002 %2$@ \002•\002", 2, _cpu_l2];
	}
	
	if (_cpu_l3) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002L%1$i:\002 %2$@ \002•\002", 3, _cpu_l3];
	}
	
	if (_memory) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Memory:\002 %@ \002•\002", _memory];
	}
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002Uptime:\002 %@ \002•\002", [self systemUptimeUsingShortValue:YES]];
	sysinfo = [sysinfo stringByAppendingFormat:@" \002Disk Space:\002 %@ \002•\002", [self diskInfo]];
	
	if (NSObjectIsNotEmpty(_gpu_model)) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Graphics:\002 %@ \002•\002", _gpu_model];
	}
	
	NSArray *allScreens = [NSScreen screens];
	
	if (NSObjectIsNotEmpty(allScreens)) {		
		NSScreen *maiScreen = [allScreens objectAtIndex:0];
		
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Screen Resolution:\002 %.0f x %.0f \002•\002", maiScreen.frame.size.width, maiScreen.frame.size.height];
	}
	
	if (NSObjectIsNotEmpty(_loadavg)) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Load:\002 %@%% \002•\002", _loadavg];
	}
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002OS:\002 %1$@ %2$@ (Build %3$@)",
			   [[Preferences systemInfoPlist] objectForKey:@"ProductName"], 
			   [[Preferences systemInfoPlist] objectForKey:@"ProductVersion"], 
			   [[Preferences systemInfoPlist] objectForKey:@"ProductBuildVersion"]];
	
	NSString *arch = [self kernelArchitecture];
	
	if (NSObjectIsNotEmpty(arch)) {
		sysinfo = [sysinfo stringByAppendingFormat:@" (%@ kernel)", arch];
	}
	
	return sysinfo;
}

+ (NSString *)getAllScreenResolutions 
{
	NSArray *screens = [NSScreen screens];
	
	if ([screens count] == 1) {
		NSScreen *maiScreen = [screens objectAtIndex:0];
		
		return [NSString stringWithFormat:@"\002Screen Resolution:\002 %.0f x %.0f", maiScreen.frame.size.width, maiScreen.frame.size.height];
	} else {
		NSMutableString *result = [NSMutableString string];
		
		for (NSScreen *screen in screens) {
			NSInteger screenNumber = ([screens indexOfObject:screen] + 1);
			
			if (screenNumber == 1) {
				[result appendFormat:@"\002Screen Resolutions:\002 Monitor %i: %.0f x %.0f", screenNumber, screen.frame.size.width, screen.frame.size.height];
			} else {
				[result appendFormat:@"; Monitor %i: %.0f x %.0f", screenNumber, screen.frame.size.width, screen.frame.size.height];
			}
		}
		
		return result;
	}
}

+ (NSString *)applicationAndSystemUptime
{
	return [NSString stringWithFormat:@"System Uptime: %@ - Textual Uptime: %@", [self systemUptime], TXReadableTime([NSDate secondsSinceUnixTimestamp:[Preferences startTime]])];
}

+ (NSString *)getCurrentThemeInUse:(IRCWorld *)world
{
	NSString* fname = [ViewTheme extractThemeName:[Preferences themeName]];
	
	if (fname) {
		return [NSString stringWithFormat:@"\002Current Theme:\002 %@", fname];
	}
    
    return @"\002Current Theme:\002 Unknown";
}

+ (NSString *)getBandwidthStats:(IRCWorld *)world
{
	return [NSString stringWithFormat:@"Textual has sent \002%i\002 messages since startup with a total of \002%i\002 messages received. That equals roughly \002%.2f\002 messages a second. Combined this comes to around \002%@ in\002 and \002%@ out\002 worth of bandwidth.",
			world.messagesSent, world.messagesReceived, (world.messagesReceived / ([[NSDate date] timeIntervalSince1970] - [Preferences startTime])), 
			[self formattedDiskSize:world.bandwidthIn], [self formattedDiskSize:world.bandwidthOut]];
}

+ (NSString *)getSystemLoadAverage
{
	return [NSString stringWithFormat:@"\002Load Average:\002 %@", [self loadAveragesWithCores:0]];
}

+ (NSString *)getTextualRunCount
{
	return [NSString stringWithFormat:@"Textual has been opened \002%i\002 times with a total runtime of %@", [_NSUserDefaults() integerForKey:@"TXRunCount"], TXReadableTime([Preferences totalRunTime])];
}

+ (NSString *)getNetworkStats
{
	/* Based off the source code of the "top" command
	 <http://src.gnu-darwin.org/DarwinSourceArchive/expanded/top/top-15/libtop.c> */
	
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
		if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING)) continue;
		if (ifa->ifa_data == 0) continue;
		
		if (strncmp(ifa->ifa_name, "lo", 2)) {
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;
			
			if (if_data->ifi_ibytes < 20000000 || if_data->ifi_obytes < 2000000) continue;
			
			net_obytes += if_data->ifi_obytes;
			net_ibytes += if_data->ifi_ibytes;
			
			if (objectIndex == 0) {
				[netstat appendFormat:@" [%@]: %@ in, %@ out", [NSString stringWithUTF8String:ifa->ifa_name], 
				 [self formattedDiskSize:if_data->ifi_ibytes], 
				 [self formattedDiskSize:if_data->ifi_obytes]];
			} else {
				[netstat appendFormat:@" — [%@]: %@ in, %@ out", [NSString stringWithUTF8String:ifa->ifa_name], 
				 [self formattedDiskSize:if_data->ifi_ibytes], 
				 [self formattedDiskSize:if_data->ifi_obytes]];
			}
			
			objectIndex += 1;
		}
	}
	
	if (ifa_list) {
	    freeifaddrs(ifa_list);
	}
	
	if (NSObjectIsEmpty(netstat)) {
		return @"Error: Unable to locate any network statistics. ";
	} else {
		return [@"\002Network Traffic:\002" stringByAppendingString:netstat];
	}
	
	return netstat;
}

+ (NSString *)getSystemMemoryUsage
{
	TXFSLongInt totalMemory = [self totalMemorySize];
	TXFSLongInt freeMemory  = [self freeMemorySize];
	TXFSLongInt usedMemory  = (totalMemory - freeMemory);
	
#if __x86_64__ == 0
	if (totalMemory > 4294967296) {
		return @"\002Error:\002 This command requires Textual to run in 64-bit mode on systems with more than 4 GB of memory.";
	}
#endif
	
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
	
	return [NSString stringWithFormat:@"\002System Memory:\002 Free: %@; Used: %@; Total: %@; — [%@]",
			 [self formattedDiskSize:freeMemory], [self formattedDiskSize:usedMemory], [self formattedDiskSize:totalMemory], result];
}

+ (NSString *)getAllVolumesAndSizes
{
	// Based off the source code located at:
	// <http://www.cocoabuilder.com/archive/cocoa/150006-detecting-volumes.html>
	
	NSMutableString *result = [NSMutableString string];
	
	NSArray *drives = [_NSFileManager() contentsOfDirectoryAtPath:LOCAL_VOLUME_DICTIONARY error:NULL];
	
	NSInteger objectIndex = 0;
	
	for (NSString *name in drives) {
		NSString *fullpath = [LOCAL_VOLUME_DICTIONARY stringByAppendingPathComponent:name];
		
		FSRef fsRef;
		struct statfs stat;
		FSCatalogInfo catalogInfo;
		
		const char *fsRep = [fullpath fileSystemRepresentation];
		
		if (FSPathMakeRef((const UInt8*)fsRep, &fsRef, NULL) != 0) {
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
							[result appendFormat:@"%@: Total: %@; Free: %@", name, [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
						} else {
							[result appendFormat:@" — %@: Total: %@; Free: %@", name, [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
						}
						
						objectIndex++;
					}
				}
			}
		}
	}
	
	if (NSObjectIsEmpty(result)) {
		return @"Error: Unable to find any mounted drives.";
	} else {
		return [@"\002Mounted Drives:\002 " stringByAppendingString:result];
	}
}

#pragma mark -
#pragma mark Formatting/Processing 

+ (NSString *)formattedDiskSize:(TXFSLongInt)size
{
	if (size >= 1000000000000.0) {
		return [NSString stringWithFormat:@"%.2f TB", (size / 1000000000000.0)];
	} else {
		if (size < 1000000000.0) {
			if (size < 1000000.0) {
				return [NSString stringWithFormat:@"%.2f KB", (size / 1000.0)];
			} else {
				return [NSString stringWithFormat:@"%.2f MB", (size / 1000000.0)];
			}
		} else {
			return [NSString stringWithFormat:@"%.2f GB", (size / 1000000000.0)];
		}
	}
}

+ (NSString *)formattedCPUFrequency:(NSDoubleN)rate
{
	if ((rate / 1000000) >= 990) {
		return [NSString stringWithFormat:@"%.2f GHz", ((rate / 100000000.0) / 10.0)];
	} else {
		return [NSString stringWithFormat:@"%.2f MHz", rate];
	}
}

#pragma mark -
#pragma mark System Information

+ (NSString *)applicationMemoryUsage
{
	struct task_basic_info info;
	
	mach_msg_type_number_t size = sizeof(info);
	kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
	
	if (kerr == KERN_SUCCESS) {
		NSString *result = [NSString stringWithFormat:@"Textual is currently using %@ of memory in ", [self formattedDiskSize:info.resident_size]];
		
#if __x86_64__
		result = [result stringByAppendingString:@"64-bit mode."];
#else 
		result = [result stringByAppendingString:@"32-bit mode."];
#endif
		
		return result;
	} 
	
	return nil;
}

+ (NSString *)graphicsCardInfo
{
	CGDirectDisplayID displayID		= CGMainDisplayID();
	CGOpenGLDisplayMask displayMask = CGDisplayIDToOpenGLDisplayMask(displayID);
    
	GLint numPixelFormats			= 0;
	CGLContextObj cglContext		= 0;
	CGLPixelFormatObj pixelFormat	= NULL;
	CGLContextObj curr_ctx			= CGLGetCurrentContext();
	
	DevNullDestroyObject(YES, curr_ctx);
		
	CGLPixelFormatAttribute attribs[] = {kCGLPFADisplayMask, displayMask, 0};
	CGLChoosePixelFormat(attribs, &pixelFormat, &numPixelFormats);
    
	if (pixelFormat) {
		CGLCreateContext(pixelFormat, NULL, &cglContext);
		CGLDestroyPixelFormat(pixelFormat);
		CGLSetCurrentContext(cglContext);
		
		if (cglContext) {
			NSString *model = [NSString stringWithCString:(const char *)glGetString(GL_RENDERER) encoding:NSASCIIStringEncoding];
            
			return [model stringByReplacingOccurrencesOfString:@" OpenGL Engine" withString:NSNullObject];
		}
	}	
	
	return nil;
}

+ (NSString *)diskInfo
{	
	NSDictionary *diskInfo = [_NSFileManager() attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
	
	if (diskInfo) {
		TXFSLongInt totalSpace = [diskInfo longLongForKey:NSFileSystemSize];
		TXFSLongInt freeSpace  = [diskInfo longLongForKey:NSFileSystemFreeSize];
		
		return [NSString stringWithFormat:@"Total: %@; Free: %@", [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
	} else {
		return nil;
	}
}

+ (NSString *)systemUptimeUsingShortValue:(BOOL)shortValue
{
	struct timeval boottime;
	size_t size = sizeof(boottime);
	
	if (sysctlbyname("kern.boottime", &boottime, &size, NULL, 0) == -1) {
		boottime.tv_sec = 0;
	}
	
	return TXSpecialReadableTime([NSDate secondsSinceUnixTimestamp:boottime.tv_sec], shortValue);
}

+ (NSString *)systemUptime
{
	return [self systemUptimeUsingShortValue:NO];	
}

+ (NSString *)loadAveragesWithCores:(NSInteger)cores
{
	NSDoubleN load_ave[3];
	
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
		
		return [NSString stringWithUTF8String:buffer];
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
		
		return [NSString stringWithUTF8String:modelBuffer];
	} else {
		return nil;
	}	
}

+ (NSNumber *)processorCount
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount = HOST_BASIC_INFO_COUNT;
	
	if (host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount) != KERN_SUCCESS) {
		return nil;
	}
	
	return [NSNumber numberWithUnsignedInt:hostInfo.max_cpus];
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

+ (NSString *)kernelArchitecture
{
	struct utsname name;
	
    if (uname(&name) >= 0) {
		NSString *machine = [NSString stringWithFormat:@"%s", name.machine];
		
		if ([machine isEqualToString:@"x86_64"]) {
			return @"64-bit";
		} else {
			return @"32-bit";
		}
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
	
	TXFSLongInt result = ((vm_stat.inactive_count + vm_stat.free_count) * pagesize);
	
	return result;
}

+ (TXFSLongInt)totalMemorySize
{
	uint64_t linesize = 0L;
	size_t len = sizeof(linesize);
	
	if (sysctlbyname("hw.memsize", &linesize, &len, NULL, 0) >= 0) {
		return (linesize / MEMORY_DIVISION_SIZE);
	} 
	
	return -1;
}

+ (NSString *)physicalMemorySize
{
	return [self formattedDiskSize:[self totalMemorySize]];
}

@end