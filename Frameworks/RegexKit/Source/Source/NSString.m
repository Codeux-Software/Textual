//
//  NSString.m
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

#import <RegexKit/NSString.h>
#import <RegexKit/RegexKitPrivate.h>
#import <RegexKit/RKLock.h>

//#define REGEXKIT_DEBUG

/*************** Match and replace operations ***************/

static BOOL RKMatchAndExtractCaptureReferences(id self, const SEL _cmd, NSString * const extractString, RK_STRONG_REF const RKUInteger * const fromIndex, RK_STRONG_REF const RKUInteger * const toIndex, RK_STRONG_REF const NSRange * const range, id aRegex, const RKCompileOption compileOptions, const RKMatchOption matchOptions, const RKCaptureExtractOptions captureExtractOptions, NSString * const firstKey, va_list useVarArgsList);
static BOOL RKExtractCapturesFromMatchesWithKeysAndPointers(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) stringBuffer,
                                                            RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges,
                                                            NSString ** const RK_C99(restrict) keyStrings, RK_STRONG_REF void *** const RK_C99(restrict) keyConversionPointers,
                                                            const RKUInteger count, const RKCaptureExtractOptions captureExtractOptions);
static NSString *RKStringByMatchingAndExpanding(id self, const SEL _cmd, NSString * const searchString, RK_STRONG_REF const RKUInteger * const fromIndex, RK_STRONG_REF const RKUInteger * const toIndex, RK_STRONG_REF const NSRange * const searchStringRange, const RKUInteger count, id aRegex, NSString * const referenceString, RK_STRONG_REF va_list * const argListPtr, const BOOL expandOrReplace, RK_STRONG_REF RKUInteger * const matchedCountPtr);
static void RKEvaluateCopyInstructions(RK_STRONG_REF const RKCopyInstructionsBuffer * const instructionsBuffer, RK_STRONG_REF void * const toBuffer, const size_t bufferLength);
static NSString *RKStringFromCopyInstructions(id self, const SEL _cmd, RK_STRONG_REF const RKCopyInstructionsBuffer * const instructionsBuffer, const RKStringBufferEncoding stringEncoding) RK_ATTRIBUTES(malloc);
static BOOL RKApplyReferenceInstructions(id self, const SEL _cmd, RKRegex * const regex, RK_STRONG_REF const NSRange * const matchRanges, RK_STRONG_REF const RKStringBuffer * const stringBuffer,
                                         RK_STRONG_REF const RKReferenceInstructionsBuffer * const referenceInstructionsBuffer, RK_STRONG_REF RKCopyInstructionsBuffer * const appliedInstructionsBuffer);
static BOOL RKCompileReferenceString(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const referenceStringBuffer, RKRegex * const regex,\
                                     RK_STRONG_REF RKReferenceInstructionsBuffer * const instructionBuffer);
static BOOL RKAppendInstruction(RK_STRONG_REF RKReferenceInstructionsBuffer * const instructionsBuffer, const int op, RK_STRONG_REF const void * const ptr, const NSRange range);
static BOOL RKAppendCopyInstruction(RK_STRONG_REF RKCopyInstructionsBuffer * const copyInstructionsBuffer, RK_STRONG_REF const void * const ptr, const NSRange range);
static RKUInteger RKMutableStringMatch(id self, const SEL _cmd, id aRegex,
                                       RK_STRONG_REF const RKUInteger * RK_C99(restrict) fromIndex, RK_STRONG_REF const RKUInteger * RK_C99(restrict) toIndex,
                                       RK_STRONG_REF const NSRange * RK_C99(restrict) range, const RKUInteger count,
                                       NSString * const RK_C99(restrict) formatString, RK_STRONG_REF va_list * const RK_C99(restrict) argListPtr);

#ifdef REGEXKIT_DEBUG
static void dumpReferenceInstructions(RK_STRONG_REF const RKReferenceInstructionsBuffer *ins);
static void dumpCopyInstructions(RK_STRONG_REF const RKCopyInstructionsBuffer *ins);
#endif // REGEXKIT_DEBUG

/*************** End match and replace operations ***************/

#define PARSEREFERENCE_CONVERSION_ALLOWED  (1<<0)
#define PARSEREFERENCE_IGNORE_CONVERSION   (1<<1)
#define PARSEREFERENCE_STRICT_REFERENCE    (1<<2)
#define PARSEREFERENCE_PERFORM_CONVERSION  (1<<3)
#define PARSEREFERENCE_CHECK_CAPTURE_NAME  (1<<4)
  
static BOOL RKParseReference(RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) referenceBuffer, const NSRange referenceRange,
                             RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) subjectBuffer, RK_STRONG_REF const NSRange * const RK_C99(restrict) subjectMatchResultRanges,
                             RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF RKUInteger * const RK_C99(restrict) parsedReferenceUInteger,
                             RK_STRONG_REF void * const RK_C99(restrict) conversionPtr, const int parseReferenceOptions, RK_STRONG_REF NSRange * const RK_C99(restrict) parsedRange,
                             RK_STRONG_REF NSRange * const RK_C99(restrict) parsedReferenceRange, NSString ** const RK_C99(restrict) errorString,
                             RK_STRONG_REF void *** const RK_C99(restrict) autoreleasePool, RK_STRONG_REF RKUInteger * const RK_C99(restrict) autoreleasePoolIndex);
  
/* Although the docs claim NSDate is multithreading safe, testing indicates otherwise.  NSDate will mis-parse strings occasionally under heavy threaded access. */
static RK_STRONG_REF RKLock  *NSStringRKExtensionsNSDateLock  = NULL;
static               int32_t  NSStringRKExtensionsInitialized = 0;

#ifdef USE_CORE_FOUNDATION
static Boolean RKCFArrayEqualCallBack(const void *value1, const void *value2) { return(CFEqual(value1, value2)); }
static void RKTypeCollectionRelease(CFAllocatorRef allocator RK_ATTRIBUTES(unused), const void *ptr) { RKCFRelease(ptr); }
static CFArrayCallBacks noRetainArrayCallBacks = {0, NULL, RKTypeCollectionRelease, NULL, RKCFArrayEqualCallBack};
#endif // USE_CORE_FOUNDATION

@implementation NSString (RegexKitAdditions)

//
// +initialize is called by the runtime just before the class receives its first message.
//

static void NSStringRKExtensionsInitializeFunction(void);

+ (void)initalize
{
  NSStringRKExtensionsInitializeFunction();
}

static void NSStringRKExtensionsInitializeFunction(void) {
  RKAtomicMemoryBarrier(); // Extra cautious
  if(NSStringRKExtensionsInitialized == 1) { return; }
  
  if(RKAtomicCompareAndSwapInt(0, 1, &NSStringRKExtensionsInitialized)) {
    NSAutoreleasePool *lockPool = [[NSAutoreleasePool alloc] init];
    
    NSStringRKExtensionsNSDateLock = [(RKLock *)NSAllocateObject([RKLock class], 0, NULL) init];
#ifdef    ENABLE_MACOSX_GARBAGE_COLLECTION
    if([objc_getClass("NSGarbageCollector") defaultCollector] != NULL) { [[objc_getClass("NSGarbageCollector") defaultCollector] disableCollectorForPointer:NSStringRKExtensionsNSDateLock]; }
#endif // ENABLE_MACOSX_GARBAGE_COLLECTION
    [lockPool release];
    lockPool = NULL;
  }
}

//
// getCapturesWithRegexAndReferences: methods
//

- (BOOL)getCapturesWithRegexAndReferences:(id)aRegex, ...
{
  va_list varArgsList; va_start(varArgsList, aRegex);
  return(RKMatchAndExtractCaptureReferences(self, _cmd, self, NULL, NULL, NULL, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), RKMatchNoUTF8Check, (RKCaptureExtractAllowConversions | RKCaptureExtractStrictReference), NULL, varArgsList));
}

- (BOOL)getCapturesWithRegex:(id)aRegex inRange:(const NSRange)range references:(NSString * const)firstReference, ...
{
  va_list varArgsList; va_start(varArgsList, firstReference);
  return(RKMatchAndExtractCaptureReferences(self, _cmd, self, NULL, NULL, &range, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), RKMatchNoUTF8Check, (RKCaptureExtractAllowConversions | RKCaptureExtractStrictReference), firstReference, varArgsList));
}

- (BOOL)getCapturesWithRegex:(id)aRegex inRange:(const NSRange)range arguments:(va_list)argList
{
  return(RKMatchAndExtractCaptureReferences(self, _cmd, self, NULL, NULL, &range, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), RKMatchNoUTF8Check, (RKCaptureExtractAllowConversions | RKCaptureExtractStrictReference), NULL, argList));
}

//
// rangesOfRegex: methods
//

- (NSRange *)rangesOfRegex:(id)aRegex
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  RKRegex *regex = RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES);
  NSRange *matchRanges = [regex rangesForCharacters:stringBuffer.characters length:stringBuffer.length inRange:NSMakeRange(0, stringBuffer.length) options:RKMatchNoUTF8Check];
  if(matchRanges != NULL) { RKUInteger captures = [regex captureCount]; for(RKUInteger x = 0; x < captures; x++) { matchRanges[x] = RKutf8to16(self, matchRanges[x]); } }
  return(matchRanges);
}

- (NSRange *)rangesOfRegex:(id)aRegex inRange:(const NSRange)range
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  RKRegex *regex = RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES);
  NSRange *matchRanges = [regex rangesForCharacters:stringBuffer.characters length:stringBuffer.length inRange:RKutf16to8(self, range) options:RKMatchNoUTF8Check];
  if(matchRanges != NULL) { RKUInteger captures = [regex captureCount]; for(RKUInteger x = 0; x < captures; x++) { matchRanges[x] = RKutf8to16(self, matchRanges[x]); } }
  return(matchRanges);
}

//
// rangeOfRegex: methods
//

- (NSRange)rangeOfRegex:(id)aRegex
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  return(RKutf8to16(self, [RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES) rangeForCharacters:stringBuffer.characters length:stringBuffer.length inRange:NSMakeRange(0, stringBuffer.length) captureIndex:0 options:RKMatchNoUTF8Check]));
}

- (NSRange)rangeOfRegex:(id)aRegex inRange:(const NSRange)range capture:(const RKUInteger)capture
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  return(RKutf8to16(self, [RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES) rangeForCharacters:stringBuffer.characters length:stringBuffer.length inRange:RKutf16to8(self, range) captureIndex:capture options:RKMatchNoUTF8Check]));
}

//
// isMatchedByRegex: methods
//

- (BOOL)isMatchedByRegex:(id)aRegex
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES) matchesCharacters:stringBuffer.characters length:stringBuffer.length inRange:NSMakeRange(0, stringBuffer.length) options:RKMatchNoUTF8Check]);
}

