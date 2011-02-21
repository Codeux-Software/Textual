//
//  RKThreadPool.m
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

#import <RegexKit/RegexKitPrivate.h>
#import <RegexKit/RKThreadPool.h>

// Used to provide lockBefore: NSDate timeIntervalSinceNow: time delays to locks.
// These are 1.0/prime, jobQueueDelays prime < 100, threadStartDelays > 100
// This is to help break up any inter-lock / scheduling synchronization modes.
// Many kernel scheduling methods tend to have a quantum that is % 100, so this stradles that heurestic.

static double jobQueueDelays[3]    = {0.0120481927710843, 0.0112359550561797, 0.0103092783505154};
static double threadStartDelays[5] = {0.0099009900990099, 0.0097087378640776, 0.0093457943925233, 0.0091743119266055, 0.0088495575221238};

static id defaultThreadPoolSingleton = NULL;
static RKUInteger threadPoolIsMultiThreaded = 0;

#if       defined(__MACOSX_RUNTIME__) || (__FreeBSD__ >= 5)

static RKUInteger cpuCores                = 0;
static RKUInteger activeCPUCores          = 0;
#ifdef    __MACOSX_RUNTIME__
static time_t     lastActiveCPUCoresCheck = 0;
#endif // __MACOSX_RUNTIME__

static void updateCPUCounts(void) {
  size_t sysctlUIntSize = sizeof(unsigned int);
  unsigned int sysctlUInt = 0;
  
  if(RK_EXPECTED(cpuCores == 0, 0)) { if(sysctlbyname("hw.ncpu", &sysctlUInt, &sysctlUIntSize, NULL, 0) == 0) { cpuCores = sysctlUInt; } }

  if(cpuCores > 1) {
#ifdef    __MACOSX_RUNTIME__
    time_t thisActiveCPUCoresCheck = time(NULL);
    if((thisActiveCPUCoresCheck - lastActiveCPUCoresCheck) > 5) {
      lastActiveCPUCoresCheck = thisActiveCPUCoresCheck;
      if(sysctlbyname("hw.activecpu", &sysctlUInt, &sysctlUIntSize, NULL, 0) != 0) { sysctlUInt = (unsigned int)cpuCores; }
    }
#endif // __MACOSX_RUNTIME__
  }
  activeCPUCores = sysctlUInt;
}

#else  // !defined(__MACOSX_RUNTIME__) && (__FreeBSD__ < 5)

static RKUInteger cpuCores       = 2;
static RKUInteger activeCPUCores = 2;
#define updateCPUCounts()

#endif // defined(__MACOSX_RUNTIME__) || (__FreeBSD__ >= 5)

@implementation RKThreadPool

+ (id)defaultThreadPool
{
  id currentDefaultThreadPoolSingleton = defaultThreadPoolSingleton;
  BOOL cocoaIsMultiThreaded = [NSThread isMultiThreaded];
  
  if(RK_EXPECTED(threadPoolIsMultiThreaded == 0, 0) && RK_EXPECTED(cocoaIsMultiThreaded == YES, 1) && (currentDefaultThreadPoolSingleton != NULL)) {
    if(RKAtomicCompareAndSwapPtr(currentDefaultThreadPoolSingleton, NULL, &defaultThreadPoolSingleton)) {
      [currentDefaultThreadPoolSingleton reapThreads];
      RKAutorelease(currentDefaultThreadPoolSingleton);
    }
    currentDefaultThreadPoolSingleton = NULL;
  }
  
  if(RK_EXPECTED(currentDefaultThreadPoolSingleton == NULL, 0)) {
    updateCPUCounts();
    threadPoolIsMultiThreaded = (cocoaIsMultiThreaded == NO) ? 0 : 1;
    RKThreadPool *tempThreadPoolSingleton = RKAutorelease([[self alloc] initWithThreadCount:((cocoaIsMultiThreaded == NO) || (cpuCores == 1)) ? 0 : cpuCores error:NULL]);

    // The thread yields allow the detached threads to execute and initialize before any attempts are made to hand jobs off to them.
    // Otherwise threadFunction:argument: might find that there are no threads ready and print a warning message.  This is harmless because it falls back to
    // executing the task inline, but yielding prevents the warning message from appearing.
    if(RKAtomicCompareAndSwapPtr(NULL, tempThreadPoolSingleton, &defaultThreadPoolSingleton)) { RKRetain(defaultThreadPoolSingleton); RKThreadYield(); RKThreadYield(); }
    currentDefaultThreadPoolSingleton = defaultThreadPoolSingleton;
  }

  return(currentDefaultThreadPoolSingleton);
}


