//
//  sortedRegexCollection.m
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

#import "sortedRegexCollection.h"

@implementation sortedRegexCollection

#define RKSortedRegexCollectionDefaultRegexLibrary RKRegexPCRELibrary
#define RKSortedRegexCollectionDefaultRegexLibraryOptions (RKCompileUTF8 | RKCompileNoUTF8Check)
#define RKSortedRegexCollectionHashForCollection(collection, regexLibrary, libraryOptions) ((RKUInteger)([collection hash] ^ (RKUInteger)collection ^ (RKUInteger)[regexLibrary hash] ^ libraryOptions))

- (void)testRKSortedRegexCollectionInitError
{
  NSSet *regexSet   = [NSSet   setWithObjects:  @"/ad/.*", @".*/ads/", @"/banners/", @"doubleclickSet",   @"adtech", @"announce", @"banner", @"(dblclk|(?zdouble))", NULL];
  NSSet *regexArray = [NSArray arrayWithObjects:@"/ad/.*", @".*/ads/", @"/banners/", @"doubleclickArray", @"adtech", @"announce", @"banner", @"(dblclk|(?zdouble))", NULL];
  
  NSError *error = NULL;
  
  id sortedRegexCollectionClass = objc_getClass("RKSortedRegexCollection"), sortedRegexCollection = NULL;
  
  sortedRegexCollection = [sortedRegexCollectionClass sortedRegexCollectionForCollection:regexSet library:RKRegexPCRELibrary options:(RKCompileUTF8 | RKCompileNoUTF8Check) error:&error];
  //if(sortedRegexCollection) { NSLog(@"sortedRegexCollection: %@", sortedRegexCollection); } else { NSLog(@"sortedRegexCollection == NULL"); }
  //if(error) { NSLog(@"Error: %@", error); NSLog(@"userInfo: %@", [error userInfo]); } else { NSLog(@"No error."); }
  
  sortedRegexCollection = NULL; error = NULL;
  
  sortedRegexCollection = [sortedRegexCollectionClass sortedRegexCollectionForCollection:regexArray library:RKRegexPCRELibrary options:(RKCompileUTF8 | RKCompileNoUTF8Check) error:&error];
  //if(sortedRegexCollection) { NSLog(@"sortedRegexCollection: %@", sortedRegexCollection); } else { NSLog(@"sortedRegexCollection == NULL"); }
  //if(error) { NSLog(@"Error: %@", error); NSLog(@"userInfo: %@", [error userInfo]); } else { NSLog(@"No error."); }
}

