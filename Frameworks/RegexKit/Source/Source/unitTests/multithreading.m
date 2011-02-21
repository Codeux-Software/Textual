//
//  multithreading.m
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

@class RKSortedRegexCollection;

#import "multithreading.h"
#import "RegexKitPrivateAtomic.h"

@implementation multithreading

NSString *RKThreadWillExitNotification = @"RKThreadWillExitNotification";

- (id) initWithInvocation:(NSInvocation *) anInvocation
{
  [self autorelease];  // In case anything goes wrong (ie, exception), we're guaranteed to be in the autorelease pool.  On successful initialization, we send ourselves a retain.
                       // If we create any ivars that are not autoreleased, they should release when the autorelease pool releases us and in turn we dealloc, releasing those resources.

  if(isInitialized == NO) {
    if((self = [super initWithInvocation:anInvocation]) == NULL) { goto errorExit; }
    isInitialized = YES;
    
    srandomdev();

    startAutoreleasedObjects = [NSAutoreleasePool totalAutoreleasedObjects];
    
    globalThreadLock          = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
    globalThreadConditionLock = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
    globalThreadCondition     = (pthread_cond_t)PTHREAD_COND_INITIALIZER;
    globalLogLock             = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
    threadExitLock            = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;

    int pthread_err = 0;

    if((pthread_err = pthread_mutex_init(&globalThreadLock,          NULL)) != 0) { NSLog(@"pthread_mutex_init on globalThreadLock returned %d",          pthread_err); exit(0); }
    if((pthread_err = pthread_mutex_init(&globalThreadConditionLock, NULL)) != 0) { NSLog(@"pthread_mutex_init on globalThreadConditionLock returned %d", pthread_err); exit(0); }
    if((pthread_err = pthread_cond_init( &globalThreadCondition,     NULL)) != 0) { NSLog(@"pthread_cond_init on globalThreadCondition returned %d",      pthread_err); exit(0); }
    if((pthread_err = pthread_mutex_init(&globalLogLock,             NULL)) != 0) { NSLog(@"pthread_mutex_init on globalLogLock returned %d",             pthread_err); exit(0); }
    if((pthread_err = pthread_mutex_init(&threadExitLock,            NULL)) != 0) { NSLog(@"pthread_mutex_init on threadExitLock returned %d",            pthread_err); exit(0); }

    logDateFormatter   = [[NSDateFormatter alloc] initWithDateFormat:@"%Y/%m/%d %H:%M:%S.%F" allowNaturalLanguage:NO];
    globalLogString    = [[NSMutableString alloc] init];
    globalLogArray     = [[NSMutableArray  alloc] init];
    timingResultsArray = [[NSMutableArray  alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptNotification:) name:RKThreadWillExitNotification          object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptNotification:) name:NSWillBecomeMultiThreadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptNotification:) name:SenTestSuiteDidStartNotification      object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptNotification:) name:SenTestSuiteDidStopNotification       object:nil];
    
    [[RKRegex regexCache] clearCache];
    [[RKRegex regexCache] clearCounters];
  

    [[RKRegex regexCache] setDebug:YES];
    
    iterations = 250;
    if(([leakEnvString intValue] > 0) || ([debugEnvString intValue] > 0)) { iterations = 200; }
    
    if(([leakEnvString intValue] > 0)) {
      NSString *leakString = [[NSString alloc] initWithFormat:@"This string should leak from [%@ %@] on purpose", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
      NSLog(@"leakString @ %p: %@", leakString, leakString);
      leakString = (NSString *)0xdeadbeef;
      
      if([leakEnvString intValue] > 1) {
        //NSString *leaksCommandString = [NSString stringWithFormat:@"/usr/bin/leaks -exclude \"+[%@ %@]\" -exclude \"+[NSTitledFrame initialize]\" -exclude \"+[NSLanguage initialize]\" -exclude \"NSPrintAutoreleasePools\" -exclude \"+[NSWindowBinder initialize]\" -exclude \"+[NSCollator initialize]\" -exclude \"+[NSCollatorElement initialize]\" %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), getpid()];
        NSString *leaksCommandString = [NSString stringWithFormat:@"/usr/bin/leaks  %d", getpid()];

        [NSAutoreleasePool showPools];
        NSLog(@"starting autoreleased objects: %u  Now: %u  Diff: %u", startAutoreleasedObjects, [NSAutoreleasePool totalAutoreleasedObjects], [NSAutoreleasePool totalAutoreleasedObjects] - startAutoreleasedObjects);
        NSLog(@"autoreleasedObjectCount: %u", [NSAutoreleasePool autoreleasedObjectCount]);
        NSLog(@"topAutoreleasePoolCount: %u", [NSAutoreleasePool topAutoreleasePoolCount]);
        
        NSLog(@"Executing '%@'", leaksCommandString);
        system([leaksCommandString UTF8String]);
      }
    }

    loggingTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(flushLog) userInfo:nil repeats:YES] retain];
    
    testStartCPUTime = [NSDate cpuTimeUsed];
  }

  return([self retain]); // We have successfully initialized, so rescue ourselves from the autorelease pool.

errorExit: // Catch point in case any clean up needs to be done.  Currently, none is neccesary.
           // We are autoreleased at the start, any objects/resources we created will be handled by dealloc
  NSLog(@"Unable to initalize");
  return(nil);
}

- (void)releaseResources
{
  NSLog(@"%@", RKPrettyObjectMethodString(@"Cache status:\n%@", [RKRegex regexCache]));

  testEndCPUTime = [NSDate cpuTimeUsed];
  testElapsedCPUTime = [NSDate differenceOfStartingTime:testStartCPUTime endingTime:testEndCPUTime];
  
  NSString *leaksCommandString = nil;
  
  NSSet *regexCacheSet = [[RKRegex regexCache] cacheSet];
  NSLog(@"Cache set count: %d", [regexCacheSet count]);
  
  NSAutoreleasePool *cachePool = [[NSAutoreleasePool alloc] init];
  [cachePool release]; cachePool = NULL;
  NSLog(@"RKRegex cache flushed");
  
  if(([leakEnvString intValue] > 0)) {
    //leaksCommandString = [[NSString alloc] initWithFormat:@"/usr/bin/leaks -exclude \"+[%@ %@]\" -exclude \"+[NSTitledFrame initialize]\" -exclude \"+[NSLanguage initialize]\" -exclude \"NSPrintAutoreleasePools\" -exclude \"+[NSWindowBinder initialize]\" -exclude \"+[NSCollator initialize]\" -exclude \"+[NSCollatorElement initialize]\" %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), getpid()];
    leaksCommandString = [[NSString alloc] initWithFormat:@"/usr/bin/leaks  %d", getpid()];

    if([leakEnvString intValue] > 2) {
      [NSAutoreleasePool showPools];
      NSLog(@"starting autoreleased objects: %u  Now: %u  Diff: %u", startAutoreleasedObjects, [NSAutoreleasePool totalAutoreleasedObjects], [NSAutoreleasePool totalAutoreleasedObjects] - startAutoreleasedObjects);
      NSLog(@"autoreleasedObjectCount: %u", [NSAutoreleasePool autoreleasedObjectCount]);
      NSLog(@"topAutoreleasePoolCount: %u", [NSAutoreleasePool topAutoreleasePoolCount]);
    }
        
    NSLog(@"Executing '%@'", leaksCommandString);
    system([leaksCommandString UTF8String]);
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if(loggingTimer != nil) {
    NSLog(@"invalidating timer..");
    [loggingTimer invalidate];
    [loggingTimer release];
    loggingTimer = nil;
    NSLog(@"The logging timer has been terminated.");
  }
  
  if(timingResultsArray != nil) {
    if([timingResultsArray count] > 0) {
      NSLog(@"Timing results:\n");
      NSEnumerator *timingEnumerator = [timingResultsArray objectEnumerator];
      NSString *timingString = nil;
      while((timingString = [timingEnumerator nextObject]) != nil) {
        fprintf(stderr, "%s\n", [timingString UTF8String]);
      }
      fprintf(stderr, "\n");
    }
  }
    
  int pthread_err = 0;
  if((pthread_err = pthread_mutex_destroy(&globalThreadLock))          != 0) { NSLog(@"pthread_mutex_destroy on globalThreadLock returned %d",          pthread_err); }
  if((pthread_err = pthread_mutex_destroy(&globalThreadConditionLock)) != 0) { NSLog(@"pthread_mutex_destroy on globalThreadConditionLock returned %d", pthread_err); }
  if((pthread_err = pthread_cond_destroy( &globalThreadCondition))     != 0) { NSLog(@"pthread_cond_destroy on globalThreadCondition returned %d",      pthread_err); }
  if((pthread_err = pthread_mutex_destroy(&globalLogLock))             != 0) { NSLog(@"pthread_mutex_destroy on globalLogLock returned %d",             pthread_err); }
  if((pthread_err = pthread_mutex_destroy(&threadExitLock))            != 0) { NSLog(@"pthread_mutex_destroy on threadExitLock returned %d",            pthread_err); }

  if(globalLogString != nil) {
    if([globalLogString length] > 0) {
      fprintf(stderr, "\n---------\nThe global log string @ %p:\n%s\n", globalLogString, [globalLogString UTF8String]);
      fflush(stderr);
    }
  }
  
  if(globalLogString    != nil) { [globalLogString    release]; globalLogString    = nil; }
  if(globalLogArray     != nil) { [globalLogArray     release]; globalLogArray     = nil; }
  if(timingResultsArray != nil) { [timingResultsArray release]; timingResultsArray = nil; }
  if(loggingTimer       != nil) { [loggingTimer       release]; loggingTimer       = nil; }
  if(logDateFormatter   != nil) { [logDateFormatter   release]; logDateFormatter   = nil; }
  
  NSLog(@"starting autoreleased objects: %u  Now: %u  Diff: %u", startAutoreleasedObjects, [NSAutoreleasePool totalAutoreleasedObjects], [NSAutoreleasePool totalAutoreleasedObjects] - startAutoreleasedObjects);
  
  NSLog(@"Elapsed CPU time: %@", [NSDate stringFromCPUTime:testElapsedCPUTime]);
  NSLog(@"Elapsed CPU time: %@", [NSDate microSecondsStringFromCPUTime:testElapsedCPUTime]);

  fflush(stdout); fflush(stderr);
  NSLog(@"Completed dealloc");
  NSLog(@"%@", RKPrettyObjectMethodString(@"Teardown complete\n"));
  fflush(stdout); fflush(stderr);
  fprintf(stderr, "-----------------------------------------\n\n");
  fflush(stdout); fflush(stderr);
}

- (void)dealloc
{
  [self releaseResources];
  [super dealloc];
}

- (void)setUp
{
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f/10.0f]];
  [self flushLog];
  [[RKRegex regexCache] clearCache];
  [[RKRegex regexCache] clearCounters];
}

- (void)tearDown
{
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f/10.0f]];
  [self flushLog];
  [self releaseResources];
}

- (void)acceptNotification:(NSNotification *)theNotification
{
  if(isInitialized == NO) { NSLog(@"Notification: %@", [theNotification name]); goto exitNow; }
  
  [self thread:0 log:[NSString stringWithFormat:@"Notification: %@\n", [theNotification name]]];
     
exitNow:
    return;
}


- (void)flushLog
{
  if(isInitialized == NO) { NSLog(@"flushLog called but not initialized"); return; }

  pthread_mutex_lock(&globalLogLock);
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  NSString *logString = [NSString stringWithString:globalLogString];
  [globalLogString setString:@""];
  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  pthread_mutex_unlock(&globalLogLock);
  
  if([logString length] > 0) { fprintf(stderr, "%s", [logString UTF8String]); }
}

- (void)thread:(int)threadID log:(NSString *)logString
{
  if(isInitialized == NO) { NSLog(@"logger called but not initialized: ID #%d : %@", threadID, logString); return; }

  pthread_mutex_lock(&globalLogLock);
  // vvvvvvvvvvvv BEGIN LOCK CRITICAL PATH vvvvvvvvvvvv
  [globalLogString appendString:[NSString stringWithFormat:@"[%@ <#%2d>] %@", [logDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]], threadID, logString]];
  // ^^^^^^^^^^^^^ END LOCK CRITICAL PATH ^^^^^^^^^^^^^
  pthread_mutex_unlock(&globalLogLock);
}

