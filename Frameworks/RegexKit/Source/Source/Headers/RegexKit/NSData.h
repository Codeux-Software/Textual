//
//  NSData.h
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
  
#ifndef _REGEXKIT_NSDATA_H_
#define _REGEXKIT_NSDATA_H_ 1

/*!
 @header NSData
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <stdarg.h>
  
/*!
 @category    NSData (RegexKitAdditions)
 @abstract    Convenient @link NSData NSData @/link additions to make regular expression pattern matching and extraction easier.
 @discussion  (comprehensive description)
*/
  
/*!
 @toc        NSData
 @group      Accessing Data
 @group      Determining the Range of a Match
 @group      Testing Data
*/
  
@interface NSData (RegexKitAdditions)

/*!
 @method     isMatchedByRegex:
 @tocgroup   NSData Testing Data
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by <span class="argument">aRegex</span>.
 @seealso    @link NSData(RegexKitAdditions)/isMatchedByRegex:inRange: - isMatchedByRegex:inRange: @/link
*/
- (BOOL)isMatchedByRegex:(id)aRegex;
/*!
 @method     isMatchedByRegex:inRange:
 @tocgroup   NSData Testing Data
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by <span class="argument">aRegex</span> within <span class="argument">range</span>.
*/
- (BOOL)isMatchedByRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     rangeOfRegex:
 @tocgroup   NSData Determining the Range of a Match
 @abstract   Returns the range of the first occurrence within the receiver of <span class="argument">aRegex</span>.
 @result     A @link NSRange NSRange @/link structure giving the location and length of the first match of <span class="argument">aRegex</span> in the receiver. Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if the receiver is not matched by <span class="argument">aRegex</span>.
 @seealso @link NSData(RegexKitAdditions)/rangeOfRegex:inRange:capture: - rangeOfRegex:inRange:capture: @/link
*/
- (NSRange)rangeOfRegex:(id)aRegex;
/*!
 @method     rangeOfRegex:inRange:capture:
 @tocgroup   NSData Determining the Range of a Match
 @abstract   Returns the range of <span class="argument">aRegex</span> capture number <span class="argument">capture</span> for the first match within <span class="argument">range</span> of the receiver.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      range The range of the receiver to search.
 @param      capture The matching range of <span class="argument">aRegex</span> capture number to return. Use <span class="code">0</span> for the entire range that <span class="argument">aRegex</span> matched.
 @result     A @link NSRange NSRange @/link structure giving the location and length of <span class="argument">aRegex</span> capture number <span class="argument">capture</span> for the first match within <span class="argument">range</span> of the receiver. Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if the receiver is not matched by <span class="argument">aRegex</span>.
 @seealso @link NSData(RegexKitAdditions)/rangeOfRegex: - rangeOfRegex: @/link
*/
- (NSRange)rangeOfRegex:(id)aRegex inRange:(const NSRange)range capture:(const RKUInteger)capture;
/*!
 @method     rangesOfRegex:
 @tocgroup   NSData Determining the Range of a Match
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver.
 @discussion See @link rangesForCharacters:length:inRange:options: rangesForCharacters:length:inRange:options: @/link for details regarding the returned @link NSRange NSRange @/link array memory allocation.
 @result     Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver, or <span class="code">NULL</span> if <span class="argument">aRegex</span> does not match.
 @seealso @link NSData(RegexKitAdditions)/rangesOfRegex:inRange: - rangesOfRegex:inRange: @/link
 @seealso @link rangesForCharacters:length:inRange:options: - rangesForCharacters:length:inRange:options: @/link
*/
- (NSRange *)rangesOfRegex:(id)aRegex;
/*!
 @method     rangesOfRegex:inRange:
 @tocgroup   NSData Determining the Range of a Match
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver within <span class="argument">range</span>.
 @discussion See @link rangesForCharacters:length:inRange:options: rangesForCharacters:length:inRange:options: @/link for details regarding the returned @link NSRange NSRange @/link array memory allocation.
 @result     Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver within <span class="argument">range</span>, or <span class="code">NULL</span> if <span class="argument">aRegex</span> does not match.
 @seealso @link NSData(RegexKitAdditions)/rangeOfRegex:inRange:capture: - rangeOfRegex:inRange:capture: @/link
 @seealso @link rangesForCharacters:length:inRange:options: - rangesForCharacters:length:inRange:options: @/link
*/
- (NSRange *)rangesOfRegex:(id)aRegex inRange:(const NSRange)range;

/*!
 @method     subdataByMatching:
 @tocgroup   NSData Accessing Data
 @abstract   Returns a @link NSData NSData @/link that contains the bytes of the first match by <span class="argument">aRegex</span>.
 @seealso    @link NSData(RegexKitAdditions)/subdataByMatching:inRange: - subdataByMatching:inRange: @/link
*/
- (NSData *)subdataByMatching:(id)aRegex;
/*!
 @method     subdataByMatching:inRange:
 @tocgroup   NSData Accessing Data
 @abstract   Returns a @link NSData NSData @/link that contains the bytes of the first match by <span class="argument">aRegex</span> within <span class="argument">range</span>.
 @seealso    @link NSData(RegexKitAdditions)/subdataByMatching: - subdataByMatching: @/link
*/
- (NSData *)subdataByMatching:(id)aRegex inRange:(const NSRange)range;

@end

#endif // _REGEXKIT_NSDATA_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
