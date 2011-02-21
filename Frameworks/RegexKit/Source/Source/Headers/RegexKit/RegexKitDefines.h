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

/*!
 @defined RKInteger
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for cross-platform @link NSInteger NSInteger @/link functionality.
 @discussion <p>On <span class="nobr">Mac OS X 10.5</span> this is defined to be @link NSInteger NSInteger@/link, otherwise it is defined as <span class="code">int</span>.</p>
 <p>This is done as a preprocessor macro so that it is rewritten in to the proper type for the build environment for type checking.</p>
*/

/*!
 @defined RKUInteger
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for cross-platform @link NSUInteger NSUInteger @/link functionality.
 @discussion <p>On <span class="nobr">Mac OS X 10.5</span> this is defined to be @link NSUInteger NSUInteger@/link, otherwise it is defined as <span class="code">unsigned int</span>.</p>
 <p>This is done as a preprocessor macro so that it is rewritten in to the proper type for the build environment for type checking.</p>
*/

/*!
 @defined RKIntegerMax
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for cross-platform @link NSIntegerMax NSIntegerMax @/link functionality.
 @discussion <p>On <span class="nobr">Mac OS X 10.5</span> this is defined to be @link NSIntegerMax NSIntegerMax@/link, otherwise it is defined as @link INT_MAX INT_MAX@/link.</p>
*/

/*!
 @defined RKIntegerMin
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for cross-platform @link NSIntegerMin NSIntegerMin @/link functionality.
 @discussion <p>On <span class="nobr">Mac OS X 10.5</span> this is defined to be @link NSIntegerMin NSIntegerMin@/link, otherwise it is defined as @link INT_MIN INT_MIN@/link.</p>
*/

/*!
 @defined RKUIntegerMax
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for cross-platform @link NSUIntegerMax NSUIntegerMax @/link functionality.
 @discussion <p>On <span class="nobr">Mac OS X 10.5</span> this is defined to be @link NSUIntegerMax NSUIntegerMax@/link, otherwise it is defined as @link UINT_MAX UINT_MAX@/link.</p>
*/

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

/*!
@defined RKREGEX_STATIC_INLINE
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition for making functions static inline.
 @discussion <p>@link RKREGEX_STATIC_INLINE RKREGEX_STATIC_INLINE @/link is a wrapper around GCC 4+ directives to always static inline.</p>
<p>Borrowed from <span class="nobr">Mac OS X</span> @link NSObjCRuntime.h NSObjCRuntime.h @/link @link FOUNDATION_STATIC_INLINE FOUNDATION_STATIC_INLINE @/link to be portable to @link GNUstep GNUstep@/link.</p>
<p>Evaluates to <span class="nobr code">static __inline__</span> for compilers other than GCC 4+.</p>
*/

/*!
@defined RK_EXPECTED
 @tocgroup Constants Preprocessor Macros
 @abstract Macro to assist the compiler by providing branch prediction information.
 @param cond The boolean conditional statement to be evaluated, for example <span class="code nobr">(aPtr == NULL)</span>.
 @param expect The expected result of the conditional statement, expressed as a <span class="code">0</span> or a <span class="code">1</span>.
 @discussion  <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell"><span class="code">RK_EXPECTED</span> should only be used when the likelihood of the prediction is nearly certain. <b><i>DO NOT GUESS</i></b>.</div></div></div></div>
 <p>@link RK_EXPECTED RK_EXPECTED @/link is a wrapper around the GCC 4+ built-in function <a href="http://gcc.gnu.org/onlinedocs/gcc-4.0.4/gcc/Other-Builtins.html#index-g_t_005f_005fbuiltin_005fexpect-2284" class="code">__builtin_expect</a>, which is used to provide the compiler with branch prediction information for conditional statements.  If a compiler other than GCC 4+ is used then the macro leaves the conditional expression unaltered.</p>
 <p>An example of an appropriate use is parameter validation checks at the start of a function, such as <span class="code nobr">(aPtr == NULL)</span>.  Since callers are always expected to pass a valid pointer, the likelyhood of the conditional evaluating to true is extremely unlikely.  This allows the compiler to schedule instructions to minimize branch miss-prediction penalties. For example:
 <div class="box sourcecode">if(RK_EXPECTED((aPtr == NULL), 0)) { abort(); }</div>
*/

