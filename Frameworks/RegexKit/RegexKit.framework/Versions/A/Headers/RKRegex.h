//
//  RKRegex.h
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

#ifdef __cplusplus
extern "C" {
#endif
  
#ifndef _REGEXKIT_RKREGEX_H_
#define _REGEXKIT_RKREGEX_H_ 1

#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>
#import <RegexKit/RegexKit.h>
#import <RegexKit/pcre.h>

@interface RKRegex : NSObject <NSCoding, NSCopying> {
  RK_STRONG_REF pcre            *_compiledPCRE;          // Pointer to pcre library type pcre.
  RK_STRONG_REF pcre_extra      *_extraPCRE;             // Pointer to pcre library type pcre_extra.

                NSString        *compiledRegexString;    // A copy of the regex string that was compiled.
                RKCompileOption  compileOption;          // The options used to compile this regex.
                RKUInteger       captureCount;           // The number of captures in the compiled regex string.
  RK_STRONG_REF char            *captureNameTable;       // Pointer to capture names structure.
                RKUInteger       captureNameTableLength; // Number of entries in the capture name structure
                RKUInteger       captureNameLength;      // The length of a capture name entry.
                NSArray         *captureNameArray;       // An array that maps capture index values to capture names.  nil if no named captures.
   
                RKInteger        referenceCountMinusOne; // Keep track of the reference count ourselves.
                RKUInteger       hash;                   // Hash value for this object.

  RK_STRONG_REF char            *compiledRegexUTF8String;
  RK_STRONG_REF char            *compiledOptionUTF8String;
}

+ (RKCache *)regexCache;

+ (NSString *)PCREVersionString;
+ (int32_t)PCREMajorVersion;
+ (int32_t)PCREMinorVersion;
+ (RKBuildConfig)PCREBuildConfig;

+ (BOOL)isValidRegexString:(NSString * const)regexString options:(const RKCompileOption)options;
+ (id)regexWithRegexString:(NSString * const)regexString options:(const RKCompileOption)options;
+ (id)regexWithRegexString:(NSString *)regexString library:(NSString *)libraryString options:(const RKCompileOption)libraryOptions error:(NSError **)error;
- (id)initWithRegexString:(NSString *)regexString options:(const RKCompileOption)options;
- (id)initWithRegexString:(NSString *)regexString library:(NSString *)library options:(const RKCompileOption)libraryOptions error:(NSError **)error;
- (NSString *)regexString;
- (RKCompileOption)compileOption;

- (RKUInteger)captureCount;
- (NSArray *)captureNameArray;
- (BOOL)isValidCaptureName:(NSString * const)captureNameString;
- (RKUInteger)captureIndexForCaptureName:(NSString * const)captureNameString;
- (NSString *)captureNameForCaptureIndex:(const RKUInteger)captureIndex;
- (RKUInteger)captureIndexForCaptureName:(NSString *)captureNameString inMatchedRanges:(const NSRange *)matchedRanges;
- (RKUInteger)captureIndexForCaptureName:(NSString *)captureNameString inMatchedRanges:(const NSRange *)matchedRanges error:(NSError **)error;

- (BOOL)matchesCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;
- (NSRange)rangeForCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange captureIndex:(const RKUInteger)captureIndex options:(const RKMatchOption)options;
- (NSRange *)rangesForCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;
- (RKMatchErrorCode)getRanges:(NSRange *)ranges withCharacters:(const void *)charactersBuffer length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;

@end

#endif // _REGEXKIT_RKREGEX_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