- (void)testRKSortedRegexCollectionSimple
{
  return;
  NSSet *regexSet = [NSSet setWithObjects:@"/ad/.*", @".*/ads/", @"./banners/", @"doubleclick", @"adtech", @"announce", @"banner", @"(dblclk|double)", NULL];
  //NSLog(@"regexSet: hash 0x%8.8lx / setListHash: 0x%8.8lx / %@", (unsigned long)[regexSet hash], (unsigned long)RKSortedRegexCollectionHashForCollection(regexSet, RKSortedRegexCollectionDefaultRegexLibrary, RKSortedRegexCollectionDefaultRegexLibraryOptions), regexSet);
  //NSSet *regex2Set = [NSSet setWithObjects:@"/ad/", @"/ads/", @"./banners/", @"doubleclick", @"adtech", @"announce", @"banner", @"(dblclk|double)", NULL];
  //NSLog(@"regex2Set: hash 0x%8.8lx / setListHash: 0x%8.8lx / %@", (unsigned long)[regex2Set hash], (unsigned long)RKSortedRegexCollectionHashForCollection(regex2Set, RKSortedRegexCollectionDefaultRegexLibrary, RKSortedRegexCollectionDefaultRegexLibraryOptions), regex2Set);
  //NSLog(@"regexSet hash == regex2 hash: %@ isEqual: %@ regexSet setListHash == regex2 setListHash: %@", RKYesOrNo([regexSet hash] == [regex2Set hash]), RKYesOrNo([regexSet isEqualToSet:regex2Set]), RKYesOrNo((RKSortedRegexCollectionHashForCollection(regexSet, RKSortedRegexCollectionDefaultRegexLibrary, RKSortedRegexCollectionDefaultRegexLibraryOptions) == RKSortedRegexCollectionHashForCollection(regex2Set, RKSortedRegexCollectionDefaultRegexLibrary, RKSortedRegexCollectionDefaultRegexLibraryOptions))));

  BOOL matchedBySet = NO;
  for(int x = 0; x < 1; x++) {
    matchedBySet = [@"news://ad78.doubleclick.com/dbl/for/you/zing" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"scp://xw99.zoo.com/ad/for/you/special" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"ftp://ny23.doubleclick.com/dbl/for/you/.php?" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"ssh://ww99.adtech.com/tec/for/you/buy" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"money://xw99.ads.com/sda/for/you/money" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"http://xw99.zoo.com/ad/for/you/spam" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"http://xw99.adtech.com/tec/for/you/cash" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"win://xw99.zoo.com/ad/for/you/scam" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"http://ad78.doubleclick.com/dbl/for/you/makemoneyfast" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"cash://xw99.zoo.com/ad/for/you/greencard" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"http://ww99.announce.com/ann/for/you/winner" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"spam://xw99.zoo.com/ad/for/you/warez" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"warez://ww99.banners.com/ban/for/you/pr0n" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"https://xw99.zoo.com/ad/for/you/phish" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"svn://ww99.adtech.com/tec/for/you/bank" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"http://ww99.adtech.com/tec/for/you/free" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"xw99.zoo.com/ad/for/you/winner" isMatchedByAnyRegexInSet:regexSet];
    matchedBySet = [@"zip://ny23.doubleclick.com/dbl/for/you/looser" isMatchedByAnyRegexInSet:regexSet];

    //if((garbageCollectorEnabled) && ((x % 100) == 0)) { objc_collect_function(0 << 0); }
  }
  
  //id sortedRegexCollectionClass = objc_getClass("RKSortedRegexCollection");
  //NSLog(@"RKSetListCache: %@", [sortedRegexCollectionClass performSelector:@selector(sortedRegexCollectionCache)]);
  //NSLog(@"Sorted set: %@", [sortedRegexCollectionClass performSelector:@selector(sortedArrayForSortedRegexCollection:) withObject:[sortedRegexCollectionClass performSelector:@selector(sortedRegexCollectionForCollection:) withObject:regexSet]]);
}

- (void)testRKSortedRegexCollectionBlacklist
{
  RKUInteger startAutoreleasedObjects = (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0);

  RKCPUTime startTime = [NSDate cpuTimeUsed];
  RKUInteger x = 0;

  //for(x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:blacklistArray]; } }
  for(x = 0; x < 1; x++) {
    NSString *URLString = NULL;
    NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
    
    while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:blacklistArray]; }
  }
  
  x *= [urlArray count];
  
  RKCPUTime elapsedTime = [NSDate differenceOfStartingTime:startTime endingTime:[NSDate cpuTimeUsed]];
  NSString *timingString = [NSString stringWithFormat:@"%-45.45s | CPU: %@  %u iterations, per: U %9.5fus, S %9.5fus, U+S %9.5fus", [NSStringFromSelector(_cmd) UTF8String], [NSDate stringFromCPUTime:elapsedTime], x, ((elapsedTime.userCPUTime / (double)x)), ((elapsedTime.systemCPUTime / (double)x)), ((elapsedTime.CPUTime / (double)x))];

  NSLog(@"%@", timingString);
  NSLog(@"starting autoreleased objects: %u  Now: %u  Diff: %u", startAutoreleasedObjects, (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0), (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0) - startAutoreleasedObjects);
}

