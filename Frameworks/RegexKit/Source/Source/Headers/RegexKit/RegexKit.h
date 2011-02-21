//
//  RegexKit.h
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
  
#ifndef _REGEXKIT_REGEXKIT_H_
#define _REGEXKIT_REGEXKIT_H_ 1

#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>

// Include primary header for the runtime environment
#ifdef __MACOSX_RUNTIME__
#import <Cocoa/Cocoa.h>
#else // Using GNUstep run time
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h> 
#endif //__MACOSX_RUNTIME__ defined in RegexKitDefines

// RKLock and RKReadWriteLock are private classes
@class RKRegex, RKCache, RKEnumerator, RKLock, RKReadWriteLock;

#ifdef USE_AUTORELEASED_MALLOC
@class RKAutoreleasedMemory;
#endif

#ifdef USE_PLACEHOLDER
@class RKRegexPlaceholder;
#endif

#import <RegexKit/pcre.h>
  
#import <RegexKit/RKCache.h>
#import <RegexKit/RKRegex.h>
#import <RegexKit/RKEnumerator.h>
#import <RegexKit/RKUtility.h>
#import <RegexKit/NSArray.h>
#import <RegexKit/NSData.h>
#import <RegexKit/NSDictionary.h>
#import <RegexKit/NSObject.h>
#import <RegexKit/NSSet.h>
#import <RegexKit/NSString.h>
  
  
#endif // _REGEXKIT_REGEXKIT_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
