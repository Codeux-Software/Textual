//
//  RKTestCase.m
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
#import "RegexKitPrivateAtomic.h"
#import "RegexKitPrivateMemory.h"

NSBundle *unitTestBundle             = NULL;

NSArray *blacklistArray              = NULL;
NSArray *whitelistArray              = NULL;
NSArray *urlArray                    = NULL;

NSString *leakEnvString              = NULL;
NSString *debugEnvString             = NULL;
NSString *timingEnvString            = NULL;
NSString *multithreadingEnvString    = NULL;
NSString *sleepWhenFinishedEnvString = NULL;

int32_t garbageCollectorEnabled      = 0;

//fptr_objc_collect objc_collect_function = NULL;
void (*objc_collect_function)(unsigned long) = NULL;

int32_t RKTestCaseLoadInitialized    = 0;

@implementation RKTestCase

+ (void)load
{
  RKAtomicMemoryBarrier(); // Extra cautious
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  if(RKAtomicCompareAndSwapInt(0, 1, &RKTestCaseLoadInitialized)) {

    if([objc_getClass("NSGarbageCollector") defaultCollector] != NULL) {
      garbageCollectorEnabled = 1;
      NSLog(@"Garbage Collection is ENABLED.  Starting background collector thread.\n");
      
      void (*objc_sct)(void);
      if((objc_sct = dlsym(RTLD_DEFAULT, "objc_startCollectorThread")) != NULL) {
        objc_sct();
        NSLog(@"Thread started...");
      }
    } else { NSLog(@"Garbage Collection is DISABLED."); }

    if((objc_collect_function = dlsym(RTLD_DEFAULT, "objc_collect")) != NULL) {
      NSLog(@"objc_collection() function defined.");
    }

    unitTestBundle = [[NSBundle bundleWithIdentifier:@"com.zang.RegexKit.Unit Tests"] retain];
    
    blacklistArray = [[[NSString stringWithContentsOfFile:[unitTestBundle pathForResource:@"blacklist" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"\n"] retain];
    whitelistArray = [[[NSString stringWithContentsOfFile:[unitTestBundle pathForResource:@"whitelist" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"\n"] retain];
    urlArray       = [[[NSString stringWithContentsOfFile:[unitTestBundle pathForResource:@"url"       ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"\n"] retain];
        
    if(getenv("DEBUG")               != NULL) { debugEnvString             = [[NSString alloc] initWithCString:getenv("DEBUG")               encoding:NSUTF8StringEncoding]; }
    if(getenv("LEAK_CHECK")          != NULL) { leakEnvString              = [[NSString alloc] initWithCString:getenv("LEAK_CHECK")          encoding:NSUTF8StringEncoding]; }
    if(getenv("TIMING")              != NULL) { timingEnvString            = [[NSString alloc] initWithCString:getenv("TIMING")              encoding:NSUTF8StringEncoding]; }
    if(getenv("MULTITHREADING")      != NULL) { multithreadingEnvString    = [[NSString alloc] initWithCString:getenv("MULTITHREADING")      encoding:NSUTF8StringEncoding]; }
    if(getenv("SLEEP_WHEN_FINISHED") != NULL) { sleepWhenFinishedEnvString = [[NSString alloc] initWithCString:getenv("SLEEP_WHEN_FINISHED") encoding:NSUTF8StringEncoding]; }
    
    NSLog(@"LEAK_CHECK = %@, DEBUG = %@, TIMING = %@, MULTITHREADING = %@, SLEEP_WHEN_FINISHED = %@", leakEnvString, debugEnvString, timingEnvString, multithreadingEnvString, sleepWhenFinishedEnvString);
  }

  [pool release]; pool = NULL;
}

@end