- (void)testSimpleMultiThreading
{
  if(isInitialized == NO) { STFail(@"[%@ %@] is not initialized!", [self className], NSStringFromSelector(_cmd)); return; }
  int pthread_err = 0, totalThreads = 13;
  
  [self thread:0 log:[NSString stringWithFormat:@"%@ is initializing.\n", NSStringFromSelector(_cmd)]];
  
  [self flushLog];

  [objc_getClass("RKSortedRegexCollection") initialize];

  if([multithreadingEnvString intValue] < 1) { [self thread:0 log:@"Multithreading testing was not requested\n"]; return; }
  setpriority(PRIO_PROCESS, 0, 20);
  
  int x = 0;
  for(x = 1; x < totalThreads + 1; x++) {
    [NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:[NSNumber numberWithInt:x]];
    [self flushLog];
  }

  usleep(10000);
  [self thread:0 log:[NSString stringWithFormat:@"Threads launched\n"]];
  [self flushLog];
    
  [self thread:0 log:[NSString stringWithFormat:@"Quiescent for 1 second in run loop\n"]];
  [self flushLog];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];

  [self thread:0 log:[NSString stringWithFormat:@"Broadcasting start condition\n"]];
  [self flushLog];
  if((pthread_err = pthread_cond_broadcast(&globalThreadCondition)) != 0) { [self thread:0 log:[NSString stringWithFormat:@"pthread_cond_broadcast on globalThreadCondition returned %d\n", pthread_err]]; }

  [self thread:0 log:[NSString stringWithFormat:@"Will now run the run loop until I see %d threads exit.\n", totalThreads]];
  [self flushLog];

  NSTimeInterval startedAt = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval lastRelease = startedAt;
  int lastCount = 0, thisCount = 0;
  double resolution = 1.0/10.0;
  BOOL endRunLoop = NO, isRunning = YES;
  
  while((isRunning == YES) && (endRunLoop == NO)) {
    NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
    
    NSDate *next = [NSDate dateWithTimeIntervalSinceNow:resolution];
    isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    if(((currentTime - lastRelease) > 1.0)) {
      //[self thread:0 log:[NSString stringWithFormat:@"RKRegex Cache: %@\n", [[RKRegex regexCache] status]]];
      //[self thread:0 log:[NSString stringWithFormat:@"RKSRCol Cache: %@\n", [[objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache] status]]];
      
      [[RKRegex regexCache] clearCache];
      [[objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache] clearCache];
      [threadPool release];
      sched_yield();
      threadPool = [[NSAutoreleasePool alloc] init];      
      lastRelease = currentTime;
    }

    if((pthread_err = pthread_mutex_lock(&threadExitLock)) != 0) { [self thread:0 log:[NSString stringWithFormat:@"pthread_mutex_lock on threadExitLock returned %d\n", pthread_err]]; }
    thisCount = threadExitCount;
    if((pthread_err = pthread_mutex_unlock(&threadExitLock)) != 0) { [self thread:0 log:[NSString stringWithFormat:@"pthread_mutex_unlock on threadExitLock returned %d\n", pthread_err]]; }

    if(thisCount != lastCount) { [self thread:0 log:[NSString stringWithFormat:@"%d of %d threads exited.  Waiting for %d more.\n", thisCount, totalThreads, totalThreads - thisCount]]; lastCount = thisCount; }
    if(thisCount == totalThreads) { [self thread:0 log:[NSString stringWithFormat:@"All threads are now accounted for, will stop the run loop\n"]]; endRunLoop = YES; }

    [threadPool release];
  }

  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f/10.0f]];
  
  setpriority(PRIO_PROCESS, 0, 0);

  return;
}

- (int)threadEntry:(id)threadArgument
{
  NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
  int pthread_err = 0;

  int threadID = [threadArgument intValue];

  NSTimeInterval sleepInterval = 0.0;
  switch(threadID) {
    case 1: sleepInterval = 0.0003; break;
    case 2: sleepInterval = 0.0005; break;
    case 3: sleepInterval = 0.0007; break;
    case 4: sleepInterval = 0.0011; break;

    case 5: sleepInterval = 0.0013; break;
    case 6: sleepInterval = 0.0017; break;
    case 7: sleepInterval = 0.0019; break;
    case 8: sleepInterval = 0.0023; break;

    case 9: sleepInterval = 0.0029; break;
    case 10: sleepInterval = 0.0031; break;
    case 11: sleepInterval = 0.0037; break;
    case 12: sleepInterval = 0.0041; break;

    case 13: sleepInterval = 0.0043; break;
    case 14: sleepInterval = 0.0047; break;
    case 15: sleepInterval = 0.0053; break;
    case 16: sleepInterval = 0.0059; break;
      
    default: sleepInterval = 0.0; break;
  }
  
  [self thread:threadID log:[NSString stringWithFormat:@"Thread %d, pthread 0x%8.8x spun up and waiting for launch command. Frame address is 0x%8.8x\n", threadID, pthread_self(), __builtin_frame_address(0)]];
  
  if((pthread_err = pthread_mutex_lock(&globalThreadConditionLock)) != 0) { [self thread:threadID log:[NSString stringWithFormat:@"pthread_mutex_lock on globalThreadConditionLock returned %d\n", pthread_err]]; }
  if((pthread_err = pthread_cond_wait(&globalThreadCondition, &globalThreadConditionLock)) != 0) { [self thread:threadID log:[NSString stringWithFormat:@"pthread_cond_wait on globalThreadCondition returned %d\n", pthread_err]]; }
  if((pthread_err = pthread_mutex_unlock(&globalThreadConditionLock)) != 0) { [self thread:threadID log:[NSString stringWithFormat:@"pthread_mutex_unlock on globalThreadConditionLock returned %d\n", pthread_err]]; }

  double rndTime = ((double)random()/(double)INT_MAX)*5.0;
  [self thread:threadID log:[NSString stringWithFormat:@"Thread %d received launch signal, starting tests after %5.3f delay\n", threadID, rndTime]];
  [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:rndTime]];

  int x = 0, y = 0;

  for(x = 0; x < 7; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKCache *recache = [RKRegex regexCache];
    RKCache *colcache = [objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache];
        
    [self thread:threadID log:[NSString stringWithFormat:@"Thread %3d, round %3d starting.. RKRegex [cnt:%3u clr:%5u r:%5u s:%5u wb:%5u] RKSRCol [cnt:%3u clr:%5u r:%5u s:%5u wb:%5u] auto: %8u\n", threadID, x, [recache cacheCount], [recache cacheClearedCount], [recache readBusyCount], [recache readSpinCount], [recache writeBusyCount], [colcache cacheCount], [colcache cacheClearedCount], [colcache readBusyCount], [colcache readSpinCount], [colcache writeBusyCount], [NSAutoreleasePool totalAutoreleasedObjects]]];
    for(y = 0; y < 53; y++) {
      [self executeTest:y];
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:sleepInterval]];
    }
    
    if(loopPool != nil) { [loopPool release]; loopPool = nil; }
  }

  [self thread:threadID log:[NSString stringWithFormat:@"Thread %d completed all tests, will now exit.\n", threadID]];

  // We post our own thread exit notification with our unique thread id to prevent coalescing in the notification center.
  NSValue *threadValue = [NSValue valueWithPointer:pthread_self()];
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:RKThreadWillExitNotification object:threadValue userInfo:[NSDictionary dictionaryWithObject:threadValue forKey:@"threadValue"]]];
  [threadPool release];
  RKAtomicIncrementIntBarrier(&((int)threadExitCount));
  return(0);
}

- (BOOL)executeTest:(unsigned int)testNumber
{
  NSAutoreleasePool *testPool = [[NSAutoreleasePool alloc] init];
  
  switch(testNumber) {
    case 0: [self mt_test_1]; break;
    case 1: [self mt_test_2]; break;
    case 2: [self mt_test_3]; break;
    case 3: [self mt_test_4]; break;
    case 4: [self mt_cache_4]; break;
    case 5: [self mt_test_6]; break;
    case 6: [self mt_test_7]; break;
    case 7: [self mt_cache_1]; break;
    case 8: [self mt_test_8]; break;
    case 9: [self mt_test_9]; break;
    case 10: [self mt_test_10]; break;
    case 11: [self mt_cache_5]; break;
    case 12: [self mt_test_12]; break;
    case 13: [self mt_test_13]; break;
    case 14: [self mt_test_14]; break;
    case 15: [self mt_cache_2]; break;
    case 16: [self mt_test_15]; break;
    case 17: [self mt_test_16]; break;
  
    case 18: [self mt_time_1]; break;
    case 19: [self mt_cache_6]; break;
    case 20: [self mt_time_3]; break;

    case 21: [self mt_sortedRegex_wl1]; break;

    case 22: [self mt_cache_4]; break;
    case 23: [self mt_time_5]; break;
    case 24: [self mt_time_6]; break;
    case 25: [self mt_time_7]; break;
    case 26: [self mt_time_8]; break;
    case 27: [self mt_cache_3]; break;
    case 28: [self mt_time_9]; break;
    case 29: [self mt_time_10]; break;
    case 30: [self mt_time_11]; break;
    case 31: [self mt_test_5]; break;
    case 32: [self mt_test_11]; break;
    case 33: [self mt_time_2]; break;
    case 34: [self mt_time_12]; break;

    case 35: [self mt_sortedRegex_wl1]; break;
    case 36: [self mt_test_18]; break;
    case 37: [self mt_test_19]; break;
    case 38: [self mt_sortedRegex_bl1]; break;
    case 39: [self mt_test_21]; break;
    case 40: [self mt_test_22]; break;
    case 41: [self mt_test_23]; break;

    case 42: [self mt_test_24]; break;
    case 43: [self mt_test_25]; break;
    case 44: [self mt_test_26]; break;

    case 45: [self mt_test_27]; break;

    case 46: [self mt_sortedRegex_bl1]; break;
    case 47: [self mt_sortedRegex_bl1]; break;
    case 48: [self mt_sortedRegex_bl1]; break;
    case 49: [self mt_sortedRegex_wl2]; break;

    case 50: [self mt_test_17]; break;
    case 51: [self mt_test_20]; break;

    case 52: [self mt_time_4]; break;

    default: [self mt_time_3]; break;
  }

  [testPool release];

  return(NO);
}











- (void)mt_cache_1
{
  BOOL lookupEnabled = [[RKRegex regexCache] isCacheLookupEnabled];
  
  if(lookupEnabled == NO) { [[RKRegex regexCache] setCacheLookupEnabled:YES]; } //else { [[RKRegex regexCache] setCacheLookupEnabled:NO]; }
}

- (void)mt_cache_2
{
  BOOL addingEnabled = [[RKRegex regexCache] isCacheAddingEnabled];
  
  if(addingEnabled == NO) { [[RKRegex regexCache] setCacheAddingEnabled:YES]; } //else { [[RKRegex regexCache] setCacheAddingEnabled:NO]; }
}

- (void)mt_cache_3
{
  NSAutoreleasePool *clearCachePool = [[NSAutoreleasePool alloc] init];
  [[RKRegex regexCache] clearCache];
  [clearCachePool release];
  sched_yield();
}

- (void)mt_cache_4
{
  NSSet *regexCacheSet = [[RKRegex regexCache] cacheSet];
  regexCacheSet = nil;
  
  NSSet *sortedRegexCollectionCacheSet = [[objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache] cacheSet];
  sortedRegexCollectionCacheSet = NULL;

}

- (void)mt_cache_5
{
  NSParameterAssert(blacklistArray != NULL);
  @try {
  NSAutoreleasePool *clearCachePool = [[NSAutoreleasePool alloc] init];
  id rmObj = [objc_getClass("RKSortedRegexCollection") sortedRegexCollectionForCollection:blacklistArray];
  if(rmObj != NULL) { [[objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache] removeObjectFromCache:rmObj]; }
  [[objc_getClass("RKSortedRegexCollection") sortedRegexCollectionCache] clearCache];
  [clearCachePool release];
  sched_yield();
    } @catch (NSException *exception) { }
    
  RKRegex *regex = nil;
  
  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:RKCompileDupNames]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+(MAGIC)" options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) )" options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"http://www.google.com/this/neat/url/index.html" options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];

  STAssertNotNil((regex = [RKRegex regexWithRegexString:@"                http://www.google.com/this/neat/url/index.html                " options:0]), nil);
  [[RKRegex regexCache] removeObjectFromCache:regex];
}

