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

/*!
 @header NSString
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <stdarg.h>

/*!
 @function  RKConvertUTF8ToUTF16RangeForString
 @tocgroup   Functions Unicode Character Index Conversions
 @abstract   Converts the UTF8 character index <span class="argument">range</span> for <span class="argument">string</span> to its UTF16 character index range equivalent.
 @discussion Used to convert the character index values from PCREs native UTF8 string encoding to Foundations native UTF16 encoding.
*/
REGEXKIT_EXTERN NSRange RKConvertUTF8ToUTF16RangeForString(NSString *string, NSRange range);
/*!
 @function  RKConvertUTF16ToUTF8RangeForString
 @tocgroup   Functions Unicode Character Index Conversions
 @abstract   Converts the UTF16 character index <span class="argument">range</span> for <span class="argument">string</span> to its UTF8 character index range equivalent.
 @discussion Used to convert the character index values from Foundations native UTF16 string encoding to PCREs native UTF8 encoding.
*/
REGEXKIT_EXTERN NSRange RKConvertUTF16ToUTF8RangeForString(NSString *string, NSRange range);
  
/*!
 @category    NSString (RegexKitAdditions)
 @abstract    Convenient @link NSString NSString @/link additions to make regular expression pattern matching and extraction easier.
*/

/*!
 @toc   NSString
 @group Capture Extraction and Conversion
 @group Determining the Range of a Match
 @group Enumerating Matches
 @group Identifying Matches
 @group Creating Temporary Strings from Match Results
 @group Search and Replace
*/

@interface NSString (RegexKitAdditions)

