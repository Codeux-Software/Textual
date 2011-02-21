//
//  RKCache.m
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

/*
 This object uses locks to enforce cache consistency.
 
 Code that is acquires and releases the lock are surrounded with the comment pair
 
 // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv

 // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^

 as a visual reminder that code within the comments is sensitive to lock based programming problems.
*/

#import <RegexKit/RKCache.h>
#import <RegexKit/RegexKitPrivate.h>
// Not placed in RKCache.h because that's a public include which would require RKLock.h to be public, but it's only used internally.
#import <RegexKit/RKLock.h>

@implementation RKCache

static NSMapTableKeyCallBacks *cacheMapKeyCallBacks   = NULL;
static int32_t                 RKCacheLoadInitialized = 0;

#pragma mark -
#pragma mark Misc Garbage Collection

#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION

// This creates the support objects that we'll need if garbage collection is found to be enabled at run time.
// If GC is enabled (RKRegexGarbageCollect == 1) then the following is used to create a Mac OS X 10.5
// NSHashMap object that uses NSPointerFunctionsZeroingWeakMemory, or in other words the GC system will
// automatically remove a cached RKRegex object when it falls out of scope and is no longer reachable.
// This means the cache is automatically trimmed to the working set.  The new class NSPointerFunctions
// are used to perform the typicaly isEqual/Hash comparision primitives.  Since we use the computed
// NSUInteger hash for a given regex for the map key, we don't need to store objects per se, so our
// overhead is very low.  Unfortunatly, a pre-fabbed NSUInteger key based NSHashMap is not provided,
// unlike it's predecesor (which we use if GC is not enabled).
//
// We use some clever preprocessor macros to selectively include the enhanced garbage collection
// functionality while keeping

static RK_STRONG_REF NSPointerFunctions *RKCacheIntegerKeyPointerFunctions  = NULL;
static RK_STRONG_REF NSPointerFunctions *RKCacheObjectValuePointerFunctions = NULL;

void       *intPointerFunctionsAcquire(const void *src, NSUInteger (*size)(const void *item) RK_ATTRIBUTES(unused), BOOL shouldCopy RK_ATTRIBUTES(unused)) { return((void *)src); }
NSString   *intPointerFunctionsDescription(const void *item) { return([NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedLong:(unsigned long)item]]); }
RKUInteger  intPointerFunctionsHash(const void *item, NSUInteger (*size)(const void *item) RK_ATTRIBUTES(unused)) { return((RKUInteger)item); }
BOOL        intPointerFunctionsIsEqual(const void *item1, const void*item2, NSUInteger (*size)(const void *item) RK_ATTRIBUTES(unused)) { return(item1 == item2); }
void        intPointerFunctionsRelinquish(const void *item RK_ATTRIBUTES(unused), NSUInteger (*size)(const void *item) RK_ATTRIBUTES(unused)) { return; }
RKUInteger  intPointerFunctionsSize(const void *item RK_ATTRIBUTES(unused)) { return(sizeof(RKUInteger)); }

#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

#pragma mark -


+ (void)load
{
  RKAtomicMemoryBarrier(); // Extra cautious
  if(RKCacheLoadInitialized == 1) { return; }
  
  if(RKAtomicCompareAndSwapInt(0, 1, &RKCacheLoadInitialized)) {
    if((cacheMapKeyCallBacks = dlsym(RTLD_DEFAULT, "NSIntegerMapKeyCallBacks")) == NULL) { cacheMapKeyCallBacks = dlsym(RTLD_DEFAULT, "NSIntMapKeyCallBacks"); }

#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
    id garbageCollector = objc_getClass("NSGarbageCollector");
    
    if(garbageCollector != NULL) {
      if([garbageCollector defaultCollector] != NULL) {
        id pointerFunctions = objc_getClass("NSPointerFunctions");

        RKCacheIntegerKeyPointerFunctions = [pointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsIntegerPersonality];
        RKCacheIntegerKeyPointerFunctions.acquireFunction     = intPointerFunctionsAcquire;
        RKCacheIntegerKeyPointerFunctions.descriptionFunction = intPointerFunctionsDescription;
        RKCacheIntegerKeyPointerFunctions.hashFunction        = intPointerFunctionsHash;
        RKCacheIntegerKeyPointerFunctions.isEqualFunction     = intPointerFunctionsIsEqual;
        RKCacheIntegerKeyPointerFunctions.relinquishFunction  = intPointerFunctionsRelinquish;
        RKCacheIntegerKeyPointerFunctions.sizeFunction        = intPointerFunctionsSize;
        
        RKCacheObjectValuePointerFunctions = [pointerFunctions pointerFunctionsWithOptions:(NSPointerFunctionsZeroingWeakMemory | NSPointerFunctionsObjectPersonality)];
        
        [[garbageCollector defaultCollector] disableCollectorForPointer:RKCacheIntegerKeyPointerFunctions];
        [[garbageCollector defaultCollector] disableCollectorForPointer:RKCacheObjectValuePointerFunctions];
      }
    }
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION
  }
}