- (BOOL)isMatchedByRegex:(id)aRegex inRange:(const NSRange)range
{
  RKStringBuffer stringBuffer = RKStringBufferWithString(self);
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES) matchesCharacters:stringBuffer.characters length:stringBuffer.length inRange:RKutf16to8(self, range) options:RKMatchNoUTF8Check]);
}

//
// matchEnumeratorWithRegex: methods
//

-(RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex
{
  return([RKEnumerator enumeratorWithRegex:aRegex string:self]);
}

-(RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex inRange:(const NSRange)range
{
  return([RKEnumerator enumeratorWithRegex:aRegex string:self inRange:range]);
}

//
// stringByMatching:withReferenceString: methods
//

- (NSString *)stringByMatching:(id)aRegex withReferenceString:(NSString * const)referenceString
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, NULL,     1, aRegex, referenceString, NULL, NO, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceString:(NSString * const)referenceString
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range,   1, aRegex, referenceString, NULL, NO, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)referenceString
//{ return(RKStringByMatchingAndExpanding(self, _cmd, self, &anIndex, NULL, NULL, 1, aRegex, referenceString, NULL, NO, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)string
//{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, &anIndex, NULL, 1, aRegex, referenceString, NULL, NO, NULL)); }

//
// stringByMatching:withReferenceFormat: methods
//

- (NSString *)stringByMatching:(id)aRegex withReferenceFormat:(NSString * const)referenceFormatString, ...
{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, NULL,     1, aRegex, referenceFormatString, &argList, NO, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString, ...
{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range,   1, aRegex, referenceFormatString, &argList, NO, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range, 1, aRegex, referenceFormatString, (va_list *)&argList, NO, NULL));  }

//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...
//{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, &anIndex, NULL, NULL, 1, aRegex, referenceFormatString, &argList, NO, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...
//{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, &anIndex, NULL, 1, aRegex, referenceFormatString, &argList, NO, NULL)); }

//
// stringByMatching:replace:withString: methods
//

- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, NULL,     count, aRegex, referenceString, NULL, YES, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range,   count, aRegex, referenceString, NULL, YES, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString
//{ return(RKStringByMatchingAndExpanding(self, _cmd, self, &anIndex, NULL, NULL, count, aRegex, referenceString, NULL, YES, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString
//{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, &anIndex, NULL, count, aRegex, referenceString, NULL, YES, NULL)); }

//
// stringByMatching:replace:withReferenceFormat: methods
//

- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...
{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, NULL,    count, aRegex, referenceFormatString, &argList, YES, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...
{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range,   count, aRegex, referenceFormatString, &argList, YES, NULL)); }

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList
{ return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, NULL, &range, count, aRegex, referenceFormatString, (va_list *)&argList, YES, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...
//{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, &anIndex, NULL, NULL, count, aRegex, referenceFormatString, &argList, YES, NULL)); }

//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...
//{ va_list argList; va_start(argList, referenceFormatString); return(RKStringByMatchingAndExpanding(self, _cmd, self, NULL, &anIndex, NULL, count, aRegex, referenceFormatString, &argList, YES, NULL)); }

@end

/* NSMutableString additions */

@implementation NSMutableString (RegexKitAdditions)

//
// match:replace:withString: methods
//

-(RKUInteger)match:(id)aRegex replace:(const RKUInteger)count withString:(NSString * const)replaceString
{ return(RKMutableStringMatch(self, _cmd, aRegex, NULL, NULL, NULL,     count, replaceString, NULL)); }

-(RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withString:(NSString * const)replaceString
{ return(RKMutableStringMatch(self, _cmd, aRegex, NULL, NULL, &range,   count, replaceString, NULL)); }

//-(RKUInteger)match:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withString:(NSString * const)replaceString
//{ return(RKMutableStringMatch(self, _cmd, aRegex, &anIndex, NULL, NULL, count, replaceString, NULL)); }

//-(RKUInteger)match:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withString:(NSString * const)replaceString
//{ return(RKMutableStringMatch(self, _cmd, aRegex, NULL, &anIndex, NULL, count, replaceString, NULL)); }

//
// match:replace:withFormat: methods
//

-(RKUInteger)match:(id)aRegex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...
{ va_list argList; va_start(argList, formatString); return(RKMutableStringMatch(self, _cmd, aRegex, NULL, NULL, NULL,     count, formatString, &argList)); }

-(RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...
{ va_list argList; va_start(argList, formatString); return(RKMutableStringMatch(self, _cmd, aRegex, NULL, NULL, &range,   count, formatString, &argList)); }

-(RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withFormat:(NSString * const)formatString arguments:(va_list)argList
{ return(RKMutableStringMatch(self, _cmd, aRegex, NULL, NULL, &range, count, formatString, (va_list *)&argList)); }

//-(RKUInteger)match:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...
//{ va_list argList; va_start(argList, formatString); return(RKMutableStringMatch(self, _cmd, aRegex, &anIndex, NULL, NULL, count, formatString, &argList)); }

//-(RKUInteger)match:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...
//{ va_list argList; va_start(argList, formatString); return(RKMutableStringMatch(self, _cmd, aRegex, NULL, &anIndex, NULL, count, formatString, &argList)); }

@end

static RKUInteger RKMutableStringMatch(id self, const SEL _cmd, id aRegex,
                                       RK_STRONG_REF const RKUInteger * RK_C99(restrict) fromIndex, RK_STRONG_REF const RKUInteger * RK_C99(restrict) toIndex,
                                       RK_STRONG_REF const NSRange * RK_C99(restrict) range, const RKUInteger count,
                                       NSString * const RK_C99(restrict) formatString, RK_STRONG_REF va_list * const RK_C99(restrict) argListPtr) {
  RKUInteger replaceCount = 0;
  RK_STRONG_REF NSString * RK_C99(restrict) replacedString = RKStringByMatchingAndExpanding(self, _cmd, self, fromIndex, toIndex, range, count, aRegex, formatString, argListPtr, YES, &replaceCount);
  if(replacedString == self) { return(0); }
#ifdef USE_CORE_FOUNDATION
  CFStringReplaceAll((CFMutableStringRef)self, (CFStringRef)replacedString);
#else  // USE_CORE_FOUNDATION is not defined
  [self setString:replacedString];
#endif // USE_CORE_FOUNDATION
  return(replaceCount);
}


static const unsigned char utf8ExtraBytes[] = {
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5 };

static const unsigned char utf8ExtraUTF16Characters[] = {
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2 };

unsigned char RKLengthOfUTF8Character(const unsigned char *p) {
  const unsigned char c = *p;
  if (c < 128) { return(1); }
  const unsigned char idx = c & 0x3f;
  return(utf8ExtraBytes[idx] + 1);
}

/*
int utf16_length(const unsigned char *string) {
  const unsigned char *p;
  int utf16len = 0;
  
  for (p = string; *p != 0; p++) {
    utf16len++;
    const unsigned char c = *p;
    if (c < 128) { continue; }
    const unsigned char idx = c & 0x3f;
    p += utf8ExtraBytes[idx];
    utf16len += utf8ExtraUTF16Characters[idx];
  }
  return(utf16len);
}
*/

NSRange RKRangeForUTF8CharacterAtLocation(RKStringBuffer *stringBuffer, RKUInteger utf8Location) {
  if(stringBuffer == NULL) { [[NSException rkException:NSInvalidArgumentException localizeReason:@"The stringBuffer parameter is NULL."] raise]; }
  RKUInteger stringUTF8Location = utf8Location;
  
  // Find the start of the previous unicode character.

  if((stringBuffer->length == stringUTF8Location) && (stringUTF8Location > 0)) { stringUTF8Location--; }
  if(((unsigned char)stringBuffer->characters[stringUTF8Location] > 127) && ((unsigned char)stringBuffer->characters[stringUTF8Location] < 0xc0)) {
    while((stringUTF8Location > 0) && (((unsigned char)stringBuffer->characters[stringUTF8Location] > 127) && ((unsigned char)stringBuffer->characters[stringUTF8Location] < 0xc0))) { stringUTF8Location--; }
  }

  return(NSMakeRange(stringUTF8Location, RKLengthOfUTF8Character((unsigned char *)stringBuffer->characters + stringUTF8Location)));
}

NSRange RKConvertUTF8ToUTF16RangeForString(NSString *string, NSRange utf8Range) {
  if(string == NULL) { [[NSException rkException:NSInvalidArgumentException localizeReason:@"String parameter is NULL."] raise]; }
  RKStringBuffer stringBuffer = RKStringBufferWithString(string);
  return(RKConvertUTF8ToUTF16RangeForStringBuffer(&stringBuffer, utf8Range));
}

NSRange RKConvertUTF8ToUTF16RangeForStringBuffer(RKStringBuffer *stringBuffer, NSRange utf8Range) {
  if(stringBuffer == NULL) { [[NSException rkException:NSInvalidArgumentException localizeReason:@"The stringBuffer parameter is NULL."] raise]; }
  
  if(utf8Range.location == NSNotFound) { return(utf8Range); }

  if((utf8Range.location > stringBuffer->length) || (NSMaxRange(utf8Range) > stringBuffer->length)) { [[NSException rkException:NSRangeException localizeReason:@"RKConvertUTF8ToUTF16RangeForStringBuffer: Range invalid. utf8Range: %@. MaxRange: %lu stringBuffer->length: %lu", NSStringFromRange(utf8Range), (unsigned long)NSMaxRange(utf8Range), (unsigned long)stringBuffer->length] raise]; }
  
#ifdef USE_CORE_FOUNDATION
  if((stringBuffer->encoding == kCFStringEncodingMacRoman) || (stringBuffer->encoding == kCFStringEncodingASCII)) { return(utf8Range); }
#else
  if((stringBuffer->encoding == NSMacOSRomanStringEncoding) || (stringBuffer->encoding == NSASCIIStringEncoding)) { return(utf8Range); }
#endif
  
  RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 1, "UTF8 to UTF16 requires slow conversion.");
  const unsigned char *p = (const unsigned char *)stringBuffer->characters;
  RKUInteger utf16len = 0;
  NSRange utf16Range = NSMakeRange(NSNotFound, 0);
  
  while((unsigned)(p - (const unsigned char *)stringBuffer->characters) < NSMaxRange(utf8Range)) {
    if((unsigned)(p - (const unsigned char *)stringBuffer->characters) == utf8Range.location) { utf16Range.location = utf16len; }
    
    const unsigned char c = *p;
    p++;
    utf16len++;
    if(c < 128) { continue; }
    const unsigned char idx = c & 0x3f;
    p += utf8ExtraBytes[idx];
    utf16len += utf8ExtraUTF16Characters[idx];
  }
  if((unsigned)(p - (const unsigned char *)stringBuffer->characters) == utf8Range.location) { utf16Range.location = utf16len; }
  utf16Range.length = utf16len - utf16Range.location;

  RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, NSMaxRange(utf8Range), -1, 2, "UTF8 to UTF16 requires slow conversion.");
  
  return(utf16Range);
}

NSRange RKConvertUTF16ToUTF8RangeForString(NSString *string, NSRange utf16Range) {
  if(string == NULL) { [[NSException rkException:NSInvalidArgumentException localizeReason:@"String parameter is NULL."] raise]; }
  RKStringBuffer stringBuffer = RKStringBufferWithString(string);
  return(RKConvertUTF16ToUTF8RangeForStringBuffer(&stringBuffer, utf16Range));
}

NSRange RKConvertUTF16ToUTF8RangeForStringBuffer(RKStringBuffer *stringBuffer, NSRange utf16Range) {
  if(stringBuffer == NULL) { [[NSException rkException:NSInvalidArgumentException localizeReason:@"The stringBuffer parameter is NULL."] raise]; }

  if(utf16Range.location == NSNotFound) { return(utf16Range); }

  RKUInteger stringLength = [stringBuffer->string length];
  if((utf16Range.location > stringLength) || (NSMaxRange(utf16Range) > stringLength)) { [[NSException rkException:NSRangeException localizeReason:@"RKConvertUTF16ToUTF8RangeForStringBuffer: Range invalid. utf16Range: %@. MaxRange: %lu stringLength: %lu", NSStringFromRange(utf16Range), (unsigned long)NSMaxRange(utf16Range), (unsigned long)stringLength] raise]; }
  
#ifdef USE_CORE_FOUNDATION
  if((stringBuffer->encoding == kCFStringEncodingMacRoman) || (stringBuffer->encoding == kCFStringEncodingASCII)) { return(utf16Range); }
#else
  if((stringBuffer->encoding == NSMacOSRomanStringEncoding) || (stringBuffer->encoding == NSASCIIStringEncoding)) { return(utf16Range); }
#endif
  RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 1, "UTF16 to UTF8 requires slow conversion.");

  const unsigned char *p = (const unsigned char *)stringBuffer->characters;
  RKUInteger utf16len = 0;
  NSRange utf8Range = NSMakeRange(NSNotFound, 0);
  
  while(utf16len < NSMaxRange(utf16Range)) {
    if(utf16len == utf16Range.location) { utf8Range.location = (p - (const unsigned char *)stringBuffer->characters); }
    
    const unsigned char c = *p;
    p++;
    utf16len++;
    if(c < 128) { continue; }
    const unsigned char idx = c & 0x3f;
    p += utf8ExtraBytes[idx];
    utf16len += utf8ExtraUTF16Characters[idx];
  }
  if(utf16len == utf16Range.location) { utf8Range.location = (p - (const unsigned char *)stringBuffer->characters); }
  utf8Range.length = (p - (const unsigned char *)stringBuffer->characters) - utf8Range.location;
  
  RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, NSMaxRange(utf8Range), -1, 2, "UTF16 to UTF8 requires slow conversion.");

  return(utf8Range);
}


