//
//  RKLock.h
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

#ifndef _REGEXKIT_RKLOCK_H_
#define _REGEXKIT_RKLOCK_H_ 1

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKitPrivate.h>
#import <pthread.h>
#import <unistd.h>

#define RKLOCK_MAX_SPURIOUS_ERROR_ATTEMPTS 2

#pragma mark -
#pragma mark Mutex

enum {
  RKMutexDidNotLock  = -1,
  RKMutexTryLazyLock = 0,
  RKMutexTryFullLock = 1,
  RKMutexLazyLock    = 2,
  RKMutexFullLock    = 3,
};

typedef RKInteger RKMutexLockStrategy;

BOOL RKFastMutexLock(  id const self, SEL _cmd, pthread_mutex_t *pthreadMutex, RKMutexLockStrategy mutexLockStrategy) RK_ATTRIBUTES(nonnull(1,3), used, visibility("hidden"));
void RKFastMutexUnlock(id const self, SEL _cmd, pthread_mutex_t *pthreadMutex) RK_ATTRIBUTES(nonnull(1,3), used, visibility("hidden"));

#pragma mark -

@interface RKLock : NSObject <NSLocking> {
  pthread_mutex_t lock;
}

+ (void)setMultithreaded:(const BOOL)enable;

- (BOOL)lock;
- (void)unlock;

BOOL RKFastLock(  RKLock * const self) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));
void RKFastUnlock(RKLock * const self) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));

@end

#pragma mark -

enum {
  RKLockDidNotLock                     = -1,
  RKLockForReading                     = 0,
  RKLockForWriting                     = 1,
  RKLockTryForReading                  = 2,
  RKLockTryForWriting                  = 3,
  RKLockTryForWritingThenForReading    = 4,
  RKLockTryForWritingThenTryForReading = 5
};

typedef RKInteger RKReadWriteLockStrategy;

@interface RKReadWriteLock : NSObject <NSLocking> {
  pthread_rwlock_t readWriteLock;
  RKUInteger       readBusyCount;
  RKUInteger       readSpinCount;
  RKUInteger       readDowngradedFromWriteCount;
  RKUInteger       writeBusyCount;
  RKUInteger       writeSpinCount;
  RKUInteger       spuriousErrorsCount;
  RKUInteger       writeLocked:1;
  RKUInteger       debuggingEnabled:1;
}

+ (void)setMultithreaded:(const BOOL)enable;

- (BOOL)lock;
- (BOOL)readLock;
- (BOOL)writeLock;
- (void)unlock;

- (void)setDebug:(const BOOL)enable;
- (RKUInteger)readBusyCount;
- (RKUInteger)readSpinCount;
- (RKUInteger)readDowngradedFromWriteCount;
- (RKUInteger)writeBusyCount;
- (RKUInteger)writeSpinCount;
- (void)clearCounters;

BOOL RKFastReadWriteLockWithStrategy(RKReadWriteLock * const self, const RKReadWriteLockStrategy lockStrategy, RKReadWriteLockStrategy *lockLevelAcquired) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));
BOOL RKFastReadWriteLock(  RKReadWriteLock * const self, const BOOL forWriting) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));
void RKFastReadWriteUnlock(RKReadWriteLock * const self)                        RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));

@end

#pragma mark -

enum {
  RKConditionLockAnyCondition                 = 0,
  RKConditionLockWhenCondition                = 1,
  RKConditionLockTryAnyCondition              = 2,
  RKConditionLockTryWhenCondition             = 3,
  RKConditionLockTryAnyConditionUntilTime     = 4,
  RKConditionLockTryWhenConditionUntilTime    = 5,
  RKConditionLockTryAnyConditionRelativeTime  = 6,
  RKConditionLockTryWhenConditionRelativeTime = 7
};

typedef RKUInteger RKConditionLockStrategy;

enum {
  RKConditionUnlockAndWakeNone = 0,
  RKConditionUnlockAndWakeOne  = 1,
  RKConditionUnlockAndWakeAll  = 2
};

typedef RKUInteger RKConditionUnlockStrategy;

@interface RKConditionLock : NSObject <NSLocking> {
  pthread_mutex_t pthreadMutex;
  pthread_cond_t  pthreadCondition;
  
  BOOL            conditionIsLocked;
  pthread_t       lockOwner;
  NSThread       *lockOwnerThread;
  RKInteger       currentLockCondition;
}

+ (void)setMultithreaded:(const BOOL)enable;

- (id)initWithCondition:(RKInteger)condition;

- (RKInteger)condition;
- (BOOL)isLocked;
- (BOOL)isLockedByCurrentThread;
- (BOOL)isLockedByThread:(NSThread *)thread;
- (NSThread *)lockOwnerThread;


- (BOOL)tryLock;
- (BOOL)tryLockWhenCondition:(RKInteger)condition;
- (BOOL)lock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
- (BOOL)lockBeforeTimeIntervalSinceNow:(NSTimeInterval)seconds;
- (void)lockWhenCondition:(RKInteger)condition;
- (BOOL)lockWhenCondition:(RKInteger)condition beforeDate:(NSDate *)limit;
- (BOOL)lockWhenCondition:(RKInteger)condition beforeTimeIntervalSinceNow:(NSTimeInterval)seconds;

- (void)unlock;
- (void)unlockWithCondition:(RKInteger)condition;

BOOL RKFastConditionLock(  RKConditionLock * const self, SEL _cmd, RKInteger lockOnCondition,     RKConditionLockStrategy   conditionLockStrategy, NSTimeInterval relativeTime) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));
void RKFastConditionUnlock(RKConditionLock * const self, SEL _cmd, RKInteger unlockWithCondition, RKConditionUnlockStrategy conditionUnlockStrategy) RK_ATTRIBUTES(nonnull(1), used, visibility("hidden"));

@end

  
#endif // _REGEXKIT_RKLOCK_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
