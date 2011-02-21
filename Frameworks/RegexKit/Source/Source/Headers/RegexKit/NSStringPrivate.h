//
//  NSStringPrivate.h
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
  
#ifndef _REGEXKIT_NSSTRINGPRIVATE_H_
#define _REGEXKIT_NSSTRINGPRIVATE_H_ 1

#ifdef    USE_CORE_FOUNDATION
#define RKStringBufferEncoding CFStringEncoding
#define RKUTF8StringEncoding   kCFStringEncodingUTF8
#else  // USE_CORE_FOUNDATION not defined
#define RKStringBufferEncoding NSStringEncoding
#define RKUTF8StringEncoding   NSUTF8StringEncoding
#endif // USE_CORE_FOUNDATION

typedef struct _RKStringBuffer {
  RK_STRONG_REF NSString               *string;
  RK_STRONG_REF const char             *characters;
  size_t                  length;
  RKStringBufferEncoding  encoding;
} RKStringBuffer;

#define RKMakeStringBuffer(bufferString, stringBufferCharacters, stringBufferLength, stringBufferEncoding) ((RKStringBuffer){bufferString, stringBufferCharacters, stringBufferLength, stringBufferEncoding})


RKREGEX_STATIC_INLINE char *RKGetUTF8String(NSString *string, char *temporaryBuffer, size_t length) RK_ATTRIBUTES(nonnull(1, 2), pure);

#ifdef    USE_CORE_FOUNDATION
RKREGEX_STATIC_INLINE char *RKGetUTF8String(NSString *string, char *temporaryBuffer, size_t length) {
  NSCParameterAssert(string != NULL); NSCParameterAssert(temporaryBuffer != NULL); NSCParameterAssert(length > 0);
  CFIndex copiedLength = 0;
  
  if(RK_EXPECTED(string != NULL, 1)) {
    //char *fastBuffer = (char *)CFStringGetCStringPtr((CFStringRef)string, kCFStringEncodingUTF8);
    //if(fastBuffer != NULL) { return(fastBuffer); }
    copiedLength = CFStringGetBytes((CFStringRef)string, (CFRange){0, CFStringGetLength((CFStringRef)string)}, kCFStringEncodingUTF8, '?', false, (UInt8 *)temporaryBuffer, (CFIndex)(length - 1), NULL);
  }
  temporaryBuffer[copiedLength] = 0;
  
  return(temporaryBuffer);
}
#else
RKREGEX_STATIC_INLINE char *RKGetUTF8String(NSString *string, char *temporaryBuffer, size_t length) {
  NSCParameterAssert(string != NULL); NSCParameterAssert(temporaryBuffer != NULL); NSCParameterAssert(length > 0);
  temporaryBuffer[0] = 0;
  [string getCString:temporaryBuffer maxLength:(RKUInteger)length encoding:NSUTF8StringEncoding];
  
  return(temporaryBuffer);
}
#endif // USE_CORE_FOUNDATION

RKREGEX_STATIC_INLINE RKStringBuffer RKStringBufferWithString(NSString * const string) RK_ATTRIBUTES(nonnull(1), const);

RKREGEX_STATIC_INLINE RKStringBuffer RKStringBufferWithString(NSString * const RK_C99(restrict) string) {
  RKStringBuffer stringBuffer = RKMakeStringBuffer(string, NULL, 0, 0);
  
#ifdef    USE_CORE_FOUNDATION
  if(RK_EXPECTED(string != NULL, 1)) {
    stringBuffer.encoding = CFStringGetFastestEncoding((CFStringRef)string);
    
    if((stringBuffer.encoding == kCFStringEncodingMacRoman) || (stringBuffer.encoding == kCFStringEncodingASCII) || (stringBuffer.encoding == kCFStringEncodingUTF8)) {
      stringBuffer.characters = CFStringGetCStringPtr((CFStringRef)string, stringBuffer.encoding);
      RKPrefetch(stringBuffer.characters);
      if(RK_EXPECTED(stringBuffer.characters != NULL, 1)) {
        if((stringBuffer.encoding == kCFStringEncodingMacRoman) || (stringBuffer.encoding == kCFStringEncodingASCII)) {
          stringBuffer.length = (size_t)CFStringGetLength((CFStringRef)string);
        } else {
          stringBuffer.length = strlen(stringBuffer.characters);
        }
      }
    }
    if(RK_EXPECTED(stringBuffer.characters == NULL, 0)) {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 1, "NSString encoding requires expensive UTF8 conversion.");
      stringBuffer.characters = [string UTF8String];
      stringBuffer.encoding = kCFStringEncodingUTF8;
      if(RK_EXPECTED(stringBuffer.characters != NULL, 1)) { stringBuffer.length = strlen(stringBuffer.characters); }
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, stringBuffer.length, -1, 2, "NSString encoding requires expensive UTF8 conversion.");
    }
  }