/*!
 @method     getCapturesWithRegexAndReferences:
 @tocgroup   NSString Capture Extraction and Conversion
 @abstract   Takes a regular expression followed by a variable length list of capture subpattern <span class="argument">reference</span> and <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs.
 @discussion <p>Following the regular expression <span class="argument">aRegex</span>, a variable length list of capture subpattern <span class="argument">reference</span> / <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs is given, terminated with a <span class="code">nil</span>.  The calling sequence is similar to @link NSDictionary NSDictionary @/link @link NSDictionary/dictionaryWithObjectsAndKeys: dictionaryWithObjectsAndKeys: @/link except that <span class="argument">reference</span> proceeds <span class="argument nobr">pointer to a pointer</span> instead of the @link NSDictionary NSDictionary @/link pair ordering where <span class="argument nobr">object pointer</span> proceeds <span class="argument">reference</span>.</p>
 <p>The order in which the capture subpattern <span class="argument">reference</span> arguments appears does not matter, nor the number of times that a capture subpattern <span class="argument">reference</span> appears.</p>
 <p>See <a href="NSString.html#CaptureSubpatternReferenceandTypeConversionSyntax" class="section-link">Capture Subpattern Reference and Type Conversion Syntax</a> for information on how to specify capture subpatterns and the different types of conversions that can be performed on the matched text.  If the optional type conversion is not specified then the default conversion to a @link NSString NSString @/link containing the text of the requested capture subpattern will be returned via <span class="argument nobr">pointer to a pointer</span>.</p>
 <p><b>Examples</b></p>
<div class="box sourcecode">NSString *capture0 = nil, *capture1 = nil, *capture2 = nil;
NSString *subjectString = &#64;"This is the subject string to be matched";

&#47;&#47; Note the use of &amp;, referring to the address containing the pointer, not the value of the pointer.
[subjectString getCapturesWithRegexAndReferences:&#64;"(is the).*(to be)", &#64;"${1}", &amp;capture1, &#64;"${2}", &amp;capture2, &#64;"${0}", &amp;capture0, nil];

&#47;&#47; capture0 == &#64;"is the subject string to be";
&#47;&#47; capture1 == &#64;"is the";
&#47;&#47; capture2 == &#64;"to be";</div> 

<p>The same example demonstrating that a @link RKRegex RKRegex @/link object and a @link NSString NSString @/link of a regular expression may be used interchangeably.  Regular expressions passed as a @link NSString NSString @/link are automatically converted to @link RKRegex RKRegex @/link objects before use.</p>

<div class="box sourcecode">NSString *capture0 = nil, *capture1 = nil, *capture2 = nil;
NSString *subjectString = &#64;"This is the subject string to be matched";
RKRegex *aRegex = [[RKRegex alloc] initWithRegexString:&#64;"(is the).*(to be)" options:RKCompileNoOptions];

[subjectString getCapturesWithRegexAndReferences:aRegex, &#64;"${1}", &amp;capture1, &#64;"${2}", &amp;capture2, &#64;"${0}", &amp;capture0, nil];</div> 

<p>An example demonstrating a hex string converted to the equivalent <span class="code">unsigned int</span> value.</p>
 
<div class="box sourcecode">unsigned int convertedHex = 0;
NSString *subjectString = &#64;"Convert this value: 0xb1223dd8";

[subjectString getCapturesWithRegexAndReferences:&#64;"value: (0x[0-9a-f]+)", &#64;"${1:%x}", &amp;convertedHex, nil];

&#47;&#47; convertedHex == 0xb1223dd8 (decimal 2971811288)</div> 
 
 @param aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param ...  A comma-separated list of capture subpattern <span class="argument">reference</span> and <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs, terminated with a <span class="code">nil</span>.
  <div class="box warning"><div class="table"><div class="row"><div class="label cell">Warning:</div><div class="message cell">Failure to terminate the argument list with a <span class="code">nil</span> will result in a crash.</div></div></div></div>
 @result <p>If <span class="argument">aRegex</span> matches the receiver, the supplied <span class="argument nobr">pointer to a pointer</span> arguments are updated with the match results and <span class="code">YES</span> is returned.  If <span class="argument">aRegex</span> matches the receiver multiple times, only the first match is used.</p>
 <p>If <span class="argument">aRegex</span> does not match the receiver, none of the supplied <span class="argument nobr">pointer to a pointer</span> arguments are altered and <span class="code">NO</span> is returned.</p>
 @seealso @link getCapturesWithRegex:inRange:references: - getCapturesWithRegex:inRange:references: @/link
 @seealso <a href="NSString.html#CaptureSubpatternReferenceandTypeConversionSyntax" class="section-link">Capture Subpattern Reference and Type Conversion Syntax</a>
*/
- (BOOL)getCapturesWithRegexAndReferences:(id)aRegex, ... RK_REQUIRES_NIL_TERMINATION;
/*!
 @method     getCapturesWithRegex:inRange:references:
 @tocgroup   NSString Capture Extraction and Conversion
 @abstract   Takes a regular expression and <span class="argument">range</span> of the receiver to search, followed by a variable length list of capture subpattern <span class="argument">reference</span> and <span class="argument nobr">pointer to a pointer</span> type conversion specification pairs.
 @result <p>If <span class="argument">aRegex</span> matches the receiver within <span class="argument">range</span>, the supplied <span class="argument nobr">pointer to a pointer</span> arguments are updated with the match results and <span class="code">YES</span> is returned.  If <span class="argument">aRegex</span> matches the receiver multiple times, only the first match within <span class="argument">range</span> is used.</p>
 <p>If <span class="argument">aRegex</span> does not match the receiver within <span class="argument">range</span>, none of the supplied <span class="argument nobr">pointer to a pointer</span> arguments are altered and <span class="code">NO</span> is returned.</p>
 @seealso <a href="NSString.html#CaptureSubpatternReferenceandTypeConversionSyntax" class="section-link">Capture Subpattern Reference and Type Conversion Syntax</a>
 @seealso @link NSString(RegexKitAdditions)/getCapturesWithRegexAndReferences: - getCapturesWithRegexAndReferences: @/link
*/
- (BOOL)getCapturesWithRegex:(id)aRegex inRange:(const NSRange)range references:(NSString * const)firstReference, ... RK_REQUIRES_NIL_TERMINATION;
/*!
 @method     rangesOfRegex:
 @tocgroup   NSString Determining the Range of a Match
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver.
 @discussion See @link rangesForCharacters:length:inRange:options: rangesForCharacters:length:inRange:options: @/link for details regarding the returned @link NSRange NSRange @/link array memory allocation.
 @result     Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver, or <span class="code">NULL</span> if <span class="argument">aRegex</span> does not match.
 @seealso @link NSString(RegexKitAdditions)/rangesOfRegex:inRange: - rangesOfRegex:inRange: @/link
 @seealso @link rangesForCharacters:length:inRange:options: - rangesForCharacters:length:inRange:options: @/link
*/
- (NSRange *)rangesOfRegex:(id)aRegex;
/*!
 @method     rangesOfRegex:inRange:
 @tocgroup   NSString Determining the Range of a Match
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver within <span class="argument">range</span>.
 @discussion See @link rangesForCharacters:length:inRange:options: rangesForCharacters:length:inRange:options: @/link for details regarding the returned @link NSRange NSRange @/link array memory allocation.
 @result     Returns a pointer to an array of @link NSRange NSRange @/link structures of the capture subpatterns of <span class="argument">aRegex</span> for the first match in the receiver within <span class="argument">range</span>, or <span class="code">NULL</span> if <span class="argument">aRegex</span> does not match.
 @seealso @link NSString(RegexKitAdditions)/rangeOfRegex:inRange:capture: - rangeOfRegex:inRange:capture: @/link
 @seealso @link rangesForCharacters:length:inRange:options: - rangesForCharacters:length:inRange:options: @/link
*/
- (NSRange *)rangesOfRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     rangeOfRegex:
 @tocgroup   NSString Determining the Range of a Match
 @abstract   Returns the range of the first occurrence within the receiver of <span class="argument">aRegex</span>.
 @result     A @link NSRange NSRange @/link structure giving the location and length of the first match of <span class="argument">aRegex</span> in the receiver. Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if the receiver is not matched by <span class="argument">aRegex</span>.
 @seealso @link NSString(RegexKitAdditions)/rangeOfRegex:inRange:capture: - rangeOfRegex:inRange:capture: @/link
