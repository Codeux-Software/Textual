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

/*!
 @header RKCache
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>
#import <dlfcn.h>

@class RKReadWriteLock;

/*!
 @class    RKCache
 @toc      RKCache
 @abstract Cache maintainer for RegexKit
*/

/*!
 @toc RKCache
 @group Creating Caches
 @group Adding, Retrieving, and Removing Objects from the Cache
 @group Cache Information
 @group Cache Maintenance
*/

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


/*!
 @method     initWithDescription:
 @tocgroup   RKCache Creating Caches
 @abstract   Initializes a new @link RKCache RKCache @/link with the caller supplied description of the cache.
 @seealso    @link RKCache/description - description @/link
 @seealso    @link RKCache/setDescription: - setDescription: @/link
*/
- (id)initWithDescription:(NSString * const)descriptionString;

/*!
 @method     setDescription:
 @tocgroup   RKCache Cache Information
 @abstract   Sets the description of the cache to <span class="argument">descriptionString</span>
 @seealso    @link RKCache/description - description @/link
 @seealso    @link RKCache/initWithDescription: - initWithDescription: @/link
*/
- (void)setDescription:(NSString * const)descriptionString;

/*!
 @method     status
 @tocgroup   RKCache Cache Information
 @abstract   A string containing the cache status, including some statistics.
 @discussion <p>Includes information about the cache, such as the number of objects currently cached and cache effectiveness.</p>
 <p>Example:</p>
 <div class="box sourcecode">NSString *cacheStatus = [[RKRegex cache] status];

// Example cacheStatus:
// @"Enabled = Yes, Cleared count = 0, Cache count = 27, Hit rate = 96.27%, Hits = 697, Misses = 27, Total = 724";</div>
 @seealso    @link RKCache/description - description @/link
*/
- (NSString *)status;

/*!
 @method     description
 @tocgroup   RKCache Cache Information
 @abstract   The receivers description together with the information from @link status status@/link.
 @discussion
 <p>Example:</p>
 <div class="box sourcecode">NSString *cacheDescription = [cacheObject description];

// Example cacheDescription:
// &lt;RKCache: 0x512750&gt; "RKRegex Cache" Enabled = Yes, Cleared count = 0, Cache count = 27, Hit rate = 96.27%, Hits = 697, Misses = 27, Total = 724</div>

<p>Example usage with <span class="code">%@</span> format specifier:</p>
<div class="box sourcecode">NSLog(@"cache info:\n%@\n", [RKRegex regexCache]);

// NSLog output:
// 2007-08-06 14:07:05.738 cli_test[19615] cache info: 
// &lt;RKCache: 0x512750&gt; "RKRegex Cache" Enabled = Yes, Cleared count = 0, Cache count = 27, Hit rate = 96.27%, Hits = 697, Misses = 27, Total = 724</div>
 @seealso    @link RKCache/initWithDescription: - initWithDescription: @/link
 @seealso    @link RKCache/setDescription: - setDescription: @/link
 @seealso    @link RKCache/status - status @/link
*/
- (NSString *)description;

/*!
 @method     objectForHash:description:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Return the cached object for the supplied hash, if it exists.
 @discussion <p>Invokes @link objectForHash:description:autorelease: objectForHash:description:autorelease: @/link with <span class="argument">objectHash</span>, <span class="argument">descriptionString</span>, and <span class="code">YES</span> for @link autorelease autorelease@/link.</p>
            <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">The returned object will be released when the current @link NSAutoreleasePool NSAutoreleasePool @/link is released.  Therefore, the caller must send the returned object a @link retain retain @/link message if the object will be used past the current @link NSAutoreleasePool NSAutoreleasePool @/link context.</div></div></div></div>
 @param      objectHash The hash that represents the value of an object.
 @param      descriptionString A description of the object.
 @result     Returns the object that matches <span class="argument">objectHash</span> if it currently exists in the cache, <span class="code">nil</span> otherwise.
 @seealso    @link RKCache/addObjectToCache: - addObjectToCache: @/link
 @seealso    @link hash - hash @/link
 @seealso    @link RKCache/objectForHash:description:autorelease: - objectForHash:description:autorelease: @/link
 @seealso    @link RKCache/removeObjectFromCache: - removeObjectFromCache: @/link
*/
- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString;