- (id)initWithThreadCount:(RKUInteger)initThreadCount error:(NSError **)error
{
  if(error != NULL) { *error = NULL; }
  BOOL        outOfMemoryError = NO, unableToAllocateObjectError = NO;
  NSError    *initError        = NULL;
  RKUInteger  objectsCount     = 0;
  id         *objects          = NULL;
  
  if((self = [self init]) == NULL) { unableToAllocateObjectError = YES; goto errorExit; }
  RKAutorelease(self);

  if((threadPoolIsMultiThreaded = ([NSThread isMultiThreaded] == NO) ? 0 : 1) == 0) { initThreadCount = 0; }
  
  if(initThreadCount > 0) {
    if((objects     = alloca(sizeof(id) * (initThreadCount * 3)))                      == NULL) { outOfMemoryError = YES; goto errorExit; }
    
    if((threads     = RKCallocScanned(   sizeof(NSThread *)        * initThreadCount)) == NULL) { outOfMemoryError = YES; goto errorExit; }
    if((locks       = RKCallocScanned(   sizeof(RKConditionLock *) * initThreadCount)) == NULL) { outOfMemoryError = YES; goto errorExit; }
    if((jobs        = RKCallocScanned(   sizeof(RKThreadPoolJob)   * initThreadCount)) == NULL) { outOfMemoryError = YES; goto errorExit; }
    if((threadQueue = RKCallocScanned(   sizeof(RKThreadPoolJob *) * initThreadCount)) == NULL) { outOfMemoryError = YES; goto errorExit; }
    
    for(unsigned int atThread = 0; atThread < initThreadCount; atThread++) {
      if((locks[atThread]        = RKAutorelease([[RKConditionLock alloc] initWithCondition:RKThreadConditionStarting])) == NULL) { unableToAllocateObjectError = YES; goto errorExit; }
      objects[objectsCount++]    = locks[atThread];
      
      if((jobs[atThread].jobLock = RKAutorelease([[RKConditionLock alloc] initWithCondition:RKJobConditionAvailable]))   == NULL) { unableToAllocateObjectError = YES; goto errorExit; }
      objects[objectsCount++]    = jobs[atThread].jobLock;
      
      [NSThread detachNewThreadSelector:@selector(workerThreadStart:) toTarget:self withObject:[NSNumber numberWithUnsignedInt:atThread]];
      threadCount++;
    }

    NSParameterAssert(objectsCount < (initThreadCount * 3));
    objectsArray = [[NSArray alloc] initWithObjects:&objects[0] count:objectsCount];
  }

  return(RKRetain(self));
  
errorExit:
  if((initError == NULL) && (unableToAllocateObjectError == YES))  { initError = [NSError rkErrorWithDomain:NSCocoaErrorDomain code:0 localizeDescription:@"Unable to allocate object."]; }
  if((initError == NULL) && (outOfMemoryError            == YES))  { initError = [NSError rkErrorWithDomain:NSPOSIXErrorDomain code:0 localizeDescription:@"Unable to allocate memory."]; }
  if((initError != NULL) && (error                       != NULL)) { *error    = initError; }
  return(NULL);
}

- (void)reapThreads
{
  RKAtomicCompareAndSwapInteger(0, RKThreadPoolStop, &threadPoolControl);
  while(liveThreads != 0) { for(RKUInteger x = 0; x < threadCount; x++) { [self wakeThread:x]; RKThreadYield(); } }
  RKAtomicCompareAndSwapInteger(RKThreadPoolStop, (RKThreadPoolStop & RKThreadPoolThreadsReaped), &threadPoolControl);
}

- (void)dealloc
{
  [self reapThreads];
  NSParameterAssert(liveThreads == 0);
  
  if(objectsArray  != NULL) { RKRelease(objectsArray);      }
  if(threads       != NULL) { RKFreeAndNULL(threads);       }
  if(locks         != NULL) { RKFreeAndNULL(locks);         }
  if(jobs          != NULL) { RKFreeAndNULL(jobs);          }
  if(threadQueue   != NULL) { RKFreeAndNULL(threadQueue);   }
  
  [super dealloc];
}

