// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_SP_SysInfo.h"

#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>

#include <sys/mount.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/socket.h>

#include <ifaddrs.h>
#include <net/if.h>

#import <OpenGL/OpenGL.h>

#define LOCAL_VOLUME_DICTIONARY @"/Volumes"

@implementation TPI_SP_SysInfo

#pragma mark -
#pragma mark Output Compiler

+ (NSString *)compiledOutput
{
	NSBundle *parentBundle = [NSBundle bundleWithIdentifier:@"com.codeux.irc.textual"];
	
	NSDictionary *systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];
	if (!systemVersionPlist) systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	NSDictionary *textualInfoPlist = [parentBundle infoDictionary];
	
	NSString *sysinfo = @"System Information:";
	
	NSString *_model = [self model];
	if ([_model length] > 0) {
		NSDictionary *_all_models = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"MacintoshModels" ofType:@"plist"]];
		NSString *_exact_model = [_all_models objectForKey:_model];
		
		if (_exact_model == nil) {
			_exact_model = _model;
		}
		
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Model:\002 %@ \002•\002", _exact_model];
		
		[_all_models release];
	}
	
	NSString *_cpu_model = [self processor];
	_cpu_model = [_cpu_model stringByReplacingOccurrencesOfRegex:@"(\\s*@.*)|CPU|\\(R\\)|\\(TM\\)" withString:@" "];
	_cpu_model = [[_cpu_model stringByReplacingOccurrencesOfRegex:@"\\s+" withString:@" "] trim];
	
	NSNumber *_cpu_count = [self processorCount];
	NSString *_cpu_speed = [self processorClockSpeed]; 
	NSInteger _cpu_count_int = [_cpu_count integerValue];
	
	if (_cpu_count_int >= 1 && [_cpu_speed length] > 0) {
		if (_cpu_count_int == 1) {
			sysinfo = [sysinfo stringByAppendingFormat:@" \002CPU:\002 %1$@ (%2$@ Core) @ %3$@ \002•\002", _cpu_model, _cpu_count, _cpu_speed];
		} else {
			sysinfo = [sysinfo stringByAppendingFormat:@" \002CPU:\002 %1$@ (%2$@ Cores) @ %3$@ \002•\002", _cpu_model, _cpu_count, _cpu_speed];
		}
	}
	
	NSString *_cpu_l2 = [self processorL2CacheSize];
	NSString *_cpu_l3 = [self processorL3CacheSize];
	
	if (_cpu_l2) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002L%1$i:\002 %2$@ \002•\002", 2, _cpu_l2];
	}
	
	if (_cpu_l3) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002L%1$i:\002 %2$@ \002•\002", 3, _cpu_l3];
	}
	
	NSString *_memory = [self physicalMemorySize];
	if (_memory) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Memory:\002 %@ \002•\002", _memory];
	}
	
	NSString *_loadavg = [self loadAverages];
	if ([_loadavg length] > 0) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Load:\002 %@ \002•\002", _loadavg];
	}
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002Uptime:\002 %@ \002•\002", [self systemUptime]];
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002Disk Space:\002 %@ \002•\002", [self diskInfo]];
	
	NSString *_gpu_model = [self graphicsCardInfo];
	if ([_gpu_model length] > 0) {
		sysinfo = [sysinfo stringByAppendingFormat:@" \002Graphics:\002 %@ \002•\002", _gpu_model];
	}
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002OS:\002 %1$@ %2$@ (Build %3$@) \002•\002",
			   [systemVersionPlist objectForKey:@"ProductName"], 
			   [systemVersionPlist objectForKey:@"ProductVersion"], 
			   [systemVersionPlist objectForKey:@"ProductBuildVersion"]];
	
	sysinfo = [sysinfo stringByAppendingFormat:@" \002Textual:\002 %1$@ (Build #%2$@) (Running for %3$@)",
			   [textualInfoPlist objectForKey:@"CFBundleVersion"], 
			   [textualInfoPlist objectForKey:@"Build Number"],
			   TXReadableTime([Preferences startTime], YES)];
	
	[systemVersionPlist release];
	
	[self getNetworkStats];
	
	return sysinfo;
}

+ (NSString *)applicationAndSystemUptime
{
	return [NSString stringWithFormat:@"System Uptime: %@ - Textual Uptime: %@", [self systemUptime], TXReadableTime([Preferences startTime], YES)];
}