- (void)testRKSortedRegexCollectionWhitelist
{
  RKCPUTime startTime = [NSDate cpuTimeUsed];
  RKUInteger x = 0;
  
  //for(x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:whitelistArray]; } }
  for(x = 0; x < 1; x++) {
    NSString *URLString = NULL;
    NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
    
    while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:whitelistArray]; }
  }
  
  x *= [urlArray count];
  
  RKCPUTime elapsedTime = [NSDate differenceOfStartingTime:startTime endingTime:[NSDate cpuTimeUsed]];
  NSString *timingString = [NSString stringWithFormat:@"%-45.45s | CPU: %@  %u iterations, per: U %9.5fus, S %9.5fus, U+S %9.5fus", [NSStringFromSelector(_cmd) UTF8String], [NSDate stringFromCPUTime:elapsedTime], x, ((elapsedTime.userCPUTime / (double)x)), ((elapsedTime.systemCPUTime / (double)x)), ((elapsedTime.CPUTime / (double)x))];
  
  NSLog(@"%@", timingString);
}

- (void)testRKSortedRegexCollectionBlacklistForIn
{
  RKUInteger startAutoreleasedObjects = (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0);

  RKCPUTime startTime = [NSDate cpuTimeUsed];
  RKUInteger x = 0;

  
  for(x = 0; x < 1; x++) {
    NSString *URLString = NULL;
    NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
    
    while((URLString = [urlArrayEnumerator nextObject]) != NULL) {
      NSString *blacklistString = NULL;
      NSEnumerator *blacklistArrayEnumerator = [blacklistArray objectEnumerator];
      while((blacklistString = [blacklistArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByRegex:blacklistString]; }
    }
  }

  x *= [urlArray count];
  
  RKCPUTime elapsedTime = [NSDate differenceOfStartingTime:startTime endingTime:[NSDate cpuTimeUsed]];
  NSString *timingString = [NSString stringWithFormat:@"%-45.45s | CPU: %@  %u iterations, per: U %9.5fus, S %9.5fus, U+S %9.5fus", [NSStringFromSelector(_cmd) UTF8String], [NSDate stringFromCPUTime:elapsedTime], x, ((elapsedTime.userCPUTime / (double)x)), ((elapsedTime.systemCPUTime / (double)x)), ((elapsedTime.CPUTime / (double)x))];

  NSLog(@"%@", timingString);
  NSLog(@"starting autoreleased objects: %u  Now: %u  Diff: %u", startAutoreleasedObjects, (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0), (([NSAutoreleasePool respondsToSelector:@selector(totalAutoreleasedObjects)]) ? [NSAutoreleasePool totalAutoreleasedObjects] : 0) - startAutoreleasedObjects);
}

- (void)testRKSortedRegexCollectionWhitelistForIn
{
  RKCPUTime startTime = [NSDate cpuTimeUsed];
  RKUInteger x = 0;
  
  //for(x = 0; x < 1; x++) { for(id URLString in urlArray) { for(id whitelistString in whitelistArray) { [URLString isMatchedByRegex:whitelistString]; } } }
  for(x = 0; x < 1; x++) {
    NSString *URLString = NULL;
    NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
    
    while((URLString = [urlArrayEnumerator nextObject]) != NULL) {
      NSString *whitelistString = NULL;
      NSEnumerator *whitelistArrayEnumerator = [whitelistArray objectEnumerator];
      while((whitelistString = [whitelistArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByRegex:whitelistString]; }
    }
  }
  
  x *= [urlArray count];
  
  RKCPUTime elapsedTime = [NSDate differenceOfStartingTime:startTime endingTime:[NSDate cpuTimeUsed]];
  NSString *timingString = [NSString stringWithFormat:@"%-45.45s | CPU: %@  %u iterations, per: U %9.5fus, S %9.5fus, U+S %9.5fus", [NSStringFromSelector(_cmd) UTF8String], [NSDate stringFromCPUTime:elapsedTime], x, ((elapsedTime.userCPUTime / (double)x)), ((elapsedTime.systemCPUTime / (double)x)), ((elapsedTime.CPUTime / (double)x))];
  
  NSLog(@"%@", timingString);
}

@end
