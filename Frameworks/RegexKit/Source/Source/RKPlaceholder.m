//
//  RKPlaceholder.m
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

#import <RegexKit/RKPlaceholder.h>

#ifdef USE_PLACEHOLDER

static RKRegexPlaceholder *singletonRKRegexPlaceholder = NULL;

@implementation RKRegexPlaceholder

+ (id)sharedObject
{
  if(RK_EXPECTED(singletonRKRegexPlaceholder != NULL, 1)) { return(singletonRKRegexPlaceholder); }
  
  id tempPlaceholder = [[self alloc] init];
  if(RKAtomicCompareAndSwapPtr(NULL, tempPlaceholder, &singletonRKRegexPlaceholder) == 0) { RKRelease(tempPlaceholder); }
  RKDisableCollectorForPointer(singletonRKRegexPlaceholder);
  return(singletonRKRegexPlaceholder);
}

+ (id)allocWithZone:(NSZone *)zone {
  if(RK_EXPECTED(singletonRKRegexPlaceholder != NULL, 1)) { return(singletonRKRegexPlaceholder); }
  return(NSAllocateObject([RKRegexPlaceholder class], 0, zone));
}

- (id)copyWithZone:(NSZone *)zone {
#pragma unused(zone)
  return(self);
}

- (id)retain
{
  return self;
}

- (RKUInteger)retainCount
{
  return(RKIntegerMax-1);
}

- (void)release
{
  // Do nothing
}

- (id)autorelease
{
  return self;
}

- (id)initWithRegexString:(NSString * const)regexString options:(const RKCompileOption)options
{
  return(RKRegexFromStringOrRegex(self, _cmd, regexString, options, NO));
}

- (id)initWithRegexString:(NSString * const RK_C99(restrict))regexString library:(NSString * const RK_C99(restrict))libraryString options:(const RKCompileOption)libraryOptions error:(NSError **)error
{
  return(RKRegexFromStringOrRegexWithError(self, _cmd, regexString, libraryString, libraryOptions, error, NO));
}

- (id)initWithCoder:(NSCoder *)coder
{
  return(RKRegexInitWithCoder(self, _cmd, coder));
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  RKRegexEncodeWithCoder(self, _cmd, coder);
}

@end

#endif //USE_PLACEHOLDER
