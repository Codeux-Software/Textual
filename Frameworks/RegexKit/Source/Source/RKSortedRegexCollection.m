//
//  RKSortedRegexCollection.m
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

#import <RegexKit/RKLock.h>
#import <RegexKit/RegexKitPrivate.h>
#import <RegexKit/RKSortedRegexCollection.h>
#import <RegexKit/RKThreadPool.h>
#import <stdlib.h>

#define RKSortedRegexCollectionDefaultRegexLibrary        RKRegexPCRELibrary
#define RKSortedRegexCollectionDefaultRegexLibraryOptions (RKCompileUTF8 | RKCompileNoUTF8Check)
#define RKSortedRegexCollectionHashForCollection(collection, regexLibrary, libraryOptions) ((RKUInteger)([collection hash] ^ (RKUInteger)collection ^ (RKUInteger)[regexLibrary hash] ^ libraryOptions))

static int sortRegexCollectionItems(const void *a, const void *b) RK_ATTRIBUTES(used, nonnull);
static int threadMatchEntryFunction(void *startState) RK_ATTRIBUTES(used, nonnull);

static RKCache *RKSortedRegexCollectionCache = NULL;

NSString *RKStringFromCollectionType(RKCollectionType collectionType) {
  NSString *collectionTypeString = NULL;
  switch(collectionType) {
    case RKArrayCollection:      collectionTypeString = @"Array";      break;
    case RKSetCollection:        collectionTypeString = @"Set";        break;
    case RKDictionaryCollection: collectionTypeString = @"Dictionary"; break;
    case RKUnknownCollection: // Fall through
    default:                     collectionTypeString = @"Unknown";    break;
  }
  return(collectionTypeString);
}

//static RKThreadPool *threadPool = NULL;

@implementation RKSortedRegexCollection


+ (void)initialize
{
  RKAtomicMemoryBarrier(); // Extra cautious
  
  if(RKSortedRegexCollectionCache == NULL) {
    RKCache *tmpCache = RKAutorelease([[RKCache alloc] initWithDescription:RKLocalizedString(@"Sorted Regex Collection Matching Accelerator Cache")]);
    if(RKAtomicCompareAndSwapPtr(NULL, tmpCache, &RKSortedRegexCollectionCache)) { RKRetain(RKSortedRegexCollectionCache); RKDisableCollectorForPointer(RKSortedRegexCollectionCache); }
  }
}

+ (RKCache *)sortedRegexCollectionCache
{
  return(RKAutorelease(RKRetain(RKSortedRegexCollectionCache)));
}

+ (NSArray *)sortedArrayForSortedRegexCollection:(RKSortedRegexCollection *)sortedRegexCollection
{  
  NSArray *returnObject = NULL;
  id *regexObjects = NULL;

  if(RK_EXPECTED(sortedRegexCollection == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"sortedRegexCollection == NULL."] raise]; goto errorExit; }

  if(RK_EXPECTED((regexObjects = alloca(sizeof(id *) * sortedRegexCollection->collectionCount)) == NULL, 0)) { [[NSException rkException:NSMallocException for:sortedRegexCollection selector:_cmd localizeReason:@"Unable to allocate temporary stack space."] raise]; goto errorExit; }
  
  RKFastReadWriteLockWithStrategy(sortedRegexCollection->readWriteLock, RKLockForReading, NULL);
  for(RKUInteger atIndex = 0; atIndex < sortedRegexCollection->collectionCount; atIndex++) {
    regexObjects[atIndex] = [NSDictionary dictionaryWithObjectsAndKeys:sortedRegexCollection->sortedElements[atIndex]->regex, @"element", [NSNumber numberWithUnsignedLong:(unsigned long)sortedRegexCollection->sortedElements[atIndex]->hitCount], @"count", NULL];
  }
  RKFastReadWriteUnlock(sortedRegexCollection->readWriteLock);
  
  returnObject = RKAutorelease([[NSArray alloc] initWithObjects:&regexObjects[0] count:sortedRegexCollection->collectionCount]);
  
errorExit:
  return(returnObject);
}


+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))collection
{
  return([self sortedRegexCollectionForCollection:collection library:RKSortedRegexCollectionDefaultRegexLibrary options:RKSortedRegexCollectionDefaultRegexLibraryOptions error:NULL]);
}

