//
//  RKAutoreleasedMemory.m
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

#import <RegexKit/RKAutoreleasedMemory.h>

#ifdef USE_AUTORELEASED_MALLOC

static int     RKAutoreleasedMemoryLoadInitialized  = 0;

static NSZone *autoreleaseMallocZone                  = NULL;
static Class   autoreleaseClass                       = NULL;
static Class   autoreleasePoolClass                   = NULL;
static SEL     autoreleasePoolAddObjectMethodSelector = NULL;
static IMP     autoreleasePoolAddObjectIMP            = NULL;
static size_t  classSizeDifference                    = 0;
static size_t  classAlignedSize                       = 0;

//
// +initialize is called by the runtime just before the class receives its first message.
//

@implementation RKAutoreleasedMemory

+ (void)initialize
{
  RKAtomicMemoryBarrier(); // Extra cautious
  if(RKAutoreleasedMemoryLoadInitialized == 1) { return; }
  
  if(RKAtomicCompareAndSwapInt(0, 1, &RKAutoreleasedMemoryLoadInitialized)) {
    NSAutoreleasePool *initPool = [[NSAutoreleasePool alloc] init];
    size_t  autoreleasePoolInstanceSize = 0;
    
    autoreleaseMallocZone                  = NSDefaultMallocZone();
    autoreleaseClass                       = [RKAutoreleasedMemory class];
    autoreleasePoolClass                   = [NSAutoreleasePool class];
    autoreleasePoolAddObjectMethodSelector = @selector(addObject:);
    autoreleasePoolAddObjectIMP            = (IMP)(class_getClassMethod(autoreleasePoolClass, autoreleasePoolAddObjectMethodSelector)->method_imp);
    autoreleasePoolInstanceSize            = autoreleaseClass->instance_size;
    classSizeDifference                    = (16 - (autoreleasePoolInstanceSize % 16));  // Ensure our returned pointer is always % 16 aligned.
    classAlignedSize                       = (autoreleasePoolInstanceSize + classSizeDifference);

    [initPool release];
    initPool = NULL;
  }
}

@end

void *autoreleasedMalloc(const size_t length) {
  if(RK_EXPECTED(RKAutoreleasedMemoryLoadInitialized == 0, 0)) { [RKAutoreleasedMemory initalize]; } 
  RKAutoreleasedMemory * RK_C99(restrict) memoryObject = (RKAutoreleasedMemory *)NSAllocateObject(autoreleaseClass, (length + classSizeDifference), autoreleaseMallocZone);
  (*autoreleasePoolAddObjectIMP)(autoreleasePoolClass, autoreleasePoolAddObjectMethodSelector, memoryObject); // == [memoryObject autorelease];
  return((void *)(((char *)memoryObject) + classAlignedSize));
}

#endif //USE_AUTORELEASED_MALLOC
