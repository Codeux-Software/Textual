//
//  NSArray.m
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

#import <RegexKit/NSArray.h>
#import <RegexKit/RegexKitPrivate.h>

typedef enum {
  RKArrayActionIndexOfFirstMatch = 0,
  RKArrayActionArrayOfMatchingObjects = 1,
  RKArrayActionCountOfMatchingObjects = 2,
  RKArrayActionAddMatches = 3,
  RKArrayActionRemoveMatches = 4,
  RKArrayActionIndexSetOfMatchingObjects = 5,
  RKArrayActionArrayMaxAction = 5
} RKArrayAction;

static id RKDoArrayAction(id self, SEL _cmd, id matchAgainstArray, const NSRange *againstRange, id regexObject, const RKArrayAction performAction, RKUInteger *UIntegerResult);

@implementation NSArray (RegexKitAdditions)

static id RKDoArrayAction(id self, SEL _cmd, id matchAgainstArray, const NSRange *againstRange, id regexObject, const RKArrayAction performAction, RKUInteger *UIntegerResult) {
  RKUInteger arrayCount = 0, atIndex = 0, matchedCount = 0, matchAgainstArrayCount = 0, *matchedIndexes = NULL, tempUIntegerResult = 23;
  RKRegex *regex = RKRegexFromStringOrRegex(self, _cmd, regexObject, (RKCompileUTF8 | RKCompileNoUTF8Check), YES);
  id returnObject = NULL, *arrayObjects = NULL, *matchedObjects = NULL;
  NSRange matchRange = NSMakeRange(NSNotFound, 0);

  if(RK_EXPECTED(self == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"self == NULL."] raise]; }
  if(RK_EXPECTED(_cmd == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"_cmd == NULL."] raise]; }
  if(RK_EXPECTED(matchAgainstArray == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"matchAgainstArray == NULL."] raise]; }
  if(RK_EXPECTED(performAction > RKArrayActionArrayMaxAction, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unknown performAction = %lu.", (unsigned long)performAction] raise]; }

#ifdef USE_CORE_FOUNDATION
  matchAgainstArrayCount = (RKUInteger)CFArrayGetCount((CFArrayRef)matchAgainstArray);
#else
  matchAgainstArrayCount = [matchAgainstArray count];
#endif
  
  if(againstRange == NULL) { matchRange = NSMakeRange(0, matchAgainstArrayCount); } else { matchRange = *againstRange; }

  if((RK_EXPECTED(matchRange.location > matchAgainstArrayCount, 0)) || (RK_EXPECTED((matchRange.location + matchRange.length) > matchAgainstArrayCount, 0))) { [[NSException rkException:NSRangeException for:self selector:_cmd localizeReason:@"Range %@ exceeds array length of %lu.", NSStringFromRange(matchRange), (unsigned long)matchAgainstArrayCount] raise]; }
  
  if((arrayCount = matchRange.length) == 0) { goto doAction; }

  if(RK_EXPECTED((arrayObjects   = alloca(sizeof(id *)       * arrayCount)) == NULL, 0)) { return(NULL); }
  if(RK_EXPECTED((matchedIndexes = alloca(sizeof(RKUInteger) * arrayCount)) == NULL, 0)) { return(NULL); }
  if(RK_EXPECTED((matchedObjects = alloca(sizeof(id *)       * arrayCount)) == NULL, 0)) { return(NULL); }
  
#ifdef USE_CORE_FOUNDATION
  CFArrayGetValues((CFArrayRef)matchAgainstArray, (CFRange){(CFIndex)matchRange.location, (CFIndex)matchRange.length}, (const void **)(&arrayObjects[0]));
#else
  [matchAgainstArray getObjects:&arrayObjects[0] range:matchRange];
#endif
  
  for(atIndex = 0; atIndex < arrayCount; atIndex++) {
    if([arrayObjects[atIndex] isMatchedByRegex:regex] == YES) {
      if(performAction == RKArrayActionIndexOfFirstMatch)    { tempUIntegerResult = (atIndex + matchRange.location); goto exitNow; }
      matchedIndexes[matchedCount]   = (atIndex + matchRange.location);
      matchedObjects[matchedCount++] = arrayObjects[atIndex];
    }
  }

doAction:
  
  switch(performAction) {
    case RKArrayActionIndexOfFirstMatch: NSCAssert(matchedCount == 0, @"array RKIndexOfFirstMatch, matched count > 0 in performAction switch statement."); if(matchedCount == 0) { tempUIntegerResult = NSNotFound; goto exitNow; } break;
    case RKArrayActionCountOfMatchingObjects: tempUIntegerResult = matchedCount; goto exitNow; break;
#ifdef USE_CORE_FOUNDATION
    case RKArrayActionArrayOfMatchingObjects: returnObject = (id)RKMakeCollectable(CFArrayCreate(kCFAllocatorDefault, (const void **)(&matchedObjects[0]), (CFIndex)matchedCount, &kCFTypeArrayCallBacks)); break;
#else
    case RKArrayActionArrayOfMatchingObjects: returnObject = [[NSArray alloc] initWithObjects:&matchedObjects[0] count:matchedCount];                          break;
#endif
    case RKArrayActionAddMatches:             for(RKUInteger x = 0; x < matchedCount; x++) { [self addObject:matchedObjects[x]];               } goto exitNow; break;
    case RKArrayActionRemoveMatches:          for(RKUInteger x = 0; x < matchedCount; x++) { [self removeObjectAtIndex:matchedIndexes[x] - x]; } goto exitNow; break;
    case RKArrayActionIndexSetOfMatchingObjects: {
      NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
      for(RKUInteger x = 0; x < matchedCount; x++) { [indexSet addIndex:matchedIndexes[x]]; }
      returnObject = [[NSIndexSet alloc] initWithIndexSet:indexSet];
      RKRelease(indexSet);
      }
      break;
    default: returnObject = NULL; NSCAssert1(1 == 0, @"Unknown RKArrayAction in switch block, performAction = %lu", (unsigned long)performAction);             break;
  }

  RKAutorelease(returnObject);

exitNow:
  if(UIntegerResult != NULL) { *UIntegerResult = tempUIntegerResult; }
  return(returnObject);
}


-(NSArray *)arrayByMatchingObjectsWithRegex:(id)aRegex
{
  return(RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionArrayOfMatchingObjects, NULL)); 
}

