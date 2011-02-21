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

/*!
 @header RKEnumerator
*/

/*!
@class      RKEnumerator
@toc        RKEnumerator
@abstract   Regular Expression Match Enumerator
*/

/*!
 @toc   RKEnumerator
 @group Advancing to the Next Match
 @group Capture Extraction and Conversion
 @group Current Match Information
 @group Creating Regular Expression Enumerators
 @group Instantiated Enumerator Information
 @group Creating Temporary Strings from the Current Enumerated Match
*/

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


/*!
 @method     enumeratorWithRegex:string:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Convenience method that returns an autoreleased @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">regex</span> starting at location <span class="code">0</span> of <span class="argument">string</span>.
 @seealso    @link enumeratorWithRegex:string:inRange: - enumeratorWithRegex:string:inRange: @/link
 @seealso    @link initWithRegex:string: - initWithRegex:string: @/link
 @seealso    @link matchEnumeratorWithRegex: - matchEnumeratorWithRegex: @/link
*/
+ (id)enumeratorWithRegex:(id)aRegex string:(NSString * const)string;
/*!
 @method     enumeratorWithRegex:string:inRange:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Convenience method that returns an autoreleased @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">regex</span> that will enumerate that matches of <span class="argument">string</span> within <span class="argument">range</span>.
 @seealso    @link enumeratorWithRegex:string: - enumeratorWithRegex:string: @/link
 @seealso    @link initWithRegex:string:inRange: - initWithRegex:string:inRange: @/link
 @seealso    @link matchEnumeratorWithRegex:inRange: - matchEnumeratorWithRegex:inRange: @/link
*/
+ (id)enumeratorWithRegex:(id)aRegex string:(NSString * const)string inRange:(const NSRange)range;

/*!
 @method     enumeratorWithRegex:string:inRange:error:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Convenience method that returns an autoreleased @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">regex</span> that will enumerate that matches of <span class="argument">string</span> within <span class="argument">range</span>.
 @seealso    @link enumeratorWithRegex:string: - enumeratorWithRegex:string: @/link
 @seealso    @link initWithRegex:string:inRange: - initWithRegex:string:inRange: @/link
 @seealso    @link matchEnumeratorWithRegex:inRange: - matchEnumeratorWithRegex:inRange: @/link
*/
+ (id)enumeratorWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange error:(NSError **)error;

/*!
 @method     initWithRegex:string:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Returns a @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">initRegex</span> starting at location <span class="code">0</span> of <span class="argument">initString</span>.
 @discussion <p>Invokes @link initWithRegex:string:inRange: initWithRegex:string:inRange: @/link for the entire range of <span class="argument">initString</span>.</p>
 @param      initRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      initString A @link NSString NSString @/link to scan and return matches by <span class="argument">initRegex</span>.
 @result     Returns a @link RKEnumerator RKEnumerator @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso    @link initWithRegex:string:inRange: - initWithRegex:string:inRange: @/link
 @seealso    @link matchEnumeratorWithRegex: - matchEnumeratorWithRegex: @/link
 @seealso    @link nextRanges - nextRanges @/link
*/
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString;

/*!
 @method     initWithRegex:string:inRange:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Returns a @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">initRegex</span> that will enumerate that matches of <span class="argument">initString</span> within <span class="argument">initRange</span>.
 @param      initRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      initString A @link NSString NSString @/link to scan and return matches by <span class="argument">initRegex</span>.
 @param      initRange The range of <span class="argument">initString</span> to enumerate matches.
 @result     Returns a @link RKEnumerator RKEnumerator @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso    @link initWithRegex:string: - initWithRegex:string: @/link
 @seealso    @link matchEnumeratorWithRegex:inRange: - matchEnumeratorWithRegex:inRange: @/link
 @seealso    @link nextRanges - nextRanges @/link
*/
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange;

/*!
 @method     initWithRegex:string:inRange:error:
 @tocgroup   RKEnumerator Creating Regular Expression Enumerators
 @abstract   Returns a @link RKEnumerator RKEnumerator @/link object initialized with the regular expression <span class="argument">initRegex</span> that will enumerate that matches of <span class="argument">initString</span> within <span class="argument">initRange</span>.
 @param      initRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      initString A @link NSString NSString @/link to scan and return matches by <span class="argument">initRegex</span>.
 @param      initRange The range of <span class="argument">initString</span> to enumerate matches.
 @param      error An <i>optional</i> parameter that if set and an error occurs, will contain a @link NSError NSError @/link object that describes the problem.  This may be set to <span class="code">NULL</span> if information about any errors is not required.
 @result     Returns a @link RKEnumerator RKEnumerator @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso    @link initWithRegex:string: - initWithRegex:string: @/link
 @seealso    @link matchEnumeratorWithRegex:inRange: - matchEnumeratorWithRegex:inRange: @/link
 @seealso    @link nextRanges - nextRanges @/link
*/
- (id)initWithRegex:(id)initRegex string:(NSString * const)initString inRange:(const NSRange)initRange error:(NSError **)error;

