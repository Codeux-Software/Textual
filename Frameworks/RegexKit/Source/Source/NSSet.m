//
//  NSSet.m
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

#import <RegexKit/NSSet.h>
#import <RegexKit/RegexKitPrivate.h>

typedef enum {
  RKSetActionObjectOfFirstMatch = 0,
  RKSetActionSetOfMatchingObjects = 1,
  RKSetActionCountOfMatchingObjects = 2,
  RKSetActionAddMatches = 3,
  RKSetActionRemoveMatches = 4,
  RKSetActionSetMaxAction = 4
} RKSetAction;

static id RKDoSetAction(id self, SEL _cmd, id matchAgainstSet, id regexObject, const RKSetAction performAction, RKUInteger *UIntegerResult);

@implementation NSSet (RegexKitAdditions)

static id RKDoSetAction(id self, SEL _cmd, id matchAgainstSet, id regexObject, const RKSetAction performAction, RKUInteger *UIntegerResult) {
  RKRegex *regex = RKRegexFromStringOrRegex(self, _cmd, regexObject, (RKCompileUTF8 | RKCompileNoUTF8Check), YES);
  id returnObject = NULL, *setObjects = NULL, *matchedObjects = NULL;
  RKUInteger setCount = 0, atIndex = 0, matchedCount = 0, tempUIntegerResult = 0;
  
  if(RK_EXPECTED(self == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"self == NULL."] raise]; }
  if(RK_EXPECTED(_cmd == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"_cmd == NULL."] raise]; }
  if(RK_EXPECTED(matchAgainstSet == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"matchAgainstSet == NULL."] raise]; }
  if(RK_EXPECTED(performAction > RKSetActionSetMaxAction, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unknown performAction = %lu.", (unsigned long)performAction] raise]; }
  
  if((RK_EXPECTED(self == matchAgainstSet, 0)) && (performAction == RKSetActionAddMatches)) { goto exitNow; } // Fast path bypass on unusual case.

#ifdef USE_CORE_FOUNDATION
  if((setCount = (RKUInteger)CFSetGetCount((CFSetRef)matchAgainstSet)) == 0) { goto doAction; }
#else
  if((setCount = [matchAgainstSet count]) == 0) { goto doAction; }
#endif
  
  if(RK_EXPECTED((setObjects     = alloca(sizeof(id *) * setCount)) == NULL, 0)) { goto exitNow; }
  if(RK_EXPECTED((matchedObjects = alloca(sizeof(id *) * setCount)) == NULL, 0)) { goto exitNow; }
  
#ifdef USE_CORE_FOUNDATION
  CFSetGetValues((CFSetRef)matchAgainstSet, (const void **)(&setObjects[0]));
#else
  [[matchAgainstSet allObjects] getObjects:&setObjects[0]];
#endif
  
  for(atIndex = 0; atIndex < setCount; atIndex++) {
    if([setObjects[atIndex] isMatchedByRegex:regex] == YES) {
      if(performAction == RKSetActionObjectOfFirstMatch) { returnObject = setObjects[atIndex]; goto exitNow; }
      matchedObjects[matchedCount++] = setObjects[atIndex];
    }
  }

doAction:
  
  returnObject = NULL;
  switch(performAction) {
    case RKSetActionObjectOfFirstMatch: NSCAssert(matchedCount == 0, @"set RKSetActionObjectOfFirstMatch, matched count > 0 in performAction switch statement."); if(matchedCount == 0) { returnObject = NULL; goto exitNow; } break;
    case RKSetActionCountOfMatchingObjects: tempUIntegerResult = matchedCount; goto exitNow; break;
#ifdef USE_CORE_FOUNDATION
    case RKSetActionSetOfMatchingObjects:   returnObject = (id)RKMakeCollectable(CFSetCreate(kCFAllocatorDefault, (const void **)(&matchedObjects[0]), (CFIndex)matchedCount, &kCFTypeSetCallBacks)); break;
#else
    case RKSetActionSetOfMatchingObjects:   returnObject = [[NSSet alloc] initWithObjects:&matchedObjects[0] count:matchedCount]; break;
#endif // USE_CORE_FOUNDATION
    case RKSetActionAddMatches:             for(RKUInteger x = 0; x < matchedCount; x++) { [self addObject:matchedObjects[x]];    } goto exitNow; break;
    case RKSetActionRemoveMatches:          for(RKUInteger x = 0; x < matchedCount; x++) { [self removeObject:matchedObjects[x]]; } goto exitNow; break;
    default: returnObject = NULL; NSCAssert1(1 == 0, @"Unknown RKSetAction in switch block, performAction = %lu", (unsigned long)performAction); break;
  }

  RKAutorelease(returnObject);

exitNow:
  if(UIntegerResult != NULL) { *UIntegerResult = tempUIntegerResult; }
  return(returnObject);
}



-(id)anyObjectMatchingRegex:(id)aRegex
{
  return(RKDoSetAction(self, _cmd, self, aRegex, RKSetActionObjectOfFirstMatch, NULL));
}

-(BOOL)containsObjectMatchingRegex:(id)aRegex
{
  return(RKDoSetAction(self, _cmd, self, aRegex, RKSetActionObjectOfFirstMatch, NULL) != NULL ? YES : NO);
}

-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex
{
  RKUInteger matchCount = 0;
  RKDoSetAction(self, _cmd, self, aRegex, RKSetActionCountOfMatchingObjects, &matchCount);
  return(matchCount);
}

-(NSSet *)setByMatchingObjectsWithRegex:(id)aRegex
{
  return(RKDoSetAction(self, _cmd, self, aRegex, RKSetActionSetOfMatchingObjects, NULL));
}

@end

@implementation NSMutableSet (RegexKitAdditions)

- (void)addObjectsFromArray:(NSArray *)otherArray matchingRegex:(id)aRegex
{
  if(RK_EXPECTED(otherArray == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"otherArray == NULL."] raise]; }
  RKDoSetAction(self, _cmd, [NSSet setWithArray:otherArray], aRegex, RKSetActionAddMatches, NULL);
}

- (void)addObjectsFromSet:(NSSet *)otherSet matchingRegex:(id)aRegex
{
  if(RK_EXPECTED(otherSet == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"otherSet == NULL."] raise]; }
  RKDoSetAction(self, _cmd, otherSet, aRegex, RKSetActionAddMatches, NULL);
}

-(void)removeObjectsMatchingRegex:(id)aRegex
{
  RKDoSetAction(self, _cmd, self, aRegex, RKSetActionRemoveMatches, NULL);
}

@end