- (void)mt_cache_6
{
  RKRegex *regex = nil;
  STAssertTrue((regex = [RKRegex regexWithRegexString:@"\\( ( ( ([^()];+) | (?R) )* ) \\)" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];
  
  STAssertTrue((regex = [RKRegex regexWithRegexString:@"\\( ( ( ([^()];+) | (?R) )* ) \\)" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.yahoo.com/this/neat/url/index.html" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.yahoo.com/this/neat/url/index.html" options:RKCompileDupNames]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.yahoo.com/this/neat/url/index.html" options:RKCompileUTF8]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.yahoo.com/this/neat/url/index.html" options:(RKCompileDupNames | RKCompileUTF8)]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];


  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.google.com/this/neat/url/index.html" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.google.com/this/neat/url/index.html" options:RKCompileDupNames]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.google.com/this/neat/url/index.html" options:RKCompileUTF8]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"http://www.google.com/this/neat/url/index.html" options:(RKCompileDupNames | RKCompileUTF8)]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];


  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.yahoo.com/this/neat/url/index.html                " options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.yahoo.com/this/neat/url/index.html                " options:RKCompileDupNames]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.yahoo.com/this/neat/url/index.html                " options:RKCompileUTF8]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.yahoo.com/this/neat/url/index.html                " options:(RKCompileDupNames | RKCompileUTF8)]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];


  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.google.com/this/neat/url/index.html                " options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.google.com/this/neat/url/index.html                " options:RKCompileDupNames]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.google.com/this/neat/url/index.html                " options:RKCompileUTF8]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"                http://www.google.com/this/neat/url/index.html                " options:(RKCompileDupNames | RKCompileUTF8)]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];


  STAssertTrue((regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()];+) | (?&pn) )* \\) )" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"\\( ( ( (?>[^()];+) | (?R) )* ) \\)" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"\\( ( ( (?>[^()];+) | (?R) )* ) \\)" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  STAssertTrue((regex = [RKRegex regexWithRegexString:@"\\( ( ( ([^()];+) | (?R) )* ) \\)" options:0]) != nil, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  regex = nil;
  STAssertThrowsSpecificNamed((regex = [RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+((MAGIC)$" options:0]), NSException, RKRegexSyntaxErrorException, nil);
  STAssertNil(regex, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];

  regex = nil;
  STAssertThrowsSpecificNamed((regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()];+) | (?&xq) )* \\) )" options:0]), NSException, RKRegexSyntaxErrorException, nil);
  STAssertNil(regex, nil);
  [[RKRegex regexCache] addObjectToCache:regex withHash:[regex hash]];
}


//- (void)testSimpleStringAdditions
- (void)mt_test_1
{
  NSString *subString0 = nil, *subString1 = nil, *subString2 = nil;
  NSString *subjectString = @"This web address, http://www.foad.org/no_way/it really/does/match/ is really neat!";
  //NSString *regexString = @"http://([^/]+)(/.*/)"; // Stupid xcode seems to choke on the last 3-4 characters when they're together. It looses it's indentation mind.
  NSString *regexString = [@"http://([^/]+)(/.*" stringByAppendingString:@"/)"];

#ifdef not_now
  NSArray *matchesArray = [subjectString stringsWithRegex:regexString];

  STAssertNotNil(matchesArray, nil);
  STAssertTrue([matchesArray count] == 3, nil);
  STAssertTrue([[matchesArray objectAtIndex:0] isEqualToString:@"http://www.foad.org/no_way/it really/does/match/"], nil);
  STAssertTrue([[matchesArray objectAtIndex:1] isEqualToString:@"www.foad.org"], nil);
  STAssertTrue([[matchesArray objectAtIndex:2] isEqualToString:@"/no_way/it really/does/match/"], nil);
#endif
  
  STAssertTrue(([subjectString getCapturesWithRegexAndReferences:regexString, @"${2}", &subString2, nil]) , nil ) ;
  STAssertTrue([subString2 isEqualToString:@"/no_way/it really/does/match/"], @"len %d %@ = '%s'", [subString2 length], subString2, [subString2 UTF8String]);

  NSString *namedSubjectString = @" 1999 - 12 - 01 / 55 ";
  NSString *namedRegexString = @"(?J)(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";
  NSString *subStringDate = nil, *subStringDay = nil, *subStringYear = nil;
  subString0 = nil, subString1 = nil, subString2 = nil;

#ifdef not_now  
  matchesArray = [namedSubjectString stringsWithRegex:namedRegexString];
  STAssertNotNil(matchesArray, nil);
  STAssertTrue([matchesArray count] == 7, nil);
  STAssertTrue([[matchesArray objectAtIndex:0] isEqualToString:@" 1999 - 12 - 01 / 55"], nil);
  STAssertTrue([[matchesArray objectAtIndex:1] isEqualToString:@" 1999 - 12 - 01 / 55"], nil);
  STAssertTrue([[matchesArray objectAtIndex:2] isEqualToString:@"1999"], nil);
  STAssertTrue([[matchesArray objectAtIndex:3] isEqualToString:@"19"], nil);
  STAssertTrue([[matchesArray objectAtIndex:4] isEqualToString:@"12"], nil);
  STAssertTrue([[matchesArray objectAtIndex:5] isEqualToString:@"01"], nil);
  STAssertTrue([[matchesArray objectAtIndex:6] isEqualToString:@"55"], nil);
#endif
  
  STAssertTrue(([namedSubjectString getCapturesWithRegexAndReferences:namedRegexString, @"${day}", &subStringDay, @"${date}", &subStringDate, @"${2}", &subString2, @"${1}", &subString1, @"${year}", &subStringYear, nil]), nil);

  STAssertTrue([subString1 isEqualToString:@" 1999 - 12 - 01 / 55"], nil);
  STAssertTrue([subString2 isEqualToString:@"1999"], nil);
  STAssertTrue([subStringDate isEqualToString:@" 1999 - 12 - 01 / 55"], @"got %@ %d", subStringDate, [subStringDate isEqualToString:@" 1999 - 12 - 01 / 55"]);
  STAssertTrue([subStringDay isEqualToString:@"01"], @"got %@ %d", subStringDay, [subStringDay isEqualToString:@"01"]);
  STAssertTrue([subStringYear isEqualToString:@"1999"], @"got %@ %d", subStringYear, [subStringYear isEqualToString:@"1999"]);
}


//- (void)testSimpleInit
- (void)mt_test_2
{
  NSAutoreleasePool *initPool = [[NSAutoreleasePool alloc] init];

  RKRegex *regex = nil;
  NSMutableSet *regexSet = [NSMutableSet set];

  STAssertNotNil(regex = [[[RKRegex alloc] initWithRegexString:@".* (\\w+) .*" options:0] autorelease], nil);
  [regexSet addObject:regex];
  STAssertThrowsSpecificNamed([[[RKRegex alloc] initWithRegexString:nil options:0] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKRegex alloc] initWithRegexString:@".* (\\w+) .*" options:0xffffffff] autorelease], NSException, RKRegexSyntaxErrorException, nil);
  
  STAssertNotNil(regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0], nil);
  [regexSet addObject:regex];
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:nil options:0], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:@".* (\\w+) .*" options:0xffffffff], NSException, RKRegexSyntaxErrorException, nil);
  
  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0];
  [regexSet addObject:regex];

  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames];
  [regexSet addObject:regex];

  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames];
  [regexSet addObject:regex];

  if([RKRegex PCREBuildConfig] & RKBuildConfigUTF8) {
    regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\W+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\W+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
  }
  
  [initPool release];
}

//- (void)testTrivialInitStringEncoding
- (void)mt_test_3
{
  // Copied from somewhere, converted to UTF8, french
  char utf8Ptr[] = {0x4c, 0x65, 0x20, 0x6d, 0xe2, 0x94, 0x9c, 0xc2, 0xac, 0x6d, 0x65, 0x20, 0x74, 0x65, 0x78, 0x74, 0x65, 0x20, 0x65, 0x6e, 0x20, 0x66, 0x72, 0x61, 0x6e, 0xe2, 0x94, 0x9c, 0xc2, 0xaf, 0x61, 0x69, 0x73, 0x00};
  NSString *initString = [NSString stringWithUTF8String:utf8Ptr];
  STAssertNotNil((id)initString, nil);
  
  RKRegex *regex = nil;
  STAssertNoThrow(regex = [RKRegex regexWithRegexString:(id)initString options:0], nil);
  STAssertNotNil(regex, nil);
}

//- (void)testBuildConfig
- (void)mt_test_4
{
  RKRegex *regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }

  RKBuildConfig regexBuildConfig = [RKRegex PCREBuildConfig];

  RKBuildConfig pcreBuildConfig = 0;
  RKCompileErrorCode initErrorCode = RKCompileErrorNoError;
  int tempConfigInt = 0;
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_UTF8, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  if(tempConfigInt == 1) { pcreBuildConfig |= RKBuildConfigUTF8; }
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_UNICODE_PROPERTIES, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  if(tempConfigInt == 1) { pcreBuildConfig |= RKBuildConfigUnicodeProperties; }
  
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_NEWLINE, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  switch(tempConfigInt) {
    case -1: pcreBuildConfig |= RKBuildConfigNewlineAny; break;
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 1
    case -2: pcreBuildConfig |= RKBuildConfigNewlineAnyCRLF; break;
#endif
    case 10: pcreBuildConfig |= RKBuildConfigNewlineLF; break;
    case 13: pcreBuildConfig |= RKBuildConfigNewlineCR; break;
    case 3338: pcreBuildConfig |= RKBuildConfigNewlineCRLF; break;
    default: STAssertTrue(tempConfigInt == tempConfigInt, @"Unknown new line configuration encountered. %u 0x%8.8x", tempConfigInt, tempConfigInt); break;
  }

#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 4
  STAssertTrue(((initErrorCode = pcre_config(PCRE_CONFIG_BSR, &tempConfigInt)) == RKMatchErrorNoError), @"initErrorCode = %d", initErrorCode);
  switch(tempConfigInt) {
    case 0:   pcreBuildConfig |= RKBuildConfigBackslashRUnicode; break;
    case 1:   pcreBuildConfig |= RKBuildConfigBackslashRAnyCRLR; break;
    default: STAssertTrue(1==0, @"Unknown PCRE_CONFIG_BSR encountered.  %u 0x%8.8x", tempConfigInt, tempConfigInt); break;
  }
#endif // >= 7.4
  
  STAssertTrue(pcreBuildConfig == regexBuildConfig, @"regex config: %u pcre config: %u", regexBuildConfig, pcreBuildConfig);
}

//- (void)testSimpleGetRanges
- (void)mt_test_5
{
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 3, @"captureCount is %u", captureCount); if(captureCount != 3) { return; }
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); }
  
  RKMatchErrorCode errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0];

  STAssertTrue(errorCode == 3, @"errorCode = %d", errorCode);
  
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 15), matchRanges[0]), @"matchRange[0] = %@", NSStringFromRange(matchRanges[0]));
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 5), matchRanges[1]), @"matchRange[1] = %@", NSStringFromRange(matchRanges[1]));
  STAssertTrue(NSEqualRanges(NSMakeRange(10, 5), matchRanges[2]), @"matchRange[2] = %@", NSStringFromRange(matchRanges[2]));
}


//- (void)testSimpleGetRangesNoMatch
- (void)mt_test_6
{
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)$";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }

  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 3, @"captureCount is %u", captureCount); if(captureCount != 3) { return; }

  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }

  RKMatchErrorCode errorCode = RKMatchErrorNoError;

  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); }
  errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0];
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
}

//- (void)testGetRangesExceptionsAndCornerCases
- (void)mt_test_7
{
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 3, @"captureCount is %u", captureCount); if(captureCount != 3) { return; }
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  RKMatchErrorCode errorCode = RKMatchErrorNoError;
  
  // First check if it works.
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0];
  STAssertTrue(errorCode == 3, @"errorCode = %d", errorCode);
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 15), matchRanges[0]), @"matchRange[0] = %@", NSStringFromRange(matchRanges[0]));
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 5), matchRanges[1]), @"matchRange[1] = %@", NSStringFromRange(matchRanges[1]));
  STAssertTrue(NSEqualRanges(NSMakeRange(10, 5), matchRanges[2]), @"matchRange[2] = %@", NSStringFromRange(matchRanges[2]));

  /// getRanges NULL
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:NULL withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }

  /// withCharacters NULL
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:NULL length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }

  /// Bad options
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0xffffffff], nil);
  STAssertTrue(errorCode == RKMatchErrorBadOption, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location exactly at the end of buffer, with a length of 0
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 0) options:0], nil);
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }

  /// inRange start location exactly at the end of buffer, with a length of 1
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 1) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location > buffer length
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength + 1, 1) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }

  /// inRange start location at one character before end of buffer, with a length of 2 exceeding buffer length
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength - 1, 2) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }

  /// inRange start location at one character before end of buffer, with a length of 1 within buffer
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength - 1, 1) options:0], nil);
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
}

//- (void)testSimpleCaptureNameException
- (void)mt_test_8
{
  NSString *regexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) )";
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];

  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:nil], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist"], NSException, RKRegexCaptureReferenceException, nil);
}
  