/*!
 @method     objectForHash:description:autorelease:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Return the cached object for the supplied hash, if it exists.
 @discussion <p>This method is used in cases such as returning a cached object from an <span class="code">init...</span> method to avoid adding the object unnecessarily to the current @link NSAutoreleasePool NSAutoreleasePool @/link which would result in wasted work because <span class="code">init...</span> would require sending a @link retain retain @/link to counter the @link autorelease autorelease@/link.</p>
 @param      objectHash The hash that represents the value of an object.
 @param      descriptionString A description of the object.
 @param      shouldAutorelease While the cache is locked, the object matching <span class="argument">objectHash</span> is sent a @link retain retain @/link to ensure the object is not deallocated once the cache lock is released. If <span class="code">YES</span>, the object is also sent an @link autorelease autorelease @/link to keep the retain count balanced.  If <span class="code">NO</span>, the caller takes responsibility for releasing the returned cached object when finished with it.
 @result     Returns the object that matches <span class="argument">objectHash</span> if it currently exists in the cache, <span class="code">nil</span> otherwise.
 @seealso    @link RKCache/addObjectToCache:withHash: - addObjectToCache:withHash: @/link
 @seealso    @link hash - hash @/link
 @seealso    @link RKCache/objectForHash:description: - objectForHash:description: @/link
 @seealso    @link RKCache/removeObjectWithHash: - removeObjectWithHash: @/link
*/
- (id)objectForHash:(const RKUInteger)objectHash description:(NSString * const)descriptionString autorelease:(const BOOL)shouldAutorelease;

/*!
 @method     addObjectToCache:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Add an object to the cache.
 @discussion Invokes @link RKCache/addObjectToCache:withHash: addObjectToCache:withHash: @/link with <span class="argument">object</span> and the result of <span class="code">[</span><span class="argument">object</span> @link hash hash @/link<span class="code">]</span> for the hash value.
 @result     Returns <span class="code">YES</span> if <span class="argument">object</span> was successfully added to the cache, <span class="code">NO</span> otherwise. 
 @seealso    @link RKCache/addObjectToCache:withHash: - addObjectToCache:withHash: @/link
 @seealso    @link RKCache/removeObjectFromCache: - removeObjectFromCache: @/link
*/
- (BOOL)addObjectToCache:(id)object;
/*!
 @method     addObjectToCache:withHash:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Add an object to the cache using the supplied <span class="argument">objectHash</span> value.
 @discussion <p>This method may be used in place of @link RKCache/addObjectToCache: addObjectToCache: @/link when either the hash value is already computed and available, or to override the default value that would be returned by <span class="code">[</span><span class="argument">object</span> @link hash hash @/link<span class="code">]</span>.</p>
 <p>Reasons for returning <span class="code">NO</span> and not adding an object to the cache include:</p>
 <ul>
 <li>An object in the cache with a hash of <span class="argument">objectHash</span> is already in the cache.</li>
 <li>Caching was not enabled when the add was attempted.  See @link RKCache/setCacheEnabled: setCacheEnabled:@/link.</li>
 <li>An error occurred while attempting to add <span class="argument">object</span> to the cache.</li>
 </ul>
 @param      object The object to add to the cache.
 @param      objectHash The hash that represents the value of <span class="argument">object</span>.
 @result     Returns <span class="code">YES</span> if <span class="argument">object</span> was successfully added to the cache, <span class="code">NO</span> otherwise. 
 @seealso    @link RKCache/addObjectToCache: - addObjectToCache: @/link
 @seealso    @link hash - hash @/link
 @seealso    @link RKCache/objectForHash:description: - objectForHash:description: @/link
 @seealso    @link RKCache/removeObjectWithHash: - removeObjectWithHash: @/link
*/
- (BOOL)addObjectToCache:(id)object withHash:(const RKUInteger)objectHash;