/* Functions for performing various regex string tasks, most private. */


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


static BOOL RKMatchAndExtractCaptureReferences(id self, const SEL _cmd, NSString * const RK_C99(restrict) extractString,
                                               RK_STRONG_REF const RKUInteger * const RK_C99(restrict) fromIndex,
                                               RK_STRONG_REF const RKUInteger * const RK_C99(restrict) toIndex,
                                               RK_STRONG_REF const NSRange    * const RK_C99(restrict) range,
                                               id aRegex,
                                               const RKCompileOption         compileOptions,
                                               const RKMatchOption           matchOptions,
                                               const RKCaptureExtractOptions captureExtractOptions,
                                               NSString * const firstKey,    va_list useVarArgsList) {
  RKMatchErrorCode matchErrorCode = RKMatchErrorNoError;
  RK_STRONG_REF NSRange * RK_C99(restrict) matchRanges = NULL;
  NSRange searchRange = NSMakeRange(NSNotFound, 0);
  RKStringBuffer stringBuffer;
  BOOL returnResult = NO;
  RKRegex *regex = NULL;
  RKUInteger captureCount = 0, fromIndexByte = 0;
  
  regex = RKRegexFromStringOrRegex(self, _cmd, aRegex, (compileOptions | RKCompileUTF8 | RKCompileNoUTF8Check), YES);

  if(RK_EXPECTED(regex == NULL, 0)) { goto exitNow; }

  captureCount = [regex captureCount];  
  if(RK_EXPECTED((matchRanges = alloca(RK_PRESIZE_CAPTURE_COUNT(captureCount) * sizeof(NSRange))) == NULL, 0)) { goto exitNow; }
  
  stringBuffer = RKStringBufferWithString(extractString);
  if(RK_EXPECTED(stringBuffer.characters == NULL, 0)) { goto exitNow; }

  if(fromIndex != NULL) { fromIndexByte = RKutf16to8(self, NSMakeRange(*fromIndex, 0)).location; }

  if((fromIndex == NULL) && (toIndex == NULL) && (range == NULL)) { searchRange = NSMakeRange(0, stringBuffer.length);                               }
  else if(range     != NULL)                                      { searchRange = RKutf16to8(self, *range);                                          }
  else if(fromIndex != NULL)                                      { searchRange = NSMakeRange(fromIndexByte, (stringBuffer.length - fromIndexByte)); }
  else if(toIndex   != NULL)                                      { searchRange = RKutf16to8(self, NSMakeRange(0, *toIndex));                        }
  
  if((matchErrorCode = [regex getRanges:matchRanges count:RK_PRESIZE_CAPTURE_COUNT(captureCount) withCharacters:stringBuffer.characters length:stringBuffer.length inRange:searchRange options:matchOptions]) <= 0) { goto exitNow; }
  
  returnResult = RKExtractCapturesFromMatchesWithKeyArguments(self, _cmd, (const RKStringBuffer *)&stringBuffer, regex, matchRanges, captureExtractOptions, firstKey, useVarArgsList);
  
exitNow:
    return(returnResult);
}

BOOL RKExtractCapturesFromMatchesWithKeyArguments(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) stringBuffer, RKRegex * const RK_C99(restrict) regex,
                                                  RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges, const RKCaptureExtractOptions captureExtractOptions,
                                                  NSString * const firstKey, va_list useVarArgsList) {
  RKUInteger stringArgumentsCount = 0, count = 0, x = 0;
  RK_STRONG_REF void ***keyConversionPointers = NULL;
  RK_STRONG_REF NSString **keyStrings = NULL;
  va_list varArgsList;

  va_copy(varArgsList, useVarArgsList);
  if(firstKey != NULL)                           { stringArgumentsCount++; if(va_arg(varArgsList, void **) != NULL) { stringArgumentsCount++; } else { goto finishedCountingArgs; } }
  while(va_arg(varArgsList, NSString *) != NULL) { stringArgumentsCount++; if(va_arg(varArgsList, void **) != NULL) { stringArgumentsCount++; } else { break; } }
  va_end(varArgsList);
  
finishedCountingArgs:
  if(RK_EXPECTED((stringArgumentsCount & 0x1) == 1, 0)) { [[NSException rkException:NSInvalidArgumentException for:self selector:_cmd localizeReason:@"Not an even pair of key and pointer to a pointer arguments."] raise]; }

  count = stringArgumentsCount / 2;
  
  if(RK_EXPECTED((keyStrings            = alloca(count * sizeof(NSString **))) == NULL, 0)) { goto errorExit; }
  if(RK_EXPECTED((keyConversionPointers = alloca(count * sizeof(void ***)))    == NULL, 0)) { goto errorExit; }
  
  va_copy(varArgsList, useVarArgsList);
  for(x = 0; x < count; x++) {
    if((firstKey != NULL) && (x == 0)) { keyStrings[x]            = firstKey;                        }
    else {                               keyStrings[x]            = va_arg(varArgsList, NSString *); }
                                         keyConversionPointers[x] = va_arg(varArgsList, void **);
  }
  va_end(varArgsList);
  
  return(RKExtractCapturesFromMatchesWithKeysAndPointers(self, _cmd, stringBuffer, regex, matchRanges, keyStrings, keyConversionPointers, count, captureExtractOptions));
  
errorExit:
    return(NO);
}