- (id)init
{
  RKAtomicMemoryBarrier(); // Extra cautious
  if(RK_EXPECTED(cacheInitialized == 1, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"This cache is already initialized."] raise]; }
  
  if(RK_EXPECTED((self = [super init]) == NULL, 0)) { goto errorExit; }

  RKAutorelease(self);
    
  if(RKAtomicCompareAndSwapInt(0, 1, &cacheInitialized)) {
    if(RK_EXPECTED((cacheRWLock = [[RKReadWriteLock alloc] init]) == NULL, 0)) { NSLog(@"Unable to initialize cache lock, caching is disabled."); goto errorExit; }
    else {
      if(RK_EXPECTED([self clearCache] == NO, 0)) { NSLog(@"Unable to create cache hash map."); goto errorExit; }
      cacheClearedCount = 0;
      cacheAddingIsEnabled = cacheLookupIsEnabled = cacheIsEnabled = YES;
    }
  }
  
  return(RKRetain(self));
  
errorExit:
  return(NULL);
}

- (id)initWithDescription:(NSString * const)descriptionString
{
  if(RK_EXPECTED((self = [self init]) == NULL, 0)) { return(NULL); }
  [self setDescription:descriptionString];
  return(self);
}

- (void)setDescription:(NSString * const)descriptionString
{
  if(cacheDescriptionString != NULL) { RKAutorelease(cacheDescriptionString); cacheDescriptionString = NULL; }
  if(descriptionString      != NULL) { cacheDescriptionString = RKRetain(descriptionString);                 }
}

const char *cacheUTF8String(RKCache *self) {
  if(RK_EXPECTED(self == NULL, 0)) { return("self == NULL"); }
  if(RK_EXPECTED(self->cacheDescriptionUTF8String == NULL, 0)) {
    RKStringBuffer cacheDescriptionStringBuffer = RKStringBufferWithString(self->cacheDescriptionString);
    if(RK_EXPECTED((self->cacheDescriptionUTF8String = RKMallocNotScanned(cacheDescriptionStringBuffer.length + 1)) == NULL, 0)) { return("Unable to malloc memory for UTF8 string."); }
    memcpy(self->cacheDescriptionUTF8String, cacheDescriptionStringBuffer.characters, cacheDescriptionStringBuffer.length + 1);
  }
  
  return((char *)self->cacheDescriptionUTF8String);
}

- (void)dealloc
{
  if(cacheRWLock)                { RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForWriting, NULL); RKRelease(cacheRWLock); cacheRWLock            = NULL; }
  if(cacheMapTable)              { if(RKRegexGarbageCollect == 0) { NSFreeMapTable(cacheMapTable); }                             cacheMapTable          = NULL; }
  if(cacheDescriptionString)     { RKRelease(cacheDescriptionString);                                                            cacheDescriptionString = NULL; }
  if(cacheDescriptionUTF8String) { RKFreeAndNULL(cacheDescriptionUTF8String);                                                                                   }

  [super dealloc];
}

#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
- (void)finalize
{
  if(cacheMapTable)              { if(RKRegexGarbageCollect == 0) { NSFreeMapTable(cacheMapTable); } cacheMapTable = NULL; }
  if(cacheDescriptionUTF8String) { RKFreeAndNULL(cacheDescriptionUTF8String);                                              }
  
  [super finalize];
}
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