//- (void)testSimpleCaptureName
- (void)mt_test_9
{
  NSString *regexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) )";
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  STAssertTrue([regex captureCount] == 6, @"count: %u", [regex captureCount]);

  NSArray *regexCaptureNameArray = [regex captureNameArray];
  STAssertNotNil(regexCaptureNameArray, nil);
  STAssertTrue([regexCaptureNameArray count] == 6, @"count: %u", [regexCaptureNameArray count]);
  
  STAssertTrue([[regexCaptureNameArray objectAtIndex:0] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:0]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:1] isEqualToString:@"date"], @"== %@", [regexCaptureNameArray objectAtIndex:1]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:2] isEqualToString:@"year"], @"== %@", [regexCaptureNameArray objectAtIndex:2]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:3] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:3]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:4] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:4]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:5] isEqualToString:@"day"], @"== %@", [regexCaptureNameArray objectAtIndex:5]);

  STAssertTrue([regex captureIndexForCaptureName:@"date"] == 1, @"value: %u", [regex captureIndexForCaptureName:@"date"]);
  STAssertTrue([regex captureIndexForCaptureName:@"year"] == 2, @"value: %u", [regex captureIndexForCaptureName:@"year"]);
  STAssertTrue([regex captureIndexForCaptureName:@"month"] == 4, @"value: %u", [regex captureIndexForCaptureName:@"month"]);
  STAssertTrue([regex captureIndexForCaptureName:@"day"] == 5, @"value: %u", [regex captureIndexForCaptureName:@"day"]);

  STAssertThrows([regex captureIndexForCaptureName:@"UNKNOWN"], nil);
  STAssertThrows([regex captureIndexForCaptureName:nil], nil);
}

//- (void)testDupCaptureName
- (void)mt_test_10
{
  NSString *regexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";
  
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:regexString options:0], NSException, RKRegexSyntaxErrorException, nil); // needs to have dup names option
  
  RK_STRONG_REF RKRegex *regex = [RKRegex regexWithRegexString:regexString options:RKCompileDupNames];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  STAssertTrue([regex captureCount] == 7, @"count: %u", [regex captureCount]);

  RK_STRONG_REF NSArray *regexCaptureNameArray = [regex captureNameArray];
  STAssertNotNil(regexCaptureNameArray, nil);
  STAssertTrue([regexCaptureNameArray count] == 7, @"count: %u", [regexCaptureNameArray count]);
  
  STAssertTrue([[regexCaptureNameArray objectAtIndex:0] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:0]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:1] isEqualToString:@"date"], @"== %@", [regexCaptureNameArray objectAtIndex:1]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:2] isEqualToString:@"year"], @"== %@", [regexCaptureNameArray objectAtIndex:2]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:3] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:3]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:4] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:4]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:5] isEqualToString:@"day"], @"== %@", [regexCaptureNameArray objectAtIndex:5]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:6] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:6]);

  STAssertTrue([regex captureIndexForCaptureName:@"date"] == 1, @"value: %u", [regex captureIndexForCaptureName:@"date"]);
  STAssertTrue([regex captureIndexForCaptureName:@"year"] == 2, @"value: %u", [regex captureIndexForCaptureName:@"year"]);
  STAssertTrue([regex captureIndexForCaptureName:@"month"] == 4, @"value: %u", [regex captureIndexForCaptureName:@"month"]); // Only the lowest index is returned
  STAssertTrue([regex captureIndexForCaptureName:@"day"] == 5, @"value: %u", [regex captureIndexForCaptureName:@"day"]);
  
  STAssertThrows([regex captureIndexForCaptureName:@"UNKNOWN"], nil);
  STAssertThrows([regex captureIndexForCaptureName:nil], nil);
}

//- (void)testRegexString
- (void)mt_test_11
{
  RKRegex *regex = [RKRegex regexWithRegexString:@"123" options:0];
  STAssertTrue([[regex regexString] isEqualToString:@"123"], nil);
  regex = [RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+(MAGIC)$" options:0];
  STAssertTrue([[regex regexString] isEqualToString:@"^(Match)\\s+the\\s+(MAGIC)$"], nil);
}

//- (void)testValidRegexString
- (void)mt_test_12
{
  STAssertTrue([RKRegex isValidRegexString:@"123" options:0], nil);
  STAssertTrue([RKRegex isValidRegexString:@"^(Match)\\s+the\\s+(MAGIC)$" options:0], nil);
  
  STAssertTrue([RKRegex isValidRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:0], nil);
  STAssertTrue([RKRegex isValidRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:0], nil);
  STAssertTrue([RKRegex isValidRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:0], nil);
  STAssertTrue([RKRegex isValidRegexString:@"\\( ( ( ([^()]+) | (?R) )* ) \\)" options:0], nil);

  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+((MAGIC)$" options:0xffffffff], NSException, RKRegexSyntaxErrorException, nil);
  STAssertNoThrow([RKRegex isValidRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&xq) )* \\) )" options:0], nil);

  STAssertNoThrow([RKRegex isValidRegexString:nil options:0], nil);
  STAssertFalse([RKRegex isValidRegexString:nil options:0], nil);
  STAssertNoThrow([RKRegex isValidRegexString:@"\\( ( ( ([^()]+) | (?R) )* ) \\)" options:0xffffffff], nil);
  STAssertFalse([RKRegex isValidRegexString:@"\\( ( ( ([^()]+) | (?R) )* ) \\)" options:0xffffffff], nil);
}

//- (void)testSimpleMatches
- (void)mt_test_13
{
  STAssertTrue([@" 012345 " isMatchedByRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)]], nil);
  STAssertTrue([@" 012345 " isMatchedByRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(2, 3)], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(2, 3) options:0], nil);
  STAssertFalse([@" 012345 " isMatchedByRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(1, 2)], nil);
  STAssertFalse([@" 012345 " isMatchedByRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(3, 2)], nil);
  STAssertFalse([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(1, 2) options:0], nil);
  STAssertFalse([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(3, 2) options:0], nil);
  
  STAssertThrowsSpecificNamed([@" 012345 " isMatchedByRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(400, 16)], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(400, 16) options:0], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:" 012345 " length:0 inRange:NSMakeRange(0, 8) options:0], NSException, NSRangeException, nil);
  
  STAssertThrowsSpecificNamed([[RKRegex regexWithRegexString:@"123" options:0] matchesCharacters:NULL length:strlen(" 012345 ") inRange:NSMakeRange(400, 16) options:0], NSException, NSInvalidArgumentException, nil);
}

//- (void)testSimpleRangeForCharacters
- (void)mt_test_14
{
  NSRange matchRange = NSMakeRange(0, 0);
  
  STAssertTrue(NSEqualRanges((matchRange = [@" 012345 " rangeOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)]]), NSMakeRange(2, 3)), @"matchRange = %@", NSStringFromRange(matchRange));
  STAssertTrue(NSEqualRanges((matchRange = [@" 012345 " rangeOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(2, 3) capture:0]), NSMakeRange(2, 3)), @"matchRange = %@", NSStringFromRange(matchRange));
  
  STAssertTrue(NSEqualRanges((matchRange = [@" 012345 " rangeOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(1,2) capture:0]), NSMakeRange(NSNotFound, 0)), @"matchRange = %@", NSStringFromRange(matchRange));
  STAssertTrue(NSEqualRanges((matchRange = [@" 012345 " rangeOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(3,2) capture:0]), NSMakeRange(NSNotFound, 0)), @"matchRange = %@", NSStringFromRange(matchRange));
  
  STAssertThrowsSpecificNamed([@" 012345 " rangeOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(400, 16) capture:0], NSException, NSRangeException, nil);
  
  STAssertThrowsSpecificNamed([[RKRegex regexWithRegexString:@"123" options:0] rangeForCharacters:nil length:strlen(" 012345 ") inRange:NSMakeRange(400, 16) captureIndex:23 options:RKMatchNoOptions], NSException, NSInvalidArgumentException, nil);
}

//- (void)testSimpleRangesData
- (void)mt_test_15
{
  NSRange *matchRanges = NULL;
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [@" 012345 " rangesOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)]], nil);
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  STAssertTrue(NSEqualRanges(matchRanges[0], NSMakeRange(2, 3)), @"matchRanges[0] = %@", NSStringFromRange(matchRanges[0]));
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [@" 012345 " rangesOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(2, 3)], nil);
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  STAssertTrue(NSEqualRanges(matchRanges[0], NSMakeRange(2, 3)), @"matchRanges[0] = %@", NSStringFromRange(matchRanges[0]));
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(2, 3) options:0], nil);
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  STAssertTrue(NSEqualRanges(matchRanges[0], NSMakeRange(2, 3)), @"matchRanges[0] = %@", NSStringFromRange(matchRanges[0]));
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [@" 012345 " rangesOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(1, 2)], nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [@" 012345 " rangesOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(3, 2)], nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(1, 2) options:0], nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertNoThrow(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(3, 2) options:0], nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertThrowsSpecificNamed(matchRanges = [@" 012345 " rangesOfRegex:[RKRegex regexWithRegexString:@"123" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] inRange:NSMakeRange(400, 16)], NSException, NSRangeException, nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertThrowsSpecificNamed(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:" 012345 " length:strlen(" 012345 ") inRange:NSMakeRange(400, 16) options:0], NSException, NSRangeException, nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  matchRanges = NULL;
  STAssertThrowsSpecificNamed(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:" 012345 " length:0 inRange:NSMakeRange(0, 8) options:0], NSException, NSRangeException, nil);
  STAssertTrue(matchRanges == NULL, nil);
  
  
  matchRanges = NULL;
  STAssertThrowsSpecificNamed(matchRanges = [[RKRegex regexWithRegexString:@"123" options:0] rangesForCharacters:NULL length:strlen(" 012345 ") inRange:NSMakeRange(0, 8) options:0], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(matchRanges == NULL, nil);
}

- (void)mt_test_16
{
//Old range value tests.
}

//- (void)testCaptureReferenceBadSyntaxTests
- (void)mt_test_17
{
  NSString *subjectString = nil, *regexString = nil;//, *captureString = nil;
  int intType = 7;

  subjectString = @"12345";
  regexString = @"(\\d+)";

  STAssertTrue(intType == 7, nil);
  
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$1:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:d", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:d", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:%", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"2", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;

  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${a:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$a:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${a:d", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"a:d}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"a:", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"a", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;

  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:%}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$1:%}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:%}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:%", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:%", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;

  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:@}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$1:@}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:@}", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:@", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:@", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;

  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"1:@z", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;

  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"$$1:", &intType, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(intType == 7, @"int value is: %d", intType); intType = 7;
}

//- (void)testNumericCaptureReferenceConversionSimpleTests
- (void)mt_test_18
{
  NSString *subjectString = nil, *regexString = nil, *captureString = nil;
  int intType = 7;
  
  subjectString = @"12345";
  regexString = @"(\\d+)";
  
  STAssertTrue(intType == 7, nil);
  

  captureString = nil;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${zip:%d}", &captureString, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(captureString == nil, nil);
  
  STAssertNoThrow(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1:%d}", &intType, nil]), nil);
  STAssertTrue(intType == 12345, nil);
  
  captureString = nil;
  STAssertTrue(captureString == nil, nil);
  STAssertNoThrow(([subjectString getCapturesWithRegexAndReferences:regexString, @"${1}", &captureString, nil]), nil);
  STAssertTrue(captureString != nil, nil);
  STAssertTrue([captureString isEqualToString:@"12345"], nil);  
}