#else  // USE_CORE_FOUNDATION is not defined
  if(RK_EXPECTED(string != NULL, 1)) {
    stringBuffer.encoding = [string fastestEncoding];
    
    if((stringBuffer.encoding == NSMacOSRomanStringEncoding) || (stringBuffer.encoding == NSASCIIStringEncoding) || (stringBuffer.encoding == NSUTF8StringEncoding)) {
      stringBuffer.characters = [string cStringUsingEncoding:stringBuffer.encoding];
      RKPrefetch(stringBuffer.characters);
      if(RK_EXPECTED(stringBuffer.characters != NULL, 1)) {
        if((stringBuffer.encoding == NSMacOSRomanStringEncoding) || (stringBuffer.encoding == NSASCIIStringEncoding)) {
          stringBuffer.length = (size_t)[string length];
        } else {
          stringBuffer.length = strlen(stringBuffer.characters);
        }
      }
    }
    if(RK_EXPECTED(stringBuffer.characters == NULL, 0)) {
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, 0, -1, 1, "NSString encoding requires expensive UTF8 conversion.");
      stringBuffer.characters = [string UTF8String];
      stringBuffer.encoding = NSUTF8StringEncoding;
      if(RK_EXPECTED(stringBuffer.characters != NULL, 1)) { stringBuffer.length = strlen(stringBuffer.characters); }
      RK_PROBE(PERFORMANCENOTE, NULL, 0, NULL, stringBuffer.length, -1, 2, "NSString encoding requires expensive UTF8 conversion.");
    }
  }
#endif //USE_CORE_FOUNDATION
  NSCParameterAssert(stringBuffer.characters != NULL);
  
  return(stringBuffer);
}

enum {
  RKCaptureExtractAllowConversions      = (1<<0),
  RKCaptureExtractStrictReference       = (1<<1),
  RKCaptureExtractIgnoreConversions     = (1<<2)
};

typedef RKUInteger RKCaptureExtractOptions;

/*************** Match and replace operations ***************/

// Used in NSString to perform match and replace operations.  Kept here to keep things tidy.

#define RK_DEFAULT_STACK_INSTRUCTIONS (64)

#define OP_STOP                 0
#define OP_COPY_CAPTUREINDEX    1
#define OP_COPY_CAPTURENAME     2
#define OP_COPY_RANGE           3
#define OP_COMMENT              4
#define OP_UPPERCASE_NEXT_CHAR  5
#define OP_LOWERCASE_NEXT_CHAR  6
#define OP_UPPERCASE_BEGIN      7
#define OP_LOWERCASE_BEGIN      8
#define OP_CHANGE_CASE_END      9

struct referenceInstruction {
                      int                     op;
  RK_STRONG_REF const void * RK_C99(restrict) ptr;
                      NSRange                 range;
};

struct copyInstruction {
  RK_STRONG_REF const void * RK_C99(restrict) ptr;
                      RKUInteger              length;
};

typedef struct referenceInstruction RKReferenceInstruction;
typedef struct copyInstruction      RKCopyInstruction;

struct referenceInstructionsBuffer {
                RKUInteger                                length, capacity;
  RK_STRONG_REF RKReferenceInstruction * RK_C99(restrict) instructions;
  RK_STRONG_REF NSMutableData          * RK_C99(restrict) mutableData;
                BOOL                                      isValid;
};

struct copyInstructionsBuffer {
                RKUInteger                           length, capacity, copiedLength;
  RK_STRONG_REF RKCopyInstruction * RK_C99(restrict) instructions;
  RK_STRONG_REF NSMutableData     * RK_C99(restrict) mutableData;
                BOOL                                 isValid;
};

typedef struct referenceInstructionsBuffer RKReferenceInstructionsBuffer;
typedef struct copyInstructionsBuffer      RKCopyInstructionsBuffer;

#define RKMakeReferenceInstructionsBuffer(length, capacity, instructions, mutableData) ((RKReferenceInstructionsBuffer){length, capacity, instructions, mutableData, YES})
#define RKMakeCopyInstructionsBuffer(length, capacity, copiedLength, instructions, mutableData) ((RKCopyInstructionsBuffer){length, capacity, copiedLength, instructions, mutableData, YES})

/*************** End match and replace operations ***************/

#define RKutf16to8(a,b) RKConvertUTF16ToUTF8RangeForString(a, b)
#define RKutf8to16(a,b) RKConvertUTF8ToUTF16RangeForString(a, b)

// In NSString.m
unsigned char RKLengthOfUTF8Character(const unsigned char *p)  RK_ATTRIBUTES(nonnull, pure, used, visibility("hidden"));
NSRange       RKConvertUTF8ToUTF16RangeForStringBuffer(RKStringBuffer *stringBuffer, NSRange utf8Range);
NSRange       RKConvertUTF16ToUTF8RangeForStringBuffer(RKStringBuffer *stringBuffer, NSRange utf16Range);
NSRange       RKRangeForUTF8CharacterAtLocation(RKStringBuffer *stringBuffer, RKUInteger utf8Location);

NSString     *RKStringFromReferenceString(id self, const SEL _cmd, RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) matchStringBuffer, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) referenceStringBuffer) RK_ATTRIBUTES(malloc, used, visibility("hidden"));
BOOL          RKExtractCapturesFromMatchesWithKeyArguments(id self, const SEL _cmd, RK_STRONG_REF const RKStringBuffer * const RK_C99(restrict) stringBuffer, RKRegex * const RK_C99(restrict) regex, RK_STRONG_REF const NSRange * const RK_C99(restrict) matchRanges, const RKCaptureExtractOptions captureExtractOptions, NSString * const firstKey, va_list useVarArgsList) RK_ATTRIBUTES(used, visibility("hidden"));

#endif _REGEXKIT_NSSTRINGPRIVATE_H_
  
#ifdef __cplusplus
}  /* extern "C" */
#endif