// Takes a set of match results and loops over all keys, parses them, and fills in the result.  parseReference does the heavy work and conversion
static BOOL RKExtractCapturesFromMatchesWithKeysAndPointers(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) stringBuffer, 
                                                            RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges,
                                                            NSString ** const RK_C99(restrict) keyStrings, RK_STRONG_REF void *** const RK_C99(restrict) keyConversionPointers,
                                                            const RKUInteger count, const RKCaptureExtractOptions captureExtractOptions) {
  RKUInteger x = 0, autoreleaseObjectsIndex = 0;
  NSException * RK_C99(restrict) throwException = NULL;
  RK_STRONG_REF void ** RK_C99(restrict) autoreleaseObjects = NULL;
  NSString *parseError = NULL;
  RKStringBuffer keyBuffer;
  BOOL returnResult = NO;
  const int parseReferenceOptions = ((((captureExtractOptions & RKCaptureExtractAllowConversions)  != 0) ? PARSEREFERENCE_CONVERSION_ALLOWED : 0) |
                                     (((captureExtractOptions & RKCaptureExtractStrictReference)   != 0) ? PARSEREFERENCE_STRICT_REFERENCE   : 0) |
                                     (((captureExtractOptions & RKCaptureExtractIgnoreConversions) != 0) ? PARSEREFERENCE_IGNORE_CONVERSION  : 0) |
                                     PARSEREFERENCE_PERFORM_CONVERSION | PARSEREFERENCE_CHECK_CAPTURE_NAME);
  
  NSCParameterAssert(RK_EXPECTED(self != NULL, 1) && RK_EXPECTED(_cmd != NULL, 1) && RK_EXPECTED(keyConversionPointers != NULL, 1) && RK_EXPECTED(keyStrings != NULL, 1) && RK_EXPECTED(stringBuffer != NULL, 1) && RK_EXPECTED(matchRanges != NULL, 1) && RK_EXPECTED(regex != NULL, 1));
  
  if(RK_EXPECTED((autoreleaseObjects = alloca(count * sizeof(void *))) == NULL, 0)) { goto exitNow; }

#ifdef USE_MACRO_EXCEPTIONS
NS_DURING
#else  // USE_MACRO_EXCEPTIONS is not defined
@try {
#endif // USE_MACRO_EXCEPTIONS
  for(x = 0; x < count && RK_EXPECTED(throwException == NULL, 1); x++) {
    keyBuffer = RKStringBufferWithString(keyStrings[x]);
    if(RK_EXPECTED(RKParseReference((const RKStringBuffer *)&keyBuffer, NSMakeRange(0, keyBuffer.length), stringBuffer,
                                    matchRanges, regex, NULL, keyConversionPointers[x], parseReferenceOptions, NULL, NULL, &parseError,
                                    (void ***)autoreleaseObjects, &autoreleaseObjectsIndex) == NO, 0)) {
      // We hold off on raising the exception until we make sure we've autoreleased any objects we created, if necessary.
      throwException = [NSException exceptionWithName:RKRegexCaptureReferenceException reason:RKPrettyObjectMethodString(parseError) userInfo:NULL];
    }
  }
#ifdef USE_MACRO_EXCEPTIONS
NS_HANDLER
  throwException = localException;
NS_ENDHANDLER
#else  // USE_MACRO_EXCEPTIONS is not defined
} @catch (NSException *exception) {
  throwException = exception;
}  
#endif // USE_MACRO_EXCEPTIONS

exitNow:
    
  if(autoreleaseObjectsIndex > 0) {
#ifdef USE_CORE_FOUNDATION
    if(RKRegexGarbageCollect == 0) { RKMakeCollectableOrAutorelease(CFArrayCreate(NULL, (const void **)&autoreleaseObjects[0], autoreleaseObjectsIndex, &noRetainArrayCallBacks)); }
    else { CFMakeCollectable(CFArrayCreate(NULL, (const void **)&autoreleaseObjects[0], autoreleaseObjectsIndex, &kCFTypeArrayCallBacks)); }
#else  // USE_CORE_FOUNDATION is not defined
    [NSArray arrayWithObjects:(id *)&autoreleaseObjects[0] count:autoreleaseObjectsIndex];
#endif // USE_CORE_FOUNDATION
  }
  
  if(RK_EXPECTED(throwException == NULL, 1)) { returnResult = YES; } else { [throwException raise]; }
  
  return(returnResult);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


/*!
@function RKStringByMatchingAndExpanding
 @abstract   This function forms the bulk of the search and replace machinery.
 @param      subjectString string to search
 @param      aRegex regex to use in performing matches
 @param      replaceWithString String to substitute for the matched string.  May contain references to matches via $# perl notation
 @param      replaceCount Pointer to an int if the number of replacements performed is needed, NULL otherwise.
 @result     Returns a new @link NSString NSString @/link with all the search and replaces applied.
 @discussion     <p>This function forms the bulk of the search and replace machinery.<p>
 <p>The high level overview of what happens is this function calls compileReferenceString which parses replaceWithString and assembles a list of instructions / operations to perform for each match.  For each match, a instructions to build a replacement string are built up instruction by instruction.  The first instruction copies the text inbetween the last match to the start of the current match. Replacement instructions are fairly simple, from copying verbatim a range of characters to appending the characters of a match. The instructions to build the replacement string are 'fully resolved' and consist only of verbatim copy operations. This continues until there are no more matches left.  The result is a list of instructions to process to create the finished, fully substituted string.</p>
 
 <p>The space to record the instructions to build the finished string are initially allocated off the stack.  If the number of instructions to complete the finished string is greater than the space allocated on the stack, the instructions are copied in to a NSMutableData buffer and that is grown as required.  The number of instructions allocated off the stack is determined by INITIAL_EDIT_INS.  This means that for the majority of cases the only time a call to malloc is required is at the very end, when its ready to process all of the instructions to create the replaced string.  Additionally, because only the ranges to be copied are recorded, no temporary buffers are create to keep intermediate results.</p>
*/

static NSString *RKStringByMatchingAndExpanding(id self, const SEL _cmd, NSString * const RK_C99(restrict) searchString, RK_STRONG_REF const RKUInteger * const RK_C99(restrict) fromIndex,
                                                RK_STRONG_REF const RKUInteger * const RK_C99(restrict) toIndex, RK_STRONG_REF const NSRange * const RK_C99(restrict) searchStringRange,
                                                const RKUInteger count, id aRegex, NSString * const RK_C99(restrict) referenceString,
                                                RK_STRONG_REF va_list * const RK_C99(restrict) argListPtr, const BOOL expandOrReplace,
                                                RK_STRONG_REF RKUInteger * const RK_C99(restrict) matchedCountPtr) {
  RK_STRONG_REF RKRegex * RK_C99(restrict) regex = NULL;
  RKStringBuffer searchStringBuffer, referenceStringBuffer;
  RKUInteger searchIndex = 0, matchedCount = 0, captureCount = 0, fromIndexByte = 0;
  RK_STRONG_REF NSRange * RK_C99(restrict) matchRanges = NULL; NSRange searchRange;
  RKMatchErrorCode matched;
  RKReferenceInstruction        stackReferenceInstructions[RK_DEFAULT_STACK_INSTRUCTIONS];
  RKCopyInstruction             stackCopyInstructions[RK_DEFAULT_STACK_INSTRUCTIONS];

  searchRange = NSMakeRange(NSNotFound, 0);
  regex = RKRegexFromStringOrRegex(self, _cmd, aRegex, (RKCompileUTF8 | RKCompileNoUTF8Check), YES);
  
  captureCount = [regex captureCount];
  if((matchRanges = alloca(sizeof(NSRange) * RK_PRESIZE_CAPTURE_COUNT(captureCount))) == NULL) { goto errorExit; }
  searchStringBuffer    = RKStringBufferWithString(searchString);
  referenceStringBuffer = RKStringBufferWithString((argListPtr == NULL) ? referenceString : (NSString *)RKAutorelease([[NSString alloc] initWithFormat:referenceString arguments:*argListPtr]));
  
  if(searchStringBuffer.characters    == NULL) { goto errorExit; }
  if(referenceStringBuffer.characters == NULL) { goto errorExit; }
  
  if(fromIndex != NULL) { fromIndexByte = RKutf16to8(self, NSMakeRange(*fromIndex, 0)).location; }

  if((fromIndex == NULL) && (toIndex == NULL) && (searchStringRange == NULL)) { searchRange = NSMakeRange(0, searchStringBuffer.length);                               }
  else if(searchStringRange != NULL)                                          { searchRange = RKutf16to8(self, *searchStringRange);                                    }
  else if(fromIndex   != NULL)                                                { searchRange = NSMakeRange(fromIndexByte, (searchStringBuffer.length - fromIndexByte)); }
  else if(toIndex     != NULL)                                                { searchRange = RKutf16to8(self, NSMakeRange(0, *toIndex));                              }
  
  RKReferenceInstructionsBuffer referenceInstructionsBuffer = RKMakeReferenceInstructionsBuffer(0, RK_DEFAULT_STACK_INSTRUCTIONS,    &stackReferenceInstructions[0], NULL);
  RKCopyInstructionsBuffer      copyInstructionsBuffer      = RKMakeCopyInstructionsBuffer(     0, RK_DEFAULT_STACK_INSTRUCTIONS, 0, &stackCopyInstructions[0],      NULL);
  
  if(RKCompileReferenceString(self, _cmd, &referenceStringBuffer, regex, &referenceInstructionsBuffer) == NO) { goto errorExit; }
  
  searchIndex = searchRange.location;
  
  if((expandOrReplace == YES) && (searchIndex != 0)) { if(RKAppendCopyInstruction(&copyInstructionsBuffer, searchStringBuffer.characters, NSMakeRange(0, searchIndex)) == NO) { goto errorExit; } }
  
  while((searchIndex < (searchRange.location + searchRange.length)) && ((matchedCount < count) || (count == RKReplaceAll))) {
    if((matched = [regex getRanges:&matchRanges[0] count:RK_PRESIZE_CAPTURE_COUNT(captureCount) withCharacters:searchStringBuffer.characters length:searchStringBuffer.length inRange:NSMakeRange(searchIndex, (searchRange.location + searchRange.length) - searchIndex) options:RKMatchNoUTF8Check]) < 0) {
      if(matched != RKMatchErrorNoMatch) { goto errorExit; }
      break;
    }
    
    if(expandOrReplace == YES) { if(RKAppendCopyInstruction(&copyInstructionsBuffer, searchStringBuffer.characters, NSMakeRange(searchIndex, (matchRanges[0].location - searchIndex))) == NO) { goto errorExit; } }
    searchIndex = matchRanges[0].location + matchRanges[0].length;
    if(RKApplyReferenceInstructions(self, _cmd, regex, matchRanges, &searchStringBuffer, &referenceInstructionsBuffer, &copyInstructionsBuffer) == NO) { goto errorExit; }
    matchedCount++;
  }

  if(matchedCountPtr != NULL) { *matchedCountPtr = matchedCount; }
  
  if(expandOrReplace == YES) {
    NSRange copySearchStringRange = NSMakeRange(searchIndex, (searchStringBuffer.length - searchIndex));
    if((copyInstructionsBuffer.length == 0) && (NSEqualRanges(NSMakeRange(0, copyInstructionsBuffer.length), copySearchStringRange) == YES)) { return(searchString); } // There were no changes, so the replaced string == search string.
    if(RKAppendCopyInstruction(&copyInstructionsBuffer, searchStringBuffer.characters, copySearchStringRange) == NO) { goto errorExit; }
  }
    
  return(RKStringFromCopyInstructions(self, _cmd, &copyInstructionsBuffer, RKUTF8StringEncoding));

errorExit:
  return(NULL);
}

NSString *RKStringFromReferenceString(id self, const SEL _cmd, RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) matchStringBuffer, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) referenceStringBuffer) {
  RKReferenceInstruction stackReferenceInstructions[RK_DEFAULT_STACK_INSTRUCTIONS];
  RKCopyInstruction      stackCopyInstructions[RK_DEFAULT_STACK_INSTRUCTIONS];

  RKReferenceInstructionsBuffer referenceInstructionsBuffer = RKMakeReferenceInstructionsBuffer(0, RK_DEFAULT_STACK_INSTRUCTIONS,    &stackReferenceInstructions[0], NULL);
  RKCopyInstructionsBuffer      copyInstructionsBuffer      = RKMakeCopyInstructionsBuffer(     0, RK_DEFAULT_STACK_INSTRUCTIONS, 0, &stackCopyInstructions[0],      NULL);
  
  if(RKCompileReferenceString(    self, _cmd, referenceStringBuffer, regex, &referenceInstructionsBuffer)                                   == NO) { goto errorExit; }
  if(RKApplyReferenceInstructions(self, _cmd, regex, matchRanges, matchStringBuffer, &referenceInstructionsBuffer, &copyInstructionsBuffer) == NO) { goto errorExit; }

  return(RKStringFromCopyInstructions(self, _cmd, &copyInstructionsBuffer, RKUTF8StringEncoding));

errorExit:
  return(NULL);
}