- (RKUInteger)hash
{
  return((RKUInteger)self);
}

- (BOOL)isEqual:(id)anObject
{
  if(self == anObject) { return(YES); } else { return(NO); }
}

- (BOOL)clearCache
{
  RK_STRONG_REF NSMapTable * RK_C99(restrict) newMapTable = NULL, * RK_C99(restrict) oldMapTable = NULL;
  RKUInteger cacheHitsCopy = 0, cacheMissesCopy = 0, cacheClearedCountCopy = 0;
  BOOL didClearCache = NO;
  
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
  if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { if(RK_EXPECTED((newMapTable = [[objc_getClass("NSMapTable") alloc] initWithKeyPointerFunctions:RKCacheIntegerKeyPointerFunctions valuePointerFunctions:RKCacheObjectValuePointerFunctions capacity:256]) == NULL, 0)) { goto exitNow; } } else
#endif
  { if(RK_EXPECTED((newMapTable = NSCreateMapTable(*cacheMapKeyCallBacks, NSObjectMapValueCallBacks, 256)) == NULL, 0)) { goto exitNow; } }
  
  if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForWriting, NULL) == NO, 0)) { goto exitNow; } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  if(RK_EXPECTED((cacheMapTable != NULL), 1)) { oldMapTable = cacheMapTable; } 
  cacheMapTable = newMapTable;
  newMapTable = NULL;
  cacheClearedCount++;
  cacheClearedCountCopy = cacheClearedCount;
  cacheHitsCopy = cacheHits;
  cacheMissesCopy = cacheMisses;
  cacheHits = 0;
  cacheMisses = 0;
  didClearCache = YES;
  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(cacheRWLock);
  
exitNow:
  if(RK_EXPECTED(RKRegexGarbageCollect == 0, 1)) {
    if(RK_EXPECTED(newMapTable != NULL, 0)) { NSFreeMapTable(newMapTable); newMapTable = NULL; }
    if(RK_EXPECTED(oldMapTable != NULL, 1)) { NSFreeMapTable(oldMapTable); oldMapTable = NULL; }
  }

  RK_PROBE(CACHECLEARED, self, (char *)cacheUTF8String(self), didClearCache, cacheClearedCountCopy, cacheHitsCopy, cacheMissesCopy);
  
  return(didClearCache);
}

- (NSString *)status
{
  double cacheLookups = (((double)cacheHits) + (double)cacheMisses);
  if(cacheLookups == 0.0) { cacheLookups = 1.0; }
  NSString *GCStatusString = @"";
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
  GCStatusString = (RK_EXPECTED(RKRegexGarbageCollect == 0, 1)) ? RKLocalizedString(@", GC Active = No") : RKLocalizedString(@", GC Active = Yes");
#endif
  return(RKLocalizedFormat(@"Enabled = %@ (Add: %@, Lookup: %@), Cleared count = %lu, Cache count = %lu, Hit rate = %6.2lf%%, Hits = %lu, Misses = %lu, Total = %.0lf%@", RKYesOrNo(cacheIsEnabled), RKYesOrNo(cacheAddingIsEnabled), RKYesOrNo(cacheLookupIsEnabled), (long)[self cacheClearedCount], (long)[self cacheCount], (((double)cacheHits) / cacheLookups) * 100.0, (long)cacheHits, (long)cacheMisses, (((double)cacheHits) + (double)cacheMisses), GCStatusString));
}

- (NSString *)description
{
  return(RKLocalizedFormat(@"<%@: %p>%s%@%s %@", [self className], self, (cacheDescriptionString != NULL) ? " \"":"", (cacheDescriptionString != NULL) ? cacheDescriptionString : @"", (cacheDescriptionString != NULL) ? "\"":"", [self status]));
}

- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString
{
  return(RKFastCacheLookup(self, _cmd, objectHash, descriptionString, YES));
}

- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString autorelease:(const BOOL)shouldAutorelease
{
  return(RKFastCacheLookup(self, _cmd, objectHash, descriptionString, shouldAutorelease));
}

