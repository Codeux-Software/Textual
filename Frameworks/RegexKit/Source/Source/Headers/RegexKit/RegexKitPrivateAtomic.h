//
//  RegexKitPrivateAtomic.h
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

#ifndef _REGEXKIT_REGEXKITPRIVATEATOMIC_H_
#define _REGEXKIT_REGEXKITPRIVATEATOMIC_H_ 1

#ifdef __MACOSX_RUNTIME__

#include <libkern/OSAtomic.h>

#define HAVE_RKREGEX_ATOMIC_OPS

#define RKAtomicMemoryBarrier(...)                             OSMemoryBarrier()

#define RKAtomicCompareAndSwapInt(oldValue, newValue, ptr)     OSAtomicCompareAndSwap32Barrier(oldValue, newValue, ptr)

#define RKAtomicIncrementInt(ptr)                              OSAtomicIncrement32(ptr)
#define RKAtomicDecrementInt(ptr)                              OSAtomicDecrement32(ptr)
#define RKAtomicIncrementIntBarrier(ptr)                       OSAtomicIncrement32Barrier(ptr)
#define RKAtomicDecrementIntBarrier(ptr)                       OSAtomicDecrement32Barrier(ptr)

#define RKAtomicOrIntBarrier(mask, ptr)                        OSAtomicOr32Barrier((mask), (ptr))
#define RKAtomicAndIntBarrier(mask, ptr)                       OSAtomicAnd32Barrier((mask), (ptr))
#define RKAtomicTestAndSetBarrier(bit, ptr)                    OSAtomicTestAndSetBarrier((bit), (ptr))
#define RKAtomicTestAndClearBarrier(bit, ptr)                  OSAtomicTestAndClearBarrier((bit), (ptr))

#ifdef __LP64__
#define RKAtomicCompareAndSwapPtr(oldp, newp, ptr)             OSAtomicCompareAndSwap64Barrier((int64_t)oldp,     (int64_t)newp,     (int64_t *)ptr)
#define RKAtomicCompareAndSwapInteger(oldValue, newValue, ptr) OSAtomicCompareAndSwap64Barrier((int64_t)oldValue, (int64_t)newValue, (int64_t *)ptr)

#define RKAtomicIncrementInteger(ptr)                          OSAtomicIncrement64(       (int64_t *)ptr)
#define RKAtomicDecrementInteger(ptr)                          OSAtomicDecrement64(       (int64_t *)ptr)
#define RKAtomicIncrementIntegerBarrier(ptr)                   OSAtomicIncrement64Barrier((int64_t *)ptr)
#define RKAtomicDecrementIntegerBarrier(ptr)                   OSAtomicDecrement64Barrier((int64_t *)ptr)
#else // __LP64__ not defined
#define RKAtomicCompareAndSwapPtr(oldp, newp, ptr)             OSAtomicCompareAndSwap32Barrier((int32_t)oldp,     (int32_t)newp,     (int32_t *)ptr)
#define RKAtomicCompareAndSwapInteger(oldValue, newValue, ptr) OSAtomicCompareAndSwap32Barrier((int32_t)oldValue, (int32_t)newValue, (int32_t *)ptr)

#define RKAtomicIncrementInteger(ptr)                          OSAtomicIncrement32(       (int32_t *)ptr)
#define RKAtomicDecrementInteger(ptr)                          OSAtomicDecrement32(       (int32_t *)ptr)
#define RKAtomicIncrementIntegerBarrier(ptr)                   OSAtomicIncrement32Barrier((int32_t *)ptr)
#define RKAtomicDecrementIntegerBarrier(ptr)                   OSAtomicDecrement32Barrier((int32_t *)ptr)
#endif // __LP64__

#endif //__MACOSX_RUNTIME__

// FreeBSD 5+
#if (__FreeBSD__ >= 5)
#include <sys/types.h>
#include <machine/atomic.h>
#include <unistd.h>

#define HAVE_RKREGEX_ATOMIC_OPS

RKREGEX_STATIC_INLINE void    RKAtomicMemoryBarrier(void)                                                              { volatile int x = 0; atomic_load_acq_int(&x); atomic_store_rel_int(&x, 1); }

RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInt(  int32_t oldValue, int32_t newValue, volatile int32_t *ptr)   { return(atomic_cmpset_rel_int(ptr, oldValue, newValue));            }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapPtr(  void    *oldp,    void    *newp,    volatile void    *ptr)   { return(atomic_cmpset_rel_ptr(ptr, oldp,      newp));               }

RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementInt(       int32_t *ptr)                                                { atomic_add_int(ptr, 1);           return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementInt(       int32_t *ptr)                                                { atomic_subtract_int(ptr, 1);      return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementIntBarrier(int32_t *ptr)                                                { atomic_add_rel_int(ptr, 1);       return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementIntBarrier(int32_t *ptr)                                                { atomic_subtract_rel_int(ptr, 1);  return(atomic_load_acq_32(ptr)); }

#ifdef __LP64__
RKREGEX_STATIC_INLINE int64_t RKAtomicIncrementInteger(       int64_t *ptr)                                            { atomic_add_long(ptr, 1);          return(atomic_load_acq_64(ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicDecrementInteger(       int64_t *ptr)                                            { atomic_subtract_long(ptr, 1);     return(atomic_load_acq_64(ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicIncrementIntegerBarrier(int64_t *ptr)                                            { atomic_add_rel_long(ptr, 1);      return(atomic_load_acq_64(ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicDecrementIntegerBarrier(int64_t *ptr)                                            { atomic_subtract_rel_long(ptr, 1); return(atomic_load_acq_64(ptr)); }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInteger(int64_t oldValue, int64_t newValue, volatile int64_t *ptr) { return(atomic_cmpset_rel_long(ptr, oldValue, newValue));           }
#else // __LP64__ not defined
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementInteger(       int32_t *ptr)                                            { atomic_add_int(ptr, 1);           return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementInteger(       int32_t *ptr)                                            { atomic_subtract_int(ptr, 1);      return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementIntegerBarrier(int32_t *ptr)                                            { atomic_add_rel_int(ptr, 1);       return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementIntegerBarrier(int32_t *ptr)                                            { atomic_subtract_rel_int(ptr, 1);  return(atomic_load_acq_32(ptr)); }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInteger(int32_t oldValue, int32_t newValue, volatile int32_t *ptr) { return(atomic_cmpset_rel_int(ptr, oldValue, newValue));            }
#endif // __LP64__

#endif //__FreeBSD__

// Solaris
#if defined(__sun__) && defined(__svr4__)
#include <atomic.h>

#define HAVE_RKREGEX_ATOMIC_OPS

RKREGEX_STATIC_INLINE void    RKAtomicMemoryBarrier(          void)                                                      { membar_enter(); membar_exit();             }

RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInt(      int32_t oldValue, int32_t newValue, volatile int32_t *ptr) { return(atomic_cas_uint(ptr, (uint_t)oldValue, (uint_t)newValue) == oldValue ? YES : NO); }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapPtr(      void    *oldp,    void    *newp,    volatile void    *ptr) { return(atomic_cas_ptr(ptr, oldp, newp) == oldp ? YES : NO); }

RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementInt(           int32_t *ptr)                                              { return(atomic_inc_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementInt(           int32_t *ptr)                                              { return(atomic_dec_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementIntBarrier(    int32_t *ptr)                                              { return(atomic_inc_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementIntBarrier(    int32_t *ptr)                                              { return(atomic_dec_uint_nv((uint_t *)ptr)); }

#ifdef __LP64__
RKREGEX_STATIC_INLINE int64_t RKAtomicIncrementInteger(       int64_t *ptr)                                              { return(atomic_inc_ulong_nv((uint64_t *)ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicDecrementInteger(       int64_t *ptr)                                              { return(atomic_dec_ulong_nv((uint64_t *)ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicIncrementIntegerBarrier(int64_t *ptr)                                              { return(atomic_inc_ulong_nv((uint64_t *)ptr)); }
RKREGEX_STATIC_INLINE int64_t RKAtomicDecrementIntegerBarrier(int64_t *ptr)                                              { return(atomic_dec_ulong_nv((uint64_t *)ptr)); }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInteger(  int64_t oldValue, int64_t newValue, volatile int64_t *ptr) { return(atomic_cas_ulong(ptr, (uint64_t)oldValue, (uint64_t)newValue) == oldValue ? YES : NO); }
#else // __LP64__ not defined
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementInteger(       int32_t *ptr)                                              { return(atomic_inc_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementInteger(       int32_t *ptr)                                              { return(atomic_dec_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicIncrementIntegerBarrier(int32_t *ptr)                                              { return(atomic_inc_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE int32_t RKAtomicDecrementIntegerBarrier(int32_t *ptr)                                              { return(atomic_dec_uint_nv((uint_t *)ptr)); }
RKREGEX_STATIC_INLINE BOOL    RKAtomicCompareAndSwapInteger(  int32_t oldValue, int32_t newValue, volatile int32_t *ptr) { return(atomic_cas_uint(ptr, (uint_t)oldValue, (uint_t)newValue) == oldValue ? YES : NO); }
#endif // __LP64__

#endif // Solaris __sun__ __svr4__

// Try for GCC 4.1+ built in atomic ops and pthreads?
#if !defined(HAVE_RKREGEX_ATOMIC_OPS) && ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 1))

#warning Unable to determine platform specific atomic operations. Trying gcc 4.1+ built in atomic ops

#define HAVE_RKREGEX_ATOMIC_OPS

#define RKAtomicMemoryBarrier(...)                             __sync_synchronize()
#define RKAtomicIncrementInt(ptr)                              __sync_add_and_fetch(ptr, 1)
#define RKAtomicDecrementInt(ptr)                              __sync_sub_and_fetch(ptr, 1)
#define RKAtomicIncrementIntBarrier(ptr)                       __sync_add_and_fetch(ptr, 1)
#define RKAtomicDecrementIntBarrier(ptr)                       __sync_sub_and_fetch(ptr, 1)
#define RKAtomicCompareAndSwapInt(oldValue, newValue, ptr)     __sync_bool_compare_and_swap(ptr, oldValue, newValue)
#define RKAtomicCompareAndSwapPtr(oldp, newp, ptr)             __sync_bool_compare_and_swap(ptr, oldValue, newValue)

#define RKAtomicIncrementInteger(ptr)                          __sync_add_and_fetch(ptr, 1)
#define RKAtomicDecrementInteger(ptr)                          __sync_sub_and_fetch(ptr, 1)
#define RKAtomicIncrementIntegerBarrier(ptr)                   __sync_add_and_fetch(ptr, 1)
#define RKAtomicDecrementIntegerBarrier(ptr)                   __sync_sub_and_fetch(ptr, 1)
#define RKAtomicCompareAndSwapInteger(oldValue, newValue, ptr) __sync_bool_compare_and_swap(ptr, oldValue, newValue)

#endif // HAVE_RKREGEX_ATOMIC_OPS && gcc >= 4.1 


#ifndef   HAVE_RKREGEX_ATOMIC_OPS
#error Unable to determine atomic operations for this platform.
#endif // HAVE_RKREGEX_ATOMIC_OPS


#endif // _REGEXKIT_REGEXKITPRIVATEATOMIC_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
