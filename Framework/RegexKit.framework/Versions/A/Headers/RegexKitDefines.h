//
//  RegexKitDefines.h
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

#ifdef __cplusplus
extern "C" {
#endif
  
#ifndef _REGEXKIT_REGEXKITDEFINES_H_
#define _REGEXKIT_REGEXKITDEFINES_H_ 1

#import <mach-o/loader.h>

#define __REGEXKIT__


// Determine runtime environment
#if !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)

#if defined(__APPLE__) && defined(__MACH__) && !defined(GNUSTEP)
#define __MACOSX_RUNTIME__
#endif // If not Mac OS X, GNUstep?

#if defined(GNUSTEP) && !defined(__MACOSX_RUNTIME__)
#define __GNUSTEP_RUNTIME__
#endif // Not Mac OS X or GNUstep, that's a problem.

#endif // !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)


// If the above did not set the run time environment, error out.
#if !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)
#error Unable to determine run time environment, automatic Mac OS X and GNUstep detection failed
#endif

#if defined(NSINTEGER_DEFINED)
#define RKInteger     NSInteger
#define RKUInteger    NSUInteger
#define RKIntegerMax  NSIntegerMax
#define RKIntegerMin  NSIntegerMin
#define RKUIntegerMax NSUIntegerMax
#else
#define RKInteger     int
#define RKUInteger    unsigned int
#define RKIntegerMax  INT_MAX
#define RKIntegerMin  INT_MIN
#define RKUIntegerMax UINT_MAX
#endif

#if defined (__GNUC__) && (__GNUC__ >= 4)
#define RKREGEX_STATIC_INLINE static __inline__ __attribute__((always_inline))
#define RKREGEX_STATIC_PURE_INLINE static __inline__ __attribute__((always_inline, pure))
#define RK_EXPECTED(cond, expect) __builtin_expect(cond, expect)
#define RK_ATTRIBUTES(attr, ...) __attribute__((attr, ##__VA_ARGS__))
#else
#define RKREGEX_STATIC_INLINE static __inline__
#define RKREGEX_STATIC_PURE_INLINE static __inline__
#define RK_EXPECTED(cond, expect) cond
#define RK_ATTRIBUTES(attr, ...)
#endif

#if defined(__MACOSX_RUNTIME__) && defined(MAC_OS_X_VERSION_10_5) && defined(NS_REQUIRES_NIL_TERMINATION)
#define RK_REQUIRES_NIL_TERMINATION NS_REQUIRES_NIL_TERMINATION
#else
#define RK_REQUIRES_NIL_TERMINATION
#endif

// Other compilers and platforms may be able to use the following:
//
// #define RK_REQUIRES_NIL_TERMINATION RK_ATTRIBUTES(sentinel)

#if __STDC_VERSION__ >= 199901L
#define RK_C99(keyword) keyword
#else
#define RK_C99(keyword) 
#endif

#ifdef __cplusplus
#define REGEXKIT_EXTERN           extern "C"
#define REGEXKIT_PRIVATE_EXTERN   __private_extern__
#else
#define REGEXKIT_EXTERN           extern
#define REGEXKIT_PRIVATE_EXTERN   __private_extern__
#endif
#define RKReplaceAll RKIntegerMax

// Used to size/check buffers when calling private RKRegex getRanges:count:withCharacters:length:inRange:options:
#define RK_PRESIZE_CAPTURE_COUNT(x) (256 + x + (x >> 1))
#define RK_MINIMUM_CAPTURE_COUNT(x) (x + ((x / 3) + ((3 - (x % 3)) % 3)))

/*************** Feature and config knobs ***************/

// Default enabled
#define USE_PLACEHOLDER

#if OBJC_API_VERSION < 2 && !defined (MAC_OS_X_VERSION_10_5)
#define USE_AUTORELEASED_MALLOC
#endif // Not enabled on Objective-C 2.0 (Mac OS X 10.5)

#ifdef __COREFOUNDATION__
#define USE_CORE_FOUNDATION
#endif

#ifdef __MACOSX_RUNTIME__
#define HAVE_NSNUMBERFORMATTER_CONVERSIONS
#endif

#if defined(HAVE_NSNUMBERFORMATTER_CONVERSIONS)
#define RK_ENABLE_THREAD_LOCAL_STORAGE
#endif

#if defined(__MACOSX_RUNTIME__) && defined(MAC_OS_X_VERSION_10_5) && defined(__OBJC_GC__)
#define ENABLE_MACOSX_GARBAGE_COLLECTION
#define RK_STRONG_REF                     __strong
#define RK_WEAK_REF                       __weak
#else
#define RK_STRONG_REF
#define RK_WEAK_REF
#endif

#if defined(ENABLE_MACOSX_GARBAGE_COLLECTION) && !defined(MAC_OS_X_VERSION_10_5)
#error The Mac OS X Garbage Collection feature requires at least Mac OS X 10.5
#endif

#if defined(__MACOSX_RUNTIME__) && defined(MAC_OS_X_VERSION_10_5) && defined(S_DTRACE_DOF)
#define ENABLE_DTRACE_INSTRUMENTATION
#endif

// AFAIK, only the GCC 3.3+ Mac OSX objc runtime has -fobjc-exception support
#if (!defined(__MACOSX_RUNTIME__)) || (!defined(__GNUC__)) || ((__GNUC__ == 3) && (__GNUC_MINOR__ < 3)) || (!defined(MAC_OS_X_VERSION_10_3))
// Otherwise, use NS_DURING / NS_HANDLER and friends
#define USE_MACRO_EXCEPTIONS
#endif

/*************** END Feature and config knobs ***************/

#endif //_REGEXKIT_REGEXKITDEFINES_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
