//
//  NSDate.h
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


#import <RegexKit/RegexKit.h>
#import <Foundation/NSDebug.h>
#import <stdint.h>
#import <sys/time.h>
#import <sys/resource.h>

#ifdef __MACOSX_RUNTIME__
//#import <malloc/malloc.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreServices/CoreServices.h>
#endif //__MACOSX_RUNTIME__

#define NSMakeRange(x, y) ((NSRange){(x), (y)})
#define NSEqualRanges(range1, range2) ({NSRange _r1 = (range1), _r2 = (range2); (_r1.location == _r2.location) && (_r1.length == _r2.length); })
#define NSLocationInRange(l, r) ({ unsigned int _l = (l); NSRange _r = (r); (_l - _r.location) < _r.length; })
#define NSMaxRange(r) ({ NSRange _r = (r); _r.location + _r.length; })

int dummyDateFunction(int dummyInt);


typedef struct {
  NSTimeInterval systemCPUTime;
  NSTimeInterval userCPUTime;
  NSTimeInterval CPUTime;
#ifdef __MACOSX_RUNTIME__
  //malloc_statistics_t zoneStats;
  uint64_t mach_time;
  uint64_t nanoSeconds;
#endif //__MACOSX_RUNTIME__
} RKCPUTime;

@interface NSDate (CPUTimeAdditions)
+ (RKCPUTime)cpuTimeUsed;
+ (RKCPUTime)differenceOfStartingTime:(RKCPUTime)startTime endingTime:(RKCPUTime)endingTime;
+ (NSString *)stringFromCPUTime:(RKCPUTime)CPUTime;
+ (NSString *)microSecondsStringFromCPUTime:(RKCPUTime)CPUTime;
#ifdef __MACOSX_RUNTIME__
+ (NSString *)machtimeStringFromCPUTime:(RKCPUTime)CPUTime;
//+ (NSString *)stringFromCPUTimeMemory:(RKCPUTime)CPUTime;
#endif //__MACOSX_RUNTIME__


@end
