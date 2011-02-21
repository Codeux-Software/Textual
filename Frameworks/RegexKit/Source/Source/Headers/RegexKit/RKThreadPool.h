//
//  RKThreadPool.h
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
  
#ifndef _REGEXKIT_RKTHREADPOOL_H_
#define _REGEXKIT_RKTHREADPOOL_H_ 1

/*!
 @header RKThreadPool
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <RegexKit/RKLock.h>
#import <pthread.h>
#import <sys/time.h>
#import <stdlib.h>
#import <sys/sysctl.h>
#if       MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#import <mach/thread_act.h>
#import <mach/thread_policy.h>
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
  
@class RKLock, RKConditionLock;

enum {
  RKThreadPoolStop           = (1 << 0),
  RKThreadPoolThreadsReaped  = (1 << 1)
};

enum {
  RKThreadConditionNotRunning  = 0,
  RKThreadConditionStarting    = 1,
  RKThreadConditionSleeping    = 2,
  RKThreadConditionWakeup      = 3,
  RKThreadConditionAwake       = 4,
  RKThreadConditionRunningJob  = 5
};

enum {
  RKJobConditionAvailable = 1,
  RKJobConditionExecuting = 2,
  RKJobConditionFinishing = 3,
  RKJobConditionCompleted = 4
};

struct threadPoolJob {
  RKConditionLock *jobLock;
  RKUInteger       activeThreadsCount;
  
  int (*jobFunction)(void *);
  void *jobArgument;
};

typedef struct threadPoolJob RK_STRONG_REF RKThreadPoolJob;

@interface RKThreadPool : NSObject {
                NSArray          *objectsArray;
                RKUInteger        threadCount;
                RKUInteger        liveThreads;
                
                RKUInteger        threadPoolControl;
  
                NSThread        **threads;
                RKConditionLock **locks;

  RK_STRONG_REF RKThreadPoolJob  *jobs;
  RK_STRONG_REF RKThreadPoolJob **threadQueue;
}

+ (id)defaultThreadPool;
- (id)initWithThreadCount:(RKUInteger)initThreadCount error:(NSError **)error;
- (void)reapThreads;
- (BOOL)wakeThread:(RKUInteger)threadNumber;
- (BOOL)threadFunction:(int(*)(void *))function argument:(void *)argument;

@end

#endif // _REGEXKIT_RKTHREADPOOL_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
