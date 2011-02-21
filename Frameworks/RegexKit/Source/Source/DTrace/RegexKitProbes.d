/*
//
//  RKAutoreleasedMemory.m
//  RegexKit
//  http://regexkit.sourceforge.net/
//
*/

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

typedef long NSInteger;
typedef unsigned long NSUInteger;

typedef struct {
  NSUInteger location;
  NSUInteger length;
} NSRange;

typedef struct {
  void *object;
  char *regex;
  int options;
} regexProbeObject;

/*
  probe MatchException(regexProbeObject *, NSRange *, NSUInteger, void *, NSUInteger, NSRange, int, char *, char *);
  probe BeginMatch(regexProbeObject *probeRegex, NSUInteger hash, NSRange *ranges, NSUInteger rangeCount, void *charactersBuffer, NSUInteger length, NSRange searchRange, int options);
  probe EndMatch(  regexProbeObject *probeRegex, NSUInteger hash, NSRange *ranges, NSUInteger rangeCount, void *charactersBuffer, NSUInteger length, NSRange searchRange, int options, int errorCode, char *errorCodeString);

*/
provider RegexKit {
  /* Fires when a condition is detected that causes a performance problem, like not being able to get direct access to a strings buffer to perform matches on. */
  probe PerformanceNote(void *, NSUInteger, char *, NSUInteger, int, int, char *);
  
  /* RKRegex probes */
  probe BeginRegexCompile(void *, NSUInteger, char *, int);
  probe EndRegexCompile(  void *, NSUInteger, char *, int, int, char *, char *, int);
  
  probe MatchException(regexProbeObject *, NSUInteger, NSRange *, NSUInteger, void *, NSUInteger, NSRange *, int, char *, char *);

  probe BeginMatch(regexProbeObject *, NSUInteger, NSRange *, NSUInteger, void *, NSUInteger, NSRange *, int);
  probe EndMatch(  regexProbeObject *, NSUInteger, NSRange *, NSUInteger, void *, NSUInteger, NSRange *, int, int, char *);

  /* RKCache probes */
  probe CacheCleared(void *, char *, int, NSUInteger, NSUInteger, NSUInteger);

  probe BeginCacheLookup(void *, char *, NSUInteger, char *, int, int, NSUInteger, NSUInteger);
  probe EndCacheLookup(  void *, char *, NSUInteger, char *, int, int, NSUInteger, NSUInteger, NSUInteger, void *);

  probe BeginCacheAdd(void *, char *, void *, NSUInteger, char *, int);
  probe EndCacheAdd(  void *, char *, void *, NSUInteger, char *, int, int, NSUInteger);

  probe BeginCacheRemove(void *, char *, NSUInteger, int);
  probe EndCacheRemove(  void *, char *, NSUInteger, int, void *, char *, NSUInteger);

  /* RKLock probes */
  
  probe BeginLock(void *, NSInteger, int);
  probe EndLock(  void *, NSInteger, int, int, NSUInteger); 

  probe Unlock(void *, int, int);
  
  /* object *, hash, collection count */
  probe BeginSortedRegexSort(void *, NSUInteger, NSUInteger);
  /* object *, hash, collection count, able to sort */
  probe EndSortedRegexSort(  void *, NSUInteger, NSUInteger, int);

  /* object *, hash, collection count, match target */
  probe BeginSortedRegexMatch(void *, NSUInteger, NSUInteger, char *);
  /* object *, hash, regex *, regex hash, regex char *, Sorted index, Collection count, Sorted index hit count, collection index, resort required */
  probe EndSortedRegexMatch(  void *, NSUInteger, void *, NSUInteger, char *, NSUInteger, NSUInteger, NSUInteger, NSUInteger, int);
  
  /* object *, hash, regex *, regex hash, regex char *, Sorted index, Collection count, Sorted index hit count, collection index, match result */
  probe SortedRegexCompare(void *, NSUInteger, void *, NSUInteger, char *, NSUInteger, NSUInteger, NSUInteger, NSUInteger, int);

  /* object *, hash, hits, misses, not founds, hits %, misses %, not founds %*/
  probe SortedRegexCache(void *, NSUInteger, NSUInteger, NSUInteger, NSUInteger, double *, double *);
};

#pragma D attributes Unstable/Unstable/Common provider RegexKit provider
#pragma D attributes Private/Private/Common provider RegexKit module
#pragma D attributes Private/Private/Common provider RegexKit function
#pragma D attributes Unstable/Unstable/Common provider RegexKit name
#pragma D attributes Unstable/Unstable/Common provider RegexKit args

