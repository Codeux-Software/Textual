//
//  RKLock.m
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
 VERY IMPORTANT!!
 These locks use a fast single threaded bypass.  However, in order for lock / unlock semantics to be atomic in single and multithreaded cases, the following condition MUST be met:
 The users of the lock MUST NOT cause the application to become multithreaded while they own the lock!
 Guaranteeing this condition is trivial and results in a 10% - 20% speed improvement for the single threaded case.
*/

#import <RegexKit/RKLock.h>
#import <sys/time.h>

#pragma mark Exceptions

NSString * const RKConditionLockException = @"RKConditionLockException";
NSString * const RKLockingException       = @"RKLockingException";

#pragma mark Global Variables
static int globalIsMultiThreaded = 0;

#pragma mark -
#pragma mark Prototypes

static void releaseRKLockResources(         RKLock          * const self, SEL _cmd) RK_ATTRIBUTES(nonnull(1), used);
static void releaseRKReadWriteResources(    RKReadWriteLock * const self, SEL _cmd) RK_ATTRIBUTES(nonnull(1), used);
static void releaseRKConditionLockResources(RKConditionLock * const self, SEL _cmd) RK_ATTRIBUTES(nonnull(1), used);

#pragma mark -
#pragma mark Mutex Functions

BOOL RKFastMutexLock(id const self, SEL _cmd, pthread_mutex_t *pthreadMutex, RKMutexLockStrategy mutexLockStrategy) {
  BOOL lazyLock = ((mutexLockStrategy == RKMutexTryLazyLock) || (mutexLockStrategy == RKMutexLazyLock))    ? YES : NO;
  BOOL tryLock  = ((mutexLockStrategy == RKMutexTryLazyLock) || (mutexLockStrategy == RKMutexTryFullLock)) ? YES : NO;
  BOOL didLock  = NO;
  
  RK_PROBE(BEGINLOCK, self, 0, globalIsMultiThreaded);
  
  if((globalIsMultiThreaded == 0) && (lazyLock == YES)) {
    if(RK_EXPECTED([NSThread isMultiThreaded] == NO, 1)) { RK_PROBE(ENDLOCK, self, 0, globalIsMultiThreaded, 1, 0); return(YES); }
    RKAtomicCompareAndSwapInt(0, 1, &globalIsMultiThreaded);
  }
  
  switch((tryLock == YES) ? pthread_mutex_trylock(pthreadMutex) : pthread_mutex_lock(pthreadMutex)) {
    case 0: didLock = YES; break;
    case EINVAL:  [[NSException rkException:RKLockingException for:self selector:_cmd localizeReason:@"Lock attempt returned EINVAL error."] raise]; break;
    case EDEADLK: [[NSException rkException:RKLockingException for:self selector:_cmd localizeReason:@"Lock attempt returned EDEADLK error."] raise]; break;
  }
  
  RK_PROBE(ENDLOCK, self, 0, globalIsMultiThreaded, didLock, 0 /*spinCount*/); 
  return(didLock);
}

void RKFastMutexUnlock(id const self, SEL _cmd, pthread_mutex_t *pthreadMutex) {
  switch(pthread_mutex_unlock(pthreadMutex)) {
    case EINVAL: [[NSException rkException:RKLockingException for:self selector:_cmd localizeReason:@"Lock attempt returned EINVAL error."] raise]; break;
    case EPERM:  [[NSException rkException:RKLockingException for:self selector:_cmd localizeReason:@"Lock attempt returned EPERM error."] raise]; break;
  }
  RK_PROBE(UNLOCK, self, 0, globalIsMultiThreaded); 
}

#pragma mark -

@implementation RKLock

+ (void)setMultithreaded:(const BOOL)enable
{
  if(enable == YES) { globalIsMultiThreaded = YES; }
}