/*!
 @method     removeObjectFromCache:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Removes the specified object from the cache.
 @discussion <p>Invokes @link removeObjectWithHash: removeObjectWithHash: @/link with the value of <span class="code">[</span><span class="argument">object</span> @link hash hash @/link<span class="code">]</span>.</p>
 <p>The returned object may not be the same object as <span class="argument">object</span>.  The returned object is the instantiated object that was originally added to the cache, but will have the same hash value as <span class="argument">object</span> and <span class="code">[</span><span class="argument">object</span> @link isEqual: isEqual:@/link<span class="argument">theRemovedObject</span><span class="code">] == YES</span>.</p>
 @result     Removes and returns the object in the cache that has a hash value of <span class="argument">object</span>.  Returns <span class="code">nil</span> if no such object was in the cache.
 @seealso    @link RKCache/addObjectToCache: - addObjectToCache: @/link
 @seealso    @link RKCache/removeObjectWithHash: - removeObjectWithHash: @/link
*/
- (id)removeObjectFromCache:(id)object;
/*!
 @method     removeObjectWithHash:
 @tocgroup   RKCache Adding, Retrieving, and Removing Objects from the Cache
 @abstract   Removes the specified object from the cache.
 @discussion <p>The object to be removed, if any, is sent both a @link retain retain @/link and @link autorelease autorelease @/link while the cache is locked.  This ensures that the object returned remains live in the callers thread for the duration of the callers current @link NSAutoreleasePool NSAutoreleasePool @/link pool.  If you wish to use the object past that point, you must take ownership of it by sending a @link retain retain @/link message.  This is similar to various convenience functions, such as <span class="code">[</span>@link NSString NSString @/link @link stringWithFormat: stringWithFormat:@/link<span class="code">@"Hello"]</span>.</p>
 @param      objectHash The hash that represents the value of an object.
 @result     Returns the object in the cache that has the hash value of <span class="argument">objectHash</span>.  Returns <span class="code">nil</span> if there is was no object in the cache matching <span class="argument">objectHash</span>.
 @seealso    @link RKCache/addObjectToCache:withHash: - addObjectToCache:withHash: @/link
 @seealso    @link hash - hash @/link
 @seealso    @link RKCache/objectForHash:description: - objectForHash:description: @/link
 @seealso    @link RKCache/removeObjectFromCache: - removeObjectFromCache: @/link
*/
- (id)removeObjectWithHash:(const RKUInteger)objectHash;

/*!
 @method     clearCache
 @tocgroup   RKCache Cache Maintenance
 @abstract   Removes all objects from the cache.
*/
- (BOOL)clearCache;

/*!
 @method     cacheSet
 @tocgroup   RKCache Cache Information
 @abstract   A @link NSSet NSSet @/link of the objects cached.
 @discussion <p>Creates a new, autoreleased @link NSSet NSSet @/link by adding all of the objects currently in the cache to a new @link NSSet NSSet@/link.  This is done while the cache is locked, and once all the current objects are added, the cache is unlocked.  Therefore it is possible that the objects in the returned @link NSSet NSSet @/link and the objects in the cache are no longer the same as another thread may have added, removed, or cleared the cache by the time the caller receives the @link NSSet NSSet @/link result.  It is, in essence, a snapshot of contents of the cache at the instant in time it was created.</p>
             <p>The objects in the returned @link NSSet NSSet @/link have their retain count incremented by being included in the @link NSSet NSSet @/link.  Therefore, even if the cache is cleared by another thread, it is still safe to use the objects contained in the returned @link NSSet NSSet @/link.</p>
*/
- (NSSet *)cacheSet;

/*!
 @method     isCacheEnabled
 @tocgroup   RKCache Cache Maintenance
 @abstract   Returns whether or not the cache is currently enabled.
 @seealso    @link RKCache/setCacheEnabled: - setCacheEnabled: @/link
*/
- (BOOL)isCacheEnabled;
/*!
 @method     setCacheEnabled:
 @tocgroup   RKCache Cache Maintenance
 @abstract   Enables or disables the cache.
 @result     Returns <span class="code">YES</span> if the cache was successfully enabled, <span class="code">NO</span> otherwise.
 @seealso    @link RKCache/isCacheEnabled - isCacheEnabled @/link
*/
- (BOOL)setCacheEnabled:(const BOOL)enableCache;


/*!
 @method     cacheCount
 @tocgroup   RKCache Cache Information
 @abstract   The number of objects currently in the cache.
*/
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