/*!
 @method     regex
 @tocgroup   RKEnumerator Instantiated Enumerator Information
 @abstract   Returns the @link RKRegex RKRegex @/link regular expression used to create receiver.
*/
- (RKRegex *)regex;
/*!
 @method     string
 @tocgroup   RKEnumerator Instantiated Enumerator Information
 @abstract   Returns the string to enumerate matches from that was used to create receiver.
*/
- (NSString *)string;
/*!
 @method     currentRange
 @tocgroup   RKEnumerator Current Match Information
 @abstract   Returns the range of the current match.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if receiver has enumerated all the matches.
 @seealso    @link nextRange - nextRange @/link
*/
- (NSRange)currentRange;
/*!
 @method     currentRangeForCapture:
 @tocgroup   RKEnumerator Current Match Information
 @abstract   Returns the range of the current match for capture subpattern <span class="argument">capture</span>.
 @param      capture The range of the match for the capture subpattern <span class="argument">capture</span> of the receivers regular expression to return.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if receiver has enumerated all the matches.
 @seealso    @link nextRangeForCapture: - nextRangeForCapture: @/link
*/
- (NSRange)currentRangeForCapture:(const RKUInteger)capture;
/*!
 @method     currentRangeForCaptureName:
 @tocgroup   RKEnumerator Current Match Information
 @abstract   Returns the range of the current match for named capture subpattern <span class="argument">captureNameString</span>.
 @param      captureNameString The range of the match for the named capture subpattern <span class="argument">captureNameString</span> of the receivers regular expression to return.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if receiver has enumerated all the matches.
 @seealso    @link nextRangeForCaptureName: - nextRangeForCaptureName: @/link
*/
- (NSRange)currentRangeForCaptureName:(NSString * const)captureNameString;
/*!
 @method     currentRanges
 @tocgroup   RKEnumerator Current Match Information
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures corresponding the the capture subpatterns of the receivers regular expression for the current match.
 @discussion <p>Returns a pointer to an array of @link NSRange NSRange @/link structures containing the current match results returned by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link.</p>
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">For speed and efficiency, the pointer returned is the receivers private buffer of @link NSRange NSRange @/link results which must not be modified, retained, or released by the caller. The pointer returned by successive invocations of @link currentRanges currentRanges @/link will be identical, however the information at the results location will be updated when the receiver is advanced to the next match with the new match results.</div></div></div></div>
 <p>Since the buffer returned by @link currentRanges currentRanges @/link is overwritten with the results of the next match, the caller must not use a pointer to the results once the receiver has advanced to the next match.  If a range result is required after the receiver has advanced to the next result, the caller must make a private copy of any required results.</p>
 @result     Returns a pointer to an array of @link NSRange NSRange @/link structures that contains <span class="code">[</span><span class="argument">receiversRegex</span> @link captureCount captureCount@/link<span class="code">]</span> elements corresponding the the capture subpatterns of the receivers regular expression.  If all of the match results have been enumerated, <span class="code">NULL</span> is returned.
 @seealso    @link nextRanges - nextRanges @/link
*/
- (NSRange *)currentRanges;
/*!
 @method     nextObject
 @tocgroup   RKEnumerator Advancing to the Next Match
 @abstract   Advances to the next match of the receivers regular expression and returns a @link NSArray NSArray @/link of @link NSValue NSValue @/link set to the range of the match for each of the receivers capture subpatterns.
 @result     Returns NULL if there are no additional matches.
 @seealso    @link nextRange - nextRange @/link
 @seealso    @link nextRanges - nextRanges @/link
*/
- (id)nextObject;
/*!
 @method     nextRange
 @tocgroup   RKEnumerator Advancing to the Next Match
 @abstract   Advances to the next match of the receivers regular expression and returns the range of the entire match.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if there are no additional matches.
 @seealso    @link currentRange - currentRange @/link
 @seealso    @link nextRangeForCapture: - nextRangeForCapture: @/link
*/
- (NSRange)nextRange;
/*!
 @method     nextRangeForCapture:
 @tocgroup   RKEnumerator Advancing to the Next Match
 @abstract   Advances to the next match of the receivers regular expression and returns the range of the match for capture subpattern <span class="argument">capture</span>.
 @param      capture The range of the match for the capture subpattern <span class="argument">capture</span> of the receivers regular expression to return.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if there are no additional matches.
 @seealso    @link currentRangeForCapture: - currentRangeForCapture: @/link
*/
- (NSRange)nextRangeForCapture:(const RKUInteger)capture;
/*!
 @method     nextRangeForCaptureName:
 @tocgroup   RKEnumerator Advancing to the Next Match
 @abstract   Advances to the next match of the receivers regular expression and returns the range of the match for named capture subpattern <span class="argument">captureNameString</span>.
 @param      capture The range of the match for the named capture subpattern <span class="argument">captureNameString</span> of the receivers regular expression to return.
 @result     Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if there are no additional matches.
 @seealso    @link captureIndexForCaptureName:inMatchedRanges: - captureIndexForCaptureName:inMatchedRanges: @/link
 @seealso    @link currentRangeForCaptureName: - currentRangeForCaptureName: @/link
*/
- (NSRange)nextRangeForCaptureName:(NSString * const)captureNameString;
/*!
 @method     nextRanges
 @tocgroup   RKEnumerator Advancing to the Next Match
 @abstract   Advances to the next match of the receivers regular expression and returns a pointer to an array of @link NSRange NSRange @/link structures corresponding the the capture subpatterns of the receivers regular expression.
 @discussion  <p>This method only updates the receivers internal state with the ranges for next consecutive match of the receivers regular expression, if any.  This is the preferred means of iterating matches when methods such as @link stringWithReferenceString: stringWithReferenceString: @/link or @link stringWithReferenceFormat: stringWithReferenceFormat: @/link are to be used with the results of a match since no extraneous objects are created or memory allocated as a result.</p>
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">See @link currentRanges currentRanges @/link for information regarding the array of results returned.</div></div></div></div>
 @result     Returns <span class="code">NULL</span> if there are no additional matches.
 @seealso    @link currentRanges - currentRanges @/link
 @seealso    @link nextRange - nextRange @/link
*/
- (NSRange *)nextRanges;
/*!
 @method     getCapturesWithReferences:
 @tocgroup   RKEnumerator Capture Extraction and Conversion
 @abstract   Takes a variable length list of capture subpattern <span class="argument">reference</span> and <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs and applies them to the receivers current match enumeration.
 @discussion <p>This method is similar to @link getCapturesWithRegexAndReferences: getCapturesWithRegexAndReferences: @/link except that instead of extracting the capture subpatterns of the first match of a regular expression, this method extracts the capture subpatterns of the current match enumeration of the receiver.</p>
<p>See <a href="NSString.html#CaptureSubpatternReferenceandTypeConversionSyntax" class="section-link">Capture Subpattern Reference and Type Conversion Syntax</a> for information on how to specify capture subpatterns and the different types of conversions that can be performed on the matched text.  If the optional type conversion is not specified then the default conversion to a @link NSString NSString @/link containing the text of the requested capture subpattern will be returned via <span class="argument nobr">pointer to a pointer</span>.</p>
 @param      firstReference The first capture subpattern type conversion reference.
 @param      ... First the <span class="argument nobr">pointer to a pointer</span> for <span class="argument">firstReference</span>, then a comma-separated list of capture subpattern <span class="argument">reference</span> and <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs, terminated with a <span class="code">nil</span>.
<div class="box warning"><div class="table"><div class="row"><div class="label cell">Warning:</div><div class="message cell">Failure to terminate the argument list with a <span class="code">nil</span> will result in a crash.</div></div></div></div>
 @result     Returns <span class="code">YES</span> if the receiver successfully converted the requested capture subpatterns, <span class="code">NO</span> otherwise.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceandTypeConversionSyntax" class="section-link">Capture Subpattern Reference and Type Conversion Syntax</a>
 @seealso    @link NSString/getCapturesWithRegexAndReferences: - getCapturesWithRegexAndReferences: @/link
 @seealso    @link RKEnumerator/stringWithReferenceFormat: - stringWithReferenceFormat: @/link
 @seealso    @link RKEnumerator/stringWithReferenceString: - stringWithReferenceString: @/link
 @seealso    @link nextRanges - nextRanges @/link
*/
- (BOOL)getCapturesWithReferences:(NSString * const)firstReference, ... RK_REQUIRES_NIL_TERMINATION;
/*!
 @method     stringWithReferenceString:
 @tocgroup   RKEnumerator Creating Temporary Strings from the Current Enumerated Match
 @abstract   Returns a new @link NSString NSString @/link containing the results of expanding the capture subpatterns in <span class="argument">referenceString</span> with the current match results.
 @discussion (comprehensive description)
 @param      referenceString (description)
 @result     (description)
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link nextRanges - nextRanges @/link
 @seealso    @link stringByMatching:replace:withReferenceString: - stringByMatching:replace:withReferenceString: @/link
*/
- (NSString *)stringWithReferenceString:(NSString * const)referenceString;
/*!
 @method     stringWithReferenceFormat:
 @tocgroup   RKEnumerator Creating Temporary Strings from the Current Enumerated Match
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      referenceFormatString (description)
 @result     (description)
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link nextRanges - nextRanges @/link
 @seealso    @link stringWithReferenceFormat:arguments: - stringWithReferenceFormat:arguments: @/link
*/
- (NSString *)stringWithReferenceFormat:(NSString * const)referenceFormatString, ...;
/*!
 @method     stringWithReferenceFormat:arguments:
 @tocgroup   RKEnumerator Creating Temporary Strings from the Current Enumerated Match
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      referenceFormatString (description)
 @param      argList A list of @link va_list va_list @/link arguments to substitute into <span class="argument">referenceFormatString</span>.
 @result     (description)
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link nextRanges - nextRanges @/link
 @seealso    @link stringWithReferenceFormat: - stringWithReferenceFormat: @/link
*/
- (NSString *)stringWithReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;

@end

#endif // _REGEXKIT_RKENUMERATOR_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