+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))initCollection library:(NSString * const RK_C99(restrict))initRegexLibraryString options:(const RKCompileOption)initRegexLibraryOptions error:(NSError ** const RK_C99(restrict))error
{
  if(RK_EXPECTED(initCollection        == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"initCollection == NULL."]        raise]; return(NULL); }
  if(RK_EXPECTED(initRegexLibraryString == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"initRegexLibraryString == NULL."] raise]; return(NULL); }

  RKSortedRegexCollection *sortedRegexCollection = NULL;
  
  if(RK_EXPECTED((sortedRegexCollection = RKFastCacheLookup(RKSortedRegexCollectionCache, _cmd, RKSortedRegexCollectionHashForCollection(initCollection, initRegexLibraryString, initRegexLibraryOptions), @"bulk matcher", YES)) == NULL, 0)) {
    sortedRegexCollection = [[[self alloc] initWithCollection:initCollection library:initRegexLibraryString options:initRegexLibraryOptions error:error] autorelease];
  }
  
  return(sortedRegexCollection);
}


- (id)initWithCollection:(id const RK_C99(restrict))initCollection
{
  return([self initWithCollection:initCollection library:RKSortedRegexCollectionDefaultRegexLibrary options:RKSortedRegexCollectionDefaultRegexLibraryOptions error:NULL]);
}

- (id)initWithCollection:(id const RK_C99(restrict))initCollection library:(NSString * const RK_C99(restrict))initRegexLibraryString options:(const RKCompileOption)initRegexLibraryOptions error:(NSError ** const RK_C99(restrict))error
{
  if(error != NULL) { *error = NULL; }
  NSError *initError = NULL;

  if((self = [self init]) == NULL) { goto errorExit; }
  RKAutorelease(self);

  id *regexObjects = NULL;
  RKUInteger atIndex = 0;
  
  if(RK_EXPECTED(initCollection        == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"initCollection == NULL."]        raise]; goto errorExit; }
  if(RK_EXPECTED(initRegexLibraryString == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"initRegexLibraryString == NULL."] raise]; goto errorExit; }

  sortedRegexCollectionHash = RKSortedRegexCollectionHashForCollection(initCollection, initRegexLibraryString, initRegexLibraryOptions);
  RKSortedRegexCollection *cachedSortedRegexCollection = NULL;
  
  if(RK_EXPECTED((cachedSortedRegexCollection = RKFastCacheLookup(RKSortedRegexCollectionCache, _cmd, sortedRegexCollectionHash, @"bulk matcher", NO)) != NULL, 1)) { return(cachedSortedRegexCollection); }

  if(     [initCollection isKindOfClass:[NSArray class]]) { collectionType = RKArrayCollection; }
  else if([initCollection isKindOfClass:[NSSet class]])   { collectionType = RKSetCollection;   }
  else { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"Supported collection types are NSArray and NSSet.  initCollection class = '%@'.", [initCollection className]] raise]; goto errorExit; }
  
  if((readWriteLock = [[RKReadWriteLock alloc] init]) == NULL) { initError = [NSError rkErrorWithDomain:NSCocoaErrorDomain code:-1 localizeDescription:@"Unable to instantiate multithreading lock."]; goto errorExit; }

  if(RK_EXPECTED((missedObjectHashCache = RKCallocNotScanned(sizeof(RKUInteger) * RK_SORTED_REGEX_COLLECTION_CACHE_BUCKETS)) == NULL, 0)) { [[NSException rkException:NSMallocException for:self selector:_cmd localizeReason:@"Unable to allocate memory for missedObjectHashCache."] raise]; goto errorExit; }

  regexLibraryString         = RKRetain(initRegexLibraryString);
  regexLibraryCompileOptions = initRegexLibraryOptions;
  collection                 = RKRetain(initCollection);
  collectionHash             = [collection hash];
  
#ifdef USE_CORE_FOUNDATION
  if(collectionType == RKArrayCollection) { if((collectionCount = (RKUInteger)CFArrayGetCount((CFArrayRef)collection)) == 0) { goto errorExit; } }
  else { if((collectionCount = (RKUInteger)CFSetGetCount((CFSetRef)collection)) == 0) { goto errorExit; } }
#else
  if((collectionCount = [collection count]) == 0) { goto errorExit; }
