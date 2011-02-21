//
//  NSDictionary.m
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

#import <RegexKit/NSDictionary.h>
#import <RegexKit/RegexKitPrivate.h>

typedef enum {
  RKDictionaryActionBooleanYesOnAnyKeyMatch = 0,
  RKDictionaryActionBooleanYesOnAnyObjectMatch = 1,
  RKDictionaryActionArrayOfMatchedKeys = 2,
  RKDictionaryActionArrayOfMatchedObjects = 3,
  RKDictionaryActionArrayOfObjectsForMatchedKeys = 4,
  RKDictionaryActionArrayOfKeysForMatchedObjects = 5,
  RKDictionaryActionDictionaryWithMatchedKeys = 6,
  RKDictionaryActionDictionaryWithMatchedObjects = 7,
  RKDictionaryActionAddMatches = 8,
  RKDictionaryActionRemoveMatches = 9,
  RKDictionaryActionDictionaryMaxAction = 9
} RKDictionaryAction;

static id RKDoDictionaryAction(id self, SEL _cmd, id matchAgainstDictionary, id aKeyRegex, id aObjectRegex, const RKDictionaryAction performAction, BOOL matchKeyAndObjectRegex);

static id RKDoDictionaryAction(id self, SEL _cmd, id matchAgainstDictionary, id aKeyRegex, id aObjectRegex, const RKDictionaryAction performAction, BOOL matchKeyAndObjectRegex) {
  id returnObject = NULL;
  RK_STRONG_REF id *keys = NULL, *objects = NULL, *matchedKeys = NULL, *matchedObjects = NULL;
  RKUInteger dictionaryCount = 0, atMatchIndex = 0, matchedCount = 0;
  RK_STRONG_REF RKRegex *keyRegex = NULL, *objectRegex = NULL;
  BOOL exitOnAnyMatch = NO;
  
  NSCParameterAssert(!((aKeyRegex == NULL) && (aObjectRegex == NULL)));
  
  if(RK_EXPECTED(self == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"self == NULL."] raise]; }
  if(RK_EXPECTED(_cmd == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"_cmd == NULL."] raise]; }
  if(RK_EXPECTED(matchAgainstDictionary == NULL, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"matchAgainstDictionary == NULL."] raise]; }
  if(RK_EXPECTED(performAction > RKDictionaryActionDictionaryMaxAction, 0)) { [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unknown performAction = %lu.", (unsigned long)performAction] raise]; }
  
  if((RK_EXPECTED(self == matchAgainstDictionary, 0)) && (performAction == RKDictionaryActionAddMatches)) { goto exitNow; } // Fast path bypass on unusual case.

  if(aKeyRegex    != NULL) { keyRegex    = RKRegexFromStringOrRegex(self, _cmd, aKeyRegex,    (RKCompileUTF8 | RKCompileNoUTF8Check), YES); }
  if(aObjectRegex != NULL) { objectRegex = RKRegexFromStringOrRegex(self, _cmd, aObjectRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES); }
  
#ifdef USE_CORE_FOUNDATION
  if((dictionaryCount = (RKUInteger)CFDictionaryGetCount((CFDictionaryRef)matchAgainstDictionary)) == 0) { goto doAction; }
#else
  if((dictionaryCount = [matchAgainstDictionary count]) == 0) { goto doAction; }
#endif
  
  if(RK_EXPECTED((keys           = alloca(sizeof(id *) * dictionaryCount)) == NULL, 0)) { return(NULL); }
  if(RK_EXPECTED((objects        = alloca(sizeof(id *) * dictionaryCount)) == NULL, 0)) { return(NULL); }
  if(RK_EXPECTED((matchedKeys    = alloca(sizeof(id *) * dictionaryCount)) == NULL, 0)) { return(NULL); }
  if(RK_EXPECTED((matchedObjects = alloca(sizeof(id *) * dictionaryCount)) == NULL, 0)) { return(NULL); }
  
#ifdef USE_CORE_FOUNDATION
  CFDictionaryGetKeysAndValues((CFDictionaryRef)matchAgainstDictionary, (const void **)(&keys[0]), (const void **)(&objects[0]));
#else
  [[matchAgainstDictionary allKeys]   getObjects:&keys[0]];
  [[matchAgainstDictionary allValues] getObjects:&objects[0]];
#endif
  
  if((performAction == RKDictionaryActionBooleanYesOnAnyKeyMatch) || (performAction == RKDictionaryActionBooleanYesOnAnyObjectMatch)) { exitOnAnyMatch = YES; }
  
  for(atMatchIndex = 0; atMatchIndex < dictionaryCount; atMatchIndex++) {
    BOOL didMatch = NO, didMatchKey = NO, didMatchObject = NO;

    if(keyRegex    != NULL) { if([keys[atMatchIndex]    isMatchedByRegex:keyRegex]    == YES) { didMatchKey    = YES; } }
    if(objectRegex != NULL) { if([objects[atMatchIndex] isMatchedByRegex:objectRegex] == YES) { didMatchObject = YES; } }

    if(matchKeyAndObjectRegex == YES) { didMatch = (didMatchKey && didMatchObject); } else { didMatch = (didMatchKey || didMatchObject); }

    if(didMatch == YES) {
      if(exitOnAnyMatch == YES) { returnObject = self; goto exitNow; }
      matchedKeys[matchedCount]      = keys[atMatchIndex];
      matchedObjects[matchedCount++] = objects[atMatchIndex];
    }
  }
  
doAction:
        
  returnObject = NULL;
  switch(performAction) {
    case RKDictionaryActionBooleanYesOnAnyObjectMatch:   // Fall-thru
    case RKDictionaryActionBooleanYesOnAnyKeyMatch:      NSCAssert(RK_EXPECTED(matchedCount == 0, 0), @"dictionary RKDictionaryActionBooleanYesOnAny(Key|Object)Match, matched count > 0 in performAction switch statement."); returnObject = NULL; goto exitNow; break;
#ifdef USE_CORE_FOUNDATION
    case RKDictionaryActionArrayOfKeysForMatchedObjects: // Fall-thru
    case RKDictionaryActionArrayOfMatchedKeys:           returnObject = (id)RKMakeCollectable(CFArrayCreate(kCFAllocatorDefault,
                                                                                                            (const void **)(&matchedKeys[0]),
                                                                                                            (CFIndex)matchedCount,
                                                                                                            &kCFTypeArrayCallBacks));
      break;
    case RKDictionaryActionArrayOfMatchedObjects:        // Fall-thru
    case RKDictionaryActionArrayOfObjectsForMatchedKeys: returnObject = (id)RKMakeCollectable(CFArrayCreate(kCFAllocatorDefault,
                                                                                                            (const void **)(&matchedObjects[0]),
                                                                                                            (CFIndex)matchedCount,
                                                                                                            &kCFTypeArrayCallBacks));
      break;
    case RKDictionaryActionDictionaryWithMatchedObjects: // Fall-thru
    case RKDictionaryActionDictionaryWithMatchedKeys:    returnObject = (id)RKMakeCollectable(CFDictionaryCreate(kCFAllocatorDefault,
                                                                                                                 (const void **)(&matchedKeys[0]),
                                                                                                                 (const void **)(&matchedObjects[0]), 
                                                                                                                 (CFIndex)matchedCount,
                                                                                                                 &kCFTypeDictionaryKeyCallBacks,
                                                                                                                 &kCFTypeDictionaryValueCallBacks));
      break;
#else
    case RKDictionaryActionArrayOfKeysForMatchedObjects: // Fall-thru
    case RKDictionaryActionArrayOfMatchedKeys:           returnObject = [[NSArray alloc] initWithObjects:&matchedKeys[0] count:matchedCount];      break;
    case RKDictionaryActionArrayOfMatchedObjects:        // Fall-thru
    case RKDictionaryActionArrayOfObjectsForMatchedKeys: returnObject = [[NSArray alloc] initWithObjects:&matchedObjects[0] count:matchedCount];   break;
    case RKDictionaryActionDictionaryWithMatchedObjects: // Fall-thru
    case RKDictionaryActionDictionaryWithMatchedKeys:    returnObject = [[NSDictionary alloc] initWithObjects:&matchedObjects[0] forKeys:&matchedKeys[0] count:matchedCount]; break;
#endif // USE_CORE_FOUNDATION
    case RKDictionaryActionAddMatches:    for(RKUInteger x = 0; x < matchedCount; x++) { [self setObject:matchedObjects[x] forKey:matchedKeys[x]]; } goto exitNow; break;
    case RKDictionaryActionRemoveMatches: for(RKUInteger x = 0; x < matchedCount; x++) { [self removeObjectForKey:matchedKeys[x]];                 } goto exitNow; break;

    default: returnObject = NULL; NSCAssert1(1 == 0, @"Unknown RKDictionaryAction in switch block, performAction = %lu", (unsigned long)performAction);            break;
  }
  RKAutorelease(returnObject);

exitNow:
  return(returnObject);
}


@implementation NSDictionary (RegexKitAdditions)
  
- (NSDictionary *)dictionaryByMatchingKeysWithRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, aRegex, NULL, RKDictionaryActionDictionaryWithMatchedKeys, NO));
}

