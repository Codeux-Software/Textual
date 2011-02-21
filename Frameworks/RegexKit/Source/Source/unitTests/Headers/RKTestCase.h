//
//  RKTestCase.h
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
#import <SenTestingKit/SenTestingKit.h>
#import <stdint.h>
#import <unistd.h>
#import <pthread.h>
#import <sys/types.h>
#import <sys/time.h>
#import <sys/resource.h>
#import <objc/objc-auto.h>
#import <objc/objc-runtime.h>
#import "NSDate.h"

#define RKPrettyObjectMethodString(stringArg, ...) [NSString stringWithFormat:[NSString stringWithFormat:@"%p [%@ %@]: %@", self, NSStringFromClass([(id)self class]), NSStringFromSelector(_cmd), stringArg], ##__VA_ARGS__]

#define RKYesOrNo(yesOrNo) (((yesOrNo) == YES) ? @"Yes":@"No")

#ifndef STAssertTrue
// Use these when testing under FreeBSD and OCUnit v27

#define STAssertTrue(exeLine, ...)                should(((exeLine) != 0))
#define STAssertNil(exeLine, ...)                 should(((exeLine) == nil))
#define STAssertNoThrow(exeLine, ...)             shouldntRaise((exeLine))
#define STAssertNotNil(exeLine, ...)              should(((exeLine) != nil))
#define STAssertThrows(exeLine, ...)              shouldRaise((exeLine))
#define STAssertThrowsSpecificNamed(exeLine, ...) shouldRaise((exeLine))
#define STAssertFalse(exeLine, ...)               should(((exeLine) == 0))

#endif

extern NSBundle *unitTestBundle;

extern NSArray *blacklistArray;
extern NSArray *whitelistArray;
extern NSArray *urlArray;

extern NSString *leakEnvString;
extern NSString *debugEnvString;
extern NSString *timingEnvString;
extern NSString *multithreadingEnvString;
extern NSString *sleepWhenFinishedEnvString;

extern int32_t garbageCollectorEnabled;

void (*objc_collect_function)(unsigned long);

@interface RKTestCase : SenTestCase {

}

@end

@interface RKSortedRegexCollection : NSObject
+ (RKCache *)sortedRegexCollectionCache;
+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))collection;
+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))collection library:(NSString * const RK_C99(restrict))initRegexLibraryString options:(const RKCompileOption)initRegexLibraryOptions error:(NSError ** const RK_C99(restrict))error;
@end