id RKFastCacheLookup(RKCache * const self, const SEL _cmd RK_ATTRIBUTES(unused), const RKUInteger objectHash, NSString * const objectString, const BOOL shouldAutorelease) {
  if(RK_EXPECTED(self == NULL, 0)) { return(NULL); }

  BOOL endCacheLookupProbeEnabled = RK_PROBE_ENABLED(ENDCACHELOOKUP);
  RK_STRONG_REF id returnObject = NULL;
  RKUInteger currentCount = 0;
#ifdef    ENABLE_DTRACE_INSTRUMENTATION
  char objectBuffer[1024];
#else
  NSString *compilerUnusedWarningSilencer = NULL; compilerUnusedWarningSilencer = objectString;
#endif // ENABLE_DTRACE_INSTRUMENTATION
  
  RK_PROBE(BEGINCACHELOOKUP, self, (char *)cacheUTF8String(self), objectHash, RKGetUTF8String(objectString, objectBuffer, 1020), shouldAutorelease, self->cacheIsEnabled, self->cacheHits, self->cacheMisses);
  
  if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(self->cacheRWLock, RKLockForReading, NULL) == NO, 0)) { goto exitNow; } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  
  if(RK_EXPECTED((self->cacheIsEnabled == YES), 1) && RK_EXPECTED((self->cacheLookupIsEnabled == YES), 1)) {
    if(RK_EXPECTED(self->cacheMapTable != NULL, 1)) {
      // If we get a hit, do a retain on the object so it will be within our current autorelease scope.  Once we unlock, the map table could vanish, taking
      // the returned object with it.  This way we ensure it stays around.  Convenience methods handle autoreleasing.
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
      if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { returnObject = [self->cacheMapTable objectForKey:(id)objectHash]; } else
#endif
      { if((returnObject = NSMapGet(self->cacheMapTable, (const void *)objectHash)) != NULL) { [returnObject retain]; } }
    }
  }

  if(RK_EXPECTED(endCacheLookupProbeEnabled, 0)) {
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
    if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { currentCount = [self->cacheMapTable count]; } else
#endif
    { currentCount = NSCountMapTable(self->cacheMapTable); }
  }


  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(self->cacheRWLock);
  
exitNow:
  if(returnObject != NULL) { self->cacheHits++; if(shouldAutorelease == YES) { RKAutorelease(returnObject); } } else { self->cacheMisses++; }

  RK_PROBE_CONDITIONAL(ENDCACHELOOKUP, endCacheLookupProbeEnabled, self, (char *)cacheUTF8String(self), objectHash, RKGetUTF8String(objectString, objectBuffer, 1020), shouldAutorelease, self->cacheIsEnabled, self->cacheHits, self->cacheMisses, currentCount, returnObject);
  
  return(returnObject);
}


- (BOOL)addObjectToCache:(id)object
{
  return([self addObjectToCache:object withHash:[object hash]]);
}

- (BOOL)addObjectToCache:(id)object withHash:(const RKUInteger)objectHash
{
  BOOL didCache = NO;
  if(RK_EXPECTED(object == NULL, 0)) { goto exitNow; }

  BOOL endCacheAddProbeEnabled = RK_PROBE_ENABLED(ENDCACHEADD); 
  RKUInteger currentCount = 0;
  
  RK_PROBE(BEGINCACHEADD, self, (char *)cacheUTF8String(self), object, objectHash, (char *)regexUTF8String(object), cacheIsEnabled);
  
  if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForWriting, NULL) == NO, 0)) { goto exitNow; } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  
  if(RK_EXPECTED((cacheAddingIsEnabled == YES), 1) && RK_EXPECTED((cacheIsEnabled == YES), 1)) {
    if(RK_EXPECTED(cacheMapTable != NULL, 1)) {
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
      if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { [cacheMapTable setObject:object forKey:(id)objectHash]; didCache = YES; } else
#endif
      { if(RK_EXPECTED(NSMapInsertIfAbsent(cacheMapTable, (const void *)objectHash, object) == NULL, 1)) { didCache = YES; } }
    }
  }
  
  if(RK_EXPECTED(endCacheAddProbeEnabled, 0)) {
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
    if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { currentCount = [cacheMapTable count]; } else
#endif
    { currentCount = NSCountMapTable(cacheMapTable); }
  }
   
  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(cacheRWLock);

  RK_PROBE_CONDITIONAL(ENDCACHEADD, endCacheAddProbeEnabled, self, (char *)cacheUTF8String(self), object, objectHash, (char *)regexUTF8String(object), cacheIsEnabled, didCache, currentCount);
  