*/
- (NSRange)rangeOfRegex:(id)aRegex;
/*!
 @method     rangeOfRegex:inRange:capture:
 @tocgroup   NSString Determining the Range of a Match
 @abstract   Returns the range of <span class="argument">aRegex</span> capture number <span class="argument">capture</span> for the first match within <span class="argument">range</span> of the receiver.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      range The range of the receiver to search.
 @param      capture The matching range of <span class="argument">aRegex</span> capture number to return. Use <span class="code">0</span> for the entire range that <span class="argument">aRegex</span> matched.
 @result     A @link NSRange NSRange @/link structure giving the location and length of <span class="argument">aRegex</span> capture number <span class="argument">capture</span> for the first match within <span class="argument">range</span> of the receiver. Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if the receiver is not matched by <span class="argument">aRegex</span>.
 @seealso @link NSString(RegexKitAdditions)/rangeOfRegex: - rangeOfRegex: @/link
*/
- (NSRange)rangeOfRegex:(id)aRegex inRange:(const NSRange)range capture:(const RKUInteger)capture;
/*!
 @method     isMatchedByRegex:
 @tocgroup   NSString Identifying Matches
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by <span class="argument">aRegex</span>.
 @seealso    @link NSString(RegexKitAdditions)/isMatchedByRegex:inRange: - isMatchedByRegex:inRange: @/link
*/
- (BOOL)isMatchedByRegex:(id)aRegex;
/*!
 @method     isMatchedByRegex:inRange:
 @tocgroup   NSString Identifying Matches
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by <span class="argument">aRegex</span> within <span class="argument">range</span>.
*/
- (BOOL)isMatchedByRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     matchEnumeratorWithRegex:
 @tocgroup   NSString Enumerating Matches
 @abstract   Returns an enumerator object that lets you access every match of <span class="argument">aRegex</span> in the receiver.
 @discussion Returns an @link RKEnumerator RKEnumerator @/link object that begins at location <span class="code">0</span> of the receiver and enumerates every match of <span class="argument">aRegex</span> in the receiver.
 @seealso    @link RKEnumerator RKEnumerator @/link
 @seealso    @link RKEnumerator/enumeratorWithRegex:string: - enumeratorWithRegex:string: @/link
 @seealso    @link RKEnumerator/getCapturesWithReferences: - getCapturesWithReferences: @/link
 @seealso    @link NSString/matchEnumeratorWithRegex:inRange: - matchEnumeratorWithRegex:inRange: @/link
 @seealso    @link RKEnumerator/nextRanges - nextRanges @/link
 @seealso    @link RKEnumerator/stringWithReferenceFormat: - stringWithReferenceFormat: @/link
 @seealso    @link RKEnumerator/stringWithReferenceString: - stringWithReferenceString: @/link
