//
//  RegexKitPrivateThreads.h
//  RegexKit
//  http://regexkit.sourceforge.net/
//
//  PRIVATE HEADER -- NOT in RegexKit.framework/Headers
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

#ifdef __cplusplus
extern "C" {
#endif
  
#ifndef _REGEXKIT_REGEXKITPRIVATETHREADS_H_
#define _REGEXKIT_REGEXKITPRIVATETHREADS_H_ 1

#ifdef __MACOSX_RUNTIME__

#import <pthread.h>
#import <mach/mach_types.h>
#import <mach/mach_host.h>
#import <mach/thread_switch.h>
#import <mach/mach_init.h>

#define HAVE_RKREGEX_THREAD_OPS

// Technically SWITCH_OPTION_DEPRESS requires determining the minimum depress time, but it's somewhat convoluted to extract and make useable globally.. :(
RKREGEX_STATIC_INLINE void RKThreadYield(void)  { thread_switch(THREAD_NULL, SWITCH_OPTION_DEPRESS, 1); }
RKREGEX_STATIC_INLINE BOOL RKIsMainThread(void) { return((BOOL)pthread_main_np());                      }

#endif //__MACOSX_RUNTIME__

// FreeBSD 5+
#if (__FreeBSD__ >= 5)

#import <pthread.h>
#import <pthread_np.h>

#define HAVE_RKREGEX_THREAD_OPS

/* Testing gave the impression that sched_yield().. didn't.  Massive bulk read spin increments.  Sleeping helped tremendously. */
RKREGEX_STATIC_INLINE void RKThreadYield(void)  { usleep(50); sched_yield();       }
RKREGEX_STATIC_INLINE BOOL RKIsMainThread(void) { return((BOOL)pthread_main_np()); }

#endif //__FreeBSD__

// Solaris
#if defined(__sun__) && defined(__svr4__)

#import <thread.h>

#define HAVE_RKREGEX_THREAD_OPS

RKREGEX_STATIC_INLINE void RKThreadYield(void)  { thr_yield(); }
RKREGEX_STATIC_INLINE void RKIsMainThread(void) { thr_main();  }

#endif // Solaris __sun__ _svr4__



// Try for generic pthread threading functions?
#if !defined(HAVE_RKREGEX_THREAD_OPS)

#warning Unable to determine platform specific thread operations. Trying sched_yield() and pthread_main_np().

#import <pthread.h>
#import <pthread_np.h>

#define HAVE_RKREGEX_THREAD_OPS

RKREGEX_STATIC_INLINE void RKThreadYield(void)  { sched_yield();                   }
RKREGEX_STATIC_INLINE BOOL RKIsMainThread(void) { return((BOOL)pthread_main_np()); }

#endif // HAVE_RKREGEX_THREAD_OPS


#ifdef RK_ENABLE_THREAD_LOCAL_STORAGE

/*
 The following block contains the compile unit private definitions for implementing
 thread local data structures.  It is currently only used to create on demand a single
 NSNumberFormatter that is reused for all requested NSNumber conversions.  Apple
 documentation indicates that this object is not multithreading safe, so each thread
 gets its own NSNumberFormatter on demand.  Additionally, when the thread is exiting,
 __RKThreadIsExiting (static in RKRegex.m) gets called so we can do any clean up of allocations.
 
 RKRegex.m +load registers our pthread key, __RKRegexThreadLocalDataKey and sets the thread exit clean up handler.
*/

extern pthread_key_t __RKRegexThreadLocalDataKey;

// Any additions here must add a deallocation section to RKRegex.m/__RKThreadIsExiting.
// Rough convention is to create a function that retrieves a specific item from the thread local data, demand populating the structure as required.

struct __RKThreadLocalData {
  RK_STRONG_REF NSNumberFormatter      *_numberFormatter;
#ifdef HAVE_NSNUMBERFORMATTER_CONVERSIONS
  RK_STRONG_REF NSNumberFormatterStyle  _currentFormatterStyle;
#endif
};

struct __RKThreadLocalData *__RKGetThreadLocalData(void) RK_ATTRIBUTES(pure, used);

RKREGEX_STATIC_PURE_INLINE struct __RKThreadLocalData *RKGetThreadLocalData(void) {
  RK_STRONG_REF struct __RKThreadLocalData * RK_C99(restrict) tld = pthread_getspecific(__RKRegexThreadLocalDataKey);
  return(RK_EXPECTED((tld != NULL), 1) ? tld : __RKGetThreadLocalData());
}

#ifdef HAVE_NSNUMBERFORMATTER_CONVERSIONS

NSNumberFormatter *__RKGetThreadLocalNumberFormatter(void) RK_ATTRIBUTES(pure, used);

RKREGEX_STATIC_PURE_INLINE NSNumberFormatter *RKGetThreadLocalNumberFormatter(void) {
  RK_STRONG_REF struct __RKThreadLocalData * RK_C99(restrict) tld = NULL;
  if(RK_EXPECTED((tld = RKGetThreadLocalData()) == NULL, 0)) { return(NULL); }
  return(RK_EXPECTED((tld->_numberFormatter != NULL), 1) ? tld->_numberFormatter : __RKGetThreadLocalNumberFormatter());
}

#endif // HAVE_NSNUMBERFORMATTER_CONVERSIONS

#endif // RK_ENABLE_THREAD_LOCAL_STORAGE

#endif // _REGEXKIT_REGEXKITPRIVATETHREADS_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