-(NSArray *)arrayByMatchingObjectsWithRegex:(id)aRegex inRange:(const NSRange)range
{
  return(RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionArrayOfMatchingObjects, NULL)); 
}

-(BOOL)containsObjectMatchingRegex:(id)aRegex
{
  RKUInteger result = 0;
  RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionIndexOfFirstMatch, &result);
  return((RKUInteger)(result != NSNotFound ? YES : NO)); 
}

-(BOOL)containsObjectMatchingRegex:(id)aRegex inRange:(const NSRange)range
{
  RKUInteger result = 0;
  RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionIndexOfFirstMatch, &result);
  return((RKUInteger)(result != NSNotFound ? YES : NO)); 
}

-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex
{
  RKUInteger result = 0;
  RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionCountOfMatchingObjects, &result);
  return(result);
}

-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range
{
  RKUInteger result = 0;
  RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionCountOfMatchingObjects, &result);
  return(result);
}

-(RKUInteger)indexOfObjectMatchingRegex:(id)aRegex
{
  RKUInteger result = NSNotFound;
  RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionIndexOfFirstMatch, &result);
  return(result);
}

-(RKUInteger)indexOfObjectMatchingRegex:(id)aRegex inRange:(const NSRange)range
{
  RKUInteger result = NSNotFound - 1;
  RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionIndexOfFirstMatch, &result); 
  return(result);
}

-(NSIndexSet *)indexSetOfObjectsMatchingRegex:(id)aRegex
{
  return(RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionIndexSetOfMatchingObjects, NULL)); 
}

-(NSIndexSet *)indexSetOfObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range
{
  return(RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionIndexSetOfMatchingObjects, NULL)); 
}

@end


@implementation NSMutableArray (RegexKitAdditions)

- (void)addObjectsFromArray:(NSArray *)otherArray matchingRegex:(id)aRegex;
{
  if(RK_EXPECTED(otherArray == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"otherArray == NULL."] raise]; }
  RKDoArrayAction(self, _cmd, otherArray, NULL, aRegex, RKArrayActionAddMatches, NULL);
}

-(void)removeObjectsMatchingRegex:(id)aRegex
{
  RKDoArrayAction(self, _cmd, self, NULL, aRegex, RKArrayActionRemoveMatches, NULL);
}

-(void)removeObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range
{
  RKDoArrayAction(self, _cmd, self, &range, aRegex, RKArrayActionRemoveMatches, NULL);
}

@end