+ (NSString *)getCurrentThemeInUse:(IRCWorld *)world
{
    NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
    
    if (kindAndName) {
        NSString* fname = [kindAndName safeObjectAtIndex:1];
        
        if (fname) {
            return [NSString stringWithFormat:@"Current Theme: %@", fname];
        }
    }
    
    return @"Current Theme: Unknown";
}

+ (NSString *)getBandwidthStats:(IRCWorld *)world
{
	return [NSString stringWithFormat:@"Textual has sent \002%i\002 messages since startup with a total of \002%i\002 messages received. That equals roughly \002%.2f\002 messages a second. Combined this comes to around \002%@ in\002 and \002%@ out\002 worth of bandwidth.",
			world.messagesSent, world.messagesReceived, (world.messagesReceived / ([[NSDate date] timeIntervalSince1970] - [Preferences startTime])), [self formattedDiskSize:world.bandwidthIn], [self formattedDiskSize:world.bandwidthOut]];
}

+ (NSString *)getNetworkStats
{
	/* Based off the source code of the "top" command
	 <http://src.gnu-darwin.org/DarwinSourceArchive/expanded/top/top-15/libtop.c> */
	
	NSMutableString *netstat = [NSMutableString stringWithString:@"Network Traffic:"];
	
	BOOL firstItemPassed = NO;
	
	long net_ibytes = 0;
	long net_obytes = 0;
	
	struct ifaddrs *ifa_list = 0, *ifa;
	
	if (getifaddrs(&ifa_list) == -1) {
		return nil;
	}
	
	for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
		if (AF_LINK != ifa->ifa_addr->sa_family) continue;
		if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING)) continue;
		if (ifa->ifa_data == 0) continue;
		
		if (strncmp(ifa->ifa_name, "lo", 2)) {
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;
			
			if (if_data->ifi_ibytes < 20000000 || if_data->ifi_obytes < 2000000) continue;
			
			net_obytes += if_data->ifi_obytes;
			net_ibytes += if_data->ifi_ibytes;
			
			if (firstItemPassed == NO) {
				firstItemPassed = YES;
				
				[netstat appendFormat:@" [%@]: %@ in, %@ out", [NSString stringWithUTF8String:ifa->ifa_name], 
				 [self formattedDiskSize:if_data->ifi_ibytes], 
				 [self formattedDiskSize:if_data->ifi_obytes]];
			} else {
				[netstat appendFormat:@" — [%@]: %@ in, %@ out", [NSString stringWithUTF8String:ifa->ifa_name], 
				 [self formattedDiskSize:if_data->ifi_ibytes], 
				 [self formattedDiskSize:if_data->ifi_obytes]];
			}
		}
	}
	
	if (ifa_list) {
	    freeifaddrs(ifa_list);
	}
	
	return netstat;
}

+ (NSString *)getAllVolumesAndSizes
{
	// Based off the source code located at:
	// <http://www.cocoabuilder.com/archive/cocoa/150006-detecting-volumes.html>
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	TXDevNullDestroyObject(pool); // Fix warning with analyzer saying pool value is never called
	
	BOOL firstItemPassed = NO;
	NSString *result = @"Mounted Drives: ";
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *drives = [fm contentsOfDirectoryAtPath:LOCAL_VOLUME_DICTIONARY error:NULL];
	
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
				NSString *fileSystemName = [fm stringWithFileSystemRepresentation:stat.f_fstypename length:strlen(stat.f_fstypename)];
				
				if ([fileSystemName isEqualToString:@"hfs"]) {
					NSDictionary *diskInfo = [fm attributesOfFileSystemForPath:fullpath error:NULL];
					
					if (diskInfo) {
						TXFSLongInt totalSpace = [[diskInfo objectForKey:NSFileSystemSize] longLongValue];
						TXFSLongInt freeSpace = [[diskInfo objectForKey:NSFileSystemFreeSize] longLongValue];
						
						if (firstItemPassed == NO) {
							firstItemPassed = YES;
							result = [result stringByAppendingFormat:@"\002%@\002: Total: %@; Free: %@", name, [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
						} else {
							result = [result stringByAppendingFormat:@" — \002%@\002: Total: %@; Free: %@", name, [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
						}
					}
				}
			}
		}
	}
	
	if ([result length] < 20) {
		return @"Error: Unable to find any mounted drives.";
	} else {
		return result;
	}
	
	[pool release];
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

+ (NSString *)formattedCPUFrequency:(double)rate
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
		return [NSString stringWithFormat:@"Textual is currently using %@ of memory. — Information about memory use: http://is.gd/j0a9s", [self formattedDiskSize:(TXFSLongInt)info.resident_size]];
	} 
	
	return nil;
}