exitNow:
  return(didCache);
}

- (id)removeObjectFromCache:(id)object
{
  return([self removeObjectWithHash:[object hash]]);
}

- (id)removeObjectWithHash:(const RKUInteger)objectHash
{
  BOOL endCacheRemoveProbeEnabled = RK_PROBE_ENABLED(ENDCACHEREMOVE);
  void **cachedKey = NULL, RK_STRONG_REF **cachedObject = NULL;
  RKUInteger currentCount = 0;
  
  RK_PROBE(BEGINCACHEREMOVE, self, (char *)cacheUTF8String(self), objectHash, cacheIsEnabled);
  
  if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForWriting, NULL) == NO, 0)) { goto exitNow; } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  
  if(RK_EXPECTED(cacheMapTable != NULL, 1)) {
  
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
    if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { if(RK_EXPECTED((cachedObject = (void **)[cacheMapTable objectForKey:(id)objectHash]) != NULL, 1)) { [cacheMapTable removeObjectForKey:(id)objectHash]; } } else
#endif
    { if(RK_EXPECTED(NSMapMember(cacheMapTable, (const void *)objectHash, (void **)&cachedKey, (void **)&cachedObject) == YES, 1)) { [(id)cachedObject retain]; NSMapRemove(cacheMapTable, (const void *)objectHash); }
   }
  }

  if(RK_EXPECTED(endCacheRemoveProbeEnabled, 0)) {
#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
    if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { currentCount = [cacheMapTable count]; } else
#endif
    { currentCount = NSCountMapTable(cacheMapTable); }
  }

  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(cacheRWLock);  
  
  RK_PROBE_CONDITIONAL(ENDCACHEREMOVE, endCacheRemoveProbeEnabled, self, (char *)cacheUTF8String(self), objectHash, cacheIsEnabled, cachedObject, (char *)regexUTF8String((id)cachedObject), currentCount);

  if(cachedObject != NULL) { RKAutorelease((id)cachedObject); }
  
exitNow:
  return((id)cachedObject);
}

- (NSSet *)cacheSet
{  

#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
  if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) {
    NSMutableSet *currentCacheSet = [NSMutableSet set];
    if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForReading, NULL) == NO, 0)) { return(NULL); } // Did not acquire lock for some reason
    id cachedObject = NULL;
    NSEnumerator *cacheMapTableEnumerator = [cacheMapTable objectEnumerator];
    while(RK_EXPECTED((cachedObject = [cacheMapTableEnumerator nextObject]) != NULL, 1)) { [currentCacheSet addObject:cachedObject]; }
    RKFastReadWriteUnlock(cacheRWLock);
    return([NSSet setWithSet:currentCacheSet]);
  }
#endif

  RKUInteger atCachedObject = 0, retrievedCount = 0, cacheCount = 0;
  NSMapEnumerator cacheMapTableEnumerator;
  BOOL retrievedObjects = NO;
  NSSet * RK_C99(restrict) returnSet = NULL;
  id    * RK_C99(restrict) objects   = NULL;
  void  *                  tempKey   = NULL;
  
  if(RK_EXPECTED(cacheMapTable == NULL,                                                                 0)) { return(NULL); } // Fast exit case.  Does not not an atomic compare on NULL.
  if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForReading, NULL) == NO,            0)) { return(NULL); } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  
  // On an error condition we goto unlockExitNow. Any resource acquisition inside here needs to ensure that the resources in question will remain valid once the lock is released.
  
  if(RK_EXPECTED(cacheMapTable == NULL,                                 0)) { goto unlockExitNow; } // Reverify under lock as this could have changed.
  if(RK_EXPECTED((cacheCount = NSCountMapTable(cacheMapTable)) == 0,    0)) { goto unlockExitNow; }
  if(RK_EXPECTED((objects = alloca(cacheCount * sizeof(id *))) == NULL, 0)) { goto unlockExitNow; }
  
  cacheMapTableEnumerator = NSEnumerateMapTable(cacheMapTable);
  while((NSNextMapEnumeratorPair(&cacheMapTableEnumerator, &tempKey, (void **)&objects[atCachedObject])) == YES) { RKRetain(objects[atCachedObject]); atCachedObject++; }
  NSEndMapTableEnumeration(&cacheMapTableEnumerator);
  
  retrievedCount = atCachedObject;
  retrievedObjects = YES;
  