#endif
    
  if(RK_EXPECTED((regexObjects = alloca(sizeof(id *) * collectionCount)) == NULL, 0)) { [[NSException rkException:NSMallocException for:self selector:_cmd localizeReason:@"Unable to allocate temporary stack space."] raise]; goto errorExit; }

  if(RK_EXPECTED((elements       = RKCallocScanned(sizeof(RKCollectionElement)   * collectionCount)) == NULL, 0)) { [[NSException rkException:NSMallocException for:self selector:_cmd localizeReason:@"Unable to allocate memory for elements."] raise]; goto errorExit; }
  if(RK_EXPECTED((sortedElements = RKCallocScanned(sizeof(RKCollectionElement *) * collectionCount)) == NULL, 0)) { [[NSException rkException:NSMallocException for:self selector:_cmd localizeReason:@"Unable to allocate memory for sortedElements."] raise]; goto errorExit; }
  
#ifdef USE_CORE_FOUNDATION
  if(collectionType == RKArrayCollection) { CFArrayGetValues((CFArrayRef)collection, (CFRange){0, (CFIndex)collectionCount}, (const void **)(&regexObjects[0])); }
  else { CFSetGetValues((CFSetRef)collection, (const void **)(&regexObjects[0])); }
#else
  if(collectionType == RKArrayCollection) { [collection getObjects:&arrayObjects[0] range:NSMakeRange(0, collectionCount)]; }
  else { [[collection allObjects] getObjects:&regexObjects[0]]; }
#endif

  for(atIndex = 0; atIndex < collectionCount; atIndex++) {
    id savedRegexObject = regexObjects[atIndex];
    regexObjects[atIndex] = RKRegexFromStringOrRegexWithError(self, _cmd, regexObjects[atIndex], regexLibraryString, regexLibraryCompileOptions, &initError, YES);

    if(initError != NULL) {
      if(error != NULL) {
        NSString *arrayErrorKey = NULL, *regexLibrary = [[initError userInfo] objectForKey:RKRegexLibraryErrorKey];
        NSNumber *arrayIndexNumber = NULL;
        if(collectionType == RKArrayCollection) { arrayIndexNumber = [NSNumber numberWithUnsignedLong:(unsigned long)atIndex]; arrayErrorKey = RKArrayIndexErrorKey; }
        NSDictionary *infoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [initError localizedDescription],   NSLocalizedDescriptionKey,
                                        [initError localizedFailureReason], NSLocalizedFailureReasonErrorKey,
                                        regexLibrary,                       RKRegexLibraryErrorKey,
                                        initError,                          NSUnderlyingErrorKey,
                                        collection,                         RKCollectionErrorKey,
                                        savedRegexObject,                   RKObjectErrorKey,
                                        arrayIndexNumber,                   arrayErrorKey,
                                        NULL];
        initError = [NSError errorWithDomain:RKRegexErrorDomain code:[initError code] userInfo:infoDictionary];
      }
      goto errorExit;
    }
    elements[atIndex].regex = regexObjects[atIndex];
    sortedElements[atIndex] = &elements[atIndex];
  }
  
  // The following simplifies memory management.  The array retains all the RKRegex objects, and on dealloc we only need to release the array.
  collectionRegexArray = [[NSArray alloc] initWithObjects:(id *)&regexObjects[0] count:collectionCount];

  [RKSortedRegexCollectionCache addObjectToCache:self withHash:sortedRegexCollectionHash];

  return(RKRetain(self));
  
errorExit:
  if(RK_EXPECTED(initError != NULL, 0) && (error != NULL)) { *error = initError; }
  return(NULL);
}

- (void)dealloc
{
  if(readWriteLock         != NULL) { RKRelease(readWriteLock);        readWriteLock        = NULL; }
  if(regexLibraryString    != NULL) { RKRelease(regexLibraryString);   regexLibraryString   = NULL; }
  if(collection            != NULL) { RKRelease(collection);           collection           = NULL; }
  if(collectionRegexArray  != NULL) { RKRelease(collectionRegexArray); collectionRegexArray = NULL; }
  
  if(elements              != NULL) { RKFreeAndNULL(elements);                                      }
  if(sortedElements        != NULL) { RKFreeAndNULL(sortedElements);                                }
  if(missedObjectHashCache != NULL) { RKFreeAndNULL(missedObjectHashCache);                         }
  
  [super dealloc];
}

- (RKUInteger)hash
{
  return(sortedRegexCollectionHash);
}