#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
- (void)finalize
{
  [self reapThreads];
  NSParameterAssert(liveThreads == 0);
  
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

- (NSString *)description
{
  return(RKLocalizedFormat(@"<%@: %p> CPU Count = %lu, Active CPUs = %lu, Multithreaded = %@, Threads in pool = %lu of %lu", [self className], self, (RKUInteger)cpuCores, (RKUInteger)activeCPUCores, RKYesOrNo(threadPoolIsMultiThreaded), liveThreads, threadCount));
}

- (BOOL)wakeThread:(RKUInteger)threadNumber
{
  if(threadNumber > threadCount) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"The threadNumber argument is greater than the total threads in the pool."] raise]; return(NO); }

  BOOL didWake = NO;
  if((didWake = RKFastConditionLock(locks[threadNumber], NULL, 0, RKConditionLockTryAnyConditionRelativeTime, 0.5)) == YES) {
    RKFastConditionUnlock(locks[threadNumber], NULL, [locks[threadNumber] condition], RKConditionUnlockAndWakeAll);
  }

  return(didWake);
}

- (BOOL)threadFunction:(int(*)(void *))function argument:(void *)argument
{ 
  updateCPUCounts();
  
  if((cpuCores == 1) || (activeCPUCores == 1) || (threadCount == 0) || (liveThreads == 0) || (threadPoolIsMultiThreaded == 0)) { function(argument); return(YES); }

  RKUInteger startedJobThreads = 0, jobQueueDelayIndex = 0, threadStartDelayIndex = 0;
  
  RK_STRONG_REF RKThreadPoolJob *runJob = NULL;

  while(RK_EXPECTED(runJob == NULL, 1) && RK_EXPECTED(((threadPoolControl & RKThreadPoolStop) == 0), 1) && RK_EXPECTED(liveThreads > 0, 1)) {
    for(RKUInteger threadNumber = 0; threadNumber < threadCount; threadNumber++) {
      if(RKFastConditionLock(jobs[threadNumber].jobLock, NULL, RKJobConditionAvailable, (jobQueueDelayIndex == 0) ? RKConditionLockTryWhenCondition : RKConditionLockTryWhenConditionRelativeTime, jobQueueDelays[(jobQueueDelayIndex > 0) ? jobQueueDelayIndex - 1 : 0])) { runJob = &jobs[threadNumber]; break; }
    }
    jobQueueDelayIndex = (jobQueueDelayIndex < 3) ? (jobQueueDelayIndex + 1) : 0;
  }

  if(RK_EXPECTED(runJob == NULL, 0)) {
#ifndef   NS_BLOCK_ASSERTIONS
    static BOOL didPrint = NO;
    if(didPrint == NO) { NSLog(@"Odd, unable to acquire a job queue slot. Executing function in-line."); didPrint = YES; }
#endif // NS_BLOCK_ASSERTIONS
    function(argument);
    return(YES);
  }
  
  NSParameterAssert(runJob->activeThreadsCount                == 0);
  NSParameterAssert([runJob->jobLock condition]               == RKJobConditionAvailable);
  NSParameterAssert([runJob->jobLock isLockedByCurrentThread] == YES);
  NSParameterAssert(runJob->jobFunction                       == NULL);
  NSParameterAssert(runJob->jobArgument                       == NULL);
  NSParameterAssert(threadPoolIsMultiThreaded                 == 1);
  NSParameterAssert(liveThreads                               >  0);
  
  runJob->jobFunction = function;
  runJob->jobArgument = argument;
  RKFastConditionUnlock(runJob->jobLock, NULL, RKJobConditionExecuting, RKConditionUnlockAndWakeAll);
  
  while(RK_EXPECTED([runJob->jobLock condition] == RKJobConditionExecuting, 1) && RK_EXPECTED(startedJobThreads < liveThreads, 1) && RK_EXPECTED((threadPoolControl & RKThreadPoolStop) == 0, 1)) {
    for(RKUInteger threadNumber = 0; ((threadNumber < threadCount) && ([runJob->jobLock condition] == RKJobConditionExecuting)); threadNumber++) {
      if(RKFastConditionLock(locks[threadNumber], NULL, RKThreadConditionSleeping, (threadStartDelayIndex == 0) ? RKConditionLockTryWhenCondition : RKConditionLockTryWhenConditionRelativeTime, threadStartDelays[(threadStartDelayIndex > 0) ? threadStartDelayIndex - 1 : 0]) == YES) {
        if([runJob->jobLock condition] == RKJobConditionExecuting) {
          threadQueue[threadNumber] = runJob;
          RKFastConditionUnlock(locks[threadNumber], NULL, RKThreadConditionWakeup,     RKConditionUnlockAndWakeAll);
          RKFastConditionLock(  locks[threadNumber], NULL, RKThreadConditionAwake,      RKConditionLockWhenCondition, 0.0);
          RKFastConditionUnlock(locks[threadNumber], NULL, RKThreadConditionRunningJob, RKConditionUnlockAndWakeAll);
          startedJobThreads++;
          if(startedJobThreads >= liveThreads) { goto exitLoop; }
        } else {
          RKFastConditionUnlock(locks[threadNumber], NULL, RKThreadConditionSleeping,   RKConditionUnlockAndWakeAll);
        }
      }
    }
    threadStartDelayIndex = (threadStartDelayIndex < 5) ? (threadStartDelayIndex + 1) : 0;
  }

exitLoop:
  if(RK_EXPECTED(startedJobThreads == 0, 0)) {
#ifndef   NS_BLOCK_ASSERTIONS
    static BOOL didPrint = NO;
    if(didPrint == NO) { NSLog(@"Odd, no job threads were started. Executing function in-line. liveThreads: %d active threads: %d jobLock: %@", liveThreads, runJob->activeThreadsCount, runJob->jobLock); didPrint = YES; }
#endif // NS_BLOCK_ASSERTIONS
    function(argument);
    if(RKFastConditionLock(runJob->jobLock, NULL, 0, RKConditionLockTryAnyCondition, 0.0) == NO) { [[NSException rkException:NSInternalInconsistencyException localizeReason:@"Unable to acquire thread run job lock."] raise]; }
  } else {
    RKFastConditionLock(runJob->jobLock, NULL, RKJobConditionCompleted, RKConditionLockWhenCondition, 0.0);
  }
  NSParameterAssert(startedJobThreads > 0);
  NSParameterAssert(runJob->activeThreadsCount == 0);
  runJob->jobFunction = NULL;
  runJob->jobArgument = NULL;
  RKFastConditionUnlock(runJob->jobLock, NULL, RKJobConditionAvailable, RKConditionUnlockAndWakeAll);

  return(YES);
}