unlockExitNow:
  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(cacheRWLock);
  
  if((retrievedObjects == YES) && (retrievedCount > 0)) {
    returnSet = [NSSet setWithObjects:&objects[0] count:retrievedCount];
    for(atCachedObject = 0; atCachedObject < retrievedCount; atCachedObject++) { RKRelease(objects[atCachedObject]); }
  }
  
  return(returnSet);
}

- (BOOL)isCacheEnabled
{
  return(cacheIsEnabled);
}

- (BOOL)setCacheEnabled:(const BOOL)enableCache
{
  RKAtomicMemoryBarrier(); // Extra cautious
  int enabledState = cacheIsEnabled;
  int returnEnabledState = RKAtomicCompareAndSwapInt(enabledState, enableCache, &cacheIsEnabled);
  return((returnEnabledState == 0) ? NO : YES);
}

- (RKUInteger)cacheCount
{
  RKUInteger returnCount = 0;
  
  if(cacheMapTable == NULL) { return(0); }
  if(RKFastReadWriteLockWithStrategy(cacheRWLock, RKLockForReading, NULL) == NO) { return(0); } // Did not acquire lock for some reason
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv

#ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
  if(RK_EXPECTED(RKRegexGarbageCollect == 1, 0)) { returnCount = [cacheMapTable count]; } else
#endif
  { returnCount = NSCountMapTable(cacheMapTable); }

  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  RKFastReadWriteUnlock(cacheRWLock);
  
  return(returnCount);
}

@end


@implementation RKCache (CacheDebugging)

- (BOOL)isCacheAddingEnabled
{
  return(cacheAddingIsEnabled);
}

- (BOOL)setCacheAddingEnabled:(const BOOL)enableCacheAdding
{
  RKAtomicMemoryBarrier(); // Extra cautious
  int lookupEnabledState = cacheAddingIsEnabled;
  int returnEnabledState = RKAtomicCompareAndSwapInt(lookupEnabledState, enableCacheAdding, &cacheAddingIsEnabled);
  return((returnEnabledState == 0) ? NO : YES);
}

- (BOOL)isCacheLookupEnabled
{
  return(cacheLookupIsEnabled);
}

- (BOOL)setCacheLookupEnabled:(const BOOL)enableCacheLookup
{
  RKAtomicMemoryBarrier(); // Extra cautious
  int lookupEnabledState = cacheLookupIsEnabled;
  int returnEnabledState = RKAtomicCompareAndSwapInt(lookupEnabledState, enableCacheLookup, &cacheLookupIsEnabled);
  return((returnEnabledState == 0) ? NO : YES);
}

@end

@implementation RKCache (CountersDebugging)

- (void) setDebug:(const BOOL)enableDebugging { [cacheRWLock setDebug:enableDebugging]; }
- (void) clearCounters                        { cacheClearedCount = 0; [cacheRWLock clearCounters]; }
- (RKUInteger) cacheClearedCount              { return(cacheClearedCount);              }
- (RKUInteger) readBusyCount                  { return([cacheRWLock readBusyCount]);    }
- (RKUInteger) readSpinCount                  { return([cacheRWLock readSpinCount]);    }
- (RKUInteger) writeBusyCount                 { return([cacheRWLock writeBusyCount]);   }
- (RKUInteger) writeSpinCount                 { return([cacheRWLock writeSpinCount]);   }

@end
