//
//  RKSortedRegexCollection.h
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
  
#ifndef _REGEXKIT_RKSORTEDREGEXLIST_H_
#define _REGEXKIT_RKSORTEDREGEXLIST_H_ 1

/*!
 @header RKSortedRegexCollection
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <pthread.h>

#define RK_SORTED_REGEX_COLLECTION_CACHE_BUCKETS 251

struct collectionElement {
  RKRegex    *regex;
  RKUInteger  hitCount;
};

typedef struct collectionElement RK_STRONG_REF RKCollectionElement;

enum {
  RKUnknownCollection    = 0,
  RKArrayCollection      = 1,
  RKSetCollection        = 2,
  RKDictionaryCollection = 3
};

typedef RKUInteger RKCollectionType;

NSString *RKStringFromCollectionType(RKCollectionType collectionType);

@class RKSortedRegexCollection;

struct _sortedRegexCollectionThreadMatchState {
  RKSortedRegexCollection *self;
    
  BOOL                     findLowestIndex;
  RKUInteger               atSortedIndex;
  RKUInteger               highestMatchingArrayIndex;
  RKUInteger               finished;

  RKStringBuffer           matchStringBuffer;
  RKRegex                 *matchedRegex;
  RKUInteger               matchingSortedIndex;
  RKUInteger               matchingCollectionIndex;
};

typedef struct _sortedRegexCollectionThreadMatchState RK_STRONG_REF RKSortedRegexCollectionThreadMatchState;

@interface RKSortedRegexCollection : NSObject {
  RKReadWriteLock                    *readWriteLock;
  NSString                           *regexLibraryString;
  RKCompileOption                     regexLibraryCompileOptions;
  RKUInteger                          sortedRegexCollectionHash;
  id                                  collection;
  NSArray                            *collectionRegexArray;
  RKCollectionType                    collectionType;
  RKUInteger                          collectionHash;
  RKUInteger                          collectionCount;
  RKUInteger                          resortRequired;
  RKCollectionElement RK_STRONG_REF  *elements;
  RKCollectionElement RK_STRONG_REF **sortedElements;
  RKUInteger                          elementsCount;

  RKUInteger RK_STRONG_REF           *missedObjectHashCache;
  
  RKUInteger cacheHits, cacheMisses;
}

+ (RKCache *)sortedRegexCollectionCache;

+ (NSArray *)sortedArrayForSortedRegexCollection:(RKSortedRegexCollection *)sortedRegexCollection;

+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))collection;
+ (RKSortedRegexCollection *)sortedRegexCollectionForCollection:(id const RK_C99(restrict))collection library:(NSString * const RK_C99(restrict))initRegexLibraryString options:(const RKCompileOption)initRegexLibraryOptions error:(NSError ** const RK_C99(restrict))error;

- (id)initWithCollection:(id const RK_C99(restrict))initCollection;
- (id)initWithCollection:(id const RK_C99(restrict))initCollection library:(NSString * const RK_C99(restrict))initRegexLibraryString options:(const RKCompileOption)initRegexLibraryOptions error:(NSError ** const RK_C99(restrict))error;

- (id)collection;

- (RKRegex *)regexMatching:(id const RK_C99(restrict))matchObject lowestIndexInCollection:(const BOOL)lowestIndex;

- (BOOL)isMatchedByAnyRegex:(id const RK_C99(restrict))matchObject;
- (RKRegex *)anyRegexMatching:(id const RK_C99(restrict))matchObject;
- (RKRegex *)firstRegexMatching:(id const RK_C99(restrict))matchObject;

@end

#endif // _REGEXKIT_RKSORTEDREGEXLIST_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
