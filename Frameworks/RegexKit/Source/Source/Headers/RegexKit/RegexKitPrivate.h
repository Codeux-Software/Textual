//
//  RegexKitPrivate.h
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

#ifndef _REGEXKIT_REGEXKITPRIVATE_H_
#define _REGEXKIT_REGEXKITPRIVATE_H_ 1

/*
 This file is intended to store various private bits for RKRegex such as:

 Runtime detection and configuration specifics (base runtime detection is from RKRegex.h)
 Compile time option configurations (ie, USE_* flags)
 Function prototypes that are for private use.
 Internal typedefs
 Preprocessor macros

 In general, this is for stuff that is compiler housekeeping (prototypes) or so simple and trivial that the specifics don't much matter (ala NSMakeRange & friends).
 The largest function currently is RKStringBufferWithString, which sort of doesn't fit here but sort of does, so it does.

 Mostly helps keep the main file cleaner looking.

 Compile unit global variables should /NOT/ be defined here.
*/

// Switches between #defines vs. RKREGEX_STATIC_INLINE functions for some things
#define _USE_DEFINES

#import <objc/objc.h>
#import <objc/objc-api.h>

#ifdef __MACOSX_RUNTIME__
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <objc/objc-auto.h>
#endif

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>
#import <RegexKit/RKRegex.h>

#import <RegexKit/RegexKitPrivateAtomic.h>
#import <RegexKit/RegexKitPrivateDTrace.h>
#import <RegexKit/RegexKitPrivateLocalization.h>
#import <RegexKit/RegexKitPrivateMemory.h>
#import <RegexKit/RegexKitPrivateThreads.h>
#import <RegexKit/NSStringPrivate.h>

// Useful min/max macros that only evaluate the parameters once, and are type sensitive.

#ifdef max
#warning max is already defined, max(a, b) may not not behave as expected.
#else
#define max(a,b) ({__typeof__(a) _a = (a); __typeof__(b) _b = (b); (_a > _b) ? _a : _b; })
#endif

#ifdef min
#warning min is already defined, min(a, b) may not behave as expected.
#else
#define min(a,b) ({__typeof__(a) _a = (a); __typeof__(b) _b = (b); (_a < _b) ? _a : _b; })
#endif

// Returns a string in the form of '[className selector]: standardStringFormat, formatArguments'
// Dynamically looks up the class name so inherited classes will reported the new class name, and not the base class name.
// example
// NSString *prettyString = RKPrettyObjectMethodString("A simple error occurred.  Size %d is invalid", requestedSize);
// [RKRegex setSize:]: A simple error occurred.  Size 2147483647 is invalid
//

#define RKPrettyObjectMethodString(stringArg, ...) RKPrettyObjectMethodStringFunction(self, _cmd, stringArg, ##__VA_ARGS__)

// Returns human readable string of an unknown object in the form of '[className @ 0x12345678]: '[object description]'...'
// The object description is limited to 40 characters, and adds a trailing '...' if the length exceeds that.
// The objects [[obj description] UTF8String] is evaluated twice, unfortunately, to remove the possibility of a NULL pointer to '%.40s'
//
#define RKPrettyObjectDescription(prettyObject) ([NSString stringWithFormat:@"[%@ @ %p]: '%.40s'%@", [prettyObject className], prettyObject, ([[prettyObject description] UTF8String] == NULL) ? "" : [[prettyObject description] UTF8String], ([[prettyObject description] length] > 40) ? @"...":@""])


// In RKRegex.m
//RKRegex *RKRegexFromStringOrRegex(id self, const SEL _cmd, id aRegex, const RKCompileOption compileOptions, const BOOL shouldAutorelease) RK_ATTRIBUTES(nonnull(3), pure, used, visibility("hidden"));
RKRegex *RKRegexFromStringOrRegexWithError(id self, const SEL _cmd, id aRegex, NSString * const RK_C99(restrict)libraryString, const RKCompileOption compileOptions, NSError **error, const BOOL shouldAutorelease) RK_ATTRIBUTES(nonnull(3, 4), used, visibility("hidden"));
RKRegex *RKRegexFromStringOrRegex(id self, SEL _cmd, id aRegex, RKCompileOption compileOptions, BOOL shouldAutorelease) RK_ATTRIBUTES(nonnull(3), used, visibility("hidden"));
//RKRegex *RKRegexFromStringOrRegexWithError(id self, SEL _cmd, id aRegex, NSString *libraryString, RKCompileOption compileOptions, NSError **error, BOOL shouldAutorelease) RK_ATTRIBUTES(nonnull(3, 4), pure, used, visibility("hidden"));