- (BOOL)isEqual:(id)anObject
{
  BOOL equal = NO;
  RKSortedRegexCollection *sortedRegexCollectionObject = anObject;
  if(self == anObject)                                                                           { equal = YES; goto exitNow; }
  if([anObject isKindOfClass:[RKSortedRegexCollection class]] == NO)                             { equal = NO;  goto exitNow; }
  if(sortedRegexCollectionHash != sortedRegexCollectionObject->sortedRegexCollectionHash)        { equal = NO;  goto exitNow; }
  if(regexLibraryCompileOptions != sortedRegexCollectionObject->regexLibraryCompileOptions)      { equal = NO;  goto exitNow; }
  if([regexLibraryString isEqualToString:sortedRegexCollectionObject->regexLibraryString] == NO) { equal = NO;  goto exitNow; }
  if([collection isEqual:sortedRegexCollectionObject->collection])                               { equal = YES; goto exitNow; }
  // Fall through with equal = NO initialization
  
exitNow:
  return(equal);
}

- (NSString *)description
{
  return(RKLocalizedFormat(@"<%@: %p> Sorted Regex Collection type = %@, count = %lu, Regex library = %@, Compiled options = 0x%8.8x (%@)", [self className], self, RKLocalizedString(RKStringFromCollectionType(collectionType)), (unsigned long)collectionCount, regexLibraryString, (unsigned int)regexLibraryCompileOptions, [RKArrayFromCompileOption(regexLibraryCompileOptions) componentsJoinedByString:@" | "]));
}

- (id)collection
{
  return(collection);
}


