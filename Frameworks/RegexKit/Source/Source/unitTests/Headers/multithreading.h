//
//  multithreading.h
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

#import "RKTestCase.h"


@interface multithreading : RKTestCase {
  BOOL isInitialized;

  pthread_mutex_t globalThreadLock;
  
  pthread_mutex_t globalThreadConditionLock;
  pthread_cond_t globalThreadCondition;

  pthread_mutex_t globalLogLock;
  NSMutableString *globalLogString;
  NSMutableArray *globalLogArray;
  
  pthread_mutex_t threadExitLock;
  unsigned int threadExitCount;
  
  RKUInteger startAutoreleasedObjects;
  unsigned int iterations;
  
  RKCPUTime testStartCPUTime;
  RKCPUTime testEndCPUTime;
  RKCPUTime testElapsedCPUTime;
  
  NSMutableArray *timingResultsArray;
  
  NSTimer *loggingTimer;
  
  NSDateFormatter *logDateFormatter;
  
  //NSString *debugEnvString;
  //NSString *leakEnvString;
  //NSString *timingEnvString;
  //NSString *multithreadingEnvString;
}

- (int)threadEntry:(id)threadArgument;
- (void)flushLog;
- (void)thread:(int)threadID log:(NSString *)logString;

- (void)releaseResources;

- (BOOL)executeTest:(unsigned int)testNumber;

- (void)mt_cache_1;
- (void)mt_cache_2;
- (void)mt_cache_3;
- (void)mt_cache_4;
- (void)mt_cache_5;
- (void)mt_cache_6;

- (void)mt_test_1;
- (void)mt_test_2;
- (void)mt_test_3;
- (void)mt_test_4;
- (void)mt_test_5;
- (void)mt_test_6;
- (void)mt_test_7;
- (void)mt_test_8;
- (void)mt_test_9;
- (void)mt_test_10;
- (void)mt_test_11;
- (void)mt_test_12;
- (void)mt_test_13;
- (void)mt_test_14;
- (void)mt_test_15;
- (void)mt_test_16;
- (void)mt_test_17;
- (void)mt_test_18;
- (void)mt_test_19;
- (void)mt_test_20;
- (void)mt_test_21;
- (void)mt_test_22;
- (void)mt_test_23;
- (void)mt_test_24;
- (void)mt_test_25;
- (void)mt_test_26;
- (void)mt_test_27;


- (BOOL)mt_time_1;
- (BOOL)mt_time_2;
- (BOOL)mt_time_3;
- (BOOL)mt_time_4;
- (BOOL)mt_time_5;
- (BOOL)mt_time_6;
- (BOOL)mt_time_7;
- (BOOL)mt_time_8;
- (BOOL)mt_time_9;
- (BOOL)mt_time_10;
- (BOOL)mt_time_11;
- (BOOL)mt_time_12;

- (void)mt_sortedRegex_bl1;
- (void)mt_sortedRegex_bl2;
- (void)mt_sortedRegex_wl1;
- (void)mt_sortedRegex_wl2;

@end
