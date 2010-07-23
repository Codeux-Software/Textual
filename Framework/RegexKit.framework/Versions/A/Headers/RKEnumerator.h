//
//  RKEnumerator.h
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
  
#ifndef _REGEXKIT_RKENUMERATOR_H_
#define _REGEXKIT_RKENUMERATOR_H_ 1

@class RKRegex;

#import <Foundation/Foundation.h>
#import <RegexKit/RKRegex.h>
#import <stdarg.h>

@interface RKEnumerator : NSEnumerator {
  RKRegex  *regex;
  NSString *string;
  RKUInteger atBufferLocation;
  RKUInteger regexCaptureCount;
  NSRange searchByteRange;
  NSRange searchUTF16Range;
  RK_STRONG_REF NSRange *resultUTF8Ranges;
  RK_STRONG_REF NSRange *resultUTF16Ranges;
  RKUInteger hasPerformedMatch:1;
}
+ (id)enumeratorWithRegex:(id)aRegex string:(NSString * const)string;
+ (id)enumeratorWithRegex:(id)aRegex string:(NSString * const)string inRange:(const NSRange)range;
+ (id)enumeratorWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange error:(NSError **)error;
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString;
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange;
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange error:(NSError **)error;
- (RKRegex *)regex;
- (NSString *)string;
- (NSRange)currentRange;
- (NSRange)currentRangeForCapture:(const RKUInteger)capture;
- (NSRange)currentRangeForCaptureName:(NSString * const)captureNameString;
- (NSRange *)currentRanges;
- (id)nextObject;
- (NSRange)nextRange;
- (NSRange)nextRangeForCapture:(const RKUInteger)capture;
- (NSRange)nextRangeForCaptureName:(NSString * const)captureNameString;
- (NSRange *)nextRanges;
- (BOOL)getCapturesWithReferences:(NSString * const)firstReference, ... RK_REQUIRES_NIL_TERMINATION;
- (NSString *)stringWithReferenceString:(NSString * const)referenceString;
- (NSString *)stringWithReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringWithReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;

@end

#endif // _REGEXKIT_RKENUMERATOR_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