static NSString *RKStringFromCopyInstructions(id self, const SEL _cmd, RK_STRONG_REF const RKCopyInstructionsBuffer * const RK_C99(restrict) instructionsBuffer, const RKStringBufferEncoding stringEncoding) {
  RK_STRONG_REF char     * RK_C99(restrict) copyBuffer = NULL;
  RK_STRONG_REF NSString * RK_C99(restrict) copyString = NULL;
  
  if((copyBuffer = RKMallocNotScanned(instructionsBuffer->copiedLength + 1)) == NULL) { [[NSException rkException:NSMallocException for:self selector:_cmd localizeReason:@"Unable to allocate memory for final copied string."] raise]; }

  RKEvaluateCopyInstructions(instructionsBuffer, copyBuffer, (instructionsBuffer->copiedLength + 1));

#ifdef USE_CORE_FOUNDATION
  copyString = RKMakeCollectableOrAutorelease(CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, copyBuffer, stringEncoding, RK_EXPECTED(RKRegexGarbageCollect == 1, 0) ? kCFAllocatorNull : kCFAllocatorMalloc));
#else  // USE_CORE_FOUNDATION is not defined
  copyString = RKAutorelease([[NSString alloc] initWithBytesNoCopy:copyBuffer length:instructionsBuffer->copiedLength encoding:stringEncoding freeWhenDone:RK_EXPECTED(RKRegexGarbageCollect == 1, 0) ? NO : YES]);
#endif // USE_CORE_FOUNDATION

  return(copyString);
}

static void RKEvaluateCopyInstructions(RK_STRONG_REF const RKCopyInstructionsBuffer * const RK_C99(restrict) instructionsBuffer, RK_STRONG_REF void * const RK_C99(restrict) toBuffer, const size_t bufferLength) {
  NSCParameterAssert(instructionsBuffer != NULL); NSCParameterAssert(toBuffer != NULL); NSCParameterAssert(instructionsBuffer->isValid == YES); NSCParameterAssert(instructionsBuffer->instructions != NULL);
  RKUInteger instructionIndex = 0, copyBufferIndex = 0;
  
  while((instructionIndex < instructionsBuffer->length) && (copyBufferIndex <= bufferLength)) {
    RKCopyInstruction * RK_C99(restrict) atInstruction = &instructionsBuffer->instructions[instructionIndex];
    NSCParameterAssert(atInstruction != NULL); NSCParameterAssert((copyBufferIndex + atInstruction->length) <= instructionsBuffer->copiedLength); NSCParameterAssert((copyBufferIndex + atInstruction->length) <= bufferLength);
    
    memcpy(toBuffer + copyBufferIndex, atInstruction->ptr, atInstruction->length);
    copyBufferIndex += atInstruction->length;
    instructionIndex++;
  }
  NSCParameterAssert(copyBufferIndex <= bufferLength);
  ((char *)toBuffer)[copyBufferIndex] = 0;
}

static BOOL RKApplyReferenceInstructions(id self, const SEL _cmd, RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges,
                                         RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) stringBuffer,
                                         RK_STRONG_REF const RKReferenceInstructionsBuffer * const RK_C99(restrict) referenceInstructionsBuffer,
                                         RK_STRONG_REF RKCopyInstructionsBuffer * const RK_C99(restrict) appliedInstructionsBuffer) {
  int currentOp = 0, lastOp = referenceInstructionsBuffer->instructions[0].op;
  RKUInteger captureIndex = 0, instructionIndex = 0;
  NSMutableString *conversionString = NULL;
  
  while((lastOp != OP_STOP) && (instructionIndex < referenceInstructionsBuffer->length)) {
    RKReferenceInstruction * RK_C99(restrict) atInstruction = &referenceInstructionsBuffer->instructions[instructionIndex];
    const char *fromPtr = NULL;
    NSRange fromRange = NSMakeRange(0, 0);
    int thisOp = 0;
    lastOp = atInstruction->op;
    
    switch(atInstruction->op) {
      case OP_COPY_RANGE:        fromPtr = atInstruction->ptr;       fromRange = atInstruction->range;                       break;
      case OP_COPY_CAPTUREINDEX: fromPtr = stringBuffer->characters; fromRange = matchRanges[atInstruction->range.location]; break;
      case OP_COPY_CAPTURENAME :
        if((captureIndex = RKCaptureIndexForCaptureNameCharacters(regex, _cmd, atInstruction->ptr + atInstruction->range.location, atInstruction->range.length, matchRanges, YES)) == NSNotFound) { break; }
                                 fromPtr = stringBuffer->characters; fromRange = matchRanges[captureIndex];                  break;
        
      case OP_UPPERCASE_NEXT_CHAR: thisOp = atInstruction->op; break;
      case OP_LOWERCASE_NEXT_CHAR: thisOp = atInstruction->op; break;
      case OP_UPPERCASE_BEGIN:     thisOp = atInstruction->op; break;
      case OP_LOWERCASE_BEGIN:     thisOp = atInstruction->op; break;
      case OP_CHANGE_CASE_END:     thisOp = atInstruction->op; break;
      case OP_STOP:                                            break;
      
      default: [[NSException rkException:NSInternalInconsistencyException for:self selector:_cmd localizeReason:@"Unknown edit op code encountered."] raise];          break;
    }
    
    instructionIndex++;

    NSCParameterAssert(currentOp != OP_CHANGE_CASE_END);
    
    if((currentOp == 0) && (thisOp == OP_CHANGE_CASE_END)) { continue; }

    if((thisOp == OP_CHANGE_CASE_END) && ((currentOp == OP_UPPERCASE_NEXT_CHAR) || (currentOp == OP_LOWERCASE_NEXT_CHAR) || (currentOp == OP_UPPERCASE_BEGIN) || (currentOp == OP_LOWERCASE_BEGIN)) && ([conversionString length] == 0)) {
      currentOp = 0;
      continue;
    }
    
    if((currentOp == 0) && (thisOp == 0) && ((fromPtr != NULL) && (fromRange.length > 0))) {
      if(RKAppendCopyInstruction(appliedInstructionsBuffer, fromPtr, fromRange) == NO) { goto errorExit; }
      continue;
    }

    if(((currentOp == OP_UPPERCASE_BEGIN) || (currentOp == OP_LOWERCASE_BEGIN)) && (thisOp == 0) && ((fromPtr != NULL) && (fromRange.length > 0))) {
      if(conversionString == NULL) { RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 0, "Temporary NSMutableString for case conversion created."); if((conversionString = [[NSMutableString alloc] initWithCapacity:1024]) == NULL) { goto errorExit; } }
      NSString *fromString = [[NSString alloc] initWithBytes:(fromPtr + fromRange.location) length:fromRange.length encoding:NSUTF8StringEncoding];
      [conversionString appendString:fromString];
      RKRelease(fromString);
      continue;
    }
    
    if(((currentOp == OP_UPPERCASE_BEGIN) || (currentOp == OP_LOWERCASE_BEGIN)) && (thisOp != currentOp) && ((thisOp != 0) || (lastOp == OP_STOP))) {
      const char *convertedPtr = NULL;
      size_t convertedLength = 0;
      
      if([conversionString length] > 0) {
        if(currentOp == OP_UPPERCASE_BEGIN) { convertedPtr = [[conversionString uppercaseString] UTF8String]; } else { convertedPtr = [[conversionString lowercaseString] UTF8String]; } 
        if(convertedPtr != NULL) { convertedLength = strlen(convertedPtr); }
      
        if(RKAppendCopyInstruction(appliedInstructionsBuffer, convertedPtr, NSMakeRange(0, convertedLength)) == NO) { goto errorExit; }
        [conversionString setString:@""];
      }
      currentOp = 0;
      if(thisOp == OP_CHANGE_CASE_END) { continue; }
    }

    if(((currentOp == OP_UPPERCASE_NEXT_CHAR) || (currentOp == OP_LOWERCASE_NEXT_CHAR)) && (thisOp == 0) && ((fromPtr != NULL) && (fromRange.length > 0))) {
      const char *convertedPtr = NULL, *fromBasePtr = (fromPtr + fromRange.location);
      const unsigned char convertChar = *((const unsigned char *)fromBasePtr);
      int fromLength = (convertChar < 128) ? 1 : utf8ExtraBytes[(convertChar & 0x3f)] + 1;
      NSString *sourceString = [[NSString alloc] initWithBytes:fromBasePtr length:fromLength encoding:NSUTF8StringEncoding];

      if(currentOp == OP_UPPERCASE_NEXT_CHAR) { convertedPtr = [[sourceString uppercaseString] UTF8String]; } else { convertedPtr = [[sourceString lowercaseString] UTF8String]; }
      
      if(sourceString != NULL) { RKRelease(sourceString); sourceString = NULL; }

      if(RKAppendCopyInstruction(appliedInstructionsBuffer, convertedPtr,               NSMakeRange(0, (convertedPtr == NULL) ? 0 : strlen(convertedPtr))) == NO) { goto errorExit; }
      if(RKAppendCopyInstruction(appliedInstructionsBuffer, (fromBasePtr + fromLength), NSMakeRange(0, fromRange.length - fromLength))                     == NO) { goto errorExit; }
      
      currentOp = 0;
      continue;
    }

    NSCAssert1(thisOp != OP_CHANGE_CASE_END, @"currentOp == %d", currentOp);
    currentOp = thisOp;
  }

  NSCParameterAssert([conversionString length] == 0);
  
  if(conversionString != NULL) { RKRelease(conversionString); conversionString = NULL; }
  return(YES);
  
errorExit:
  if(conversionString != NULL) { RKRelease(conversionString); conversionString = NULL; }
  return(NO);
}