- (NSDictionary *)dictionaryByMatchingObjectsWithRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, NULL, aRegex, RKDictionaryActionDictionaryWithMatchedObjects, NO));
}

- (BOOL)containsKeyMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, aRegex, NULL, RKDictionaryActionBooleanYesOnAnyKeyMatch, NO) == NULL ? NO : YES);
}

- (BOOL)containsObjectMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, NULL, aRegex, RKDictionaryActionBooleanYesOnAnyObjectMatch, NO) == NULL ? NO : YES);
}

- (NSArray *)keysMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, aRegex, NULL, RKDictionaryActionArrayOfMatchedKeys, NO));
}
- (NSArray *)keysForObjectsMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, NULL, aRegex, RKDictionaryActionArrayOfKeysForMatchedObjects, NO));
}

- (NSArray *)objectsForKeysMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, aRegex, NULL, RKDictionaryActionArrayOfObjectsForMatchedKeys, NO));
}

- (NSArray *)objectsMatchingRegex:(id)aRegex
{
  return(RKDoDictionaryAction(self, _cmd, self, NULL, aRegex, RKDictionaryActionArrayOfMatchedObjects, NO));
}

@end


//////////////////////////////////
//  Mutable Dictionary Methods  //
//////////////////////////////////


@implementation NSMutableDictionary (RegexKitAdditions)

- (void)addEntriesFromDictionary:(id)otherDictionary withKeysMatchingRegex:(id)aRegex
{
  if(RK_EXPECTED(otherDictionary == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"otherDictionary == NULL."] raise]; }
  RKDoDictionaryAction(self, _cmd, otherDictionary, aRegex, NULL, RKDictionaryActionAddMatches, NO);
}

- (void)addEntriesFromDictionary:(id)otherDictionary withObjectsMatchingRegex:(id)aRegex
{
  if(RK_EXPECTED(otherDictionary == NULL, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"otherDictionary == NULL."] raise]; }
  RKDoDictionaryAction(self, _cmd, otherDictionary, NULL, aRegex, RKDictionaryActionAddMatches, NO);
}

- (void)removeObjectsMatchingRegex:(id)aRegex
{
  RKDoDictionaryAction(self, _cmd, self, NULL, aRegex, RKDictionaryActionRemoveMatches, NO);
}

- (void)removeObjectsForKeysMatchingRegex:(id)aRegex
{
  RKDoDictionaryAction(self, _cmd, self, aRegex, NULL, RKDictionaryActionRemoveMatches, NO);
}


@end