- (id)init
{
  pthread_mutexattr_t threadMutexAttribute;
  int pthreadError = 0, initTryCount = 0;
  BOOL mutexAttributeInitialized = NO;

  if((self = [super init]) == NULL) { goto errorExit; }
  RKAutorelease(self);

  //lock = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;

  if((pthreadError = pthread_mutexattr_init(&threadMutexAttribute))                              != 0) { NSLog(@"pthread_mutexattr_init returned #%d, %s.",    pthreadError, strerror(pthreadError)); goto errorExit; }
  mutexAttributeInitialized = YES;
  if((pthreadError = pthread_mutexattr_settype(&threadMutexAttribute, PTHREAD_MUTEX_ERRORCHECK)) != 0) { NSLog(@"pthread_mutexattr_settype returned #%d, %s.", pthreadError, strerror(pthreadError)); goto errorExit; }
  
  while((pthreadError = pthread_mutex_init(&lock, &threadMutexAttribute)) != 0) {
    if(pthreadError == EAGAIN)  { initTryCount++; if(initTryCount > 5) { NSLog(@"pthread_mutex_init returned EAGAIN 5 times, giving up."); goto errorExit; } RKThreadYield(); continue; }
    if(pthreadError == EINVAL)  { NSLog(@"pthread_mutex_init returned EINVAL.");  goto errorExit; }
    if(pthreadError == EDEADLK) { NSLog(@"pthread_mutex_init returned EDEADLK."); goto errorExit; }
    if(pthreadError == ENOMEM)  { NSLog(@"pthread_mutex_init returned ENOMEM.");  goto errorExit; }
  }

  if(mutexAttributeInitialized == YES) { mutexAttributeInitialized = NO; pthread_mutexattr_destroy(&threadMutexAttribute); }
  return(RKRetain(self));

errorExit:
  if(mutexAttributeInitialized == YES) { mutexAttributeInitialized = NO; pthread_mutexattr_destroy(&threadMutexAttribute); }
  return(NULL);
}

- (void)dealloc
{
  releaseRKLockResources(self, _cmd);
  [super dealloc];
}

#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
- (void)finalize
{
  releaseRKLockResources(self, _cmd);
  [super finalize];
}
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