static BOOL RKCompileReferenceString(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) referenceStringBuffer, RKRegex * const RK_C99(restrict) regex,
                                     RK_STRONG_REF RKReferenceInstructionsBuffer * const RK_C99(restrict) instructionBuffer) {
  NSCParameterAssert((referenceStringBuffer != NULL) && (regex != NULL) && (instructionBuffer != NULL));
  NSRange currentRange = NSMakeRange(0,0), validVarRange, parsedVarRange;
  RKUInteger referenceIndex = 0, parsedUInteger = 0;
  RK_STRONG_REF NSString *parseErrorString = NULL;

  while((RKUInteger)referenceIndex < referenceStringBuffer->length) {
    if((referenceStringBuffer->characters[referenceIndex] == '$') && (referenceStringBuffer->characters[referenceIndex + 1] == '$')) {
      currentRange.length++;
      if(RKAppendInstruction(instructionBuffer, OP_COPY_RANGE, referenceStringBuffer->characters, currentRange) == NO) { goto errorExit; }
      referenceIndex += 2;
      currentRange = NSMakeRange(referenceIndex, 0);
      continue;
    } else if(referenceStringBuffer->characters[referenceIndex] == '$') {
      if(RKParseReference(referenceStringBuffer, NSMakeRange(referenceIndex, (referenceStringBuffer->length - referenceIndex)), NULL, NULL, regex, &parsedUInteger, NULL, PARSEREFERENCE_IGNORE_CONVERSION, &parsedVarRange, &validVarRange, &parseErrorString, NULL, NULL)) {
        if(currentRange.length > 0)      {
          if(RKAppendInstruction(instructionBuffer, OP_COPY_RANGE,        referenceStringBuffer->characters,                  currentRange)  == NO) { goto errorExit; }
        } if(parsedUInteger == NSNotFound) {
          if(RKAppendInstruction(instructionBuffer, OP_COPY_CAPTURENAME,  referenceStringBuffer->characters + referenceIndex, validVarRange) == NO) { goto errorExit; }
        } else {
          if(RKAppendInstruction(instructionBuffer, OP_COPY_CAPTUREINDEX, NULL,                              NSMakeRange(parsedUInteger, 0)) == NO) { goto errorExit; }
        }
        
        referenceIndex += parsedVarRange.length;
        currentRange = NSMakeRange(referenceIndex, 0);
        continue;
      }
      else { [[NSException exceptionWithName:RKRegexCaptureReferenceException reason:RKPrettyObjectMethodString(parseErrorString) userInfo:NULL] raise]; }
    }
    else if(referenceStringBuffer->characters[referenceIndex] == '\\') {
      int appendOp = 0;
      RKUInteger appendRangeLocation = 0;
      char nextChar = referenceStringBuffer->characters[referenceIndex + 1];
      
      if((nextChar >= '0') && (nextChar <= '9')) {
        appendOp = OP_COPY_CAPTUREINDEX;
        appendRangeLocation = nextChar - '0';

        if(appendRangeLocation >= [regex captureCount]) {
          [[NSException rkException:RKRegexCaptureReferenceException for:self selector:_cmd localizeReason:@"The capture reference '\\%c' specifies a capture subpattern '%lu' that is greater than number of capture subpatterns defined by the regular expression, '%ld'.", nextChar, (unsigned long)appendRangeLocation, (long)max(0, ((RKInteger)[regex captureCount] - 1))] raise];
        }
      } else {
        switch(nextChar) {
          case 'u': appendOp = OP_UPPERCASE_NEXT_CHAR; break;
          case 'l': appendOp = OP_LOWERCASE_NEXT_CHAR; break;
          case 'U': appendOp = OP_UPPERCASE_BEGIN;     break;
          case 'L': appendOp = OP_LOWERCASE_BEGIN;     break;
          case 'E': appendOp = OP_CHANGE_CASE_END;     break;
          default:                                     break;
        }
      }

      if(appendOp != 0) {
        if(RKAppendInstruction(instructionBuffer, OP_COPY_RANGE, referenceStringBuffer->characters, currentRange)      == NO) { goto errorExit; }
        referenceIndex += 2;
        currentRange = NSMakeRange(referenceIndex, 0);
        if(RKAppendInstruction(instructionBuffer, appendOp,      NULL,            NSMakeRange(appendRangeLocation, 0)) == NO) { goto errorExit; }
        continue;
      }
    }
    
    referenceIndex++;
    currentRange.length++;
  }
  
  if(RKAppendInstruction(instructionBuffer, OP_COPY_RANGE, referenceStringBuffer->characters, currentRange)               == NO) { goto errorExit; }
  if(RKAppendInstruction(instructionBuffer, OP_STOP,       NULL,                              NSMakeRange(NSNotFound, 0)) == NO) { goto errorExit; }

  return(YES);

errorExit:
  return(NO);
}

static BOOL RKAppendInstruction(RK_STRONG_REF RKReferenceInstructionsBuffer * const RK_C99(restrict) instructionsBuffer, const int op, RK_STRONG_REF const void * ptr, const NSRange range) {
  NSCParameterAssert(instructionsBuffer != NULL); NSCParameterAssert(instructionsBuffer->length <= instructionsBuffer->capacity); NSCParameterAssert(instructionsBuffer->isValid == YES);

  if((range.length == 0) && ((op == OP_COPY_RANGE))) { return(YES); }
  
  if(instructionsBuffer->length >= instructionsBuffer->capacity) {
    if(instructionsBuffer->mutableData == NULL) {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 0, "The number of RKReferenceInstructions exceeded stack buffer requiring a buffer to be allocated from the heap.");
      if((instructionsBuffer->mutableData = [NSMutableData dataWithLength:(sizeof(RKReferenceInstruction) * (instructionsBuffer->capacity + RK_DEFAULT_STACK_INSTRUCTIONS))]) == NULL) { goto errorExit; }
      if((instructionsBuffer->instructions != NULL) && (instructionsBuffer->capacity > 0)) {
        [instructionsBuffer->mutableData appendBytes:instructionsBuffer->instructions length:(sizeof(RKReferenceInstruction) * instructionsBuffer->capacity)];
      }
      instructionsBuffer->capacity += RK_DEFAULT_STACK_INSTRUCTIONS;
    }
    else {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 0, "The number of RKReferenceInstructions exceeded current heap buffer size requiring additional heap storage be allocated.");
      [instructionsBuffer->mutableData increaseLengthBy:(sizeof(RKReferenceInstruction) * RK_DEFAULT_STACK_INSTRUCTIONS)];
      instructionsBuffer->capacity += RK_DEFAULT_STACK_INSTRUCTIONS;
    }
    if((instructionsBuffer->instructions = [instructionsBuffer->mutableData mutableBytes]) == NULL) { goto errorExit; }
  }
  
  instructionsBuffer->instructions[instructionsBuffer->length].op    = op;
  instructionsBuffer->instructions[instructionsBuffer->length].ptr   = ptr;
  instructionsBuffer->instructions[instructionsBuffer->length].range = range;
  instructionsBuffer->length++;
  
  return(YES);
  
errorExit:
  instructionsBuffer->isValid = NO;
  return(NO);
}

static BOOL RKAppendCopyInstruction(RK_STRONG_REF RKCopyInstructionsBuffer * const RK_C99(restrict) instructionsBuffer, RK_STRONG_REF const void * ptr, const NSRange range) {
  NSCParameterAssert(instructionsBuffer != NULL); NSCParameterAssert(instructionsBuffer->length <= instructionsBuffer->capacity); NSCParameterAssert(instructionsBuffer->isValid == YES);
  
  if(range.length == 0) { return(YES); }

  // If the current append request starts where the last copy ends, just append the current requests length
  if(instructionsBuffer->length > 0) {
    RKCopyInstruction *lastInstruction = &instructionsBuffer->instructions[(instructionsBuffer->length) - 1];
    if((lastInstruction->ptr + lastInstruction->length) == (ptr + range.location)) {
      lastInstruction->length += range.length;
      instructionsBuffer->copiedLength += range.length;
      return(YES);
    }
  }

  if(instructionsBuffer->length >= instructionsBuffer->capacity) {
    if(instructionsBuffer->mutableData == NULL) {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 0, "The number of RKCopyInstructions exceeded stack buffer requiring a buffer to be allocated from the heap.");
      if((instructionsBuffer->mutableData = [NSMutableData dataWithLength:(sizeof(RKCopyInstruction) * (instructionsBuffer->capacity + RK_DEFAULT_STACK_INSTRUCTIONS))]) == NULL) { goto errorExit; }
      if((instructionsBuffer->instructions != NULL) && (instructionsBuffer->capacity > 0)) {
        [instructionsBuffer->mutableData appendBytes:instructionsBuffer->instructions length:(sizeof(RKCopyInstruction) * instructionsBuffer->capacity)];
      }
      instructionsBuffer->capacity += RK_DEFAULT_STACK_INSTRUCTIONS;
    }
    else {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 0, "The number of RKCopyInstructions exceeded current heap buffer size requiring additional heap storage be allocated.");
      [instructionsBuffer->mutableData increaseLengthBy:(sizeof(RKCopyInstruction) * RK_DEFAULT_STACK_INSTRUCTIONS)];
      instructionsBuffer->capacity += RK_DEFAULT_STACK_INSTRUCTIONS;
    }
    if((instructionsBuffer->instructions = [instructionsBuffer->mutableData mutableBytes]) == NULL) { goto errorExit; }
  }
  
  instructionsBuffer->instructions[instructionsBuffer->length].ptr    = (ptr + range.location);
  instructionsBuffer->instructions[instructionsBuffer->length].length = range.length;
  instructionsBuffer->copiedLength += instructionsBuffer->instructions[instructionsBuffer->length].length;
  instructionsBuffer->length++;

  return(YES);
  
errorExit:
    instructionsBuffer->isValid = NO;
    return(NO);
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


