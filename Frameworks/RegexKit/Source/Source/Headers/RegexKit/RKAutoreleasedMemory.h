//
//  RKAutoreleasedMemory.h
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
  
#ifndef _REGEXKIT_RKAUTORELEASEDMEMORY_H_
#define _REGEXKIT_RKAUTORELEASEDMEMORY_H_ 1

#import <Foundation/Foundation.h>
#import <RegexKit/RKRegex.h>
#import <RegexKit/RegexKitPrivate.h>

// defines the RKAutoreleasedMalloc macro which maps to the appropriate function

#ifdef USE_AUTORELEASED_MALLOC

@interface RKAutoreleasedMemory : NSObject {
}
@end

#define RKAutoreleasedMalloc(x) autoreleasedMalloc(x)
void *autoreleasedMalloc(const size_t length) RK_ATTRIBUTES(malloc, used, visibility("hidden"));

#else // USE_AUTORELEASED_MALLOC == NO

#ifdef USE_CORE_FOUNDATION 
#define RKAutoreleasedMalloc(x) (void *)CFDataGetMutableBytePtr((CFMutableDataRef)(RKMakeCollectableOrAutorelease(CFDataCreateMutable(NULL, (CFIndex)x))))
#else
#define RKAutoreleasedMalloc(x) [[NSMutableData dataWithLength:((RKUInteger))x] mutableBytes]
#endif

#endif //USE_AUTORELEASED_MALLOC

#endif // _REGEXKIT_RKAUTORELEASEDMEMORY_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