*/
- (RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex;
/*!
 @method     matchEnumeratorWithRegex:inRange:
 @tocgroup   NSString Enumerating Matches
 @abstract   Returns an enumerator object that lets you access every match of <span class="argument">aRegex</span> within <span class="argument">range</span> of the receiver.
 @param      range The range of the receiver to enumerate matches.
 @discussion Returns an @link RKEnumerator RKEnumerator @/link object that enumerates every match of <span class="argument">aRegex</span> within <span class="argument">range</span> of the receiver.
 @seealso    @link RKEnumerator RKEnumerator @/link
 @seealso    @link RKEnumerator/enumeratorWithRegex:string: - enumeratorWithRegex:string: @/link
 @seealso    @link NSString/matchEnumeratorWithRegex: - matchEnumeratorWithRegex: @/link
*/
- (RKEnumerator *)matchEnumeratorWithRegex:(id)aRegex inRange:(const NSRange)range;



/*!
 @method     stringByMatching:withReferenceString:
 @tocgroup   NSString Creating Temporary Strings from Match Results
 @abstract   Returns a new @link NSString NSString @/link containing the results of expanding the capture references in <span class="argument">referenceString</span> with the text of the first match of <span class="argument">aRegex</span> in the receiver.
 @discussion Equivalent to @link NSString(RegexKitAdditions)/stringByMatching:inRange:withReferenceString: stringByMatching:inRange:withReferenceString: @/link with <span class="argument">range</span> specified as the entire range of the receiver.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link NSString(RegexKitAdditions)/stringByMatching:inRange:withReferenceString: - stringByMatching:inRange:withReferenceString: @/link
*/
- (NSString *)stringByMatching:(id)aRegex withReferenceString:(NSString * const)referenceString;
/*!
 @method     stringByMatching:inRange:withReferenceString:
 @tocgroup   NSString Creating Temporary Strings from Match Results
 @abstract   Returns a new @link NSString NSString @/link containing the results of expanding the capture references in <span class="argument">referenceString</span> with the text of the first match of <span class="argument">aRegex</span> within <span class="argument">range</span> of the receiver.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
*/
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceString:(NSString * const)referenceString;

/*!
 @method     stringByMatching:withReferenceFormat:
 @tocgroup   NSString Creating Temporary Strings from Match Results
 @abstract   Returns a new @link NSString NSString @/link containing the results of expanding the capture references and substituting the format specifiers in <span class="argument">referenceFormatString</span> with the text of the first match of <span class="argument">aRegex</span> in the receiver and the variable length list of format arguments.
 @discussion See <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a> for important information.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/FormatStrings.html#//apple_ref/doc/uid/20000943" class="section-link">Formatting String Objects</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">String Format Specifiers</a>
*/
- (NSString *)stringByMatching:(id)aRegex withReferenceFormat:(NSString * const)referenceFormatString, ...;
/*!
 @method     stringByMatching:inRange:withReferenceFormat:
 @tocgroup   NSString Creating Temporary Strings from Match Results
 @abstract   Returns a new @link NSString NSString @/link containing the results of expanding the capture references and substituting the format specifiers in <span class="argument">referenceFormatString</span> with the text of the first match of <span class="argument">aRegex</span> within <span class="argument">range</span> of the receiver and the variable length list of format arguments.
 @discussion See <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a> for important information.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/FormatStrings.html#//apple_ref/doc/uid/20000943" class="section-link">Formatting String Objects</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">String Format Specifiers</a>
*/
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString, ...;
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex withReferenceFormat:(NSString * const)referenceFormatString, ...;

/*!
 @method     stringByMatching:replace:withReferenceString:
 @tocgroup   NSString Search and Replace
 @abstract   Returns a new @link NSString NSString @/link containing the results of repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of <span class="argument">referenceString</span> after capture references have been expanded.
 @discussion Equivalent to @link NSString(RegexKitAdditions)/stringByMatching:inRange:replace:withReferenceString: stringByMatching:inRange:replace:withReferenceString: @/link with <span class="argument">range</span> specified as the entire range of the receiver.
 @result     A @link NSString NSString @/link containing the results of repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of the replacement string after match references have been expanded.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link NSString(RegexKitAdditions)/stringByMatching:inRange:replace:withReferenceString: - stringByMatching:inRange:replace:withReferenceString: @/link
 @seealso    @link NSMutableString(RegexKitAdditions)/match:replace:withString: - match:replace:withString: @/link
*/
- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
/*!
 @method     stringByMatching:inRange:replace:withReferenceString:
 @tocgroup   NSString Search and Replace
 @abstract   Returns a new @link NSString NSString @/link containing the results of repeatedly searching the <span class="argument">range</span> of the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of <span class="argument">referenceString</span> after capture references have been expanded.
 @discussion @link RKReplaceAll RKReplaceAll @/link can be used for <span class="argument">count</span> to specify that all matches should be replaced.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      range The range of the receiver to perform the search and replace.
 @param      count The maximum number of replacements to perform, or @link RKReplaceAll RKReplaceAll @/link to replace all matches.
 @param      referenceString The string used to replace the matched text.  May include references to <span class="argument">aRegex</span> captures with <i>perl</i> style <span class="regex">${</span><span class="code argument">NUMBER</span><span class="code">}</span> notation. Refer to <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a> for additional information.
 @result     A @link NSString NSString @/link containing the results of repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of the replacement string after match references have been expanded.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    @link NSMutableString(RegexKitAdditions)/match:replace:withString: - match:replace:withString: @/link
*/
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceString:(NSString * const)referenceString;


/*!
 @method     stringByMatching:replace:withReferenceFormat:
 @tocgroup   NSString Search and Replace
 @abstract   Returns a new @link NSString NSString @/link containing the results of repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the evaluated and expanded text of <span class="argument">referenceFormatString</span>.
 @discussion See <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a> for important information.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/FormatStrings.html#//apple_ref/doc/uid/20000943" class="section-link">Formatting String Objects</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">String Format Specifiers</a>
 @seealso    @link NSString(RegexKitAdditions)/stringByMatching:replace:withReferenceString: - stringByMatching:replace:withReferenceString: @/link
 @seealso    @link NSString(RegexKitAdditions)/stringByMatching:inRange:replace:withReferenceFormat: - stringByMatching:inRange:replace:withReferenceFormat: @/link
*/
- (NSString *)stringByMatching:(id)aRegex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
/*!
 @method     stringByMatching:inRange:replace:withReferenceFormat:
 @tocgroup   NSString Search and Replace
 @abstract   Returns a new @link NSString NSString @/link containing the results of repeatedly searching within <span class="argument">range</span> of the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the evaluated and expanded text of <span class="argument">referenceFormatString</span>.
 @discussion See <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a> for important information.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      range The range of the receiver to perform the search and replace.
 @param      count The maximum number of replacements to perform, or @link RKReplaceAll RKReplaceAll @/link to replace all matches.
 @param      referenceFormatString A format string containing <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">format specifiers</a> and <a href="NSString.html#ExpansionofCaptureSubpatternMatchReferencesinStrings" class="section-link">capture subpattern references</a>.
 @param      ... A comma-separated list of <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">format specifier</a> arguments to substitute into <span class="argument">referenceFormatString</span>.
 @seealso    <a href="NSString.html#CaptureSubpatternReferenceSyntax" class="section-link">Capture Subpattern Reference Syntax</a>
 @seealso    <a href="NSString.html#OrderofFormatSpecifierArgumentSubstitutionandExpansionofCaptureSubpatternMatchReferences" class="section-link">Order of Format Specifier Argument Substitution and Expansion of Capture Subpattern Match References</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/FormatStrings.html#//apple_ref/doc/uid/20000943" class="section-link">Formatting String Objects</a>
 @seealso    <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265" class="section-link">String Format Specifiers</a>
*/
- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex fromIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;
//- (NSString *)stringByMatching:(id)aRegex toIndex:(const RKUInteger)anIndex replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString, ...;

- (NSString *)stringByMatching:(id)aRegex inRange:(const NSRange)range replace:(const RKUInteger)count withReferenceFormat:(NSString * const)referenceFormatString arguments:(va_list)argList;

@end

/*!
 @toc        NSMutableString
 @group      Search and Replace
*/

@interface NSMutableString (RegexKitAdditions)

/*!
 @method     match:replace:withString:
 @tocgroup   NSMutableString Search and Replace
 @abstract   Modifies the receiver by repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of <span class="argument">replacementString</span> after capture references have been expanded.
 @discussion <p>This method is identical to @link NSString(RegexKitAdditions)/stringByMatching:replace:withReferenceString: stringByMatching:replace:withReferenceString: @/link except that this method modifies the mutable receiver directly instead of creating a new @link NSString NSString @/link that contains the result of the search and replace.</p>
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @param      count The maximum number of replacements to perform, or @link RKReplaceAll RKReplaceAll @/link to replace all matches.
 @param      replacementString The string used to replace the matched text.  May include references to <span class="argument">aRegex</span> captures with <i>perl</i> style <span class="regex">${</span><span class="code argument">NUMBER</span><span class="code">}</span> notation. Refer to <a href="NSString.html#ExpansionofCaptureSubpatternMatchReferencesinStrings" class="section-link">Expansion of Capture Subpattern Match References in Strings</a> for additional information.
 @result     Modifies the receiver by repeatedly searching the receiver with <span class="argument">aRegex</span> and replacing up to <span class="argument">count</span> matches with the text of <span class="argument">replacementString</span> after capture references have been expanded.  Returns the number of match and replace operations performed.
 @seealso    <a href="NSString.html#ExpansionofCaptureSubpatternMatchReferencesinStrings" class="section-link">Expansion of Capture Subpattern Match References in Strings</a>
 @seealso    @link NSString(RegexKitAdditions)/stringByMatching:replace:withReferenceString: - stringByMatching:replace:withReferenceString: @/link
*/
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