static void releaseRKLockResources(RKLock * const self, SEL _cmd RK_ATTRIBUTES(unused)) {
  int pthreadError = 0, destroyTryCount = 0;

  while((pthreadError = pthread_mutex_destroy(&self->lock)) != 0) {
    if(pthreadError == EBUSY)  { usleep(50); if(++destroyTryCount > 100) { NSLog(@"pthread_mutex_destroy returned EAGAIN 100 times, giving up."); goto errorExit; } continue; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_mutex_destroy returned EINVAL."); goto errorExit; }
  }

errorExit:
  return;
}

- (RKUInteger)hash
{
  return((RKUInteger)self);
}

- (BOOL)isEqual:(id)anObject
{
  if(self == anObject) { return(YES); } else { return(NO); }
}

- (BOOL)lock
{
  return(RKFastLock(self));
}

- (void)unlock
{
  return(RKFastUnlock(self));
}

BOOL RKFastLock(RKLock * const self) {
  if(globalIsMultiThreaded == 0) {
    if(RK_EXPECTED([NSThread isMultiThreaded] == NO, 1)) { RK_PROBE(BEGINLOCK, self, 0, globalIsMultiThreaded); RK_PROBE(ENDLOCK, self, 0, globalIsMultiThreaded, 1, 0); return(YES); }
    RKAtomicCompareAndSwapInt(0, 1, &globalIsMultiThreaded);
  }
  
  return(RKFastMutexLock(self, @selector(lock), &self->lock, RKMutexFullLock));
}

void RKFastUnlock(RKLock * const self) {
  if(globalIsMultiThreaded != 0) { RKFastMutexUnlock(self, @selector(unlock), &self->lock); } else { RK_PROBE(UNLOCK, self, 0, globalIsMultiThreaded); }
}


@end

#pragma mark -

@implementation RKReadWriteLock

+ (void)setMultithreaded:(const BOOL)enable
{
  if(enable == YES) { globalIsMultiThreaded = YES; }
}

- (id)init
{
  int pthreadError = 0, initTryCount = 0;
  
  if((self = [super init]) == NULL) { goto errorExit; }
  RKAutorelease(self);

  //readWriteLock = (pthread_rwlock_t)PTHREAD_RWLOCK_INITIALIZER;
  
  while((pthreadError = pthread_rwlock_init(&readWriteLock, NULL)) != 0) {
    if(pthreadError == EAGAIN)  { if(++initTryCount > 5) { NSLog(@"pthread_rwlock_init returned EAGAIN 5 times, giving up."); goto errorExit; } RKThreadYield(); continue; }
    if(pthreadError == EINVAL)  { NSLog(@"pthread_rwlock_init returned EINVAL.");  goto errorExit; }
    if(pthreadError == EDEADLK) { NSLog(@"pthread_rwlock_init returned EDEADLK."); goto errorExit; }
    if(pthreadError == ENOMEM)  { NSLog(@"pthread_rwlock_init returned ENOMEM.");  goto errorExit; }
  }
  
  return(RKRetain(self));
  
errorExit:
    return(NULL);
}

- (void)dealloc
{
  releaseRKReadWriteResources(self, _cmd);
  [super dealloc];
}

#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
- (void)finalize
{
  releaseRKReadWriteResources(self, _cmd);
  [super finalize];
}
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

static void releaseRKReadWriteResources(RKReadWriteLock * const self, SEL _cmd RK_ATTRIBUTES(unused)) {
  int pthreadError = 0, destroyTryCount = 0;
  
  while((pthreadError = pthread_rwlock_destroy(&self->readWriteLock)) != 0) {
    if(pthreadError == EBUSY)  { usleep(50); if(++destroyTryCount > 100) { NSLog(@"pthread_rwlock_destroy returned EAGAIN 100 times, giving up."); goto errorExit; } continue; }
    if(pthreadError == EPERM)  { NSLog(@"pthread_rwlock_destroy returned EPERM.");  goto errorExit; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_rwlock_destroy returned EINVAL."); goto errorExit; }
  }
  
errorExit:
  return;
}

- (RKUInteger)hash
{
  return((RKUInteger)self);
}

- (BOOL)isEqual:(id)anObject
{
  if(self == anObject) { return(YES); } else { return(NO); }
}

- (BOOL)lock
{
  return(RKFastReadWriteLockWithStrategy(self, RKLockForWriting, NULL)); // Be conservative and assume a write lock
}

- (BOOL)readLock
{
  return(RKFastReadWriteLockWithStrategy(self, RKLockForReading, NULL));
}

- (BOOL)writeLock
{
  return(RKFastReadWriteLock(self, YES));
}

- (void)unlock
{
  RKFastReadWriteUnlock(self);
}

- (void)setDebug:(const BOOL)enable
{
  debuggingEnabled = enable;
}

- (RKUInteger)readBusyCount
{
  return(readBusyCount);
}

- (RKUInteger)readSpinCount
{
  return(readSpinCount);
}

- (RKUInteger)readDowngradedFromWriteCount
{
  return(readDowngradedFromWriteCount);
}

- (RKUInteger)writeBusyCount
{
  return(writeBusyCount);
}

- (RKUInteger)writeSpinCount
{
  return(writeSpinCount);
}

- (void)clearCounters
{
  readBusyCount = 0;
  readSpinCount = 0;
  readDowngradedFromWriteCount = 0;
  writeBusyCount = 0;
  writeSpinCount = 0;
}

BOOL RKFastReadWriteLock(RKReadWriteLock * const self, const BOOL forWriting) {
  return(RKFastReadWriteLockWithStrategy(self, (forWriting == NO) ? RKLockForReading : RKLockForWriting, NULL));
}

BOOL RKFastReadWriteLockWithStrategy(RKReadWriteLock * const self, const RKReadWriteLockStrategy lockStrategy, RKReadWriteLockStrategy *lockLevelAcquired) {
  int pthreadError = 0, spuriousErrors = 0, spinCount = 0;
  NSString * RK_C99(restrict) functionString = NULL;
  BOOL didLock = NO, forWriting = ((lockStrategy == RKLockForReading) || (lockStrategy == RKLockTryForReading)) ? NO : YES;

  RK_PROBE(BEGINLOCK, self, lockStrategy, globalIsMultiThreaded); 

  if(globalIsMultiThreaded == 0) {
    if(RK_EXPECTED([NSThread isMultiThreaded] == NO, 1)) { self->writeLocked = forWriting; RK_PROBE(ENDLOCK, self, forWriting, 0, 1, 0); if(lockLevelAcquired) { *lockLevelAcquired = forWriting; } return(YES); }
    RKAtomicCompareAndSwapInt(0, 1, &globalIsMultiThreaded);
  }

  if(RK_EXPECTED(lockStrategy == RKLockTryForWritingThenForReading, 0)) {
    if(RK_EXPECTED((pthreadError = pthread_rwlock_trywrlock(&self->readWriteLock)) == 0, 1)) { // Fast exit on the common acquired lock case.
      self->writeLocked = forWriting;
      RK_PROBE(ENDLOCK, self, forWriting, globalIsMultiThreaded, 1, spinCount);
      if(lockLevelAcquired) { *lockLevelAcquired = RKLockForWriting; }
      return(YES);
    }
    forWriting = NO; // Unable to acquire a write level lock, downgrade and acquire a read level lock.
  }
  
  if(RK_EXPECTED(forWriting == YES, 0)) {
    functionString = @"pthread_rwlock_trywrlock";
    if(RK_EXPECTED((pthreadError = pthread_rwlock_trywrlock(&self->readWriteLock)) == 0, 1)) { self->writeLocked = forWriting; RK_PROBE(ENDLOCK, self, forWriting, globalIsMultiThreaded, 1, spinCount); if(lockLevelAcquired) { *lockLevelAcquired = RKLockForWriting; } return(YES); } // Fast exit on the common acquired lock case.

    switch(pthreadError) {
      case 0:                                                      didLock = YES; goto exitNow; break; // Lock was acquired
      case EAGAIN:                                                                                     // drop through
      case EBUSY:   spinCount++; if(self->debuggingEnabled == YES) { self->writeBusyCount++; }  break; // Do nothing, we need to wait on the lock, which we do after the switch
      case EDEADLK: NSLog(@"%@ returned EDEADLK.", functionString);               goto exitNow; break; // XXX Hopeless?
      case ENOMEM:  NSLog(@"%@ returned ENOMEM.", functionString);                goto exitNow; break; // XXX Hopeless?
      case EINVAL:  NSLog(@"%@ returned EINVAL.", functionString);                goto exitNow; break; // XXX Hopeless?
      default:
        if((spuriousErrors < RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS) || (lockStrategy == RKLockTryForWriting)) {
          spuriousErrors++;
          RKAtomicIncrementIntegerBarrier(&self->spuriousErrorsCount);
          NSLog(@"%@ returned an unknown error code %d. This may be a spurious error, retry %d of %d.", functionString, pthreadError, spuriousErrors, RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS);
        } else { NSLog(@"%@ returned an unknown error code %d. Giving up after %d attempts.", functionString, pthreadError, spuriousErrors); goto exitNow; }
        break;
    }

    if(lockStrategy == RKLockTryForWriting) { goto exitNow; }
    functionString = @"pthread_rwlock_wrlock";
    
    do {
      pthreadError = pthread_rwlock_wrlock(&self->readWriteLock);  // Don't trylock, allow write lock request to block reads for priority access
      
      switch(pthreadError) {
        case 0:                                                                                    didLock = YES; goto exitNow; break; // Lock was acquired
        case EAGAIN:                                                                                                                   // drop through
        case EBUSY:   spinCount++; if(self->debuggingEnabled == YES) { self->writeSpinCount++; }               RKThreadYield(); break; // This normally shouldn't happen.
        case EINVAL:  NSLog(@"%@ returned EINVAL after a trylock succeeded without any error.",  functionString); goto exitNow; break; // XXX Hopeless?
        case EDEADLK: NSLog(@"%@ returned EDEADLK after a trylock succeeded without any error.", functionString); goto exitNow; break; // XXX Hopeless?
        case ENOMEM:  NSLog(@"%@ returned ENOMEM after a trylock succeeded without any error.",  functionString); goto exitNow; break; // XXX Hopeless?
        default:
          if(spuriousErrors < RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS) {
            spuriousErrors++;
            RKAtomicIncrementIntegerBarrier(&self->spuriousErrorsCount);
            NSLog(@"%@ returned an unknown error code %d. This may be a spurious error, retry %d of %d.", functionString, pthreadError, spuriousErrors, RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS);
          } else { NSLog(@"%@ returned an unknown error code %d. Giving up after %d attempts.", functionString, pthreadError, spuriousErrors); goto exitNow; }
          break;
      }    
    } while(pthreadError != 0);
    
  } else { // forWriting == NO
    if(RK_EXPECTED((pthreadError = pthread_rwlock_tryrdlock(&self->readWriteLock)) == 0, 1)) { self->writeLocked = forWriting; RK_PROBE(ENDLOCK, self, forWriting, globalIsMultiThreaded, 1, spinCount); if(lockLevelAcquired) { *lockLevelAcquired = RKLockForReading; } return(YES); } // Fast exit on the common acquired lock case.
    functionString = @"pthread_rwlock_tryrdlock";
    
    switch(pthreadError) {
      case 0:                                                    didLock = YES; goto exitNow; break; // Lock was acquired
      case EAGAIN:                                                                                   // drop through
      case EBUSY:   spinCount++; if(self->debuggingEnabled == YES) { self->readBusyCount++; } break; // Do nothing, we need to wait on the lock, which we do after the switch
      case EDEADLK: NSLog(@"%@ returned EDEADLK.", functionString);             goto exitNow; break; // XXX Hopeless?
      case ENOMEM:  NSLog(@"%@ returned ENOMEM.", functionString);              goto exitNow; break; // XXX Hopeless?
      case EINVAL:  NSLog(@"%@ returned EINVAL.", functionString);              goto exitNow; break; // XXX Hopeless?
      default:
        if((spuriousErrors < RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS) || (lockStrategy == RKLockTryForReading)){
          spuriousErrors++;
          RKAtomicIncrementIntegerBarrier(&self->spuriousErrorsCount);
          NSLog(@"%@ returned an unknown error code %d. This may be a spurious error, retry %d of %d.", functionString, pthreadError, spuriousErrors, RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS);
        } else { NSLog(@"%@ returned an unknown error code %d. Giving up after %d attempts.", functionString, pthreadError, spuriousErrors); goto exitNow; }
        break;
    }
    
    if(lockStrategy == RKLockTryForReading) { goto exitNow; }
    functionString = (self->debuggingEnabled == YES) ? @"pthread_rwlock_tryrdlock":@"pthread_rwlock_rdlock";
    
    do {
      //if(self->debuggingEnabled == YES) { pthreadError = pthread_rwlock_tryrdlock(&self->readWriteLock); } else { pthreadError = pthread_rwlock_rdlock(&self->readWriteLock); }
      pthreadError = pthread_rwlock_rdlock(&self->readWriteLock);

      switch(pthreadError) {
        case 0:                                                                                    didLock = YES; goto exitNow; break; // Lock was acquired
        case EAGAIN:                                                                                                                   // drop through
        case EBUSY:   spinCount++; if(self->debuggingEnabled == YES) { self->readSpinCount++; }                RKThreadYield(); break; // Yield and then try again
        case EINVAL:  NSLog(@"%@ returned EINVAL after a trylock succeeded without any error.",  functionString); goto exitNow; break; // XXX Hopeless?
        case EDEADLK: NSLog(@"%@ returned EDEADLK after a trylock succeeded without any error.", functionString); goto exitNow; break; // XXX Hopeless?
        case ENOMEM:  NSLog(@"%@ returned ENOMEM after a trylock succeeded without any error.",  functionString); goto exitNow; break; // XXX Hopeless?
        default:
          if(spuriousErrors < RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS) {
            spuriousErrors++;
            RKAtomicIncrementIntegerBarrier(&self->spuriousErrorsCount);
            NSLog(@"%@ returned an unknown error code %d. This may be a spurious error, retry %d of %d.", functionString, pthreadError, spuriousErrors, RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS);
          } else { NSLog(@"%@ returned an unknown error code %d. Giving up after %d attempts.", functionString, pthreadError, spuriousErrors); goto exitNow; }
          break;
      }    
    } while(pthreadError != 0);
  }
  
exitNow:
  if(didLock == YES) { self->writeLocked = forWriting; }
  RK_PROBE(ENDLOCK, self, forWriting, globalIsMultiThreaded, didLock, spinCount);
  if(lockLevelAcquired) { if(didLock == YES) { *lockLevelAcquired = forWriting; } else { *lockLevelAcquired = RKLockDidNotLock; } }
  return(didLock);
}

void RKFastReadWriteUnlock(RKReadWriteLock * const self) {
  int pthreadError = 0;

  RK_PROBE(UNLOCK, self, self->writeLocked, globalIsMultiThreaded); 
  
  if(globalIsMultiThreaded == 0) { return; }
  if(RK_EXPECTED((pthreadError = pthread_rwlock_unlock(&self->readWriteLock)) != 0, 0)) {
    if(pthreadError == EINVAL) { NSLog(@"pthread_mutex_unlock returned EINVAL.");           return; }
    if(pthreadError == EPERM)  { NSLog(@"pthread_mutex_unlock returned EPERM, not owner?"); return; }
  }
}

@end

#pragma mark -

@implementation RKConditionLock

+ (void)setMultithreaded:(const BOOL)enable
{
  if(enable == YES) { globalIsMultiThreaded = YES; }
}

- (id)initWithCondition:(RKInteger)initCondition
{
  pthread_mutexattr_t threadMutexAttribute;
  int pthreadError = 0, initTryCount = 0;
  BOOL mutexAttributeInitialized = NO;
  
  if((self = [self init]) == NULL) { goto errorExit; }
  RKAutorelease(self);
  
  //pthreadMutex     = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
  //pthreadCondition = (pthread_cond_t) PTHREAD_COND_INITIALIZER;

  if((pthreadError = pthread_mutexattr_init(&threadMutexAttribute))                              != 0) { NSLog(@"pthread_mutexattr_init returned #%d, %s.",    pthreadError, strerror(pthreadError)); goto errorExit; }
  mutexAttributeInitialized = YES;
  if((pthreadError = pthread_mutexattr_settype(&threadMutexAttribute, PTHREAD_MUTEX_ERRORCHECK)) != 0) { NSLog(@"pthread_mutexattr_settype returned #%d, %s.", pthreadError, strerror(pthreadError)); goto errorExit; }
  
  while((pthreadError = pthread_mutex_init(&pthreadMutex, &threadMutexAttribute)) != 0) {
    if(pthreadError == EAGAIN) { initTryCount++; if(initTryCount > 5) { NSLog(@"pthread_mutex_init returned EAGAIN 5 times, giving up."); goto errorExit; } RKThreadYield(); continue; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_mutex_init returned EINVAL."); goto errorExit; }
    if(pthreadError == ENOMEM) { NSLog(@"pthread_mutex_init returned ENOMEM."); goto errorExit; }
  }

  if(mutexAttributeInitialized == YES) { mutexAttributeInitialized = NO; pthread_mutexattr_destroy(&threadMutexAttribute); }

  initTryCount = 0;
  while((pthreadError = pthread_cond_init(&pthreadCondition, NULL)) != 0) {
    if(pthreadError == EAGAIN) { if(++initTryCount > 5) { NSLog(@"pthread_cond_init returned EAGAIN 5 times, giving up."); goto errorExit; } RKThreadYield(); continue; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_cond_init returned EINVAL.");  goto errorExit; }
    if(pthreadError == ENOMEM) { NSLog(@"pthread_cond_init returned ENOMEM.");  goto errorExit; }
  }
    
  currentLockCondition = initCondition;
  
  return(RKRetain(self));
  
errorExit:
  if(mutexAttributeInitialized == YES) { mutexAttributeInitialized = NO; pthread_mutexattr_destroy(&threadMutexAttribute); }
  return(NULL);
}

- (void)dealloc
{
  releaseRKConditionLockResources(self, _cmd);
  [super dealloc];
}

#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
- (void)finalize
{
  releaseRKConditionLockResources(self, _cmd);
  [super finalize];
}
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION

static void releaseRKConditionLockResources(RKConditionLock * const self, SEL _cmd RK_ATTRIBUTES(unused)) {
  int pthreadError = 0, destroyTryCount = 0;
  
  while((pthreadError = pthread_cond_destroy(&self->pthreadCondition)) != 0) {
    if(pthreadError == EBUSY)  { usleep(50); if(++destroyTryCount > 100) { NSLog(@"pthread_cond_destroy returned EAGAIN 100 times, giving up."); goto errorExit; } continue; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_cond_destroy returned EINVAL.");  goto errorExit; }
  }
  
  destroyTryCount = 0;
  while((pthreadError = pthread_mutex_destroy(&self->pthreadMutex)) != 0) {
    if(pthreadError == EBUSY)  { usleep(50); if(++destroyTryCount > 100) { NSLog(@"pthread_mutex_destroy returned EAGAIN 100 times, giving up."); goto errorExit; } continue; }
    if(pthreadError == EINVAL) { NSLog(@"pthread_mutex_destroy returned EINVAL.");  goto errorExit; }
  }
  
errorExit:
  return;
}

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
  NSMutableString *lockedString = [NSMutableString stringWithFormat:RKLocalizedString(@"Locked = %@"), RKYesOrNo(conditionIsLocked)];
  if(conditionIsLocked == YES) { [lockedString appendFormat:RKLocalizedString(@", Lock Owned by Thread = %@ (this thread: %@)"), [self lockOwnerThread], RKYesOrNo([self isLockedByCurrentThread])]; }
  return(RKLocalizedFormat(@"<%@: %p> %@, Condition = %lu", [self className], self, lockedString, (unsigned long)currentLockCondition));
}

#pragma mark -
#pragma mark RKConditionalLock Information

- (RKInteger)condition
{
  return(currentLockCondition);
}

- (BOOL)isLocked
{
  return(conditionIsLocked);
}

- (BOOL)isLockedByCurrentThread
{
  return(((conditionIsLocked == YES) && [[NSThread currentThread] isEqual:lockOwnerThread]));
}

- (BOOL)isLockedByThread:(NSThread *)thread
{
  return([thread isEqual:lockOwnerThread]);
}

- (NSThread *)lockOwnerThread
{
  return(RKAutorelease(RKRetain(lockOwnerThread)));
}

#pragma mark -
#pragma mark RKConditionalLock Locking Methods

- (BOOL)tryLock
{
  return(RKFastConditionLock(self, _cmd, 0, RKConditionLockAnyCondition, 0.0));
}

- (BOOL)tryLockWhenCondition:(RKInteger)condition
{
  return(RKFastConditionLock(self, _cmd, condition, RKConditionLockTryWhenCondition, 0.0));
}

- (BOOL)lock
{
  return(RKFastConditionLock(self, _cmd, 0, RKConditionLockAnyCondition, 0.0));
}

- (BOOL)lockBeforeDate:(NSDate *)limit
{
  return(RKFastConditionLock(self, _cmd, 0, RKConditionLockTryAnyConditionUntilTime, [limit timeIntervalSince1970]));
}

- (BOOL)lockBeforeTimeIntervalSinceNow:(NSTimeInterval)seconds
{
  return(RKFastConditionLock(self, _cmd, 0, RKConditionLockTryAnyConditionUntilTime, seconds));
}

- (void)lockWhenCondition:(RKInteger)condition
{
  RKFastConditionLock(self, _cmd, condition, RKConditionLockWhenCondition, 0.0);
}

- (BOOL)lockWhenCondition:(RKInteger)condition beforeDate:(NSDate *)limit
{
  return(RKFastConditionLock(self, _cmd, condition, RKConditionLockTryWhenConditionUntilTime, [limit timeIntervalSince1970]));
}

- (BOOL)lockWhenCondition:(RKInteger)condition beforeTimeIntervalSinceNow:(NSTimeInterval)seconds
{
  return(RKFastConditionLock(self, _cmd, condition, RKConditionLockTryWhenConditionUntilTime, seconds));
}

#pragma mark -
#pragma mark RKConditionalLock Unlocking Methods

- (void)unlock
{
  RKFastConditionUnlock(self, _cmd, currentLockCondition, RKConditionUnlockAndWakeAll);
}

- (void)unlockWithCondition:(RKInteger)condition
{
  RKFastConditionUnlock(self, _cmd, condition, RKConditionUnlockAndWakeAll);
}

#pragma mark -

BOOL RKFastConditionLock(RKConditionLock * const self, SEL _cmd, RKInteger lockOnCondition, RKConditionLockStrategy conditionLockStrategy, NSTimeInterval relativeTime) {
  BOOL didLock = NO, lockOnAnyCondition = NO, tryToLock = NO, isRelativeTime = NO, canTimeOut = NO, lockTimedOut = NO, mutexLocked = NO;
  double relativeTimeIntegralPart, relativeTimeFractionalPart;
  struct timespec pthreadConditionTimeSpec;
  struct timeval nowTimeVal;
  int pthreadError = 0;

  switch(conditionLockStrategy) {
    case RKConditionLockAnyCondition:                 lockOnAnyCondition = YES;                                         break;
    case RKConditionLockWhenCondition:                                                                                  break;
    case RKConditionLockTryAnyCondition:              lockOnAnyCondition = YES;                   tryToLock      = YES; break;
    case RKConditionLockTryWhenCondition:                                                         tryToLock      = YES; break;
    case RKConditionLockTryAnyConditionUntilTime:     lockOnAnyCondition = YES; canTimeOut = YES;                       break;
    case RKConditionLockTryWhenConditionUntilTime:                              canTimeOut = YES;                       break;
    case RKConditionLockTryAnyConditionRelativeTime:  lockOnAnyCondition = YES; canTimeOut = YES; isRelativeTime = YES; break;
    case RKConditionLockTryWhenConditionRelativeTime:                           canTimeOut = YES; isRelativeTime = YES; break;
    default: break;
  }
  
  if((tryToLock == YES) && ((self->conditionIsLocked == YES) || ((self->currentLockCondition != lockOnCondition) && (lockOnAnyCondition == NO)))) { goto exitNow; }
  
  if((canTimeOut == YES) && (isRelativeTime == NO)) { relativeTime = 0.0; }
  if(isRelativeTime == YES) { gettimeofday(&nowTimeVal, NULL); relativeTime += (NSTimeInterval)((double)nowTimeVal.tv_sec + (1.0E-6 * (double)nowTimeVal.tv_usec)); }
  
  if(canTimeOut == YES) {
    relativeTimeFractionalPart       = modf(relativeTime, &relativeTimeIntegralPart);
    pthreadConditionTimeSpec.tv_sec  = (long)relativeTimeIntegralPart;
    pthreadConditionTimeSpec.tv_nsec = (long)(relativeTimeFractionalPart * 1.0E9);
  }
  
  mutexLocked = RKFastMutexLock(self, _cmd, &self->pthreadMutex, (tryToLock == YES) ? RKMutexTryFullLock : RKMutexFullLock);

  if((mutexLocked == NO) && (tryToLock == YES)) { goto exitNow; }
  else if((mutexLocked == NO) && (tryToLock == NO)) { [[NSException rkException:RKConditionLockException for:self selector:_cmd localizeReason:@"Mutex did not lock as expected."] raise]; }
  
  pthread_t pthreadSelf = pthread_self();
  
  if((self->conditionIsLocked == YES) && pthread_equal(self->lockOwner, pthreadSelf)) { [[NSException rkException:RKConditionLockException for:self selector:_cmd localizeReason:@"This RKConditionLock is already locked by this thread."] raise]; }
  
  if((tryToLock == YES) && ((self->conditionIsLocked == YES) || ((self->currentLockCondition != lockOnCondition) && (lockOnAnyCondition == NO)))) { goto exitNow; }
  
  while((((self->currentLockCondition != lockOnCondition) && (lockOnAnyCondition == NO)) || (self->conditionIsLocked == YES)) && (lockTimedOut == NO) && (tryToLock == NO)) {
    if(canTimeOut == YES) { pthreadError = pthread_cond_timedwait(&self->pthreadCondition, &self->pthreadMutex, &pthreadConditionTimeSpec); }
    else {                  pthreadError = pthread_cond_wait(     &self->pthreadCondition, &self->pthreadMutex); }
    
    if((pthreadError == ETIMEDOUT) || ((pthreadError == EINVAL) && (canTimeOut == YES))) { lockTimedOut = YES; }
    else if(pthreadError != 0) { [[NSException rkException:RKConditionLockException for:self selector:_cmd localizeReason:@"pthread_cond != 0, is %d '%s'.", pthreadError, strerror(pthreadError)] raise]; }
  }
  NSCParameterAssert((pthreadError == ETIMEDOUT) ? (canTimeOut == YES) : YES);
  NSCParameterAssert((lockTimedOut == YES)       ? ((pthreadError == ETIMEDOUT) || (pthreadError == EINVAL)) : YES);
  NSCParameterAssert((tryToLock    == YES)       ? ((self->conditionIsLocked == NO) && ((self->currentLockCondition == lockOnCondition) || (lockOnAnyCondition == YES))) : YES);
   
  if((self->conditionIsLocked == NO) && (lockTimedOut == NO) && ((self->currentLockCondition == lockOnCondition) || (lockOnAnyCondition == YES))) {
    NSCParameterAssert(self->conditionIsLocked == NO);
    NSCParameterAssert((self->currentLockCondition == lockOnCondition) || (lockOnAnyCondition == YES));
    
    self->conditionIsLocked    = YES;
    self->lockOwner            = pthreadSelf;
    self->lockOwnerThread      = [NSThread currentThread];
    self->currentLockCondition = (lockOnAnyCondition == YES) ? self->currentLockCondition : lockOnCondition;
    didLock                    = YES;
  }

exitNow:
  RK_PROBE(ENDLOCK, self, 0, globalIsMultiThreaded, didLock, 0);
  if(mutexLocked == YES) { RKFastMutexUnlock(self, _cmd, &self->pthreadMutex); mutexLocked = NO; }
  return(didLock);
}

void RKFastConditionUnlock(RKConditionLock * const self, SEL _cmd, RKInteger unlockWithCondition, RKConditionUnlockStrategy conditionUnlockStrategy) {
  if(RKFastMutexLock(self, _cmd, &self->pthreadMutex, RKMutexFullLock) == NO) { [[NSException rkException:RKConditionLockException for:self selector:_cmd localizeReason:@"Mutex did not lock as expected."] raise]; }
  if((self->conditionIsLocked == NO) || (pthread_equal(self->lockOwner, pthread_self()) == 0)) { [[NSException rkException:RKConditionLockException for:self selector:_cmd localizeReason:@"Illegal unlock attempt. conditionIsLocked: %@, thread is lock owner: %@.", RKYesOrNo(self->conditionIsLocked), RKYesOrNo(pthread_equal(self->lockOwner, pthread_self()))] raise]; }
  
  self->conditionIsLocked    = NO;
  self->currentLockCondition = unlockWithCondition;

  if(     conditionUnlockStrategy == RKConditionUnlockAndWakeOne) { pthread_cond_signal(   &self->pthreadCondition); }
  else if(conditionUnlockStrategy == RKConditionUnlockAndWakeAll) { pthread_cond_broadcast(&self->pthreadCondition); }
  
  RKFastMutexUnlock(self, _cmd, &self->pthreadMutex);
}

@end
