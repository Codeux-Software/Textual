//
//  NSString.h
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
  
#ifndef _REGEXKIT_NSSTRING_H_
#define _REGEXKIT_NSSTRING_H_ 1

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <stdarg.h>
REGEXKIT_EXTERN NSRange RKConvertUTF8ToUTF16RangeForString(NSString *string, NSRange range);
REGEXKIT_EXTERN NSRange RKConvertUTF16ToUTF8RangeForString(NSString *string, NSRange range);

@interface NSString (RegexKitAdditions)
- (BOOL)getCapturesWithRegexAndReferences:(id)aRegex, ... RK_REQUIRES_NIL_TERMINATION;
- (BOOL)getCapturesWithRegex:(id)aRegex inRange:(const NSRange)range references:(NSString * const)firstReference, ... RK_REQUIRES_NIL_TERMINATION;
- (NSRange *)rangesOfRegex:(id)aRegex;
- (NSRange *)rangesOfRegex:(id)aRegex inRange:(const NSRange)range;
- (NSRange)rangeOfRegex:(id)aRegex;
- (NSRange)rangeOfRegex:(id)aRegex inRange:(const NSRange)range capture:(const RKUInteger)capture;
- (BOOL)isMatchedByRegex:(id)aRegex;
- (BOOL)isMatchedByRegex:(id)aRegex inRange:(const NSRange)range;
- (RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex;
- (RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex inRange:(const NSRange)range;
- (NSString *)stringByMatching:(id)aRegex withReferenceString:(NSString * const)referenceString;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)referenceString;
- (NSString *)stringByMatching:(id)aRegex withReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;

@end

@interface NSMutableString (RegexKitAdditions)
- (RKUInteger)match:(id)aRegex replace:(const RKUInteger)count withString:(NSString * const)replacementString;
- (RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withString:(NSString * const)replacementString;
//- (RKUInteger)match:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withString:(NSString * const)replacementString;
//- (RKUInteger)match:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withString:(NSString * const)replacementString;

- (RKUInteger)match:(id)aRegex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...;
- (RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...;
- (RKUInteger)match:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withFormat:(NSString * const)formatString arguments:(va_list)argList;
//- (RKUInteger)match:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...;
//- (RKUInteger)match:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withFormat:(NSString * const)formatString, ...;

@end

#endif // _REGEXKIT_NSSTRING_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