NSException *RKExceptionFromInitFailureForOlderAPI(id self, const SEL _cmd, NSError *initError) RK_ATTRIBUTES(used, visibility("hidden"), nonnull);
NSError *RKErrorForCompileInitFailure(id self, const SEL _cmd, RKStringBuffer *regexStringBuffer, RKUInteger errorOffset, RKCompileErrorCode compileErrorCode, RKCompileOption compileOption, RKUInteger abreviatedPadding) RK_ATTRIBUTES(nonnull(3), used, visibility("hidden"));
const char *regexUTF8String(RKRegex *self) RK_ATTRIBUTES(used, visibility("hidden"), nonnull(1));
RKUInteger RKCaptureIndexForCaptureNameCharacters(RKRegex * const aRegex, const SEL _cmd, const char * const RK_C99(restrict) captureNameCharacters, const RKUInteger length, const NSRange * const RK_C99(restrict) matchedRanges, const BOOL raiseExceptionOnDoesNotExist) RK_ATTRIBUTES(used, visibility("hidden"));
RKUInteger RKCaptureIndexForCaptureNameCharactersWithError(RKRegex * const aRegex, const SEL _cmd, const char * const RK_C99(restrict) captureNameCharacters, const RKUInteger length, const NSRange * const RK_C99(restrict) matchedRanges, NSError **error);

@interface RKRegex (Private)
- (RKMatchErrorCode)getRanges:(NSRange * const RK_C99(restrict))ranges count:(const RKUInteger)rangeCount withCharacters:(const void * const RK_C99(restrict))charactersBuffer length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;
@end


// In RKCache.m
id RKFastCacheLookup(RKCache * const self, const SEL _cmd RK_ATTRIBUTES(unused), const RKUInteger objectHash, NSString * const objectDescription, const BOOL shouldAutorelease) RK_ATTRIBUTES(used, visibility("hidden"), nonnull(1));
const char *cacheUTF8String(RKCache *self) RK_ATTRIBUTES(used, visibility("hidden"), nonnull(1));


// In RKPrivate.m
void      nsprintf( NSString * const formatString, ...)                                                           RK_ATTRIBUTES(visibility("hidden"));
void      vnsprintf(NSString * const formatString, va_list ap)                                                    RK_ATTRIBUTES(visibility("hidden"));
int       RKRegexPCRECallout(pcre_callout_block * const callout_block)                                            RK_ATTRIBUTES(visibility("hidden"), used);
NSArray  *RKArrayOfPrettyNewlineTypes(NSString * const prefixString)                                              RK_ATTRIBUTES(visibility("hidden"), used);
NSString *RKPrettyObjectMethodStringFunction( id self, SEL _cmd, NSString * const formatString, ...)              RK_ATTRIBUTES(visibility("hidden"), used);
NSString *RKVPrettyObjectMethodStringFunction(id self, SEL _cmd, NSString * const formatString, va_list argList)  RK_ATTRIBUTES(visibility("hidden"), used);

// In RKUtility.m
const char *RKCharactersFromCompileErrorCode(const RKCompileErrorCode decodeErrorCode);
const char *RKCharactersFromMatchErrorCode(  const RKMatchErrorCode   decodeErrorCode);


// NSRange related macros
#define NSEqualRanges(range1, range2)                 ({NSRange _r1 = (range1), _r2 = (range2); (_r1.location == _r2.location) && (_r1.length == _r2.length); })
#define NSLocationInRange(loc, r)                     ({ (__typeof__(NSRange.location)) _loc = (loc); NSRange _r = (r); (_lpc - _r.location) < _r.length; })
#define NSMakeRange(loc, len)                         ((NSRange){(RKUInteger)(loc), (RKUInteger)(len)})
#define NSMaxRange(r)                                 ({ NSRange _r = (r); _r.location + _r.length; })
#define RKRangeInsideRange(inside, within)            (((inside.location - within.location) < within.length) && ((NSMaxRange(inside) - within.location) <= within.length))

#define RKYesOrNo(yesOrNo)                            (((yesOrNo) == YES) ? RKLocalizedString(@"Yes"):RKLocalizedString(@"No"))

#ifdef    USE_CORE_FOUNDATION
#define RKHashForStringAndCompileOption(string, option) (RK_EXPECTED((string) == NULL, 0) ? (RKUInteger)(option) : ((RKUInteger)CFHash((CFTypeRef)(string)) ^ (RKUInteger)(option)))
#else  // USE_CORE_FOUNDATION is not defined
#define RKHashForStringAndCompileOption(string, option) (RK_EXPECTED((string) == NULL, 0) ? (RKUInteger)(option) : ([(string) hash] ^ (RKUInteger)(option)))
#endif // USE_CORE_FOUNDATION


// These imports have dependencies on the platform configuration details

#import <RegexKit/RKAutoreleasedMemory.h>
#import <RegexKit/RKPlaceholder.h>
#import <RegexKit/RKCoder.h>
#import <RegexKit/RKSortedRegexCollection.h>
#import <RegexKit/RKThreadPool.h>

#endif // _REGEXKIT_REGEXKITPRIVATE_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