static BOOL RKParseReference(RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) referenceBuffer, const NSRange referenceRange,
                             RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) subjectBuffer, RK_STRONG_REF const NSRange * const RK_C99(restrict) subjectMatchResultRanges,
                             RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF RKUInteger * const RK_C99(restrict) parsedReferenceUInteger,
                             RK_STRONG_REF void * const RK_C99(restrict) conversionPtr, const int parseReferenceOptions, RK_STRONG_REF NSRange * const RK_C99(restrict) parsedRange,
                             RK_STRONG_REF NSRange * const RK_C99(restrict) parsedReferenceRange, NSString ** const RK_C99(restrict) errorString,
                             RK_STRONG_REF void *** const RK_C99(restrict) autoreleasePool, RK_STRONG_REF RKUInteger * const RK_C99(restrict) autoreleasePoolIndex) {
  NSCParameterAssert(referenceBuffer != NULL);
  NSCParameterAssert(regex != NULL);

  const RKStringBuffer rBuffer = RKMakeStringBuffer(referenceBuffer->string, referenceBuffer->characters + referenceRange.location, referenceRange.length, referenceBuffer->encoding);
  NSString * RK_C99(restrict) tempErrorString = NULL;
  const BOOL conversionAllowed = (parseReferenceOptions & PARSEREFERENCE_CONVERSION_ALLOWED) != 0 ? YES : NO;
  const BOOL ignoreConversion  = (parseReferenceOptions & PARSEREFERENCE_IGNORE_CONVERSION)  != 0 ? YES : NO;
  const BOOL strictReference   = (parseReferenceOptions & PARSEREFERENCE_STRICT_REFERENCE)   != 0 ? YES : NO;
  const BOOL performConversion = (parseReferenceOptions & PARSEREFERENCE_PERFORM_CONVERSION) != 0 ? YES : NO;
  const BOOL checkCaptureName  = (parseReferenceOptions & PARSEREFERENCE_CHECK_CAPTURE_NAME) != 0 ? YES : NO;
  BOOL successfulParse = NO, createMutableConvertedString = NO;
  RKUInteger referenceUInteger = 0;
  
  RK_STRONG_REF const char *atPtr = rBuffer.characters, *startReference = atPtr, *endReference = atPtr, *startBracket = NULL, *endBracket = NULL, *startFormat = NULL, *endFormat = NULL;
  
  if(parsedRange             != NULL)     { *parsedRange             = NSMakeRange(0, 0); }
  if(parsedReferenceRange    != NULL)     { *parsedReferenceRange    = NSMakeRange(0, 0); }
  if(RK_EXPECTED(errorString != NULL, 1)) { *errorString             = NULL;              }
  if(parsedReferenceUInteger != NULL)     { *parsedReferenceUInteger = NSNotFound;        }

  if((*atPtr != '\\') && RK_EXPECTED((*(atPtr + 1) <= '9'), 1) && RK_EXPECTED((*(atPtr + 1) >= '0'), 1) && ((*(atPtr + 2) == 0) || (strictReference == NO))) { referenceUInteger = (*(atPtr + 1) - '0'); startReference = atPtr + 1; atPtr += 2; endReference = atPtr; goto finishedParse; } // Fast path \\[0-9]

  if(RK_EXPECTED(*atPtr != '$', 0)) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
  
  if(RK_EXPECTED((*(atPtr + 1) <= '9'), 1) && RK_EXPECTED((*(atPtr + 1) >= '0'), 1) && ((*(atPtr + 2) == 0) || (strictReference == NO))) { referenceUInteger = (*(atPtr + 1) - '0'); startReference = atPtr + 1; atPtr += 2; endReference = atPtr; goto finishedParse; } // Fast path $[0-9]

  if(RK_EXPECTED(*(atPtr + 1) != '{', 0)) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }

  if(RK_EXPECTED((*(atPtr + 2) <= '9'), 1) && RK_EXPECTED((*(atPtr + 2) >= '0'), 1) && RK_EXPECTED((*(atPtr + 3) == '}'), 1) && ((*(atPtr + 4) == 0) || (strictReference == NO))) { referenceUInteger = (*(atPtr + 2) - '0'); startReference = atPtr + 2; endReference = atPtr + 3; atPtr += 4; goto finishedParse; } // Fast path ${[0-9]}

  startBracket = atPtr+1;
  startReference = atPtr+2;
  atPtr += 2;
  
  while(((atPtr - rBuffer.characters) < (int)rBuffer.length) && (*atPtr != 0) && (*atPtr != ':') && (*atPtr != '}')) {
    if((referenceUInteger != NSNotFound) && (RK_EXPECTED((*atPtr <= '9'), 1) && RK_EXPECTED((*atPtr >= '0'), 1))) { referenceUInteger = ((referenceUInteger * 10) + (*atPtr - '0')); atPtr++; continue; }
    if((RK_EXPECTED(((*atPtr | 0x20) >= 'a'), 1) && RK_EXPECTED(((*atPtr | 0x20) <= 'z'), 1)) || RK_EXPECTED((*atPtr == '_'), 0) || ((referenceUInteger == NSNotFound ) && RK_EXPECTED((*atPtr >= '0'), 1) && (*atPtr <= '9'))) { referenceUInteger = NSNotFound; atPtr++; continue; }
    break;
  }

  endReference = atPtr;

  if(RK_EXPECTED((endReference - startReference) == 0, 0)) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
  if((*atPtr == ':') && (conversionAllowed == NO) && (ignoreConversion == NO)) { tempErrorString = RKLocalizedFormat(@"Type conversion is not permitted for capture reference '%*.*s' in this context.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }

  if((conversionAllowed == YES) && (*atPtr == ':')) {
    atPtr++;
    if((*atPtr == '%') || (*atPtr == '@')) {
      startFormat = atPtr; while(((atPtr - rBuffer.characters) < (int)rBuffer.length) && (*atPtr != 0) && (*atPtr != '}')) { atPtr++; } endFormat = atPtr;
      if((endFormat - startFormat) == 1) { tempErrorString = RKLocalizedFormat(@"The conversion format of capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
    } else { tempErrorString = RKLocalizedFormat(@"The conversion format of capture reference '%*.*s' is not valid. Valid formats begin with '@' or '%%'.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
  }
  
  if(*atPtr == '}') { atPtr++; endBracket = atPtr; }
  
  if(RK_EXPECTED((startBracket != NULL), 1) && RK_EXPECTED(((endBracket - startBracket) == 0), 0)) { tempErrorString = RKLocalizedFormat(@"The conversion format of capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }

  if(RK_EXPECTED((startBracket != NULL), 1) && RK_EXPECTED((endBracket == NULL), 0)) {
    while(((atPtr - rBuffer.characters) < (int)rBuffer.length) && (*atPtr != 0) && (*atPtr != '}')) { atPtr++; }
    if(*atPtr == '}') { 
      if(conversionAllowed == NO) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
      else { endBracket = atPtr; tempErrorString = RKLocalizedFormat(@"The conversion format of capture reference '%*.*s' is not valid.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
    }
  }

  if((RK_EXPECTED((startBracket == NULL), 0) && RK_EXPECTED((endBracket != NULL), 1)) || (RK_EXPECTED((startBracket != NULL), 1) && RK_EXPECTED((endBracket == NULL), 0))) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' has unbalanced curly brackets.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }

finishedParse:
  
  if((referenceUInteger == NSNotFound) && (regex != NULL)) {
    referenceUInteger = RKCaptureIndexForCaptureNameCharacters(regex, NULL, startReference, (endReference - startReference), NULL, NO);

    if((referenceUInteger == NSNotFound) && ((subjectMatchResultRanges != NULL) || (checkCaptureName == YES))) {
      tempErrorString = RKLocalizedFormat(@"The named capture '%*.*s' from capture reference '%*.*s' is not defined by the regular expression.", (int)(endReference - startReference), (int)(endReference - startReference), startReference, (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters);
      goto finishedParseError;
    }
  }
    
  if(referenceUInteger != NSNotFound) {
    if(RK_EXPECTED(referenceUInteger >= [regex captureCount], 0)) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' specifies a capture subpattern '%lu' that is greater than number of capture subpatterns defined by the regular expression, '%ld'.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters, (unsigned long)referenceUInteger, (long)max(0, ((RKInteger)[regex captureCount] - 1))); goto finishedParseError; }
    
    if((performConversion == YES) && (subjectMatchResultRanges[referenceUInteger].location != NSNotFound)) {
      NSCParameterAssert((subjectMatchResultRanges[referenceUInteger].location + subjectMatchResultRanges[referenceUInteger].length) <= subjectBuffer->length);
      
      id convertedString = NULL;
      
      if(startFormat != NULL) {
        if(*startFormat == '%') {
          RKUInteger convertLength = subjectMatchResultRanges[referenceUInteger].length;
          RK_STRONG_REF       char * RK_C99(restrict) convertBuffer = NULL; char convertStackBuffer[1024];
          RK_STRONG_REF const char * RK_C99(restrict) convertPtr    = (subjectBuffer->characters + subjectMatchResultRanges[referenceUInteger].location);
          RK_STRONG_REF       char * RK_C99(restrict) formatBuffer  = NULL; char formatStackBuffer[1024]; // If it fits in our *stackBuffer, use that, otherwise grab an autoreleasedMalloc to hold the characters.
          
          if(RK_EXPECTED(convertLength < 1020, 1)) { memcpy(&convertStackBuffer[0], convertPtr, convertLength); convertBuffer = &convertStackBuffer[0]; }
          else { convertBuffer = RKAutoreleasedMalloc(convertLength + 1); memcpy(&convertBuffer[0], convertPtr, convertLength); }
          convertBuffer[convertLength] = 0;
          
          if(RK_EXPECTED((endFormat - startFormat) < 1020, 1)) { memcpy(&formatStackBuffer[0], startFormat, (endFormat - startFormat)); formatBuffer = &formatStackBuffer[0]; } 
          else { formatBuffer = RKAutoreleasedMalloc((endFormat - startFormat) + 1); memcpy(&formatBuffer[0], startFormat, (endFormat - startFormat)); }
          formatBuffer[(endFormat - startFormat)] = 0;
          
          if(RK_EXPECTED((convertBuffer != NULL), 1) && RK_EXPECTED((formatBuffer != NULL), 1)) {
            if(formatBuffer[2] == 0) { // Fast, inline bypass if it's a simple (32 bit int) conversion.
              BOOL unsignedConversion = NO;
              
              switch(formatBuffer[1]) {
                case 'u': unsignedConversion = YES; // Fall-thru
                case 'x': unsignedConversion = YES; // Fall-thru
                case 'X': unsignedConversion = YES; // Fall-thru 
                case 'd': // Fall-thru
                case 'i': // Fall-thru
                case 'o':
                { // Modified from the libc conversion routine.
                  int neg = 0, any = 0, cutlim = 0, base = 0;
                  const char * RK_C99(restrict) s = &convertBuffer[0];
                  unsigned int acc = 0, cutoff = 0;
                  char c = 0;
                  
                  NSCParameterAssert(s != NULL);
                  
                  do { c = *s++; } while (isspace((unsigned char)c) && (s <= &convertBuffer[convertLength]));
                  if(c == '-') { neg = 1; c = *s++; } else if (c == '+') { c = *s++; } 
                  if((c == '0') && (*s == 'x' || *s == 'X') && (s <= &convertBuffer[convertLength])) { c = s[1]; s += 2; base = 16; } else { base = c == '0' ? 8 : 10; }
                  
                  if(unsignedConversion == YES) { cutoff = UINT_MAX / base; cutlim = UINT_MAX % base; } 
                  else { cutoff = (neg ? (unsigned int)-(INT_MIN + INT_MAX) + INT_MAX : INT_MAX) / base; cutlim = cutoff % base; }
                  
                  do {
                    if(c >= '0' && c <= '9') { c -= '0'; } else if(c >= 'A' && c <= 'F') { c -= 'A' - 10; } else if(c >= 'a' && c <= 'f') { c -= 'a' - 10; } else { break; }
                    if(c >= base) {  break; }
                    if(any < 0 || acc > cutoff || (acc == cutoff && c > cutlim)) { any = -1; }
                    else { any = 1; acc *= base; acc += c; }
                  } while(((c = *s++) != 0) && (s <= &convertBuffer[convertLength]));
                  
                  if(any < 0) { if(unsignedConversion == YES) { acc = UINT_MAX; } else { acc = neg ? INT_MIN : INT_MAX; } } else if(neg) { acc = -acc; }
                  
                  if(RK_EXPECTED(conversionPtr == NULL, 0)) { tempErrorString = RKLocalizedFormat(@"The capture reference '%*.*s' storage pointer is NULL.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
                  *((int *)conversionPtr) = acc;
                  goto finishedParseSuccess;
                }
                  break;
                default: break; // Will fall thru to sscanf if we didn't fast bypass convert it here.
              }
            }
            RK_PROBE(PERFORMANCENOTE, regex, [regex hash], (char *)regexUTF8String(regex), 0, -1, 0, "Slow conversion via sscanf.");
            sscanf(convertBuffer, formatBuffer, conversionPtr); 
          }
          goto finishedParseSuccess;
        }
        
        NSCParameterAssert(endFormat != NULL);
        
        // Before we create a string, check if it's something reasonable.
        if( ! ( RK_EXPECTED((*startFormat == '@'), 1) && 
                     ( ((*(endFormat - 1) == 'n') && (((startFormat + 1) == (endFormat - 1)) || ((startFormat + 2) == (endFormat - 1)))) ||
                       ((*(endFormat - 1) == 'd') &&  ((startFormat + 1) == (endFormat - 1))) ))) {
          tempErrorString = RKLocalizedFormat(@"Unknown type conversion requested in capture reference '%*.*s'.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters);
          goto finishedParseError;
        }
      }
#ifdef USE_CORE_FOUNDATION
      if(RK_EXPECTED(createMutableConvertedString == NO, 1)) { convertedString = RKMakeCollectable(CFStringCreateWithBytes(NULL, (const UInt8 *)(&subjectBuffer->characters[subjectMatchResultRanges[referenceUInteger].location]), (CFIndex)subjectMatchResultRanges[referenceUInteger].length, kCFStringEncodingUTF8, NO));
      } else { convertedString = [[NSMutableString alloc] initWithBytes:&subjectBuffer->characters[subjectMatchResultRanges[referenceUInteger].location] length:subjectMatchResultRanges[referenceUInteger].length encoding:NSUTF8StringEncoding]; }
#else  // USE_CORE_FOUNDATION is not defined
      if(RK_EXPECTED(createMutableConvertedString == YES, 0)) { convertedString = [[NSMutableString alloc] initWithBytes:&subjectBuffer->characters[subjectMatchResultRanges[referenceUInteger].location] length:subjectMatchResultRanges[referenceUInteger].length encoding:NSUTF8StringEncoding]; }
      else { convertedString = [[NSString alloc] initWithBytes:&subjectBuffer->characters[subjectMatchResultRanges[referenceUInteger].location] length:subjectMatchResultRanges[referenceUInteger].length encoding:NSUTF8StringEncoding]; }
#endif // USE_CORE_FOUNDATION
      if((autoreleasePool != NULL) && (RKRegexGarbageCollect == 0)) { autoreleasePool[*autoreleasePoolIndex] = (void *)convertedString; *autoreleasePoolIndex = *autoreleasePoolIndex + 1; }
      if((autoreleasePool == NULL) && (RKRegexGarbageCollect == 0)) { RKAutorelease(convertedString); }

      if(startFormat == NULL) { *((NSString **)conversionPtr) = convertedString; goto finishedParseSuccess; }
      
      if(RK_EXPECTED((*startFormat == '@'), 1) && RK_EXPECTED((*(endFormat - 1) == 'd'), 1) && RK_EXPECTED(((startFormat + 1) == (endFormat - 1)), 1)) {
        static BOOL didPrintLockWarning = NO;
        if(RK_EXPECTED(NSStringRKExtensionsInitialized == 0, 0)) { NSStringRKExtensionsInitializeFunction(); } 
        if(RK_EXPECTED(RKFastLock(NSStringRKExtensionsNSDateLock) == NO, 0)) {
          if(didPrintLockWarning == NO) { NSLog(@"Unable to acquire the NSDate access serialization lock.  Heavy concurrent date conversions may return incorrect results."); didPrintLockWarning = YES; }
        }
        *((NSDate **)conversionPtr) = [NSDate dateWithNaturalLanguageString:convertedString];
        RKFastUnlock(NSStringRKExtensionsNSDateLock);
        goto finishedParseSuccess;
      }
#ifdef HAVE_NSNUMBERFORMATTER_CONVERSIONS
      else if(RK_EXPECTED((*startFormat == '@'), 1) && (*(endFormat - 1) == 'n') && (((startFormat + 1) == (endFormat - 1)) || ((startFormat + 2) == (endFormat - 1)))) {
        RK_STRONG_REF struct __RKThreadLocalData * RK_C99(restrict) tld = RKGetThreadLocalData();
        if(RK_EXPECTED(tld == NULL, 0)) { goto finishedParseError; }
        RK_STRONG_REF NSNumberFormatter * RK_C99(restrict) numberFormatter = RK_EXPECTED((tld->_numberFormatter == NULL), 0) ? RKGetThreadLocalNumberFormatter() : tld->_numberFormatter;
        if((startFormat + 1) != (endFormat - 1)) {
          switch(*(startFormat + 1)) {
            case '.': if(tld->_currentFormatterStyle != NSNumberFormatterDecimalStyle)    { tld->_currentFormatterStyle = NSNumberFormatterDecimalStyle;    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle]; }    break;
            case '$': if(tld->_currentFormatterStyle != NSNumberFormatterCurrencyStyle)   { tld->_currentFormatterStyle = NSNumberFormatterCurrencyStyle;   [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle]; }   break;
            case '%': if(tld->_currentFormatterStyle != NSNumberFormatterPercentStyle)    { tld->_currentFormatterStyle = NSNumberFormatterPercentStyle;    [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle]; }    break;
            case 's': if(tld->_currentFormatterStyle != NSNumberFormatterScientificStyle) { tld->_currentFormatterStyle = NSNumberFormatterScientificStyle; [numberFormatter setNumberStyle:NSNumberFormatterScientificStyle]; } break;
            case 'w': if(tld->_currentFormatterStyle != NSNumberFormatterSpellOutStyle)   { tld->_currentFormatterStyle = NSNumberFormatterSpellOutStyle;   [numberFormatter setNumberStyle:NSNumberFormatterSpellOutStyle]; }   break;
            default: tempErrorString = RKLocalizedFormat(@"Capture reference '%*.*s' NSNumber conversion is invalid. Valid NSNumber conversion options are '.$%%ew'.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; break;
          }
        } else { if(tld->_currentFormatterStyle != NSNumberFormatterNoStyle) { tld->_currentFormatterStyle = NSNumberFormatterNoStyle; [numberFormatter setNumberStyle:NSNumberFormatterNoStyle]; } }
        *((NSNumber **)conversionPtr) = [numberFormatter numberFromString:convertedString];
        goto finishedParseSuccess;
      }
#endif // HAVE_NSNUMBERFORMATTER_CONVERSIONS
      else { tempErrorString = RKLocalizedFormat(@"Unknown type conversion requested in capture reference '%*.*s'.", (int)rBuffer.length, (int)rBuffer.length, rBuffer.characters); goto finishedParseError; }
    }
  }
  
finishedParseSuccess:
  successfulParse = YES;
  goto finishedExit;
  
finishedParseError:
  if(RK_EXPECTED(errorString != NULL, 1)) { *errorString = tempErrorString; }
  
  successfulParse = NO;
  goto finishedExit;
  
finishedExit:

  if(parsedRange             != NULL) { *parsedRange             = NSMakeRange(0, (atPtr - rBuffer.characters)); }
  if(parsedReferenceRange    != NULL) { *parsedReferenceRange    = NSMakeRange(startReference - rBuffer.characters, (endReference - startReference)); }
  if(parsedReferenceUInteger != NULL) { *parsedReferenceUInteger = referenceUInteger; }
  
  return(successfulParse);
}

#ifdef REGEXKIT_DEBUG

static void dumpReferenceInstructions(RK_STRONG_REF const RKReferenceInstructionsBuffer *ins) {
  if(ins == NULL) { NSLog(@"NULL replacement instructions"); return; }
  NSLog(@"Replacement instructions");
  NSLog(@"isValid     : %@",  RKYesOrNo(ins->isValid));
  NSLog(@"Length      : %lu", (unsigned long)ins->length);
  NSLog(@"Capacity    : %lu", (unsigned long)ins->capacity);
  NSLog(@"Instructions: %p",  ins->instructions);
  NSLog(@"mutableData : %p",  ins->mutableData);
  
  for(RKUInteger x = 0; x < ins->length; x++) {
    RKReferenceInstruction *at = &ins->instructions[x];
    NSMutableString *logString = [NSMutableString stringWithFormat:@"[%4lu] op: %lu ptr: %p range {%6lu, %6lu} ", (unsigned long)x, (unsigned long)at->op, at->ptr, (unsigned long)at->range.location, (unsigned long)at->range.length];
    switch(at->op) {
      case OP_STOP:                [logString appendFormat:@"Stop"]; break;
      case OP_COPY_CAPTUREINDEX:   [logString appendFormat:@"Capture Index #%lu", (unsigned long)at->range.location]; break;
      case OP_COPY_CAPTURENAME:    [logString appendFormat:@"Capture Name '%@'", at->ptr]; break;
      case OP_COPY_RANGE:          [logString appendFormat:@"Copy range: ptr: %p length: %lu '%*.*s'", (at->ptr + at->range.location), (unsigned long)at->range.length, (int)at->range.length, (int)at->range.length, at->ptr + at->range.location]; break;
      case OP_COMMENT:             [logString appendFormat:@"Comment"]; break;

      case OP_UPPERCASE_NEXT_CHAR: [logString appendFormat:@"Uppercase Next Char"]; break;
      case OP_LOWERCASE_NEXT_CHAR: [logString appendFormat:@"Lowercase Next Char"]; break;
      case OP_UPPERCASE_BEGIN:     [logString appendFormat:@"Uppercase Begin"]; break;
      case OP_LOWERCASE_BEGIN:     [logString appendFormat:@"Lowercase Begin"]; break;
      case OP_CHANGE_CASE_END:     [logString appendFormat:@"Change Case End"]; break;
      default:                     [logString appendFormat:@"UNKNOWN"]; break;
    }
    NSLog(@"%@", logString);
  }
}


static void dumpCopyInstructions(RK_STRONG_REF const RKCopyInstructionsBuffer *ins) {
  if(ins == NULL) { NSLog(@"NULL copy instructions"); return; }
  NSLog(@"Copy instructions");
  NSLog(@"isValid      : %@",  RKYesOrNo(ins->isValid));
  NSLog(@"Length       : %lu", (unsigned long)ins->length);
  NSLog(@"Capacity     : %lu", (unsigned long)ins->capacity);
  NSLog(@"Copied length: %lu", (unsigned long)ins->copiedLength);
  NSLog(@"Instructions : %p",  ins->instructions);
  NSLog(@"mutableData  : %p",  ins->mutableData);
  
  for(RKUInteger x = 0; x < ins->length; x++) {
    RKCopyInstruction *at = &ins->instructions[x];
    NSLog(@"[%4lu] ptr: %p - %p length %lu (0x%8.8lx) = '%*.*s'", (unsigned long)x, at->ptr, at->ptr + at->length, (unsigned long)at->length, (unsigned long)at->length, (int)min(at->length, (unsigned)16), (int)min(at->length, (unsigned)16), at->ptr); 
  }
}

#endif // REGEXKIT_DEBUG