//- (void)testNamedCaptureReferenceConversionSimpleTests
- (void)mt_test_19
{
  NSString *subjectString = nil, *regexString = nil, *captureString = nil;
  int intType = 7;
  
  subjectString = @"12345";
  regexString = @"(?<num>\\d+)";
  
  STAssertTrue(intType == 7, nil);
  
  captureString = nil;
  STAssertThrowsSpecificNamed(([subjectString getCapturesWithRegexAndReferences:regexString, @"${zip:%d}", &captureString, nil]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(captureString == nil, nil);
  
  STAssertNoThrow(([subjectString getCapturesWithRegexAndReferences:regexString, @"${num:%d}", &intType, nil]), nil);
  STAssertTrue(intType == 12345, nil);
  
  captureString = nil;
  STAssertTrue(captureString == nil, nil);
  STAssertNoThrow(([subjectString getCapturesWithRegexAndReferences:regexString, @"${num}", &captureString, nil]), nil);
  STAssertTrue(captureString != nil, nil);
  STAssertTrue([captureString isEqualToString:@"12345"], nil);  
}

//- (void)testNumericCaptureReferenceNSNumberConversionSimpleTests
- (void)mt_test_20
{
  NSNumber *number1 = nil, *number2 = nil;
  
  STAssertNoThrow(([@"123, 456" getCapturesWithRegexAndReferences:@"(\\d+), (\\d+)", @"${1:@n}", &number1, @"${2:@n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"$123, 99.5%" getCapturesWithRegexAndReferences:@"([^,]*), (.*)", @"${1:@$n}", &number1, @"${2:@%n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"forty-two, 100,954,123.92" getCapturesWithRegexAndReferences:@"([^,]*), (.*)", @"${1:@wn}", &number1, @"${2:@.n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"2.657066311614524e+78, $5,917.23" getCapturesWithRegexAndReferences:@"([^,]*), (.*)", @"${1:@sn}", &number1, @"${2:@$n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
}

//- (void)testNamedCaptureReferenceNSNumberConversionSimpleTests
- (void)mt_test_21
{
  NSNumber *number1 = nil, *number2 = nil;
  
  STAssertNoThrow(([@"123, 456" getCapturesWithRegexAndReferences:@"(?<num1>\\d+), (?<num2>\\d+)", @"${num1:@n}", &number1, @"${num2:@n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"$123, 99.5%" getCapturesWithRegexAndReferences:@"(?<num1>[^,]*), (?<num2>.*)", @"${num1:@$n}", &number1, @"${num2:@%n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"forty-two, 100,954,123.92" getCapturesWithRegexAndReferences:@"(?<num1>[^,]*), (?<num2>.*)", @"${num1:@wn}", &number1, @"${num2:@.n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
  
  number1 = number2 = nil;
  STAssertNoThrow(([@"2.657066311614524e+78, $5,917.23" getCapturesWithRegexAndReferences:@"(?<num1>[^,]*), (?<num2>.*)", @"${num1:@sn}", &number1, @"${num2:@$n}", &number2, nil]), nil);
  STAssertTrue(number1 != nil, nil); STAssertTrue(number2 != nil, nil);
}


//- (void)testNumericCaptureReferenceNSDateFormatterConversionSimpleTests
- (void)mt_test_22
{
  id dateCapture = nil;
  
  STAssertNoThrow(([@"07/20/2007" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 7, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 20, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);
  STAssertTrue([dateCapture yearOfCommonEra] == 2007, [NSString stringWithFormat:@"yearOfCommonEra == %d object ='%@'", [dateCapture yearOfCommonEra], dateCapture]);
  
  dateCapture = nil;
  STAssertNoThrow(([@"6:44 PM" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture hourOfDay] == 18, [NSString stringWithFormat:@"hourOfDay == %d object = '%@'", [dateCapture hourOfDay], dateCapture]);
  STAssertTrue([dateCapture minuteOfHour] == 44, [NSString stringWithFormat:@"minuteOfHour == %d object ='%@'", [dateCapture minuteOfHour], dateCapture]);
  
  dateCapture = nil;
  STAssertNoThrow(([@"Feb 5th" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 2, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 5, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);

  dateCapture = nil;
  STAssertNoThrow(([@"6/20/2007, 11:34PM EDT" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 6, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 20, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);
  STAssertTrue([dateCapture yearOfCommonEra] == 2007, [NSString stringWithFormat:@"yearOfCommonEra == %d object ='%@'", [dateCapture yearOfCommonEra], dateCapture]);
  STAssertTrue([dateCapture hourOfDay] == 23, [NSString stringWithFormat:@"hourOfDay == %d object ='%@'", [dateCapture hourOfDay], dateCapture]);
  STAssertTrue([dateCapture minuteOfHour] == 34, [NSString stringWithFormat:@"minuteOfHour == %d object ='%@'", [dateCapture minuteOfHour], dateCapture]);
  STAssertTrue([[dateCapture timeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"EDT"]] == YES, [NSString stringWithFormat:@"timeZone name: %@, abbreviation: %@", [[dateCapture timeZone] name], [[dateCapture timeZone] abbreviation]]);
}

//- (void)testNamedCaptureReferenceNSDateFormatterConversionSimpleTests
- (void)mt_test_23
{
  id dateCapture = nil;
  
  STAssertNoThrow(([@"07/20/2007" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 7, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 20, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);
  STAssertTrue([dateCapture yearOfCommonEra] == 2007, [NSString stringWithFormat:@"yearOfCommonEra == %d object ='%@'", [dateCapture yearOfCommonEra], dateCapture]);
  
  dateCapture = nil;
  STAssertNoThrow(([@"6:44 PM" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture hourOfDay] == 18, [NSString stringWithFormat:@"hourOfDay == %d object = '%@'", [dateCapture hourOfDay], dateCapture]);
  STAssertTrue([dateCapture minuteOfHour] == 44, [NSString stringWithFormat:@"minuteOfHour == %d object ='%@'", [dateCapture minuteOfHour], dateCapture]);
  
  dateCapture = nil;
  STAssertNoThrow(([@"Feb 5th" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 2, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 5, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);
  
  dateCapture = nil;
  STAssertNoThrow(([@"6/20/2007, 11:34PM EDT" getCapturesWithRegexAndReferences:@"(.*)", @"${1:@d}", &dateCapture, nil]), nil);
  STAssertTrue(dateCapture != nil, nil);
  STAssertTrue([dateCapture monthOfYear] == 6, [NSString stringWithFormat:@"monthOfYear == %d object ='%@'", [dateCapture monthOfYear], dateCapture]);
  STAssertTrue([dateCapture dayOfMonth] == 20, [NSString stringWithFormat:@"dayOfMonth == %d object ='%@'", [dateCapture dayOfMonth], dateCapture]);
  STAssertTrue([dateCapture yearOfCommonEra] == 2007, [NSString stringWithFormat:@"yearOfCommonEra == %d object ='%@'", [dateCapture yearOfCommonEra], dateCapture]);
  STAssertTrue([dateCapture hourOfDay] == 23, [NSString stringWithFormat:@"hourOfDay == %d object ='%@'", [dateCapture hourOfDay], dateCapture]);
  STAssertTrue([dateCapture minuteOfHour] == 34, [NSString stringWithFormat:@"minuteOfHour == %d object ='%@'", [dateCapture minuteOfHour], dateCapture]);
  STAssertTrue([[dateCapture timeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"EDT"]] == YES, [NSString stringWithFormat:@"timeZone name: %@, abbreviation: %@", [[dateCapture timeZone] name], [[dateCapture timeZone] abbreviation]]);
}

#if defined(__i386__)
#warning Test mt_test_24 is disable on x86 architectures as it crashes the compiler
- (void)mt_test_24 { }
#endif

#ifndef __i386__

//- (void)testArrayExtensions
- (void)mt_test_24
{
  NSArray *testArray = NULL, *matchedArray = NULL;
  NSMutableArray *mutableArray = NULL;

  STAssertTrueNoThrow((testArray = [NSArray arrayWithObjects:@"zero 0 aaa", @"one 1 aab", @"two 2 ab", @"three 3 bab", @"four 4 aba ", @"five 5 baa", @"six 6 bbb", nil]) != NULL, nil);
    
    
  STAssertTrueNoThrow((matchedArray = [testArray arrayByMatchingObjectsWithRegex:@"ab"]) != NULL, nil);
  //ab array     : ("one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ")
  STAssertTrue([matchedArray count] == 4, @"Count is %u", [matchedArray count]);
  STAssertTrue([[matchedArray objectAtIndex:0] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:1] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:2] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:3] isEqualToString:@"four 4 aba "], nil);

  STAssertTrueNoThrow((matchedArray = [testArray arrayByMatchingObjectsWithRegex:@"aa"]) != NULL, nil);
  //aa array     : ("zero 0 aaa",  "one 1 aab",   "five 5 baa")
  STAssertTrue([matchedArray count] == 3, @"Count is %u", [matchedArray count]);
  STAssertTrue([[matchedArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[matchedArray objectAtIndex:1] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:2] isEqualToString:@"five 5 baa"], nil);  

  STAssertTrueNoThrow((matchedArray = [testArray arrayByMatchingObjectsWithRegex:@"ba"]) != NULL, nil);
  //ba array     : ("three 3 bab", "four 4 aba ", "five 5 baa")
  STAssertTrue([matchedArray count] == 3, @"Count is %u", [matchedArray count]);
  STAssertTrue([[matchedArray objectAtIndex:0] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:1] isEqualToString:@"four 4 aba "], nil);
  STAssertTrue([[matchedArray objectAtIndex:2] isEqualToString:@"five 5 baa"], nil);
  

  STAssertTrueNoThrow((matchedArray = [testArray arrayByMatchingObjectsWithRegex:@"o"]) != NULL, nil);
  //o array      : ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "four 4 aba ")
  STAssertTrue([matchedArray count] == 4, @"Count is %u", [matchedArray count]);
  STAssertTrue([[matchedArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[matchedArray objectAtIndex:1] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:2] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:3] isEqualToString:@"four 4 aba "], nil);
  
  STAssertTrueNoThrow((matchedArray = [testArray arrayByMatchingObjectsWithRegex:@"2|4|6"]) != NULL, nil);
  //2|4|6 array  : ("two 2 ab",    "four 4 aba ", "six 6 bbb")
  STAssertTrue([matchedArray count] == 3, @"Count is %u", [matchedArray count]);
  STAssertTrue([[matchedArray objectAtIndex:0] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[matchedArray objectAtIndex:1] isEqualToString:@"four 4 aba "], nil);
  STAssertTrue([[matchedArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);
  
    
  
  STAssertTrueNoThrow((mutableArray = [NSMutableArray arrayWithArray:testArray]) != NULL, nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb")
  STAssertTrue([mutableArray count] == 7, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:3] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:4] isEqualToString:@"four 4 aba "], nil);
  STAssertTrue([[mutableArray objectAtIndex:5] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:6] isEqualToString:@"six 6 bbb"], nil);
  

  STAssertNoThrow([mutableArray addObjectsFromArray:testArray matchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb", "one 1 aab", "two 2 ab", "three 3 bab", "four 4 aba ")
  STAssertTrue([mutableArray count] == 11, @"Count is %u", [mutableArray count]);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"ab"] == 8, @"Count == %u", [mutableArray countOfObjectsMatchingRegex:@"ab"]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:3] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:4] isEqualToString:@"four 4 aba "], nil);
  STAssertTrue([[mutableArray objectAtIndex:5] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:6] isEqualToString:@"six 6 bbb"], nil);
  STAssertTrue([[mutableArray objectAtIndex:7] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:8] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:9] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:10] isEqualToString:@"four 4 aba "], nil);
  
  STAssertTrueNoThrow([mutableArray indexOfObjectMatchingRegex:@"^four"] == 4, @"Index is %u", [mutableArray indexOfObjectMatchingRegex:@"^four"]);
  STAssertTrueNoThrow([mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(3, 7)] == 4, @"Index is %u", [mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(3, 7)]);
  STAssertTrueNoThrow([mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(5, 5)] == NSNotFound, @"Index is %u", [mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(5, 5)]);
  STAssertTrueNoThrow([mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(5, 6)] == 10, @"Index is %u", [mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(5, 6)]);
  STAssertThrowsSpecificNamed([mutableArray indexOfObjectMatchingRegex:@"^four" inRange:NSMakeRange(5, 7)], NSException, NSRangeException, nil);


  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^four"] == 2, @"Count is %u", [mutableArray countOfObjectsMatchingRegex:@"^four"]);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(3, 8)] == 2, @"Count is %u", [mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(3, 8)]);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(4, 7)] == 2, @"Count is %u", [mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(4, 7)]);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(5, 6)] == 1, @"Count is %u", [mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(5, 6)]);
  STAssertThrowsSpecificNamed([mutableArray countOfObjectsMatchingRegex:@"^four" inRange:NSMakeRange(5, 7)], NSException, NSRangeException, nil);


  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"ab" inRange:NSMakeRange(3, 5)] == 3, @"Count == %u", [mutableArray countOfObjectsMatchingRegex:@"ab" inRange:NSMakeRange(3, 5)]);
  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@"ab" inRange:NSMakeRange(3, 5)], nil);
  // mutable array: ("zero 0 aaa", "one 1 aab", "two 2 ab", "five 5 baa", "six 6 bbb", "two 2 ab", "three 3 bab", "four 4 aba ")
  STAssertTrue([mutableArray count] == 8, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"one 1 aab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:3] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:4] isEqualToString:@"six 6 bbb"], nil);
  STAssertTrue([[mutableArray objectAtIndex:5] isEqualToString:@"two 2 ab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:6] isEqualToString:@"three 3 bab"], nil);
  STAssertTrue([[mutableArray objectAtIndex:7] isEqualToString:@"four 4 aba "], nil);
  
  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb")
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  // Same thing, should remain the same.
  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb")
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertThrowsSpecificNamed([mutableArray containsObjectMatchingRegex:@"ab" inRange:NSMakeRange(23,42)], NSException, NSRangeException, nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertThrowsSpecificNamed([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(13, 17)], NSException, NSRangeException, nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(0, 0)], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(1, 0)], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(2, 0)], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertNoThrow([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(3, 0)], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);

  STAssertNoThrow([mutableArray removeObjectsInRange:NSMakeRange(3, 0)], nil);
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);
  
  STAssertThrowsSpecificNamed([mutableArray removeObjectsMatchingRegex:@".*" inRange:NSMakeRange(4, 0)], NSException, NSRangeException, nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb") 
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([[mutableArray objectAtIndex:0] isEqualToString:@"zero 0 aaa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:1] isEqualToString:@"five 5 baa"], nil);
  STAssertTrue([[mutableArray objectAtIndex:2] isEqualToString:@"six 6 bbb"], nil);
  
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"(?:a|b)" inRange:NSMakeRange(1, 1)] == 1, nil);

  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^(?:five|six)" inRange:NSMakeRange(0, 2)] == 1, nil);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^(?:five|six)" inRange:NSMakeRange(1, 2)] == 2, nil);
  STAssertThrowsSpecificNamed([mutableArray removeObjectsMatchingRegex:@"^(?:five|six)" inRange:NSMakeRange(2, 2)], NSException, NSRangeException, nil);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^(?:five|six)" inRange:NSMakeRange(2, 1)] == 1, nil);
  STAssertTrueNoThrow([mutableArray countOfObjectsMatchingRegex:@"^(?:five|six)" inRange:NSMakeRange(0, 3)] == 2, nil);

  
  STAssertTrueNoThrow((matchedArray = [mutableArray arrayByMatchingObjectsWithRegex:@"I don't wanna match"]) != NULL, nil);
  STAssertTrue([mutableArray count] == 3, @"Count is %u", [mutableArray count]);
  STAssertTrue([matchedArray count] == 0, @"Count is %u", [matchedArray count]);

  STAssertThrowsSpecificNamed([mutableArray removeObjectsMatchingRegex:NULL inRange:NSMakeRange(0, 1)], NSException, NSInvalidArgumentException, nil);

}

#endif

#if defined(__i386__)
#warning Test mt_test_25 is disable on x86 architectures as it crashes the compiler
- (void)mt_test_25 { }
#endif

#ifndef __i386__
//- (void)testDictionaryExtensions
- (void)mt_test_25
{
  NSMutableDictionary *testDict = [NSMutableDictionary dictionary];
  NSDictionary *regexDictionary = NULL, *staticDictionary = NULL;
  NSArray *testObjects = NULL, *regexObjects = NULL;
  
  STAssertNotNil(testDict, nil);
  [testDict setObject:[NSNumber numberWithInt:0] forKey:@"zero aaa"];
  [testDict setObject:[NSNumber numberWithInt:1] forKey:@"one aab"];
  [testDict setObject:[NSNumber numberWithInt:2] forKey:@"two aba"];
  [testDict setObject:[NSNumber numberWithInt:3] forKey:@"three baa"];
  [testDict setObject:[NSNumber numberWithInt:4] forKey:@"four bab"];  
  STAssertTrue([testDict count] == 5, @"Count = %u", [testDict count]);

  STAssertTrueNoThrow((staticDictionary = [NSDictionary dictionaryWithDictionary:testDict]) != NULL, nil);

  STAssertTrueNoThrow((regexDictionary = [testDict dictionaryByMatchingKeysWithRegex:@"No! They're stealing my regex!"]) != NULL, nil);
  STAssertTrue([regexDictionary count] == 0, @"Count = %u", [regexDictionary count]);


  STAssertTrueNoThrow((regexDictionary = [testDict dictionaryByMatchingKeysWithRegex:@".*"]) != NULL, nil);
  STAssertTrue([regexDictionary count] == 5, @"Count = %u", [regexDictionary count]);
  STAssertTrueNoThrow((regexObjects = [regexDictionary allKeys]) != NULL, nil);
  STAssertTrue([regexObjects containsObject:@"zero aaa"], nil);
  STAssertTrue([regexObjects containsObject:@"one aab"], nil);
  STAssertTrue([regexObjects containsObject:@"two aba"], nil);
  STAssertTrue([regexObjects containsObject:@"three baa"], nil);
  STAssertTrue([regexObjects containsObject:@"four bab"], nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary allValues]) != NULL, nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:4]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"zero aaa"] isEqualToNumber:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"one aab"] isEqualToNumber:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"two aba"] isEqualToNumber:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"three baa"] isEqualToNumber:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"four bab"] isEqualToNumber:[NSNumber numberWithInt:4]], nil);

  STAssertTrueNoThrow((regexDictionary = [testDict dictionaryByMatchingObjectsWithRegex:@".*"]) != NULL, nil);
  STAssertTrue([regexDictionary count] == 5, @"Count = %u", [regexDictionary count]);
  STAssertTrueNoThrow((regexObjects = [regexDictionary allKeys]) != NULL, nil);
  STAssertTrue([regexObjects containsObject:@"zero aaa"], nil);
  STAssertTrue([regexObjects containsObject:@"one aab"], nil);
  STAssertTrue([regexObjects containsObject:@"two aba"], nil);
  STAssertTrue([regexObjects containsObject:@"three baa"], nil);
  STAssertTrue([regexObjects containsObject:@"four bab"], nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary allValues]) != NULL, nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:4]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"zero aaa"] isEqualToNumber:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"one aab"] isEqualToNumber:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"two aba"] isEqualToNumber:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"three baa"] isEqualToNumber:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"four bab"] isEqualToNumber:[NSNumber numberWithInt:4]], nil);
  
  
  
  STAssertTrueNoThrow((regexDictionary = [testDict dictionaryByMatchingObjectsWithRegex:@"1|3|4"]) != NULL, nil);
  STAssertTrue([regexDictionary count] == 3, @"Count = %u", [regexDictionary count]);
  STAssertTrue([[regexDictionary allKeys] containsObject:@"one aab"], nil);
  STAssertTrue([[regexDictionary allKeys] containsObject:@"three baa"], nil);
  STAssertTrue([[regexDictionary allKeys] containsObject:@"four bab"], nil);
  STAssertTrue([[regexDictionary allValues] containsObject:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([[regexDictionary allValues] containsObject:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([[regexDictionary allValues] containsObject:[NSNumber numberWithInt:4]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"one aab"] isEqualToNumber:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"three baa"] isEqualToNumber:[NSNumber numberWithInt:3]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"four bab"] isEqualToNumber:[NSNumber numberWithInt:4]], nil);


  STAssertTrueNoThrow((testObjects = [testDict objectsMatchingRegex:@"2|3"]) != NULL, nil);
  STAssertTrue([testObjects count] == 2, @"Count = %u", [testObjects count]);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:3]], nil);

  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"0|2"] == NO, nil);
  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"0|1|2"] == YES, nil);
  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"0|1"] == YES, nil);
  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"1|2"] == YES, nil);
  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"0"] == NO, nil);
  STAssertTrue([regexDictionary containsObjectMatchingRegex:@"3"] == YES, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary objectsMatchingRegex:@"0|1|2"]) != NULL, nil);
  STAssertTrue([regexObjects count] == 1, @"Count = %u", [regexObjects count]);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:1]], nil);
  


  STAssertTrueNoThrow((testObjects = [testDict objectsForKeysMatchingRegex:@"o a"]) != NULL, nil);
  STAssertTrue([testObjects count] == 2, @"Count = %u", [regexObjects count]);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:2]], nil);

  STAssertTrueNoThrow((testObjects = [testDict objectsMatchingRegex:@"CantMatchThis"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary objectsMatchingRegex:@"CanTooMatchThat"]) != NULL, nil);
  STAssertTrue([testObjects count] == 0, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 0, @"Count = %u", [regexObjects count]);
  
  STAssertTrueNoThrow((regexDictionary = [testDict dictionaryByMatchingKeysWithRegex:@"o a"]) != NULL, nil);
  STAssertTrue([regexDictionary count] == 2, @"Count = %u", [regexDictionary count]);
  STAssertTrue([[regexDictionary allKeys] containsObject:@"zero aaa"], nil);
  STAssertTrue([[regexDictionary allKeys] containsObject:@"two aba"], nil);
  STAssertTrue([[regexDictionary allValues] containsObject:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([[regexDictionary allValues] containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"zero aaa"] isEqualToNumber:[NSNumber numberWithInt:0]], nil);
  STAssertTrue([[regexDictionary objectForKey:@"two aba"] isEqualToNumber:[NSNumber numberWithInt:2]], nil);
  
  STAssertTrueNoThrow([testDict containsKeyMatchingRegex:@"aaa"], nil);
  STAssertTrueNoThrow([regexDictionary containsKeyMatchingRegex:@"aaa"], nil);
  STAssertTrueNoThrow([testDict containsKeyMatchingRegex:@"aab"], nil);
  STAssertFalseNoThrow([regexDictionary containsKeyMatchingRegex:@"aab"], nil);
  

  STAssertTrueNoThrow((testObjects = [testDict keysMatchingRegex:@"CantMatchThis"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary keysMatchingRegex:@"CanTooMatchThat"]) != NULL, nil);
  STAssertTrue([testObjects count] == 0, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 0, @"Count = %u", [regexObjects count]);
  
  

  STAssertTrueNoThrow((testObjects = [testDict keysMatchingRegex:@".*"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary keysMatchingRegex:@".*"]) != NULL, nil);
  STAssertTrue([testObjects count] == 5, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 2, @"Count = %u", [regexObjects count]);
  STAssertTrue([testObjects containsObject:@"zero aaa"], nil);
  STAssertTrue([testObjects containsObject:@"one aab"], nil);
  STAssertTrue([testObjects containsObject:@"two aba"], nil);
  STAssertTrue([testObjects containsObject:@"three baa"], nil);
  STAssertTrue([testObjects containsObject:@"four bab"], nil);
  STAssertTrue([regexObjects containsObject:@"zero aaa"], nil);
  STAssertTrue([regexObjects containsObject:@"two aba"], nil);
  

  STAssertTrueNoThrow((testObjects = [testDict keysMatchingRegex:@"ba"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary keysMatchingRegex:@"ba"]) != NULL, nil);
  STAssertTrue([testObjects count] == 3, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 1, @"Count = %u", [regexObjects count]);
  STAssertTrue([testObjects containsObject:@"two aba"], nil);
  STAssertTrue([testObjects containsObject:@"three baa"], nil);
  STAssertTrue([testObjects containsObject:@"four bab"], nil);
  STAssertTrue([regexObjects containsObject:@"two aba"], nil);
  

  STAssertTrueNoThrow((testObjects = [testDict objectsForKeysMatchingRegex:@"ab"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary objectsForKeysMatchingRegex:@"ab"]) != NULL, nil);
  STAssertTrue([testObjects count] == 3, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 1, @"Count = %u", [regexObjects count]);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:1]], nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:4]], nil);
  STAssertTrue([regexObjects containsObject:[NSNumber numberWithInt:2]], nil);


  STAssertTrueNoThrow((testObjects = [testDict objectsForKeysMatchingRegex:@"bab"]) != NULL, nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary objectsForKeysMatchingRegex:@"bab"]) != NULL, nil);
  STAssertTrue([testObjects count] == 1, @"Count = %u", [testObjects count]);
  STAssertTrue([regexObjects count] == 0, @"Count = %u", [regexObjects count]);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:4]], nil);
 

  STAssertNotNil((regexDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"five aca", [NSNumber numberWithInt:6], @"six dad", nil]), nil);
  STAssertTrue([regexDictionary count] == 2, nil);

  STAssertTrue([testDict count] == 5, nil);
  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withKeysMatchingRegex:@"^six"], nil);
  STAssertTrue([testDict count] == 6, nil);
  STAssertTrue([regexDictionary count] == 2, nil);

  STAssertTrueNoThrow((testObjects = [testDict objectsForKeysMatchingRegex:@"dad$"]) != NULL, nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:6]], nil);
  

  STAssertNoThrow([testDict removeObjectsForKeysMatchingRegex:@"^(\\w+)\\s+(?:a|b)a(?:a|b)$"], nil);
  STAssertTrue([testDict count] == 2, nil);
  

  STAssertTrueNoThrow((testObjects = [testDict objectsForKeysMatchingRegex:@"^(\\w+)\\s+([abd]{3})"]) != NULL, nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:2]], nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:6]], nil);


  STAssertThrowsSpecificNamed([testDict objectsForKeysMatchingRegex:@"^(\\w+)(?\\s+)([abd]{3})"], NSException, RKRegexSyntaxErrorException, nil);


  STAssertThrows([(NSMutableDictionary *)regexDictionary removeObjectsForKeysMatchingRegex:@"e a"], nil);
  STAssertThrows([(NSMutableDictionary *)regexDictionary addEntriesFromDictionary:testDict withKeysMatchingRegex:@".*"], nil);

  STAssertNotNil((regexDictionary = [NSDictionary dictionary]), nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary objectsForKeysMatchingRegex:@"^No Match I!$"]) != NULL, nil);
  STAssertTrue([regexObjects count] == 0, nil);

  STAssertNotNil((regexDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"five aca", [NSNumber numberWithInt:6], @"six dad", nil]), nil);
  STAssertTrue([regexDictionary count] == 2, nil);
  STAssertNotNil((testDict = [NSMutableDictionary dictionary]), nil);
  STAssertTrue([testDict count] == 0, nil);

  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withKeysMatchingRegex:@"^No Match I!$"], nil);
  STAssertTrue([testDict count] == 0, nil);
  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withObjectsMatchingRegex:@"^No Match I!$"], nil);
  STAssertTrue([testDict count] == 0, nil);

  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withKeysMatchingRegex:@".*"], nil);
  STAssertTrue([testDict count] == 2, nil);

  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withKeysMatchingRegex:@".*"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);

  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withKeysMatchingRegex:@"^six"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);

  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withKeysMatchingRegex:@"^six"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);

  STAssertNotNil((testDict = [NSMutableDictionary dictionary]), nil);
  STAssertTrue([testDict count] == 0, nil);

  STAssertNotNil((regexDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"five aca", [NSNumber numberWithInt:6], @"six dad", nil]), nil);
  STAssertTrue([regexDictionary count] == 2, nil);
  STAssertNoThrow([testDict setDictionary:staticDictionary], nil);
  STAssertTrue([testDict count] == 5, nil);


  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withObjectsMatchingRegex:@"6\\d*"], nil);
  STAssertTrue([testDict count] == 6, nil);
  STAssertTrue([regexDictionary count] == 2, nil);
  
  STAssertTrueNoThrow((testObjects = [testDict objectsMatchingRegex:@"\\d*6"]) != NULL, nil);
  STAssertTrue([testObjects containsObject:[NSNumber numberWithInt:6]], nil);
  
  
  STAssertNoThrow([testDict removeObjectsMatchingRegex:@"^[^26]*$"], nil);
  STAssertTrue([testDict count] == 2, nil);
  
  
  STAssertTrueNoThrow((testObjects = [testDict keysForObjectsMatchingRegex:@"\\d*[26]\\d*"]) != NULL, nil);
  STAssertTrue([testObjects containsObject:@"two aba"], nil);
  STAssertTrue([testObjects containsObject:@"six dad"], nil);
  
  
  STAssertThrowsSpecificNamed([testDict keysForObjectsMatchingRegex:@"^(\\d+)(\\S*)(?[246]{3})"], NSException, RKRegexSyntaxErrorException, nil);
  
  
  STAssertThrows([(NSMutableDictionary *)regexDictionary removeObjectsMatchingRegex:@"\\d+"], nil);
  STAssertThrows([(NSMutableDictionary *)regexDictionary addEntriesFromDictionary:testDict withObjectsMatchingRegex:@".*"], nil);
  
  STAssertNotNil((regexDictionary = [NSDictionary dictionary]), nil);
  STAssertTrueNoThrow((regexObjects = [regexDictionary keysForObjectsMatchingRegex:@"^No Match You!$"]) != NULL, nil);
  STAssertTrue([regexObjects count] == 0, nil);


  STAssertNoThrow([testDict removeObjectsMatchingRegex:@"\\d+"], nil);
  STAssertTrue([testDict count] == 0, nil);
  STAssertNotNil((regexDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"five aca", [NSNumber numberWithInt:6], @"six dad", nil]), nil);
  STAssertTrue([regexDictionary count] == 2, nil);


  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withKeysMatchingRegex:@"^No Match Zuul!$"], nil);
  STAssertTrue([testDict count] == 0, nil);
  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withObjectsMatchingRegex:@"^No Match Zuul\\?$"], nil);
  STAssertTrue([testDict count] == 0, nil);
  
  STAssertNoThrow([testDict addEntriesFromDictionary:regexDictionary withKeysMatchingRegex:@".*"], nil);
  STAssertTrue([testDict count] == 2, nil);
  
  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withObjectsMatchingRegex:@".*"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);
  
  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withObjectsMatchingRegex:@"\\d+"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);
  
  STAssertNoThrow([testDict addEntriesFromDictionary:testDict withObjectsMatchingRegex:@"6\\d*"], nil);
  STAssertTrue([testDict count] == 2, @"Count is %u", [testDict count]);
  
}