+ (NSString *)graphicsCardInfo
{
	CGDirectDisplayID displayID = CGMainDisplayID();
	CGOpenGLDisplayMask displayMask = CGDisplayIDToOpenGLDisplayMask(displayID);
	
	CGLPixelFormatAttribute attribs[] = {kCGLPFADisplayMask, (CGLPixelFormatAttribute)displayMask, (CGLPixelFormatAttribute)0};
	
	GLint numPixelFormats = 0;
	CGLContextObj cglContext = 0;
	CGLPixelFormatObj pixelFormat = NULL;
	CGLContextObj curr_ctx = CGLGetCurrentContext();
	TXDevNullDestroyObject(curr_ctx);
	
	CGLChoosePixelFormat(attribs, &pixelFormat, &numPixelFormats);
	
	if (pixelFormat) {
		CGLCreateContext(pixelFormat, NULL, &cglContext);
		CGLDestroyPixelFormat(pixelFormat);
		CGLSetCurrentContext(cglContext);
		
		if (cglContext) {
			NSString *model = [NSString stringWithCString:(const char *)glGetString(GL_RENDERER) encoding:NSASCIIStringEncoding];
			
			return [model stringByReplacingOccurrencesOfString:@" OpenGL Engine" withString:@""];
		}
	}	
	
	return nil;
}

+ (NSString *)diskInfo
{	
	NSDictionary *diskInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
	
	if (diskInfo) {
		TXFSLongInt totalSpace = [[diskInfo objectForKey:NSFileSystemSize] longLongValue];
		TXFSLongInt freeSpace = [[diskInfo objectForKey:NSFileSystemFreeSize] longLongValue];
		
		return [NSString stringWithFormat:@"Total: %@; Free: %@", [self formattedDiskSize:totalSpace], [self formattedDiskSize:freeSpace]];
	} else {
		return nil;
	}
}

+ (NSString *)systemUptime
{
	struct timeval boottime;
	size_t size;
	
	size = sizeof(boottime);
	
	if (sysctlbyname("kern.boottime", &boottime, &size, NULL, 0) == -1) {
		boottime.tv_sec = 0;
	}
	
	NSTimeInterval timeDiff = boottime.tv_sec;
	NSString *formattedString = TXReadableTime(timeDiff, YES);
	
	return formattedString;
}

+ (NSString *)loadAverages
{
	double load_ave[3];
	int loads = getloadavg(load_ave, 3);
	
	if (loads == 3) {
		return [NSString stringWithFormat:@"%.2f %.2f %.2f",
				(CGFloat)load_ave[0],
				(CGFloat)load_ave[1],
				(CGFloat)load_ave[2]];
	}
	
	return nil;
}

+ (NSString *)processor
{
	char buffer[256];
	size_t sz = sizeof(buffer);
	
	if (0 == sysctlbyname("machdep.cpu.brand_string", buffer, &sz, NULL, 0)) {
		buffer[sizeof(buffer) - 1] = 0;
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
		modelBuffer[sizeof(modelBuffer) - 1] = 0;
		return [NSString stringWithUTF8String:modelBuffer];
	} else {
		return nil;
	}	
}

+ (NSNumber *)processorCount
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount;
	
	infoCount = HOST_BASIC_INFO_COUNT;
	
	host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount);
	
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
		double speed = (double)clockrate;
		return [self formattedCPUFrequency:speed];
	} else {
		return nil;
	}
}

+ (NSString *)physicalMemorySize
{
	uint64_t linesize;
	size_t len;
	
	len = sizeof(linesize);
	linesize = 0L;
	
	if (sysctlbyname("hw.memsize", &linesize, &len, NULL, 0) >= 0) {
		TXFSLongInt memtotal = (TXFSLongInt)linesize/1.073741824;
		return [self formattedDiskSize:memtotal];
	} else {
		return nil;
	}
}

@end