- (void)workerThreadStart:(id)startObject
{
  NSAutoreleasePool             *topThreadPool = [[NSAutoreleasePool alloc] init], *loopThreadPool = NULL;
  unsigned int                   threadNumber  = 0;
  NSThread                      *thisThread    = NULL;
  RKThreadPoolJob RK_STRONG_REF *currentJob    = NULL;
  RKConditionLock               *threadLock    = NULL;
  
  if(startObject == NULL) { goto exitThreadNow; }
  RKAutorelease(startObject);
  
  threadNumber          = [startObject unsignedIntValue];
  thisThread            = [NSThread currentThread];
  threads[threadNumber] = thisThread;
  threadLock            = locks[threadNumber];
  
#if       MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 && defined(THREAD_AFFINITY_POLICY)
  // Since we start a number of threads equal to the number of CPU's, give each thread a seperate CPU affinity if running on Mac OS X 10.5 or later.
  if(NSFoundationVersionNumber >= 677.0) {
    thread_affinity_policy_data_t threadAffinityPolicy;
    memset(&threadAffinityPolicy, 0, sizeof(thread_affinity_policy_data_t));
    threadAffinityPolicy.affinity_tag = (threadNumber + 1);

    kern_return_t kernalReturn = thread_policy_set(mach_thread_self(), THREAD_AFFINITY_POLICY, (integer_t *) &threadAffinityPolicy, THREAD_AFFINITY_POLICY_COUNT);
    if(kernalReturn != KERN_SUCCESS) { NSLog(@"Unable to set the threads CPU affinity.  thread_policy_set returned %d.", kernalReturn); }
  }
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 && defined(THREAD_AFFINITY_POLICY)
  
  RKAtomicIncrementIntegerBarrier(&liveThreads);
  
  if(RKFastConditionLock(threadLock, NULL, RKThreadConditionStarting, RKConditionLockWhenCondition, 0.0) == NO) { NSLog(@"Unknown start up lock state, %ld.", (long)[threadLock condition]); goto exitThread; }
  
  RKFastConditionUnlock(threadLock, NULL, RKThreadConditionSleeping, RKConditionUnlockAndWakeAll);

  while(RK_EXPECTED((threadPoolControl & RKThreadPoolStop) == 0, 1)) {
    if(RK_EXPECTED(loopThreadPool == NULL, 1) && RK_EXPECTED(RKRegexGarbageCollect == 0, 1)) { loopThreadPool = [[NSAutoreleasePool alloc] init]; }

    RKFastConditionLock(threadLock, NULL, RKThreadConditionWakeup, RKConditionLockWhenCondition, 0.0);
    
    if(RK_EXPECTED((threadPoolControl & RKThreadPoolStop) != 0, 0)) { break; } // Check if we're exiting.
    
    if(RK_EXPECTED(threadQueue[threadNumber] != NULL, 1)) {
      RKFastConditionLock(threadQueue[threadNumber]->jobLock, NULL, 0, RKConditionLockAnyCondition, 0.0);
      RKInteger jobCondition = [threadQueue[threadNumber]->jobLock condition];
      if(jobCondition == RKJobConditionExecuting) { currentJob = threadQueue[threadNumber]; currentJob->activeThreadsCount++; }
      RKFastConditionUnlock(threadQueue[threadNumber]->jobLock, NULL, jobCondition, RKConditionUnlockAndWakeAll);
      threadQueue[threadNumber] = NULL;
    }

    RKFastConditionUnlock(threadLock, NULL, RKThreadConditionAwake, RKConditionUnlockAndWakeAll);
    
    if(RK_EXPECTED(currentJob != NULL, 1)) {
      currentJob->jobFunction(currentJob->jobArgument);
      RKFastConditionLock(currentJob->jobLock, NULL, 0, RKConditionLockAnyCondition, 0.0);
      NSParameterAssert(([currentJob->jobLock condition] == RKJobConditionExecuting) || ([currentJob->jobLock condition] == RKJobConditionFinishing));
      currentJob->activeThreadsCount--;
      if(currentJob->activeThreadsCount == 0) { RKFastConditionUnlock(currentJob->jobLock, NULL, RKJobConditionCompleted, RKConditionUnlockAndWakeAll); }
      else                                    { RKFastConditionUnlock(currentJob->jobLock, NULL, RKJobConditionFinishing, RKConditionUnlockAndWakeAll); }
      
      currentJob = NULL;
    }
    
    RKFastConditionLock(  threadLock, NULL, RKThreadConditionRunningJob, RKConditionLockWhenCondition, 0.0);
    RKFastConditionUnlock(threadLock, NULL, RKThreadConditionSleeping,   RKConditionUnlockAndWakeAll);
    
    if(loopThreadPool != NULL) { [loopThreadPool release]; loopThreadPool = NULL; }
  }
  
exitThread:
  
  if(currentJob != NULL) {
    RKFastConditionLock(currentJob->jobLock, NULL, 0, RKConditionLockAnyCondition, 0.0);
    currentJob->activeThreadsCount--;
    if(currentJob->activeThreadsCount == 0) { RKFastConditionUnlock(currentJob->jobLock, NULL, RKJobConditionCompleted, RKConditionUnlockAndWakeAll); }
    else                                    { RKFastConditionUnlock(currentJob->jobLock, NULL, RKJobConditionFinishing, RKConditionUnlockAndWakeAll); }
    
    currentJob = NULL;
  }
  
  if([threadLock isLockedByCurrentThread] == NO) { RKFastConditionLock(threadLock, NULL, 0, RKConditionLockAnyCondition, 0.0); }
  RKFastConditionUnlock(threadLock, NULL, RKThreadConditionNotRunning, RKConditionUnlockAndWakeAll);
   
  threads[threadNumber] = NULL;
  RKAtomicDecrementIntegerBarrier(&liveThreads);
  
exitThreadNow:
  if(loopThreadPool != NULL) { [loopThreadPool release]; loopThreadPool = NULL; }
  if(topThreadPool  != NULL) { [topThreadPool  release]; topThreadPool  = NULL; }
}

@end