#endif


//- (void)testSetExtensions
- (void)mt_test_26
{
  NSSet *testSet = NULL, *matchedSet = NULL;
  NSMutableSet *mutableSet = NULL;
  
  STAssertTrueNoThrow((testSet = [NSSet setWithObjects:@"zero 0 aaa", @"one 1 aab", @"two 2 ab", @"three 3 bab", @"four 4 aba ", @"five 5 baa", @"six 6 bbb", nil]) != NULL, nil);
  
  
  STAssertTrueNoThrow((matchedSet = [testSet setByMatchingObjectsWithRegex:@"ab"]) != NULL, nil);
  //ab array     : ("one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ")
  STAssertTrue([matchedSet count] == 4, @"Count is %u", [matchedSet count]);
  STAssertTrue([matchedSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([matchedSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([matchedSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([matchedSet containsObject:@"four 4 aba "], nil);
  
  STAssertTrueNoThrow((matchedSet = [testSet setByMatchingObjectsWithRegex:@"aa"]) != NULL, nil);
  //aa array     : ("zero 0 aaa",  "one 1 aab",   "five 5 baa")
  STAssertTrue([matchedSet count] == 3, @"Count is %u", [matchedSet count]);
  STAssertTrue([matchedSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([matchedSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([matchedSet containsObject:@"five 5 baa"], nil);  
  
  STAssertTrueNoThrow((matchedSet = [testSet setByMatchingObjectsWithRegex:@"ba"]) != NULL, nil);
  //ba array     : ("three 3 bab", "four 4 aba ", "five 5 baa")
  STAssertTrue([matchedSet count] == 3, @"Count is %u", [matchedSet count]);
  STAssertTrue([matchedSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([matchedSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([matchedSet containsObject:@"five 5 baa"], nil);
  
  
  STAssertTrueNoThrow((matchedSet = [testSet setByMatchingObjectsWithRegex:@"o"]) != NULL, nil);
  //o array      : ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "four 4 aba ")
  STAssertTrue([matchedSet count] == 4, @"Count is %u", [matchedSet count]);
  STAssertTrue([matchedSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([matchedSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([matchedSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([matchedSet containsObject:@"four 4 aba "], nil);
  
  STAssertTrueNoThrow((matchedSet = [testSet setByMatchingObjectsWithRegex:@"2|4|6"]) != NULL, nil);
  //2|4|6 array  : ("two 2 ab",    "four 4 aba ", "six 6 bbb")
  STAssertTrue([matchedSet count] == 3, @"Count is %u", [matchedSet count]);
  STAssertTrue([matchedSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([matchedSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([matchedSet containsObject:@"six 6 bbb"], nil);
  
  
  
  STAssertTrueNoThrow((mutableSet = [NSMutableSet setWithSet:testSet]) != NULL, nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb")
  STAssertTrue([mutableSet count] == 7, @"Count is %u", [mutableSet count]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([mutableSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([mutableSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([mutableSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  
  
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ab"] == 4, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ab"]);
  STAssertNoThrow([mutableSet addObjectsFromSet:testSet matchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb"
  STAssertTrue([mutableSet count] == 7, @"Count is %u", [mutableSet count]);
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ab"] == 4, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ab"]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([mutableSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([mutableSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([mutableSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);

  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ba"] == 3, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ba"]);
  STAssertNoThrow([mutableSet addObjectsFromArray:[testSet allObjects] matchingRegex:@"ba"], nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb"
  STAssertTrue([mutableSet count] == 7, @"Count is %u", [mutableSet count]);
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ba"] == 3, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ba"]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([mutableSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([mutableSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([mutableSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"^four"] == 1, @"Count is %u", [mutableSet countOfObjectsMatchingRegex:@"^four"]);  
    
  STAssertNoThrow([mutableSet removeObjectsMatchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb")
  STAssertTrue([mutableSet count] == 3, @"Count is %u", [mutableSet count]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  
  // Same thing, should remain the same.
  STAssertNoThrow([mutableSet removeObjectsMatchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb")
  STAssertTrue([mutableSet count] == 3, @"Count is %u", [mutableSet count]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);


  // Add it back in...
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ab"] == 0, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ab"]);
  STAssertNoThrow([mutableSet addObjectsFromSet:testSet matchingRegex:@"(b|a)"], nil);
  //mutable array: ("zero 0 aaa",  "one 1 aab",   "two 2 ab",    "three 3 bab", "four 4 aba ", "five 5 baa", "six 6 bbb"
  STAssertTrue([mutableSet count] == 7, @"Count is %u", [mutableSet count]);
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ab"] == 4, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ab"]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"one 1 aab"], nil);
  STAssertTrue([mutableSet containsObject:@"two 2 ab"], nil);
  STAssertTrue([mutableSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([mutableSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  

  // Remove and try with an array
  STAssertNoThrow([mutableSet removeObjectsMatchingRegex:@"ab"], nil);
  //mutable array: ("zero 0 aaa",  "five 5 baa",  "six 6 bbb")
  STAssertTrue([mutableSet count] == 3, @"Count is %u", [mutableSet count]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ba"] == 1, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ba"]);
  STAssertNoThrow([mutableSet addObjectsFromArray:[testSet allObjects] matchingRegex:@"ba"], nil);
  //mutable set: (five 5 baa, six 6 bbb, three 3 bab, zero 0 aaa, four 4 aba )
  STAssertTrue([mutableSet count] == 5, @"Count is %u", [mutableSet count]);
  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"ba"] == 3, @"Count == %u", [mutableSet countOfObjectsMatchingRegex:@"ba"]);
  STAssertTrue([mutableSet containsObject:@"zero 0 aaa"], nil);
  STAssertTrue([mutableSet containsObject:@"three 3 bab"], nil);
  STAssertTrue([mutableSet containsObject:@"four 4 aba "], nil);
  STAssertTrue([mutableSet containsObject:@"five 5 baa"], nil);
  STAssertTrue([mutableSet containsObject:@"six 6 bbb"], nil);
  


  STAssertTrueNoThrow((matchedSet = [mutableSet setByMatchingObjectsWithRegex:@"I don't wanna match"]) != NULL, nil);
  STAssertTrue([mutableSet count] == 5, @"Count is %u", [mutableSet count]);
  STAssertTrue([matchedSet count] == 0, @"Count is %u", [matchedSet count]);
  
  STAssertThrowsSpecificNamed([mutableSet addObjectsFromArray:NULL matchingRegex:@".*"], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([mutableSet addObjectsFromSet:NULL matchingRegex:@".*"], NSException, NSInvalidArgumentException, nil);

  STAssertThrowsSpecificNamed([mutableSet addObjectsFromArray:[testSet allObjects] matchingRegex:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([mutableSet addObjectsFromSet:testSet matchingRegex:NULL], NSException, NSInvalidArgumentException, nil);

  STAssertThrowsSpecificNamed([mutableSet removeObjectsMatchingRegex:NULL], NSException, NSInvalidArgumentException, nil);


  STAssertTrueNoThrow([mutableSet countOfObjectsMatchingRegex:@"I don't wanna match"] == 0, nil);
  STAssertTrueNoThrow([mutableSet containsObjectMatchingRegex:@"\\s\\d\\s"] == YES, nil);
  STAssertTrueNoThrow([mutableSet containsObjectMatchingRegex:@"No more matching!"] == NO, nil);
  STAssertTrueNoThrow([mutableSet anyObjectMatchingRegex:@"\\s\\d\\s"] != NULL, nil);
  STAssertTrueNoThrow([mutableSet anyObjectMatchingRegex:@"^Really! I've had enough of your pattern matching (ways|plays)!$"] == NULL, nil);
  
}

#if defined(__i386__)
#warning Test mt_test_27 is disable on x86 architectures as it crashes the compiler
- (void)mt_test_27 { }
#endif

#ifndef __i386__

//- (void)testRKEnumeratorInit
- (void)mt_test_27
{
  NSAutoreleasePool *tempPool = NULL;
  RKEnumerator *enumerator = NULL;
  NSString *subjectString = @"  blarg   You think?  Nope.. ";
  
  STAssertTrueNoThrow((enumerator = [[[RKEnumerator alloc] initWithRegex:@"\\s*\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length])] autorelease]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  tempPool = [[NSAutoreleasePool alloc] init];
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [[RKEnumerator alloc] initWithRegex:[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)] string:subjectString]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  [tempPool release]; tempPool = NULL;
  [enumerator autorelease];
  STAssertFalse([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] isEqual:[enumerator regex]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileDupNames | RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [[[RKEnumerator alloc] initWithRegex:@"\\s*\\S+\\s+" string:subjectString] autorelease]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length])]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s+" string:subjectString]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{1,6}\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length] + 1)] autorelease], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s*\\S{3}\\s+" string:subjectString inRange:NSMakeRange([subjectString length] + 1, 100)] autorelease], NSException, NSRangeException, nil);
  
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s{9,}" string:subjectString inRange:NSMakeRange(2, [subjectString length] + 3)], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s{3,}\\S+\\s+" string:subjectString inRange:NSMakeRange([subjectString length] - 2, 61)], NSException, NSRangeException, nil);
  
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{1,6}\\S+\\s+" string:NULL inRange:NSMakeRange(0, [subjectString length])] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{6,12}\\S+\\s+" string:NULL] autorelease], NSException, NSInvalidArgumentException, nil);
  
  
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s{9,}" string:NULL inRange:NSMakeRange(0, [subjectString length])], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S{4,5}\\s{9,}" string:NULL], NSException, NSInvalidArgumentException, nil);
  
  
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:NULL string:subjectString inRange:NSMakeRange(0, [subjectString length])] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:NULL string:subjectString] autorelease], NSException, NSInvalidArgumentException, nil);
  
  
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:NULL string:subjectString inRange:NSMakeRange(0, [subjectString length])], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:NULL string:subjectString], NSException, NSInvalidArgumentException, nil);
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [subjectString matchEnumeratorWithRegex:@"\\s{5}\\S+?\\s?" inRange:NSMakeRange(0, [subjectString length])]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s{5}\\S+?\\s?" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [subjectString matchEnumeratorWithRegex:@"\\s{6}\\S+?\\s?"]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s{6}\\S+?\\s?" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);
  
  
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:@"\\s{7}\\S+?\\s?" inRange:NSMakeRange(0, [subjectString length] + 1)], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:@"\\s{8}\\S+?\\s?" inRange:NSMakeRange([subjectString length], 1)], NSException, NSRangeException, nil);
  
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:NULL inRange:NSMakeRange(2, [subjectString length] + 1)], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:NULL], NSException, NSInvalidArgumentException, nil);
}

#endif













//- (void)testZInitSimpleTiming
- (BOOL)mt_time_1
{
  unsigned int x = 0;

  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [[RKRegex alloc] initWithRegexString:@".* (\\w+) .*" options:0];
    STAssertNotNil(regex, nil);
    [regex release];
    [loopPool release];
  }
  return(NO);
}

//- (void)testZConvienenceInitSimpleTiming
- (BOOL)mt_time_2
{
  unsigned int x = 0;
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    STAssertNotNil([RKRegex regexWithRegexString:@".* (\\w+) .*" options:0], nil);
    [loopPool release];
  }
  return(NO);
}

//- (void)testZStringAdditionsNoNamedCapturesSimpleTiming
- (BOOL)mt_time_3
{
  unsigned int x = 0;
  
  NSString *namedSubjectString = @" 1999 - 12 - 01 / 55 ";
  NSString *namedRegexString = @"(?J)(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    
    NSString *subString0 = nil, *subString1 = nil, *subString2 = nil, *subString3 = nil, *subString4 = nil;
    STAssertTrue(([namedSubjectString getCapturesWithRegexAndReferences:namedRegexString, @"${2}", &subString2, @"${4}", &subString4, @"${1}", &subString1, @"${0}", &subString0, @"${3}", &subString3, nil] == YES), nil);
    STAssertNotNil(subString0, nil);
    STAssertNotNil(subString1, nil);
    STAssertNotNil(subString2, nil);
    STAssertNotNil(subString3, nil);
    STAssertNotNil(subString4, nil);
    [loopPool release];
  }
  return(NO);
}


//- (void)testZStringAdditionsHeavyNamedCaptureSimpleTiming
- (BOOL)mt_time_4
{
  unsigned int x = 0;
  
  NSString *namedSubjectString = @" 1999 - 12 - 01 / 55 ";
  NSString *namedRegexString = @"(?J)(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";

  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];

    NSString *subStringDate = nil, *subStringDay = nil, *subStringYear = nil;
    NSString /**subString0 = @"$0",*/ *subString1 = nil, *subString2 = nil;
    STAssertTrue(([namedSubjectString getCapturesWithRegexAndReferences:namedRegexString, @"${day}", &subStringDay, @"${date}", &subStringDate, @"${2}", &subString2, @"${1}", &subString1, @"${year}", &subStringYear, nil] == YES), nil);

    STAssertNotNil(subStringDate, nil);
    STAssertNotNil(subStringYear, nil);
    STAssertNotNil(subStringDay, nil);
    STAssertNotNil(subString1, nil);
    STAssertNotNil(subString2, nil);

    [loopPool release];
  }
  return(NO);
}

//- (void)testZInitWithCaptureNamesTiming
- (BOOL)mt_time_5
{
  unsigned int x = 0;
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [[RKRegex alloc] initWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:RKCompileDupNames];
    STAssertNotNil(regex, nil);
    [regex release];
    [loopPool release];
  }
  return(NO);
}

//- (void)testZConvienceInitWithCaptureNamesTiming
- (BOOL)mt_time_6
{
  unsigned int x = 0;
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:RKCompileDupNames];
    STAssertNotNil(regex, nil);
    [loopPool release];
  }
  return(NO);
}

//- (void)testZrangesForTiming
- (BOOL)mt_time_7
{
  unsigned int x = 0;
  NSString *subjectString = @" 1999 - 12 - 01 / 55 ";

  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)];
    NSRange *ranges = [subjectString rangesOfRegex:regex];
    STAssertNotNil(regex, nil);
    STAssertTrue(ranges != NULL, nil);
    [loopPool release];
  }
  return(NO);
}


//- (void)testZPCRERKRegexEquivTiming
- (BOOL)mt_time_8
{
  unsigned int x = 0;
  
  const char *subjectCharacters = " 1999 - 12 - 01 / 55 ";
  RKInteger subjectLength = strlen(subjectCharacters);
  NSRange subjectRange = NSMakeRange(0, subjectLength);
  NSRange matchRanges[4096];

  RKRegex *regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:RKCompileDupNames];
  sched_yield();
  STAssertNotNil(regex, nil);
  if(regex == nil) { return(YES); }
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    [regex getRanges:&matchRanges[0] withCharacters:subjectCharacters length:subjectLength inRange:subjectRange options:0];
    [loopPool release];
  }
  return(NO);
}


//- (void)testZPCREbaseCaptureNameTiming
- (BOOL)mt_time_9
{
  unsigned int x = 0;
  const char *subjectCharacters = " 1999 - 12 - 01 / 55 ";
  RKInteger subjectLength = strlen(subjectCharacters);
  const char *regexCharacters = "(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";

  BOOL returnValue = NO;
  
  int ovectors[4096];
  void *_compiledPCRE = NULL;
  void *_extraPCRE = NULL;
  

  int compileErrorOffset = 0;
  const char *errorCharPtr = NULL;
  RKCompileErrorCode initErrorCode = RKCompileErrorNoError;
  RKMatchErrorCode matchErrorCode = RKMatchErrorNoError;
  
  _compiledPCRE = pcre_compile2(regexCharacters, RKCompileDupNames, (int *)&initErrorCode, &errorCharPtr, &compileErrorOffset, NULL);
  if((initErrorCode != RKCompileErrorNoError) || (_compiledPCRE == NULL)) { returnValue = YES; goto exitNow; }
  
  _extraPCRE = pcre_study(_compiledPCRE, 0, &errorCharPtr);
  if((_extraPCRE == NULL) && (errorCharPtr != NULL)) { returnValue = YES; goto exitNow; }
  
  for(x = 0; x < iterations; x++) {
    matchErrorCode = (RKMatchErrorCode)pcre_exec(_compiledPCRE, _extraPCRE, subjectCharacters, subjectLength, 0, 0, &ovectors[0], 256);
    if(matchErrorCode <= 0) { returnValue = YES; goto exitNow; }
  }
  
exitNow:
    if(_compiledPCRE) { pcre_free(_compiledPCRE); _compiledPCRE = NULL; }
  sched_yield();
  if(_extraPCRE) { pcre_free(_extraPCRE); _extraPCRE = NULL; }
  sched_yield();
  return(returnValue);
}

//- (void)testZrangesForNoMatchTiming
- (BOOL)mt_time_10
{
  unsigned int x = 0;
  NSString *subjectString = @" 1999 - 12 - 01 / ab ";

  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [RKRegex regexWithRegexString:@"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)];
    NSRange *ranges = [subjectString rangesOfRegex:regex];
    STAssertNotNil(regex, nil);
    STAssertTrue(ranges == NULL, nil);
    [loopPool release];
  }
  return(NO);
}

//- (void)testZSimplerangesForTiming
- (BOOL)mt_time_11
{
  unsigned int x = 0;
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";

  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    RKRegex *regex = [RKRegex regexWithRegexString:regexString options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)];
    NSRange *ranges = [subjectString rangesOfRegex:regex];
    STAssertNotNil(regex, nil);
    STAssertTrue(ranges != NULL, nil);
    [loopPool release];
  }
  return(NO);
}


- (BOOL)mt_time_12
{
  unsigned int x = 0;
  
  NSString *namedSubjectString = @" 1999 - 12 - 01 / 55 ";
  NSString *namedRegexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<monthb>\\d\\d))";
  
  for(x = 0; x < iterations; x++) {
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    
    NSString *subString0 = nil, *subString1 = nil, *subString2 = nil, *subString3 = nil, *subString4 = nil;
    STAssertTrue(([namedSubjectString getCapturesWithRegexAndReferences:namedRegexString, @"${2}", &subString2, @"${4}", &subString4, @"${1}", &subString1, @"${0}", &subString0, @"${3}", &subString3, nil] == YES), nil);
    [[RKRegex regexCache] removeObjectFromCache:[[[RKRegex alloc] initWithRegexString:namedRegexString options:RKCompileDupNames] autorelease]];
    STAssertNotNil(subString0, nil);
    STAssertNotNil(subString1, nil);
    STAssertNotNil(subString2, nil);
    STAssertNotNil(subString3, nil);
    STAssertNotNil(subString4, nil);
    [loopPool release];
  }
  return(NO);
}














- (void)mt_sortedRegex_bl1
{
  return;
  //for(RKUInteger x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:blacklistArray]; } }
  NSString *URLString = NULL;
  NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
  
  while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:blacklistArray]; }
}