- (RKRegex *)regexMatching:(id const RK_C99(restrict))matchObject lowestIndexInCollection:(const BOOL)lowestIndex
{
  RKReadWriteLockStrategy tryForLockLevel = 0, acquiredLockLevel = 0;
  
  if(resortRequired == NO) {
    tryForLockLevel = RKLockForReading;
    if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(readWriteLock, tryForLockLevel, &acquiredLockLevel) == NO, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unable to acquire lock."] raise]; }
  } else {
    RK_PROBE(BEGINSORTEDREGEXSORT, self, sortedRegexCollectionHash, collectionCount);
    tryForLockLevel = RKLockTryForWritingThenForReading;
    if(RK_EXPECTED(RKFastReadWriteLockWithStrategy(readWriteLock, tryForLockLevel, &acquiredLockLevel) == NO, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unable to acquire lock."] raise]; }
    if(acquiredLockLevel == RKLockForWriting) {
      mergesort(sortedElements, collectionCount, sizeof(RKCollectionElement *), sortRegexCollectionItems);
      resortRequired = 0;
      RK_PROBE(ENDSORTEDREGEXSORT, self, sortedRegexCollectionHash, collectionCount, 1);
    } else {
      RK_PROBE(ENDSORTEDREGEXSORT, self, sortedRegexCollectionHash, collectionCount, 0);
    }
  }

#ifdef    ENABLE_DTRACE_INSTRUMENTATION
  char matchObjectCString[64];
#endif // ENABLE_DTRACE_INSTRUMENTATION

  RK_PROBE(BEGINSORTEDREGEXMATCH, self, sortedRegexCollectionHash, collectionCount, RKGetUTF8String([matchObject description], matchObjectCString, 60));

  RKUInteger matchObjectHash        = [matchObject hash];
  RKUInteger matchObjectCacheHash   = (matchObjectHash % RK_SORTED_REGEX_COLLECTION_CACHE_BUCKETS);
  BOOL sortedRegexCacheProbeEnabled = RK_PROBE_ENABLED(SORTEDREGEXCACHE);

  if(missedObjectHashCache[matchObjectCacheHash] == matchObjectHash) {
    RKFastReadWriteUnlock(readWriteLock);
    RK_PROBE(ENDSORTEDREGEXMATCH, self, sortedRegexCollectionHash, NULL, 0, "", 0, collectionCount, 0, 0, 0x02);

    if(sortedRegexCacheProbeEnabled != 0) { RKAtomicIncrementIntegerBarrier(&cacheHits); } else { cacheHits++; }
#ifdef    ENABLE_DTRACE_INSTRUMENTATION
    if(RK_EXPECTED(sortedRegexCacheProbeEnabled != 0, 0)) {
      
      double hitsPercent   = (((double)cacheHits   / ((double)(cacheHits + cacheMisses))) * 100.0);
      double missesPercent = (((double)cacheMisses / ((double)(cacheHits + cacheMisses))) * 100.0);
      RK_PROBE_CONDITIONAL(SORTEDREGEXCACHE, sortedRegexCacheProbeEnabled, self, sortedRegexCollectionHash, collectionCount, cacheHits, cacheMisses, &hitsPercent, &missesPercent);
    }
#endif // ENABLE_DTRACE_INSTRUMENTATION

    return(NULL);
  }

  if(sortedRegexCacheProbeEnabled != 0) { RKAtomicDecrementIntegerBarrier(&cacheMisses); } else { cacheMisses++; }

  RK_STRONG_REF RKSortedRegexCollectionThreadMatchState threadMatchState;
  memset(&threadMatchState, 0, sizeof(RKSortedRegexCollectionThreadMatchState));
  
  threadMatchState.highestMatchingArrayIndex = RKUIntegerMax;
  threadMatchState.findLowestIndex           = lowestIndex;
  threadMatchState.self                      = self;
  
  if([matchObject isMemberOfClass:[NSString class]]) { threadMatchState.matchStringBuffer = RKStringBufferWithString(matchObject); }
  else {                                               threadMatchState.matchStringBuffer = RKStringBufferWithString([matchObject description]); }
  
  if([[RKThreadPool defaultThreadPool] threadFunction:threadMatchEntryFunction argument:&threadMatchState] == NO) {
#ifndef   NS_BLOCK_ASSERTIONS
    static BOOL didPrint = NO;
    if(didPrint == NO) { NSLog(@"threadFunction returned NO? Executing in-line within the current thread."); didPrint = YES; }
#endif // NS_BLOCK_ASSERTIONS
    threadMatchEntryFunction(&threadMatchState);
  }
  
  BOOL matchHit = (threadMatchState.matchedRegex == NULL) ? NO : YES;

  if(matchHit == YES) {
    RKAtomicIncrementInteger(&sortedElements[threadMatchState.matchingSortedIndex]->hitCount);
    if((threadMatchState.matchingSortedIndex > 0) && (sortedElements[threadMatchState.matchingSortedIndex]->hitCount > sortedElements[threadMatchState.matchingSortedIndex - 1]->hitCount)) { resortRequired = 1; }
  }
  
  RKFastReadWriteUnlock(readWriteLock);
  
  RK_PROBE(ENDSORTEDREGEXMATCH, self, sortedRegexCollectionHash, (matchHit == YES) ? threadMatchState.matchedRegex : NULL, (matchHit == YES) ? [threadMatchState.matchedRegex hash] : 0, (matchHit == YES) ? (char *)regexUTF8String(threadMatchState.matchedRegex) : "", (matchHit == YES) ? threadMatchState.matchingSortedIndex : 0, collectionCount, (matchHit == YES) ? sortedElements[threadMatchState.matchingSortedIndex]->hitCount : 0, (matchHit == YES) ? threadMatchState.matchingCollectionIndex : 0, (((resortRequired == NO) ? 0x00 : 0x01) | (((matchHit == YES) && (lowestIndex == YES)) ? 0x04 : 0x00)));

  if(matchHit == NO) { missedObjectHashCache[matchObjectCacheHash] = matchObjectHash; }

  return(threadMatchState.matchedRegex);
}

static int threadMatchEntryFunction(void *startState) {
  RK_STRONG_REF RKSortedRegexCollectionThreadMatchState *threadMatchState = (RK_STRONG_REF RKSortedRegexCollectionThreadMatchState *)startState;
  RK_STRONG_REF RKSortedRegexCollection                 *self             = threadMatchState->self;
  
  if((threadMatchState->finished == NO) && (threadMatchState->matchedRegex == NULL) && (threadMatchState->atSortedIndex < self->collectionCount)) {
    for(RKUInteger threadAtSortedIndex = (RKAtomicIncrementIntegerBarrier(&threadMatchState->atSortedIndex) - 1);
    
        (RK_EXPECTED(threadMatchState->finished                  != YES,                   1) &&
         RK_EXPECTED(threadMatchState->matchedRegex              == NULL,                  1) &&
         RK_EXPECTED(threadAtSortedIndex                         <  self->collectionCount, 1) &&
         RK_EXPECTED(threadMatchState->highestMatchingArrayIndex >  0,                     1));
         
        threadAtSortedIndex = (RKAtomicIncrementIntegerBarrier(&threadMatchState->atSortedIndex) - 1)) {
      
      RKUInteger threadMatchingCollectionIndex = (((RKCollectionElement *)(self->sortedElements[threadAtSortedIndex]) - self->elements));
      RKRegex   *threadAtRegex                 = self->sortedElements[threadAtSortedIndex]->regex;
      
      if(threadMatchingCollectionIndex > threadMatchState->highestMatchingArrayIndex) {
        RK_PROBE(SORTEDREGEXCOMPARE, self, self->sortedRegexCollectionHash, threadAtRegex, [threadAtRegex hash], (char *)regexUTF8String(threadAtRegex), threadAtSortedIndex, self->collectionCount, self->sortedElements[threadAtSortedIndex]->hitCount, threadMatchingCollectionIndex, 2);
        continue;
      }

      if([self->sortedElements[threadAtSortedIndex]->regex matchesCharacters:threadMatchState->matchStringBuffer.characters length:threadMatchState->matchStringBuffer.length inRange:NSMakeRange(0, threadMatchState->matchStringBuffer.length) options:RKMatchNoUTF8Check] == YES) {
        BOOL shouldBreak = NO;
        if((threadMatchState->findLowestIndex == NO) || (self->collectionType == RKSetCollection) || ((self->collectionType == RKArrayCollection) && (threadMatchingCollectionIndex == 0))) {
          if(RKAtomicCompareAndSwapPtr(NULL, threadAtRegex, &threadMatchState->matchedRegex)) {
            threadMatchState->matchingSortedIndex     = threadAtSortedIndex;
            threadMatchState->matchingCollectionIndex = threadMatchingCollectionIndex;
            threadMatchState->finished                = YES;
          }
          shouldBreak = YES;
        } else {
          while((threadMatchState->highestMatchingArrayIndex > threadMatchingCollectionIndex) && (RKAtomicCompareAndSwapInteger(threadMatchState->highestMatchingArrayIndex, threadMatchingCollectionIndex, &threadMatchState->highestMatchingArrayIndex) == NO)) { /* do nothing, loop */ }
        }
        
        RK_PROBE(SORTEDREGEXCOMPARE, self, self->sortedRegexCollectionHash, threadAtRegex, [threadAtRegex hash], (char *)regexUTF8String(threadAtRegex), threadAtSortedIndex, self->collectionCount, self->sortedElements[threadAtSortedIndex]->hitCount, threadMatchingCollectionIndex, (shouldBreak == YES) ? 1 : 3);
        if(shouldBreak == YES) { break; } else { continue; }
      }
      RK_PROBE(SORTEDREGEXCOMPARE, self, self->sortedRegexCollectionHash, threadAtRegex, [threadAtRegex hash], (char *)regexUTF8String(threadAtRegex), threadAtSortedIndex, self->collectionCount, self->sortedElements[threadAtSortedIndex]->hitCount, threadMatchingCollectionIndex, 0);
      if(threadMatchState->atSortedIndex >= self->collectionCount) { RKAtomicCompareAndSwapInteger(0, 1, &threadMatchState->finished); break; }
    }
  }
  
  if(((threadMatchState->matchedRegex != NULL) || (threadMatchState->atSortedIndex >= self->collectionCount)) && (threadMatchState->finished == NO)) { RKAtomicCompareAndSwapInteger(0, 1, &threadMatchState->finished); }

  return(1);
}


- (BOOL)isMatchedByAnyRegex:(id const RK_C99(restrict))matchObject
{
  return(([self regexMatching:matchObject lowestIndexInCollection:NO] == NULL) ? NO : YES);
}

- (RKRegex *)anyRegexMatching:(id const RK_C99(restrict))matchObject
{
  return(RKAutorelease(RKRetain([self regexMatching:matchObject lowestIndexInCollection:NO])));
}

- (RKRegex *)firstRegexMatching:(id const RK_C99(restrict))matchObject
{
  return(RKAutorelease(RKRetain([self regexMatching:matchObject lowestIndexInCollection:YES])));
}


static int sortRegexCollectionItems(const void *a, const void *b) {
  RK_STRONG_REF RKCollectionElement *itemA = *((RK_STRONG_REF RKCollectionElement **)a), RK_STRONG_REF *itemB = *((RK_STRONG_REF RKCollectionElement **)b);
  
  if(itemA->hitCount > itemB->hitCount) { return(-1); } else if(itemA->hitCount < itemB->hitCount) { return(1); } else { return(0); }
}

@end
