//
//  RegexKitPrivateMemory.h
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
  
#ifndef _REGEXKIT_REGEXKITPRIVATEMEMORY_H_
#define _REGEXKIT_REGEXKITPRIVATEMEMORY_H_ 1

// Used to inform the compiler / cpu to prefetch data in to the caches.
#if       defined (__GNUC__) && (__GNUC__ >= 4)
#define RKPrefetch(addr)          __builtin_prefetch((addr), 0);
#define RKPrefetchRead(addr)      __builtin_prefetch((addr), 0);
#define RKPrefetchWrite(addr)     __builtin_prefetch((addr), 1);
#define RKPrefetchOnce(addr)      __builtin_prefetch((addr), 0, 0);
#define RKPrefetchReadOnce(addr)  __builtin_prefetch((addr), 0, 0);
#define RKPrefetchWriteOnce(addr) __builtin_prefetch((addr), 1, 0);
#else  // __GNUC__ is not defined || __GNUC__ < 4
#define RKPrefetch(addr)
#define RKPrefetchRead(addr)
#define RKPrefetchWrite(addr)
#define RKPrefetchOnce(addr)
#define RKPrefetchReadOnce(addr)
#define RKPrefetchWriteOnce(addr)
#endif // defined (__GNUC__) && (__GNUC__ >= 4)


#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION

extern int32_t RKRegexGarbageCollect; // Set in the RKRegex +load method, used by all.

#define RKAutoreleasedMallocNoGC(size)                (RKAutoreleasedMalloc((size)))
#define RKAutoreleasedMallocScanned(size)             (RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? RKAutoreleasedMalloc((size)) : NSAllocateCollectable((size), NSScannedOption))
#define RKAutoreleasedMallocNotScanned(size)          (RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? RKAutoreleasedMalloc((size)) : NSAllocateCollectable((size), 0))
#define RKMallocNoGC(size)                            (malloc((size)))
#define RKMallocScanned(size)                         (RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? malloc((size)) : NSAllocateCollectable((size), NSScannedOption))
#define RKMallocNotScanned(size)                      (RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? malloc((size)) : NSAllocateCollectable((size), 0))
#define RKCallocNoGC(size)                            (calloc((size), 1))
#define RKCallocScanned(size)                         ({size_t _size = (size); RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? calloc(_size, 1) : memset(NSAllocateCollectable(_size, NSScannedOption), 0, _size); })

#define RKCallocNotScanned(size)                      ({size_t _size = (size); RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? calloc(_size, 1) : memset(NSAllocateCollectable(_size, 0), 0, _size); })
#define RKFreeAndNULL(ptr)                        { if(RK_EXPECTED(RKRegexGarbageCollect == 0, 1)) { free(ptr); } ptr = NULL; }
#define RKFreeAndNULLNoGC(ptr)                                                                     { free(ptr);   ptr = NULL; }
#define RKMemMoveGC(dst, src, size)                   (RK_EXPECTED(RKRegexGarbageCollect == 0, 1) ? memmove((dst), (src), (size)) : objc_memmove_collectable((dst), (src), (size)))

#define RKEnableCollectorForPointer(x)              if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { if(RK_EXPECTED((x) != NULL, 1)) { [[objc_getClass("NSGarbageCollector") defaultCollector] enableCollectorForPointer:(x)];  } }
#define RKDisableCollectorForPointer(x)             if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { if(RK_EXPECTED((x) != NULL, 1)) { [[objc_getClass("NSGarbageCollector") defaultCollector] disableCollectorForPointer:(x)]; } }
#define RKMakeCollectable(x)                           RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? NSMakeCollectable((id)(x)) : (id)(x)
#define RKMakeCollectableOrAutorelease(x)              RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? NSMakeCollectable((id)(x)) : [(id)(x) autorelease]
#define RKAutorelease(x)                               RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : [(x) autorelease]
#define RKCFRetain(x)                                  RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : CFRetain((x))
#define RKCFRelease(x)                                 RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : CFRelease((x))
#define RKRetain(x)                                    RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : [(x) retain]
#define RKRelease(x)                                   RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : [(x) release]
#define RKDealloc(x)                                   RK_EXPECTED(RKRegexGarbageCollect == 1, 0)  ? (x) : [(x) dealloc]

#else  // ENABLE_MACOSX_GARBAGE_COLLECTION not defined

#define RKRegexGarbageCollect 0

#define RKAutoreleasedMallocNoGC(size)                (RKAutoreleasedMalloc((size)))
#define RKAutoreleasedMallocScanned(size)             (RKAutoreleasedMalloc((size)))
#define RKAutoreleasedMallocNotScanned(size)          (RKAutoreleasedMalloc((size)))
#define RKMallocNoGC(size)                            (malloc((size)))
#define RKMallocScanned(size)                         (malloc((size)))
#define RKMallocNotScanned(size)                      (malloc((size)))
#define RKCallocNoGC(size)                            (calloc((size), 1))
#define RKCallocScanned(size)                         (calloc((size), 1))
#define RKCallocNotScanned(size)                      (calloc((size), 1))
#define RKFreeAndNULL(ptr)                           { free(ptr); ptr = NULL; }
#define RKFreeAndNULLNoGC(ptr)                       { free(ptr); ptr = NULL; }
#define RKMemMoveGC(dst, src, size)                   (memmove((dst), (src), (size)))

#define RKEnableCollectorForPointer(x)
#define RKDisableCollectorForPointer(x)
#define RKMakeCollectable(x)                          (id)(x)
#define RKMakeCollectableOrAutorelease(x)             [(id)(x) autorelease]
#define RKAutorelease(x)                              [(id)(x) autorelease]
#define RKCFRetain(x)                                 CFRetain((x))
#define RKCFRelease(x)                                CFRelease((x))
#define RKRetain(x)                                   [(id)(x) retain]
#define RKRelease(x)                                  [(id)(x) release]
#define RKDealloc(x)                                  [(id)(x) dealloc]

#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

#endif // _REGEXKIT_REGEXKITPRIVATEMEMORY_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