- (void)mt_sortedRegex_bl2
{
  return;
  NSArray *localBlacklistArray = [[[NSArray alloc] initWithArray:blacklistArray copyItems:YES] autorelease];
  //for(RKUInteger x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:localBlacklistArray]; } }
  NSString *URLString = NULL;
  NSEnumerator *urlArrayEnumerator = [localBlacklistArray objectEnumerator];
  
  while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:blacklistArray]; }
}

- (void)mt_sortedRegex_wl1
{
  //return;
  //for(RKUInteger x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:whitelistArray]; } }
  NSString *URLString = NULL;
  NSEnumerator *urlArrayEnumerator = [urlArray objectEnumerator];
  
  while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:whitelistArray]; }  
}

- (void)mt_sortedRegex_wl2
{
  //return;
  NSArray *localWhitelistArray = [[[NSArray alloc] initWithArray:whitelistArray copyItems:YES] autorelease];
  //for(RKUInteger x = 0; x < 1; x++) { for(id URLString in urlArray) { [URLString isMatchedByAnyRegexInArray:localWhitelistArray]; } }
  NSString *URLString = NULL;
  NSEnumerator *urlArrayEnumerator = [localWhitelistArray objectEnumerator];
  
  while((URLString = [urlArrayEnumerator nextObject]) != NULL) { [URLString isMatchedByAnyRegexInArray:localWhitelistArray]; }
}



@end
