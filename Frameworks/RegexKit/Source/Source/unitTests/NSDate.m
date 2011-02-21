//
//  NSDate.m
//  RegexKit
//  http://regexkit.sourceforge.net/
//

/*
 Copyright © 2007-2008, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSDate.h"

int dummyDateFunction(int dummyInt) {
  return(dummyInt);
}

@implementation NSDate (CPUTime)

+ (RKCPUTime) cpuTimeUsed
{
  struct rusage currentRusage;
  RKCPUTime timeUsed; memset(&timeUsed, 0, sizeof(RKCPUTime));
  
  getrusage(RUSAGE_SELF, &currentRusage);
  timeUsed.userCPUTime   = ((((NSTimeInterval)currentRusage.ru_utime.tv_sec) * 1000000.0) + ((NSTimeInterval)currentRusage.ru_utime.tv_usec));// / 1000000.0;
  timeUsed.systemCPUTime = ((((NSTimeInterval)currentRusage.ru_stime.tv_sec) * 1000000.0) + ((NSTimeInterval)currentRusage.ru_stime.tv_usec));// / 1000000.0;
  timeUsed.CPUTime = timeUsed.userCPUTime + timeUsed.systemCPUTime;

#ifdef __MACOSX_RUNTIME__
  //malloc_zone_statistics(malloc_default_zone(), &timeUsed.zoneStats);
  timeUsed.mach_time = mach_absolute_time();
#endif //__MACOSX_RUNTIME__
  
  return(timeUsed);
}

+ (RKCPUTime) differenceOfStartingTime:(RKCPUTime)startingTime endingTime:(RKCPUTime)endingTime
{
  RKCPUTime diffTime; memset(&diffTime, 0, sizeof(RKCPUTime));
  
  diffTime.userCPUTime   = (endingTime.userCPUTime   - startingTime.userCPUTime);
  diffTime.systemCPUTime = (endingTime.systemCPUTime - startingTime.systemCPUTime);
  diffTime.CPUTime       = (endingTime.CPUTime       - startingTime.CPUTime);

#ifdef __MACOSX_RUNTIME__
  /*
  diffTime.zoneStats.blocks_in_use   = endingTime.zoneStats.blocks_in_use   - startingTime.zoneStats.blocks_in_use;
  diffTime.zoneStats.size_in_use     = endingTime.zoneStats.size_in_use     - startingTime.zoneStats.size_in_use;
  diffTime.zoneStats.max_size_in_use = endingTime.zoneStats.max_size_in_use - startingTime.zoneStats.max_size_in_use;
  diffTime.zoneStats.size_allocated  = endingTime.zoneStats.size_allocated  - startingTime.zoneStats.size_allocated;
   */
  diffTime.mach_time       = (endingTime.mach_time       - startingTime.mach_time);
  Nanoseconds elapsed_nanoSeconds = AbsoluteToNanoseconds( *(AbsoluteTime *) &diffTime.mach_time );
  diffTime.nanoSeconds = * (uint64_t *) &elapsed_nanoSeconds;
#endif //__MACOSX_RUNTIME__

  return(diffTime);
}

+ (NSString *)stringFromCPUTime:(RKCPUTime)CPUTime
{
  return([NSString stringWithFormat:@"<U %f %6.2f%% S %f %6.2f%% U+S %f>", CPUTime.userCPUTime / 1000000.0, (CPUTime.userCPUTime / CPUTime.CPUTime) * 100.0, CPUTime.systemCPUTime / 1000000.0, (CPUTime.systemCPUTime / CPUTime.CPUTime) * 100.0, CPUTime.CPUTime / 1000000.0]); 
}

+ (NSString *)microSecondsStringFromCPUTime:(RKCPUTime)CPUTime
{
  return([NSString stringWithFormat:@"<U %.1fus %6.2f%% S %.1fus %6.2f%% U+S %.1fus>", CPUTime.userCPUTime, (CPUTime.userCPUTime / CPUTime.CPUTime) * 100.0, CPUTime.systemCPUTime, (CPUTime.systemCPUTime / CPUTime.CPUTime) * 100.0, CPUTime.CPUTime]); 
}

#ifdef __MACOSX_RUNTIME__
+ (NSString *)machtimeStringFromCPUTime:(RKCPUTime)CPUTime
{
  return([NSString stringWithFormat:@"<< %llu / %llu >>", CPUTime.mach_time, CPUTime.nanoSeconds]);
}

/*
+ (NSString *)stringFromCPUTimeMemory:(RKCPUTime)CPUTime
{
  char membuf[4096];
  snprintf(&membuf[0], 4090, "<blocks: %10u in use: %10zu max in use: %10zu heap: %10zu>", CPUTime.zoneStats.blocks_in_use, CPUTime.zoneStats.size_in_use, CPUTime.zoneStats.max_size_in_use, CPUTime.zoneStats.size_allocated);

  return([NSString stringWithFormat:@"%s", &membuf[0]]);
}
*/
#endif //__MACOSX_RUNTIME__

@end