/*!
@defined RK_ATTRIBUTES
 @tocgroup Constants Preprocessor Macros
 @abstract Macro wrapper around GCC <a href="http://gcc.gnu.org/onlinedocs/gcc-4.0.4/gcc/Attribute-Syntax.html#Attribute-Syntax" class="code">__attribute__</a> syntax.
 @discussion <p>When a compiler other than GCC 4+ is used, <span class="code">RK_ATTRIBUTES</span> evaluates to an empty string, removing itself and its arguments from the code to be compiled.</p>
*/

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

/*!
 @defined RK_REQUIRES_NIL_TERMINATION
 @tocgroup Constants Preprocessor Macros
 @abstract Compile time check for functions and methods that support a varying number of arguments that must be terminated with a <span class="code">NULL</span> or <span class="code">nil</span> as the last argument.
 @discussion <p>Supported on <span class="nobr">Mac OS X 10.5</span> and later.</p>
*/

#if defined(__MACOSX_RUNTIME__) && defined(MAC_OS_X_VERSION_10_5) && defined(NS_REQUIRES_NIL_TERMINATION)
#define RK_REQUIRES_NIL_TERMINATION NS_REQUIRES_NIL_TERMINATION
#else
#define RK_REQUIRES_NIL_TERMINATION
#endif

// Other compilers and platforms may be able to use the following:
//
// #define RK_REQUIRES_NIL_TERMINATION RK_ATTRIBUTES(sentinel)

/*!
@defined RK_C99
 @tocgroup Constants Preprocessor Macros
 @abstract Macro wrapper around <span class="code">C99</span> keywords.
 @discussion <p>@link RK_C99 RK_C99 @/link is a wrapper for <span class="code">C99</span> standard keywords that are not compatible with previous <span class="code">C</span> standards, such as <span class="code">C89</span>.</p>
<p>This is used almost exclusively to wrap the <span class="code">C99</span> <span class="code">restrict</span> keyword.</p>
*/

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

/*!
@defined RKReplaceAll
 @tocgroup Constants Constants
 @abstract Predefined <span class="argument">count</span> for use with <a href="NSString.html#ExpansionofCaptureSubpatternMatchReferencesinStrings" class="section-link">Search and Replace</a> methods to specify all matches are to be replaced.
*/
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


/*!
 @defined ENABLE_MACOSX_GARBAGE_COLLECTION
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition to enable <span class="nobr">Mac OS X 10.5 (Leopard)</span> <span class="nobr">Garbage Collection</span>.
 @discussion <p>This preprocessor define enables support for <span class="nobr">Garbage Collection</span> on <span class="nobr">Mac OS X 10.5 (Leopard)</span>.  Traditional <span class="nobr">@link retain retain @/link / @link release release @/link</span> functionality remains allowing the framework to be used in either <span class="nobr">Garbage Collected</span> enabled applications or reference counting applications.  The framework dynamically picks which mode to use at run-time base on whether or not the <span class="nobr">Garbage Collection</span> system is active.</p>
 @seealso <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/GarbageCollection/index.html" class="section-link" target="_top">Garbage Collection Programming Guide</a>
 @seealso <a href="http://developer.apple.com/documentation/Cocoa/Reference/NSGarbageCollector_class/index.html" class="section-link" target="_top">NSGarbageCollector Class Reference</a>
*/

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

/*!
 @defined ENABLE_DTRACE_INSTRUMENTATION
 @tocgroup Constants Preprocessor Macros
 @abstract Preprocessor definition to enable RegexKit specific DTrace probe points.
 @discussion <p>This preprocessor define enables support for RegexKit specific DTrace probe points.</p>
 @seealso <a href="http://developer.apple.com/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/index.html" class="section-link" target="_top">Instruments User Guide</a>
 @seealso <a href="http://docs.sun.com/app/docs/doc/817-6223" class="section-link" target="_top">Solaris Dynamic Tracing Guide</a> <a href="http://dlc.sun.com/pdf/817-6223/817-6223.pdf" class="section-link" target="_top">(as .PDF)</a>
*/

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
