#import "TPI_SP_SysInfo.h"

#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>

#include <sys/types.h>
#include <sys/sysctl.h>

#import <OpenGL/OpenGL.h>
#import <SystemConfiguration/SystemConfiguration.h>

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
	
#if defined(__ppc__)
	NSString *_cpu_model = @"PowerPC 32-bit";
#elif defined(__ppc64__)
	NSString *_cpu_model = @"PowerPC 64-bit";
#elif defined(__i386__) 
	NSString *_cpu_model = @"Intel 32-bit";
#elif defined(__x86_64__)
	NSString *_cpu_model = @"Intel 64-bit";
#else
	NSString *_cpu_model = @"Unknown Architecture";
#endif
	
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
			   TXReadableTime(IntervalSinceTextualStart(), YES)];
	
	[systemVersionPlist release];
	
	return sysinfo;
}

+ (NSString *)applicationAndSystemUptime
{
	return [NSString stringWithFormat:@"System Uptime: %@ - Textual Uptime: %@", [self systemUptime], TXReadableTime(IntervalSinceTextualStart(), YES)];
}
			
#pragma mark -
#pragma mark Formatting/Processing 
			
			+ (NSString *)formattedDiskSize:(TXLongInt)size
	{
		if (size >= 1099511627776) {
			return [NSString stringWithFormat:@"%.2f TB", (size / 1099511627776.0)];
		} else {
			if (size < 1073741824) {
				if (size < 1048576) {
					return [NSString stringWithFormat:@"%.2f KB", (size / 1024.0)];
				} else {
					return [NSString stringWithFormat:@"%.2f MB", (size / 1048576.0)];
				}
			} else {
				return [NSString stringWithFormat:@"%.2f GB", (size / 1073741824.0)];
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
			return [NSString stringWithFormat:@"Textual is currently using %@ of memory.", [self formattedDiskSize:(TXLongInt)info.resident_size]];
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
			TXLongInt totalSpace = [[diskInfo objectForKey:@"NSFileSystemSize"] longLongValue];
			TXLongInt freeSpace = [[diskInfo objectForKey:@"NSFileSystemFreeSize"] longLongValue];
			
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
			return [self formattedDiskSize:(TXLongInt)size];
		} else {
			return nil;
		}
	}
			
			+ (NSString *)processorL3CacheSize
	{
		u_int64_t size = 0L;
		size_t len = sizeof(size);
		
		if (sysctlbyname("hw.l3cachesize", &size, &len, NULL, 0) >= 0) {
			return [self formattedDiskSize:(TXLongInt)size];
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
			TXLongInt memtotal = (TXLongInt)linesize;
			return [self formattedDiskSize:memtotal];
		} else {
			return nil;
		}
	}
			
			@end