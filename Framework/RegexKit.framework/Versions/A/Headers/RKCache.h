//
//  RKCache.h
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
  
#ifndef _REGEXKIT_RKCACHE_H_
#define _REGEXKIT_RKCACHE_H_ 1

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>
#import <dlfcn.h>

@class RKReadWriteLock;

@interface RKCache : NSObject {
  RK_STRONG_REF RKReadWriteLock *cacheRWLock;
  RK_STRONG_REF NSMapTable      *cacheMapTable;
  RK_STRONG_REF NSString        *cacheDescriptionString;
                RKUInteger       cacheHits;
                RKUInteger       cacheMisses;
                RKUInteger       cacheClearedCount;
                int              cacheInitialized;
                int              cacheIsEnabled;
                int              cacheAddingIsEnabled;   // Used during debugging
                int              cacheLookupIsEnabled;   // Used during debugging  
  RK_STRONG_REF char            *cacheDescriptionUTF8String;
}
- (id)initWithDescription:(NSString * const)descriptionString;
- (void)setDescription:(NSString * const)descriptionString;
- (NSString *)status;
- (NSString *)description;
- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString;
- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString autorelease:(const BOOL)shouldAutorelease;
- (BOOL)addObjectToCache:(id)object;
- (BOOL)addObjectToCache:(id)object withHash:(const RKUInteger)objectHash;
- (id)removeObjectFromCache:(id)object;
- (id)removeObjectWithHash:(const RKUInteger)objectHash;
- (BOOL)clearCache;
- (NSSet *)cacheSet;
- (BOOL)isCacheEnabled;
- (BOOL)setCacheEnabled:(const BOOL)enableCache;
- (RKUInteger)cacheCount;

@end


@interface RKCache (CacheDebugging)

- (BOOL)isCacheAddingEnabled;
- (BOOL)setCacheAddingEnabled:(const BOOL)enableCacheAdding;
- (BOOL)isCacheLookupEnabled;
- (BOOL)setCacheLookupEnabled:(const BOOL)enableCacheLookup;

@end

@interface RKCache (CountersDebugging)

- (void)setDebug:(const BOOL)enableDebugging;
- (void)clearCounters;
- (RKUInteger)cacheClearedCount;
- (RKUInteger)readBusyCount;
- (RKUInteger)readSpinCount;
- (RKUInteger)writeBusyCount;
- (RKUInteger)writeSpinCount;

@end

#endif // _REGEXKIT_RKCACHE_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
